// Copyright 2024 Circle Internet Group, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module stablecoin::treasury {
    use std::string;
    use std::ascii;
    use std::u64::{min, max};
    use sui::{
        coin::{
            Self, Coin, CoinMetadata, DenyCapV2, TreasuryCap, 

            // returns if address is on the deny list based on the most recent update
            deny_list_v2_contains_next_epoch as is_blocklisted,
            // returns if the global pause is effective based on the most recent update
            deny_list_v2_is_global_pause_enabled_next_epoch as is_paused,
        },
        deny_list::{DenyList},
        event,
        table::{Self, Table},
        dynamic_object_field as dof,
        vec_set::{Self, VecSet}
    };
    use stablecoin::mint_allowance::{Self, MintAllowance};
    use stablecoin::roles::{Self, Roles};
    use stablecoin::version_control::{Self, assert_object_version_is_compatible_with_package};

    // === Errors ===

    const EControllerAlreadyConfigured: u64 = 0;
    const EDeniedAddress: u64 = 1;
    const EDenyCapNotFound: u64 = 2;
    const EInsufficientAllowance: u64 = 3;
    const ENotBlocklister: u64 = 4;
    const ENotController: u64 = 5;
    const ENotMasterMinter: u64 = 6;
    const ENotMetadataUpdater: u64 = 7;
    const ENotPauser: u64 = 8;
    const EPaused: u64 = 9;
    const ETreasuryCapNotFound: u64 = 10;
    const EUnauthorizedMintCap: u64 = 11;
    const EZeroAmount: u64 = 12;

    /// Migration related error codes, starting at 100.
    const EMigrationStarted: u64 = 100;
    const EMigrationNotStarted: u64 = 101;
    const EObjectMigrated: u64 = 102;
    const ENotPendingVersion: u64 = 103;

    // === Structs ===

    /// A versioned Treasury of type `T` that stores:
    /// - a TreasuryCap object
    /// - a DenyCap object
    /// - a set of privileged roles that manages different parts of this object's data
    /// - additional configurations related to minting and burning
    public struct Treasury<phantom T> has key, store {
        id: UID,
        /// A map of { controller address => MintCap ID that it controls }.
        controllers: Table<address, ID>,
        /// A map of { authorized MintCap ID => its MintAllowance }.
        mint_allowances: Table<ID, MintAllowance<T>>, 
        /// Mutable privileged role addresses.
        roles: Roles<T>,
        /// The set of package version numbers that object is compatible with.
        compatible_versions: VecSet<u64>
    }

    /// An object representing the ability to mint up to an allowance 
    /// specified in the Treasury. 
    /// The privilege can be revoked by the master minter.
    public struct MintCap<phantom T> has key, store {
        id: UID,
    }

    /// Key for retrieving the `TreasuryCap` stored in a `Treasury<T>` dynamic object field
    public struct TreasuryCapKey has copy, store, drop {}
    /// Key for retrieving `DenyCap` stored in a `Treasury<T>` dynamic object field
    public struct DenyCapKey has copy, store, drop {}

    // === Events ===

    public struct MintCapCreated<phantom T> has copy, drop {
        mint_cap: ID,
    }

    public struct ControllerConfigured<phantom T> has copy, drop {
        controller: address,
        mint_cap: ID,
    }

    public struct ControllerRemoved<phantom T> has copy, drop {
        controller: address,
    }
    
    public struct MinterConfigured<phantom T> has copy, drop {
        controller: address,
        mint_cap: ID,
        allowance: u64,
    }
    
    public struct MinterRemoved<phantom T> has copy, drop {
        controller: address,
        mint_cap: ID,
    }

    public struct MinterAllowanceIncremented<phantom T> has copy, drop {
        controller: address,
        mint_cap: ID,
        allowance_increment: u64,
        new_allowance: u64,
    }

    public struct Mint<phantom T> has copy, drop {
        mint_cap: ID,
        recipient: address,
        amount: u64,
    }

    public struct Burn<phantom T> has copy, drop {
        mint_cap: ID,
        amount: u64,
    }

    public struct Blocklisted<phantom T> has copy, drop {
        `address`: address
    }

    public struct Unblocklisted<phantom T> has copy, drop {
        `address`: address
    }

    public struct Pause<phantom T> has copy, drop {}

    public struct Unpause<phantom T> has copy, drop {}

    public struct MetadataUpdated<phantom T> has copy, drop {
        name: string::String,
        symbol: ascii::String,
        description: string::String,
        icon_url: ascii::String
    }

    public struct MigrationStarted<phantom T> has copy, drop {
        compatible_versions: vector<u64>
    }

    public struct MigrationAborted<phantom T> has copy, drop {
        compatible_versions: vector<u64>
    }

    public struct MigrationCompleted<phantom T> has copy, drop {
        compatible_versions: vector<u64>
    }

    // === View-only functions ===

    /// Gets an immutable reference to the Roles object.
    public fun roles<T>(treasury: &Treasury<T>): &Roles<T> {
        &treasury.roles
    }

    /// [Package private] Gets a mutable reference to the Roles object.
    public(package) fun roles_mut<T>(treasury: &mut Treasury<T>): &mut Roles<T> {
        &mut treasury.roles
    }

    /// Gets the corresponding MintCap ID attached to a controller address.
    /// Returns option::none() when input is not a valid controller
    public fun get_mint_cap_id<T>(treasury: &Treasury<T>, controller: address): Option<ID> {
        if (!treasury.controllers.contains(controller)) return option::none();
        option::some(*treasury.controllers.borrow(controller))
    }
    
    /// Gets the allowance of a MintCap object.
    /// Returns 0 if the MintCap object is unauthorized.
    public fun mint_allowance<T>(treasury: &Treasury<T>, mint_cap: ID): u64 {
        if (!treasury.is_authorized_mint_cap(mint_cap)) return 0;
        treasury.mint_allowances.borrow(mint_cap).value()
    }

    /// Returns the total amount of Coin<T> in circulation.
    public fun total_supply<T>(treasury: &Treasury<T>): u64 {
        treasury.borrow_treasury_cap().total_supply()
    }

    /// Checks if a MintCap object is authorized to mint.
    public fun is_authorized_mint_cap<T>(treasury: &Treasury<T>, id: ID): bool {
        treasury.mint_allowances.contains(id)
    }

    /// [Package private] Ensures that TreasuryCap exists.
    public(package) fun assert_treasury_cap_exists<T>(treasury: &Treasury<T>) {
        assert!(dof::exists_with_type<_, TreasuryCap<T>>(&treasury.id, TreasuryCapKey {}), ETreasuryCapNotFound);
    }

    /// [Package private] Ensures that DenyCap exists.
    public(package) fun assert_deny_cap_exists<T>(treasury: &Treasury<T>) {
        assert!(dof::exists_with_type<_, DenyCapV2<T>>(&treasury.id, DenyCapKey {}), EDenyCapNotFound);
    }

    /// Gets the set of package versions that the Treasury object is compatible with.
    public fun compatible_versions<T>(treasury: &Treasury<T>): vector<u64> {
        *treasury.compatible_versions.keys()
    }

    /// Checks if an address is a mint controller.
    fun is_controller<T>(treasury: &Treasury<T>, controller_addr: address): bool {
        treasury.controllers.contains(controller_addr)
    }

    // === Write functions ===

    /// Creates and initializes a Treasury object of type T, wrapping a 
    /// TreasuryCap and DenyCapV2 of the same type into it.
    public fun new<T>(
        treasury_cap: TreasuryCap<T>, 
        deny_cap: DenyCapV2<T>, 
        owner: address,
        master_minter: address,
        blocklister: address,
        pauser: address,
        metadata_updater: address,
        ctx: &mut TxContext
    ): Treasury<T> {
        let roles = roles::new(owner, master_minter, blocklister, pauser, metadata_updater, ctx);
        let mut treasury = Treasury {
            id: object::new(ctx),
            controllers: table::new(ctx),
            mint_allowances: table::new(ctx),
            roles,
            compatible_versions: vec_set::singleton(version_control::current_version())
        };
        dof::add(&mut treasury.id, TreasuryCapKey {}, treasury_cap);
        dof::add(&mut treasury.id, DenyCapKey {}, deny_cap);
        treasury
    }

    /// Configures a controller of a MintCap object.
    /// - Only callable by the master minter.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun configure_controller<T>(
        treasury: &mut Treasury<T>, 
        controller: address, 
        mint_cap_id: ID,
        ctx: &TxContext
    ) {
        treasury.assert_is_compatible();
        assert!(treasury.roles.master_minter() == ctx.sender(), ENotMasterMinter);
        assert!(!treasury.is_controller(controller), EControllerAlreadyConfigured);

        treasury.controllers.add(controller, mint_cap_id);
        event::emit(ControllerConfigured<T> {
            controller,
            mint_cap: mint_cap_id
        });
    }

    /// Creates a MintCap object.
    /// - Only callable by the master minter.
    /// - Only callable if the Treasury object is compatible with this package.
    fun create_mint_cap<T>(
        treasury: &Treasury<T>, 
        ctx: &mut TxContext
    ): MintCap<T> {
        treasury.assert_is_compatible();
        assert!(treasury.roles.master_minter() == ctx.sender(), ENotMasterMinter);
        let mint_cap = MintCap { id: object::new(ctx) };
        event::emit(MintCapCreated<T> { 
            mint_cap: object::id(&mint_cap)
        });
        mint_cap
    }

    /// Convenience function that 
    /// 1. creates a MintCap
    /// 2. configures the controller for this MintCap object
    /// 3. transfers the MintCap object to a minter
    /// 
    /// - Only callable by the master minter.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun configure_new_controller<T>(
        treasury: &mut Treasury<T>, 
        controller: address, 
        minter: address,
        ctx: &mut TxContext
    ) {
        let mint_cap = create_mint_cap(treasury, ctx);
        configure_controller(treasury, controller, object::id(&mint_cap), ctx);
        transfer::transfer(mint_cap, minter)
    }

    /// Removes a controller.
    /// - Only callable by the master minter.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun remove_controller<T>(
        treasury: &mut Treasury<T>, 
        controller: address, 
        ctx: &TxContext
    ) {
        treasury.assert_is_compatible();
        assert!(treasury.roles.master_minter() == ctx.sender(), ENotMasterMinter);
        assert!(treasury.is_controller(controller), ENotController);

        treasury.controllers.remove(controller);
        
        event::emit(ControllerRemoved<T> {
            controller
        });
    }

    /// Authorizes a MintCap object to mint and burn, and sets its allowance.
    /// - Only callable by the MintCap's controller.
    /// - Only callable when not paused.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun configure_minter<T>(
        treasury: &mut Treasury<T>, 
        deny_list: &DenyList, 
        new_allowance: u64, 
        ctx: &TxContext
    ) {
        treasury.assert_is_compatible();

        assert!(!is_paused<T>(deny_list), EPaused);

        let controller = ctx.sender();
        assert!(treasury.is_controller(controller), ENotController);

        let mint_cap_id = *get_mint_cap_id(treasury, controller).borrow();
        if (!treasury.mint_allowances.contains(mint_cap_id)) {
            let mut allowance = mint_allowance::new();
            allowance.set(new_allowance);
            treasury.mint_allowances.add(mint_cap_id, allowance);
        } else {
            treasury.mint_allowances.borrow_mut(mint_cap_id).set(new_allowance);
        };
        event::emit(MinterConfigured<T> {
            controller,
            mint_cap: mint_cap_id,
            allowance: new_allowance
        });
    }

    /// Increment allowance for a MintCap
    /// - Only callable by the MintCap's controller.
    /// - Only callable when not paused.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun increment_mint_allowance<T>(
        treasury: &mut Treasury<T>, 
        deny_list: &DenyList, 
        allowance_increment: u64, 
        ctx: &TxContext
    ) {
        treasury.assert_is_compatible();
        
        assert!(!is_paused<T>(deny_list), EPaused);
        assert!(allowance_increment > 0, EZeroAmount);

        let controller = ctx.sender();
        assert!(treasury.is_controller(controller), ENotController);

        let mint_cap_id = *get_mint_cap_id(treasury, controller).borrow();
        assert!(treasury.is_authorized_mint_cap(mint_cap_id), EUnauthorizedMintCap);

        treasury.mint_allowances.borrow_mut(mint_cap_id).increase(allowance_increment);
        let new_allowance = treasury.mint_allowances.borrow(mint_cap_id).value();

        event::emit(MinterAllowanceIncremented<T> {
            controller,
            mint_cap: mint_cap_id,
            allowance_increment,
            new_allowance,
        });
    }

    /// Deauthorizes a MintCap object.
    /// - Only callable by the MintCap's controller.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun remove_minter<T>(
        treasury: &mut Treasury<T>, 
        ctx: &TxContext
    ) {
        treasury.assert_is_compatible();

        let controller = ctx.sender();
        assert!(treasury.is_controller(controller), ENotController);

        let mint_cap_id = *get_mint_cap_id(treasury, controller).borrow();
        let mint_allowance = treasury.mint_allowances.remove(mint_cap_id);
        mint_allowance.destroy();
        event::emit(MinterRemoved<T> {
            controller,
            mint_cap: mint_cap_id
        });
    }
    
    /// Mints a Coin object with a specified amount (limited to the MintCap's allowance)
    /// to a recipient address, increasing the total supply.
    /// - Only callable by a minter.
    /// - Only callable when not paused.
    /// - Only callable if minter is not blocklisted.
    /// - Only callable if recipient is not blocklisted.
    /// - Only callable if the Treasury object is compatible with this package.
    public fun mint<T>(
        treasury: &mut Treasury<T>, 
        mint_cap: &MintCap<T>, 
        deny_list: &DenyList, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext
    ) {
        treasury.assert_is_compatible();

        assert!(!is_paused<T>(deny_list), EPaused);
        assert!(!is_blocklisted<T>(deny_list, ctx.sender()), EDeniedAddress);
        assert!(!is_blocklisted<T>(deny_list, recipient), EDeniedAddress);
        let mint_cap_id = object::id(mint_cap);
        assert!(treasury.is_authorized_mint_cap(mint_cap_id), EUnauthorizedMintCap);
        assert!(amount > 0, EZeroAmount);

        let mint_allowance = treasury.mint_allowances.borrow_mut(mint_cap_id);
        assert!(mint_allowance.value() >= amount, EInsufficientAllowance);

        mint_allowance.decrease(amount);

        treasury.borrow_treasury_cap_mut().mint_and_transfer(amount, recipient, ctx);
        
        event::emit(Mint<T> { 
            mint_cap: mint_cap_id, 
            recipient, 
            amount, 
        });
    }

    /// Burns a Coin object, decreasing the total supply.
    /// - Only callable by a minter.
    /// - Only callable when not paused.
    /// - Only callable if minter is not blocklisted.
    /// - Only callable if the Treasury object is compatible with this package.
    public fun burn<T>(
        treasury: &mut Treasury<T>, 
        mint_cap: &MintCap<T>, 
        deny_list: &DenyList, 
        coin: Coin<T>,
        ctx: &TxContext
    ) {
        treasury.assert_is_compatible();

        assert!(!is_paused<T>(deny_list), EPaused);
        assert!(!is_blocklisted<T>(deny_list, ctx.sender()), EDeniedAddress);
        let mint_cap_id = object::id(mint_cap);
        assert!(treasury.is_authorized_mint_cap(mint_cap_id), EUnauthorizedMintCap);

        let amount = coin.value();
        assert!(amount > 0, EZeroAmount);

        treasury.borrow_treasury_cap_mut().burn(coin);
        event::emit(Burn<T> {
            mint_cap: mint_cap_id,
            amount
        });
    }

    /// Blocklists an address.
    /// - Only callable by the blocklister.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun blocklist<T>(
        treasury: &mut Treasury<T>,
        deny_list: &mut DenyList,
        addr: address,
        ctx: &mut TxContext
    ) {
        treasury.assert_is_compatible();
        assert!(treasury.roles.blocklister() == ctx.sender(), ENotBlocklister);

        if (!is_blocklisted<T>(deny_list, addr)) {
            coin::deny_list_v2_add<T>(deny_list, treasury.borrow_deny_cap_mut(), addr, ctx);
        };
        event::emit(Blocklisted<T> {
            `address`: addr
        })
    }

    /// Unblocklists an address.
    /// - Only callable by the blocklister.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun unblocklist<T>(
        treasury: &mut Treasury<T>,
        deny_list: &mut DenyList,
        addr: address,
        ctx: &mut TxContext
    ) {
        treasury.assert_is_compatible();
        assert!(treasury.roles.blocklister() == ctx.sender(), ENotBlocklister);

        if (is_blocklisted<T>(deny_list, addr)) {
            coin::deny_list_v2_remove<T>(deny_list, treasury.borrow_deny_cap_mut(), addr, ctx);
        };
        event::emit(Unblocklisted<T> {
            `address`: addr
        })
    }

    /// Triggers stopped state; pause all transfers.
    /// - Only callable by the pauser.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun pause<T>(
        treasury: &mut Treasury<T>, 
        deny_list: &mut DenyList,
        ctx: &mut TxContext
    ) {
        treasury.assert_is_compatible();

        assert!(treasury.roles.pauser() == ctx.sender(), ENotPauser);
        let deny_cap = treasury.borrow_deny_cap_mut();

        if (!is_paused<T>(deny_list)) {
            coin::deny_list_v2_enable_global_pause(deny_list, deny_cap, ctx);
        };
        event::emit(Pause<T> {});
    }

    /// Restores normal state; unpause all transfers.
    /// - Only callable by the pauser.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun unpause<T>(
        treasury: &mut Treasury<T>, 
        deny_list: &mut DenyList,
        ctx: &mut TxContext
    ) {
        treasury.assert_is_compatible();
        assert!(treasury.roles().pauser() == ctx.sender(), ENotPauser);
        let deny_cap = treasury.borrow_deny_cap_mut();

        if (is_paused<T>(deny_list)) {
            coin::deny_list_v2_disable_global_pause(deny_list, deny_cap, ctx);
        };
        event::emit(Unpause<T> {});
    }
   
    /// Returns an immutable reference of the TreasuryCap.
    fun borrow_treasury_cap<T>(treasury: &Treasury<T>): &TreasuryCap<T> {
        treasury.assert_treasury_cap_exists();
        dof::borrow(&treasury.id, TreasuryCapKey {})
    }

    /// Returns a mutable reference of the TreasuryCap.
    fun borrow_treasury_cap_mut<T>(treasury: &mut Treasury<T>): &mut TreasuryCap<T> {
        treasury.assert_treasury_cap_exists();
        dof::borrow_mut(&mut treasury.id, TreasuryCapKey {})
    }

    /// Returns a mutable reference of the DenyCap.
    fun borrow_deny_cap_mut<T>(treasury: &mut Treasury<T>): &mut DenyCapV2<T> {
        treasury.assert_deny_cap_exists();
        dof::borrow_mut(&mut treasury.id, DenyCapKey {})
    }

    /// Updates the CoinMetadata<T> object of the same type as the Treasury<T>.
    /// - Only callable by the metadata updater.
    /// - Only callable if the Treasury object is compatible with this package.
    entry fun update_metadata<T>(
        treasury: &Treasury<T>,
        metadata: &mut CoinMetadata<T>,
        name: string::String,
        symbol: ascii::String,
        description: string::String,
        icon_url: ascii::String,
        ctx: &TxContext
    ) {
        treasury.assert_is_compatible();
        assert!(treasury.roles.metadata_updater() == ctx.sender(), ENotMetadataUpdater);
        treasury.borrow_treasury_cap().update_name(metadata, name);
        treasury.borrow_treasury_cap().update_symbol(metadata, symbol);
        treasury.borrow_treasury_cap().update_description(metadata, description);
        treasury.borrow_treasury_cap().update_icon_url(metadata, icon_url);
        event::emit(MetadataUpdated<T> {
            name,
            symbol,
            description,
            icon_url
        })
    }

    /// Starts the migration process, making the Treasury object be
    /// additionally compatible with this package's version.
    entry fun start_migration<T>(treasury: &mut Treasury<T>, ctx: &TxContext) {
        treasury.roles.owner_role().assert_sender_is_active_role(ctx);
        assert!(treasury.compatible_versions.size() == 1, EMigrationStarted);

        let active_version = treasury.compatible_versions.keys()[0];
        assert!(active_version < version_control::current_version(), EObjectMigrated);

        treasury.compatible_versions.insert(version_control::current_version());
        
        event::emit(MigrationStarted<T> {
            compatible_versions: *treasury.compatible_versions.keys()
        });
    }

    /// Aborts the migration process, reverting the Treasury object's compatibility
    /// to the previous version.
    entry fun abort_migration<T>(treasury: &mut Treasury<T>, ctx: &TxContext) {
        treasury.roles.owner_role().assert_sender_is_active_role(ctx);
        assert!(treasury.compatible_versions.size() == 2, EMigrationNotStarted);

        let pending_version = max(
            treasury.compatible_versions.keys()[0],
            treasury.compatible_versions.keys()[1]
        );
        assert!(pending_version == version_control::current_version(), ENotPendingVersion);

        treasury.compatible_versions.remove(&pending_version);

        event::emit(MigrationAborted<T> {
            compatible_versions: *treasury.compatible_versions.keys()
        });
    }

    /// Completes the migration process, making the Treasury object be
    /// only compatible with this package's version.
    entry fun complete_migration<T>(treasury: &mut Treasury<T>, ctx: &TxContext) {
        treasury.roles.owner_role().assert_sender_is_active_role(ctx);
        assert!(treasury.compatible_versions.size() == 2, EMigrationNotStarted);

        let (version_a, version_b) = (treasury.compatible_versions.keys()[0], treasury.compatible_versions.keys()[1]);
        let (active_version, pending_version) = (min(version_a, version_b), max(version_a, version_b));

        assert!(pending_version == version_control::current_version(), ENotPendingVersion);

        treasury.compatible_versions.remove(&active_version);

        event::emit(MigrationCompleted<T> {
            compatible_versions: *treasury.compatible_versions.keys()
        });
    }

    // === Assertions ===
    
    /// [Package private] Asserts that the Treasury object 
    /// is compatible with the package's version.
    public(package) fun assert_is_compatible<T>(treasury: &Treasury<T>) {
        assert_object_version_is_compatible_with_package(treasury.compatible_versions);
    }

    // === Test Only ===

    #[test_only]
    public(package) fun get_controllers_for_testing<T>(treasury: &Treasury<T>): &Table<address, ID> {
        &treasury.controllers
    }

    #[test_only]
    public(package) fun get_mint_allowances_for_testing<T>(treasury: &Treasury<T>): &Table<ID, MintAllowance<T>> {
        &treasury.mint_allowances
    }

    #[test_only]
    public(package) fun get_deny_cap_for_testing<T>(treasury: &mut Treasury<T>): &mut DenyCapV2<T> {
        treasury.borrow_deny_cap_mut()
    }

    #[test_only]
    public(package) fun remove_treasury_cap_for_testing<T>(treasury: &mut Treasury<T>): TreasuryCap<T> {
        dof::remove(&mut treasury.id, TreasuryCapKey {})
    }

    #[test_only]
    public(package) fun remove_deny_cap_for_testing<T>(treasury: &mut Treasury<T>): DenyCapV2<T> {
        dof::remove(&mut treasury.id, DenyCapKey {})
    }

    #[test_only]
    public(package) fun create_mint_cap_for_testing<T>(ctx: &mut TxContext): MintCap<T> {
        MintCap { id: object::new(ctx) }
    }

    #[test_only]
    public(package) fun set_compatible_versions_for_testing<T>(treasury: &mut Treasury<T>, compatible_versions: VecSet<u64>) {
        treasury.compatible_versions = compatible_versions;
    }

    #[test_only]
    public(package) fun create_mint_cap_created_event<T>(mint_cap: ID): MintCapCreated<T> {
        MintCapCreated { mint_cap }
    }

    #[test_only]
    public(package) fun create_controller_configured_event<T>(controller: address, mint_cap: ID): ControllerConfigured<T> {
        ControllerConfigured { controller, mint_cap }
    }

    #[test_only]
    public(package) fun create_controller_removed_event<T>(controller: address): ControllerRemoved<T> {
        ControllerRemoved { controller }
    }

    #[test_only]
    public(package) fun create_minter_configured_event<T>(controller: address, mint_cap: ID, allowance: u64): MinterConfigured<T> {
        MinterConfigured { controller, mint_cap, allowance }
    }

    #[test_only]
    public(package) fun create_minter_allowance_incremented_event<T>(
        controller: address, 
        mint_cap: ID, 
        allowance_increment: u64, 
        new_allowance: u64
    ): MinterAllowanceIncremented<T> {
        MinterAllowanceIncremented { controller, mint_cap, allowance_increment, new_allowance }
    }

    #[test_only]
    public(package) fun create_minter_removed_event<T>(controller: address, mint_cap: ID): MinterRemoved<T> {
        MinterRemoved { controller, mint_cap }
    }

    #[test_only]
    public(package) fun create_mint_event<T>(mint_cap: ID, recipient: address, amount: u64): Mint<T> {
        Mint { mint_cap, recipient, amount }
    }

    #[test_only]
    public(package) fun create_burn_event<T>(mint_cap: ID, amount: u64): Burn<T> {
        Burn { mint_cap, amount }
    }

    #[test_only]
    public(package) fun create_blocklisted_event<T>(`address`: address): Blocklisted<T> {
        Blocklisted { `address` }
    }

    #[test_only]
    public(package) fun create_unblocklisted_event<T>(`address`: address): Unblocklisted<T> {
        Unblocklisted { `address` }
    }

    #[test_only]
    public(package) fun create_migration_started_event<T>(compatible_versions: vector<u64>): MigrationStarted<T> {
        MigrationStarted { compatible_versions }
    }

    #[test_only]
    public(package) fun create_migration_aborted_event<T>(compatible_versions: vector<u64>): MigrationAborted<T> {
        MigrationAborted { compatible_versions }
    }

    #[test_only]
    public(package) fun create_migration_completed_event<T>(compatible_versions: vector<u64>): MigrationCompleted<T> {
        MigrationCompleted { compatible_versions }
    }

    #[test_only]
    public(package) fun create_metadata_updated_event<T>(
        name: string::String,
        symbol: ascii::String,
        description: string::String,
        icon_url: ascii::String
    ): MetadataUpdated<T> {
        MetadataUpdated {
            name,
            symbol,
            description,
            icon_url
        }
    }
}

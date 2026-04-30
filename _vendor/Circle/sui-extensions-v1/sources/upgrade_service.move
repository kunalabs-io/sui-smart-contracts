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

module sui_extensions::upgrade_service {
    use sui::{
        address,
        dynamic_object_field as dof,
        event,
        package::{
            UpgradeTicket, 
            UpgradeReceipt,
            UpgradeCap
        },
        types::is_one_time_witness
    };
    use sui_extensions::two_step_role::{Self, TwoStepRole};
    use std::type_name;

    // === Errors ===

    const ENotOneTimeWitness: u64 = 0;
    const ETypeNotFromPackage: u64 = 1;  
    const EUpgradeCapDoesNotExist: u64 = 2;
    const EUpgradeCapExists: u64 = 3;

    // === Structs ===

    /// An `UpgradeService<T>` that stores an `UpgradeCap` and delegates access of
    /// the capability object to an `admin` address.
    /// 
    /// The type must be a One-Time Witness type that comes
    /// from the package that the `UpgradeCap` controls.
    public struct UpgradeService<phantom T> has key, store {
        id: UID,
        /// A mutable `TwoStepRole` representing the admin address that is
        /// able to perform upgrades using the `UpgradeCap` that this service custodies.
        admin: TwoStepRole<AdminRole<T>>
    }

    /// Key for retrieving the `UpgradeCap` stored in an `UpgradeService<T>` dynamic object field.
    public struct UpgradeCapKey has copy, store, drop {}

    /// Type used to specify which `TwoStepRole` the admin role corresponds to.
    public struct AdminRole<phantom T> has drop {}

    // === Events ===

    public struct UpgradeCapDeposited<phantom T> has copy, drop {
        upgrade_cap_id: ID
    }

    public struct UpgradeCapExtracted<phantom T> has copy, drop {
        upgrade_cap_id: ID
    }

    public struct UpgradeServiceDestroyed<phantom T> has copy, drop {}

    public struct AuthorizeUpgrade<phantom T> has copy, drop {
        package_id: ID,
        policy: u8
    }

    public struct CommitUpgrade<phantom T> has copy, drop {
        package_id: ID
    }

    // === View-only functions ===

    /// The ID of the package that the stored `UpgradeCap` authorizes upgrades for.
    /// Can be `0x0` if the cap cannot currently authorize an upgrade because there is 
    /// already a pending upgrade in the transaction. Otherwise guaranteed to be the 
    /// latest version of any given package.
    public fun upgrade_cap_package<T>(upgrade_service: &UpgradeService<T>): ID {
        upgrade_service.assert_upgrade_cap_exists();
        upgrade_service.borrow_upgrade_cap().package()
    }
    
    /// The most recent version of the package that the stored `UpgradeCap` manages,
    /// increments by one for each successfully applied upgrade.
    public fun upgrade_cap_version<T>(upgrade_service: &UpgradeService<T>): u64 {
        upgrade_service.assert_upgrade_cap_exists();
        upgrade_service.borrow_upgrade_cap().version()
    }
    
    /// The most permissive kind of upgrade currently supported by the stored `UpgradeCap`.
    public fun upgrade_cap_policy<T>(upgrade_service: &UpgradeService<T>): u8 {
        upgrade_service.assert_upgrade_cap_exists();
        upgrade_service.borrow_upgrade_cap().policy()
    }

    /// Gets the current admin address.
    public fun admin<T>(upgrade_service: &UpgradeService<T>): address {
        upgrade_service.admin.active_address()
    }

    /// Gets the pending admin address.
    public fun pending_admin<T>(upgrade_service: &UpgradeService<T>): Option<address> {
        upgrade_service.admin.pending_address()
    }

    // === Write functions ===

    /// Creates an `UpgradeService<T>` object, initializing the admin role to
    /// the predefined admin address.
    public fun new<T: drop>(witness: T, admin: address, ctx: &mut TxContext): (UpgradeService<T>, T) {
        assert!(is_one_time_witness<T>(&witness), ENotOneTimeWitness);
        let upgrade_service = UpgradeService<T> {
            id: object::new(ctx),
            admin: two_step_role::new(AdminRole<T> {}, admin)
        };
        (upgrade_service, witness)
    }

    /// Performs a one-time deposit of an `UpgradeCap` into an `UpgradeService<T>`.
    /// `UpgradeCap` must control the package that `T` is defined in.
    /// - Only callable if the `UpgradeCap` has not been used for an upgrade.
    entry fun deposit<T>(upgrade_service: &mut UpgradeService<T>, upgrade_cap: UpgradeCap) {
        let package_address_of_type = address::from_ascii_bytes(
            type_name::get_with_original_ids<T>().get_address().as_bytes()
        );
        let package_address_of_upgrade_cap = &upgrade_cap.package().to_address();
        assert!(package_address_of_type == package_address_of_upgrade_cap, ETypeNotFromPackage);

        upgrade_service.assert_upgrade_cap_does_not_exist();
        let upgrade_cap_id = object::id(&upgrade_cap);
        upgrade_service.add_upgrade_cap(upgrade_cap);

        event::emit(UpgradeCapDeposited<T> {
            upgrade_cap_id
        });
    }

    /// Extracts the stored `UpgradeCap` and transfers it to a recipient address.
    /// - Only callable by the admin.
    entry fun extract<T>(upgrade_service: &mut UpgradeService<T>, recipient: address, ctx: &TxContext) {
        upgrade_service.admin.assert_sender_is_active_role(ctx);
        upgrade_service.assert_upgrade_cap_exists();

        let upgrade_cap = remove_upgrade_cap(upgrade_service);
        let upgrade_cap_id = object::id(&upgrade_cap);

        transfer::public_transfer(upgrade_cap, recipient);

        event::emit(UpgradeCapExtracted<T> {
            upgrade_cap_id
        });
    }

    /// Permanently destroys the `UpgradeService<T>`.
    /// - Only callable by the admin.
    entry fun destroy_empty<T>(upgrade_service: UpgradeService<T>, ctx: &TxContext) {
        upgrade_service.admin.assert_sender_is_active_role(ctx);
        upgrade_service.assert_upgrade_cap_does_not_exist();

        let UpgradeService { id, admin } = upgrade_service;
        id.delete();
        admin.destroy();

        event::emit(UpgradeServiceDestroyed<T> {});
    }

    /// Start admin role transfer process.
    /// - Only callable by the admin.
    entry fun change_admin<T>(upgrade_service: &mut UpgradeService<T>, new_admin: address, ctx: &TxContext) {
        upgrade_service.admin.begin_role_transfer(new_admin, ctx)
    }

    /// Finalize admin role transfer process.
    /// - Only callable by the pending admin.
    entry fun accept_admin<T>(upgrade_service: &mut UpgradeService<T>, ctx: &TxContext) {
        upgrade_service.admin.accept_role(ctx)
    }

    /// Issues an `UpgradeTicket` that authorizes the upgrade to a package content with `digest`
    /// for the package that the stored `UpgradeCap` manages. 
    /// - Only callable by the admin.
    public fun authorize_upgrade<T>(
        upgrade_service: &mut UpgradeService<T>,
        policy: u8,
        digest: vector<u8>,
        ctx: &TxContext
    ): UpgradeTicket {
        upgrade_service.admin.assert_sender_is_active_role(ctx);
        upgrade_service.assert_upgrade_cap_exists();

        let package_id_before_authorization = upgrade_service.borrow_upgrade_cap().package();
        let upgrade_ticket = upgrade_service.borrow_upgrade_cap_mut().authorize(policy, digest);
        
        event::emit(AuthorizeUpgrade<T> { 
            package_id: package_id_before_authorization,
            policy
        });
        
        upgrade_ticket
    }

    /// Consumes an `UpgradeReceipt` to update the stored `UpgradeCap`, 
    /// finalizing the upgrade.
    /// - Only callable by the admin.
    public fun commit_upgrade<T>(
        upgrade_service: &mut UpgradeService<T>,
        receipt: UpgradeReceipt,
        ctx: &TxContext
    ) {
        upgrade_service.admin.assert_sender_is_active_role(ctx);
        upgrade_service.assert_upgrade_cap_exists();

        let new_package_id = receipt.package();
        upgrade_service.borrow_upgrade_cap_mut().commit(receipt);

        event::emit(CommitUpgrade<T> { 
            package_id: new_package_id
        });
    }

    // === Helper functions ===

    /// Stores an `UpgradeCap` in a dynamic object field on an `UpgradeService<T>`.
    fun add_upgrade_cap<T>(upgrade_service: &mut UpgradeService<T>, upgrade_cap: UpgradeCap) {
        dof::add(&mut upgrade_service.id, UpgradeCapKey {}, upgrade_cap);
    }

    /// Returns an immutable reference to the `UpgradeCap` stored in a `UpgradeService<T>`.
    fun borrow_upgrade_cap<T>(upgrade_service: &UpgradeService<T>): &UpgradeCap {
        dof::borrow(&upgrade_service.id, UpgradeCapKey {})
    }

    /// Returns a mutable reference to the `UpgradeCap` stored in a `UpgradeService<T>`.
    fun borrow_upgrade_cap_mut<T>(upgrade_service: &mut UpgradeService<T>): &mut UpgradeCap {
        dof::borrow_mut(&mut upgrade_service.id, UpgradeCapKey {})
    }

    /// Removes an `UpgradeCap` that is stored in an `UpgradeService<T>`
    fun remove_upgrade_cap<T>(upgrade_service: &mut UpgradeService<T>): UpgradeCap {
        dof::remove(&mut upgrade_service.id, UpgradeCapKey {})
    }

    /// Ensures that an `UpgradeCap` exists in an `UpgradeService<T>`.
    fun assert_upgrade_cap_exists<T>(upgrade_service: &UpgradeService<T>) {
        assert!(upgrade_service.exists_upgrade_cap(), EUpgradeCapDoesNotExist);
    }

    /// Ensures that an `UpgradeCap` does not exist in an `UpgradeService<T>`.
    fun assert_upgrade_cap_does_not_exist<T>(upgrade_service: &UpgradeService<T>) {
        assert!(!upgrade_service.exists_upgrade_cap(), EUpgradeCapExists);
    }

    /// Checks whether an `UpgradeCap` exists in an `UpgradeService<T>`.
    public(package) fun exists_upgrade_cap<T>(upgrade_service: &UpgradeService<T>): bool {
        dof::exists_with_type<_, UpgradeCap>(&upgrade_service.id, UpgradeCapKey {})
    }

    // === Test Only ===

    #[test_only]
    public(package) fun add_upgrade_cap_for_testing<T>(upgrade_service: &mut UpgradeService<T>, upgrade_cap: UpgradeCap) {
        add_upgrade_cap(upgrade_service, upgrade_cap)
    }

    #[test_only]
    public(package) fun borrow_upgrade_cap_for_testing<T>(upgrade_service: &UpgradeService<T>): &UpgradeCap {
        upgrade_service.borrow_upgrade_cap()
    }

    #[test_only]
    public(package) fun borrow_upgrade_cap_mut_for_testing<T>(upgrade_service: &mut UpgradeService<T>): &mut UpgradeCap {
        upgrade_service.borrow_upgrade_cap_mut()
    }

    #[test_only]
    public(package) fun create_upgrade_cap_deposited_event<T>(upgrade_cap_id: ID): UpgradeCapDeposited<T> {
        UpgradeCapDeposited { upgrade_cap_id }
    }

    #[test_only]
    public(package) fun create_upgrade_cap_extracted_event<T>(upgrade_cap_id: ID): UpgradeCapExtracted<T> {
        UpgradeCapExtracted { upgrade_cap_id }
    }

    #[test_only]    
    public(package) fun create_authorize_upgrade_event<T>(package_id: ID, policy: u8): AuthorizeUpgrade<T> {
        AuthorizeUpgrade { package_id, policy }
    }

    #[test_only]    
    public(package) fun create_commit_upgrade_event<T>(package_id: ID): CommitUpgrade<T> {
        CommitUpgrade { package_id }
    }
}

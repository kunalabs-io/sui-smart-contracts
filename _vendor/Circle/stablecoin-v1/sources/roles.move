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

module stablecoin::roles {
    use sui::bag::{Self, Bag};
    use sui::event;
    use sui_extensions::two_step_role::{Self, TwoStepRole};

    // === Structs ===

    public struct Roles<phantom T> has store {
        /// A bag that maintains the mapping of privileged roles and their addresses.
        /// Keys are structs that are suffixed with _Key.
        /// Values are either addresses or objects containing more complex logic.
        data: Bag
    }

    /// Type used to specify which TwoStepRole the owner role corresponds to.
    public struct OwnerRole<phantom T> has drop {}

    /// Key used to map to the mutable TwoStepRole of the owner EOA
    public struct OwnerKey {} has copy, store, drop;
    /// Key used to map to the mutable address of the master minter EOA, controlled by owner
    public struct MasterMinterKey {} has copy, store, drop;
    /// Key used to map to the address of the blocklister EOA, controlled by owner
    public struct BlocklisterKey {} has copy, store, drop;
    /// Key used to map to the address of the pauser EOA, controlled by owner
    public struct PauserKey {} has copy, store, drop;
    /// Key used to map to the address of the metadata updater EOA, controlled by owner
    public struct MetadataUpdaterKey {} has copy, store, drop;

    // === Events ===

    public struct MasterMinterChanged<phantom T> has copy, drop {
        old_master_minter: address,
        new_master_minter: address,
    }

    public struct BlocklisterChanged<phantom T> has copy, drop {
        old_blocklister: address,
        new_blocklister: address,
    }

    public struct PauserChanged<phantom T> has copy, drop {
        old_pauser: address,
        new_pauser: address,
    }

    public struct MetadataUpdaterChanged<phantom T> has copy, drop {
        old_metadata_updater: address,
        new_metadata_updater: address,
    }

    // === View-only functions ===

    /// [Package private] Gets a mutable reference to the owner's TwoStepRole object.
    public(package) fun owner_role_mut<T>(roles: &mut Roles<T>): &mut TwoStepRole<OwnerRole<T>> {
        roles.data.borrow_mut(OwnerKey {})
    }

    /// [Package private] Gets an immutable reference to the owner's TwoStepRole object.
    public(package) fun owner_role<T>(roles: &Roles<T>): &TwoStepRole<OwnerRole<T>> {
        roles.data.borrow(OwnerKey {})
    }
    
    /// Gets the current owner address.
    public fun owner<T>(roles: &Roles<T>): address {
        roles.owner_role().active_address()
    }

    /// Gets the pending owner address.
    public fun pending_owner<T>(roles: &Roles<T>): Option<address> {
        roles.owner_role().pending_address()
    }

    /// Gets the master minter address.
    public fun master_minter<T>(roles: &Roles<T>): address {
        *roles.data.borrow(MasterMinterKey {})
    }

    /// Gets the blocklister address.
    public fun blocklister<T>(roles: &Roles<T>): address {
        *roles.data.borrow(BlocklisterKey {})
    }

    /// Gets the pauser address.
    public fun pauser<T>(roles: &Roles<T>): address {
        *roles.data.borrow(PauserKey {})
    }

    /// Gets the metadata updater address.
    public fun metadata_updater<T>(roles: &Roles<T>): address {
        *roles.data.borrow(MetadataUpdaterKey {})
    }

    // === Write functions ===

    /// [Package private] Creates and initializes a Roles object.
    public(package) fun new<T>(
        owner: address, 
        master_minter: address,
        blocklister: address, 
        pauser: address,
        metadata_updater: address,
        ctx: &mut TxContext,
    ): Roles<T> {
        let mut data = bag::new(ctx);
        data.add(OwnerKey {}, two_step_role::new(OwnerRole<T> {}, owner));
        data.add(MasterMinterKey {}, master_minter);
        data.add(BlocklisterKey {}, blocklister);
        data.add(PauserKey {}, pauser);
        data.add(MetadataUpdaterKey {}, metadata_updater);
        Roles {
            data
        }
    }

    /// [Package private] Change the master minter address.
    /// - Only callable by the owner.
    public(package) fun update_master_minter<T>(roles: &mut Roles<T>, new_master_minter: address, ctx: &TxContext) {
        roles.owner_role().assert_sender_is_active_role(ctx);

        let old_master_minter = roles.update_address(MasterMinterKey {}, new_master_minter);

        event::emit(MasterMinterChanged<T> { 
            old_master_minter, 
            new_master_minter 
        });
    }

    /// [Package private] Change the blocklister address.
    /// - Only callable by the owner.
    public(package) fun update_blocklister<T>(roles: &mut Roles<T>, new_blocklister: address, ctx: &TxContext) {
        roles.owner_role().assert_sender_is_active_role(ctx);

        let old_blocklister = roles.update_address(BlocklisterKey {}, new_blocklister);

        event::emit(BlocklisterChanged<T> {
            old_blocklister,
            new_blocklister
        });
    }

    /// [Package private] Change the pauser address.
    /// - Only callable by the owner.
    public(package) fun update_pauser<T>(roles: &mut Roles<T>, new_pauser: address, ctx: &TxContext) {
        roles.owner_role().assert_sender_is_active_role(ctx);

        let old_pauser = roles.update_address(PauserKey {}, new_pauser);

        event::emit(PauserChanged<T> {
            old_pauser,
            new_pauser
        });
    }

    /// [Package private] Change the metadata updater address.
    /// - Only callable by the owner.
    public(package) fun update_metadata_updater<T>(roles: &mut Roles<T>, new_metadata_updater: address, ctx: &TxContext) {
        roles.owner_role().assert_sender_is_active_role(ctx);

        let old_metadata_updater = roles.update_address(MetadataUpdaterKey {}, new_metadata_updater);

        event::emit(MetadataUpdaterChanged<T> {
            old_metadata_updater,
            new_metadata_updater
        });
    }

    /// Updates an existing simple address role and returns the previously set address.
    /// Fails if the key does not exist, or if the previously set value is not an address.
    fun update_address<T, K: copy + drop + store>(roles: &mut Roles<T>, key: K, new_address: address): address {
        let old_address = roles.data.remove(key);
        roles.data.add(key, new_address);
        old_address
    }

    // === Test Only ===

    #[test_only]
    public(package) fun create_master_minter_changed_event<T>(old_master_minter: address, new_master_minter: address): MasterMinterChanged<T> {
        MasterMinterChanged { old_master_minter, new_master_minter }
    }

    #[test_only]
    public(package) fun create_blocklister_changed_event<T>(old_blocklister: address, new_blocklister: address): BlocklisterChanged<T> {
        BlocklisterChanged { old_blocklister, new_blocklister }
    }

    #[test_only]
    public(package) fun create_pauser_changed_event<T>(old_pauser: address, new_pauser: address): PauserChanged<T> {
        PauserChanged { old_pauser, new_pauser }
    }

    #[test_only]
    public(package) fun create_metadata_updater_changed_event<T>(old_metadata_updater: address, new_metadata_updater: address): MetadataUpdaterChanged<T> {
        MetadataUpdaterChanged { old_metadata_updater, new_metadata_updater }
    }
}

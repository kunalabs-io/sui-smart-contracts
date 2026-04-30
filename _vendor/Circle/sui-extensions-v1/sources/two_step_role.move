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

/// Module containing basic role management functionality, 
/// including a two-step transfer process.
/// This module controls the role via address storage (as opposed
/// to using Capabilities) for cases when using Capabilities are not desired.
/// The two-step transfer process ensures the role is never transferred to an 
/// inaccesible address.
/// If access to the active_address EOA is lost, this role can not be transferred.
/// 
/// Inspired by OpenZeppelin's Ownable2Step in Solidity: 
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol.
module sui_extensions::two_step_role {
    use sui::event;

    // === Errors ===

    const ESenderNotActiveRole: u64 = 0;
    const EPendingAddressNotSet: u64 = 1;
    const ESenderNotPendingAddress: u64 = 2;

    // === Structs ===

    public struct TwoStepRole<phantom T> has store {
        active_address: address,
        pending_address: Option<address>
    }

    // === Events ===

    public struct RoleTransferStarted<phantom T> has copy, drop {
        old_address: address,
        new_address: address,
    }

    public struct RoleTransferred<phantom T> has copy, drop {
        old_address: address,
        new_address: address,
    }

    // === View-only functions ===

    /// Gets the active address of the TwoStepRole.
    public fun active_address<T>(role: &TwoStepRole<T>): address {
        role.active_address
    }

    /// Gets the optional, pending address of the TwoStepRole. May be
    /// empty if there is no ongoing role transfer.
    public fun pending_address<T>(role: &TwoStepRole<T>): Option<address> {
        role.pending_address
    }

    /// Asserts that the transaction sender EOA is the active_address stored on the Role.
    /// Aborts with error otherwise.
    public fun assert_sender_is_active_role<T>(role: &TwoStepRole<T>, ctx: &TxContext) {
        assert!(role.active_address == ctx.sender(), ESenderNotActiveRole);
    }

    // === Write functions ===

    /// Creates and initializes a TwoStepRole object.
    public fun new<T: drop>(_witness: T, active_address: address): TwoStepRole<T> {
        TwoStepRole<T> {
            active_address,
            pending_address: option::none(),
        }
    }

    /// Start the role transfer. Must be followed by an accept_role call by the new_address EOA.
    /// A transfer can be aborted by starting another role transfer process
    /// to the current active address and accepting the role.
    /// 
    /// - Only callable by the active address.
    public fun begin_role_transfer<T>(
        role: &mut TwoStepRole<T>,
        new_address: address,
        ctx: &TxContext
    ) {
        role.assert_sender_is_active_role(ctx);

        role.pending_address = option::some(new_address);

        event::emit(RoleTransferStarted<T> {
            old_address: role.active_address,
            new_address,
        });
    }

    /// Complete the role transfer by accepting the role.
    /// - Only callable by the pending address.
    public fun accept_role<T>(
        role: &mut TwoStepRole<T>,
        ctx: &TxContext
    ) {
        assert!(role.pending_address.is_some(), EPendingAddressNotSet);
        assert!(role.pending_address.contains(&ctx.sender()), ESenderNotPendingAddress);

        let old_address = role.active_address;
        role.active_address = role.pending_address.extract();

        event::emit(RoleTransferred<T> {
            old_address,
            new_address: role.active_address
        });
    }

    /// Destroys a TwoStepRole object.
    public fun destroy<T>(role: TwoStepRole<T>) {
        let TwoStepRole<T> { active_address: _, pending_address: _ } = role;
    }

    // === Test Only ===

    #[test_only]
    public fun create_role_transfer_started_event<T>(old_address: address, new_address: address): RoleTransferStarted<T> {
        RoleTransferStarted { old_address, new_address }
    }

    #[test_only]
    public fun create_role_transferred_event<T>(old_address: address, new_address: address): RoleTransferred<T> {
        RoleTransferred { old_address, new_address }
    }
}

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

#[test_only]
module sui_extensions::two_step_role_tests {
    use sui::{
        event,
        test_scenario::{Self, Scenario},
        test_utils::{assert_eq}
    };
    use sui_extensions::{
        test_utils::last_event_by_type,
        two_step_role::{Self, TwoStepRole}
    };

    public struct TWO_STEP_ROLE_TESTS has drop {}

    // Test addresses
    const ADMIN: address = @0xA;
    const NEW_ADMIN: address = @0xB;
    const INVALID_ADMIN: address = @0xC;

    // === Helper functions ===

    fun setup(): (Scenario, TwoStepRole<TWO_STEP_ROLE_TESTS>) {
        let scenario = test_scenario::begin(ADMIN);
        let role = two_step_role::new(TWO_STEP_ROLE_TESTS {}, ADMIN);
        (scenario, role)
    }

    fun test_begin_role_transfer(new_address: address, role: &mut TwoStepRole<TWO_STEP_ROLE_TESTS>, scenario: &mut Scenario) {
        let active_address = role.active_address();
        role.begin_role_transfer(new_address, scenario.ctx());

        assert_eq(role.active_address(), active_address);
        assert_eq(role.pending_address(), option::some(new_address));

        let expected_event = two_step_role::create_role_transfer_started_event<TWO_STEP_ROLE_TESTS>(active_address, new_address);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);
    }

    fun test_accept_role(role: &mut TwoStepRole<TWO_STEP_ROLE_TESTS>, scenario: &mut Scenario) {
        let old_active_address = role.active_address();
        let new_active_address = role.pending_address();
        role.accept_role(scenario.ctx());

        assert_eq(role.active_address(), *new_active_address.borrow());
        assert_eq(role.pending_address().is_none(), true);

        let expected_event = two_step_role::create_role_transferred_event<TWO_STEP_ROLE_TESTS>(
            old_active_address, *new_active_address.borrow()
        );
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);
    }

    // === Tests ===

    // new tests

    #[test]
    fun new__should_succeed() {
        let (scenario, role) = setup();
        assert_eq(role.active_address(), ADMIN);
        assert_eq(role.pending_address(), option::none());

        role.destroy();
        scenario.end();
    }

    // begin_role_transfer tests

    #[test]
    fun begin_role_transfer__should_succeed() {
        let (mut scenario, mut role) = setup();
        
        scenario.next_tx(ADMIN);
        test_begin_role_transfer(NEW_ADMIN, &mut role, &mut scenario);

        role.destroy();
        scenario.end();
    }

    #[test]
    fun begin_role_transfer__should_succeed_if_pending_address_is_set() {
        let (mut scenario, mut role) = setup();
        
        // Transfer to INVALID_ADMIN
        scenario.next_tx(ADMIN);
        test_begin_role_transfer(INVALID_ADMIN, &mut role,  &mut scenario);

         // Transfer to NEW_ADMIN before original transfer is accepted
        scenario.next_tx(ADMIN);
        test_begin_role_transfer(NEW_ADMIN, &mut role, &mut scenario);

        role.destroy();
        scenario.end();
    }

    #[test]
    fun begin_role_transfer__should_succeed_when_set_to_current_active_address() {
        let (mut scenario, mut role) = setup();
        
        // Transfer to current active address
        scenario.next_tx(ADMIN);
        test_begin_role_transfer(ADMIN, &mut role, &mut scenario);

        role.destroy();
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = two_step_role::ESenderNotActiveRole)]
    fun begin_role_transfer__should_fail_if_sender_is_not_active_address() {
        let (mut scenario, mut role) = setup();
        
        scenario.next_tx(INVALID_ADMIN);
        role.begin_role_transfer(NEW_ADMIN, scenario.ctx());
        
        role.destroy();
        scenario.end();
    }

    // accept_role tests

    #[test]
    fun accept_role__should_succeed() {
        let (mut scenario, mut role) = setup();

        scenario.next_tx(ADMIN);
        test_begin_role_transfer(NEW_ADMIN, &mut role, &mut scenario);

        scenario.next_tx(NEW_ADMIN);
        test_accept_role(&mut role, &mut scenario);
        
        role.destroy();
        scenario.end();
    }

    #[test]
    fun accept_role__should_succeed_if_pending_address_is_active_address() {
        let (mut scenario, mut role) = setup();

        scenario.next_tx(ADMIN);
        test_begin_role_transfer(ADMIN, &mut role, &mut scenario);
        
        scenario.next_tx(ADMIN);
        test_accept_role(&mut role, &mut scenario);

        role.destroy();
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = two_step_role::EPendingAddressNotSet)]
    fun accept_role__should_fail_if_pending_address_not_set() {
        let (mut scenario, mut role) = setup();

        scenario.next_tx(NEW_ADMIN);
        test_accept_role(&mut role, &mut scenario);

        role.destroy();
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = two_step_role::ESenderNotPendingAddress)]
    fun accept_role__should_fail_if_sender_is_not_pending_address() {
        let (mut scenario, mut role) = setup();

        scenario.next_tx(ADMIN);
        test_begin_role_transfer(NEW_ADMIN, &mut role, &mut scenario);

        scenario.next_tx(INVALID_ADMIN);
        test_accept_role(&mut role, &mut scenario);

        role.destroy();
        scenario.end();
    }

    // assert_sender_is_active_role tests

    #[test]
    fun assert_sender_is_active_role__should_succeed() {
        let (mut scenario, role) = setup();

        scenario.next_tx(ADMIN);
        role.assert_sender_is_active_role(scenario.ctx());

        role.destroy();
        scenario.end();
    }

    #[test]
    #[expected_failure]
    fun assert_sender_is_active_role__should_fail_if_sender_not_active_address() {
        let (mut scenario, role) = setup();

        scenario.next_tx(INVALID_ADMIN);
        role.assert_sender_is_active_role(scenario.ctx());
        
        role.destroy();
        scenario.end();
    }

}

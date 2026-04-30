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
module stablecoin::roles_tests {
    use sui::{
        event,
        test_scenario::{Self, Scenario},
        test_utils::assert_eq,
        test_utils::destroy,
    };
    use stablecoin::roles::{Self, Roles, OwnerRole};
    use sui_extensions::{
        two_step_role,
        test_utils::last_event_by_type
    };

    public struct ROLES_TEST has drop {}

    // test addresses
    const DEPLOYER: address = @0x0;
    const OWNER: address = @0x20;
    const BLOCKLISTER: address = @0x30;
    const PAUSER: address = @0x40;
    const RANDOM_ADDRESS: address = @0x50;
    const MASTER_MINTER: address = @0x60;
    const METADATA_UPDATER: address = @0x70;

    #[test]
    fun transfer_ownership_and_update_roles__should_succeed_and_pass_all_assertions() {
        let (mut scenario, mut roles) = setup();

        // transfer ownership to the DEPLOYER address
        scenario.next_tx(OWNER);
        test_transfer_ownership(DEPLOYER, &mut roles, &mut scenario);

        scenario.next_tx(DEPLOYER);
        test_accept_ownership(&mut roles, &mut scenario);

        // use the DEPLOYER address to modify the master minter, blocklister, pauser, and metadata updater
        scenario.next_tx(DEPLOYER);
        test_update_master_minter(MASTER_MINTER, &mut roles, &mut scenario);

        scenario.next_tx(DEPLOYER);
        test_update_blocklister(BLOCKLISTER, &mut roles, &mut scenario);

        scenario.next_tx(DEPLOYER);
        test_update_pauser(PAUSER, &mut roles, &mut scenario);

        scenario.next_tx(DEPLOYER);
        test_update_metadata_updater(METADATA_UPDATER, &mut roles, &mut scenario);

        scenario.end();
        destroy(roles);
    }

    #[test, expected_failure(abort_code = two_step_role::ESenderNotActiveRole)]
    fun update_master_minter__should_fail_if_not_sent_by_owner() {
        let (mut scenario, mut roles) = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_update_master_minter(RANDOM_ADDRESS, &mut roles, &mut scenario);

        scenario.end();
        destroy(roles);
    }

    #[test, expected_failure(abort_code = two_step_role::ESenderNotActiveRole)]
    fun update_blocklister__should_fail_if_not_sent_by_owner() {
        let (mut scenario, mut roles) = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_update_blocklister(RANDOM_ADDRESS, &mut roles, &mut scenario);

        scenario.end();
        destroy(roles);
    }

    #[test, expected_failure(abort_code = two_step_role::ESenderNotActiveRole)]
    fun update_pauser__should_fail_if_not_sent_by_owner() {
        let (mut scenario, mut roles) = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_update_pauser(RANDOM_ADDRESS, &mut roles, &mut scenario);

        scenario.end();
        destroy(roles);
    }

    #[test, expected_failure(abort_code = two_step_role::ESenderNotActiveRole)]
    fun update_metadata_updater__should_fail_if_not_sent_by_owner() {
        let (mut scenario, mut roles) = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_update_metadata_updater(RANDOM_ADDRESS, &mut roles, &mut scenario);

        scenario.end();
        destroy(roles);
    }

    // === Helpers ===

    /// Creates a Roles object and assigns all roles to OWNER
    fun setup(): (Scenario, Roles<ROLES_TEST>) {
        let mut scenario = test_scenario::begin(DEPLOYER);
        let roles = roles::new(OWNER, OWNER, OWNER, OWNER, OWNER, scenario.ctx());
        assert_eq(roles.owner(), OWNER);
        assert_eq(roles.pending_owner().is_none(), true);
        assert_eq(roles.master_minter(), OWNER);
        assert_eq(roles.pauser(), OWNER);
        assert_eq(roles.blocklister(), OWNER);

        (scenario, roles)
    }

    public(package) fun test_transfer_ownership<T>(new_owner: address, roles: &mut Roles<T>, scenario: &mut Scenario) {
        let old_owner = roles.owner();
        roles.owner_role_mut().begin_role_transfer(new_owner, scenario.ctx());
        assert_eq(roles.owner(), old_owner);    
        assert_eq(*roles.pending_owner().borrow(), new_owner);

        let expected_event = two_step_role::create_role_transfer_started_event<OwnerRole<T>>(
            old_owner, new_owner
        );
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);
    }

    public(package) fun test_accept_ownership<T>(roles: &mut Roles<T>, scenario: &mut Scenario) {
        let old_owner = roles.owner();
        let pending_owner = roles.pending_owner();
        roles.owner_role_mut().accept_role(scenario.ctx());
        assert_eq(roles.owner(), *pending_owner.borrow());
        assert_eq(roles.pending_owner().is_none(), true);

        let expected_event = two_step_role::create_role_transferred_event<OwnerRole<T>>(
            old_owner, *pending_owner.borrow()
        );
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);
    }

    public(package) fun test_update_master_minter<T>(new_master_minter: address, roles: &mut Roles<T>, scenario: &mut Scenario) {
        let old_master_minter = roles.master_minter();
        roles.update_master_minter(new_master_minter, scenario.ctx());
        assert_eq(roles.master_minter(), new_master_minter);

        let expected_event = roles::create_master_minter_changed_event<T>(old_master_minter, new_master_minter);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);
    }

    public(package) fun test_update_blocklister<T>(new_blocklister: address, roles: &mut Roles<T>, scenario: &mut Scenario) {
        let old_blocklister = roles.blocklister();
        roles.update_blocklister(new_blocklister, scenario.ctx());
        assert_eq(roles.blocklister(), new_blocklister);

        let expected_event = roles::create_blocklister_changed_event<T>(old_blocklister, new_blocklister);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);
    }

    public(package) fun test_update_pauser<T>(new_pauser: address, roles: &mut Roles<T>, scenario: &mut Scenario) {
        let old_pauser = roles.pauser();
        roles.update_pauser(new_pauser, scenario.ctx());
        assert_eq(roles.pauser(), new_pauser);

        let expected_event = roles::create_pauser_changed_event<T>(old_pauser, new_pauser);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);
    }

    public(package) fun test_update_metadata_updater<T>(new_metadata_updater: address, roles: &mut Roles<T>, scenario: &mut Scenario) {
        let old_metadata_updater = roles.metadata_updater();
        roles.update_metadata_updater(new_metadata_updater, scenario.ctx());
        assert_eq(roles.metadata_updater(), new_metadata_updater);

        let expected_event = roles::create_metadata_updater_changed_event<T>(old_metadata_updater, new_metadata_updater);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);
    }
}

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
module sui_extensions::upgrade_service_tests {
    use sui::{
        event,
        package::{Self, UpgradeTicket, UpgradeReceipt, UpgradeCap},
        test_scenario::{Self, Scenario},
        test_utils::{assert_eq, destroy, create_one_time_witness}
    };
    use sui_extensions::{
        upgrade_service::{Self, UpgradeService, AdminRole},
        test_utils::last_event_by_type,
        two_step_role
    };

    public struct UPGRADE_SERVICE_TESTS has drop {}
    public struct NOT_ONE_TIME_WITNESS has drop {}

    const ZERO_ADDRESS: address = @0x0;
    const DEPLOYER: address = @0x10;
    const UPGRADE_SERVICE_ADMIN: address = @0x20;
    const RANDOM_ADDRESS: address = @0x30;
    const UPGRADE_CAP_RECIPIENT: address = @0x40;
    
    const UPGRADE_CAP_PACKAGE_ID: address = @0x1000;
    const TEST_DIGEST: vector<u8> = vector[0, 1, 2];

    #[test, expected_failure(abort_code = ::sui_extensions::upgrade_service::ENotOneTimeWitness)]
    fun new__should_fail_if_type_is_not_one_time_witness() {   
        let mut scenario = test_scenario::begin(DEPLOYER);

        destroy(test_new(&mut scenario, NOT_ONE_TIME_WITNESS {}, UPGRADE_SERVICE_ADMIN));
        
        scenario.end();
    }

    #[test]
    fun new__should_succeed_and_pass_all_assertions() {   
        let mut scenario = test_scenario::begin(DEPLOYER);

        destroy(test_new(&mut scenario, create_one_time_witness<UPGRADE_SERVICE_TESTS>(), UPGRADE_SERVICE_ADMIN));
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::upgrade_service::ETypeNotFromPackage)]
    fun deposit__should_fail_if_type_is_not_from_package() {
        // Create an `UpgradeService<T>`.
        let mut scenario = test_scenario::begin(DEPLOYER);
        {
            let upgrade_service = test_new(&mut scenario, create_one_time_witness<UPGRADE_SERVICE_TESTS>(), UPGRADE_SERVICE_ADMIN);
            transfer::public_share_object(upgrade_service);
        };

        // Attempt to deposit an `UpgradeCap` that has a different package id from the package that
        // defines `UPGRADE_SERVICE_TESTS`, should fail.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        assert_eq(RANDOM_ADDRESS != @sui_extensions, true);
        let upgrade_cap_for_random_package = create_upgrade_cap(&mut scenario, RANDOM_ADDRESS.to_id());
        test_deposit<UPGRADE_SERVICE_TESTS>(&scenario, upgrade_cap_for_random_package);
        
        scenario.end();
    }
    
    #[test, expected_failure(abort_code = ::sui_extensions::upgrade_service::EUpgradeCapExists)]
    fun deposit__should_fail_if_upgrade_cap_exists() {
        // Create an `UpgradeService<T>`.
        let mut scenario = test_scenario::begin(DEPLOYER);
        {
            let upgrade_service = test_new(&mut scenario, create_one_time_witness<UPGRADE_SERVICE_TESTS>(), UPGRADE_SERVICE_ADMIN);
            transfer::public_share_object(upgrade_service);
        };

        // Force add an `UpgradeCap`. In practice, this is not possible.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        {
            let mut upgrade_service = scenario.take_shared<UpgradeService<UPGRADE_SERVICE_TESTS>>();

            let upgrade_cap = create_upgrade_cap(&mut scenario, @sui_extensions.to_id());
            upgrade_service.add_upgrade_cap_for_testing(upgrade_cap);

            test_scenario::return_shared(upgrade_service);
        };

        // Attempt to deposit an `UpgradeCap`, should fail.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        let upgrade_cap = create_upgrade_cap(&mut scenario, @sui_extensions.to_id());
        test_deposit<UPGRADE_SERVICE_TESTS>(&scenario, upgrade_cap);
        
        scenario.end();
    }

    #[test]
    fun deposit__should_succeed_and_pass_all_assertions() {
        // Create an `UpgradeService<T>`.
        let mut scenario = test_scenario::begin(DEPLOYER);
        {
            let upgrade_service = test_new(&mut scenario, create_one_time_witness<UPGRADE_SERVICE_TESTS>(), UPGRADE_SERVICE_ADMIN);
            transfer::public_share_object(upgrade_service);
        };

        // Deposit an `UpgradeCap`.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        let upgrade_cap = create_upgrade_cap(&mut scenario, @sui_extensions.to_id());
        test_deposit<UPGRADE_SERVICE_TESTS>(&scenario, upgrade_cap);
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::two_step_role::ESenderNotActiveRole)]
    fun extract__should_fail_if_sender_is_not_admin () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Random address attempts to extract the `UpgradeCap`, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_extract<UPGRADE_SERVICE_TESTS>(&mut scenario);
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::upgrade_service::EUpgradeCapDoesNotExist)]
    fun extract__should_fail_if_upgrade_cap_is_missing () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Extract the `UpgradeCap`.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_extract<UPGRADE_SERVICE_TESTS>(&mut scenario);

        // Extract the `UpgradeCap` again, should fail.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        {
            let mut upgrade_service = scenario.take_shared<UpgradeService<UPGRADE_SERVICE_TESTS>>();
            upgrade_service.extract(UPGRADE_CAP_RECIPIENT, scenario.ctx());
            test_scenario::return_shared(upgrade_service);
        };
        
        scenario.end();
    }

    #[test]
    fun extract__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup_with_shared_upgrade_service();

        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_extract<UPGRADE_SERVICE_TESTS>(&mut scenario);
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::two_step_role::ESenderNotActiveRole)]
    fun destroy_empty__should_fail_if_sender_is_not_admin () {
        let mut scenario = setup_with_shared_upgrade_service();

        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_extract<UPGRADE_SERVICE_TESTS>(&mut scenario);

        // Random address attempts to destroy the `UpgradeService<T>`, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_destroy_empty<UPGRADE_SERVICE_TESTS>(&mut scenario);
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::upgrade_service::EUpgradeCapExists)]
    fun destroy_empty__should_fail_if_upgrade_cap_exists () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Attempt to destroy the `UpgradeService<T>` when the `UpgradeCap` has not
        // been extracted, should fail.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_destroy_empty<UPGRADE_SERVICE_TESTS>(&mut scenario);
        
        scenario.end();
    }
    
    #[test]
    fun destroy_empty__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup_with_shared_upgrade_service();

        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_extract<UPGRADE_SERVICE_TESTS>(&mut scenario);

        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_destroy_empty<UPGRADE_SERVICE_TESTS>(&mut scenario);
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::two_step_role::ESenderNotActiveRole)]
    fun change_admin__should_fail_if_sender_is_not_admin () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Random address attempts to change the admin, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_change_admin<UPGRADE_SERVICE_TESTS>(&mut scenario, RANDOM_ADDRESS);
        
        scenario.end();
    }

    #[test]
    fun change_admin__should_succeed_and_pass_all_assertions () {
        let mut scenario = setup_with_shared_upgrade_service();

        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_change_admin<UPGRADE_SERVICE_TESTS>(&mut scenario, RANDOM_ADDRESS);
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::two_step_role::ESenderNotPendingAddress)]
    fun accept_admin__should_fail_if_sender_is_not_pending_admin () {
        let mut scenario = setup_with_shared_upgrade_service();

        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_change_admin<UPGRADE_SERVICE_TESTS>(&mut scenario, UPGRADE_SERVICE_ADMIN);

        // Random address attempts to accept the admin, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_accept_admin<UPGRADE_SERVICE_TESTS>(&mut scenario);
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::two_step_role::EPendingAddressNotSet)]
    fun accept_admin__should_fail_if_pending_admin_is_not_set () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Attempt to accept admin when the pending admin has not been set, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_accept_admin<UPGRADE_SERVICE_TESTS>(&mut scenario);
        
        scenario.end();
    }

    #[test]
    fun accept_admin__should_succeed_and_pass_all_assertions () {
        let mut scenario = setup_with_shared_upgrade_service();

        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_change_admin<UPGRADE_SERVICE_TESTS>(&mut scenario, RANDOM_ADDRESS);

        scenario.next_tx(RANDOM_ADDRESS);
        test_accept_admin<UPGRADE_SERVICE_TESTS>(&mut scenario);
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::two_step_role::ESenderNotActiveRole)]
    fun authorize_upgrade__should_fail_if_sender_is_not_admin () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Random address attempts to authorize an upgrade, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        destroy(test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        ));
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::upgrade_service::EUpgradeCapDoesNotExist)]
    fun authorize_upgrade__should_fail_if_upgrade_cap_is_missing () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Extract the `UpgradeCap`.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_extract<UPGRADE_SERVICE_TESTS>(&mut scenario);

        // Attempt to authorize an upgrade after the `UpgradeCap` has been extracted, should fail.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        destroy(test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        ));
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui::package::EAlreadyAuthorized)]
    fun authorize_upgrade__should_fail_if_upgrade_cap_has_authorized_an_upgrade () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Authorize an upgrade.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        destroy(test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        ));

        // Attempt to authorize another upgrade, should fail as there is a pending
        // upgrade.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        destroy(test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        ));
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui::package::ETooPermissive)]
    fun authorize_upgrade__should_fail_if_upgrade_is_too_permissive () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Restrict the underlying `UpgradeCap`'s upgrade policy.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        {
            let mut upgrade_service = scenario.take_shared<UpgradeService<UPGRADE_SERVICE_TESTS>>();
            upgrade_service.borrow_upgrade_cap_mut_for_testing().only_dep_upgrades();
            test_scenario::return_shared(upgrade_service);
        };

        // Attempt to authorize an upgrade that has a more permissive policy, should fail.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        destroy(test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        ));
        
        scenario.end();
    }

    #[test]
    fun authorize_upgrade__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup_with_shared_upgrade_service();

        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        destroy(test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        ));
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::two_step_role::ESenderNotActiveRole)]
    fun commit_upgrade__should_fail_if_sender_is_not_admin () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Authorize an upgrade with the `UpgradeCap`.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        let upgrade_ticket = test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        );

        // Perform the upgrade with the authorization ticket.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        let upgrade_receipt = package::test_upgrade(upgrade_ticket);

        // Random address attempts to commit an upgrade, should fail.
        // In practice, this is not possible as the `UpgradeReceipt` must
        // have been derived from an authorize_upgrade triggered by the 
        // admin.
        scenario.next_tx(RANDOM_ADDRESS);
        test_commit_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            upgrade_receipt
        );
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui_extensions::upgrade_service::EUpgradeCapDoesNotExist)]
    fun commit_upgrade__should_fail_if_upgrade_cap_is_missing () {
        let mut scenario = setup_with_shared_upgrade_service();
        
        // Authorize an upgrade with the `UpgradeCap`.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        let upgrade_ticket = test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        );

        // Perform the upgrade with the authorization ticket.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        let upgrade_receipt = package::test_upgrade(upgrade_ticket);

        // Extract the `UpgradeCap`.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_extract<UPGRADE_SERVICE_TESTS>(&mut scenario);

        // Attempt to commit the upgrade after the `UpgradeCap` has been extracted, should fail.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_commit_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            upgrade_receipt
        );
        
        scenario.end();
    }

    #[test, expected_failure(abort_code = ::sui::package::EWrongUpgradeCap)]
    fun commit_upgrade__should_fail_if_upgrade_cap_and_receipt_are_mismatched () {
        let mut scenario = setup_with_shared_upgrade_service();

        // Perform an upgrade cycle for a random package.
        scenario.next_tx(DEPLOYER);
        let mut upgrade_cap_for_random_package = create_upgrade_cap(&mut scenario, RANDOM_ADDRESS.to_id());
        let upgrade_ticket_for_random_package = upgrade_cap_for_random_package.authorize(
            package::compatible_policy(),
            TEST_DIGEST
        );
        let upgrade_receipt_for_random_package = package::test_upgrade(upgrade_ticket_for_random_package);
        destroy(upgrade_cap_for_random_package);

        // Attempt to commit the upgrade using an `UpgradeReceipt` that did not derive from the `UpgradeCap`, should fail.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_commit_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            upgrade_receipt_for_random_package
        );
        
        scenario.end();
    }

    #[test]
    fun commit_upgrade__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup_with_shared_upgrade_service();
        
        // Authorize an upgrade with the `UpgradeCap`.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        let upgrade_ticket = test_authorize_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            package::compatible_policy(),
            TEST_DIGEST
        );

        // Perform the upgrade with the authorization ticket.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        let upgrade_receipt = package::test_upgrade(upgrade_ticket);

        // Commit the results of the upgrade to the `UpgradeCap`.
        scenario.next_tx(UPGRADE_SERVICE_ADMIN);
        test_commit_upgrade<UPGRADE_SERVICE_TESTS>(
            &mut scenario,
            upgrade_receipt
        );
        
        scenario.end();
    }

    // === Helpers ===

    #[allow(lint(share_owned))]
    fun setup_with_shared_upgrade_service(): Scenario {
        // Here, the package id that `UpgradeCap` controls does not match the id of the package 
        // that defines `UPGRADE_SERVICE_TESTS`. This is intentional as authorizing an upgrade
        // requires that the `UpgradeCap`'s package is a non-0x0 address. Conversely, the package
        // id of the test type `UPGRADE_SERVICE_TESTS` depends on the address set as the 
        // package's alias in the package manifest file, and for operational purposes, should be 
        // able to set to 0x0.
        // 
        // This is a workaround to make the test environment isolated.
        let mut scenario = test_scenario::begin(DEPLOYER);
        
        assert_eq(UPGRADE_CAP_PACKAGE_ID != @sui_extensions, true);
        
        let mut upgrade_service = test_new(&mut scenario, create_one_time_witness<UPGRADE_SERVICE_TESTS>(), UPGRADE_SERVICE_ADMIN);
        let upgrade_cap = create_upgrade_cap(&mut scenario, UPGRADE_CAP_PACKAGE_ID.to_id());
        upgrade_service.add_upgrade_cap_for_testing(upgrade_cap);

        transfer::public_share_object(upgrade_service);

        scenario
    }

    fun test_new<T: drop>(scenario: &mut Scenario, witness: T, admin: address): UpgradeService<T> {
        let (upgrade_service, _) = upgrade_service::new<T>(witness, admin, scenario.ctx());

        assert_eq(upgrade_service.exists_upgrade_cap(), false);
        assert_eq(upgrade_service.admin(), admin);
        assert_eq(upgrade_service.pending_admin(), option::none());

        upgrade_service
    }

    fun test_deposit<T>(scenario: &Scenario, upgrade_cap: UpgradeCap) {
        let mut upgrade_service = scenario.take_shared<UpgradeService<T>>();

        let expected_upgrade_cap_id = object::id(&upgrade_cap);
        let expected_upgrade_cap_package = upgrade_cap.package();
        let expected_upgrade_cap_version = upgrade_cap.version();
        let expected_upgrade_cap_policy = upgrade_cap.policy();
        
        upgrade_service.deposit(upgrade_cap);

        assert_eq(upgrade_service.exists_upgrade_cap(), true);
        assert_eq(object::id(upgrade_service.borrow_upgrade_cap_for_testing()), expected_upgrade_cap_id);
        check_upgrade_service_and_upgrade_cap(
            &upgrade_service,
            expected_upgrade_cap_package,
            expected_upgrade_cap_version,
            expected_upgrade_cap_policy
        );

        // Ensure that the correct event was emitted.
        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(),
            upgrade_service::create_upgrade_cap_deposited_event<T>(expected_upgrade_cap_id)
        );

        test_scenario::return_shared(upgrade_service);
    }

    fun test_extract<T>(scenario: &mut Scenario) {
        let mut upgrade_service = scenario.take_shared<UpgradeService<T>>();

        let prev_upgrade_cap_id = object::id(upgrade_service.borrow_upgrade_cap_for_testing());
        let prev_upgrade_cap_package = upgrade_service.borrow_upgrade_cap_for_testing().package();
        let prev_upgrade_cap_version = upgrade_service.borrow_upgrade_cap_for_testing().version();
        let prev_upgrade_cap_policy = upgrade_service.borrow_upgrade_cap_for_testing().policy();

        upgrade_service.extract(UPGRADE_CAP_RECIPIENT, scenario.ctx());
        assert_eq(upgrade_service.exists_upgrade_cap(), false);

        // Ensure that the correct event was emitted.
        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(),
            upgrade_service::create_upgrade_cap_extracted_event<T>(prev_upgrade_cap_id)
        );

        // Ensure that the extracted `UpgradeCap` has the same fields.
        scenario.next_tx(UPGRADE_CAP_RECIPIENT);
        let upgrade_cap = scenario.take_from_sender<UpgradeCap>();
        check_upgrade_cap(
            &upgrade_cap,
            prev_upgrade_cap_package,
            prev_upgrade_cap_version,
            prev_upgrade_cap_policy
        );
        scenario.return_to_sender(upgrade_cap);

        test_scenario::return_shared(upgrade_service);
    }

    fun test_destroy_empty<T>(scenario: &mut Scenario){
        let upgrade_service = scenario.take_shared<UpgradeService<T>>();
        let upgrade_service_object_id = object::id(&upgrade_service);

        upgrade_service.destroy_empty(scenario.ctx());

        // Ensure that the correct event was emitted.
        assert_eq(event::num_events(), 1);
        assert_eq(event::events_by_type<upgrade_service::UpgradeServiceDestroyed<T>>().length(), 1);

        // Ensure that the `UpgradeService<T>` was destroyed.
        let prev_tx_effects = scenario.next_tx(RANDOM_ADDRESS);
        assert_eq(prev_tx_effects.deleted(), vector[upgrade_service_object_id]);
    }

    fun test_change_admin<T>(scenario: &mut Scenario, new_admin: address){
        let mut upgrade_service = scenario.take_shared<UpgradeService<T>>();

        let current_admin = upgrade_service.admin();

        upgrade_service.change_admin(new_admin, scenario.ctx());

        // Ensure that the admin states are correctly set.
        assert_eq(upgrade_service.admin(), current_admin);
        assert_eq(upgrade_service.pending_admin(), option::some(new_admin));

        // Ensure that the correct event was emitted.
        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(),
            two_step_role::create_role_transfer_started_event<AdminRole<T>>(current_admin, new_admin)
        );

        test_scenario::return_shared(upgrade_service);
    }

    fun test_accept_admin<T>(scenario: &mut Scenario){
        let mut upgrade_service = scenario.take_shared<UpgradeService<T>>();

        let current_admin = upgrade_service.admin();
        let pending_admin = upgrade_service.pending_admin().get_with_default(ZERO_ADDRESS);

        upgrade_service.accept_admin(scenario.ctx());

        // Ensure that the admin states are correctly set.
        assert_eq(upgrade_service.admin(), pending_admin);
        assert_eq(upgrade_service.pending_admin(), option::none());

        // Ensure that the correct event was emitted.
        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(),
            two_step_role::create_role_transferred_event<AdminRole<T>>(current_admin, pending_admin)
        );

        test_scenario::return_shared(upgrade_service);
    }

    fun test_authorize_upgrade<T>(scenario: &mut Scenario, policy: u8, digest: vector<u8>): UpgradeTicket {
        let mut upgrade_service = scenario.take_shared<UpgradeService<T>>();

        let prev_upgrade_cap_package = upgrade_service.upgrade_cap_package();
        let prev_upgrade_cap_version = upgrade_service.upgrade_cap_version();
        let prev_upgrade_cap_policy = upgrade_service.upgrade_cap_policy();

        let upgrade_ticket = upgrade_service.authorize_upgrade(policy, digest, scenario.ctx());

        // Ensure that the `UpgradeTicket` is created correctly.
        check_upgrade_ticket(
            &upgrade_ticket,
            prev_upgrade_cap_package,
            policy,
            digest
        );

        check_upgrade_service_and_upgrade_cap(
            &upgrade_service,
            @0x0.to_id(),
            prev_upgrade_cap_version,
            prev_upgrade_cap_policy
        );

        // Ensure that the correct events were emitted.
        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(), 
            upgrade_service::create_authorize_upgrade_event<T>(prev_upgrade_cap_package, policy)
        );

        test_scenario::return_shared(upgrade_service);
        upgrade_ticket
    }

    fun test_commit_upgrade<T>(scenario: &mut Scenario, receipt: UpgradeReceipt) {
        let mut upgrade_service = scenario.take_shared<UpgradeService<T>>();

        let prev_upgrade_cap_version = upgrade_service.upgrade_cap_version();
        let prev_upgrade_cap_policy = upgrade_service.upgrade_cap_policy();
        let new_upgrade_cap_package = receipt.package();

        upgrade_service.commit_upgrade(receipt, scenario.ctx());

        check_upgrade_service_and_upgrade_cap(
            &upgrade_service,
            new_upgrade_cap_package,
            prev_upgrade_cap_version + 1,
            prev_upgrade_cap_policy
        );

        // Ensure that the correct events were emitted.
        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(), 
            upgrade_service::create_commit_upgrade_event<T>(new_upgrade_cap_package)
        );
        
        test_scenario::return_shared(upgrade_service);
    }

    fun create_upgrade_cap(
        scenario: &mut Scenario,
        package_id: ID,
    ): UpgradeCap {
        let upgrade_cap = package::test_publish(package_id, scenario.ctx());
        check_upgrade_cap(
            &upgrade_cap,
            package_id,
            1,
            package::compatible_policy()
        );
        upgrade_cap
    }

    fun check_upgrade_service_and_upgrade_cap<T>(upgrade_service: &UpgradeService<T>, package: ID, version: u64, policy: u8) {
        assert_eq(upgrade_service.upgrade_cap_package(), package);
        assert_eq(upgrade_service.upgrade_cap_version(), version);
        assert_eq(upgrade_service.upgrade_cap_policy(), policy);
        
        check_upgrade_cap(
            upgrade_service.borrow_upgrade_cap_for_testing(),
            package,
            version,
            policy
        );
    }

    fun check_upgrade_cap(upgrade_cap: &UpgradeCap, package: ID, version: u64, policy: u8) {
        assert_eq(upgrade_cap.package(), package);
        assert_eq(upgrade_cap.version(), version);
        assert_eq(upgrade_cap.policy(), policy);
    }

    fun check_upgrade_ticket(upgrade_ticket: &UpgradeTicket, package: ID, policy: u8, digest: vector<u8>) {
        assert_eq(upgrade_ticket.package(), package);
        assert_eq(upgrade_ticket.policy(), policy);
        assert_eq(*upgrade_ticket.digest(), digest);
    }
}

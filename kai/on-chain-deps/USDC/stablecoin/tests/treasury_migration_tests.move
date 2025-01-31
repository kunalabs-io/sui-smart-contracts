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

/// Tests in this module check that the migration functions work
/// as intended when given an outdated Treasury object.
#[test_only]
module stablecoin::treasury_migration_tests {
    use sui::{
        coin,
        event,
        vec_set,
        test_scenario::{Self, Scenario}, 
        test_utils::{assert_eq, destroy, create_one_time_witness},
    };
    use stablecoin::{
        treasury::{Self, Treasury},
        version_control
    };
    use sui_extensions::test_utils::last_event_by_type;

    // Test addresses
    const DEPLOYER: address = @0x0;
    const OWNER: address = @0x10;
    const RANDOM_ADDRESS: address = @0x1000;

    public struct TREASURY_MIGRATION_TESTS has drop {}

    #[test, expected_failure(abort_code = ::stablecoin::two_step_role::ESenderNotActiveRole)]
    fun start_migration__should_fail_is_caller_is_not_owner() {
        let mut scenario = setup();

        // Some random address attempts to start a migration, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_start_migration(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EMigrationStarted)]
    fun start_migration__should_fail_if_migration_started() {
        let mut scenario = setup();

        // Start a migration to this package.
        scenario.next_tx(OWNER);
        test_start_migration(&mut scenario);
        
        // Attempt to start another migration, should fail.
        scenario.next_tx(OWNER);
        test_start_migration(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EObjectMigrated)]
    fun start_migration__should_fail_if_treasury_is_migrated() {
        let mut scenario = setup();

        // Complete a migration flow to this package.
        {
            scenario.next_tx(OWNER);
            test_start_migration(&mut scenario);
            
            scenario.next_tx(OWNER);
            test_complete_migration(&mut scenario);
        };

        // Attempt to start a migration to this package again, should fail.
        scenario.next_tx(OWNER);
        test_start_migration(&mut scenario);

        scenario.end();
    }

    #[test]
    fun start_migration__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup();

        scenario.next_tx(OWNER);
        test_start_migration(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::two_step_role::ESenderNotActiveRole)]
    fun abort_migration__should_fail_is_caller_is_not_owner() {
        let mut scenario = setup();

        // Some random address attempts to start a migration, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_abort_migration(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EMigrationNotStarted)]
    fun abort_migration__should_fail_if_migration_not_started() {
        let mut scenario = setup();

        // Attempt to abort a migration that has not started, should fail.
        scenario.next_tx(OWNER);
        test_abort_migration(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotPendingVersion)]
    fun abort_migration__should_fail_if_the_pending_version_is_not_this_package_version() {
        let mut scenario = setup();

        // Start a migration flow to a later package.
        scenario.next_tx(OWNER);
        start_migration_to_custom_version_for_testing(&scenario, version_control::current_version() + 100);

        // Attempt to abort the migration using this package, should fail.
        scenario.next_tx(OWNER);
        test_abort_migration(&mut scenario);

        scenario.end();
    }

    #[test]
    fun abort_migration__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup();

        // Start a migration.    
        scenario.next_tx(OWNER);
        test_start_migration(&mut scenario);

        // Abort the migration.
        scenario.next_tx(OWNER);
        test_abort_migration(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::two_step_role::ESenderNotActiveRole)]
    fun complete_migration__should_fail_is_caller_is_not_owner() {
        let mut scenario = setup();

        // Some random address attempts to start a migration, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_complete_migration(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EMigrationNotStarted)]
    fun complete_migration__should_fail_if_migration_not_started() {
        let mut scenario = setup();

        // Attempt to complete a migration that has not started, should fail.
        scenario.next_tx(OWNER);
        test_complete_migration(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotPendingVersion)]
    fun complete_migration__should_fail_if_the_pending_version_is_not_this_package_version() {
        let mut scenario = setup();

        // Start a migration flow to a later package.
        scenario.next_tx(OWNER);
        start_migration_to_custom_version_for_testing(&scenario, version_control::current_version() + 100);

        // Attempt to complete the migration using this package, should fail.
        scenario.next_tx(OWNER);
        test_complete_migration(&mut scenario);

        scenario.end();
    }

    #[test]
    fun complete_migration__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup();

        // Start a migration.    
        scenario.next_tx(OWNER);
        test_start_migration(&mut scenario);

        // Complete the migration.
        scenario.next_tx(OWNER);
        test_complete_migration(&mut scenario);

        scenario.end();
    }

    // === Helpers ===

    /// Sets up an outdated Treasury object that is initialized with
    /// (package's version - 1). 
    fun setup(): Scenario {
        let mut scenario = test_scenario::begin(DEPLOYER);

        let (treasury_cap, deny_cap, metadata) = coin::create_regulated_currency_v2(
            create_one_time_witness<TREASURY_MIGRATION_TESTS>(),
            6,
            b"SYMBOL",
            b"NAME",
            b"",
            option::none(),
            true,
            scenario.ctx()
        );
        destroy(metadata);

        let mut treasury = treasury::new(
            treasury_cap,
            deny_cap,
            OWNER,
            OWNER,
            OWNER,
            OWNER,
            OWNER,
            scenario.ctx()
        );
        
        let previous_version = version_control::current_version() - 1;
        
        treasury.set_compatible_versions_for_testing(vec_set::singleton(previous_version));
        assert_eq(treasury.compatible_versions(), vector[previous_version]);
        
        transfer::public_share_object(treasury);

        scenario
    }

    fun test_start_migration(scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_MIGRATION_TESTS>>();
        
        treasury.start_migration(scenario.ctx());

        let updated_compatible_versions = treasury.compatible_versions();
        assert_eq(updated_compatible_versions.length(), 2);
        assert_eq(updated_compatible_versions.contains(&version_control::current_version()), true);

        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(),
            treasury::create_migration_started_event<TREASURY_MIGRATION_TESTS>(updated_compatible_versions)
        );
        
        test_scenario::return_shared(treasury);
    }

    fun test_abort_migration(scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_MIGRATION_TESTS>>();
        
        treasury.abort_migration(scenario.ctx());

        let updated_compatible_versions = treasury.compatible_versions();
        assert_eq(updated_compatible_versions.length(), 1);
        assert_eq(updated_compatible_versions.contains(&version_control::current_version()), false);

        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(),
            treasury::create_migration_aborted_event<TREASURY_MIGRATION_TESTS>(updated_compatible_versions)
        );

        test_scenario::return_shared(treasury);
    }

    fun test_complete_migration(scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_MIGRATION_TESTS>>();
        
        treasury.complete_migration(scenario.ctx());

        let updated_compatible_versions = treasury.compatible_versions();
        assert_eq(updated_compatible_versions, vector[version_control::current_version()]);

        assert_eq(event::num_events(), 1);
        assert_eq(
            last_event_by_type(),
            treasury::create_migration_completed_event<TREASURY_MIGRATION_TESTS>(updated_compatible_versions)
        );

        test_scenario::return_shared(treasury);
    }

    fun start_migration_to_custom_version_for_testing(scenario: &Scenario, version: u64) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_MIGRATION_TESTS>>();

        assert_eq(treasury.compatible_versions().length(), 1);

        let mut compatible_versions = vec_set::from_keys(treasury.compatible_versions());
        compatible_versions.insert(version);
        treasury.set_compatible_versions_for_testing(compatible_versions);

        assert_eq(treasury.compatible_versions().length(), 2);
        assert_eq(treasury.compatible_versions().contains(&version), true);

        test_scenario::return_shared(treasury);
    }
}

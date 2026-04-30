/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_config {
    use sui::test_scenario::{Self, Scenario};
    use sui::table::{Self};
    use sui::dynamic_field;
    use std::vector;
    use std::string::{String};
    use bluefin_spot::config::{Self, GlobalConfig};
    use bluefin_spot::tick_math;
    use bluefin_spot::constants;
    use bluefin_spot::utils;
    use bluefin_spot::errors;
    use integer_mate::i32::{Self as MateI32};

    const ADMIN: address = @0xAD;
    const MANAGER1: address = @0x1;
    const MANAGER2: address = @0x2;
    const MANAGER3: address = @0x3;

    // Test coin types for pool creation fee testing
    struct USDC has drop {}
    struct SUI has drop {}
    struct BTC has drop {}

    // Helper functions for creating test data
    fun create_test_config(scenario: &mut Scenario): GlobalConfig {
        test_scenario::next_tx(scenario, ADMIN);
        config::create_config(test_scenario::ctx(scenario))
    }


    //===========================================================//
    //                   Initialization Tests                   //
    //===========================================================//

    #[test]
    fun test_create_config_basic() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Check initial values
        assert!(config::get_version(&config) == 8, 0); // VERSION constant
        assert!(MateI32::eq(config::get_min_tick(&config), tick_math::min_tick()), 1);
        assert!(MateI32::eq(config::get_max_tick(&config), tick_math::max_tick()), 2);
        assert!(vector::length(config::get_reward_managers(&config)) == 0, 3);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_init_test_function() {
        let scenario = test_scenario::begin(ADMIN);
        
        // Test the init_test function
        config::init_test(test_scenario::ctx(&mut scenario));
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                   Tick Range Tests                       //
    //===========================================================//

    #[test]
    fun test_get_tick_range() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        let (min_tick, max_tick) = config::get_tick_range(&config);
        
        assert!(MateI32::eq(min_tick, tick_math::min_tick()), 0);
        assert!(MateI32::eq(max_tick, tick_math::max_tick()), 1);
        assert!(MateI32::lt(min_tick, max_tick), 2);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                   Version Tests                          //
    //===========================================================//

    #[test]
    fun test_verify_version_success() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Should not abort with correct version
        config::verify_version(&config);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1001, location = bluefin_spot::config)]
    fun test_verify_version_failure() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Set wrong version
        config::set_version(&mut config, 5);
        
        // Should abort with wrong version
        config::verify_version(&config);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_supported_version() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        let version = config::get_supported_version(&config);
        assert!(version == 8, 0);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_version() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        config::set_version(&mut config, 5);
        assert!(config::get_version(&config) == 5, 0);
        
        config::set_version(&mut config, 0);
        assert!(config::get_version(&config) == 0, 1);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Version Increase Tests                   //
    //===========================================================//

    #[test]
    fun test_increase_version_success() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Set version to 6 (less than VERSION = 8)
        config::set_version(&mut config, 6);
        
        let (old_version, new_version) = config::increase_supported_version(&mut config);
        
        assert!(old_version == 6, 0);
        assert!(new_version == 7, 1);
        assert!(config::get_version(&config) == 7, 2);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_increase_version_multiple_times() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Set version to 5
        config::set_version(&mut config, 5);
        
        // Increase version multiple times
        let (old1, new1) = config::increase_supported_version(&mut config);
        assert!(old1 == 5 && new1 == 6, 0);
        
        let (old2, new2) = config::increase_supported_version(&mut config);
        assert!(old2 == 6 && new2 == 7, 1);
        
        let (old3, new3) = config::increase_supported_version(&mut config);
        assert!(old3 == 7 && new3 == 8, 2);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1005, location = bluefin_spot::config)]
    fun test_increase_version_at_max() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Version is already at VERSION (8), should fail
        config::increase_supported_version(&mut config);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1005, location = bluefin_spot::config)]
    fun test_increase_version_beyond_max() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Set version to VERSION (8)
        config::set_version(&mut config, 8);
        
        // Should fail when trying to increase beyond VERSION
        config::increase_supported_version(&mut config);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Reward Manager Tests                     //
    //===========================================================//

    #[test]
    fun test_verify_reward_manager_empty() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Should return false for any manager when list is empty
        assert!(config::verify_reward_manager(&config, MANAGER1) == false, 0);
        assert!(config::verify_reward_manager(&config, MANAGER2) == false, 1);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_reward_manager_single() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Add a single reward manager
        config::set_reward_manager(&mut config, MANAGER1);
        
        assert!(config::verify_reward_manager(&config, MANAGER1) == true, 0);
        assert!(config::verify_reward_manager(&config, MANAGER2) == false, 1);
        assert!(vector::length(config::get_reward_managers(&config)) == 1, 2);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_reward_manager_multiple() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Add multiple reward managers
        config::set_reward_manager(&mut config, MANAGER1);
        config::set_reward_manager(&mut config, MANAGER2);
        config::set_reward_manager(&mut config, MANAGER3);
        
        assert!(config::verify_reward_manager(&config, MANAGER1) == true, 0);
        assert!(config::verify_reward_manager(&config, MANAGER2) == true, 1);
        assert!(config::verify_reward_manager(&config, MANAGER3) == true, 2);
        assert!(vector::length(config::get_reward_managers(&config)) == 3, 3);
        
        // Check the order
        let managers = config::get_reward_managers(&config);
        assert!(*vector::borrow(managers, 0) == MANAGER1, 4);
        assert!(*vector::borrow(managers, 1) == MANAGER2, 5);
        assert!(*vector::borrow(managers, 2) == MANAGER3, 6);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1032, location = bluefin_spot::config)]
    fun test_set_reward_manager_duplicate() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Add manager first time - should succeed
        config::set_reward_manager(&mut config, MANAGER1);
        
        // Try to add same manager again - should fail
        config::set_reward_manager(&mut config, MANAGER1);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_remove_reward_manager_single() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Add and then remove a manager
        config::set_reward_manager(&mut config, MANAGER1);
        assert!(config::verify_reward_manager(&config, MANAGER1) == true, 0);
        
        config::remove_reward_manager(&mut config, MANAGER1);
        assert!(config::verify_reward_manager(&config, MANAGER1) == false, 1);
        assert!(vector::length(config::get_reward_managers(&config)) == 0, 2);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_remove_reward_manager_multiple() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Add multiple managers
        config::set_reward_manager(&mut config, MANAGER1);
        config::set_reward_manager(&mut config, MANAGER2);
        config::set_reward_manager(&mut config, MANAGER3);
        
        // Remove middle manager
        config::remove_reward_manager(&mut config, MANAGER2);
        
        assert!(config::verify_reward_manager(&config, MANAGER1) == true, 0);
        assert!(config::verify_reward_manager(&config, MANAGER2) == false, 1);
        assert!(config::verify_reward_manager(&config, MANAGER3) == true, 2);
        assert!(vector::length(config::get_reward_managers(&config)) == 2, 3);
        
        // Remove first manager
        config::remove_reward_manager(&mut config, MANAGER1);
        
        assert!(config::verify_reward_manager(&config, MANAGER1) == false, 4);
        assert!(config::verify_reward_manager(&config, MANAGER3) == true, 5);
        assert!(vector::length(config::get_reward_managers(&config)) == 1, 6);
        
        // Remove last manager
        config::remove_reward_manager(&mut config, MANAGER3);
        
        assert!(config::verify_reward_manager(&config, MANAGER3) == false, 7);
        assert!(vector::length(config::get_reward_managers(&config)) == 0, 8);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1031, location = bluefin_spot::config)]
    fun test_remove_reward_manager_not_found() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Try to remove manager that doesn't exist
        config::remove_reward_manager(&mut config, MANAGER1);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1031, location = bluefin_spot::config)]
    fun test_remove_reward_manager_already_removed() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Add and remove manager
        config::set_reward_manager(&mut config, MANAGER1);
        config::remove_reward_manager(&mut config, MANAGER1);
        
        // Try to remove again - should fail
        config::remove_reward_manager(&mut config, MANAGER1);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //               Pool Creation Fee Tests                    //
    //===========================================================//

    #[test]
    fun test_get_pool_creation_fee_no_dynamic_field() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Should return (false, 0) when no dynamic field exists
        let (exists, amount) = config::get_pool_creation_fee_amount<USDC>(&config);
        assert!(exists == false, 0);
        assert!(amount == 0, 1);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_pool_creation_fee_with_dynamic_field() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Add dynamic field with fee table
        test_scenario::next_tx(&mut scenario, ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        let fee_table = table::new<String, u64>(ctx);
        
        // Add fees for different coin types
        let usdc_type = utils::get_type_string<USDC>();
        let sui_type = utils::get_type_string<SUI>();
        
        table::add(&mut fee_table, usdc_type, 1000u64);
        table::add(&mut fee_table, sui_type, 2000u64);
        
        // Add the fee table to config as dynamic field
        let key = constants::pool_creation_fee_dynamic_key();
        dynamic_field::add(config::get_config_id(&mut config), key, fee_table);
        
        // Test getting fees for different coin types
        let (exists_usdc, amount_usdc) = config::get_pool_creation_fee_amount<USDC>(&config);
        assert!(exists_usdc == true, 0);
        assert!(amount_usdc == 1000, 1);
        
        let (exists_sui, amount_sui) = config::get_pool_creation_fee_amount<SUI>(&config);
        assert!(exists_sui == true, 2);
        assert!(amount_sui == 2000, 3);
        
        // Test for coin type not in table
        let (exists_btc, amount_btc) = config::get_pool_creation_fee_amount<BTC>(&config);
        assert!(exists_btc == false, 4);
        assert!(amount_btc == 0, 5);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                   Config ID Tests                       //
    //===========================================================//

    #[test]
    fun test_get_config_id() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Test that we can get the config ID
        let _uid = config::get_config_id(&mut config);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_id() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Test the test-only getter
        let _uid = config::get_id(&config);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                   Integration Tests                     //
    //===========================================================//

    #[test]
    fun test_full_config_lifecycle() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // 1. Verify initial state
        assert!(config::get_version(&config) == 8, 0);
        assert!(vector::length(config::get_reward_managers(&config)) == 0, 1);
        
        // 2. Add reward managers
        config::set_reward_manager(&mut config, MANAGER1);
        config::set_reward_manager(&mut config, MANAGER2);
        assert!(vector::length(config::get_reward_managers(&config)) == 2, 2);
        
        // 3. Verify version
        config::verify_version(&config);
        
        // 4. Test version management
        config::set_version(&mut config, 6);
        let (old_v, new_v) = config::increase_supported_version(&mut config);
        assert!(old_v == 6 && new_v == 7, 3);
        
        // 5. Remove a reward manager
        config::remove_reward_manager(&mut config, MANAGER1);
        assert!(config::verify_reward_manager(&config, MANAGER1) == false, 4);
        assert!(config::verify_reward_manager(&config, MANAGER2) == true, 5);
        
        // 6. Test tick range
        let (min_tick, max_tick) = config::get_tick_range(&config);
        assert!(MateI32::lt(min_tick, max_tick), 6);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reward_manager_edge_cases() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Test with same address multiple operations
        config::set_reward_manager(&mut config, MANAGER1);
        assert!(config::verify_reward_manager(&config, MANAGER1) == true, 0);
        
        config::remove_reward_manager(&mut config, MANAGER1);
        assert!(config::verify_reward_manager(&config, MANAGER1) == false, 1);
        
        // Add it back
        config::set_reward_manager(&mut config, MANAGER1);
        assert!(config::verify_reward_manager(&config, MANAGER1) == true, 2);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_version_edge_cases() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Test version 0
        config::set_version(&mut config, 0);
        assert!(config::get_version(&config) == 0, 0);
        
        // Increase from 0
        let (old_v, new_v) = config::increase_supported_version(&mut config);
        assert!(old_v == 0 && new_v == 1, 1);
        
        // Set to VERSION - 1 and increase to VERSION
        config::set_version(&mut config, 7);
        let (old_v2, new_v2) = config::increase_supported_version(&mut config);
        assert!(old_v2 == 7 && new_v2 == 8, 2);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_large_number_of_reward_managers() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Add many reward managers using predefined addresses
        let managers = vector::empty<address>();
        let addresses = vector[
            @0x1, @0x2, @0x3, @0x4, @0x5, @0x6, @0x7, @0x8, @0x9, @0xa
        ];
        let i = 0;
        while (i < vector::length(&addresses)) {
            let addr = *vector::borrow(&addresses, i);
            vector::push_back(&mut managers, addr);
            config::set_reward_manager(&mut config, addr);
            i = i + 1;
        };
        
        // Verify all are added
        assert!(vector::length(config::get_reward_managers(&config)) == 10, 0);
        
        // Verify all can be found
        let j = 0;
        while (j < vector::length(&managers)) {
            let addr = *vector::borrow(&managers, j);
            assert!(config::verify_reward_manager(&config, addr) == true, (j as u64));
            j = j + 1;
        };
        
        // Remove some managers
        let k = 0;
        while (k < 5) {
            let addr = *vector::borrow(&managers, k);
            config::remove_reward_manager(&mut config, addr);
            k = k + 1;
        };
        
        // Verify correct number remaining
        assert!(vector::length(config::get_reward_managers(&config)) == 5, 10);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                    Getter Tests                         //
    //===========================================================//

    #[test]
    fun test_all_getters() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Test all getter functions
        let version = config::get_version(&config);
        let supported_version = config::get_supported_version(&config);
        let min_tick = config::get_min_tick(&config);
        let max_tick = config::get_max_tick(&config);
        let managers = config::get_reward_managers(&config);
        let _id = config::get_id(&config);
        
        assert!(version == supported_version, 0);
        assert!(version == 8, 1);
        assert!(MateI32::eq(min_tick, tick_math::min_tick()), 2);
        assert!(MateI32::eq(max_tick, tick_math::max_tick()), 3);
        assert!(vector::length(managers) == 0, 4);
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                    Error Code Tests                     //
    //===========================================================//

    #[test]
    fun test_error_codes() {
        let scenario = test_scenario::begin(ADMIN);
        let config = create_test_config(&mut scenario);
        
        // Test version mismatch error
        config::set_version(&mut config, 5);
        let _error_occurred = false;
        
        // We can't directly test the error code without aborting,
        // but we can verify the error constants exist
        let _version_mismatch = errors::version_mismatch();
        let _version_cant_increase = errors::verion_cant_be_increased();
        let _reward_manager_not_found = errors::reward_manager_not_found();
        let _already_reward_manager = errors::already_a_reward_manger();
        
        config::destroy_config_for_testing(config);
        test_scenario::end(scenario);
    }
}

/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_admin {
    use std::string;
    use std::vector;

    use sui::test_scenario::{Self};
    use sui::balance;
    use sui::clock::{Clock};
    use sui::coin::{Self};

    
    
    use bluefin_spot::admin::{Self, AdminCap, ProtocolFeeCap};
    use bluefin_spot::test_utils::{Self, BLUE, USDC};
    use bluefin_spot::config::{Self, GlobalConfig};
    use bluefin_spot::pool::{Self, Pool};



    #[test]
    fun should_create_admin_and_fee_cap_upon_initialization() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let transaction_effects = test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            // verify that both AdminCap and ProtocolFeeCap are created
            let created_objects = test_scenario::created(&transaction_effects);
            assert!(vector::length(&created_objects) == 2, 1);

            // verify that both AdminCap and ProtocolFeeCap are transferred to admin address
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario,test_utils::admin_address());
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario,test_utils::admin_address());

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_to_address<ProtocolFeeCap>(test_utils::admin_address(), fee_cap);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_transfer_admin_cap() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        let new_admin = test_utils::bob_address();
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario,test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
           
            // transfer the admin cap to new admin
            admin::transer_admin_cap(&protocol_config, admin_cap, new_admin);

            // return the protocol config 
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::next_tx(&mut scenario,new_admin );
        {
            // verify that AdminCap is transferred to new admin address
            let new_admin_cap = test_scenario::take_from_address<AdminCap>(&scenario,new_admin);

            // return the objects back to new admin address
            test_scenario::return_to_address<AdminCap>(new_admin, new_admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_transfer_protocol_fee_cap() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        let new_admin = test_utils::bob_address();
        {
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario,test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
           
            // transfer the admin cap to new admin
            admin::transer_protocol_fee_cap(&protocol_config, fee_cap, new_admin);

            // return the protocol config 
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::next_tx(&mut scenario,new_admin );
        {
            // verify that AdminCap is transferred to new admin address
            let new_admin_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario,new_admin);

            // return the objects back to new admin address
            test_scenario::return_to_address<ProtocolFeeCap>(new_admin, new_admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_claim_protocol_fee_via_admin_cap() {
        // setup a test scenario with a pool and a position having liquidity provided by BOB
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::admin_address());

        // Alice swaps to generate some protocol fee
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::perform_swap_in_test_scenario(
                &mut scenario,
                &mut pool,
                test_utils::alice_address()
            );
            test_scenario::return_shared(pool);
        };

        // Admin claims the protocol fee
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario,test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let amount_a = pool::get_protocol_fee_for_coin_a(&pool);
            let amount_b = pool::get_protocol_fee_for_coin_b(&pool);

 
            admin::claim_protocol_fee<BLUE, USDC>
            (
            &fee_cap, 
            &protocol_config, 
            &mut pool,
            amount_a,
            amount_b,
            test_utils::admin_address(),
            test_scenario::ctx(&mut scenario)
            );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_to_address<ProtocolFeeCap>(test_utils::admin_address(), fee_cap);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1003,location = bluefin_spot::admin)]
    fun should_not_be_able_to_claim_protocol_fee_via_admin_cap_due_to_invalid_coin_a_amount() {
        // setup a test scenario with a pool and a position having liquidity provided by BOB
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::admin_address());

        // Alice swaps to generate some protocol fee
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::perform_swap_in_test_scenario(
                &mut scenario,
                &mut pool,
                test_utils::alice_address()
            );
            test_scenario::return_shared(pool);
        };

        // Admin claims the protocol fee
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario,test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let amount_a = pool::get_protocol_fee_for_coin_a(&pool);
            let amount_b = pool::get_protocol_fee_for_coin_b(&pool);

 
            admin::claim_protocol_fee<BLUE, USDC>
            (
            &fee_cap, 
            &protocol_config, 
            &mut pool,
            amount_a + 100000,
            amount_b,
            test_utils::admin_address(),
            test_scenario::ctx(&mut scenario)
            );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_to_address<ProtocolFeeCap>(test_utils::admin_address(), fee_cap);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1003,location = bluefin_spot::admin)]
    fun should_not_be_able_to_claim_protocol_fee_via_admin_cap_due_to_invalid_coin_b_amount() {
        // setup a test scenario with a pool and a position having liquidity provided by BOB
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::admin_address());

        // Alice swaps to generate some protocol fee
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::perform_swap_in_test_scenario(
                &mut scenario,
                &mut pool,
                test_utils::alice_address()
            );
            test_scenario::return_shared(pool);
        };

        // Admin claims the protocol fee
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario,test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let amount_a = pool::get_protocol_fee_for_coin_a(&pool);
            let amount_b = pool::get_protocol_fee_for_coin_b(&pool);

 
            admin::claim_protocol_fee<BLUE, USDC>
            (
            &fee_cap, 
            &protocol_config, 
            &mut pool,
            amount_a,
            amount_b + 100000,
            test_utils::admin_address(),
            test_scenario::ctx(&mut scenario)
            );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_to_address<ProtocolFeeCap>(test_utils::admin_address(), fee_cap);
        };
        test_scenario::end(scenario);
    }




    #[test]
    fun should_be_able_to_add_reward_manager() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario,test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            admin::add_reward_manager(&admin_cap, &mut protocol_config, test_utils::bob_address());
            assert!(config::verify_reward_manager(&protocol_config, test_utils::bob_address()), 1);
            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_remove_reward_manager() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario,test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
             admin::add_reward_manager(&admin_cap, &mut protocol_config, test_utils::bob_address());

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario,test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            admin::remove_reward_manager(&admin_cap, &mut protocol_config, test_utils::bob_address());

            assert!(!config::verify_reward_manager(&protocol_config, test_utils::bob_address()), 1);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_update_pool_pause_status() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Pause the pool
            admin::update_pool_pause_status<BLUE, USDC>(&admin_cap, &protocol_config, &mut pool, true);
            assert!(pool::is_pool_paused(&pool), 2);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_update_supported_version() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            config::set_version(&mut protocol_config, 1);

            // Get initial version
            let initial_version = config::get_supported_version(&protocol_config);

            // Update version
            admin::update_supported_version(&admin_cap, &mut protocol_config);
            let new_version = config::get_supported_version(&protocol_config);

            // Verify version increased
            assert!(new_version > initial_version, 1);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1005,location = bluefin_spot::config)]
    fun should_not_be_able_to_update_supported_version_due_to_max_version_reched() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // Get initial version
            let initial_version = config::get_supported_version(&protocol_config);

            // Update version
            admin::update_supported_version(&admin_cap, &mut protocol_config);
            let new_version = config::get_supported_version(&protocol_config);

            // Verify version increased
            assert!(new_version > initial_version, 1);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_update_protocol_fee_share() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Get initial protocol fee share
            let initial_fee_share = pool::protocol_fee_share(&pool);

            // Update protocol fee share
            let new_fee_share = 300000; // 3%
            admin::update_protocol_fee_share<BLUE, USDC>(&admin_cap, &mut pool, new_fee_share);

            // Verify fee share was updated
            assert!(pool::protocol_fee_share(&pool) == new_fee_share, 1);
            assert!(pool::protocol_fee_share(&pool) != initial_fee_share, 2);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1025,location = bluefin_spot::admin)]
    fun should_not_be_able_to_update_protocol_fee_share_with_invalid_fee_share() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Get initial protocol fee share
            let initial_fee_share = pool::protocol_fee_share(&pool);

            // Update protocol fee share
            let new_fee_share = 600000; // 6 percent
            admin::update_protocol_fee_share<BLUE, USDC>(&admin_cap, &mut pool, new_fee_share);

            // Verify fee share was updated
            assert!(pool::protocol_fee_share(&pool) == new_fee_share, 1);
            assert!(pool::protocol_fee_share(&pool) != initial_fee_share, 2);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_increase_observation_cardinality_next() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Increase observation cardinality
            let new_cardinality = 100;
            admin::increase_observation_cardinality_next<BLUE, USDC>(&admin_cap, &mut pool, new_cardinality);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1028,location = bluefin_spot::admin)]
    fun should_be_able_to_increase_observation_cardinality_next_with_invalid_cardinality() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Increase observation cardinality
            let new_cardinality = 10000;
            admin::increase_observation_cardinality_next<BLUE, USDC>(&admin_cap, &mut pool, new_cardinality);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_set_pool_manager() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // Get initial pool manager
            let initial_manager = pool::get_pool_manager(&pool);

            // Set new pool manager
            let new_manager = test_utils::bob_address();
            admin::set_pool_manager<BLUE, USDC>(&protocol_config,&mut pool, new_manager, test_scenario::ctx(&mut scenario));

            // Verify manager was updated
            assert!(pool::get_pool_manager(&pool) == new_manager, 1);
            assert!(pool::get_pool_manager(&pool) != initial_manager, 2);

            // return the objects back to admin address
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_set_pool_creation_fee() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // Set pool creation fee
            let new_fee_amount = 5_000_000; // 5 USDC
            admin::set_pool_creation_fee<BLUE>(&admin_cap, &mut protocol_config, new_fee_amount, test_scenario::ctx(&mut scenario));


            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_claim_pool_creation_fee() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);

        // Now claim the pool creation fee
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // Claim pool creation fee
            admin::claim_pool_creation_fee<USDC>(&fee_cap, &mut protocol_config, 1000, test_utils::bob_address(), test_scenario::ctx(&mut scenario));

            // return the objects back to admin address
            test_scenario::return_to_address<ProtocolFeeCap>(test_utils::admin_address(), fee_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1029,location = bluefin_spot::admin)]
    fun should_not_be_able_to_claim_pool_creation_fee_with_amount_zero() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);

        // Now claim the pool creation fee
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // Claim pool creation fee
            admin::claim_pool_creation_fee<USDC>(&fee_cap, &mut protocol_config, 0, test_utils::bob_address(), test_scenario::ctx(&mut scenario));

            // return the objects back to admin address
            test_scenario::return_to_address<ProtocolFeeCap>(test_utils::admin_address(), fee_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1038,location = bluefin_spot::admin)]
    fun should_not_be_able_to_claim_pool_creation_fee_with_unsupported_coin() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);

        // Now claim the pool creation fee
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // Claim pool creation fee
            admin::claim_pool_creation_fee<BLUE>(&fee_cap, &mut protocol_config, 100, test_utils::bob_address(), test_scenario::ctx(&mut scenario));

            // return the objects back to admin address
            test_scenario::return_to_address<ProtocolFeeCap>(test_utils::admin_address(), fee_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1003,location = bluefin_spot::admin)]
    fun should_not_be_able_to_claim_pool_creation_fee_with_amount_greater_than_collected_fee() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);

        // Now claim the pool creation fee
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let fee_cap = test_scenario::take_from_address<ProtocolFeeCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // Claim pool creation fee
            admin::claim_pool_creation_fee<USDC>(&fee_cap, &mut protocol_config, 1_000_000_000, test_utils::bob_address(), test_scenario::ctx(&mut scenario));

            // return the objects back to admin address
            test_scenario::return_to_address<ProtocolFeeCap>(test_utils::admin_address(), fee_cap);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_set_pool_icon_url() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

          

            // Set new icon URL
            let new_icon_url = string::utf8(b"https://new-icon-url.com/icon.png");
            admin::set_pool_icon_url<BLUE, USDC>(&admin_cap, &protocol_config, &mut pool, new_icon_url);

            // return the objects back to admin address
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_add_rewards_to_pool() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Add rewards to the pool
            test_utils::add_rewards_in_test_scenario(&mut scenario, &mut pool, test_utils::admin_address());

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1023,location = bluefin_spot::admin)]
    fun should_not_be_able_to_add_rewards_to_pool_due_to_not_invalid_manager() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {   
            // create some test coins
            let reward_coin = balance::create_for_testing<USDC>(1_000_000_000); // 1000 USDC
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            admin::initialize_pool_reward<BLUE, USDC, USDC>(
                &protocol_config,
                &mut pool,
                test_utils::start_time(), // not a valid reward manager
                10,
                coin::from_balance<USDC>(reward_coin,test_scenario::ctx(&mut scenario)),
                string::utf8(b"USDC"),
                6, 
                1_000_000_000,
                &clock,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1037,location = bluefin_spot::admin)]
    fun should_not_be_able_to_add_rewards_to_pool_due_to_invalid_amount() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {   
            // create some test coins
            let reward_coin = balance::create_for_testing<USDC>(1_000_000_000); // 1000 USDC
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            admin::initialize_pool_reward<BLUE, USDC, USDC>(
                &protocol_config,
                &mut pool,
                test_utils::start_time(), // not a valid reward manager
                10,
                coin::from_balance<USDC>(reward_coin,test_scenario::ctx(&mut scenario)),
                string::utf8(b"USDC"),
                6, 
                1_000_000,
                &clock,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1020,location = bluefin_spot::admin)]
    fun should_not_be_able_to_add_rewards_to_pool_due_to_invalid_start_time() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        config::init_test(test_scenario::ctx(&mut scenario));
        test_utils::create_pool_in_test_scenario(&mut scenario);

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {   
            // create some test coins
            let reward_coin = balance::create_for_testing<USDC>(1_000_000_000); // 1000 USDC
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            admin::initialize_pool_reward<BLUE, USDC, USDC>(
                &protocol_config,
                &mut pool,
                0, 
                10,
                coin::from_balance<USDC>(reward_coin,test_scenario::ctx(&mut scenario)),
                string::utf8(b"USDC"),
                6, 
                1_000_000_000,
                &clock,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_update_pool_reward_emission() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_having_rewards(&mut scenario, test_utils::admin_address());

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let balance = balance::create_for_testing<USDC>(1_000_000_000);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Update pool reward emission
            let new_emission_rate = 20; // New emission rate
            admin::update_pool_reward_emission<BLUE, USDC, USDC>
            ( &protocol_config,
             &mut pool, 
             new_emission_rate, 
             coin::from_balance<USDC>(balance, test_scenario::ctx(&mut scenario)),
             1_000_000_000,
             &clock,
             test_scenario::ctx(&mut scenario),
             );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1023,location = bluefin_spot::admin)]
    fun should_notbe_able_to_update_pool_reward_emission_due_to_invalid_manager() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_having_rewards(&mut scenario, test_utils::admin_address());

        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let balance = balance::create_for_testing<USDC>(1_000_000_000);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Update pool reward emission
            let new_emission_rate = 20; // New emission rate
            admin::update_pool_reward_emission<BLUE, USDC, USDC>
            ( &protocol_config,
             &mut pool, 
             new_emission_rate, 
             coin::from_balance<USDC>(balance, test_scenario::ctx(&mut scenario)),
             1_000_000_000,
             &clock,
             test_scenario::ctx(&mut scenario),
             );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1037,location = bluefin_spot::admin)]
    fun should_notbe_able_to_update_pool_reward_emission_due_to_invalid_amount() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_having_rewards(&mut scenario, test_utils::admin_address());

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let balance = balance::create_for_testing<USDC>(1_000_000_000);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Update pool reward emission
            let new_emission_rate = 20; // New emission rate
            admin::update_pool_reward_emission<BLUE, USDC, USDC>
            ( &protocol_config,
             &mut pool, 
             new_emission_rate, 
             coin::from_balance<USDC>(balance, test_scenario::ctx(&mut scenario)),
             1_000_000,
             &clock,
             test_scenario::ctx(&mut scenario),
             );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_add_seconds_to_rewards_emission(){
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_having_rewards(&mut scenario, test_utils::admin_address());

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Add seconds to rewards emission
            let additional_seconds = 500; // Additional seconds
            admin::add_seconds_to_reward_emission<BLUE, USDC, USDC>
            ( &protocol_config,
             &mut pool, 
             additional_seconds, 
             &clock,
             test_scenario::ctx(&mut scenario),
             );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1023,location = bluefin_spot::admin)]
    fun should_not_be_able_to_add_seconds_to_rewards_emission_due_to_invalid_manager() {
       let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_having_rewards(&mut scenario, test_utils::admin_address());

        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);

            // Add seconds to rewards emission
            let additional_seconds = 500; // Additional seconds
            admin::add_seconds_to_reward_emission<BLUE, USDC, USDC>
            ( &protocol_config,
             &mut pool, 
             additional_seconds, 
             &clock,
             test_scenario::ctx(&mut scenario),
             );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_add_reserve_to_pool_rewards() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_having_rewards(&mut scenario, test_utils::admin_address());

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let balance = balance::create_for_testing<USDC>(1_000_000_000);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario,test_utils::admin_address());

            // Add reserve to pool rewards
            admin::add_reward_reserves_to_pool<BLUE, USDC, USDC>(
                 &admin_cap,
                &protocol_config,
            &mut pool, 
            coin::from_balance<USDC>(balance, test_scenario::ctx(&mut scenario)),
             );

            // return the objects back to admin address
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
        };
        test_scenario::end(scenario);
    }
}





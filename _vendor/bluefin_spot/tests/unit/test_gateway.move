/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_gateway {
    use sui::test_scenario::{Self};
    use std::string;
    use sui::coin::{Self};
    
    use bluefin_spot::admin::{Self, AdminCap};
    use bluefin_spot::position::{ Position};
    use bluefin_spot::config::{Self, GlobalConfig};
    use bluefin_spot::gateway::{Self};
    use bluefin_spot::test_utils::{Self, BLUE, USDC};
    use bluefin_spot::pool::{Self, Pool};
    use sui::balance;
    use sui::clock::{Self, Clock};


    

    #[test]
    fun should_be_able_to_create_pool_via_gateway() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        let pool_name = b"BLUE-USDC";

        // transfer admin cap to PROTOCOL_ADMIN
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
           
            let icon_url = b"https://bluefin.io/images/nfts/default.gif";
            let coin_a_symbol = b"BLUE";
            let coin_a_decimals = 9;
            let coin_a_url = b"https://bluefin.io/images/nfts/default.gif";
            let coin_b_symbol = b"USDC";
            let coin_b_decimals = 6;
            let coin_b_url = b"https://bluefin.io/images/nfts/default.gif";
          
        
            let fee_coin = balance::create_for_testing<USDC>(10000000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            gateway::create_pool_v2<BLUE, USDC, USDC>(
                &clock,
                &mut config,
                pool_name,
                icon_url,
                coin_a_symbol,
                coin_a_decimals,
                coin_a_url,
                coin_b_symbol,
                coin_b_decimals,
                coin_b_url,
                test_utils::blue_usdc_tick_spacing(),
                test_utils::blue_usdc_fee_rate(),
                test_utils::blue_usdc_sqrt_price(),
                coin::from_balance(fee_coin, test_scenario::ctx(&mut scenario)),
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            
        };
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            assert!(pool::get_pool_name(&pool) == string::utf8(pool_name), 1);
            assert!(pool::get_fee_rate(&pool) == test_utils::blue_usdc_fee_rate(), 2);
            test_scenario::return_shared(pool);
        };

        test_scenario::end(scenario);
    }


    #[test]
    #[expected_failure(abort_code = 1036, location = bluefin_spot::gateway)]
    fun should_fail_to_create_pool_using_deprecated_method() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        let pool_name = b"BLUE-USDC";

        // transfer admin cap to PROTOCOL_ADMIN
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
           
            let icon_url = b"https://bluefin.io/images/nfts/default.gif";
            let coin_a_symbol = b"BLUE";
            let coin_a_decimals = 9;
            let coin_a_url = b"https://bluefin.io/images/nfts/default.gif";
            let coin_b_symbol = b"USDC";
            let coin_b_decimals = 6;
            let coin_b_url = b"https://bluefin.io/images/nfts/default.gif";
          
        
            gateway::create_pool<BLUE, USDC>(
                &clock,
                pool_name,
                icon_url,
                coin_a_symbol,
                coin_a_decimals,
                coin_a_url,
                coin_b_symbol,
                coin_b_decimals,
                coin_b_url,
                test_utils::blue_usdc_tick_spacing(),
                test_utils::blue_usdc_fee_rate(),
                test_utils::blue_usdc_sqrt_price(),
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            
        };
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            assert!(pool::get_pool_name(&pool) == string::utf8(pool_name), 1);
            assert!(pool::get_fee_rate(&pool) == test_utils::blue_usdc_fee_rate(), 2);
            test_scenario::return_shared(pool);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_provide_liquidity_via_gateway() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_and_position(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            // take pool, clock, protocol config 
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // fetch Alice's position
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());

            // create some test coins
            let coin_a = balance::create_for_testing<BLUE>(10000000000); // 10 Blue
            let coin_b = balance::create_for_testing<USDC>(1000000); // 1 USDC
            
            // provide liquidity in pool using Alice's position
            gateway::provide_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin::from_balance(coin_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_b, test_scenario::ctx(&mut scenario)),
                0,
                0,
                test_utils::blue_usdc_liquidity(),
                test_scenario::ctx(&mut scenario),

            );
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_fail_to_provide_liquidity_as_coin_a_is_not_enough() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_and_position(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            // take pool, clock, protocol config 
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // fetch Alice's position
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());

            // create some test coins
            let coin_a = balance::create_for_testing<BLUE>(10000000000); // 10 Blue
            let coin_b = balance::create_for_testing<USDC>(1000000); // 1 USDC
            
            // provide liquidity in pool using Alice's position
            gateway::provide_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin::from_balance(coin_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_b, test_scenario::ctx(&mut scenario)),
                1000000000000000,
                0,
                test_utils::blue_usdc_liquidity(),
                test_scenario::ctx(&mut scenario),

            );
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

     #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_fail_to_provide_liquidity_as_coin_b_is_not_enough() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_and_position(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            // take pool, clock, protocol config 
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            // fetch Alice's position
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());

            // create some test coins
            let coin_a = balance::create_for_testing<BLUE>(10000000000); // 10 Blue
            let coin_b = balance::create_for_testing<USDC>(1000000); // 1 USDC
            
            // provide liquidity in pool using Alice's position
            gateway::provide_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin::from_balance(coin_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_b, test_scenario::ctx(&mut scenario)),
                0,
                1000000000000000,
                test_utils::blue_usdc_liquidity(),
                test_scenario::ctx(&mut scenario),

            );
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_provide_liquidity_via_gateway_with_fixed_amount() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_and_position(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            let coin_a = balance::create_for_testing<BLUE>(10000000000); // 10 Blue
            let coin_b = balance::create_for_testing<USDC>(1000000); // 1 USDC
            gateway::provide_liquidity_with_fixed_amount<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin::from_balance(coin_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_b, test_scenario::ctx(&mut scenario)),
                9000000000,
                10000000000,
                1000000,
                true,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_be_able_to_provide_liquidity_via_gateway_with_fixed_amount_as_coin_b_exceeds_slippage() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_and_position(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            let coin_a = balance::create_for_testing<BLUE>(10000000000); // 10 Blue
            let coin_b = balance::create_for_testing<USDC>(1000000); // 1 USDC
            gateway::provide_liquidity_with_fixed_amount<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin::from_balance(coin_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_b, test_scenario::ctx(&mut scenario)),
                9000000000,
                10000000000,
                10000,
                true,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }


    #[test]
    #[expected_failure(abort_code = 1004, location = bluefin_spot::utils)]
    fun should_be_able_to_provide_liquidity_via_gateway_with_fixed_amount_as_insufficient_coin_amount_is_provided() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_and_position(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            let coin_a = balance::create_for_testing<BLUE>(10000000000); // 10 Blue
            let coin_b = balance::create_for_testing<USDC>(1000000); // 1 USDC
            gateway::provide_liquidity_with_fixed_amount<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin::from_balance(coin_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_b, test_scenario::ctx(&mut scenario)),
                900000,
                100000,
                100000,
                false,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_be_able_to_provide_liquidity_via_gateway_with_fixed_amount_as_coin_a_exceeds_slippage() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_and_position(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            let coin_a = balance::create_for_testing<BLUE>(10000000000); // 10 Blue
            let coin_b = balance::create_for_testing<USDC>(1000000); // 1 USDC
            gateway::provide_liquidity_with_fixed_amount<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin::from_balance(coin_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_b, test_scenario::ctx(&mut scenario)),
                90000,
                100000,
                100000,
                false,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_remove_liquidity() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
    
            gateway::remove_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                test_utils::blue_usdc_liquidity(),
                0,
                0,
                test_utils::alice_address(),
                test_scenario::ctx(&mut scenario),
            );
          
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_fail_to_remove_liquidity_as_coin_a_exceeds_slippage() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
    
            gateway::remove_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                test_utils::blue_usdc_liquidity(),
                1000000000000000,
                0,
                test_utils::alice_address(),
                test_scenario::ctx(&mut scenario),
            );
          
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }


    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_fail_to_remove_liquidity_as_coin_b_exceeds_slippage() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
    
            gateway::remove_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                test_utils::blue_usdc_liquidity(),
                0,
                1000000000000000,
                test_utils::alice_address(),
                test_scenario::ctx(&mut scenario),
            );
          
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_close_position() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
    
            gateway::close_position<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                position,
                test_utils::alice_address(),
                test_scenario::ctx(&mut scenario),
            );
          
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }


    #[test]
    fun should_be_able_to_close_position_with_no_liquidity_in_it() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);

            let position = pool::open_position(&protocol_config, &mut pool, test_utils::blue_usdc_pos_lower_tick(), test_utils::blue_usdc_pos_upper_tick(), test_scenario::ctx(&mut scenario));
            
    
            gateway::close_position<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                position,
                test_utils::alice_address(),
                test_scenario::ctx(&mut scenario),
            );
          
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_swap_assets_via_gateway() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            gateway::swap_assets<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                true, // by_amount_in
                100000000, // amount
                0, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_flash_swap_a_to_b() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            gateway::flash_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                true, // by_amount_in
                100000000, // amount
                0, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_flash_swap_by_amount_out() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            gateway::flash_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                false, // by_amount_in
                10000, // amount
                1000000000, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_fail_to_do_flash_swap_by_amount_out_as_slippage_exceeds() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            gateway::flash_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                false, // by_amount_in
                10000, // amount
                100, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }


    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_fail_to_do_flash_swap_from_a_to_b_as_slippage_exceeds() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            gateway::flash_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                true, // by_amount_in
                100000000, // amount
                100000000000, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_do_flash_swap_from_b_to_a() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(0); 
            let coin_in_b = balance::create_for_testing<USDC>(100000000);
            gateway::flash_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                false, // a2b
                true, // by_amount_in
                100000000, // amount
                0, // amount_limit
                test_utils::blue_usdc_sqrt_price() + 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }


    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_fail_to_do_flash_swap_from_b_to_a_as_slippage_exceeds() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(0); 
            let coin_in_b = balance::create_for_testing<USDC>(100000000);
            gateway::flash_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                false, // a2b
                true, // by_amount_in
                100000000, // amount
                1000000000000, // amount_limit
                test_utils::blue_usdc_sqrt_price() + 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_collect_fees_via_gateway() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());

        // perform a swap to generate some fees in the pool
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
           let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
           
           test_utils::perform_swap_in_test_scenario(&mut scenario, &mut pool, test_utils::bob_address());
           test_scenario::return_shared(pool);
        };
        
        // now collect fees using Alice's position
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
    
            gateway::collect_fee<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                test_scenario::ctx(&mut scenario),
            );
          
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }

    // #[test]
    // fun should_be_able_to_collect_rewards_via_gateway() {
    //     // First set environment with pool having rewards and position having liquidity
    //     let scenario = test_scenario::begin(test_utils::admin_address());
    //     test_utils::setup_test_scenario_with_pool_having_rewards(&mut scenario, test_utils::bob_address());

    //     test_scenario::next_tx(&mut scenario, test_utils::alice_address());
    //     {
    //         let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
    //         test_utils::open_position_and_provide_liquidity_in_test_scenario
    //         (&mut scenario,&mut pool, test_utils::alice_address());

    //         test_scenario::return_shared(pool);
    //     };

    //     // perform a swap to generate some fees and rewards in the pool
    //     test_scenario::next_tx(&mut scenario, test_utils::bob_address());
    //     {
    //        let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
           
    //        test_utils::perform_swap_in_test_scenario(&mut scenario, &mut pool, test_utils::bob_address());
    //        test_scenario::return_shared(pool);
    //     };
        
    //     // now collect fees using Alice's position
    //     test_scenario::next_tx(&mut scenario, test_utils::alice_address());
    //     {
    //         let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
    //         let clock = test_scenario::take_shared<Clock>(&scenario);
    //         clock::set_for_testing(&mut clock, test_utils::start_time() + 100000 ); // move time forward to accumulate rewards
    //         let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
    //         let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
    
    //         gateway::collect_reward<BLUE, USDC, USDC>(
    //             &clock,
    //             &protocol_config,
    //             &mut pool,
    //             &mut position,
    //             test_scenario::ctx(&mut scenario),
    //         );
          
    //         test_scenario::return_shared(pool);
    //         test_scenario::return_shared(clock);
    //         test_scenario::return_shared(protocol_config);
    //         test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
    //     };
    //     test_scenario::end(scenario);
    // }

    #[test]
    #[expected_failure(abort_code = 1033,location = bluefin_spot::gateway)]
    fun should_not_be_able_to_collect_rewards_via_gateway() {
        // First set environment with pool having rewards and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_pool_having_rewards(&mut scenario, test_utils::bob_address());

        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario
            (&mut scenario,&mut pool, test_utils::alice_address());

            test_scenario::return_shared(pool);
        };

        // perform a swap to generate some fees and rewards in the pool
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
           let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
           
           test_utils::perform_swap_in_test_scenario(&mut scenario, &mut pool, test_utils::bob_address());
           test_scenario::return_shared(pool);
        };
        
        // now collect fees using Alice's position
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
    
            gateway::collect_reward<BLUE, USDC, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                test_scenario::ctx(&mut scenario),
            );
          
            test_scenario::return_shared(pool);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
        };
        test_scenario::end(scenario);
    }


    #[test]
    fun should_be_able_to_perform_a_route_swap_a_to_b() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            let (coin_out_a, coin_out_b) = gateway::route_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                true, // by_amount_in
                false, // middle_step
                100000000, // amount
                0, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin_out_a);
            coin::burn_for_testing(coin_out_b);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

     #[test]
    fun should_be_able_to_perform_a_route_swap_a_to_b_as_middle_step() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            let (coin_out_a, coin_out_b) = gateway::route_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                true, // by_amount_in
                true, // middle_step
                100000000, // amount
                0, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin_out_a);
            coin::burn_for_testing(coin_out_b);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_fail_to_perform_a_route_swap_a_to_b_as_slippage_exceeds() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            let (coin_out_a, coin_out_b) = gateway::route_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                true, // by_amount_in
                false, // middle_step
                100000000, // amount
                1000000000000, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin_out_a);
            coin::burn_for_testing(coin_out_b);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }


    #[test]
    fun should_be_able_to_perform_a_route_swap_b_to_a() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(0); 
            let coin_in_b = balance::create_for_testing<USDC>(100000000); 
            let (coin_out_a, coin_out_b) = gateway::route_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                false, // a2b
                true, // by_amount_in
                false, // middle_step
                1000000, // amount
                0, // amount_limit
                test_utils::blue_usdc_sqrt_price() + 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin_out_a);
            coin::burn_for_testing(coin_out_b);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_be_able_to_perform_a_route_swap_a_to_b_by_amount_out() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            let (coin_out_a, coin_out_b) = gateway::route_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                false, // by_amount_in
                false, // middle_step
                10000, // amount
                1000000000, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin_out_a);
            coin::burn_for_testing(coin_out_b);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1010, location = bluefin_spot::gateway)]
    fun should_fail_to_perform_a_route_swap_a_to_b_by_amount_out_as_slippage_exceeds() {
        // First set environment with pool and position having liquidity
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::setup_test_scenario_with_position_having_liquidity(&mut scenario, test_utils::alice_address());
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(100000000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is being swapped
            let (coin_out_a, coin_out_b) = gateway::route_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin::from_balance(coin_in_a, test_scenario::ctx(&mut scenario)),
                coin::from_balance(coin_in_b, test_scenario::ctx(&mut scenario)),
                true, // a2b
                false, // by_amount_in
                false, // middle_step
                100000, // amount
                0, // amount_limit
                test_utils::blue_usdc_sqrt_price() - 100000, // sqrt_price_max_limit
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin_out_a);
            coin::burn_for_testing(coin_out_b);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }
}
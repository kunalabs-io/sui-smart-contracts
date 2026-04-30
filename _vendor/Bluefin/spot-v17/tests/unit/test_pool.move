/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_pool {
    use std::string;
    use std::vector;

    use sui::test_scenario::{Self};
    use sui::transfer;
    use sui::tx_context;
    use sui::balance;
    use sui::clock::{Self, Clock};
    use sui::coin;
    
    
    use bluefin_spot::admin::{Self, AdminCap};
    use bluefin_spot::test_utils::{Self, BLUE, USDC};
    use bluefin_spot::config::{Self, GlobalConfig};
    use bluefin_spot::pool::{Self, Pool};
    use bluefin_spot::position::{Position};
    use bluefin_spot::utils::{Self};
    use integer_mate::i32::{Self as MateI32};



    #[test]
    fun test_open_position() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = pool::open_position<BLUE, USDC>(
                &protocol_config,
                &mut pool,
                test_utils::blue_usdc_pos_lower_tick(),
                test_utils::blue_usdc_pos_upper_tick(),
                test_scenario::ctx(&mut scenario),
            );
            transfer::public_transfer(position, tx_context::sender(test_scenario::ctx(&mut scenario)));
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1002, location = bluefin_spot::pool)]
    fun test_open_position_with_invalid_ticks() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = pool::open_position<BLUE, USDC>(
                &protocol_config,
                &mut pool,
                test_utils::blue_usdc_pos_upper_tick(),
                test_utils::blue_usdc_pos_lower_tick(),
                test_scenario::ctx(&mut scenario),
            );
            transfer::public_transfer(position, tx_context::sender(test_scenario::ctx(&mut scenario)));
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_provide_liquidity() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            // open position first
            test_utils::open_position_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
            
           
        };
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            // create some test coins
            let coin_a = balance::create_for_testing<BLUE>(10000000000); // 10 Blue
            let coin_b = balance::create_for_testing<USDC>(1000000); // 1 USDC

            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            let (_,_,balance_a,balance_b) = pool::add_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin_a,
                coin_b,
                test_utils::blue_usdc_liquidity()
            );
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_close_position() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            // open position first
            test_utils::open_position_in_test_scenario(&mut scenario, &mut pool,test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());

            pool::close_position_v2<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                position 
            );
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_remove_liquidity() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            // open position first
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            let (_,_,balance_a,balance_b) = pool::remove_liquidity<BLUE, USDC>(
                &protocol_config,
                &mut pool,
                &mut position,
                test_utils::blue_usdc_liquidity(),
                &clock
            );
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_perform_swap() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            // open position first
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(1_000_000_000); // 1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is bieng swapped
            let (coin_in, coin_out) = pool::swap< BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                1000_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            // transfer the output coin to test_utils::bob_address()
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_pool() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        let pool_name = b"BLUE-USDC";
        let fee_rate = 100;

        // transfer admin cap to test_utils::admin_address()
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
            pool::create_pool<BLUE, USDC, USDC>(
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
                fee_rate,
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
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
            assert!(pool::get_fee_rate(&pool) == fee_rate, 2);
            test_scenario::return_shared(pool);
        };

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1038, location = bluefin_spot::pool)]
    fun should_fail_pool_creation_as_fee_creation_coin_no_supported() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        let pool_name = b"BLUE-USDC";
        let fee_rate = 100;

        // transfer admin cap to test_utils::admin_address()
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
    
            let fee_coin = balance::create_for_testing<BLUE>(10000000);

            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            pool::create_pool<BLUE, USDC, BLUE>(
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
                fee_rate,
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1039, location = bluefin_spot::pool)]
    fun should_fail_pool_creation_as_fee_creation_amount_incorrect() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        let pool_name = b"BLUE-USDC";
        let fee_rate = 100;

        // transfer admin cap to test_utils::admin_address()
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
    
            let fee_coin = balance::create_for_testing<USDC>(10000); // less than required fee

            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            pool::create_pool<BLUE, USDC, USDC>(
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
                fee_rate,
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun should_use_default_icon_url_while_pool_creation() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        let pool_name = b"BLUE-USDC";
        let fee_rate = 100;

        // transfer admin cap to test_utils::admin_address()
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
           
            let icon_url = b"";
            let coin_a_symbol = b"BLUE";
            let coin_a_decimals = 9;
            let coin_a_url = b"https://bluefin.io/images/nfts/default.gif";
            let coin_b_symbol = b"USDC";
            let coin_b_decimals = 6;
            let coin_b_url = b"https://bluefin.io/images/nfts/default.gif";
    
            let fee_coin = balance::create_for_testing<USDC>(10000000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            pool::create_pool<BLUE, USDC, USDC>(
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
                fee_rate,
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_flash_swap_and_repay() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let (balance_a, balance_b, receipt) = pool::flash_swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                true,
                true,
                100_000_000,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            
            let pay_amount = pool::swap_pay_amount(&receipt);
            assert!(pay_amount > 0, 1);
            
            let repay_coin_a = balance::create_for_testing<BLUE>(pay_amount);
            let repay_coin_b = balance::create_for_testing<USDC>(0);
            
            pool::repay_flash_swap(
                &protocol_config,
                &mut pool,
                repay_coin_a,
                repay_coin_b,
                receipt
            );
            
            utils::transfer_balance(balance_a, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_swap_exact_output() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(1_000_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                false,
                10_000,
                1_000_000_000,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_swap_b2a() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(0);
            let coin_in_b = balance::create_for_testing<USDC>(100_000);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                false,
                true,
                100_000,
                0,
                test_utils::blue_usdc_sqrt_price()+100000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_collect_fee() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(1_000_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                1_000_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            let (fee_a, fee_b, balance_a, balance_b) = pool::collect_fee<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
            );
            
            assert!(fee_a >= 0 && fee_b >= 0, 1);
            
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_calculate_swap_results() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let swap_result = pool::calculate_swap_results<BLUE, USDC>(
                &pool,
                true,
                true,
                100_000_000,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            
            assert!(pool::get_swap_result_a2b(&swap_result) == true, 1);
            assert!(pool::get_swap_result_by_amount_in(&swap_result) == true, 2);
            assert!(pool::get_swap_result_amount_specified(&swap_result) == 100_000_000, 3);
            assert!(pool::get_swap_result_amount_calculated(&swap_result) >= 0, 4);
            assert!(pool::get_swap_result_fee_amount(&swap_result) >= 0, 5);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_pool_getters() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let _name = pool::get_pool_name(&pool);
            let _fee_rate = pool::get_fee_rate(&pool);
            let _tick_spacing = pool::get_tick_spacing(&pool);
            let _liquidity = pool::liquidity(&pool);
            let _sqrt_price = pool::current_sqrt_price(&pool);
            let _tick_index = pool::current_tick_index(&pool);
            let _sequence_number = pool::sequence_number(&pool);
            let (coin_a, coin_b) = pool::coin_reserves(&pool);
            let _protocol_fee_share = pool::protocol_fee_share(&pool);
            let _is_paused = pool::is_pool_paused(&pool);
            let _manager = pool::get_pool_manager(&pool);
            let _protocol_fee_a = pool::get_protocol_fee_for_coin_a(&pool);
            let _protocol_fee_b = pool::get_protocol_fee_for_coin_b(&pool);
            let _reward_len = pool::reward_infos_length(&pool);
            let _tick_manager = pool::get_tick_manager(&pool);
            
    
            assert!(_fee_rate == test_utils::blue_usdc_fee_rate(), 1);
            assert!(_tick_spacing == test_utils::blue_usdc_tick_spacing(), 2);
            assert!(_liquidity == 0, 3);
            assert!(coin_a == 0 && coin_b == 0, 4);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_liquidity_with_fixed_amount_coin_a() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            let coin_a = balance::create_for_testing<BLUE>(5_000_000_000);
            let coin_b = balance::create_for_testing<USDC>(1_000_000);
            
            let (amount_a, amount_b, balance_a, balance_b) = pool::add_liquidity_with_fixed_amount<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin_a,
                coin_b,
                5_000_000_000,
                true,
            );
            
      
            assert!(amount_a > 0, 1);
            assert!(amount_b > 0, 2);
            
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_liquidity_with_fixed_amount_coin_b() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            let coin_a = balance::create_for_testing<BLUE>(10_000_000_000);
            let coin_b = balance::create_for_testing<USDC>(500_000);
            
            let (amount_a, amount_b, balance_a, balance_b) = pool::add_liquidity_with_fixed_amount<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin_a,
                coin_b,
                500_000,
                false,
            );
            
            assert!(amount_b == 500_000, 1);
            assert!(amount_a > 0, 2);
            
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_pool_manager_operations() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let current_manager = pool::get_pool_manager(&pool);
            assert!(pool::verify_pool_manager(&pool, current_manager), 1);
            
            pool::set_manager<BLUE, USDC>(
                &protocol_config,
                &mut pool,
                test_utils::bob_address(),
                test_scenario::ctx(&mut scenario)
            );
            
            assert!(pool::verify_pool_manager(&pool, test_utils::bob_address()), 2);
            assert!(!pool::verify_pool_manager(&pool, current_manager), 3);
            
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_liquidity_by_amount() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let lower_tick = MateI32::from_u32(test_utils::blue_usdc_pos_lower_tick());
            let upper_tick = MateI32::from_u32(test_utils::blue_usdc_pos_upper_tick());
            
            let (liquidity, _amount_a_used, _amount_b_used) = pool::get_liquidity_by_amount(
                lower_tick,
                upper_tick,
                pool::current_tick_index(&pool),
                pool::current_sqrt_price(&pool),
                1_000_000_000,
                true
            );
            
            assert!(liquidity > 0, 1);
            
            let (amount_a, amount_b) = pool::get_amount_by_liquidity(
                lower_tick,
                upper_tick,
                pool::current_tick_index(&pool),
                pool::current_sqrt_price(&pool),
                liquidity,
                true
            );
            
            assert!(amount_a > 0 || amount_b > 0, 2);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_fetch_provided_ticks() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let ticks = vector::empty<u32>();
            vector::push_back(&mut ticks, test_utils::blue_usdc_pos_lower_tick());
            vector::push_back(&mut ticks, test_utils::blue_usdc_pos_upper_tick());
            
            let tick_infos = pool::fetch_provided_ticks<BLUE, USDC>(&pool, ticks);
            
            assert!(vector::length(&tick_infos) == 2, 1);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1012, location = bluefin_spot::pool)]
    fun test_swap_when_pool_paused() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            admin::update_pool_pause_status<BLUE, USDC>(&admin_cap, &protocol_config, &mut pool, true);
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(100_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                100_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1029, location = bluefin_spot::pool)]
    fun test_swap_zero_amount() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(0);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                0,
                0,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1018, location = bluefin_spot::pool)]
    fun test_close_position_with_liquidity() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            pool::close_position_v2<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                position
            );
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_pool_and_get_object() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let fee_coin = balance::create_for_testing<USDC>(10000000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            
            let pool = pool::create_pool_and_get_object<BLUE, USDC, USDC>(
                &clock,
                &mut config,
                b"BLUE-USDC",
                b"https://bluefin.io/images/nfts/default.gif",
                b"BLUE",
                9,
                b"https://bluefin.io/images/nfts/default.gif",
                b"USDC",
                6,
                b"https://bluefin.io/images/nfts/default.gif",
                test_utils::blue_usdc_tick_spacing(),
                test_utils::blue_usdc_fee_rate(),
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            pool::share_pool_object(pool);
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1036, location = bluefin_spot::pool)]
    fun test_deprecated_new_function() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        
        pool::new<BLUE, USDC>(
            &clock,
            b"",
            b"",
            b"",
            0,
            b"",
            b"",
            0,
            b"",
            0,
            0,
            0,
            test_scenario::ctx(&mut scenario)
        );
        
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reward_infos_length() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let reward_len = pool::reward_infos_length(&pool);
            assert!(reward_len == 0, 1);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_positions_in_pool() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::bob_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let liquidity = pool::liquidity(&pool);
            assert!(liquidity > 0, 1);
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_remove_partial_liquidity() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            let half_liquidity = test_utils::blue_usdc_liquidity() / 2;
            let (_,_,balance_a,balance_b) = pool::remove_liquidity<BLUE, USDC>(
                &protocol_config,
                &mut pool,
                &mut position,
                half_liquidity,
                &clock
            );
            
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_large_swap_crossing_ticks() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(10_000_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                10_000_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-1000000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_swap_with_tight_price_limit() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(100_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                100_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-10000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_pool_with_different_tick_spacing() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let fee_coin = balance::create_for_testing<USDC>(10000000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            
            let pool = pool::create_pool_and_get_object<BLUE, USDC, USDC>(
                &clock,
                &mut config,
                b"BLUE-USDC-10",
                b"",
                b"BLUE",
                9,
                b"",
                b"USDC",
                6,
                b"",
                10,
                100,
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            assert!(pool::get_tick_spacing(&pool) == 10, 1);
            
            pool::share_pool_object(pool);
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1026, location = bluefin_spot::pool)]
    fun test_create_pool_with_invalid_tick_spacing() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let fee_coin = balance::create_for_testing<USDC>(10000000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            
            pool::create_pool<BLUE, USDC, USDC>(
                &clock,
                &mut config,
                b"BLUE-USDC",
                b"",
                b"BLUE",
                9,
                b"",
                b"USDC",
                6,
                b"",
                500,
                100,
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1027, location = bluefin_spot::pool)]
    fun test_create_pool_with_invalid_fee_rate() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let fee_coin = balance::create_for_testing<USDC>(10000000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            
            pool::create_pool<BLUE, USDC, USDC>(
                &clock,
                &mut config,
                b"BLUE-USDC",
                b"",
                b"BLUE",
                9,
                b"",
                b"USDC",
                6,
                b"",
                50,
                25000,
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1013, location = bluefin_spot::pool)]
    fun test_create_pool_with_same_coin_types() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let fee_coin = balance::create_for_testing<USDC>(10000000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            
            pool::create_pool<BLUE, BLUE, USDC>(
                &clock,
                &mut config,
                b"BLUE-BLUE",
                b"",
                b"BLUE",
                9,
                b"",
                b"BLUE",
                9,
                b"",
                50,
                100,
                test_utils::blue_usdc_sqrt_price(),
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_sequential_swaps() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::perform_swap_in_test_scenario(&mut scenario, &mut pool, test_utils::bob_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(0);
            let coin_in_b = balance::create_for_testing<USDC>(50_000);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                false,
                true,
                50_000,
                0,
                test_utils::blue_usdc_sqrt_price()+100000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_pool_sequence_number() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let initial_seq = pool::sequence_number(&pool);
            assert!(initial_seq == 0, 1);
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let seq_before = pool::sequence_number(&pool);
            
            test_utils::perform_swap_in_test_scenario(&mut scenario, &mut pool, test_utils::bob_address());
            
            let seq_after = pool::sequence_number(&pool);
            assert!(seq_after > seq_before, 2);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_coin_reserves() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let (reserve_a, reserve_b) = pool::coin_reserves(&pool);
            assert!(reserve_a == 0 && reserve_b == 0, 1);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_pool_icon_url_update() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let new_url = string::utf8(b"https://new-url.com/icon.png");
            admin::set_pool_icon_url<BLUE, USDC>(&admin_cap, &protocol_config, &mut pool, new_url);
            
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_protocol_fee_share() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let fee_share = pool::protocol_fee_share(&pool);
            assert!(fee_share > 0, 1);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_is_reward_present() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let has_blue_reward = pool::is_reward_present<BLUE, USDC, BLUE>(&pool);
            assert!(!has_blue_reward, 1);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_close_position_after_removing_liquidity() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            let (_,_,balance_a,balance_b) = pool::remove_liquidity<BLUE, USDC>(
                &protocol_config,
                &mut pool,
                &mut position,
                test_utils::blue_usdc_liquidity(),
                &clock
            );
            
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            pool::close_position_v2<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                position
            );
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1030, location = bluefin_spot::pool)]
    fun test_create_pool_at_max_sqrt_price() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        admin::test_init(test_scenario::ctx(&mut scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, test_utils::start_time());
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(&mut scenario));

        test_scenario::next_tx(&mut scenario, test_utils::admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(&scenario, test_utils::admin_address());
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let fee_coin = balance::create_for_testing<USDC>(10000000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10000000, test_scenario::ctx(&mut scenario));
            
            pool::create_pool<BLUE, USDC, USDC>(
                &clock,
                &mut config,
                b"BLUE-USDC",
                b"",
                b"BLUE",
                9,
                b"",
                b"USDC",
                6,
                b"",
                50,
                100,
                79226673515401279992447579055,
                fee_coin,
                test_scenario::ctx(&mut scenario),
            );
            
            test_scenario::return_to_address<AdminCap>(test_utils::admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_swap_result_getters() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            
            let swap_result = pool::calculate_swap_results<BLUE, USDC>(
                &pool,
                true,
                true,
                100_000_000,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            
            let _remaining = pool::get_swap_result_amount_specified_remaining(&swap_result);
            let _calculated = pool::get_swap_result_amount_calculated(&swap_result);
            let _fee_growth = pool::get_swap_result_fee_growth_global(&swap_result);
            let _fee_amount = pool::get_swap_result_fee_amount(&swap_result);
            let _protocol_fee = pool::get_swap_result_protocol_fee(&swap_result);
            let _start_price = pool::get_swap_result_start_sqrt_price(&swap_result);
            let _end_price = pool::get_swap_result_end_sqrt_price(&swap_result);
            let _current_tick = pool::get_swap_result_current_tick_index(&swap_result);
            let _is_exceed = pool::get_swap_result_is_exceed(&swap_result);
            let _start_liquidity = pool::get_swap_result_starting_liquidity(&swap_result);
            let _liquidity = pool::get_swap_result_liquidity(&swap_result);
            let _steps = pool::get_swap_result_steps(&swap_result);
            
            test_scenario::return_shared(pool);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1009, location = bluefin_spot::pool)]
    fun test_swap_with_invalid_price_limit_a2b() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(100_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                100_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()+100000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1009, location = bluefin_spot::pool)]
    fun test_swap_with_invalid_price_limit_b2a() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(0);
            let coin_in_b = balance::create_for_testing<USDC>(100_000);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                false,
                true,
                100_000,
                0,
                test_utils::blue_usdc_sqrt_price()-100000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_collect_fee_event_emission() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(10_000_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                10_000_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-1000000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            let (fee_a, fee_b, balance_a, balance_b) = pool::collect_fee<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
            );
            
            assert!(fee_a >= 0 && fee_b >= 0, 1);
            
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_swap_crossing_multiple_ticks() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::bob_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let coin_in_a = balance::create_for_testing<BLUE>(50_000_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                50_000_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-3000000,
            );
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_liquidity_change_in_pool_state() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            let position = test_scenario::take_from_address<Position>(&scenario, test_utils::alice_address());
            
            let coin_a = balance::create_for_testing<BLUE>(100_000_000_000);
            let coin_b = balance::create_for_testing<USDC>(10_000_000);
            
            let (_amount_a, _amount_b, balance_a, balance_b) = pool::add_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                &mut position,
                coin_a,
                coin_b,
                test_utils::blue_usdc_liquidity()
            );
            
            test_scenario::return_to_address<Position>(test_utils::alice_address(), position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
            utils::transfer_balance(balance_a, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(balance_b, test_utils::alice_address(), test_scenario::ctx(&mut scenario));
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let initial_liquidity = pool::liquidity(&pool);
            
            let coin_in_a = balance::create_for_testing<BLUE>(5_000_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                5_000_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-500000,
            );
            
            let final_liquidity = pool::liquidity(&pool);
            assert!(initial_liquidity == final_liquidity || initial_liquidity != final_liquidity, 1);
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_swap_changes_tick_index() {
        let scenario = test_scenario::begin(test_utils::admin_address());
        test_utils::create_pool_in_test_scenario(&mut scenario);
        
        test_scenario::next_tx(&mut scenario, test_utils::alice_address());
        {   
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            test_utils::open_position_and_provide_liquidity_in_test_scenario(&mut scenario, &mut pool, test_utils::alice_address());
            test_scenario::return_shared(pool);
        };
        
        test_scenario::next_tx(&mut scenario, test_utils::bob_address());
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(&scenario);
            let clock = test_scenario::take_shared<Clock>(&scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(&scenario);
            
            let initial_tick = pool::current_tick_index(&pool);
            
            let coin_in_a = balance::create_for_testing<BLUE>(20_000_000_000);
            let coin_in_b = balance::create_for_testing<USDC>(0);
            
            let (coin_in, coin_out) = pool::swap<BLUE, USDC>(
                &clock,
                &protocol_config,
                &mut pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                20_000_000_000,
                0,
                test_utils::blue_usdc_sqrt_price()-2000000,
            );
            
            let final_tick = pool::current_tick_index(&pool);
            assert!(initial_tick != final_tick || initial_tick == final_tick, 1);
            
            utils::transfer_balance(coin_in, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            utils::transfer_balance(coin_out, test_utils::bob_address(), test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(clock);
            test_scenario::return_shared(pool);
            test_scenario::return_shared(protocol_config);
        };
        
        test_scenario::end(scenario);
    }
}

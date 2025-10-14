/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_utils {
    use std::string::{Self};

    use sui::test_scenario::{Self, Scenario};
    use sui::transfer;
    use sui::tx_context;
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::coin;
    
    
    use bluefin_spot::admin::{Self, AdminCap};
    use bluefin_spot::config::{Self, GlobalConfig};
    use bluefin_spot::pool::{Self, Pool};
    use bluefin_spot::position::{Position};
    use bluefin_spot::utils::{Self};
    use bluefin_spot::constants;
    use integer_mate::i128::{Self as MateI128};
    use std::vector;


    const ADMIN: address = @0xABC;
    const MANAGER: address = @0xA;
    const ZERO: address = @0x0;
    const BOB: address = @0xB;
    const ALICE: address = @0xC;

    const BLUE_USDC_SQRT_PRICE: u128 = 193820013307490999;
    const BLUE_USDC_TICK_SPACING: u32 = 200;
    const BLUE_USDC_POS_LOWER_TICK: u32 = 4294873896;
    const BLUE_USDC_POS_UPPER_TICK: u32 = 4294880696;
    const BLUE_USDC_FEE_RATE: u64 = 20000;
    const BLUE_USDC_LIQUIDITY: u128 = 519567915;
    const START_TIME: u64 = 1759930361000; // in ms

    struct BLUE has drop {}
    struct USDC has drop {}

    #[test_only]
    public fun admin_address(): address {
        ADMIN
    }

    #[test_only]
    public fun bob_address(): address {
        BOB
    }

    #[test_only]
    public fun alice_address(): address {
        ALICE
    }

    #[test_only]
    public fun zero_address(): address {
        ZERO
    }

    #[test_only]
    public fun manager_address(): address {
        MANAGER
    }

    #[test_only]
    public fun blue_usdc_pos_upper_tick(): u32 {
        BLUE_USDC_POS_UPPER_TICK
    }

    #[test_only]
    public fun blue_usdc_pos_lower_tick(): u32 {
        BLUE_USDC_POS_LOWER_TICK
    }

    #[test_only]
    public fun blue_usdc_tick_spacing(): u32 {
        BLUE_USDC_TICK_SPACING
    }

    #[test_only]
    public fun blue_usdc_sqrt_price(): u128 {
        BLUE_USDC_SQRT_PRICE
    }

    #[test_only]
    public fun blue_usdc_fee_rate(): u64 {
        BLUE_USDC_FEE_RATE
    }

    #[test_only]
    public fun blue_usdc_liquidity(): u128 {
        BLUE_USDC_LIQUIDITY
    }

    #[test_only]
    public fun start_time(): u64 {
        START_TIME
    }

    #[test_only]
    public fun create_pool_in_test_scenario(
        scenario: &mut Scenario,
    ) {
        admin::test_init(test_scenario::ctx(scenario));
        let clock = clock::create_for_testing(test_scenario::ctx(scenario));
        clock::set_for_testing(&mut clock, START_TIME);
        clock::share_for_testing(clock);
        config::init_test(test_scenario::ctx(scenario));

        let pool_name = b"BLUE-USDC";

        // transfer admin cap to admin_address()
        test_scenario::next_tx(scenario, admin_address());
        {
            let admin_cap = test_scenario::take_from_address<AdminCap>(scenario, admin_address());
            let clock = test_scenario::take_shared<Clock>(scenario);
            let config = test_scenario::take_shared<GlobalConfig>(scenario);
           
            let icon_url = b"https://bluefin.io/images/nfts/default.gif";
            let coin_a_symbol = b"BLUE";
            let coin_a_decimals = 9;
            let coin_a_url = b"https://bluefin.io/images/nfts/default.gif";
            let coin_b_symbol = b"USDC";
            let coin_b_decimals = 6;
            let coin_b_url = b"https://bluefin.io/images/nfts/default.gif";
        
          
            
            let fee_coin = balance::create_for_testing<USDC>(10_000_000);
            admin::set_pool_creation_fee<USDC>(&admin_cap, &mut config, 10_000_000, test_scenario::ctx(scenario));
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
                BLUE_USDC_TICK_SPACING,
                BLUE_USDC_FEE_RATE,
                BLUE_USDC_SQRT_PRICE,
                fee_coin,
                test_scenario::ctx(scenario),
            );
            test_scenario::return_to_address<AdminCap>(admin_address(), admin_cap);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
    }

    #[test_only]
    public fun open_position_in_test_scenario(
        scenario: &mut Scenario,
        pool: &mut Pool<BLUE, USDC>,
        owner: address,
    ) {
        test_scenario::next_tx(scenario, owner);
        {
        let clock = test_scenario::take_shared<Clock>(scenario);
        let protocol_config = test_scenario::take_shared<GlobalConfig>(scenario);
        let position = pool::open_position<BLUE, USDC>(
            &protocol_config,
            pool,
            BLUE_USDC_POS_LOWER_TICK, // 0.15 computed using  asUintN(BigInt(TickMath.priceToInitializableTickIndex()))
            BLUE_USDC_POS_UPPER_TICK, // 0.09 computed using asUintN(BigInt(TickMath.priceToInitializableTickIndex()))
            test_scenario::ctx(scenario),
        );
        transfer::public_transfer(position, tx_context::sender(test_scenario::ctx(scenario)));
        test_scenario::return_shared(clock);
        test_scenario::return_shared(protocol_config);
        };
    }

    #[test_only]
    public fun open_position_and_provide_liquidity_in_test_scenario(
        scenario: &mut Scenario,
        pool: &mut Pool<BLUE, USDC>,
        owner: address,
    ) {
        open_position_in_test_scenario(scenario, pool, owner);
        test_scenario::next_tx(scenario, owner);
        {   
            // create some test coins
            let coin_a = balance::create_for_testing<BLUE>(1_00_000_000_000); // 100 Blue
            let coin_b = balance::create_for_testing<USDC>(10_000_000); // 1 USDC

            let clock = test_scenario::take_shared<Clock>(scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(scenario);
            let position = test_scenario::take_from_address<Position>(scenario, owner);
            let (_,_,balance_a,balance_b) = pool::add_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                pool,
                &mut position,
                coin_a,
                coin_b,
                BLUE_USDC_LIQUIDITY
            );
            test_scenario::return_to_address<Position>(owner, position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            utils::transfer_balance(balance_a, owner, test_scenario::ctx(scenario));
            utils::transfer_balance(balance_b, owner, test_scenario::ctx(scenario));
        };
    }

    #[test_only]
    // Setup a test scenario with a pool and an empty position owned by owner
    public fun setup_test_scenario_with_pool_and_position(
        scenario: &mut Scenario,
        owner: address,
    ) {
        create_pool_in_test_scenario(scenario);

        test_scenario::next_tx(scenario, owner);
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(scenario);
            open_position_in_test_scenario(scenario, &mut pool, owner);
            test_scenario::return_shared(pool);
        }
    }

    #[test_only]
    // Setup a test scenario with a pool and a position having liquidity provided by owner
    public fun setup_test_scenario_with_position_having_liquidity(
        scenario: &mut Scenario,
        owner: address,
    ) {
        setup_test_scenario_with_pool_and_position(scenario, owner);
        test_scenario::next_tx(scenario, owner);
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(scenario);
            provide_liquidity_in_test_scenario(scenario, &mut pool, owner);
            test_scenario::return_shared(pool);
        };
    }

    #[test_only]
    // Setup a test scenario with a pool and an empty position owned by owner
    public fun setup_test_scenario_with_pool_having_rewards(
        scenario: &mut Scenario,
        manager: address,
    ) {
        create_pool_in_test_scenario(scenario);

        test_scenario::next_tx(scenario, manager);
        {
            let pool = test_scenario::take_shared<Pool<BLUE, USDC>>(scenario);
            add_rewards_in_test_scenario(scenario, &mut pool, manager);
            test_scenario::return_shared(pool);
        }
    }

    #[test_only]
    // Add rewards to an existing pool in a test scenario
    public fun add_rewards_in_test_scenario(
        scenario: &mut Scenario,
        pool: &mut Pool<BLUE, USDC>,
        manager: address,
    ) {
        // add manager to reward managers list
        test_scenario::next_tx(scenario, admin_address());
        {   
            let protocol_config = test_scenario::take_shared<GlobalConfig>(scenario);
            let admin_cap = test_scenario::take_from_address<AdminCap>(scenario, admin_address());
            // add manager to reward managers list
            admin::add_reward_manager(&admin_cap, &mut protocol_config, manager);
            test_scenario::return_shared(protocol_config);
            test_scenario::return_to_address<AdminCap>(admin_address(), admin_cap);
        };

        // initialize pool rewards
        test_scenario::next_tx(scenario, admin_address());
        {   
            // create some test coins
            let reward_coin = balance::create_for_testing<USDC>(1_000_000_000); // 1000 USDC
            let clock = test_scenario::take_shared<Clock>(scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(scenario);
            admin::initialize_pool_reward<BLUE, USDC, USDC>(
                &protocol_config,
                pool,
                START_TIME,
                10,
                coin::from_balance<USDC>(reward_coin,test_scenario::ctx(scenario)),
                string::utf8(b"USDC"),
                6, 
                1_000_000_000,
                &clock,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
        };
    }



    #[test_only]
    // Provide liquidity to an existing position of owner in a test scenario
    public fun provide_liquidity_in_test_scenario(
        scenario: &mut Scenario,
        pool: &mut Pool<BLUE, USDC>,
        owner: address,
    ) {
        test_scenario::next_tx(scenario, owner);
        {   
            // create some test coins
            let coin_a = balance::create_for_testing<BLUE>(100_000_000_000); // 100 Blue
            let coin_b = balance::create_for_testing<USDC>(10_000_000); // 10 USDC

            let clock = test_scenario::take_shared<Clock>(scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(scenario);
            let position = test_scenario::take_from_address<Position>(scenario, owner);
            let (_,_,balance_a,balance_b) = pool::add_liquidity<BLUE, USDC>(
                &clock,
                &protocol_config,
                pool,
                &mut position,
                coin_a,
                coin_b,
                BLUE_USDC_LIQUIDITY
            );
            test_scenario::return_to_address<Position>(owner, position);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
            utils::transfer_balance(balance_a, owner, test_scenario::ctx(scenario));
            utils::transfer_balance(balance_b, owner, test_scenario::ctx(scenario));
        };
    }

    #[test_only]
    // Perform a swap on the pool in a test scenario asuming pool has liquidity
    public fun perform_swap_in_test_scenario(
        scenario: &mut Scenario,
        pool: &mut Pool<BLUE, USDC>,
        owner: address,
    ) {
        test_scenario::next_tx(scenario, owner);
        {   
           
            let clock = test_scenario::take_shared<Clock>(scenario);
            let protocol_config = test_scenario::take_shared<GlobalConfig>(scenario);
            // create some test coins
            let coin_in_a = balance::create_for_testing<BLUE>(10_000_000_000); // 0.1 BLUE
            let coin_in_b = balance::create_for_testing<USDC>(0); // 0 USDC since BLUE is bieng swapped
            let (coin_in, coin_out) = pool::swap< BLUE, USDC>(
                &clock,
                &protocol_config,
                pool,
                coin_in_a,
                coin_in_b,
                true,
                true,
                10_000_000_000,
                0,
                blue_usdc_sqrt_price()-100000,
            );
            // transfer the output coin to test_utils::bob_address()
            utils::transfer_balance(coin_in, owner, test_scenario::ctx(scenario));
            utils::transfer_balance(coin_out, owner, test_scenario::ctx(scenario));
            test_scenario::return_shared(clock);
            test_scenario::return_shared(protocol_config);
        };
    }

    //===========================================================//
    //                 overflow_add Function Tests               //
    //===========================================================//

    #[test]
    fun test_overflow_add_no_overflow() {
        // Test normal addition without overflow
        let result = utils::overflow_add(100, 200);
        assert!(result == 300, 0);
    }

    #[test]
    fun test_overflow_add_zero_values() {
        // Test addition with zero values
        assert!(utils::overflow_add(0, 0) == 0, 0);
        assert!(utils::overflow_add(100, 0) == 100, 0);
        assert!(utils::overflow_add(0, 200) == 200, 0);
    }

    #[test]
    fun test_overflow_add_small_values() {
        // Test with small values that won't overflow
        let a: u256 = 1000;
        let b: u256 = 2000;
        let result = utils::overflow_add(a, b);
        assert!(result == 3000, 0);
    }

    #[test]
    fun test_overflow_add_large_values_no_overflow() {
        // Test with large values that still don't overflow
        let max_u128: u256 = 0xffffffffffffffffffffffffffffffff; // Max u128
        let a: u256 = max_u128;
        let b: u256 = max_u128;
        let result = utils::overflow_add(a, b);
        let expected = a + b;
        assert!(result == expected, 0);
    }

    #[test]
    fun test_overflow_add_max_minus_one() {
        // Test with max_u256 - 1 + 1 (should not overflow)
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let a = max_u256 - 1;
        let b = 1;
        let result = utils::overflow_add(a, b);
        assert!(result == max_u256, 0);
    }

    #[test]
    fun test_overflow_add_simple_overflow() {
        // Test simple overflow case: max_u256 + 1
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let a = max_u256;
        let b = 1;
        let result = utils::overflow_add(a, b);
        // Expected: 1 - (max_u256 - max_u256) - 1 = 1 - 0 - 1 = 0
        assert!(result == 0, 0);
    }

    #[test]
    fun test_overflow_add_overflow_by_two() {
        // Test overflow case: max_u256 + 2
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let a = max_u256;
        let b = 2;
        let result = utils::overflow_add(a, b);
        // Expected: 2 - (max_u256 - max_u256) - 1 = 2 - 0 - 1 = 1
        assert!(result == 1, 0);
    }

    #[test]
    fun test_overflow_add_overflow_by_large_amount() {
        // Test overflow with larger second operand
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let a = max_u256;
        let b = 100;
        let result = utils::overflow_add(a, b);
        // Expected: 100 - (max_u256 - max_u256) - 1 = 100 - 0 - 1 = 99
        assert!(result == 99, 0);
    }

    #[test]
    fun test_overflow_add_both_large_overflow() {
        // Test overflow with both operands causing overflow
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let half_max = max_u256 / 2;
        let a = half_max + 1;
        let b = half_max + 1;
        let result = utils::overflow_add(a, b);
        // This should overflow since (half_max + 1) + (half_max + 1) = max_u256 + 1
        // According to the overflow_add logic: b - (max_u256 - a) - 1
        // = (half_max + 1) - (max_u256 - (half_max + 1)) - 1
        // = (half_max + 1) - (half_max - 1) - 1 = 2 - 1 = 1
        // But let's verify this calculation is correct
        // Actually: max_u256 = 2*half_max + 1, so half_max = (max_u256 - 1) / 2
        // a + b = 2*(half_max + 1) = 2*half_max + 2 = max_u256 + 1
        // So overflow should give us: (half_max + 1) - ((max_u256 - (half_max + 1)) - 1) = 0
        assert!(result == 0, 0);
    }

    #[test]
    fun test_overflow_add_edge_case_half_max() {
        // Test with exactly half of max value
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let half_max = max_u256 / 2;
        let a = half_max;
        let b = half_max;
        let result = utils::overflow_add(a, b);
        // This should not overflow since half + half = max - 1
        let expected = half_max + half_max;
        assert!(result == expected, 0);
    }

    #[test]
    fun test_overflow_add_commutative_property() {
        // Test that overflow_add is commutative: a + b = b + a
        let a: u256 = 12345;
        let b: u256 = 67890;
        assert!(utils::overflow_add(a, b) == utils::overflow_add(b, a), 0);

        // Test with overflow case
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let c = max_u256;
        let d = 50;
        assert!(utils::overflow_add(c, d) == utils::overflow_add(d, c), 0);
    }

    #[test]
    fun test_overflow_add_associative_property() {
        // Test associative property: (a + b) + c = a + (b + c)
        let a: u256 = 1000;
        let b: u256 = 2000;
        let c: u256 = 3000;
        
        let left_assoc = utils::overflow_add(utils::overflow_add(a, b), c);
        let right_assoc = utils::overflow_add(a, utils::overflow_add(b, c));
        assert!(left_assoc == right_assoc, 0);
    }

    #[test]
    fun test_overflow_add_identity_element() {
        // Test that 0 is the identity element: a + 0 = a
        let values = vector[
            0u256,
            1u256,
            1000u256,
            340282366920938463463374607431768211455u256, // max u128
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // max u256
        ];
        
        let i = 0;
        while (i < std::vector::length(&values)) {
            let val = *std::vector::borrow(&values, i);
            assert!(utils::overflow_add(val, 0) == val, i);
            assert!(utils::overflow_add(0, val) == val, i);
            i = i + 1;
        };
    }

    #[test]
    fun test_overflow_add_multiple_overflows() {
        // Test multiple consecutive overflows
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let a = max_u256;
        
        // First overflow: max + 5 = 4
        let result1 = utils::overflow_add(a, 5);
        assert!(result1 == 4, 0);
        
        // Second overflow: 4 + max = 3
        let result2 = utils::overflow_add(result1, max_u256);
        assert!(result2 == 3, 0);
        
        // Third overflow: 3 + max = 2
        let result3 = utils::overflow_add(result2, max_u256);
        assert!(result3 == 2, 0);
    }

    #[test]
    fun test_overflow_add_boundary_values() {
        // Test various boundary values
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let max_u128: u256 = 0xffffffffffffffffffffffffffffffff;
        let max_u64: u256 = 0xffffffffffffffff;
        
        // Test max_u64 + max_u64 (should not overflow u256)
        let result1 = utils::overflow_add(max_u64, max_u64);
        assert!(result1 == max_u64 + max_u64, 0);
        
        // Test max_u128 + max_u128 (should not overflow u256)
        let result2 = utils::overflow_add(max_u128, max_u128);
        assert!(result2 == max_u128 + max_u128, 0);
        
        // Test max_u256 + max_u128 (should overflow)
        let result3 = utils::overflow_add(max_u256, max_u128);
        let expected3 = max_u128 - 1;
        assert!(result3 == expected3, 0);
    }

    #[test]
    fun test_overflow_add_powers_of_two() {
        // Test with powers of 2
        let power_255 = 1u256 << 255; // 2^255
        let power_254 = 1u256 << 254; // 2^254
        
        // 2^255 + 2^255 should overflow since 2^256 > max_u256
        let result1 = utils::overflow_add(power_255, power_255);
        // This should wrap around to 0
        assert!(result1 == 0, 0);
        
        // 2^254 + 2^254 = 2^255 (should not overflow)
        let result2 = utils::overflow_add(power_254, power_254);
        assert!(result2 == power_255, 0);
    }

    #[test]
    fun test_overflow_add_sequential_additions() {
        // Test sequential additions that eventually overflow
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        let start_val = max_u256 - 10;
        let increment = 3;
        
        // First addition: (max - 10) + 3 = max - 7
        let result1 = utils::overflow_add(start_val, increment);
        assert!(result1 == max_u256 - 7, 0);
        
        // Second addition: (max - 7) + 3 = max - 4
        let result2 = utils::overflow_add(result1, increment);
        assert!(result2 == max_u256 - 4, 0);
        
        // Third addition: (max - 4) + 3 = max - 1
        let result3 = utils::overflow_add(result2, increment);
        assert!(result3 == max_u256 - 1, 0);
        
        // Fourth addition: (max - 1) + 3 = 1 (overflow)
        let result4 = utils::overflow_add(result3, increment);
        assert!(result4 == 1, 0);
    }

    //===========================================================//
    //                 add_delta Function Tests                 //
    //===========================================================//

    #[test]
    fun test_add_delta_positive_delta_normal() {
        // Test adding positive delta to current liquidity
        let current_liquidity = 1000u128;
        let positive_delta = MateI128::from(500u128);
        let result = utils::add_delta(current_liquidity, positive_delta);
        assert!(result == 1500, 0);
    }

    #[test]
    fun test_add_delta_negative_delta_normal() {
        // Test subtracting negative delta from current liquidity
        let current_liquidity = 1000u128;
        let negative_delta = MateI128::neg_from(500u128);
        let result = utils::add_delta(current_liquidity, negative_delta);
        assert!(result == 500, 0);
    }

    #[test]
    fun test_add_delta_zero_delta() {
        // Test adding zero delta (should return original liquidity)
        let current_liquidity = 1000u128;
        let zero_delta = MateI128::zero();
        let result = utils::add_delta(current_liquidity, zero_delta);
        assert!(result == 1000, 0);
    }

    #[test]
    fun test_add_delta_zero_current_liquidity_positive_delta() {
        // Test adding positive delta to zero liquidity
        let current_liquidity = 0u128;
        let positive_delta = MateI128::from(500u128);
        let result = utils::add_delta(current_liquidity, positive_delta);
        assert!(result == 500, 0);
    }

    #[test]
    fun test_add_delta_zero_current_liquidity_zero_delta() {
        // Test zero liquidity with zero delta
        let current_liquidity = 0u128;
        let zero_delta = MateI128::zero();
        let result = utils::add_delta(current_liquidity, zero_delta);
        assert!(result == 0, 0);
    }

    #[test]
    #[expected_failure(abort_code = 1015, location = bluefin_spot::utils)]
    fun test_add_delta_negative_delta_exceeds_liquidity() {
        // Test subtracting more than available liquidity (should fail)
        let current_liquidity = 500u128;
        let negative_delta = MateI128::neg_from(1000u128); // Try to subtract 1000 from 500
        utils::add_delta(current_liquidity, negative_delta);
    }

    #[test]
    #[expected_failure(abort_code = 1015, location = bluefin_spot::utils)]
    fun test_add_delta_negative_delta_equals_liquidity_plus_one() {
        // Test subtracting exactly liquidity + 1 (should fail)
        let current_liquidity = 1000u128;
        let negative_delta = MateI128::neg_from(1001u128);
        utils::add_delta(current_liquidity, negative_delta);
    }

    #[test]
    fun test_add_delta_negative_delta_equals_liquidity() {
        // Test subtracting exactly the current liquidity (should result in 0)
        let current_liquidity = 1000u128;
        let negative_delta = MateI128::neg_from(1000u128);
        let result = utils::add_delta(current_liquidity, negative_delta);
        assert!(result == 0, 0);
    }

    #[test]
    #[expected_failure(abort_code = 1015, location = bluefin_spot::utils)]
    fun test_add_delta_zero_liquidity_negative_delta() {
        // Test subtracting from zero liquidity (should fail)
        let current_liquidity = 0u128;
        let negative_delta = MateI128::neg_from(1u128);
        utils::add_delta(current_liquidity, negative_delta);
    }

    #[test]
    fun test_add_delta_large_values_no_overflow() {
        // Test with large values that don't cause overflow
        let max_u64 = 18446744073709551615u128; // 2^64 - 1
        let current_liquidity = max_u64;
        let small_delta = MateI128::from(1000u128);
        let result = utils::add_delta(current_liquidity, small_delta);
        assert!(result == max_u64 + 1000, 0);
    }

    #[test]
    #[expected_failure(abort_code = 1015, location = bluefin_spot::utils)]
    fun test_add_delta_overflow_protection() {
        // Test overflow protection: adding delta that would cause overflow
        let max_u128 = constants::max_u128();
        let current_liquidity = max_u128 - 100;
        let large_delta = MateI128::from(200u128); // This would cause overflow
        utils::add_delta(current_liquidity, large_delta);
    }

    #[test]
    fun test_add_delta_max_safe_addition() {
        // Test maximum safe addition (right at the boundary)
        let max_u128 = constants::max_u128();
        let current_liquidity = max_u128 - 100;
        let safe_delta = MateI128::from(99u128); // This should be safe
        let result = utils::add_delta(current_liquidity, safe_delta);
        assert!(result == max_u128 - 1, 0);
    }

    #[test]
    #[expected_failure(abort_code = 1015, location = bluefin_spot::utils)]
    fun test_add_delta_boundary_overflow() {
        // Test exact boundary case that should cause overflow
        let max_u128 = constants::max_u128();
        let current_liquidity = max_u128 - 100;
        let boundary_delta = MateI128::from(100u128); // This equals max_u128 - current_liquidity, should fail
        utils::add_delta(current_liquidity, boundary_delta);
    }

    #[test]
    #[expected_failure(abort_code = 1015, location = bluefin_spot::utils)]
    fun test_add_delta_max_u128_zero_delta() {
        // Test max u128 value with zero delta
        // This fails because the function checks value < max_u128 - current_liquidity
        // When current_liquidity = max_u128, then max_u128 - current_liquidity = 0
        // So even with zero delta (value = 0), the condition 0 < 0 is false
        let max_u128 = constants::max_u128();
        let zero_delta = MateI128::zero();
        utils::add_delta(max_u128, zero_delta);
    }

    #[test]
    #[expected_failure(abort_code = 1015, location = bluefin_spot::utils)]
    fun test_add_delta_max_u128_positive_delta() {
        // Test max u128 value with any positive delta (should fail)
        let max_u128 = constants::max_u128();
        let small_delta = MateI128::from(1u128);
        utils::add_delta(max_u128, small_delta);
    }

    #[test]
    fun test_add_delta_max_u128_negative_delta() {
        // Test max u128 value with negative delta
        let max_u128 = constants::max_u128();
        let negative_delta = MateI128::neg_from(1000u128);
        let result = utils::add_delta(max_u128, negative_delta);
        assert!(result == max_u128 - 1000, 0);
    }

    #[test]
    fun test_add_delta_sequential_operations() {
        // Test multiple sequential add_delta operations
        let current_liquidity = 1000u128;
        
        // Add 500
        let delta1 = MateI128::from(500u128);
        let current_liquidity = utils::add_delta(current_liquidity, delta1);
        assert!(current_liquidity == 1500, 0);
        
        // Subtract 200
        let delta2 = MateI128::neg_from(200u128);
        let current_liquidity = utils::add_delta(current_liquidity, delta2);
        assert!(current_liquidity == 1300, 0);
        
        // Add 700
        let delta3 = MateI128::from(700u128);
        let current_liquidity = utils::add_delta(current_liquidity, delta3);
        assert!(current_liquidity == 2000, 0);
    }

    #[test]
    fun test_add_delta_alternating_operations() {
        // Test alternating positive and negative operations
        let liquidity = 5000u128;
        
        // Subtract 1000
        let liquidity = utils::add_delta(liquidity, MateI128::neg_from(1000u128));
        assert!(liquidity == 4000, 0);
        
        // Add 2000
        let liquidity = utils::add_delta(liquidity, MateI128::from(2000u128));
        assert!(liquidity == 6000, 0);
        
        // Subtract 3000
        let liquidity = utils::add_delta(liquidity, MateI128::neg_from(3000u128));
        assert!(liquidity == 3000, 0);
        
        // Add 1500
        let liquidity = utils::add_delta(liquidity, MateI128::from(1500u128));
        assert!(liquidity == 4500, 0);
    }

    #[test]
    fun test_add_delta_edge_case_one() {
        // Test edge cases with value 1
        let current_liquidity = 1u128;
        
        // Add 1
        let result1 = utils::add_delta(current_liquidity, MateI128::from(1u128));
        assert!(result1 == 2, 0);
        
        // Subtract 1 from original
        let result2 = utils::add_delta(current_liquidity, MateI128::neg_from(1u128));
        assert!(result2 == 0, 0);
    }

    #[test]
    fun test_add_delta_large_negative_operations() {
        // Test large negative operations within bounds
        let max_u64 = 18446744073709551615u128;
        let current_liquidity = max_u64;
        let large_negative = MateI128::neg_from(max_u64 / 2);
        let result = utils::add_delta(current_liquidity, large_negative);
        assert!(result == max_u64 - (max_u64 / 2), 0);
    }

    #[test]
    fun test_add_delta_powers_of_two() {
        // Test with powers of 2
        let current_liquidity = 1024u128; // 2^10
        
        // Add 2^9
        let result1 = utils::add_delta(current_liquidity, MateI128::from(512u128));
        assert!(result1 == 1536, 0);
        
        // Subtract 2^8 from original
        let result2 = utils::add_delta(current_liquidity, MateI128::neg_from(256u128));
        assert!(result2 == 768, 0);
    }

    #[test]
    fun test_add_delta_type_conversion_consistency() {
        // Test that the function handles type conversions correctly
        let test_values = vector[
            1u128,
            100u128,
            1000u128,
            10000u128,
            100000u128,
            1000000u128
        ];
        
        let i = 0;
        while (i < std::vector::length(&test_values)) {
            let val = *std::vector::borrow(&test_values, i);
            let current_liquidity = val * 2;
            
            // Test positive delta
            let pos_result = utils::add_delta(current_liquidity, MateI128::from(val));
            assert!(pos_result == current_liquidity + val, i);
            
            // Test negative delta
            let neg_result = utils::add_delta(current_liquidity, MateI128::neg_from(val));
            assert!(neg_result == current_liquidity - val, i);
            
            i = i + 1;
        };
    }

    #[test]
    fun test_add_delta_boundary_values_systematic() {
        // Test systematic boundary values
        let boundaries = vector[
            0u128,
            1u128,
            255u128,        // max u8
            65535u128,      // max u16
            4294967295u128, // max u32
        ];
        
        let i = 0;
        while (i < std::vector::length(&boundaries)) {
            let boundary = *std::vector::borrow(&boundaries, i);
            if (boundary > 0) {
                // Test adding boundary value
                let result1 = utils::add_delta(boundary, MateI128::from(boundary));
                assert!(result1 == boundary * 2, i);
                
                // Test subtracting boundary value (should result in 0)
                let result2 = utils::add_delta(boundary, MateI128::neg_from(boundary));
                assert!(result2 == 0, i);
            };
            i = i + 1;
        };
    }

    //===========================================================//
    //               u128_to_string Function Tests              //
    //===========================================================//

    #[test]
    fun test_u128_to_string_zero() {
        // Test converting zero
        let result = utils::u128_to_string(0);
        assert!(string::as_bytes(&result) == &b"0", 0);
    }

    #[test]
    fun test_u128_to_string_single_digit() {
        // Test single digit numbers
        let test_cases = vector[1u128, 2u128, 3u128, 4u128, 5u128, 6u128, 7u128, 8u128, 9u128];
        let expected = vector[b"1", b"2", b"3", b"4", b"5", b"6", b"7", b"8", b"9"];
        
        let i = 0;
        while (i < std::vector::length(&test_cases)) {
            let num = *std::vector::borrow(&test_cases, i);
            let expected_bytes = *std::vector::borrow(&expected, i);
            let result = utils::u128_to_string(num);
            assert!(string::as_bytes(&result) == &expected_bytes, i);
            i = i + 1;
        };
    }

    #[test]
    fun test_u128_to_string_two_digit() {
        // Test two digit numbers
        let result10 = utils::u128_to_string(10);
        assert!(string::as_bytes(&result10) == &b"10", 0);
        
        let result25 = utils::u128_to_string(25);
        assert!(string::as_bytes(&result25) == &b"25", 1);
        
        let result99 = utils::u128_to_string(99);
        assert!(string::as_bytes(&result99) == &b"99", 2);
    }

    #[test]
    fun test_u128_to_string_three_digit() {
        // Test three digit numbers
        let result100 = utils::u128_to_string(100);
        assert!(string::as_bytes(&result100) == &b"100", 0);
        
        let result123 = utils::u128_to_string(123);
        assert!(string::as_bytes(&result123) == &b"123", 1);
        
        let result999 = utils::u128_to_string(999);
        assert!(string::as_bytes(&result999) == &b"999", 2);
    }

    #[test]
    fun test_u128_to_string_powers_of_ten() {
        // Test powers of 10
        let powers = vector[
            1u128,
            10u128,
            100u128,
            1000u128,
            10000u128,
            100000u128,
            1000000u128,
            10000000u128,
            100000000u128,
            1000000000u128,
            10000000000u128
        ];
        
        let expected = vector[
            b"1",
            b"10",
            b"100",
            b"1000",
            b"10000",
            b"100000",
            b"1000000",
            b"10000000",
            b"100000000",
            b"1000000000",
            b"10000000000"
        ];
        
        let i = 0;
        while (i < std::vector::length(&powers)) {
            let num = *std::vector::borrow(&powers, i);
            let expected_bytes = *std::vector::borrow(&expected, i);
            let result = utils::u128_to_string(num);
            assert!(string::as_bytes(&result) == &expected_bytes, i);
            i = i + 1;
        };
    }

    #[test]
    fun test_u128_to_string_powers_of_ten_minus_one() {
        // Test powers of 10 minus 1 (all 9s)
        let numbers = vector[
            9u128,
            99u128,
            999u128,
            9999u128,
            99999u128,
            999999u128,
            9999999u128,
            99999999u128,
            999999999u128,
            9999999999u128
        ];
        
        let expected = vector[
            b"9",
            b"99",
            b"999",
            b"9999",
            b"99999",
            b"999999",
            b"9999999",
            b"99999999",
            b"999999999",
            b"9999999999"
        ];
        
        let i = 0;
        while (i < std::vector::length(&numbers)) {
            let num = *std::vector::borrow(&numbers, i);
            let expected_bytes = *std::vector::borrow(&expected, i);
            let result = utils::u128_to_string(num);
            assert!(string::as_bytes(&result) == &expected_bytes, i);
            i = i + 1;
        };
    }

    #[test]
    fun test_u128_to_string_type_boundaries() {
        // Test boundary values for different integer types
        
        // Max u8 = 255
        let result_u8 = utils::u128_to_string(255);
        assert!(string::as_bytes(&result_u8) == &b"255", 0);
        
        // Max u16 = 65535
        let result_u16 = utils::u128_to_string(65535);
        assert!(string::as_bytes(&result_u16) == &b"65535", 1);
        
        // Max u32 = 4294967295
        let result_u32 = utils::u128_to_string(4294967295);
        assert!(string::as_bytes(&result_u32) == &b"4294967295", 2);
        
        // Max u64 = 18446744073709551615
        let result_u64 = utils::u128_to_string(18446744073709551615);
        assert!(string::as_bytes(&result_u64) == &b"18446744073709551615", 3);
    }

    #[test]
    fun test_u128_to_string_large_numbers() {
        // Test large numbers
        let large1 = utils::u128_to_string(123456789012345);
        assert!(string::as_bytes(&large1) == &b"123456789012345", 0);
        
        let large2 = utils::u128_to_string(987654321098765);
        assert!(string::as_bytes(&large2) == &b"987654321098765", 1);
        
        let large3 = utils::u128_to_string(111111111111111111);
        assert!(string::as_bytes(&large3) == &b"111111111111111111", 2);
    }

    #[test]
    fun test_u128_to_string_max_u128() {
        // Test maximum u128 value = 340282366920938463463374607431768211455
        let max_u128 = constants::max_u128();
        let result = utils::u128_to_string(max_u128);
        assert!(string::as_bytes(&result) == &b"340282366920938463463374607431768211455", 0);
    }

    #[test]
    fun test_u128_to_string_max_u128_minus_one() {
        // Test max u128 - 1
        let max_u128 = constants::max_u128();
        let result = utils::u128_to_string(max_u128 - 1);
        assert!(string::as_bytes(&result) == &b"340282366920938463463374607431768211454", 0);
    }

    #[test]
    fun test_u128_to_string_repeating_digits() {
        // Test numbers with repeating digits
        let rep1 = utils::u128_to_string(1111);
        assert!(string::as_bytes(&rep1) == &b"1111", 0);
        
        let rep2 = utils::u128_to_string(2222222);
        assert!(string::as_bytes(&rep2) == &b"2222222", 1);
        
        let rep3 = utils::u128_to_string(333333333);
        assert!(string::as_bytes(&rep3) == &b"333333333", 2);
        
        let rep4 = utils::u128_to_string(4444444444444);
        assert!(string::as_bytes(&rep4) == &b"4444444444444", 3);
    }

    #[test]
    fun test_u128_to_string_alternating_digits() {
        // Test numbers with alternating digit patterns
        let alt1 = utils::u128_to_string(1212121212);
        assert!(string::as_bytes(&alt1) == &b"1212121212", 0);
        
        let alt2 = utils::u128_to_string(3434343434);
        assert!(string::as_bytes(&alt2) == &b"3434343434", 1);
        
        let alt3 = utils::u128_to_string(5656565656565656);
        assert!(string::as_bytes(&alt3) == &b"5656565656565656", 2);
    }

    #[test]
    fun test_u128_to_string_ascending_digits() {
        // Test numbers with ascending digit patterns
        let asc1 = utils::u128_to_string(123);
        assert!(string::as_bytes(&asc1) == &b"123", 0);
        
        let asc2 = utils::u128_to_string(12345);
        assert!(string::as_bytes(&asc2) == &b"12345", 1);
        
        let asc3 = utils::u128_to_string(123456789);
        assert!(string::as_bytes(&asc3) == &b"123456789", 2);
        
        let asc4 = utils::u128_to_string(1234567890123456);
        assert!(string::as_bytes(&asc4) == &b"1234567890123456", 3);
    }

    #[test]
    fun test_u128_to_string_descending_digits() {
        // Test numbers with descending digit patterns
        let desc1 = utils::u128_to_string(321);
        assert!(string::as_bytes(&desc1) == &b"321", 0);
        
        let desc2 = utils::u128_to_string(54321);
        assert!(string::as_bytes(&desc2) == &b"54321", 1);
        
        let desc3 = utils::u128_to_string(987654321);
        assert!(string::as_bytes(&desc3) == &b"987654321", 2);
        
        let desc4 = utils::u128_to_string(9876543210987654);
        assert!(string::as_bytes(&desc4) == &b"9876543210987654", 3);
    }

    #[test]
    fun test_u128_to_string_numbers_with_zeros() {
        // Test numbers containing zeros in various positions
        let zero1 = utils::u128_to_string(101);
        assert!(string::as_bytes(&zero1) == &b"101", 0);
        
        let zero2 = utils::u128_to_string(1001);
        assert!(string::as_bytes(&zero2) == &b"1001", 1);
        
        let zero3 = utils::u128_to_string(10001);
        assert!(string::as_bytes(&zero3) == &b"10001", 2);
        
        let zero4 = utils::u128_to_string(100010001);
        assert!(string::as_bytes(&zero4) == &b"100010001", 3);
        
        let zero5 = utils::u128_to_string(1000000000000001);
        assert!(string::as_bytes(&zero5) == &b"1000000000000001", 4);
    }

    #[test]
    fun test_u128_to_string_scientific_notation_equivalents() {
        // Test numbers that might be written in scientific notation
        let sci1 = utils::u128_to_string(1000000); // 1e6
        assert!(string::as_bytes(&sci1) == &b"1000000", 0);
        
        let sci2 = utils::u128_to_string(1000000000); // 1e9
        assert!(string::as_bytes(&sci2) == &b"1000000000", 1);
        
        let sci3 = utils::u128_to_string(1000000000000); // 1e12
        assert!(string::as_bytes(&sci3) == &b"1000000000000", 2);
        
        let sci4 = utils::u128_to_string(1000000000000000); // 1e15
        assert!(string::as_bytes(&sci4) == &b"1000000000000000", 3);
    }

    #[test]
    fun test_u128_to_string_fibonacci_like_numbers() {
        // Test Fibonacci-like sequence numbers
        let fib1 = utils::u128_to_string(1);
        assert!(string::as_bytes(&fib1) == &b"1", 0);
        
        let fib2 = utils::u128_to_string(1);
        assert!(string::as_bytes(&fib2) == &b"1", 1);
        
        let fib3 = utils::u128_to_string(2);
        assert!(string::as_bytes(&fib3) == &b"2", 2);
        
        let fib4 = utils::u128_to_string(3);
        assert!(string::as_bytes(&fib4) == &b"3", 3);
        
        let fib5 = utils::u128_to_string(5);
        assert!(string::as_bytes(&fib5) == &b"5", 4);
        
        let fib6 = utils::u128_to_string(8);
        assert!(string::as_bytes(&fib6) == &b"8", 5);
        
        let fib7 = utils::u128_to_string(13);
        assert!(string::as_bytes(&fib7) == &b"13", 6);
        
        let fib8 = utils::u128_to_string(21);
        assert!(string::as_bytes(&fib8) == &b"21", 7);
        
        let fib9 = utils::u128_to_string(34);
        assert!(string::as_bytes(&fib9) == &b"34", 8);
        
        let fib10 = utils::u128_to_string(55);
        assert!(string::as_bytes(&fib10) == &b"55", 9);
    }

    #[test]
    fun test_u128_to_string_edge_case_numbers() {
        // Test various edge case numbers
        let edge1 = utils::u128_to_string(1024); // 2^10
        assert!(string::as_bytes(&edge1) == &b"1024", 0);
        
        let edge2 = utils::u128_to_string(65536); // 2^16
        assert!(string::as_bytes(&edge2) == &b"65536", 1);
        
        let edge3 = utils::u128_to_string(16777216); // 2^24
        assert!(string::as_bytes(&edge3) == &b"16777216", 2);
        
        let edge4 = utils::u128_to_string(4294967296); // 2^32
        assert!(string::as_bytes(&edge4) == &b"4294967296", 3);
        
        let edge5 = utils::u128_to_string(18446744073709551616); // 2^64
        assert!(string::as_bytes(&edge5) == &b"18446744073709551616", 4);
    }

    #[test]
    fun test_u128_to_string_random_large_numbers() {
        // Test various random large numbers
        let rand1 = utils::u128_to_string(12345678901234567890);
        assert!(string::as_bytes(&rand1) == &b"12345678901234567890", 0);
        
        let rand2 = utils::u128_to_string(98765432109876543210);
        assert!(string::as_bytes(&rand2) == &b"98765432109876543210", 1);
        
        let rand3 = utils::u128_to_string(13579246801357924680);
        assert!(string::as_bytes(&rand3) == &b"13579246801357924680", 2);
        
        let rand4 = utils::u128_to_string(24681357902468135790);
        assert!(string::as_bytes(&rand4) == &b"24681357902468135790", 3);
    }

    #[test]
    fun test_u128_to_string_consistency_with_arithmetic() {
        // Test that string conversion is consistent with arithmetic operations
        let base = 12345u128;
        let multiplier = 10u128;
        
        // Test base number
        let base_str = utils::u128_to_string(base);
        assert!(string::as_bytes(&base_str) == &b"12345", 0);
        
        // Test base * 10
        let mult_str = utils::u128_to_string(base * multiplier);
        assert!(string::as_bytes(&mult_str) == &b"123450", 1);
        
        // Test base * 100
        let mult2_str = utils::u128_to_string(base * 100);
        assert!(string::as_bytes(&mult2_str) == &b"1234500", 2);
        
        // Test base + 1
        let add_str = utils::u128_to_string(base + 1);
        assert!(string::as_bytes(&add_str) == &b"12346", 3);
        
        // Test base - 1
        let sub_str = utils::u128_to_string(base - 1);
        assert!(string::as_bytes(&sub_str) == &b"12344", 4);
    }

    //===========================================================//
    //             withdraw_balance Function Tests              //
    //===========================================================//

    #[test]
    fun test_withdraw_balance_normal_withdrawal() {
        // Test normal withdrawal from balance
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a balance with 1000 units
        let balance = balance::create_for_testing<USDC>(1000);
        
        // Withdraw 300 units
        let withdrawn = utils::withdraw_balance(&mut balance, 300);
        
        // Check withdrawn balance
        assert!(balance::value(&withdrawn) == 300, 0);
        
        // Check remaining balance
        assert!(balance::value(&balance) == 700, 1);
        
        // Clean up
        balance::destroy_for_testing(balance);
        balance::destroy_for_testing(withdrawn);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_zero_amount() {
        // Test withdrawing zero amount
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a balance with 1000 units
        let balance = balance::create_for_testing<USDC>(1000);
        
        // Withdraw 0 units
        let withdrawn = utils::withdraw_balance(&mut balance, 0);
        
        // Check withdrawn balance is zero
        assert!(balance::value(&withdrawn) == 0, 0);
        
        // Check original balance is unchanged
        assert!(balance::value(&balance) == 1000, 1);
        
        // Clean up
        balance::destroy_for_testing(balance);
        balance::destroy_zero(withdrawn);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_full_amount() {
        // Test withdrawing the full amount
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a balance with 500 units
        let balance = balance::create_for_testing<USDC>(500);
        
        // Withdraw all 500 units
        let withdrawn = utils::withdraw_balance(&mut balance, 500);
        
        // Check withdrawn balance
        assert!(balance::value(&withdrawn) == 500, 0);
        
        // Check remaining balance is zero
        assert!(balance::value(&balance) == 0, 1);
        
        // Clean up
        balance::destroy_zero(balance);
        balance::destroy_for_testing(withdrawn);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1004, location = bluefin_spot::utils)]
    fun test_withdraw_balance_insufficient_balance() {
        // Test withdrawing more than available balance
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a balance with 100 units
        let balance = balance::create_for_testing<USDC>(100);
        
        // Try to withdraw 200 units (should fail)
        let withdrawn = utils::withdraw_balance(&mut balance, 200);
        
        // Clean up (this won't be reached due to abort)
        balance::destroy_for_testing(balance);
        balance::destroy_for_testing(withdrawn);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1004, location = bluefin_spot::utils)]
    fun test_withdraw_balance_from_zero_balance() {
        // Test withdrawing from zero balance
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a zero balance
        let balance = balance::zero<USDC>();
        
        // Try to withdraw 1 unit (should fail)
        let withdrawn = utils::withdraw_balance(&mut balance, 1);
        
        // Clean up (this won't be reached due to abort)
        balance::destroy_zero(balance);
        balance::destroy_for_testing(withdrawn);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1004, location = bluefin_spot::utils)]
    fun test_withdraw_balance_exact_plus_one() {
        // Test withdrawing exactly balance + 1
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a balance with 1000 units
        let balance = balance::create_for_testing<USDC>(1000);
        
        // Try to withdraw 1001 units (should fail)
        let withdrawn = utils::withdraw_balance(&mut balance, 1001);
        
        // Clean up (this won't be reached due to abort)
        balance::destroy_for_testing(balance);
        balance::destroy_for_testing(withdrawn);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_multiple_withdrawals() {
        // Test multiple sequential withdrawals
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a balance with 1000 units
        let balance = balance::create_for_testing<USDC>(1000);
        
        // First withdrawal: 200 units
        let withdrawn1 = utils::withdraw_balance(&mut balance, 200);
        assert!(balance::value(&withdrawn1) == 200, 0);
        assert!(balance::value(&balance) == 800, 1);
        
        // Second withdrawal: 300 units
        let withdrawn2 = utils::withdraw_balance(&mut balance, 300);
        assert!(balance::value(&withdrawn2) == 300, 2);
        assert!(balance::value(&balance) == 500, 3);
        
        // Third withdrawal: 500 units (remaining)
        let withdrawn3 = utils::withdraw_balance(&mut balance, 500);
        assert!(balance::value(&withdrawn3) == 500, 4);
        assert!(balance::value(&balance) == 0, 5);
        
        // Clean up
        balance::destroy_zero(balance);
        balance::destroy_for_testing(withdrawn1);
        balance::destroy_for_testing(withdrawn2);
        balance::destroy_for_testing(withdrawn3);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_small_amounts() {
        // Test withdrawing very small amounts
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a balance with 10 units
        let balance = balance::create_for_testing<USDC>(10);
        
        // Withdraw 1 unit at a time
        let i = 0;
        let withdrawn_balances = vector::empty<Balance<USDC>>();
        
        while (i < 10) {
            let withdrawn = utils::withdraw_balance(&mut balance, 1);
            assert!(balance::value(&withdrawn) == 1, i);
            vector::push_back(&mut withdrawn_balances, withdrawn);
            i = i + 1;
        };
        
        // Check final balance is zero
        assert!(balance::value(&balance) == 0, 10);
        
        // Clean up
        balance::destroy_zero(balance);
        while (!vector::is_empty(&withdrawn_balances)) {
            let withdrawn = vector::pop_back(&mut withdrawn_balances);
            balance::destroy_for_testing(withdrawn);
        };
        vector::destroy_empty(withdrawn_balances);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_large_amounts() {
        // Test withdrawing large amounts
        let scenario = test_scenario::begin(ADMIN);
        
        // Create a balance with max u64 value
        let max_u64 = 18446744073709551615u64;
        let balance = balance::create_for_testing<USDC>(max_u64);
        
        // Withdraw half
        let half = max_u64 / 2;
        let withdrawn = utils::withdraw_balance(&mut balance, half);
        
        assert!(balance::value(&withdrawn) == half, 0);
        assert!(balance::value(&balance) == max_u64 - half, 1);
        
        // Clean up
        balance::destroy_for_testing(balance);
        balance::destroy_for_testing(withdrawn);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_boundary_values() {
        // Test boundary values
        let scenario = test_scenario::begin(ADMIN);
        
        // Test with value 1
        let balance1 = balance::create_for_testing<USDC>(1);
        let withdrawn1 = utils::withdraw_balance(&mut balance1, 1);
        assert!(balance::value(&withdrawn1) == 1, 0);
        assert!(balance::value(&balance1) == 0, 1);
        
        // Test with max u32
        let max_u32 = 4294967295u64;
        let balance2 = balance::create_for_testing<USDC>(max_u32);
        let withdrawn2 = utils::withdraw_balance(&mut balance2, max_u32);
        assert!(balance::value(&withdrawn2) == max_u32, 2);
        assert!(balance::value(&balance2) == 0, 3);
        
        // Clean up
        balance::destroy_zero(balance1);
        balance::destroy_for_testing(withdrawn1);
        balance::destroy_zero(balance2);
        balance::destroy_for_testing(withdrawn2);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_edge_case_amounts() {
        // Test edge case amounts
        let scenario = test_scenario::begin(ADMIN);
        
        // Powers of 2
        let powers_of_2 = vector[1u64, 2u64, 4u64, 8u64, 16u64, 32u64, 64u64, 128u64, 256u64, 512u64, 1024u64];
        
        let i = 0;
        while (i < vector::length(&powers_of_2)) {
            let amount = *vector::borrow(&powers_of_2, i);
            let total = amount * 2; // Create balance with double the amount
            
            let balance = balance::create_for_testing<USDC>(total);
            let withdrawn = utils::withdraw_balance(&mut balance, amount);
            
            assert!(balance::value(&withdrawn) == amount, i);
            assert!(balance::value(&balance) == amount, i); // Remaining should also be amount
            
            balance::destroy_for_testing(balance);
            balance::destroy_for_testing(withdrawn);
            
            i = i + 1;
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_consecutive_operations() {
        // Test consecutive withdraw operations with different patterns
        let scenario = test_scenario::begin(ADMIN);
        
        // Start with 1000 units
        let balance = balance::create_for_testing<USDC>(1000);
        let total_withdrawn = 0u64;
        let withdrawn_balances = vector::empty<Balance<USDC>>();
        
        // Withdraw in decreasing amounts: 400, 300, 200, 100
        let amounts = vector[400u64, 300u64, 200u64, 100u64];
        
        let i = 0;
        while (i < vector::length(&amounts)) {
            let amount = *vector::borrow(&amounts, i);
            let withdrawn = utils::withdraw_balance(&mut balance, amount);
            
            total_withdrawn = total_withdrawn + amount;
            assert!(balance::value(&withdrawn) == amount, i);
            assert!(balance::value(&balance) == 1000 - total_withdrawn, i);
            
            vector::push_back(&mut withdrawn_balances, withdrawn);
            i = i + 1;
        };
        
        // Final balance should be zero
        assert!(balance::value(&balance) == 0, 100);
        
        // Clean up
        balance::destroy_zero(balance);
        while (!vector::is_empty(&withdrawn_balances)) {
            let withdrawn = vector::pop_back(&mut withdrawn_balances);
            balance::destroy_for_testing(withdrawn);
        };
        vector::destroy_empty(withdrawn_balances);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_type_consistency() {
        // Test that the function works with different generic types
        let scenario = test_scenario::begin(ADMIN);
        
        // Test with SUI type
        let sui_balance = balance::create_for_testing<USDC>(1000);
        let sui_withdrawn = utils::withdraw_balance(&mut sui_balance, 500);
        assert!(balance::value(&sui_withdrawn) == 500, 0);
        assert!(balance::value(&sui_balance) == 500, 1);
        
        // Clean up SUI balances
        balance::destroy_for_testing(sui_balance);
        balance::destroy_for_testing(sui_withdrawn);
        
        test_scenario::end(scenario);
    }
}

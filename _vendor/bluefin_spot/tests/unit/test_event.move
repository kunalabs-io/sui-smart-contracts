/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_event {
    use sui::test_scenario;
    use sui::object::{Self, ID};
    use std::string::{Self, String};
    use integer_mate::i32::{Self as MateI32, I32 as MateI32Type};
    use integer_mate::i128::{Self as MateI128, I128 as MateI128Type};
    use bluefin_spot::events;

    // Test constants
    const ADMIN: address = @0xAD;

    //===========================================================//
    //                     Helper Functions                     //
    //===========================================================//

    fun create_test_pool_id(): ID {
        object::id_from_address(@0x1234567890abcdef)
    }

    fun create_test_position_id(): ID {
        object::id_from_address(@0xfedcba0987654321)
    }

    fun create_test_tick(): MateI32Type {
        MateI32::from(100u32)
    }

    fun create_test_negative_tick(): MateI32Type {
        MateI32::neg_from(50u32)
    }

    fun create_test_liquidity_net(): MateI128Type {
        MateI128::from(1000000u128)
    }

    fun create_test_negative_liquidity_net(): MateI128Type {
        MateI128::neg_from(500000u128)
    }

    fun create_test_string(value: vector<u8>): String {
        string::utf8(value)
    }

    //===========================================================//
    //              emit_tick_update_event Tests               //
    //===========================================================//

    #[test]
    fun test_emit_tick_update_event_basic() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let tick_index = create_test_tick();
        let liquidity_gross = 1000000u128;
        let liquidity_net = create_test_liquidity_net();
        
        events::emit_tick_update_event(
            pool_id,
            tick_index,
            liquidity_gross,
            liquidity_net
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_tick_update_event_negative_tick() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let tick_index = create_test_negative_tick();
        let liquidity_gross = 500000u128;
        let liquidity_net = create_test_negative_liquidity_net();
        
        events::emit_tick_update_event(
            pool_id,
            tick_index,
            liquidity_gross,
            liquidity_net
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_tick_update_event_zero_values() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let tick_index = MateI32::zero();
        let liquidity_gross = 0u128;
        let liquidity_net = MateI128::zero();
        
        events::emit_tick_update_event(
            pool_id,
            tick_index,
            liquidity_gross,
            liquidity_net
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_tick_update_event_maximum_values() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let tick_index = MateI32::from(443636u32); // Maximum valid tick
        let liquidity_gross = 340282366920938463463374607431768211455u128; // Max u128
        let liquidity_net = MateI128::from(170141183460469231731687303715884105727u128); // Max positive i128
        
        events::emit_tick_update_event(
            pool_id,
            tick_index,
            liquidity_gross,
            liquidity_net
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_tick_update_event_minimum_values() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let tick_index = MateI32::neg_from(443636u32); // Minimum valid tick
        let liquidity_gross = 1u128; // Minimum non-zero liquidity
        let liquidity_net = MateI128::neg_from(170141183460469231731687303715884105727u128); // Max negative i128
        
        events::emit_tick_update_event(
            pool_id,
            tick_index,
            liquidity_gross,
            liquidity_net
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_tick_update_event_multiple_calls() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        
        // First update
        events::emit_tick_update_event(
            pool_id,
            MateI32::from(100u32),
            1000000u128,
            MateI128::from(500000u128)
        );
        
        // Second update with different values
        events::emit_tick_update_event(
            pool_id,
            MateI32::from(200u32),
            2000000u128,
            MateI128::from(1000000u128)
        );
        
        // Third update with negative values
        events::emit_tick_update_event(
            pool_id,
            MateI32::neg_from(150u32),
            750000u128,
            MateI128::neg_from(250000u128)
        );
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //            emit_user_reward_collected Tests             //
    //===========================================================//

    #[test]
    fun test_emit_user_reward_collected_basic() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let reward_type = create_test_string(b"0x123::reward_coin::REWARD");
        let reward_symbol = create_test_string(b"RWD");
        let reward_decimals = 9u8;
        let reward_amount = 1000000u64;
        let sequence_number = 12345u128;
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            reward_type,
            reward_symbol,
            reward_decimals,
            reward_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_reward_collected_zero_amount() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let reward_type = create_test_string(b"0x456::token::TOKEN");
        let reward_symbol = create_test_string(b"TKN");
        let reward_decimals = 6u8;
        let reward_amount = 0u64; // Zero reward amount
        let sequence_number = 0u128; // Zero sequence number
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            reward_type,
            reward_symbol,
            reward_decimals,
            reward_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_reward_collected_maximum_values() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let reward_type = create_test_string(b"0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff::very_long_module_name::VERY_LONG_STRUCT_NAME");
        let reward_symbol = create_test_string(b"VERYLONGSYMBOL");
        let reward_decimals = 255u8; // Maximum u8 value
        let reward_amount = 18446744073709551615u64; // Maximum u64 value
        let sequence_number = 340282366920938463463374607431768211455u128; // Maximum u128 value
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            reward_type,
            reward_symbol,
            reward_decimals,
            reward_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_reward_collected_different_decimals() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let reward_amount = 1000000u64;
        let sequence_number = 100u128;
        
        // Test with different decimal values
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x789::test::TEST"),
            create_test_string(b"D0"),
            0u8,
            reward_amount,
            sequence_number
        );
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x789::test::TEST"),
            create_test_string(b"D6"),
            6u8,
            reward_amount,
            sequence_number + 1
        );
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x789::test::TEST"),
            create_test_string(b"D9"),
            9u8,
            reward_amount,
            sequence_number + 2
        );
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x789::test::TEST"),
            create_test_string(b"D18"),
            18u8,
            reward_amount,
            sequence_number + 3
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_reward_collected_multiple_rewards() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        
        // Simulate collecting multiple different rewards
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x1::sui::SUI"),
            create_test_string(b"SUI"),
            9u8,
            1000000000u64, // 1 SUI
            1u128
        );
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x2::usdc::USDC"),
            create_test_string(b"USDC"),
            6u8,
            1000000u64, // 1 USDC
            2u128
        );
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x3::reward::REWARD"),
            create_test_string(b"RWD"),
            18u8,
            1000000000000000000u64, // 1 RWD with 18 decimals
            3u128
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_reward_collected_empty_strings() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let reward_type = create_test_string(b""); // Empty string
        let reward_symbol = create_test_string(b""); // Empty string
        let reward_decimals = 0u8;
        let reward_amount = 1u64;
        let sequence_number = 1u128;
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            reward_type,
            reward_symbol,
            reward_decimals,
            reward_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //             emit_user_fee_collected Tests               //
    //===========================================================//

    #[test]
    fun test_emit_user_fee_collected_basic() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let coin_a_amount = 1000000u64;
        let coin_b_amount = 2000000u64;
        let pool_coin_a_amount = 50000000u64;
        let pool_coin_b_amount = 100000000u64;
        let sequence_number = 12345u128;
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            coin_a_amount,
            coin_b_amount,
            pool_coin_a_amount,
            pool_coin_b_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_fee_collected_zero_amounts() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let coin_a_amount = 0u64;
        let coin_b_amount = 0u64;
        let pool_coin_a_amount = 1000000u64;
        let pool_coin_b_amount = 2000000u64;
        let sequence_number = 0u128;
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            coin_a_amount,
            coin_b_amount,
            pool_coin_a_amount,
            pool_coin_b_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_fee_collected_only_coin_a_fee() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let coin_a_amount = 500000u64; // Only coin A fee collected
        let coin_b_amount = 0u64; // No coin B fee
        let pool_coin_a_amount = 10000000u64;
        let pool_coin_b_amount = 20000000u64;
        let sequence_number = 100u128;
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            coin_a_amount,
            coin_b_amount,
            pool_coin_a_amount,
            pool_coin_b_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_fee_collected_only_coin_b_fee() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let coin_a_amount = 0u64; // No coin A fee
        let coin_b_amount = 750000u64; // Only coin B fee collected
        let pool_coin_a_amount = 15000000u64;
        let pool_coin_b_amount = 30000000u64;
        let sequence_number = 200u128;
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            coin_a_amount,
            coin_b_amount,
            pool_coin_a_amount,
            pool_coin_b_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_fee_collected_maximum_values() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let coin_a_amount = 18446744073709551615u64; // Max u64
        let coin_b_amount = 18446744073709551615u64; // Max u64
        let pool_coin_a_amount = 18446744073709551615u64; // Max u64
        let pool_coin_b_amount = 18446744073709551615u64; // Max u64
        let sequence_number = 340282366920938463463374607431768211455u128; // Max u128
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            coin_a_amount,
            coin_b_amount,
            pool_coin_a_amount,
            pool_coin_b_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_fee_collected_small_amounts() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let coin_a_amount = 1u64; // Minimum non-zero amount
        let coin_b_amount = 1u64; // Minimum non-zero amount
        let pool_coin_a_amount = 1000u64;
        let pool_coin_b_amount = 2000u64;
        let sequence_number = 1u128;
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            coin_a_amount,
            coin_b_amount,
            pool_coin_a_amount,
            pool_coin_b_amount,
            sequence_number
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_fee_collected_multiple_collections() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        
        // Simulate multiple fee collections over time
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            100000u64,
            200000u64,
            5000000u64,
            10000000u64,
            1u128
        );
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            150000u64,
            300000u64,
            5100000u64,
            10200000u64,
            2u128
        );
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            75000u64,
            125000u64,
            5175000u64,
            10325000u64,
            3u128
        );
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            200000u64,
            400000u64,
            5375000u64,
            10725000u64,
            4u128
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_emit_user_fee_collected_different_positions() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id_1 = create_test_position_id();
        let position_id_2 = object::id_from_address(@0x1111111111111111);
        let position_id_3 = object::id_from_address(@0x2222222222222222);
        
        // Collect fees from different positions
        events::emit_user_fee_collected(
            pool_id,
            position_id_1,
            100000u64,
            200000u64,
            5000000u64,
            10000000u64,
            1u128
        );
        
        events::emit_user_fee_collected(
            pool_id,
            position_id_2,
            150000u64,
            250000u64,
            5150000u64,
            10250000u64,
            2u128
        );
        
        events::emit_user_fee_collected(
            pool_id,
            position_id_3,
            75000u64,
            175000u64,
            5225000u64,
            10425000u64,
            3u128
        );
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                Integration Tests                        //
    //===========================================================//

    #[test]
    fun test_all_events_integration() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        let tick_index = create_test_tick();
        let sequence_number = 1000u128;
        
        // Emit tick update event
        events::emit_tick_update_event(
            pool_id,
            tick_index,
            1000000u128,
            create_test_liquidity_net()
        );
        
        // Emit user reward collected event
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x123::reward::REWARD"),
            create_test_string(b"RWD"),
            9u8,
            500000u64,
            sequence_number
        );
        
        // Emit user fee collected event
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            100000u64,
            200000u64,
            5000000u64,
            10000000u64,
            sequence_number + 1
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_events_with_same_ids() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        
        // Test that the same IDs can be used across different event types
        events::emit_tick_update_event(
            pool_id,
            MateI32::from(50u32),
            500000u128,
            MateI128::from(250000u128)
        );
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x456::token::TOKEN"),
            create_test_string(b"TKN"),
            6u8,
            1000000u64,
            100u128
        );
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            50000u64,
            100000u64,
            2500000u64,
            5000000u64,
            101u128
        );
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_events_sequence_ordering() {
        let scenario = test_scenario::begin(ADMIN);
        
        let pool_id = create_test_pool_id();
        let position_id = create_test_position_id();
        
        // Test events with sequential sequence numbers
        let base_sequence = 1000u128;
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x1::reward1::R1"),
            create_test_string(b"R1"),
            9u8,
            1000000u64,
            base_sequence
        );
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            100000u64,
            200000u64,
            5000000u64,
            10000000u64,
            base_sequence + 1
        );
        
        events::emit_user_reward_collected(
            pool_id,
            position_id,
            create_test_string(b"0x2::reward2::R2"),
            create_test_string(b"R2"),
            6u8,
            2000000u64,
            base_sequence + 2
        );
        
        events::emit_user_fee_collected(
            pool_id,
            position_id,
            150000u64,
            250000u64,
            5150000u64,
            10250000u64,
            base_sequence + 3
        );
        
        test_scenario::end(scenario);
    }
}

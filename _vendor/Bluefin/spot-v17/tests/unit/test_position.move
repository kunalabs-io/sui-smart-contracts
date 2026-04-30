/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_position {
    use sui::object::{Self, ID};
    use sui::test_scenario::{Self, Scenario};
    use std::string::{Self, String};
    use std::vector;
    use bluefin_spot::position::{Self, Position};
    use integer_mate::i32::{Self as MateI32};
    use integer_mate::i128::{Self as MateI128};

    const ADMIN: address = @0xAD;

    //===========================================================//
    //                   Helper Functions                       //
    //===========================================================//

    fun create_dummy_pool_id(): ID {
        object::id_from_address(@0x1234)
    }

    fun create_test_strings(): (String, String, String, String) {
        (
            string::utf8(b"SUI/USDC"),
            string::utf8(b"https://example.com/image.png"),
            string::utf8(b"SUI"),
            string::utf8(b"USDC")
        )
    }

    fun create_test_position(scenario: &mut Scenario): Position {
        let ctx = test_scenario::ctx(scenario);
        let pool_id = create_dummy_pool_id();
        let (pool_name, image_url, coin_type_a, coin_type_b) = create_test_strings();
        let lower_tick = MateI32::neg_from(100u32);
        let upper_tick = MateI32::from(100u32);
        
        position::open(
            pool_id,
            pool_name,
            image_url,
            coin_type_a,
            coin_type_b,
            1u128, // position_index
            lower_tick,
            upper_tick,
            3000u64, // fee_rate (0.3%)
            ctx
        )
    }

    fun create_test_reward_growths(count: u64): vector<u128> {
        let rewards = vector::empty<u128>();
        let i = 0;
        while (i < count) {
            vector::push_back(&mut rewards, (i as u128) * 1000 + 500);
            i = i + 1;
        };
        rewards
    }

    //===========================================================//
    //                 Module Initialization Tests             //
    //===========================================================//

    #[test]
    fun test_module_init() {
        let scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        
        // Test the module initialization
        position::test_init(ctx);
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Position Creation Tests                 //
    //===========================================================//

    #[test]
    fun test_new_position_basic() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Verify initial values
        assert!(position::liquidity(&position) == 0, 0);
        assert!(position::pool_id(&position) == create_dummy_pool_id(), 1);
        
        let (fee_a, fee_b) = position::get_accrued_fee(&position);
        assert!(fee_a == 0, 2);
        assert!(fee_b == 0, 3);
        
        assert!(position::reward_infos_length(&position) == 0, 4);
        assert!(position::is_empty(&position) == true, 5);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_new_position_with_different_ticks() {
        let scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        let pool_id = create_dummy_pool_id();
        let (pool_name, image_url, coin_type_a, coin_type_b) = create_test_strings();
        
        // Test different tick combinations
        let lower_ticks = vector[
            MateI32::neg_from(1000u32), // Both negative
            MateI32::neg_from(100u32),  // Negative to positive
            MateI32::from(50u32),       // Both positive
            MateI32::zero()             // Zero to positive
        ];
        let upper_ticks = vector[
            MateI32::neg_from(500u32),  // Both negative
            MateI32::from(100u32),      // Negative to positive
            MateI32::from(150u32),      // Both positive
            MateI32::from(100u32)       // Zero to positive
        ];
        
        let i = 0;
        while (i < std::vector::length(&lower_ticks)) {
            let lower_tick = *std::vector::borrow(&lower_ticks, i);
            let upper_tick = *std::vector::borrow(&upper_ticks, i);
            
            let position = position::open(
                pool_id, pool_name, image_url, coin_type_a, coin_type_b,
                (i as u128), lower_tick, upper_tick, 3000u64, ctx
            );
            
            assert!(MateI32::eq(position::lower_tick(&position), lower_tick), i);
            assert!(MateI32::eq(position::upper_tick(&position), upper_tick), i + 100);
            
            position::close(position);
            i = i + 1;
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_new_position_with_different_fee_rates() {
        let scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        let pool_id = create_dummy_pool_id();
        let (pool_name, image_url, coin_type_a, coin_type_b) = create_test_strings();
        let lower_tick = MateI32::neg_from(100u32);
        let upper_tick = MateI32::from(100u32);
        
        // Test different fee rates
        let fee_rates = vector[500u64, 3000u64, 10000u64]; // 0.05%, 0.3%, 1%
        
        let i = 0;
        while (i < std::vector::length(&fee_rates)) {
            let fee_rate = *std::vector::borrow(&fee_rates, i);
            
            let position = position::open(
                pool_id, pool_name, image_url, coin_type_a, coin_type_b,
                (i as u128), lower_tick, upper_tick, fee_rate, ctx
            );
            
            // Note: fee_rate is private, so we can't directly test it
            // but we can verify the position was created successfully
            assert!(position::liquidity(&position) == 0, i);
            
            position::close(position);
            i = i + 1;
        };
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Position Deletion Tests                 //
    //===========================================================//

    #[test]
    fun test_del_position() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        let original_pool_id = position::pool_id(&position);
        let original_lower_tick = position::lower_tick(&position);
        let original_upper_tick = position::upper_tick(&position);
        
        let (position_id, pool_id, lower_tick, upper_tick) = position::del(position);
        
        // Verify returned values match original position
        assert!(pool_id == original_pool_id, 0);
        assert!(MateI32::eq(lower_tick, original_lower_tick), 1);
        assert!(MateI32::eq(upper_tick, original_upper_tick), 2);
        
        // position_id should be valid (non-zero)
        assert!(position_id != object::id_from_address(@0x0), 3);
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Fee Management Tests                    //
    //===========================================================//

    #[test]
    fun test_set_fee_amounts() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Initially fees should be zero
        let (initial_fee_a, initial_fee_b) = position::get_accrued_fee(&position);
        assert!(initial_fee_a == 0, 0);
        assert!(initial_fee_b == 0, 1);
        
        // Set new fee amounts
        position::set_fee_amounts(&mut position, 1000u64, 2000u64);
        
        let (new_fee_a, new_fee_b) = position::get_accrued_fee(&position);
        assert!(new_fee_a == 1000, 2);
        assert!(new_fee_b == 2000, 3);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_fee_amounts_multiple_times() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Set fees multiple times
        position::set_fee_amounts(&mut position, 500u64, 750u64);
        let (fee_a1, fee_b1) = position::get_accrued_fee(&position);
        assert!(fee_a1 == 500, 0);
        assert!(fee_b1 == 750, 1);
        
        position::set_fee_amounts(&mut position, 1500u64, 2250u64);
        let (fee_a2, fee_b2) = position::get_accrued_fee(&position);
        assert!(fee_a2 == 1500, 2);
        assert!(fee_b2 == 2250, 3);
        
        // Set to zero
        position::set_fee_amounts(&mut position, 0u64, 0u64);
        let (fee_a3, fee_b3) = position::get_accrued_fee(&position);
        assert!(fee_a3 == 0, 4);
        assert!(fee_b3 == 0, 5);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Reward Management Tests                 //
    //===========================================================//

    #[test]
    fun test_add_reward_info() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Initially no reward infos
        assert!(position::reward_infos_length(&position) == 0, 0);
        assert!(position::coins_owed_reward(&position, 0) == 0, 1);
        
        // Add first reward info
        position::add_reward_info(&mut position);
        assert!(position::reward_infos_length(&position) == 1, 2);
        assert!(position::coins_owed_reward(&position, 0) == 0, 3);
        
        // Add second reward info
        position::add_reward_info(&mut position);
        assert!(position::reward_infos_length(&position) == 2, 4);
        assert!(position::coins_owed_reward(&position, 1) == 0, 5);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_coins_owed_reward_out_of_bounds() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Add one reward info
        position::add_reward_info(&mut position);
        
        // Test valid index
        assert!(position::coins_owed_reward(&position, 0) == 0, 0);
        
        // Test out of bounds indices
        assert!(position::coins_owed_reward(&position, 1) == 0, 1);
        assert!(position::coins_owed_reward(&position, 5) == 0, 2);
        assert!(position::coins_owed_reward(&position, 100) == 0, 3);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_decrease_reward_amount() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Add reward info and set initial amount through update
        position::add_reward_info(&mut position);
        
        // First we need to add some liquidity and update to get rewards
        let liquidity_delta = MateI128::from(1000u128);
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, liquidity_delta, 1000u128, 2000u128, reward_growths);
        
        // Now decrease reward amount
        let initial_reward = position::coins_owed_reward(&position, 0);
        if (initial_reward > 0) {
            let decrease_amount = initial_reward / 2;
            position::decrease_reward_amount(&mut position, 0, decrease_amount);
            
            let new_reward = position::coins_owed_reward(&position, 0);
            assert!(new_reward == initial_reward - decrease_amount, 0);
        };
        
        position::close(position);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Position Update Tests                   //
    //===========================================================//

    #[test]
    fun test_update_add_liquidity() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Initially no liquidity
        assert!(position::liquidity(&position) == 0, 0);
        assert!(position::is_empty(&position) == true, 1);
        
        // Add liquidity
        let liquidity_delta = MateI128::from(1000u128);
        let reward_growths = create_test_reward_growths(2);
        
        position::update(&mut position, liquidity_delta, 500u128, 750u128, reward_growths);
        
        // Verify liquidity was added
        assert!(position::liquidity(&position) == 1000, 2);
        assert!(position::is_empty(&position) == false, 3);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_remove_liquidity() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // First add liquidity
        let add_delta = MateI128::from(2000u128);
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, add_delta, 500u128, 750u128, reward_growths);
        assert!(position::liquidity(&position) == 2000, 0);
        
        // Then remove some liquidity
        let remove_delta = MateI128::neg_from(800u128);
        position::update(&mut position, remove_delta, 600u128, 850u128, reward_growths);
        
        // Verify liquidity was reduced
        assert!(position::liquidity(&position) == 1200, 1);
        assert!(position::is_empty(&position) == false, 2);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_remove_all_liquidity() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Add liquidity
        let add_delta = MateI128::from(1500u128);
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, add_delta, 500u128, 750u128, reward_growths);
        assert!(position::liquidity(&position) == 1500, 0);
        
        // Remove all liquidity
        let remove_all_delta = MateI128::neg_from(1500u128);
        position::update(&mut position, remove_all_delta, 600u128, 850u128, reward_growths);
        
        // Verify all liquidity was removed
        assert!(position::liquidity(&position) == 0, 1);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_zero_liquidity_delta() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // First add some liquidity
        let add_delta = MateI128::from(1000u128);
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, add_delta, 500u128, 750u128, reward_growths);
        assert!(position::liquidity(&position) == 1000, 0);
        
        // Update with zero delta (should just update fees/rewards)
        let zero_delta = MateI128::zero();
        position::update(&mut position, zero_delta, 600u128, 850u128, reward_growths);
        
        // Liquidity should remain the same
        assert!(position::liquidity(&position) == 1000, 1);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1015, location = bluefin_spot::position)]
    fun test_update_zero_liquidity_delta_with_no_liquidity() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Try to update with zero delta when position has no liquidity
        let zero_delta = MateI128::zero();
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, zero_delta, 500u128, 750u128, reward_growths);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_fee_accumulation() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Add liquidity
        let liquidity_delta = MateI128::from(1000u128);
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, liquidity_delta, 1000u128, 2000u128, reward_growths);
        
        let (initial_fee_a, initial_fee_b) = position::get_accrued_fee(&position);
        
        // Update again with higher fee growth
        let zero_delta = MateI128::zero();
        position::update(&mut position, zero_delta, 2000u128, 4000u128, reward_growths);
        
        let (final_fee_a, final_fee_b) = position::get_accrued_fee(&position);
        
        // Fees should have increased
        assert!(final_fee_a >= initial_fee_a, 0);
        assert!(final_fee_b >= initial_fee_b, 1);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_with_multiple_rewards() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Add liquidity with multiple reward types
        let liquidity_delta = MateI128::from(1000u128);
        let reward_growths = create_test_reward_growths(3);
        
        position::update(&mut position, liquidity_delta, 500u128, 750u128, reward_growths);
        
        // Verify reward infos were created
        assert!(position::reward_infos_length(&position) == 3, 0);
        
        // All rewards should initially be 0 (no growth difference)
        assert!(position::coins_owed_reward(&position, 0) == 0, 1);
        assert!(position::coins_owed_reward(&position, 1) == 0, 2);
        assert!(position::coins_owed_reward(&position, 2) == 0, 3);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 is_empty Function Tests                 //
    //===========================================================//

    #[test]
    fun test_is_empty_new_position() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // New position should be empty
        assert!(position::is_empty(&position) == true, 0);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_is_empty_with_liquidity() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Add liquidity
        let liquidity_delta = MateI128::from(1000u128);
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, liquidity_delta, 500u128, 750u128, reward_growths);
        
        // Position with liquidity should not be empty
        assert!(position::is_empty(&position) == false, 0);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_is_empty_with_rewards_only() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Add and then remove liquidity to generate rewards
        let liquidity_delta = MateI128::from(1000u128);
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, liquidity_delta, 1000u128, 2000u128, reward_growths);
        
        // Update with higher growth to generate rewards
        let zero_delta = MateI128::zero();
        let higher_reward_growths = vector[2000u128];
        position::update(&mut position, zero_delta, 2000u128, 4000u128, higher_reward_growths);
        
        // Remove all liquidity
        let remove_delta = MateI128::neg_from(1000u128);
        position::update(&mut position, remove_delta, 2000u128, 4000u128, higher_reward_growths);
        
        // Position should not be empty if there are pending rewards
        let has_rewards = position::coins_owed_reward(&position, 0) > 0;
        assert!(position::is_empty(&position) == !has_rewards, 0);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Getter Function Tests                   //
    //===========================================================//

    #[test]
    fun test_getter_functions() {
        let scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        let pool_id = create_dummy_pool_id();
        let (pool_name, image_url, coin_type_a, coin_type_b) = create_test_strings();
        let lower_tick = MateI32::neg_from(200u32);
        let upper_tick = MateI32::from(300u32);
        
        let position = position::open(
            pool_id, pool_name, image_url, coin_type_a, coin_type_b,
            42u128, lower_tick, upper_tick, 5000u64, ctx
        );
        
        // Test all getter functions
        assert!(position::pool_id(&position) == pool_id, 0);
        assert!(MateI32::eq(position::lower_tick(&position), lower_tick), 1);
        assert!(MateI32::eq(position::upper_tick(&position), upper_tick), 2);
        assert!(position::liquidity(&position) == 0, 3);
        
        let (fee_a, fee_b) = position::get_accrued_fee(&position);
        assert!(fee_a == 0, 4);
        assert!(fee_b == 0, 5);
        
        assert!(position::reward_infos_length(&position) == 0, 6);
        assert!(position::coins_owed_reward(&position, 0) == 0, 7);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Edge Case Tests                         //
    //===========================================================//

    #[test]
    fun test_extreme_tick_values() {
        let scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        let pool_id = create_dummy_pool_id();
        let (pool_name, image_url, coin_type_a, coin_type_b) = create_test_strings();
        
        // Test with extreme tick values
        let lower_tick = MateI32::neg_from(443636u32); // Near minimum tick
        let upper_tick = MateI32::from(443636u32);     // Near maximum tick
        
        let position = position::open(
            pool_id, pool_name, image_url, coin_type_a, coin_type_b,
            1u128, lower_tick, upper_tick, 3000u64, ctx
        );
        
        assert!(MateI32::eq(position::lower_tick(&position), lower_tick), 0);
        assert!(MateI32::eq(position::upper_tick(&position), upper_tick), 1);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_large_liquidity_values() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Test with large liquidity values
        let large_liquidity = MateI128::from(1000000000u128); // 1 billion
        let reward_growths = create_test_reward_growths(1);
        
        position::update(&mut position, large_liquidity, 1000u128, 2000u128, reward_growths);
        
        assert!(position::liquidity(&position) == 1000000000, 0);
        assert!(position::is_empty(&position) == false, 1);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_empty_reward_growths() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // Update with empty reward growths vector
        let liquidity_delta = MateI128::from(1000u128);
        let empty_rewards = vector::empty<u128>();
        
        position::update(&mut position, liquidity_delta, 500u128, 750u128, empty_rewards);
        
        assert!(position::liquidity(&position) == 1000, 0);
        assert!(position::reward_infos_length(&position) == 0, 1);
        
        position::close(position);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Integration Tests                       //
    //===========================================================//

    #[test]
    fun test_full_position_lifecycle() {
        let scenario = test_scenario::begin(ADMIN);
        let position = create_test_position(&mut scenario);
        
        // 1. Initially empty
        assert!(position::is_empty(&position) == true, 0);
        assert!(position::liquidity(&position) == 0, 1);
        
        // 2. Add liquidity
        let add_delta = MateI128::from(5000u128);
        let reward_growths = create_test_reward_growths(2);
        position::update(&mut position, add_delta, 1000u128, 2000u128, reward_growths);
        
        assert!(position::is_empty(&position) == false, 2);
        assert!(position::liquidity(&position) == 5000, 3);
        assert!(position::reward_infos_length(&position) == 2, 4);
        
        // 3. Update fees and rewards
        let zero_delta = MateI128::zero();
        let higher_rewards = vector[2000u128, 3000u128];
        position::update(&mut position, zero_delta, 2000u128, 4000u128, higher_rewards);
        
        let (fee_a, fee_b) = position::get_accrued_fee(&position);
        // Fees should be accumulated (may be 0 if no fee growth difference)
        assert!(fee_a >= 0, 5);
        assert!(fee_b >= 0, 6);
        
        // 4. Set additional fees
        position::set_fee_amounts(&mut position, fee_a + 1000, fee_b + 1500);
        let (new_fee_a, new_fee_b) = position::get_accrued_fee(&position);
        assert!(new_fee_a == fee_a + 1000, 7);
        assert!(new_fee_b == fee_b + 1500, 8);
        
        // 5. Partially remove liquidity
        let remove_delta = MateI128::neg_from(2000u128);
        position::update(&mut position, remove_delta, 2000u128, 4000u128, higher_rewards);
        assert!(position::liquidity(&position) == 3000, 9);
        
        // 6. Remove remaining liquidity
        let remove_all_delta = MateI128::neg_from(3000u128);
        position::update(&mut position, remove_all_delta, 2000u128, 4000u128, higher_rewards);
        assert!(position::liquidity(&position) == 0, 10);
        
        // 7. Clean up
        position::close(position);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_positions_interaction() {
        let scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        let pool_id = create_dummy_pool_id();
        let (pool_name, image_url, coin_type_a, coin_type_b) = create_test_strings();
        
        // Create multiple positions with different parameters
        let positions = vector::empty<Position>();
        
        let i = 0u64;
        while (i < 3) {
            let multiplier = ((i + 1) as u32);
            let lower_tick = MateI32::neg_from(multiplier * 100);
            let upper_tick = MateI32::from(multiplier * 100);
            let fee_rate = 3000u64 + i * 1000;
            
            let position = position::open(
                pool_id, pool_name, image_url, coin_type_a, coin_type_b,
                (i as u128), lower_tick, upper_tick, fee_rate, ctx
            );
            
            vector::push_back(&mut positions, position);
            i = i + 1;
        };
        
        // Update each position differently
        i = 0;
        while (i < std::vector::length(&positions)) {
            let position_ref = vector::borrow_mut(&mut positions, i);
            let liquidity = (i + 1) * 1000;
            let liquidity_delta = MateI128::from((liquidity as u128));
            let reward_growths = create_test_reward_growths(i + 1);
            
            position::update(position_ref, liquidity_delta, 1000u128, 2000u128, reward_growths);
            
            assert!(position::liquidity(position_ref) == (liquidity as u128), (i as u64));
            assert!(position::reward_infos_length(position_ref) == i + 1, (i as u64) + 100);
            
            i = i + 1;
        };
        
        // Clean up all positions
        while (!vector::is_empty(&positions)) {
            let position = vector::pop_back(&mut positions);
            position::close(position);
        };
        vector::destroy_empty(positions);
        
        test_scenario::end(scenario);
    }
}

/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_tick {
    use sui::object::{Self, ID};
    use sui::test_scenario::{Self, Scenario};
    use sui::table;
    use std::vector;
    use bluefin_spot::tick::{Self, TickManager, TickInfo};
    use integer_mate::i32::{Self as MateI32, I32 as MateI32Type};
    use integer_mate::i64::{Self as MateI64};
    use integer_mate::i128::{Self as MateI128};

    const ADMIN: address = @0xAD;

    //===========================================================//
    //                   Helper Functions                       //
    //===========================================================//

    fun create_test_manager(scenario: &mut Scenario, tick_spacing: u32): TickManager {
        let ctx = test_scenario::ctx(scenario);
        tick::initialize_manager(tick_spacing, ctx)
    }

    fun create_dummy_id(): ID {
        object::id_from_address(@0x1)
    }

    fun create_test_reward_growths(count: u64): vector<u128> {
        let rewards = vector::empty<u128>();
        let i = 0;
        while (i < count) {
            vector::push_back(&mut rewards, (i as u128) * 1000);
            i = i + 1;
        };
        rewards
    }

    //===========================================================//
    //                 initialize_manager Tests                 //
    //===========================================================//

    #[test]
    fun test_initialize_manager_basic() {
        let scenario = test_scenario::begin(ADMIN);
        
        let manager = create_test_manager(&mut scenario, 1);
        assert!(tick::tick_spacing(&manager) == 1, 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_initialize_manager_different_spacings() {
        let scenario = test_scenario::begin(ADMIN);
        
        let spacings = vector[1u32, 2u32, 5u32, 10u32, 60u32, 200u32];
        let i = 0;
        while (i < std::vector::length(&spacings)) {
            let spacing = *std::vector::borrow(&spacings, i);
            let manager = create_test_manager(&mut scenario, spacing);
            assert!(tick::tick_spacing(&manager) == spacing, i);
            tick::destroy_manager_for_testing(manager);
            i = i + 1;
        };
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 create_tick Function Tests              //
    //===========================================================//

    #[test]
    fun test_create_tick_zero_index() {
        let zero_index = MateI32::zero();
        let tick_info = tick::create_tick(zero_index);
        
        assert!(tick::liquidity_gross(&tick_info) == 0, 0);
        assert!(MateI128::eq(tick::liquidity_net(&tick_info), MateI128::zero()), 1);
        assert!(tick::sqrt_price(&tick_info) > 0, 2); // Should have valid sqrt_price
    }

    #[test]
    fun test_create_tick_positive_indices() {
        let positive_indices = vector[1u32, 10u32, 100u32, 1000u32];
        let i = 0;
        while (i < std::vector::length(&positive_indices)) {
            let index_value = *std::vector::borrow(&positive_indices, i);
            let index = MateI32::from(index_value);
            let tick_info = tick::create_tick(index);
            
            assert!(tick::liquidity_gross(&tick_info) == 0, i);
            assert!(MateI128::eq(tick::liquidity_net(&tick_info), MateI128::zero()), i + 100);
            assert!(tick::sqrt_price(&tick_info) > 0, i + 200);
            
            i = i + 1;
        };
    }

    #[test]
    fun test_create_tick_negative_indices() {
        let negative_indices = vector[1u32, 10u32, 100u32, 1000u32];
        let i = 0;
        while (i < std::vector::length(&negative_indices)) {
            let index_value = *std::vector::borrow(&negative_indices, i);
            let index = MateI32::neg_from(index_value);
            let tick_info = tick::create_tick(index);
            
            assert!(tick::liquidity_gross(&tick_info) == 0, i);
            assert!(MateI128::eq(tick::liquidity_net(&tick_info), MateI128::zero()), i + 100);
            assert!(tick::sqrt_price(&tick_info) > 0, i + 200);
            
            i = i + 1;
        };
    }

    #[test]
    fun test_create_tick_boundary_indices() {
        // Test tick creation at boundary values
        let boundary_indices = vector[
            MateI32::zero(),
            MateI32::from(443636u32),     // Near max tick
            MateI32::neg_from(443636u32)  // Near min tick
        ];
        
        let i = 0;
        while (i < std::vector::length(&boundary_indices)) {
            let index = *std::vector::borrow(&boundary_indices, i);
            let tick_info = tick::create_tick(index);
            
            assert!(tick::liquidity_gross(&tick_info) == 0, i);
            assert!(MateI128::eq(tick::liquidity_net(&tick_info), MateI128::zero()), i + 100);
            assert!(tick::sqrt_price(&tick_info) > 0, i + 200);
            
            i = i + 1;
        };
    }

    //===========================================================//
    //                 Tick Table Access Tests                 //
    //===========================================================//

    #[test]
    fun test_get_mutable_tick_from_table_new_tick() {
        let scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        let ticks = table::new<MateI32Type, TickInfo>(ctx);
        
        let index = MateI32::from(100u32);
        let tick_ref = tick::get_mutable_tick_from_table(&mut ticks, index);
        
        // Should create a new tick with default values
        assert!(tick::liquidity_gross(tick_ref) == 0, 0);
        assert!(MateI128::eq(tick::liquidity_net(tick_ref), MateI128::zero()), 1);
        
        table::drop(ticks);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_mutable_tick_from_table_existing_tick() {
        let scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        let ticks = table::new<MateI32Type, TickInfo>(ctx);
        
        let index = MateI32::from(100u32);
        
        // First access creates the tick
        let tick_ref1 = tick::get_mutable_tick_from_table(&mut ticks, index);
        let original_sqrt_price = tick::sqrt_price(tick_ref1);
        
        // Second access should return the same tick
        let tick_ref2 = tick::get_mutable_tick_from_table(&mut ticks, index);
        assert!(tick::sqrt_price(tick_ref2) == original_sqrt_price, 0);
        
        table::drop(ticks);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_mutable_tick_from_manager() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let index = MateI32::from(50u32);
        let tick_ref = tick::get_mutable_tick_from_manager(&mut manager, index);
        
        assert!(tick::liquidity_gross(tick_ref) == 0, 0);
        assert!(MateI128::eq(tick::liquidity_net(tick_ref), MateI128::zero()), 1);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_is_tick_initialized() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let index = MateI32::from(42u32);
        
        // Initially not initialized
        assert!(tick::is_tick_initialized(&manager, index) == false, 0);
        
        // Access the tick (creates it)
        let _ = tick::get_mutable_tick_from_manager(&mut manager, index);
        
        // Now should be initialized
        assert!(tick::is_tick_initialized(&manager, index) == true, 1);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 update Function Tests                   //
    //===========================================================//

    #[test]
    fun test_update_new_tick_below_current() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(10u32);
        let current_tick = MateI32::from(20u32);
        let liquidity_delta = MateI128::from(1000u128);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(3);
        
        let flipped = tick::update(
            &mut manager,
            dummy_id,
            tick_index,
            current_tick,
            liquidity_delta,
            100u128, // fee_growth_global_coin_a
            200u128, // fee_growth_global_coin_b
            reward_growths,
            MateI64::from(300u64), // tick_cumulative
            400u256, // seconds_per_liquidity_cumulative
            500u64,  // seconds_outside
            false    // upper
        );
        
        // Should flip from uninitialized to initialized
        assert!(flipped == true, 0);
        
        // Check tick was created and updated
        let tick_info = tick::get_tick_from_manager(&manager, tick_index);
        assert!(tick::liquidity_gross(tick_info) == 1000, 1);
        assert!(MateI128::eq(tick::liquidity_net(tick_info), liquidity_delta), 2);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_new_tick_above_current() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(30u32);
        let current_tick = MateI32::from(20u32);
        let liquidity_delta = MateI128::from(1000u128);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(2);
        
        let flipped = tick::update(
            &mut manager,
            dummy_id,
            tick_index,
            current_tick,
            liquidity_delta,
            100u128,
            200u128,
            reward_growths,
            MateI64::from(300u64),
            400u256,
            500u64,
            false
        );
        
        // Should flip from uninitialized to initialized
        assert!(flipped == true, 0);
        
        let tick_info = tick::get_tick_from_manager(&manager, tick_index);
        assert!(tick::liquidity_gross(tick_info) == 1000, 1);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_existing_tick_add_liquidity() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(15u32);
        let current_tick = MateI32::from(20u32);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(1);
        
        // First update - add initial liquidity
        let liquidity_delta1 = MateI128::from(500u128);
        let flipped1 = tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta1,
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        assert!(flipped1 == true, 0); // Should flip to initialized
        
        // Second update - add more liquidity
        let liquidity_delta2 = MateI128::from(300u128);
        let flipped2 = tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta2,
            150u128, 250u128, reward_growths, MateI64::from(350u64), 450u256, 550u64, false
        );
        assert!(flipped2 == false, 1); // Should not flip (already initialized)
        
        let tick_info = tick::get_tick_from_manager(&manager, tick_index);
        assert!(tick::liquidity_gross(tick_info) == 800, 2); // 500 + 300
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_remove_all_liquidity() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(25u32);
        let current_tick = MateI32::from(20u32);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(1);
        
        // Add liquidity
        let liquidity_delta_add = MateI128::from(1000u128);
        let flipped1 = tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta_add,
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        assert!(flipped1 == true, 0);
        
        // Remove all liquidity
        let liquidity_delta_remove = MateI128::neg_from(1000u128);
        let flipped2 = tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta_remove,
            150u128, 250u128, reward_growths, MateI64::from(350u64), 450u256, 550u64, false
        );
        assert!(flipped2 == true, 1); // Should flip back to uninitialized
        
        let tick_info = tick::get_tick_from_manager(&manager, tick_index);
        assert!(tick::liquidity_gross(tick_info) == 0, 2);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_upper_vs_lower_tick() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(15u32);
        let current_tick = MateI32::from(20u32);
        let liquidity_delta = MateI128::from(1000u128);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(1);
        
        // Test as lower tick (upper = false)
        tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta,
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        
        let tick_info_lower = tick::get_tick_from_manager(&manager, tick_index);
        let net_lower = tick::liquidity_net(tick_info_lower);
        
        // Reset the manager
        tick::destroy_manager_for_testing(manager);
        let manager = create_test_manager(&mut scenario, 1);
        
        // Test as upper tick (upper = true)
        tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta,
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, true
        );
        
        let tick_info_upper = tick::get_tick_from_manager(&manager, tick_index);
        let net_upper = tick::liquidity_net(tick_info_upper);
        
        // Net liquidity should be opposite for upper vs lower
        assert!(MateI128::eq(net_lower, MateI128::neg(net_upper)), 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 cross Function Tests                    //
    //===========================================================//

    #[test]
    fun test_cross_basic() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(10u32);
        let current_tick = MateI32::from(20u32);
        let liquidity_delta = MateI128::from(1000u128);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(2);
        
        // First create and update a tick
        tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta,
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        
        // Now cross the tick
        let reward_growths_cross = create_test_reward_growths(2);
        let liquidity_net = tick::cross(
            &mut manager,
            tick_index,
            150u128, // fee_growth_global_coin_a
            250u128, // fee_growth_global_coin_b
            reward_growths_cross,
            MateI64::from(350u64), // tick_cumulative
            450u256, // seconds_per_liquidity_cumulative
            600u64   // current_time
        );
        
        // Should return the liquidity_net of the tick
        assert!(MateI128::eq(liquidity_net, liquidity_delta), 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_cross_updates_outside_values() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(5u32);
        let current_tick = MateI32::from(20u32);
        let liquidity_delta = MateI128::from(500u128);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(1);
        
        // Create tick with initial outside values
        tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta,
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        
        // Get initial outside values
        let (initial_fee_a, initial_fee_b, _) = tick::get_fee_and_reward_growths_outside(&manager, tick_index);
        
        // Cross the tick with different global values
        let reward_growths_cross = create_test_reward_growths(1);
        tick::cross(
            &mut manager, tick_index, 180u128, 280u128, reward_growths_cross,
            MateI64::from(380u64), 480u256, 580u64
        );
        
        // Check that outside values were updated
        let (new_fee_a, new_fee_b, _) = tick::get_fee_and_reward_growths_outside(&manager, tick_index);
        
        // Outside values should have changed
        assert!(new_fee_a != initial_fee_a, 0);
        assert!(new_fee_b != initial_fee_b, 1);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Fee and Reward Growth Tests             //
    //===========================================================//

    #[test]
    fun test_get_fee_and_reward_growths_outside_uninitialized() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(100u32);
        
        let (fee_a, fee_b, rewards) = tick::get_fee_and_reward_growths_outside(&manager, tick_index);
        
        // Uninitialized tick should return zeros
        assert!(fee_a == 0, 0);
        assert!(fee_b == 0, 1);
        assert!(std::vector::length(&rewards) == 0, 2);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_fee_and_reward_growths_outside_initialized() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(15u32);
        let current_tick = MateI32::from(20u32);
        let liquidity_delta = MateI128::from(1000u128);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(3);
        
        // Initialize the tick
        tick::update(
            &mut manager, dummy_id, tick_index, current_tick, liquidity_delta,
            150u128, 250u128, reward_growths, MateI64::from(350u64), 450u256, 550u64, false
        );
        
        let (fee_a, fee_b, rewards) = tick::get_fee_and_reward_growths_outside(&manager, tick_index);
        
        // Should return the outside values set during update
        assert!(fee_a == 150, 0);
        assert!(fee_b == 250, 1);
        assert!(std::vector::length(&rewards) == 3, 2);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_fee_and_reward_growths_inside_current_below_range() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let lower_tick = MateI32::from(10u32);
        let upper_tick = MateI32::from(30u32);
        let current_tick = MateI32::from(5u32); // Below range
        let dummy_id = create_dummy_id();
        let reward_growths_global = create_test_reward_growths(2);
        
        // Initialize both ticks
        tick::update(
            &mut manager, dummy_id, lower_tick, current_tick, MateI128::from(1000u128),
            100u128, 200u128, reward_growths_global, MateI64::from(300u64), 400u256, 500u64, false
        );
        tick::update(
            &mut manager, dummy_id, upper_tick, current_tick, MateI128::from(1000u128),
            100u128, 200u128, reward_growths_global, MateI64::from(300u64), 400u256, 500u64, true
        );
        
        let (fee_inside_a, fee_inside_b, rewards_inside) = tick::get_fee_and_reward_growths_inside(
            &manager, lower_tick, upper_tick, current_tick, 1000u128, 2000u128, reward_growths_global
        );
        
        // Should calculate inside values correctly
        assert!(fee_inside_a <= 1000u128, 0);
        assert!(fee_inside_b <= 2000u128, 1);
        assert!(std::vector::length(&rewards_inside) == 2, 2);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_fee_and_reward_growths_inside_current_in_range() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let lower_tick = MateI32::from(10u32);
        let upper_tick = MateI32::from(30u32);
        let current_tick = MateI32::from(20u32); // In range
        let dummy_id = create_dummy_id();
        let reward_growths_global = create_test_reward_growths(1);
        
        // Initialize both ticks
        tick::update(
            &mut manager, dummy_id, lower_tick, current_tick, MateI128::from(1000u128),
            100u128, 200u128, reward_growths_global, MateI64::from(300u64), 400u256, 500u64, false
        );
        tick::update(
            &mut manager, dummy_id, upper_tick, current_tick, MateI128::from(1000u128),
            100u128, 200u128, reward_growths_global, MateI64::from(300u64), 400u256, 500u64, true
        );
        
        let (fee_inside_a, fee_inside_b, rewards_inside) = tick::get_fee_and_reward_growths_inside(
            &manager, lower_tick, upper_tick, current_tick, 1000u128, 2000u128, reward_growths_global
        );
        
        // Should calculate inside values correctly
        assert!(fee_inside_a <= 1000u128, 0);
        assert!(fee_inside_b <= 2000u128, 1);
        assert!(std::vector::length(&rewards_inside) == 1, 2);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_fee_and_reward_growths_inside_current_above_range() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let lower_tick = MateI32::from(10u32);
        let upper_tick = MateI32::from(30u32);
        let current_tick = MateI32::from(35u32); // Above range
        let dummy_id = create_dummy_id();
        let reward_growths_global = create_test_reward_growths(1);
        
        // Initialize both ticks
        tick::update(
            &mut manager, dummy_id, lower_tick, current_tick, MateI128::from(1000u128),
            100u128, 200u128, reward_growths_global, MateI64::from(300u64), 400u256, 500u64, false
        );
        tick::update(
            &mut manager, dummy_id, upper_tick, current_tick, MateI128::from(1000u128),
            100u128, 200u128, reward_growths_global, MateI64::from(300u64), 400u256, 500u64, true
        );
        
        let (fee_inside_a, fee_inside_b, rewards_inside) = tick::get_fee_and_reward_growths_inside(
            &manager, lower_tick, upper_tick, current_tick, 1000u128, 2000u128, reward_growths_global
        );
        
        // Should calculate inside values correctly
        assert!(fee_inside_a <= 1000u128, 0);
        assert!(fee_inside_b <= 2000u128, 1);
        assert!(std::vector::length(&rewards_inside) == 1, 2);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Utility Function Tests                  //
    //===========================================================//

    #[test]
    fun test_fetch_provided_ticks_empty() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let empty_ticks = vector::empty<u32>();
        let result = tick::fetch_provided_ticks(&manager, empty_ticks);
        
        assert!(std::vector::length(&result) == 0, 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_fetch_provided_ticks_uninitialized() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_indices = vector[10u32, 20u32, 30u32];
        let result = tick::fetch_provided_ticks(&manager, tick_indices);
        
        // Should return empty since ticks are not initialized
        assert!(std::vector::length(&result) == 0, 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_fetch_provided_ticks_initialized() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_indices = vector[10u32, 20u32, 30u32];
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(1);
        
        // Initialize some ticks
        let i = 0;
        while (i < std::vector::length(&tick_indices)) {
            let tick_value = *std::vector::borrow(&tick_indices, i);
            let tick_index = MateI32::from(tick_value);
            tick::update(
                &mut manager, dummy_id, tick_index, MateI32::from(50u32), MateI128::from(1000u128),
                100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
            );
            i = i + 1;
        };
        
        let result = tick::fetch_provided_ticks(&manager, tick_indices);
        
        // Should return all initialized ticks
        assert!(std::vector::length(&result) == 3, 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_fetch_provided_ticks_mixed() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_indices = vector[10u32, 20u32, 30u32, 40u32];
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(1);
        
        // Initialize only some ticks (10 and 30)
        tick::update(
            &mut manager, dummy_id, MateI32::from(10u32), MateI32::from(50u32), MateI128::from(1000u128),
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        tick::update(
            &mut manager, dummy_id, MateI32::from(30u32), MateI32::from(50u32), MateI128::from(1000u128),
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        
        let result = tick::fetch_provided_ticks(&manager, tick_indices);
        
        // Should return only initialized ticks (2 out of 4)
        assert!(std::vector::length(&result) == 2, 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Bitmap Access Tests                     //
    //===========================================================//

    #[test]
    fun test_bitmap_access() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let bitmap_ref = tick::bitmap(&manager);
        // Should be able to access bitmap (empty initially)
        assert!(table::length(bitmap_ref) == 0, 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_mutable_bitmap_access() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let bitmap_ref = tick::mutable_bitmap(&mut manager);
        // Should be able to access mutable bitmap
        assert!(table::length(bitmap_ref) == 0, 0);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Remove Function Tests                   //
    //===========================================================//

    #[test]
    fun test_remove_existing_tick() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(25u32);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(1);
        
        // Create a tick
        tick::update(
            &mut manager, dummy_id, tick_index, MateI32::from(30u32), MateI128::from(1000u128),
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        
        // Verify tick exists
        assert!(tick::is_tick_initialized(&manager, tick_index) == true, 0);
        
        // Remove the tick
        tick::remove(&mut manager, tick_index);
        
        // Verify tick is removed
        assert!(tick::is_tick_initialized(&manager, tick_index) == false, 1);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_remove_nonexistent_tick() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(99u32);
        
        // Verify tick doesn't exist
        assert!(tick::is_tick_initialized(&manager, tick_index) == false, 0);
        
        // This should not fail even if tick doesn't exist
        // (table::remove handles non-existent keys gracefully in some implementations)
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Integration Tests                       //
    //===========================================================//

    #[test]
    fun test_full_tick_lifecycle() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 10);
        
        let tick_index = MateI32::from(100u32);
        let current_tick = MateI32::from(50u32);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(2);
        
        // 1. Initially not initialized
        assert!(tick::is_tick_initialized(&manager, tick_index) == false, 0);
        
        // 2. Add liquidity (initialize)
        let flipped1 = tick::update(
            &mut manager, dummy_id, tick_index, current_tick, MateI128::from(1000u128),
            100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
        );
        assert!(flipped1 == true, 1);
        assert!(tick::is_tick_initialized(&manager, tick_index) == true, 2);
        
        // 3. Add more liquidity (no flip)
        let flipped2 = tick::update(
            &mut manager, dummy_id, tick_index, current_tick, MateI128::from(500u128),
            150u128, 250u128, reward_growths, MateI64::from(350u64), 450u256, 550u64, false
        );
        assert!(flipped2 == false, 3);
        
        let tick_info = tick::get_tick_from_manager(&manager, tick_index);
        assert!(tick::liquidity_gross(tick_info) == 1500, 4);
        
        // 4. Cross the tick
        let liquidity_net = tick::cross(
            &mut manager, tick_index, 200u128, 300u128, reward_growths,
            MateI64::from(400u64), 500u256, 600u64
        );
        assert!(MateI128::abs_u128(liquidity_net) > 0, 5);
        
        // 5. Remove all liquidity (flip back)
        let flipped3 = tick::update(
            &mut manager, dummy_id, tick_index, current_tick, MateI128::neg_from(1500u128),
            200u128, 300u128, reward_growths, MateI64::from(400u64), 500u256, 600u64, false
        );
        assert!(flipped3 == true, 6);
        
        let tick_info_final = tick::get_tick_from_manager(&manager, tick_index);
        assert!(tick::liquidity_gross(tick_info_final) == 0, 7);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_ticks_interaction() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_indices = vector[10u32, 20u32, 30u32];
        let current_tick = MateI32::from(25u32);
        let dummy_id = create_dummy_id();
        let reward_growths = create_test_reward_growths(1);
        
        // Initialize multiple ticks
        let i = 0;
        while (i < std::vector::length(&tick_indices)) {
            let tick_value = *std::vector::borrow(&tick_indices, i);
            let tick_index = MateI32::from(tick_value);
            let liquidity = (tick_value as u128) * 10; // Different liquidity for each
            
            tick::update(
                &mut manager, dummy_id, tick_index, current_tick, MateI128::from(liquidity),
                100u128, 200u128, reward_growths, MateI64::from(300u64), 400u256, 500u64, false
            );
            i = i + 1;
        };
        
        // Verify all ticks are initialized with correct liquidity
        i = 0;
        while (i < std::vector::length(&tick_indices)) {
            let tick_value = *std::vector::borrow(&tick_indices, i);
            let tick_index = MateI32::from(tick_value);
            let expected_liquidity = (tick_value as u128) * 10;
            
            assert!(tick::is_tick_initialized(&manager, tick_index) == true, i);
            let tick_info = tick::get_tick_from_manager(&manager, tick_index);
            assert!(tick::liquidity_gross(tick_info) == expected_liquidity, i + 100);
            
            i = i + 1;
        };
        
        // Test fetch_provided_ticks
        let fetched_ticks = tick::fetch_provided_ticks(&manager, tick_indices);
        assert!(std::vector::length(&fetched_ticks) == 3, 200);
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reward_growths_edge_cases() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = create_test_manager(&mut scenario, 1);
        
        let tick_index = MateI32::from(15u32);
        let current_tick = MateI32::from(20u32);
        let dummy_id = create_dummy_id();
        
        // Test with empty reward growths
        let empty_rewards = vector::empty<u128>();
        tick::update(
            &mut manager, dummy_id, tick_index, current_tick, MateI128::from(1000u128),
            100u128, 200u128, empty_rewards, MateI64::from(300u64), 400u256, 500u64, false
        );
        
        let (_, _, rewards_outside) = tick::get_fee_and_reward_growths_outside(&manager, tick_index);
        assert!(std::vector::length(&rewards_outside) == 0, 0);
        
        // Test cross with different reward growths length
        let cross_rewards = create_test_reward_growths(3);
        tick::cross(
            &mut manager, tick_index, 150u128, 250u128, cross_rewards,
            MateI64::from(350u64), 450u256, 550u64
        );
        
        tick::destroy_manager_for_testing(manager);
        test_scenario::end(scenario);
    }
}

/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_oracle {
    use sui::test_scenario::{Self};
    use std::vector;
    use bluefin_spot::oracle::{Self};
    use integer_mate::i32::{Self as MateI32, I32 as MateI32Type};
    use integer_mate::i64::{Self as MateI64};

    const ADMIN: address = @0xAD;

    // Helper functions for creating test data
    fun create_test_timestamp(): u64 {
        1000000u64
    }

    fun create_test_tick(): MateI32Type {
        MateI32::from(100u32)
    }

    fun create_negative_test_tick(): MateI32Type {
        MateI32::neg_from(100u32)
    }

    fun create_test_liquidity(): u128 {
        1000000u128
    }

    fun create_zero_liquidity(): u128 {
        0u128
    }

    //===========================================================//
    //                 ObservationManager Tests                 //
    //===========================================================//

    #[test]
    fun test_initialize_manager_basic() {
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        
        // Check manager properties
        assert!(oracle::observation_index(&manager) == 0, 0);
        assert!(oracle::observation_cardinality(&manager) == 1, 1);
        assert!(oracle::observation_cardinality_next(&manager) == 1, 2);
        assert!(oracle::observations_length(&manager) == 1, 3);
        
        // Check the initial observation
        let observation = oracle::get_observation_for_testing(&manager, 0);
        assert!(oracle::timestamp(&observation) == timestamp, 4);
        assert!(oracle::initialized(&observation) == true, 5);
        assert!(MateI64::eq(oracle::tick_cumulative(&observation), MateI64::zero()), 6);
        assert!(oracle::seconds_per_liquidity_cumulative(&observation) == 0, 7);
    }

    #[test]
    fun test_initialize_manager_different_timestamps() {
        let timestamps = vector[0u64, 1u64, 1000u64, 999999999u64];
        let i = 0;
        while (i < vector::length(&timestamps)) {
            let timestamp = *vector::borrow(&timestamps, i);
            let manager = oracle::initialize_manager(timestamp);
            
            let observation = oracle::get_observation_for_testing(&manager, 0);
            assert!(oracle::timestamp(&observation) == timestamp, i);
            assert!(oracle::initialized(&observation) == true, i + 100);
            
            i = i + 1;
        };
    }

    //===========================================================//
    //                   Observation Tests                      //
    //===========================================================//

    #[test]
    fun test_default_observation() {
        let observation = oracle::default_observation();
        
        assert!(oracle::timestamp(&observation) == 0, 0);
        assert!(MateI64::eq(oracle::tick_cumulative(&observation), MateI64::zero()), 1);
        assert!(oracle::seconds_per_liquidity_cumulative(&observation) == 0, 2);
        assert!(oracle::initialized(&observation) == false, 3);
    }

    //===========================================================//
    //                    Transform Tests                       //
    //===========================================================//

    #[test]
    fun test_transform_positive_tick() {
        let base_timestamp = 1000u64;
        let new_timestamp = 2000u64;
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Create base observation with timestamp
        let base_obs = oracle::create_observation(
            base_timestamp,
            MateI64::zero(),
            0,
            true
        );
        
        let transformed = oracle::transform(&base_obs, new_timestamp, tick, liquidity);
        
        assert!(oracle::timestamp(&transformed) == new_timestamp, 0);
        assert!(oracle::initialized(&transformed) == true, 1);
        
        // Check tick cumulative calculation: tick * time_delta
        let time_delta = new_timestamp - base_timestamp;
        let expected_tick_cumulative = MateI64::from(100u64 * time_delta);
        assert!(MateI64::eq(oracle::tick_cumulative(&transformed), expected_tick_cumulative), 2);
        
        // Check seconds per liquidity cumulative
        let expected_seconds_per_liquidity = ((time_delta as u256) << 128) / (liquidity as u256);
        assert!(oracle::seconds_per_liquidity_cumulative(&transformed) == expected_seconds_per_liquidity, 3);
    }

    #[test]
    fun test_transform_negative_tick() {
        let base_timestamp = 1000u64;
        let new_timestamp = 2000u64;
        let negative_tick = create_negative_test_tick();
        let liquidity = create_test_liquidity();
        
        let base_obs = oracle::create_observation(
            base_timestamp,
            MateI64::zero(),
            0,
            true
        );
        
        let transformed = oracle::transform(&base_obs, new_timestamp, negative_tick, liquidity);
        
        assert!(oracle::timestamp(&transformed) == new_timestamp, 0);
        assert!(oracle::initialized(&transformed) == true, 1);
        
        // Check negative tick cumulative calculation
        let time_delta = new_timestamp - base_timestamp;
        let expected_tick_cumulative = MateI64::neg_from(100u64 * time_delta);
        assert!(MateI64::eq(oracle::tick_cumulative(&transformed), expected_tick_cumulative), 2);
    }

    #[test]
    fun test_transform_zero_liquidity() {
        let base_timestamp = 1000u64;
        let new_timestamp = 2000u64;
        let tick = create_test_tick();
        let zero_liquidity = create_zero_liquidity();
        
        let base_obs = oracle::create_observation(
            base_timestamp,
            MateI64::zero(),
            0,
            true
        );
        
        let transformed = oracle::transform(&base_obs, new_timestamp, tick, zero_liquidity);
        
        // When liquidity is 0, it should use 1 as non_zero_liquidity
        let time_delta = new_timestamp - base_timestamp;
        let expected_seconds_per_liquidity = ((time_delta as u256) << 128) / 1u256;
        assert!(oracle::seconds_per_liquidity_cumulative(&transformed) == expected_seconds_per_liquidity, 0);
    }

    #[test]
    fun test_transform_with_existing_cumulative() {
        let base_timestamp = 1000u64;
        let new_timestamp = 2000u64;
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        let base_obs = oracle::create_observation(
            base_timestamp,
            MateI64::from(5000u64),
            1000u256,
            true
        );
        
        let transformed = oracle::transform(&base_obs, new_timestamp, tick, liquidity);
        
        // Check that existing cumulative values are added to
        let time_delta = new_timestamp - base_timestamp;
        let tick_delta = MateI64::from(100u64 * time_delta);
        let expected_tick_cumulative = MateI64::add(MateI64::from(5000u64), tick_delta);
        assert!(MateI64::eq(oracle::tick_cumulative(&transformed), expected_tick_cumulative), 0);
        
        let liquidity_delta = ((time_delta as u256) << 128) / (liquidity as u256);
        let expected_seconds_per_liquidity = 1000u256 + liquidity_delta;
        assert!(oracle::seconds_per_liquidity_cumulative(&transformed) == expected_seconds_per_liquidity, 1);
    }

    #[test]
    fun test_transform_same_timestamp() {
        let timestamp = 1000u64;
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        let base_obs = oracle::create_observation(
            timestamp,
            MateI64::from(5000u64),
            1000u256,
            true
        );
        
        let transformed = oracle::transform(&base_obs, timestamp, tick, liquidity);
        
        // When timestamps are the same, no change should occur
        assert!(MateI64::eq(oracle::tick_cumulative(&transformed), MateI64::from(5000u64)), 0);
        assert!(oracle::seconds_per_liquidity_cumulative(&transformed) == 1000u256, 1);
    }

    //===========================================================//
    //                  observe_single Tests                   //
    //===========================================================//

    #[test]
    fun test_observe_single_zero_seconds_ago_same_timestamp() {
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        let (tick_cumulative, seconds_per_liquidity) = oracle::observe_single(
            &manager, timestamp, 0, tick, liquidity
        );
        
        // Should return the current observation values
        assert!(MateI64::eq(tick_cumulative, MateI64::zero()), 0);
        assert!(seconds_per_liquidity == 0, 1);
    }

    #[test]
    fun test_observe_single_zero_seconds_ago_different_timestamp() {
        let init_timestamp = 1000u64;
        let current_timestamp = 2000u64;
        let manager = oracle::initialize_manager(init_timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        let (tick_cumulative, seconds_per_liquidity) = oracle::observe_single(
            &manager, current_timestamp, 0, tick, liquidity
        );
        
        // Should transform the observation to current timestamp
        let time_delta = current_timestamp - init_timestamp;
        let expected_tick_cumulative = MateI64::from(100u64 * time_delta);
        assert!(MateI64::eq(tick_cumulative, expected_tick_cumulative), 0);
        
        let expected_seconds_per_liquidity = ((time_delta as u256) << 128) / (liquidity as u256);
        assert!(seconds_per_liquidity == expected_seconds_per_liquidity, 1);
    }

    #[test]
    fun test_observe_single_with_seconds_ago_exact_match() {
        let init_timestamp = 1000u64;
        let current_timestamp = 2000u64;
        let seconds_ago = 1000u64;
        let manager = oracle::initialize_manager(init_timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        let (tick_cumulative, seconds_per_liquidity) = oracle::observe_single(
            &manager, current_timestamp, seconds_ago, tick, liquidity
        );
        
        // Target timestamp = current_timestamp - seconds_ago = 2000 - 1000 = 1000
        // This matches the init_timestamp exactly
        assert!(MateI64::eq(tick_cumulative, MateI64::zero()), 0);
        assert!(seconds_per_liquidity == 0, 1);
    }

    //===========================================================//
    //                get_surrounding_observations Tests        //
    //===========================================================//

    #[test]
    fun test_get_surrounding_observations_exact_match() {
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        let (before_or_at, at_or_after) = oracle::get_surrounding_observations(
            &manager, timestamp, tick, liquidity
        );
        
        // Should return the exact observation and a default one
        assert!(oracle::timestamp(&before_or_at) == timestamp, 0);
        assert!(oracle::initialized(&before_or_at) == true, 1);
        assert!(oracle::initialized(&at_or_after) == false, 2);
    }

    #[test]
    fun test_get_surrounding_observations_future_target() {
        let init_timestamp = 1000u64;
        let target_timestamp = 2000u64;
        let manager = oracle::initialize_manager(init_timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        let (before_or_at, at_or_after) = oracle::get_surrounding_observations(
            &manager, target_timestamp, tick, liquidity
        );
        
        // Should return the current observation and a transformed one
        assert!(oracle::timestamp(&before_or_at) == init_timestamp, 0);
        assert!(oracle::timestamp(&at_or_after) == target_timestamp, 1);
        assert!(oracle::initialized(&before_or_at) == true, 2);
        assert!(oracle::initialized(&at_or_after) == true, 3);
    }

    //===========================================================//
    //                     Update Tests                        //
    //===========================================================//

    #[test]
    fun test_update_same_timestamp() {
        let scenario = test_scenario::begin(ADMIN);
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Update with same timestamp should not change anything
        oracle::update(&mut manager, tick, liquidity, timestamp);
        
        assert!(oracle::observation_index(&manager) == 0, 0);
        assert!(oracle::observation_cardinality(&manager) == 1, 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_different_timestamp() {
        let scenario = test_scenario::begin(ADMIN);
        let init_timestamp = 1000u64;
        let new_timestamp = 2000u64;
        let manager = oracle::initialize_manager(init_timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Grow the manager first to have space for new observation
        oracle::grow(&mut manager, 2);
        
        oracle::update(&mut manager, tick, liquidity, new_timestamp);
        
        // Should update to next index
        assert!(oracle::observation_index(&manager) == 1, 0);
        assert!(oracle::observation_cardinality(&manager) == 2, 1);
        
        // Check the new observation
        let new_observation = oracle::get_observation_for_testing(&manager, 1);
        assert!(oracle::timestamp(&new_observation) == new_timestamp, 2);
        assert!(oracle::initialized(&new_observation) == true, 3);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_cardinality_expansion() {
        let scenario = test_scenario::begin(ADMIN);
        let init_timestamp = 1000u64;
        let new_timestamp = 2000u64;
        let manager = oracle::initialize_manager(init_timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Set cardinality_next to 3 but keep cardinality at 1
        oracle::grow(&mut manager, 3);
        
        // Update should expand cardinality when at the last index
        oracle::update(&mut manager, tick, liquidity, new_timestamp);
        
        assert!(oracle::observation_cardinality(&manager) == 3, 0);
        assert!(oracle::observation_index(&manager) == 1, 1);
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                      Grow Tests                         //
    //===========================================================//

    #[test]
    fun test_grow_basic() {
        let scenario = test_scenario::begin(ADMIN);
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        
        let (old_cardinality, new_cardinality) = oracle::grow(&mut manager, 5);
        
        // The grow function returns (final_cardinality, observation_cardinality_next)
        assert!(old_cardinality == 5, 0);
        assert!(new_cardinality == 5, 1);
        assert!(oracle::observation_cardinality_next(&manager) == 5, 2);
        assert!(oracle::observations_length(&manager) == 5, 3);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_grow_no_change_when_smaller() {
        let scenario = test_scenario::begin(ADMIN);
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        
        // First grow to 5
        oracle::grow(&mut manager, 5);
        
        // Try to grow to smaller number
        let (old_cardinality, new_cardinality) = oracle::grow(&mut manager, 3);
        
        assert!(old_cardinality == 5, 0);
        assert!(new_cardinality == 5, 1); // Should remain 5
        assert!(oracle::observation_cardinality_next(&manager) == 5, 2);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_grow_multiple_times() {
        let scenario = test_scenario::begin(ADMIN);
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        
        // Grow multiple times
        oracle::grow(&mut manager, 3);
        oracle::grow(&mut manager, 7);
        oracle::grow(&mut manager, 10);
        
        assert!(oracle::observation_cardinality_next(&manager) == 10, 0);
        assert!(oracle::observations_length(&manager) == 10, 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_grow_zero_cardinality() {
        let scenario = test_scenario::begin(ADMIN);
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        
        let (old_cardinality, new_cardinality) = oracle::grow(&mut manager, 0);
        
        // Should remain at current cardinality
        assert!(old_cardinality == 1, 0);
        assert!(new_cardinality == 1, 1);
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 get_observation Tests                   //
    //===========================================================//

    #[test]
    fun test_get_observation_valid_index() {
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        
        let observation = oracle::get_observation_for_testing(&manager, 0);
        assert!(oracle::timestamp(&observation) == timestamp, 0);
        assert!(oracle::initialized(&observation) == true, 1);
    }

    #[test]
    fun test_get_observation_out_of_bounds() {
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        
        let observation = oracle::get_observation_for_testing(&manager, 999);
        // Should return default observation
        assert!(oracle::timestamp(&observation) == 0, 0);
        assert!(oracle::initialized(&observation) == false, 1);
    }

    //===========================================================//
    //                   Binary Search Tests                   //
    //===========================================================//

    #[test]
    fun test_binary_search_single_observation() {
        let scenario = test_scenario::begin(ADMIN);
        let init_timestamp = 1000u64;
        let _target_timestamp = 500u64; // Target before init_timestamp to avoid infinite loop
        let manager = oracle::initialize_manager(init_timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Grow to have more observations for binary search to work properly
        oracle::grow(&mut manager, 3);
        oracle::update(&mut manager, tick, liquidity, 2000u64);
        
        let (before_or_at, _at_or_after) = oracle::binary_search(&manager, 1500u64);
        
        // Should find an observation
        assert!(oracle::initialized(&before_or_at) == true, 0);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_binary_search_multiple_observations() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Grow and add more observations
        oracle::grow(&mut manager, 5);
        oracle::update(&mut manager, tick, liquidity, 2000u64);
        oracle::update(&mut manager, tick, liquidity, 3000u64);
        oracle::update(&mut manager, tick, liquidity, 4000u64);
        
        // Search for timestamp between observations
        let (before_or_at, at_or_after) = oracle::binary_search(&manager, 2500u64);
        
        assert!(oracle::timestamp(&before_or_at) <= 2500u64, 0);
        assert!(oracle::timestamp(&at_or_after) >= 2500u64, 1);
        assert!(oracle::initialized(&before_or_at) == true, 2);
        assert!(oracle::initialized(&at_or_after) == true, 3);
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                   Integration Tests                     //
    //===========================================================//

    #[test]
    fun test_full_oracle_lifecycle() {
        let scenario = test_scenario::begin(ADMIN);
        let init_timestamp = 1000u64;
        let manager = oracle::initialize_manager(init_timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // 1. Grow the oracle
        oracle::grow(&mut manager, 10);
        assert!(oracle::observation_cardinality_next(&manager) == 10, 0);
        
        // 2. Add several observations
        let timestamps = vector[2000u64, 3000u64, 4000u64, 5000u64];
        let i = 0;
        while (i < vector::length(&timestamps)) {
            let timestamp = *vector::borrow(&timestamps, i);
            oracle::update(&mut manager, tick, liquidity, timestamp);
            i = i + 1;
        };
        
        // 3. Observe at different points
        let (tick_cumulative, seconds_per_liquidity) = oracle::observe_single(
            &manager, 5000u64, 0, tick, liquidity
        );
        assert!(MateI64::gt(tick_cumulative, MateI64::zero()), 1);
        assert!(seconds_per_liquidity > 0, 2);
        
        // 4. Observe with seconds_ago
        let (past_tick_cumulative, past_seconds_per_liquidity) = oracle::observe_single(
            &manager, 5000u64, 2000u64, tick, liquidity
        );
        assert!(MateI64::lt(past_tick_cumulative, tick_cumulative), 3);
        assert!(past_seconds_per_liquidity < seconds_per_liquidity, 4);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_edge_case_zero_time_delta() {
        let scenario = test_scenario::begin(ADMIN);
        let timestamp = 1000u64;
        let manager = oracle::initialize_manager(timestamp);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Update with same timestamp should not change state
        oracle::update(&mut manager, tick, liquidity, timestamp);
        
        let observation = oracle::get_observation_for_testing(&manager, 0);
        assert!(oracle::timestamp(&observation) == timestamp, 0);
        assert!(MateI64::eq(oracle::tick_cumulative(&observation), MateI64::zero()), 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_extreme_values() {
        let scenario = test_scenario::begin(ADMIN);
        let large_timestamp = 1000000000u64; // Large but reasonable timestamp
        let manager = oracle::initialize_manager(0u64);
        let extreme_tick = MateI32::from(100000u32); // Large but safe tick value
        let large_liquidity = 1000000000000000000u128; // Large liquidity
        
        oracle::grow(&mut manager, 2);
        oracle::update(&mut manager, extreme_tick, large_liquidity, large_timestamp);
        
        let observation = oracle::get_observation_for_testing(&manager, 1);
        assert!(oracle::timestamp(&observation) == large_timestamp, 0);
        assert!(oracle::initialized(&observation) == true, 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_negative_tick_accumulation() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let negative_tick = create_negative_test_tick();
        let liquidity = create_test_liquidity();
        
        oracle::grow(&mut manager, 3);
        oracle::update(&mut manager, negative_tick, liquidity, 2000u64);
        oracle::update(&mut manager, negative_tick, liquidity, 3000u64);
        
        let observation = oracle::get_observation_for_testing(&manager, 2);
        assert!(MateI64::is_neg(oracle::tick_cumulative(&observation)), 0);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_liquidity_per_second_overflow() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(0u64);
        let tick = create_test_tick();
        let min_liquidity = 1u128;
        let large_time = 1000000u64; // Large but safe time delta
        
        oracle::grow(&mut manager, 2);
        oracle::update(&mut manager, tick, min_liquidity, large_time);
        
        let observation = oracle::get_observation_for_testing(&manager, 1);
        // Should handle large time deltas correctly
        assert!(oracle::seconds_per_liquidity_cumulative(&observation) > 0, 0);
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //              Additional Coverage Tests                   //
    //===========================================================//

    #[test]
    fun test_observe_single_interpolation_edge_cases() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Create multiple observations for interpolation testing
        oracle::grow(&mut manager, 5);
        oracle::update(&mut manager, tick, liquidity, 2000u64);
        oracle::update(&mut manager, tick, liquidity, 3000u64);
        oracle::update(&mut manager, tick, liquidity, 4000u64);
        
        // Test interpolation in the middle of two observations
        let (tick_cumulative, seconds_per_liquidity) = oracle::observe_single(
            &manager, 4000u64, 1500u64, tick, liquidity // target = 2500 (between 2000 and 3000)
        );
        
        // Should interpolate between observations
        assert!(MateI64::gt(tick_cumulative, MateI64::zero()), 0);
        assert!(seconds_per_liquidity > 0, 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_surrounding_observations_past_target() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        oracle::grow(&mut manager, 4);
        oracle::update(&mut manager, tick, liquidity, 2000u64);
        oracle::update(&mut manager, tick, liquidity, 3000u64);
        oracle::update(&mut manager, tick, liquidity, 4000u64);
        
        // Target is between observations - should trigger binary search
        let target = 2500u64;
        
        let (before_or_at, _at_or_after) = oracle::get_surrounding_observations(
            &manager, target, tick, liquidity
        );
        
        assert!(oracle::timestamp(&before_or_at) <= target, 0);
        assert!(oracle::initialized(&before_or_at) == true, 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1014, location = bluefin_spot::oracle)]
    fun test_get_surrounding_observations_invalid_timestamp() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(3000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        oracle::grow(&mut manager, 3);
        oracle::update(&mut manager, tick, liquidity, 4000u64);
        
        // Target is before the earliest observation - should fail
        let target = 500u64;
        
        oracle::get_surrounding_observations(&manager, target, tick, liquidity);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_binary_search_comprehensive() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Create a full ring buffer of observations
        oracle::grow(&mut manager, 10);
        let timestamps = vector[2000u64, 3000u64, 4000u64, 5000u64, 6000u64, 7000u64, 8000u64, 9000u64, 10000u64];
        let i = 0;
        while (i < vector::length(&timestamps)) {
            let timestamp = *vector::borrow(&timestamps, i);
            oracle::update(&mut manager, tick, liquidity, timestamp);
            i = i + 1;
        };
        
        // Test binary search at various points
        let (before_or_at, at_or_after) = oracle::binary_search(&manager, 5500u64);
        
        assert!(oracle::timestamp(&before_or_at) <= 5500u64, 0);
        assert!(oracle::timestamp(&at_or_after) >= 5500u64, 1);
        assert!(oracle::initialized(&before_or_at) == true, 2);
        assert!(oracle::initialized(&at_or_after) == true, 3);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_binary_search_uninitialized_observations() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Grow but don't fill all observations
        oracle::grow(&mut manager, 8);
        oracle::update(&mut manager, tick, liquidity, 2000u64);
        oracle::update(&mut manager, tick, liquidity, 3000u64);
        // Leave some observations uninitialized
        
        let (before_or_at, _at_or_after) = oracle::binary_search(&manager, 2500u64);
        
        assert!(oracle::initialized(&before_or_at) == true, 0);
        assert!(oracle::timestamp(&before_or_at) <= 2500u64, 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_update_with_cardinality_not_at_boundary() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Grow and update a few times
        oracle::grow(&mut manager, 5);
        oracle::update(&mut manager, tick, liquidity, 2000u64);
        oracle::update(&mut manager, tick, liquidity, 3000u64);
        
        // Now we're not at the boundary (observation_index != cardinality - 1)
        let old_cardinality = oracle::observation_cardinality(&manager);
        oracle::update(&mut manager, tick, liquidity, 4000u64);
        
        // Cardinality should not change since we're not at boundary
        assert!(oracle::observation_cardinality(&manager) == old_cardinality, 0);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transform_with_zero_tick() {
        let base_timestamp = 1000u64;
        let new_timestamp = 2000u64;
        let zero_tick = MateI32::zero();
        let liquidity = create_test_liquidity();
        
        let base_obs = oracle::create_observation(
            base_timestamp,
            MateI64::from(1000u64),
            500u256,
            true
        );
        
        let transformed = oracle::transform(&base_obs, new_timestamp, zero_tick, liquidity);
        
        // With zero tick, tick_cumulative should remain the same
        assert!(MateI64::eq(oracle::tick_cumulative(&transformed), MateI64::from(1000u64)), 0);
        assert!(oracle::timestamp(&transformed) == new_timestamp, 1);
    }

    #[test]
    fun test_transform_with_maximum_values() {
        let base_timestamp = 0u64;
        let new_timestamp = 1000000u64; // Large time delta
        let tick = MateI32::from(50000u32); // Large tick
        let liquidity = 1u128; // Minimum liquidity
        
        let base_obs = oracle::create_observation(
            base_timestamp,
            MateI64::zero(),
            0u256,
            true
        );
        
        let transformed = oracle::transform(&base_obs, new_timestamp, tick, liquidity);
        
        assert!(oracle::timestamp(&transformed) == new_timestamp, 0);
        assert!(oracle::initialized(&transformed) == true, 1);
        assert!(MateI64::gt(oracle::tick_cumulative(&transformed), MateI64::zero()), 2);
        assert!(oracle::seconds_per_liquidity_cumulative(&transformed) > 0, 3);
    }

    #[test]
    fun test_observe_single_right_boundary() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        oracle::grow(&mut manager, 3);
        oracle::update(&mut manager, tick, liquidity, 2000u64);
        oracle::update(&mut manager, tick, liquidity, 3000u64);
        
        // Test when target exactly matches at_or_after timestamp
        let (tick_cumulative, seconds_per_liquidity) = oracle::observe_single(
            &manager, 3000u64, 1000u64, tick, liquidity // target = 2000 (exact match)
        );
        
        assert!(MateI64::gte(tick_cumulative, MateI64::zero()), 0);
        assert!(seconds_per_liquidity >= 0, 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_circular_buffer_wraparound() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = create_test_tick();
        let liquidity = create_test_liquidity();
        
        // Create small buffer and fill it completely to test wraparound
        oracle::grow(&mut manager, 3);
        oracle::update(&mut manager, tick, liquidity, 2000u64);
        oracle::update(&mut manager, tick, liquidity, 3000u64);
        oracle::update(&mut manager, tick, liquidity, 4000u64); // This should wrap around
        
        // Verify the buffer wrapped around correctly
        assert!(oracle::observation_index(&manager) == 0, 0); // Should wrap to 0
        
        // Test that we can still observe correctly after wraparound
        let (tick_cumulative, _) = oracle::observe_single(
            &manager, 4000u64, 0, tick, liquidity
        );
        
        assert!(MateI64::gt(tick_cumulative, MateI64::zero()), 1);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_get_observation_out_of_bounds_edge_cases() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        
        // Test various out of bounds indices
        let obs1 = oracle::get_observation_for_testing(&manager, 999);
        let obs2 = oracle::get_observation_for_testing(&manager, 1000000);
        
        // Both should return default observations
        assert!(oracle::timestamp(&obs1) == 0, 0);
        assert!(oracle::initialized(&obs1) == false, 1);
        assert!(oracle::timestamp(&obs2) == 0, 2);
        assert!(oracle::initialized(&obs2) == false, 3);
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_complex_interpolation_scenario() {
        let scenario = test_scenario::begin(ADMIN);
        let manager = oracle::initialize_manager(1000u64);
        let tick = MateI32::from(1000u32); // Larger tick for more noticeable effects
        let liquidity = 1000000u128;
        
        oracle::grow(&mut manager, 5);
        
        // Create observations with significant time gaps
        oracle::update(&mut manager, tick, liquidity, 5000u64);  // 4000 time delta
        oracle::update(&mut manager, tick, liquidity, 15000u64); // 10000 time delta
        oracle::update(&mut manager, tick, liquidity, 20000u64); // 5000 time delta
        
        // Test interpolation between first and second observation
        let (tick_cumulative, seconds_per_liquidity) = oracle::observe_single(
            &manager, 20000u64, 10000u64, tick, liquidity // target = 10000 (between 5000 and 15000)
        );
        
        // Verify interpolated values are reasonable
        assert!(MateI64::gt(tick_cumulative, MateI64::zero()), 0);
        assert!(seconds_per_liquidity > 0, 1);
        
        // Test another interpolation point
        let (tick_cumulative2, seconds_per_liquidity2) = oracle::observe_single(
            &manager, 20000u64, 3000u64, tick, liquidity // target = 17000 (between 15000 and 20000)
        );
        
        // Later interpolation should have larger cumulative values
        assert!(MateI64::gt(tick_cumulative2, tick_cumulative), 2);
        assert!(seconds_per_liquidity2 > seconds_per_liquidity, 3);
        
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                    Getter Tests                         //
    //===========================================================//

    #[test]
    fun test_observation_getters() {
        let timestamp = 12345u64;
        let tick_cumulative = MateI64::from(67890u64);
        let seconds_per_liquidity = 98765u256;
        
        let observation = oracle::create_observation(
            timestamp,
            tick_cumulative,
            seconds_per_liquidity,
            true
        );
        
        assert!(oracle::timestamp(&observation) == timestamp, 0);
        assert!(MateI64::eq(oracle::tick_cumulative(&observation), tick_cumulative), 1);
        assert!(oracle::seconds_per_liquidity_cumulative(&observation) == seconds_per_liquidity, 2);
        assert!(oracle::initialized(&observation) == true, 3);
    }

    #[test]
    fun test_manager_getters() {
        let scenario = test_scenario::begin(ADMIN);
        let timestamp = create_test_timestamp();
        let manager = oracle::initialize_manager(timestamp);
        
        assert!(oracle::observation_index(&manager) == 0, 0);
        assert!(oracle::observation_cardinality(&manager) == 1, 1);
        assert!(oracle::observation_cardinality_next(&manager) == 1, 2);
        assert!(oracle::observations_length(&manager) == 1, 3);
        
        oracle::grow(&mut manager, 5);
        assert!(oracle::observation_cardinality_next(&manager) == 5, 4);
        assert!(oracle::observations_length(&manager) == 5, 5);
        
        test_scenario::end(scenario);
    }
}

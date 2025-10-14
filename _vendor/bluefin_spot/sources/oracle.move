/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::oracle {
    use std::vector;
    use std::u64;

    // integer mate modules
    use integer_mate::i32::{I32};
    use integer_mate::i64::{Self as MateI64, I64};

    use integer_library::i32::{Self};
    use integer_library::i64::{Self};
    use bluefin_spot::i32H;
    use bluefin_spot::i64H;

    // local modules
    use bluefin_spot::errors;
    use bluefin_spot::utils;

    friend bluefin_spot::pool;
    #[test_only]
    friend bluefin_spot::test_oracle;

    //===========================================================//
    //                           Structs                         //
    //===========================================================//


    struct ObservationManager has copy, drop, store {
        observations: vector<Observation>,
        observation_index: u64,  
        observation_cardinality: u64,  
        observation_cardinality_next: u64, 
    }

    struct Observation has copy, drop, store {
        timestamp: u64,
        tick_cumulative: I64,
        seconds_per_liquidity_cumulative: u256,
        initialized: bool,
    }


    //===========================================================//
    //                     Public Functions                      //
    //===========================================================//
    
    /// Creates an Observation Manager
    public fun initialize_manager(timestamp: u64): ObservationManager {

        let manager = ObservationManager {
            observation_index: 0,  
            observation_cardinality: 1,  
            observation_cardinality_next: 1, 
            observations: vector::empty<Observation>()
        };

        let observation = default_observation();
        observation.timestamp = timestamp;
        observation.initialized = true;

        vector::push_back<Observation>(&mut manager.observations, observation);


        manager       
    }

    /// Creates a new observation
    public fun default_observation():Observation {
        Observation{
            timestamp: 0, 
            tick_cumulative: MateI64::zero(), 
            seconds_per_liquidity_cumulative: 0, 
            initialized: false,
        }
    }


    public fun observe_single(manager: &ObservationManager, timestamp: u64, seconds_ago: u64, current_tick_index: I32, liquidity: u128) : (I64, u256) {

        if (seconds_ago == 0) {
            
            let observation = get_observation(manager, manager.observation_index);

            if (observation.timestamp != timestamp) {
                // let observation_reference = &observation;
                observation = transform(&observation, timestamp, current_tick_index, liquidity);
            };
            return (observation.tick_cumulative, observation.seconds_per_liquidity_cumulative)
        };

        let target = timestamp - seconds_ago;

        let (before_or_at, at_or_after) = get_surrounding_observations(manager, target, current_tick_index, liquidity);

        if (target == before_or_at.timestamp) {
            // we're at the left boundary
            (before_or_at.tick_cumulative, before_or_at.seconds_per_liquidity_cumulative)
        } else {
            let (tick_cumulative, seconds_per_liquidity_cumulative) = if (target == at_or_after.timestamp) {
                // we're at the right boundary
                (at_or_after.tick_cumulative, at_or_after.seconds_per_liquidity_cumulative)
            } else {
                // we are in the middle
                let observation_time_delta = at_or_after.timestamp - before_or_at.timestamp;
                let time_delta = target - before_or_at.timestamp;
                (
                    i64H::lib_to_mate(i64::add(i64H::mate_to_lib(before_or_at.tick_cumulative), i64::mul(
                        i64::div(
                            i64H::mate_to_lib(i64H::sub(at_or_after.tick_cumulative, before_or_at.tick_cumulative)), 
                            i64::from(observation_time_delta)
                        ), 
                        i64::from(time_delta))
                    )     ), 
                    before_or_at.seconds_per_liquidity_cumulative + 
                    (at_or_after.seconds_per_liquidity_cumulative - before_or_at.seconds_per_liquidity_cumulative) * 
                    (time_delta as u256) / (observation_time_delta as u256))
            };
            (tick_cumulative, seconds_per_liquidity_cumulative)
        }
    }

    public fun transform(observation: &Observation, timestamp: u64, current_tick_index: I32, liquidity: u128) : Observation {

        let index = if (i32::is_neg(i32H::mate_to_lib(current_tick_index))) {
            i64::neg_from((i32::abs_u32(i32H::mate_to_lib(current_tick_index)) as u64))
        } else {
            i64::from((i32::abs_u32(i32H::mate_to_lib(current_tick_index)) as u64))
        };

        let time_delta = timestamp - observation.timestamp;

        // liquidity has to be non-zero
        let non_zero_liquidity = if (liquidity == 0) {
            1
        } else {
            liquidity
        };

        Observation{
            timestamp,
            initialized: true,
            tick_cumulative: i64H::add(observation.tick_cumulative, i64H::lib_to_mate(i64::mul(index, i64::from(time_delta)))), 
            seconds_per_liquidity_cumulative: utils::overflow_add(
                observation.seconds_per_liquidity_cumulative, ((time_delta as u256) << 128) / (non_zero_liquidity as u256)), 
        }
    }

    public fun get_surrounding_observations(manager: &ObservationManager, target: u64, current_tick_index: I32, liquidity: u128) : (Observation, Observation) {

        let observation = get_observation(manager, manager.observation_index);

        if (observation.timestamp <= target) {

            if (observation.timestamp == target) {
                return (observation, default_observation())
            };

            return (observation, transform(&observation, target, current_tick_index, liquidity))
        };

        observation = get_observation(manager, (manager.observation_index + 1) % manager.observation_cardinality);

        if (!observation.initialized) {
            observation = *vector::borrow(&manager.observations, 0);
        }
        ;
        assert!(observation.timestamp <= target, errors::invalid_observation_timestamp());

        binary_search(manager, target)
    }

    public fun binary_search(manager: &ObservationManager, timestamp: u64) : (Observation, Observation) {

        let index = (manager.observation_index + 1) % manager.observation_cardinality;
        let start = index;
        let end = index+ manager.observation_cardinality - 1;

        let at_or_after;
        let before_or_at;
        
        loop {
            let mid = (start + end) / 2;
            before_or_at = get_observation(manager, mid % manager.observation_cardinality);
            
            if (!before_or_at.initialized) {
                start = mid + 1;
                continue
            };

            at_or_after = get_observation(manager, (mid + 1) % manager.observation_cardinality);

            if (before_or_at.timestamp <= timestamp && timestamp <= at_or_after.timestamp) {
                break
            };

            if (before_or_at.timestamp < timestamp) {
                start = mid + 1;
                continue
            };

            end = mid - 1;
        };

        (before_or_at, at_or_after)
    }
 
    public (friend) fun update(manager: &mut ObservationManager, current_tick_index: I32, liquidity: u128, target: u64) {

        let observation = vector::borrow(&manager.observations, manager.observation_index);

        if (observation.timestamp == target) {
            return
        };

        let cardinality_updated = if (manager.observation_cardinality_next > manager.observation_cardinality && manager.observation_index == manager.observation_cardinality - 1) {
            manager.observation_cardinality_next
        } else {
            manager.observation_cardinality
        };

        let index_updated = (manager.observation_index + 1) % cardinality_updated;

        *vector::borrow_mut(&mut manager.observations, index_updated) = transform(observation, target, current_tick_index, liquidity);

        manager.observation_index = index_updated;
        manager.observation_cardinality = cardinality_updated;
    }

    public (friend) fun grow(manager: &mut ObservationManager, new_cardinality: u64) : (u64, u64) {
        
        let current_cardinality = manager.observation_cardinality_next;

        // while current_cardinality < new_cardinality 
        while (current_cardinality < new_cardinality) {
            vector::push_back(&mut manager.observations, default_observation());
            current_cardinality = current_cardinality + 1;
        };

        // cardinality can only be increased, not decreased
        manager.observation_cardinality_next  = u64::max(current_cardinality, new_cardinality);

        (current_cardinality, manager.observation_cardinality_next)
    }

    //===========================================================//
    //                      Getter Functions                    //
    //===========================================================//

    // ObservationManager getters
    public fun observation_index(manager: &ObservationManager): u64 {
        manager.observation_index
    }

    public fun observation_cardinality(manager: &ObservationManager): u64 {
        manager.observation_cardinality
    }

    public fun observation_cardinality_next(manager: &ObservationManager): u64 {
        manager.observation_cardinality_next
    }

    public fun observations_length(manager: &ObservationManager): u64 {
        vector::length(&manager.observations)
    }

    // Observation getters
    public fun timestamp(observation: &Observation): u64 {
        observation.timestamp
    }

    public fun tick_cumulative(observation: &Observation): I64 {
        observation.tick_cumulative
    }

    public fun seconds_per_liquidity_cumulative(observation: &Observation): u256 {
        observation.seconds_per_liquidity_cumulative
    }

    public fun initialized(observation: &Observation): bool {
        observation.initialized
    }
    //===========================================================//
    //                    Internal Functions                     //
    //===========================================================//

    /// Gets the observation at provided index. If index out of bound, creates one
    fun get_observation(manager: &ObservationManager, index: u64) : Observation {
        if (index < vector::length(&manager.observations)) {
            *vector::borrow(&manager.observations, index)

        } else {
            default_observation()
        }
    }

    // Test-only constructor for Observation
    #[test_only]
    public fun create_observation(timestamp: u64, tick_cumulative: I64, seconds_per_liquidity_cumulative: u256, initialized: bool): Observation {
        Observation {
            timestamp,
            tick_cumulative,
            seconds_per_liquidity_cumulative,
            initialized,
        }
    }

    #[test_only]
    public fun get_observation_for_testing(manager: &ObservationManager, index: u64) : Observation {
        get_observation(manager, index)
    }
    

}
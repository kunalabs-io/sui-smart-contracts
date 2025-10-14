/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::tick {
    use sui::object::{ID};
    use sui::tx_context::{TxContext};
    use sui::table::{Self, Table};
    use std::vector;

    // local modules
    use integer_mate::i32::{Self, I32};
    use integer_mate::i64::{Self, I64};
    use integer_mate::i128::{Self, I128};
    use integer_library::i32::{Self as LibraryI32};

    use bluefin_spot::tick_math::{Self};
    use integer_library::math_u128;

    use bluefin_spot::i32H;
    use bluefin_spot::i64H;
    use bluefin_spot::i128H;
    use bluefin_spot::utils;


    // friend modules
    friend bluefin_spot::pool;
    #[test_only]
    friend bluefin_spot::test_tick;

    //===========================================================//
    //                           Structs                         //
    //===========================================================//

    /// Ticks manager
    struct TickManager has store {
        tick_spacing: u32,
        ticks: Table<I32, TickInfo>,                    
        bitmap: Table<I32, u256>,
    }

    /// Tick infos.
    #[allow(unused_field)]
    struct TickInfo has copy, drop, store {
        index: I32,  // -400K to 400K  -10, 0, 10, 20, 30, 40
        sqrt_price: u128,
        // total liquidity at tick
        liquidity_gross: u128, 
        // amount of liquidity added or subtracted when tick is crossed
        liquidity_net: I128,

        fee_growth_outside_a: u128,
        fee_growth_outside_b: u128,

        tick_cumulative_out_side: I64,
        seconds_per_liquidity_out_side: u256,
        seconds_out_side: u64,
        reward_growths_outside: vector<u128>
    }

    /// Initializes the tick manager
    public (friend) fun initialize_manager(tick_spacing: u32, ctx: &mut TxContext): TickManager {

        TickManager {
            tick_spacing,
            ticks: table::new<I32, TickInfo>(ctx),
            bitmap: table::new<I32, u256>(ctx),

        }
    }


    public (friend) fun update(
        manager: &mut TickManager, 
        _: ID,
        index: I32, 
        current_tick: I32, 
        liquidity_delta: I128,
        fee_growth_global_coin_a: u128, 
        fee_growth_global_coin_b: u128, 
        reward_growths_global: vector<u128>,
        tick_cumulative: I64, 
        seconds_per_liquidity_cumulative: u256,
        seconds_outside: u64, 
        upper: bool
        ) : bool {

        let tick = get_mutable_tick_from_table(&mut manager.ticks, index);

        let initial_gross_liquidity = tick.liquidity_gross;

        let liqudity_after = utils::add_delta(initial_gross_liquidity, liquidity_delta);

        let lib_tick = i32H::mate_to_lib(current_tick);
        let lib_index = i32H::mate_to_lib(index);

        //  a new tick has been created
        if (initial_gross_liquidity == 0) {
            if (LibraryI32::lte(lib_index, lib_tick)) {
                tick.fee_growth_outside_a = fee_growth_global_coin_a;
                tick.fee_growth_outside_b = fee_growth_global_coin_b;
                tick.seconds_per_liquidity_out_side = seconds_per_liquidity_cumulative;
                tick.tick_cumulative_out_side = tick_cumulative;
                tick.seconds_out_side = seconds_outside;
                tick.reward_growths_outside = reward_growths_global
            } else {
                let index = 0;
                while (index < vector::length<u128>(&reward_growths_global)) {
                      vector::push_back<u128>(&mut tick.reward_growths_outside, 0);
                    index = index + 1;
                };
            };
        };
        
        tick.liquidity_gross = liqudity_after;

        tick.liquidity_net  = if (upper) {
            i128H::sub(tick.liquidity_net, liquidity_delta)
        } else {
            i128H::add(tick.liquidity_net, liquidity_delta)
        };

        // return true if the tick flipped
        (liqudity_after == 0) != (initial_gross_liquidity == 0)
    }

    public (friend) fun cross(
        manager: &mut TickManager, 
        index: I32, 
        fee_growth_global_coin_a: u128, 
        fee_growth_global_coin_b: u128, 
        reward_growths_global: vector<u128>,
        tick_cumulative: I64, 
        seconds_per_liquidity_cumulative: u256,
        current_time: u64, 
        ) : I128 {

        let tick = get_mutable_tick_from_manager(manager, index);


        tick.fee_growth_outside_a = math_u128::wrapping_sub(fee_growth_global_coin_a, tick.fee_growth_outside_a);
        tick.fee_growth_outside_b = math_u128::wrapping_sub(fee_growth_global_coin_b, tick.fee_growth_outside_b);
        tick.reward_growths_outside = compute_reward_growths(reward_growths_global,tick.reward_growths_outside);
        tick.seconds_per_liquidity_out_side = seconds_per_liquidity_cumulative - tick.seconds_per_liquidity_out_side;
        tick.tick_cumulative_out_side = i64H::sub(tick_cumulative, tick.tick_cumulative_out_side);
        tick.seconds_out_side = current_time - tick.seconds_out_side;
        tick.liquidity_net
    }

    public (friend) fun get_mutable_tick_from_table(ticks: &mut Table<I32, TickInfo>, index: I32) : &mut TickInfo {

        if (!table::contains(ticks, index)) {
            table::add(ticks, index, create_tick(index));
        };
        table::borrow_mut(ticks, index)
    }   

    public (friend) fun get_mutable_tick_from_manager(manager: &mut TickManager, index: I32) : &mut TickInfo {
        get_mutable_tick_from_table(&mut manager.ticks, index)
    }   

    public fun get_tick_from_table(ticks: &Table<I32, TickInfo>, index: I32) : &TickInfo {
        table::borrow(ticks, index)
    }   

    public fun get_tick_from_manager(manager: &TickManager, index: I32) : &TickInfo {
        get_tick_from_table(&manager.ticks, index)
    }   


    public fun sqrt_price(tick: &TickInfo) : u128 {
        tick.sqrt_price
    }

    public fun create_tick(index: I32): TickInfo {
        TickInfo {
            index,
            sqrt_price: tick_math::get_sqrt_price_at_tick(index),
            liquidity_gross: 0,
            liquidity_net: i128::zero(),
            fee_growth_outside_a: 0,
            fee_growth_outside_b: 0,
            tick_cumulative_out_side: i64::zero(),
            seconds_per_liquidity_out_side: 0,
            seconds_out_side: 0,
            reward_growths_outside: vector::empty<u128>()
        }
    }

    public fun liquidity_gross(tick: &TickInfo): u128 {
        tick.liquidity_gross
    }

    public fun liquidity_net(tick: &TickInfo): I128 {
        tick.liquidity_net
    }

    public fun tick_spacing(manager: &TickManager): u32 {
        manager.tick_spacing
    }

    public fun get_fee_and_reward_growths_inside(manager: &TickManager, lower_tick_index: I32, upper_tick_index: I32, current_tick_index: I32, fee_growth_global_coin_a: u128, fee_growth_global_coin_b: u128, reward_growths_global: vector<u128>) : (u128, u128, vector<u128>) {
        let (lt_fee_growth_outside_a, lt_fee_growth_outside_b, lt_reward_growths_outside) = get_fee_and_reward_growths_outside(manager, lower_tick_index);
        let (ut_fee_growth_outside_a, ut_fee_growth_outside_b, ut_reward_growths_outside) = get_fee_and_reward_growths_outside(manager, upper_tick_index);

        let lib_current_tick_index = i32H::mate_to_lib(current_tick_index);
        let lib_lower_tick_index = i32H::mate_to_lib(lower_tick_index);
        let lib_upper_tick_index = i32H::mate_to_lib(upper_tick_index);

        let (fee_growth_below_a, fee_growth_below_b, reward_growths_below) = if (LibraryI32::gte(lib_current_tick_index, lib_lower_tick_index)) {
            (lt_fee_growth_outside_a, lt_fee_growth_outside_b, lt_reward_growths_outside)
        } else {
            (math_u128::wrapping_sub(fee_growth_global_coin_a, lt_fee_growth_outside_a), math_u128::wrapping_sub(fee_growth_global_coin_b, lt_fee_growth_outside_b), compute_reward_growths(reward_growths_global, lt_reward_growths_outside))
        };
        
        let (fee_growth_above_a, fee_growth_above_b, reward_growths_above) = if (LibraryI32::lt(lib_current_tick_index, lib_upper_tick_index)) {
            (ut_fee_growth_outside_a, ut_fee_growth_outside_b, ut_reward_growths_outside)
        } else {
            (math_u128::wrapping_sub(fee_growth_global_coin_a, ut_fee_growth_outside_a), math_u128::wrapping_sub(fee_growth_global_coin_b, ut_fee_growth_outside_b), compute_reward_growths(reward_growths_global, ut_reward_growths_outside))
        };

        (
            math_u128::wrapping_sub(math_u128::wrapping_sub(fee_growth_global_coin_a, fee_growth_below_a), fee_growth_above_a),
            math_u128::wrapping_sub(math_u128::wrapping_sub(fee_growth_global_coin_b, fee_growth_below_b), fee_growth_above_b),
            compute_reward_growths(compute_reward_growths(reward_growths_global, reward_growths_below), reward_growths_above)
        )
    }

    public fun get_fee_and_reward_growths_outside(manager: &TickManager, tick_index: I32) : (u128, u128, vector<u128>) {
        if (!is_tick_initialized(manager, tick_index)) {
            (0, 0, vector::empty<u128>())
        } else {
            let tick = table::borrow(&manager.ticks,tick_index);
            (tick.fee_growth_outside_a, tick.fee_growth_outside_b, tick.reward_growths_outside)
        }
    }


    public fun is_tick_initialized(manager: &TickManager, tick_index: I32) : bool {
        table::contains(&manager.ticks, tick_index)
    }

    public fun bitmap(manager: &TickManager ): &Table<I32, u256> {
        &manager.bitmap
    }

    public fun fetch_provided_ticks(manager: &TickManager, ticks: vector<u32>): vector<TickInfo> {
        let i = 0;
        let count = vector::length(&ticks);
        let result = vector::empty<TickInfo>();
        while(i < count){
            let tick_bits = *vector::borrow(&ticks, i);
            let index = i32::from_u32(tick_bits);

            if(is_tick_initialized(manager, index)){
                vector::push_back(&mut result, *get_tick_from_manager(manager, index));
            };

            i = i + 1;
        };

        result
    }

    public (friend) fun mutable_bitmap(manager: &mut TickManager ): &mut Table<I32, u256> {
        &mut manager.bitmap
    }
    
    public (friend) fun remove(manager: &mut TickManager, tick: I32) {
        table::remove(&mut manager.ticks, tick);
    }

    fun compute_reward_growths(
        reward_growths_global: vector<u128>,  
        tick_reward_growths: vector<u128> 
    ) : vector<u128> {
        let current_index = 0;
        let diff_in_reward_growths = vector::empty<u128>();
        while (current_index < vector::length<u128>(&reward_growths_global)) {
            let tick_reward_growth = if (current_index >=   vector::length<u128>(&tick_reward_growths)) {
                0
            } else {
                 *(vector::borrow<u128>(&tick_reward_growths, current_index))
            };

            vector::push_back<u128>(&mut diff_in_reward_growths,  math_u128::wrapping_sub(*vector::borrow<u128>(&reward_growths_global, current_index), tick_reward_growth));
            current_index = current_index + 1;
        };
        diff_in_reward_growths
    }

    #[test_only]
    public fun destroy_manager_for_testing(manager: TickManager) {
        let TickManager { tick_spacing: _, ticks, bitmap } = manager;
        table::drop(ticks);
        table::drop(bitmap);
    }   

}
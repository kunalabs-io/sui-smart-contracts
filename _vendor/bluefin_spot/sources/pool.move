/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

/// Module: pool
module bluefin_spot::pool {
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self,TxContext};
    use std::string::{Self, String};
    use sui::clock::{Clock};
    use sui::transfer;
    use std::u64;
    use std::vector;
    use sui::event::emit;
    use sui::dynamic_field as field;

    // local modules
    use bluefin_spot::constants;
    use bluefin_spot::config::{Self, GlobalConfig};
    use bluefin_spot::position::{Self, Position};
    use bluefin_spot::tick::{Self, TickManager, TickInfo};
    use bluefin_spot::oracle::{Self, ObservationManager};
    use bluefin_spot::events;
    use bluefin_spot::utils;
    use bluefin_spot::errors;
    use bluefin_spot::tick_math;
    use bluefin_spot::tick_bitmap;

    use integer_mate::i32::{Self as MateI32, I32};
    use integer_library::i32::{Self};
    use integer_library::i128::{Self, I128 as LibraryI128Type};

    use integer_library::full_math_u64;
    use integer_library::full_math_u128;
    use integer_library::math_u128;
    use bluefin_spot::clmm_math;
    use bluefin_spot::i32H;
    use bluefin_spot::i128H;

    // friend modules
    friend bluefin_spot::admin;
    
    // ==== Constants ==== //
    const DEFAULT_POOL_ICON_URL: vector<u8> = b"https://bluefin.io/images/nfts/default.gif";

    //===========================================================//
    //                           Structs                         //
    //===========================================================//

    /// Represents a pool
    struct Pool<phantom CoinTypeA, phantom CoinTypeB> has key, store {
        // Id of the pool
        id: UID,
        // The name of the pool
        name: String,
        // Amount of Coin A locked in pool
        coin_a: Balance<CoinTypeA>,
        // Amount of Coin B locked in pool
        coin_b: Balance<CoinTypeB>,
        // The fee in basis points. 1 bps is represented as 100, 5 as 500
        fee_rate: u64,
        // the percentage of fee that will go to protocol
        protocol_fee_share: u64,        
        // Variable to track the fee accumulated in coin A 
        fee_growth_global_coin_a: u128,
        // Variable to track the fee accumulated in coin B 
        fee_growth_global_coin_b: u128,
        // Variable to track the accrued protocol fee of coin A
        protocol_fee_coin_a: u64,
        // Variable to track the accrued protocol fee of coin B
        protocol_fee_coin_b: u64,
        // The tick manager
        ticks_manager: TickManager,
        // The observations manager
        observations_manager: ObservationManager,
        // Current sqrt(P) in Q96 notation
        current_sqrt_price: u128,
        // The current tick index
        current_tick_index: I32,
        // The amount of liquidity (L) in the pool currently
        liquidity: u128,
        // Vector holding the information for different pool rewards
        reward_infos: vector<PoolRewardInfo>,
        // Is the pool paused
        is_paused: bool,
        // url of the pool logo
        icon_url: String,
        // position index number
        position_index: u128,
        // a incrementor, updated every time pool state is changed
        sequence_number: u128,
    }

    /// Represents reward configs inside a pool
    struct PoolRewardInfo has copy, drop, store {
        // symbol of reward coin
        reward_coin_symbol: String,
        // decimals of the reward coin
        reward_coin_decimals: u8,
        // type string of the reward coin
        reward_coin_type: String,
        // last time the data of this coin was changed.
        last_update_time: u64, 
        //timestamp at which the rewards will finish
        ended_at_seconds: u64,  
        // total coins to be emitted 
        total_reward: u64, 
        // total reward collectable at the moment 
        total_reward_allocated: u64, 
        // amount of reward to be emitted per second
        reward_per_seconds: u128, 
        // global values used to distribute rewards
        reward_growth_global: u128, 
    }

    /// Represents a swap result
    struct SwapResult has copy, drop {
        a2b: bool,
        by_amount_in: bool,
        amount_specified: u64,
        amount_specified_remaining: u64,
        amount_calculated: u64,
        fee_growth_global: u128,
        fee_amount: u64,
        protocol_fee: u64,
        start_sqrt_price: u128,
        end_sqrt_price: u128,
        current_tick_index: I32,
        is_exceed: bool,
        starting_liquidity: u128,
        liquidity: u128,
        steps: u64,
        step_results: vector<SwapStepResult>,
    }

    struct SwapStepResult has copy, drop, store {
        tick_index_next: I32,
        initialized: bool,
        sqrt_price_start: u128,
        sqrt_price_next: u128,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        remaining_amount: u64,
    }


    struct FlashSwapReceipt<phantom CoinTypeA, phantom CoinTypeB> {
        pool_id: ID,
        a2b: bool,
        pay_amount: u64,
    }



    //===========================================================//
    //                     Friend Functions                      //
    //===========================================================//


    public (friend) fun set_protocol_fee_amount<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA,CoinTypeB>, coin_a: u64, coin_b: u64){
        pool.protocol_fee_coin_a = coin_a;
        pool.protocol_fee_coin_b = coin_b;
    }

    public (friend) fun withdraw_balances<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA,CoinTypeB>, coin_a_amount: u64, coin_b_amount: u64): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
        (utils::withdraw_balance<CoinTypeA>(&mut pool.coin_a, coin_a_amount), utils::withdraw_balance<CoinTypeB>(&mut pool.coin_b, coin_b_amount))
    }

    public (friend) fun increase_sequence_number<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA,CoinTypeB>): u128 {
        pool.sequence_number = pool.sequence_number + 1;
        pool.sequence_number
    }
    

    public (friend) fun add_reward_info<CoinTypeA, CoinTypeB, RewardCoinType>(
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        pool_reward_info: PoolRewardInfo) {
            field::add<String, Balance<RewardCoinType>>(
                &mut pool.id, 
                utils::get_type_string<RewardCoinType>(),
                balance::zero<RewardCoinType>()
                );
            vector::push_back<PoolRewardInfo>(&mut pool.reward_infos, pool_reward_info)
        }

    
    public (friend) fun update_pool_reward_emission<CoinTypeA, CoinTypeB, RewardCoinType>(
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        balance: Balance<RewardCoinType>,
        active_for_seconds: u64
        ) {
        
        let pool_id = object::id(pool);

        let reward_info_index = find_reward_info_index<CoinTypeA, CoinTypeB, RewardCoinType>(pool);
        let reward_info = vector::borrow_mut<PoolRewardInfo>(
            &mut pool.reward_infos, reward_info_index);

        let new_end_time = reward_info.ended_at_seconds + active_for_seconds;
        
        assert!(new_end_time > reward_info.last_update_time, errors::invalid_last_update_time());
    
       
        reward_info.total_reward = reward_info.total_reward + balance::value<RewardCoinType>(&balance);
       
        reward_info.ended_at_seconds = new_end_time;
        reward_info.reward_per_seconds = full_math_u128::mul_div_floor((
            (reward_info.total_reward - reward_info.total_reward_allocated) as u128), (constants::q64() as u128), ((reward_info.ended_at_seconds - reward_info.last_update_time) as u128));

        
        
        balance::join<RewardCoinType>(
            field::borrow_mut< String ,Balance<RewardCoinType>>
            (&mut pool.id, utils::get_type_string<RewardCoinType>()), balance);
    
        
        pool.sequence_number = pool.sequence_number + 1;

        events::emit_update_pool_reward_emission_event(
            pool_id,
            reward_info.reward_coin_symbol,
            reward_info.reward_coin_type,
            reward_info.reward_coin_decimals, 
            reward_info.total_reward, 
            reward_info.ended_at_seconds, 
            reward_info.last_update_time,
            reward_info.reward_per_seconds,
            pool.sequence_number
        );
    }

    public (friend) fun update_reward_infos<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>, current_timestamp_seconds: u64) : vector<u128> {
        let reward_growth_globals = vector::empty<u128>();
        let current_index = 0;
        while (current_index < vector::length<PoolRewardInfo>(&pool.reward_infos)) {
            let reward_info = vector::borrow_mut<PoolRewardInfo>(&mut pool.reward_infos, current_index);
            current_index = current_index + 1;

            if (current_timestamp_seconds > reward_info.last_update_time) {
            
                let min_timestamp = u64::min(current_timestamp_seconds, reward_info.ended_at_seconds);
                if (pool.liquidity != 0 && min_timestamp > reward_info.last_update_time) {

                    let rewards_accumulated = full_math_u128::full_mul(((min_timestamp - reward_info.last_update_time) as u128), reward_info.reward_per_seconds);
                    
                    reward_info.reward_growth_global = math_u128::wrapping_add(reward_info.reward_growth_global, ((rewards_accumulated / (pool.liquidity as u256)) as u128));
                    
                    reward_info.total_reward_allocated = reward_info.total_reward_allocated + ((rewards_accumulated/ (constants::q64() as u256)) as u64);
                };
                reward_info.last_update_time = current_timestamp_seconds;
            };

            vector::push_back<u128>(&mut reward_growth_globals, reward_info.reward_growth_global);
        };
        reward_growth_globals
    }

    public (friend) fun update_pause_status<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA,CoinTypeB>, status: bool){
        pool.is_paused = status;

        pool.sequence_number = pool.sequence_number + 1;
        
        events::emit_pool_pause_status_update_event(
            object::uid_to_inner(&pool.id),
            pool.is_paused,
            pool.sequence_number
        )

    }

    
    public (friend) fun set_protocol_fee_share<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>, protocol_fee_share: u64){
            pool.protocol_fee_share = protocol_fee_share;
    }

    /// A friend function that allows the admin to increase the number of observations stored
    public (friend) fun increase_observation_cardinality_next<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>, value: u64){
        let(previous, current) =  oracle::grow(&mut pool.observations_manager, value);
        increase_sequence_number(pool);
        events::emit_observation_cardinality_updated_event(
            object::id(pool), 
            previous, 
            current,
            pool.sequence_number
        );
    }

    /// A friend function that allows admin to add reward coins to a pool with out increasing its total reward supply
    public (friend) fun increase_reward_coin_reserves<CoinTypeA, CoinTypeB, RewardCoinType>(
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        balance: Balance<RewardCoinType> ){
            
            // Find the reward token to which coins are being added. This will revert if the reward token being
            // updated does not exists which is correct. Admin can only add to reserves of an already existing reward coin
            assert!(is_reward_present<CoinTypeA, CoinTypeB, RewardCoinType>(pool), errors::reward_index_not_found());

            let amount = balance::value(&balance);

            let reward_coin_type = utils::get_type_string<RewardCoinType>();
            let reserves = field::borrow_mut< String ,Balance<RewardCoinType>>(&mut pool.id, reward_coin_type);

            let reward_reserves_before = balance::value(reserves);

            // update reserves
            balance::join(reserves, balance);

            let reward_reserves_after = balance::value(reserves);

            events::emit_reward_reserves_increased(
                object::id(pool),
                reward_coin_type,
                amount,
                reward_reserves_before,
                reward_reserves_after
            )

    }

    /// A friend function that allows the admin to update the icon url of a pool
    public (friend)fun set_pool_icon_url<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>, icon_url: String){
        assert!(pool.icon_url != icon_url, errors::same_value_provided());
        pool.icon_url = icon_url;

        let sequence_number = increase_sequence_number(pool);

        events::emit_pool_icon_url_update_event(
            object::uid_to_inner(&pool.id),
            icon_url,
            sequence_number
        )
    }


    //===========================================================//
    //                      Public Functions                     //
    //===========================================================//


    #[allow(lint(share_owned))]
    public fun create_pool<CoinTypeA, CoinTypeB, CoinTypeFee>(
        clock: &Clock,
        protocol_config: &mut GlobalConfig,
        pool_name: vector<u8>, 
        icon_url: vector<u8>,
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>, 
        tick_spacing: u32,
        fee_rate: u64,
        current_sqrt_price: u128,
        creation_fee: Balance<CoinTypeFee>,
        ctx: &mut TxContext): ID {
        
        // create pool
        let pool = create_pool_internal<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            pool_name,
            icon_url,
            coin_a_symbol,
            coin_a_decimals,
            coin_a_url,
            coin_b_symbol,
            coin_b_decimals,
            coin_b_url,
            tick_spacing,
            fee_rate,
            current_sqrt_price, 
            ctx,           
        );


        let id = object::id(&pool);

        // charge pool creation fee
        charge_pool_creation_fee<CoinTypeFee>(protocol_config, id, creation_fee, ctx);

        // share the pool object
        transfer::share_object(pool); 

        // return the pool id
        id
    }

    #[allow(lint(share_owned))]
    public fun create_pool_with_liquidity<CoinTypeA, CoinTypeB, CoinTypeFee>(
        clock: &Clock,
        protocol_config: &mut GlobalConfig,
        pool_name: vector<u8>, 
        icon_url: vector<u8>,
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>, 
        tick_spacing: u32,
        fee_rate: u64,
        current_sqrt_price: u128,
        creation_fee: Balance<CoinTypeFee>,
        lower_tick_bits: u32,
        upper_tick_bits: u32,
        balance_a: Balance<CoinTypeA>,
        balance_b: Balance<CoinTypeB>,
        amount: u64,
        is_fixed_a: bool,
        ctx: &mut TxContext): (ID, Position,  u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>) {

        // create pool
        let pool = create_pool_internal<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            pool_name,
            icon_url,
            coin_a_symbol,
            coin_a_decimals,
            coin_a_url,
            coin_b_symbol,
            coin_b_decimals,
            coin_b_url,
            tick_spacing,
            fee_rate,
            current_sqrt_price, 
            ctx,           
        );


        let id = object::id(&pool);

        // charge pool creation fee
        charge_pool_creation_fee<CoinTypeFee>(protocol_config, id, creation_fee, ctx);


        // open position
        let position = open_position(protocol_config, &mut pool, lower_tick_bits, upper_tick_bits, ctx);


        let (coin_a_provided, coin_b_provided, balance_token_a, balance_token_b) = add_liquidity_with_fixed_amount<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            &mut pool, 
            &mut position,
            balance_a,
            balance_b,
            amount,
            is_fixed_a
        );

        // share the pool object
        transfer::share_object(pool); 

        // return the pool id and the open position
        (id, position, coin_a_provided, coin_b_provided, balance_token_a, balance_token_b)

    }

    public fun create_pool_and_get_object<CoinTypeA, CoinTypeB, CoinTypeFee>(
        clock: &Clock,
        protocol_config: &mut GlobalConfig,
        pool_name: vector<u8>, 
        icon_url: vector<u8>,
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>,     
        tick_spacing: u32,
        fee_rate: u64,
        current_sqrt_price: u128,
        creation_fee: Balance<CoinTypeFee>,
        ctx: &mut TxContext): Pool<CoinTypeA, CoinTypeB> {
        
        // create pool
        let pool = create_pool_internal<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            pool_name,
            icon_url,
            coin_a_symbol,
            coin_a_decimals,
            coin_a_url,
            coin_b_symbol,
            coin_b_decimals,
            coin_b_url,
            tick_spacing,
            fee_rate,
            current_sqrt_price, 
            ctx,           
        );

        // charge pool creation fee
        charge_pool_creation_fee<CoinTypeFee>(protocol_config, object::id(&pool), creation_fee, ctx);

        pool
    }

    #[allow(lint(share_owned), lint(custom_state_change))]
    public fun share_pool_object<CoinTypeA, CoinTypeB>(pool: Pool<CoinTypeA, CoinTypeB>) {
        transfer::share_object(pool);
    }

    #[allow(unused_type_parameter)]
    public fun new<CoinTypeA, CoinTypeB>(
        _: &Clock, 
        _: vector<u8>, 
        _: vector<u8>,
        _: vector<u8>, 
        _: u8, 
        _: vector<u8>, 
        _: vector<u8>, 
        _: u8, 
        _: vector<u8>, 
        _: u32,
        _: u64,
        _: u128,
        _: &mut TxContext) {
        abort errors::depricated()
    }

    public fun add_liquidity_with_fixed_amount<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        balance_a: Balance<CoinTypeA>,
        balance_b: Balance<CoinTypeB>,
        amount: u64,
        is_fixed_a: bool,
    ) : (u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>) {

        // verify version
        config::verify_version(protocol_config);

        assert!(object::id(pool) == position::pool_id(position), errors::position_does_not_belong_to_pool());

        // ensure pool is not paused
        assert!(!pool.is_paused, errors::pool_is_paused());

        // ensure there is no flash swap in progress
        assert!(!is_flash_swap_in_progress(&pool.id), errors::flash_swap_in_progress());

        // the amount must be > 0
        assert!(amount > 0, errors::zero_amount());

        let pool_starting_liquidity = pool.liquidity;

        let (liquidity, _, _) =  clmm_math::get_liquidity_by_amount(
                position::lower_tick(position),
                position::upper_tick(position),
                pool.current_tick_index,
                pool.current_sqrt_price,
                amount,
                is_fixed_a
            );

        let (coin_a_amount, coin_b_amount) = update_data_for_delta_l(
            clock,
            pool, 
            position, 
            i128::from(liquidity), 
        );

        // increment the sequence since the action changed the pool state
        pool.sequence_number = pool.sequence_number + 1;

        let (balance_a, balance_b) = (
            utils::deposit_balance(&mut pool.coin_a, balance_a, coin_a_amount),
            utils::deposit_balance(&mut pool.coin_b, balance_b, coin_b_amount)
        );


        // emit event
        events::emit_liquidity_provided_event(
            object::id(pool),
            object::id(position),
            coin_a_amount,
            coin_b_amount,
            balance::value(&pool.coin_a),
            balance::value(&pool.coin_b),
            liquidity,
            pool_starting_liquidity,
            pool.liquidity,
            pool.current_sqrt_price,
            pool.current_tick_index,
            position::lower_tick(position),
            position::upper_tick(position),
            pool.sequence_number,
        );


        (
            coin_a_amount,
            coin_b_amount,
            balance_a, 
            balance_b
        )
    }

    public fun add_liquidity<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        balance_a: Balance<CoinTypeA>,
        balance_b: Balance<CoinTypeB>,
        liquidity: u128,
    ) : (u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>) {
        
        // verify version
        config::verify_version(protocol_config);

        assert!(object::id(pool) == position::pool_id(position), errors::position_does_not_belong_to_pool());

        // ensure pool is not paused
        assert!(!pool.is_paused, errors::pool_is_paused());

        // ensure there is no flash swap in progress
        assert!(!is_flash_swap_in_progress(&pool.id), errors::flash_swap_in_progress());

        // the liquidity must be > 0
        assert!(liquidity > 0, errors::zero_amount());

        let pool_starting_liquidity = pool.liquidity;

        let (coin_a_amount, coin_b_amount) = update_data_for_delta_l(
            clock,
            pool, 
            position, 
            i128::from(liquidity), 
        );

        assert!(
            balance::value(&balance_a) >= coin_a_amount && 
            balance::value(&balance_b) >= coin_b_amount, 
            errors::insufficient_amount());

        // increment the seqeunce since the action changed the pool state
        pool.sequence_number = pool.sequence_number + 1;


        (balance_a, balance_b) = (
            utils::deposit_balance(&mut pool.coin_a, balance_a, coin_a_amount),
            utils::deposit_balance(&mut pool.coin_b, balance_b, coin_b_amount)
        );

        // emit event
        events::emit_liquidity_provided_event(
            object::id(pool),
            object::id(position),
            coin_a_amount,
            coin_b_amount,
            balance::value(&pool.coin_a),
            balance::value(&pool.coin_b),
            liquidity,
            pool_starting_liquidity,
            pool.liquidity,
            pool.current_sqrt_price,
            pool.current_tick_index,
            position::lower_tick(position),
            position::upper_tick(position),
            pool.sequence_number,
        );


        (
            coin_a_amount,
            coin_b_amount,
            balance_a, 
            balance_b
        )
    }

    public fun remove_liquidity<CoinTypeA, CoinTypeB>(
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        liquidity: u128,
        clock: &Clock,
    ) : (u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>) {
        
        // verify version
        config::verify_version(protocol_config);

        assert!(object::id(pool) == position::pool_id(position), errors::position_does_not_belong_to_pool());

        // ensure pool is not paused
        assert!(!pool.is_paused, errors::pool_is_paused());

        // ensure there is no flash swap in progress
        assert!(!is_flash_swap_in_progress(&pool.id), errors::flash_swap_in_progress());

        // the liquidity being removed be > 0
        assert!(liquidity > 0, errors::zero_amount());

        let pool_starting_liquidity = pool.liquidity;

        let (coin_a_amount, coin_b_amount) = update_data_for_delta_l(
            clock,
            pool, 
            position, 
            i128::neg_from(liquidity), 
        );

        let (balance_a, balance_b) = withdraw_balances(pool, coin_a_amount, coin_b_amount);

        pool.sequence_number = pool.sequence_number + 1;

        // emit event
        events::emit_liquidity_removed_event(
            object::id(pool),
            object::id(position),
            coin_a_amount,
            coin_b_amount,
            balance::value(&pool.coin_a),
            balance::value(&pool.coin_b),
            liquidity,
            pool_starting_liquidity,
            pool.liquidity,
            pool.current_sqrt_price,
            pool.current_tick_index,
            position::lower_tick(position),
            position::upper_tick(position),
            pool.sequence_number,
        );

        (
            coin_a_amount,
            coin_b_amount,
            balance_a,
            balance_b,           
        )
    }



    /// Performs a swap on the pool
    public fun swap<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        balance_a: Balance<CoinTypeA>,
        balance_b: Balance<CoinTypeB>,
        a2b: bool,
        by_amount_in:bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_max_limit: u128,
    ): (Balance<CoinTypeA>, Balance<CoinTypeB>) {

        // verify version
        config::verify_version(protocol_config);

        // verify pool is not paused
        assert!(!pool.is_paused, errors::pool_is_paused());

        // ensure there is no flash swap in progress
        assert!(!is_flash_swap_in_progress(&pool.id), errors::flash_swap_in_progress());

        // the amount must be > 0
        assert!(amount > 0, errors::zero_amount());
        
        let swap_result = swap_in_pool<CoinTypeA, CoinTypeB>(clock, pool, a2b, by_amount_in, amount, sqrt_price_max_limit);

        let (amount_in, amount_out) = if (by_amount_in) {
            assert!(swap_result.amount_calculated >= amount_limit, errors::slippage_exceeds());
            (swap_result.amount_specified - swap_result.amount_specified_remaining, swap_result.amount_calculated)
        } else {
            assert!(swap_result.amount_calculated <= amount_limit, errors::slippage_exceeds());
            (swap_result.amount_calculated, swap_result.amount_specified - swap_result.amount_specified_remaining)
        };

        // perform transfer of coins
        if (a2b) {            
            balance_a = utils::deposit_balance(&mut pool.coin_a, balance_a, amount_in);
            // destroy coin_b as it is zero coin
            balance::destroy_zero(balance_b);
            balance_b = utils::withdraw_balance(&mut pool.coin_b, amount_out);
        } else {
            balance_b = utils::deposit_balance(&mut pool.coin_b, balance_b, amount_in);
            balance::destroy_zero(balance_a);
            balance_a = utils::withdraw_balance(&mut pool.coin_a, amount_out);
        };

        events::emit_swap_event(
            object::uid_to_inner(&pool.id),
            a2b,
            amount_in,
            amount_out,
            balance::value(&pool.coin_a),
            balance::value(&pool.coin_b),
            swap_result.fee_amount + swap_result.protocol_fee,
            swap_result.starting_liquidity,
            swap_result.liquidity,
            swap_result.start_sqrt_price,
            swap_result.end_sqrt_price,
            pool.current_tick_index,
            swap_result.is_exceed,
            pool.sequence_number,
        );

 
        (balance_a, balance_b)

    }

    public fun flash_swap<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        a2b: bool,
        by_amount_in:bool,
        amount: u64,
        sqrt_price_max_limit: u128,
    ) : (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>) {

        // verify version
        config::verify_version(protocol_config);        

        assert!(!pool.is_paused, errors::pool_is_paused());

        // revert if a flash swap is already in progress
        assert!(!is_flash_swap_in_progress(&pool.id), errors::flash_swap_in_progress());

        // set flash swap in progress so no other tx can be performed
        // During the flash swap is in progress no other action like swap, add/remove liquidity can be performed
        // only the flash swap amount can be repaid
        field::add(&mut pool.id, constants::flash_swap_in_progress_key(), true);

        // the amount must be > 0
        assert!(amount > 0, errors::zero_amount());

        // compute swap results
        let swap_result = swap_in_pool<CoinTypeA, CoinTypeB>(clock, pool, a2b, by_amount_in, amount, sqrt_price_max_limit);

        let (amount_in, amount_out) = if (by_amount_in) {
            (swap_result.amount_specified- swap_result.amount_specified_remaining, swap_result.amount_calculated)
        } else {
            (swap_result.amount_calculated, swap_result.amount_specified- swap_result.amount_specified_remaining)
        };


        // get coin 
        let (balance_a, balance_b) = if (a2b) {
            ( balance::zero<CoinTypeA>(), balance::split(&mut pool.coin_b, amount_out))
        } else {
            ( balance::split(&mut pool.coin_a, amount_out), balance::zero<CoinTypeB>())
        };
        

        // emit swap event
        events::emit_flash_swap_event(
            object::uid_to_inner(&pool.id),
            a2b,
            amount_in,
            amount_out,
            swap_result.fee_amount + swap_result.protocol_fee,
            swap_result.starting_liquidity,
            swap_result.liquidity,
            swap_result.start_sqrt_price,
            swap_result.end_sqrt_price,
            pool.current_tick_index,
            swap_result.is_exceed,
            pool.sequence_number,
        );


         let receipt = FlashSwapReceipt<CoinTypeA, CoinTypeB>{
            pool_id: object::id(pool), 
            a2b, 
            pay_amount: amount_in, 
        };

        (balance_a, balance_b, receipt)

    }

    public fun calculate_swap_results<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>,
        a2b: bool,
        by_amount_in: bool,
        amount:u64, sqrt_price_max_limit: u128): SwapResult {


        if (a2b) {
            assert!(pool.current_sqrt_price > sqrt_price_max_limit && sqrt_price_max_limit >= tick_math::min_sqrt_price(), errors::invalid_price_limit());
        } else {
            assert!(pool.current_sqrt_price < sqrt_price_max_limit && sqrt_price_max_limit <= tick_math::max_sqrt_price(), errors::invalid_price_limit());
        };

        let swap_result = SwapResult{
            a2b                        : a2b,
            by_amount_in               : by_amount_in,
            amount_specified           : amount,
            amount_specified_remaining : amount, 
            amount_calculated          : 0, 
            fee_amount                 : 0, 
            protocol_fee               : 0,
            fee_growth_global          : if (a2b) {pool.fee_growth_global_coin_a} else {pool.fee_growth_global_coin_b},
            start_sqrt_price           : pool.current_sqrt_price, 
            end_sqrt_price             : pool.current_sqrt_price,
            current_tick_index         : pool.current_tick_index,
            is_exceed                  : false,
            starting_liquidity         : pool.liquidity, 
            liquidity                  : pool.liquidity, 
            steps                      : 0,
            step_results               : vector::empty<SwapStepResult>(),
        };

        // Iterate until the amount to be swapped becomes zero
        while(swap_result.amount_specified_remaining > 0 && swap_result.end_sqrt_price != sqrt_price_max_limit){

            let step_result = SwapStepResult{
                tick_index_next: MateI32::zero(),
                initialized: false,
                sqrt_price_start: swap_result.end_sqrt_price,
                sqrt_price_next: 0, 
                amount_in: 0, 
                amount_out: 0, 
                fee_amount: 0, 
                remaining_amount: 0,
            };

            // get the next tick
            let (tick_index_next, initialized) = tick_bitmap::next_initialized_tick_within_one_word(
                tick::bitmap(&pool.ticks_manager), 
                swap_result.current_tick_index, 
                tick::tick_spacing(&pool.ticks_manager),
                a2b
            );

            step_result.tick_index_next = tick_index_next;
            step_result.initialized = initialized;

            // if the tick is out of min/max tick bounds use the min/max ticks
            if (i32H::lt(step_result.tick_index_next, tick_math::min_tick())) {
                step_result.tick_index_next = tick_math::min_tick();
            } else {
                if (i32H::gt(step_result.tick_index_next, tick_math::max_tick())) {
                    step_result.tick_index_next = tick_math::max_tick();
                };
            };

            // get the price at the tick
            step_result.sqrt_price_next = tick_math::get_sqrt_price_at_tick(step_result.tick_index_next);

            // get the target sqrt price 
            let target_sqrt_price = if (a2b) {
                math_u128::max(step_result.sqrt_price_next, sqrt_price_max_limit)
            } else {
                math_u128::min(step_result.sqrt_price_next, sqrt_price_max_limit)
            };

            
            let (amount_in, amount_out, next_sqrt_price, fee_amount) = clmm_math::compute_swap_step(
                swap_result.end_sqrt_price, 
                target_sqrt_price, 
                swap_result.liquidity, 
                swap_result.amount_specified_remaining, 
                pool.fee_rate, 
                a2b, 
                by_amount_in
            );

            swap_result.end_sqrt_price = next_sqrt_price;
            

            if(by_amount_in){
                swap_result.amount_specified_remaining = swap_result.amount_specified_remaining - amount_in - fee_amount;
                swap_result.amount_calculated = swap_result.amount_calculated + amount_out;
            } else {
                swap_result.amount_specified_remaining = swap_result.amount_specified_remaining  - amount_out;
                swap_result.amount_calculated = swap_result.amount_calculated + amount_in + fee_amount;
            };

            // update this step's results
            step_result.amount_in = amount_in; 
            step_result.amount_out = amount_out; 
            step_result.fee_amount = fee_amount; 
            step_result.remaining_amount = swap_result.amount_specified_remaining;

            // Calculate protocol fee
            if (pool.protocol_fee_share > 0) {
                let protocol_fee_amount = full_math_u64::mul_div_floor(
                    fee_amount,
                    pool.protocol_fee_share,
                    clmm_math::fee_rate_denominator(),
                );
                step_result.fee_amount = step_result.fee_amount - protocol_fee_amount;
                swap_result.protocol_fee = swap_result.protocol_fee + protocol_fee_amount;
            };


            // update fee growth global
            if (swap_result.liquidity > 0) {
                swap_result.fee_growth_global = math_u128::wrapping_add(
                    swap_result.fee_growth_global, 
                    full_math_u128::mul_div_floor((step_result.fee_amount as u128), constants::q64(), swap_result.liquidity));
            };
            

            swap_result.fee_amount = swap_result.fee_amount + step_result.fee_amount;
            // Increase step count                
            swap_result.steps = swap_result.steps + 1;


            vector::push_back<SwapStepResult>(&mut swap_result.step_results, step_result);

            if(swap_result.end_sqrt_price == step_result.sqrt_price_next){
                
                // if the tick is initialized
                if(step_result.initialized){
                    let liquidity_net = tick::liquidity_net(tick::get_tick_from_manager(&pool.ticks_manager, step_result.tick_index_next));
                    
                    liquidity_net = if (a2b) {
                        i128H::neg(liquidity_net)
                    } else {
                        liquidity_net
                    };

                    swap_result.liquidity = utils::add_delta(swap_result.liquidity, liquidity_net);
                };

                swap_result.current_tick_index = if (a2b) {
                    i32H::lib_to_mate(i32::sub(i32H::mate_to_lib(step_result.tick_index_next), i32::from(1)))
                } else {
                    step_result.tick_index_next
                };
                continue
            };


            if (swap_result.end_sqrt_price != step_result.sqrt_price_start) {
                swap_result.current_tick_index = tick_math::get_tick_at_sqrt_price(swap_result.end_sqrt_price);
            };


        }; // end of while loop       

        swap_result.is_exceed =  if (swap_result.amount_specified_remaining > 0 ) { true } else { false };

        // emit swap result
        emit<SwapResult>(swap_result);

        swap_result
    }

    public fun repay_flash_swap<CoinTypeA, CoinTypeB>(protocol_config: &GlobalConfig, pool: &mut Pool<CoinTypeA, CoinTypeB>, coin_a: Balance<CoinTypeA>, coin_b: Balance<CoinTypeB>, receipt: FlashSwapReceipt<CoinTypeA, CoinTypeB>) {

        // verify version
        config::verify_version(protocol_config);

        // revert if no flash swap is in progress
        assert!(is_flash_swap_in_progress(&pool.id), errors::no_flash_swap_in_progress());

        // remove the flash swap in progress key
        field::remove<vector<u8>, bool>(&mut pool.id, constants::flash_swap_in_progress_key());

        let FlashSwapReceipt {
            pool_id,
            a2b,
            pay_amount,
        } = receipt;

        assert!(object::id(pool) == pool_id, errors::invalid_pool());

        if (a2b) {
            assert!(balance::value(&coin_a) == pay_amount, 0);
            balance::join(&mut pool.coin_a, coin_a);
            balance::destroy_zero(coin_b);
        } else {
            assert!(balance::value(&coin_b) == pay_amount, 0);
            balance::join(&mut pool.coin_b, coin_b);
            balance::destroy_zero(coin_a);
        };

        // increment the sequence since the action changed the pool state
        pool.sequence_number = pool.sequence_number + 1;

    } 

    public fun set_manager<CoinTypeA,CoinTypeB>(
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        pool_manger: address, 
        ctx: &TxContext
    ) {
        // verify version
        config::verify_version(protocol_config);
        // verify existing manager
        assert!(get_pool_manager(pool) == tx_context::sender(ctx),errors::not_authorized());

        let mutable_manager = field::borrow_mut<String, address>
                             (&mut pool.id, constants::manager());
        *mutable_manager = pool_manger;

        increase_sequence_number(pool);

        events::emit_pool_manager_update_event(
            object::uid_to_inner(&pool.id),
            pool_manger,
            pool.sequence_number
        )

    }

    /// Returns the amount to be paid for the flash swap
    public fun swap_pay_amount<CoinTypeA, CoinTypeB>(receipt: &FlashSwapReceipt<CoinTypeA, CoinTypeB>) : u64 {
        receipt.pay_amount
    }

    public fun get_pool_manager<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): address {
        let pool_manager = field::borrow<String, address>(&pool.id, constants::manager());
        *pool_manager
    }

    /// Returns the accrued protocol fee for coin A
    public fun get_protocol_fee_for_coin_a<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
        pool.protocol_fee_coin_a
    }

    /// Returns the accrued protocol fee for coin B
    public fun get_protocol_fee_for_coin_b<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
        pool.protocol_fee_coin_b
    }

    public fun open_position<CoinTypeA, CoinTypeB>(
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        lower_tick_bits: u32, 
        upper_tick_bits: u32, 
        ctx: &mut TxContext): Position {

        // verify version
        config::verify_version(protocol_config);

        let (min_allowed_tick, max_allowed_tick) = config::get_tick_range(protocol_config);

        let tick_spacing = tick::tick_spacing(&pool.ticks_manager);

        let (lower_tick, upper_tick) = (i32::from_u32(lower_tick_bits), i32::from_u32(upper_tick_bits));

        //validate ticks
        assert!(
            i32::lt(lower_tick, upper_tick) &&
            i32::gte(lower_tick, i32H::mate_to_lib(min_allowed_tick)) && 
            i32::lte(upper_tick, i32H::mate_to_lib(max_allowed_tick)) &&
            i32::abs_u32(lower_tick) % tick_spacing == 0 &&
            i32::abs_u32(upper_tick) % tick_spacing == 0,
            errors::invalid_tick_range()
        );

        let pool_id = object::id(pool);
        let coin_type_a = utils::get_type_string<CoinTypeA>();
        let coin_type_b = utils::get_type_string<CoinTypeB>();
        pool.position_index = pool.position_index + 1;

        let position = position::new(
            pool_id, 
            pool.name,
            pool.icon_url, 
            coin_type_a, 
            coin_type_b,
            pool.position_index,
            i32H::lib_to_mate(lower_tick), 
            i32H::lib_to_mate(upper_tick), 
            pool.fee_rate, 
            ctx
        );
        
        let position_id = object::id(&position);

        events::emit_position_open_event(
            pool_id, 
            position_id, 
            i32H::lib_to_mate(lower_tick), 
            i32H::lib_to_mate(upper_tick), 
        );

        position

    }

    public fun close_position<CoinTypeA, CoinTypeB>(
        _: &Clock,
        _: &GlobalConfig,
        _: &mut Pool<CoinTypeA, CoinTypeB>,
        _: Position): (Balance<CoinTypeA>, Balance<CoinTypeB>) {        
        abort errors::depricated()
    }


    public fun close_position_v2<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        position: Position) {

        // verify version
        config::verify_version(protocol_config);

        // assert that the position belongs to provided pool
        assert!(object::id(pool) == position::pool_id(&position), errors::position_does_not_belong_to_pool());

        // ensure position has no liquidity or pending rewards for claim
        let is_pos_empty = position::is_empty(&position);
        assert!(is_pos_empty , errors::non_empty_position());

        // ensure position has no fee pending for claim
        let (fee_a, fee_b) = get_accrued_fee(clock, pool, &mut position);
        assert!(fee_a == 0 && fee_b == 0, errors::cannot_close_position_with_fee_to_claim());

        // deletes position object
        let (pos_id, pool_id, lower_tick, upper_tick) = position::del(position);

        events::emit_position_close_event(
            pool_id, 
            pos_id, 
            lower_tick, 
            upper_tick
        );


    }

    /// Collect the accrued fee in position
    public fun collect_fee<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
    ):( u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>){
        
        // verify version
        config::verify_version(protocol_config);

        // ensure pool and position match
        assert!(object::id(pool) == position::pool_id(position), errors::position_does_not_belong_to_pool());

        // ensure pool is not paused
        assert!(!pool.is_paused, errors::pool_is_paused());

        // ensure there is no flash swap in progress
        assert!(!is_flash_swap_in_progress(&pool.id), errors::flash_swap_in_progress());
        

        let (fee_a, fee_b) = get_accrued_fee(clock, pool, position);
        
        let (balance_a, balance_b) = if (fee_a > 0 || fee_b > 0) { 
            let (balance_a, balance_b) = withdraw_balances(pool, fee_a, fee_b);

            increase_sequence_number(pool);

            events::emit_user_fee_collected(
                object::id(pool),
                object::id(position),
                fee_a,
                fee_b,
                balance::value(&pool.coin_a),
                balance::value(&pool.coin_b),
                pool.sequence_number
            );

             (balance_a, balance_b)
        } else {
            (balance::zero<CoinTypeA>(), balance::zero<CoinTypeB>())
        };

        (fee_a, fee_b, balance_a, balance_b)

    }

    public fun collect_reward<CoinTypeA, CoinTypeB, RewardCoinType>(
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
    ) : Balance<RewardCoinType> {

        // verify version
        config::verify_version(protocol_config);

        // ensure pool and position match
        assert!(object::id(pool) == position::pool_id(position), errors::position_does_not_belong_to_pool());

         // ensure pool is not paused
        assert!(!pool.is_paused, errors::pool_is_paused());

        // ensure there is no flash swap in progress
        assert!(!is_flash_swap_in_progress(&pool.id), errors::flash_swap_in_progress());


        let (reward_amount, reward_info) = get_accrued_rewards<CoinTypeA, CoinTypeB, RewardCoinType>(clock, pool, position);

        // only emit event if non-zero rewards are collected
        if (reward_amount > 0 ){ 

            increase_sequence_number(pool);

            events::emit_user_reward_collected(
                object::id(pool),
                object::id(position),
                utils::get_type_string<RewardCoinType>(),
                reward_info.reward_coin_symbol,
                reward_info.reward_coin_decimals,
                reward_amount,
                pool.sequence_number
            );
        };

        // if the reward amount is zero, just return zero balance        
        return if (reward_amount == 0) {
            balance::zero<RewardCoinType>()
        } else {
            let pool_reward_balance = field::borrow_mut(&mut pool.id, utils::get_type_string<RewardCoinType>());
            let balance = utils::withdraw_balance<RewardCoinType>(pool_reward_balance, reward_amount);
            balance
        }

    }

    public fun liquidity<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>
    ): u128 {
        pool.liquidity
    }

    public fun current_sqrt_price<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>
    ): u128 {
        pool.current_sqrt_price
    }

    public fun current_tick_index<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>
    ): I32 {
        pool.current_tick_index
    }

    public fun sequence_number<CoinTypeA, CoinTypeB>(
        pool: &Pool<CoinTypeA, CoinTypeB>
    ): u128 {
        pool.sequence_number
    }

    public fun verify_pool_manager<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>, manager: address): bool {
        return manager == *field::borrow<String, address>(&pool.id, constants::manager())
    }

    public fun coin_reserves<CoinTypeA, CoinTypeB> (pool: &Pool<CoinTypeA, CoinTypeB>): (u64, u64){
        (balance::value(&pool.coin_a), balance::value(&pool.coin_b))
    }

    /// Returns the protocol fee share on the pool
    public fun protocol_fee_share<CoinTypeA, CoinTypeB> (pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
        pool.protocol_fee_share
    }

    public fun reward_infos_length<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>) : u64 {
        vector::length<PoolRewardInfo>(&pool.reward_infos)
    }

    /// Returns true if the pool emits the provided reward
    public fun is_reward_present<CoinTypeA, CoinTypeB, RewardCoinType>(pool: &Pool<CoinTypeA, CoinTypeB>): bool {        
        let exist = false;        
        let reward_type = utils::get_type_string<RewardCoinType>();
        let count = vector::length(&pool.reward_infos);
        let i = 0;
        while (i < count) {
            let reward_info = vector::borrow(&pool.reward_infos, i);
            if (reward_info.reward_coin_type == reward_type) {
                exist = true;
                break
            };
            i = i + 1;
        };

        exist
    }

    public fun default_reward_info(coin_type: String, coin_symbol: String, coin_decimals: u8, start_time: u64) : PoolRewardInfo {
        PoolRewardInfo{
            reward_coin_symbol: coin_symbol,
            reward_coin_decimals: coin_decimals,
            reward_coin_type       : coin_type, 
            last_update_time       : start_time, 
            ended_at_seconds       : start_time, 
            total_reward           : 0, 
            total_reward_allocated : 0, 
            reward_per_seconds     : 0, 
            reward_growth_global   : 0,
        }
    }

    /// Returns the tick manager readable reference
    public fun get_tick_manager<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): &TickManager{
        &pool.ticks_manager
    }


    /// Returns the provided tick details if exist
    public fun fetch_provided_ticks<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>, ticks:vector<u32>): vector<TickInfo>{
        tick::fetch_provided_ticks(&pool.ticks_manager, ticks)
    }
    
    /// Returns pool fee rate
    public fun get_fee_rate<CoinTypeA,CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
        pool.fee_rate
    }

    /// Returns pool tick spacing
    public fun get_tick_spacing<CoinTypeA,CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u32 {
        tick::tick_spacing(&pool.ticks_manager)
    }

    /// Returns the a2b flag of swap result
    public fun get_swap_result_a2b(result: &SwapResult): bool {
        result.a2b
    }

    /// Returns the by amount in flag of swap result
    public fun get_swap_result_by_amount_in(result: &SwapResult): bool {
        result.by_amount_in
    }
    
    /// Returns the by input amount specified for swap calculations
    public fun get_swap_result_amount_specified(result: &SwapResult): u64 {
        result.amount_specified
    }

    /// Returns the input amount remaining after swap
    public fun get_swap_result_amount_specified_remaining(result: &SwapResult): u64 {
        result.amount_specified_remaining
    }

    /// Returns the swap amount calculated
    public fun get_swap_result_amount_calculated(result: &SwapResult): u64 {
        result.amount_calculated
    }
    
    /// Returns the fee growth global after the swap calculations
    public fun get_swap_result_fee_growth_global(result: &SwapResult): u128 {
        result.fee_growth_global
    }

    /// Returns the fee amount calculated for LPs from the swap
    public fun get_swap_result_fee_amount(result: &SwapResult): u64 {
        result.fee_amount
    }

    /// Returns the protocol fee amount calculated from the swap
    public fun get_swap_result_protocol_fee(result: &SwapResult): u64 {
        result.protocol_fee
    }

    /// Returns the starting sqrt price of the pool prior to swap
    public fun get_swap_result_start_sqrt_price(result: &SwapResult): u128 {
        result.start_sqrt_price
    }

    /// Returns the ending sqrt price of the pool after the swap
    public fun get_swap_result_end_sqrt_price(result: &SwapResult): u128 {
        result.end_sqrt_price
    }
    
    /// Returns the current tick index of the pool (at end sqrt price) after the swap
    public fun get_swap_result_current_tick_index(result: &SwapResult): I32 {
        result.current_tick_index
    }

    /// Returns true if input amount was not fully swapped
    public fun get_swap_result_is_exceed(result: &SwapResult): bool {
        result.is_exceed
    }

    /// Returns the liquidity of the pool prior to swap calculations
    public fun get_swap_result_starting_liquidity(result: &SwapResult): u128 {
        result.starting_liquidity
    }

    /// Returns the liquidity of the pool after the swap calculations    
    public fun get_swap_result_liquidity(result: &SwapResult): u128 {
        result.liquidity
    }

    /// Returns the number of ticks used to compute the swap amount    
    public fun get_swap_result_steps(result: &SwapResult): u64 {
        result.steps
    }    

    /// Returns the liquidity, coin a and coin b amount by the provided input coin amount
    public fun get_liquidity_by_amount(
        lower_index:I32, 
        upper_index: I32, 
        current_tick_index: I32, 
        current_sqrt_price: u128, 
        amount: u64, 
        is_fixed_a: bool): (u128, u64, u64) {

        clmm_math::get_liquidity_by_amount(
            lower_index,
            upper_index,
            current_tick_index,
            current_sqrt_price,
            amount,
            is_fixed_a
        )
    }


    /// Returns the coin A and B amounts by provided liquidity input
    public fun get_amount_by_liquidity(
        lower_index:I32, 
        upper_index: I32, 
        current_tick_index: I32, 
        current_sqrt_price: u128, 
        liquidity: u128, 
        round_up: bool ): (u64, u64) {

        clmm_math::get_amount_by_liquidity(
            lower_index,
            upper_index,
            current_tick_index,
            current_sqrt_price,
            liquidity,
            round_up
        )
    }
     
    /// Returns the name of the pool
    public fun get_pool_name<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): String {
        pool.name
    }


    //===========================================================//
    //                    Internal Functions                     //
    //===========================================================//

    fun find_reward_info_index<CoinTypeA, CoinTypeB, RewardCoinType>(pool: &Pool<CoinTypeA, CoinTypeB>) : u64 {
        let start_index = 0;
        let reward_index = start_index;
        let reward_found = false;
        let current_index = start_index;
        while (current_index < vector::length<PoolRewardInfo>(&pool.reward_infos)) {
            if (vector::borrow<PoolRewardInfo>(&pool.reward_infos, current_index).reward_coin_type == utils::get_type_string<RewardCoinType>()) {
                reward_index = current_index;
                reward_found = true;
                break
            };
            current_index = current_index + 1;
        };
        assert!(reward_found, errors::reward_index_not_found());
        reward_index
    }

    fun swap_in_pool<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        a2b: bool, 
        by_amount_in: bool, 
        amount:u64, 
        sqrt_price_max_limit: u128): SwapResult {

        if (a2b) {
            assert!(pool.current_sqrt_price > sqrt_price_max_limit && sqrt_price_max_limit > tick_math::min_sqrt_price(), errors::invalid_price_limit());
        } else {
            assert!(pool.current_sqrt_price < sqrt_price_max_limit && sqrt_price_max_limit < tick_math::max_sqrt_price(), errors::invalid_price_limit());
        };

        let target = utils::timestamp_seconds(clock);

        let swap_result = SwapResult{
            a2b                        : a2b,
            by_amount_in               : by_amount_in,
            amount_specified           : amount,
            amount_specified_remaining : amount, 
            amount_calculated          : 0, 
            fee_amount                 : 0, 
            protocol_fee               : 0,
            fee_growth_global          : if (a2b) {pool.fee_growth_global_coin_a} else {pool.fee_growth_global_coin_b},
            start_sqrt_price           : pool.current_sqrt_price, 
            end_sqrt_price             : pool.current_sqrt_price,
            current_tick_index         : pool.current_tick_index,
            is_exceed                  : false,
            starting_liquidity         : pool.liquidity, 
            liquidity                  : pool.liquidity, 
            steps                      : 0,
            step_results               : vector::empty<SwapStepResult>(),
        };

        // Iterate until the amount to be swapped becomes zero
        while(swap_result.amount_specified_remaining > 0 && swap_result.end_sqrt_price != sqrt_price_max_limit){

            let step_result = SwapStepResult{
                tick_index_next: MateI32::zero(),
                initialized: false,
                sqrt_price_start: swap_result.end_sqrt_price,
                sqrt_price_next: 0, 
                amount_in: 0, 
                amount_out: 0, 
                fee_amount: 0, 
                remaining_amount: 0,
            };

            // get the next tick
            let (tick_index_next, initialized) = tick_bitmap::next_initialized_tick_within_one_word(
                tick::bitmap(&pool.ticks_manager), 
                swap_result.current_tick_index, 
                tick::tick_spacing(&pool.ticks_manager),
                a2b
            );

            step_result.tick_index_next = tick_index_next;
            step_result.initialized = initialized;

            // if the tick is out of min/max tick bounds use the min/max ticks
            if (i32H::lt(step_result.tick_index_next, tick_math::min_tick())) {
                step_result.tick_index_next = tick_math::min_tick();
            } else {
                if (i32H::gt(step_result.tick_index_next, tick_math::max_tick())) {
                    step_result.tick_index_next = tick_math::max_tick();
                };
            };

            // get the price at the tick
            step_result.sqrt_price_next = tick_math::get_sqrt_price_at_tick(step_result.tick_index_next);

            // get the target sqrt price 
            let target_sqrt_price = if (a2b) {
                math_u128::max(step_result.sqrt_price_next, sqrt_price_max_limit)
            } else {
                math_u128::min(step_result.sqrt_price_next, sqrt_price_max_limit)
            };

            
            let (amount_in, amount_out, next_sqrt_price, fee_amount) = clmm_math::compute_swap_step(
                swap_result.end_sqrt_price, 
                target_sqrt_price, 
                swap_result.liquidity, 
                swap_result.amount_specified_remaining, 
                pool.fee_rate, 
                a2b, 
                by_amount_in
            );

            swap_result.end_sqrt_price = next_sqrt_price;
            

            if(by_amount_in){
                swap_result.amount_specified_remaining = swap_result.amount_specified_remaining - amount_in - fee_amount;
                swap_result.amount_calculated = swap_result.amount_calculated + amount_out;
            } else {
                swap_result.amount_specified_remaining = swap_result.amount_specified_remaining  - amount_out;
                swap_result.amount_calculated = swap_result.amount_calculated + amount_in + fee_amount;
            };

            // update this step's results
            step_result.amount_in = amount_in; 
            step_result.amount_out = amount_out; 
            step_result.fee_amount = fee_amount; 
            step_result.remaining_amount = swap_result.amount_specified_remaining;

            // Calculate protocol fee
            if (pool.protocol_fee_share > 0) {
                let protocol_fee_amount = full_math_u64::mul_div_floor(
                    fee_amount,
                    pool.protocol_fee_share,
                    clmm_math::fee_rate_denominator(),
                );
                step_result.fee_amount = step_result.fee_amount - protocol_fee_amount;
                swap_result.protocol_fee = swap_result.protocol_fee + protocol_fee_amount;
            };


            // update fee growth global
            if (swap_result.liquidity > 0) {
                swap_result.fee_growth_global = math_u128::wrapping_add(
                    swap_result.fee_growth_global, 
                    full_math_u128::mul_div_floor((step_result.fee_amount as u128), constants::q64(), swap_result.liquidity));
            };
            

            swap_result.fee_amount = swap_result.fee_amount + step_result.fee_amount;
            // Increase step count                
            swap_result.steps = swap_result.steps + 1;

            if(swap_result.end_sqrt_price == step_result.sqrt_price_next){
                
                let (fee_growth_global_coin_a, fee_growth_global_coin_b) = if (a2b) {
                    (swap_result.fee_growth_global, pool.fee_growth_global_coin_b)
                } else {
                    ( pool.fee_growth_global_coin_a, swap_result.fee_growth_global)
                };

                // if the tick is initialized
                if(step_result.initialized){
                    
                    let (tick_cumulative, seconds_per_liquidity_cumulative) = oracle::observe_single(
                        &pool.observations_manager, 
                        target,
                        0, 
                        pool.current_tick_index,
                        pool.liquidity
                    );
                    let new_reward_growths_global = update_reward_infos<CoinTypeA, CoinTypeB>(pool,  utils::timestamp_seconds(clock));
                    let liquidity_net = tick::cross(
                        &mut pool.ticks_manager,
                        step_result.tick_index_next,
                        fee_growth_global_coin_a,
                        fee_growth_global_coin_b,
                        new_reward_growths_global,
                        tick_cumulative,
                        seconds_per_liquidity_cumulative,
                        target
                    );

            
                    liquidity_net = if (a2b) {
                        i128H::neg(liquidity_net)
                    } else {
                        liquidity_net
                    };
                    
                    swap_result.liquidity = utils::add_delta(swap_result.liquidity, liquidity_net);
                };

                swap_result.current_tick_index = if (a2b) {
                    i32H::lib_to_mate(i32::sub(i32H::mate_to_lib(step_result.tick_index_next), i32::from(1)))
                } else {
                    step_result.tick_index_next
                };
                continue
            };

            if (swap_result.end_sqrt_price != step_result.sqrt_price_start) {
                swap_result.current_tick_index = tick_math::get_tick_at_sqrt_price(swap_result.end_sqrt_price);
            };

        }; // end of while loop       

        swap_result.is_exceed =  swap_result.amount_specified_remaining > 0;

        update_pool_state(pool, swap_result, target);

        swap_result
    }


    fun update_data_for_delta_l<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position, 
        liquidity_delta: LibraryI128Type, 
        ) : (u64, u64) {

        let new_reward_growth_globals = update_reward_infos<CoinTypeA, CoinTypeB>(pool, utils::timestamp_seconds(clock));
        
        let liquidity_amount = i128::abs_u128(liquidity_delta);
        let lower_tick = position::lower_tick(position);
        let upper_tick = position::upper_tick(position);



        let (lower_tick_flipped, upper_tick_flipped) = (false, false);

        let tick_spacing = tick::tick_spacing(&pool.ticks_manager);

        let target = utils::timestamp_seconds(clock);

        if (liquidity_amount > 0) {
            let id = object::id(pool);
            let (tick_cumulative, seconds_per_liquidity_cumulative) = oracle::observe_single(
                &pool.observations_manager, 
                target,
                0, 
                pool.current_tick_index,
                pool.liquidity
            );

            lower_tick_flipped = tick::update(
                &mut pool.ticks_manager,
                id, 
                lower_tick, 
                pool.current_tick_index, 
                i128H::lib_to_mate(liquidity_delta), 
                pool.fee_growth_global_coin_a, 
                pool.fee_growth_global_coin_b,
                new_reward_growth_globals, 
                tick_cumulative,
                seconds_per_liquidity_cumulative, 
                target, 
                false, // updating lower tick so false
            );

            upper_tick_flipped = tick::update(
                &mut pool.ticks_manager,
                id,
                upper_tick, 
                pool.current_tick_index, 
                i128H::lib_to_mate(liquidity_delta), 
                pool.fee_growth_global_coin_a, 
                pool.fee_growth_global_coin_b,
                new_reward_growth_globals,
                tick_cumulative,
                seconds_per_liquidity_cumulative, 
                target, 
                true, // updating upper tick so true
            );

            if (lower_tick_flipped) {
                tick_bitmap::flip_tick(tick::mutable_bitmap(&mut pool.ticks_manager), lower_tick, tick_spacing);
            };
            if (upper_tick_flipped) {
                tick_bitmap::flip_tick(tick::mutable_bitmap(&mut pool.ticks_manager), upper_tick, tick_spacing);
            };
        };

        let (fee_growth_inside_a, fee_growth_inside_b, reward_growths_inside) = tick::get_fee_and_reward_growths_inside(
            &pool.ticks_manager, 
            lower_tick, 
            upper_tick, 
            pool.current_tick_index, 
            pool.fee_growth_global_coin_a, 
            pool.fee_growth_global_coin_b, 
            new_reward_growth_globals
        );

        position::update(
            position, 
            i128H::lib_to_mate(liquidity_delta),
            fee_growth_inside_a,
            fee_growth_inside_b,
            reward_growths_inside
        );

        if (i128::lt(liquidity_delta, i128::zero())) {
            if (lower_tick_flipped) {
                tick::remove(&mut pool.ticks_manager, lower_tick);
            };
            if (upper_tick_flipped) {
                tick::remove(&mut pool.ticks_manager, upper_tick);
            };
        };

        if (i32H::gte(pool.current_tick_index, lower_tick) && i32H::lt(pool.current_tick_index, upper_tick)) {
            
                oracle::update(
                    &mut pool.observations_manager, 
                    pool.current_tick_index,
                    pool.liquidity,
                    target,
                );

                pool.liquidity = utils::add_delta(pool.liquidity, i128H::lib_to_mate(liquidity_delta));
        };

        // compute the swap amounts and return        
        clmm_math::get_amount_by_liquidity(
            lower_tick,
            upper_tick,
            pool.current_tick_index,
            pool.current_sqrt_price,
            liquidity_amount,
            !i128::is_neg(liquidity_delta) // round up if liquidity is to be added, round down otherwise
        )
    }

    fun update_pool_state<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>, swap_result: SwapResult, current_time: u64) {
        
        // current tick index of pool is not the same as swap result
        if (!i32H::eq(pool.current_tick_index, swap_result.current_tick_index)) {

            oracle::update(
                &mut pool.observations_manager, 
                pool.current_tick_index,
                pool.liquidity,
                current_time,
            );

            pool.current_sqrt_price = swap_result.end_sqrt_price;
            pool.current_tick_index = swap_result.current_tick_index;

        } else {
            pool.current_sqrt_price = swap_result.end_sqrt_price;
        };

        // update liquidity
        if (pool.liquidity != swap_result.liquidity) {
            pool.liquidity = swap_result.liquidity;
        };
        
        // update protocol fee and fee growth global
        if(swap_result.a2b){
            pool.protocol_fee_coin_a = pool.protocol_fee_coin_a + swap_result.protocol_fee;
            pool.fee_growth_global_coin_a = swap_result.fee_growth_global;
        } else {
            pool.protocol_fee_coin_b = pool.protocol_fee_coin_b + swap_result.protocol_fee;
            pool.fee_growth_global_coin_b = swap_result.fee_growth_global;
        };

        // increment the seqeunce since the action changed the pool state
        pool.sequence_number = pool.sequence_number + 1;
    }

    fun get_accrued_rewards<CoinTypeA, CoinTypeB, RewardCoinType>(
        clock: &Clock, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position
        ): (u64, PoolRewardInfo) {
        
        if (position::liquidity(position) > 0) {
            let (_, _) = update_data_for_delta_l(clock, pool, position, i128::zero());        
        };


        let pool_reward_infos_len = reward_infos_length(pool);
        // this loop is to add missing reward info if applicable, inside position's vector when comparing to pool rewards vector
        while(position::reward_infos_length(position) < pool_reward_infos_len)
        {
            position::add_reward_info(position)
        };

        let reward_index = find_reward_info_index<CoinTypeA, CoinTypeB, RewardCoinType>(pool);
        let reward_amount = position::coins_owed_reward(position, reward_index);
        position::decrease_reward_amount(position, reward_index, reward_amount);

        let reward_info = vector::borrow<PoolRewardInfo>(&pool.reward_infos, reward_index);

        (reward_amount, *reward_info)
    }

    fun get_accrued_fee<CoinTypeA, CoinTypeB>(clock: &Clock, pool: &mut Pool<CoinTypeA, CoinTypeB>, position: &mut Position): (u64, u64) {
            
            if (position::liquidity(position) > 0) {
                let (_, _) = update_data_for_delta_l(clock, pool, position, i128::zero());
            };
            // get user fee        
            let (fee_a, fee_b) = position::get_accrued_fee(position);
            
            // set fee amounts to zero
            position::set_fee_amounts(position, 0, 0);
            (fee_a, fee_b)
    }   

    fun create_pool_internal<CoinTypeA, CoinTypeB> (
        clock: &Clock,
        protocol_config: &GlobalConfig,
        pool_name: vector<u8>, 
        icon_url: vector<u8>,
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>, 
        tick_spacing: u32,
        fee_rate: u64,
        current_sqrt_price: u128,
        ctx: &mut TxContext
    ): Pool<CoinTypeA, CoinTypeB> {
        // verify version
        config::verify_version(protocol_config);

        // if icon url is empty, use default icon url
        let icon_url = if (vector::length(&icon_url) == 0) {
            DEFAULT_POOL_ICON_URL
        } else {
            icon_url
        };

        // revert if tick spacing > max allowed tick spacing
        assert!(tick_spacing <= constants::max_allowed_tick_spacing(), errors::invalid_tick_spacing());

        // revert if fee rate is > max allowed fee rate
        assert!(fee_rate <= constants::max_allowed_fee_rate(), errors::invalid_fee_rate());

        // a  pool can not be initialized at max sqrt price
        assert!(current_sqrt_price < tick_math::max_sqrt_price(), errors::invalid_pool_price());

        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);

        let ticks_manager = tick::initialize_manager(tick_spacing, ctx);
        let observations_manager = oracle::initialize_manager(utils::timestamp_seconds(clock));

        let current_tick_index = tick_math::get_tick_at_sqrt_price(current_sqrt_price);

        let coin_a_type = utils::get_type_string<CoinTypeA>();
        let coin_b_type = utils::get_type_string<CoinTypeB>();

        assert!(coin_a_type != coin_b_type, errors::invalid_coins());

        let pool = Pool<CoinTypeA, CoinTypeB> {
            id:uid,
            name: string::utf8(pool_name),
            coin_a: balance::zero<CoinTypeA>(),
            coin_b: balance::zero<CoinTypeB>(),
            fee_rate,
            protocol_fee_share: constants::protocol_fee_share(),
            fee_growth_global_coin_a: 0,
            fee_growth_global_coin_b: 0,
            protocol_fee_coin_a: 0,
            protocol_fee_coin_b: 0,
            ticks_manager,
            observations_manager,
            current_sqrt_price,
            current_tick_index,
            liquidity: 0,
            is_paused: false,
            icon_url: string::utf8(icon_url),
            position_index: 0,
            sequence_number: 0,
            reward_infos: vector::empty<PoolRewardInfo>()
        };

        // add pool creator as manager
        field::add<String, address>(
            &mut pool.id, 
            constants::manager(),
            tx_context::sender(ctx)
        );

        events::emit_pool_created_event(
            id, 
            coin_a_type,
            string::utf8(coin_a_symbol), 
            coin_a_decimals, 
            string::utf8(coin_a_url), 
            coin_b_type,
            string::utf8(coin_b_symbol), 
            coin_b_decimals, 
            string::utf8(coin_b_url), 
            current_sqrt_price,
            current_tick_index,
            tick_spacing,
            fee_rate,
            constants::protocol_fee_share()
        );

        pool
    }

    fun charge_pool_creation_fee<CoinTypeFee>(
        protocol_config: &mut GlobalConfig,
        pool: ID,
        creation_fee: Balance<CoinTypeFee>, 
        ctx: &TxContext,
        ){

        let fee_amount = balance::value(&creation_fee);

        // get the fee amount required for provided coin type to create a pool
        let (supported, fee_required) = config::get_pool_creation_fee_amount<CoinTypeFee>(protocol_config);

        // revert if the provided fee coin is not supported for pool creation
        assert!(supported, errors::fee_coin_not_supported());

        // revert if the user provided < or > fee then required
        assert!(fee_amount == fee_required, errors::invalid_fee_provided());

        let config_id = config::get_config_id(protocol_config);
        let fee_coin_type = utils::get_type_string<CoinTypeFee>();

        // create the dynamic field if it does not exist
        if(!field::exists_(config_id, fee_coin_type)){
                field::add(
                    config_id,
                    fee_coin_type,
                    balance::zero<CoinTypeFee>()
                );
        };

        // add the fee to the accrued fee
        let accrued_fee = field::borrow_mut(config_id, fee_coin_type);
        balance::join(accrued_fee, creation_fee);

        events::emit_pool_creation_fee_paid_event(
            pool,
            tx_context::sender(ctx),
            utils::get_type_string<CoinTypeFee>(),
            fee_amount,
            balance::value(accrued_fee)
        );
    }

    fun is_flash_swap_in_progress(pool: &UID): bool {
        field::exists_(pool, constants::flash_swap_in_progress_key())
    }

    #[test_only]
    public fun is_pool_paused<CoinTypeA,CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): bool {
        pool.is_paused
    }

    #[test_only]
    public fun create_test_pool_without_liquidity<CoinTypeA, CoinTypeB, CoinTypeFee>(
        clock: &Clock,
        protocol_config: &mut GlobalConfig,
        pool_name: vector<u8>, 
        icon_url: vector<u8>,
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>, 
        tick_spacing: u32,
        fee_rate: u64,
        current_sqrt_price: u128,
        creation_fee: Balance<CoinTypeFee>,
        ctx: &mut TxContext): Pool<CoinTypeA, CoinTypeB> {

        // create pool
        let pool = create_pool_internal<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            pool_name,
            icon_url,
            coin_a_symbol,
            coin_a_decimals,
            coin_a_url,
            coin_b_symbol,
            coin_b_decimals,
            coin_b_url,
            tick_spacing,
            fee_rate,
            current_sqrt_price, 
            ctx,           
        );


        let id = object::id(&pool);
        charge_pool_creation_fee<CoinTypeFee>(protocol_config, id, creation_fee, ctx);

        pool

    }

    #[test_only]
    public fun create_test_pool_with_liquidity<CoinTypeA, CoinTypeB, CoinTypeFee>(
        clock: &Clock,
        protocol_config: &mut GlobalConfig,
        pool_name: vector<u8>, 
        icon_url: vector<u8>,
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>, 
        tick_spacing: u32,
        fee_rate: u64,
        current_sqrt_price: u128,
        creation_fee: Balance<CoinTypeFee>,
        lower_tick_bits: u32, 
        upper_tick_bits: u32, 
        balance_a: Balance<CoinTypeA>,
        balance_b: Balance<CoinTypeB>,
        amount: u64,
        is_fixed_a: bool,
        ctx: &mut TxContext): (Pool<CoinTypeA, CoinTypeB>, Position,  u64, u64, Balance<CoinTypeA>, Balance<CoinTypeB>) {

            // create pool
        let pool = create_pool_internal<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            pool_name,
            icon_url,
            coin_a_symbol,
            coin_a_decimals,
            coin_a_url,
            coin_b_symbol,
            coin_b_decimals,
            coin_b_url,
            tick_spacing,
            fee_rate,
            current_sqrt_price, 
            ctx,           
        );


        let id = object::id(&pool);

        // charge pool creation fee
        charge_pool_creation_fee<CoinTypeFee>(protocol_config, id, creation_fee, ctx);

        // open position
        let position = open_position(protocol_config, &mut pool, lower_tick_bits, upper_tick_bits, ctx);

        let (coin_a_provided, coin_b_provided, balance_token_a, balance_token_b) = add_liquidity_with_fixed_amount<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            &mut pool, 
            &mut position,
            balance_a,
            balance_b,
            amount,
            is_fixed_a
        );

        (pool, position, coin_a_provided, coin_b_provided, balance_token_a, balance_token_b)

    } 

    #[test_only]
    public fun get_accrued_fee_amount<CoinTypeA, CoinTypeB>(
        clock: &Clock, pool: &mut Pool<CoinTypeA, CoinTypeB>, position: &mut Position
    ): (u64, u64) {
        if (position::liquidity(position) > 0) {
            let (_, _) = update_data_for_delta_l(clock, pool, position, i128::zero());
        };
        // get user fee        
        let (fee_a, fee_b) = position::get_accrued_fee(position);
        
        (fee_a, fee_b)
    }

    #[test_only]
    public fun get_accrued_reward_amount<CoinTypeA, CoinTypeB, RewardCoinType>(
        clock: &Clock, pool: &mut Pool<CoinTypeA, CoinTypeB>, position: &mut Position
    ): u64 {
                
        if (position::liquidity(position) > 0) {
            let (_, _) = update_data_for_delta_l(clock, pool, position, i128::zero());        
        };


        let pool_reward_infos_len = reward_infos_length(pool);
        // this loop is to add missing reward info if applicable, inside position's vector when comparing to pool rewards vector
        while(position::reward_infos_length(position) < pool_reward_infos_len)
        {
            position::add_reward_info(position)
        };

        let reward_index = find_reward_info_index<CoinTypeA, CoinTypeB, RewardCoinType>(pool);
        let reward_amount = position::coins_owed_reward(position, reward_index);

        reward_amount
    }
}
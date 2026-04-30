/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::events {
    use sui::object::ID;
    use std::string::{String};
    use sui::event::emit;


    use integer_mate::i32::{I32};
    use integer_mate::i128::{I128};

    // friend modules
    friend bluefin_spot::pool;
    friend bluefin_spot::admin;
    friend bluefin_spot::tick;
    friend bluefin_spot::config;
    #[test_only]
    friend bluefin_spot::test_event;

    //===========================================================//
    //                           Structs                         //
    //===========================================================//

    struct AdminCapTransferred has copy, drop {
        owner: address
    } 

    struct ProtocolFeeCapTransferred has copy, drop {
        owner: address
    } 

    struct PoolCreated has copy, drop {
        id: ID,
        coin_a: String,
        coin_a_symbol: String, 
        coin_a_decimals: u8, 
        coin_a_url: String, 
        coin_b: String,
        coin_b_symbol: String, 
        coin_b_decimals: u8, 
        coin_b_url: String, 
        current_sqrt_price: u128,
        current_tick_index: I32,
        tick_spacing: u32,
        fee_rate: u64, 
        protocol_fee_share: u64
    }

    struct PositionOpened has copy, drop {
        pool_id: ID,
        position_id: ID,
        tick_lower: I32,
        tick_upper: I32
    }

    struct PositionClosed has copy, drop {
        pool_id: ID,
        position_id: ID,
        tick_lower: I32,
        tick_upper: I32
    }

    struct AssetSwap has copy, drop {
        pool_id: ID,
        a2b: bool,
        amount_in: u64,
        amount_out: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        fee: u64,
        before_liquidity: u128,
        after_liquidity: u128,
        before_sqrt_price: u128,
        after_sqrt_price: u128,
        current_tick: I32,
        exceeded: bool,
        sequence_number: u128
    }

    struct FlashSwap has copy, drop {
        pool_id: ID,
        a2b: bool,
        amount_in: u64,
        amount_out: u64,
        fee: u64,
        before_liquidity: u128,
        after_liquidity: u128,
        before_sqrt_price: u128,
        after_sqrt_price: u128,
        current_tick: I32,
        exceeded: bool,
        sequence_number: u128

    }

    struct ProtocolFeeCollected has copy, drop {
        pool_id: ID,
        sender: address,
        destination: address,
        coin_a_amount: u64,
        coin_b_amount: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        sequence_number: u128

    }

    struct UserFeeCollected has copy, drop {
        pool_id: ID,
        position_id: ID,
        coin_a_amount: u64,
        coin_b_amount: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        sequence_number: u128

    }

    struct UserRewardCollected has copy, drop {
        pool_id: ID,
        position_id: ID,
        reward_type: String,
        reward_symbol: String,
        reward_decimals: u8,
        reward_amount: u64,
        sequence_number: u128
    }


    struct LiquidityProvided has copy, drop {
        pool_id: ID,
        position_id: ID, 
        coin_a_amount: u64, 
        coin_b_amount: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        liquidity: u128, 
        before_liquidity: u128, 
        after_liquidity: u128,
        current_sqrt_price: u128,
        current_tick_index: I32,
        lower_tick: I32,
        upper_tick: I32,
        sequence_number: u128

    }

    struct LiquidityRemoved has copy, drop {
        pool_id: ID,
        position_id: ID, 
        coin_a_amount: u64, 
        coin_b_amount: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        liquidity: u128, 
        before_liquidity: u128, 
        after_liquidity: u128,
        current_sqrt_price: u128,
        current_tick_index: I32,
        lower_tick: I32,
        upper_tick: I32,
        sequence_number: u128
    }

    struct UpdatePoolRewardEmissionEvent has copy, drop {
        pool_id: ID,
        reward_coin_symbol: String,
        reward_coin_type: String,
        reward_coin_decimals: u8,
        total_reward: u64,
        ended_at_seconds: u64,
        last_update_time: u64,
        reward_per_seconds: u128,
        sequence_number: u128
    }

    struct SupportedVersionUpdate has copy, drop {
        old_version: u64, 
        new_version: u64
    }

    #[allow(unused_field)]
    struct TickUpdate has copy, drop {
        index: I32,
        liquidity_gross: u128,
        liquidity_net: I128
    }

    struct PoolPauseStatusUpdate has copy, drop {
        pool_id: ID,
        status: bool,
        sequence_number: u128
    }

    struct RewardsManagerUpdate has copy, drop {
        manager: address,
        is_active: bool
    }
    
    struct PoolTickUpdate has copy, drop {
        pool: ID,
        index: I32,
        liquidity_gross: u128,
        liquidity_net: I128
    }

    struct ProtocolFeeShareUpdated has copy, drop {
        pool: ID, 
        previous_protocol_fee_share: u64,
        current_protocol_fee_share: u64,
        sequence_number: u128
    }

    struct ObservationCardinalityUpdated has copy, drop {
        pool: ID,
        previous_observation_cardinality: u64,
        current_observation_cardinality: u64,
        sequence_number: u128
    }

    struct PoolManagerUpdate has copy, drop {
        pool_id: ID,
        new_manager: address,
        sequence_number: u128,
    }

    struct PoolCreationFeeUpdate has copy, drop {
        coin_type: String,
        previous_fee_amount: u64,
        current_fee_amount: u64,
    }

    struct PoolCreationFeePaid has copy, drop {
        pool: ID, 
        creator: address,
        coin_type: String, 
        fee_amount: u64,
        total_accrued_fee: u64
    }

    struct PoolCreationFeeClaimed has copy, drop {
        coin_type: String, 
        amount: u64,
        destination: address,
        accrued_fee_before: u64, 
        accrued_fee_after: u64,         
    }

    struct PoolRewardReservesIncreased has copy, drop {
        pool: ID,
        reward_coin_type: String,
        amount: u64,
        reserves_before: u64,
        revers_after: u64
    }

    struct PoolIconUrlUpdate has copy, drop {
        pool_id: ID,
        icon_url: String,
        sequence_number: u128
    }

    //===========================================================//
    //                     Friend Functions                      //
    //===========================================================//


    public (friend) fun emit_pool_created_event(id: ID, 
        coin_a: String,
        coin_a_symbol: String, 
        coin_a_decimals: u8, 
        coin_a_url: String, 
        coin_b: String,
        coin_b_symbol: String, 
        coin_b_decimals: u8, 
        coin_b_url: String, 
        current_sqrt_price: u128, current_tick_index: I32, tick_spacing: u32, fee_rate: u64, protocol_fee_share: u64) {
        emit(
            PoolCreated {
                id,
                coin_a,
                coin_a_symbol,
                coin_a_decimals,
                coin_a_url,
                coin_b,
                coin_b_symbol,
                coin_b_decimals,
                coin_b_url,
                current_sqrt_price,
                current_tick_index,
                tick_spacing,
                fee_rate,
                protocol_fee_share
            }
        );
    }

    public (friend) fun emit_liquidity_provided_event(
        pool_id: ID,
        position_id: ID,
        coin_a_amount: u64, 
        coin_b_amount: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        liquidity: u128, 
        before_liquidity: u128,
        after_liquidity: u128,
        current_sqrt_price: u128,
        current_tick_index: I32,
        lower_tick: I32,
        upper_tick: I32,
        sequence_number: u128,
    ) {

        emit(
            LiquidityProvided {
                pool_id,
                position_id,
                coin_a_amount,
                coin_b_amount,
                pool_coin_a_amount,
                pool_coin_b_amount,
                liquidity,
                before_liquidity,
                after_liquidity,
                current_sqrt_price,
                current_tick_index,
                lower_tick,
                upper_tick,
                sequence_number,
            }
        );        
    }


    public (friend) fun emit_liquidity_removed_event(
        pool_id: ID,
        position_id: ID, 
        coin_a_amount: u64, 
        coin_b_amount: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        liquidity: u128, 
        before_liquidity: u128,
        after_liquidity: u128,
        current_sqrt_price: u128,
        current_tick_index: I32,
        lower_tick: I32,
        upper_tick: I32,
        sequence_number: u128,
    ) {

        emit(
            LiquidityRemoved {
                pool_id,
                position_id,
                coin_a_amount,
                coin_b_amount,
                pool_coin_a_amount,
                pool_coin_b_amount,
                liquidity,
                before_liquidity,
                after_liquidity,
                current_sqrt_price,
                current_tick_index,
                lower_tick,
                upper_tick,
                sequence_number,
            }
        );        
    }

    public (friend) fun emit_swap_event(
        pool_id: ID,
        a2b: bool,
        amount_in: u64,
        amount_out: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        fee: u64,
        before_liquidity: u128,
        after_liquidity: u128,
        before_sqrt_price: u128,
        after_sqrt_price: u128,
        current_tick: I32,
        exceeded: bool,
        sequence_number: u128,
    ){

        emit(
            AssetSwap {
                pool_id,
                a2b,
                amount_in,
                amount_out,
                pool_coin_a_amount,
                pool_coin_b_amount,
                fee,
                before_liquidity,
                after_liquidity,
                before_sqrt_price,
                after_sqrt_price,
                current_tick,
                exceeded,
                sequence_number,

            }
        );            
    }


    public (friend) fun emit_flash_swap_event(
        pool_id: ID,
        a2b: bool,
        amount_in: u64,
        amount_out: u64,
        fee: u64,
        before_liquidity: u128,
        after_liquidity: u128,
        before_sqrt_price: u128,
        after_sqrt_price: u128,
        current_tick: I32,
        exceeded: bool,
        sequence_number: u128,
    ){

        emit(
            FlashSwap {
                pool_id,
                a2b,
                amount_in,
                amount_out,
                fee,
                before_liquidity,
                after_liquidity,
                before_sqrt_price,
                after_sqrt_price,
                current_tick,
                exceeded,
                sequence_number
            }
        );            
    }

    public(friend) fun emit_admin_cap_transfer_event(owner:address){
        emit(
            AdminCapTransferred {
                owner
            }
        );
    }

    public(friend) fun emit_protocol_fee_cap_transfer_event(owner:address){
        emit(
            ProtocolFeeCapTransferred {
                owner
            }
        );
    }

    public(friend) fun emit_protocol_fee_collected(
        pool_id: ID,
        sender: address,
        destination: address,
        coin_a_amount: u64,
        coin_b_amount: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        sequence_number: u128
    ){
        emit(
            ProtocolFeeCollected {
                pool_id,
                sender,
                destination,
                coin_a_amount,
                coin_b_amount,
                pool_coin_a_amount,
                pool_coin_b_amount,
                sequence_number,
            }
        );
    }

    public(friend) fun emit_user_fee_collected(
        pool_id: ID,
        position_id: ID,
        coin_a_amount: u64,
        coin_b_amount: u64,
        pool_coin_a_amount: u64,
        pool_coin_b_amount: u64,
        sequence_number:u128){
        emit(
            UserFeeCollected {
                pool_id,
                position_id,
                coin_a_amount,
                coin_b_amount,
                pool_coin_a_amount,
                pool_coin_b_amount,
                sequence_number,
            }
        );
    }

    public(friend) fun emit_user_reward_collected(
        pool_id: ID, 
        position_id: ID,
        reward_type: String,
        reward_symbol: String,
        reward_decimals: u8,
        reward_amount: u64,
        sequence_number: u128){
        emit(
            UserRewardCollected {
                pool_id,
                position_id,
                reward_type,
                reward_symbol,
                reward_decimals,
                reward_amount,
                sequence_number,
            }
        );
    }



    public(friend) fun emit_position_open_event(pool_id: ID, position_id: ID, tick_lower: I32, tick_upper: I32) {
            emit(
                PositionOpened {
                    pool_id,
                    position_id, 
                    tick_lower,
                    tick_upper                    
            }
        );
    }

    public(friend) fun emit_position_close_event(pool_id: ID, position_id: ID, tick_lower: I32, tick_upper: I32) {
            emit(
                PositionClosed {
                    pool_id,
                    position_id, 
                    tick_lower,
                    tick_upper                    
            }
        );
    }

     public(friend) fun emit_update_pool_reward_emission_event(
        pool_id: ID, 
        reward_coin_symbol: String,
        reward_coin_type: String, 
        reward_coin_decimals: u8,
        total_reward: u64, 
        ended_at_seconds: u64, 
        last_update_time: u64, 
        reward_per_seconds: u128,
        sequence_number: u128,
        ) {
            emit(
                UpdatePoolRewardEmissionEvent {
                    pool_id,
                    reward_coin_symbol,
                    reward_coin_type,
                    reward_coin_decimals,
                    total_reward,
                    ended_at_seconds,
                    last_update_time,
                    reward_per_seconds,   
                    sequence_number             
            }
        );
    }

    public(friend) fun emit_supported_version_update_event(
        old_version: u64,
        new_version: u64
    ) {
        emit(
            SupportedVersionUpdate {
                old_version,
                new_version
            }
        )
    }

    public(friend) fun emit_tick_update_event(
        pool: ID,
        index: I32,
        liquidity_gross: u128,
        liquidity_net: I128,
    ) {
        emit(
            PoolTickUpdate {
                pool,
                index,
                liquidity_gross,
                liquidity_net
            }
        )
    }

    public(friend) fun emit_reward_manager_update_event(
        manager: address,
        is_active: bool
    ) {
        emit(
            RewardsManagerUpdate {
                manager,
                is_active
            }
        )
    }

    public(friend) fun emit_protocol_fee_share_updated_event(
        pool: ID,
        previous_protocol_fee_share: u64,
        current_protocol_fee_share: u64,
        sequence_number: u128
    ){
        emit (
            ProtocolFeeShareUpdated {
                pool,
                previous_protocol_fee_share,
                current_protocol_fee_share,
                sequence_number
            }
        )
    }

    public(friend) fun emit_pool_pause_status_update_event(
        pool_id: ID,
        status: bool,
        sequence_number: u128,
    ) {
        emit(
            PoolPauseStatusUpdate {
                pool_id,
                status,
                sequence_number
            }
        )
    }

    public(friend) fun emit_observation_cardinality_updated_event(
        pool: ID,
        previous_observation_cardinality: u64,
        current_observation_cardinality: u64,
        sequence_number: u128
    ){
         emit (
            ObservationCardinalityUpdated {
                pool,
                previous_observation_cardinality,
                current_observation_cardinality,
                sequence_number
            }
        )
    }

    public(friend) fun emit_pool_manager_update_event(
        pool_id: ID,
        new_manager: address,
        sequence_number: u128
    ){
         emit (
            PoolManagerUpdate {
                pool_id,
                new_manager,
                sequence_number
            }
        )
    }

    public(friend) fun emit_pool_creation_fee_update_event(
        coin_type: String,
        previous_fee_amount: u64,
        current_fee_amount: u64
    ){
         emit (
            PoolCreationFeeUpdate {
                coin_type,
                previous_fee_amount,
                current_fee_amount
            }
        )
    }

    public(friend) fun emit_pool_creation_fee_paid_event(
        pool: ID, 
        creator: address,
        coin_type: String,
        fee_amount: u64,
        total_accrued_fee: u64
    ){
         emit (
            PoolCreationFeePaid {
                pool,
                creator,
                coin_type,
                fee_amount,
                total_accrued_fee
            }
        )
    }


    public(friend) fun emit_pool_creation_fee_claimed(
        coin_type: String,
        amount: u64,
        destination: address,
        accrued_fee_before: u64,
        accrued_fee_after: u64,
    ){
         emit (
            PoolCreationFeeClaimed {
                coin_type,
                amount,
                destination,
                accrued_fee_before,
                accrued_fee_after
            }
        )
    }

    public(friend) fun emit_reward_reserves_increased(
        pool: ID,
        reward_coin_type: String,
        amount: u64,
        reserves_before: u64,
        revers_after: u64,
    ){
         emit (
            PoolRewardReservesIncreased {
                pool,
                reward_coin_type,
                amount,
                reserves_before,
                revers_after
            }
        )
    }

    public(friend) fun emit_pool_icon_url_update_event(
        pool_id: ID,
        icon_url: String,
        sequence_number: u128
    ){
        emit(
            PoolIconUrlUpdate {
                pool_id,
                icon_url,
                sequence_number
    
            }
        )
    }
}
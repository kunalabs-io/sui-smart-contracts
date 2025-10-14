/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::position {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use std::vector;
    use sui::transfer;
    use sui::package;
    use sui::display;

    use integer_mate::i32::{I32};
    use integer_mate::i128::{Self, I128};
    use integer_library::full_math_u128;
    use integer_library::math_u128;
    use integer_library::math_u64;
    use bluefin_spot::i128H;

    use bluefin_spot::errors;
    use bluefin_spot::constants;
    use bluefin_spot::utils;

    // friend Modules
    friend bluefin_spot::pool;
    #[test_only]
    friend bluefin_spot::test_position;

    //===========================================================//
    //                          Structs                          //
    //===========================================================//

    // One time witness (OTW)
    #[allow(unused_field)]
    struct POSITION has drop {
        dummy_field: bool
    }

    struct Position has key, store {
        id: UID,
        pool_id: ID,
        lower_tick: I32,
        upper_tick: I32,
        fee_rate: u64,
        liquidity: u128,
        fee_growth_coin_a : u128, 
        fee_growth_coin_b : u128, 
        token_a_fee: u64, 
        token_b_fee: u64, 

         // fields for the NFT display
        name: String,
        coin_type_a: String,
        coin_type_b: String,
        description: String,
        image_url: String,
        position_index: u128,

        reward_infos: vector<PositionRewardInfo>
    }

    struct PositionRewardInfo has copy, drop, store {
        reward_growth_inside_last: u128,
        coins_owed_reward: u64,
    }


    //===========================================================//
    //                       Initialization                      //
    //===========================================================//

    fun init(otw: POSITION, ctx: &mut TxContext) {

        let keys = vector::empty<String>();
        vector::push_back(&mut keys, string::utf8(b"name"));
        vector::push_back(&mut keys, string::utf8(b"id"));
        vector::push_back(&mut keys, string::utf8(b"pool"));
        vector::push_back(&mut keys, string::utf8(b"coin_a"));
        vector::push_back(&mut keys, string::utf8(b"coin_b"));
        vector::push_back(&mut keys, string::utf8(b"link"));
        vector::push_back(&mut keys, string::utf8(b"image_url"));
        vector::push_back(&mut keys, string::utf8(b"description"));
        vector::push_back(&mut keys, string::utf8(b"project_url"));
        vector::push_back(&mut keys, string::utf8(b"creator"));

        let values = vector::empty<String>();
        vector::push_back(&mut values, string::utf8(b"{name}"));
        vector::push_back(&mut values, string::utf8(b"{id}"));
        vector::push_back(&mut values, string::utf8(b"{pool_id}"));
        vector::push_back(&mut values, string::utf8(b"{coin_type_a}"));
        vector::push_back(&mut values, string::utf8(b"{coin_type_b}"));
        vector::push_back(&mut values, string::utf8(b"https://trade.bluefin.io/spot-nft/id={id}"));
        vector::push_back(&mut values, string::utf8(b"{image_url}"));
        vector::push_back(&mut values, string::utf8(b"{description}"));
        vector::push_back(&mut values, string::utf8(b"https://trade.bluefin.io"));
        vector::push_back(&mut values, string::utf8(b"Bluefin"));
        
        let pub = package::claim<POSITION>(otw, ctx);
        let display = display::new_with_fields<Position>(&pub, keys, values, ctx);
        display::update_version(&mut display);

        transfer::public_transfer(pub, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));

    }


       

    //===========================================================//
    //                        Public Funcitons                   //
    //===========================================================//


    public fun lower_tick(position: &Position): I32 {
        position.lower_tick
    }

    public fun upper_tick(position: &Position): I32 {
        position.upper_tick
    }

    public fun liquidity(position: &Position): u128 {
        position.liquidity
    }

    public fun pool_id(position: &Position): ID {
        position.pool_id
    }

    public fun get_accrued_fee(position: &Position): (u64, u64){
        (position.token_a_fee, position.token_b_fee)
    }

    public fun coins_owed_reward(position: &Position, index: u64) : u64 {
        if (index >= vector::length<PositionRewardInfo>(&position.reward_infos)) {
            0
        } else {
            vector::borrow<PositionRewardInfo>(&position.reward_infos, index).coins_owed_reward
        }
    }

    public fun is_empty(position: &Position) : bool {
        let rewards_empty = true;
        let current_index = 0;
        while (current_index < vector::length<PositionRewardInfo>(&position.reward_infos)) {
            if (vector::borrow<PositionRewardInfo>(&position.reward_infos, current_index).coins_owed_reward != 0) {
                rewards_empty = false;
                break
            };
            current_index = current_index + 1;
        };
        let zero_liquidity = position.liquidity == 0;
        rewards_empty && zero_liquidity
    }

    public fun reward_infos_length(position: &Position) : u64 {
         vector::length<PositionRewardInfo>(&position.reward_infos)
    }

    //===========================================================//
    //                        Friend Funcitons                   //
    //===========================================================//


    public (friend) fun new(
        pool_id: ID, 
        pool_name: String,
        image_url: String,
        coin_type_a: String, 
        coin_type_b: String,
        position_index: u128,
        lower_tick: I32, 
        upper_tick: I32, 
        fee_rate: u64, 
        ctx: &mut TxContext): Position {

        Position {
            id: object::new(ctx), 
            pool_id,
            lower_tick, 
            upper_tick, 
            fee_rate,
            liquidity: 0,
            fee_growth_coin_a: 0, 
            fee_growth_coin_b: 0, 
            token_a_fee: 0, 
            token_b_fee: 0, 
            // fields for NFT display
            name: create_position_name(pool_name),
            image_url,
            coin_type_a,
            coin_type_b,
            description: create_position_description(pool_name),
            position_index,
            reward_infos             : vector::empty<PositionRewardInfo>()
        }
    }

    public (friend) fun del(position: Position): (ID, ID, I32, I32) {
        let position_id = object::id(&position);

        let Position {
            id, 
            pool_id,
            lower_tick, 
            upper_tick, 
            fee_rate: _, 
            liquidity: _, 
            fee_growth_coin_a: _, 
            fee_growth_coin_b: _, 
            token_a_fee: _, 
            token_b_fee: _,
            coin_type_a: _,
            coin_type_b: _,
            description: _,
            name: _,
            image_url: _,
            position_index: _,
            reward_infos: _
        } = position;

        object::delete(id);

        (position_id, pool_id, lower_tick, upper_tick)

    }

    /// Sets the fees for provided position to the provided amounts
    public (friend) fun set_fee_amounts(position: &mut Position, fee_a: u64, fee_b: u64){
        position.token_a_fee = fee_a;
        position.token_b_fee = fee_b;
    }

    public(friend) fun decrease_reward_amount(position: &mut Position, index : u64, reward_amount: u64) {
        let pos_reward_info = get_mutable_reward_info(position, index);
        pos_reward_info.coins_owed_reward = pos_reward_info.coins_owed_reward - reward_amount;
    }

    public(friend) fun update(position: &mut Position, liquidity_delta: I128, fee_growth_inside_a: u128, fee_growth_inside_b: u128, reward_growths_inside: vector<u128>){

        
        let liquidity = if (i128H::eq(liquidity_delta, i128::zero())) {
            assert!(position.liquidity > 0, errors::insufficient_liquidity());
            position.liquidity
        } else {
            utils::add_delta(position.liquidity, liquidity_delta)
        };

        let token_a_fee = full_math_u128::mul_div_floor(math_u128::wrapping_sub(fee_growth_inside_a, position.fee_growth_coin_a), position.liquidity, constants::q64());
        let token_b_fee = full_math_u128::mul_div_floor(math_u128::wrapping_sub(fee_growth_inside_b, position.fee_growth_coin_b), position.liquidity, constants::q64());

        assert!(
            token_a_fee <= (constants::max_u64() as u128) && 
            token_b_fee <= (constants::max_u64() as u128), 
            errors::invalid_fee_growth()
        );

        assert!(
            math_u64::add_check(position.token_a_fee, (token_a_fee as u64)) && 
            math_u64::add_check(position.token_b_fee, (token_b_fee as u64)), 
            errors::add_check_failed()
        );
        update_reward_infos(position, reward_growths_inside);
        position.liquidity = liquidity;
        position.fee_growth_coin_a = fee_growth_inside_a;
        position.fee_growth_coin_b = fee_growth_inside_b;
        
        position.token_a_fee = position.token_a_fee + (token_a_fee as u64);
        position.token_b_fee = position.token_b_fee + (token_b_fee as u64);

    }

    public(friend) fun add_reward_info(position: &mut Position) {
        vector::push_back<PositionRewardInfo>(&mut position.reward_infos, PositionRewardInfo {
            reward_growth_inside_last : 0, 
            coins_owed_reward         : 0,
        });            
    }


    //===========================================================//
    //                        Internal Methods                   //
    //===========================================================//
    
    fun create_position_name(pool_name: String): String {
        let name = string::utf8(b"Bluefin Position, ");
        string::append(&mut name, pool_name);
        name
    }

    fun create_position_description(pool_name: String): String {
        let description = string::utf8(b"This NFT represents a liquidity position of a Bluefin ");
        string::append(&mut description, pool_name);
        string::append(&mut description, string::utf8(b" pool. The owner of this NFT can modify or redeem the position"));
        description
    }

    fun update_reward_infos(position: &mut Position, reward_growths_inside: vector<u128>) {
        let current_index = 0;
        let pos_liquidity = position.liquidity;

        while (current_index < vector::length<u128>(&reward_growths_inside)) {
            let reward_growth_inside_val = *vector::borrow<u128>(&reward_growths_inside, current_index);
            let pos_reward_info = get_mutable_reward_info(position, current_index);
            let new_coins_owed_reward = full_math_u128::mul_div_floor(math_u128::wrapping_sub(reward_growth_inside_val, pos_reward_info.reward_growth_inside_last), pos_liquidity, constants::q64());
            assert!(new_coins_owed_reward <= (constants::max_u64() as u128) && math_u64::add_check(pos_reward_info.coins_owed_reward, (new_coins_owed_reward as u64)), errors::update_rewards_info_check_failed());
            pos_reward_info.reward_growth_inside_last = reward_growth_inside_val;
            pos_reward_info.coins_owed_reward = pos_reward_info.coins_owed_reward + (new_coins_owed_reward as u64);
            current_index = current_index + 1;
        };
    }

    fun get_mutable_reward_info(position: &mut Position, index: u64) : &mut PositionRewardInfo {
        if (index >= vector::length<PositionRewardInfo>(&position.reward_infos)) {
            add_reward_info(position);
        };
        vector::borrow_mut<PositionRewardInfo>(&mut position.reward_infos, index)
    }


    #[test_only]
    public fun open(
        pool_id: ID, 
        pool_name: String,
        image_url: String,
        coin_type_a: String, 
        coin_type_b: String,
        position_index: u128,
        lower_tick: I32, 
        upper_tick: I32, 
        fee_rate: u64, 
        ctx: &mut TxContext): Position {
            new(pool_id, pool_name, image_url, coin_type_a, coin_type_b, position_index, lower_tick, upper_tick, fee_rate, ctx)
    }

    #[test_only]
    public fun close(position: Position){
        let (_, _, _, _) = del(position);
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        let otw = POSITION { dummy_field: false };
        init(otw, ctx);
    }

}
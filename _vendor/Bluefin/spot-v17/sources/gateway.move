/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::gateway {
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::clock::{Clock};
    use sui::balance;

    // local modules 
    use bluefin_spot::config::{GlobalConfig};
    use bluefin_spot::pool::{Self, Pool};
    use bluefin_spot::utils::{Self};
    use bluefin_spot::position::{Self, Position};
    use bluefin_spot::errors;


    //===========================================================//
    //                   Public Entry Methods                    //
    //===========================================================//

    /// Creates a pool
    #[allow(unused_type_parameter, lint(public_entry))]
    public entry fun create_pool<CoinTypeA, CoinTypeB>(
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
        _: &mut TxContext
        ){
        
        abort errors::depricated()
    }

     #[allow(lint(public_entry))]
    public entry fun create_pool_v2<CoinTypeA, CoinTypeB, CoinTypeFee>(
        clock: &Clock, 
        protocol_config: &mut GlobalConfig, 
        pool_name: vector<u8>, 
        pool_icon_url: vector<u8>, 
        coin_a_symbol: vector<u8>, 
        coin_a_decimals: u8, 
        coin_a_url: vector<u8>, 
        coin_b_symbol: vector<u8>, 
        coin_b_decimals: u8, 
        coin_b_url: vector<u8>, 
        tick_spacing: u32, 
        fee_basis_points: u64, 
        current_sqrt_price: u128, 
        creation_fee: Coin<CoinTypeFee>,
        ctx: &mut TxContext
        ){
        
        pool::create_pool<CoinTypeA, CoinTypeB, CoinTypeFee>(
            clock, 
            protocol_config,
            pool_name, 
            pool_icon_url, 
            coin_a_symbol, 
            coin_a_decimals, 
            coin_a_url, 
            coin_b_symbol,
            coin_b_decimals, 
            coin_b_url, 
            tick_spacing, 
            fee_basis_points, 
            current_sqrt_price, 
            coin::into_balance(creation_fee),
            ctx
        );
    }
    
    //  Provides liquidity to the pool
    #[allow(lint(public_entry))]
    public entry fun provide_liquidity<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        coin_a_min: u64,
        coin_b_min: u64,
        liquidity: u128, 
        ctx: &mut TxContext) {

        let sender = tx_context::sender(ctx);

        let (coin_a_provided, coin_b_provided, balance_token_a, balance_token_b) = pool::add_liquidity<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            pool,
            position,
            coin::into_balance(coin_a),
            coin::into_balance(coin_b),
            liquidity,
        );

        // check slippage
        assert!(
            coin_a_provided >= coin_a_min && 
            coin_b_provided >= coin_b_min, 
            errors::slippage_exceeds(),
        );

        utils::transfer_balance(balance_token_a, sender, ctx);
        utils::transfer_balance(balance_token_b, sender, ctx);

    }

    //  Provides liquidity to the pool
    #[allow(lint(public_entry))]
    public entry fun provide_liquidity_with_fixed_amount<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        amount: u64,
        coin_a_max: u64,
        coin_b_max: u64,
        is_fixed_a: bool,
        ctx: &mut TxContext) {

        let sender = tx_context::sender(ctx);

        let (coin_a_provided, coin_b_provided, balance_token_a, balance_token_b) = pool::add_liquidity_with_fixed_amount<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config,
            pool,
            position,
            coin::into_balance(coin_a),
            coin::into_balance(coin_b),
            amount,
            is_fixed_a
        );

        // check slippage
        assert!(
            coin_a_provided <= coin_a_max && 
            coin_b_provided <= coin_b_max, 
            errors::slippage_exceeds(),
        );

        utils::transfer_balance(balance_token_a, sender, ctx);
        utils::transfer_balance(balance_token_b, sender, ctx);

    }


    //  Remove liquidity from the pool
    #[allow(lint(public_entry))]
    public entry fun remove_liquidity<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: &mut Position,
        liquidity: u128, 
        min_coins_a: u64,
        min_coins_b: u64,
        transfer_coins_to: address,
        ctx: &mut TxContext) {


        let (amount_a, amount_b, balance_token_a, balance_token_b) = pool::remove_liquidity<CoinTypeA, CoinTypeB>(
            protocol_config,
            pool,
            position,
            liquidity,
            clock,
        );

        assert!(amount_a >= min_coins_a && amount_b >= min_coins_b, errors::slippage_exceeds());

        utils::transfer_balance(balance_token_a, transfer_coins_to, ctx);
        utils::transfer_balance(balance_token_b, transfer_coins_to, ctx);

    }

    //  Closes the position and removes any residual liquidity and transfers to the provided address
    #[allow(lint(public_entry))]
    public entry fun close_position<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        position: Position,
        transfer_coins_to: address,
        ctx: &mut TxContext) {
        
        let liquidity = position::liquidity(&position);
        let (residual_a, residual_b) = if (liquidity > 0 ) {
            let (_, _, balance_a, balance_b) = pool::remove_liquidity(
                protocol_config,
                pool,
                &mut position,
                liquidity,
                clock,
            );
            (balance_a, balance_b)
        } else {
            (balance::zero<CoinTypeA>(), balance::zero<CoinTypeB>())
        };

        // collect fee if there is any
        let (_, _, fee_a, fee_b) = pool::collect_fee(
            clock,
            protocol_config,
            pool, 
            &mut position
        );

        balance::join<CoinTypeA>(&mut residual_a,fee_a);
        balance::join<CoinTypeB>(&mut residual_b, fee_b);

        pool::close_position_v2(
            clock, 
            protocol_config, 
            pool, 
            position
        );

        utils::transfer_balance(residual_a, transfer_coins_to, ctx);
        utils::transfer_balance(residual_b, transfer_coins_to, ctx);

    }


    /// Performs swap on the pool
    #[allow(lint(public_entry))]
    public entry fun swap_assets<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        a2b: bool,
        by_amount_in: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_max_limit: u128,
        ctx: &mut TxContext) {

        let (balance_coin_a, balance_coin_b) = pool::swap<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config, 
            pool, 
            coin::into_balance(coin_a), 
            coin::into_balance(coin_b), 
            a2b, 
            by_amount_in, 
            amount, 
            amount_limit, 
            sqrt_price_max_limit
        );

        utils::transfer_balance(balance_coin_a, tx_context::sender(ctx), ctx);
        utils::transfer_balance(balance_coin_b, tx_context::sender(ctx), ctx);
        
    }

    /// Sample flash swap call
    #[allow(lint(public_entry))]
    public entry fun flash_swap<CoinTypeA,CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        a2b: bool,
        by_amount_in: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_max_limit: u128,
        ctx: &mut TxContext
        ) {

        let (receive_coin_a, receive_coin_b, receipt) = pool::flash_swap<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config, 
            pool, 
            a2b, 
            by_amount_in, 
            amount, 
            sqrt_price_max_limit, 
        );

        let (in_amount, out_amount) = (
            pool::swap_pay_amount(&receipt),
            if (a2b) balance::value(&receive_coin_b) else balance::value(&receive_coin_a)
        );


        if (by_amount_in) {
            assert!(out_amount >= amount_limit, errors::slippage_exceeds());
        } else {
            assert!(in_amount <= amount_limit, errors::slippage_exceeds());
        };

        let (pay_coin_a, pay_coin_b) = if (a2b) {
            (coin::into_balance(coin::split(&mut coin_a, in_amount, ctx)), balance::zero<CoinTypeB>())
        } else {
            (balance::zero<CoinTypeA>(), coin::into_balance(coin::split(&mut coin_b, in_amount, ctx)))
        };

        coin::join(&mut coin_a, coin::from_balance(receive_coin_a, ctx));
        coin::join(&mut coin_b, coin::from_balance(receive_coin_b, ctx));

        // replay the flash swap
        pool::repay_flash_swap<CoinTypeA, CoinTypeB>(
            protocol_config,
            pool,
            pay_coin_a,
            pay_coin_b,
            receipt
        );

        // TODO do something with the coins. We are sending it to recepient
        utils::transfer_coin(coin_a, tx_context::sender(ctx));
        utils::transfer_coin(coin_b, tx_context::sender(ctx));

    }

    /// Allows user to collect the fees accrued on their position
    #[allow(lint(public_entry))]
    public entry fun collect_fee<CoinTypeA,CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        position: &mut Position,
        ctx: &mut TxContext
     ){

        let sender = tx_context::sender(ctx);

        let (_, _, balance_a, balance_b) = pool::collect_fee(clock, protocol_config, pool, position);

        utils::transfer_balance(balance_a, sender, ctx);
        utils::transfer_balance(balance_b, sender, ctx);


     }

     /// Allows user to collect the rewards accrued on their position
     /// Reverts if the reward accrued amount is zero
     #[allow(lint(public_entry))]
     public entry fun collect_reward<CoinTypeA, CoinTypeB, RewardCoinType>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        position: &mut Position,
        ctx: &mut TxContext
        ){

        let sender = tx_context::sender(ctx);

        let reward_balance = pool::collect_reward<CoinTypeA, CoinTypeB, RewardCoinType>(clock, protocol_config, pool, position);

        assert!(balance::value(&reward_balance) > 0, errors::can_not_claim_zero_reward());

        utils::transfer_balance(reward_balance, sender, ctx);
        
    }

    //===========================================================//
    //                        Public Methods                     //
    //===========================================================//

    /// Function to perform swap in a route
    #[allow(lint(public_entry))]
    public fun route_swap<CoinTypeA, CoinTypeB>(
        clock: &Clock,
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        coin_a: Coin<CoinTypeA>,
        coin_b: Coin<CoinTypeB>,
        a2b: bool,
        by_amount_in: bool,
        middle_step: bool,
        amount: u64,
        amount_limit: u64,
        sqrt_price_max_limit: u128,
        ctx: &mut TxContext
    ): (Coin<CoinTypeA>, Coin<CoinTypeB>){

        if (by_amount_in && middle_step) {

            amount = if (a2b) {
                coin::value(&coin_a)
            } else {
                coin::value(&coin_b)
            };
        };

        let (receive_coin_a, receive_coin_b, receipt) = pool::flash_swap<CoinTypeA, CoinTypeB>(
            clock,
            protocol_config, 
            pool, 
            a2b, 
            by_amount_in, 
            amount, 
            sqrt_price_max_limit,
        );

        let (in_amount, out_amount) = (
            pool::swap_pay_amount(&receipt),
            if (a2b) balance::value(&receive_coin_b) else balance::value(&receive_coin_a)
        );

        // TODO update error code
        if (by_amount_in) {
            assert!(out_amount >= amount_limit, errors::slippage_exceeds());
        } else {
            assert!(in_amount <= amount_limit, errors::slippage_exceeds());
        };

        let (pay_coin_a, pay_coin_b) = if (a2b) {
            (coin::into_balance(coin::split(&mut coin_a, in_amount, ctx)), balance::zero<CoinTypeB>())
        } else {
            (balance::zero<CoinTypeA>(), coin::into_balance(coin::split(&mut coin_b, in_amount, ctx)))
        };

        coin::join(&mut coin_a, coin::from_balance(receive_coin_a, ctx));
        coin::join(&mut coin_b, coin::from_balance(receive_coin_b, ctx));

        // replay the flash swap
        pool::repay_flash_swap<CoinTypeA, CoinTypeB>(
            protocol_config,
            pool,
            pay_coin_a,
            pay_coin_b,
            receipt
        );

        (coin_a, coin_b)

    }
}
// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_leverage::bluefin_spot;

use access_management::access::ActionRequest;
use bluefin_spot::config as bluefin_config;
use bluefin_spot::pool as bluefin_pool;
use bluefin_spot::position::Position as BluefinPosition;
use integer_mate::i32::{Self, I32};
use kai_leverage::debt_info::DebtInfo;
use kai_leverage::position_core_clmm::{
    Self as core,
    PositionConfig,
    CreatePositionTicket,
    PositionCap,
    Position,
    DeleverageTicket,
    RebalanceReceipt,
    ReductionRepaymentTicket
};
use kai_leverage::position_model_clmm::PositionModel;
use kai_leverage::pyth::PythPriceInfo;
use kai_leverage::supply_pool::SupplyPool;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::sui::SUI;

/* ================= errors ================= */

/// Invalid balance value passed in for liquidity deposit.
const EInvalidBalanceValue: u64 = 0;

/* ================= util ================= */

public fun slippage_tolerance_assertion<X, Y>(
    pool: &bluefin_pool::Pool<X, Y>,
    p0_desired_x128: u256,
    max_slippage_bps: u16,
) {
    core::slippage_tolerance_assertion!(pool, p0_desired_x128, max_slippage_bps);
}

public fun calc_deposit_amounts_by_liquidity<X, Y>(
    pool: &bluefin_pool::Pool<X, Y>,
    tick_a: I32,
    tick_b: I32,
    delta_l: u128,
): (u64, u64) {
    let current_tick = pool.current_tick_index();
    let sqrt_p0_x64 = pool.current_sqrt_price();
    bluefin_pool::get_amount_by_liquidity(
        tick_a,
        tick_b,
        current_tick,
        sqrt_p0_x64,
        delta_l,
        true,
    )
}

public fun position_tick_range(position: &BluefinPosition): (I32, I32) {
    (position.lower_tick(), position.upper_tick())
}

public fun remove_liquidity<X, Y>(
    config: &bluefin_config::GlobalConfig,
    pool: &mut bluefin_pool::Pool<X, Y>,
    lp_position: &mut BluefinPosition,
    delta_l: u128,
    clock: &Clock,
): (Balance<X>, Balance<Y>) {
    if (delta_l > 0) {
        let (_, _, delta_x, delta_y) = bluefin_pool::remove_liquidity(
            config,
            pool,
            lp_position,
            delta_l,
            clock,
        );
        (delta_x, delta_y)
    } else {
        (balance::zero(), balance::zero())
    }
}

/* ================= position creation ================= */

public fun create_position_ticket<X, Y>(
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    config: &mut PositionConfig,
    tick_a: I32,
    tick_b: I32,
    principal_x: Balance<X>,
    principal_y: Balance<Y>,
    delta_l: u128,
    price_info: &PythPriceInfo,
    ctx: &mut TxContext,
): CreatePositionTicket<X, Y, I32> {
    core::create_position_ticket!(
        bluefin_pool,
        config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        price_info,
        ctx,
    )
}

public fun borrow_for_position_x<X, Y, SX>(
    ticket: &mut CreatePositionTicket<X, Y, I32>,
    config: &PositionConfig,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
) {
    core::borrow_for_position_x!(ticket, config, supply_pool, clock)
}

public fun borrow_for_position_y<X, Y, SY>(
    ticket: &mut CreatePositionTicket<X, Y, I32>,
    config: &PositionConfig,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
) {
    core::borrow_for_position_y!(ticket, config, supply_pool, clock)
}

public fun create_position<X, Y>(
    config: &PositionConfig,
    ticket: CreatePositionTicket<X, Y, I32>,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    creation_fee: Balance<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
): PositionCap {
    core::create_position!(
        config,
        ticket,
        bluefin_pool,
        creation_fee,
        ctx,
        |pool, tick_a, tick_b, delta_l, balance_x0, balance_y0| {
            let mut lp_position = bluefin_pool::open_position(
                bluefin_global_config,
                pool,
                i32::as_u32(tick_a),
                i32::as_u32(tick_b),
                ctx,
            );
            let (_, _, residual_x, residual_y) = bluefin_pool::add_liquidity(
                clock,
                bluefin_global_config,
                pool,
                &mut lp_position,
                balance_x0,
                balance_y0,
                delta_l,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();

            lp_position
        },
    )
}

/* ================= deleverage and liquidation ================= */

public fun create_deleverage_ticket<X, Y>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    max_delta_l: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): (DeleverageTicket, ActionRequest) {
    core::create_deleverage_ticket!(
        position,
        config,
        price_info,
        debt_info,
        bluefin_pool,
        max_delta_l,
        ctx,
        |
            pool: &mut bluefin_pool::Pool<X, Y>,
            lp_position: &mut BluefinPosition,
            delta_l: u128,
        | remove_liquidity(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun create_deleverage_ticket_for_liquidation<X, Y>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): DeleverageTicket {
    core::create_deleverage_ticket_for_liquidation!(
        position,
        config,
        price_info,
        debt_info,
        bluefin_pool,
        |
            pool: &mut bluefin_pool::Pool<X, Y>,
            lp_position: &mut BluefinPosition,
            delta_l: u128,
        | remove_liquidity(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun deleverage<X, Y, SX, SY>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    max_delta_l: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): ActionRequest {
    core::deleverage!(
        position,
        config,
        price_info,
        supply_pool_x,
        supply_pool_y,
        bluefin_pool,
        max_delta_l,
        clock,
        ctx,
        |
            pool: &mut bluefin_pool::Pool<X, Y>,
            lp_position: &mut BluefinPosition,
            delta_l: u128,
        | remove_liquidity(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun deleverage_for_liquidation<X, Y, SX, SY>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
) {
    core::deleverage_for_liquidation!(
        position,
        config,
        price_info,
        supply_pool_x,
        supply_pool_y,
        bluefin_pool,
        clock,
        |
            pool: &mut bluefin_pool::Pool<X, Y>,
            lp_position: &mut BluefinPosition,
            delta_l: u128,
        | remove_liquidity(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun liquidate_col_x<X, Y, SY>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<Y>,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
): Balance<X> {
    core::liquidate_col_x!(position, config, price_info, debt_info, repayment, supply_pool, clock)
}

public fun liquidate_col_y<X, Y, SX>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<X>,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
): Balance<Y> {
    core::liquidate_col_y!(position, config, price_info, debt_info, repayment, supply_pool, clock)
}

public fun reduce<X, Y, SX, SY>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    factor_x64: u128,
    clock: &Clock,
): (Balance<X>, Balance<Y>, ReductionRepaymentTicket<SX, SY>) {
    core::reduce!(
        position,
        config,
        cap,
        price_info,
        supply_pool_x,
        supply_pool_y,
        bluefin_pool,
        factor_x64,
        clock,
        |
            pool: &mut bluefin_pool::Pool<X, Y>,
            lp_position: &mut BluefinPosition,
            delta_l: u128,
        | remove_liquidity(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun add_liquidity<X, Y>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_config: &bluefin_config::GlobalConfig,
    delta_l: u128,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
    clock: &Clock,
) {
    let (delta_x, delta_y) = calc_deposit_amounts_by_liquidity(
        bluefin_pool,
        position.lp_position().lower_tick(),
        position.lp_position().upper_tick(),
        delta_l,
    );
    assert!(balance_x.value() == delta_x, EInvalidBalanceValue);
    assert!(balance_y.value() == delta_y, EInvalidBalanceValue);

    core::add_liquidity!(
        position,
        config,
        cap,
        price_info,
        debt_info,
        bluefin_pool,
        |pool: &mut bluefin_pool::Pool<X, Y>, lp_position: &mut BluefinPosition| {
            let (delta_x, delta_y, residual_x, residual_y) = bluefin_pool::add_liquidity(
                clock,
                bluefin_config,
                pool,
                lp_position,
                balance_x,
                balance_y,
                delta_l,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();

            (delta_l, delta_x, delta_y)
        },
    )
}

public fun repay_debt_x<X, Y, SX>(
    position: &mut Position<X, Y, BluefinPosition>,
    cap: &PositionCap,
    balance: &mut Balance<X>,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
) {
    core::repay_debt_x(position, cap, balance, supply_pool, clock)
}

public fun repay_debt_y<X, Y, SY>(
    position: &mut Position<X, Y, BluefinPosition>,
    cap: &PositionCap,
    balance: &mut Balance<Y>,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
) {
    core::repay_debt_y(position, cap, balance, supply_pool, clock)
}

public fun owner_collect_fee<X, Y>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): (Balance<X>, Balance<Y>) {
    core::owner_collect_fee!(
        position,
        config,
        cap,
        bluefin_pool,
        |pool: &mut bluefin_pool::Pool<X, Y>, lp_position: &mut BluefinPosition| {
            let (_, _, balance_x, balance_y) = bluefin_pool::collect_fee(
                clock,
                bluefin_config,
                pool,
                lp_position,
            );
            (balance_x, balance_y)
        },
    )
}

public fun owner_collect_reward<X, Y, T>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): Balance<T> {
    core::owner_collect_reward!(
        position,
        config,
        cap,
        bluefin_pool,
        |
            pool: &mut bluefin_pool::Pool<X, Y>,
            lp_position: &mut BluefinPosition,
        | bluefin_pool::collect_reward(
            clock,
            bluefin_config,
            pool,
            lp_position,
        ),
    )
}

public fun owner_take_stashed_rewards<X, Y, T>(
    position: &mut Position<X, Y, BluefinPosition>,
    cap: &PositionCap,
    amount: Option<u64>,
): Balance<T> {
    core::owner_take_stashed_rewards(position, cap, amount)
}

public fun delete_position<X, Y>(
    position: Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    cap: PositionCap,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    core::delete_position!(
        position,
        config,
        cap,
        |lp_position| bluefin_pool::close_position_v2(
            clock,
            bluefin_config,
            bluefin_pool,
            lp_position,
        ),
        ctx,
    )
}

/* ================= rebalance ================= */

#[allow(unused_mut_ref)]
public fun rebalance_collect_fee<X, Y>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    receipt: &mut RebalanceReceipt,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): (Balance<X>, Balance<Y>) {
    core::rebalance_collect_fee!(
        position,
        config,
        receipt,
        bluefin_pool,
        |pool: &mut bluefin_pool::Pool<X, Y>, lp_position: &mut BluefinPosition| {
            let (_, _, balance_x, balance_y) = bluefin_pool::collect_fee(
                clock,
                bluefin_config,
                pool,
                lp_position,
            );
            (balance_x, balance_y)
        },
    )
}

#[allow(unused_mut_ref)]
public fun rebalance_collect_reward<X, Y, T>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    receipt: &mut RebalanceReceipt,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): Balance<T> {
    core::rebalance_collect_reward!(
        position,
        config,
        receipt,
        bluefin_pool,
        |
            pool: &mut bluefin_pool::Pool<X, Y>,
            lp_position: &mut BluefinPosition,
        | bluefin_pool::collect_reward(
            clock,
            bluefin_config,
            pool,
            lp_position,
        ),
    )
}

public fun rebalance_add_liquidity<X, Y>(
    position: &mut Position<X, Y, BluefinPosition>,
    config: &mut PositionConfig,
    receipt: &mut RebalanceReceipt,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    bluefin_pool: &mut bluefin_pool::Pool<X, Y>,
    bluefin_config: &bluefin_config::GlobalConfig,
    delta_l: u128,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
    clock: &Clock,
) {
    let (delta_x, delta_y) = calc_deposit_amounts_by_liquidity(
        bluefin_pool,
        position.lp_position().lower_tick(),
        position.lp_position().upper_tick(),
        delta_l,
    );
    assert!(balance_x.value() == delta_x, EInvalidBalanceValue);
    assert!(balance_y.value() == delta_y, EInvalidBalanceValue);

    core::rebalance_add_liquidity!(
        position,
        config,
        receipt,
        price_info,
        debt_info,
        bluefin_pool,
        |pool: &mut bluefin_pool::Pool<X, Y>, lp_position: &mut BluefinPosition| {
            let (delta_x, delta_y, residual_x, residual_y) = bluefin_pool::add_liquidity(
                clock,
                bluefin_config,
                pool,
                lp_position,
                balance_x,
                balance_y,
                delta_l,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();

            (delta_l, delta_x, delta_y)
        },
    )
}

/* ================= read ================= */

public fun position_model<X, Y>(
    position: &Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    debt_info: &DebtInfo,
): PositionModel {
    core::validated_model_for_position!(position, config, debt_info)
}

public fun calc_liquidate_col_x<X, Y>(
    position: &Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_y: u64,
): (u64, u64) {
    core::calc_liquidate_col_x!(position, config, price_info, debt_info, max_repayment_amt_y)
}

public fun calc_liquidate_col_y<X, Y>(
    position: &Position<X, Y, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_x: u64,
): (u64, u64) {
    core::calc_liquidate_col_y!(position, config, price_info, debt_info, max_repayment_amt_x)
}

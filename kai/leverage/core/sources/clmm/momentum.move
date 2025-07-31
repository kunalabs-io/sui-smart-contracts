// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_leverage::momentum;

use access_management::access::ActionRequest;
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
use mmt_v3::i32::I32;
use mmt_v3::liquidity as mmt_liquidity;
use mmt_v3::liquidity_math as mmt_liquidity_math;
use mmt_v3::pool as mmt_pool;
use mmt_v3::position::Position as MomentumPosition;
use mmt_v3::tick_math as mmt_tick_math;
use mmt_v3::version::Version as MomentumVersion;
use mmt_v3::collect as mmt_collect;
use sui::coin;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::sui::SUI;

/* ================= errors ================= */

/// Invalid balance value passed in for liquidity deposit.
const EInvalidBalanceValue: u64 = 0;

/* ================= util ================= */

public fun slippage_tolerance_assertion<X, Y>(
    pool: &mmt_pool::Pool<X, Y>,
    p0_desired_x128: u256,
    max_slippage_bps: u16,
) {
    core::slippage_tolerance_assertion!(pool, p0_desired_x128, max_slippage_bps);
}

public fun calc_deposit_amounts_by_liquidity<X, Y>(
    pool: &mmt_pool::Pool<X, Y>,
    tick_a: I32,
    tick_b: I32,
    delta_l: u128,
): (u64, u64) {
    let sqrt_p0_x64 = pool.sqrt_price();
    let sqrt_pa_x64 = mmt_tick_math::get_sqrt_price_at_tick(tick_a);
    let sqrt_pb_x64 = mmt_tick_math::get_sqrt_price_at_tick(tick_b);
    mmt_liquidity_math::get_amounts_for_liquidity(
        sqrt_p0_x64,
        sqrt_pa_x64,
        sqrt_pb_x64,
        delta_l,
        true,
    )
}

public fun position_tick_range(position: &MomentumPosition): (I32, I32) {
    (position.tick_lower_index(), position.tick_upper_index())
}

public fun remove_liquidity<X, Y>(
    pool: &mut mmt_pool::Pool<X, Y>,
    position: &mut MomentumPosition,
    version: &MomentumVersion,
    delta_l: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): (Balance<X>, Balance<Y>) {
    if (delta_l > 0) {
        let (coin_x, coin_y) = mmt_liquidity::remove_liquidity(
            pool,
            position,
            delta_l,
            0,
            0,
            clock,
            version,
            ctx,
        );
        (coin_x.into_balance(), coin_y.into_balance())
    } else {
        (balance::zero(), balance::zero())
    }
}

/* ================= position creation ================= */

public fun create_position_ticket<X, Y>(
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
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
        momentum_pool,
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
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    creation_fee: Balance<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
): PositionCap {
    core::create_position!(
        config,
        ticket,
        momentum_pool,
        creation_fee,
        ctx,
        |pool, tick_a, tick_b, _, balance_x0, balance_y0| {
            let mut lp_position = mmt_liquidity::open_position(
                pool,
                tick_a,
                tick_b,
                momentum_version,
                ctx,
            );
            let (residual_x, residual_y) = mmt_liquidity::add_liquidity(
                pool,
                &mut lp_position,
                coin::from_balance(balance_x0, ctx),
                coin::from_balance(balance_y0, ctx),
                0,
                0,
                clock,
                momentum_version,
                ctx,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();

            lp_position
        },
    )
}

/* ================= deleverage and liquidation ================= */

public fun create_deleverage_ticket<X, Y>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    max_delta_l: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): (DeleverageTicket, ActionRequest) {
    core::create_deleverage_ticket!(
        position,
        config,
        price_info,
        debt_info,
        momentum_pool,
        max_delta_l,
        ctx,
        |
            pool: &mut mmt_pool::Pool<X, Y>,
            lp_position: &mut MomentumPosition,
            delta_l: u128,
        | remove_liquidity(pool, lp_position, momentum_version, delta_l, clock, ctx),
    )
}

public fun create_deleverage_ticket_for_liquidation<X, Y>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    clock: &Clock,
    ctx: &mut TxContext,
): DeleverageTicket {
    core::create_deleverage_ticket_for_liquidation!(
        position,
        config,
        price_info,
        debt_info,
        momentum_pool,
        |
            pool: &mut mmt_pool::Pool<X, Y>,
            lp_position: &mut MomentumPosition,
            delta_l: u128,
        | remove_liquidity(pool, lp_position, momentum_version, delta_l, clock, ctx),
    )
}

public fun deleverage<X, Y, SX, SY>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
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
        momentum_pool,
        max_delta_l,
        clock,
        ctx,
        |
            pool: &mut mmt_pool::Pool<X, Y>,
            lp_position: &mut MomentumPosition,
            delta_l: u128,
        | remove_liquidity(pool, lp_position, momentum_version, delta_l, clock, ctx),
    )
}

public fun deleverage_for_liquidation<X, Y, SX, SY>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    core::deleverage_for_liquidation!(
        position,
        config,
        price_info,
        supply_pool_x,
        supply_pool_y,
        momentum_pool,
        clock,
        |
            pool: &mut mmt_pool::Pool<X, Y>,
            lp_position: &mut MomentumPosition,
            delta_l: u128,
        | remove_liquidity(pool, lp_position, momentum_version, delta_l, clock, ctx),
    )
}

public fun liquidate_col_x<X, Y, SY>(
    position: &mut Position<X, Y, MomentumPosition>,
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
    position: &mut Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<X>,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
): Balance<Y> {
    core::liquidate_col_y!(position, config, price_info, debt_info, repayment, supply_pool, clock)
}

public fun repay_bad_debt_x<X, Y, SX>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    supply_pool: &mut SupplyPool<X, SX>,
    repayment: &mut Balance<X>,
    clock: &Clock,
    ctx: &mut TxContext,
): ActionRequest {
    core::repay_bad_debt!(
        position,
        config,
        price_info,
        debt_info,
        supply_pool,
        repayment,
        clock,
        ctx,
    )
}

public fun repay_bad_debt_y<X, Y, SY>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    supply_pool: &mut SupplyPool<Y, SY>,
    repayment: &mut Balance<Y>,
    clock: &Clock,
    ctx: &mut TxContext,
): ActionRequest {
    core::repay_bad_debt!(
        position,
        config,
        price_info,
        debt_info,
        supply_pool,
        repayment,
        clock,
        ctx,
    )
}

public fun reduce<X, Y, SX, SY>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    factor_x64: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): (Balance<X>, Balance<Y>, ReductionRepaymentTicket<SX, SY>) {
    core::reduce!(
        position,
        config,
        cap,
        price_info,
        supply_pool_x,
        supply_pool_y,
        momentum_pool,
        factor_x64,
        clock,
        |
            pool: &mut mmt_pool::Pool<X, Y>,
            lp_position: &mut MomentumPosition,
            delta_l: u128,
        | remove_liquidity(pool, lp_position, momentum_version, delta_l, clock, ctx),
    )
}

public fun add_liquidity<X, Y>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    delta_l: u128,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let (delta_x, delta_y) = calc_deposit_amounts_by_liquidity(
        momentum_pool,
        position.lp_position().tick_lower_index(),
        position.lp_position().tick_upper_index(),
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
        momentum_pool,
        |pool: &mut mmt_pool::Pool<X, Y>, lp_position: &mut MomentumPosition| {
            let (residual_x, residual_y) = mmt_liquidity::add_liquidity(
                pool,
                lp_position,
                coin::from_balance(balance_x, ctx),
                coin::from_balance(balance_y, ctx),
                0,
                0,
                clock,
                momentum_version,
                ctx,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();

            (delta_l, delta_x, delta_y)
        },
    )
}

public fun repay_debt_x<X, Y, SX>(
    position: &mut Position<X, Y, MomentumPosition>,
    cap: &PositionCap,
    balance: &mut Balance<X>,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
) {
    core::repay_debt_x(position, cap, balance, supply_pool, clock)
}

public fun repay_debt_y<X, Y, SY>(
    position: &mut Position<X, Y, MomentumPosition>,
    cap: &PositionCap,
    balance: &mut Balance<Y>,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
) {
    core::repay_debt_y(position, cap, balance, supply_pool, clock)
}

public fun owner_collect_fee<X, Y>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    clock: &Clock,
    ctx: &mut TxContext,
): (Balance<X>, Balance<Y>) {
    core::owner_collect_fee!(
        position,
        config,
        cap,
        momentum_pool,
        |pool: &mut mmt_pool::Pool<X, Y>, lp_position: &mut MomentumPosition| {
            let (coin_x, coin_y) = mmt_collect::fee(
                pool,
                lp_position,
                clock,
                momentum_version,
                ctx,
            );
            (coin_x.into_balance(), coin_y.into_balance())
        },
    )
}

public fun owner_collect_reward<X, Y, T>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    clock: &Clock,
    ctx: &mut TxContext,
): Balance<T> {
    core::owner_collect_reward!(
        position,
        config,
        cap,
        momentum_pool,
        |
            pool: &mut mmt_pool::Pool<X, Y>,
            lp_position: &mut MomentumPosition,
        | mmt_collect::reward(
            pool,
            lp_position,
            clock,
            momentum_version,
            ctx,
        ).into_balance(),
    )
}

public fun owner_take_stashed_rewards<X, Y, T>(
    position: &mut Position<X, Y, MomentumPosition>,
    cap: &PositionCap,
    amount: Option<u64>,
): Balance<T> {
    core::owner_take_stashed_rewards(position, cap, amount)
}

public fun delete_position<X, Y>(
    position: Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    cap: PositionCap,
    momentum_version: &MomentumVersion,
    ctx: &mut TxContext,
) {
    core::delete_position!(
        position,
        config,
        cap,
        |lp_position| mmt_liquidity::close_position(
            lp_position,
            momentum_version,
            ctx,
        ),
        ctx,
    )
}

/* ================= rebalance ================= */

#[allow(unused_mut_ref)]
public fun rebalance_collect_fee<X, Y>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    receipt: &mut RebalanceReceipt,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    clock: &Clock,
    ctx: &mut TxContext,
): (Balance<X>, Balance<Y>) {
    core::rebalance_collect_fee!(
        position,
        config,
        receipt,
        momentum_pool,
        |pool: &mut mmt_pool::Pool<X, Y>, lp_position: &mut MomentumPosition| {
            let (coin_x, coin_y) = mmt_collect::fee(
                pool,
                lp_position,
                clock,
                momentum_version,
                ctx,
            );
            (coin_x.into_balance(), coin_y.into_balance())
        },
    )
}

#[allow(unused_mut_ref)]
public fun rebalance_collect_reward<X, Y, T>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    receipt: &mut RebalanceReceipt,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    clock: &Clock,
    ctx: &mut TxContext,
): Balance<T> {
    core::rebalance_collect_reward!(
        position,
        config,
        receipt,
        momentum_pool,
        |
            pool: &mut mmt_pool::Pool<X, Y>,
            lp_position: &mut MomentumPosition,
        | mmt_collect::reward(
            pool,
            lp_position,
            clock,
            momentum_version,
            ctx,
        ).into_balance(),
    )
}

public fun rebalance_add_liquidity<X, Y>(
    position: &mut Position<X, Y, MomentumPosition>,
    config: &mut PositionConfig,
    receipt: &mut RebalanceReceipt,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    momentum_pool: &mut mmt_pool::Pool<X, Y>,
    momentum_version: &MomentumVersion,
    delta_l: u128,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let (delta_x, delta_y) = calc_deposit_amounts_by_liquidity(
        momentum_pool,
        position.lp_position().tick_lower_index(),
        position.lp_position().tick_upper_index(),
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
        momentum_pool,
        |pool: &mut mmt_pool::Pool<X, Y>, lp_position: &mut MomentumPosition| {
            let (residual_x, residual_y) = mmt_liquidity::add_liquidity(
                pool,
                lp_position,
                coin::from_balance(balance_x, ctx),
                coin::from_balance(balance_y, ctx),
                0,
                0,
                clock,
                momentum_version,
                ctx,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();

            (delta_l, delta_x, delta_y)
        },
    )
}

/* ================= read ================= */

public fun position_model<X, Y>(
    position: &Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    debt_info: &DebtInfo,
): PositionModel {
    core::validated_model_for_position!(position, config, debt_info)
}

public fun calc_liquidate_col_x<X, Y>(
    position: &Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_y: u64,
): (u64, u64) {
    core::calc_liquidate_col_x!(position, config, price_info, debt_info, max_repayment_amt_y)
}

public fun calc_liquidate_col_y<X, Y>(
    position: &Position<X, Y, MomentumPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_x: u64,
): (u64, u64) {
    core::calc_liquidate_col_y!(position, config, price_info, debt_info, max_repayment_amt_x)
}

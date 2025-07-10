// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_leverage::cetus;

use access_management::access::{Self, ActionRequest};
use cetus_clmm::config as cetus_config;
use cetus_clmm::pool as cetus_pool;
use cetus_clmm::position::Position as CetusPosition;
use cetus_clmm::rewarder::RewarderGlobalVault;
use integer_mate::i32::{Self, I32};
use kai_leverage::balance_bag::BalanceBag;
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

/* ================= access ================= */

public struct AHandleExploitedPosition() has drop;

/* ================= util ================= */

public fun slippage_tolerance_assertion<X, Y>(
    pool: &cetus_pool::Pool<X, Y>,
    p0_desired_x128: u256,
    max_slippage_bps: u16,
) {
    core::slippage_tolerance_assertion!(pool, p0_desired_x128, max_slippage_bps);
}

public fun calc_deposit_amounts_by_liquidity<X, Y>(
    pool: &cetus_pool::Pool<X, Y>,
    tick_a: I32,
    tick_b: I32,
    delta_l: u128,
): (u64, u64) {
    let current_tick = pool.current_tick_index();
    let sqrt_p0_x64 = pool.current_sqrt_price();
    cetus_pool::get_amount_by_liquidity(
        tick_a,
        tick_b,
        current_tick,
        sqrt_p0_x64,
        delta_l,
        true,
    )
}

public fun remove_liquidity<X, Y>(
    config: &cetus_config::GlobalConfig,
    pool: &mut cetus_pool::Pool<X, Y>,
    lp_position: &mut CetusPosition,
    delta_l: u128,
    clock: &Clock,
): (Balance<X>, Balance<Y>) {
    if (delta_l > 0) {
        cetus_pool::remove_liquidity(config, pool, lp_position, delta_l, clock)
    } else {
        (balance::zero(), balance::zero())
    }
}

/* ================= position creation ================= */

public fun create_position_ticket<X, Y>(
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
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
        cetus_pool,
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
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_global_config: &cetus_config::GlobalConfig,
    creation_fee: Balance<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
): PositionCap {
    core::create_position!(
        config,
        ticket,
        cetus_pool,
        creation_fee,
        ctx,
        |pool, tick_a, tick_b, delta_l, balance_x0, balance_y0| {
            let mut lp_position = cetus_pool::open_position(
                cetus_global_config,
                pool,
                i32::as_u32(tick_a),
                i32::as_u32(tick_b),
                ctx,
            );
            let receipt = cetus_pool::add_liquidity(
                cetus_global_config,
                pool,
                &mut lp_position,
                delta_l,
                clock,
            );
            cetus_pool::repay_add_liquidity(
                cetus_global_config,
                pool,
                balance_x0,
                balance_y0,
                receipt,
            );

            lp_position
        },
    )
}

/* ================= deleverage and liquidation ================= */

public fun create_deleverage_ticket<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_global_config: &cetus_config::GlobalConfig,
    max_delta_l: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): (DeleverageTicket, ActionRequest) {
    core::create_deleverage_ticket!(
        position,
        config,
        price_info,
        debt_info,
        cetus_pool,
        max_delta_l,
        ctx,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
            delta_l: u128,
        | remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun create_deleverage_ticket_for_liquidation<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_global_config: &cetus_config::GlobalConfig,
    clock: &Clock,
): DeleverageTicket {
    core::create_deleverage_ticket_for_liquidation!(
        position,
        config,
        price_info,
        debt_info,
        cetus_pool,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
            delta_l: u128,
        | remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun deleverage<X, Y, SX, SY>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_global_config: &cetus_config::GlobalConfig,
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
        cetus_pool,
        max_delta_l,
        clock,
        ctx,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
            delta_l: u128,
        | remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun deleverage_for_liquidation<X, Y, SX, SY>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_global_config: &cetus_config::GlobalConfig,
    clock: &Clock,
) {
    core::deleverage_for_liquidation!(
        position,
        config,
        price_info,
        supply_pool_x,
        supply_pool_y,
        cetus_pool,
        clock,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
            delta_l: u128,
        | remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun liquidate_col_x<X, Y, SY>(
    position: &mut Position<X, Y, CetusPosition>,
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
    position: &mut Position<X, Y, CetusPosition>,
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
    position: &mut Position<X, Y, CetusPosition>,
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
    position: &mut Position<X, Y, CetusPosition>,
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
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_global_config: &cetus_config::GlobalConfig,
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
        cetus_pool,
        factor_x64,
        clock,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
            delta_l: u128,
        | remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock),
    )
}

public fun add_liquidity<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
    delta_l: u128,
    clock: &Clock,
): cetus_pool::AddLiquidityReceipt<X, Y> {
    core::add_liquidity_with_receipt!(
        position,
        config,
        cap,
        price_info,
        debt_info,
        cetus_pool,
        |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition| {
            let receipt = cetus_pool::add_liquidity(
                cetus_config,
                pool,
                lp_position,
                delta_l,
                clock,
            );
            let (delta_x, delta_y) = receipt.add_liquidity_pay_amount();
            (delta_l, delta_x, delta_y, receipt)
        },
    )
}

public fun add_liquidity_fix_coin<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
    amount: u64,
    fix_amount_x: bool,
    clock: &Clock,
): cetus_pool::AddLiquidityReceipt<X, Y> {
    core::add_liquidity_with_receipt!(
        position,
        config,
        cap,
        price_info,
        debt_info,
        cetus_pool,
        |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition| {
            let l_init = lp_position.liquidity();
            let receipt = cetus_pool::add_liquidity_fix_coin(
                cetus_config,
                pool,
                lp_position,
                amount,
                fix_amount_x,
                clock,
            );
            let l_end = lp_position.liquidity();
            let delta_l = l_end - l_init;
            let (delta_x, delta_y) = receipt.add_liquidity_pay_amount();

            (delta_l, delta_x, delta_y, receipt)
        },
    )
}

public fun repay_debt_x<X, Y, SX>(
    position: &mut Position<X, Y, CetusPosition>,
    cap: &PositionCap,
    balance: &mut Balance<X>,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
) {
    core::repay_debt_x(position, cap, balance, supply_pool, clock)
}

public fun repay_debt_y<X, Y, SY>(
    position: &mut Position<X, Y, CetusPosition>,
    cap: &PositionCap,
    balance: &mut Balance<Y>,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
) {
    core::repay_debt_y(position, cap, balance, supply_pool, clock)
}

public fun owner_collect_fee<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
): (Balance<X>, Balance<Y>) {
    core::owner_collect_fee!(
        position,
        config,
        cap,
        cetus_pool,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
        | cetus_pool::collect_fee(cetus_config, pool, lp_position, true),
    )
}

public fun owner_collect_reward<X, Y, T>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
    cetus_vault: &mut RewarderGlobalVault,
    clock: &Clock,
): Balance<T> {
    core::owner_collect_reward!(
        position,
        config,
        cap,
        cetus_pool,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
        | cetus_pool::collect_reward(cetus_config, pool, lp_position, cetus_vault, true, clock),
    )
}

public fun owner_take_stashed_rewards<X, Y, T>(
    position: &mut Position<X, Y, CetusPosition>,
    cap: &PositionCap,
    amount: Option<u64>,
): Balance<T> {
    core::owner_take_stashed_rewards(position, cap, amount)
}

public fun delete_position<X, Y>(
    position: Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    cap: PositionCap,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
    ctx: &mut TxContext,
) {
    core::delete_position!(
        position,
        config,
        cap,
        |lp_position| cetus_pool::close_position(cetus_config, cetus_pool, lp_position),
        ctx,
    )
}

/* ================= rebalance ================= */

#[allow(unused_mut_ref)]
public fun rebalance_collect_fee<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    receipt: &mut RebalanceReceipt,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
): (Balance<X>, Balance<Y>) {
    core::rebalance_collect_fee!(
        position,
        config,
        receipt,
        cetus_pool,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
        | cetus_pool::collect_fee(cetus_config, pool, lp_position, true),
    )
}

#[allow(unused_mut_ref)]
public fun rebalance_collect_reward<X, Y, T>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    receipt: &mut RebalanceReceipt,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
    cetus_vault: &mut RewarderGlobalVault,
    clock: &Clock,
): Balance<T> {
    core::rebalance_collect_reward!(
        position,
        config,
        receipt,
        cetus_pool,
        |
            pool: &mut cetus_pool::Pool<X, Y>,
            lp_position: &mut CetusPosition,
        | cetus_pool::collect_reward(cetus_config, pool, lp_position, cetus_vault, true, clock),
    )
}

public fun rebalance_add_liquidity<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    receipt: &mut RebalanceReceipt,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
    delta_l: u128,
    clock: &Clock,
): cetus_pool::AddLiquidityReceipt<X, Y> {
    core::rebalance_add_liquidity_with_receipt!(
        position,
        config,
        receipt,
        price_info,
        debt_info,
        cetus_pool,
        |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition| {
            let receipt = cetus_pool::add_liquidity(
                cetus_config,
                pool,
                lp_position,
                delta_l,
                clock,
            );
            let (delta_x, delta_y) = receipt.add_liquidity_pay_amount();
            (delta_l, delta_x, delta_y, receipt)
        },
    )
}

public fun rebalance_add_liquidity_by_fix_coin<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    receipt: &mut RebalanceReceipt,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    cetus_config: &cetus_config::GlobalConfig,
    amount: u64,
    fix_amount_x: bool,
    clock: &Clock,
): cetus_pool::AddLiquidityReceipt<X, Y> {
    core::rebalance_add_liquidity_with_receipt!(
        position,
        config,
        receipt,
        price_info,
        debt_info,
        cetus_pool,
        |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition| {
            let l_init = lp_position.liquidity();
            let receipt = cetus_pool::add_liquidity_fix_coin(
                cetus_config,
                pool,
                lp_position,
                amount,
                fix_amount_x,
                clock,
            );
            let l_end = lp_position.liquidity();
            let delta_l = l_end - l_init;
            let (delta_x, delta_y) = receipt.add_liquidity_pay_amount();

            (delta_l, delta_x, delta_y, receipt)
        },
    )
}

/* ================= cetus incident recovery ================= */

public fun sync_exploited_position_liquidity_by_small_withdraw<X, Y>(
    position: &mut Position<X, Y, CetusPosition>,
    config: &mut PositionConfig,
    cetus_config: &cetus_config::GlobalConfig,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    balance_bag: &mut BalanceBag,
    clock: &Clock,
    ctx: &mut TxContext,
): ActionRequest {
    core::check_versions(position, config);
    assert!(position.config_id() == object::id(config)); // EInvalidConfig
    assert!(config.pool_object_id() == object::id(cetus_pool)); // EInvalidPool
    assert!(position.ticket_active() == false); // ETicketActive

    let position_id = object::id(position.lp_position());
    assert!(cetus_pool.is_attacked_position(position_id)); // EPositionNotExploited

    let position_info = cetus_pool.borrow_position_info(position_id);
    let info_liquidity = position_info.info_liquidity();
    assert!(info_liquidity != position.lp_position().liquidity()); // EPositionAlreadySynced

    let delta_l = 1;
    let initial_liquidity = position.lp_position().liquidity();

    let (delta_x, delta_y) = remove_liquidity(
        cetus_config,
        cetus_pool,
        position.lp_position_mut(),
        delta_l,
        clock,
    );
    config.decrease_current_global_l(initial_liquidity - position.lp_position().liquidity());

    balance_bag.add(delta_x);
    balance_bag.add(delta_y);

    access::new_request(AHandleExploitedPosition(), ctx)
}

public fun destruct_exploited_position_and_return_lp<X, Y>(
    position: Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    cap: PositionCap,
    cetus_pool: &mut cetus_pool::Pool<X, Y>,
    ctx: &mut TxContext,
): CetusPosition {
    core::check_versions(&position, config);
    assert!(position.config_id() == object::id(config)); // EInvalidConfig
    assert!(cap.position_id() == object::id(&position)); // EInvalidPositionCap
    assert!(position.ticket_active() == false); // ETicketActive
    assert!(!config.delete_position_disabled()); // EDeletePositionDisabled

    let position_id = object::id(position.lp_position());
    assert!(cetus_pool.is_attacked_position(position_id)); // EPositionNotExploited

    // delete position
    let (
        id,
        _config_id,
        lp_position,
        col_x,
        col_y,
        debt_bag,
        collected_fees,
        owner_reward_stash,
        _ticket_active,
        _version,
    ) = core::position_deconstructor(position);

    id.delete();
    col_x.destroy_zero();
    col_y.destroy_zero();
    debt_bag.destroy_empty();
    owner_reward_stash.destroy_empty();

    // delete cap
    let (id, position_id) = core::position_cap_deconstructor(cap);
    let cap_id = id.to_inner();
    id.delete();

    if (collected_fees.is_empty()) {
        collected_fees.destroy_empty()
    } else {
        core::share_deleted_position_collected_fees(
            position_id,
            collected_fees,
            ctx,
        );
    };

    core::emit_delete_position_info(position_id, cap_id);

    lp_position
}

/* ================= read ================= */

public fun position_model<X, Y>(
    position: &Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    debt_info: &DebtInfo,
): PositionModel {
    core::validated_model_for_position!(position, config, debt_info)
}

public fun calc_liquidate_col_x<X, Y>(
    position: &Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_y: u64,
): (u64, u64) {
    core::calc_liquidate_col_x!(position, config, price_info, debt_info, max_repayment_amt_y)
}

public fun calc_liquidate_col_y<X, Y>(
    position: &Position<X, Y, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_x: u64,
): (u64, u64) {
    core::calc_liquidate_col_y!(position, config, price_info, debt_info, max_repayment_amt_x)
}

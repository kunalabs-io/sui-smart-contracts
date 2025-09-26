#[test_only]
module kai_leverage::mock_dex_integration;

use access_management::access::ActionRequest;
use integer_mate::i32::I32;
use kai_leverage::debt_info::DebtInfo;
use kai_leverage::mock_dex::{Self, MockDexPool, PositionKey};
use kai_leverage::position_core_clmm::{
    Self as core,
    PositionConfig,
    CreatePositionTicket,
    PositionCap,
    Position,
    RebalanceReceipt,
    ReductionRepaymentTicket,
    DeleverageTicket,
    e_invalid_balance_value
};
use kai_leverage::position_model_clmm::PositionModel;
use kai_leverage::pyth::PythPriceInfo;
use kai_leverage::supply_pool::SupplyPool;
use sui::balance::Balance;
use sui::clock::Clock;
use sui::sui::SUI;

public fun create_position_ticket<X, Y>(
    mock_dex_pool: &mut MockDexPool<X, Y>,
    config: &mut PositionConfig,
    tick_a: I32,
    tick_b: I32,
    principal_x: Balance<X>,
    principal_y: Balance<Y>,
    delta_l: u128,
    price_info: &PythPriceInfo,
    clock: &Clock,
    ctx: &mut TxContext,
): CreatePositionTicket<X, Y, I32> {
    core::create_position_ticket!(
        mock_dex_pool,
        config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        price_info,
        clock,
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
    mock_dex_pool: &mut MockDexPool<X, Y>,
    creation_fee: Balance<SUI>,
    ctx: &mut TxContext,
): PositionCap {
    core::create_position!(
        config,
        ticket,
        mock_dex_pool,
        creation_fee,
        ctx,
        |pool, tick_a, tick_b, delta_l, balance_x0, balance_y0| {
            let position_key = pool.open_position(
                tick_a,
                tick_b,
                delta_l,
                balance_x0,
                balance_y0,
                ctx,
            );

            position_key
        },
    )
}

/* ================= deleverage and liquidation ================= */

public fun create_deleverage_ticket<X, Y>(
    position: &mut Position<X, Y, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    mock_dex_pool: &mut MockDexPool<X, Y>,
    max_delta_l: u128,
    ctx: &mut TxContext,
): (DeleverageTicket, ActionRequest) {
    core::create_deleverage_ticket!(
        position,
        config,
        price_info,
        debt_info,
        mock_dex_pool,
        max_delta_l,
        ctx,
        |
            pool: &mut MockDexPool<X, Y>,
            lp_position: &mut PositionKey,
            delta_l: u128,
        | pool.remove_liquidity(lp_position, delta_l),
    )
}

public fun create_deleverage_ticket_for_liquidation<X, Y>(
    position: &mut Position<X, Y, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    mock_dex_pool: &mut MockDexPool<X, Y>,
): DeleverageTicket {
    core::create_deleverage_ticket_for_liquidation!(
        position,
        config,
        price_info,
        debt_info,
        mock_dex_pool,
        |
            pool: &mut MockDexPool<X, Y>,
            lp_position: &mut PositionKey,
            delta_l: u128,
        | pool.remove_liquidity(lp_position, delta_l),
    )
}

public fun deleverage<X, Y, SX, SY>(
    position: &mut Position<X, Y, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    mock_dex_pool: &mut MockDexPool<X, Y>,
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
        mock_dex_pool,
        max_delta_l,
        clock,
        ctx,
        |
            pool: &mut MockDexPool<X, Y>,
            lp_position: &mut PositionKey,
            delta_l: u128,
        | pool.remove_liquidity(lp_position, delta_l),
    )
}

public fun deleverage_for_liquidation<X, Y, SX, SY>(
    position: &mut Position<X, Y, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    mock_dex_pool: &mut MockDexPool<X, Y>,
    clock: &Clock,
) {
    core::deleverage_for_liquidation!(
        position,
        config,
        price_info,
        supply_pool_x,
        supply_pool_y,
        mock_dex_pool,
        clock,
        |
            pool: &mut MockDexPool<X, Y>,
            lp_position: &mut PositionKey,
            delta_l: u128,
        | pool.remove_liquidity(lp_position, delta_l),
    )
}

public fun liquidate_col_x<X, Y, SY>(
    position: &mut Position<X, Y, PositionKey>,
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
    position: &mut Position<X, Y, PositionKey>,
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
    position: &mut Position<X, Y, PositionKey>,
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
    position: &mut Position<X, Y, PositionKey>,
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

/* ================= user operations ================= */

public fun reduce<X, Y, SX, SY>(
    position: &mut Position<X, Y, PositionKey>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    supply_pool_x: &mut SupplyPool<X, SX>,
    supply_pool_y: &mut SupplyPool<Y, SY>,
    mock_dex_pool: &mut MockDexPool<X, Y>,
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
        mock_dex_pool,
        factor_x64,
        clock,
        |
            pool: &mut MockDexPool<X, Y>,
            lp_position: &mut PositionKey,
            delta_l: u128,
        | pool.remove_liquidity(lp_position, delta_l),
    )
}

public fun owner_collect_fee<X, Y>(
    position: &mut Position<X, Y, PositionKey>,
    config: &PositionConfig,
    cap: &PositionCap,
    mock_dex_pool: &mut MockDexPool<X, Y>,
): (Balance<X>, Balance<Y>) {
    core::owner_collect_fee!(
        position,
        config,
        cap,
        mock_dex_pool,
        |pool: &mut MockDexPool<X, Y>, lp_position: &mut PositionKey| {
            let (balance_x, balance_y) = mock_dex::collect_fees(
                pool,
                lp_position,
            );
            (balance_x, balance_y)
        },
    )
}

public fun owner_collect_reward<X, Y, T>(
    position: &mut Position<X, Y, PositionKey>,
    config: &PositionConfig,
    cap: &PositionCap,
    mock_dex_pool: &mut MockDexPool<X, Y>,
): Balance<T> {
    core::owner_collect_reward!(
        position,
        config,
        cap,
        mock_dex_pool,
        |pool: &mut MockDexPool<X, Y>, lp_position: &mut PositionKey| mock_dex::collect_reward(
            pool,
            lp_position,
        ),
    )
}

public fun delete_position<X, Y>(
    position: Position<X, Y, PositionKey>,
    config: &PositionConfig,
    cap: PositionCap,
    mock_dex_pool: &mut MockDexPool<X, Y>,
    ctx: &mut TxContext,
) {
    core::delete_position!(
        position,
        config,
        cap,
        |lp_position| mock_dex::close_position(
            mock_dex_pool,
            lp_position,
        ),
        ctx,
    )
}

/* ================= rebalance ================= */

#[allow(unused_mut_ref)]
public fun rebalance_collect_fee<X, Y>(
    position: &mut Position<X, Y, PositionKey>,
    config: &PositionConfig,
    receipt: &mut RebalanceReceipt,
    mock_dex_pool: &mut MockDexPool<X, Y>,
): (Balance<X>, Balance<Y>) {
    core::rebalance_collect_fee!(
        position,
        config,
        receipt,
        mock_dex_pool,
        |pool: &mut MockDexPool<X, Y>, lp_position: &mut PositionKey| {
            let (balance_x, balance_y) = mock_dex::collect_fees(
                pool,
                lp_position,
            );
            (balance_x, balance_y)
        },
    )
}

#[allow(unused_mut_ref)]
public fun rebalance_collect_reward<X, Y, T>(
    position: &mut Position<X, Y, PositionKey>,
    config: &PositionConfig,
    receipt: &mut RebalanceReceipt,
    mock_dex_pool: &mut MockDexPool<X, Y>,
): Balance<T> {
    core::rebalance_collect_reward!(
        position,
        config,
        receipt,
        mock_dex_pool,
        |pool: &mut MockDexPool<X, Y>, lp_position: &mut PositionKey| mock_dex::collect_reward(
            pool,
            lp_position,
        ),
    )
}

public fun rebalance_add_liquidity<X, Y>(
    position: &mut Position<X, Y, PositionKey>,
    config: &mut PositionConfig,
    receipt: &mut RebalanceReceipt,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    mock_dex_pool: &mut MockDexPool<X, Y>,
    delta_l: u128,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
) {
    let (delta_x, delta_y) = mock_dex::calc_deposit_amounts_by_liquidity(
        mock_dex_pool,
        position.lp_position().tick_a(),
        position.lp_position().tick_b(),
        delta_l,
    );
    assert!(balance_x.value() == delta_x, e_invalid_balance_value!());
    assert!(balance_y.value() == delta_y, e_invalid_balance_value!());

    core::rebalance_add_liquidity!(
        position,
        config,
        receipt,
        price_info,
        debt_info,
        mock_dex_pool,
        |pool: &mut MockDexPool<X, Y>, lp_position: &mut PositionKey| {
            let (delta_x, delta_y) = mock_dex::add_liquidity(
                pool,
                lp_position,
                balance_x,
                balance_y,
                delta_l,
            );

            (delta_l, delta_x, delta_y)
        },
    )
}

/* ================= read ================= */

public fun validated_model_for_position<X, Y>(
    position: &Position<X, Y, PositionKey>,
    config: &PositionConfig,
    debt_info: &DebtInfo,
): PositionModel {
    core::validated_model_for_position!(position, config, debt_info)
}

public fun calc_liquidate_col_x<X, Y>(
    position: &Position<X, Y, PositionKey>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_y: u64,
): (u64, u64) {
    core::calc_liquidate_col_x!(position, config, price_info, debt_info, max_repayment_amt_y)
}

public fun calc_liquidate_col_y<X, Y>(
    position: &Position<X, Y, PositionKey>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_x: u64,
): (u64, u64) {
    core::calc_liquidate_col_y!(position, config, price_info, debt_info, max_repayment_amt_x)
}

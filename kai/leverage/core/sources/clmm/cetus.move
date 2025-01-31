module kai_leverage::cetus {
    use sui::balance::{Self, Balance};
    use sui::clock::Clock;
    use sui::sui::SUI;

    use cetus_clmm::pool as cetus_pool;
    use integer_mate::i32::{Self, I32};
    use cetus_clmm::config as cetus_config;
    use cetus_clmm::position::Position as CetusPosition;
    use cetus_clmm::rewarder::RewarderGlobalVault;

    use access_management::access::ActionRequest;
    use kai_leverage::position_core_clmm as core;
    use kai_leverage::position_core_clmm::{
        PositionConfig, CreatePositionTicket, PositionCap, Position, DeleverageTicket, RebalanceReceipt,
        ReductionRepaymentTicket
    };
    use kai_leverage::pyth::PythPriceInfo;
    use kai_leverage::supply_pool::SupplyPool;
    use kai_leverage::debt_info::DebtInfo;
    use kai_leverage::position_model_clmm::PositionModel;

    /* ================= util ================= */

    public fun slippage_tolerance_assertion<X, Y>(
        pool: &cetus_pool::Pool<X, Y>, p0_desired_x128: u256, max_slippage_bps: u16
    ) {
        core::slippage_tolerance_assertion!(pool, p0_desired_x128, max_slippage_bps);
    }

    public fun calc_deposit_amounts_by_liquidity<X, Y>(
        pool: &cetus_pool::Pool<X, Y>, tick_a: I32, tick_b: I32, delta_l: u128
    ): (u64, u64) {
        let current_tick = pool.current_tick_index();
        let sqrt_p0_x64 = pool.current_sqrt_price();
        cetus_pool::get_amount_by_liquidity(
            tick_a, tick_b, current_tick, sqrt_p0_x64, delta_l, true
        )
    }

    public fun remove_liquidity<X, Y>(
        config: &cetus_config::GlobalConfig, pool: &mut cetus_pool::Pool<X, Y>,
        lp_position: &mut CetusPosition, delta_l: u128, clock: &Clock
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
        ctx: &mut TxContext
    ): CreatePositionTicket<X, Y, I32> {
        core::create_position_ticket!(
            cetus_pool, config, tick_a, tick_b, principal_x, principal_y, delta_l, price_info, ctx,
        )
    }

    public fun borrow_for_position_x<X, Y, SX>(
        ticket: &mut CreatePositionTicket<X, Y, I32>, config: &PositionConfig,
        supply_pool: &mut SupplyPool<X, SX>, clock: &Clock
    ) {
        core::borrow_for_position_x!(ticket, config, supply_pool, clock)
    }

    public fun borrow_for_position_y<X, Y, SY>(
        ticket: &mut CreatePositionTicket<X, Y, I32>, config: &PositionConfig,
        supply_pool: &mut SupplyPool<Y, SY>, clock: &Clock
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
            config, ticket, cetus_pool, creation_fee, ctx,
            |pool, tick_a, tick_b, delta_l, balance_x0, balance_y0| {
                let mut lp_position = cetus_pool::open_position(
                    cetus_global_config, pool, i32::as_u32(tick_a), i32::as_u32(tick_b), ctx
                );
                let receipt = cetus_pool::add_liquidity(
                    cetus_global_config, pool, &mut lp_position, delta_l, clock
                );
                cetus_pool::repay_add_liquidity(cetus_global_config, pool, balance_x0, balance_y0, receipt);

                lp_position
            }
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
        ctx: &mut TxContext
    ): (DeleverageTicket, ActionRequest) {
        core::create_deleverage_ticket!(
            position, config, price_info, debt_info, cetus_pool, max_delta_l, ctx,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition, delta_l: u128|
                remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock)
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
            position, config, price_info, debt_info, cetus_pool,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition, delta_l: u128|
                remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock)
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
        ctx: &mut TxContext
    ): ActionRequest {
        core::deleverage!(
            position, config, price_info, supply_pool_x, supply_pool_y, cetus_pool,
            max_delta_l, clock, ctx,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition, delta_l: u128|
                remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock)
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
        clock: &Clock
    ) {
        core::deleverage_for_liquidation!(
            position, config, price_info, supply_pool_x, supply_pool_y, cetus_pool, clock,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition, delta_l: u128|
                remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock)
        )
    }

    public fun liquidate_col_x<X, Y, SY>(
        position: &mut Position<X, Y, CetusPosition>,
        config: &PositionConfig,
        price_info: &PythPriceInfo,
        debt_info: &DebtInfo,
        repayment: &mut Balance<Y>,
        supply_pool: &mut SupplyPool<Y, SY>,
        clock: &Clock
    ): Balance<X> {
        core::liquidate_col_x!(
            position, config, price_info, debt_info, repayment, supply_pool, clock
        )
    }

    public fun liquidate_col_y<X, Y, SX>(
        position: &mut Position<X, Y, CetusPosition>,
        config: &PositionConfig,
        price_info: &PythPriceInfo,
        debt_info: &DebtInfo,
        repayment: &mut Balance<X>,
        supply_pool: &mut SupplyPool<X, SX>,
        clock: &Clock
    ): Balance<Y> {
        core::liquidate_col_y!(
            position, config, price_info, debt_info, repayment, supply_pool, clock
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
        clock: &Clock
    ): (Balance<X>, Balance<Y>, ReductionRepaymentTicket<SX, SY>) {
        core::reduce!(
            position, config, cap, price_info, supply_pool_x, supply_pool_y, cetus_pool,
            factor_x64, clock,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition, delta_l: u128|
                remove_liquidity(cetus_global_config, pool, lp_position, delta_l, clock)
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
        clock: &Clock
    ): cetus_pool::AddLiquidityReceipt<X, Y> {
        core::add_liquidity_with_receipt!(
            position, config, cap, price_info, debt_info, cetus_pool,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition| {
                let receipt = cetus_pool::add_liquidity(cetus_config, pool, lp_position, delta_l, clock);
                let (delta_x, delta_y) = receipt.add_liquidity_pay_amount();
                (delta_l, delta_x, delta_y, receipt)
            }
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
        clock: &Clock
    ): cetus_pool::AddLiquidityReceipt<X, Y> {
        core::add_liquidity_with_receipt!(
            position, config, cap, price_info, debt_info, cetus_pool,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition| {
                let l_init = lp_position.liquidity();
                let receipt = cetus_pool::add_liquidity_fix_coin(
                    cetus_config, pool, lp_position, amount, fix_amount_x, clock
                );
                let l_end = lp_position.liquidity();
                let delta_l = l_end - l_init;
                let (delta_x, delta_y) = receipt.add_liquidity_pay_amount();

                (delta_l, delta_x, delta_y, receipt)
            }
        )
    }

    public fun repay_debt_x<X, Y, SX>(
        position: &mut Position<X, Y, CetusPosition>,
        cap: &PositionCap,
        balance: &mut Balance<X>,
        supply_pool: &mut SupplyPool<X, SX>,
        clock: &Clock
    ) {
        core::repay_debt_x(position, cap, balance, supply_pool, clock)
    }

    public fun repay_debt_y<X, Y, SY>(
        position: &mut Position<X, Y, CetusPosition>,
        cap: &PositionCap,
        balance: &mut Balance<Y>,
        supply_pool: &mut SupplyPool<Y, SY>,
        clock: &Clock
    ) {
        core::repay_debt_y(position, cap, balance, supply_pool, clock)
    }

    /* ================= rebalance ================= */

    #[allow(unused_mut_ref)]
    public fun rebalance_collect_fee<X, Y>(
        position: &mut Position<X, Y, CetusPosition>,
        config: &PositionConfig,
        receipt: &mut RebalanceReceipt,
        cetus_pool: &mut cetus_pool::Pool<X, Y>,
        cetus_config: &cetus_config::GlobalConfig
    ): (Balance<X>, Balance<Y>) {
       core::rebalance_collect_fee!(
            position, config, receipt, cetus_pool,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition|
                cetus_pool::collect_fee(cetus_config, pool, lp_position, true)
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
        clock: &Clock
    ): Balance<T> {
        core::rebalance_collect_reward!(
            position, config, receipt, cetus_pool,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &CetusPosition|
                cetus_pool::collect_reward(cetus_config, pool, lp_position, cetus_vault, true, clock)
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
        clock: &Clock
    ): cetus_pool::AddLiquidityReceipt<X, Y> {
        core::rebalance_add_liquidity_with_receipt!(
            position, config, receipt, price_info, debt_info, cetus_pool,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition| {
                let receipt = cetus_pool::add_liquidity(cetus_config, pool, lp_position, delta_l, clock);
                let (delta_x, delta_y) = receipt.add_liquidity_pay_amount();
                (delta_l, delta_x, delta_y, receipt)
            }
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
        clock: &Clock
    ): cetus_pool::AddLiquidityReceipt<X, Y> {
        core::rebalance_add_liquidity_with_receipt!(
            position, config, receipt, price_info, debt_info, cetus_pool,
            |pool: &mut cetus_pool::Pool<X, Y>, lp_position: &mut CetusPosition| {
                let l_init = lp_position.liquidity();
                let receipt = cetus_pool::add_liquidity_fix_coin(
                    cetus_config, pool, lp_position, amount, fix_amount_x, clock
                );
                let l_end = lp_position.liquidity();
                let delta_l = l_end - l_init;
                let (delta_x, delta_y) = receipt.add_liquidity_pay_amount();

                (delta_l, delta_x, delta_y, receipt)
            }
        )
    }

    /* ================= read ================= */

    public fun position_model<X, Y>(
        position: &Position<X, Y, CetusPosition>,
        config: &PositionConfig,
        debt_info: &DebtInfo
    ): PositionModel {
        core::validated_model_for_position!(position, config, debt_info)
    }

    public fun calc_liquidate_col_x<X, Y>(
        position: &Position<X, Y, CetusPosition>,
        config: &PositionConfig,
        price_info: &PythPriceInfo,
        debt_info: &DebtInfo,
        max_repayment_amt_y: u64
    ): (u64, u64) {
        core::calc_liquidate_col_x!(position, config, price_info, debt_info, max_repayment_amt_y)
    }

    public fun calc_liquidate_col_y<X, Y>(
        position: &Position<X, Y, CetusPosition>,
        config: &PositionConfig,
        price_info: &PythPriceInfo,
        debt_info: &DebtInfo,
        max_repayment_amt_x: u64
    ): (u64, u64) {
        core::calc_liquidate_col_y!(position, config, price_info, debt_info, max_repayment_amt_x)
    }
}

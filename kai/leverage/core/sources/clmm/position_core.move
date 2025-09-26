// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_leverage::position_core_clmm;

use access_management::access::{Self, ActionRequest};
use kai_leverage::balance_bag::{Self, BalanceBag};
use kai_leverage::debt_info::{Self, DebtInfo, ValidatedDebtInfo};
use kai_leverage::position_model_clmm::{Self, PositionModel};
use kai_leverage::pyth::{Self, PythPriceInfo, ValidatedPythPriceInfo};
use kai_leverage::supply_pool::{Self, SupplyPool, LendFacilCap, FacilDebtBag, FacilDebtShare};
use kai_leverage::util;
use pyth::i64 as pyth_i64;
use rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter;
use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::dynamic_field as df;
use sui::event;
use sui::sui::SUI;
use sui::vec_map::{Self, VecMap};

// Position
use fun position_share_object as Position.share_object;

// PositionCap
public use fun pc_position_id as PositionCap.position_id;

// RebalanceReceipt
public use fun rr_position_id as RebalanceReceipt.position_id;
public use fun rr_collected_amm_fee_x as RebalanceReceipt.collected_amm_fee_x;
public use fun rr_collected_amm_fee_y as RebalanceReceipt.collected_amm_fee_y;
public use fun rr_collected_amm_rewards as RebalanceReceipt.collected_amm_rewards;
public use fun rr_fees_taken as RebalanceReceipt.fees_taken;
public use fun rr_taken_cx as RebalanceReceipt.taken_cx;
public use fun rr_taken_cy as RebalanceReceipt.taken_cy;
public use fun rr_delta_l as RebalanceReceipt.delta_l;
public use fun rr_delta_x as RebalanceReceipt.delta_x;
public use fun rr_delta_y as RebalanceReceipt.delta_y;
public use fun rr_x_repaid as RebalanceReceipt.x_repaid;
public use fun rr_y_repaid as RebalanceReceipt.y_repaid;
public use fun rr_added_cx as RebalanceReceipt.added_cx;
public use fun rr_added_cy as RebalanceReceipt.added_cy;
public use fun rr_stashed_amm_rewards as RebalanceReceipt.stashed_amm_rewards;

// CreatePositionTicket
public use fun cpt_config_id as CreatePositionTicket.config_id;
public use fun cpt_debt_bag as CreatePositionTicket.debt_bag;
use fun cpt_debt_bag_mut as CreatePositionTicket.debt_bag_mut;
public use fun cpt_tick_a as CreatePositionTicket.tick_a;
public use fun cpt_tick_b as CreatePositionTicket.tick_b;

// Position
public use fun position_config_id as Position.config_id;
public use fun position_debt_bag as Position.debt_bag;
use fun position_debt_bag_mut as Position.debt_bag_mut;

// AddLiquidityInfo
use fun ali_emit as AddLiquidityInfo.emit;
use fun ali_delta_l as AddLiquidityInfo.delta_l;
use fun ali_delta_x as AddLiquidityInfo.delta_x;
use fun ali_delta_y as AddLiquidityInfo.delta_y;

// DeleverageTicket
public use fun dt_position_id as DeleverageTicket.position_id;
public use fun dt_can_repay_x as DeleverageTicket.can_repay_x;
public use fun dt_can_repay_y as DeleverageTicket.can_repay_y;
public use fun dt_info as DeleverageTicket.info;

// DeleverageInfo
public use fun di_position_id as DeleverageInfo.position_id;
public use fun di_model as DeleverageInfo.model;
public use fun di_oracle_price_x128 as DeleverageInfo.oracle_price_x128;
public use fun di_sqrt_pool_price_x64 as DeleverageInfo.sqrt_pool_price_x64;
public use fun di_delta_l as DeleverageInfo.delta_l;
public use fun di_delta_x as DeleverageInfo.delta_x;
public use fun di_delta_y as DeleverageInfo.delta_y;
public use fun di_x_repaid as DeleverageInfo.x_repaid;
public use fun di_y_repaid as DeleverageInfo.y_repaid;

// ReductionRepaymentTicket
public use fun rrt_sx as ReductionRepaymentTicket.sx;
public use fun rrt_sy as ReductionRepaymentTicket.sy;
public use fun rrt_info as ReductionRepaymentTicket.info;

// ReductionInfo
public use fun ri_position_id as ReductionInfo.position_id;
public use fun ri_model as ReductionInfo.model;
public use fun ri_oracle_price_x128 as ReductionInfo.oracle_price_x128;
public use fun ri_sqrt_pool_price_x64 as ReductionInfo.sqrt_pool_price_x64;
public use fun ri_delta_l as ReductionInfo.delta_l;
public use fun ri_delta_x as ReductionInfo.delta_x;
public use fun ri_delta_y as ReductionInfo.delta_y;
public use fun ri_withdrawn_x as ReductionInfo.withdrawn_x;
public use fun ri_withdrawn_y as ReductionInfo.withdrawn_y;
public use fun ri_x_repaid as ReductionInfo.x_repaid;
public use fun ri_y_repaid as ReductionInfo.y_repaid;

// turbos
/*
use fun turbos_clmm::pool::get_pool_sqrt_price as turbos_clmm::pool::Pool.current_sqrt_price_x64;
use fun turbos_clmm::pool::get_pool_current_index as turbos_clmm::pool::Pool.current_tick_index;
use fun turbos_clmm::math_tick::sqrt_price_from_tick_index as
    turbos_clmm::i32::I32.as_sqrt_price_x64;
use fun kai_leverage::turbos::calc_deposit_amounts_by_liquidity as
    turbos_clmm::pool::Pool.calc_deposit_amounts_by_liquidity;
use fun kai_leverage::turbos::wrapped_tick_range as
    kai_leverage::turbos::TurbosWrappedPosition.tick_range;
use fun kai_leverage::turbos::wrapped_liquidity as
    kai_leverage::turbos::TurbosWrappedPosition.liquidity;
*/

// cetus
use fun cetus_clmm::pool::current_sqrt_price as cetus_clmm::pool::Pool.current_sqrt_price_x64;
use fun cetus_clmm::tick_math::get_sqrt_price_at_tick as integer_mate::i32::I32.as_sqrt_price_x64;
use fun kai_leverage::cetus::calc_deposit_amounts_by_liquidity as
    cetus_clmm::pool::Pool.calc_deposit_amounts_by_liquidity;

// bluefin
use fun bluefin_spot::pool::current_sqrt_price as bluefin_spot::pool::Pool.current_sqrt_price_x64;
use fun kai_leverage::bluefin_spot::calc_deposit_amounts_by_liquidity as
    bluefin_spot::pool::Pool.calc_deposit_amounts_by_liquidity;
use fun kai_leverage::bluefin_spot::position_tick_range as
    bluefin_spot::position::Position.tick_range;

// flowx
/*
use fun flowx_clmm::pool::sqrt_price_current as flowx_clmm::pool::Pool.current_sqrt_price_x64;
use fun flowx_clmm::pool::tick_index_current as flowx_clmm::pool::Pool.current_tick_index;
use fun flowx_clmm::tick_math::get_sqrt_price_at_tick as flowx_clmm::i32::I32.as_sqrt_price_x64;
use fun kai_leverage::flowx::calc_deposit_amounts_by_liquidity as
    flowx_clmm::pool::Pool.calc_deposit_amounts_by_liquidity;
use fun kai_leverage::flowx::position_tick_range as flowx_clmm::position::Position.tick_range;
*/

/* ================= constants ================= */

const MODULE_VERSION: u16 = 3;

/* ================= errors ================= */

// Invalid position - the current price is not within the chosen range.
public(package) macro fun e_invalid_tick_range(): u64 {
    0
}
// Invalid position - the margin is too low at the liquidation threshold.
public(package) macro fun e_liq_margin_too_low(): u64 {
    1
}
// Invalid position - the initial margin is below allowed.
public(package) macro fun e_initial_margin_too_low(): u64 {
    2
}
// Creating new positions is not allowed.
public(package) macro fun e_new_positions_not_allowed(): u64 {
    3
}
/// Invalid config passed in for the position.
public(package) macro fun e_invalid_config(): u64 {
    4
}
// Invalid pool object passed in.
public(package) macro fun e_invalid_pool(): u64 {
    5
}
// Borrowed amount is not equal to the amount needed for the position.
public(package) macro fun e_invalid_borrow(): u64 {
    6
}
/// Invalid `PositionCap` object.
public(package) macro fun e_invalid_position_cap(): u64 {
    7
}
/// Another ticket is already active for this position. One operation at a time please!
public(package) macro fun e_ticket_active(): u64 {
    8
}
/// The ticket / receipt does not match the position.
public(package) macro fun e_position_mismatch(): u64 {
    9
}
/// The ticket is not fully exhausted, so it cannot be destroyed.
const ETicketNotExhausted: u64 = 10;
// Operation not permitted because the position is below a safe margin level.
public(package) macro fun e_position_below_threshold(): u64 {
    11
}
// AMM price slippage exceeded the allowed tolerance.
public(package) macro fun e_slippage_exceeded(): u64 {
    12
}
// The position size limit has been exceeded.
public(package) macro fun e_position_size_limit_exceeded(): u64 {
    13
}
// The global vault size limit has been exceeded.
public(package) macro fun e_vault_global_size_limit_exceeded(): u64 {
    14
}
// The creation fee amount does not match the required fee amount.
public(package) macro fun e_invalid_creation_fee_amount(): u64 {
    15
}
/// The `PositionConfig` version does not match the module version.
const EInvalidConfigVersion: u64 = 16;
/// The `Position` version does not match the module version.
const EInvalidPositionVersion: u64 = 17;
/// The migration is not allowed because the object version is higher or equal to the module
/// version.
const ENotUpgrade: u64 = 18;
/// The deleverage margin must be higher than the liquidation margin.
const EInvalidMarginValue: u64 = 19;
/// The `SupplyPool` share type does not match the position debt share type.
public(package) macro fun e_supply_pool_mismatch(): u64 {
    20
}
/// The position must have zero outstanding debt before this operation can proceed.
public(package) macro fun e_position_not_fully_deleveraged(): u64 {
    21
}
/// The position's margin is not sufficiently low to qualify as bad debt.
public(package) macro fun e_position_not_below_bad_debt_threshold(): u64 {
    22
}
/// Liquidation actions are currently disabled for this position.
public(package) macro fun e_liquidation_disabled(): u64 {
    23
}
/// Reduction operations are currently disabled for this position.
public(package) macro fun e_reduction_disabled(): u64 {
    24
}
/// Adding liquidity is currently disabled for this position.
public(package) macro fun e_add_liquidity_disabled(): u64 {
    25
}
/// Owner fee collection is currently disabled for this position.
public(package) macro fun e_owner_collect_fee_disabled(): u64 {
    26
}
/// Owner reward collection is currently disabled for this position.
public(package) macro fun e_owner_collect_reward_disabled(): u64 {
    27
}
/// Deleting this position is currently disabled.
public(package) macro fun e_delete_position_disabled(): u64 {
    28
}
/// Invalid balance value passed in for liquidity deposit.
public(package) macro fun e_invalid_balance_value(): u64 {
    29
}
/// Function deprecated.
public(package) macro fun e_function_deprecated(): u64 {
    30
}
/// The deviation between the oracle price and the pool price is too high.
public(package) macro fun e_price_deviation_too_high(): u64 {
    31
}

/* ================= access ================= */

public struct ACreateConfig has drop {}
public struct AModifyConfig has drop {}
public struct AMigrate has drop {}
public struct ADeleverage has drop {}
public struct ARebalance has drop {}
public struct ACollectProtocolFees has drop {}
public struct ARepayBadDebt has drop {}

public(package) fun a_deleverage(): ADeleverage {
    ADeleverage {}
}

public(package) fun a_rebalance(): ARebalance {
    ARebalance {}
}

public(package) fun a_repay_bad_debt(): ARepayBadDebt {
    ARepayBadDebt {}
}

/* ================= CreatePositionTicket ================= */

public struct CreatePositionTicket<phantom X, phantom Y, I32> {
    config_id: ID,
    tick_a: I32,
    tick_b: I32,
    dx: u64,
    dy: u64,
    delta_l: u128,
    principal_x: Balance<X>,
    principal_y: Balance<Y>,
    borrowed_x: Balance<X>,
    borrowed_y: Balance<Y>,
    debt_bag: FacilDebtBag,
}

/* ================= Position ================= */

public struct Position<phantom X, phantom Y, LP> has key {
    id: UID,
    config_id: ID,
    lp_position: LP,
    col_x: Balance<X>,
    col_y: Balance<Y>,
    debt_bag: FacilDebtBag,
    collected_fees: BalanceBag,
    owner_reward_stash: BalanceBag,
    ticket_active: bool,
    version: u16,
}

public(package) fun position_constructor<X, Y, LP>(
    config_id: ID,
    lp_position: LP,
    col_x: Balance<X>,
    col_y: Balance<Y>,
    debt_bag: FacilDebtBag,
    collected_fees: BalanceBag,
    owner_reward_stash: BalanceBag,
    ctx: &mut TxContext,
): Position<X, Y, LP> {
    Position {
        id: object::new(ctx),
        config_id,
        lp_position,
        col_x,
        col_y,
        debt_bag,
        collected_fees,
        owner_reward_stash,
        ticket_active: false,
        version: MODULE_VERSION,
    }
}

public(package) fun position_deconstructor<X, Y, LP: store>(
    position: Position<X, Y, LP>,
): (UID, ID, LP, Balance<X>, Balance<Y>, FacilDebtBag, BalanceBag, BalanceBag, bool, u16) {
    let Position {
        id,
        config_id,
        lp_position,
        col_x,
        col_y,
        debt_bag,
        collected_fees,
        owner_reward_stash,
        ticket_active,
        version,
    } = position;
    (
        id,
        config_id,
        lp_position,
        col_x,
        col_y,
        debt_bag,
        collected_fees,
        owner_reward_stash,
        ticket_active,
        version,
    )
}

#[allow(lint(share_owned))]
public(package) fun position_share_object<X, Y, LP: store>(position: Position<X, Y, LP>) {
    transfer::share_object(position);
}

public fun position_config_id<X, Y, LP>(position: &Position<X, Y, LP>): ID {
    position.config_id
}

public fun lp_position<X, Y, LP>(position: &Position<X, Y, LP>): &LP {
    &position.lp_position
}

public fun col_x<X, Y, LP>(position: &Position<X, Y, LP>): &Balance<X> {
    &position.col_x
}

public fun col_y<X, Y, LP>(position: &Position<X, Y, LP>): &Balance<Y> {
    &position.col_y
}

public fun position_debt_bag<X, Y, LP>(position: &Position<X, Y, LP>): &FacilDebtBag {
    &position.debt_bag
}

public(package) fun ticket_active<X, Y, LP>(position: &Position<X, Y, LP>): bool {
    position.ticket_active
}

public(package) fun set_ticket_active<X, Y, LP>(position: &mut Position<X, Y, LP>, value: bool) {
    position.ticket_active = value;
}

public(package) fun lp_position_mut<X, Y, LP>(position: &mut Position<X, Y, LP>): &mut LP {
    &mut position.lp_position
}

public(package) fun col_x_mut<X, Y, LP>(position: &mut Position<X, Y, LP>): &mut Balance<X> {
    &mut position.col_x
}

public(package) fun col_y_mut<X, Y, LP>(position: &mut Position<X, Y, LP>): &mut Balance<Y> {
    &mut position.col_y
}

public(package) fun position_debt_bag_mut<X, Y, LP>(
    position: &mut Position<X, Y, LP>,
): &mut FacilDebtBag {
    &mut position.debt_bag
}

public(package) fun collected_fees<X, Y, LP>(position: &Position<X, Y, LP>): &BalanceBag {
    &position.collected_fees
}

public(package) fun collected_fees_mut<X, Y, LP>(
    position: &mut Position<X, Y, LP>,
): &mut BalanceBag {
    &mut position.collected_fees
}

public(package) fun owner_reward_stash<X, Y, LP>(position: &Position<X, Y, LP>): &BalanceBag {
    &position.owner_reward_stash
}

public(package) fun owner_reward_stash_mut<X, Y, LP>(
    position: &mut Position<X, Y, LP>,
): &mut BalanceBag {
    &mut position.owner_reward_stash
}

/* ================= PositionCap ================= */

public struct PositionCap has key, store {
    id: UID,
    position_id: ID,
}

public(package) fun position_cap_constructor(position_id: ID, ctx: &mut TxContext): PositionCap {
    PositionCap {
        id: object::new(ctx),
        position_id,
    }
}

public(package) fun position_cap_deconstructor(cap: PositionCap): (UID, ID) {
    let PositionCap { id, position_id } = cap;
    (id, position_id)
}

public fun pc_position_id(cap: &PositionCap): ID {
    cap.position_id
}

/* ================= PositionConfig ================= */

public struct PythConfig has copy, drop, store {
    max_age_secs: u64,
    pio_allowlist: VecMap<TypeName, ID>,
}

public struct PositionConfig has key {
    id: UID,
    pool_object_id: ID,
    allow_new_positions: bool,
    lend_facil_cap: LendFacilCap,
    /// The minimum required distance between the initial price and the price
    /// at which the liquidation will be triggered.
    min_liq_start_price_delta_bps: u16,
    /// The minimum initial margin allowed for position creation. Multiplied by 10000.
    min_init_margin_bps: u16,
    allowed_oracles: Bag,
    /// When the position margin level is below or at this value, it can be deleveraged. Multiplied
    /// by 10000.
    deleverage_margin_bps: u16,
    base_deleverage_factor_bps: u16,
    /// When the position margin level is below or at this value, it can be liquidated. Multiplied
    /// by 10000.
    liq_margin_bps: u16,
    base_liq_factor_bps: u16,
    liq_bonus_bps: u16,
    max_position_l: u128,
    max_global_l: u128,
    current_global_l: u128,
    rebalance_fee_bps: u16,
    liq_fee_bps: u16,
    position_creation_fee_sui: u64,
    version: u16,
}

public fun create_empty_config(pool_object_id: ID, ctx: &mut TxContext): (ID, ActionRequest) {
    let lend_facil_cap = supply_pool::create_lend_facil_cap(ctx);
    let lend_facil_cap_id = object::id(&lend_facil_cap);

    let config = PositionConfig {
        id: object::new(ctx),
        pool_object_id,
        allow_new_positions: false,
        lend_facil_cap,
        min_liq_start_price_delta_bps: 0,
        min_init_margin_bps: 0,
        allowed_oracles: bag::new(ctx),
        deleverage_margin_bps: 0,
        base_deleverage_factor_bps: 0,
        liq_margin_bps: 0,
        base_liq_factor_bps: 0,
        liq_bonus_bps: 0,
        max_position_l: 0,
        max_global_l: 0,
        current_global_l: 0,
        rebalance_fee_bps: 0,
        liq_fee_bps: 0,
        position_creation_fee_sui: 0,
        version: MODULE_VERSION,
    };
    transfer::share_object(config);

    (lend_facil_cap_id, access::new_request(ACreateConfig {}, ctx))
}

public fun pool_object_id(config: &PositionConfig): ID {
    config.pool_object_id
}

public fun allow_new_positions(config: &PositionConfig): bool {
    config.allow_new_positions
}

public(package) fun lend_facil_cap(config: &PositionConfig): &LendFacilCap {
    &config.lend_facil_cap
}

public fun min_liq_start_price_delta_bps(config: &PositionConfig): u16 {
    config.min_liq_start_price_delta_bps
}

public fun min_init_margin_bps(config: &PositionConfig): u16 {
    config.min_init_margin_bps
}

public fun allowed_oracles(config: &PositionConfig): &Bag {
    &config.allowed_oracles
}

public fun deleverage_margin_bps(config: &PositionConfig): u16 {
    config.deleverage_margin_bps
}

public fun base_deleverage_factor_bps(config: &PositionConfig): u16 {
    config.base_deleverage_factor_bps
}

public fun liq_margin_bps(config: &PositionConfig): u16 {
    config.liq_margin_bps
}

public fun base_liq_factor_bps(config: &PositionConfig): u16 {
    config.base_liq_factor_bps
}

public fun liq_bonus_bps(config: &PositionConfig): u16 {
    config.liq_bonus_bps
}

public fun max_position_l(config: &PositionConfig): u128 {
    config.max_position_l
}

public fun max_global_l(config: &PositionConfig): u128 {
    config.max_global_l
}

public fun current_global_l(config: &PositionConfig): u128 {
    config.current_global_l
}

public fun rebalance_fee_bps(config: &PositionConfig): u16 {
    config.rebalance_fee_bps
}

public fun liq_fee_bps(config: &PositionConfig): u16 {
    config.liq_fee_bps
}

public fun position_creation_fee_sui(config: &PositionConfig): u64 {
    config.position_creation_fee_sui
}

public(package) fun increase_current_global_l(config: &mut PositionConfig, delta_l: u128) {
    config.current_global_l = config.current_global_l + delta_l;
}

public(package) fun decrease_current_global_l(config: &mut PositionConfig, delta_l: u128) {
    config.current_global_l = config.current_global_l - delta_l;
}

public fun set_allow_new_positions(
    config: &mut PositionConfig,
    value: bool,
    ctx: &mut TxContext,
): ActionRequest {
    config.allow_new_positions = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_min_liq_start_price_delta_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    config.min_liq_start_price_delta_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_min_init_margin_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    config.min_init_margin_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun config_add_empty_pyth_config(
    config: &mut PositionConfig,
    ctx: &mut TxContext,
): ActionRequest {
    let pyth_config = PythConfig {
        max_age_secs: 0,
        pio_allowlist: vec_map::empty(),
    };
    config.allowed_oracles.add(type_name::with_defining_ids<PythConfig>(), pyth_config);

    access::new_request(AModifyConfig {}, ctx)
}

public fun set_pyth_config_max_age_secs(
    config: &mut PositionConfig,
    max_age_secs: u64,
    ctx: &mut TxContext,
): ActionRequest {
    let pyth_config: &mut PythConfig =
        &mut config.allowed_oracles[type_name::with_defining_ids<PythConfig>()];
    pyth_config.max_age_secs = max_age_secs;
    access::new_request(AModifyConfig {}, ctx)
}

public fun pyth_config_allow_pio(
    config: &mut PositionConfig,
    coin_type: TypeName,
    pio_id: ID,
    ctx: &mut TxContext,
): ActionRequest {
    let pyth_config: &mut PythConfig =
        &mut config.allowed_oracles[type_name::with_defining_ids<PythConfig>()];
    pyth_config.pio_allowlist.insert(coin_type, pio_id);
    access::new_request(AModifyConfig {}, ctx)
}

public fun pyth_config_disallow_pio(
    config: &mut PositionConfig,
    coin_type: TypeName,
    ctx: &mut TxContext,
): ActionRequest {
    let pyth_config: &mut PythConfig =
        &mut config.allowed_oracles[type_name::with_defining_ids<PythConfig>()];
    pyth_config.pio_allowlist.remove(&coin_type);
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_deleverage_margin_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    assert!(value > config.liq_margin_bps, EInvalidMarginValue);
    config.deleverage_margin_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_base_deleverage_factor_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    config.base_deleverage_factor_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_liq_margin_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    assert!(value < config.deleverage_margin_bps, EInvalidMarginValue);
    config.liq_margin_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_base_liq_factor_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    config.base_liq_factor_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_liq_bonus_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    config.liq_bonus_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_max_position_l(
    config: &mut PositionConfig,
    value: u128,
    ctx: &mut TxContext,
): ActionRequest {
    config.max_position_l = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_max_global_l(
    config: &mut PositionConfig,
    value: u128,
    ctx: &mut TxContext,
): ActionRequest {
    config.max_global_l = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_rebalance_fee_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    config.rebalance_fee_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_liq_fee_bps(
    config: &mut PositionConfig,
    value: u16,
    ctx: &mut TxContext,
): ActionRequest {
    config.liq_fee_bps = value;
    access::new_request(AModifyConfig {}, ctx)
}

public fun set_position_creation_fee_sui(
    config: &mut PositionConfig,
    value: u64,
    ctx: &mut TxContext,
): ActionRequest {
    config.position_creation_fee_sui = value;
    access::new_request(AModifyConfig {}, ctx)
}

/* ================= config extensions ================= */

public struct LiquidationDisabledKey() has copy, drop, store;
public struct ReductionDisabledKey() has copy, drop, store;
public struct AddLiquidityDisabledKey() has copy, drop, store;
public struct OwnerCollectFeeDisabledKey() has copy, drop, store;
public struct OwnerCollectRewardDisabledKey() has copy, drop, store;
public struct DeletePositionDisabledKey() has copy, drop, store;
public struct PositionCreateWithdrawLimiterKey() has copy, drop, store;

fun upsert_config_extension<Key: copy + drop + store, Val: store + drop>(
    config: &mut PositionConfig,
    key: Key,
    new_value: Val,
    ctx: &mut TxContext,
): ActionRequest {
    check_config_version(config);

    if (df::exists_(&config.id, key)) {
        let val = df::borrow_mut<Key, Val>(&mut config.id, key);
        *val = new_value;
    } else {
        df::add(&mut config.id, key, new_value);
    };

    access::new_request(AModifyConfig {}, ctx)
}

fun add_config_extension<Key: copy + drop + store, Val: store>(
    config: &mut PositionConfig,
    key: Key,
    new_value: Val,
    ctx: &mut TxContext,
): ActionRequest {
    check_config_version(config);

    df::add(&mut config.id, key, new_value);
    access::new_request(AModifyConfig {}, ctx)
}

fun has_config_extension<Key: copy + drop + store>(config: &PositionConfig, key: Key): bool {
    check_config_version(config);
    df::exists_(&config.id, key)
}

fun borrow_config_extension<Key: copy + drop + store, Val: store>(
    config: &PositionConfig,
    key: Key,
): &Val {
    check_config_version(config);
    df::borrow<Key, Val>(&config.id, key)
}

fun get_config_extension_or_default<Key: copy + drop + store, Val: copy + drop + store>(
    config: &PositionConfig,
    key: Key,
    default_value: Val,
): Val {
    check_config_version(config);

    if (df::exists_(&config.id, key)) {
        *df::borrow<Key, Val>(&config.id, key)
    } else {
        default_value
    }
}

fun config_extension_mut<Key: copy + drop + store, Val: store>(
    config: &mut PositionConfig,
    key: Key,
): &mut Val {
    check_config_version(config);
    df::borrow_mut<Key, Val>(&mut config.id, key)
}

public fun set_liquidation_disabled(
    config: &mut PositionConfig,
    disabled: bool,
    ctx: &mut TxContext,
): ActionRequest {
    upsert_config_extension(config, LiquidationDisabledKey(), disabled, ctx)
}

public fun liquidation_disabled(config: &PositionConfig): bool {
    get_config_extension_or_default(config, LiquidationDisabledKey(), false)
}

public fun set_reduction_disabled(
    config: &mut PositionConfig,
    disabled: bool,
    ctx: &mut TxContext,
): ActionRequest {
    upsert_config_extension(config, ReductionDisabledKey(), disabled, ctx)
}

public fun reduction_disabled(config: &PositionConfig): bool {
    get_config_extension_or_default(config, ReductionDisabledKey(), false)
}

public fun set_add_liquidity_disabled(
    config: &mut PositionConfig,
    disabled: bool,
    ctx: &mut TxContext,
): ActionRequest {
    upsert_config_extension(config, AddLiquidityDisabledKey(), disabled, ctx)
}

public fun add_liquidity_disabled(config: &PositionConfig): bool {
    get_config_extension_or_default(config, AddLiquidityDisabledKey(), false)
}

public fun set_owner_collect_fee_disabled(
    config: &mut PositionConfig,
    disabled: bool,
    ctx: &mut TxContext,
): ActionRequest {
    upsert_config_extension(config, OwnerCollectFeeDisabledKey(), disabled, ctx)
}

public fun owner_collect_fee_disabled(config: &PositionConfig): bool {
    get_config_extension_or_default(config, OwnerCollectFeeDisabledKey(), false)
}

public fun set_owner_collect_reward_disabled(
    config: &mut PositionConfig,
    disabled: bool,
    ctx: &mut TxContext,
): ActionRequest {
    upsert_config_extension(config, OwnerCollectRewardDisabledKey(), disabled, ctx)
}

public fun owner_collect_reward_disabled(config: &PositionConfig): bool {
    get_config_extension_or_default(config, OwnerCollectRewardDisabledKey(), false)
}

public fun set_delete_position_disabled(
    config: &mut PositionConfig,
    disabled: bool,
    ctx: &mut TxContext,
): ActionRequest {
    upsert_config_extension(config, DeletePositionDisabledKey(), disabled, ctx)
}

public fun delete_position_disabled(config: &PositionConfig): bool {
    get_config_extension_or_default(config, DeletePositionDisabledKey(), false)
}

public fun add_create_withdraw_limiter<L: store>(
    config: &mut PositionConfig,
    rate_limiter: L,
    ctx: &mut TxContext,
): ActionRequest {
    add_config_extension(config, PositionCreateWithdrawLimiterKey(), rate_limiter, ctx)
}

public(package) fun has_create_withdraw_limiter(config: &PositionConfig): bool {
    has_config_extension(config, PositionCreateWithdrawLimiterKey())
}

public(package) fun borrow_create_withdraw_limiter(config: &PositionConfig): &NetSlidingSumLimiter {
    borrow_config_extension(config, PositionCreateWithdrawLimiterKey())
}

public(package) fun borrow_create_withdraw_limiter_mut(
    config: &mut PositionConfig,
): &mut NetSlidingSumLimiter {
    config_extension_mut(config, PositionCreateWithdrawLimiterKey())
}

public fun set_max_create_withdraw_net_inflow_and_outflow_limits(
    config: &mut PositionConfig,
    max_net_inflow_limit: Option<u256>,
    max_net_outflow_limit: Option<u256>,
    ctx: &mut TxContext,
): ActionRequest {
    check_config_version(config);

    let rate_limiter = config.borrow_create_withdraw_limiter_mut();
    rate_limiter.set_max_net_inflow_limit(max_net_inflow_limit);
    rate_limiter.set_max_net_outflow_limit(max_net_outflow_limit);

    access::new_request(AModifyConfig {}, ctx)
}

/* ================= DeleverageTicket ================= */

public struct DeleverageTicket {
    position_id: ID,
    can_repay_x: bool,
    can_repay_y: bool,
    info: DeleverageInfo,
}

public(package) fun deleverage_ticket_constructor(
    position_id: ID,
    can_repay_x: bool,
    can_repay_y: bool,
    info: DeleverageInfo,
): DeleverageTicket {
    DeleverageTicket { position_id, can_repay_x, can_repay_y, info }
}

public(package) fun dt_position_id(self: &DeleverageTicket): ID {
    self.position_id
}

public(package) fun dt_can_repay_x(self: &DeleverageTicket): bool {
    self.can_repay_x
}

public(package) fun dt_can_repay_y(self: &DeleverageTicket): bool {
    self.can_repay_y
}

public(package) fun dt_info(self: &DeleverageTicket): &DeleverageInfo {
    &self.info
}

/* ================= ReductionRepaymentTicket ================= */

public struct ReductionRepaymentTicket<phantom SX, phantom SY> {
    sx: FacilDebtShare<SX>,
    sy: FacilDebtShare<SY>,
    info: ReductionInfo,
}

public(package) fun reduction_repayment_ticket_constructor<SX, SY>(
    sx: FacilDebtShare<SX>,
    sy: FacilDebtShare<SY>,
    info: ReductionInfo,
): ReductionRepaymentTicket<SX, SY> {
    ReductionRepaymentTicket { sx, sy, info }
}

public(package) fun rrt_sx<SX, SY>(self: &ReductionRepaymentTicket<SX, SY>): &FacilDebtShare<SX> {
    &self.sx
}

public(package) fun rrt_sy<SX, SY>(self: &ReductionRepaymentTicket<SX, SY>): &FacilDebtShare<SY> {
    &self.sy
}

public(package) fun rrt_info<SX, SY>(self: &ReductionRepaymentTicket<SX, SY>): &ReductionInfo {
    &self.info
}

/* ================= RebalanceReceipt ================= */

public struct RebalanceReceipt {
    id: ID,
    position_id: ID,
    /// The amount of X collected from AMM fees (before fees are taken).
    collected_amm_fee_x: u64,
    /// The amount of Y collected from AMM fees (before fees are taken).
    collected_amm_fee_y: u64,
    /// The amount other AMM rewards collected (before fees are taken).
    collected_amm_rewards: VecMap<TypeName, u64>,
    /// The amount fees taken from collected rewards (both AMM fees and AMM rewards).
    fees_taken: VecMap<TypeName, u64>,
    /// The amount of X taken from cx.
    taken_cx: u64,
    /// The amount of Y taken from cy.
    taken_cy: u64,
    /// The amount of liquidity added to the LP position.
    delta_l: u128,
    /// The amount of X added to the LP position (corresponds to delta_l).
    delta_x: u64,
    /// The amount of Y added to the LP position (corresponds to delta_l).
    delta_y: u64,
    /// The amount of X debt repaid.
    x_repaid: u64,
    /// The amount of Y debt repaid.
    y_repaid: u64,
    /// The amount of X added to cx.
    added_cx: u64,
    /// The amount of Y added to cy.
    added_cy: u64,
    /// The amount rewards stashed back into the position.
    stashed_amm_rewards: VecMap<TypeName, u64>,
}

public(package) fun rr_position_id(self: &RebalanceReceipt): ID {
    self.position_id
}

public(package) fun increase_collected_amm_fee_x(self: &mut RebalanceReceipt, delta: u64) {
    self.collected_amm_fee_x = self.collected_amm_fee_x + delta;
}

public(package) fun increase_collected_amm_fee_y(self: &mut RebalanceReceipt, delta: u64) {
    self.collected_amm_fee_y = self.collected_amm_fee_y + delta;
}

public(package) fun collected_amm_rewards_mut(
    self: &mut RebalanceReceipt,
): &mut VecMap<TypeName, u64> {
    &mut self.collected_amm_rewards
}

public(package) fun increase_delta_l(self: &mut RebalanceReceipt, delta: u128) {
    self.delta_l = self.delta_l + delta;
}

public(package) fun increase_delta_x(self: &mut RebalanceReceipt, delta: u64) {
    self.delta_x = self.delta_x + delta;
}

public(package) fun increase_delta_y(self: &mut RebalanceReceipt, delta: u64) {
    self.delta_y = self.delta_y + delta;
}

public(package) fun rr_collected_amm_fee_x(self: &RebalanceReceipt): u64 {
    self.collected_amm_fee_x
}

public(package) fun rr_collected_amm_fee_y(self: &RebalanceReceipt): u64 {
    self.collected_amm_fee_y
}

public(package) fun rr_collected_amm_rewards(self: &RebalanceReceipt): &VecMap<TypeName, u64> {
    &self.collected_amm_rewards
}

public(package) fun rr_fees_taken(self: &RebalanceReceipt): &VecMap<TypeName, u64> {
    &self.fees_taken
}

public(package) fun rr_taken_cx(self: &RebalanceReceipt): u64 {
    self.taken_cx
}

public(package) fun rr_taken_cy(self: &RebalanceReceipt): u64 {
    self.taken_cy
}

public(package) fun rr_delta_l(self: &RebalanceReceipt): u128 {
    self.delta_l
}

public(package) fun rr_delta_x(self: &RebalanceReceipt): u64 {
    self.delta_x
}

public(package) fun rr_delta_y(self: &RebalanceReceipt): u64 {
    self.delta_y
}

public(package) fun rr_x_repaid(self: &RebalanceReceipt): u64 {
    self.x_repaid
}

public(package) fun rr_y_repaid(self: &RebalanceReceipt): u64 {
    self.y_repaid
}

public(package) fun rr_added_cx(self: &RebalanceReceipt): u64 {
    self.added_cx
}

public(package) fun rr_added_cy(self: &RebalanceReceipt): u64 {
    self.added_cy
}

public(package) fun rr_stashed_amm_rewards(self: &RebalanceReceipt): &VecMap<TypeName, u64> {
    &self.stashed_amm_rewards
}

/* ================= CreatePositionTicket ================= */

public(package) fun new_create_position_ticket<X, Y, I32>(
    config_id: ID,
    tick_a: I32,
    tick_b: I32,
    dx: u64,
    dy: u64,
    delta_l: u128,
    principal_x: Balance<X>,
    principal_y: Balance<Y>,
    borrowed_x: Balance<X>,
    borrowed_y: Balance<Y>,
    debt_bag: FacilDebtBag,
): CreatePositionTicket<X, Y, I32> {
    CreatePositionTicket {
        config_id,
        tick_a,
        tick_b,
        dx,
        dy,
        delta_l,
        principal_x,
        principal_y,
        borrowed_x,
        borrowed_y,
        debt_bag,
    }
}

public(package) fun destroy_create_position_ticket<X, Y, I32>(
    ticket: CreatePositionTicket<X, Y, I32>,
): (ID, I32, I32, u64, u64, u128, Balance<X>, Balance<Y>, Balance<X>, Balance<Y>, FacilDebtBag) {
    let CreatePositionTicket {
        config_id,
        tick_a,
        tick_b,
        dx,
        dy,
        delta_l,
        principal_x,
        principal_y,
        borrowed_x,
        borrowed_y,
        debt_bag,
    } = ticket;

    (
        config_id,
        tick_a,
        tick_b,
        dx,
        dy,
        delta_l,
        principal_x,
        principal_y,
        borrowed_x,
        borrowed_y,
        debt_bag,
    )
}

public(package) fun cpt_config_id<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): ID {
    ticket.config_id
}

public(package) fun dx<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): u64 {
    ticket.dx
}

public(package) fun dy<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): u64 {
    ticket.dy
}

public(package) fun borrowed_x<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): &Balance<X> {
    &ticket.borrowed_x
}

public(package) fun borrowed_x_mut<X, Y, I32>(
    ticket: &mut CreatePositionTicket<X, Y, I32>,
): &mut Balance<X> {
    &mut ticket.borrowed_x
}

public(package) fun borrowed_y<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): &Balance<Y> {
    &ticket.borrowed_y
}

public(package) fun borrowed_y_mut<X, Y, I32>(
    ticket: &mut CreatePositionTicket<X, Y, I32>,
): &mut Balance<Y> {
    &mut ticket.borrowed_y
}

public(package) fun delta_l<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): u128 {
    ticket.delta_l
}

public(package) fun principal_x<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): &Balance<X> {
    &ticket.principal_x
}

public(package) fun principal_y<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): &Balance<Y> {
    &ticket.principal_y
}

public(package) fun cpt_debt_bag<X, Y, I32>(
    ticket: &CreatePositionTicket<X, Y, I32>,
): &FacilDebtBag {
    &ticket.debt_bag
}

public(package) fun cpt_debt_bag_mut<X, Y, I32>(
    ticket: &mut CreatePositionTicket<X, Y, I32>,
): &mut FacilDebtBag {
    &mut ticket.debt_bag
}

public(package) fun cpt_tick_a<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): &I32 {
    &ticket.tick_a
}

public(package) fun cpt_tick_b<X, Y, I32>(ticket: &CreatePositionTicket<X, Y, I32>): &I32 {
    &ticket.tick_b
}

/* ================= DeletedPositionCollectedFees ================= */

public struct DeletedPositionCollectedFees has key {
    id: UID,
    position_id: ID,
    balance_bag: BalanceBag,
}

public(package) fun share_deleted_position_collected_fees(
    position_id: ID,
    balance_bag: BalanceBag,
    ctx: &mut TxContext,
) {
    let id = object::new(ctx);
    transfer::share_object(DeletedPositionCollectedFees { id, position_id, balance_bag });
}

/* ================= PositionCreationInfo ================= */

public struct PositionCreationInfo has copy, drop {
    position_id: ID,
    config_id: ID,
    sqrt_pa_x64: u128,
    sqrt_pb_x64: u128,
    l: u128,
    x0: u64,
    y0: u64,
    cx: u64,
    cy: u64,
    dx: u64,
    dy: u64,
    creation_fee_amt_sui: u64,
}

public(package) fun emit_position_creation_info(
    position_id: ID,
    config_id: ID,
    sqrt_pa_x64: u128,
    sqrt_pb_x64: u128,
    l: u128,
    x0: u64,
    y0: u64,
    cx: u64,
    cy: u64,
    dx: u64,
    dy: u64,
    creation_fee_amt_sui: u64,
) {
    let info = PositionCreationInfo {
        position_id,
        config_id,
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        x0,
        y0,
        cx,
        cy,
        dx,
        dy,
        creation_fee_amt_sui,
    };
    event::emit(info);
}

/* ================= DeleverageInfo ================= */

public struct DeleverageInfo has copy, drop {
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    sqrt_pool_price_x64: u128,
    /// The amount of L removed from the LP position.
    delta_l: u128,
    /// The amount of X withdrawn from the LP position (corresponds to delta_l),
    /// and added to cx.
    delta_x: u64,
    /// The amount of Y withdrawn from the LP position (corresponds to delta_l),
    /// and added to cy.
    delta_y: u64,
    /// The amount of X debt repaid with cx.
    x_repaid: u64,
    /// The amount of Y debt repaid with cy.
    y_repaid: u64,
}

public(package) fun deleverage_info_constructor(
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    sqrt_pool_price_x64: u128,
    delta_l: u128,
    delta_x: u64,
    delta_y: u64,
    x_repaid: u64,
    y_repaid: u64,
): DeleverageInfo {
    DeleverageInfo {
        position_id,
        model,
        oracle_price_x128,
        sqrt_pool_price_x64,
        delta_l,
        delta_x,
        delta_y,
        x_repaid,
        y_repaid,
    }
}

public(package) fun set_delta_l(info: &mut DeleverageInfo, delta_l: u128) {
    info.delta_l = delta_l;
}

public(package) fun set_delta_x(info: &mut DeleverageInfo, delta_x: u64) {
    info.delta_x = delta_x;
}

public(package) fun set_delta_y(info: &mut DeleverageInfo, delta_y: u64) {
    info.delta_y = delta_y;
}

public(package) fun di_position_id(self: &DeleverageInfo): ID {
    self.position_id
}

public(package) fun di_model(self: &DeleverageInfo): PositionModel {
    self.model
}

public(package) fun di_oracle_price_x128(self: &DeleverageInfo): u256 {
    self.oracle_price_x128
}

public(package) fun di_sqrt_pool_price_x64(self: &DeleverageInfo): u128 {
    self.sqrt_pool_price_x64
}

public(package) fun di_delta_l(self: &DeleverageInfo): u128 {
    self.delta_l
}

public(package) fun di_delta_x(self: &DeleverageInfo): u64 {
    self.delta_x
}

public(package) fun di_delta_y(self: &DeleverageInfo): u64 {
    self.delta_y
}

public(package) fun di_x_repaid(self: &DeleverageInfo): u64 {
    self.x_repaid
}

public(package) fun di_y_repaid(self: &DeleverageInfo): u64 {
    self.y_repaid
}

/* ================= LiquidationInfo ================= */

public struct LiquidationInfo has copy, drop {
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    /// The amount of X debt repaid, using the inputted repayment `Balance<X>`.
    x_repaid: u64,
    /// The amount of Y debt repaid, using the inputted repayment `Balance<Y>`.
    y_repaid: u64,
    /// The amount of X the liquidator receives for `y_repaid` (after fees), taken from cx.
    liquidator_reward_x: u64,
    /// The amount of Y the liquidator receives for `x_repaid` (after fees), taken from cy.
    liquidator_reward_y: u64,
    /// The liquidation fee taken before returning `liquidator_reward_x` to the liquidator.
    liquidation_fee_x: u64,
    /// The liquidation fee taken before returning `liquidator_reward_y` to the liquidator.
    liquidation_fee_y: u64,
}

public(package) fun emit_liquidation_info(
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    x_repaid: u64,
    y_repaid: u64,
    liquidator_reward_x: u64,
    liquidator_reward_y: u64,
    liquidation_fee_x: u64,
    liquidation_fee_y: u64,
) {
    let info = LiquidationInfo {
        position_id,
        model,
        oracle_price_x128,
        x_repaid,
        y_repaid,
        liquidator_reward_x,
        liquidator_reward_y,
        liquidation_fee_x,
        liquidation_fee_y,
    };
    event::emit(info);
}

/* ================= ReductionInfo ================= */

public struct ReductionInfo has copy, drop {
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    sqrt_pool_price_x64: u128,
    /// The amount of L removed from the LP position.
    delta_l: u128,
    /// The amount of X withdrawn from the LP position (corresponds to delta_l).
    delta_x: u64,
    /// The amount of Y withdrawn from the LP position (corresponds to delta_l).
    delta_y: u64,
    /// The total amount of X returned from the position (delta_x + cx).
    withdrawn_x: u64,
    /// The total amount of Y returned from the position (delta_y + cy).
    withdrawn_y: u64,
    /// The amount X debt repaid.
    x_repaid: u64,
    /// The amount Y debt repaid.
    y_repaid: u64,
}

public(package) fun reduction_info_constructor(
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    sqrt_pool_price_x64: u128,
    delta_l: u128,
    delta_x: u64,
    delta_y: u64,
    withdrawn_x: u64,
    withdrawn_y: u64,
    x_repaid: u64,
    y_repaid: u64,
): ReductionInfo {
    ReductionInfo {
        position_id,
        model,
        oracle_price_x128,
        sqrt_pool_price_x64,
        delta_l,
        delta_x,
        delta_y,
        withdrawn_x,
        withdrawn_y,
        x_repaid,
        y_repaid,
    }
}

public(package) fun ri_position_id(self: &ReductionInfo): ID {
    self.position_id
}

public(package) fun ri_model(self: &ReductionInfo): PositionModel {
    self.model
}

public(package) fun ri_oracle_price_x128(self: &ReductionInfo): u256 {
    self.oracle_price_x128
}

public(package) fun ri_sqrt_pool_price_x64(self: &ReductionInfo): u128 {
    self.sqrt_pool_price_x64
}

public(package) fun ri_delta_l(self: &ReductionInfo): u128 {
    self.delta_l
}

public(package) fun ri_delta_x(self: &ReductionInfo): u64 {
    self.delta_x
}

public(package) fun ri_delta_y(self: &ReductionInfo): u64 {
    self.delta_y
}

public(package) fun ri_withdrawn_x(self: &ReductionInfo): u64 {
    self.withdrawn_x
}

public(package) fun ri_withdrawn_y(self: &ReductionInfo): u64 {
    self.withdrawn_y
}

public(package) fun ri_x_repaid(self: &ReductionInfo): u64 {
    self.x_repaid
}

public(package) fun ri_y_repaid(self: &ReductionInfo): u64 {
    self.y_repaid
}

/* ================= AddCollateralInfo ================= */

public struct AddCollateralInfo has copy, drop {
    position_id: ID,
    amount_x: u64,
    amount_y: u64,
}

/* ================= AddLiquidityInfo ================= */

public struct AddLiquidityInfo has copy, drop {
    position_id: ID,
    sqrt_pool_price_x64: u128,
    delta_l: u128,
    delta_x: u64,
    delta_y: u64,
}

public(package) fun add_liquidity_info_constructor(
    position_id: ID,
    sqrt_pool_price_x64: u128,
    delta_l: u128,
    delta_x: u64,
    delta_y: u64,
): AddLiquidityInfo {
    AddLiquidityInfo {
        position_id,
        sqrt_pool_price_x64,
        delta_l,
        delta_x,
        delta_y,
    }
}

public(package) fun ali_emit(info: AddLiquidityInfo) {
    event::emit(info);
}

public(package) fun ali_delta_l(self: &AddLiquidityInfo): u128 {
    self.delta_l
}

public(package) fun ali_delta_x(self: &AddLiquidityInfo): u64 {
    self.delta_x
}

public(package) fun ali_delta_y(self: &AddLiquidityInfo): u64 {
    self.delta_y
}

/* ================= RepayDebtInfo ================= */

public struct RepayDebtInfo has copy, drop {
    position_id: ID,
    x_repaid: u64,
    y_repaid: u64,
}

/* ================= OwnerCollectFeeInfo ================= */

public struct OwnerCollectFeeInfo has copy, drop {
    position_id: ID,
    /// The amount of X fees collected (before fees are taken)
    collected_x_amt: u64,
    /// The amount of Y fees collected (before fees are taken)
    collected_y_amt: u64,
    /// The amount of X fees taken
    fee_amt_x: u64,
    /// The amount of Y fees taken
    fee_amt_y: u64,
}

public(package) fun emit_owner_collect_fee_info(
    position_id: ID,
    collected_x_amt: u64,
    collected_y_amt: u64,
    fee_amt_x: u64,
    fee_amt_y: u64,
) {
    let info = OwnerCollectFeeInfo {
        position_id,
        collected_x_amt,
        collected_y_amt,
        fee_amt_x,
        fee_amt_y,
    };
    event::emit(info);
}

/* ================= OwnerCollectRewardInfo ================= */

public struct OwnerCollectRewardInfo<phantom T> has copy, drop {
    position_id: ID,
    /// The amount of rewards collected (before fees are taken)
    collected_reward_amt: u64,
    /// The amount of fees taken
    fee_amt: u64,
}

public(package) fun emit_owner_collect_reward_info<T>(
    position_id: ID,
    collected_reward_amt: u64,
    fee_amt: u64,
) {
    let info = OwnerCollectRewardInfo<T> { position_id, collected_reward_amt, fee_amt };
    event::emit(info);
}

/* ================= OwnerTakeStahedRewards ================= */

public struct OwnerTakeStashedRewardsInfo<phantom T> has copy, drop {
    position_id: ID,
    amount: u64,
}

/* ================= DeletePositionInfo ================= */

public struct DeletePositionInfo has copy, drop {
    position_id: ID,
    cap_id: ID,
}

public(package) fun emit_delete_position_info(position_id: ID, cap_id: ID) {
    let info = DeletePositionInfo { position_id, cap_id };
    event::emit(info);
}

/* ================= RebalanceInfo ================= */

public struct RebalanceInfo has copy, drop {
    id: ID,
    position_id: ID,
    collected_amm_fee_x: u64,
    collected_amm_fee_y: u64,
    collected_amm_rewards: VecMap<TypeName, u64>,
    fees_taken: VecMap<TypeName, u64>,
    taken_cx: u64,
    taken_cy: u64,
    delta_l: u128,
    delta_x: u64,
    delta_y: u64,
    x_repaid: u64,
    y_repaid: u64,
    added_cx: u64,
    added_cy: u64,
    stashed_amm_rewards: VecMap<TypeName, u64>,
}

/* ================= CollectProtocolFeesInfo ================= */

public struct CollectProtocolFeesInfo<phantom T> has copy, drop {
    position_id: ID,
    amount: u64,
}

public struct DeletedPositionCollectedFeesInfo has copy, drop {
    position_id: ID,
    amounts: VecMap<TypeName, u64>,
}

/* ================= BadDebtRepaid ================= */

public struct BadDebtRepaid<phantom ST> has copy, drop {
    position_id: ID,
    shares_repaid: u128,
    balance_repaid: u64,
}

public(package) fun emit_bad_debt_repaid<T>(
    position_id: ID,
    shares_repaid: u128,
    balance_repaid: u64,
) {
    event::emit(BadDebtRepaid<T> { position_id, shares_repaid, balance_repaid });
}

/* ================= upgrade ================= */

public(package) fun check_config_version(config: &PositionConfig) {
    assert!(config.version == MODULE_VERSION, EInvalidConfigVersion);
}

public(package) fun check_position_version<X, Y, LP>(position: &Position<X, Y, LP>) {
    assert!(position.version == MODULE_VERSION, EInvalidPositionVersion);
}

public(package) fun check_versions<X, Y, LP>(
    position: &Position<X, Y, LP>,
    config: &PositionConfig,
) {
    check_config_version(config);
    check_position_version(position);
}

public fun migrate_config(config: &mut PositionConfig, ctx: &mut TxContext): ActionRequest {
    assert!(config.version < MODULE_VERSION, ENotUpgrade);
    config.version = MODULE_VERSION;
    access::new_request(AMigrate {}, ctx)
}

public fun migrate_position<X, Y, LP>(
    position: &mut Position<X, Y, LP>,
    ctx: &mut TxContext,
): ActionRequest {
    assert!(position.version < MODULE_VERSION, ENotUpgrade);
    position.version = MODULE_VERSION;
    access::new_request(AMigrate {}, ctx)
}

/* ================= util ================= */

public(package) fun validate_price_info(
    config: &PositionConfig,
    price_info: &PythPriceInfo,
): ValidatedPythPriceInfo {
    let pyth_config: &PythConfig =
        &config.allowed_oracles[type_name::with_defining_ids<PythConfig>()];
    price_info.validate(pyth_config.max_age_secs, &pyth_config.pio_allowlist)
}

public(package) fun validate_debt_info(
    config: &PositionConfig,
    debt_info: &DebtInfo,
): ValidatedDebtInfo {
    debt_info.validate(object::id(&config.lend_facil_cap))
}

public(package) fun calc_borrow_amt(principal: u64, need_for_position: u64): (u64, u64) {
    if (principal > need_for_position) {
        (0, principal - need_for_position)
    } else {
        (need_for_position - principal, 0)
    }
}

public(package) fun price_deviation_is_acceptable(
    config: &PositionConfig,
    p0_oracle_ema_x128: u256,
    p0_x128: u256,
): bool {
    let delta_bps = (config.min_liq_start_price_delta_bps as u256);
    let pl_x128 = p0_oracle_ema_x128 - (p0_oracle_ema_x128 * delta_bps) / 10000;
    let ph_x128 = p0_oracle_ema_x128 + (p0_oracle_ema_x128 * delta_bps) / 10000;

    if (p0_x128 < pl_x128 || p0_x128 > ph_x128) {
        false
    } else {
        true
    }
}

public(package) fun liq_margin_is_valid(
    config: &PositionConfig,
    model: &PositionModel,
    p0_min_x128: u256,
    p0_max_x128: u256,
): bool {
    let delta_bps = (config.min_liq_start_price_delta_bps as u256);
    let liq_margin_x64 = (
            (config.liq_margin_bps as u128) << 64
        ) / 10000;
    let pl_x128 = p0_min_x128 - (p0_min_x128 * delta_bps) / 10000;
    let ph_x128 = p0_max_x128 + (p0_max_x128 * delta_bps) / 10000;

    if (model.margin_x64(pl_x128) < liq_margin_x64) {
        return false
    };
    if (model.margin_x64(ph_x128) < liq_margin_x64) {
        return false
    };

    true
}

public(package) fun init_margin_is_valid(
    config: &PositionConfig,
    model: &PositionModel,
    p0_min_x128: u256,
    p0_max_x128: u256,
): bool {
    let min_margin_x64 = (
            (config.min_init_margin_bps as u128) << 64
        ) / 10000;

    if (model.margin_x64(p0_min_x128) < min_margin_x64) {
        return false
    };
    if (model.margin_x64(p0_max_x128) < min_margin_x64) {
        return false
    };

    true
}

public(package) macro fun model_from_position<$X, $Y, $LP>(
    $position: &Position<$X, $Y, $LP>,
    $debt_info: &ValidatedDebtInfo,
): PositionModel {
    let position = $position;
    let debt_info = $debt_info;

    let (tick_a, tick_b) = position.lp_position().tick_range();

    let l = position.lp_position().liquidity();
    let sqrt_pa_x64 = tick_a.as_sqrt_price_x64();
    let sqrt_pb_x64 = tick_b.as_sqrt_price_x64();
    let cx = position.col_x().value();
    let cy = position.col_y().value();

    let sx = position.debt_bag().get_share_amount_by_asset_type<$X>();
    let dx = if (sx > 0) {
        let share_type = position.debt_bag().get_share_type_for_asset<$X>();
        debt_info.calc_repay_by_shares(share_type, sx)
    } else {
        0
    };
    let sy = position.debt_bag().get_share_amount_by_asset_type<$Y>();
    let dy = if (sy > 0) {
        let share_type = position.debt_bag().get_share_type_for_asset<$Y>();
        debt_info.calc_repay_by_shares(share_type, sy)
    } else {
        0
    };

    position_model_clmm::create(
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx,
        cy,
        dx,
        dy,
    )
}

public(package) macro fun slippage_tolerance_assertion(
    $pool_object: _,
    $p0_desired_x128: u256,
    $max_slippage_bps: u16,
) {
    let pool = $pool_object;

    let sqrt_p0_x64 = pool.current_sqrt_price_x64();
    let p0_x64 = ((sqrt_p0_x64 as u256) * (sqrt_p0_x64 as u256)) >> 64;
    let p0_desired_x64 = $p0_desired_x128 >> 64;
    let p0_x64_max = p0_desired_x64 + ((p0_desired_x64 * ($max_slippage_bps as u256)) / 10000);
    let p0_x64_min = p0_desired_x64 - ((p0_desired_x64 * ($max_slippage_bps as u256)) / 10000);

    if (p0_x64 < p0_x64_min || p0_x64 > p0_x64_max) {
        false
    } else {
        true
    };

    assert!(p0_x64 >= p0_x64_min && p0_x64 <= p0_x64_max, e_slippage_exceeded!());
}

public(package) fun get_amount_ema_usd_value_6_decimals<T>(
    amount: u64,
    price_info: &ValidatedPythPriceInfo,
    round_up: bool,
): u64 {
    let t = type_name::with_defining_ids<T>();
    let price = price_info.get_ema_price(t);

    let p = pyth_i64::get_magnitude_if_positive(&price.get_price()) as u128;
    let expo = pyth_i64::get_magnitude_if_negative(&price.get_expo()) as u8;
    let dec = pyth::decimals(t);

    let num = p * (amount as u128);
    (if (expo + dec > 6) {
            if (round_up) {
                std::macros::num_divide_and_round_up!(num, 10_u128.pow(expo + dec - 6))
            } else {
                num / 10_u128.pow(expo + dec - 6)
            }
        } else {
            num * 10_u128.pow(6 - (expo + dec))
        }) as u64
}

public(package) fun get_balance_ema_usd_value_6_decimals<T>(
    balance: &Balance<T>,
    price_info: &ValidatedPythPriceInfo,
    round_up: bool,
): u64 {
    get_amount_ema_usd_value_6_decimals<T>(balance.value(), price_info, round_up)
}

/* ================= position creation ================= */

public(package) macro fun create_position_ticket<$X, $Y, $I32>(
    $pool_object: _,
    $config: &mut PositionConfig,
    // The lower tick of the LP position range
    $tick_a: $I32,
    // The upper tick of the LP position range
    $tick_b: $I32,
    $principal_x: Balance<$X>,
    $principal_y: Balance<$Y>,
    $delta_l: u128,
    $price_info: &PythPriceInfo,
    $clock: &Clock,
    $ctx: &mut TxContext,
): CreatePositionTicket<$X, $Y, $I32> {
    let pool_object = $pool_object;
    let config = $config;
    let tick_a = $tick_a;
    let tick_b = $tick_b;
    let principal_x = $principal_x;
    let principal_y = $principal_y;

    check_config_version(config);
    assert!(config.allow_new_positions(), e_new_positions_not_allowed!());
    assert!(object::id(pool_object) == config.pool_object_id(), e_invalid_pool!());
    let price_info = validate_price_info(config, $price_info);

    if (config.has_create_withdraw_limiter()) {
        let limiter = config.borrow_create_withdraw_limiter_mut();
        let x_value = get_balance_ema_usd_value_6_decimals(&principal_x, &price_info, true);
        let y_value = get_balance_ema_usd_value_6_decimals(&principal_y, &price_info, true);
        limiter.consume_inflow(x_value + y_value, $clock);
    };

    assert!($delta_l <= config.max_position_l(), e_position_size_limit_exceeded!());
    assert!(
        config.current_global_l() + $delta_l <= config.max_global_l(),
        e_vault_global_size_limit_exceeded!(),
    );
    config.increase_current_global_l($delta_l);

    let current_tick = pool_object.current_tick_index();
    let sqrt_p0_x64 = pool_object.current_sqrt_price_x64();

    // assert that the current price is within the range of the LP position
    assert!(tick_a.lte(current_tick), e_invalid_tick_range!());
    assert!(current_tick.lt(tick_b), e_invalid_tick_range!());

    let p0_oracle_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );
    let p0_x128 = (sqrt_p0_x64 as u256) * (sqrt_p0_x64 as u256);

    // validate price deviation
    {
        let p0_oracle_ema_x128 = price_info.div_ema_price_numeric_x128(
            type_name::with_defining_ids<$X>(),
            type_name::with_defining_ids<$Y>(),
        );
        assert!(
            price_deviation_is_acceptable(config, p0_oracle_ema_x128, p0_x128),
            e_price_deviation_too_high!(),
        )
    };

    let p0_min_x128 = util::min_u256(p0_oracle_x128, p0_x128);
    let p0_max_x128 = util::max_u256(p0_oracle_x128, p0_x128);

    // validate position
    let model = {
        let (x0, y0) = pool_object.calc_deposit_amounts_by_liquidity(tick_a, tick_b, $delta_l);
        let (dx, cx) = calc_borrow_amt(principal_x.value(), x0);
        let (dy, cy) = calc_borrow_amt(principal_y.value(), y0);

        let sqrt_pa_x64 = tick_a.as_sqrt_price_x64();
        let sqrt_pb_x64 = tick_b.as_sqrt_price_x64();

        position_model_clmm::create(
            sqrt_pa_x64,
            sqrt_pb_x64,
            $delta_l,
            cx,
            cy,
            dx,
            dy,
        )
    };
    assert!(liq_margin_is_valid(config, &model, p0_min_x128, p0_max_x128), e_liq_margin_too_low!());
    assert!(
        init_margin_is_valid(config, &model, p0_min_x128, p0_max_x128),
        e_initial_margin_too_low!(),
    );

    // create ticket
    let config_id = object::id(config);
    let debt_bag = supply_pool::empty_facil_debt_bag(
        object::id(config.lend_facil_cap()),
        $ctx,
    );
    new_create_position_ticket(
        config_id,
        tick_a,
        tick_b,
        model.dx(),
        model.dy(),
        $delta_l,
        principal_x,
        principal_y,
        balance::zero(),
        balance::zero(),
        debt_bag,
    )
}

public(package) macro fun borrow_for_position_x<$X, $Y, $SX, $I32>(
    $ticket: &mut CreatePositionTicket<$X, $Y, $I32>,
    $config: &PositionConfig,
    $supply_pool: &mut SupplyPool<$X, $SX>,
    $clock: &Clock,
) {
    let ticket = $ticket;
    let config = $config;
    let supply_pool = $supply_pool;

    assert!(ticket.config_id() == object::id(config), e_invalid_config!());
    if (ticket.dx() == ticket.borrowed_x().value()) {
        return
    };

    let (balance, shares) = supply_pool.borrow(config.lend_facil_cap(), ticket.dx(), $clock);
    ticket.borrowed_x_mut().join(balance);

    ticket.debt_bag_mut().add<$X, $SX>(shares);
}

public(package) macro fun borrow_for_position_y<$X, $Y, $SY, $I32>(
    $ticket: &mut CreatePositionTicket<$X, $Y, $I32>,
    $config: &PositionConfig,
    $supply_pool: &mut SupplyPool<$Y, $SY>,
    $clock: &Clock,
) {
    let ticket = $ticket;
    let config = $config;
    let supply_pool = $supply_pool;

    assert!(ticket.config_id() == object::id(config), e_invalid_config!());
    if (ticket.dy() == ticket.borrowed_y().value()) {
        return
    };

    let (balance, shares) = supply_pool.borrow(config.lend_facil_cap(), ticket.dy(), $clock);
    ticket.borrowed_y_mut().join(balance);

    ticket.debt_bag_mut().add<$Y, $SY>(shares);
}

public(package) macro fun create_position<$X, $Y, $I32, $Pool, $LP>(
    $config: &PositionConfig,
    $ticket: CreatePositionTicket<$X, $Y, $I32>,
    $pool_object: &mut $Pool,
    $creation_fee: Balance<SUI>,
    $ctx: &mut TxContext,
    $open_position: |&mut $Pool, $I32, $I32, u128, Balance<$X>, Balance<$Y>| -> $LP,
): PositionCap {
    let config = $config;
    let ticket = $ticket;
    let pool_object = $pool_object;
    let creation_fee = $creation_fee;

    assert!(ticket.config_id() == object::id(config), e_invalid_config!());
    assert!(object::id(pool_object) == config.pool_object_id(), e_invalid_pool!());

    assert!(
        creation_fee.value() == config.position_creation_fee_sui(),
        e_invalid_creation_fee_amount!(),
    );

    assert!(ticket.borrowed_x().value() == ticket.dx(), e_invalid_borrow!());
    assert!(ticket.borrowed_y().value() == ticket.dy(), e_invalid_borrow!());

    let (
        config_id,
        tick_a,
        tick_b,
        dx,
        dy,
        delta_l,
        mut principal_x,
        mut principal_y,
        borrowed_x,
        borrowed_y,
        debt_bag,
    ) = destroy_create_position_ticket(ticket);

    // prepare balances for LP position creation
    let (x0, y0) = pool_object.calc_deposit_amounts_by_liquidity(tick_a, tick_b, delta_l);

    let mut balance_x0 = borrowed_x;
    if (balance_x0.value() < x0) {
        let amt = x0 - balance_x0.value();
        balance_x0.join(principal_x.split(amt));
    };
    let mut balance_y0 = borrowed_y;
    if (balance::value(&balance_y0) < y0) {
        let amt = y0 - balance_y0.value();
        balance_y0.join(principal_y.split(amt));
    };

    // create LP position
    let lp_position = $open_position(
        pool_object,
        tick_a,
        tick_b,
        delta_l,
        balance_x0,
        balance_y0,
    );

    // create position
    let mut collected_fees = balance_bag::empty($ctx);
    collected_fees.add(creation_fee);

    let owner_reward_stash = balance_bag::empty($ctx);

    let col_x = principal_x;
    let col_y = principal_y;
    let position = position_constructor(
        object::id(config),
        lp_position,
        col_x,
        col_y,
        debt_bag,
        collected_fees,
        owner_reward_stash,
        $ctx,
    );

    let cap = position_cap_constructor(object::id(&position), $ctx);

    emit_position_creation_info(
        object::id(&position),
        config_id,
        tick_a.as_sqrt_price_x64(),
        tick_b.as_sqrt_price_x64(),
        delta_l,
        x0,
        y0,
        position.col_x().value(),
        position.col_y().value(),
        dx,
        dy,
        config.position_creation_fee_sui(),
    );

    position.share_object();
    cap
}

/* ================= deleverage and liquidation ================= */

public(package) macro fun create_deleverage_ticket_inner<$X, $Y, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $max_delta_l: u128,
    $is_for_liquidation: bool,
    $remove_liquidity: |&mut $Pool, &mut $LP, u128| -> (Balance<$X>, Balance<$Y>),
): DeleverageTicket {
    let position = $position;
    let config = $config;
    let pool_object = $pool_object;

    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(config.pool_object_id() == object::id(pool_object), e_invalid_pool!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    position.set_ticket_active(true);

    let price_info = validate_price_info(config, $price_info);
    let debt_info = validate_debt_info(config, $debt_info);

    let model = model_from_position!(position, &debt_info);
    let p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );

    let mut info = {
        let position_id = object::id(position);
        let oracle_price_x128 = p_x128;
        let sqrt_pool_price_x64 = pool_object.current_sqrt_price_x64();
        let delta_l = 0;
        let delta_x = 0;
        let delta_y = 0;
        let x_repaid = 0;
        let y_repaid = 0;
        deleverage_info_constructor(
            position_id,
            model,
            oracle_price_x128,
            sqrt_pool_price_x64,
            delta_l,
            delta_x,
            delta_y,
            x_repaid,
            y_repaid,
        )
    };

    let threshold_margin = if ($is_for_liquidation) {
        config.liq_margin_bps()
    } else {
        config.deleverage_margin_bps()
    };
    if (!model.margin_below_threshold(p_x128, threshold_margin)) {
        // return instead of abort helps to avoid tx failures
        let can_repay_x = false;
        let can_repay_y = false;
        let ticket = deleverage_ticket_constructor(
            object::id(position),
            can_repay_x,
            can_repay_y,
            info,
        );
        return ticket
    };

    let delta_l = util::min_u128(
        $max_delta_l,
        model.calc_max_deleverage_delta_l(
            p_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        ),
    );
    let (got_x, got_y) = $remove_liquidity(pool_object, position.lp_position_mut(), delta_l);
    info.set_delta_l(delta_l);
    info.set_delta_x(got_x.value());
    info.set_delta_y(got_y.value());

    position.col_x_mut().join(got_x);
    position.col_y_mut().join(got_y);
    config.decrease_current_global_l(delta_l);

    {
        let can_repay_x = {
            let share_amt = position.debt_bag().get_share_amount_by_asset_type<$X>();
            share_amt > 0 && position.col_x().value() > 0
        };
        let can_repay_y = {
            let share_amt = position.debt_bag().get_share_amount_by_asset_type<$Y>();
            share_amt > 0 && position.col_y().value() > 0
        };
        deleverage_ticket_constructor(object::id(position), can_repay_x, can_repay_y, info)
    }
}

public(package) macro fun create_deleverage_ticket<$X, $Y, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $max_delta_l: u128,
    $ctx: &mut TxContext,
    $remove_liquidity: |&mut $Pool, &mut $LP, u128| -> (Balance<$X>, Balance<$Y>),
): (DeleverageTicket, ActionRequest) {
    check_versions($position, $config);

    let ticket = create_deleverage_ticket_inner!(
        $position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $max_delta_l,
        false,
        $remove_liquidity,
    );
    let request = access::new_request(a_deleverage(), $ctx);

    (ticket, request)
}

public(package) macro fun create_deleverage_ticket_for_liquidation<$X, $Y, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $remove_liquidity: |&mut $Pool, &mut $LP, u128| -> (Balance<$X>, Balance<$Y>),
): DeleverageTicket {
    check_versions($position, $config);

    let config = $config;
    assert!(!config.liquidation_disabled(), e_liquidation_disabled!());

    let u128_max = (((1u256 << 128) - 1) as u128);
    create_deleverage_ticket_inner!(
        $position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        u128_max,
        true,
        $remove_liquidity,
    )
}

public fun deleverage_ticket_repay_x<X, Y, SX, LP: store>(
    position: &mut Position<X, Y, LP>,
    config: &PositionConfig,
    ticket: &mut DeleverageTicket,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
) {
    assert!(ticket.position_id == object::id(position), e_position_mismatch!());
    assert!(position.config_id == config.id.to_inner(), e_invalid_config!());
    if (!ticket.can_repay_x) {
        return
    };
    assert!(
        position.debt_bag().get_share_type_for_asset<X>() == type_name::with_defining_ids<SX>(),
        e_supply_pool_mismatch!(),
    );

    let mut shares = position.debt_bag.take_all();
    let (_, x_repaid) = supply_pool.repay_max_possible(&mut shares, &mut position.col_x, clock);

    position.debt_bag.add<X, SX>(shares);
    ticket.can_repay_x = false;
    ticket.info.x_repaid = x_repaid;
}

public fun deleverage_ticket_repay_y<X, Y, SY, LP: store>(
    position: &mut Position<X, Y, LP>,
    config: &PositionConfig,
    ticket: &mut DeleverageTicket,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
) {
    assert!(ticket.position_id == object::id(position), e_position_mismatch!());
    assert!(position.config_id == config.id.to_inner(), e_invalid_config!());
    if (!ticket.can_repay_y) {
        return
    };
    assert!(
        position.debt_bag().get_share_type_for_asset<Y>() == type_name::with_defining_ids<SY>(),
        e_supply_pool_mismatch!(),
    );

    let mut shares = position.debt_bag.take_all();
    let (_, y_repaid) = supply_pool.repay_max_possible(&mut shares, &mut position.col_y, clock);
    ticket.info.y_repaid = y_repaid;

    position.debt_bag.add<Y, SY>(shares);
    ticket.can_repay_y = false;
}

public fun destroy_deleverage_ticket<X, Y, LP: store>(
    position: &mut Position<X, Y, LP>,
    ticket: DeleverageTicket,
) {
    assert!(ticket.position_id == object::id(position), e_position_mismatch!());
    assert!(ticket.can_repay_x == false, ETicketNotExhausted);
    assert!(ticket.can_repay_y == false, ETicketNotExhausted);
    let DeleverageTicket { position_id: _, can_repay_x: _, can_repay_y: _, info } = ticket;

    position.ticket_active = false;

    if (info.delta_l == 0 && info.x_repaid == 0 && info.y_repaid == 0) {
        // nothing was deleveraged, don't emit event
        return
    } else {
        event::emit(info);
    };
}

public(package) macro fun deleverage<$X, $Y, $SX, $SY, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $price_info: &PythPriceInfo,
    $supply_pool_x: &mut SupplyPool<$X, $SX>,
    $supply_pool_y: &mut SupplyPool<$Y, $SY>,
    $pool_object: &mut $Pool,
    $max_delta_l: u128,
    $clock: &Clock,
    $ctx: &mut TxContext,
    $remove_liquidity: |&mut $Pool, &mut $LP, u128| -> (Balance<$X>, Balance<$Y>),
): ActionRequest {
    let position = $position;
    let config = $config;
    let supply_pool_x = $supply_pool_x;
    let supply_pool_y = $supply_pool_y;

    check_versions(position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<$X, $SX>(),
        e_supply_pool_mismatch!(),
    );
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<$Y, $SY>(),
        e_supply_pool_mismatch!(),
    );

    let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
    debt_info.add_from_supply_pool(supply_pool_x, $clock);
    debt_info.add_from_supply_pool(supply_pool_y, $clock);

    let (mut ticket, request) = create_deleverage_ticket!(
        position,
        config,
        $price_info,
        &debt_info,
        $pool_object,
        $max_delta_l,
        $ctx,
        $remove_liquidity,
    );
    deleverage_ticket_repay_x(position, config, &mut ticket, supply_pool_x, $clock);
    deleverage_ticket_repay_y(position, config, &mut ticket, supply_pool_y, $clock);
    destroy_deleverage_ticket(position, ticket);

    request
}

public(package) macro fun deleverage_for_liquidation<$X, $Y, $SX, $SY, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $price_info: &PythPriceInfo,
    $supply_pool_x: &mut SupplyPool<$X, $SX>,
    $supply_pool_y: &mut SupplyPool<$Y, $SY>,
    $pool_object: &mut $Pool,
    $clock: &Clock,
    $remove_liquidity: |&mut $Pool, &mut $LP, u128| -> (Balance<$X>, Balance<$Y>),
) {
    let position = $position;
    let config = $config;
    let supply_pool_x = $supply_pool_x;
    let supply_pool_y = $supply_pool_y;

    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(!config.liquidation_disabled(), e_liquidation_disabled!());
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<$X, $SX>(),
        e_supply_pool_mismatch!(),
    );
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<$Y, $SY>(),
        e_supply_pool_mismatch!(),
    );

    let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
    debt_info.add_from_supply_pool(supply_pool_x, $clock);
    debt_info.add_from_supply_pool(supply_pool_y, $clock);

    let mut ticket = create_deleverage_ticket_for_liquidation!(
        position,
        config,
        $price_info,
        &debt_info,
        $pool_object,
        $remove_liquidity,
    );
    deleverage_ticket_repay_x(position, config, &mut ticket, supply_pool_x, $clock);
    deleverage_ticket_repay_y(position, config, &mut ticket, supply_pool_y, $clock);
    destroy_deleverage_ticket(position, ticket);
}

public(package) fun calc_liq_fee_from_reward(config: &PositionConfig, reward_amt: u64): u64 {
    util::muldiv(
        reward_amt,
        (config.liq_bonus_bps as u64) * (config.liq_fee_bps as u64),
        (10000 + (config.liq_bonus_bps as u64)) * 10000,
    )
}

public(package) macro fun liquidate_col_x<$X, $Y, $SY, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $repayment: &mut Balance<$Y>,
    $supply_pool: &mut SupplyPool<$Y, $SY>,
    $clock: &Clock,
): Balance<$X> {
    let position = $position;
    let config = $config;
    let repayment = $repayment;
    let supply_pool = $supply_pool;

    check_versions(position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    assert!(!config.liquidation_disabled(), e_liquidation_disabled!());
    let price_info = validate_price_info(config, $price_info);
    let debt_info = validate_debt_info(config, $debt_info);

    let model = model_from_position!(position, &debt_info);
    let p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );

    let (repayment_amt_y, reward_amt_x) = model.calc_liquidate_col_x(
        p_x128,
        repayment.value(),
        config.liq_margin_bps(),
        config.liq_bonus_bps(),
        config.base_liq_factor_bps(),
    );
    if (repayment_amt_y == 0) {
        return balance::zero()
    };
    let mut r = repayment.split(repayment_amt_y);

    assert!(
        type_name::with_defining_ids<$SY>() == position.debt_bag().get_share_type_for_asset<$Y>(),
        e_supply_pool_mismatch!(),
    );

    let mut debt_shares = position.debt_bag_mut().take_all();
    let (_, y_repaid) = supply_pool.repay_max_possible(&mut debt_shares, &mut r, $clock);

    position.debt_bag_mut().add<$Y, $SY>(debt_shares);
    repayment.join(r);

    let mut reward = position.col_x_mut().split(reward_amt_x);
    let fee_amt = calc_liq_fee_from_reward(config, reward_amt_x);
    position.collected_fees_mut().add(reward.split(fee_amt));

    {
        let position_id = object::id(position);
        let oracle_price_x128 = p_x128;
        let x_repaid = 0;
        let liquidator_reward_x = reward.value();
        let liquidator_reward_y = 0;
        let liquidation_fee_x = fee_amt;
        let liquidation_fee_y = 0;

        emit_liquidation_info(
            position_id,
            model,
            oracle_price_x128,
            x_repaid,
            y_repaid,
            liquidator_reward_x,
            liquidator_reward_y,
            liquidation_fee_x,
            liquidation_fee_y,
        );
    };

    reward
}

public(package) macro fun liquidate_col_y<$X, $Y, $SX, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $repayment: &mut Balance<$X>,
    $supply_pool: &mut SupplyPool<$X, $SX>,
    $clock: &Clock,
): Balance<$Y> {
    let position = $position;
    let config = $config;
    let repayment = $repayment;
    let supply_pool = $supply_pool;

    check_versions(position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    assert!(!config.liquidation_disabled(), e_liquidation_disabled!());
    let price_info = validate_price_info(config, $price_info);
    let debt_info = validate_debt_info(config, $debt_info);

    let model = model_from_position!(position, &debt_info);
    let p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );

    let (repayment_amt_x, reward_amt_y) = model.calc_liquidate_col_y(
        p_x128,
        repayment.value(),
        config.liq_margin_bps(),
        config.liq_bonus_bps(),
        config.base_liq_factor_bps(),
    );
    if (repayment_amt_x == 0) {
        return balance::zero()
    };
    let mut r = repayment.split(repayment_amt_x);

    assert!(
        type_name::with_defining_ids<$SX>() == position.debt_bag().get_share_type_for_asset<$X>(),
        e_supply_pool_mismatch!(),
    );

    let mut debt_shares = position.debt_bag_mut().take_all();
    let (_, x_repaid) = supply_pool.repay_max_possible(&mut debt_shares, &mut r, $clock);

    position.debt_bag_mut().add<$X, $SX>(debt_shares);
    repayment.join(r);

    let mut reward = position.col_y_mut().split(reward_amt_y);
    let fee_amt = calc_liq_fee_from_reward(config, reward_amt_y);
    position.collected_fees_mut().add(reward.split(fee_amt));

    {
        let position_id = object::id(position);
        let oracle_price_x128 = p_x128;
        let y_repaid = 0;
        let liquidator_reward_x = 0;
        let liquidator_reward_y = reward.value();
        let liquidation_fee_x = 0;
        let liquidation_fee_y = fee_amt;

        emit_liquidation_info(
            position_id,
            model,
            oracle_price_x128,
            x_repaid,
            y_repaid,
            liquidator_reward_x,
            liquidator_reward_y,
            liquidation_fee_x,
            liquidation_fee_y,
        );
    };

    reward
}

/// If a position falls below the critical margin threshold `(1 + liq_bonus)`, liquidations
/// will not restore the margin level due to the liquidation math and guaranteed liquidation bonus.
/// In this scenario, the position is considered to be in a "bad debt" state, allowing an entity
/// with the `ARepayBadDebt` permission to repay the debt and help restore the position's solvency.
///
/// ### Type Parameters
/// - `$X`: The type of the first asset in the position.
/// - `$Y`: The type of the second asset in the position.
/// - `$T`: The asset type being repaid (must match the supply pool and balance).
/// - `$ST`: The share type for the debt being repaid.
/// - `$LP`: The type of the LP position.
///
/// ### Arguments
/// - `$position`: Mutable reference to the `Position` to repay bad debt for.
/// - `$config`: Reference to the position's `PositionConfig`.
/// - `$price_info`: Reference to the `PriceInfo` object containing info for relevant prices.
/// - `$debt_info`: Reference to the `DebtInfo` object containing info for the position's debt.
/// - `$supply_pool`: Mutable reference to the `SupplyPool` for the debt being repaid.
/// - `$repayment`: Mutable reference to the `Balance` for the debt being repaid.
/// - `$clock`: Reference to the current `Clock`.
/// - `$ctx`: Mutable reference to the `TxContext`.
///
/// ### Returns
/// - `ActionRequest`: An action request representing the bad debt repayment operation.
///
/// ### Aborts
/// - If the position is not fully deleveraged.
/// - If the position is not below the bad debt margin threshold.
/// - If the config and position mismatch.
/// - If the hot-potato ticket is active.
///
/// ### Emits
/// - Emits a `BadDebtRepaid` event if any shares or balance are repaid.
public(package) macro fun repay_bad_debt<$X, $Y, $T, $ST, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $supply_pool: &mut SupplyPool<$T, $ST>,
    $repayment: &mut Balance<$T>,
    $clock: &Clock,
    $ctx: &mut TxContext,
): ActionRequest {
    let position = $position;
    let config = $config;
    let supply_pool = $supply_pool;

    check_versions(position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<$T, $ST>(),
        e_supply_pool_mismatch!(),
    );

    let price_info = validate_price_info(config, $price_info);
    let debt_info = validate_debt_info(config, $debt_info);
    let model = model_from_position!(position, &debt_info);

    assert!(model.is_fully_deleveraged(), e_position_not_fully_deleveraged!());

    let p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );
    let crit_margin_bps = 10000 + config.liq_bonus_bps();
    assert!(
        model.margin_below_threshold(p_x128, crit_margin_bps),
        e_position_not_below_bad_debt_threshold!(),
    );

    let mut debt_shares = position.debt_bag_mut().take_all();
    if (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        return access::new_request(a_repay_bad_debt(), $ctx)
    };
    let (shares_repaid, balance_repaid) = supply_pool.repay_max_possible(
        &mut debt_shares,
        $repayment,
        $clock,
    );
    position.debt_bag_mut().add<$T, $ST>(debt_shares);

    if (shares_repaid > 0 || balance_repaid > 0) {
        emit_bad_debt_repaid<$ST>(object::id(position), shares_repaid, balance_repaid);
    };

    access::new_request(a_repay_bad_debt(), $ctx)
}

/* ================= user operations ================= */

public(package) macro fun reduce<$X, $Y, $SX, $SY, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $cap: &PositionCap,
    $price_info: &PythPriceInfo,
    $supply_pool_x: &mut SupplyPool<$X, $SX>,
    $supply_pool_y: &mut SupplyPool<$Y, $SY>,
    $pool_object: &mut $Pool,
    $factor_x64: u128,
    $clock: &Clock,
    $remove_liquidity: |&mut $Pool, &mut $LP, u128| -> (Balance<$X>, Balance<$Y>),
): (Balance<$X>, Balance<$Y>, ReductionRepaymentTicket<$SX, $SY>) {
    let position = $position;
    let config = $config;
    let cap = $cap;
    let pool_object = $pool_object;
    let supply_pool_x = $supply_pool_x;
    let supply_pool_y = $supply_pool_y;

    check_versions(position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(config.pool_object_id() == object::id(pool_object), e_invalid_pool!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    assert!(cap.position_id() == object::id(position), e_invalid_position_cap!());
    assert!(!config.reduction_disabled(), e_reduction_disabled!());
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<$X, $SX>(),
        e_supply_pool_mismatch!(),
    );
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<$Y, $SY>(),
        e_supply_pool_mismatch!(),
    );

    let price_info = validate_price_info(config, $price_info);

    let oracle_price_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );
    let sqrt_pool_price_x64 = pool_object.current_sqrt_price_x64();
    let pool_price_x128 = (sqrt_pool_price_x64 as u256) * (sqrt_pool_price_x64 as u256);

    let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
    debt_info.add_from_supply_pool(supply_pool_x, $clock);
    debt_info.add_from_supply_pool(supply_pool_y, $clock);
    let model = model_from_position!(position, &validate_debt_info(config, &debt_info));

    assert!(
        !model.margin_below_threshold(oracle_price_x128, config.liq_margin_bps()),
        e_position_below_threshold!(),
    );
    assert!(
        !model.margin_below_threshold(pool_price_x128, config.liq_margin_bps()),
        e_position_below_threshold!(),
    );

    let l = position.lp_position().liquidity();
    let delta_l = util::muldiv_u128($factor_x64, l, 1 << 64);
    let delta_cx = {
        let cx = position.col_x().value() as u128;
        util::muldiv_u128($factor_x64, cx, 1 << 64) as u64
    };
    let delta_cy = {
        let cy = position.col_y().value() as u128;
        util::muldiv_u128($factor_x64, cy, 1 << 64) as u64
    };
    let delta_shares_x = {
        let share_amt = position.debt_bag().get_share_amount_by_asset_type<$X>();
        util::muldiv_u128($factor_x64, share_amt, 1 << 64)
    };
    let delta_shares_y = {
        let share_amt = position.debt_bag().get_share_amount_by_asset_type<$Y>();
        util::muldiv_u128($factor_x64, share_amt, 1 << 64)
    };

    let (mut got_x, mut got_y) = $remove_liquidity(
        pool_object,
        position.lp_position_mut(),
        delta_l,
    );
    let delta_x = got_x.value();
    let delta_y = got_y.value();

    got_x.join(position.col_x_mut().split(delta_cx));
    got_y.join(position.col_y_mut().split(delta_cy));
    config.decrease_current_global_l(delta_l);

    let sx = position.debt_bag_mut().take_amt(delta_shares_x);
    let sy = position.debt_bag_mut().take_amt(delta_shares_y);

    // calculate the inflow and outflow of the position
    if (config.has_create_withdraw_limiter()) {
        let limiter = config.borrow_create_withdraw_limiter_mut();

        let dx = supply_pool_x.calc_repay_by_shares(sx.facil_id(), sx.value_x64(), $clock);
        let dy = supply_pool_y.calc_repay_by_shares(sy.facil_id(), sy.value_x64(), $clock);

        let x_value = get_balance_ema_usd_value_6_decimals(&got_x, &price_info, true);
        let y_value = get_balance_ema_usd_value_6_decimals(&got_y, &price_info, true);
        let dx_value = get_amount_ema_usd_value_6_decimals<$X>(dx, &price_info, true);
        let dy_value = get_amount_ema_usd_value_6_decimals<$Y>(dy, &price_info, true);

        // In some special cases (e.g. bad debt / negative equity) the inflow can be larger than the outflow,
        // so the reduction will be a net inflow. We don't consume this inflow in order to not count
        // towards the limiter net.
        let in = dx_value + dy_value;
        let out = x_value + y_value;
        let net_out = if (out > in) { out - in } else { 0 };

        limiter.consume_outflow(net_out, $clock);
    };

    let info = {
        let withdrawn_x = got_x.value();
        let withdrawn_y = got_y.value();
        let x_repaid = 0;
        let y_repaid = 0;
        reduction_info_constructor(
            object::id(position),
            model,
            oracle_price_x128,
            sqrt_pool_price_x64,
            delta_l,
            delta_x,
            delta_y,
            withdrawn_x,
            withdrawn_y,
            x_repaid,
            y_repaid,
        )
    };
    let ticket = reduction_repayment_ticket_constructor(sx, sy, info);

    (got_x, got_y, ticket)
}

public fun reduction_ticket_calc_repay_amt_x<X, SX, SY>(
    ticket: &ReductionRepaymentTicket<SX, SY>,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
): u64 {
    let facil_id = ticket.sx.facil_id();
    let amount = ticket.sx.value_x64();
    supply_pool.calc_repay_by_shares(facil_id, amount, clock)
}

public fun reduction_ticket_calc_repay_amt_y<Y, SX, SY>(
    ticket: &ReductionRepaymentTicket<SX, SY>,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
): u64 {
    let facil_id = ticket.sy.facil_id();
    let amount = ticket.sy.value_x64();
    supply_pool.calc_repay_by_shares(facil_id, amount, clock)
}

public fun reduction_ticket_repay_x<X, SX, SY>(
    ticket: &mut ReductionRepaymentTicket<SX, SY>,
    supply_pool: &mut SupplyPool<X, SX>,
    balance: Balance<X>,
    clock: &Clock,
) {
    let shares = ticket.sx.withdraw_all();
    ticket.info.x_repaid = balance.value();
    supply_pool.repay(shares, balance, clock);
}

public fun reduction_ticket_repay_y<Y, SX, SY>(
    ticket: &mut ReductionRepaymentTicket<SX, SY>,
    supply_pool: &mut SupplyPool<Y, SY>,
    balance: Balance<Y>,
    clock: &Clock,
) {
    let shares = ticket.sy.withdraw_all();
    ticket.info.y_repaid = balance.value();
    supply_pool.repay(shares, balance, clock);
}

public fun destroy_reduction_ticket<SX, SY>(ticket: ReductionRepaymentTicket<SX, SY>) {
    assert!(ticket.sx.value_x64() == 0, ETicketNotExhausted);
    assert!(ticket.sy.value_x64() == 0, ETicketNotExhausted);

    let ReductionRepaymentTicket { sx, sy, info } = ticket;
    sx.destroy_zero();
    sy.destroy_zero();

    if (
        info.delta_l == 0 && info.x_repaid == 0 && info.y_repaid == 0 &&
            info.withdrawn_x == 0 && info.withdrawn_y == 0
    ) {
        // position wasn't reduced, don't emit event
        return
    };

    event::emit(info);
}

public fun add_collateral_x<X, Y, LP: store>(
    position: &mut Position<X, Y, LP>,
    cap: &PositionCap,
    balance: Balance<X>,
) {
    check_position_version(position);
    assert!(cap.position_id == object::id(position), e_invalid_position_cap!());

    let amount_x = balance.value();
    if (amount_x == 0) {
        balance.destroy_zero();
        return
    };
    position.col_x.join(balance);

    event::emit(AddCollateralInfo {
        position_id: object::id(position),
        amount_x,
        amount_y: 0,
    });
}

public fun add_collateral_y<X, Y, LP: store>(
    position: &mut Position<X, Y, LP>,
    cap: &PositionCap,
    balance: Balance<Y>,
) {
    check_position_version(position);
    assert!(cap.position_id == object::id(position), e_invalid_position_cap!());

    let amount_y = balance.value();
    if (amount_y == 0) {
        balance.destroy_zero();
        return
    };

    position.col_y.join(balance);

    event::emit(AddCollateralInfo {
        position_id: object::id(position),
        amount_x: 0,
        amount_y,
    });
}

public(package) macro fun add_liquidity_with_receipt_inner<$X, $Y, $Pool, $LP, $Receipt>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $add_liquidity_inner: |&mut $Pool, &mut $LP| -> (u128, u64, u64, $Receipt),
): ($Receipt, AddLiquidityInfo) {
    let position = $position;
    let config = $config;
    let pool_object = $pool_object;

    check_versions(position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(config.pool_object_id() == object::id(pool_object), e_invalid_pool!());
    assert!(!config.add_liquidity_disabled(), e_add_liquidity_disabled!());

    let price_info = validate_price_info(config, $price_info);
    let debt_info = validate_debt_info(config, $debt_info);
    let sqrt_pool_price_x64 = pool_object.current_sqrt_price_x64();

    let (delta_l, delta_x, delta_y, receipt) = $add_liquidity_inner(
        pool_object,
        position.lp_position_mut(),
    );

    config.increase_current_global_l(delta_l);
    assert!(
        config.current_global_l() <= config.max_global_l(),
        e_vault_global_size_limit_exceeded!(),
    );
    assert!(
        position.lp_position().liquidity() <= config.max_position_l(),
        e_position_size_limit_exceeded!(),
    );

    let model = model_from_position!(position, &debt_info);
    let price_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );
    assert!(
        !model.margin_below_threshold(price_x128, config.deleverage_margin_bps()),
        e_position_below_threshold!(),
    );

    let info = add_liquidity_info_constructor(
        object::id(position),
        sqrt_pool_price_x64,
        delta_l,
        delta_x,
        delta_y,
    );

    (receipt, info)
}

public(package) macro fun add_liquidity_inner<$X, $Y, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $add_liquidity_inner: |&mut $Pool, &mut $LP| -> (u128, u64, u64),
): AddLiquidityInfo {
    let (_, info) = add_liquidity_with_receipt_inner!(
        $position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        |pool, lp_position| {
            let (delta_l, delta_x, delta_y) = $add_liquidity_inner(pool, lp_position);
            (delta_l, delta_x, delta_y, 0)
        },
    );
    info
}

public(package) macro fun add_liquidity_with_receipt<$X, $Y, $Pool, $LP, $Receipt>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $cap: &PositionCap,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $add_liquidity_inner: |&mut $Pool, &mut $LP| -> (u128, u64, u64, $Receipt),
): $Receipt {
    let position = $position;
    let cap = $cap;
    assert!(cap.position_id() == object::id(position), e_invalid_position_cap!());
    let (receipt, info) = add_liquidity_with_receipt_inner!(
        position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $add_liquidity_inner,
    );
    if (info.delta_l() > 0) {
        info.emit();
    };

    receipt
}

public(package) macro fun add_liquidity<$X, $Y, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $cap: &PositionCap,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $add_liquidity_inner: |&mut $Pool, &mut $LP| -> (u128, u64, u64),
) {
    let position = $position;
    let cap = $cap;
    assert!(cap.position_id() == object::id(position), e_invalid_position_cap!());
    let info = add_liquidity_inner!(
        position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $add_liquidity_inner,
    );
    if (info.delta_l() > 0) {
        info.emit();
    };
}

public fun repay_debt_x<X, Y, SX, LP: store>(
    position: &mut Position<X, Y, LP>,
    cap: &PositionCap,
    balance: &mut Balance<X>,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
) {
    check_position_version(position);
    assert!(cap.position_id == object::id(position), e_invalid_position_cap!());
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<X, SX>(),
        e_supply_pool_mismatch!(),
    );

    let mut debt_shares = position.debt_bag.take_all();
    if (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        return
    };
    let (_, x_repaid) = supply_pool.repay_max_possible(&mut debt_shares, balance, clock);
    position.debt_bag.add<X, SX>(debt_shares);

    if (x_repaid > 0) {
        event::emit(RepayDebtInfo {
            position_id: object::id(position),
            x_repaid,
            y_repaid: 0,
        })
    };
}

public fun repay_debt_y<X, Y, SY, LP: store>(
    position: &mut Position<X, Y, LP>,
    cap: &PositionCap,
    balance: &mut Balance<Y>,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
) {
    check_position_version(position);
    assert!(cap.position_id == object::id(position), e_invalid_position_cap!());
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<Y, SY>(),
        e_supply_pool_mismatch!(),
    );

    let mut debt_shares = position.debt_bag.take_all();
    if (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        return
    };
    let (_, y_repaid) = supply_pool.repay_max_possible(&mut debt_shares, balance, clock);
    position.debt_bag.add<Y, SY>(debt_shares);

    if (y_repaid > 0) {
        event::emit(RepayDebtInfo {
            position_id: object::id(position),
            x_repaid: 0,
            y_repaid,
        })
    };
}

public(package) macro fun owner_collect_fee<$X, $Y, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $cap: &PositionCap,
    $pool_object: &mut $Pool,
    $collect_fee: |&mut $Pool, &mut $LP| -> (Balance<$X>, Balance<$Y>),
): (Balance<$X>, Balance<$Y>) {
    let position = $position;
    let config = $config;
    let cap = $cap;

    check_versions(position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(cap.position_id() == object::id(position), e_invalid_position_cap!());
    assert!(!config.owner_collect_fee_disabled(), e_owner_collect_fee_disabled!());

    let (mut x, mut y) = $collect_fee($pool_object, position.lp_position_mut());
    let collected_x_amt = x.value();
    let collected_y_amt = y.value();

    let x_fee_amt = util::muldiv(collected_x_amt, (config.rebalance_fee_bps() as u64), 10000);
    let x_fee = x.split(x_fee_amt);
    position.collected_fees_mut().add(x_fee);

    let y_fee_amt = util::muldiv(collected_y_amt, (config.rebalance_fee_bps() as u64), 10000);
    let y_fee = y.split(y_fee_amt);
    position.collected_fees_mut().add(y_fee);

    let position_id = object::id(position);
    emit_owner_collect_fee_info(
        position_id,
        collected_x_amt,
        collected_y_amt,
        x_fee_amt,
        y_fee_amt,
    );

    (x, y)
}

public(package) macro fun owner_collect_reward<$X, $Y, $T, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $cap: &PositionCap,
    $pool_object: &mut $Pool,
    $collect_reward: |&mut $Pool, &mut $LP| -> Balance<$T>,
): Balance<$T> {
    let position = $position;
    let config = $config;
    let cap = $cap;

    check_versions(position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(cap.position_id() == object::id(position), e_invalid_position_cap!());
    assert!(!config.owner_collect_reward_disabled(), e_owner_collect_reward_disabled!());

    let mut reward = $collect_reward($pool_object, position.lp_position_mut());
    let collected_reward_amt = reward.value();

    let fee_amt = util::muldiv(collected_reward_amt, (config.rebalance_fee_bps() as u64), 10000);
    let fee = reward.split(fee_amt);
    position.collected_fees_mut().add(fee);

    let position_id = object::id(position);
    emit_owner_collect_reward_info<$T>(
        position_id,
        collected_reward_amt,
        fee_amt,
    );

    reward
}

public fun owner_take_stashed_rewards<X, Y, T, LP: store>(
    position: &mut Position<X, Y, LP>,
    cap: &PositionCap,
    amount: Option<u64>,
): Balance<T> {
    check_position_version(position);
    assert!(cap.position_id == object::id(position), e_invalid_position_cap!());

    let rewards = if (amount.is_some()) {
        let amount = amount.destroy_some();
        position.owner_reward_stash.take_amount(amount)
    } else {
        position.owner_reward_stash.take_all()
    };

    event::emit(OwnerTakeStashedRewardsInfo<T> {
        position_id: object::id(position),
        amount: rewards.value(),
    });

    rewards
}

public(package) macro fun delete_position<$X, $Y, $LP: store>(
    $position: Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $cap: PositionCap,
    $destroy_empty_lp_position: |$LP| -> (),
    $ctx: &mut TxContext,
) {
    let position = $position;
    let config = $config;
    let cap = $cap;
    let ctx = $ctx;

    check_versions(&position, config);
    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(cap.position_id() == object::id(&position), e_invalid_position_cap!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    assert!(!config.delete_position_disabled(), e_delete_position_disabled!());

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
    ) = position_deconstructor(position);

    id.delete();
    $destroy_empty_lp_position(lp_position);
    col_x.destroy_zero();
    col_y.destroy_zero();
    debt_bag.destroy_empty();
    owner_reward_stash.destroy_empty();

    // delete cap
    let (id, position_id) = position_cap_deconstructor(cap);
    let cap_id = id.to_inner();
    id.delete();

    if (collected_fees.is_empty()) {
        collected_fees.destroy_empty()
    } else {
        share_deleted_position_collected_fees(
            position_id,
            collected_fees,
            ctx,
        );
    };

    emit_delete_position_info(position_id, cap_id);
}

/* ================= rebalance ================= */

public fun create_rebalance_receipt<X, Y, LP: store>(
    position: &mut Position<X, Y, LP>,
    config: &PositionConfig,
    ctx: &mut TxContext,
): (RebalanceReceipt, ActionRequest) {
    check_versions(position, config);
    assert!(position.config_id == config.id.to_inner(), e_invalid_config!());
    assert!(position.ticket_active == false, e_ticket_active!());
    position.ticket_active = true;

    let receipt = RebalanceReceipt {
        id: object::id_from_address(tx_context::fresh_object_address(ctx)),
        position_id: object::id(position),
        collected_amm_fee_x: 0,
        collected_amm_fee_y: 0,
        collected_amm_rewards: vec_map::empty(),
        fees_taken: vec_map::empty(),
        taken_cx: 0,
        taken_cy: 0,
        delta_l: 0,
        delta_x: 0,
        delta_y: 0,
        x_repaid: 0,
        y_repaid: 0,
        added_cx: 0,
        added_cy: 0,
        stashed_amm_rewards: vec_map::empty(),
    };
    (receipt, access::new_request(ARebalance {}, ctx))
}

public(package) fun add_amount_to_map<T>(map: &mut VecMap<TypeName, u64>, amount: u64) {
    let `type` = type_name::with_defining_ids<T>();
    if (vec_map::contains(map, &`type`)) {
        let total = &mut map[&`type`];
        *total = *total + amount;
    } else {
        map.insert(`type`, amount);
    }
}

public(package) fun take_rebalance_fee<X, Y, LP, T>(
    position: &mut Position<X, Y, LP>,
    fee_bps: u16,
    balance: &mut Balance<T>,
    receipt: &mut RebalanceReceipt,
) {
    let fee_amt = util::muldiv(balance.value(), (fee_bps as u64), 10000);
    let fee = balance.split(fee_amt);
    position.collected_fees.add(fee);

    add_amount_to_map<T>(&mut receipt.fees_taken, fee_amt);
}

public(package) macro fun rebalance_collect_fee<$X, $Y, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $receipt: &mut RebalanceReceipt,
    $pool_object: &mut $Pool,
    $collect_fee: |&mut $Pool, &mut $LP| -> (Balance<$X>, Balance<$Y>),
): (Balance<$X>, Balance<$Y>) {
    let position = $position;
    let config = $config;
    let receipt = $receipt;

    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(receipt.position_id() == object::id(position), e_position_mismatch!());
    assert!(object::id($pool_object) == config.pool_object_id(), e_invalid_pool!());

    let (mut x, mut y) = $collect_fee($pool_object, position.lp_position_mut());
    receipt.increase_collected_amm_fee_x(x.value());
    receipt.increase_collected_amm_fee_y(y.value());

    take_rebalance_fee(position, config.rebalance_fee_bps(), &mut x, receipt);
    take_rebalance_fee(position, config.rebalance_fee_bps(), &mut y, receipt);

    (x, y)
}

public(package) macro fun rebalance_collect_reward<$X, $Y, $T, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $receipt: &mut RebalanceReceipt,
    $pool_object: &mut $Pool,
    $collect_reward: |&mut $Pool, &mut $LP| -> Balance<$T>,
): Balance<$T> {
    let position = $position;
    let config = $config;
    let receipt = $receipt;

    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(receipt.position_id() == object::id(position), e_position_mismatch!());

    let mut reward = $collect_reward($pool_object, position.lp_position_mut());
    add_amount_to_map<$T>(receipt.collected_amm_rewards_mut(), balance::value(&reward));

    take_rebalance_fee(position, config.rebalance_fee_bps(), &mut reward, receipt);

    reward
}

public(package) macro fun rebalance_add_liquidity_with_receipt<$X, $Y, $Pool, $LP, $Receipt>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $receipt: &mut RebalanceReceipt,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $add_liquidity_lambda: |&mut $Pool, &mut $LP| -> (u128, u64, u64, $Receipt),
): $Receipt {
    let receipt = $receipt;
    let position = $position;

    assert!(receipt.position_id() == object::id(position), e_position_mismatch!());

    let (cetus_receipt, info) = add_liquidity_with_receipt_inner!(
        position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $add_liquidity_lambda,
    );

    receipt.increase_delta_l(info.delta_l());
    receipt.increase_delta_x(info.delta_x());
    receipt.increase_delta_y(info.delta_y());

    cetus_receipt
}

public(package) macro fun rebalance_add_liquidity<$X, $Y, $Pool, $LP>(
    $position: &mut Position<$X, $Y, $LP>,
    $config: &mut PositionConfig,
    $receipt: &mut RebalanceReceipt,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &mut $Pool,
    $add_liquidity_lambda: |&mut $Pool, &mut $LP| -> (u128, u64, u64),
) {
    let receipt = $receipt;
    let position = $position;

    assert!(receipt.position_id() == object::id(position), e_position_mismatch!());

    let info = add_liquidity_inner!(
        position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $add_liquidity_lambda,
    );

    receipt.increase_delta_l(info.delta_l());
    receipt.increase_delta_x(info.delta_x());
    receipt.increase_delta_y(info.delta_y());
}

public fun rebalance_repay_debt_x<X, Y, SX, LP: store>(
    position: &mut Position<X, Y, LP>,
    balance: &mut Balance<X>,
    receipt: &mut RebalanceReceipt,
    supply_pool: &mut SupplyPool<X, SX>,
    clock: &Clock,
) {
    assert!(receipt.position_id == object::id(position), e_position_mismatch!());
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<X, SX>(),
        e_supply_pool_mismatch!(),
    );

    let mut debt_shares = position.debt_bag.take_all();
    if (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        return
    };
    let (_, x_repaid) = supply_pool::repay_max_possible(
        supply_pool,
        &mut debt_shares,
        balance,
        clock,
    );
    position.debt_bag.add<X, SX>(debt_shares);

    receipt.x_repaid = receipt.x_repaid + x_repaid;
}

public fun rebalance_repay_debt_y<X, Y, SY, LP: store>(
    position: &mut Position<X, Y, LP>,
    balance: &mut Balance<Y>,
    receipt: &mut RebalanceReceipt,
    supply_pool: &mut SupplyPool<Y, SY>,
    clock: &Clock,
) {
    assert!(receipt.position_id == object::id(position), e_position_mismatch!());
    assert!(
        position.debt_bag().share_type_matches_asset_if_any_exists<Y, SY>(),
        e_supply_pool_mismatch!(),
    );

    let mut debt_shares = position.debt_bag.take_all();
    if (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        return
    };
    let (_, y_repaid) = supply_pool.repay_max_possible(&mut debt_shares, balance, clock);
    position.debt_bag.add<Y, SY>(debt_shares);

    receipt.y_repaid = receipt.y_repaid + y_repaid;
}

public fun rebalance_stash_rewards<X, Y, T, LP: store>(
    position: &mut Position<X, Y, LP>,
    receipt: &mut RebalanceReceipt,
    rewards: Balance<T>,
) {
    assert!(receipt.position_id == object::id(position), e_position_mismatch!());

    add_amount_to_map<T>(&mut receipt.stashed_amm_rewards, rewards.value());
    position.owner_reward_stash.add(rewards);
}

public fun consume_rebalance_receipt<X, Y, LP: store>(
    position: &mut Position<X, Y, LP>,
    receipt: RebalanceReceipt,
) {
    assert!(receipt.position_id == object::id(position), e_position_mismatch!());
    position.ticket_active = false;

    let RebalanceReceipt {
        id,
        position_id,
        delta_l,
        delta_x,
        delta_y,
        fees_taken,
        collected_amm_fee_x,
        collected_amm_fee_y,
        collected_amm_rewards,
        taken_cx,
        taken_cy,
        x_repaid,
        y_repaid,
        added_cx,
        added_cy,
        stashed_amm_rewards,
    } = receipt;

    event::emit(RebalanceInfo {
        id,
        position_id,
        delta_l,
        delta_x,
        delta_y,
        fees_taken,
        collected_amm_fee_x,
        collected_amm_fee_y,
        collected_amm_rewards,
        taken_cx,
        taken_cy,
        x_repaid,
        y_repaid,
        added_cx,
        added_cy,
        stashed_amm_rewards,
    });
}

/* ================= admin ================= */

public fun collect_protocol_fees<X, Y, T, LP: store>(
    position: &mut Position<X, Y, LP>,
    amount: Option<u64>,
    ctx: &mut TxContext,
): (Balance<T>, ActionRequest) {
    check_position_version(position);

    let fee: Balance<T> = if (amount.is_none()) {
        position.collected_fees.take_all()
    } else {
        let amount = amount.destroy_some();
        position.collected_fees.take_amount(amount)
    };

    event::emit(CollectProtocolFeesInfo<T> {
        position_id: object::id(position),
        amount: fee.value(),
    });

    (fee, access::new_request(ACollectProtocolFees {}, ctx))
}

public fun collect_deleted_position_fees(
    fees: DeletedPositionCollectedFees,
    ctx: &mut TxContext,
): (BalanceBag, ActionRequest) {
    let DeletedPositionCollectedFees { id, position_id, balance_bag } = fees;
    id.delete();

    event::emit(DeletedPositionCollectedFeesInfo {
        position_id,
        amounts: *balance_bag.amounts(),
    });

    (balance_bag, access::new_request(ACollectProtocolFees {}, ctx))
}

/* ================= read ================= */

public(package) macro fun validated_model_for_position<$X, $Y, $LP>(
    $position: &Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $debt_info: &DebtInfo,
): PositionModel {
    let position = $position;
    let config = $config;

    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    let debt_info = validate_debt_info(config, $debt_info);
    model_from_position!(position, &debt_info)
}

public(package) macro fun calc_liquidate_col_x<$X, $Y, $LP>(
    $position: &Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $max_repayment_amt_y: u64,
): (u64, u64) {
    let position = $position;
    let config = $config;

    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    let price_info = validate_price_info(config, $price_info);
    let debt_info = validate_debt_info(config, $debt_info);

    let model = model_from_position!(position, &debt_info);
    let p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );

    model.calc_liquidate_col_x(
        p_x128,
        $max_repayment_amt_y,
        config.liq_margin_bps(),
        config.liq_bonus_bps(),
        config.base_liq_factor_bps(),
    )
}

public(package) macro fun calc_liquidate_col_y<$X, $Y, $LP>(
    $position: &Position<$X, $Y, $LP>,
    $config: &PositionConfig,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $max_repayment_amt_x: u64,
): (u64, u64) {
    let position = $position;
    let config = $config;

    assert!(position.config_id() == object::id(config), e_invalid_config!());
    assert!(position.ticket_active() == false, e_ticket_active!());
    let price_info = validate_price_info(config, $price_info);
    let debt_info = validate_debt_info(config, $debt_info);

    let model = model_from_position!(position, &debt_info);
    let p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids<$X>(),
        type_name::with_defining_ids<$Y>(),
    );

    model.calc_liquidate_col_y(
        p_x128,
        $max_repayment_amt_x,
        config.liq_margin_bps(),
        config.liq_bonus_bps(),
        config.base_liq_factor_bps(),
    )
}

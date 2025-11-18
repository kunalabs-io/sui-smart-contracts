#[test_only]
module kai_leverage::position_core_bluefin_test_setup;

use access_management::access::{ActionRequest, PackageAdmin};
use bluefin_spot::admin as bluefin_admin;
use bluefin_spot::config::{Self as bluefin_config, GlobalConfig as BluefinGlobalConfig};
use bluefin_spot::pool::{Self as bluefin_pool, Pool as BluefinPool};
use bluefin_spot::position::Position as BluefinPosition;
use bluefin_spot::tick_bitmap;
use bluefin_spot::tick_math;
use integer_mate::i32::{Self, I32};
use kai_leverage::bluefin_spot;
use kai_leverage::debt_info::{Self, DebtInfo, ValidatedDebtInfo};
use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{
    Self as core,
    PositionConfig,
    PositionCap,
    CreatePositionTicket,
    Position,
    RebalanceReceipt,
    ReductionRepaymentTicket,
    DeleverageTicket
};
use kai_leverage::position_core_test_util::{
    Self,
    sqrt_price_x64_to_price_human_mul_n,
    price_mul_100_human_to_sqrt_x64
};
use kai_leverage::position_core_test_util_macros;
use kai_leverage::position_model_clmm::PositionModel;
use kai_leverage::pyth::{Self, PythPriceInfo};
use kai_leverage::pyth_test_util;
use kai_leverage::supply_pool::SupplyPool;
use kai_leverage::supply_pool_tests::{Self, SSUI, SUSDC};
use kai_leverage::util;
use pyth::price_info::PriceInfoObject;
use std::u128;
use std::string;
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin;
use sui::sui::SUI;
use sui::test_scenario::{Self, Scenario, TransactionEffects};
use sui::test_utils::destroy as destroy_;
use usdc::usdc::USDC;

const INITIAL_CLOCK_TIMESTAMP_MS: u64 = 1755000000000;

public struct Setup {
    scenario: Scenario,
    package_admin: PackageAdmin,
    clock: Clock,
    sui_pio: PriceInfoObject,
    usdc_pio: PriceInfoObject,
    supply_pool_x: SupplyPool<SUI, SSUI>,
    supply_pool_y: SupplyPool<USDC, SUSDC>,
    bluefin_pool: BluefinPool<SUI, USDC>,
    bluefin_global_config: BluefinGlobalConfig,
    config_id: ID,
}

public fun scenario(setup: &Setup): &Scenario {
    &setup.scenario
}

public fun package_admin(setup: &Setup): &PackageAdmin {
    &setup.package_admin
}

public fun clock(setup: &Setup): &Clock {
    &setup.clock
}

public fun clock_mut(setup: &mut Setup): &mut Clock {
    &mut setup.clock
}

public fun sui_pio(setup: &Setup): &PriceInfoObject {
    &setup.sui_pio
}

public fun sui_pio_mut(setup: &mut Setup): &mut PriceInfoObject {
    &mut setup.sui_pio
}

public fun usdc_pio(setup: &Setup): &PriceInfoObject {
    &setup.usdc_pio
}

public fun usdc_pio_mut(setup: &mut Setup): &mut PriceInfoObject {
    &mut setup.usdc_pio
}

public fun supply_pool_x(setup: &Setup): &SupplyPool<SUI, SSUI> {
    &setup.supply_pool_x
}

public fun supply_pool_x_mut(setup: &mut Setup): &mut SupplyPool<SUI, SSUI> {
    &mut setup.supply_pool_x
}

public fun supply_pool_y(setup: &Setup): &SupplyPool<USDC, SUSDC> {
    &setup.supply_pool_y
}

public fun supply_pool_y_mut(setup: &mut Setup): &mut SupplyPool<USDC, SUSDC> {
    &mut setup.supply_pool_y
}

public fun clmm_pool(setup: &Setup): &BluefinPool<SUI, USDC> {
    &setup.bluefin_pool
}

public fun config_id(setup: &Setup): ID {
    setup.config_id
}

public fun ctx(self: &mut Setup): &mut TxContext {
    self.scenario.ctx()
}

public fun create_bluefin_pool_for_testing(
    current_sqrt_price: u128,
    config: &mut BluefinGlobalConfig,
    clock: &Clock,
    ctx: &mut TxContext,
): BluefinPool<SUI, USDC> {
    bluefin_pool::create_test_pool_without_liquidity<SUI, USDC, USDC>(
        clock,
        config,
        b"SUI-USDC Pool",
        b"https://bluefin.io/images/nfts/default.gif",
        b"SUI",
        9,
        b"https://sui.io/icon.png",
        b"USDC",
        6,
        b"https://usdc.io/icon.png",
        1, // tick_spacing
        20000, // fee_rate (2%)
        current_sqrt_price,
        balance::create_for_testing(100000000), // creation_fee
        ctx,
    )
}

public fun new_setup(): Setup {
    let mut scenario = test_scenario::begin(@0);
    let package_admin = position_core_test_util::create_admin_for_testing(scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(INITIAL_CLOCK_TIMESTAMP_MS);

    let bluefin_admin_cap = bluefin_admin::get_admin_cap(scenario.ctx());

    let mut bluefin_global_config = bluefin_config::create_config(scenario.ctx());
    bluefin_admin::set_pool_creation_fee<USDC>(
        &bluefin_admin_cap,
        &mut bluefin_global_config,
        100000000,
        scenario.ctx(),
    );
    
    // Add reward manager to config for SUI rewards
    bluefin_admin::add_reward_manager(
        &bluefin_admin_cap,
        &mut bluefin_global_config,
        @0, // Use @0 as the reward manager address
    );
    
    destroy_(bluefin_admin_cap);

    let (
        sui_pio,
        usdc_pio,
        mut pool,
        supply_pool_x,
        supply_pool_y,
        config_id,
    ) = position_core_test_util_macros::initialize_config_for_testing!(
        &mut scenario,
        &package_admin,
        &clock,
        |current_sqrt_price_x64, clock, ctx| -> BluefinPool<SUI, USDC> {
            create_bluefin_pool_for_testing(
                current_sqrt_price_x64,
                &mut bluefin_global_config,
                clock,
                ctx,
            )
        },
    );

    // Initialize SUI reward for the pool
    let sui_reward_amount = 1000000_000000000; // 1M SUI
    let sui_reward_coin = coin::mint_for_testing(
        sui_reward_amount,
        scenario.ctx(),
    );
    
    bluefin_admin::initialize_pool_reward<SUI, USDC, SUI>(
        &bluefin_global_config,
        &mut pool,
        INITIAL_CLOCK_TIMESTAMP_MS / 1000 + 1, // Start time in future
        31536000, // active for 1 year
        sui_reward_coin,
        string::utf8(b"SUI"),
        9, // SUI decimals
        sui_reward_amount,
        &clock,
        scenario.ctx(),
    );

    // create a position in a full range to facilitate swaps
    let tick_a = i32::neg_from(443636);
    let tick_b = i32::from(443636);
    let liquidity = 100000000000;
    let (amt_x, amt_y) = bluefin_spot::calc_deposit_amounts_by_liquidity(
        &pool,
        tick_a,
        tick_b,
        liquidity,
    );
    let balance_x0 = balance::create_for_testing(amt_x);
    let balance_y0 = balance::create_for_testing(amt_y);

    let mut lp_position = bluefin_pool::open_position(
        &bluefin_global_config,
        &mut pool,
        i32::as_u32(tick_a),
        i32::as_u32(tick_b),
        scenario.ctx(),
    );
    let (_, _, residual_x, residual_y) = bluefin_pool::add_liquidity(
        &clock,
        &bluefin_global_config,
        &mut pool,
        &mut lp_position,
        balance_x0,
        balance_y0,
        liquidity,
    );
    residual_x.destroy_zero();
    residual_y.destroy_zero();
    destroy_(lp_position);

    Setup {
        scenario,
        package_admin,
        clock,
        sui_pio,
        usdc_pio,
        supply_pool_x,
        supply_pool_y,
        bluefin_pool: pool,
        bluefin_global_config,
        config_id,
    }
}

public fun next_tx(self: &mut Setup, sender: address): TransactionEffects {
    self.scenario.next_tx(sender)
}

public fun take_shared_position(self: &Setup): Position<SUI, USDC, BluefinPosition> {
    self.scenario.take_shared()
}

public fun create_position_ticket(
    self: &mut Setup,
    config: &mut PositionConfig,
    tick_a: I32,
    tick_b: I32,
    principal_x: Balance<SUI>,
    principal_y: Balance<USDC>,
    delta_l: u128,
    price_info: &PythPriceInfo,
): CreatePositionTicket<SUI, USDC, I32> {
    bluefin_spot::create_position_ticket_v2(
        &mut self.bluefin_pool,
        config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        price_info,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun create_position_ticket_with_different_pool(
    self: &mut Setup,
    config: &mut PositionConfig,
    tick_a: I32,
    tick_b: I32,
    principal_x: Balance<SUI>,
    principal_y: Balance<USDC>,
    delta_l: u128,
    price_info: &PythPriceInfo,
): CreatePositionTicket<SUI, USDC, I32> {
    let mut different_pool = create_bluefin_pool_for_testing(
        self.bluefin_pool.current_sqrt_price(),
        &mut self.bluefin_global_config,
        &self.clock,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let ticket = bluefin_spot::create_position_ticket_v2(
        &mut different_pool,
        config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        price_info,
        &self.clock,
        self.scenario.ctx(),
    );
    destroy_(different_pool);

    ticket
}

public fun borrow_for_position_x(
    self: &mut Setup,
    ticket: &mut CreatePositionTicket<SUI, USDC, I32>,
    config: &PositionConfig,
) {
    bluefin_spot::borrow_for_position_x(ticket, config, &mut self.supply_pool_x, &self.clock);
}

public fun borrow_for_position_y(
    self: &mut Setup,
    ticket: &mut CreatePositionTicket<SUI, USDC, I32>,
    config: &PositionConfig,
) {
    bluefin_spot::borrow_for_position_y(ticket, config, &mut self.supply_pool_y, &self.clock);
}

public fun create_position(
    self: &mut Setup,
    config: &PositionConfig,
    ticket: CreatePositionTicket<SUI, USDC, I32>,
    creation_fee: Balance<SUI>,
): PositionCap {
    bluefin_spot::create_position(
        config,
        ticket,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        creation_fee,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun create_position_with_different_pool(
    self: &mut Setup,
    config: &PositionConfig,
    ticket: CreatePositionTicket<SUI, USDC, I32>,
    creation_fee: Balance<SUI>,
): PositionCap {
    let mut different_pool = create_bluefin_pool_for_testing(
        self.bluefin_pool.current_sqrt_price(),
        &mut self.bluefin_global_config,
        &self.clock,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let cap = bluefin_spot::create_position(
        config,
        ticket,
        &mut different_pool,
        &self.bluefin_global_config,
        creation_fee,
        &self.clock,
        self.scenario.ctx(),
    );
    destroy_(different_pool);

    cap
}

public fun debt_info(self: &mut Setup, config: &PositionConfig): DebtInfo {
    let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
    debt_info.add_from_supply_pool(
        &mut self.supply_pool_x,
        &self.clock,
    );
    debt_info.add_from_supply_pool(
        &mut self.supply_pool_y,
        &self.clock,
    );

    debt_info
}

public fun validated_debt_info(self: &mut Setup, config: &PositionConfig): ValidatedDebtInfo {
    config.validate_debt_info(&self.debt_info(config))
}

public fun position_model(
    self: &mut Setup,
    position: &Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
): PositionModel {
    bluefin_spot::position_model(position, config, &self.debt_info(config))
}

public fun get_lp_fee_amounts(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
): (u64, u64) {
    bluefin_spot::get_accrued_fee(position, &mut self.bluefin_pool, &self.clock)
}

public fun get_lp_reward_amount<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
): u64 {
    bluefin_spot::get_accrued_rewards<_, _, R>(position, &mut self.bluefin_pool, &self.clock)
}

public fun rebalance_collect_fee(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
): (Balance<SUI>, Balance<USDC>) {
    bluefin_spot::rebalance_collect_fee(
        position,
        config,
        rebalance_receipt,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        &self.clock,
    )
}

public fun rebalance_collect_reward<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
): Balance<R> {
    bluefin_spot::rebalance_collect_reward(
        position,
        config,
        rebalance_receipt,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        &self.clock,
    )
}

public fun price_info(self: &mut Setup): PythPriceInfo {
    let mut price_info = pyth::create(&self.clock);
    price_info.add(&self.sui_pio);
    price_info.add(&self.usdc_pio);
    price_info
}

public fun rebalance_add_liquidity(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
    delta_l: u128,
    balance_x: Balance<SUI>,
    balance_y: Balance<USDC>,
) {
    let debt_info = self.debt_info(config);
    bluefin_spot::rebalance_add_liquidity(
        position,
        config,
        rebalance_receipt,
        &self.price_info(),
        &debt_info,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        delta_l,
        balance_x,
        balance_y,
        &self.clock,
    );
}

public fun update_pio_timestamps(self: &mut Setup) {
    pyth_test_util::set_pyth_pio_timestamp(&mut self.sui_pio, self.clock.timestamp_ms() / 1000);
    pyth_test_util::set_pyth_pio_timestamp(&mut self.usdc_pio, self.clock.timestamp_ms() / 1000);
}

public fun sync_pyth_pio_price_x_to_pool(self: &mut Setup) {
    let current_sqrt_price_x64 = self.bluefin_pool.current_sqrt_price();
    let price_human_mul_8 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
        current_sqrt_price_x64,
        8,
    );
    pyth_test_util::update_pyth_pio_price_human_mul_n(
        &mut self.sui_pio,
        price_human_mul_8,
        price_human_mul_8,
        8,
        &self.clock,
    );
}

public fun update_pyth_pio_price_human_mul_n(
    self: &mut Setup,
    spot_price: u64,
    ema_price: u64,
    decimals: u8,
) {
    pyth_test_util::update_pyth_pio_price_human_mul_n(
        &mut self.sui_pio,
        spot_price,
        ema_price,
        decimals,
        &self.clock,
    );
}

public fun rebalance_repay_debt_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    balance_x: &mut Balance<SUI>,
    rebalance_receipt: &mut RebalanceReceipt,
) {
    core::rebalance_repay_debt_x(
        position,
        balance_x,
        rebalance_receipt,
        &mut self.supply_pool_x,
        &self.clock,
    );
}

public fun rebalance_repay_debt_y(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    balance_y: &mut Balance<USDC>,
    rebalance_receipt: &mut RebalanceReceipt,
) {
    core::rebalance_repay_debt_y(
        position,
        balance_y,
        rebalance_receipt,
        &mut self.supply_pool_y,
        &self.clock,
    );
}

public fun repay_debt_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    cap: &PositionCap,
    balance: &mut Balance<SUI>,
) {
    core::repay_debt_x(position, cap, balance, &mut self.supply_pool_x, &self.clock);
}

public fun repay_debt_y(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    cap: &PositionCap,
    balance: &mut Balance<USDC>,
) {
    core::repay_debt_y(position, cap, balance, &mut self.supply_pool_y, &self.clock);
}

public fun reduce(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    factor_x64: u128,
): (Balance<SUI>, Balance<USDC>, ReductionRepaymentTicket<SSUI, SUSDC>) {
    bluefin_spot::reduce(
        position,
        config,
        cap,
        &self.price_info(),
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        factor_x64,
        &self.clock,
    )
}

public fun reduction_ticket_calc_repay_amt_x(
    self: &mut Setup,
    ticket: &ReductionRepaymentTicket<SSUI, SUSDC>,
): u64 {
    core::reduction_ticket_calc_repay_amt_x(ticket, &mut self.supply_pool_x, &self.clock)
}

public fun reduction_ticket_calc_repay_amt_y(
    self: &mut Setup,
    ticket: &ReductionRepaymentTicket<SSUI, SUSDC>,
): u64 {
    core::reduction_ticket_calc_repay_amt_y(ticket, &mut self.supply_pool_y, &self.clock)
}

public fun reduction_ticket_repay_x(
    self: &mut Setup,
    ticket: &mut ReductionRepaymentTicket<SSUI, SUSDC>,
    balance: Balance<SUI>,
) {
    core::reduction_ticket_repay_x(ticket, &mut self.supply_pool_x, balance, &self.clock);
}

public fun reduction_ticket_repay_y(
    self: &mut Setup,
    ticket: &mut ReductionRepaymentTicket<SSUI, SUSDC>,
    balance: Balance<USDC>,
) {
    core::reduction_ticket_repay_y(ticket, &mut self.supply_pool_y, balance, &self.clock);
}

public fun add_liquidity(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    delta_l: u128,
    balance_x: Balance<SUI>,
    balance_y: Balance<USDC>,
) {
    bluefin_spot::add_liquidity(
        position,
        config,
        cap,
        price_info,
        debt_info,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        delta_l,
        balance_x,
        balance_y,
        &self.clock,
    );
}

public fun add_liquidity_with_receipt(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    delta_l: u128,
) {
    let (delta_x, delta_y) = bluefin_spot::calc_deposit_amounts_by_liquidity(
        &self.bluefin_pool,
        position.lp_position().lower_tick(),
        position.lp_position().upper_tick(),
        delta_l,
    );
    bluefin_spot::add_liquidity(
        position,
        config,
        cap,
        price_info,
        debt_info,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        delta_l,
        balance::create_for_testing(delta_x),
        balance::create_for_testing(delta_y),
        &self.clock,
    );
}

public fun owner_collect_fee(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
): (Balance<SUI>, Balance<USDC>) {
    bluefin_spot::owner_collect_fee(
        position,
        config,
        cap,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        &self.clock,
    )
}

public fun owner_collect_reward<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
): Balance<R> {
    bluefin_spot::owner_collect_reward(
        position,
        config,
        cap,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        &self.clock,
    )
}

public fun delete_position(
    self: &mut Setup,
    position: Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    cap: PositionCap,
) {
    bluefin_spot::delete_position(
        position,
        config,
        cap,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun destroy(setup: Setup) {
    let Setup {
        scenario,
        package_admin,
        clock,
        sui_pio,
        usdc_pio,
        supply_pool_x,
        supply_pool_y,
        bluefin_pool,
        bluefin_global_config,
        config_id: _,
    } = setup;
    scenario.end();
    destroy_(package_admin);
    destroy_(clock);
    destroy_(sui_pio);
    destroy_(usdc_pio);
    destroy_(supply_pool_x);
    destroy_(supply_pool_y);
    destroy_(bluefin_pool);
    bluefin_config::destroy_config_for_testing(bluefin_global_config);
}

public fun swap_x_in(self: &mut Setup, balance_x: Balance<SUI>): Balance<USDC> {
    let a2b = true;
    let by_amount_in = true;
    let amount = balance_x.value();
    let sqrt_price_limit = 4295048016 + 1; // MIN_SQRT_PRICE_X64

    let (balance_x_out, balance_y_out, receipt) = bluefin_pool::flash_swap(
        &self.clock,
        &self.bluefin_global_config,
        &mut self.bluefin_pool,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
    );
    balance_x_out.destroy_zero();

    bluefin_pool::repay_flash_swap(
        &self.bluefin_global_config,
        &mut self.bluefin_pool,
        balance_x,
        balance::zero(),
        receipt,
    );

    balance_y_out
}

public fun swap_y_in(self: &mut Setup, balance_y: Balance<USDC>): Balance<SUI> {
    let a2b = false;
    let by_amount_in = true;
    let amount_y_in = balance::value(&balance_y);
    let amount_limit = amount_y_in;
    let sqrt_price_limit = 79226673515401279992447579055 - 1; // MAX_SQRT_PRICE_X64

    let (balance_x_out, balance_y_out) = bluefin_pool::swap(
        &self.clock,
        &self.bluefin_global_config,
        &mut self.bluefin_pool,
        balance::create_for_testing(0),
        balance_y,
        a2b,
        by_amount_in,
        amount_y_in,
        amount_limit,
        sqrt_price_limit,
    );
    balance_y_out.destroy_zero();

    balance_x_out
}

public fun swap_to_sqrt_price_x64(self: &mut Setup, sqrt_price_x64: u128) {
    let current_sqrt_price_x64 = self.bluefin_pool.current_sqrt_price();
    if (current_sqrt_price_x64 == sqrt_price_x64) {
        return
    };
    let pool = &self.bluefin_pool;

    let a2b = sqrt_price_x64 < current_sqrt_price_x64;
    let mut amount_in = 0;
    let mut current_sqrt_price_x64 = current_sqrt_price_x64;
    let mut current_tick_index = pool.current_tick_index();
    let mut current_liquidity = pool.liquidity();

    while (current_sqrt_price_x64 != sqrt_price_x64) {
        let tick_manager = pool.get_tick_manager();
        let (
            next_tick_index,
            next_tick_initialized,
        ) = tick_bitmap::next_initialized_tick_within_one_word(
            tick_manager.bitmap(),
            current_tick_index,
            tick_manager.tick_spacing(),
            a2b,
        );

        let next_tick_sqrt_price_x64 = tick_math::get_sqrt_price_at_tick(next_tick_index);

        let next_sqrt_price_x64 = if (a2b) {
            u128::max(
                next_tick_sqrt_price_x64,
                sqrt_price_x64,
            )
        } else {
            u128::min(
                next_tick_sqrt_price_x64,
                sqrt_price_x64,
            )
        };

        let amount = if (a2b) {
            mock_dex_math::get_delta_a(
                current_sqrt_price_x64,
                next_sqrt_price_x64,
                current_liquidity,
                true,
            )
        } else {
            mock_dex_math::get_delta_b(
                current_sqrt_price_x64,
                next_sqrt_price_x64,
                current_liquidity,
                true,
            )
        };
        amount_in =
            amount_in + util::muldiv_round_up(amount, 1000000, 1000000 - pool.get_fee_rate());

        if (next_tick_initialized && next_sqrt_price_x64 == next_tick_sqrt_price_x64) {
            let next_tick = tick_manager.get_tick_from_manager(next_tick_index);
            let liquidity_change = if (a2b) {
                next_tick.liquidity_net().neg()
            } else {
                next_tick.liquidity_net()
            };
            current_liquidity = if (!liquidity_change.is_neg()) {
                current_liquidity + liquidity_change.abs_u128()
            } else {
                current_liquidity - liquidity_change.abs_u128()
            };
        };
        if (next_sqrt_price_x64 == next_tick_sqrt_price_x64) {
            current_tick_index = if (a2b) {
                next_tick_index.sub(i32::from(1))
            } else {
                next_tick_index
            };
        };

        current_sqrt_price_x64 = next_sqrt_price_x64;
    };

    if (a2b) {
        let out = self.swap_x_in(balance::create_for_testing(amount_in));
        destroy_(out);
    } else {
        let out = self.swap_y_in(balance::create_for_testing(amount_in));
        destroy_(out);
    }
}

/* ================= deleverage functions ================= */

public fun create_deleverage_ticket(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_delta_l: u128,
): (DeleverageTicket, ActionRequest) {
    bluefin_spot::create_deleverage_ticket(
        position,
        config,
        price_info,
        debt_info,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        max_delta_l,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun deleverage(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    max_delta_l: u128,
): ActionRequest {
    bluefin_spot::deleverage(
        position,
        config,
        price_info,
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        max_delta_l,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun deleverage_ticket_repay_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    ticket: &mut DeleverageTicket,
) {
    core::deleverage_ticket_repay_x(
        position,
        config,
        ticket,
        &mut self.supply_pool_x,
        &self.clock,
    );
}

public fun deleverage_ticket_repay_y(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    ticket: &mut DeleverageTicket,
) {
    core::deleverage_ticket_repay_y(
        position,
        config,
        ticket,
        &mut self.supply_pool_y,
        &self.clock,
    );
}

/* ================= liquidation functions ================= */

public fun create_deleverage_ticket_for_liquidation(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
): DeleverageTicket {
    bluefin_spot::create_deleverage_ticket_for_liquidation(
        position,
        config,
        price_info,
        debt_info,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        &self.clock,
    )
}

public fun deleverage_for_liquidation(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
) {
    bluefin_spot::deleverage_for_liquidation(
        position,
        config,
        price_info,
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.bluefin_pool,
        &self.bluefin_global_config,
        &self.clock,
    );
}

public fun calc_liquidate_col_x(
    _: &Setup,
    position: &Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_amount: u64,
): (u64, u64) {
    bluefin_spot::calc_liquidate_col_x(
        position,
        config,
        price_info,
        debt_info,
        max_amount,
    )
}

public fun calc_liquidate_col_y(
    _: &Setup,
    position: &Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_amount: u64,
): (u64, u64) {
    bluefin_spot::calc_liquidate_col_y(
        position,
        config,
        price_info,
        debt_info,
        max_amount,
    )
}

public fun liquidate_col_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_y: &mut Balance<USDC>,
): Balance<SUI> {
    bluefin_spot::liquidate_col_x(
        position,
        config,
        price_info,
        debt_info,
        repayment_y,
        &mut self.supply_pool_y,
        &self.clock,
    )
}

public fun liquidate_col_y(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_x: &mut Balance<SUI>,
): Balance<USDC> {
    bluefin_spot::liquidate_col_y(
        position,
        config,
        price_info,
        debt_info,
        repayment_x,
        &mut self.supply_pool_x,
        &self.clock,
    )
}

public fun liquidate_col_x_with_wrong_supply_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_y: &mut Balance<USDC>,
): Balance<SUI> {
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_usdc_supply_pool_for_testing();

    // This should abort with e_supply_pool_mismatch
    let reward_x = bluefin_spot::liquidate_col_x(
        position,
        config,
        price_info,
        debt_info,
        repayment_y,
        &mut wrong_supply_pool,
        &self.clock,
    );
    destroy_(wrong_supply_pool);
    reward_x
}

public fun liquidate_col_y_with_wrong_supply_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_x: &mut Balance<SUI>,
): Balance<USDC> {
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_sui_supply_pool_for_testing();

    // This should abort with e_supply_pool_mismatch
    let reward_y = bluefin_spot::liquidate_col_y(
        position,
        config,
        price_info,
        debt_info,
        repayment_x,
        &mut wrong_supply_pool,
        &self.clock,
    );
    destroy_(wrong_supply_pool);
    reward_y
}

/* ================= deleverage helper functions ================= */

public fun create_deleverage_ticket_with_different_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_delta_l: u128,
): (DeleverageTicket, ActionRequest) {
    let mut different_pool = create_bluefin_pool_for_testing(
        self.bluefin_pool.current_sqrt_price(),
        &mut self.bluefin_global_config,
        &self.clock,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let (ticket, request) = bluefin_spot::create_deleverage_ticket(
        position,
        config,
        price_info,
        debt_info,
        &mut different_pool,
        &self.bluefin_global_config,
        max_delta_l,
        &self.clock,
        self.scenario.ctx(),
    );

    destroy_(different_pool);
    (ticket, request)
}

public fun create_deleverage_ticket_for_liquidation_with_different_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
): DeleverageTicket {
    let mut different_pool = create_bluefin_pool_for_testing(
        self.bluefin_pool.current_sqrt_price(),
        &mut self.bluefin_global_config,
        &self.clock,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let ticket = bluefin_spot::create_deleverage_ticket_for_liquidation(
        position,
        config,
        price_info,
        debt_info,
        &mut different_pool,
        &self.bluefin_global_config,
        &self.clock,
    );

    destroy_(different_pool);
    ticket
}

public fun take_shared_position_by_cap(
    self: &mut Setup,
    position_cap: &PositionCap,
): Position<SUI, USDC, BluefinPosition> {
    self.scenario.take_shared_by_id(position_cap.position_id())
}

public fun deleverage_ticket_repay_x_with_wrong_supply_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    ticket: &mut DeleverageTicket,
) {
    // Create a wrong supply pool with a different ID
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_sui_supply_pool_for_testing();

    core::deleverage_ticket_repay_x(
        position,
        config,
        ticket,
        &mut wrong_supply_pool,
        &self.clock,
    );
    destroy_(wrong_supply_pool);
}

public fun deleverage_ticket_repay_y_with_wrong_supply_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    ticket: &mut DeleverageTicket,
) {
    // Create a wrong supply pool with a different ID
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_usdc_supply_pool_for_testing();

    core::deleverage_ticket_repay_y(
        position,
        config,
        ticket,
        &mut wrong_supply_pool,
        &self.clock,
    );

    destroy_(wrong_supply_pool);
}

/* ================= bad debt functions ================= */

public fun repay_bad_debt_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<SUI>,
): ActionRequest {
    bluefin_spot::repay_bad_debt_x(
        position,
        config,
        price_info,
        debt_info,
        &mut self.supply_pool_x,
        repayment,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun repay_bad_debt_y(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, BluefinPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<USDC>,
): ActionRequest {
    bluefin_spot::repay_bad_debt_y(
        position,
        config,
        price_info,
        debt_info,
        &mut self.supply_pool_y,
        repayment,
        &self.clock,
        self.scenario.ctx(),
    )
}

/* ================= tests ================= */

#[test]
public fun swap_to_sqrt_price_x64_is_correct() {
    let mut setup = new_setup();

    // position in partial range
    {
        let tick_a = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_45),
        );
        let tick_b = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_55),
        );
        let liquidity = 100000000000;
        let (amt_x, amt_y) = bluefin_spot::calc_deposit_amounts_by_liquidity(
            &setup.bluefin_pool,
            tick_a,
            tick_b,
            liquidity,
        );
        let balance_x0 = balance::create_for_testing(amt_x);
        let balance_y0 = balance::create_for_testing(amt_y);

        let mut lp_position = bluefin_pool::open_position(
            &setup.bluefin_global_config,
            &mut setup.bluefin_pool,
            i32::as_u32(tick_a),
            i32::as_u32(tick_b),
            setup.scenario.ctx(),
        );
        let clock = &setup.clock;
        let (_, _, residual_x, residual_y) = bluefin_pool::add_liquidity(
            clock,
            &setup.bluefin_global_config,
            &mut setup.bluefin_pool,
            &mut lp_position,
            balance_x0,
            balance_y0,
            liquidity,
        );
        residual_x.destroy_zero();
        residual_y.destroy_zero();

        destroy_(lp_position);
    };

    // move up within range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_53);
        setup.swap_to_sqrt_price_x64(want_price);

        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            bluefin_pool::current_sqrt_price(&setup.bluefin_pool),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move up out of range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_70);
        setup.swap_to_sqrt_price_x64(want_price);

        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            bluefin_pool::current_sqrt_price(&setup.bluefin_pool),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move down within range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_47);
        setup.swap_to_sqrt_price_x64(want_price);
        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            bluefin_pool::current_sqrt_price(&setup.bluefin_pool),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move down out of range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_30);
        setup.swap_to_sqrt_price_x64(want_price);
        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            bluefin_pool::current_sqrt_price(&setup.bluefin_pool),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move up out of range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60);
        setup.swap_to_sqrt_price_x64(want_price);
        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            bluefin_pool::current_sqrt_price(&setup.bluefin_pool),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move down out of range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_20);
        setup.swap_to_sqrt_price_x64(want_price);
        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            bluefin_pool::current_sqrt_price(&setup.bluefin_pool),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };

    setup.destroy();
}
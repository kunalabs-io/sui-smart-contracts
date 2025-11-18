#[test_only]
module kai_leverage::position_core_mock_dex_test_setup;

use access_management::access::{PackageAdmin, ActionRequest};
use integer_mate::i32::{Self, I32};
use kai_leverage::debt_info::{Self, DebtInfo, ValidatedDebtInfo};
use kai_leverage::mock_dex::{Self, MockDexPool, PositionKey};
use kai_leverage::mock_dex_integration;
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
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
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
    mock_dex_pool: MockDexPool<SUI, USDC>,
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

public fun clmm_pool(setup: &Setup): &MockDexPool<SUI, USDC> {
    &setup.mock_dex_pool
}

public fun config_id(setup: &Setup): ID {
    setup.config_id
}

public fun ctx(self: &mut Setup): &mut TxContext {
    self.scenario.ctx()
}

public fun new_setup(): Setup {
    let mut scenario = test_scenario::begin(@0);
    let package_admin = position_core_test_util::create_admin_for_testing(scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(INITIAL_CLOCK_TIMESTAMP_MS);
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
        |current_sqrt_price_x64, _clock, ctx| -> MockDexPool<SUI, USDC> {
            mock_dex::create_mock_dex_pool(
                current_sqrt_price_x64,
                50_00, // swap fee: 50%
                ctx,
            )
        },
    );

    // create a position in a full range to facilitate swaps
    let tick_a = i32::neg_from(443636);
    let tick_b = i32::from(443636);
    let liquidity = 100000000000;
    let (amt_x, amt_y) = pool.calc_deposit_amounts_by_liquidity(
        tick_a,
        tick_b,
        liquidity,
    );
    let balance_x = balance::create_for_testing(amt_x);
    let balance_y = balance::create_for_testing(amt_y);

    let position = pool.open_position(
        tick_a,
        tick_b,
        liquidity,
        balance_x,
        balance_y,
        scenario.ctx(),
    );
    destroy_(position);

    Setup {
        scenario,
        package_admin,
        clock,
        sui_pio,
        usdc_pio,
        supply_pool_x,
        supply_pool_y,
        mock_dex_pool: pool,
        config_id,
    }
}

public fun next_tx(self: &mut Setup, sender: address): TransactionEffects {
    self.scenario.next_tx(sender)
}

public fun take_shared_position(self: &Setup): Position<SUI, USDC, PositionKey> {
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
    mock_dex_integration::create_position_ticket(
        &mut self.mock_dex_pool,
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
    let mut different_pool = mock_dex::create_mock_dex_pool(
        self.mock_dex_pool.current_sqrt_price_x64(),
        50_00,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let ticket = mock_dex_integration::create_position_ticket(
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
    mock_dex_integration::borrow_for_position_x(
        ticket,
        config,
        &mut self.supply_pool_x,
        &self.clock,
    );
}

public fun borrow_for_position_y(
    self: &mut Setup,
    ticket: &mut CreatePositionTicket<SUI, USDC, I32>,
    config: &PositionConfig,
) {
    mock_dex_integration::borrow_for_position_y(
        ticket,
        config,
        &mut self.supply_pool_y,
        &self.clock,
    );
}

public fun create_position(
    self: &mut Setup,
    config: &PositionConfig,
    ticket: CreatePositionTicket<SUI, USDC, I32>,
    creation_fee: Balance<SUI>,
): PositionCap {
    mock_dex_integration::create_position(
        config,
        ticket,
        &mut self.mock_dex_pool,
        creation_fee,
        self.scenario.ctx(),
    )
}

public fun create_position_with_different_pool(
    self: &mut Setup,
    config: &PositionConfig,
    ticket: CreatePositionTicket<SUI, USDC, I32>,
    creation_fee: Balance<SUI>,
): PositionCap {
    let mut different_pool = mock_dex::create_mock_dex_pool(
        self.mock_dex_pool.current_sqrt_price_x64(),
        50_00,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let cap = mock_dex_integration::create_position(
        config,
        ticket,
        &mut different_pool,
        creation_fee,
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
    position: &Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
): PositionModel {
    mock_dex_integration::validated_model_for_position(position, config, &self.debt_info(config))
}

public fun get_lp_fee_amounts(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
): (u64, u64) {
    mock_dex::position_fees(
        &self.mock_dex_pool,
        position.lp_position(),
    )
}

public fun get_lp_reward_amount<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
): u64 {
    mock_dex::position_rewards<_, _, R>(
        &self.mock_dex_pool,
        position.lp_position(),
    )
}

public fun rebalance_collect_fee(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
): (Balance<SUI>, Balance<USDC>) {
    mock_dex_integration::rebalance_collect_fee(
        position,
        config,
        rebalance_receipt,
        &mut self.mock_dex_pool,
    )
}

public fun rebalance_collect_reward<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
): Balance<R> {
    mock_dex_integration::rebalance_collect_reward(
        position,
        config,
        rebalance_receipt,
        &mut self.mock_dex_pool,
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
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
    delta_l: u128,
    balance_x: Balance<SUI>,
    balance_y: Balance<USDC>,
) {
    let debt_info = self.debt_info(config);
    mock_dex_integration::rebalance_add_liquidity(
        position,
        config,
        rebalance_receipt,
        &self.price_info(),
        &debt_info,
        &mut self.mock_dex_pool,
        delta_l,
        balance_x,
        balance_y,
    );
}

public fun update_pio_timestamps(self: &mut Setup) {
    pyth_test_util::set_pyth_pio_timestamp(&mut self.sui_pio, self.clock.timestamp_ms() / 1000);
    pyth_test_util::set_pyth_pio_timestamp(&mut self.usdc_pio, self.clock.timestamp_ms() / 1000);
}

public fun sync_pyth_pio_price_x_to_pool(self: &mut Setup) {
    let current_sqrt_price_x64 = self.mock_dex_pool.current_sqrt_price_x64();
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
    position: &mut Position<SUI, USDC, PositionKey>,
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
    position: &mut Position<SUI, USDC, PositionKey>,
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
    position: &mut Position<SUI, USDC, PositionKey>,
    cap: &PositionCap,
    balance: &mut Balance<SUI>,
) {
    core::repay_debt_x(position, cap, balance, &mut self.supply_pool_x, &self.clock);
}

public fun repay_debt_y(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    cap: &PositionCap,
    balance: &mut Balance<USDC>,
) {
    core::repay_debt_y(position, cap, balance, &mut self.supply_pool_y, &self.clock);
}

public fun reduce(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    factor_x64: u128,
): (Balance<SUI>, Balance<USDC>, ReductionRepaymentTicket<SSUI, SUSDC>) {
    mock_dex_integration::reduce(
        position,
        config,
        cap,
        &self.price_info(),
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.mock_dex_pool,
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
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    delta_l: u128,
    balance_x: Balance<SUI>,
    balance_y: Balance<USDC>,
) {
    mock_dex_integration::add_liquidity(
        position,
        config,
        cap,
        price_info,
        debt_info,
        &mut self.mock_dex_pool,
        delta_l,
        balance_x,
        balance_y,
    );
}

public fun add_liquidity_with_receipt(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    delta_l: u128,
) {
    let receipt = mock_dex_integration::add_liquidity_with_receipt(
        position,
        config,
        cap,
        price_info,
        debt_info,
        &mut self.mock_dex_pool,
        delta_l,
    );
    let (amount_x, amount_y) = receipt.pay_amounts();
    mock_dex::fulfill_add_liquidity_receipt(
        &mut self.mock_dex_pool,
        receipt,
        balance::create_for_testing(amount_x),
        balance::create_for_testing(amount_y),
    );
}

public fun owner_collect_fee(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    cap: &PositionCap,
): (Balance<SUI>, Balance<USDC>) {
    mock_dex_integration::owner_collect_fee(
        position,
        config,
        cap,
        &mut self.mock_dex_pool,
    )
}

public fun owner_collect_reward<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    cap: &PositionCap,
): Balance<R> {
    mock_dex_integration::owner_collect_reward(
        position,
        config,
        cap,
        &mut self.mock_dex_pool,
    )
}

public fun delete_position(
    self: &mut Setup,
    position: Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    cap: PositionCap,
) {
    mock_dex_integration::delete_position(
        position,
        config,
        cap,
        &mut self.mock_dex_pool,
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
        mock_dex_pool,
        config_id: _,
    } = setup;
    scenario.end();
    destroy_(package_admin);
    destroy_(clock);
    destroy_(sui_pio);
    destroy_(usdc_pio);
    destroy_(supply_pool_x);
    destroy_(supply_pool_y);
    destroy_(mock_dex_pool);
}

public fun swap_x_in(self: &mut Setup, balance_x: Balance<SUI>): Balance<USDC> {
    self.mock_dex_pool.swap_x_in(balance_x)
}

public fun swap_y_in(self: &mut Setup, balance_y: Balance<USDC>): Balance<SUI> {
    self.mock_dex_pool.swap_y_in(balance_y)
}

public fun swap_to_sqrt_price_x64(self: &mut Setup, sqrt_price_x64: u128) {
    let current_sqrt_price_x64 = self.mock_dex_pool.current_sqrt_price_x64();
    if (current_sqrt_price_x64 == sqrt_price_x64) {
        return
    };
    let pool = &self.mock_dex_pool;
    if (sqrt_price_x64 > current_sqrt_price_x64) {
        let liquidity_list = pool.get_liquidity_list_upwards();
        assert!(liquidity_list.length() > 0);

        let mut amount_y_in = 0;
        let mut current_sqrt_price_x64 = current_sqrt_price_x64;
        let mut i = 0;
        while (i < liquidity_list.length()) {
            let liquidity_info = liquidity_list[i];
            let next_sqrt_price_x64 = u128::min(
                mock_dex_math::get_sqrt_price_at_tick(liquidity_info.tick_end()),
                sqrt_price_x64,
            );

            let amount = mock_dex_math::get_delta_b(
                current_sqrt_price_x64,
                next_sqrt_price_x64,
                liquidity_info.liquidity(),
                true,
            );
            amount_y_in = amount_y_in + util::muldiv_round_up(amount, 100_00, pool.swap_fee_bps());

            current_sqrt_price_x64 = next_sqrt_price_x64;
            if (next_sqrt_price_x64 == sqrt_price_x64) {
                break
            };
            i = i + 1;
        };
        assert!(current_sqrt_price_x64 == sqrt_price_x64);

        let out = self.mock_dex_pool.swap_y_in(balance::create_for_testing(amount_y_in));
        destroy_(out);
    } else {
        let liquidity_list = pool.get_liquidity_list_downwards();
        assert!(liquidity_list.length() > 0);

        let mut amount_x_in = 0;
        let mut current_sqrt_price_x64 = current_sqrt_price_x64;
        let mut i = 0;
        while (i < liquidity_list.length()) {
            let liquidity_info = liquidity_list[i];
            let next_sqrt_price_x64 = u128::max(
                mock_dex_math::get_sqrt_price_at_tick(liquidity_info.tick_end()),
                sqrt_price_x64,
            );

            let amount = mock_dex_math::get_delta_a(
                current_sqrt_price_x64,
                next_sqrt_price_x64,
                liquidity_info.liquidity(),
                true,
            );
            amount_x_in = amount_x_in + util::muldiv_round_up(amount, 100_00, pool.swap_fee_bps());

            current_sqrt_price_x64 = next_sqrt_price_x64;
            if (next_sqrt_price_x64 == sqrt_price_x64) {
                break
            };
            i = i + 1;
        };
        assert!(current_sqrt_price_x64 == sqrt_price_x64);

        let out = self.mock_dex_pool.swap_x_in(balance::create_for_testing(amount_x_in));
        destroy_(out);
    };
}

/* ================= deleverage functions ================= */

public fun create_deleverage_ticket(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_delta_l: u128,
): (DeleverageTicket, ActionRequest) {
    mock_dex_integration::create_deleverage_ticket(
        position,
        config,
        price_info,
        debt_info,
        &mut self.mock_dex_pool,
        max_delta_l,
        self.scenario.ctx(),
    )
}

public fun deleverage(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    max_delta_l: u128,
): ActionRequest {
    mock_dex_integration::deleverage(
        position,
        config,
        price_info,
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.mock_dex_pool,
        max_delta_l,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun deleverage_ticket_repay_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
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
    position: &mut Position<SUI, USDC, PositionKey>,
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

/* ================= deleverage helper functions ================= */

public fun create_deleverage_ticket_with_different_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_delta_l: u128,
): (DeleverageTicket, ActionRequest) {
    let mut different_pool = mock_dex::create_mock_dex_pool(
        self.mock_dex_pool.current_sqrt_price_x64(),
        50_00,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let (ticket, request) = mock_dex_integration::create_deleverage_ticket(
        position,
        config,
        price_info,
        debt_info,
        &mut different_pool,
        max_delta_l,
        self.scenario.ctx(),
    );

    destroy_(different_pool);
    (ticket, request)
}

public fun create_deleverage_ticket_for_liquidation_with_different_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
): DeleverageTicket {
    let mut different_pool = mock_dex::create_mock_dex_pool(
        self.mock_dex_pool.current_sqrt_price_x64(),
        50_00,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let ticket = mock_dex_integration::create_deleverage_ticket_for_liquidation(
        position,
        config,
        price_info,
        debt_info,
        &mut different_pool,
    );

    destroy_(different_pool);
    ticket
}

public fun take_shared_position_by_cap(
    self: &mut Setup,
    position_cap: &PositionCap,
): Position<SUI, USDC, PositionKey> {
    self.scenario.take_shared_by_id(position_cap.position_id())
}

public fun deleverage_ticket_repay_x_with_wrong_supply_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    ticket: &mut DeleverageTicket,
) {
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_sui_supply_pool_for_testing();

    // This should abort with e_supply_pool_mismatch
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
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    ticket: &mut DeleverageTicket,
) {
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

/* ================= liquidation functions ================= */

public fun create_deleverage_ticket_for_liquidation(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
): DeleverageTicket {
    mock_dex_integration::create_deleverage_ticket_for_liquidation(
        position,
        config,
        price_info,
        debt_info,
        &mut self.mock_dex_pool,
    )
}

public fun deleverage_for_liquidation(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
) {
    mock_dex_integration::deleverage_for_liquidation(
        position,
        config,
        price_info,
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.mock_dex_pool,
        &self.clock,
    );
}

public fun calc_liquidate_col_x(
    _: &Setup,
    position: &Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_amount: u64,
): (u64, u64) {
    mock_dex_integration::calc_liquidate_col_x(
        position,
        config,
        price_info,
        debt_info,
        max_amount,
    )
}

public fun calc_liquidate_col_y(
    _: &Setup,
    position: &Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_amount: u64,
): (u64, u64) {
    mock_dex_integration::calc_liquidate_col_y(
        position,
        config,
        price_info,
        debt_info,
        max_amount,
    )
}

public fun liquidate_col_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_y: &mut Balance<USDC>,
): Balance<SUI> {
    mock_dex_integration::liquidate_col_x(
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
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_x: &mut Balance<SUI>,
): Balance<USDC> {
    mock_dex_integration::liquidate_col_y(
        position,
        config,
        price_info,
        debt_info,
        repayment_x,
        &mut self.supply_pool_x,
        &self.clock,
    )
}

/* ================= tests ================= */

#[test]
public fun swap_to_sqrt_price_x64_is_correct() {
    let mut setup = new_setup();
    let pool = &mut setup.mock_dex_pool;

    // position in partial range
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );
    {
        let liquidity = 100000000000;
        let (amt_x, amt_y) = pool.calc_deposit_amounts_by_liquidity(
            tick_a,
            tick_b,
            liquidity,
        );
        let balance_x = balance::create_for_testing(amt_x);
        let balance_y = balance::create_for_testing(amt_y);

        let position = pool.open_position(
            tick_a,
            tick_b,
            liquidity,
            balance_x,
            balance_y,
            setup.scenario.ctx(),
        );

        destroy_(position);
    };

    // move up within range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_55);
        setup.swap_to_sqrt_price_x64(want_price);

        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            setup.mock_dex_pool.current_sqrt_price_x64(),
            6,
        );

        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move up out of range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(7_00);
        setup.swap_to_sqrt_price_x64(want_price);

        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            setup.mock_dex_pool.current_sqrt_price_x64(),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move down within range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_45);
        setup.swap_to_sqrt_price_x64(want_price);
        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            setup.mock_dex_pool.current_sqrt_price_x64(),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move down out of range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(0_50);
        setup.swap_to_sqrt_price_x64(want_price);
        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            setup.mock_dex_pool.current_sqrt_price_x64(),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move up out of range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_00);
        setup.swap_to_sqrt_price_x64(want_price);
        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            setup.mock_dex_pool.current_sqrt_price_x64(),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };
    // move down out of range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(0_40);
        setup.swap_to_sqrt_price_x64(want_price);
        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            setup.mock_dex_pool.current_sqrt_price_x64(),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };

    setup.destroy();
}

/* ================= bad debt functions ================= */

public fun repay_bad_debt_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<SUI>,
): ActionRequest {
    mock_dex_integration::repay_bad_debt_x(
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
    position: &mut Position<SUI, USDC, PositionKey>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<USDC>,
): ActionRequest {
    mock_dex_integration::repay_bad_debt_y(
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

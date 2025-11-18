#[test_only]
module kai_leverage::position_core_cetus_test_setup;

use access_management::access::{ActionRequest, PackageAdmin};
use cetus_clmm::config::{Self as cetus_config, GlobalConfig as CetusGlobalConfig};
use cetus_clmm::pool::{Self as cetus_pool, Pool as CetusPool};
use cetus_clmm::position::Position as CetusPosition;
use cetus_clmm::rewarder::RewarderGlobalVault;
use integer_mate::i32::{Self, I32};
use kai_leverage::cetus;
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
    cetus_pool: CetusPool<SUI, USDC>,
    cetus_global_config: CetusGlobalConfig,
    cetus_vault: RewarderGlobalVault,
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

public fun clmm_pool(setup: &Setup): &CetusPool<SUI, USDC> {
    &setup.cetus_pool
}

public fun config_id(setup: &Setup): ID {
    setup.config_id
}

public fun ctx(self: &mut Setup): &mut TxContext {
    self.scenario.ctx()
}

public fun create_cetus_pool_for_testing(
    current_sqrt_price_x64: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): CetusPool<SUI, USDC> {
    let tick_spacing = 1;
    let fee_rate = 500000; // 50%
    let fee_growth_global_a = 0;
    let fee_growth_global_b = 0;
    let fee_protocol_coin_a = 0;
    let fee_protocol_coin_b = 0;
    let liquidity = 0;
    let balance_a = 0;
    let balance_b = 0;
    cetus_pool::new_pool_custom<SUI, USDC>(
        tick_spacing,
        current_sqrt_price_x64,
        fee_rate,
        fee_growth_global_a,
        fee_growth_global_b,
        fee_protocol_coin_a,
        fee_protocol_coin_b,
        liquidity,
        balance_a,
        balance_b,
        clock,
        ctx,
    )
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
        |current_sqrt_price_x64, clock, ctx| -> CetusPool<SUI, USDC> {
            create_cetus_pool_for_testing(
                current_sqrt_price_x64,
                clock,
                ctx,
            )
        },
    );

    let (admin_cap, cetus_global_config) = cetus_config::new_global_config_for_test(
        scenario.ctx(),
        0,
    );
    destroy_(admin_cap);

    let mut cetus_vault = cetus_clmm::rewarder::new_vault_for_test(scenario.ctx());
    cetus_clmm::rewarder::deposit_reward<SUI>(
        &cetus_global_config,
        &mut cetus_vault,
        balance::create_for_testing(1000000_000000000), // 1M SUI
    );
    cetus_pool::initialize_rewarder<SUI, USDC, SUI>(
        &cetus_global_config,
        &mut pool,
        scenario.ctx(),
    );
    let emissions_per_second = 1_000000000 << 64; // 1 SUI per second
    cetus_pool::update_emission<SUI, USDC, SUI>(
        &cetus_global_config,
        &mut pool,
        &cetus_vault,
        emissions_per_second,
        &clock,
        scenario.ctx(),
    );

    // create a position in a full range to facilitate swaps
    let tick_a = i32::neg_from(443636);
    let tick_b = i32::from(443636);
    let liquidity = 100000000000;
    let (amt_x, amt_y) = cetus::calc_deposit_amounts_by_liquidity(
        &pool,
        tick_a,
        tick_b,
        liquidity,
    );
    let balance_x0 = balance::create_for_testing(amt_x);
    let balance_y0 = balance::create_for_testing(amt_y);

    let mut lp_position = cetus_pool::open_position(
        &cetus_global_config,
        &mut pool,
        i32::as_u32(tick_a),
        i32::as_u32(tick_b),
        scenario.ctx(),
    );
    let receipt = cetus_pool::add_liquidity(
        &cetus_global_config,
        &mut pool,
        &mut lp_position,
        liquidity,
        &clock,
    );
    cetus_pool::repay_add_liquidity(
        &cetus_global_config,
        &mut pool,
        balance_x0,
        balance_y0,
        receipt,
    );
    destroy_(lp_position);

    Setup {
        scenario,
        package_admin,
        clock,
        sui_pio,
        usdc_pio,
        supply_pool_x,
        supply_pool_y,
        cetus_pool: pool,
        cetus_global_config,
        cetus_vault,
        config_id,
    }
}

public fun next_tx(self: &mut Setup, sender: address): TransactionEffects {
    self.scenario.next_tx(sender)
}

public fun take_shared_position(self: &Setup): Position<SUI, USDC, CetusPosition> {
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
    cetus::create_position_ticket_v2(
        &mut self.cetus_pool,
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
    let mut different_pool = create_cetus_pool_for_testing(
        self.cetus_pool.current_sqrt_price(),
        &self.clock,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let ticket = cetus::create_position_ticket_v2(
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
    cetus::borrow_for_position_x(ticket, config, &mut self.supply_pool_x, &self.clock);
}

public fun borrow_for_position_y(
    self: &mut Setup,
    ticket: &mut CreatePositionTicket<SUI, USDC, I32>,
    config: &PositionConfig,
) {
    cetus::borrow_for_position_y(ticket, config, &mut self.supply_pool_y, &self.clock);
}

public fun create_position(
    self: &mut Setup,
    config: &PositionConfig,
    ticket: CreatePositionTicket<SUI, USDC, I32>,
    creation_fee: Balance<SUI>,
): PositionCap {
    cetus::create_position(
        config,
        ticket,
        &mut self.cetus_pool,
        &self.cetus_global_config,
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
    let mut different_pool = create_cetus_pool_for_testing(
        self.cetus_pool.current_sqrt_price(),
        &self.clock,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let cap = cetus::create_position(
        config,
        ticket,
        &mut different_pool,
        &self.cetus_global_config,
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
    position: &Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
): PositionModel {
    cetus::position_model(position, config, &self.debt_info(config))
}

public fun get_lp_fee_amounts(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
): (u64, u64) {
    cetus_pool::calculate_and_update_fee(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        object::id(position.lp_position()),
    )
}

public fun get_lp_reward_amount<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
): u64 {
    cetus_pool::calculate_and_update_reward<_, _, R>(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        object::id(position.lp_position()),
        &self.clock,
    )
}

public fun rebalance_collect_fee(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
): (Balance<SUI>, Balance<USDC>) {
    cetus::rebalance_collect_fee(
        position,
        config,
        rebalance_receipt,
        &mut self.cetus_pool,
        &self.cetus_global_config,
    )
}

public fun rebalance_collect_reward<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
): Balance<R> {
    cetus::rebalance_collect_reward(
        position,
        config,
        rebalance_receipt,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        &mut self.cetus_vault,
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    rebalance_receipt: &mut RebalanceReceipt,
    delta_l: u128,
    balance_x: Balance<SUI>,
    balance_y: Balance<USDC>,
) {
    let debt_info = self.debt_info(config);
    let receipt = cetus::rebalance_add_liquidity(
        position,
        config,
        rebalance_receipt,
        &self.price_info(),
        &debt_info,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        delta_l,
        &self.clock,
    );
    cetus_pool::repay_add_liquidity(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        balance_x,
        balance_y,
        receipt,
    );
}

public fun update_pio_timestamps(self: &mut Setup) {
    pyth_test_util::set_pyth_pio_timestamp(&mut self.sui_pio, self.clock.timestamp_ms() / 1000);
    pyth_test_util::set_pyth_pio_timestamp(&mut self.usdc_pio, self.clock.timestamp_ms() / 1000);
}

public fun sync_pyth_pio_price_x_to_pool(self: &mut Setup) {
    let current_sqrt_price_x64 = self.cetus_pool.current_sqrt_price();
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
    position: &mut Position<SUI, USDC, CetusPosition>,
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
    position: &mut Position<SUI, USDC, CetusPosition>,
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    cap: &PositionCap,
    balance: &mut Balance<SUI>,
) {
    core::repay_debt_x(position, cap, balance, &mut self.supply_pool_x, &self.clock);
}

public fun repay_debt_y(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    cap: &PositionCap,
    balance: &mut Balance<USDC>,
) {
    core::repay_debt_y(position, cap, balance, &mut self.supply_pool_y, &self.clock);
}

public fun reduce(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    factor_x64: u128,
): (Balance<SUI>, Balance<USDC>, ReductionRepaymentTicket<SSUI, SUSDC>) {
    cetus::reduce(
        position,
        config,
        cap,
        &self.price_info(),
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.cetus_pool,
        &self.cetus_global_config,
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    delta_l: u128,
    balance_x: Balance<SUI>,
    balance_y: Balance<USDC>,
) {
    let receipt = cetus::add_liquidity(
        position,
        config,
        cap,
        price_info,
        debt_info,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        delta_l,
        &self.clock,
    );
    cetus_pool::repay_add_liquidity(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        balance_x,
        balance_y,
        receipt,
    );
}

public fun add_liquidity_with_receipt(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    delta_l: u128,
) {
    let receipt = cetus::add_liquidity(
        position,
        config,
        cap,
        price_info,
        debt_info,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        delta_l,
        &self.clock,
    );
    let (amount_x, amount_y) = receipt.add_liquidity_pay_amount();
    cetus_pool::repay_add_liquidity(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        balance::create_for_testing(amount_x),
        balance::create_for_testing(amount_y),
        receipt,
    );
}

public fun owner_collect_fee(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
): (Balance<SUI>, Balance<USDC>) {
    cetus::owner_collect_fee(
        position,
        config,
        cap,
        &mut self.cetus_pool,
        &self.cetus_global_config,
    )
}

public fun owner_collect_reward<R>(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    cap: &PositionCap,
): Balance<R> {
    cetus::owner_collect_reward(
        position,
        config,
        cap,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        &mut self.cetus_vault,
        &self.clock,
    )
}

public fun delete_position(
    self: &mut Setup,
    position: Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    cap: PositionCap,
) {
    cetus::delete_position(
        position,
        config,
        cap,
        &mut self.cetus_pool,
        &self.cetus_global_config,
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
        cetus_pool,
        cetus_global_config,
        cetus_vault,
        config_id: _,
    } = setup;
    scenario.end();
    destroy_(package_admin);
    destroy_(clock);
    destroy_(sui_pio);
    destroy_(usdc_pio);
    destroy_(supply_pool_x);
    destroy_(supply_pool_y);
    destroy_(cetus_pool);
    destroy_(cetus_global_config);
    destroy_(cetus_vault);
}

public fun swap_x_in(self: &mut Setup, balance_x: Balance<SUI>): Balance<USDC> {
    let a2b = true;
    let by_amount_in = true;
    let amount = balance_x.value();
    let sqrt_price_limit = 4295048016; // MIN_SQRT_PRICE_X64

    let (balance_x_out, balance_y_out, receipt) = cetus_pool::flash_swap(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        &self.clock,
    );
    balance_x_out.destroy_zero();

    cetus_pool::repay_flash_swap(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        balance_x,
        balance::create_for_testing(0),
        receipt,
    );

    balance_y_out
}

public fun swap_y_in(self: &mut Setup, balance_y: Balance<USDC>): Balance<SUI> {
    let a2b = false;
    let by_amount_in = true;
    let amount_y_in = balance::value(&balance_y);
    let sqrt_price_limit = 79226673515401279992447579055; // MAX_SQRT_PRICE_X64

    let (balance_x_out, balance_y_out, receipt) = cetus_pool::flash_swap(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        a2b,
        by_amount_in,
        amount_y_in,
        sqrt_price_limit,
        &self.clock,
    );
    balance_y_out.destroy_zero();

    cetus_pool::repay_flash_swap(
        &self.cetus_global_config,
        &mut self.cetus_pool,
        balance::create_for_testing(0),
        balance_y,
        receipt,
    );

    balance_x_out
}

public fun swap_to_sqrt_price_x64(self: &mut Setup, sqrt_price_x64: u128) {
    let current_sqrt_price_x64 = self.cetus_pool.current_sqrt_price();
    if (current_sqrt_price_x64 == sqrt_price_x64) {
        return
    };
    let pool = &self.cetus_pool;
    let tick_manager = pool.tick_manager();

    let a2b = sqrt_price_x64 < current_sqrt_price_x64;
    let mut amount_in = 0;
    let mut current_sqrt_price_x64 = current_sqrt_price_x64;
    let mut current_tick_index = mock_dex_math::get_tick_at_sqrt_price(current_sqrt_price_x64);
    let mut current_liquidity = pool.liquidity();

    while (current_sqrt_price_x64 != sqrt_price_x64) {
        let next_score = tick_manager
            .first_score_for_swap(
                current_tick_index,
                a2b,
            )
            .borrow();
        let (next_tick, _) = tick_manager.borrow_tick_for_swap(next_score, a2b);

        let next_sqrt_price_x64 = if (a2b) {
            u128::max(
                next_tick.sqrt_price(),
                sqrt_price_x64,
            )
        } else {
            u128::min(
                next_tick.sqrt_price(),
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
        amount_in = amount_in + util::muldiv_round_up(amount, 1000000, pool.fee_rate());

        if (next_sqrt_price_x64 == next_tick.sqrt_price()) {
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
            current_tick_index = if (a2b) {
                next_tick.index().sub(i32::from(1))
            } else {
                next_tick.index()
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_delta_l: u128,
): (DeleverageTicket, ActionRequest) {
    cetus::create_deleverage_ticket(
        position,
        config,
        price_info,
        debt_info,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        max_delta_l,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun deleverage(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    max_delta_l: u128,
): ActionRequest {
    cetus::deleverage(
        position,
        config,
        price_info,
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        max_delta_l,
        &self.clock,
        self.scenario.ctx(),
    )
}

public fun deleverage_ticket_repay_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
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
    position: &mut Position<SUI, USDC, CetusPosition>,
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
): DeleverageTicket {
    cetus::create_deleverage_ticket_for_liquidation(
        position,
        config,
        price_info,
        debt_info,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        &self.clock,
    )
}

public fun deleverage_for_liquidation(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
) {
    cetus::deleverage_for_liquidation(
        position,
        config,
        price_info,
        &mut self.supply_pool_x,
        &mut self.supply_pool_y,
        &mut self.cetus_pool,
        &self.cetus_global_config,
        &self.clock,
    );
}

public fun calc_liquidate_col_x(
    _: &Setup,
    position: &Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_amount: u64,
): (u64, u64) {
    cetus::calc_liquidate_col_x(
        position,
        config,
        price_info,
        debt_info,
        max_amount,
    )
}

public fun calc_liquidate_col_y(
    _: &Setup,
    position: &Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_amount: u64,
): (u64, u64) {
    cetus::calc_liquidate_col_y(
        position,
        config,
        price_info,
        debt_info,
        max_amount,
    )
}

public fun liquidate_col_x(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_y: &mut Balance<USDC>,
): Balance<SUI> {
    cetus::liquidate_col_x(
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_x: &mut Balance<SUI>,
): Balance<USDC> {
    cetus::liquidate_col_y(
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_y: &mut Balance<USDC>,
): Balance<SUI> {
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_usdc_supply_pool_for_testing();

    // This should abort with e_supply_pool_mismatch
    let reward_x = cetus::liquidate_col_x(
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment_x: &mut Balance<SUI>,
): Balance<USDC> {
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_sui_supply_pool_for_testing();

    // This should abort with e_supply_pool_mismatch
    let reward_y = cetus::liquidate_col_y(
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

/* ================= tests ================= */

#[test]
public fun swap_to_sqrt_price_x64_is_correct() {
    let mut setup = new_setup();

    // position in partial range
    {
        let tick_a = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
        );
        let tick_b = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
        );
        let liquidity = 100000000000;
        let (amt_x, amt_y) = cetus::calc_deposit_amounts_by_liquidity(
            &setup.cetus_pool,
            tick_a,
            tick_b,
            liquidity,
        );
        let balance_x0 = balance::create_for_testing(amt_x);
        let balance_y0 = balance::create_for_testing(amt_y);

        let mut lp_position = cetus_pool::open_position(
            &setup.cetus_global_config,
            &mut setup.cetus_pool,
            i32::as_u32(tick_a),
            i32::as_u32(tick_b),
            setup.scenario.ctx(),
        );
        let clock = &setup.clock;
        let receipt = cetus_pool::add_liquidity(
            &setup.cetus_global_config,
            &mut setup.cetus_pool,
            &mut lp_position,
            liquidity,
            clock,
        );
        cetus_pool::repay_add_liquidity(
            &setup.cetus_global_config,
            &mut setup.cetus_pool,
            balance_x0,
            balance_y0,
            receipt,
        );

        destroy_(lp_position);
    };

    // move up within range
    {
        let want_price = price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_55);
        setup.swap_to_sqrt_price_x64(want_price);

        let act_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(
            setup.cetus_pool.current_sqrt_price(),
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
            setup.cetus_pool.current_sqrt_price(),
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
            setup.cetus_pool.current_sqrt_price(),
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
            setup.cetus_pool.current_sqrt_price(),
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
            setup.cetus_pool.current_sqrt_price(),
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
            setup.cetus_pool.current_sqrt_price(),
            6,
        );
        let want_price_mul_6 = sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(want_price, 6);
        assert!(act_price_mul_6 == want_price_mul_6);
    };

    setup.destroy();
}

/* ================= deleverage helper functions ================= */

public fun create_deleverage_ticket_with_different_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_delta_l: u128,
): (DeleverageTicket, ActionRequest) {
    let mut different_pool = create_cetus_pool_for_testing(
        self.cetus_pool.current_sqrt_price(),
        &self.clock,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let (ticket, request) = cetus::create_deleverage_ticket(
        position,
        config,
        price_info,
        debt_info,
        &mut different_pool,
        &self.cetus_global_config,
        max_delta_l,
        &self.clock,
        self.scenario.ctx(),
    );

    destroy_(different_pool);
    (ticket, request)
}

public fun create_deleverage_ticket_for_liquidation_with_different_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &mut PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
): DeleverageTicket {
    let mut different_pool = create_cetus_pool_for_testing(
        self.cetus_pool.current_sqrt_price(),
        &self.clock,
        self.scenario.ctx(),
    );

    // This should abort with e_invalid_pool
    let ticket = cetus::create_deleverage_ticket_for_liquidation(
        position,
        config,
        price_info,
        debt_info,
        &mut different_pool,
        &self.cetus_global_config,
        &self.clock,
    );

    destroy_(different_pool);
    ticket
}

public fun take_shared_position_by_cap(
    self: &mut Setup,
    position_cap: &PositionCap,
): Position<SUI, USDC, CetusPosition> {
    self.scenario.take_shared_by_id(position_cap.position_id())
}

public fun deleverage_ticket_repay_x_with_wrong_supply_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
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
    position: &mut Position<SUI, USDC, CetusPosition>,
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<SUI>,
): ActionRequest {
    cetus::repay_bad_debt_x(
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
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<USDC>,
): ActionRequest {
    cetus::repay_bad_debt_y(
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

public fun repay_bad_debt_x_with_wrong_supply_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<SUI>,
): ActionRequest {
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_sui_supply_pool_for_testing();

    // This should abort with e_supply_pool_mismatch
    let request = cetus::repay_bad_debt_x(
        position,
        config,
        price_info,
        debt_info,
        &mut wrong_supply_pool,
        repayment,
        &self.clock,
        self.scenario.ctx(),
    );
    destroy_(wrong_supply_pool);
    request
}

public fun repay_bad_debt_y_with_wrong_supply_pool(
    self: &mut Setup,
    position: &mut Position<SUI, USDC, CetusPosition>,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &mut Balance<USDC>,
): ActionRequest {
    let mut wrong_supply_pool = supply_pool_tests::create_wrong_usdc_supply_pool_for_testing();

    // This should abort with e_supply_pool_mismatch
    let request = cetus::repay_bad_debt_y(
        position,
        config,
        price_info,
        debt_info,
        &mut wrong_supply_pool,
        repayment,
        &self.clock,
        self.scenario.ctx(),
    );
    destroy_(wrong_supply_pool);
    request
}

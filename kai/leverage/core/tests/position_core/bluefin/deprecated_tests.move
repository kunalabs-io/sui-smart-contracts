// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Pins that the deprecated Bluefin adapter functions abort with `e_function_deprecated`.
/// One test per distinct stub signature family; the remaining stubs are identical
/// mirrors (x/y twins, `_for_liquidation` twins).
#[test_only, allow(deprecated_usage)]
module kai_leverage::position_core_bluefin_deprecated_tests;

use bluefin_spot::admin as bluefin_admin;
use bluefin_spot::config::{Self as bluefin_config, GlobalConfig as BluefinGlobalConfig};
use bluefin_spot::pool::Pool as BluefinPool;
use integer_mate::i32;
use kai_leverage::bluefin_spot;
use kai_leverage::debt_info::{Self, DebtInfo};
use kai_leverage::position_core_bluefin_test_setup;
use kai_leverage::position_core_clmm::{Self as core, PositionConfig};
use kai_leverage::position_core_liquidate_test_macros as macros;
use kai_leverage::pyth;
use kai_leverage::supply_pool_tests;
use std::unit_test::destroy;
use sui::balance;
use sui::clock::{Self, Clock};
use sui::sui::SUI;
use usdc::usdc::USDC;

/// The deprecated stubs abort before reading any of their arguments, so throwaway
/// values are enough for the calls to type-check.
fun throwaway_env(ctx: &mut TxContext): (Clock, BluefinPool<SUI, USDC>, BluefinGlobalConfig) {
    let clock = clock::create_for_testing(ctx);
    let admin_cap = bluefin_admin::get_admin_cap(ctx);
    let mut global_config = bluefin_config::create_config(ctx);
    bluefin_admin::set_pool_creation_fee<USDC>(&admin_cap, &mut global_config, 100000000, ctx);
    destroy(admin_cap);
    let pool = position_core_bluefin_test_setup::create_bluefin_pool_for_testing(
        1 << 64,
        &mut global_config,
        &clock,
        ctx,
    );
    (clock, pool, global_config)
}

fun throwaway_debt_info(): DebtInfo {
    debt_info::empty(object::id_from_address(@0x0))
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun create_position_ticket_v2_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    setup.next_tx(@0);
    let mut config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, mut pool, _global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);

    let _ticket = bluefin_spot::create_position_ticket_v2(
        &mut pool,
        &mut config,
        i32::zero(),
        i32::from(1),
        balance::zero(),
        balance::zero(),
        0,
        &price_info,
        &clock,
        ctx,
    );

    abort 0
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun create_deleverage_ticket_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    let position_cap = macros::create_position_for_liquidate_col_x_tests!(&mut setup);

    setup.next_tx(@0);
    let mut position = setup.take_shared_position_by_cap(&position_cap);
    let mut config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, mut pool, global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);
    let dbt = throwaway_debt_info();

    let (_ticket, _request) = bluefin_spot::create_deleverage_ticket(
        &mut position,
        &mut config,
        &price_info,
        &dbt,
        &mut pool,
        &global_config,
        0,
        &clock,
        ctx,
    );

    abort 0
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun deleverage_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    let position_cap = macros::create_position_for_liquidate_col_x_tests!(&mut setup);

    setup.next_tx(@0);
    let mut position = setup.take_shared_position_by_cap(&position_cap);
    let mut config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, mut pool, global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);
    let mut supply_pool_x = supply_pool_tests::create_wrong_sui_supply_pool_for_testing();
    let mut supply_pool_y = supply_pool_tests::create_wrong_usdc_supply_pool_for_testing();

    let _request = bluefin_spot::deleverage(
        &mut position,
        &mut config,
        &price_info,
        &mut supply_pool_x,
        &mut supply_pool_y,
        &mut pool,
        &global_config,
        0,
        &clock,
        ctx,
    );

    abort 0
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun liquidate_col_x_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    let position_cap = macros::create_position_for_liquidate_col_x_tests!(&mut setup);

    setup.next_tx(@0);
    let mut position = setup.take_shared_position_by_cap(&position_cap);
    let config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, _pool, _global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);
    let dbt = throwaway_debt_info();
    let mut supply_pool_y = supply_pool_tests::create_wrong_usdc_supply_pool_for_testing();
    let mut repayment = balance::zero();

    let _reward = bluefin_spot::liquidate_col_x(
        &mut position,
        &config,
        &price_info,
        &dbt,
        &mut repayment,
        &mut supply_pool_y,
        &clock,
    );

    abort 0
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun repay_bad_debt_x_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    let position_cap = macros::create_position_for_liquidate_col_x_tests!(&mut setup);

    setup.next_tx(@0);
    let mut position = setup.take_shared_position_by_cap(&position_cap);
    let config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, _pool, _global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);
    let dbt = throwaway_debt_info();
    let mut supply_pool_x = supply_pool_tests::create_wrong_sui_supply_pool_for_testing();
    let mut repayment = balance::zero();

    let _request = bluefin_spot::repay_bad_debt_x(
        &mut position,
        &config,
        &price_info,
        &dbt,
        &mut supply_pool_x,
        &mut repayment,
        &clock,
        ctx,
    );

    abort 0
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun reduce_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    let position_cap = macros::create_position_for_liquidate_col_x_tests!(&mut setup);

    setup.next_tx(@0);
    let mut position = setup.take_shared_position_by_cap(&position_cap);
    let mut config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, mut pool, global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);
    let mut supply_pool_x = supply_pool_tests::create_wrong_sui_supply_pool_for_testing();
    let mut supply_pool_y = supply_pool_tests::create_wrong_usdc_supply_pool_for_testing();

    let (_balance_x, _balance_y, _ticket) = bluefin_spot::reduce(
        &mut position,
        &mut config,
        &position_cap,
        &price_info,
        &mut supply_pool_x,
        &mut supply_pool_y,
        &mut pool,
        &global_config,
        0,
        &clock,
    );

    abort 0
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun add_liquidity_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    let position_cap = macros::create_position_for_liquidate_col_x_tests!(&mut setup);

    setup.next_tx(@0);
    let mut position = setup.take_shared_position_by_cap(&position_cap);
    let mut config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, mut pool, global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);
    let dbt = throwaway_debt_info();

    bluefin_spot::add_liquidity(
        &mut position,
        &mut config,
        &position_cap,
        &price_info,
        &dbt,
        &mut pool,
        &global_config,
        0,
        balance::zero(),
        balance::zero(),
        &clock,
    );

    abort 0
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun rebalance_add_liquidity_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    let position_cap = macros::create_position_for_liquidate_col_x_tests!(&mut setup);

    setup.next_tx(@0);
    let mut position = setup.take_shared_position_by_cap(&position_cap);
    let mut config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, mut pool, global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);
    let dbt = throwaway_debt_info();
    let (mut rebalance_receipt, request) = core::create_rebalance_receipt(
        &mut position,
        &config,
        ctx,
    );
    destroy(request);

    bluefin_spot::rebalance_add_liquidity(
        &mut position,
        &mut config,
        &mut rebalance_receipt,
        &price_info,
        &dbt,
        &mut pool,
        &global_config,
        0,
        balance::zero(),
        balance::zero(),
        &clock,
    );

    abort 0
}

#[test, expected_failure(abort_code = 30, location = bluefin_spot)] // e_function_deprecated
fun calc_liquidate_col_x_aborts_when_deprecated() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    let position_cap = macros::create_position_for_liquidate_col_x_tests!(&mut setup);

    setup.next_tx(@0);
    let position = setup.take_shared_position_by_cap(&position_cap);
    let config = setup.scenario().take_shared<PositionConfig>();

    let ctx = &mut tx_context::dummy();
    let (clock, _pool, _global_config) = throwaway_env(ctx);
    let price_info = pyth::create(&clock);
    let dbt = throwaway_debt_info();

    let (_, _) = bluefin_spot::calc_liquidate_col_x(
        &position,
        &config,
        &price_info,
        &dbt,
        0,
    );

    abort 0
}

#[test_only]
module kai_leverage::position_core_create_position_tests;

use kai_leverage::mock_dex_integration;
use kai_leverage::mock_dex_math;
use kai_leverage::position_core_test_util::{
    Self,
    price_mul_100_human_to_sqrt_x64
};
use kai_leverage::pyth;
use kai_leverage::pyth_test_util;
use sui::balance;
use sui::clock;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

// Test the price deviation assertion failure in create_position_ticket!
// This tests the abort when price deviation is too high

#[test, expected_failure(abort_code = 31, location = mock_dex_integration)] // e_price_deviation_too_high
fun create_position_ticket_aborts_when_oracle_price_too_high() {
    let mut scenario = test_scenario::begin(@0);
    let package_admin = position_core_test_util::create_admin_for_testing(scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(1755000000000);

    let (
        mut sui_pio,
        usdc_pio,
        mut pool,
        supply_pool_x,
        supply_pool_y,
    ) = position_core_test_util::initialize_config_for_testing(
        &mut scenario,
        &package_admin,
        &clock,
    );
    scenario.next_tx(@0);

    // Keep spot price same as pool (3.50), but set EMA to 4.60 (>30% above pool price)
    pyth_test_util::update_pyth_pio_price_human_mul_n(
        &mut sui_pio,
        3_50,
        4_60,
        2,
        &clock,
    );

    let mut config = scenario.take_shared();

    // Create position ticket - this should abort due to price deviation
    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;
    let principal_x = balance::create_for_testing(principal_x_amount);
    let principal_y = balance::create_for_testing(principal_y_amount);

    let delta_l = 663611732121;
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );

    let mut price_info = pyth::create(&clock);
    price_info.add(&sui_pio);
    price_info.add(&usdc_pio);

    // This should abort with e_price_deviation_too_high
    let ticket = mock_dex_integration::create_position_ticket(
        &mut pool,
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
        &clock,
        scenario.ctx(),
    );

    test_scenario::return_shared(config);
    scenario.end();

    destroy(ticket);
    destroy(pool);
    destroy(supply_pool_x);
    destroy(supply_pool_y);
    destroy(package_admin);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
}

#[test, expected_failure(abort_code = 31, location = mock_dex_integration)] // e_price_deviation_too_high
fun create_position_ticket_aborts_when_oracle_price_too_low() {
    let mut scenario = test_scenario::begin(@0);
    let package_admin = position_core_test_util::create_admin_for_testing(scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(1755000000000);

    let (
        mut sui_pio,
        usdc_pio,
        mut pool,
        supply_pool_x,
        supply_pool_y,
    ) = position_core_test_util::initialize_config_for_testing(
        &mut scenario,
        &package_admin,
        &clock,
    );
    scenario.next_tx(@0);

    // Keep spot price same as pool (3.50), but set EMA to 2.40 (<30% below pool price)
    pyth_test_util::update_pyth_pio_price_human_mul_n(
        &mut sui_pio,
        3_50,
        2_40,
        2,
        &clock,
    );

    let mut config = scenario.take_shared();

    // Create position ticket - this should abort due to price deviation
    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;
    let principal_x = balance::create_for_testing(principal_x_amount);
    let principal_y = balance::create_for_testing(principal_y_amount);

    let delta_l = 663611732121;
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );

    let mut price_info = pyth::create(&clock);
    price_info.add(&sui_pio);
    price_info.add(&usdc_pio);

    // This should abort with e_price_deviation_too_high
    let ticket = mock_dex_integration::create_position_ticket(
        &mut pool,
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
        &clock,
        scenario.ctx(),
    );

    test_scenario::return_shared(config);
    scenario.end();

    destroy(ticket);
    destroy(pool);
    destroy(supply_pool_x);
    destroy(supply_pool_y);
    destroy(package_admin);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
}

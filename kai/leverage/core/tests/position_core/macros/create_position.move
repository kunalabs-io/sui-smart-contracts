#[test_only]
module kai_leverage::position_core_create_position_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::PositionConfig;
use kai_leverage::position_core_test_util::price_mul_100_human_to_sqrt_x64;
use sui::balance;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

public macro fun create_position_ticket_aborts_when_oracle_price_too_high<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    // Keep spot price same as pool (3.50), but set EMA to 4.60 (>30% above pool price)
    setup.update_pyth_pio_price_human_mul_n(
        3_50,
        4_60,
        2,
    );

    let mut config = setup.scenario().take_shared<PositionConfig>();

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

    let price_info = setup.price_info();

    // This should abort with e_price_deviation_too_high
    let ticket = setup.create_position_ticket(
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
    );

    test_scenario::return_shared(config);
    destroy(ticket);
}

public macro fun create_position_ticket_aborts_when_oracle_price_too_low<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    // Keep spot price same as pool (3.50), but set EMA to 2.40 (<30% below pool price)
    setup.update_pyth_pio_price_human_mul_n(
        3_50,
        2_40,
        2,
    );

    let mut config = setup.scenario().take_shared<PositionConfig>();

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

    let price_info = setup.price_info();

    // This should abort with e_price_deviation_too_high
    let ticket = setup.create_position_ticket(
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
    );

    test_scenario::return_shared(config);
    destroy(ticket);
}

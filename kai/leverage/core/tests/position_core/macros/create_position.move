#[test_only]
module kai_leverage::position_core_create_position_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{Self, PositionConfig};
use kai_leverage::position_core_test_util::{
    price_mul_100_human_to_sqrt_x64,
    integer_mate_i32_tick_add_int
};
use sui::balance;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;
use sui::bcs;

use fun integer_mate_i32_tick_add_int as integer_mate::i32::I32.add_int;

// cetus
use fun kai_leverage::cetus::calc_deposit_amounts_by_liquidity as
    cetus_clmm::pool::Pool.calc_deposit_amounts_by_liquidity;

// bluefin
use fun kai_leverage::bluefin_spot::calc_deposit_amounts_by_liquidity as
    bluefin_spot::pool::Pool.calc_deposit_amounts_by_liquidity;

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

public macro fun create_position_ticket_aborts_when_new_positions_not_allowed<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    let mut config = setup.scenario().take_shared<PositionConfig>();

    // Disable new positions
    config.set_allow_new_positions(false, setup.ctx()).admin_approve_request(setup.package_admin());

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

    // This should abort with e_new_positions_not_allowed
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

public macro fun create_position_ticket_aborts_when_invalid_pool<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    setup.next_tx(@0);

    let mut config = setup.scenario().take_shared<PositionConfig>();

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

    // This should abort with e_new_positions_not_allowed
    let ticket = setup.create_position_ticket_with_different_pool(
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

public macro fun create_position_ticket_aborts_when_position_size_limit_exceeded<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    let mut config = setup.scenario().take_shared<PositionConfig>();

    // Set max_position_l to a value less than our delta_l
    config
        .set_max_position_l(600000000000, setup.ctx())
        .admin_approve_request(setup.package_admin());

    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;
    let principal_x = balance::create_for_testing(principal_x_amount);
    let principal_y = balance::create_for_testing(principal_y_amount);

    let delta_l = 663611732121; // This exceeds the limit
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );

    let price_info = setup.price_info();

    // This should abort with e_position_size_limit_exceeded
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

public macro fun create_position_ticket_aborts_when_vault_global_size_limit_exceeded<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    let mut config = setup.scenario().take_shared<PositionConfig>();

    // Set max_global_l to a value less than our delta_l
    config.set_max_global_l(600000000000, setup.ctx()).admin_approve_request(setup.package_admin());

    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;
    let principal_x = balance::create_for_testing(principal_x_amount);
    let principal_y = balance::create_for_testing(principal_y_amount);

    let delta_l = 663611732121; // This exceeds the global limit
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );

    let price_info = setup.price_info();

    // This should abort with e_vault_global_size_limit_exceeded
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

public macro fun create_position_ticket_aborts_when_tick_a_above_current_tick<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    let mut config = setup.scenario().take_shared<PositionConfig>();

    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;
    let principal_x = balance::create_for_testing(principal_x_amount);
    let principal_y = balance::create_for_testing(principal_y_amount);

    let delta_l = 663611732121;
    // Set tick_a above current pool tick - this should fail
    let tick_a = setup.clmm_pool().current_tick_index().add_int(1);
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_80),
    );

    let price_info = setup.price_info();

    // This should abort with e_invalid_tick_range
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

public macro fun create_position_ticket_aborts_when_tick_b_at_or_below_current_tick<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    let mut config = setup.scenario().take_shared<PositionConfig>();

    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;
    let principal_x = balance::create_for_testing(principal_x_amount);
    let principal_y = balance::create_for_testing(principal_y_amount);

    let delta_l = 663611732121;
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_20),
    );
    // Set tick_b at current pool tick - this should fail
    let tick_b = setup.clmm_pool().current_tick_index();

    let price_info = setup.price_info();

    // This should abort with e_invalid_tick_range
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

public macro fun create_position_ticket_aborts_when_liq_margin_too_low<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    let mut config = setup.scenario().take_shared<PositionConfig>();

    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;
    let principal_x = balance::create_for_testing(principal_x_amount);
    let principal_y = balance::create_for_testing(principal_y_amount);

    // Increase delta_l by 1 to make liquidation margin insufficient
    let delta_l = 663611732122; // 1 more than standard 663611732121
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );

    let price_info = setup.price_info();

    // This should abort with e_liq_margin_too_low
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

public macro fun create_position_ticket_aborts_when_mint_init_margin_too_low<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    let mut config = setup.scenario().take_shared<PositionConfig>();

    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;
    let principal_x = balance::create_for_testing(principal_x_amount);
    let principal_y = balance::create_for_testing(principal_y_amount);

    let delta_l = 28380231290;
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_00),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_00),
    );

    let price_info = setup.price_info();

    // This should abort with e_liq_margin_too_low
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

public macro fun borrow_for_position_x_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // create different config
    setup.next_tx(@0);
    {
        let (_, request) = position_core_clmm::create_empty_config(
            object::id(setup.clmm_pool()),
            setup.ctx(),
        );
        request.admin_approve_request(setup.package_admin());
    };

    setup.next_tx(@0);
    {
        let invalid_config = setup.scenario().take_shared<PositionConfig>();

        let mut config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());
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
        let mut ticket = setup.create_position_ticket(
            &mut config,
            tick_a,
            tick_b,
            principal_x,
            principal_y,
            delta_l,
            &price_info,
        );

        // aborts with e_invalid_config
        setup.borrow_for_position_x(&mut ticket, &invalid_config);

        test_scenario::return_shared(invalid_config);
        test_scenario::return_shared(config);
        destroy(ticket);
    };
}

public macro fun borrow_for_position_y_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // create different config
    setup.next_tx(@0);
    {
        let (_, request) = position_core_clmm::create_empty_config(
            object::id(setup.clmm_pool()),
            setup.ctx(),
        );
        request.admin_approve_request(setup.package_admin());
    };

    setup.next_tx(@0);
    {
        let invalid_config = setup.scenario().take_shared<PositionConfig>();

        let mut config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());
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
        let mut ticket = setup.create_position_ticket(
            &mut config,
            tick_a,
            tick_b,
            principal_x,
            principal_y,
            delta_l,
            &price_info,
        );

        // aborts with e_invalid_config
        setup.borrow_for_position_y(&mut ticket, &invalid_config);

        test_scenario::return_shared(invalid_config);
        test_scenario::return_shared(config);
        destroy(ticket);
    };
}

public macro fun borrow_for_position_x_is_idempotent<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    // Create a valid ticket first
    let mut config = setup.scenario().take_shared<PositionConfig>();
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
    let mut ticket = setup.create_position_ticket(
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
    );

    setup.borrow_for_position_x(&mut ticket, &config);
    let ticket_before = bcs::to_bytes(&ticket);
    setup.borrow_for_position_x(&mut ticket, &config);
    let ticket_after = bcs::to_bytes(&ticket);

    assert!(ticket_before == ticket_after);

    test_scenario::return_shared(config);
    destroy(ticket);
}

public macro fun borrow_for_position_y_is_idempotent<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    // Create a valid ticket first
    let mut config = setup.scenario().take_shared<PositionConfig>();
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
    let mut ticket = setup.create_position_ticket(
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
    );

    setup.borrow_for_position_y(&mut ticket, &config);
    let ticket_before = bcs::to_bytes(&ticket);
    setup.borrow_for_position_y(&mut ticket, &config);
    let ticket_after = bcs::to_bytes(&ticket);

    assert!(ticket_before == ticket_after);

    test_scenario::return_shared(config);
    destroy(ticket);
}


public macro fun create_position_aborts_when_invalid_creation_fee_amount<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    setup.next_tx(@0);

    // Create a valid ticket first
    let mut config = setup.scenario().take_shared<PositionConfig>();
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
    let mut ticket = setup.create_position_ticket(
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
    );

    // Borrow funds
    setup.borrow_for_position_x(&mut ticket, &config);
    setup.borrow_for_position_y(&mut ticket, &config);

    // Pass wrong creation fee amount (too low)
    let position_cap = setup.create_position(
        &config,
        ticket,
        balance::create_for_testing(500000000), // Wrong amount (should be 1_000000000)
    );

    test_scenario::return_shared(config);
    destroy(position_cap);
}

public macro fun create_position_aborts_when_invalid_borrow_x<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    setup.next_tx(@0);

    // Create a valid ticket first
    let mut config = setup.scenario().take_shared<PositionConfig>();
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
    let mut ticket = setup.create_position_ticket(
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
    );

    // Borrow wrong amount for X (don't borrow at all)
    setup.borrow_for_position_y(&mut ticket, &config);
    // Skip borrowing X to create mismatch

    // This should abort with e_invalid_borrow
    let position_cap = setup.create_position(
        &config,
        ticket,
        balance::create_for_testing(1_000000000),
    );

    test_scenario::return_shared(config);
    destroy(position_cap);
}

public macro fun create_position_aborts_when_invalid_borrow_y<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    setup.next_tx(@0);

    // Create a valid ticket first
    let mut config = setup.scenario().take_shared<PositionConfig>();
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
    let mut ticket = setup.create_position_ticket(
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
    );

    // Borrow wrong amount for Y (don't borrow at all)
    setup.borrow_for_position_x(&mut ticket, &config);
    // Skip borrowing Y to create mismatch

    // This should abort with e_invalid_borrow
    let position_cap = setup.create_position(
        &config,
        ticket,
        balance::create_for_testing(1_000000000),
    );

    test_scenario::return_shared(config);
    destroy(position_cap);
}

public macro fun create_position_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // create different config
    setup.next_tx(@0);
    {
        let (_, request) = position_core_clmm::create_empty_config(
            object::id(setup.clmm_pool()),
            setup.ctx(),
        );
        request.admin_approve_request(setup.package_admin());
    };

    setup.next_tx(@0);
    {
        let invalid_config = setup.scenario().take_shared<PositionConfig>();

        let mut config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());
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
        let mut ticket = setup.create_position_ticket(
            &mut config,
            tick_a,
            tick_b,
            principal_x,
            principal_y,
            delta_l,
            &price_info,
        );

        // Borrow funds
        setup.borrow_for_position_x(&mut ticket, &config);
        setup.borrow_for_position_y(&mut ticket, &config);

        // This should abort with e_invalid_config
        let position_cap = setup.create_position(
            &invalid_config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(invalid_config);
        test_scenario::return_shared(config);
        destroy(position_cap);
    };
}

public macro fun create_position_aborts_when_invalid_pool<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    setup.next_tx(@0);

    // Create a valid ticket first
    let mut config = setup.scenario().take_shared<PositionConfig>();
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
    let mut ticket = setup.create_position_ticket(
        &mut config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        &price_info,
    );

    // Borrow funds
    setup.borrow_for_position_x(&mut ticket, &config);
    setup.borrow_for_position_y(&mut ticket, &config);

    // This should abort with e_invalid_pool because pool object ID doesn't match config's pool object ID
    let position_cap = setup.create_position_with_different_pool(
        &config,
        ticket,
        balance::create_for_testing(1_000000000),
    );

    test_scenario::return_shared(config);
    destroy(position_cap);
}

public macro fun create_position_is_correct_when_there_is_extra_collateral<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    let delta_l = 100000000000; // Much smaller than standard 663611732121
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );
    let principal_x_amount = 100_000000000;
    let principal_y_amount = 100_000000;

    setup.next_tx(@0);
    {
        // Create a valid ticket with small liquidity that doesn't require full borrowing
        let mut config = setup.scenario().take_shared<PositionConfig>();
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let price_info = setup.price_info();
        let mut ticket = setup.create_position_ticket(
            &mut config,
            tick_a,
            tick_b,
            principal_x,
            principal_y,
            delta_l,
            &price_info,
        );

        // Borrow funds
        setup.borrow_for_position_x(&mut ticket, &config);
        setup.borrow_for_position_y(&mut ticket, &config);

        // This should succeed - principal will be used to supplement borrowed amounts
        let position_cap = setup.create_position(
            &config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(config);
        destroy(position_cap);
    };

    setup.next_tx(@0);
    {
        let position = setup.take_shared_position();

        let (need_x, need_y) = setup.clmm_pool().calc_deposit_amounts_by_liquidity(
            tick_a, tick_b, delta_l
        );

        assert!(position.lp_position().liquidity() == delta_l);
        assert!(position.col_x().value() == principal_x_amount - need_x);
        assert!(position.col_y().value() == principal_y_amount - need_y);

        test_scenario::return_shared(position);
    };
}

#[test_only]
module kai_leverage::position_core_deleverage_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{Self, PositionConfig, PositionCap};
use kai_leverage::position_core_test_util::price_mul_100_human_to_sqrt_x64;
use std::type_name;
use std::u128;
use sui::balance;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use kai_leverage::supply_pool_tests::{SSUI, SUSDC};
use usdc::usdc::USDC;

// cetus
use fun cetus_clmm::pool::current_sqrt_price as cetus_clmm::pool::Pool.current_sqrt_price_x64;

// bluefin
use fun bluefin_spot::pool::current_sqrt_price as bluefin_spot::pool::Pool.current_sqrt_price_x64;

/* ================= Helper macros ================= */

// Helper macro to create a standard position for deleverage tests
public macro fun create_position_for_deleverage_tests<$Setup>($setup: &mut $Setup): PositionCap {
    let setup = $setup;

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    setup.next_tx(@0);
    let position_cap = {
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let principal_x_amount = 100_000000000;
        let principal_y_amount = 100_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 31467114902;

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
        setup.borrow_for_position_y(&mut ticket, &config);

        let position_cap = setup.create_position(
            &config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(config);
        position_cap
    };

    position_cap
}

public macro fun move_price_to_tirgger_deleverage_but_not_liquidation<$Setup>($setup: &mut $Setup) {
    let setup = $setup;
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(2_19));
        setup.sync_pyth_pio_price_x_to_pool();

        let config: PositionConfig = setup.scenario().take_shared();
        let position = setup.take_shared_position();

        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let model = setup.position_model(&position, &config);
        assert!(model.margin_below_threshold(p_x128, config.deleverage_margin_bps()));
        assert!(!model.margin_below_threshold(p_x128, config.liq_margin_bps()));

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    }
}

public macro fun move_price_to_trigger_liquidation<$Setup>($setup: &mut $Setup) {
    let setup = $setup;
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_50));
        setup.sync_pyth_pio_price_x_to_pool();

        let config: PositionConfig = setup.scenario().take_shared();
        let position = setup.take_shared_position();

        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let model = setup.position_model(&position, &config);
        assert!(model.margin_below_threshold(p_x128, config.liq_margin_bps()));

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    }
}
/* ================= create_deleverage_ticket tests ================= */

public macro fun create_deleverage_ticket_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage, but above liquidation threshold
    move_price_to_tirgger_deleverage_but_not_liquidation!(setup);

    // Create different config
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
        let mut invalid_config = setup.scenario().take_shared<PositionConfig>();
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_invalid_config
        let (ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut invalid_config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        test_scenario::return_shared(invalid_config);
        destroy(ticket);
        destroy(request);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_aborts_when_invalid_pool<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_tirgger_deleverage_but_not_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_invalid_pool
        let (ticket, request) = setup.create_deleverage_ticket_with_different_pool(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(ticket);
        destroy(request);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_aborts_when_ticket_active<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_tirgger_deleverage_but_not_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create first ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        assert!(position.ticket_active() == true);

        // This should abort with e_ticket_active
        let (ticket2, request2) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(ticket2);
        destroy(request2);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_returns_early_when_position_not_below_threshold<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Don't move price - position should be healthy
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket - should return early
        let (ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        // Verify ticket indicates no deleveraging occurred
        assert!(ticket.can_repay_x() == false);
        assert!(ticket.can_repay_y() == false);
        let info = ticket.info();
        assert!(info.delta_l() == 0);
        assert!(info.delta_x() == 0);
        assert!(info.delta_y() == 0);
        assert!(info.x_repaid() == 0);
        assert!(info.y_repaid() == 0);

        // Ticket should still be active though
        assert!(position.ticket_active() == true);

        position.destroy_deleverage_ticket(ticket);
        assert!(position.ticket_active() == false);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_is_correct_when_position_below_threshold<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );
    let initial_l = 31467114902;

    // Move price to trigger deleverage
    move_price_to_tirgger_deleverage_but_not_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let model = setup.position_model(&position, &config);

        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let exp_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            exp_delta_l,
            false,
        );

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        // Verify all ticket fields
        let exp_global_l = initial_l - exp_delta_l;
        assert!(config.current_global_l() == exp_global_l);
        assert!(position.ticket_active() == true);
        assert!(ticket.position_id() == object::id(&position));
        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == true);

        let info = ticket.info();
        assert!(info.position_id() == object::id(&position));
        assert!(info.model() == model);
        assert!(info.oracle_price_x128() == exp_oracle_price_x128);
        assert!(info.sqrt_pool_price_x64() == setup.clmm_pool().current_sqrt_price_x64());
        assert!(info.delta_l() == exp_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        assert!(info.x_repaid() == 0);
        assert!(info.y_repaid() == 0);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_respects_max_delta_l<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );
    let initial_l = 31467114902;

    // Move price to trigger deleverage
    setup.next_tx(@0);
    move_price_to_tirgger_deleverage_but_not_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let model = setup.position_model(&position, &config);

        // Set a low max_delta_l
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let delta_l = max_delta_l / 2;
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            delta_l,
            false,
        );

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            delta_l,
        );
        request.admin_approve_request(setup.package_admin());

        let info = ticket.info();
        assert!(info.delta_l() == delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        assert!(config.current_global_l() == initial_l - delta_l);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_can_repay_x_false_when_no_collateral<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    // Move price out of range
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_92));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            max_delta_l,
            false,
        );

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            max_delta_l,
        );
        request.admin_approve_request(setup.package_admin());

        assert!(ticket.can_repay_x() == false);
        assert!(ticket.can_repay_y() == true);

        let info = ticket.info();
        assert!(info.delta_l() == max_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        // sanity checks
        assert!(info.delta_x() == 0);
        assert!(info.delta_y() > 0);
        assert!(info.delta_l() > 0);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_can_repay_y_false_when_no_collateral<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    // Move price out of range
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_46));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            max_delta_l,
            false,
        );

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            max_delta_l,
        );
        request.admin_approve_request(setup.package_admin());

        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == false);

        let info = ticket.info();
        assert!(info.delta_l() == max_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        // sanity checks
        assert!(info.delta_l() > 0);
        assert!(info.delta_x() > 0);
        assert!(info.delta_y() == 0);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_can_repay_x_false_when_no_debt<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_51),
    );
    setup.next_tx(@0);
    let position_cap = {
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let principal_x_amount = 100_000000000;
        let principal_y_amount = 0;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 27467114902;

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
        setup.borrow_for_position_y(&mut ticket, &config);

        let position_cap = setup.create_position(
            &config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(config);
        position_cap
    };

    // Move price below liquidation threshold, but within range
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_48));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        // sanity checks
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() > 0);

        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            max_delta_l,
            false,
        );

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            max_delta_l,
        );
        request.admin_approve_request(setup.package_admin());

        assert!(ticket.can_repay_x() == false);
        assert!(ticket.can_repay_y() == true);

        let info = ticket.info();
        assert!(info.delta_l() == max_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        // sanity checks
        assert!(info.delta_x() > 0);
        assert!(info.delta_y() > 0);
        assert!(info.delta_l() > 0);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_can_repay_y_false_when_no_debt<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_50),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );
    setup.next_tx(@0);
    let position_cap = {
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let principal_x_amount = 0;
        let principal_y_amount = 100_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 5467114902;

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
        setup.borrow_for_position_y(&mut ticket, &config);

        let position_cap = setup.create_position(
            &config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(config);
        position_cap
    };

    // Move price below liquidation threshold, but within range
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_90));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        // sanity checks
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() > 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);

        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            max_delta_l,
            false,
        );

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            max_delta_l,
        );
        request.admin_approve_request(setup.package_admin());

        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == false);

        let info = ticket.info();
        assert!(info.delta_l() == max_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        // sanity checks
        assert!(info.delta_x() > 0);
        assert!(info.delta_y() > 0);
        assert!(info.delta_l() > 0);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

/* ================= create_deleverage_ticket_for_liquidation tests ================= */

public macro fun create_deleverage_ticket_for_liquidation_aborts_when_liquidation_disabled<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Disable liquidation
    setup.next_tx(@0);
    {
        let mut config: PositionConfig = setup.scenario().take_shared();
        config
            .set_liquidation_disabled(true, setup.ctx())
            .admin_approve_request(setup.package_admin());
        test_scenario::return_shared(config);
    };

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_liquidation_disabled
        let ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(ticket);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_aborts_when_invalid_config<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation!(setup);

    // Create different config
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
        let mut invalid_config = setup.scenario().take_shared<PositionConfig>();
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_invalid_config
        let ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut invalid_config,
            &price_info,
            &debt_info,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        test_scenario::return_shared(invalid_config);
        destroy(ticket);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_aborts_when_invalid_pool<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price below liquidation threshold
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_invalid_pool
        let ticket = setup.create_deleverage_ticket_for_liquidation_with_different_pool(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(ticket);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_aborts_when_ticket_active<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create first ticket using regular deleverage (to activate ticket)
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        assert!(position.ticket_active() == true);

        // This should abort with e_ticket_active
        let ticket2 = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        // This branch won't execute due to abort, but if it did...
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(ticket2);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_is_correct<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let exp_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            exp_delta_l,
            false,
        );

        // Create liquidation ticket
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        // Verify ticket is valid
        assert!(ticket.position_id() == object::id(&position));
        assert!(position.ticket_active() == true);

        let info = ticket.info();
        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == true);
        assert!(info.position_id() == object::id(&position));
        assert!(info.model() == model);
        assert!(info.oracle_price_x128() == exp_oracle_price_x128);
        assert!(info.sqrt_pool_price_x64() == setup.clmm_pool().current_sqrt_price_x64());
        assert!(info.delta_l() == exp_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        assert!(info.x_repaid() == 0);
        assert!(info.y_repaid() == 0);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_returns_early_when_position_not_below_threshold<
    $Setup,
>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Don't move price - position should be healthy
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket - should return early
        let ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        // Verify ticket indicates no deleveraging occurred
        assert!(ticket.can_repay_x() == false);
        assert!(ticket.can_repay_y() == false);
        let info = ticket.info();
        assert!(info.delta_l() == 0);
        assert!(info.delta_x() == 0);
        assert!(info.delta_y() == 0);
        assert!(info.x_repaid() == 0);
        assert!(info.y_repaid() == 0);

        // Ticket should still be active though
        assert!(position.ticket_active() == true);

        position.destroy_deleverage_ticket(ticket);
        assert!(position.ticket_active() == false);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_can_repay_x_false_when_no_collateral<
    $Setup,
>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    let initial_l = 31467114902;

    // Move price out of range
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_92));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            max_delta_l,
            false,
        );

        // Create ticket
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        assert!(ticket.can_repay_x() == false);
        assert!(ticket.can_repay_y() == true);

        let info = ticket.info();
        assert!(info.delta_l() == max_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        // sanity checks
        assert!(info.delta_x() == 0);
        assert!(info.delta_y() > 0);
        assert!(info.delta_l() == initial_l);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_can_repay_y_false_when_no_collateral<
    $Setup,
>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    let initial_l = 31467114902;

    // Move price out of range
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_46));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            max_delta_l,
            false,
        );

        // Create ticket
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == false);

        let info = ticket.info();
        assert!(info.delta_l() == max_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        // sanity checks
        assert!(info.delta_l() == initial_l);
        assert!(info.delta_x() > 0);
        assert!(info.delta_y() == 0);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_can_repay_x_false_when_no_debt<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_51),
    );
    let initial_l = 27467114902;

    setup.next_tx(@0);
    let position_cap = {
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let principal_x_amount = 100_000000000;
        let principal_y_amount = 0;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = initial_l;

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
        setup.borrow_for_position_y(&mut ticket, &config);

        let position_cap = setup.create_position(
            &config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(config);
        position_cap
    };

    // Move price below liquidation threshold, but within range
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_48));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        // sanity checks
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() > 0);

        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            max_delta_l,
            false,
        );

        // Create ticket
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        assert!(ticket.can_repay_x() == false);
        assert!(ticket.can_repay_y() == true);

        let info = ticket.info();
        assert!(info.delta_l() == max_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        // sanity checks
        assert!(info.delta_x() > 0);
        assert!(info.delta_y() > 0);
        assert!(info.delta_l() == initial_l);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun create_deleverage_ticket_for_liquidation_can_repay_y_false_when_no_debt<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_50),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );
    let initial_l = 5467114902;

    setup.next_tx(@0);
    let position_cap = {
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let principal_x_amount = 0;
        let principal_y_amount = 100_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = initial_l;

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
        setup.borrow_for_position_y(&mut ticket, &config);

        let position_cap = setup.create_position(
            &config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(config);
        position_cap
    };

    // Move price below liquidation threshold, but within range
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_90));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let exp_oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        // sanity checks
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() > 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);

        let max_delta_l = model.calc_max_deleverage_delta_l(
            exp_oracle_price_x128,
            config.deleverage_margin_bps(),
            config.base_deleverage_factor_bps(),
        );
        let (exp_delta_x, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            max_delta_l,
            false,
        );

        // Create ticket
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == false);

        let info = ticket.info();
        assert!(info.delta_l() == max_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        // sanity checks
        assert!(info.delta_x() > 0);
        assert!(info.delta_y() > 0);
        assert!(info.delta_l() == initial_l);

        // Clean up
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

/* ================= deleverage_ticket_repay_x tests ================= */

public macro fun deleverage_ticket_repay_x_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    // Create different config
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
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        // Try to repay with invalid config - should abort with e_invalid_config
        setup.deleverage_ticket_repay_x(&mut position, &invalid_config, &mut ticket);

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        test_scenario::return_shared(invalid_config);
    };

    destroy(position_cap);
}

public macro fun deleverage_ticket_repay_x_aborts_when_position_mismatch<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create two positions
    let position_cap_1 = create_position_for_deleverage_tests!(setup);
    let position_cap_2 = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position_1 = setup.take_shared_position_by_cap(&position_cap_1);
        let mut position_2 = setup.take_shared_position_by_cap(&position_cap_2);
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket from position 1
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position_1,
            &mut config,
            &price_info,
            &debt_info,
        );

        // Try to repay with position 2 - should abort with e_ticket_position_mismatch
        setup.deleverage_ticket_repay_x(
            &mut position_2,
            &config,
            &mut ticket,
        );

        test_scenario::return_shared(position_1);
        test_scenario::return_shared(position_2);
        test_scenario::return_shared(config);
        destroy(ticket);
    };

    destroy(position_cap_1);
    destroy(position_cap_2);
}

public macro fun deleverage_ticket_repay_x_aborts_when_supply_pool_mismatch<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        // Try to repay with wrong supply pool - should abort with e_supply_pool_mismatch
        setup.deleverage_ticket_repay_x_with_wrong_supply_pool(
            &mut position,
            &config,
            &mut ticket,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(ticket);
    };

    destroy(position_cap);
}

public macro fun deleverage_ticket_repay_x_returns_early_when_can_repay_false<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Don't move price - position should be healthy
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        // sanity checks
        assert!(initial_sx > 0);
        assert!(initial_sy > 0);

        // Create ticket - should return early with can_repay_x = false
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        assert!(ticket.can_repay_x() == false);

        // This should return early without doing anything
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);

        let final_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let final_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(final_sx == initial_sx);
        assert!(final_sy == initial_sy);

        // Still false
        assert!(ticket.can_repay_x() == false);
        assert!(ticket.info().x_repaid() == 0);

        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun deleverage_ticket_repay_x_is_idempotent<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        // sanity checks
        assert!(initial_sx > 0);
        assert!(initial_sy > 0);

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        let validated_debt_info = setup.validated_debt_info(&config);
        let exp_sx_repaid = u128::min(initial_sx, validated_debt_info.calc_repay_by_amount(
            type_name::with_original_ids<SSUI>(),
            ticket.info().delta_x(),
        ));
        let exp_sy_repaid = u128::min(initial_sy, validated_debt_info.calc_repay_by_amount(
            type_name::with_original_ids<SUSDC>(),
            ticket.info().delta_y(),
        ));

        assert!(ticket.can_repay_x() == true);

        // Repay first time
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        assert!(ticket.can_repay_x() == false);
        let x_repaid_first = ticket.info().x_repaid();

        let final_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let final_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(final_sx == initial_sx - exp_sx_repaid);
        assert!(final_sy == initial_sy);

        // Repay second time - should return early
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        assert!(ticket.can_repay_x() == false);
        assert!(ticket.info().x_repaid() == x_repaid_first); // Same amount

        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        let final_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let final_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(final_sx == initial_sx - exp_sx_repaid);
        assert!(final_sy == initial_sy - exp_sy_repaid);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun deleverage_ticket_repay_x_with_partial_debt_repayment<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage, but not enough to cover all debt x after deleverage
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(7_97));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let model = setup.position_model(&position, &config);

        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        // sanity checks
        assert!(ticket.info().delta_x() > 0);
        assert!(model.dx() > 0);
        assert!(model.dx() > ticket.info().delta_x());

        let validated_debt_info = setup.validated_debt_info(&config);
        let exp_sx_repaid = validated_debt_info.calc_repay_by_amount(
            type_name::with_original_ids<SSUI>(),
            ticket.info().delta_x(),
        );
        let exp_x_repaid = ticket.info().delta_x();

        // Repay
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);

        // Verify full repayment
        assert!(ticket.can_repay_x() == false);
        assert!(ticket.info().x_repaid() == exp_x_repaid);
        assert!(ticket.info().y_repaid() == 0);
        let final_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        assert!(final_sx == initial_sx - exp_sx_repaid);
        // sanity check
        assert!(final_sx > 0);

        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

/* ================= deleverage_ticket_repay_y tests ================= */

public macro fun deleverage_ticket_repay_y_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    // Create different config
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
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        // Try to repay with invalid config - should abort with e_invalid_config
        setup.deleverage_ticket_repay_y(&mut position, &invalid_config, &mut ticket);

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        test_scenario::return_shared(invalid_config);
    };

    destroy(position_cap);
}

public macro fun deleverage_ticket_repay_y_aborts_when_position_mismatch<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create two positions
    let position_cap_1 = create_position_for_deleverage_tests!(setup);
    let position_cap_2 = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position_1 = setup.take_shared_position_by_cap(&position_cap_1);
        let mut position_2 = setup.take_shared_position_by_cap(&position_cap_2);
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket from position 1
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position_1,
            &mut config,
            &price_info,
            &debt_info,
        );

        // Try to repay with position 2 - should abort with e_ticket_position_mismatch
        setup.deleverage_ticket_repay_y(
            &mut position_2,
            &config,
            &mut ticket,
        );

        test_scenario::return_shared(position_1);
        test_scenario::return_shared(position_2);
        test_scenario::return_shared(config);
        destroy(ticket);
    };

    destroy(position_cap_1);
    destroy(position_cap_2);
}

public macro fun deleverage_ticket_repay_y_aborts_when_supply_pool_mismatch<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket
        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
        );

        // Try to repay with wrong supply pool - should abort with e_supply_pool_mismatch
        setup.deleverage_ticket_repay_y_with_wrong_supply_pool(
            &mut position,
            &config,
            &mut ticket,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(ticket);
    };

    destroy(position_cap);
}

public macro fun deleverage_ticket_repay_y_returns_early_when_can_repay_false<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Don't move price - position should be healthy
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        // sanity checks
        assert!(initial_sx > 0);
        assert!(initial_sy > 0);

        // Create ticket - should return early with can_repay_y = false
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        assert!(ticket.can_repay_y() == false);

        // This should return early without doing anything
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);

        let final_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let final_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(final_sx == initial_sx);
        assert!(final_sy == initial_sy);

        // Still false
        assert!(ticket.can_repay_y() == false);
        assert!(ticket.info().y_repaid() == 0);

        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun deleverage_ticket_repay_y_is_idempotent<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        // sanity checks
        assert!(initial_sx > 0);
        assert!(initial_sy > 0);

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        let validated_debt_info = setup.validated_debt_info(&config);
        let exp_sx_repaid = u128::min(initial_sx, validated_debt_info.calc_repay_by_amount(
            type_name::with_original_ids<SSUI>(),
            ticket.info().delta_x(),
        ));
        let exp_sy_repaid = u128::min(initial_sy, validated_debt_info.calc_repay_by_amount(
            type_name::with_original_ids<SUSDC>(),
            ticket.info().delta_y(),
        ));

        assert!(ticket.can_repay_y() == true);

        // Repay first time
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        assert!(ticket.can_repay_y() == false);
        let y_repaid_first = ticket.info().y_repaid();

        let final_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let final_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(final_sx == initial_sx);
        assert!(final_sy == initial_sy - exp_sy_repaid);

        // Repay second time - should return early
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        assert!(ticket.can_repay_y() == false);
        assert!(ticket.info().y_repaid() == y_repaid_first); // Same amount

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        let final_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let final_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(final_sx == initial_sx - exp_sx_repaid);
        assert!(final_sy == initial_sy - exp_sy_repaid);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun deleverage_ticket_repay_y_with_partial_debt_repayment<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage, but not enough to cover all debt y after deleverage
    setup.next_tx(@0);
    setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(2_19));
    setup.sync_pyth_pio_price_x_to_pool();

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let model = setup.position_model(&position, &config);

        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        // sanity checks
        assert!(ticket.info().delta_y() > 0);
        assert!(model.dy() > 0);
        assert!(model.dy() > ticket.info().delta_y());

        let validated_debt_info = setup.validated_debt_info(&config);
        let exp_sy_repaid = validated_debt_info.calc_repay_by_amount(
            type_name::with_original_ids<SUSDC>(),
            ticket.info().delta_y(),
        );
        let exp_y_repaid = ticket.info().delta_y();

        // Repay
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);

        // Verify full repayment
        assert!(ticket.can_repay_y() == false);
        assert!(ticket.info().x_repaid() == 0);
        assert!(ticket.info().y_repaid() == exp_y_repaid);
        let final_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(final_sy == initial_sy - exp_sy_repaid);
        // sanity check
        assert!(final_sy > 0);

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

/* ================= destroy_deleverage_ticket tests ================= */

public macro fun destroy_deleverage_ticket_aborts_when_position_mismatch<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create two positions
    let position_cap_1 = create_position_for_deleverage_tests!(setup);
    let position_cap_2 = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position_1 = setup.take_shared_position_by_cap(&position_cap_1);
        let mut position_2 = setup.take_shared_position_by_cap(&position_cap_2);
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket from position 1
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position_1,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        destroy(request);

        // Repay both X and Y to exhaust ticket
        setup.deleverage_ticket_repay_x(
            &mut position_1,
            &config,
            &mut ticket,
        );

        setup.deleverage_ticket_repay_y(
            &mut position_1,
            &config,
            &mut ticket,
        );

        // Try to destroy with position 2 - should abort with e_ticket_position_mismatch
        position_2.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position_1);
        test_scenario::return_shared(position_2);
        test_scenario::return_shared(config);
    };

    destroy(position_cap_1);
    destroy(position_cap_2);
}

public macro fun destroy_deleverage_ticket_aborts_when_can_repay_x_true<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        // sanity checks
        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == true);

        // Only repay Y, leave X unrepaid
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);

        // sanity checks
        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == false);

        // This should abort with ETicketNotExhausted
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

public macro fun destroy_deleverage_ticket_aborts_when_can_repay_y_true<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position
    let position_cap = create_position_for_deleverage_tests!(setup);

    // Move price to trigger deleverage
    move_price_to_trigger_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create ticket
        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        // sanity checks
        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == true);

        // Only repay X, leave Y unrepaid
        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);

        // sanity checks
        assert!(ticket.can_repay_x() == false);
        assert!(ticket.can_repay_y() == true);

        // This should abort with ETicketNotExhausted
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    destroy(position_cap);
}

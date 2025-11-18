#[test_only]
module kai_leverage::position_core_repay_bad_debt_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{Self as core, Position, PositionConfig, PositionCap};
use kai_leverage::position_core_test_util::price_mul_100_human_to_sqrt_x64;
use kai_leverage::supply_pool_tests::{SSUI, SUSDC};
use std::type_name;
use std::u128;
use std::u64;
use sui::balance;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

// cetus
use fun cetus_clmm::pool::current_sqrt_price as cetus_clmm::pool::Pool.current_sqrt_price_x64;

// bluefin
use fun bluefin_spot::pool::current_sqrt_price as bluefin_spot::pool::Pool.current_sqrt_price_x64;

/* ================= Helper macros ================= */

// Helper macro to create a standard position for repay_bad_debt_x tests
public macro fun create_position_for_repay_bad_debt_x_tests<$Setup>(
    $setup: &mut $Setup,
): PositionCap {
    let setup = $setup;

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_49),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );

    setup.next_tx(@0);
    let position_cap = {
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let principal_x_amount = 10_000000000;
        let principal_y_amount = 1_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 103639266383;

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

// Helper macro to create a standard position for repay_bad_debt_y tests
public macro fun create_position_for_repay_bad_debt_y_tests<$Setup>(
    $setup: &mut $Setup,
): PositionCap {
    let setup = $setup;

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_51),
    );

    setup.next_tx(@0);
    let position_cap = {
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let principal_x_amount = 1_000000000;
        let principal_y_amount = 50_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 131150098162;

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

// Helper macro to move price to trigger bad debt for X
public macro fun move_price_to_trigger_bad_debt_x<$Setup>($setup: &mut $Setup) {
    let setup = $setup;
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(7_97));
        setup.sync_pyth_pio_price_x_to_pool();

        let config: PositionConfig = setup.scenario().take_shared();
        let position = setup.take_shared_position();

        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let model = setup.position_model(&position, &config);
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(p_x128, crit_margin_bps));

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    }
}

// Helper macro to move price to trigger bad debt for Y
public macro fun move_price_to_trigger_bad_debt_y<$Setup>($setup: &mut $Setup) {
    let setup = $setup;
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_77));
        setup.sync_pyth_pio_price_x_to_pool();

        let config: PositionConfig = setup.scenario().take_shared();
        let position = setup.take_shared_position();

        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let model = setup.position_model(&position, &config);
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(p_x128, crit_margin_bps));

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    }
}

// Helper macro to deleverage and liquidate
public macro fun deleverage_and_liquidate<$Setup>($setup: &mut $Setup) {
    let setup = $setup;
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let price_info = setup.price_info();
        let debt_info = setup.debt_info(&config);

        setup.deleverage_for_liquidation(&mut position, &mut config, &price_info);

        let (repayment_amt_y, _) = setup.calc_liquidate_col_x(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        let mut repayment_y = balance::create_for_testing(repayment_amt_y);
        let reward_x = setup.liquidate_col_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );
        destroy(reward_x);
        repayment_y.destroy_zero();

        let (repayment_amt_x, _) = setup.calc_liquidate_col_y(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        let mut repayment_x = balance::create_for_testing(repayment_amt_x);
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );
        destroy(reward_y);
        repayment_x.destroy_zero();

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    }
}

public macro fun position_has_bad_debt($position: &Position<_, _, _>): bool {
    let position = $position;

    if (position.lp_position().liquidity() != 0) {
        return false
    };
    if (position.col_x().value() != 0) {
        return false
    };
    if (position.col_y().value() != 0) {
        return false
    };
    let sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
    let sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
    if (sx == 0 && sy == 0) {
        return false
    };

    true
}

/* ================= repay_bad_debt_x tests ================= */

public macro fun repay_bad_debt_x_is_correct<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_x_tests!(setup);
    move_price_to_trigger_bad_debt_x!(setup);
    deleverage_and_liquidate!(setup);

    // repay debt partially
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let validated_debt_info = setup.validated_debt_info(&config);
        let model = setup.position_model(&position, &config);

        // sanity check
        assert!(position_has_bad_debt!(&position));
        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_dx = model.dx();
        assert!(initial_sx > 0);
        assert!(initial_dx > 0);
        let supply_pool_initial_st = setup
            .validated_debt_info(&config)
            .supply_x64(type_name::with_original_ids<SSUI>());
        assert!(supply_pool_initial_st > 0);

        let partial_repayment_amt_x = initial_dx / 4;
        assert!(partial_repayment_amt_x > 0);

        let exp_sx_repaid = validated_debt_info.calc_repay_by_amount(
            type_name::with_original_ids<SSUI>(),
            partial_repayment_amt_x,
        );

        // Full repayment
        let mut repayment_x = balance::create_for_testing(partial_repayment_amt_x);
        let request = setup.repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );
        request.admin_approve_request(setup.package_admin());

        // Verify full repayment occurred
        let final_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        assert!(final_sx == initial_sx - exp_sx_repaid);
        assert!(final_sx > 0);
        assert!(repayment_x.value() == 0);
        let supply_pool_final_st = setup
            .validated_debt_info(&config)
            .supply_x64(type_name::with_original_ids<SSUI>());
        assert!(supply_pool_final_st == supply_pool_initial_st - exp_sx_repaid);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
    };

    // repay debt fully
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let model = setup.position_model(&position, &config);

        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        assert!(initial_sx > 0);

        let supply_pool_initial_st = setup
            .validated_debt_info(&config)
            .supply_x64(type_name::with_original_ids<SSUI>());
        assert!(supply_pool_initial_st > 0);

        let exp_sx_repaid = initial_sx;

        let mut repayment_x = balance::create_for_testing(model.dx());
        let request = setup.repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );
        request.admin_approve_request(setup.package_admin());

        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);
        assert!(repayment_x.value() == 0);
        let supply_pool_final_st = setup
            .validated_debt_info(&config)
            .supply_x64(type_name::with_original_ids<SSUI>());
        assert!(supply_pool_final_st == supply_pool_initial_st - exp_sx_repaid);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_x_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_x_tests!(setup);
    move_price_to_trigger_bad_debt_x!(setup);
    deleverage_and_liquidate!(setup);

    // Create different config
    setup.next_tx(@0);
    {
        let (_, request) = core::create_empty_config(
            object::id(setup.clmm_pool()),
            setup.ctx(),
        );
        request.admin_approve_request(setup.package_admin());
    };

    setup.next_tx(@0);
    {
        let invalid_config = setup.scenario().take_shared<PositionConfig>();
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_invalid_config
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let request = setup.repay_bad_debt_x(
            &mut position,
            &invalid_config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        test_scenario::return_shared(invalid_config);
        destroy(repayment_x);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_x_aborts_when_ticket_active<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_x_tests!(setup);
    move_price_to_trigger_bad_debt_x!(setup);
    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create a deleverage ticket to activate ticket
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
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let request2 = setup.repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        request2.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_x_aborts_when_supply_pool_mismatch<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_x_tests!(setup);
    move_price_to_trigger_bad_debt_x!(setup);
    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_supply_pool_mismatch
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let request = setup.repay_bad_debt_x_with_wrong_supply_pool(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_x_aborts_when_position_not_fully_liquidated<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_x_tests!(setup);
    move_price_to_trigger_bad_debt_x!(setup);

    // Don't deleverage - position still has liquidity

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position) == false);

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        assert!(!model.is_fully_deleveraged()); // Sanity check

        // Verify position is below bad debt threshold
        let p_x128 = config.validate_price_info(&price_info).div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(p_x128, crit_margin_bps));

        // This should abort with e_no_bad_debt_or_not_fully_liquidated
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let request = setup.repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_x_aborts_when_position_not_below_bad_debt_threshold<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_x_tests!(setup);

    // Move price to trigger liquidation, but not bad debt threshold
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(5_54));
        setup.sync_pyth_pio_price_x_to_pool();
    };

    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position) == false);

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        assert!(model.is_fully_deleveraged());

        // Verify position is above crit_margin
        let validated_price_info = config.validate_price_info(&price_info);
        let p_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(!model.margin_below_threshold(p_x128, crit_margin_bps));

        // This should abort with e_position_not_below_bad_debt_threshold
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let request = setup.repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_x_aborts_when_fully_liquidated_but_no_bad_debt<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position and trigger liquidation
    let position_cap = create_position_for_repay_bad_debt_x_tests!(setup);
    
    // Move price to trigger liquidation, but not necessarily bad debt threshold
    // After liquidation, all debt should be paid off (no bad debt)
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(5_54));
        setup.sync_pyth_pio_price_x_to_pool();
    };

    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // Verify position is fully liquidated, but has some collateral left
        assert!(position.lp_position().liquidity() == 0);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() > 0);

        // Verify no debt remaining
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);
        assert!(position_has_bad_debt!(&position) == false);

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_no_bad_debt_or_not_fully_liquidated
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let request = setup.repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_x_returns_early_when_no_debt<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_y_tests!(setup);
    move_price_to_trigger_bad_debt_y!(setup);
    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // No X debt remaining
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);

        // This should return early
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let initial_repayment = repayment_x.value();
        let request = setup.repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        request.admin_approve_request(setup.package_admin());

        // No repayment should have occurred
        assert!(repayment_x.value() == initial_repayment);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
    };

    destroy(position_cap);
}

/* ================= repay_bad_debt_y tests ================= */

public macro fun repay_bad_debt_y_is_correct<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_y_tests!(setup);
    move_price_to_trigger_bad_debt_y!(setup);
    deleverage_and_liquidate!(setup);

    // repay debt partially
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let validated_debt_info = setup.validated_debt_info(&config);
        let model = setup.position_model(&position, &config);

        // sanity check
        assert!(position_has_bad_debt!(&position));
        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        let initial_dy = model.dy();
        assert!(initial_sy > 0);
        assert!(initial_dy > 0);
        let supply_pool_initial_st = setup
            .validated_debt_info(&config)
            .supply_x64(type_name::with_original_ids<SUSDC>());
        assert!(supply_pool_initial_st > 0);

        let partial_repayment_amt_y = initial_dy / 4;
        assert!(partial_repayment_amt_y > 0);

        let exp_sy_repaid = validated_debt_info.calc_repay_by_amount(
            type_name::with_original_ids<SUSDC>(),
            partial_repayment_amt_y,
        );

        // Full repayment
        let mut repayment_y = balance::create_for_testing(partial_repayment_amt_y);
        let request = setup.repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );
        request.admin_approve_request(setup.package_admin());

        // Verify full repayment occurred
        let final_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(final_sy == initial_sy - exp_sy_repaid);
        assert!(final_sy > 0);
        assert!(repayment_y.value() == 0);
        let supply_pool_final_st = setup
            .validated_debt_info(&config)
            .supply_x64(type_name::with_original_ids<SUSDC>());
        assert!(supply_pool_final_st == supply_pool_initial_st - exp_sy_repaid);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
    };

    // repay debt fully
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let model = setup.position_model(&position, &config);

        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(initial_sy > 0);

        let supply_pool_initial_st = setup
            .validated_debt_info(&config)
            .supply_x64(type_name::with_original_ids<SUSDC>());
        assert!(supply_pool_initial_st > 0);

        let exp_sy_repaid = initial_sy;

        let mut repayment_y = balance::create_for_testing(model.dy());
        let request = setup.repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );
        request.admin_approve_request(setup.package_admin());

        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);
        assert!(repayment_y.value() == 0);
        let supply_pool_final_st = setup
            .validated_debt_info(&config)
            .supply_x64(type_name::with_original_ids<SUSDC>());
        assert!(supply_pool_final_st == supply_pool_initial_st - exp_sy_repaid);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_y_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_y_tests!(setup);
    move_price_to_trigger_bad_debt_y!(setup);
    deleverage_and_liquidate!(setup);

    // Create different config
    setup.next_tx(@0);
    {
        let (_, request) = core::create_empty_config(
            object::id(setup.clmm_pool()),
            setup.ctx(),
        );
        request.admin_approve_request(setup.package_admin());
    };

    setup.next_tx(@0);
    {
        let invalid_config = setup.scenario().take_shared<PositionConfig>();
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared_by_id(setup.config_id());

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_invalid_config
        let mut repayment_y = balance::create_for_testing(100_000000);
        let request = setup.repay_bad_debt_y(
            &mut position,
            &invalid_config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        test_scenario::return_shared(invalid_config);
        destroy(repayment_y);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_y_aborts_when_ticket_active<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_y_tests!(setup);
    move_price_to_trigger_bad_debt_y!(setup);
    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // Create a deleverage ticket to activate ticket
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
        let mut repayment_y = balance::create_for_testing(100_000000);
        let request2 = setup.repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        request2.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_y_aborts_when_supply_pool_mismatch<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_y_tests!(setup);
    move_price_to_trigger_bad_debt_y!(setup);
    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_supply_pool_mismatch
        let mut repayment_y = balance::create_for_testing(100_000000);
        let request = setup.repay_bad_debt_y_with_wrong_supply_pool(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_y_aborts_when_position_not_fully_liquidated<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_y_tests!(setup);
    move_price_to_trigger_bad_debt_y!(setup);

    // Don't deleverage - position still has liquidity

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position) == false);

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        assert!(!model.is_fully_deleveraged()); // Sanity check

        // Verify position is below bad debt threshold
        let p_x128 = config.validate_price_info(&price_info).div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(p_x128, crit_margin_bps));

        // This should abort with e_no_bad_debt_or_not_fully_liquidated
        let mut repayment_y = balance::create_for_testing(100_000000);
        let request = setup.repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_y_aborts_when_position_not_below_bad_debt_threshold<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_y_tests!(setup);

    // Move price to trigger liquidation, but not bad debt threshold
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(2_00));
        setup.sync_pyth_pio_price_x_to_pool();
    };

    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position) == false);

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        assert!(model.is_fully_deleveraged());

        // Verify position is above crit_margin
        let validated_price_info = config.validate_price_info(&price_info);
        let p_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(!model.margin_below_threshold(p_x128, crit_margin_bps));

        // This should abort with e_position_not_below_bad_debt_threshold
        let mut repayment_y = balance::create_for_testing(100_000000);
        let request = setup.repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_y_aborts_when_fully_liquidated_but_no_bad_debt<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position and trigger liquidation
    let position_cap = create_position_for_repay_bad_debt_y_tests!(setup);
    
    // Move price to trigger liquidation, but not necessarily bad debt threshold
    // After liquidation, all debt should be paid off (no bad debt)
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(2_00));
        setup.sync_pyth_pio_price_x_to_pool();
    };

    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // Verify position is fully liquidated, but has some collateral left
        assert!(position.lp_position().liquidity() == 0);
        assert!(position.col_x().value() > 0);
        assert!(position.col_y().value() == 0);

        // Verify no debt remaining
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);
        assert!(position_has_bad_debt!(&position) == false);

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_no_bad_debt_or_not_fully_liquidated
        let mut repayment_y = balance::create_for_testing(100_000000);
        let request = setup.repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
    };

    destroy(position_cap);
}

public macro fun repay_bad_debt_y_returns_early_when_no_debt<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position and trigger bad debt
    let position_cap = create_position_for_repay_bad_debt_x_tests!(setup);
    move_price_to_trigger_bad_debt_x!(setup);
    deleverage_and_liquidate!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        assert!(position_has_bad_debt!(&position));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // No Y debt remaining
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);

        // This should return early
        let mut repayment_y = balance::create_for_testing(100_000000);
        let initial_repayment = repayment_y.value();
        let request = setup.repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        request.admin_approve_request(setup.package_admin());

        // No repayment should have occurred
        assert!(repayment_y.value() == initial_repayment);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
    };

    destroy(position_cap);
}

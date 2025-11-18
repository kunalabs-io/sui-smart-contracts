#[test_only]
module kai_leverage::position_core_liquidate_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{Self as core, Position, PositionConfig, PositionCap};
use kai_leverage::position_core_test_util::price_mul_100_human_to_sqrt_x64;
use kai_leverage::supply_pool_tests::{SUSDC, SSUI};
use kai_leverage::util;
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

// Helper macro to create a standard position for liquidation tests (col_x scenario)
public macro fun create_position_for_liquidate_col_x_tests<$Setup>(
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

// Helper macro to create a standard position for liquidation tests (col_y scenario)
public macro fun create_position_for_liquidate_col_y_tests<$Setup>(
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

// Helper macro to move price to trigger liquidation for col_x scenario
public macro fun move_price_to_trigger_liquidation_col_x<$Setup>($setup: &mut $Setup) {
    let setup = $setup;
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(2_00));
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

// Helper macro to move price to trigger liquidation for col_y scenario
public macro fun move_price_to_trigger_liquidation_col_y<$Setup>($setup: &mut $Setup) {
    let setup = $setup;
    setup.next_tx(@0);
    {
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(5_54));
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

// Helper macro to deleverage for liquidation
public macro fun deleverage_for_liquidation<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let price_info = setup.price_info();
        setup.deleverage_for_liquidation(&mut position, &mut config, &price_info);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    }
}

// Helper macro to check if position is liquidateable
public macro fun position_is_liquidateable<$Setup>(
    $setup: &mut $Setup,
    $position: &Position<_, _, _>,
    $config: &PositionConfig,
): bool {
    let setup = $setup;
    let position = $position;
    let config = $config;

    let debt_info = setup.debt_info(config);
    let price_info = setup.price_info();

    let (repayment_amt_y, reward_amt_x) = setup.calc_liquidate_col_x(
        position,
        config,
        &price_info,
        &debt_info,
        u64::max_value!(),
    );
    let (repayment_amt_x, reward_amt_y) = setup.calc_liquidate_col_y(
        position,
        config,
        &price_info,
        &debt_info,
        u64::max_value!(),
    );

    let is_liquidateable_x = repayment_amt_y > 0 && reward_amt_x > 0;
    let is_liquidateable_y = repayment_amt_x > 0 && reward_amt_y > 0;

    is_liquidateable_x || is_liquidateable_y
}

/* ================= liquidate_col_x tests ================= */

public macro fun liquidate_col_x_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_x_tests!(setup);

    // Move price to trigger liquidation and deleverage
    move_price_to_trigger_liquidation_col_x!(setup);
    deleverage_for_liquidation!(setup);

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

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        // This should abort with e_invalid_config
        let mut repayment_y = balance::create_for_testing(100_000000);
        let reward_x = setup.liquidate_col_x(
            &mut position,
            &invalid_config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        test_scenario::return_shared(invalid_config);
        destroy(repayment_y);
        destroy(reward_x);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_x_aborts_when_ticket_active<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_x_tests!(setup);

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation_col_x!(setup);
    deleverage_for_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

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
        let reward_x = setup.liquidate_col_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
        destroy(reward_x);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_x_aborts_when_liquidation_disabled<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_x_tests!(setup);

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
    move_price_to_trigger_liquidation_col_x!(setup);

    // deleverage
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let price_info = setup.price_info();

        let action_request = setup.deleverage(
            &mut position,
            &mut config,
            &price_info,
            u128::max_value!(),
        );
        action_request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_liquidation_disabled
        let mut repayment_y = balance::create_for_testing(100_000000);
        let reward_x = setup.liquidate_col_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
        destroy(reward_x);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_x_aborts_when_supply_pool_mismatch<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_x_tests!(setup);

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation_col_x!(setup);
    deleverage_for_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_supply_pool_mismatch
        let mut repayment_y = balance::create_for_testing(100_000000);
        let reward_x = setup.liquidate_col_x_with_wrong_supply_pool(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
        destroy(reward_x);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_x_returns_zero_when_repayment_amount_is_zero<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_x_tests!(setup);

    // Don't move price - position should be healthy
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config) == false);

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let (repayment_amt_y, reward_amt_x) = setup.calc_liquidate_col_x(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_y == 0);
        assert!(reward_amt_x == 0);

        let initial_l = position.lp_position().liquidity();
        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(initial_sx > 0);
        assert!(initial_sy > 0);

        // This should return zero balance
        let mut repayment_y = balance::create_for_testing(100_000000);
        let reward_x = setup.liquidate_col_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        assert!(reward_x.value() == 0);
        assert!(repayment_y.value() == 100_000000); // No repayment taken
        assert!(position.lp_position().liquidity() == initial_l);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == initial_sx);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == initial_sy);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
        destroy(reward_x);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_x_is_correct<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_x_tests!(setup);

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation_col_x!(setup);
    deleverage_for_liquidation!(setup);

    // Partial liquidation with limited repayment
    setup.next_tx(@0);
    let collected_protocol_fees_x = {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let validated_debt_info = config.validate_debt_info(&debt_info);

        let model = setup.position_model(&position, &config);
        let p_x128 = config
            .validate_price_info(&price_info)
            .div_price_numeric_x128(
                type_name::with_defining_ids<SUI>(),
                type_name::with_defining_ids<USDC>(),
            );
        let (max_repayment_amt_y, max_reward_amt_x) = model.calc_liquidate_col_x(
            p_x128,
            u64::max_value!(),
            config.liq_margin_bps(),
            config.liq_bonus_bps(),
            config.base_liq_factor_bps(),
        );

        assert!(max_repayment_amt_y == 61782766);
        assert!(max_reward_amt_x == 32435952475);
        assert!(model.dy() == max_repayment_amt_y);
        assert!(position.col_x().value() > max_reward_amt_x);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<SUI>()] == config.position_creation_fee_sui(),
        );

        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        let initial_cx = position.col_x().value();

        let partial_repayment_amt_y = 14077732;
        let (exp_repayment_amt_y, exp_reward_amt_x) = model.calc_liquidate_col_x(
            p_x128,
            partial_repayment_amt_y,
            config.liq_margin_bps(),
            config.liq_bonus_bps(),
            config.base_liq_factor_bps(),
        );
        assert!(exp_repayment_amt_y == partial_repayment_amt_y);
        let exp_liq_fee = util::muldiv(
            exp_reward_amt_x,
            (config.liq_bonus_bps() as u64) * (config.liq_fee_bps() as u64),
            (10000 + (config.liq_bonus_bps() as u64)) * 10000,
        );
        assert!(exp_liq_fee > 0);
        let exp_sy_repaid = validated_debt_info.calc_repay_by_amount(
            type_name::with_defining_ids<SUSDC>(),
            partial_repayment_amt_y,
        );
        assert!(exp_sy_repaid > 0);

        let mut repayment_y = balance::create_for_testing(partial_repayment_amt_y);
        let reward_x = setup.liquidate_col_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        assert!(reward_x.value() == exp_reward_amt_x - exp_liq_fee);
        assert!(repayment_y.value() == 0);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<USDC>() == initial_sy - exp_sy_repaid,
        );
        assert!(position.col_x().value() == initial_cx - exp_reward_amt_x);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<SUI>()] == config.position_creation_fee_sui() + exp_liq_fee,
        );
        let collected_protocol_fees_x = config.position_creation_fee_sui() + exp_liq_fee;

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
        destroy(reward_x);

        collected_protocol_fees_x
    };

    // Full liquidation
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let p_x128 = config
            .validate_price_info(&price_info)
            .div_price_numeric_x128(
                type_name::with_defining_ids<SUI>(),
                type_name::with_defining_ids<USDC>(),
            );
        let (max_repayment_amt_y, max_reward_amt_x) = model.calc_liquidate_col_x(
            p_x128,
            u64::max_value!(),
            config.liq_margin_bps(),
            config.liq_bonus_bps(),
            config.base_liq_factor_bps(),
        );

        assert!(max_repayment_amt_y == 47705034);
        assert!(max_reward_amt_x == 25045143101);
        assert!(position.col_x().value() > max_reward_amt_x);
        assert!(model.dy() == max_repayment_amt_y);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<SUI>()] == collected_protocol_fees_x,
        );

        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        let initial_cx = position.col_x().value();
        assert!(initial_sy > 0);

        let repayment_amount_y = max_repayment_amt_y * 2;
        let (exp_repayment_amt_y, exp_reward_amt_x) = model.calc_liquidate_col_x(
            p_x128,
            repayment_amount_y,
            config.liq_margin_bps(),
            config.liq_bonus_bps(),
            config.base_liq_factor_bps(),
        );
        assert!(exp_repayment_amt_y == max_repayment_amt_y);
        let exp_liq_fee = util::muldiv(
            exp_reward_amt_x,
            (config.liq_bonus_bps() as u64) * (config.liq_fee_bps() as u64),
            (10000 + (config.liq_bonus_bps() as u64)) * 10000,
        );
        assert!(exp_liq_fee > 0);

        let mut repayment_y = balance::create_for_testing(repayment_amount_y);
        let reward_x = setup.liquidate_col_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );

        assert!(reward_x.value() == exp_reward_amt_x - exp_liq_fee);
        assert!(repayment_y.value() == repayment_amount_y - max_repayment_amt_y);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);
        assert!(position.col_x().value() == initial_cx - exp_reward_amt_x);
        assert!(position.col_x().value() > 0);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<SUI>()] == collected_protocol_fees_x + exp_liq_fee,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_y);
        destroy(reward_x);
    };

    destroy(position_cap);
}

/* ================= liquidate_col_y tests ================= */

public macro fun liquidate_col_y_aborts_when_invalid_config<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_y_tests!(setup);

    // Move price to trigger liquidation and deleverage
    move_price_to_trigger_liquidation_col_y!(setup);
    deleverage_for_liquidation!(setup);

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

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_invalid_config
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &invalid_config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        test_scenario::return_shared(invalid_config);
        destroy(repayment_x);
        destroy(reward_y);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_y_aborts_when_ticket_active<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_y_tests!(setup);

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation_col_y!(setup);
    deleverage_for_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

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
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        setup.deleverage_ticket_repay_x(&mut position, &config, &mut ticket);
        setup.deleverage_ticket_repay_y(&mut position, &config, &mut ticket);
        position.destroy_deleverage_ticket(ticket);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
        destroy(reward_y);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_y_aborts_when_liquidation_disabled<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_y_tests!(setup);

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
    move_price_to_trigger_liquidation_col_y!(setup);

    // deleverage
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let price_info = setup.price_info();

        let action_request = setup.deleverage(
            &mut position,
            &mut config,
            &price_info,
            u128::max_value!(),
        );
        action_request.admin_approve_request(setup.package_admin());

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_liquidation_disabled
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
        destroy(reward_y);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_y_aborts_when_supply_pool_mismatch<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_y_tests!(setup);

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation_col_y!(setup);
    deleverage_for_liquidation!(setup);

    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        // This should abort with e_supply_pool_mismatch
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let reward_y = setup.liquidate_col_y_with_wrong_supply_pool(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
        destroy(reward_y);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_y_returns_zero_when_repayment_amount_is_zero<$Setup>(
    $setup: &mut $Setup,
) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_y_tests!(setup);

    // Don't move price - position should be healthy
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config) == false);

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let (repayment_amt_x, reward_amt_y) = setup.calc_liquidate_col_y(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_x == 0);
        assert!(reward_amt_y == 0);

        let initial_l = position.lp_position().liquidity();
        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_sy = position.debt_bag().get_share_amount_by_asset_type<USDC>();
        assert!(initial_sx > 0);
        assert!(initial_sy > 0);

        // This should return zero balance
        let mut repayment_x = balance::create_for_testing(100_000000000);
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        assert!(reward_y.value() == 0);
        assert!(repayment_x.value() == 100_000000000); // No repayment taken
        assert!(position.lp_position().liquidity() == initial_l);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == initial_sx);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == initial_sy);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
        destroy(reward_y);
    };

    destroy(position_cap);
}

public macro fun liquidate_col_y_is_correct<$Setup>($setup: &mut $Setup) {
    let setup = $setup;

    // Create position first
    let position_cap = create_position_for_liquidate_col_y_tests!(setup);

    // Move price to trigger liquidation
    move_price_to_trigger_liquidation_col_y!(setup);
    deleverage_for_liquidation!(setup);

    // Partial liquidation with limited repayment
    setup.next_tx(@0);
    let collected_protocol_fees_y = {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let validated_debt_info = config.validate_debt_info(&debt_info);

        let model = setup.position_model(&position, &config);
        let p_x128 = config
            .validate_price_info(&price_info)
            .div_price_numeric_x128(
                type_name::with_defining_ids<SUI>(),
                type_name::with_defining_ids<USDC>(),
            );
        let (max_repayment_amt_x, max_reward_amt_y) = model.calc_liquidate_col_y(
            p_x128,
            u64::max_value!(),
            config.liq_margin_bps(),
            config.liq_bonus_bps(),
            config.base_liq_factor_bps(),
        );

        assert!(max_repayment_amt_x == 14418266918);
        assert!(max_reward_amt_y == 83871059);
        assert!(model.dx() == max_repayment_amt_x);
        assert!(position.col_y().value() > max_reward_amt_y);
        assert!(
            position.collected_fees().amounts().contains(&type_name::with_defining_ids<USDC>()) == false
        );

        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_cy = position.col_y().value();

        let partial_repayment_amt_x = 3604566729;
        let (exp_repayment_amt_x, exp_reward_amt_y) = model.calc_liquidate_col_y(
            p_x128,
            partial_repayment_amt_x,
            config.liq_margin_bps(),
            config.liq_bonus_bps(),
            config.base_liq_factor_bps(),
        );
        assert!(exp_repayment_amt_x == partial_repayment_amt_x);
        let exp_liq_fee = util::muldiv(
            exp_reward_amt_y,
            (config.liq_bonus_bps() as u64) * (config.liq_fee_bps() as u64),
            (10000 + (config.liq_bonus_bps() as u64)) * 10000,
        );
        assert!(exp_liq_fee > 0);
        let exp_sx_repaid = validated_debt_info.calc_repay_by_amount(
            type_name::with_defining_ids<SSUI>(),
            partial_repayment_amt_x,
        );
        assert!(exp_sx_repaid > 0);

        let mut repayment_x = balance::create_for_testing(partial_repayment_amt_x);
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        assert!(reward_y.value() == exp_reward_amt_y - exp_liq_fee);
        assert!(repayment_x.value() == 0);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<SUI>() == initial_sx - exp_sx_repaid,
        );
        assert!(position.col_y().value() == initial_cy - exp_reward_amt_y);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<USDC>()] == exp_liq_fee,
        );
        let collected_protocol_fees_y = exp_liq_fee;

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
        destroy(reward_y);

        collected_protocol_fees_y
    };
    
    // Full liquidation
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        // sanity check
        assert!(position_is_liquidateable!(setup, &position, &config));

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        let model = setup.position_model(&position, &config);
        let p_x128 = config
            .validate_price_info(&price_info)
            .div_price_numeric_x128(
                type_name::with_defining_ids<SUI>(),
                type_name::with_defining_ids<USDC>(),
            );
        let (max_repayment_amt_x, max_reward_amt_y) = model.calc_liquidate_col_y(
            p_x128,
            u64::max_value!(),
            config.liq_margin_bps(),
            config.liq_bonus_bps(),
            config.base_liq_factor_bps(),
        );

        assert!(max_repayment_amt_x == 10813700189);
        assert!(max_reward_amt_y == 62903294);
        assert!(position.col_y().value() > max_reward_amt_y);
        assert!(model.dx() == max_repayment_amt_x);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<USDC>()] == collected_protocol_fees_y,
        );

        let initial_sx = position.debt_bag().get_share_amount_by_asset_type<SUI>();
        let initial_cy = position.col_y().value();
        assert!(initial_sx > 0);

        let repayment_amount_x = max_repayment_amt_x * 2;
        let (exp_repayment_amt_x, exp_reward_amt_y) = model.calc_liquidate_col_y(
            p_x128,
            repayment_amount_x,
            config.liq_margin_bps(),
            config.liq_bonus_bps(),
            config.base_liq_factor_bps(),
        );
        assert!(exp_repayment_amt_x == max_repayment_amt_x);
        let exp_liq_fee = util::muldiv(
            exp_reward_amt_y,
            (config.liq_bonus_bps() as u64) * (config.liq_fee_bps() as u64),
            (10000 + (config.liq_bonus_bps() as u64)) * 10000,
        );
        assert!(exp_liq_fee > 0);

        let mut repayment_x = balance::create_for_testing(repayment_amount_x);
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );

        assert!(reward_y.value() == exp_reward_amt_y - exp_liq_fee);
        assert!(repayment_x.value() == repayment_amount_x - max_repayment_amt_x);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);
        assert!(position.col_y().value() == initial_cy - exp_reward_amt_y);
        assert!(position.col_y().value() > 0);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<USDC>()] == collected_protocol_fees_y + exp_liq_fee,
        );

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
        destroy(repayment_x);
        destroy(reward_y);
    };

    destroy(position_cap);
}

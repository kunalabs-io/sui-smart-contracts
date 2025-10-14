#[test_only]
module kai_leverage::position_core_deleverage_standard_flow_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{PositionConfig, PositionCap};
use kai_leverage::position_core_test_util::{
    price_mul_100_human_to_sqrt_x64,
    sqrt_price_x64_to_price_human_mul_n
};
use kai_leverage::pyth;
use std::type_name;
use std::u128;
use sui::balance;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

// cetus
use fun cetus_clmm::pool::current_sqrt_price as cetus_clmm::pool::Pool.current_sqrt_price_x64;
use fun cetus_clmm::pool::liquidity as cetus_clmm::pool::Pool.active_liquidity;

// bluefin
use fun bluefin_spot::pool::current_sqrt_price as bluefin_spot::pool::Pool.current_sqrt_price_x64;

public macro fun deleverage_with_ticket_standard_flow<$Setup>($setup: &mut $Setup): PositionCap {
    let setup = $setup;

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    // create position
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
        assert!(config.current_global_l() == delta_l);

        // borrow
        setup.borrow_for_position_x(
            &mut ticket,
            &config,
        );
        setup.borrow_for_position_y(
            &mut ticket,
            &config,
        );

        // create position
        let position_cap = setup.create_position(
            &config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(config);

        position_cap
    };

    // do a swap to move the price for position margin to go below deleverage threshold,
    // but above liquidation threshold
    setup.next_tx(@0);
    {
        let config: PositionConfig = setup.scenario().take_shared();
        let position = setup.take_shared_position();

        // some sanity checks
        assert!(position.lp_position().liquidity() == 31467114902);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 98513978425 << 64);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 555201071 << 64);

        // swap to move the price the right amount
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(2_19));

        // update pyth price info
        setup.sync_pyth_pio_price_x_to_pool();

        // sanity check that margin level is below deleverage threshold but above liquidation threshold
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
    };

    // deleverage
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let model = setup.position_model(&position, &config);

        let (mut ticket, request) = setup.create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

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
        let initial_l = 31467114902;
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

        setup.deleverage_ticket_repay_x(
            &mut position,
            &config,
            &mut ticket,
        );
        setup.deleverage_ticket_repay_y(
            &mut position,
            &config,
            &mut ticket,
        );
        let initial_dx = 98513978425;
        let initial_dy = 555201071;
        assert!(ticket.can_repay_y() == false);
        assert!(ticket.can_repay_x() == false);
        assert!(ticket.info().x_repaid() == initial_dx); // all x was repaid
        assert!(ticket.info().y_repaid() == exp_delta_y); // all withdrawn y was repaid
        assert!(position.col_x().value() == exp_delta_x - initial_dx);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<USDC>() == ((initial_dy - exp_delta_y) as u128) << 64,
        );

        position.destroy_deleverage_ticket(ticket);
        assert!(position.ticket_active() == false);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    position_cap
}

public macro fun deleverage_helper_standard_flow<$Setup>($setup: &mut $Setup): PositionCap {
    let setup = $setup;

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    // create position
    setup.next_tx(@0);
    let position_cap = {
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let principal_x_amount = 100_000000000;
        let principal_y_amount = 100_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 31467114902;

        let mut price_info = pyth::create(setup.clock());
        price_info.add(setup.sui_pio());
        price_info.add(setup.usdc_pio());

        let mut ticket = setup.create_position_ticket(
            &mut config,
            tick_a,
            tick_b,
            principal_x,
            principal_y,
            delta_l,
            &price_info,
        );
        assert!(config.current_global_l() == delta_l);

        // borrow
        setup.borrow_for_position_x(
            &mut ticket,
            &config,
        );
        setup.borrow_for_position_y(
            &mut ticket,
            &config,
        );

        // create position
        let position_cap = setup.create_position(
            &config,
            ticket,
            balance::create_for_testing(1_000000000),
        );

        test_scenario::return_shared(config);

        position_cap
    };

    // do a swap to move the price for position margin to go below deleverage threshold,
    // but above liquidation threshold
    setup.next_tx(@0);
    {
        let config: PositionConfig = setup.scenario().take_shared();
        let position = setup.take_shared_position();

        // some sanity checks
        assert!(position.lp_position().liquidity() == 31467114902);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 98513978425 << 64);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 555201071 << 64);

        // swap to move the price the right amount
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(7_97));

        // update pyth price info
        setup.sync_pyth_pio_price_x_to_pool();

        // sanity check that margin level is below deleverage threshold but above liquidation threshold
        let model = setup.position_model(&position, &config);

        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        assert!(model.margin_below_threshold(p_x128, config.deleverage_margin_bps()));
        assert!(!model.margin_below_threshold(p_x128, config.liq_margin_bps()));

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    // deleverage
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

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

        let request = setup.deleverage(
            &mut position,
            &mut config,
            &price_info,
            u128::max_value!(),
        );
        request.admin_approve_request(setup.package_admin());

        let initial_l = 31467114902;
        let exp_global_l = initial_l - exp_delta_l;
        assert!(config.current_global_l() == exp_global_l);
        assert!(position.ticket_active() == false);

        let initial_dx = 98513978425;
        let initial_dy = 555201071;
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == exp_delta_y - initial_dy);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<SUI>() == ((initial_dx - exp_delta_x) as u128) << 64,
        );
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    position_cap
}

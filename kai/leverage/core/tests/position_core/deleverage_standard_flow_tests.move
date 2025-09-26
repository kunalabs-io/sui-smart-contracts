#[test_only]
module kai_leverage::position_core_deleverage_standard_flow_tests;

use kai_leverage::debt_info;
use kai_leverage::mock_dex::{Self, PositionKey};
use kai_leverage::mock_dex_integration;
use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{PositionConfig, Position};
use kai_leverage::position_core_test_util::{
    Self,
    price_mul_100_human_to_sqrt_x64,
    sqrt_price_x64_to_price_human_mul_n
};
use kai_leverage::pyth;
use kai_leverage::pyth_test_util;
use std::type_name;
use std::u128;
use sui::balance;
use sui::clock;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

#[test]
fun deleverage_with_ticket_standard_flow_is_correct() {
    let mut scenario = test_scenario::begin(@0);
    let package_admin = position_core_test_util::create_admin_for_testing(scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(1755000000000);
    let (
        mut sui_pio,
        usdc_pio,
        mut pool,
        mut supply_pool_x,
        mut supply_pool_y,
    ) = position_core_test_util::initialize_config_for_testing(
        &mut scenario,
        &package_admin,
        &clock,
    );

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    // create position
    scenario.next_tx(@0);
    let position_cap = {
        let mut config = scenario.take_shared();

        let principal_x_amount = 100_000000000;
        let principal_y_amount = 100_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 31467114902;

        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);

        let mut ticket = mock_dex_integration::create_position_ticket(
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
        assert!(config.current_global_l() == delta_l);

        // borrow
        mock_dex_integration::borrow_for_position_x(
            &mut ticket,
            &config,
            &mut supply_pool_x,
            &clock,
        );
        mock_dex_integration::borrow_for_position_y(
            &mut ticket,
            &config,
            &mut supply_pool_y,
            &clock,
        );

        // create position
        let position_cap = mock_dex_integration::create_position(
            &config,
            ticket,
            &mut pool,
            balance::create_for_testing(1_000000000),
            scenario.ctx(),
        );

        test_scenario::return_shared(config);

        position_cap
    };

    // do a swap to move the price for position margin to go below deleverage threshold,
    // but above liquidation threshold
    scenario.next_tx(@0);
    {
        let config: PositionConfig = scenario.take_shared();
        let position: Position<SUI, USDC, PositionKey> = scenario.take_shared();

        // some sanity checks
        assert!(position.lp_position().liquidity() == 31467114902);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 98513978425 << 64);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 555201071 << 64);

        // calculate delta_x to move the price the right amount
        let delta_x = mock_dex_math::get_delta_a(
            pool.current_sqrt_price_x64(),
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(2_19),
            pool.active_liquidity(),
            true,
        );
        let balance_y = mock_dex::swap_x_in(&mut pool, balance::create_for_testing(delta_x));
        destroy(balance_y);

        // update pyth price info
        pyth_test_util::update_pyth_pio_price_human_mul_n(
            &mut sui_pio,
            sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(pool.current_sqrt_price_x64(), 8),
            8,
            &clock,
        );

        // sanity check that margin level is below deleverage threshold but above liquidation threshold
        let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
        debt_info.add_from_supply_pool(
            &mut supply_pool_x,
            &clock,
        );
        debt_info.add_from_supply_pool(
            &mut supply_pool_y,
            &clock,
        );
        let model = mock_dex_integration::validated_model_for_position(
            &position,
            &config,
            &debt_info,
        );

        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);
        let price_info = config.validate_price_info(&price_info);
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        assert!(model.margin_below_threshold(p_x128, config.deleverage_margin_bps()));
        assert!(!model.margin_below_threshold(p_x128, config.liq_margin_bps()));

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // deleverage
    scenario.next_tx(@0);
    {
        let mut position: Position<SUI, USDC, PositionKey> = scenario.take_shared();
        let mut config: PositionConfig = scenario.take_shared();

        let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
        debt_info.add_from_supply_pool(
            &mut supply_pool_x,
            &clock,
        );
        debt_info.add_from_supply_pool(
            &mut supply_pool_y,
            &clock,
        );
        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);

        let model = mock_dex_integration::validated_model_for_position(
            &position,
            &config,
            &debt_info,
        );

        let (mut ticket, request) = mock_dex_integration::create_deleverage_ticket(
            &mut position,
            &mut config,
            &price_info,
            &debt_info,
            &mut pool,
            u128::max_value!(),
            scenario.ctx(),
        );
        request.admin_approve_request(&package_admin);

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
            pool.current_tick_index(),
            pool.current_sqrt_price_x64(),
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
        assert!(info.sqrt_pool_price_x64() == pool.current_sqrt_price_x64());
        assert!(info.delta_l() == exp_delta_l);
        assert!(info.delta_x() == exp_delta_x);
        assert!(info.delta_y() == exp_delta_y);
        assert!(info.x_repaid() == 0);
        assert!(info.y_repaid() == 0);

        position.deleverage_ticket_repay_x(
            &config,
            &mut ticket,
            &mut supply_pool_x,
            &clock,
        );
        position.deleverage_ticket_repay_y(
            &config,
            &mut ticket,
            &mut supply_pool_y,
            &clock,
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

    scenario.end();

    destroy(position_cap);
    destroy(pool);
    destroy(package_admin);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
    destroy(supply_pool_x);
    destroy(supply_pool_y);
}

#[test]
fun deleverage_helper_standard_flow_is_correct() {
    let mut scenario = test_scenario::begin(@0);
    let package_admin = position_core_test_util::create_admin_for_testing(scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(1755000000000);
    let (
        mut sui_pio,
        usdc_pio,
        mut pool,
        mut supply_pool_x,
        mut supply_pool_y,
    ) = position_core_test_util::initialize_config_for_testing(
        &mut scenario,
        &package_admin,
        &clock,
    );

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_47),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(8_91),
    );

    // create position
    scenario.next_tx(@0);
    let position_cap = {
        let mut config = scenario.take_shared();

        let principal_x_amount = 100_000000000;
        let principal_y_amount = 100_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 31467114902;

        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);

        let mut ticket = mock_dex_integration::create_position_ticket(
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
        assert!(config.current_global_l() == delta_l);

        // borrow
        mock_dex_integration::borrow_for_position_x(
            &mut ticket,
            &config,
            &mut supply_pool_x,
            &clock,
        );
        mock_dex_integration::borrow_for_position_y(
            &mut ticket,
            &config,
            &mut supply_pool_y,
            &clock,
        );

        // create position
        let position_cap = mock_dex_integration::create_position(
            &config,
            ticket,
            &mut pool,
            balance::create_for_testing(1_000000000),
            scenario.ctx(),
        );

        test_scenario::return_shared(config);

        position_cap
    };

    // do a swap to move the price for position margin to go below deleverage threshold,
    // but above liquidation threshold
    scenario.next_tx(@0);
    {
        let config: PositionConfig = scenario.take_shared();
        let position: Position<SUI, USDC, PositionKey> = scenario.take_shared();

        // some sanity checks
        assert!(position.lp_position().liquidity() == 31467114902);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 98513978425 << 64);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 555201071 << 64);

        // calculate delta_y to move the price the right amount
        let delta_y = mock_dex_math::get_delta_b(
            pool.current_sqrt_price_x64(),
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(7_97),
            pool.active_liquidity(),
            true,
        );
        let balance_y = mock_dex::swap_y_in(&mut pool, balance::create_for_testing(delta_y));
        destroy(balance_y);

        // update pyth price info
        pyth_test_util::update_pyth_pio_price_human_mul_n(
            &mut sui_pio,
            sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(pool.current_sqrt_price_x64(), 8),
            8,
            &clock,
        );

        // sanity check that margin level is below deleverage threshold but above liquidation threshold
        let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
        debt_info.add_from_supply_pool(
            &mut supply_pool_x,
            &clock,
        );
        debt_info.add_from_supply_pool(
            &mut supply_pool_y,
            &clock,
        );
        let model = mock_dex_integration::validated_model_for_position(
            &position,
            &config,
            &debt_info,
        );

        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);
        let price_info = config.validate_price_info(&price_info);
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        assert!(model.margin_below_threshold(p_x128, config.deleverage_margin_bps()));
        assert!(!model.margin_below_threshold(p_x128, config.liq_margin_bps()));

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // deleverage
    scenario.next_tx(@0);
    {
        let mut position: Position<SUI, USDC, PositionKey> = scenario.take_shared();
        let mut config: PositionConfig = scenario.take_shared();

        let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
        debt_info.add_from_supply_pool(
            &mut supply_pool_x,
            &clock,
        );
        debt_info.add_from_supply_pool(
            &mut supply_pool_y,
            &clock,
        );
        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);

        let model = mock_dex_integration::validated_model_for_position(
            &position,
            &config,
            &debt_info,
        );

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
            pool.current_tick_index(),
            pool.current_sqrt_price_x64(),
            exp_delta_l,
            false,
        );

        let request = mock_dex_integration::deleverage(
            &mut position,
            &mut config,
            &price_info,
            &mut supply_pool_x,
            &mut supply_pool_y,
            &mut pool,
            u128::max_value!(),
            &clock,
            scenario.ctx(),
        );
        request.admin_approve_request(&package_admin);

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

    scenario.end();

    destroy(position_cap);
    destroy(pool);
    destroy(package_admin);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
    destroy(supply_pool_x);
    destroy(supply_pool_y);
}

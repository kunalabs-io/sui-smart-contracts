#[test_only]
module kai_leverage::position_core_bad_debt_standard_flow_tests;

use integer_mate::i32;
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
use kai_leverage::util;
use std::type_name;
use std::u64;
use sui::balance;
use sui::clock;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

#[test]
fun repay_bad_debt_x_standard_flow_is_correct() {
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

    // add some initial liquidity to the pool to facilitate swaps
    scenario.next_tx(@0);
    {
        let tick_a = i32::neg_from(443636);
        let tick_b = i32::from(443636);
        let liquidity = 100000000000;
        let (amt_x, amt_y) = pool.calc_deposit_amounts_by_liquidity(
            tick_a,
            tick_b,
            liquidity,
        );
        let balance_x = balance::create_for_testing(amt_x);
        let balance_y = balance::create_for_testing(amt_y);

        let position = pool.open_position(
            tick_a,
            tick_b,
            liquidity,
            balance_x,
            balance_y,
            scenario.ctx(),
        );

        destroy(position);
    };

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_49),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );

    // create position
    scenario.next_tx(@0);
    let position_cap = {
        let mut config = scenario.take_shared();

        let principal_x_amount = 10_000000000;
        let principal_y_amount = 1_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 103639266383;

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

    // do a swap to make the position go below liquidation threshold
    scenario.next_tx(@0);
    {
        let config: PositionConfig = scenario.take_shared();
        let position: Position<SUI, USDC, PositionKey> = scenario.take_shared();

        // some sanity checks
        assert!(position.lp_position().liquidity() == 103639266383);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 14418266918 << 64);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 7959953 << 64);
        assert!(position.debt_bag().fdb_size() == 2);

        // calculate delta_y to move the price the right amount
        let delta_y = mock_dex_math::get_delta_b(
            pool.current_sqrt_price_x64(),
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(6_50),
            pool.active_liquidity(),
            true,
        );
        let balance_x = mock_dex::swap_y_in(&mut pool, balance::create_for_testing(delta_y));
        destroy(balance_x);

        // update pyth price info
        pyth_test_util::update_pyth_pio_price_human_mul_n(
            &mut sui_pio,
            sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(pool.current_sqrt_price_x64(), 8),
            8,
            &clock,
        );

        // sanity check that margin level is below crit margin
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
            type_name::get<SUI>(),
            type_name::get<USDC>(),
        );

        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(p_x128, crit_margin_bps));

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // liquidate
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

        mock_dex_integration::deleverage_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &mut supply_pool_x,
            &mut supply_pool_y,
            &mut pool,
            &clock,
        );

        // checks after deleverage
        let exp_delta_l = 103639266383;
        let (_, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            pool.current_tick_index(),
            pool.current_sqrt_price_x64(),
            exp_delta_l,
            false,
        );
        let initial_dx = 14418266918;
        let initial_dy = 7959953;
        let exp_cx = 0;
        let exp_cy = exp_delta_y - initial_dy;

        assert!(config.current_global_l() == 0);
        assert!(position.ticket_active() == false);
        assert!(position.lp_position().liquidity() == 0);
        assert!(position.col_x().value() == exp_cx);
        assert!(position.col_y().value() == exp_cy);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<SUI>() == (initial_dx as u128) << 64,
        );
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);

        // sanity check that margin level is still below crit margin
        let model = mock_dex_integration::validated_model_for_position(
            &position,
            &config,
            &debt_info,
        );
        let validated_price_info = config.validate_price_info(&price_info);
        let oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::get<SUI>(),
            type_name::get<USDC>(),
        );
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(oracle_price_x128, crit_margin_bps));

        // check liquidation and reward amounts
        let (repayment_amt_y, reward_amt_x) = mock_dex_integration::calc_liquidate_col_x(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_y == 0);
        assert!(reward_amt_x == 0);

        let (repayment_amt_x, reward_amt_y) = mock_dex_integration::calc_liquidate_col_y(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_x == 8025694367);
        assert!(reward_amt_y == 87672035);
        assert!(reward_amt_y == exp_cy);
        let exp_fee_amt_y = util::muldiv(
            reward_amt_y,
            (config.liq_bonus_bps() as u64) * (config.liq_fee_bps() as u64),
            (10000 + (config.liq_bonus_bps() as u64)) * 10000,
        );
        assert!(exp_fee_amt_y == 417485);

        // liquidate
        let mut repayment_x = balance::create_for_testing(repayment_amt_x);
        let reward_y = mock_dex_integration::liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
            &mut supply_pool_x,
            &clock,
        );
        assert!(reward_y.value() == reward_amt_y - exp_fee_amt_y);
        destroy(repayment_x);
        destroy(reward_y);

        // check position after liquidation
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == exp_cy - reward_amt_y);
        assert!(position.debt_bag().size() == 1);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<SUI>() == (initial_dx - repayment_amt_x) as u128 << 64,
        );
        assert!(position.collected_fees().amounts().size() == 2);
        assert!(position.collected_fees().amounts()[&type_name::get<SUI>()] == 1_000000000);
        assert!(position.collected_fees().amounts()[&type_name::get<USDC>()] == exp_fee_amt_y);

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // repay bad debt
    scenario.next_tx(@0);
    {
        let mut position: Position<SUI, USDC, PositionKey> = scenario.take_shared();
        let config: PositionConfig = scenario.take_shared();

        let dx = 6392572551_u64;
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == (dx as u128) << 64);

        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);
        let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
        debt_info.add_from_supply_pool(
            &mut supply_pool_x,
            &clock,
        );
        debt_info.add_from_supply_pool(
            &mut supply_pool_y,
            &clock,
        );

        let mut repayment_x = balance::create_for_testing<SUI>(dx);
        let request = mock_dex_integration::repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut supply_pool_x,
            &mut repayment_x,
            &clock,
            scenario.ctx(),
        );
        request.admin_approve_request(&package_admin);
        repayment_x.destroy_zero();

        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);
        assert!(supply_pool_x.total_liabilities_x64() == 0);
        assert!(supply_pool_y.total_liabilities_x64() == 0);

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
fun repay_bad_debt_y_standard_flow_is_correct() {
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

    // add some initial liquidity to the pool to facilitate swaps
    scenario.next_tx(@0);
    {
        let tick_a = i32::neg_from(443636);
        let tick_b = i32::from(443636);
        let liquidity = 100000000000;
        let (amt_x, amt_y) = pool.calc_deposit_amounts_by_liquidity(
            tick_a,
            tick_b,
            liquidity,
        );
        let balance_x = balance::create_for_testing(amt_x);
        let balance_y = balance::create_for_testing(amt_y);

        let position = pool.open_position(
            tick_a,
            tick_b,
            liquidity,
            balance_x,
            balance_y,
            scenario.ctx(),
        );

        destroy(position);
    };

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_51),
    );

    // create position
    scenario.next_tx(@0);
    let position_cap = {
        let mut config = scenario.take_shared();

        let principal_x_amount = 1_000000000;
        let principal_y_amount = 50_000000;
        let principal_x = balance::create_for_testing(principal_x_amount);
        let principal_y = balance::create_for_testing(principal_y_amount);

        let delta_l = 131150098162;

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

    // do a swap to make the position go below bad debt threshold
    scenario.next_tx(@0);
    {
        let config: PositionConfig = scenario.take_shared();
        let position: Position<SUI, USDC, PositionKey> = scenario.take_shared();

        // some sanity checks
        assert!(position.lp_position().liquidity() == 131150098162);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 2073649862 << 64);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 61782766 << 64);
        assert!(position.debt_bag().fdb_size() == 2);

        // calculate delta_y to move the price the right amount
        let delta_x = mock_dex_math::get_delta_a(
            pool.current_sqrt_price_x64(),
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_50),
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

        // sanity check that margin level is below crit margin
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
            type_name::get<SUI>(),
            type_name::get<USDC>(),
        );

        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(p_x128, crit_margin_bps));

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // liquidate
    scenario.next_tx(@0);
    {
        let mut position: Position<SUI, USDC, PositionKey> = scenario.take_shared();
        let mut config: PositionConfig = scenario.take_shared();

        // deleverage
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

        mock_dex_integration::deleverage_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
            &mut supply_pool_x,
            &mut supply_pool_y,
            &mut pool,
            &clock,
        );

        // checks after deleverage
        let exp_delta_l = 131150098162;
        let (exp_delta_x, _) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            pool.current_tick_index(),
            pool.current_sqrt_price_x64(),
            exp_delta_l,
            false,
        );
        let initial_dx = 2073649862;
        let initial_dy = 61782766;
        let exp_cx = exp_delta_x - initial_dx;
        let exp_cy = 0;

        assert!(config.current_global_l() == 0);
        assert!(position.ticket_active() == false);
        assert!(position.lp_position().liquidity() == 0);
        assert!(position.col_x().value() == exp_cx);
        assert!(position.col_y().value() == exp_cy);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 0);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<USDC>() == (initial_dy as u128) << 64,
        );

        // sanity check that margin level is still below crit margin
        let model = mock_dex_integration::validated_model_for_position(
            &position,
            &config,
            &debt_info,
        );
        let validated_price_info = config.validate_price_info(&price_info);
        let oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::get<SUI>(),
            type_name::get<USDC>(),
        );
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(oracle_price_x128, crit_margin_bps));

        // check liquidation and reward amounts
        let (repayment_amt_x, reward_amt_y) = mock_dex_integration::calc_liquidate_col_y(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_x == 0);
        assert!(reward_amt_y == 0);

        let (repayment_amt_y, reward_amt_x) = mock_dex_integration::calc_liquidate_col_x(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_y == 23001783);
        assert!(reward_amt_x == 33404787696);
        assert!(reward_amt_x == exp_cx);
        let exp_fee_amt_x = util::muldiv(
            reward_amt_x,
            (config.liq_bonus_bps() as u64) * (config.liq_fee_bps() as u64),
            (10000 + (config.liq_bonus_bps() as u64)) * 10000,
        );
        assert!(exp_fee_amt_x == 159070417);

        // liquidate
        let mut repayment_y = balance::create_for_testing(repayment_amt_y);
        let reward_x = mock_dex_integration::liquidate_col_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
            &mut supply_pool_y,
            &clock,
        );
        assert!(reward_x.value() == reward_amt_x - exp_fee_amt_x);
        destroy(repayment_y);
        destroy(reward_x);

        // check position after liquidation
        assert!(position.lp_position().liquidity() == 0);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().size() == 1);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<USDC>() == (initial_dy - repayment_amt_y) as u128 << 64,
        );
        assert!(position.collected_fees().amounts().size() == 1);
        assert!(
            position.collected_fees().amounts()[&type_name::get<SUI>()] == 1_000000000 + exp_fee_amt_x,
        );

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // repay bad debt
    scenario.next_tx(@0);
    {
        let mut position: Position<SUI, USDC, PositionKey> = scenario.take_shared();
        let config: PositionConfig = scenario.take_shared();

        let dy = 38780983_u64;
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == (dy as u128) << 64);

        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);
        let mut debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
        debt_info.add_from_supply_pool(
            &mut supply_pool_x,
            &clock,
        );
        debt_info.add_from_supply_pool(
            &mut supply_pool_y,
            &clock,
        );

        let mut repayment_y = balance::create_for_testing<USDC>(dy);
        let request = mock_dex_integration::repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut supply_pool_y,
            &mut repayment_y,
            &clock,
            scenario.ctx(),
        );
        request.admin_approve_request(&package_admin);
        repayment_y.destroy_zero();

        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);
        assert!(supply_pool_x.total_liabilities_x64() == 0);
        assert!(supply_pool_y.total_liabilities_x64() == 0);

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

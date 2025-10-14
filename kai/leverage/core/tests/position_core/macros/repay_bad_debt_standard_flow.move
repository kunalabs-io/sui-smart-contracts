#[test_only]
module kai_leverage::position_core_repay_bad_debt_standard_flow_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{PositionConfig, PositionCap};
use kai_leverage::position_core_test_util::{
    price_mul_100_human_to_sqrt_x64,
    sqrt_price_x64_to_price_human_mul_n
};
use kai_leverage::util;
use std::type_name;
use std::u64;
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

public macro fun repay_bad_debt_x_standard_flow<$Setup>($setup: &mut $Setup): PositionCap {
    let setup = $setup;

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_49),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
    );

    // create position
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

    // do a swap to make the position go below liquidation threshold
    setup.next_tx(@0);
    {
        let config: PositionConfig = setup.scenario().take_shared();
        let position = setup.take_shared_position();

        // some sanity checks
        assert!(position.lp_position().liquidity() == 103639266383);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 14418266918 << 64);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 7959953 << 64);
        assert!(position.debt_bag().length() == 2);

        // change price to move position below bad debt threshold
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(10_40));

        // update pyth price info
        setup.sync_pyth_pio_price_x_to_pool();

        // sanity check that margin level is below crit margin
        let model = setup.position_model(&position, &config);
        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(p_x128, crit_margin_bps));

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // liquidate
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        setup.deleverage_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
        );

        // checks after deleverage
        let exp_delta_l = 103639266383;
        let (_, exp_delta_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
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
        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(oracle_price_x128, crit_margin_bps));

        // check liquidation and reward amounts
        let (repayment_amt_y, reward_amt_x) = setup.calc_liquidate_col_x(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_y == 0);
        assert!(reward_amt_x == 0);

        let (repayment_amt_x, reward_amt_y) = setup.calc_liquidate_col_y(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_x == 8028574642);
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
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );
        assert!(reward_y.value() == reward_amt_y - exp_fee_amt_y);
        destroy(repayment_x);
        destroy(reward_y);

        // check position after liquidation
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == exp_cy - reward_amt_y);
        assert!(position.debt_bag().length() == 1);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<SUI>() == (initial_dx - repayment_amt_x) as u128 << 64,
        );
        assert!(position.collected_fees().amounts().length() == 2);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<SUI>()] == 1_000000000,
        );
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<USDC>()] == exp_fee_amt_y,
        );

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // repay bad debt
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        let dx = 6389692276;
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == (dx as u128) << 64);

        let price_info = setup.price_info();
        let debt_info = setup.debt_info(&config);

        let mut repayment_x = balance::create_for_testing<SUI>(dx);
        let request = setup.repay_bad_debt_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );
        request.admin_approve_request(setup.package_admin());
        repayment_x.destroy_zero();

        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);
        assert!(setup.supply_pool_x().total_liabilities_x64() == 0);
        assert!(setup.supply_pool_y().total_liabilities_x64() == 0);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    position_cap
}

public macro fun repay_bad_debt_y_standard_flow<$Setup>($setup: &mut $Setup): PositionCap {
    let setup = $setup;

    let tick_a = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
    );
    let tick_b = mock_dex_math::get_tick_at_sqrt_price(
        price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_51),
    );

    // create position
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

    // do a swap to make the position go below bad debt threshold
    setup.next_tx(@0);
    {
        let config: PositionConfig = setup.scenario().take_shared();
        let position = setup.take_shared_position();

        // some sanity checks
        assert!(position.lp_position().liquidity() == 131150098162);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().get_share_amount_by_asset_type<SUI>() == 2073649862 << 64);
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 61782766 << 64);
        assert!(position.debt_bag().length() == 2);

        // swap to move the price the right amount
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(0_72));

        // update pyth price info
        setup.sync_pyth_pio_price_x_to_pool();

        // sanity check that margin level is below crit margin
        let model = setup.position_model(&position, &config);
        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(p_x128, crit_margin_bps));

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // liquidate
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        // deleverage
        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();

        setup.deleverage_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
        );

        // checks after deleverage
        let exp_delta_l = 131150098162;
        let (exp_delta_x, _) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
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
        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        let crit_margin_bps = 10000 + config.liq_bonus_bps();
        assert!(model.margin_below_threshold(oracle_price_x128, crit_margin_bps));

        // check liquidation and reward amounts
        let (repayment_amt_x, reward_amt_y) = setup.calc_liquidate_col_y(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_x == 0);
        assert!(reward_amt_y == 0);

        let (repayment_amt_y, reward_amt_x) = setup.calc_liquidate_col_x(
            &position,
            &config,
            &price_info,
            &debt_info,
            u64::max_value!(),
        );
        assert!(repayment_amt_y == 22906140);
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
        let reward_x = setup.liquidate_col_x(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );
        assert!(reward_x.value() == reward_amt_x - exp_fee_amt_x);
        destroy(repayment_y);
        destroy(reward_x);

        // check position after liquidation
        assert!(position.lp_position().liquidity() == 0);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().length() == 1);
        assert!(
            position.debt_bag().get_share_amount_by_asset_type<USDC>() == (initial_dy - repayment_amt_y) as u128 << 64,
        );
        assert!(position.collected_fees().amounts().length() == 1);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<SUI>()] == 1_000000000 + exp_fee_amt_x,
        );

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // repay bad debt
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let config: PositionConfig = setup.scenario().take_shared();

        let dy = 38876626;
        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == (dy as u128) << 64);

        let price_info = setup.price_info();
        let debt_info = setup.debt_info(&config);

        let mut repayment_y = balance::create_for_testing<USDC>(dy);
        let request = setup.repay_bad_debt_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_y,
        );
        request.admin_approve_request(setup.package_admin());
        repayment_y.destroy_zero();

        assert!(position.debt_bag().get_share_amount_by_asset_type<USDC>() == 0);
        assert!(setup.supply_pool_x().total_liabilities_x64() == 0);
        assert!(setup.supply_pool_y().total_liabilities_x64() == 0);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    position_cap
}

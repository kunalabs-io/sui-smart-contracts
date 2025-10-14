#[test_only]
module kai_leverage::position_core_liquidate_standard_flow_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{Self as core, PositionConfig, PositionCap};
use kai_leverage::position_core_test_util::{
    price_mul_100_human_to_sqrt_x64,
    sqrt_price_x64_to_price_human_mul_n
};
use kai_leverage::util;
use std::type_name;
use std::u256;
use std::u64;
use sui::balance;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

// cetus
use fun cetus_clmm::pool::current_sqrt_price as cetus_clmm::pool::Pool.current_sqrt_price_x64;
use fun cetus_clmm::pool::liquidity as cetus_clmm::pool::Pool.active_liquidity;

public macro fun liquidate_col_x_standard_flow<$Setup>($setup: &mut $Setup): PositionCap {
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

    // do a swap to make the position go below liquidation threshold
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
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(1_77));

        // update pyth price info
        setup.sync_pyth_pio_price_x_to_pool();

        // sanity check that margin level is below liquidation threshold
        let model = setup.position_model(&position, &config);
        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        assert!(model.margin_below_threshold(p_x128, config.liq_margin_bps()));

        test_scenario::return_shared(config);
        test_scenario::return_shared(position);
    };

    // liquidate
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();
        let mut config: PositionConfig = setup.scenario().take_shared();

        // deleverage with ticket
        let debt_info = setup.debt_info(&config);
        let price_info = setup.price_info();
        let model = setup.position_model(&position, &config);

        let mut ticket = setup.create_deleverage_ticket_for_liquidation(
            &mut position,
            &mut config,
            &price_info,
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
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            exp_delta_l,
            false,
        );
        let initial_l = 131150098162;
        let exp_global_l = initial_l - exp_delta_l;
        assert!(config.current_global_l() == exp_global_l);
        assert!(position.ticket_active() == true);
        assert!(ticket.position_id() == object::id(&position));
        assert!(ticket.can_repay_x() == true);
        assert!(ticket.can_repay_y() == false);
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
        let initial_dx = 2073649862;
        let initial_dy = 61782766;
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

        core::destroy_deleverage_ticket(&mut position, ticket);

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

        // sanity check that margin level is still below liquidation threshold
        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        assert!(model.margin_below_threshold(oracle_price_x128, config.liq_margin_bps()));

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
        assert!(repayment_amt_y == 56310928);
        assert!(reward_amt_x == 33404787696);
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
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == exp_cy - reward_amt_y);
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

    position_cap
}

public macro fun liquidate_col_y_standard_flow<$Setup>($setup: &mut $Setup): PositionCap {
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

        // swap to move the price the right amount
        setup.swap_to_sqrt_price_x64(price_mul_100_human_to_sqrt_x64<SUI, USDC>(5_54));

        // update pyth price info
        setup.sync_pyth_pio_price_x_to_pool();

        // sanity check that margin level is below liquidation threshold
        let model = setup.position_model(&position, &config);
        let price_info = config.validate_price_info(&setup.price_info());
        let p_x128 = price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );

        assert!(model.margin_below_threshold(p_x128, config.liq_margin_bps()));

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

        // sanity check that margin level is still below liquidation threshold
        let model = setup.position_model(&position, &config);
        let validated_price_info = config.validate_price_info(&price_info);
        let oracle_price_x128 = validated_price_info.div_price_numeric_x128(
            type_name::with_defining_ids<SUI>(),
            type_name::with_defining_ids<USDC>(),
        );
        assert!(model.margin_below_threshold(oracle_price_x128, config.liq_margin_bps()));

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
        let exp_reward_amt_y = {
            let debt_value_x64 = (initial_dx as u256) * (oracle_price_x128 >> 64);
            let liq_bonus_x64 = ((config.liq_bonus_bps() as u256) << 64) / 10000;
            let repayment_value_with_bonus_x64 =
                (debt_value_x64 * ((1 << 64) + liq_bonus_x64)) >> 64;

            u256::divide_and_round_up(repayment_value_with_bonus_x64, 1 << 64) as u64
        };
        let exp_fee_amt_y = util::muldiv(
            exp_reward_amt_y,
            (config.liq_bonus_bps() as u64) * (config.liq_fee_bps() as u64),
            (10000 + (config.liq_bonus_bps() as u64)) * 10000,
        );
        assert!(exp_fee_amt_y == 399385);
        assert!(repayment_amt_x == initial_dx);
        assert!(reward_amt_y == exp_reward_amt_y);

        // liquidate
        let mut repayment_x = balance::create_for_testing(repayment_amt_x);
        let reward_y = setup.liquidate_col_y(
            &mut position,
            &config,
            &price_info,
            &debt_info,
            &mut repayment_x,
        );
        assert!(reward_y.value() == exp_reward_amt_y - exp_fee_amt_y);
        destroy(repayment_x);
        destroy(reward_y);

        // check position after liquidation
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == exp_cy - reward_amt_y);
        assert!(position.debt_bag().length() == 0);
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

    position_cap
}

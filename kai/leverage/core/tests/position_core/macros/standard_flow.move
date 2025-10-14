#[test_only]
module kai_leverage::position_core_standard_flow_test_macros;

use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{
    Self as core,
    PositionConfig,
    DeletedPositionCollectedFees,
    PositionCap
};
use kai_leverage::position_core_test_util::{
    price_mul_100_human_to_sqrt_x64,
    sqrt_price_x64_to_price_human_mul_n
};
use kai_leverage::pyth;
use kai_leverage::supply_pool_tests::{SSUI, SUSDC};
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
use fun cetus_clmm::tick_math::get_sqrt_price_at_tick as integer_mate::i32::I32.as_sqrt_price_x64;
use fun kai_leverage::cetus::calc_deposit_amounts_by_liquidity as
    cetus_clmm::pool::Pool.calc_deposit_amounts_by_liquidity;

public macro fun q64(): u128 {
    1 << 64
}

public macro fun q128(): u256 {
    1 << 128
}

public fun calc_expected_debt(
    initial_debt_x64: u128,
    seconds_passed: u128,
    interest_pct: u128,
): u64 {
    let seconds_in_year = 365 * 24 * 60 * 60;
    let accrued = (initial_debt_x64 * seconds_passed * interest_pct) / 100 / seconds_in_year;
    u128::divide_and_round_up(initial_debt_x64 + accrued, q64!()) as u64
}

public macro fun create_position<$Setup>($setup: &mut $Setup): PositionCap {
    let setup = $setup;

    // create position
    setup.next_tx(@0);
    let position_cap = {
        let mut config: PositionConfig = setup.scenario().take_shared();

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

        let mut price_info = pyth::create(setup.clock());
        price_info.add(setup.sui_pio_mut());
        price_info.add(setup.usdc_pio_mut());

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

        // check ticket fields
        assert!(ticket.config_id() == object::id(&config));
        assert!(ticket.tick_a() == tick_a);
        assert!(ticket.tick_b() == tick_b);
        assert!(ticket.dx() == 56352403581);
        assert!(ticket.dy() == 465614178);
        assert!(ticket.delta_l() == delta_l);
        assert!(ticket.principal_x().value() == principal_x_amount);
        assert!(ticket.principal_y().value() == principal_y_amount);
        assert!(ticket.borrowed_x().value() == 0);
        assert!(ticket.borrowed_y().value() == 0);
        assert!(ticket.debt_bag().is_empty());

        // borrow
        setup.borrow_for_position_x(
            &mut ticket,
            &config,
        );
        setup.borrow_for_position_y(
            &mut ticket,
            &config,
        );

        // check ticket fields after borrow
        assert!(ticket.borrowed_x().value() == 56352403581);
        assert!(ticket.borrowed_y().value() == 465614178);
        assert!(ticket.debt_bag().length() == 2);
        assert!(
            ticket.debt_bag().fdb_get_share_amount_by_asset_type<SUI>() == 56352403581 * (1u128 << 64),
        );
        assert!(
            ticket.debt_bag().fdb_get_share_amount_by_asset_type<USDC>() == 465614178 * (1u128 << 64),
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

    // check position fields
    setup.next_tx(@0);
    {
        let position = setup.take_shared_position();
        let config = setup.scenario().take_shared<PositionConfig>();

        let tick_a = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
        );
        let tick_b = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
        );

        let (act_tick_a, act_tick_b) = position.lp_position().tick_range();
        assert!(position_cap.position_id() == object::id(&position));
        assert!(position.config_id() == object::id(&config));
        assert!(act_tick_a == tick_a);
        assert!(act_tick_b == tick_b);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().length() == 2);
        assert!(position.collected_fees().amounts().length() == 1);
        assert!(
            position.collected_fees().amounts()[&type_name::with_defining_ids<SUI>()] == 1_000000000,
        );

        // check rate limiter after position creation
        assert!(config.has_create_withdraw_limiter());
        let limiter = config.borrow_create_withdraw_limiter();
        // Expected: 100 SUI * $3.50 + 100 USDC * $1.00 = $350 + $100 = $450 = 450000000 (6 decimals)
        assert!(limiter.inflow_total() == 450000000);
        assert!(limiter.outflow_total() == 0);
        let (net_amount, is_outflow) = limiter.net_value();
        assert!(net_amount == 450000000);
        assert!(is_outflow == false);

        let model = setup.position_model(
            &position,
            &config,
        );
        assert!(model.sqrt_pa_x64() == mock_dex_math::get_sqrt_price_at_tick(tick_a));
        assert!(model.sqrt_pb_x64() == mock_dex_math::get_sqrt_price_at_tick(tick_b));
        assert!(model.l() == 663611732121);
        assert!(model.cx() == 0);
        assert!(model.cy() == 0);
        assert!(model.dx() == 56352403581);
        assert!(model.dy() == 465614178);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    position_cap
}

public macro fun rebalance<$Setup>($setup: &mut $Setup): (u64, u64, u64, u128, u128) {
    let setup = $setup;

    // do some swaps and forward the clock to generate fees and rewards
    setup.next_tx(@0);
    {
        let position = setup.take_shared_position();
        let config = setup.scenario().take_shared<PositionConfig>();

        let initial_sqrt_price_x64 = setup.clmm_pool().current_sqrt_price_x64();
        setup.swap_to_sqrt_price_x64(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(4_00),
        );
        setup.swap_to_sqrt_price_x64(initial_sqrt_price_x64);

        // forward the clock by 1 day
        setup.clock_mut().increment_for_testing(1000 * 60 * 60 * 24);
        setup.update_pio_timestamps();

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);
    };

    // rebalance
    setup.next_tx(@0);
    let (
        exp_rebalance_fee_x,
        exp_rebalance_fee_y,
        exp_rebalance_reward_fee_sui,
        position_sx_after_rebalance,
        position_sy_after_rebalance,
    ) = {
        let mut position = setup.take_shared_position();
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let (mut receipt, request) = core::create_rebalance_receipt(
            &mut position,
            &config,
            setup.ctx(),
        );
        destroy(request);

        assert!(position.ticket_active() == true);
        assert!(receipt.position_id() == object::id(&position));
        assert!(receipt.collected_amm_fee_x() == 0);
        assert!(receipt.collected_amm_fee_y() == 0);
        assert!(receipt.collected_amm_rewards().length() == 0);
        assert!(receipt.fees_taken().length() == 0);
        assert!(receipt.taken_cx() == 0);
        assert!(receipt.taken_cy() == 0);
        assert!(receipt.delta_l() == 0);
        assert!(receipt.delta_x() == 0);
        assert!(receipt.delta_y() == 0);
        assert!(receipt.x_repaid() == 0);
        assert!(receipt.y_repaid() == 0);
        assert!(receipt.added_cx() == 0);
        assert!(receipt.added_cy() == 0);
        assert!(receipt.stashed_amm_rewards().length() == 0);

        let (exp_lp_fee_x, exp_lp_fee_y) = setup.get_lp_fee_amounts(position.lp_position());
        let exp_lp_reward_sui = setup.get_lp_reward_amount<SUI>(position.lp_position());
        // sanity check our test setup
        assert!(exp_lp_fee_x > 1000);
        assert!(exp_lp_fee_y > 1000);
        assert!(exp_lp_reward_sui > 1000);

        let (fee_balance_x, fee_balance_y) = setup.rebalance_collect_fee(
            &mut position,
            &config,
            &mut receipt,
        );
        let reward_balance_x = setup.rebalance_collect_reward<SUI>(
            &mut position,
            &config,
            &mut receipt,
        );

        let exp_rebalance_fee_x = exp_lp_fee_x * 1_00 / 10000;
        let exp_rebalance_fee_y = exp_lp_fee_y * 1_00 / 10000;
        let exp_rebalance_reward_fee_sui = exp_lp_reward_sui * 1_00 / 10000;
        assert!(fee_balance_x.value() == exp_lp_fee_x - exp_rebalance_fee_x);
        assert!(fee_balance_y.value() == exp_lp_fee_y - exp_rebalance_fee_y);
        assert!(reward_balance_x.value() == exp_lp_reward_sui - exp_rebalance_reward_fee_sui);
        assert!(receipt.collected_amm_fee_x() == exp_lp_fee_x);
        assert!(receipt.collected_amm_fee_y() == exp_lp_fee_y);
        assert!(
            receipt.collected_amm_rewards()[&type_name::with_defining_ids<SUI>()] == exp_lp_reward_sui,
        );
        assert!(
            receipt.fees_taken()[&type_name::with_defining_ids<SUI>()] == exp_rebalance_fee_x + exp_rebalance_reward_fee_sui,
        );
        assert!(receipt.fees_taken()[&type_name::with_defining_ids<USDC>()] == exp_rebalance_fee_y);
        destroy(fee_balance_x);
        destroy(fee_balance_y);
        destroy(reward_balance_x);

        let delta_l = 111732121;
        let (tick_a, tick_b) = position.lp_position().tick_range();
        let (delta_x_amt, delta_y_amt) = setup
            .clmm_pool()
            .calc_deposit_amounts_by_liquidity(
                tick_a,
                tick_b,
                delta_l,
            );
        setup.rebalance_add_liquidity(
            &mut position,
            &mut config,
            &mut receipt,
            delta_l,
            balance::create_for_testing(delta_x_amt),
            balance::create_for_testing(delta_y_amt),
        );
        assert!(config.current_global_l() == 663611732121 + delta_l);
        assert!(receipt.delta_l() == delta_l);
        assert!(receipt.delta_x() == delta_x_amt);
        assert!(receipt.delta_y() == delta_y_amt);
        assert!(position.lp_position().liquidity() == 663611732121 + delta_l);

        let mut repay_debt_x_balance = balance::create_for_testing(50000);
        let mut repay_debt_y_balance = balance::create_for_testing(60000);
        setup.rebalance_repay_debt_x(
            &mut position,
            &mut repay_debt_x_balance,
            &mut receipt,
        );
        setup.rebalance_repay_debt_y(
            &mut position,
            &mut repay_debt_y_balance,
            &mut receipt,
        );
        core::rebalance_stash_rewards(
            &mut position,
            &mut receipt,
            balance::create_for_testing<SUI>(70000),
        );
        repay_debt_x_balance.destroy_zero();
        repay_debt_y_balance.destroy_zero();
        assert!(receipt.x_repaid() == 50000);
        assert!(receipt.y_repaid() == 60000);
        assert!(receipt.stashed_amm_rewards().length() == 1);
        assert!(receipt.stashed_amm_rewards()[&type_name::with_defining_ids<SUI>()] == 70000);
        assert!(position.debt_bag().length() == 2);

        let validated_debt_info = setup.validated_debt_info(&config);
        let exp_shares_repaid_x = validated_debt_info.calc_repay_by_amount(
            type_name::with_defining_ids<SSUI>(),
            50000,
        );
        let exp_shares_repaid_y = validated_debt_info.calc_repay_by_amount(
            type_name::with_defining_ids<SUSDC>(),
            60000,
        );
        let position_sx_after_rebalance = (56352403581 << 64) - exp_shares_repaid_x;
        let position_sy_after_rebalance = (465614178 << 64) - exp_shares_repaid_y;
        assert!(
            position.debt_bag().fdb_get_share_amount_by_asset_type<SUI>() == position_sx_after_rebalance,
        );
        assert!(
            position.debt_bag().fdb_get_share_amount_by_asset_type<USDC>() == position_sy_after_rebalance,
        );

        // check all receipt fields once more
        assert!(receipt.position_id() == object::id(&position));
        assert!(receipt.collected_amm_fee_x() == exp_lp_fee_x);
        assert!(receipt.collected_amm_fee_y() == exp_lp_fee_y);
        assert!(
            receipt.collected_amm_rewards()[&type_name::with_defining_ids<SUI>()] == exp_lp_reward_sui,
        );
        assert!(
            receipt.fees_taken()[&type_name::with_defining_ids<SUI>()] == exp_rebalance_fee_x + exp_rebalance_reward_fee_sui,
        );
        assert!(receipt.fees_taken()[&type_name::with_defining_ids<USDC>()] == exp_rebalance_fee_y);
        assert!(receipt.taken_cx() == 0);
        assert!(receipt.taken_cy() == 0);
        assert!(receipt.delta_l() == delta_l);
        assert!(receipt.delta_x() == delta_x_amt);
        assert!(receipt.delta_y() == delta_y_amt);
        assert!(receipt.x_repaid() == 50000);
        assert!(receipt.y_repaid() == 60000);
        assert!(receipt.added_cx() == 0);
        assert!(receipt.added_cy() == 0);
        assert!(receipt.stashed_amm_rewards().length() == 1);
        assert!(receipt.stashed_amm_rewards()[&type_name::with_defining_ids<SUI>()] == 70000);

        core::consume_rebalance_receipt(
            &mut position,
            receipt,
        );
        assert!(position.ticket_active() == false);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);

        (
            exp_rebalance_fee_x,
            exp_rebalance_fee_y,
            exp_rebalance_reward_fee_sui,
            position_sx_after_rebalance,
            position_sy_after_rebalance,
        )
    };

    (
        exp_rebalance_fee_x,
        exp_rebalance_fee_y,
        exp_rebalance_reward_fee_sui,
        position_sx_after_rebalance,
        position_sy_after_rebalance,
    )
}

public macro fun collect_protocol_fees<$Setup>(
    $setup: &mut $Setup,
    $exp_rebalance_fee_x: u64,
    $exp_rebalance_fee_y: u64,
    $exp_rebalance_reward_fee_sui: u64,
) {
    let setup = $setup;

    // collect protocol fees
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();

        let (sui_balance, request) = core::collect_protocol_fees<_, _, SUI, _>(
            &mut position,
            option::none(),
            setup.ctx(),
        );
        request.admin_approve_request(setup.package_admin());
        let (usdc_balance, request) = core::collect_protocol_fees<_, _, USDC, _>(
            &mut position,
            option::none(),
            setup.ctx(),
        );
        request.admin_approve_request(setup.package_admin());

        assert!(
            sui_balance.value() == 1_000000000 + $exp_rebalance_fee_x + $exp_rebalance_reward_fee_sui,
        );
        assert!(usdc_balance.value() == $exp_rebalance_fee_y);
        assert!(position.collected_fees().amounts().length() == 0);

        destroy(sui_balance);
        destroy(usdc_balance);

        test_scenario::return_shared(position);
    };
}

public macro fun owner_repay_debt_and_add_collateral<$Setup>(
    $setup: &mut $Setup,
    $position_cap: &PositionCap,
    $position_sx_after_rebalance: u128,
    $position_sy_after_rebalance: u128,
): (u128, u128) {
    let setup = $setup;

    // owner repay a portion of the debt
    setup.next_tx(@0);
    let (position_sx_after_repay_debt, position_sy_after_repay_debt) = {
        let mut position = setup.take_shared_position();
        let config = setup.scenario().take_shared<PositionConfig>();

        let mut repay_debt_x_balance = balance::create_for_testing(10000);
        let mut repay_debt_y_balance = balance::create_for_testing(20000);
        setup.repay_debt_x(
            &mut position,
            $position_cap,
            &mut repay_debt_x_balance,
        );
        setup.repay_debt_y(
            &mut position,
            $position_cap,
            &mut repay_debt_y_balance,
        );
        repay_debt_x_balance.destroy_zero();
        repay_debt_y_balance.destroy_zero();
        assert!(position.debt_bag().length() == 2);

        let validated_debt_info = setup.validated_debt_info(&config);
        let repaid_sx = validated_debt_info.calc_repay_by_amount(
            type_name::with_defining_ids<SSUI>(),
            10000,
        );
        let repaid_sy = validated_debt_info.calc_repay_by_amount(
            type_name::with_defining_ids<SUSDC>(),
            20000,
        );
        let exp_sx = $position_sx_after_rebalance - repaid_sx;
        let exp_sy = $position_sy_after_rebalance - repaid_sy;
        assert!(position.debt_bag().fdb_get_share_amount_by_asset_type<SUI>() == exp_sx);
        assert!(position.debt_bag().fdb_get_share_amount_by_asset_type<USDC>() == exp_sy);

        test_scenario::return_shared(position);
        test_scenario::return_shared(config);

        (exp_sx, exp_sy)
    };

    // add collateral
    setup.next_tx(@0);
    {
        let mut position = setup.take_shared_position();

        let cx_balance = balance::create_for_testing(30000);
        let cy_balance = balance::create_for_testing(40000);
        core::add_collateral_x(
            &mut position,
            $position_cap,
            cx_balance,
        );
        core::add_collateral_y(
            &mut position,
            $position_cap,
            cy_balance,
        );
        assert!(position.col_x().value() == 30000);
        assert!(position.col_y().value() == 40000);

        test_scenario::return_shared(position);
    };

    (position_sx_after_repay_debt, position_sy_after_repay_debt)
}

public macro fun close_position<$Setup>(
    $setup: &mut $Setup,
    $position_cap: PositionCap,
    $position_sx_after_repay_debt: u128,
    $position_sy_after_repay_debt: u128,
): (u64, u64, u64) {
    let setup = $setup;
    let position_cap = $position_cap;
    let position_sx_after_repay_debt = $position_sx_after_repay_debt;
    let position_sy_after_repay_debt = $position_sy_after_repay_debt;

    let (initial_dx_x64, initial_dy_x64) = {
        let config = setup.scenario().take_shared<PositionConfig>();

        let debt_info = setup.validated_debt_info(&config);
        let initial_dx_x64 = debt_info.testing_calc_repay_x64(
            type_name::with_defining_ids<SSUI>(),
            position_sx_after_repay_debt,
        );
        let initial_dy_x64 = debt_info.testing_calc_repay_x64(
            type_name::with_defining_ids<SUSDC>(),
            position_sy_after_repay_debt,
        );

        test_scenario::return_shared(config);

        (initial_dx_x64, initial_dy_x64)
    };

    // do swaps to accrue rewards and make the position go out of range
    setup.next_tx(@0);
    {
        let position = setup.take_shared_position();

        // increment clock here so rewards accrue
        setup.clock_mut().increment_for_testing(10000_000); // +10000 seconds (~2.8 hours)
        setup.update_pio_timestamps();

        // do some swaps
        setup.swap_to_sqrt_price_x64(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(2_00),
        );
        setup.swap_to_sqrt_price_x64(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(4_00),
        );

        // update pyth price info
        setup.sync_pyth_pio_price_x_to_pool();

        test_scenario::return_shared(position);
    };

    // close position
    setup.next_tx(@0);
    let (exp_protocol_fee_x, exp_protocol_fee_y, exp_protocol_reward_fee_sui) = {
        let mut position = setup.take_shared_position();
        let mut config = setup.scenario().take_shared<PositionConfig>();

        let (balance_x, balance_y, mut ticket) = setup.reduce(
            &mut position,
            &mut config,
            &position_cap,
            1 << 64,
        );

        let tick_a = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
        );
        let tick_b = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
        );
        let exp_cx = 30000;
        let exp_cy = 40000;
        let (exp_x, exp_y) = mock_dex_math::get_amount_by_liquidity(
            tick_a,
            tick_b,
            setup.clmm_pool().current_tick_index(),
            setup.clmm_pool().current_sqrt_price_x64(),
            663723464242,
            false,
        );

        let seconds_passed = 10000;
        let interest_pct = 10;
        let exp_dx = calc_expected_debt(initial_dx_x64, seconds_passed, interest_pct);
        let exp_dy = calc_expected_debt(initial_dy_x64, seconds_passed, interest_pct);
        let exp_oracle_price_x128 =
            ((sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(setup.clmm_pool().current_sqrt_price_x64(), 8) as u256) * q128!()) / 10_u256.pow(8) / 1000;

        assert!(config.current_global_l() == 0);
        assert!(balance_x.value() == exp_x + exp_cx);
        assert!(balance_y.value() == exp_y + exp_cy);
        assert!(ticket.sx().facil_id() == object::id(config.lend_facil_cap()));
        assert!(ticket.sx().value_x64() == position_sx_after_repay_debt);
        assert!(ticket.sy().facil_id() == object::id(config.lend_facil_cap()));
        assert!(ticket.sy().value_x64() == position_sy_after_repay_debt);
        assert!(ticket.info().position_id() == object::id(&position));
        let withdrawn_balance_x_amount = balance_x.value();
        let withdrawn_balance_y_amount = balance_y.value();
        destroy(balance_x);
        destroy(balance_y);

        let info = ticket.info();
        let model = info.model();
        assert!(model.sqrt_pa_x64() == mock_dex_math::get_sqrt_price_at_tick(tick_a));
        assert!(model.sqrt_pb_x64() == mock_dex_math::get_sqrt_price_at_tick(tick_b));
        assert!(model.l() == 663723464242);
        assert!(model.cx() == exp_cx);
        assert!(model.cy() == exp_cy);
        assert!(model.dx() == exp_dx);
        assert!(model.dy() == exp_dy);
        assert!(info.oracle_price_x128() == exp_oracle_price_x128);
        assert!(info.sqrt_pool_price_x64() == setup.clmm_pool().current_sqrt_price_x64());
        assert!(info.delta_l() == 663723464242);
        assert!(info.delta_x() == exp_x);
        assert!(info.delta_y() == exp_y);
        assert!(info.withdrawn_x() == exp_x + exp_cx);
        assert!(info.withdrawn_y() == exp_y + exp_cy);
        assert!(info.x_repaid() == 0);
        assert!(info.y_repaid() == 0);

        // check rate limiter after position reduction
        let limiter = config.borrow_create_withdraw_limiter();
        assert!(limiter.inflow_total() == 450_000000);

        let validated_price_info = core::validate_price_info(&config, &setup.price_info());
        let withdrawn_x_value = core::get_amount_ema_usd_value_6_decimals<SUI>(
            withdrawn_balance_x_amount,
            &validated_price_info,
            true,
        );
        let withdrawn_y_value = core::get_amount_ema_usd_value_6_decimals<USDC>(
            withdrawn_balance_y_amount,
            &validated_price_info,
            true,
        );
        let repaid_x_value = core::get_amount_ema_usd_value_6_decimals<SUI>(
            exp_dx,
            &validated_price_info,
            true,
        );
        let repaid_y_value = core::get_amount_ema_usd_value_6_decimals<USDC>(
            exp_dy,
            &validated_price_info,
            true,
        );
        let expected_outflow =
            (withdrawn_x_value + withdrawn_y_value) - (repaid_x_value + repaid_y_value);
        assert!(limiter.outflow_total() == (expected_outflow as u256));
        let (net_amount, is_outflow) = limiter.net_value();
        assert!(net_amount == 450_000000 - (expected_outflow as u256));
        assert!(is_outflow == false);

        // repay ticket
        let repay_amt_x = setup.reduction_ticket_calc_repay_amt_x(
            &ticket,
        );
        let repay_amt_y = setup.reduction_ticket_calc_repay_amt_y(
            &ticket,
        );
        assert!(repay_amt_x == exp_dx);
        assert!(repay_amt_y == exp_dy);
        setup.reduction_ticket_repay_x(
            &mut ticket,
            balance::create_for_testing(repay_amt_x),
        );
        setup.reduction_ticket_repay_y(
            &mut ticket,
            balance::create_for_testing(repay_amt_y),
        );
        assert!(ticket.info().x_repaid() == exp_dx);
        assert!(ticket.info().y_repaid() == exp_dy);
        core::destroy_reduction_ticket(ticket);

        // collect fees and rewards
        let (exp_lp_fee_x, exp_lp_fee_y) = setup.get_lp_fee_amounts(position.lp_position());
        let exp_lp_reward_sui = setup.get_lp_reward_amount<SUI>(position.lp_position());
        // sanity check our setup
        assert!(exp_lp_fee_x > 1000);
        assert!(exp_lp_fee_y > 1000);
        assert!(exp_lp_reward_sui > 1000);

        let (fee_balance_x, fee_balance_y) = setup.owner_collect_fee(
            &mut position,
            &config,
            &position_cap,
        );
        let reward_balance = setup.owner_collect_reward<SUI>(
            &mut position,
            &config,
            &position_cap,
        );
        let reward_stash_balance = core::owner_take_stashed_rewards<_, _, SUI, _>(
            &mut position,
            &position_cap,
            option::none(),
        );
        let exp_fee_x = exp_lp_fee_x * 1_00 / 10000;
        let exp_fee_y = exp_lp_fee_y * 1_00 / 10000;
        let exp_fee_reward = exp_lp_reward_sui * 1_00 / 10000;
        assert!(fee_balance_x.value() == exp_lp_fee_x  - exp_fee_x);
        assert!(fee_balance_y.value() == exp_lp_fee_y - exp_fee_y);
        assert!(reward_balance.value() == exp_lp_reward_sui - exp_fee_reward);
        assert!(reward_stash_balance.value() == 70000);
        destroy(fee_balance_x);
        destroy(fee_balance_y);
        destroy(reward_balance);
        destroy(reward_stash_balance);

        // close position
        setup.delete_position(
            position,
            &config,
            position_cap,
        );

        test_scenario::return_shared(config);

        (exp_fee_x, exp_fee_y, exp_fee_reward)
    };

    (exp_protocol_fee_x, exp_protocol_fee_y, exp_protocol_reward_fee_sui)
}

public macro fun collect_deleted_position_fees<$Setup>(
    $setup: &mut $Setup,
    $exp_sui_balance: u64,
    $exp_usdc_balance: u64,
) {
    let setup = $setup;

    // collect deleted position fees
    setup.next_tx(@0);
    {
        let deleted_position_fees = setup.scenario().take_shared<DeletedPositionCollectedFees>();

        let (
            mut balance_bag,
            request,
        ) = deleted_position_fees.collect_deleted_position_fees(setup.ctx());
        request.admin_approve_request(setup.package_admin());

        let sui_balance = balance_bag.take_all<SUI>();
        let usdc_balance = balance_bag.take_all<USDC>();
        balance_bag.destroy_empty();
        assert!(sui_balance.value() == $exp_sui_balance, 0);
        assert!(usdc_balance.value() == $exp_usdc_balance, 0);

        destroy(sui_balance);
        destroy(usdc_balance);
    };
}

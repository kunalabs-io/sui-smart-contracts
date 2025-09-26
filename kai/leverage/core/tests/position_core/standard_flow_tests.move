#[test_only]
module kai_leverage::position_core_standard_flow_tests;

use kai_leverage::debt_info;
use kai_leverage::mock_dex::{Self, PositionKey};
use kai_leverage::mock_dex_integration;
use kai_leverage::mock_dex_math;
use kai_leverage::position_core_clmm::{
    Self as core,
    PositionConfig,
    Position,
    DeletedPositionCollectedFees
};
use kai_leverage::position_core_test_util::{
    Self,
    price_mul_100_human_to_sqrt_x64,
    sqrt_price_x64_to_price_human_mul_n
};
use kai_leverage::pyth;
use kai_leverage::pyth_test_util;
use std::type_name;
use std::u64;
use sui::balance;
use sui::clock;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

const Q64: u128 = 1 << 64;
const Q128: u256 = 1 << 128;

#[test]
fun standard_flow_is_correct() {
    let mut scenario = test_scenario::begin(@0);
    let package_admin = position_core_test_util::create_admin_for_testing(scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(1755000000000);
    let (
        mut sui_pio,
        mut usdc_pio,
        mut pool,
        mut supply_pool_x,
        mut supply_pool_y,
    ) = position_core_test_util::initialize_config_for_testing(
        &mut scenario,
        &package_admin,
        &clock,
    );

    // create position
    scenario.next_tx(@0);
    let position_cap = {
        let mut config = scenario.take_shared();

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

    // check position fields
    scenario.next_tx(@0);
    {
        let position: Position<SUI, USDC, PositionKey> = scenario.take_shared();
        let config = scenario.take_shared<PositionConfig>();

        let tick_a = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_40),
        );
        let tick_b = mock_dex_math::get_tick_at_sqrt_price(
            price_mul_100_human_to_sqrt_x64<SUI, USDC>(3_60),
        );

        assert!(position_cap.position_id() == object::id(&position));
        assert!(position.config_id() == object::id(&config));
        assert!(position.lp_position().tick_a() == tick_a);
        assert!(position.lp_position().tick_b() == tick_b);
        assert!(position.col_x().value() == 0);
        assert!(position.col_y().value() == 0);
        assert!(position.debt_bag().length() == 2);
        assert!(position.collected_fees().amounts().length() == 1);
        assert!(position.collected_fees().amounts()[&type_name::with_defining_ids<SUI>()] == 1_000000000);

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

    // rebalance
    scenario.next_tx(@0);
    {
        let mut position = scenario.take_shared<Position<SUI, USDC, PositionKey>>();
        let mut config = scenario.take_shared<PositionConfig>();

        pool.add_fees_to_position(
            position.lp_position().idx(),
            balance::create_for_testing(0_150000000),
            balance::create_for_testing(1_100000),
        );
        pool.add_reward_to_position(
            position.lp_position().idx(),
            balance::create_for_testing<SUI>(0_200000000),
        );

        let (mut receipt, request) = core::create_rebalance_receipt(
            &mut position,
            &config,
            scenario.ctx(),
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

        let (fee_balance_x, fee_balance_y) = mock_dex_integration::rebalance_collect_fee(
            &mut position,
            &config,
            &mut receipt,
            &mut pool,
        );
        let reward_balance_x = mock_dex_integration::rebalance_collect_reward<_, _, SUI>(
            &mut position,
            &config,
            &mut receipt,
            &mut pool,
        );
        let exp_rebalance_fee_x = 0_150000000 * 1_00 / 10000;
        let exp_rebalance_fee_y = 1_100000 * 1_00 / 10000;
        let exp_reward_sui = 0_200000000 * 1_00 / 10000;
        assert!(fee_balance_x.value() == 0_150000000 - exp_rebalance_fee_x);
        assert!(fee_balance_y.value() == 1_100000 - exp_rebalance_fee_y);
        assert!(reward_balance_x.value() == 0_200000000 - exp_reward_sui);
        assert!(receipt.collected_amm_fee_x() == 0_150000000);
        assert!(receipt.collected_amm_fee_y() == 1_100000);
        assert!(receipt.collected_amm_rewards()[&type_name::with_defining_ids<SUI>()] == 0_200000000);
        assert!(
            receipt.fees_taken()[&type_name::with_defining_ids<SUI>()] == exp_rebalance_fee_x + exp_reward_sui,
        );
        assert!(receipt.fees_taken()[&type_name::with_defining_ids<USDC>()] == exp_rebalance_fee_y);
        destroy(fee_balance_x);
        destroy(fee_balance_y);
        destroy(reward_balance_x);

        let delta_l = 111732121;
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
        let (delta_x_amt, delta_y_amt) = mock_dex::calc_deposit_amounts_by_liquidity(
            &pool,
            position.lp_position().tick_a(),
            position.lp_position().tick_b(),
            delta_l,
        );
        mock_dex_integration::rebalance_add_liquidity(
            &mut position,
            &mut config,
            &mut receipt,
            &price_info,
            &debt_info,
            &mut pool,
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
        core::rebalance_repay_debt_x(
            &mut position,
            &mut repay_debt_x_balance,
            &mut receipt,
            &mut supply_pool_x,
            &clock,
        );
        core::rebalance_repay_debt_y(
            &mut position,
            &mut repay_debt_y_balance,
            &mut receipt,
            &mut supply_pool_y,
            &clock,
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
        assert!(
            position.debt_bag().fdb_get_share_amount_by_asset_type<SUI>() == (56352403581 - 50000) * (1u128 << 64),
        );
        assert!(
            position.debt_bag().fdb_get_share_amount_by_asset_type<USDC>() == (465614178 - 60000) * (1u128 << 64),
        );

        // check all receipt fields once more
        assert!(receipt.position_id() == object::id(&position));
        assert!(receipt.collected_amm_fee_x() == 0_150000000);
        assert!(receipt.collected_amm_fee_y() == 1_100000);
        assert!(receipt.collected_amm_rewards()[&type_name::with_defining_ids<SUI>()] == 0_200000000);
        assert!(
            receipt.fees_taken()[&type_name::with_defining_ids<SUI>()] == exp_rebalance_fee_x + exp_reward_sui,
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
    };

    // collect protocol fees
    scenario.next_tx(@0);
    {
        let mut position = scenario.take_shared<Position<SUI, USDC, PositionKey>>();

        let (sui_balance, request) = core::collect_protocol_fees<_, _, SUI, _>(
            &mut position,
            option::none(),
            scenario.ctx(),
        );
        request.admin_approve_request(&package_admin);
        let (usdc_balance, request) = core::collect_protocol_fees<_, _, USDC, _>(
            &mut position,
            option::none(),
            scenario.ctx(),
        );
        request.admin_approve_request(&package_admin);

        assert!(sui_balance.value() == 1_000000000 + 1500000 + 2000000);
        assert!(usdc_balance.value() == 11000);
        assert!(position.collected_fees().amounts().length() == 0);

        destroy(sui_balance);
        destroy(usdc_balance);

        test_scenario::return_shared(position);
    };

    // owner repay a portion of the debt
    scenario.next_tx(@0);
    {
        let mut position = scenario.take_shared<Position<SUI, USDC, PositionKey>>();

        let mut repay_debt_x_balance = balance::create_for_testing(10000);
        let mut repay_debt_y_balance = balance::create_for_testing(20000);
        core::repay_debt_x(
            &mut position,
            &position_cap,
            &mut repay_debt_x_balance,
            &mut supply_pool_x,
            &clock,
        );
        core::repay_debt_y(
            &mut position,
            &position_cap,
            &mut repay_debt_y_balance,
            &mut supply_pool_y,
            &clock,
        );
        repay_debt_x_balance.destroy_zero();
        repay_debt_y_balance.destroy_zero();
        assert!(position.debt_bag().length() == 2);
        assert!(
            position.debt_bag().fdb_get_share_amount_by_asset_type<SUI>() == (56352403581 - 50000 - 10000) * (1u128 << 64),
        );
        assert!(
            position.debt_bag().fdb_get_share_amount_by_asset_type<USDC>() == (465614178 - 60000 - 20000) * (1u128 << 64),
        );

        test_scenario::return_shared(position);
    };

    // add collateral
    scenario.next_tx(@0);
    {
        let mut position = scenario.take_shared<Position<SUI, USDC, PositionKey>>();

        let cx_balance = balance::create_for_testing(30000);
        let cy_balance = balance::create_for_testing(40000);
        core::add_collateral_x(
            &mut position,
            &position_cap,
            cx_balance,
        );
        core::add_collateral_y(
            &mut position,
            &position_cap,
            cy_balance,
        );
        assert!(position.col_x().value() == 30000);
        assert!(position.col_y().value() == 40000);

        test_scenario::return_shared(position);
    };

    // make position go out of range by doing a swap
    scenario.next_tx(@0);
    {
        let position = scenario.take_shared<Position<SUI, USDC, PositionKey>>();

        // get amount of x to swap in to get the position just out of range
        let (tick_a, _) = position.lp_position().tick_range();
        let amount_x_in = mock_dex_math::get_delta_a(
            pool.current_sqrt_price_x64(),
            mock_dex_math::get_sqrt_price_at_tick(tick_a),
            pool.active_liquidity(),
            true,
        );
        let balance_y = mock_dex::swap_x_in(&mut pool, balance::create_for_testing(amount_x_in));
        destroy(balance_y);

        // sanity check to make sure the position went just out of range
        let (tick_a, _) = position.lp_position().tick_range();
        assert!(pool.current_sqrt_price_x64() == mock_dex_math::get_sqrt_price_at_tick(tick_a));

        // update pyth price info
        pyth_test_util::update_pyth_pio_price_human_mul_n(
            &mut sui_pio,
            sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(pool.current_sqrt_price_x64(), 8),
            8,
            &clock,
        );

        test_scenario::return_shared(position);
    };

    // forward clock so that interest is accrued and add fees and rewards to position
    scenario.next_tx(@0);
    {
        let position = scenario.take_shared<Position<SUI, USDC, PositionKey>>();

        let new_ts = clock.timestamp_ms() + 10000_000; // +10000 seconds (~2.8 hours)
        clock.set_for_testing(new_ts);

        pyth_test_util::set_pyth_pio_timestamp(&mut sui_pio, new_ts / 1000);
        pyth_test_util::set_pyth_pio_timestamp(&mut usdc_pio, new_ts / 1000);

        pool.add_fees_to_position(
            position.lp_position().idx(),
            balance::create_for_testing(1_000000000),
            balance::create_for_testing(1_000000),
        );
        pool.add_reward_to_position(
            position.lp_position().idx(),
            balance::create_for_testing<SUI>(2_000000000),
        );

        test_scenario::return_shared(position);
    };

    // close position
    scenario.next_tx(@0);
    {
        let mut position: Position<SUI, USDC, PositionKey> = scenario.take_shared();
        let mut config = scenario.take_shared<PositionConfig>();

        let mut price_info = pyth::create(&clock);
        price_info.add(&sui_pio);
        price_info.add(&usdc_pio);

        let (balance_x, balance_y, mut ticket) = mock_dex_integration::reduce(
            &mut position,
            &mut config,
            &position_cap,
            &price_info,
            &mut supply_pool_x,
            &mut supply_pool_y,
            &mut pool,
            1 << 64,
            &clock,
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
            pool.current_tick_index(),
            pool.current_sqrt_price_x64(),
            663723464242,
            false,
        );
        let seconds_in_year = 365 * 24 * 60 * 60;
        let seconds_passed = 10000;
        let interest_pct = 10;
        let initial_dx = 56352343581;
        let initial_dy = 465534178;
        let exp_dx =
            initial_dx + u64::divide_and_round_up(initial_dx * seconds_passed * interest_pct / 100, seconds_in_year);
        let exp_dy =
            initial_dy + u64::divide_and_round_up(initial_dy * seconds_passed * interest_pct / 100, seconds_in_year);
        let exp_oracle_price_x128 =
            ((sqrt_price_x64_to_price_human_mul_n<SUI, USDC>(pool.current_sqrt_price_x64(), 8) as u256) * Q128) / 10_u256.pow(8) / 1000;

        assert!(config.current_global_l() == 0);
        assert!(balance_x.value() == exp_x + exp_cx);
        assert!(balance_y.value() == exp_y + exp_cy);
        assert!(ticket.sx().facil_id() == object::id(config.lend_facil_cap()));
        assert!(ticket.sx().value_x64() == 56352343581 * Q64);
        assert!(ticket.sy().facil_id() == object::id(config.lend_facil_cap()));
        assert!(ticket.sy().value_x64() == 465534178 * Q64);
        assert!(ticket.info().position_id() == object::id(&position));
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
        assert!(info.sqrt_pool_price_x64() == pool.current_sqrt_price_x64());
        assert!(info.delta_l() == 663723464242);
        assert!(info.delta_x() == exp_x);
        assert!(info.delta_y() == exp_y);
        assert!(info.withdrawn_x() == exp_x + exp_cx);
        assert!(info.withdrawn_y() == exp_y + exp_cy);
        assert!(info.x_repaid() == 0);
        assert!(info.y_repaid() == 0);

        // repay ticket
        let repay_amt_x = core::reduction_ticket_calc_repay_amt_x(
            &ticket,
            &mut supply_pool_x,
            &clock,
        );
        let repay_amt_y = core::reduction_ticket_calc_repay_amt_y(
            &ticket,
            &mut supply_pool_y,
            &clock,
        );
        assert!(repay_amt_x == exp_dx);
        assert!(repay_amt_y == exp_dy);
        core::reduction_ticket_repay_x(
            &mut ticket,
            &mut supply_pool_x,
            balance::create_for_testing(repay_amt_x),
            &clock,
        );
        core::reduction_ticket_repay_y(
            &mut ticket,
            &mut supply_pool_y,
            balance::create_for_testing(repay_amt_y),
            &clock,
        );
        assert!(ticket.info().x_repaid() == exp_dx);
        assert!(ticket.info().y_repaid() == exp_dy);
        core::destroy_reduction_ticket(ticket);

        // collect fees and rewards
        let (fee_balance_x, fee_balance_y) = mock_dex_integration::owner_collect_fee(
            &mut position,
            &config,
            &position_cap,
            &mut pool,
        );
        let reward_balance = mock_dex_integration::owner_collect_reward<_, _, SUI>(
            &mut position,
            &config,
            &position_cap,
            &mut pool,
        );
        let reward_stash_balance = core::owner_take_stashed_rewards<_, _, SUI, _>(
            &mut position,
            &position_cap,
            option::none(),
        );
        let exp_fee_x = 1_000000000 * 1_00 / 10000;
        let exp_fee_y = 1_000000 * 1_00 / 10000;
        let exp_fee_reward = 2_000000000 * 1_00 / 10000;
        assert!(fee_balance_x.value() == 1_000000000  - exp_fee_x);
        assert!(fee_balance_y.value() == 1_000000 - exp_fee_y);
        assert!(reward_balance.value() == 2_000000000 - exp_fee_reward);
        assert!(reward_stash_balance.value() == 70000);
        destroy(fee_balance_x);
        destroy(fee_balance_y);
        destroy(reward_balance);
        destroy(reward_stash_balance);

        // close position
        mock_dex_integration::delete_position(
            position,
            &config,
            position_cap,
            &mut pool,
            scenario.ctx(),
        );

        test_scenario::return_shared(config);
    };

    // collect deleted position fees
    scenario.next_tx(@0);
    {
        let deleted_position_fees = scenario.take_shared<DeletedPositionCollectedFees>();

        let (
            mut balance_bag,
            request,
        ) = deleted_position_fees.collect_deleted_position_fees(scenario.ctx());
        request.admin_approve_request(&package_admin);

        let sui_balance = balance_bag.take_all<SUI>();
        let usdc_balance = balance_bag.take_all<USDC>();
        balance_bag.destroy_empty();
        assert!(sui_balance.value() == 10000000 + 20000000);
        assert!(usdc_balance.value() == 10000);

        destroy(sui_balance);
        destroy(usdc_balance);
    };

    scenario.end();

    destroy(pool);
    destroy(package_admin);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
    destroy(supply_pool_x);
    destroy(supply_pool_y);
}

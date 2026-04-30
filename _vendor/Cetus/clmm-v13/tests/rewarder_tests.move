#[test_only]
module cetus_clmm::rewarder_tests;

use cetus_clmm::config::{Self, AdminCap, GlobalConfig};
use cetus_clmm::pool::{Self, Pool};
use cetus_clmm::pool_tests::{
    open_position_with_liquidity,
    nt,
    pt,
    remove_liquidity,
    add_liquidity,
    swap
};
use cetus_clmm::position::{Self, Position};
use cetus_clmm::rewarder::{Self, RewarderGlobalVault};
use cetus_clmm::tick;
use cetus_clmm::tick_math::{get_sqrt_price_at_tick, min_sqrt_price, max_sqrt_price};
use integer_mate::i32;
use std::string::utf8;
use std::type_name::{Self, TypeName};
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin;
use sui::test_scenario::{Self, Scenario};
use sui::transfer::public_transfer;

public struct CoinA {}
public struct CoinB {}
public struct CoinC {}
public struct CoinD {}
public struct CoinE {}

fun init_test(
    ctx: &mut TxContext,
): (Clock, AdminCap, GlobalConfig, RewarderGlobalVault, Pool<CoinA, CoinB>) {
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let vault = rewarder::new_vault_for_test(ctx);
    let pool = pool::new_for_test<CoinA, CoinB>(
        5,
        get_sqrt_price_at_tick(i32::from(0)),
        2000,
        utf8(b""),
        0,
        &clock,
        ctx,
    );
    (clock, admin_cap, config, vault, pool)
}

fun close_test(
    clock: Clock,
    cap: AdminCap,
    config: GlobalConfig,
    vault: RewarderGlobalVault,
    pool: Pool<CoinA, CoinB>,
) {
    clock::destroy_for_testing(clock);
    transfer::public_transfer(cap, @0x123);
    transfer::public_share_object(config);
    transfer::public_share_object(vault);
    transfer::public_share_object(pool);
}

#[test]
fun test_initialize_rewarder() {
    let mut ctx = tx_context::dummy();
    let (clock, admin_cap, config, mut vault, mut pool) = init_test(&mut ctx);
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    let rewarder_manager = pool::rewarder_manager(&pool);
    let rewarder = rewarder::borrow_rewarder<CoinC>(rewarder_manager);
    assert!(rewarder::emissions_per_second(rewarder) == 0, 0);
    assert!(rewarder::growth_global(rewarder) == 0, 0);

    deposit_reward<CoinC>(&config, &mut vault, 100000000);
    let balances = vault.balances();
    let a = balances.borrow<TypeName, Balance<CoinC>>(type_name::get<CoinC>());
    assert!(balance::value(a) == 100000000, 0);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 1 << 64, &clock, &ctx);
    let rewarder_manager = pool::rewarder_manager(&pool);
    let rewarder = rewarder::borrow_rewarder<CoinC>(rewarder_manager);
    assert!(rewarder::emissions_per_second(rewarder) == (1 << 64), 0);
    let mut rewarder_index = rewarder::rewarder_index<CoinC>(rewarder_manager);
    assert!(option::extract(&mut rewarder_index) == 0, 0);

    close_test(clock, admin_cap, config, vault, pool);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::rewarder::ERewardAmountInsufficient)]
fun test_update_emission_amount_insufficient() {
    let mut ctx = tx_context::dummy();
    let (clock, admin_cap, config, vault, mut pool) = init_test(&mut ctx);

    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 1 << 64, &clock, &ctx);
    close_test(clock, admin_cap, config, vault, pool);
}

fun initialize_pool_with_rewarder(): Scenario {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (clock, admin_cap, config, mut vault, mut pool) = init_test(ctx);
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, ctx);

    deposit_reward<CoinC>(&config, &mut vault, 100000000);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 1 << 64, &clock, ctx);
    transfer::public_share_object(pool);
    transfer::public_share_object(vault);
    transfer::public_share_object(config);
    transfer::public_transfer(admin_cap, ctx.sender());
    clock::destroy_for_testing(clock);
    scenerio.next_tx(@0x1234);
    scenerio
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun collect_reward_not_permited() {
    let mut scenario = initialize_pool_with_rewarder();
    let config = test_scenario::take_shared<GlobalConfig>(&scenario);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenario);
    let mut clock = clock::create_for_testing(scenario.ctx());
    let mut vault = test_scenario::take_shared<RewarderGlobalVault>(&scenario);
    let position = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        scenario.ctx(),
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    pool::set_pool_status(
        &config,
        &mut pool,
        false,
        false,
        false,
        false,
        false,
        true,
        scenario.ctx(),
    );
    let reward_balance = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position,
        &mut vault,
        true,
        &clock,
    );
    reward_balance.destroy_for_testing();
    clock::destroy_for_testing(clock);
    transfer::public_share_object(pool);
    transfer::public_share_object(vault);
    transfer::public_share_object(config);
    transfer::public_transfer(position, scenario.ctx().sender());
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolPositionNotMatch)]
fun collect_reward_pool_position_not_match() {
    let mut scenario = initialize_pool_with_rewarder();
    let config = test_scenario::take_shared<GlobalConfig>(&scenario);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenario);
    let mut clock = clock::create_for_testing(scenario.ctx());
    let mut vault = test_scenario::take_shared<RewarderGlobalVault>(&scenario);
    let position = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        scenario.ctx(),
    );
    let mut pool_2 = pool::new_for_test<CoinA, CoinB>(
        5,
        get_sqrt_price_at_tick(i32::from(0)),
        2000,
        utf8(b""),
        0,
        &clock,
        scenario.ctx(),
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool_2,
        &position,
        &mut vault,
        true,
        &clock,
    );
    reward_balance.destroy_for_testing();
    clock::destroy_for_testing(clock);
    transfer::public_share_object(pool);
    transfer::public_share_object(pool_2);
    transfer::public_share_object(vault);
    transfer::public_share_object(config);
    transfer::public_transfer(position, scenario.ctx().sender());
    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::ERewardNotExist)]
fun collect_reward_not_exist() {
    let mut scenario = initialize_pool_with_rewarder();
    let config = test_scenario::take_shared<GlobalConfig>(&scenario);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenario);
    let mut clock = clock::create_for_testing(scenario.ctx());
    let mut vault = test_scenario::take_shared<RewarderGlobalVault>(&scenario);
    let position = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        scenario.ctx(),
    );

    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance = pool::collect_reward<CoinA, CoinB, CoinD>(
        &config,
        &mut pool,
        &position,
        &mut vault,
        true,
        &clock,
    );
    reward_balance.destroy_for_testing();
    clock::destroy_for_testing(clock);
    transfer::public_share_object(pool);
    transfer::public_share_object(vault);
    transfer::public_share_object(config);
    transfer::public_transfer(position, scenario.ctx().sender());
    test_scenario::end(scenario);
}

#[test]
fun calculate_and_update_reward() {
    let mut scenario = initialize_pool_with_rewarder();
    let config = test_scenario::take_shared<GlobalConfig>(&scenario);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenario);
    let mut clock = clock::create_for_testing(scenario.ctx());
    let mut vault = test_scenario::take_shared<RewarderGlobalVault>(&scenario);
    let mut position = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        scenario.ctx(),
    );

    clock::increment_for_testing(&mut clock, 6000 * 1000);

    scenario.next_tx(@0x1234);

    let liquidity = position::liquidity(&position);
    let (balance_a, balance_b) = pool::remove_liquidity(
        &config,
        &mut pool,
        &mut position,
        liquidity,
        &clock,
    );
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();

    pool::calculate_and_update_rewards(&config, &mut pool, object::id(&position), &clock);
    let balance_r = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position,
        &mut vault,
        false,
        &clock,
    );
    balance_r.destroy_for_testing();

    clock::destroy_for_testing(clock);
    transfer::public_share_object(pool);
    transfer::public_share_object(vault);
    transfer::public_share_object(config);
    transfer::public_transfer(position, scenario.ctx().sender());
    test_scenario::end(scenario);
}

#[test]
fun test_collect_reward_and_points() {
    let mut ctx = tx_context::dummy();
    let (mut clock, admin_cap, config, mut vault, mut pool) = init_test(&mut ctx);
    deposit_reward<CoinC>(&config, &mut vault, 100000000);
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 1 << 64, &clock, &ctx);

    let mut position_1 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        &mut ctx,
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    assert!(balance::value(&reward_balance) == 5999, 0);
    balance::destroy_for_testing(reward_balance);
    let points = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    assert!(points == 6000 * 1000000, 0);

    let position_2 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        &mut ctx,
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    let reward_balance_2 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    let points_1 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let points_2 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    assert!(points_1 == 9000 * 1000000, 0);
    assert!(points_2 == 3000 * 1000000, 0);
    balance::destroy_for_testing(reward_balance_1);
    balance::destroy_for_testing(reward_balance_2);
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 2 << 64, &clock, &ctx);
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let need_reward_1 = pool::calculate_and_update_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    assert!(
        need_reward_1 == pool::get_position_reward<CoinA, CoinB, CoinC>(&pool, object::id(&position_1)),
        0,
    );
    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    let need_reward_2 = pool::calculate_and_update_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    assert!(
        need_reward_1 == pool::get_position_reward<CoinA, CoinB, CoinC>(&pool, object::id(&position_2)),
        0,
    );
    let reward_balance_2 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    assert!(balance::value(&reward_balance_1) == need_reward_1, 0);
    assert!(balance::value(&reward_balance_2) == need_reward_2, 0);
    assert!(balance::value(&reward_balance_1) == 8999, 0);
    assert!(balance::value(&reward_balance_2) == 8999, 0);
    let points_1 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let points_2 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    assert!(points_1 == pool::get_position_points(&pool, object::id(&position_1)), 0);
    assert!(points_2 == pool::get_position_points(&pool, object::id(&position_2)), 0);
    assert!(points_1 == 15000 * 1000000, 0);
    assert!(points_2 == 9000 * 1000000, 0);
    balance::destroy_for_testing(reward_balance_1);
    balance::destroy_for_testing(reward_balance_2);

    let liquidity = position::liquidity(&position_1);
    remove_liquidity(
        &config,
        &mut pool,
        &mut position_1,
        liquidity,
        &clock,
        &mut ctx,
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let need_reward_1 = pool::calculate_and_update_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    assert!(
        need_reward_1 == pool::get_position_reward<CoinA, CoinB, CoinC>(&pool, object::id(&position_1)),
        0,
    );
    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    let new_points_1 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    assert!(new_points_1 == points_1, 0);
    assert!(points_1 == pool::get_position_points(&pool, object::id(&position_1)), 0);
    assert!(need_reward_1 == 0, 0);
    assert!(balance::value(&reward_balance_1) == 0, 0);
    balance::destroy_zero(reward_balance_1);

    public_transfer(position_1, @0x12345);
    public_transfer(position_2, @0x12345);

    close_test(clock, admin_cap, config, vault, pool);
}

#[test]
fun test_collect_reward_and_points_position_open_with_full_range() {
    let mut ctx = tx_context::dummy();
    let (mut clock, admin_cap, config, mut vault, mut pool) = init_test(&mut ctx);
    deposit_reward<CoinC>(&config, &mut vault, 100000000);
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 1 << 64, &clock, &ctx);
    let (min_tick, max_tick) = (nt(443635), pt(443635));

    let mut position_1 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        &mut ctx,
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    assert!(balance::value(&reward_balance) == 5999, 0);
    balance::destroy_for_testing(reward_balance);
    let points = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    assert!(points == 6000 * 1000000, 0);

    let mut position_2 = open_position_with_liquidity(
        &config,
        &mut pool,
        min_tick,
        max_tick,
        1000000,
        &clock,
        &mut ctx,
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    let reward_balance_2 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    let points_1 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let points_2 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    assert!(points_1 == 9000 * 1000000, 0);
    assert!(points_2 == 3000 * 1000000, 0);
    balance::destroy_for_testing(reward_balance_1);
    balance::destroy_for_testing(reward_balance_2);
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 2 << 64, &clock, &ctx);
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let need_reward_1 = pool::calculate_and_update_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    assert!(
        need_reward_1 == pool::get_position_reward<CoinA, CoinB, CoinC>(&pool, object::id(&position_1)),
        0,
    );
    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    let need_reward_2 = pool::calculate_and_update_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    assert!(
        need_reward_1 == pool::get_position_reward<CoinA, CoinB, CoinC>(&pool, object::id(&position_2)),
        0,
    );
    let reward_balance_2 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    assert!(balance::value(&reward_balance_1) == need_reward_1, 0);
    assert!(balance::value(&reward_balance_2) == need_reward_2, 0);
    assert!(balance::value(&reward_balance_1) == 8999, 0);
    assert!(balance::value(&reward_balance_2) == 8999, 0);
    let points_1 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let points_2 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    assert!(points_1 == pool::get_position_points(&pool, object::id(&position_1)), 0);
    assert!(points_2 == pool::get_position_points(&pool, object::id(&position_2)), 0);
    assert!(points_1 == 15000 * 1000000, 0);
    assert!(points_2 == 9000 * 1000000, 0);
    balance::destroy_for_testing(reward_balance_1);
    balance::destroy_for_testing(reward_balance_2);

    let liquidity = position::liquidity(&position_1);
    remove_liquidity(
        &config,
        &mut pool,
        &mut position_1,
        liquidity,
        &clock,
        &mut ctx,
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let need_reward_1 = pool::calculate_and_update_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    assert!(
        need_reward_1 == pool::get_position_reward<CoinA, CoinB, CoinC>(&pool, object::id(&position_1)),
        0,
    );
    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    let new_points_1 = pool::calculate_and_update_points(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    assert!(new_points_1 == points_1, 0);
    assert!(points_1 == pool::get_position_points(&pool, object::id(&position_1)), 0);
    assert!(need_reward_1 == 0, 0);
    assert!(balance::value(&reward_balance_1) == 0, 0);
    balance::destroy_zero(reward_balance_1);

    let liquidity = position::liquidity(&position_2);
    remove_liquidity(
        &config,
        &mut pool,
        &mut position_2,
        liquidity,
        &clock,
        &mut ctx,
    );
    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    assert!(balance::value(&reward_balance_1) == 11999, 0);
    balance::destroy_for_testing(reward_balance_1);

    add_liquidity(
        &config,
        &mut pool,
        &mut position_2,
        liquidity,
        &clock,
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    let reward_balance_2 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    assert!(balance::value(&reward_balance_1) == 0, 0);
    assert!(balance::value(&reward_balance_2) == 11999, 0);
    balance::destroy_for_testing(reward_balance_1);
    balance::destroy_for_testing(reward_balance_2);

    public_transfer(position_1, @0x12345);
    public_transfer(position_2, @0x12345);

    close_test(clock, admin_cap, config, vault, pool);
}

#[test]
fun test_collect_reward_position_open_before_init() {
    let mut ctx = tx_context::dummy();
    let (mut clock, admin_cap, config, mut vault, mut pool) = init_test(&mut ctx);
    deposit_reward<CoinC>(&config, &mut vault, 100000000);
    deposit_reward<CoinD>(&config, &mut vault, 100000000);
    deposit_reward<CoinE>(&config, &mut vault, 100000000);

    let position_1 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        &mut ctx,
    );
    let mut position_2 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(2000),
        pt(2000),
        1000000,
        &clock,
        &mut ctx,
    );
    clock::increment_for_testing(&mut clock, 60000 * 1000);
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 2 << 64, &clock, &ctx);
    clock::increment_for_testing(&mut clock, 60000 * 1000);

    let position_info = pool::borrow_position_info(&pool, object::id(&position_1));
    let tick_upper_1 = pool::borrow_tick(&pool, pt(1000));
    let tick_lower_1 = pool::borrow_tick(&pool, nt(1000));
    let tick_upper_2 = pool::borrow_tick(&pool, pt(2000));
    let tick_lower_2 = pool::borrow_tick(&pool, nt(2000));
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_1)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_1)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_2)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_2)) == 0, 0);
    assert!(vector::length(position::info_rewards(position_info)) == 0, 0);

    let reward_balance_1 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_1,
        &mut vault,
        true,
        &clock,
    );
    let position_info = pool::borrow_position_info(&pool, object::id(&position_1));
    let tick_upper_1 = pool::borrow_tick(&pool, pt(1000));
    let tick_lower_1 = pool::borrow_tick(&pool, nt(1000));
    let tick_upper_2 = pool::borrow_tick(&pool, pt(2000));
    let tick_lower_2 = pool::borrow_tick(&pool, nt(2000));
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_1)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_1)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_2)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_2)) == 0, 0);
    assert!(vector::length(position::info_rewards(position_info)) == 1, 0);
    assert!(balance::value(&reward_balance_1) == 59999, 0);

    // will cross -1000
    swap(
        &mut pool,
        &config,
        true,
        true,
        130000,
        min_sqrt_price(),
        &clock,
        &mut ctx,
    );
    let tick_upper_1 = pool::borrow_tick(&pool, pt(1000));
    let tick_lower_1 = pool::borrow_tick(&pool, nt(1000));
    let tick_upper_2 = pool::borrow_tick(&pool, pt(2000));
    let tick_lower_2 = pool::borrow_tick(&pool, nt(2000));
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_1)) == 1, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_1)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_2)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_2)) == 0, 0);
    let reward_balance_2 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    let position_info = pool::borrow_position_info(&pool, object::id(&position_1));
    let tick_upper_1 = pool::borrow_tick(&pool, pt(1000));
    let tick_lower_1 = pool::borrow_tick(&pool, nt(1000));
    let tick_upper_2 = pool::borrow_tick(&pool, pt(2000));
    let tick_lower_2 = pool::borrow_tick(&pool, nt(2000));
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_1)) == 1, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_1)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_2)) == 0, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_2)) == 0, 0);
    assert!(vector::length(position::info_rewards(position_info)) == 1, 0);
    clock::increment_for_testing(&mut clock, 6000 * 1000);

    let mut position_3 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(3000),
        pt(3000),
        1000000,
        &clock,
        &mut ctx,
    );
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance_3 = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_3,
        &mut vault,
        true,
        &clock,
    );
    let position_info = pool::borrow_position_info(&pool, object::id(&position_1));
    let tick_upper_3 = pool::borrow_tick(&pool, pt(3000));
    let tick_lower_3 = pool::borrow_tick(&pool, nt(3000));
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_3)) == 1, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_3)) == 1, 0);
    assert!(vector::length(position::info_rewards(position_info)) == 1, 0);
    // position-1 had out range
    assert!(balance::value(&reward_balance_3) == 5999, 0);
    balance::destroy_for_testing(reward_balance_1);
    balance::destroy_for_testing(reward_balance_2);
    balance::destroy_for_testing(reward_balance_3);

    pool::initialize_rewarder<CoinA, CoinB, CoinD>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinD>(&config, &mut pool, &vault, 2 << 64, &clock, &ctx);
    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let position_info = pool::borrow_position_info(&pool, object::id(&position_1));
    let tick_upper_3 = pool::borrow_tick(&pool, pt(3000));
    let tick_lower_3 = pool::borrow_tick(&pool, nt(3000));
    assert!(vector::length(tick::rewards_growth_outside(tick_lower_3)) == 1, 0);
    assert!(vector::length(tick::rewards_growth_outside(tick_upper_3)) == 1, 0);
    assert!(vector::length(position::info_rewards(position_info)) == 1, 0);
    let reward_balance = pool::collect_reward<CoinA, CoinB, CoinD>(
        &config,
        &mut pool,
        &position_3,
        &mut vault,
        true,
        &clock,
    );
    add_liquidity(&config, &mut pool, &mut position_3, 1000000, &clock);
    assert!(balance::value(&reward_balance) == 5999, 0);
    balance::destroy_for_testing(reward_balance);

    clock::increment_for_testing(&mut clock, 6000 * 1000);
    let reward_balance = pool::collect_reward<CoinA, CoinB, CoinD>(
        &config,
        &mut pool,
        &position_3,
        &mut vault,
        true,
        &clock,
    );
    assert!(balance::value(&reward_balance) == 7999, 0);
    balance::destroy_for_testing(reward_balance);

    let liquidity = position::liquidity(&position_2);
    remove_liquidity(
        &config,
        &mut pool,
        &mut position_2,
        liquidity,
        &clock,
        &mut ctx,
    );
    let reward_balance_c = pool::collect_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    let reward_balance_d = pool::collect_reward<CoinA, CoinB, CoinD>(
        &config,
        &mut pool,
        &position_2,
        &mut vault,
        true,
        &clock,
    );
    assert!(balance::value(&reward_balance_d) == 9999, 0);
    assert!(balance::value(&reward_balance_c) == 27999, 0);
    balance::destroy_for_testing(reward_balance_c);
    balance::destroy_for_testing(reward_balance_d);

    public_transfer(position_1, @0x12345);
    public_transfer(position_2, @0x12345);
    public_transfer(position_3, @0x12345);
    close_test(clock, admin_cap, config, vault, pool);
}

#[test]
fun test_multi_rewarder_and_swap_cross() {
    let mut ctx = tx_context::dummy();
    let (mut clock, admin_cap, config, mut vault, mut pool) = init_test(&mut ctx);
    deposit_reward<CoinC>(&config, &mut vault, 100000000);
    deposit_reward<CoinD>(&config, &mut vault, 100000000);
    deposit_reward<CoinE>(&config, &mut vault, 100000000);

    let position_1 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        &mut ctx,
    );
    let position_2 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(2000),
        pt(2000),
        1000000,
        &clock,
        &mut ctx,
    );
    let position_3 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(200000),
        pt(200000),
        1000000,
        &clock,
        &mut ctx,
    );
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 1 << 64, &clock, &ctx);

    pool::initialize_rewarder<CoinA, CoinB, CoinD>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinD>(&config, &mut pool, &vault, 2 << 64, &clock, &ctx);

    pool::initialize_rewarder<CoinA, CoinB, CoinE>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinE>(&config, &mut pool, &vault, 3 << 64, &clock, &ctx);

    clock::increment_for_testing(&mut clock, 1000 * 1000);

    // left cross tick -1000
    swap(
        &mut pool,
        &config,
        true,
        true,
        200000,
        min_sqrt_price(),
        &clock,
        &mut ctx,
    );
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[333, 666, 999], 0);
    assert!(rewards_1 == rewards_2, 0);
    assert!(rewards_1 == rewards_3, 0);

    clock::increment_for_testing(&mut clock, 1000 * 1000);
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[333, 666, 999], 0);
    assert!(rewards_2 == vector[832, 1665, 2498], 0);
    assert!(rewards_3 == vector[832, 1665, 2498], 0);

    // left cross tick -2000
    swap(
        &mut pool,
        &config,
        true,
        true,
        500000,
        min_sqrt_price(),
        &clock,
        &mut ctx,
    );
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[333, 666, 999], 0);
    assert!(rewards_2 == vector[832, 1665, 2498], 0);
    assert!(rewards_3 == vector[832, 1665, 2498], 0);

    clock::increment_for_testing(&mut clock, 1000 * 1000);
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[333, 666, 999], 0);
    assert!(rewards_2 == vector[832, 1665, 2498], 0);
    assert!(rewards_3 == vector[1831, 3664, 5497], 0);

    // right cross tick -2000
    swap(
        &mut pool,
        &config,
        false,
        true,
        300000,
        max_sqrt_price(),
        &clock,
        &mut ctx,
    );
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[333, 666, 999], 0);
    assert!(rewards_2 == vector[832, 1665, 2498], 0);
    assert!(rewards_3 == vector[1831, 3664, 5497], 0);

    clock::increment_for_testing(&mut clock, 1000 * 1000);
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[333, 666, 999], 0);
    assert!(rewards_2 == vector[1331, 2664, 3997], 0);
    assert!(rewards_3 == vector[2330, 4663, 6996], 0);

    // right cross tick -1000
    swap(
        &mut pool,
        &config,
        false,
        true,
        200000,
        max_sqrt_price(),
        &clock,
        &mut ctx,
    );
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[333, 666, 999], 0);
    assert!(rewards_2 == vector[1331, 2664, 3997], 0);
    assert!(rewards_3 == vector[2330, 4663, 6996], 0);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[ 666, 1332, 1998  ], 0);
    assert!(rewards_2 == vector[ 1664, 3330, 4996 ], 0);
    assert!(rewards_3 == vector[ 2663, 5329, 7995 ], 0);

    // right cross tick 1000
    swap(
        &mut pool,
        &config,
        false,
        true,
        200000,
        max_sqrt_price(),
        &clock,
        &mut ctx,
    );
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[ 666, 1332, 1998  ], 0);
    assert!(rewards_2 == vector[ 1664, 3330, 4996 ], 0);
    assert!(rewards_3 == vector[ 2663, 5329, 7995 ], 0);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    let rewards_1 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_1),
        &clock,
    );
    let rewards_2 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_2),
        &clock,
    );
    let rewards_3 = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_3),
        &clock,
    );
    assert!(rewards_1 == vector[ 666, 1332, 1998  ], 0);
    assert!(rewards_2 == vector[ 2163, 4329, 6495 ], 0);
    assert!(rewards_3 == vector[ 3162, 6328, 9494 ], 0);

    public_transfer(position_1, @0x12345);
    public_transfer(position_2, @0x12345);
    public_transfer(position_3, @0x12345);
    close_test(clock, admin_cap, config, vault, pool);
}

#[test]
fun test_multi_rewarder_release_total() {
    let mut ctx = tx_context::dummy();
    let (mut clock, admin_cap, config, mut vault, mut pool) = init_test(&mut ctx);
    deposit_reward<CoinC>(&config, &mut vault, 100000000);
    deposit_reward<CoinD>(&config, &mut vault, 100000000);
    deposit_reward<CoinE>(&config, &mut vault, 100000000);
    let mut receipt_c = coin::zero<CoinC>(&mut ctx);
    let mut receipt_d = coin::zero<CoinD>(&mut ctx);
    let mut receipt_e = coin::zero<CoinE>(&mut ctx);
    let mut position_1 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(1000),
        pt(1000),
        1000000,
        &clock,
        &mut ctx,
    );
    let mut position_2 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(2000),
        pt(2000),
        1000000,
        &clock,
        &mut ctx,
    );
    let mut position_3 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(200000),
        pt(200000),
        10000000,
        &clock,
        &mut ctx,
    );
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 1 << 64, &clock, &ctx);
    pool::initialize_rewarder<CoinA, CoinB, CoinD>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinD>(&config, &mut pool, &vault, 2 << 64, &clock, &ctx);
    pool::initialize_rewarder<CoinA, CoinB, CoinE>(&config, &mut pool, &ctx);
    pool::update_emission<CoinA, CoinB, CoinE>(&config, &mut pool, &vault, 3 << 64, &clock, &ctx);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    collect_reward(&config, &mut pool, &position_1, &mut vault, &clock, &mut receipt_c, &mut ctx);
    collect_reward(&config, &mut pool, &position_1, &mut vault, &clock, &mut receipt_d, &mut ctx);
    collect_reward(&config, &mut pool, &position_1, &mut vault, &clock, &mut receipt_e, &mut ctx);
    collect_reward(&config, &mut pool, &position_2, &mut vault, &clock, &mut receipt_c, &mut ctx);
    collect_reward(&config, &mut pool, &position_3, &mut vault, &clock, &mut receipt_c, &mut ctx);
    let position_4 = open_position_with_liquidity(
        &config,
        &mut pool,
        nt(300000),
        pt(300000),
        80000000,
        &clock,
        &mut ctx,
    );
    swap(&mut pool, &config, false, true, 200000, max_sqrt_price(), &clock, &mut ctx);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    remove_liquidity(&config, &mut pool, &mut position_1, 500000, &clock, &mut ctx);
    swap(&mut pool, &config, false, true, 200000, max_sqrt_price(), &clock, &mut ctx);
    collect_reward(&config, &mut pool, &position_1, &mut vault, &clock, &mut receipt_e, &mut ctx);
    collect_reward(&config, &mut pool, &position_2, &mut vault, &clock, &mut receipt_d, &mut ctx);
    collect_reward(&config, &mut pool, &position_3, &mut vault, &clock, &mut receipt_c, &mut ctx);
    collect_reward(&config, &mut pool, &position_4, &mut vault, &clock, &mut receipt_c, &mut ctx);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    remove_liquidity(&config, &mut pool, &mut position_2, 300000, &clock, &mut ctx);
    add_liquidity(&config, &mut pool, &mut position_1, 1000000, &clock);
    clock::increment_for_testing(&mut clock, 2000 * 1000);
    collect_reward(&config, &mut pool, &position_2, &mut vault, &clock, &mut receipt_d, &mut ctx);
    swap(&mut pool, &config, true, true, 300000, min_sqrt_price(), &clock, &mut ctx);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    collect_reward(&config, &mut pool, &position_3, &mut vault, &clock, &mut receipt_e, &mut ctx);
    clock::increment_for_testing(&mut clock, 3000 * 1000);
    add_liquidity(&config, &mut pool, &mut position_3, 2000000, &clock);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    collect_reward(&config, &mut pool, &position_2, &mut vault, &clock, &mut receipt_c, &mut ctx);
    collect_reward(&config, &mut pool, &position_3, &mut vault, &clock, &mut receipt_d, &mut ctx);
    collect_reward(&config, &mut pool, &position_4, &mut vault, &clock, &mut receipt_e, &mut ctx);
    remove_liquidity(&config, &mut pool, &mut position_3, 800000, &clock, &mut ctx);
    collect_reward(&config, &mut pool, &position_3, &mut vault, &clock, &mut receipt_c, &mut ctx);
    swap(&mut pool, &config, true, true, 30000000, min_sqrt_price(), &clock, &mut ctx);
    add_liquidity(&config, &mut pool, &mut position_2, 2000000, &clock);
    swap(&mut pool, &config, true, true, 300000, min_sqrt_price(), &clock, &mut ctx);
    collect_reward(&config, &mut pool, &position_2, &mut vault, &clock, &mut receipt_c, &mut ctx);
    swap(&mut pool, &config, false, true, 200000, max_sqrt_price(), &clock, &mut ctx);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    swap(&mut pool, &config, false, true, 200000, max_sqrt_price(), &clock, &mut ctx);
    swap(&mut pool, &config, true, true, 30000000, min_sqrt_price(), &clock, &mut ctx);
    clock::increment_for_testing(&mut clock, 1000 * 1000);
    swap(&mut pool, &config, true, false, 20000000, min_sqrt_price(), &clock, &mut ctx);

    collect_reward(&config, &mut pool, &position_1, &mut vault, &clock, &mut receipt_c, &mut ctx);
    collect_reward(&config, &mut pool, &position_2, &mut vault, &clock, &mut receipt_c, &mut ctx);
    collect_reward(&config, &mut pool, &position_3, &mut vault, &clock, &mut receipt_c, &mut ctx);
    collect_reward(&config, &mut pool, &position_4, &mut vault, &clock, &mut receipt_c, &mut ctx);

    collect_reward(&config, &mut pool, &position_1, &mut vault, &clock, &mut receipt_d, &mut ctx);
    collect_reward(&config, &mut pool, &position_2, &mut vault, &clock, &mut receipt_d, &mut ctx);
    collect_reward(&config, &mut pool, &position_3, &mut vault, &clock, &mut receipt_d, &mut ctx);
    collect_reward(&config, &mut pool, &position_4, &mut vault, &clock, &mut receipt_d, &mut ctx);

    collect_reward(&config, &mut pool, &position_1, &mut vault, &clock, &mut receipt_e, &mut ctx);
    collect_reward(&config, &mut pool, &position_2, &mut vault, &clock, &mut receipt_e, &mut ctx);
    collect_reward(&config, &mut pool, &position_3, &mut vault, &clock, &mut receipt_e, &mut ctx);
    collect_reward(&config, &mut pool, &position_4, &mut vault, &clock, &mut receipt_e, &mut ctx);

    assert!(coin::value(&receipt_c) + rewarder::balance_of<CoinC>(&vault) == 100000000, 0);
    assert!(coin::value(&receipt_d) + rewarder::balance_of<CoinD>(&vault) == 100000000, 0);
    assert!(coin::value(&receipt_e) + rewarder::balance_of<CoinE>(&vault) == 100000000, 0);
    public_transfer(position_1, @0x12345);
    public_transfer(position_2, @0x12345);
    public_transfer(position_3, @0x12345);
    public_transfer(position_4, @0x12345);
    public_transfer(receipt_c, @0x12345);
    public_transfer(receipt_d, @0x12345);
    public_transfer(receipt_e, @0x12345);

    close_test(clock, admin_cap, config, vault, pool);
}

fun deposit_reward<CoinType>(config: &GlobalConfig, vault: &mut RewarderGlobalVault, amount: u64) {
    let balance = balance::create_for_testing<CoinType>(amount);
    let before_balance = rewarder::balance_of<CoinType>(vault);
    rewarder::deposit_reward(config, vault, balance);
    let afeter_balance = rewarder::balance_of<CoinType>(vault);
    assert!((afeter_balance - before_balance) == amount, 0);
}

#[allow(unused_function)]
fun emerge_withdraw<CoinType>(
    cap: &AdminCap,
    config: &GlobalConfig,
    vault: &mut RewarderGlobalVault,
    amount: u64,
) {
    let before_balance = rewarder::balance_of<CoinType>(vault);
    let balance = rewarder::emergent_withdraw<CoinType>(cap, config, vault, amount);
    let afeter_balance = rewarder::balance_of<CoinType>(vault);
    assert!((before_balance - afeter_balance) == amount, 0);
    assert!(balance::value(&balance) == amount, 0);
    balance::destroy_for_testing(balance);
}

fun collect_reward<CoinTypeA, CoinTypeB, CoinTypeR>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position: &Position,
    vault: &mut RewarderGlobalVault,
    clock: &Clock,
    receipt_coin: &mut coin::Coin<CoinTypeR>,
    ctx: &mut TxContext,
) {
    let reward = pool::collect_reward<CoinTypeA, CoinTypeB, CoinTypeR>(
        config,
        pool,
        position,
        vault,
        true,
        clock,
    );
    coin::join(receipt_coin, coin::from_balance(reward, ctx));
}

#[test_only]
module cetus_clmm::swap_cases;

use cetus_clmm::config::{Self, GlobalConfig};
use cetus_clmm::pool::{Self, add_liquidity_fix_coin, Pool};
use cetus_clmm::pool_tests;
use cetus_clmm::tick_math::get_sqrt_price_at_tick;
use integer_mate::i32;
use std::string;
use std::unit_test::assert_eq;
use sui::balance;
use sui::clock;
use sui::test_scenario;

public struct CETUS has drop {}
public struct USDC has drop {}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolCurrentTickIndexOutOfRange)]
fun test_swap_to_min_tick() {
    let mut sc = test_scenario::begin(@0x52);
    let ctx = test_scenario::ctx(&mut sc);
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CETUS, USDC>(
        2,
        get_sqrt_price_at_tick(i32::from(46151)),
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let mut pos = pool::open_position(
        &config,
        &mut pool,
        i32::neg_from(443636).as_u32(),
        i32::from(443636).as_u32(),
        ctx,
    );
    let receipt = add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut pos,
        1000000,
        true,
        &clock,
    );
    let (pay_a, pay_b) = receipt.add_liquidity_pay_amount();
    std::debug::print(&pay_a);
    std::debug::print(&pay_b);
    let balance_a = balance::create_for_testing<CETUS>(pay_a);
    let balance_b = balance::create_for_testing<USDC>(pay_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    transfer::public_transfer(admin_cap, @0x52);
    transfer::public_share_object(pool);
    transfer::public_share_object(config);
    transfer::public_transfer(pos, @0x52);
    sc.next_tx(@0x52);
    let config = test_scenario::take_shared<GlobalConfig>(&sc);
    let mut pool = test_scenario::take_shared<Pool<CETUS, USDC>>(&sc);
    std::debug::print(&pool.current_tick_index());
    std::debug::print(&pool.liquidity());
    let (s_a, s_b, receipt) = pool::flash_swap(
        &config,
        &mut pool,
        true,
        true,
        18446744073709551614,
        // get_sqrt_price_at_tick(i32::neg_from(443636)),
        4295048016,
        &clock,
    );
    s_a.destroy_for_testing();
    let pay_amount = receipt.swap_pay_amount();
    std::debug::print(&pay_amount);
    std::debug::print(&s_b.value());
    s_b.destroy_for_testing();
    std::debug::print(&pool.current_tick_index());
    assert_eq!(pool.current_tick_index(), i32::neg_from(443637));
    let balance_a = balance::create_for_testing<CETUS>(pay_amount);
    let balance_b = balance::zero();
    pool::repay_flash_swap(&config, &mut pool, balance_a, balance_b, receipt);

    pool_tests::swap(
        &mut pool,
        &config,
        false,
        true,
        1000000,
        79226673515401279992447579055,
        &clock,
        sc.ctx(),
    );
    // std::debug::print(&pool.current_tick_index());

    test_scenario::return_shared(config);
    test_scenario::return_shared(pool);
    clock.destroy_for_testing();
    sc.end();
}


#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolCurrentTickIndexOutOfRange)]
fun test_swap_to_max_tick() {
    let mut sc = test_scenario::begin(@0x52);
    let ctx = test_scenario::ctx(&mut sc);
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CETUS, USDC>(
        2,
        get_sqrt_price_at_tick(i32::from(46151)),
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let mut pos = pool::open_position(
        &config,
        &mut pool,
        i32::neg_from(443636).as_u32(),
        i32::from(443636).as_u32(),
        ctx,
    );
    let receipt = add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut pos,
        1000000,
        true,
        &clock,
    );
    let (pay_a, pay_b) = receipt.add_liquidity_pay_amount();
    let balance_a = balance::create_for_testing<CETUS>(pay_a);
    let balance_b = balance::create_for_testing<USDC>(pay_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    transfer::public_transfer(admin_cap, @0x52);
    transfer::public_share_object(pool);
    transfer::public_share_object(config);
    transfer::public_transfer(pos, @0x52);
    sc.next_tx(@0x52);
    let config = test_scenario::take_shared<GlobalConfig>(&sc);
    let mut pool = test_scenario::take_shared<Pool<CETUS, USDC>>(&sc);
    std::debug::print(&pool.current_tick_index());
    let (s_a, s_b, receipt) = pool::flash_swap(
        &config,
        &mut pool,
        false,
        true,
        18446744073709551614,
        79226673515401279992447579055,
        &clock,
    );
    s_a.destroy_for_testing();
    let pay_amount = receipt.swap_pay_amount();
    s_b.destroy_for_testing();
    std::debug::print(&pool.current_tick_index());
    assert_eq!(pool.current_tick_index(), i32::from(443636));
    let balance_b = balance::create_for_testing<USDC>(pay_amount);
    let balance_a = balance::zero();
    pool::repay_flash_swap(&config, &mut pool, balance_a, balance_b, receipt);

    test_scenario::return_shared(config);
    test_scenario::return_shared(pool);
    clock.destroy_for_testing();
    sc.end();
}

#[test]
fun swap_cross_tick_when_tick_spacing_is_1() {
    let mut sc = test_scenario::begin(@0x52);
    let ctx = test_scenario::ctx(&mut sc);
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CETUS, USDC>(
        1,
        get_sqrt_price_at_tick(i32::from(0)),
        0,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let mut pos = pool::open_position(
        &config,
        &mut pool,
        i32::neg_from(10).as_u32(),
        i32::from(0).as_u32(),
        ctx,
    );
    let receipt = add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut pos,
        1000000,
        false,
        &clock,
    );
    let (pay_a, pay_b) = receipt.add_liquidity_pay_amount();
    std::debug::print(&pay_a);
    std::debug::print(&pay_b);
    let balance_a = balance::create_for_testing<CETUS>(pay_a);
    let balance_b = balance::create_for_testing<USDC>(pay_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    let mut pos2 = pool::open_position(
        &config,
        &mut pool,
        i32::neg_from(20).as_u32(),
        i32::neg_from(11).as_u32(),
        ctx,
    );
    let receipt = add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut pos2,
        1000000,
        false,
        &clock,
    );
    let (pay_a, pay_b) = receipt.add_liquidity_pay_amount();
    std::debug::print(&pay_a);
    std::debug::print(&pay_b);
    let balance_a = balance::create_for_testing<CETUS>(pay_a);
    let balance_b = balance::create_for_testing<USDC>(pay_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    transfer::public_transfer(admin_cap, @0x52);
    transfer::public_share_object(pool);
    transfer::public_share_object(config);
    transfer::public_transfer(pos, @0x52);
    transfer::public_transfer(pos2, @0x52);
    sc.next_tx(@0x52);
    let config = test_scenario::take_shared<GlobalConfig>(&sc);
    let mut pool = test_scenario::take_shared<Pool<CETUS, USDC>>(&sc);
    // std::debug::print(&pool.current_tick_index());
    // std::debug::print(&pool.liquidity());
    let (s_a, s_b, receipt) = pool::flash_swap(
        &config,
        &mut pool,
        true,
        true,
        1000502,
        get_sqrt_price_at_tick(i32::neg_from(10)),
        // 4295048016,
        &clock,
    );
    std::debug::print(&999999999999110);
    std::debug::print(&s_b.value());
    // std::debug::print(&s_a.value());
    std::debug::print(&pool.current_tick_index());
    s_a.destroy_for_testing();
    s_b.destroy_for_testing();

    let pay_amount = receipt.swap_pay_amount();
    std::debug::print(&pay_amount);
    let balance_a = balance::create_for_testing<CETUS>(pay_amount);
    let balance_b = balance::zero();
    pool::repay_flash_swap(&config, &mut pool, balance_a, balance_b, receipt);
    assert_eq!(pool.current_tick_index(), i32::neg_from(11));
    std::debug::print(&999999999999110);
    pool_tests::swap(
        &mut pool,
        &config,
        true,
        true,
        100000,
        4295048016,
        &clock,
        sc.ctx(),
    );
    // std::debug::print(&pool.current_tick_index());

    test_scenario::return_shared(config);
    test_scenario::return_shared(pool);
    clock.destroy_for_testing();
    sc.end();
}


#[test]
fun swap_cross_tick_when_tick_spacing_is_1_case_2() {
    let mut sc = test_scenario::begin(@0x52);
    let ctx = test_scenario::ctx(&mut sc);
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CETUS, USDC>(
        1,
        get_sqrt_price_at_tick(i32::from(0)),
        0,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let mut pos = pool::open_position(
        &config,
        &mut pool,
        i32::neg_from(10).as_u32(),
        i32::from(0).as_u32(),
        ctx,
    );
    let receipt = add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut pos,
        1000000,
        false,
        &clock,
    );
    let (pay_a, pay_b) = receipt.add_liquidity_pay_amount();
    std::debug::print(&pay_a);
    std::debug::print(&pay_b);
    let balance_a = balance::create_for_testing<CETUS>(pay_a);
    let balance_b = balance::create_for_testing<USDC>(pay_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    let mut pos2 = pool::open_position(
        &config,
        &mut pool,
        i32::neg_from(20).as_u32(),
        i32::neg_from(10).as_u32(),
        ctx,
    );
    let receipt = add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut pos2,
        1000000,
        false,
        &clock,
    );
    let (pay_a, pay_b) = receipt.add_liquidity_pay_amount();
    std::debug::print(&pay_a);
    std::debug::print(&pay_b);
    let balance_a = balance::create_for_testing<CETUS>(pay_a);
    let balance_b = balance::create_for_testing<USDC>(pay_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    transfer::public_transfer(admin_cap, @0x52);
    transfer::public_share_object(pool);
    transfer::public_share_object(config);
    transfer::public_transfer(pos, @0x52);
    transfer::public_transfer(pos2, @0x52);
    sc.next_tx(@0x52);
    let config = test_scenario::take_shared<GlobalConfig>(&sc);
    let mut pool = test_scenario::take_shared<Pool<CETUS, USDC>>(&sc);
    // std::debug::print(&pool.current_tick_index());
    // std::debug::print(&pool.liquidity());
    let (s_a, s_b, receipt) = pool::flash_swap(
        &config,
        &mut pool,
        true,
        true,
        1000502,
        get_sqrt_price_at_tick(i32::neg_from(10)),
        // 4295048016,
        &clock,
    );
    s_a.destroy_for_testing();
    s_b.destroy_for_testing();

    let pay_amount = receipt.swap_pay_amount();
    std::debug::print(&pay_amount);
    let balance_a = balance::create_for_testing<CETUS>(pay_amount);
    let balance_b = balance::zero();
    pool::repay_flash_swap(&config, &mut pool, balance_a, balance_b, receipt);
    assert_eq!(pool.current_tick_index(), i32::neg_from(11));
    std::debug::print(&999999999999110);
    pool_tests::swap(
        &mut pool,
        &config,
        true,
        true,
        400000,
        4295048016,
        &clock,
        sc.ctx(),
    );
    std::debug::print(&pool.current_tick_index());

    test_scenario::return_shared(config);
    test_scenario::return_shared(pool);
    clock.destroy_for_testing();
    sc.end();
}


#[test]
fun swap_cross_tick_when_tick_spacing_is_1_b2a() {
    let mut sc = test_scenario::begin(@0x52);
    let ctx = test_scenario::ctx(&mut sc);
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CETUS, USDC>(
        1,
        get_sqrt_price_at_tick(i32::from(0)),
        0,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let mut pos = pool::open_position(
        &config,
        &mut pool,
        i32::neg_from(10).as_u32(),
        i32::from(0).as_u32(),
        ctx,
    );
    let receipt = add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut pos,
        1000000,
        false,
        &clock,
    );
    let (pay_a, pay_b) = receipt.add_liquidity_pay_amount();
    std::debug::print(&pay_a);
    std::debug::print(&pay_b);
    let balance_a = balance::create_for_testing<CETUS>(pay_a);
    let balance_b = balance::create_for_testing<USDC>(pay_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    let mut pos2 = pool::open_position(
        &config,
        &mut pool,
        i32::neg_from(20).as_u32(),
        i32::neg_from(11).as_u32(),
        ctx,
    );
    let receipt = add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut pos2,
        1000000,
        false,
        &clock,
    );
    let (pay_a, pay_b) = receipt.add_liquidity_pay_amount();
    std::debug::print(&pay_a);
    std::debug::print(&pay_b);
    let balance_a = balance::create_for_testing<CETUS>(pay_a);
    let balance_b = balance::create_for_testing<USDC>(pay_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    transfer::public_transfer(admin_cap, @0x52);
    transfer::public_share_object(pool);
    transfer::public_share_object(config);
    transfer::public_transfer(pos, @0x52);
    transfer::public_transfer(pos2, @0x52);
    sc.next_tx(@0x52);
    let config = test_scenario::take_shared<GlobalConfig>(&sc);
    let mut pool = test_scenario::take_shared<Pool<CETUS, USDC>>(&sc);
    // std::debug::print(&pool.current_tick_index());
    // std::debug::print(&pool.liquidity());
    let (s_a, s_b, receipt) = pool::flash_swap(
        &config,
        &mut pool,
        true,
        true,
        1000502,
        get_sqrt_price_at_tick(i32::neg_from(10)),
        // 4295048016,
        &clock,
    );
    std::debug::print(&999999999999110);
    std::debug::print(&s_b.value());
    // std::debug::print(&s_a.value());
    std::debug::print(&pool.current_tick_index());
    s_a.destroy_for_testing();
    s_b.destroy_for_testing();

    let pay_amount = receipt.swap_pay_amount();
    std::debug::print(&pay_amount);
    let balance_a = balance::create_for_testing<CETUS>(pay_amount);
    let balance_b = balance::zero();
    pool::repay_flash_swap(&config, &mut pool, balance_a, balance_b, receipt);
    assert_eq!(pool.current_tick_index(), i32::neg_from(11));
    std::debug::print(&999999999999110);
    pool_tests::swap(
        &mut pool,
        &config,
        false,
        true,
        400000,
        get_sqrt_price_at_tick(i32::from(10)),
        &clock,
        sc.ctx(),
    );
    std::debug::print(&pool.current_tick_index());

    test_scenario::return_shared(config);
    test_scenario::return_shared(pool);
    clock.destroy_for_testing();
    sc.end();
}

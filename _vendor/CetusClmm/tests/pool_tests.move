#[test_only]
module cetus_clmm::pool_tests;

use cetus_clmm::clmm_math;
use cetus_clmm::config::{Self, GlobalConfig, AdminCap, new_global_config_for_test};
use cetus_clmm::partner::{Self, Partner};
use cetus_clmm::pool::{
    Self,
    Pool,
    flash_swap,
    repay_flash_swap,
    swap_pay_amount,
    flash_swap_with_partner,
    repay_flash_swap_with_partner,
    ref_fee_amount,
    liquidity,
    current_tick_index,
    current_sqrt_price,
    ProtocolFeeCollectCap
};
use cetus_clmm::position::{Self, Position};
use cetus_clmm::rewarder;
use cetus_clmm::tick;
use cetus_clmm::tick_math::{min_sqrt_price, max_sqrt_price, get_sqrt_price_at_tick};
use integer_mate::full_math_u64;
use integer_mate::i128;
use integer_mate::i32::{Self, I32};
use std::string::{Self, String};
use std::type_name;
use std::unit_test::assert_eq;
use sui::bag;
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin;
use sui::test_scenario;

const PROTOCOL_FEE_DENOMINATOR: u64 = 10000;
const TEST_ADDR: address = @0x12345;

public struct CoinA {}
public struct CoinB {}
public struct CoinC {}
public struct CoinD {}
public struct CoinE {}

public struct LPItem has copy, drop {
    liquidity: u128,
    tick_lower: I32,
    tick_upper: I32,
}

fun lpitem(liquidity: u128, tick_lower: I32, tick_upper: I32): LPItem {
    LPItem {
        liquidity,
        tick_lower,
        tick_upper,
    }
}

public fun pt(v: u32): I32 {
    i32::from(v)
}

public fun nt(v: u32): I32 {
    i32::neg_from(v)
}

fun init_test(ctx: &mut TxContext): (Clock, AdminCap, GlobalConfig) {
    let (cap, config) = config::new_global_config_for_test(
        ctx,
        2000,
    );
    (clock::create_for_testing(ctx), cap, config)
}

fun close_test(cap: AdminCap, config: GlobalConfig, clock: Clock) {
    transfer::public_transfer(cap, TEST_ADDR);
    transfer::public_share_object(config);
    clock::destroy_for_testing(clock);
}

#[test]
public fun test_new() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let pool = create_pool<CoinA, CoinB>(
        100,
        min_sqrt_price(),
        2000,
        0,
        &clock,
        ctx,
    );
    transfer::public_share_object(pool);
    close_test(admin_cap, config, clock);
}

#[test]
public fun test_open_position() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, mut config) = init_test(ctx);
    config::add_role(&admin_cap, &mut config, TEST_ADDR, 0);

    let mut pool = create_pool<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        0,
        &clock,
        ctx,
    );
    let position_nft = open_position(
        &config,
        &mut pool,
        i32::neg_from(1000),
        i32::from(1000),
        ctx,
    );
    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
public fun test_close_position() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, mut config) = init_test(ctx);
    config::add_role(&admin_cap, &mut config, TEST_ADDR, 0);

    let mut pool = create_pool<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        0,
        &clock,
        ctx,
    );
    let position_nft = open_position(
        &config,
        &mut pool,
        i32::neg_from(1000),
        i32::from(1000),
        ctx,
    );
    pool::close_position(&config, &mut pool, position_nft);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
public fun test_close_position_not_allowed() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, mut config) = init_test(ctx);
    config::add_role(&admin_cap, &mut config, TEST_ADDR, 0);

    let mut pool = create_pool<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        0,
        &clock,
        ctx,
    );
    pool::set_pool_status(&config, &mut pool, false, true, false, false, false, true, ctx);
    let position_nft = open_position(
        &config,
        &mut pool,
        i32::neg_from(1000),
        i32::from(1000),
        ctx,
    );
    pool::close_position(&config, &mut pool, position_nft);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EDeprecatedFunction)]
public fun test_close_position_cannot_close_attacked_position() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, mut config) = init_test(ctx);
    config::add_role(&admin_cap, &mut config, TEST_ADDR, 0);

    let mut pool = create_pool<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        0,
        &clock,
        ctx,
    );
    let position_nft = open_position(
        &config,
        &mut pool,
        i32::neg_from(1000),
        i32::from(1000),
        ctx,
    );
    pool::pause(&config, &mut pool, ctx);
    config::update_package_version(&admin_cap, &mut config, 18446744073709551000);
    pool::init_position_snapshot(&config, &mut pool, 5000, ctx);
    pool::apply_liquidity_cut(&config, &mut pool, object::id(&position_nft), 5000, &clock, ctx);
    config::update_package_version(&admin_cap, &mut config, 1);
    pool::unpause(&config, &mut pool, ctx);
    pool::close_position(&config, &mut pool, position_nft);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolPositionNotMatch)]
public fun test_close_position_pool_position_not_match() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, mut config) = init_test(ctx);
    config::add_role(&admin_cap, &mut config, TEST_ADDR, 0);

    let mut pool = create_pool<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        0,
        &clock,
        ctx,
    );
    let position_nft = open_position(
        &config,
        &mut pool,
        i32::neg_from(1000),
        i32::from(1000),
        ctx,
    );
    let mut pool2 = create_pool<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        0,
        &clock,
        ctx,
    );
    let position_nft2 = open_position(
        &config,
        &mut pool2,
        i32::neg_from(1000),
        i32::from(1000),
        ctx,
    );
    sui::transfer::public_share_object(pool2);
    pool::close_position(&config, &mut pool, position_nft2);
    transfer::public_share_object(pool);
    sui::transfer::public_transfer(position_nft, TEST_ADDR);

    close_test(admin_cap, config, clock);
}

#[test]
public fun test_add_liquidity() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clock);
    add_liquidity_fix_coin(&config, &mut pool, &mut position_nft, 100000, true, &clock);
    add_liquidity(&config, &mut pool, &mut position_nft, 200000000, &clock);
    add_liquidity_fix_coin(&config, &mut pool, &mut position_nft, 100000, false, &clock);

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
public fun test_collect_fee_without_recalculate() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clock);
    add_liquidity_fix_coin(&config, &mut pool, &mut position_nft, 100000, true, &clock);
    add_liquidity(&config, &mut pool, &mut position_nft, 200000000, &clock);
    add_liquidity_fix_coin(&config, &mut pool, &mut position_nft, 100000, false, &clock);
    let info_liquidity = position::liquidity(&position_nft);
    let (balance_a, balance_b) = pool::remove_liquidity(
        &config,
        &mut pool,
        &mut position_nft,
        info_liquidity,
        &clock,
    );
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();
    let (balance_a, balance_b) = pool::collect_fee(&config, &mut pool, &position_nft, false);
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::ELiquidityIsZero)]
public fun test_add_liquidity_delta_zero() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    add_liquidity(&config, &mut pool, &mut position_nft, 0, &clock);

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolPositionNotMatch)]
public fun test_add_liquidity_pool_position_not_match() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    let mut pool_2 = pool::new_for_test<CoinA, CoinB>(
        10,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let rec = pool::add_liquidity(&config, &mut pool_2, &mut position_nft, 100000000, &clock);
    let (pay_amount_a, pay_amount_b) = pool::add_liquidity_pay_amount(&rec);
    pool::repay_add_liquidity(
        &config,
        &mut pool_2,
        balance::create_for_testing<CoinA>(pay_amount_a),
        balance::create_for_testing<CoinB>(pay_amount_b + 1),
        rec,
    );

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);
    transfer::public_share_object(pool_2);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolPositionNotMatch)]
public fun test_add_liquidity_fix_coin_pool_position_not_match() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    let mut pool_2 = pool::new_for_test<CoinA, CoinB>(
        10,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let rec = pool::add_liquidity_fix_coin(
        &config,
        &mut pool_2,
        &mut position_nft,
        100000000,
        true,
        &clock,
    );
    let (pay_amount_a, pay_amount_b) = pool::add_liquidity_pay_amount(&rec);
    pool::repay_add_liquidity(
        &config,
        &mut pool_2,
        balance::create_for_testing<CoinA>(pay_amount_a),
        balance::create_for_testing<CoinB>(pay_amount_b + 1),
        rec,
    );

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);
    transfer::public_share_object(pool_2);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolPositionNotMatch)]
public fun test_collect_fee_position_not_match() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    let mut pool_2 = pool::new_for_test<CoinA, CoinB>(
        10,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let rec = pool::add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut position_nft,
        100000000,
        true,
        &clock,
    );
    let (pay_amount_a, pay_amount_b) = pool::add_liquidity_pay_amount(&rec);
    pool::repay_add_liquidity(
        &config,
        &mut pool,
        balance::create_for_testing<CoinA>(pay_amount_a),
        balance::create_for_testing<CoinB>(pay_amount_b),
        rec,
    );
    let (balance_a, balance_b) = pool::collect_fee(&config, &mut pool_2, &position_nft, true);
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);
    transfer::public_share_object(pool_2);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolPositionNotMatch)]
public fun test_remove_liquidity_fix_coin_pool_position_not_match() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    let mut pool_2 = pool::new_for_test<CoinA, CoinB>(
        10,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let rec = pool::add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut position_nft,
        100000000,
        true,
        &clock,
    );
    let (pay_amount_a, pay_amount_b) = pool::add_liquidity_pay_amount(&rec);
    pool::repay_add_liquidity(
        &config,
        &mut pool,
        balance::create_for_testing<CoinA>(pay_amount_a),
        balance::create_for_testing<CoinB>(pay_amount_b),
        rec,
    );
    let (balance_a, balance_b) = pool::remove_liquidity(
        &config,
        &mut pool_2,
        &mut position_nft,
        100000000,
        &clock,
    );
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);
    transfer::public_share_object(pool_2);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EAmountIncorrect)]
public fun test_add_liquidity_fix_coin_amount_zero() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );

    let rec = pool::add_liquidity_fix_coin(&config, &mut pool, &mut position_nft, 0, true, &clock);
    let (pay_amount_a, pay_amount_b) = pool::add_liquidity_pay_amount(&rec);
    pool::repay_add_liquidity(
        &config,
        &mut pool,
        balance::create_for_testing<CoinA>(pay_amount_a),
        balance::create_for_testing<CoinB>(pay_amount_b + 1),
        rec,
    );

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EAmountIncorrect)]
public fun test_add_liquidity_expect_error_amount_incorrect() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    let receipt = pool::add_liquidity_fix_coin(
        &config,
        &mut pool,
        &mut position_nft,
        100000000,
        true,
        &clock,
    );
    let (pay_amount_a, pay_amount_b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(
        &config,
        &mut pool,
        balance::create_for_testing<CoinA>(pay_amount_a),
        balance::create_for_testing<CoinB>(pay_amount_b + 1),
        receipt,
    );

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
public fun test_remove_liquidity_and_close() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clock);
    remove_liquidity(&config, &mut pool, &mut position_nft, 50000000, &clock, ctx);
    remove_liquidity(&config, &mut pool, &mut position_nft, 50000000, &clock, ctx);

    transfer::public_transfer(position_nft, TEST_ADDR);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
public fun test_swap() {
    let ctx = &mut tx_context::dummy();
    let (mut clock, admin_cap, config) = init_test(ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        60,
        4201216077597414008,
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    // let config = config::new_global_config_for_test(test_scenario::ctx(test), 2000);
    //| pool | index |  liquidity  | tick_lower_index | tick_upper_index |
    //|------|-------|-------------|------------------|------------------|
    //|      |   1   |  244944594  |      -30840      |      -27960      |
    //|      |   2   |  323359200  |      -30840      |      -27960      |
    //|      |   8   |   1147824   |     -443580      |      443580      |
    //|      |  13   |  121909879  |      -33540      |      -25260      |
    //|      |  17   |   1285216   |      -34620      |      67320       |
    //|      |  20   |  321511631  |      -34620      |      67320       |
    //|      |  21   | 11555285940 |      52320       |      54840       |
    //|      |  23   |    14352    |      11400       |      113400      |
    //|      |  24   |   229090    |      -36780      |      67320       |
    //|      |  25   |  38848687   |      -34980      |      -32220      |
    //|      |  26   |   134514    |     -443580      |      443580      |
    //|      |  27   | 73580862370 |      -29760      |      -29640      |
    //|      |  28   | 7630712637  |      -29520      |      -29460      |
    //|      |  29   |   4410085   |      -33720      |      -15060      |
    //|      |  30   | 3468680112  |      -29700      |      -29460      |
    //|      |  31   |  22774837   |     -443580      |      443580      |
    //|      |  34   | 9236228715  |      -29700      |      -29460      |
    //|      |  35   |  23543990   |      -33720      |      -15060      |
    //|      |  36   |   2354399   |      -33720      |      -15060      |
    //|      |  37   | 3468680355  |      -29700      |      -29460      |
    //|      |  38   |  23543990   |      -33720      |      -15060      |

    let liquiditys = vector<LPItem>[
        lpitem(244944594, nt(30840), nt(27960)),
        lpitem(323359200, nt(30840), nt(27960)),
        lpitem(1147824, nt(443580), pt(443580)),
        lpitem(121909879, nt(33540), nt(25260)),
        lpitem(1285216, nt(34620), pt(67320)),
        lpitem(321511631, nt(34620), pt(67320)),
        lpitem(11555285940, pt(52320), pt(54840)),
        lpitem(14352, pt(11400), pt(113400)),
        lpitem(229090, nt(36780), pt(67320)),
        lpitem(38848687, nt(34980), nt(32220)),
        lpitem(134514, nt(443580), pt(443580)),
        lpitem(73580862370, nt(29760), nt(29640)),
        lpitem(7630712637, nt(29520), nt(29460)),
        lpitem(4410085, nt(33720), nt(15060)),
        lpitem(3468680112, nt(29700), nt(29460)),
        lpitem(22774837, nt(443580), pt(443580)),
        lpitem(9236228715, nt(29700), nt(29460)),
        lpitem(23543990, nt(33720), nt(15060)),
        lpitem(2354399, nt(33720), nt(15060)),
        lpitem(3468680355, nt(29700), nt(29460)),
        lpitem(23543990, nt(33720), nt(15060)),
    ];
    let mut i = 0;
    while (i < vector::length(&liquiditys)) {
        let LPItem { liquidity, tick_lower, tick_upper } = *vector::borrow(&liquiditys, i);
        add_liquidity_for_swap(&config, &mut pool, tick_lower, tick_upper, liquidity, &clock, ctx);
        i = i + 1;
    };

    let (recv_amount, pay_amount) = swap(
        &mut pool,
        &config,
        true,
        true,
        10000000,
        min_sqrt_price(),
        &clock,
        ctx,
    );
    assert!(recv_amount == 517587, 0);
    assert!(pay_amount == 10000000, 0);
    let (recv_amount, pay_amount) = swap(
        &mut pool,
        &config,
        true,
        true,
        10000000,
        min_sqrt_price(),
        &clock,
        ctx,
    );
    assert!(recv_amount == 517451, 0);
    assert!(pay_amount == 10000000, 0);

    let (recv_amount, pay_amount) = swap(
        &mut pool,
        &config,
        false,
        true,
        100000000000,
        max_sqrt_price(),
        &clock,
        ctx,
    );
    assert!(recv_amount == 2620897394, 0);
    assert!(pay_amount == 100000000000, 0);
    assert!(current_sqrt_price(&pool) == 53088636778614969649700, 0);

    let (partner_cap, mut partner) = partner::create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clock,
        ctx,
    );
    clock::increment_for_testing(&mut clock, 100000000);
    let (recv_amount, pay_amount) = swap_with_partner(
        &mut pool,
        &config,
        &mut partner,
        true,
        true,
        1000000000,
        min_sqrt_price(),
        &clock,
        ctx,
    );
    assert!(recv_amount == 99685917468, 0);
    assert!(pay_amount == 1000000000, 0);
    assert!(current_sqrt_price(&pool) == 7226146395086366169, 0);

    transfer::public_share_object(partner_cap);
    transfer::public_share_object(partner);
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::ENotEnoughLiquidity)]
fun test_swap_to_target_price_expect_error_amount_out_is_zero() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        60,
        get_sqrt_price_at_tick(i32::from(0)),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );

    let target_sqrt_price = get_sqrt_price_at_tick(i32::neg_from(1000));
    swap(
        &mut pool,
        &config,
        true,
        true,
        1000000000,
        target_sqrt_price,
        &clock,
        ctx,
    );
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EAmountIncorrect)]
fun test_swap_to_target_price_expect_error_amount_in_incorrect() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        60,
        get_sqrt_price_at_tick(i32::from(0)),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );

    let target_sqrt_price = get_sqrt_price_at_tick(i32::neg_from(1000));
    swap(
        &mut pool,
        &config,
        true,
        true,
        0,
        target_sqrt_price,
        &clock,
        ctx,
    );
    transfer::public_share_object(pool);

    close_test(admin_cap, config, clock);
}

#[test]
fun test_collect_fee() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        60,
        get_sqrt_price_at_tick(pt(0)),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let mut position_1 = open_position(&config, &mut pool, nt(1800), pt(1800), ctx);
    add_liquidity(&config, &mut pool, &mut position_1, 100000000, &clock);
    swap(
        &mut pool,
        &config,
        false,
        true,
        1000000,
        max_sqrt_price(),
        &clock,
        ctx,
    );
    let need_fee_b = ((((1000000 * 2000) / 1000000) * 8000) / 10000) - 1;
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_1, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == need_fee_b, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);

    swap(
        &mut pool,
        &config,
        false,
        true,
        1000000,
        max_sqrt_price(),
        &clock,
        ctx,
    );
    let need_fee_b = ((((1000000 * 2000) / 1000000) * 8000) / 10000) - 1;
    let (calculate_fee_a, calculate_fee_b) = pool::calculate_and_update_fee(
        &config,
        &mut pool,
        object::id(&position_1),
    );
    let (get_fee_a, get_fee_b) = pool::get_position_fee(&pool, object::id(&position_1));
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_1, true);
    assert!(balance::value(&fee_a) == calculate_fee_a, 0);
    assert!(balance::value(&fee_b) == calculate_fee_b, 0);
    assert!(get_fee_a == calculate_fee_a, 0);
    assert!(get_fee_b == calculate_fee_b, 0);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == need_fee_b, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);

    swap(
        &mut pool,
        &config,
        true,
        true,
        1000000,
        min_sqrt_price(),
        &clock,
        ctx,
    );
    let need_fee_a = ((((1000000 * 2000) / 1000000) * 8000) / 10000) - 1;
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_1, true);
    assert!(balance::value(&fee_a) == need_fee_a, 0);
    assert!(balance::value(&fee_b) == 0, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);

    let position_2 = open_position(&config, &mut pool, nt(1200), pt(1200), ctx);
    add_liquidity(&config, &mut pool, &mut position_1, 100000000, &clock);
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_1, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == 0, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);
    let (fee_amount_a, fee_amount_b) = pool::calculate_and_update_fee(
        &config,
        &mut pool,
        object::id(&position_1),
    );
    assert!(fee_amount_a == 0, 0);
    assert!(fee_amount_b == 0, 0);

    transfer::public_transfer(position_1, TEST_ADDR);
    transfer::public_transfer(position_2, TEST_ADDR);
    transfer::public_share_object(pool);
    close_test(admin_cap, config, clock);
}

#[test]
fun test_collect_fee_full_range() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(pt(0)),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (lower, upper) = (i32::neg_from(443636), i32::from(443636));
    let mut position_0 = open_position(&config, &mut pool, lower, upper, ctx);
    add_liquidity(&config, &mut pool, &mut position_0, 1, &clock);
    remove_liquidity(&config, &mut pool, &mut position_0, 1, &clock, ctx);

    let mut position_1 = open_position(&config, &mut pool, nt(2400), pt(2400), ctx);
    add_liquidity(&config, &mut pool, &mut position_1, 100000000, &clock);
    swap(
        &mut pool,
        &config,
        false,
        true,
        1000000,
        max_sqrt_price(),
        &clock,
        ctx,
    );
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_1, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == 1599, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);

    let mut position_2 = open_position(&config, &mut pool, lower, upper, ctx);
    add_liquidity(&config, &mut pool, &mut position_2, 100000000, &clock);
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_2, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == 0, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);
    swap(
        &mut pool,
        &config,
        false,
        true,
        1000000,
        max_sqrt_price(),
        &clock,
        ctx,
    );
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_2, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == 799, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_1, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == 799, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);

    let mut position_3 = open_position(&config, &mut pool, lower, upper, ctx);
    add_liquidity(&config, &mut pool, &mut position_3, 200000000, &clock);
    swap(
        &mut pool,
        &config,
        false,
        true,
        1000000,
        max_sqrt_price(),
        &clock,
        ctx,
    );
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_1, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == 399, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_2, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == 399, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);
    let (fee_a, fee_b) = pool::collect_fee(&config, &mut pool, &position_3, true);
    assert!(balance::value(&fee_a) == 0, 0);
    assert!(balance::value(&fee_b) == 799, 0);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);

    transfer::public_transfer(position_0, TEST_ADDR);
    transfer::public_transfer(position_1, TEST_ADDR);
    transfer::public_transfer(position_2, TEST_ADDR);
    transfer::public_transfer(position_3, TEST_ADDR);
    transfer::public_share_object(pool);
    close_test(admin_cap, config, clock);
}

public fun create_pool<CoinTypeA, CoinTypeB>(
    tick_spacing: u32,
    init_sqrt_price: u128,
    fee_rate: u64,
    index: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Pool<CoinTypeA, CoinTypeB> {
    let pool = pool::new_for_test<CoinTypeA, CoinTypeB>(
        tick_spacing,
        init_sqrt_price,
        fee_rate,
        string::utf8(b""),
        index,
        clock,
        ctx,
    );
    assert!(pool::fee_rate(&pool) == 2000, 0);
    //let ticks = pool::fetch_ticks(&pool, vector::empty<u32>(), 10);
    // let min_tick = *vector::borrow(&ticks, 0);
    // let max_tick = *vector::borrow(&ticks, 1);
    // assert!(tick::index(&min_tick) == i32::neg_from(443636 - 443636 % 100), 0);
    // assert!(tick::index(&max_tick) == i32::from(443636 - 443636 % 100), 0);
    pool
}

public fun open_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower_idx: i32::I32,
    tick_upper_idx: i32::I32,
    ctx: &mut TxContext,
): Position {
    let position_nft = pool::open_position(
        config,
        pool,
        i32::as_u32(tick_lower_idx),
        i32::as_u32(tick_upper_idx),
        ctx,
    );
    let (l, u) = position::tick_range(&position_nft);
    assert!(i32::eq(l, tick_lower_idx), 0);
    assert!(i32::eq(u, tick_upper_idx), 0);
    assert!(position::liquidity(&position_nft) == 0, 0);
    assert!(position::pool_id(&position_nft) == object::id(pool), 0);

    let postion_manager = pool::position_manager(pool);
    let position_info = position::borrow_position_info(postion_manager, object::id(&position_nft));
    assert!(position::info_liquidity(position_info) == 0, 0);
    assert!(position::info_position_id(position_info) == object::id(&position_nft), 0);
    position_nft
}

public fun add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    liquidity: u128,
    clock: &Clock,
) {
    let (tick_lower_idx, tick_upper_idx) = position::tick_range(position_nft);
    let (before_balance_a, before_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let (before_tick_lower, before_tick_upper) = {
        let tick_manager = pool::tick_manager(pool);
        (
            tick::copy_tick_with_default(tick_manager, tick_lower_idx),
            tick::copy_tick_with_default(tick_manager, tick_upper_idx),
        )
    };
    let before_nft_liquidity = position::liquidity(position_nft);
    let before_position_info = *pool::borrow_position_info(pool, object::id(position_nft));

    let receipt = pool::add_liquidity(
        config,
        pool,
        position_nft,
        liquidity,
        clock,
    );
    let (pay_amount_a, pay_amount_b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(
        config,
        pool,
        balance::create_for_testing<CoinTypeA>(pay_amount_a),
        balance::create_for_testing<CoinTypeB>(pay_amount_b),
        receipt,
    );

    // Check amount_a / amount_b
    let (cal_amount_a, cal_amount_b) = clmm_math::get_amount_by_liquidity(
        tick_lower_idx,
        tick_upper_idx,
        pool::current_tick_index(pool),
        pool::current_sqrt_price(pool),
        liquidity,
        true,
    );
    assert!(pay_amount_a == cal_amount_a, 0);
    assert!(pay_amount_b == cal_amount_b, 0);

    // Check pool balances
    let (after_balance_a, after_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let (after_tick_lower, after_tick_upper) = (
        *pool::borrow_tick(pool, tick_lower_idx),
        *pool::borrow_tick(pool, tick_upper_idx),
    );

    assert!((after_balance_a - before_balance_a) == pay_amount_a, 0);
    assert!((after_balance_b - before_balance_b) == pay_amount_b, 0);

    // Check position
    let after_position_info = *pool::borrow_position_info(pool, object::id(position_nft));
    assert!(before_nft_liquidity + liquidity == position::liquidity(position_nft), 0);
    assert!(position::liquidity(position_nft) == position::info_liquidity(&after_position_info), 0);
    assert!(
        position::info_liquidity(&before_position_info) + liquidity == position::info_liquidity(&after_position_info),
        0,
    );

    // Check tick liquidity
    assert!(
        tick::liquidity_gross(&after_tick_lower) - tick::liquidity_gross(&before_tick_lower) == liquidity,
        0,
    );
    assert!(
        tick::liquidity_gross(&after_tick_upper) - tick::liquidity_gross(&before_tick_upper) == liquidity,
        0,
    );
    assert!(
        i128::as_u128(
                i128::sub(tick::liquidity_net(&after_tick_lower), tick::liquidity_net(&before_tick_lower))
            ) == liquidity,
        0,
    );
    assert!(
        i128::as_u128(
                i128::sub(tick::liquidity_net(&before_tick_upper), tick::liquidity_net(&after_tick_upper))
            ) == liquidity,
        0,
    );
}

public fun open_position_with_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower: I32,
    tick_upper: I32,
    liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): Position {
    let mut position = open_position(config, pool, tick_lower, tick_upper, ctx);
    add_liquidity(config, pool, &mut position, liquidity, clock);
    position
}

public fun add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    amount: u64,
    fix_amount_a: bool,
    clock: &Clock,
) {
    let (tick_lower_idx, tick_upper_idx) = position::tick_range(position_nft);
    let (before_balance_a, before_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let (before_tick_lower, before_tick_upper) = {
        let tick_manager = pool::tick_manager(pool);
        (
            tick::copy_tick_with_default(tick_manager, tick_lower_idx),
            tick::copy_tick_with_default(tick_manager, tick_upper_idx),
        )
    };
    let before_nft_liquidity = position::liquidity(position_nft);
    let before_position_info = *pool::borrow_position_info(pool, object::id(position_nft));

    let receipt = pool::add_liquidity_fix_coin(
        config,
        pool,
        position_nft,
        amount,
        fix_amount_a,
        clock,
    );
    let (pay_amount_a, pay_amount_b) = pool::add_liquidity_pay_amount(&receipt);
    pool::repay_add_liquidity(
        config,
        pool,
        balance::create_for_testing<CoinTypeA>(pay_amount_a),
        balance::create_for_testing<CoinTypeB>(pay_amount_b),
        receipt,
    );

    // Check amount_a / amount_b
    let (liquidity, amount_a, amount_b) = clmm_math::get_liquidity_by_amount(
        tick_lower_idx,
        tick_upper_idx,
        current_tick_index(pool),
        current_sqrt_price(pool),
        amount,
        fix_amount_a,
    );
    assert!(pay_amount_a == amount_a, 0);
    assert!(pay_amount_b == amount_b, 0);
    if (fix_amount_a) {
        assert!(pay_amount_a == amount, 0)
    } else {
        assert!(pay_amount_b == amount, 0)
    };

    // Check pool balances
    let (after_balance_a, after_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let (after_tick_lower, after_tick_upper) = (
        *pool::borrow_tick(pool, tick_lower_idx),
        *pool::borrow_tick(pool, tick_upper_idx),
    );
    assert!((after_balance_a - before_balance_a) == pay_amount_a, 0);
    assert!((after_balance_b - before_balance_b) == pay_amount_b, 0);

    // Check position
    let after_position_info = *pool::borrow_position_info(pool, object::id(position_nft));
    assert!(before_nft_liquidity + liquidity == position::liquidity(position_nft), 0);
    assert!(position::liquidity(position_nft) == position::info_liquidity(&after_position_info), 0);
    assert!(
        position::info_liquidity(&before_position_info) + liquidity == position::info_liquidity(&after_position_info),
        0,
    );

    // Check tick liquidity
    assert!(
        tick::liquidity_gross(&after_tick_lower) - tick::liquidity_gross(&before_tick_lower) == liquidity,
        0,
    );
    assert!(
        tick::liquidity_gross(&after_tick_upper) - tick::liquidity_gross(&before_tick_upper) == liquidity,
        0,
    );
    assert!(
        i128::as_u128(
                i128::sub(tick::liquidity_net(&after_tick_lower), tick::liquidity_net(&before_tick_lower))
            ) == liquidity,
        0,
    );
    assert!(
        i128::as_u128(
                i128::sub(tick::liquidity_net(&before_tick_upper), tick::liquidity_net(&after_tick_upper))
            ) == liquidity,
        0,
    );
}

public fun remove_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): (u64, u64) {
    let (before_balance_a, before_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let before_pool_current_liqudity = pool::liquidity(pool);
    let (tick_lower_idx, tick_upper_idx) = position::tick_range(position_nft);
    let (before_tick_lower, before_tick_upper) = (
        *pool::borrow_tick(pool, tick_lower_idx),
        *pool::borrow_tick(pool, tick_upper_idx),
    );
    let (recv_a, recv_b) = pool::remove_liquidity(
        config,
        pool,
        position_nft,
        delta_liquidity,
        clock,
    );

    // Check balances
    let (need_a, need_b) = clmm_math::get_amount_by_liquidity(
        tick_lower_idx,
        tick_upper_idx,
        pool::current_tick_index(pool),
        pool::current_sqrt_price(pool),
        delta_liquidity,
        false,
    );
    assert!(need_a == balance::value(&recv_a), 0);
    assert!(need_b == balance::value(&recv_b), 0);
    let (after_balance_a, after_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    assert!((before_balance_a - after_balance_a) == need_a, 0);
    assert!((before_balance_b - after_balance_b) == need_b, 0);

    // Check tick's liquidity gross and liquidity net.
    let (after_tick_lower, after_tick_upper) = {
        let tick_manager = pool::tick_manager(pool);
        (
            tick::copy_tick_with_default(tick_manager, tick_lower_idx),
            tick::copy_tick_with_default(tick_manager, tick_upper_idx),
        )
    };
    assert!(
        (tick::liquidity_gross(&before_tick_lower) - tick::liquidity_gross(&after_tick_lower)) == delta_liquidity,
        0,
    );
    assert!(
        (tick::liquidity_gross(&before_tick_upper) - tick::liquidity_gross(&after_tick_upper)) == delta_liquidity,
        0,
    );
    assert!(
        i128::eq(
            i128::sub(
                tick::liquidity_net(&before_tick_lower),
                tick::liquidity_net(&after_tick_lower),
            ),
            i128::from(delta_liquidity),
        ),
        0,
    );
    assert!(
        i128::eq(
            i128::add(tick::liquidity_net(&before_tick_upper), i128::from(delta_liquidity)),
            tick::liquidity_net(&after_tick_upper),
        ),
        0,
    );

    // Check pool's liquidity
    if (i32::gte(pool::current_tick_index(pool), tick_upper_idx)) {
        assert!(pool::liquidity(pool) == before_pool_current_liqudity, 0);
    } else if (i32::gte(pool::current_tick_index(pool), tick_lower_idx)) {
        assert!(pool::liquidity(pool) + delta_liquidity == before_pool_current_liqudity, 0);
    } else {
        assert!(pool::liquidity(pool) == before_pool_current_liqudity, 0);
    };
    transfer::public_transfer(coin::from_balance(recv_a, ctx), TEST_ADDR);
    transfer::public_transfer(coin::from_balance(recv_b, ctx), TEST_ADDR);
    (need_a, need_b)
}

public fun add_liquidity_for_swap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower_idx: I32,
    tick_upper_idx: I32,
    liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let mut position_nft = pool::open_position(
        config,
        pool,
        i32::as_u32(tick_lower_idx),
        i32::as_u32(tick_upper_idx),
        ctx,
    );
    add_liquidity(config, pool, &mut position_nft, liquidity, clock);
    transfer::public_transfer(position_nft, tx_context::sender(ctx));
}

public fun swap<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    config: &GlobalConfig,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): (u64, u64) {
    let (before_balance_a, before_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let (before_protocol_fee_a, before_protocol_fee_b) = pool::protocol_fee(pool);

    let (recv_balance_a, recv_balance_b, receipt) = flash_swap(
        config,
        pool,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        clock,
    );
    let pay_amount = swap_pay_amount(&receipt);
    // std::debug::print(&pay_amount);
    let (pay_balance_a, pay_balance_b) = if (a2b) {
        (balance::create_for_testing<CoinTypeA>(pay_amount), balance::zero<CoinTypeB>())
    } else {
        (balance::zero<CoinTypeA>(), balance::create_for_testing<CoinTypeB>(pay_amount))
    };
    let (pay_amount_a, pay_amount_b) = (
        balance::value(&pay_balance_a),
        balance::value(&pay_balance_b),
    );
    repay_flash_swap(
        config,
        pool,
        pay_balance_a,
        pay_balance_b,
        receipt,
    );

    // Check pool balance
    let (after_balance_a, after_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let recv_amount = if (a2b) {
        assert!(after_balance_a - before_balance_a == pay_amount_a, 0);
        assert!(before_balance_b - after_balance_b == balance::value(&recv_balance_b), 0);
        balance::destroy_zero(recv_balance_a);
        let amount = balance::value(&recv_balance_b);
        transfer::public_transfer(coin::from_balance(recv_balance_b, ctx), tx_context::sender(ctx));
        amount
    } else {
        assert!(after_balance_b - before_balance_b == pay_amount_b, 0);
        assert!(before_balance_a - after_balance_a == balance::value(&recv_balance_a), 0);
        balance::destroy_zero(recv_balance_b);
        let amount = balance::value(&recv_balance_a);
        transfer::public_transfer(coin::from_balance(recv_balance_a, ctx), tx_context::sender(ctx));
        amount
    };

    // Check protocol fee
    // Protocol fees are calculated for every step swap in the split, and due to rounding up,
    // the actual fees may be slightly higher than the result calculated directly through the protocol fee rate
    let fee_amount = full_math_u64::mul_div_ceil(
        pay_amount,
        pool::fee_rate(pool),
        clmm_math::fee_rate_denominator(),
    );
    let expect_protocol_fee = full_math_u64::mul_div_ceil(
        fee_amount,
        config::protocol_fee_rate(config),
        10000,
    );
    let (after_protocol_fee_a, after_protocol_fee_b) = pool::protocol_fee(pool);
    if (a2b) {
        assert!(after_protocol_fee_a - before_protocol_fee_a >= expect_protocol_fee, 0);
        assert!((after_protocol_fee_a - before_protocol_fee_a - expect_protocol_fee) <= 100, 0);
        assert!(after_protocol_fee_b - before_protocol_fee_b == 0, 0);
    } else {
        assert!(after_protocol_fee_a - before_protocol_fee_a == 0, 0);
        assert!(after_protocol_fee_b - before_protocol_fee_b >= expect_protocol_fee, 0);
        assert!((after_protocol_fee_b - before_protocol_fee_b - expect_protocol_fee) <= 100, 0);
    };
    (recv_amount, pay_amount)
}

public fun swap_with_partner<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    config: &GlobalConfig,
    partner: &mut Partner,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext,
): (u64, u64) {
    let (before_balance_a, before_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let (before_protocol_fee_a, before_protocol_fee_b) = pool::protocol_fee(pool);
    let (before_ref_balance_a, before_ref_balance_b) = {
        let ref_balances = partner::balances(partner);
        let key_a = string::from_ascii(type_name::into_string(type_name::get<CoinTypeA>()));
        let key_b = string::from_ascii(type_name::into_string(type_name::get<CoinTypeB>()));
        let balance_a = if (bag::contains(ref_balances, key_a)) {
            balance::value(bag::borrow<String, Balance<CoinTypeA>>(ref_balances, key_a))
        } else {
            0
        };
        let balance_b = if (bag::contains(ref_balances, key_b)) {
            balance::value(bag::borrow<String, Balance<CoinTypeB>>(ref_balances, key_b))
        } else {
            0
        };
        (balance_a, balance_b)
    };

    let (recv_balance_a, recv_balance_b, receipt) = flash_swap_with_partner(
        config,
        pool,
        partner,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        clock,
    );
    let pay_amount = swap_pay_amount(&receipt);
    let ref_fee_amount = ref_fee_amount(&receipt);
    let (pay_balance_a, pay_balance_b) = if (a2b) {
        (balance::create_for_testing<CoinTypeA>(pay_amount), balance::zero<CoinTypeB>())
    } else {
        (balance::zero<CoinTypeA>(), balance::create_for_testing<CoinTypeB>(pay_amount))
    };
    let (pay_amount_a, pay_amount_b) = (
        balance::value(&pay_balance_a),
        balance::value(&pay_balance_b),
    );
    repay_flash_swap_with_partner(
        config,
        pool,
        partner,
        pay_balance_a,
        pay_balance_b,
        receipt,
    );

    // Check pool balance
    let (after_balance_a, after_balance_b) = {
        let (a, b) = pool::balances(pool);
        (balance::value(a), balance::value(b))
    };
    let recv_amount = if (a2b) {
        assert!(after_balance_a - before_balance_a + ref_fee_amount == pay_amount_a, 0);
        assert!(before_balance_b - after_balance_b == balance::value(&recv_balance_b), 0);
        balance::destroy_zero(recv_balance_a);
        let amount = balance::value(&recv_balance_b);
        transfer::public_transfer(coin::from_balance(recv_balance_b, ctx), tx_context::sender(ctx));
        amount
    } else {
        assert!(after_balance_b - before_balance_b + ref_fee_amount == pay_amount_b, 0);
        assert!(before_balance_a - after_balance_a == balance::value(&recv_balance_a), 0);
        balance::destroy_zero(recv_balance_b);
        let amount = balance::value(&recv_balance_a);
        transfer::public_transfer(coin::from_balance(recv_balance_a, ctx), tx_context::sender(ctx));
        amount
    };

    // Check protocol fee
    // Protocol fees are calculated for every step swap in the split, and due to rounding up,
    // the actual fees may be slightly higher than the result calculated directly through the protocol fee rate
    let fee_amount = full_math_u64::mul_div_ceil(
        pay_amount,
        pool::fee_rate(pool),
        clmm_math::fee_rate_denominator(),
    );
    let expect_protocol_fee =
        full_math_u64::mul_div_ceil(fee_amount, config::protocol_fee_rate(config), 10000) - ref_fee_amount;
    let (after_protocol_fee_a, after_protocol_fee_b) = pool::protocol_fee(pool);
    let real_protocol_fee = if (a2b) {
        let real_protocol_fee = after_protocol_fee_a - before_protocol_fee_a;
        assert!(real_protocol_fee >= expect_protocol_fee, 0);
        assert!((real_protocol_fee - expect_protocol_fee) <= 100, 0);
        assert!(after_protocol_fee_b - before_protocol_fee_b == 0, 0);
        real_protocol_fee
    } else {
        let real_protocol_fee = after_protocol_fee_b - before_protocol_fee_b;
        assert!(real_protocol_fee >= expect_protocol_fee, 0);
        assert!((real_protocol_fee - expect_protocol_fee) <= 100, 0);
        assert!(after_protocol_fee_a - before_protocol_fee_a == 0, 0);
        real_protocol_fee
    };

    // Check ref fee
    let (after_ref_balance_a, after_ref_balance_b) = {
        let ref_balances = partner::balances(partner);
        let key_a = string::from_ascii(type_name::into_string(type_name::get<CoinTypeA>()));
        let key_b = string::from_ascii(type_name::into_string(type_name::get<CoinTypeB>()));
        let balance_a = if (bag::contains(ref_balances, key_a)) {
            balance::value(bag::borrow<String, Balance<CoinTypeA>>(ref_balances, key_a))
        } else {
            0
        };
        let balance_b = if (bag::contains(ref_balances, key_b)) {
            balance::value(bag::borrow<String, Balance<CoinTypeB>>(ref_balances, key_b))
        } else {
            0
        };
        (balance_a, balance_b)
    };
    assert!(
        ref_fee_amount == full_math_u64::mul_div_floor((real_protocol_fee + ref_fee_amount), partner::ref_fee_rate(partner), 10000),
        0,
    );
    if (a2b) {
        assert!((after_ref_balance_a - before_ref_balance_a) == ref_fee_amount, 0);
        assert!((after_ref_balance_b - before_ref_balance_b) == 0, 0);
    } else {
        assert!((after_ref_balance_a - before_ref_balance_a) == 0, 0);
        assert!((after_ref_balance_b - before_ref_balance_b) == ref_fee_amount, 0);
    };

    (recv_amount, pay_amount)
}

#[test]
public fun test_swap_on_bound() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        200,
        12100745878893454763100,
        10000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let liquiditys = vector<LPItem>[
        lpitem(90371, pt(129600), pt(132000)),
        lpitem(334870, pt(55000), pt(143400)),
        lpitem(263049, nt(443600), pt(443600)),
        lpitem(121642, nt(443600), pt(443600)),
        lpitem(1, pt(55000), pt(142400)),
        lpitem(1, pt(54400), pt(143200)),
    ];
    let mut i = 0;
    while (i < vector::length(&liquiditys)) {
        let LPItem { liquidity, tick_lower, tick_upper } = *vector::borrow(&liquiditys, i);
        add_liquidity_for_swap(&config, &mut pool, tick_lower, tick_upper, liquidity, &clock, ctx);
        i = i + 1;
    };

    let (recv_amount, _) = swap(
        &mut pool,
        &config,
        true,
        true,
        11,
        min_sqrt_price(),
        &clock,
        ctx,
    );
    assert!(recv_amount == 3420345, 0);
    assert!(i32::eq(current_tick_index(&pool), i32::from(129599)), 0);
    assert!(current_sqrt_price(&pool) == 12022845416078604922929, 0);
    assert!(liquidity(&pool) == 719563, 0);

    let (recv_amount, _) = swap(
        &mut pool,
        &config,
        true,
        true,
        45,
        min_sqrt_price(),
        &clock,
        ctx,
    );
    assert!(recv_amount == 17974441, 0);
    assert!(i32::eq(current_tick_index(&pool), i32::from(128818)), 0);
    assert!(current_sqrt_price(&pool) == 11562051952539348770540, 0);
    assert!(liquidity(&pool) == 719563, 0);

    let (recv_amount, _) = swap<CoinA, CoinB>(
        &mut pool,
        &config,
        false,
        true,
        18156004,
        max_sqrt_price(),
        &clock,
        ctx,
    );
    assert!(recv_amount == 43, 0);
    assert!(liquidity(&pool) == 809934, 0);
    assert!(i32::eq(current_tick_index(&pool), i32::from(129600)), 0);
    assert!(current_sqrt_price(&pool) == 12022845416078604922929, 0);

    transfer::public_share_object(pool);
    close_test(admin_cap, config, clock);
}

#[test]
fun test_flash_loan() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        200,
        18446744073709551616,
        10000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let mut position_1 = open_position(&config, &mut pool, nt(1800), pt(1800), ctx);
    add_liquidity(&config, &mut pool, &mut position_1, 1 <<64, &clock);

    let (mut a, b, r) = pool::flash_loan(&config, &mut pool, true, 10000);
    assert!(balance::value(&a) == 10000, 0);
    assert!(balance::value(&b) == 0, 0);
    let fee_amount = 10000 * 10000 / 1000000;
    balance::join(&mut a, balance::create_for_testing(fee_amount));
    pool::repay_flash_loan(&config, &mut pool, a, b, r);

    let (a, mut b, r) = pool::flash_loan(&config, &mut pool, false, 1000000);
    assert!(balance::value(&a) == 0, 0);
    assert!(balance::value(&b) == 1000000, 0);
    let fee_amount_b = 1000000 * 10000 / 1000000;
    balance::join(&mut b, balance::create_for_testing(fee_amount_b));
    pool::repay_flash_loan(&config, &mut pool, a, b, r);

    let (fee_growth_global_a, fee_growth_global_b) = pool::fees_growth_global(&pool);
    let fee_growth_global_a_expect = fee_amount * (10000 - 2000) / 10000;
    let fee_growth_global_a_expect =
        ((fee_growth_global_a_expect as u128) << 64)  / liquidity(&pool);
    assert!(fee_growth_global_a == fee_growth_global_a_expect, 0);

    let fee_growth_global_b_expect = fee_amount_b * (10000 - 2000) / 10000;
    let fee_growth_global_b_expect =
        ((fee_growth_global_b_expect as u128) << 64)  / liquidity(&pool);
    assert!(fee_growth_global_b == fee_growth_global_b_expect, 0);

    transfer::public_share_object(pool);
    close_test(admin_cap, config, clock);
    transfer::public_transfer(position_1, TEST_ADDR);
}

#[test]
fun test_flash_loan_with_partner() {
    let ctx = &mut tx_context::dummy();
    let (clock, admin_cap, config) = init_test(ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        200,
        18446744073709551616,
        10000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (partner_cap, mut partner) = cetus_clmm::partner::create_partner_for_test(
        std::string::utf8(b"Test"),
        2000,
        0,
        10000000000000000000,
        &clock,
        ctx,
    );
    let mut position_1 = open_position(&config, &mut pool, nt(1800), pt(1800), ctx);
    add_liquidity(&config, &mut pool, &mut position_1, 1 <<64, &clock);
    let (mut a, b, r) = pool::flash_loan_with_partner(
        &config,
        &mut pool,
        &partner,
        true,
        10000,
        &clock,
    );
    assert!(balance::value(&a) == 10000, 0);
    assert!(balance::value(&b) == 0, 0);
    let fee_amount = 10000 * 10000 / 1000000;
    balance::join(&mut a, balance::create_for_testing(fee_amount));
    pool::repay_flash_loan_with_partner(&config, &mut pool, &mut partner, a, b, r);

    let (a, mut b, r) = pool::flash_loan_with_partner(
        &config,
        &mut pool,
        &partner,
        false,
        1000000,
        &clock,
    );
    assert!(balance::value(&a) == 0, 0);
    assert!(balance::value(&b) == 1000000, 0);
    let fee_amount_b = 1000000 * 10000 / 1000000;
    balance::join(&mut b, balance::create_for_testing(fee_amount_b));
    pool::repay_flash_loan_with_partner(&config, &mut pool, &mut partner, a, b, r);

    let (fee_growth_global_a, fee_growth_global_b) = pool::fees_growth_global(&pool);
    let fee_growth_global_a_expect = fee_amount * (10000 - 2000) / 10000;
    let fee_growth_global_a_expect =
        ((fee_growth_global_a_expect as u128) << 64)  / liquidity(&pool);
    assert!(fee_growth_global_a == fee_growth_global_a_expect, 0);

    let fee_growth_global_b_expect = fee_amount_b * (10000 - 2000) / 10000;
    let fee_growth_global_b_expect =
        ((fee_growth_global_b_expect as u128) << 64)  / liquidity(&pool);
    assert!(fee_growth_global_b == fee_growth_global_b_expect, 0);

    let ref_fee = cetus_clmm::partner::balances(&partner);
    let key_a = string::from_ascii(type_name::into_string(type_name::get<CoinA>()));
    let key_b = string::from_ascii(type_name::into_string(type_name::get<CoinB>()));
    let balance_a = bag::borrow<String, Balance<CoinA>>(ref_fee, key_a);
    let balance_b = bag::borrow<String, Balance<CoinB>>(ref_fee, key_b);
    assert!(balance::value(balance_a) == 4, 0);
    assert!(balance::value(balance_b) == 400, 0);

    transfer::public_share_object(pool);
    transfer::public_transfer(partner_cap, TEST_ADDR);
    transfer::public_share_object(partner);
    close_test(admin_cap, config, clock);
    transfer::public_transfer(position_1, TEST_ADDR);
}

#[test]
fun test_update_pool_fee() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        10,
        get_sqrt_price_at_tick(i32::from(0)),
        10000,
        string::utf8(b""),
        0,
        &clk,
        &mut ctx,
    );
    pool.update_liquidity(10000000000);
    pool::update_pool_fee_test(&mut pool, 2 << 12, 5000, true);
    let fee = (2 << 12) - full_math_u64::mul_div_ceil(2 << 12, 5000, PROTOCOL_FEE_DENOMINATOR);
    let (fee_growth_global_a, fee_growth_global_b) = pool::fees_growth_global(&pool);
    assert!(fee_growth_global_a == (((fee as u128) << 64) / 10000000000), 1);
    assert!(fee_growth_global_b == 0, 2);

    pool::update_pool_fee_test(&mut pool, 2 << 12, 5000, false);
    let fee = (2 << 12) - full_math_u64::mul_div_ceil(2 << 12, 5000, PROTOCOL_FEE_DENOMINATOR);
    let (fee_growth_global_a, fee_growth_global_b) = pool::fees_growth_global(&pool);
    assert!(fee_growth_global_b == (((fee as u128) << 64) / 10000000000), 1);
    assert!(fee_growth_global_a == fee_growth_global_b, 2);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(pool);
}

#[test]
fun test_swap_in_pool() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let mut pool = pool::new_pool_custom<CoinA, CoinB>(
        60,
        1715006487636306234,
        2500,
        0,
        0,
        110257286,
        791874,
        50214615874,
        533921553807,
        4701968956,
        &clk,
        &mut ctx,
    );

    let tick_manager = pool.mut_tick_manager();
    tick::insert_tick(
        tick_manager,
        i32::neg_from(443580),
        4307090400,
        i128::from(50000000001),
        50000000001,
        0,
        0,
        0,
        vector[],
    );
    tick::insert_tick(
        tick_manager,
        i32::neg_from(55140),
        1171196320715478783,
        i128::from(27300932),
        27300932,
        143267228134630813,
        1027858884105033,
        445998234215864138263,
        vector[],
    );
    tick::insert_tick(
        tick_manager,
        i32::neg_from(54540),
        1206862748656139047,
        i128::from(187314941),
        187314941,
        52224278677715496,
        219224795916387,
        137418651039469457519,
        vector[],
    );
    tick::insert_tick(
        tick_manager,
        i32::neg_from(41880),
        2272754597651468243,
        i128::neg_from(214615873),
        214615873,
        0,
        0,
        0,
        vector[],
    );
    tick::insert_tick(
        tick_manager,
        i32::from(443580),
        79005160168441461737552776218,
        i128::neg_from(50000000001),
        50000000001,
        0,
        0,
        0,
        vector[],
    );
    // a2b and by_amount_in = false
    let swap_res = pool::swap_in_pool_test(
        &mut pool,
        true,
        false,
        min_sqrt_price(),
        4653499090,
        5000,
        0,
    );
    assert!(swap_res.amount_out() == 4653499090, 2);
    assert!(swap_res.ref_amount() == 0, 3);

    // a2b and by_amount_in = true
    let swap_res = pool::swap_in_pool_test(
        &mut pool,
        true,
        true,
        min_sqrt_price(),
        533921553807,
        5000,
        0,
    );
    assert!(swap_res.amount_in() + swap_res.fee_amount() == 533921553807, 2);
    assert!(swap_res.ref_amount() == 0, 3);
    // b2a and by_amount_in = false
    let swap_res = pool::swap_in_pool_test(
        &mut pool,
        false,
        false,
        max_sqrt_price(),
        4701968956,
        5000,
        0,
    );
    assert!(swap_res.amount_out() == 4701968956, 2);
    assert!(swap_res.ref_amount() == 0, 3);
    // b2a and by_amount_in = true
    let swap_res = pool::swap_in_pool_test(
        &mut pool,
        false,
        true,
        max_sqrt_price(),
        4701968956,
        5000,
        0,
    );
    assert!(swap_res.amount_in() + swap_res.fee_amount() == 4701968956, 2);
    assert!(swap_res.ref_amount() == 0, 3);

    clock::destroy_for_testing(clk);
    transfer::public_share_object(pool);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::ENotEnoughLiquidity)]
fun test_swap_in_poo_failure_with_no_enough_liquidity() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let mut pool = pool::new_pool_with_ticks<CoinA, CoinB>(&clk, &mut ctx);
    // a2b and by_amount_in = false
    let swap_res = pool::swap_in_pool_test(
        &mut pool,
        true,
        false,
        min_sqrt_price(),
        4853499090,
        5000,
        0,
    );
    assert!(swap_res.amount_out() == 4653499090, 2);
    assert!(swap_res.ref_amount() == 0, 3);

    clock::destroy_for_testing(clk);
    transfer::public_share_object(pool);
}

#[test]
fun test_flash_swap_internal() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let mut pool = pool::new_pool_with_ticks<CoinA, CoinB>(&clk, &mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let coin_a = balance::create_for_testing<CoinA>(5000000);
    let coin_b = balance::zero<CoinB>();
    let (balance_a, balance_b, receipt) = pool::flash_swap_internal_test(
        &mut pool,
        &config,
        object::id_from_address(@101),
        0,
        true,
        true,
        5000000,
        min_sqrt_price(),
        &clk,
    );
    assert!(balance::value(&balance_a) == 0, 1);
    assert!(5000000 == receipt.swap_pay_amount(), 2);
    assert!(receipt.ref_fee_amount() == 0, 3);
    pool::repay_flash_swap(&config, &mut pool, coin_a, coin_b, receipt);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(pool);
    transfer::public_transfer(coin::from_balance(balance_a, &mut ctx), tx_context::sender(&ctx));
    transfer::public_transfer(coin::from_balance(balance_b, &mut ctx), tx_context::sender(&ctx));
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EAmountIncorrect)]
fun test_flash_swap_internal_failure_with_eamount_incorrect() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let mut pool = pool::new_pool_with_ticks<CoinA, CoinB>(&clk, &mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let coin_a = balance::create_for_testing<CoinA>(5000000);
    let coin_b = balance::zero<CoinB>();
    let (balance_a, balance_b, receipt) = pool::flash_swap_internal_test(
        &mut pool,
        &config,
        object::id_from_address(@101),
        0,
        true,
        true,
        0,
        min_sqrt_price(),
        &clk,
    );
    assert!(balance::value(&balance_a) == 0, 1);
    assert!(5000000 == receipt.swap_pay_amount(), 2);
    assert!(receipt.ref_fee_amount() == 0, 3);
    pool::repay_flash_swap(&config, &mut pool, coin_a, coin_b, receipt);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(pool);
    transfer::public_transfer(coin::from_balance(balance_a, &mut ctx), tx_context::sender(&ctx));
    transfer::public_transfer(coin::from_balance(balance_b, &mut ctx), tx_context::sender(&ctx));
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EWrongSqrtPriceLimit)]
fun test_flash_swap_internal_failure_with_ewrong_sqrt_price_limit() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let mut pool = pool::new_pool_with_ticks<CoinA, CoinB>(&clk, &mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let coin_a = balance::create_for_testing<CoinA>(5000000);
    let coin_b = balance::zero<CoinB>();
    let (balance_a, balance_b, receipt) = pool::flash_swap_internal_test(
        &mut pool,
        &config,
        object::id_from_address(@101),
        0,
        true,
        true,
        5000000,
        max_sqrt_price(),
        &clk,
    );
    assert!(balance::value(&balance_a) == 0, 1);
    assert!(5000000 == receipt.swap_pay_amount(), 2);
    assert!(receipt.ref_fee_amount() == 0, 3);
    pool::repay_flash_swap(&config, &mut pool, coin_a, coin_b, receipt);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(pool);
    transfer::public_transfer(coin::from_balance(balance_a, &mut ctx), tx_context::sender(&ctx));
    transfer::public_transfer(coin::from_balance(balance_b, &mut ctx), tx_context::sender(&ctx));
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EAmountOutIsZero)]
fun test_flash_swap_internal_failure_with_eamount_out_is_zero() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let mut pool = pool::new_pool_with_ticks<CoinA, CoinB>(&clk, &mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let coin_a = balance::create_for_testing<CoinA>(5000000);
    let coin_b = balance::zero<CoinB>();
    let (balance_a, balance_b, receipt) = pool::flash_swap_internal_test(
        &mut pool,
        &config,
        object::id_from_address(@101),
        0,
        true,
        true,
        5,
        min_sqrt_price(),
        &clk,
    );
    assert!(balance::value(&balance_a) == 0, 1);
    assert!(5000000 == receipt.swap_pay_amount(), 2);
    assert!(receipt.ref_fee_amount() == 0, 3);
    pool::repay_flash_swap(&config, &mut pool, coin_a, coin_b, receipt);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(pool);
    transfer::public_transfer(coin::from_balance(balance_a, &mut ctx), tx_context::sender(&ctx));
    transfer::public_transfer(coin::from_balance(balance_b, &mut ctx), tx_context::sender(&ctx));
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
}

#[test]
fun test_add_liquidity_internal() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    let mut pos = pool::open_position(&config, &mut pool, 0, 100, &mut ctx);
    let receipt = pool::add_liquidity_internal_test(&mut pool, &mut pos, true, 0, 1000000, true, 0);
    let (amount_a, amount_b) = receipt.add_liquidity_pay_amount();
    assert!(amount_a == 1000000, 1);
    let coin_a = balance::create_for_testing<CoinA>(amount_a);
    let coin_b = balance::create_for_testing<CoinB>(amount_b);
    pool::repay_add_liquidity(&config, &mut pool, coin_a, coin_b, receipt);
    let (balance_a, balance_b) = pool::balances(&pool);
    assert!(balance::value(balance_a) == 1000000, 2);
    assert!(balance::value(balance_b) == amount_b, 3);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EAmountIncorrect)]
fun test_add_liquidity_internal_failure_with_eamount_incorrect() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    let mut pos = pool::open_position(&config, &mut pool, 0, 100, &mut ctx);
    let receipt = pool::add_liquidity_internal_test(&mut pool, &mut pos, true, 0, 1000000, true, 0);
    let (amount_a, amount_b) = receipt.add_liquidity_pay_amount();
    assert!(amount_a == 1000000, 1);
    let coin_a = balance::create_for_testing<CoinA>(amount_a - 1);
    let coin_b = balance::create_for_testing<CoinB>(amount_b);
    pool::repay_add_liquidity(&config, &mut pool, coin_a, coin_b, receipt);
    let (balance_a, balance_b) = pool::balances(&pool);
    assert!(balance::value(balance_a) == 1000000, 2);
    assert!(balance::value(balance_b) == amount_b, 3);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
}

#[test]
fun test_add_liquidity_internal_by_liquidity() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    let mut pos = pool::open_position(&config, &mut pool, 0, 100, &mut ctx);
    let receipt = pool::add_liquidity_internal_test(
        &mut pool,
        &mut pos,
        false,
        2 << 60 - 1,
        0,
        true,
        0,
    );
    let (amount_a, amount_b) = receipt.add_liquidity_pay_amount();
    let coin_a = balance::create_for_testing<CoinA>(amount_a);
    let coin_b = balance::create_for_testing<CoinB>(amount_b);
    pool::repay_add_liquidity(&config, &mut pool, coin_a, coin_b, receipt);
    let (balance_a, balance_b) = pool::balances(&pool);
    assert!(balance::value(balance_a) == amount_a, 2);
    assert!(balance::value(balance_b) == amount_b, 3);
    assert!(pool.liquidity() == (2 << 60 - 1), 4);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolIdIsError)]
fun test_add_liquidity_internal_failure_epool_id_is_error() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    let mut pool_2 = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    let mut pos = pool::open_position(&config, &mut pool, 0, 100, &mut ctx);
    let receipt = pool::add_liquidity_internal_test(
        &mut pool,
        &mut pos,
        false,
        2 << 60 - 1,
        0,
        true,
        0,
    );
    let (amount_a, amount_b) = receipt.add_liquidity_pay_amount();
    let coin_a = balance::create_for_testing<CoinA>(amount_a);
    let coin_b = balance::create_for_testing<CoinB>(amount_b);
    pool::repay_add_liquidity(&config, &mut pool_2, coin_a, coin_b, receipt);
    let (balance_a, balance_b) = pool::balances(&pool_2);
    assert!(balance::value(balance_a) == amount_a, 2);
    assert!(balance::value(balance_b) == amount_b, 3);
    assert!(pool_2.liquidity() == (2 << 60 - 1), 4);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_share_object(pool_2);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
}

#[test]
fun test_remove_liquidity() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );

    let mut pos = pool::open_position(&config, &mut pool, 0, 100, &mut ctx);
    let receipt = pool::add_liquidity_internal_test(
        &mut pool,
        &mut pos,
        false,
        2 << 56,
        0,
        true,
        0,
    );
    let (amount_a, amount_b) = receipt.add_liquidity_pay_amount();
    let coin_a = balance::create_for_testing<CoinA>(amount_a);
    let coin_b = balance::create_for_testing<CoinB>(amount_b);
    pool::repay_add_liquidity(&config, &mut pool, coin_a, coin_b, receipt);
    let (balance_a, balance_b) = pool::balances(&pool);
    assert!(balance::value(balance_a) == amount_a, 2);
    assert!(balance::value(balance_b) == amount_b, 3);
    assert!(pool.liquidity() == (2 << 56), 4);

    let (balance_a, balance_b) = pool::remove_liquidity(
        &config,
        &mut pool,
        &mut pos,
        2 << 55,
        &clk,
    );
    assert!(pool.liquidity() == (2 << 55), 5);
    balance::destroy_for_testing(balance_a);
    balance::destroy_for_testing(balance_b);
    let (balance_a, balance_b) = pool::remove_liquidity(
        &config,
        &mut pool,
        &mut pos,
        2 << 55,
        &clk,
    );
    assert!(pool.liquidity() == 0, 6);
    balance::destroy_for_testing(balance_a);
    balance::destroy_for_testing(balance_b);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::ELiquidityIsZero)]
fun test_remove_liquidity_failure_with_eliquidity_is_zero() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );

    let mut pos = pool::open_position(&config, &mut pool, 0, 100, &mut ctx);
    let (balance_a, balance_b) = pool::remove_liquidity(&config, &mut pool, &mut pos, 0, &clk);
    assert!(pool.liquidity() == (2 << 55), 5);
    balance::destroy_for_testing(balance_a);
    balance::destroy_for_testing(balance_b);

    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EDeprecatedFunction)]
fun test_pause_unpause() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    assert!(pool.is_pause() == false, 1);
    pool::pause(&config, &mut pool, &ctx);
    assert!(pool.is_pause(), 2);
    pool::unpause(&config, &mut pool, &ctx);
    assert!(pool.is_pause() == false, 3);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
}

#[test]
fun test_update_fee_rate() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    assert!(pool.fee_rate() == 2500, 1);
    pool::update_fee_rate(&config, &mut pool, 3000, &ctx);
    assert!(pool.fee_rate() == 3000, 2);
    pool::update_fee_rate(&config, &mut pool, 2000, &ctx);
    assert!(pool.fee_rate() == 2000, 3);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EInvalidFeeRate)]
fun test_update_fee_rate_failure_with_einvalid_fee_rate() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    assert!(pool.fee_rate() == 2500, 1);
    pool::update_fee_rate(&config, &mut pool, 3000, &ctx);
    assert!(pool.fee_rate() == 3000, 2);
    pool::update_fee_rate(&config, &mut pool, 200001, &ctx);
    assert!(pool.fee_rate() == 20000, 3);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
}

#[test]
fun test_update_position_url() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    pool::update_position_url(&config, &mut pool, string::utf8(b"www.cetus.io"), &ctx);
    assert!(pool.url() == string::utf8(b"www.cetus.io"), 1);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
}

#[test]
fun test_update_emission() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let mut vault = rewarder::new_vault_for_test(&mut ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    let balance_c = balance::create_for_testing<CoinC>(1000000000);
    rewarder::deposit_reward(&config, &mut vault, balance_c);
    pool::update_emission<CoinA, CoinB, CoinC>(&config, &mut pool, &vault, 1000, &clk, &ctx);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_share_object(vault);
}

#[test]
fun test_collect_protocol_fee() {
    let ctx = &mut tx_context::dummy();
    let clk = clock::create_for_testing(ctx);
    let (cap, config) = new_global_config_for_test(ctx, 5000);
    let mut pool = pool::new_pool_custom<CoinA, CoinB>(
        60,
        1715006487636306234,
        2500,
        0,
        0,
        110257286,
        791874,
        50214615874,
        533921553807,
        4701968956,
        &clk,
        ctx,
    );
    let (fee_a, fee_b) = pool::collect_protocol_fee(&config, &mut pool, ctx);
    assert!(balance::value(&fee_a) == 110257286, 1);
    assert!(balance::value(&fee_b) == 791874, 2);
    let (fee_a_amount, fee_b_amount) = pool::protocol_fee(&pool);
    assert!(fee_a_amount == 0, 3);
    assert!(fee_b_amount == 0, 4);
    balance::destroy_for_testing(fee_a);
    balance::destroy_for_testing(fee_b);
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
}

#[test]
fun test_get_position_infos() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = new_global_config_for_test(&mut ctx, 5000);
    let vault = rewarder::new_vault_for_test(&mut ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        &mut ctx,
    );
    let pos = pool::open_position(&config, &mut pool, 0, 100, &mut ctx);
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, &ctx);
    pool::calculate_and_update_rewards(&config, &mut pool, object::id(&pos), &clk);
    let (fee_a, fee_b) = pool::get_position_fee(&pool, object::id(&pos));
    assert!(fee_a == 0, 1);
    assert!(fee_b == 0, 2);
    pool::get_position_points(&pool, object::id(&pos));
    pool::get_position_rewards(&pool, object::id(&pos));
    // pool::get_position_reward<CoinA, CoinB, CoinC>(&pool, object::id(&pos));
    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    transfer::public_share_object(vault);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EMULTIPLICATION_OVERFLOW)]
fun test_checked_shlw_overflow() {
    let mut ctx = tx_context::dummy();
    let (cap, config) = new_global_config_for_test(&mut ctx, 2500);
    let clk = clock::create_for_testing(&mut ctx);
    let mut pool = pool::new_pool_custom<CoinA, CoinB>(
        60,
        17284667705865820439,
        2500,
        0,
        0,
        110257286,
        791874,
        7401931245199,
        40728637215896,
        34151818685042,
        &clk,
        &mut ctx,
    );

    let mut position_res10 = pool::open_position(
        &config,
        &mut pool,
        300000,
        300060,
        &mut ctx,
    );

    let receipt = pool::add_liquidity(
        &config,
        &mut pool,
        &mut position_res10,
        34673429775949185766360837292402478,
        &clk,
    );
    let (amount_a, amount_b) = receipt.add_liquidity_pay_amount();
    let balance_a = balance::create_for_testing<CoinA>(amount_a);
    let balance_b = balance::create_for_testing<CoinB>(amount_b);
    pool::repay_add_liquidity(&config, &mut pool, balance_a, balance_b, receipt);

    clock::destroy_for_testing(clk);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(position_res10, @4345);
}

#[test]
fun test_mint_protocol_fee_collect_cap() {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (cap, config) = new_global_config_for_test(ctx, 5000);
    pool::mint_protocol_fee_collect_cap(&cap, @0x1234, ctx);
    transfer::public_share_object(cap);
    transfer::public_share_object(config);
    test_scenario::next_tx(&mut scenerio, @0x1234);

    let cap = test_scenario::take_from_address<ProtocolFeeCollectCap>(&scenerio, @0x1234);
    transfer::public_transfer(cap, @0x1234);
    scenerio.end();
}

#[test]
fun test_collect_protocol_fee_with_cap() {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (cap, config) = new_global_config_for_test(ctx, 5000);
    let clk = clock::create_for_testing(ctx);
    let pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        ctx,
    );
    pool::mint_protocol_fee_collect_cap(&cap, @0x1234, ctx);
    transfer::public_transfer(cap, @0x1234);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);

    test_scenario::next_tx(&mut scenerio, @0x1234);

    let cap = test_scenario::take_from_address<ProtocolFeeCollectCap>(&scenerio, @0x1234);
    let mut config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    pool::update_protocol_fee(&mut pool, 1000, 1000);
    let admin_cap = test_scenario::take_from_address<AdminCap>(&scenerio, @0x1234);
    config::add_role(&admin_cap, &mut config, object::id_address(&cap), 2);
    let (fee_a, fee_b) = pool::collect_protocol_fee_with_cap(&mut pool, &config, &cap);
    assert_eq!(fee_a.value(), 1000);
    assert_eq!(fee_b.value(), 1000);
    fee_a.destroy_for_testing();
    fee_b.destroy_for_testing();
    let (fee_a_amount, fee_b_amount) = pool::protocol_fee(&pool);
    assert_eq!(fee_a_amount, 0);
    assert_eq!(fee_b_amount, 0);
    transfer::public_transfer(cap, @0x1234);
    transfer::public_transfer(admin_cap, @0x1234);
    test_scenario::return_shared(config);
    test_scenario::return_shared(pool);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
fun test_check_pool_status() {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (cap, config) = new_global_config_for_test(ctx, 5000);
    let clk = clock::create_for_testing(ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        ctx,
    );
    pool.pause_pool();
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(cap, @0x1234);

    test_scenario::next_tx(&mut scenerio, @0x1234);

    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    assert!(!pool.is_allow_add_liquidity(), 1);
    assert!(!pool.is_allow_remove_liquidity(), 2);
    assert!(!pool.is_allow_swap(), 3);
    assert!(!pool.is_allow_flash_loan(), 4);
    assert!(!pool.is_allow_collect_fee(), 1);
    assert!(!pool.is_allow_collect_reward(), 1);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
fun test_set_pool_status() {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (cap, mut config) = new_global_config_for_test(ctx, 5000);
    let clk = clock::create_for_testing(ctx);
    let pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(50)),
        2500,
        string::utf8(b""),
        1,
        &clk,
        ctx,
    );
    config::add_role(&cap, &mut config, object::id_address(&cap), 0);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(cap, @0x1234);

    test_scenario::next_tx(&mut scenerio, @0x1234);

    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    assert!(pool.is_allow_add_liquidity(), 1);
    assert!(pool.is_allow_remove_liquidity(), 2);
    assert!(pool.is_allow_swap(), 3);
    assert!(pool.is_allow_flash_loan(), 4);
    assert!(pool.is_allow_collect_fee(), 1);
    assert!(pool.is_allow_collect_reward(), 1);
    let ctx = scenerio.ctx();
    pool::set_pool_status(&config, &mut pool, true, true, true, true, true, true, ctx);
    assert!(!pool.is_allow_add_liquidity(), 1);
    assert!(!pool.is_allow_remove_liquidity(), 2);
    assert!(!pool.is_allow_swap(), 3);
    assert!(!pool.is_allow_flash_loan(), 4);
    assert!(!pool.is_allow_collect_fee(), 1);
    assert!(!pool.is_allow_collect_reward(), 1);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);

    test_scenario::next_tx(&mut scenerio, @0x1234);

    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let ctx = scenerio.ctx();
    pool::set_pool_status(&config, &mut pool, true, false, true, false, true, false, ctx);
    assert!(!pool.is_allow_add_liquidity(), 1);
    assert!(pool.is_allow_remove_liquidity(), 2);
    assert!(!pool.is_allow_swap(), 3);
    assert!(pool.is_allow_flash_loan(), 4);
    assert!(!pool.is_allow_collect_fee(), 1);
    assert!(pool.is_allow_collect_reward(), 1);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
public fun test_remove_liquidity_and_update_pool_liquidty() {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clock);
    let pool_current_liquidity = pool::liquidity(&pool);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(admin_cap, @0x1234);
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::next_tx(&mut scenerio, @0x1234);

    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let mut position_nft = test_scenario::take_from_address<Position>(&scenerio, @0x1234);
    let (balance_a, balance_b) = pool::remove_liquidity(
        &config,
        &mut pool,
        &mut position_nft,
        50000000,
        &clock,
    );
    let pool_after_remove_liquidity = pool::liquidity(&pool);
    assert_eq!(pool_after_remove_liquidity +  50000000, pool_current_liquidity);
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();

    transfer::public_transfer(position_nft, TEST_ADDR);
    test_scenario::return_shared(config);
    test_scenario::return_shared(pool);
    scenerio.end();
    clock.destroy_for_testing();
}

#[test]
public fun test_remove_liquidity_and_not_update_pool_liquidty() {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::from(1000), i32::from(2000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clock);
    let pool_current_liquidity = pool::liquidity(&pool);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(admin_cap, @0x1234);
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::next_tx(&mut scenerio, @0x1234);

    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let mut position_nft = test_scenario::take_from_address<Position>(&scenerio, @0x1234);
    let (balance_a, balance_b) = pool::remove_liquidity(
        &config,
        &mut pool,
        &mut position_nft,
        50000000,
        &clock,
    );
    let pool_after_remove_liquidity = pool::liquidity(&pool);
    assert_eq!(pool_after_remove_liquidity, pool_current_liquidity);
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();

    transfer::public_transfer(position_nft, TEST_ADDR);
    test_scenario::return_shared(config);
    test_scenario::return_shared(pool);
    scenerio.end();
    clock.destroy_for_testing();
}

#[test]
fun test_get_position_amounts() {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (clock, admin_cap, config) = init_test(ctx);

    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clock);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    transfer::public_transfer(admin_cap, @0x1234);
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::next_tx(&mut scenerio, @0x1234);

    let pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let position_nft = test_scenario::take_from_address<Position>(&scenerio, @0x1234);
    let (amount_a, amount_b) = pool::get_position_amounts_v2(&pool, object::id(&position_nft));
    let (amount_a_expected, amount_b_expected) = pool::get_amount_by_liquidity(
        tick_lower,
        tick_upper,
        pool::current_tick_index(&pool),
        pool::current_sqrt_price(&pool),
        position::liquidity(&position_nft),
        false,
    );
    assert_eq!(amount_a, amount_a_expected);
    assert_eq!(amount_b, amount_b_expected);
    test_scenario::return_shared(pool);
    transfer::public_transfer(position_nft, @0x1234);
    scenerio.end();
    clock.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_open_position_no_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, true, true, true, true, true, true, scenerio.ctx());
    let tick_lower = i32::neg_from(1000);
    let tick_upper = i32::from(1000);
    let position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        scenerio.ctx(),
    );
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_add_liquidity_no_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, true, true, true, true, true, true, scenerio.ctx());
    let mut position_nft = test_scenario::take_from_address<Position>(&scenerio, TEST_ADDR);
    let clk = clock::create_for_testing(scenerio.ctx());
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clk);
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_remove_liquidity_no_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let mut position_nft = test_scenario::take_from_address<Position>(&scenerio, TEST_ADDR);
    let clk = clock::create_for_testing(scenerio.ctx());
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clk);
    let (balance_a, balance_b) = pool::remove_liquidity(
        &config,
        &mut pool,
        &mut position_nft,
        50000000,
        &clk,
    );
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_collect_fee_no_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let position_nft = test_scenario::take_from_address<Position>(&scenerio, TEST_ADDR);
    let clk = clock::create_for_testing(scenerio.ctx());
    let (balance_a, balance_b) = pool::collect_fee(&config, &mut pool, &position_nft, true);
    balance_a.destroy_for_testing();
    balance_b.destroy_for_testing();
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_calculate_and_update_rewards_not_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let mut config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let cap = test_scenario::take_from_address<AdminCap>(&scenerio, TEST_ADDR);
    config::add_role(&cap, &mut config, TEST_ADDR, 4);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let position_nft = test_scenario::take_from_address<Position>(&scenerio, TEST_ADDR);
    let clk = clock::create_for_testing(scenerio.ctx());
    pool::initialize_rewarder<CoinA, CoinB, CoinC>(&config, &mut pool, scenerio.ctx());
    let rewards = pool::calculate_and_update_rewards(
        &config,
        &mut pool,
        object::id(&position_nft),
        &clk,
    );
    assert!(rewards == vector[0], 0);
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    test_scenario::return_shared(cap);
    scenerio.end();
    clk.destroy_for_testing()
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::ERewardNotExist)]
fun test_calculate_and_update_reward_not_exist() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let position_nft = test_scenario::take_from_address<Position>(&scenerio, TEST_ADDR);
    let clk = clock::create_for_testing(scenerio.ctx());
    pool::calculate_and_update_reward<CoinA, CoinB, CoinC>(
        &config,
        &mut pool,
        object::id(&position_nft),
        &clk,
    );
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_calculate_and_update_points_not_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let position_nft = test_scenario::take_from_address<Position>(&scenerio, TEST_ADDR);
    let clk = clock::create_for_testing(scenerio.ctx());
    pool::calculate_and_update_points(&config, &mut pool, object::id(&position_nft), &clk);
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_calculate_and_update_fee_not_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let position_nft = test_scenario::take_from_address<Position>(&scenerio, TEST_ADDR);
    let clk = clock::create_for_testing(scenerio.ctx());
    pool::calculate_and_update_fee(&config, &mut pool, object::id(&position_nft));
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
fun test_calculate_and_update_fee() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let clock = clock::create_for_testing(scenerio.ctx());
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    let mut position_nft = test_scenario::take_from_address<Position>(&scenerio, TEST_ADDR);
    pool::calculate_and_update_fee(&config, &mut pool, object::id(&position_nft));
    add_liquidity(&config, &mut pool, &mut position_nft, 1<<12, &clock);
    let (fee_a, fee_b) = pool::calculate_and_update_fee(
        &config,
        &mut pool,
        object::id(&position_nft),
    );
    assert!(fee_a == 0, 0);
    assert!(fee_b == 0, 0);
    transfer::public_transfer(position_nft, @0x1234);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clock.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_flash_swap_not_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let clk = clock::create_for_testing(scenerio.ctx());
    let (a, b, receipt) = pool::flash_swap(&config, &mut pool, true, true, 100000000, 0, &clk);
    pool::repay_flash_swap(&config, &mut pool, a, b, receipt);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_flash_swap_with_partner_not_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let clk = clock::create_for_testing(scenerio.ctx());
    let (cap, partner) = cetus_clmm::partner::create_partner_for_test(
        string::utf8(b"test"),
        10000-1,
        0,
        10000000000,
        &clk,
        scenerio.ctx(),
    );
    let (a, b, receipt) = pool::flash_swap_with_partner(
        &config,
        &mut pool,
        &partner,
        true,
        true,
        100000000,
        0,
        &clk,
    );
    pool::repay_flash_swap(&config, &mut pool, a, b, receipt);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    transfer::public_transfer(cap, @0x1234);
    transfer::public_transfer(partner, @0x1234);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_flash_loan_not_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let clk = clock::create_for_testing(scenerio.ctx());
    let (a, b, receipt) = pool::flash_loan(&config, &mut pool, true, 100000000);
    pool::repay_flash_loan(&config, &mut pool, a, b, receipt);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    scenerio.end();
    clk.destroy_for_testing();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EOperationNotPermitted)]
fun test_flash_loan_with_partner_not_permit() {
    let mut scenerio = test_scenario::begin(@0x1234);
    test_open_position();
    scenerio.next_tx(TEST_ADDR);
    let mut pool = test_scenario::take_shared<Pool<CoinA, CoinB>>(&scenerio);
    let config = test_scenario::take_shared<GlobalConfig>(&scenerio);
    pool::set_pool_status(&config, &mut pool, false, true, true, true, true, true, scenerio.ctx());
    let clk = clock::create_for_testing(scenerio.ctx());
    let (cap, partner) = cetus_clmm::partner::create_partner_for_test(
        string::utf8(b"test"),
        10000-1,
        0,
        10000000000,
        &clk,
        scenerio.ctx(),
    );
    let (a, b, receipt) = pool::flash_loan_with_partner(
        &config,
        &mut pool,
        &partner,
        true,
        100000000,
        &clk,
    );
    pool::repay_flash_loan(&config, &mut pool, a, b, receipt);
    test_scenario::return_shared(pool);
    test_scenario::return_shared(config);
    transfer::public_transfer(cap, @0x1234);
    transfer::public_transfer(partner, @0x1234);
    scenerio.end();
    clk.destroy_for_testing();
}

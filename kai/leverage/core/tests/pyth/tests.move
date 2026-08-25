#[test_only]
module kai_leverage::pyth_tests;

use deep::deep::DEEP;
use kai_leverage::pyth;
use lbtc::lbtc::LBTC;
use pyth::i64;
use pyth::price;
use pyth::price_feed;
use pyth::price_identifier;
use pyth::price_info::{Self, PriceInfoObject};
use std::type_name::{Self, TypeName};
use std::unit_test::destroy;
use suiusdt::usdt::USDT as SUIUSDT;
use usdc::usdc::USDC;
use usdy::usdy::USDY;
use wal::wal::WAL;
use wbtc::btc::BTC as WBTC;
use whusdce::coin::COIN as WHUSDCE;
use whusdte::coin::COIN as WHUSDTE;
use xbtc::xbtc::XBTC;
use sui::bcs;
use sui::clock;
use sui::sui::SUI;
use sui::vec_map;

public struct DUMMY_COIN has drop { }

#[test]
public fun test_decimals() {
    assert!(pyth::decimals(type_name::with_defining_ids<SUI>()) == 9);
    assert!(pyth::decimals(type_name::with_defining_ids<WHUSDCE>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<WHUSDTE>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<USDC>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<SUIUSDT>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<USDY>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<DEEP>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<WAL>()) == 9);
    assert!(pyth::decimals(type_name::with_defining_ids<LBTC>()) == 8);
    assert!(pyth::decimals(type_name::with_defining_ids<WBTC>()) == 8);
    assert!(pyth::decimals(type_name::with_defining_ids<XBTC>()) == 8);
}

#[test, expected_failure(abort_code = pyth::EUnsupportedCoinType)]
fun test_decimals_aborts_when_unsupported_coin_type() {
    pyth::decimals(type_name::with_defining_ids<DUMMY_COIN>());
}

/// Build a price info object carrying `timestamp_sec`, independently of any
/// clock, so the gap between price time and clock snapshot can be set exactly.
fun create_pio_at(timestamp_sec: u64, ctx: &mut TxContext): PriceInfoObject {
    let identifier = price_identifier::from_byte_vec(
        bcs::to_bytes(&tx_context::fresh_object_address(ctx)),
    );
    let price = price::new(
        i64::new(3_50 * 10_u64.pow(6), false),
        0, // conf
        i64::new(8, true), // expo
        timestamp_sec,
    );
    let price_feed = price_feed::new(identifier, price, price);
    price_info::new_price_info_object_for_testing(
        price_info::new_price_info(timestamp_sec, timestamp_sec, price_feed),
        ctx,
    )
}

fun allowlist_for(pio: &PriceInfoObject): vec_map::VecMap<TypeName, ID> {
    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(pio));
    allowlist
}

#[test]
fun add_computes_age_for_past_price() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000005000);

    let pio = create_pio_at(1755000000, &mut ctx);

    let mut info = pyth::create(&clock);
    info.add(&pio);

    let validated = info.validate(60, &allowlist_for(&pio));
    assert!(validated.max_age_secs() == 5);

    destroy(clock);
    destroy(pio);
}

#[test]
fun add_accepts_price_slightly_ahead_of_clock() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // the price is published one second ahead of the clock snapshot -- what
    // happens when a freshly pushed price is read during simulation, where
    // `Clock` trails wall time by the node's execution lag
    let pio = create_pio_at(1755000001, &mut ctx);

    let mut info = pyth::create(&clock);
    info.add(&pio);

    let validated = info.validate(60, &allowlist_for(&pio));

    // a price ahead of the clock is not stale -- age clamps to zero
    assert!(validated.max_age_secs() == 0);

    destroy(clock);
    destroy(pio);
}

#[test]
fun add_accepts_price_at_max_future_skew() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // exactly MAX_FUTURE_SKEW_SECS ahead of the snapshot -- the bound is inclusive
    let pio = create_pio_at(1755000060, &mut ctx);

    let mut info = pyth::create(&clock);
    info.add(&pio);

    let validated = info.validate(60, &allowlist_for(&pio));
    assert!(validated.max_age_secs() == 0);

    destroy(clock);
    destroy(pio);
}

#[test, expected_failure(abort_code = pyth::EPriceTimestampInFuture)]
fun add_aborts_when_price_too_far_in_future() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // one second past MAX_FUTURE_SKEW_SECS -- no longer plausible skew
    let pio = create_pio_at(1755000061, &mut ctx);

    let mut info = pyth::create(&clock);
    info.add(&pio);

    abort 0
}

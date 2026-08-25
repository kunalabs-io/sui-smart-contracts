// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module kai_leverage::oracle_price_tests;

use kai_leverage::coin_registry_test_util;
use kai_leverage::oracle_price;
use kai_leverage::pyth_test_util;
use pyth_pro::i64;
use std::type_name::{Self, TypeName};
use std::unit_test::destroy;
use sui::clock;
use sui::sui::SUI;
use sui::vec_map;
use usdc::usdc::USDC;

#[test]
fun add_pyth_pro_and_validate_happy_path() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // $3.50 and $1.00, expo -8, conf 0, ema = spot
    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);
    let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(1_00, &clock, &mut ctx);

    let mut registry = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry,
        9,
        &mut ctx,
    );
    let usdc_currency = coin_registry_test_util::create_currency_for_testing<USDC>(
        &mut registry,
        6,
        &mut ctx,
    );

    let mut price_info = oracle_price::create(&clock);
    price_info.add_pyth_pro(&sui_pio);
    price_info.add_pyth_pro(&usdc_pio);
    price_info.add_currency(&sui_currency);
    price_info.add_currency(&usdc_currency);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));
    allowlist.insert(type_name::with_defining_ids<USDC>(), object::id(&usdc_pio));

    let validated = price_info.validate(60, &allowlist);

    // both feeds are fresh at collection creation time
    assert!(validated.max_age_secs() == 0);

    // registry-sourced decimals are carried into the validated set
    assert!(validated.decimals(type_name::with_defining_ids<SUI>()) == 9);
    assert!(validated.decimals(type_name::with_defining_ids<USDC>()) == 6);

    let sui_spot = validated.get_price(type_name::with_defining_ids<SUI>());
    assert!(sui_spot.quote_price() == 3_50 * 10_u64.pow(6));
    assert!(sui_spot.quote_expo_neg() == 8);
    assert!(sui_spot.quote_conf() == option::some(0));

    let sui_smoothed = validated.get_smoothed_price(type_name::with_defining_ids<SUI>());
    assert!(sui_smoothed.quote_price() == 3_50 * 10_u64.pow(6));
    assert!(sui_smoothed.quote_expo_neg() == 8);

    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
    destroy(registry);
    destroy(sui_currency);
    destroy(usdc_currency);
}

#[test, expected_failure(abort_code = oracle_price::EStalePrice)]
fun validate_aborts_when_price_stale() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);

    // collection is created 61 seconds after the price was published
    clock.set_for_testing(1755000061000);
    let mut price_info = oracle_price::create(&clock);
    price_info.add_pyth_pro(&sui_pio);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));

    price_info.validate(60, &allowlist);

    abort 0
}

#[test]
fun validate_accepts_price_slightly_ahead_of_clock() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    let mut registry = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry,
        9,
        &mut ctx,
    );

    // the collection snapshots the clock first, then a price published one
    // second later joins the same transaction -- what happens when a freshly
    // pushed price is read during simulation, where `Clock` trails wall time
    // by the node's execution lag
    let mut price_info = oracle_price::create(&clock);
    clock.set_for_testing(1755000001000);
    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);

    price_info.add_pyth_pro(&sui_pio);
    price_info.add_currency(&sui_currency);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));

    let validated = price_info.validate(60, &allowlist);

    // a price ahead of the snapshot is not stale -- age clamps to zero
    assert!(validated.max_age_secs() == 0);

    destroy(clock);
    destroy(sui_pio);
    destroy(registry);
    destroy(sui_currency);
}

#[test]
fun validate_accepts_price_at_max_future_skew() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    let mut registry = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry,
        9,
        &mut ctx,
    );

    // exactly MAX_FUTURE_SKEW_SECS ahead of the snapshot -- the bound is inclusive
    let mut price_info = oracle_price::create(&clock);
    clock.set_for_testing(1755000060000);
    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);

    price_info.add_pyth_pro(&sui_pio);
    price_info.add_currency(&sui_currency);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));

    let validated = price_info.validate(60, &allowlist);
    assert!(validated.max_age_secs() == 0);

    destroy(clock);
    destroy(sui_pio);
    destroy(registry);
    destroy(sui_currency);
}

#[test, expected_failure(abort_code = oracle_price::EPriceTimestampInFuture)]
fun validate_aborts_when_price_too_far_in_future() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // one second past MAX_FUTURE_SKEW_SECS -- no longer plausible skew
    let mut price_info = oracle_price::create(&clock);
    clock.set_for_testing(1755000061000);
    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);

    price_info.add_pyth_pro(&sui_pio);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));

    price_info.validate(60, &allowlist);

    abort 0
}

#[test, expected_failure(abort_code = oracle_price::EPriceObjectMissing)]
fun validate_aborts_when_allowlisted_price_object_absent() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);
    let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(1_00, &clock, &mut ctx);

    let mut registry = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry,
        9,
        &mut ctx,
    );
    let usdc_currency = coin_registry_test_util::create_currency_for_testing<USDC>(
        &mut registry,
        6,
        &mut ctx,
    );

    // usdc_pio is allowlisted but never added to the collection
    let mut price_info = oracle_price::create(&clock);
    price_info.add_pyth_pro(&sui_pio);
    price_info.add_currency(&sui_currency);
    price_info.add_currency(&usdc_currency);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));
    allowlist.insert(type_name::with_defining_ids<USDC>(), object::id(&usdc_pio));

    price_info.validate(60, &allowlist);

    abort 0
}


#[test]
fun div_price_numeric_x128_matches_hand_computed_value() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // SUI = $3.50 (9 decimals), USDC = $1.00 (6 decimals); distinct EMA for SUI
    let mut sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
        3_50,
        &clock,
        &mut ctx,
    );
    // spot $3.50, EMA $3.40, expo -8
    pyth_test_util::update_pyth_pio_price(
        &mut sui_pio,
        i64::new(350_000_000, false),
        i64::new(340_000_000, false),
        &clock,
    );
    let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(1_00, &clock, &mut ctx);

    let mut registry = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry,
        9,
        &mut ctx,
    );
    let usdc_currency = coin_registry_test_util::create_currency_for_testing<USDC>(
        &mut registry,
        6,
        &mut ctx,
    );

    let mut price_info = oracle_price::create(&clock);
    price_info.add_pyth_pro(&sui_pio);
    price_info.add_pyth_pro(&usdc_pio);
    price_info.add_currency(&sui_currency);
    price_info.add_currency(&usdc_currency);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));
    allowlist.insert(type_name::with_defining_ids<USDC>(), object::id(&usdc_pio));

    let validated = price_info.validate(60, &allowlist);

    // price = Y / X = (3.5e8 * 2^128) / (1e8 * 10^(8+9-8-6))
    //       = 0.0035 * 2^128 = 1190988284223284622121811126011188740 (truncated)
    let p_x128 = validated.div_price_numeric_x128(
        type_name::with_defining_ids<SUI>(),
        type_name::with_defining_ids<USDC>(),
    );
    assert!(p_x128 == 1190988284223284622121811126011188740);

    // smoothed variant uses the EMA: 0.0034 * 2^128 (truncated)
    let p_smoothed_x128 = validated.div_smoothed_price_numeric_x128(
        type_name::with_defining_ids<SUI>(),
        type_name::with_defining_ids<USDC>(),
    );
    assert!(p_smoothed_x128 == 1156960047531190775775473665268011918);

    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
    destroy(registry);
    destroy(sui_currency);
    destroy(usdc_currency);
}

#[test, expected_failure(abort_code = oracle_price::EDecimalsMissing)]
fun validate_aborts_when_decimals_missing_for_allowlisted_coin() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);
    let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(1_00, &clock, &mut ctx);

    let mut registry = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry,
        9,
        &mut ctx,
    );

    // both prices are present but USDC has no registry decimals evidence
    let mut price_info = oracle_price::create(&clock);
    price_info.add_pyth_pro(&sui_pio);
    price_info.add_pyth_pro(&usdc_pio);
    price_info.add_currency(&sui_currency);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));
    allowlist.insert(type_name::with_defining_ids<USDC>(), object::id(&usdc_pio));

    price_info.validate(60, &allowlist);

    abort 0
}

#[test]
fun add_currency_is_idempotent() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);

    // two registries so that two `Currency<SUI>` objects with different
    // decimals can exist (impossible on-chain — the registry enforces
    // uniqueness — but it makes the first-write-wins behavior observable)
    let mut registry_a = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let mut registry_b = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry_a,
        9,
        &mut ctx,
    );
    let bogus_sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry_b,
        5,
        &mut ctx,
    );

    let mut price_info = oracle_price::create(&clock);
    price_info.add_pyth_pro(&sui_pio);
    price_info.add_currency(&sui_currency);
    // second add for the same coin type is a no-op
    price_info.add_currency(&bogus_sui_currency);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));

    let validated = price_info.validate(60, &allowlist);
    assert!(validated.decimals(type_name::with_defining_ids<SUI>()) == 9);

    destroy(clock);
    destroy(sui_pio);
    destroy(registry_a);
    destroy(registry_b);
    destroy(sui_currency);
    destroy(bogus_sui_currency);
}

#[test]
fun div_price_uses_registry_sourced_decimals() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // same prices as `div_price_numeric_x128_matches_hand_computed_value`
    // but with swapped decimals (SUI 6, USDC 9) — the result must scale by
    // 10^(9-6) squared relative to the canonical value, proving the math
    // reads the registry evidence and not a hardcoded table
    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(3_50, &clock, &mut ctx);
    let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(1_00, &clock, &mut ctx);

    let mut registry = coin_registry_test_util::create_registry_for_testing(&mut ctx);
    let sui_currency = coin_registry_test_util::create_currency_for_testing<SUI>(
        &mut registry,
        6,
        &mut ctx,
    );
    let usdc_currency = coin_registry_test_util::create_currency_for_testing<USDC>(
        &mut registry,
        9,
        &mut ctx,
    );

    let mut price_info = oracle_price::create(&clock);
    price_info.add_pyth_pro(&sui_pio);
    price_info.add_pyth_pro(&usdc_pio);
    price_info.add_currency(&sui_currency);
    price_info.add_currency(&usdc_currency);

    let mut allowlist = vec_map::empty<TypeName, ID>();
    allowlist.insert(type_name::with_defining_ids<SUI>(), object::id(&sui_pio));
    allowlist.insert(type_name::with_defining_ids<USDC>(), object::id(&usdc_pio));

    let validated = price_info.validate(60, &allowlist);

    // price = Y / X = (3.5e8 * 10^(8+9-8-6) * 2^128) / 1e8 = 3500 * 2^128
    let p_x128 = validated.div_price_numeric_x128(
        type_name::with_defining_ids<SUI>(),
        type_name::with_defining_ids<USDC>(),
    );
    assert!(p_x128 == 3500 * (1u256 << 128));

    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
    destroy(registry);
    destroy(sui_currency);
    destroy(usdc_currency);
}

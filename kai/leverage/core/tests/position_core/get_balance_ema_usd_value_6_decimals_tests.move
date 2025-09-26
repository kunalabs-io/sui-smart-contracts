#[test_only]
module kai_leverage::get_balance_ema_usd_value_6_decimals_tests;

use kai_leverage::position_core_clmm as core;
use kai_leverage::pyth::{Self, ValidatedPythPriceInfo};
use kai_leverage::pyth_test_util;
use pyth::price_info::PriceInfoObject;
use std::type_name::{Self, TypeName};
use sui::balance;
use sui::clock::{Self, Clock};
use sui::sui::SUI;
use sui::test_utils::destroy;
use sui::vec_map;
use usdc::usdc::USDC;

// Helper function to create ValidatedPythPriceInfo for testing
fun create_validated_pyth_price_info_for_testing(
    sui_pio: &PriceInfoObject,
    usdc_pio: &PriceInfoObject,
    clock: &Clock,
): ValidatedPythPriceInfo {
    let mut price_info = pyth::create(clock);
    price_info.add(sui_pio);
    price_info.add(usdc_pio);

    // Create allowlist
    let mut allowlist = vec_map::empty<TypeName, ID>();
    vec_map::insert(&mut allowlist, type_name::with_defining_ids<SUI>(), object::id(sui_pio));
    vec_map::insert(&mut allowlist, type_name::with_defining_ids<USDC>(), object::id(usdc_pio));

    // Validate the price info
    pyth::validate(&price_info, 3600, &allowlist) // 1 hour max age
}

#[test]
fun test_get_balance_ema_usd_value_6_decimals_sui() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // Create price info objects
    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
        3_50, // $3.50
        &clock,
        &mut ctx,
    );
    let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
        1_00, // $1.00
        &clock,
        &mut ctx,
    );

    // Create ValidatedPythPriceInfo
    let price_info = create_validated_pyth_price_info_for_testing(&sui_pio, &usdc_pio, &clock);

    // Test 1 SUI (9 decimals) = 1_000000000
    let balance_1_sui = balance::create_for_testing(1_000000000);
    let usd_value_1_sui = core::get_balance_ema_usd_value_6_decimals<SUI>(
        &balance_1_sui,
        &price_info,
        false, // round_up = false
    );
    // Expected: 1 SUI * $3.50 = $3.50 = 3500000 (6 decimals)
    assert!(usd_value_1_sui == 3500000);

    // Test 10 SUI
    let balance_10_sui = balance::create_for_testing(10_000000000);
    let usd_value_10_sui = core::get_balance_ema_usd_value_6_decimals<SUI>(
        &balance_10_sui,
        &price_info,
        false,
    );
    // Expected: 10 SUI * $3.50 = $35.00 = 35000000 (6 decimals)
    assert!(usd_value_10_sui == 35000000);

    // Test 0.5 SUI
    let balance_half_sui = balance::create_for_testing(500000000); // 0.5 SUI
    let usd_value_half_sui = core::get_balance_ema_usd_value_6_decimals<SUI>(
        &balance_half_sui,
        &price_info,
        false,
    );
    // Expected: 0.5 SUI * $3.50 = $1.75 = 1750000 (6 decimals)
    assert!(usd_value_half_sui == 1750000);

    // Test with round_up = true
    let balance_round_up = balance::create_for_testing(333333333); // 0.333333333 SUI
    let usd_value_round_up = core::get_balance_ema_usd_value_6_decimals<SUI>(
        &balance_round_up,
        &price_info,
        true, // round_up = true
    );
    // Expected: 0.333333333 SUI * $3.50 = $1.166666666... = 1166667 (6 decimals, rounded up)
    assert!(usd_value_round_up == 1166667);

    destroy(balance_1_sui);
    destroy(balance_10_sui);
    destroy(balance_half_sui);
    destroy(balance_round_up);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
}

#[test]
fun test_get_balance_ema_usd_value_6_decimals_usdc() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // Create price info objects
    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
        3_50, // $3.50
        &clock,
        &mut ctx,
    );
    let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
        1_00, // $1.00
        &clock,
        &mut ctx,
    );

    // Create ValidatedPythPriceInfo
    let price_info = create_validated_pyth_price_info_for_testing(&sui_pio, &usdc_pio, &clock);

    // Test 1 USDC (6 decimals) = 1_000000
    let balance_1_usdc = balance::create_for_testing(1_000000);
    let usd_value_1_usdc = core::get_balance_ema_usd_value_6_decimals<USDC>(
        &balance_1_usdc,
        &price_info,
        false, // round_up = false
    );
    // Expected: 1 USDC * $1.00 = $1.00 = 1000000 (6 decimals)
    assert!(usd_value_1_usdc == 1000000);

    // Test 100 USDC
    let balance_100_usdc = balance::create_for_testing(100_000000);
    let usd_value_100_usdc = core::get_balance_ema_usd_value_6_decimals<USDC>(
        &balance_100_usdc,
        &price_info,
        false,
    );
    // Expected: 100 USDC * $1.00 = $100.00 = 100000000 (6 decimals)
    assert!(usd_value_100_usdc == 100000000);

    // Test 0.5 USDC
    let balance_half_usdc = balance::create_for_testing(500000); // 0.5 USDC
    let usd_value_half_usdc = core::get_balance_ema_usd_value_6_decimals<USDC>(
        &balance_half_usdc,
        &price_info,
        false,
    );
    // Expected: 0.5 USDC * $1.00 = $0.50 = 500000 (6 decimals)
    assert!(usd_value_half_usdc == 500000);

    // Test zero balance
    let balance_zero = balance::create_for_testing(0);
    let usd_value_zero = core::get_balance_ema_usd_value_6_decimals<USDC>(
        &balance_zero,
        &price_info,
        false,
    );
    // Expected: 0 USDC * $1.00 = $0.00 = 0 (6 decimals)
    assert!(usd_value_zero == 0);

    destroy(balance_1_usdc);
    destroy(balance_100_usdc);
    destroy(balance_half_usdc);
    destroy(balance_zero);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
}

#[test]
fun test_get_balance_ema_usd_value_6_decimals_round_up() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock.set_for_testing(1755000000000);

    // Create price info objects
    let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
        3_50, // $3.50
        &clock,
        &mut ctx,
    );
    let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
        1_00, // $1.00
        &clock,
        &mut ctx,
    );

    // Create ValidatedPythPriceInfo
    let price_info = create_validated_pyth_price_info_for_testing(&sui_pio, &usdc_pio, &clock);

    // Test with amount that results in fractional USD value
    let balance_fractional = balance::create_for_testing(333333333); // 0.333333333 SUI
    let usd_value_no_round = core::get_balance_ema_usd_value_6_decimals<SUI>(
        &balance_fractional,
        &price_info,
        false, // round_up = false
    );
    let usd_value_round_up = core::get_balance_ema_usd_value_6_decimals<SUI>(
        &balance_fractional,
        &price_info,
        true, // round_up = true
    );

    assert!(usd_value_round_up > usd_value_no_round);
    assert!(usd_value_round_up - usd_value_no_round == 1);

    // Test with exact amount that doesn't need rounding
    let balance_exact = balance::create_for_testing(1_000000000); // 1 SUI
    let usd_value_exact_no_round = core::get_balance_ema_usd_value_6_decimals<SUI>(
        &balance_exact,
        &price_info,
        false,
    );
    let usd_value_exact_round_up = core::get_balance_ema_usd_value_6_decimals<SUI>(
        &balance_exact,
        &price_info,
        true,
    );

    // For exact amounts, round_up should not matter
    assert!(usd_value_exact_no_round == usd_value_exact_round_up);

    destroy(balance_fractional);
    destroy(balance_exact);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
}

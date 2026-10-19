#[test_only]
module cetus_clmm::clmm_math_tests;

use cetus_clmm::clmm_math::{
    get_liquidity_by_amount,
    get_amount_by_liquidity,
    get_delta_a,
    get_delta_b,
    compute_swap_step,
    get_liquidity_from_a,
    get_liquidity_from_b,
    get_next_sqrt_price_b_down,
    get_next_sqrt_price_a_up,
    get_delta_down_from_output,
    get_delta_up_from_input
};
use cetus_clmm::tick_math::{Self, get_sqrt_price_at_tick, tick_bound};
use integer_mate::i32;
use std::debug;
use cetus_clmm::clmm_math;

///                  current/ lower           upper
///                      |                     |
/// ----------------------------------------------------------------
///  is_fixed_a = true
#[test]
fun test_get_liquidity_from_a_11() {
    // current_tick == lower_tick
    // current_sqrt_proce == lower_price
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = current_tick_index;
    let upper_tick_index = i32::from_u32(20000);
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        true,
    );
    assert!(b == 0, 1);
    assert!(l > 0 && a == amount, 1);
    // current_tick == lower_tick
    // current_sqrt_proce > lower_price
    let current_sqrt_price = 42246388494348824448;
    let current_tick_index_2 = tick_math::get_tick_at_sqrt_price(current_sqrt_price);
    assert!(i32::eq(current_tick_index_2, current_tick_index), 1);
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        true,
    );
    debug::print(&b);
    assert!(b > 0, 1);
    assert!(l > 0 && a == amount, 1);
}

///                 current/ lower            upper
///                      |                     |
/// ----------------------------------------------------------------
/// is_fixed_a = false
#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EINVALID_FIXED_TOKEN_TYPE)]
fun test_get_liquidity_from_a_121() {
    // current_tick == lower_tick
    // current_sqrt_proce == lower_price
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = current_tick_index;
    let upper_tick_index = i32::from_u32(20000);
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        false,
    );
    assert!(b == 0, 1);
    assert!(l > 0 && a == amount, 1);
}

///                 current/ lower            upper
///                      |                     |
/// ----------------------------------------------------------------
/// is_fixed_a = false
#[test]
fun test_get_liquidity_from_a_122() {
    // current_tick == lower_tick
    // current_sqrt_proce > lower_price
    let upper_tick_index = i32::from_u32(20000);
    let current_sqrt_price = 42246388494348824448;
    let amount = 1000000000000;
    let current_tick_index = tick_math::get_tick_at_sqrt_price(current_sqrt_price);
    let lower_tick_index = current_tick_index;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        false,
    );
    debug::print(&b);
    assert!(b == amount, 1);
    assert!(l > 0 && a > 0, 1);
}

///                 current   lower            upper
///                      |     |                |
/// ----------------------------------------------------------------
/// is_fixed_a = true
#[test]
fun test_get_liquidity_from_a_21() {
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = i32::add(current_tick_index, i32::from(100));
    let upper_tick_index = i32::from_u32(20000);
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        true,
    );
    assert!(b == 0, 1);
    assert!(l > 0 && a == amount, 1);
}

///                 current   lower            upper
///                      |     |                |
/// ----------------------------------------------------------------
/// is_fixed_a = false
#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EINVALID_FIXED_TOKEN_TYPE)]
fun test_get_liquidity_from_a_22() {
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = i32::add(current_tick_index, i32::from(100));
    let upper_tick_index = i32::from_u32(20000);
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        false,
    );
    assert!(b == 0, 1);
    assert!(l > 0 && a == amount, 1);
}

///                    lower          upper/current
///                      |                |
/// ----------------------------------------------------------------
/// is_fixed_a = true
#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EINVALID_FIXED_TOKEN_TYPE)]
fun test_get_liquidity_from_a_31() {
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = i32::sub(current_tick_index, i32::from(1000));
    let upper_tick_index = current_tick_index;
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        true,
    );
    assert!(b == 0, 1);
    assert!(l > 0 && a == amount, 1);
}

///                    lower          upper/current
///                      |                |
/// ----------------------------------------------------------------
/// is_fixed_a = false
#[test]
fun test_get_liquidity_from_a_32() {
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = i32::sub(current_tick_index, i32::from(1000));
    let upper_tick_index = current_tick_index;
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        false,
    );
    assert!(b == amount, 1);
    assert!(l > 0 && a == 0, 1);
}

///                    lower          upper    current
///                      |                |      |
/// ----------------------------------------------------------------
/// is_fixed_a = true
#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EINVALID_FIXED_TOKEN_TYPE)]
fun test_get_liquidity_from_a_41() {
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = i32::sub(current_tick_index, i32::from(1000));
    let upper_tick_index = current_tick_index;
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (_, _, _) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        true,
    );
}

///                    lower          upper    current
///                      |                |      |
/// ----------------------------------------------------------------
/// is_fixed_a = false
#[test]
fun test_get_liquidity_from_a_42() {
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = i32::sub(current_tick_index, i32::from(1000));
    let upper_tick_index = current_tick_index;
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        false,
    );
    assert!(b == amount, 1);
    assert!(l > 0 && a == 0, 1);
}

///                    lower          current   upper
///                      |                |      |
/// ----------------------------------------------------------------
/// is_fixed_a = true
#[test]
fun test_get_liquidity_from_a_51() {
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = i32::sub(current_tick_index, i32::from(1000));
    let upper_tick_index = i32::add(current_tick_index, i32::from(2000));
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        true,
    );
    assert!(b > 0, 1);
    assert!(l > 0 && a == amount, 1);
}

///                    lower          current   upper
///                      |                |      |
/// ----------------------------------------------------------------
/// is_fixed_a = false
#[test]
fun test_get_liquidity_from_a_52() {
    let current_tick_index = i32::from_u32(16573);
    let lower_tick_index = i32::sub(current_tick_index, i32::from(1000));
    let upper_tick_index = i32::add(current_tick_index, i32::from(2000));
    let current_sqrt_price = tick_math::get_sqrt_price_at_tick(current_tick_index);
    let amount = 1000000000000;
    let (l, a, b) = get_liquidity_by_amount(
        lower_tick_index,
        upper_tick_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        false,
    );
    assert!(b == amount, 1);
    assert!(l > 0 && a > 0, 1);
}

#[test]
fun test_get_liquidity_from_a() {
    //18446744073709551616 19392480388906836277 1000000 20505166
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::from(0));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(1000));
    let amount_a = 1000000;
    assert!(get_liquidity_from_a(sqrt_price_0, sqrt_price_1, amount_a, false) == 20505166, 0);

    //11188795550323325955 30412779051191548722 1000000000 959569283
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10000));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(10000));
    let amount_a = 1000000000;
    assert!(get_liquidity_from_a(sqrt_price_0, sqrt_price_1, amount_a, false) == 959569283, 0);

    //18437523468038800957 18455969290605290427 300000000000 300014987250637
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(10));
    let amount_a = 300000000000;
    assert!(
        get_liquidity_from_a(sqrt_price_0, sqrt_price_1, amount_a, false) == 300014987250637,
        0,
    );

    // 18437523468038800957 19392480388906836277 300000000000 6089108304263
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(1000));
    let amount_a = 300000000000;
    assert!(get_liquidity_from_a(sqrt_price_0, sqrt_price_1, amount_a, false) == 6089108304263, 0);

    //18437523468038800957 18455969290605290427 999000000000000 999049907544623895
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(10));
    let amount_a = 999000000000000;
    assert!(
        get_liquidity_from_a(sqrt_price_0, sqrt_price_1, amount_a, false) == 999049907544623895,
        0,
    );

    //18437523468038800957 18455969290605290427 18446744073709551615 18447665626965832135371
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(10));
    let amount_a = 18446744073709551615;
    assert!(
        get_liquidity_from_a(sqrt_price_0, sqrt_price_1, amount_a, false) == 18447665626965832136299,
        0,
    );
}

#[test]
fun test_get_liquidity_from_b() {
    // 18446744073709551616 19392480388906836277 1000000 19505166
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::from(0));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(1000));
    let amount_b = 1000000;
    assert!(get_liquidity_from_b(sqrt_price_0, sqrt_price_1, amount_b, false) == 19505166, 0);

    // 11188795550323325955 30412779051191548722 1000000000 959569283
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10000));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(10000));
    let amount_b = 1000000000;
    assert!(get_liquidity_from_b(sqrt_price_0, sqrt_price_1, amount_b, false) == 959569283, 0);

    // 18437523468038800957 18455969290605290427 300000000000 300014987250637
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(10));
    let amount_b = 300000000000;
    assert!(
        get_liquidity_from_b(sqrt_price_0, sqrt_price_1, amount_b, false) == 300014987250637,
        0,
    );

    // 18437523468038800957 19392480388906836277 300000000000 5795050123394
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(1000));
    let amount_b = 300000000000;
    assert!(get_liquidity_from_b(sqrt_price_0, sqrt_price_1, amount_b, false) == 5795050123394, 0);

    // 18437523468038800957 19392480388906836277 18446744073709551615 356332688401932418314
    let sqrt_price_0 = tick_math::get_sqrt_price_at_tick(i32::neg_from(10));
    let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(i32::from(1000));
    let amount_b = 18446744073709551615;
    assert!(
        get_liquidity_from_b(sqrt_price_0, sqrt_price_1, amount_b, false) == 356332688401932418314,
        0,
    );
}

#[test]
fun test_get_delta_a() {
    assert!(get_delta_a(4u128 << 64, 2u128 << 64, 4, true) == 1, 0);
    assert!(get_delta_a(4u128 << 64, 2u128 << 64, 4, false) == 1, 0);

    assert!(get_delta_a(4 << 64, 4 << 64, 4, true) == 0, 0);
    assert!(get_delta_a(4 << 64, 4 << 64, 4, false) == 0, 0);
}

#[test]
fun test_get_delta_b() {
    assert!(get_delta_b(4u128 << 64, 2u128 << 64, 4, true) == 8, 0);
    assert!(get_delta_b(4u128 << 64, 2u128 << 64, 4, false) == 8, 0);

    assert!(get_delta_b(4 << 64, 4 << 64, 4, true) == 0, 0);
    assert!(get_delta_b(4 << 64, 4 << 64, 4, false) == 0, 0);
}

#[test]
fun test_get_next_price_a_up() {
    let (sqrt_price, liquidity, amount) = (10u128 << 64, 200u128 << 64, 10000000u64);
    let r1 = get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, true);
    let r2 = get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, false);
    assert!(184467440737090516161u128 == r1, 0);
    assert!(184467440737100516161u128 == r2, 0);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::ESUBTRACTION_UNDERFLOW)]
fun test_get_next_price_a_up_underflow() {
    let (sqrt_price, liquidity, amount) = (10u128 << 64, 200u128, 10000000u64);
    let r1 = get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, true);
    let r2 = get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, false);
    assert!(184467440737090516161u128 == r1, 0);
    assert!(184467440737100516161u128 == r2, 0);
}

#[test]
fun test_get_next_price_a_down() {
    let (sqrt_price, liquidity, amount, add) = (
        62058032627749460283664515388u128,
        56315830353026631512438212669420532741u128,
        10476203047244913035u64,
        true,
    );
    let r = get_next_sqrt_price_b_down(sqrt_price, liquidity, amount, add);
    assert!(62058032627749460283664515391u128 == r, 0);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::ESUBTRACTION_UNDERFLOW)]
fun test_get_next_price_a_down_underflow() {
    let (sqrt_price, liquidity, amount, add) = (4295048016, 563, 10476203047244913035u64, false);
    let r = get_next_sqrt_price_b_down(sqrt_price, liquidity, amount, add);
    assert!(62058032627749460283664515391u128 == r, 0);
}

#[test]
fun test_compute_swap_step() {
    let (current_sqrt_price, target_sqrt_price, liquidity, amount, fee_rate) = (
        1u128 << 64,
        2u128 << 64,
        1000u128 << 32,
        20000,
        1000u64,
    );
    let (amount_in, amount_out, next_sqrt_price, fee_amount) = compute_swap_step(
        current_sqrt_price,
        target_sqrt_price,
        liquidity,
        amount,
        fee_rate,
        false,
        false,
    );
    // 20001 20000 18446744159608897937 21
    assert!(amount_in == 20001, 0);
    assert!(amount_out == 20000, 0);
    assert!(next_sqrt_price == 18446744159608897937, 0);
    assert!(fee_amount == 21, 0);

    // 19980 19979 18446744159522998190 20
    let (amount_in, amount_out, next_sqrt_price, fee_amount) = compute_swap_step(
        current_sqrt_price,
        target_sqrt_price,
        liquidity,
        amount,
        fee_rate,
        false,
        true,
    );
    assert!(amount_in == 19980, 0);
    assert!(amount_out == 19979, 0);
    assert!(next_sqrt_price == 18446744159522998190, 0);
    assert!(fee_amount == 20, 0);
}

#[test]
fun test_get_amount_by_liquidity_with_little_liquidity() {
    let (amount_a, amount_b) = get_amount_by_liquidity(
        i32::neg_from(1),
        i32::from(1),
        i32::from(0),
        tick_math::get_sqrt_price_at_tick(i32::from(0)),
        1,
        true,
    );
    assert!(amount_a > 0 || amount_b > 0, 0);

    let (amount_a, amount_b) = get_amount_by_liquidity(
        i32::neg_from(1),
        i32::from(1),
        i32::from(200),
        tick_math::get_sqrt_price_at_tick(i32::from(200)),
        1,
        true,
    );
    assert!(amount_a > 0 || amount_b > 0, 0);

    let (amount_a, amount_b) = get_amount_by_liquidity(
        i32::neg_from(1),
        i32::from(1),
        i32::neg_from(200),
        tick_math::get_sqrt_price_at_tick(i32::neg_from(200)),
        1,
        true,
    );
    assert!(amount_a > 0 || amount_b > 0, 0);
}

#[test]
fun test_get_liquidity_by_amount_with_little_amount() {
    let (liquidity, amount_a, amount_b) = get_liquidity_by_amount(
        i32::neg_from(443636),
        i32::from(443636),
        i32::from(0),
        tick_math::get_sqrt_price_at_tick(i32::from(0)),
        1,
        true,
    );
    let (recv_amount_a, recv_amount_b) = get_amount_by_liquidity(
        i32::neg_from(443636),
        i32::from(443636),
        i32::from(0),
        tick_math::get_sqrt_price_at_tick(i32::from(0)),
        liquidity,
        false,
    );
    assert!(recv_amount_a <= amount_a, 0);
    assert!(recv_amount_b <= amount_b, 0);

    let (liquidity, amount_a, amount_b) = get_liquidity_by_amount(
        i32::neg_from(443636),
        i32::from(443636),
        i32::from(0),
        tick_math::get_sqrt_price_at_tick(i32::from(0)),
        1,
        false,
    );
    let (recv_amount_a, recv_amount_b) = get_amount_by_liquidity(
        i32::neg_from(443636),
        i32::from(443636),
        i32::from(0),
        tick_math::get_sqrt_price_at_tick(i32::from(0)),
        liquidity,
        false,
    );
    assert!(recv_amount_a <= amount_a, 0);
    assert!(recv_amount_b <= amount_b, 0);
}

#[test]
fun test_get_amount_by_liquidity_zero() {
    let (amount_a, amount_b) = get_amount_by_liquidity(
        i32::neg_from(1),
        i32::from(1),
        i32::from(0),
        tick_math::get_sqrt_price_at_tick(i32::from(0)),
        0,
        true,
    );
    assert!(amount_a == 0, 0);
    assert!(amount_b == 0, 0);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EINVALID_SQRT_PRICE_INPUT)]
fun test_compute_swap_step_sqrt_price_invalid() {
    let (current_sqrt_price, target_sqrt_price, liquidity, amount, fee_rate) = (
        1u128 << 64,
        2u128 << 64,
        1000u128 << 32,
        20000,
        1000u64,
    );
    compute_swap_step(
        current_sqrt_price,
        target_sqrt_price,
        liquidity,
        amount,
        fee_rate,
        true,
        false,
    );
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EAMOUNT_CAST_TO_U64_OVERFLOW)]
fun test_compute_swap_step_cast_to_u64_error() {
    let (current_sqrt_price, target_sqrt_price, liquidity, amount, fee_rate) = (
        get_sqrt_price_at_tick(i32::from(30000)),
        get_sqrt_price_at_tick(i32::neg_from(443636)),
        9381000597014909076792095726466300,
        18446744073709551614,
        0,
    );
    compute_swap_step(
        current_sqrt_price,
        target_sqrt_price,
        liquidity,
        amount,
        fee_rate,
        true,
        true,
    );
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EAMOUNT_CAST_TO_U64_OVERFLOW)]
fun test_compute_swap_step_cast_to_u64_error_2() {
    let (current_sqrt_price, target_sqrt_price, liquidity, amount, fee_rate) = (
        get_sqrt_price_at_tick(i32::neg_from(30000)),
        get_sqrt_price_at_tick(i32::neg_from(223636)),
        9381000597014909076792095726466300,
        18446744073709551614,
        0,
    );
    compute_swap_step(
        current_sqrt_price,
        target_sqrt_price,
        liquidity,
        amount,
        fee_rate,
        true,
        false,
    );
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EINVALID_SQRT_PRICE_INPUT)]
fun test_compute_swap_step_sqrt_price_invalid_2() {
    let (current_sqrt_price, target_sqrt_price, liquidity, amount, fee_rate) = (
        10u128 << 64,
        2u128 << 64,
        1000u128 << 32,
        20000,
        1000u64,
    );
    compute_swap_step(
        current_sqrt_price,
        target_sqrt_price,
        liquidity,
        amount,
        fee_rate,
        false,
        false,
    );
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EMULTIPLICATION_OVERFLOW)]
fun test_get_delta_down_from_output_overflow() {
    get_delta_down_from_output(
        get_sqrt_price_at_tick(i32::neg_from(tick_bound())),
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        9381000597014909076792095726466300,
        false,
    );
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EMULTIPLICATION_OVERFLOW)]
fun test_get_delta_up_from_input_overflow() {
    get_delta_up_from_input(
        get_sqrt_price_at_tick(i32::neg_from(tick_bound())),
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        9381000597014909076792095726466300,
        true,
    );
}

#[test]
fun test_get_delta_up_from_input_zero() {
    let amount = get_delta_up_from_input(
        get_sqrt_price_at_tick(i32::neg_from(tick_bound())),
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        0,
        true,
    );
    assert!(amount == 0, 0);
    let amount = get_delta_up_from_input(
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        93810005970149090767920957264663000,
        false,
    );
    assert!(amount == 0, 0);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EMULTIPLICATION_OVERFLOW)]
fun test_get_next_sqrt_price_a_up_overflow() {
    let (sqrt_price, liquidity, amount) = (
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        9381000597014909076792095726466300,
        10000000u64,
    );
    get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, true);
    get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, false);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::ESUBTRACTION_UNDERFLOW)]
fun test_get_next_sqrt_price_a_up_underflow() {
    let (sqrt_price, liquidity, amount) = (
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        9381000597014909076792,
        std::u64::max_value!() - 1000,
    );
    get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, true);
    get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, false);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::ETOKEN_AMOUNT_MAX_EXCEEDED)]
fun test_get_next_sqrt_price_a_up_token_amount_max_exceed() {
    let (sqrt_price, liquidity, amount) = (
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        9381000597014909076792,
        10000000,
    );
    get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, true);
    get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, false);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::ETOKEN_AMOUNT_MIN_SUBCEEDED)]
fun test_get_next_sqrt_price_a_up_token_amount_min_exceed() {
    let (sqrt_price, liquidity, amount) = (
        get_sqrt_price_at_tick(i32::neg_from(tick_bound())),
        93810005970,
        1000000000000000,
    );
    get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, true);
    get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, false);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::ETOKEN_AMOUNT_MAX_EXCEEDED)]
fun test_get_next_sqrt_price_b_down_token_amount_max_exceed() {
    let (sqrt_price, liquidity, amount) = (
        get_sqrt_price_at_tick(i32::from(tick_bound())),
        9381000597014909076792,
        10000000,
    );
    get_next_sqrt_price_b_down(sqrt_price, liquidity, amount, true);
    get_next_sqrt_price_b_down(sqrt_price, liquidity, amount, false);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::ETOKEN_AMOUNT_MIN_SUBCEEDED)]
fun test_get_next_sqrt_price_b_down_token_amount_min_exceed() {
    let (sqrt_price, liquidity, amount) = (
        get_sqrt_price_at_tick(i32::neg_from(200000)),
        93810005970,
        4261080,
    );
    get_next_sqrt_price_b_down(sqrt_price, liquidity, amount, true);
    get_next_sqrt_price_b_down(sqrt_price, liquidity, amount, false);
}

#[test]
fun test_get_liquidity_from_a_1() {
    let liquidity = clmm_math::get_liquidity_from_a(
        get_sqrt_price_at_tick(i32::from(0)),
        get_sqrt_price_at_tick(i32::from(100)),
        100000,
        true,
    );
    assert!(liquidity > 0, 0);
}

#[test]
fun test_get_liquidity_from_a_2() {
    let liquidity = clmm_math::get_liquidity_from_a(
        get_sqrt_price_at_tick(i32::from(100)),
        get_sqrt_price_at_tick(i32::from(0)),
        100000,
        true,
    );
    assert!(liquidity > 0, 0);
}

#[test]
fun test_get_liquidity_from_b_1() {
    let liquidity = clmm_math::get_liquidity_from_b(
        get_sqrt_price_at_tick(i32::from(0)),
        get_sqrt_price_at_tick(i32::from(100)),
        100000,
        true,
    );
    assert!(liquidity > 0, 0);
}

#[test]
fun test_get_liquidity_from_b_2() {
    let liquidity = clmm_math::get_liquidity_from_b(
        get_sqrt_price_at_tick(i32::from(100)),
        get_sqrt_price_at_tick(i32::from(0)),
        100000,
        true,
    );
    assert!(liquidity > 0, 0);
}
#[test_only]
module cetus_clmm::tick_math_tests;

use cetus_clmm::tick_math::{
    get_tick_at_sqrt_price,
    max_tick,
    min_tick,
    get_sqrt_price_at_tick,
    tick_bound,
    is_valid_index
};
use integer_mate::i32;

const MAX_SQRT_PRICE_X64: u128 = 79226673515401279992447579055;

const MIN_SQRT_PRICE_X64: u128 = 4295048016;

#[test]
fun test_get_sqrt_price_at_tick() {
    // min tick
    assert!(get_sqrt_price_at_tick(i32::neg_from(tick_bound())) == 4295048016u128, 2);
    // max tick
    assert!(
        get_sqrt_price_at_tick(i32::from(tick_bound())) == 79226673515401279992447579055u128,
        1,
    );
    assert!(get_sqrt_price_at_tick(i32::neg_from(435444u32)) == 6469134034u128, 3);
    assert!(get_sqrt_price_at_tick(i32::from(408332u32)) == 13561044167458152057771544136u128, 4);
}

#[test]
fun test_tick_swap_sqrt_price() {
    let mut t = i32::from(400800);
    while (i32::lte(t, i32::from(401200))) {
        let sqrt_price = get_sqrt_price_at_tick(t);
        let tick = get_tick_at_sqrt_price(sqrt_price);
        assert!(i32::eq(t, tick) == true, 0);
        t = i32::add(t, i32::from(1));
    }
}

#[test]
fun test_get_tick_at_sqrt_price_1() {
    assert!(i32::eq(get_tick_at_sqrt_price(6469134034u128), i32::neg_from(435444)) == true, 0);
    assert!(
        i32::eq(get_tick_at_sqrt_price(13561044167458152057771544136u128), i32::from(408332u32)) == true,
        0,
    );
}

#[test]
#[expected_failure]
fun test_get_sqrt_price_at_invalid_upper_tick() {
    get_sqrt_price_at_tick(i32::add(max_tick(), i32::from(1)));
}

#[test]
#[expected_failure]
fun test_get_sqrt_price_at_invalid_lower_tick() {
    get_sqrt_price_at_tick(i32::sub(min_tick(), i32::from(1)));
}

#[test]
#[expected_failure]
fun test_get_tick_at_invalid_lower_sqrt_price() {
    get_tick_at_sqrt_price(MAX_SQRT_PRICE_X64 + 1);
}

#[test]
#[expected_failure]
fun test_get_tick_at_invalid_upper_sqrt_price() {
    get_tick_at_sqrt_price(MIN_SQRT_PRICE_X64 - 1);
}

#[test]
fun test_is_valid_index() {
    assert!(is_valid_index(i32::from(0), 1), 0);
    assert!(is_valid_index(i32::from(1), 1), 1);
    assert!(is_valid_index(i32::from(2), 1), 2);
    assert!(!is_valid_index(i32::from(3), 2), 3);
    assert!(!is_valid_index(i32::from(448080), 2), 4);
    assert!(!is_valid_index(i32::neg_from(448080), 2), 4);
    assert!(is_valid_index(i32::from(443636), 2), 4);
    assert!(is_valid_index(i32::neg_from(443636), 2), 4);
     assert!(!is_valid_index(i32::from(443636), 10), 4);
    assert!(!is_valid_index(i32::neg_from(443636), 10), 4);
}

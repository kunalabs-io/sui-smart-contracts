module integer_library_specs::math_u128_specs;

use integer_library::math_u128::{
    wrapping_add,
    overflowing_add,
    wrapping_sub,
    overflowing_sub,
    wrapping_mul,
    overflowing_mul,
    full_mul,
    hi,
    lo,
    hi_u128,
    lo_u128,
    from_lo_hi,
    checked_div_round,
    max,
    min,
    add_check
};

#[spec_only]
use prover::prover::{ensures, asserts};

const TWO_POW_128: u256 = 0x100000000000000000000000000000000u256;

/*
 ✅ Computes `n1 + n2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_add)]
public fun wrapping_add_spec(n1: u128, n2: u128): u128 {
    let result = wrapping_add(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let sum_int = n1_int.add(n2_int);

    ensures(result == sum_int.to_u128());

    result
}

/*
 ✅ Computes `n1 + n2` with wrapping overflow and a boolean indicating overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = overflowing_add)]
public fun overflowing_add_spec(n1: u128, n2: u128): (u128, bool) {
    let (result, overflow) = overflowing_add(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let sum_int = n1_int.add(n2_int);

    ensures(result == sum_int.to_u128());
    // Check if overflow occurs
    ensures(overflow == sum_int.gt(std::u128::max_value!().to_int()));

    (result, overflow)
}

/*
 ✅ Computes `n1 - n2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_sub)]
public fun wrapping_sub_spec(n1: u128, n2: u128): u128 {
    let result = wrapping_sub(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let diff_int = n1_int.sub(n2_int);

    ensures(result == diff_int.to_u128());

    result
}

/*
 ✅ Computes `n1 - n2` with wrapping overflow and a boolean indicating overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = overflowing_sub)]
public fun overflowing_sub_spec(n1: u128, n2: u128): (u128, bool) {
    let (result, overflow) = overflowing_sub(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let diff_int = n1_int.sub(n2_int);

    ensures(result == diff_int.to_u128());
    // Overflow occurs when num1 < num2
    ensures(overflow == n1_int.lt(n2_int));

    (result, overflow)
}

/*
 ✅ Computes `n1 * n2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_mul)]
public fun wrapping_mul_spec(n1: u128, n2: u128): u128 {
    let result = wrapping_mul(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let product_int = n1_int.mul(n2_int);

    ensures(result == product_int.to_u128());

    result
}

/*
 ✅ Computes `n1 * n2` with wrapping overflow and a boolean indicating overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = overflowing_mul)]
public fun overflowing_mul_spec(n1: u128, n2: u128): (u128, bool) {
    let (result, overflow) = overflowing_mul(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let product_int = n1_int.mul(n2_int);

    ensures(result == product_int.to_u128());
    ensures(overflow == product_int.gt(std::u128::max_value!().to_int()));

    (result, overflow)
}

/*
 ✅ Computes the full 256-bit product of `n1 * n2` as two u128 values (lo, hi).
 ⏮️ The function does not abort.
*/
#[spec(prove, target = full_mul)]
public fun full_mul_spec(n1: u128, n2: u128): (u128, u128) {
    let (lo, hi) = full_mul(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let expected_int = n1_int.mul(n2_int);
    let actual_int = lo.to_int().add(hi.to_int().mul(TWO_POW_128.to_int()));

    ensures(actual_int == expected_int);

    (lo, hi)
}

/*
 ✅ Extracts the high 64 bits of a u128 value.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = hi)]
public fun hi_spec(n: u128): u64 {
    let n_int = n.to_int();
    let result = hi(n);
    let expected_result = n_int.div(1u64.to_int().shl(64u64.to_int()));
    ensures(result.to_int() == expected_result);
    result
}

/*
 ✅ Extracts the low 64 bits of a u128 value.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = lo)]
public fun lo_spec(n: u128): u64 {
    let n_int = n.to_int();
    let result = lo(n);
    let expected_result = n_int.mod(1u64.to_int().shl(64u64.to_int()));
    ensures(result.to_int() == expected_result);
    result
}

/*
 ✅ Extracts the high 64 bits of a u128 value as a u128.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = hi_u128)]
public fun hi_u128_spec(n: u128): u128 {
    let result = hi_u128(n);
    let n_int = n.to_int();
    let expected_result = n_int.div(1u64.to_int().shl(64u64.to_int()));
    ensures(result.to_int() == expected_result);
    result
}

/*
 ✅ Extracts the low 64 bits of a u128 value as a u128.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = lo_u128)]
public fun lo_u128_spec(n: u128): u128 {
    let result = lo_u128(n);
    let n_int = n.to_int();
    let expected_result = n_int.mod(1u64.to_int().shl(64u64.to_int()));
    ensures(result.to_int() == expected_result);
    result
}

/*
 ✅ Constructs a u128 from low and high u64 components.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = from_lo_hi)]
public fun from_lo_hi_spec(lo: u64, hi: u64): u128 {
    let result = from_lo_hi(lo, hi);
    let expected_result = hi.to_int().mul(1u64.to_int().shl(64u64.to_int())).add(lo.to_int());
    ensures(result.to_int() == expected_result);
    result
}

/*
 ✅ Computes `num / denom` with optional rounding up.
 ⏮️ The function aborts if `denom == 0`.
*/
#[spec(prove, target = checked_div_round)]
public fun checked_div_round_spec(num: u128, denom: u128, round_up: bool): u128 {
    asserts(denom != 0);

    let result = checked_div_round(num, denom, round_up);

    let num_int = num.to_int();
    let denom_int = denom.to_int();
    let res_int = result.to_int();
    if (!round_up) {
        ensures(res_int.mul(denom_int).lte(num_int));
        ensures(num_int.lt(res_int.add(1u64.to_int()).mul(denom_int)));
    } else {
        ensures(res_int.sub(1u64.to_int()).mul(denom_int).lt(num_int));
        ensures(num_int.lte(res_int.mul(denom_int)));
    };
    result
}

/*
 ✅ Returns the maximum of two u128 values.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = max)]
public fun max_spec(num1: u128, num2: u128): u128 {
    let result = max(num1, num2);
    if (num1 > num2) {
        ensures(result == num1);
    } else {
        ensures(result == num2);
    };
    result
}

/*
 ✅ Returns the minimum of two u128 values.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = min)]
public fun min_spec(num1: u128, num2: u128): u128 {
    let result = min(num1, num2);
    if (num1 < num2) {
        ensures(result == num1);
    } else {
        ensures(result == num2);
    };
    result
}

/*
 ✅ Checks if `num1 + num2` will overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = add_check)]
public fun add_check_spec(num1: u128, num2: u128): bool {
    let result = add_check(num1, num2);
    ensures(result == num1.to_int().add(num2.to_int()).lte(std::u128::max_value!().to_int()));
    result
}

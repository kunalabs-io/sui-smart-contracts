module integer_library_specs::i128_specs;

use integer_library::i128::{
    I128,
    zero,
    from,
    neg_from,
    neg,
    wrapping_add,
    add,
    overflowing_add,
    wrapping_sub,
    sub,
    overflowing_sub,
    mul,
    div,
    abs,
    abs_u128,
    shl,
    shr,
    as_u128,
    as_i64,
    as_i32,
    sign,
    is_neg,
    cmp,
    eq,
    gt,
    gte,
    lt,
    lte,
    or,
    and,
    u128_neg,
    u8_neg
};

use integer_library_specs::i32_specs::Self;
use integer_library_specs::i64_specs::Self;

#[spec_only]
use std::integer::Integer;
#[spec_only]
use prover::prover::{ensures, asserts};

const MIN_AS_U128: u128 = 0x80000000000000000000000000000000;
const MAX_AS_U128: u128 = 0x7fffffffffffffffffffffffffffffff;

#[spec_only]
fun to_signed_int(x: u128): Integer {
    if (x <= MAX_AS_U128) {
        x.to_int()
    } else {
        let pow_2_128 = 0x100000000000000000000000000000000u256.to_int();
        x.to_int().sub(pow_2_128)
    }
}

#[spec_only]
fun to_int(v: I128): Integer {
    v.as_u128().to_signed_int()
}

#[spec_only]
fun is_i128(v: Integer): bool {
    v.gte(MIN_AS_U128.to_signed_int()) && v.lte(MAX_AS_U128.to_signed_int())
}

#[spec_only]
public fun int_div_trunc(x: Integer, y: Integer): Integer {
    let result_abs = x.abs().div(y.abs());
    if (x.is_pos() && y.is_pos() || x.is_neg() && y.is_neg()) {
        result_abs
    } else {
        result_abs.neg()
    }
}

#[spec_only]
public fun int_abs(v: Integer): Integer {
    if (v.is_neg()) {
        v.neg()
    } else {
        v
    }
}

#[spec_only]
public fun int_is_pos(v: Integer): bool {
    v.gte(0u128.to_int())
}

#[spec_only]
public fun int_is_neg(v: Integer): bool {
    v.lt(0u128.to_int())
}

use fun to_int as I128.to_int;
use fun to_signed_int as u128.to_signed_int;
use fun int_abs as Integer.abs;
use fun int_is_pos as Integer.is_pos;
use fun int_is_neg as Integer.is_neg;
use fun int_div_trunc as Integer.div_trunc;

/*
 ✅ Computes `0` as an `I128`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = zero)]
public fun zero_spec(): I128 {
    let result = zero();
    ensures(result.to_int() == 0u128.to_int());
    result
}

/*
 ✅ Computes an `I128` from a `u128`.
 ⏮️ The function aborts when the value exceeds `I128::MAX`.
*/
#[spec(prove, target = from)]
public fun from_spec(v: u128): I128 {
    asserts(is_i128(v.to_int()));
    let result = from(v);
    ensures(result.to_int() == v.to_int());
    result
}

/*
 ✅ Computes an `I128` from the negation of a `u128`.
 ⏮️ The function aborts when the result does not fit in `I128`.
*/
#[spec(prove, target = neg_from)]
public fun neg_from_spec(v: u128): I128 {
    asserts(is_i128(v.to_int().neg()));
    let result = neg_from(v);
    ensures(result.to_int() == v.to_int().neg());
    result
}

/*
 ✅ Computes the negation of an `I128`.
 ⏮️ The function aborts when the input is `MIN_I128`, that is `-2^127`.
*/
#[spec(prove, target = neg)]
public fun neg_spec(v: I128): I128 {
    let v_int = v.to_int();
    asserts(is_i128(v_int.neg()));
    let result = neg(v);
    ensures(result.to_int() == v_int.neg());
    result
}

/*
 ✅ Computes `num1 + num2` with wrapping overflow.
 ⏮️ The function does not abort.
 ⚠️ Proved in a separate package as it requires a custom prover configuration.
*/
#[spec(target = wrapping_add)]
public fun wrapping_add_spec(num1: I128, num2: I128): I128 {
    let result = wrapping_add(num1, num2);
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let sum_int = num1_int.add(num2_int);
    ensures(result.to_int() == sum_int.to_u128().to_signed_int());
    result
}

/*
 ✅ Computes `num1 + num2`.
 ⏮️ The function aborts when the result does not fit in `I128`.
*/
#[spec(prove, target = add)]
public fun add_spec(num1: I128, num2: I128): I128 {
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let sum_int = num1_int.add(num2_int);
    asserts(is_i128(sum_int));
    let result = add(num1, num2);
    ensures(result.to_int() == sum_int);
    result
}

/*
 ✅ Computes `num1 + num2` and returns a flag indicating overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = overflowing_add)]
public fun overflowing_add_spec(num1: I128, num2: I128): (I128, bool) {
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let sum_int = num1_int.add(num2_int);
    let (result, overflow) = overflowing_add(num1, num2);
    ensures(result.to_int() == sum_int.to_u128().to_signed_int());
    ensures(overflow == !is_i128(sum_int));
    (result, overflow)
}

/*
 ✅ Computes `num1 - num2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_sub)]
public fun wrapping_sub_spec(num1: I128, num2: I128): I128 {
    let result = wrapping_sub(num1, num2);
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let diff_int = num1_int.sub(num2_int);
    ensures(result.to_int() == diff_int.to_u128().to_signed_int());
    result
}

/*
 ✅ Computes `num1 - num2`.
 ⏮️ The function aborts when the result does not fit in `I128`.
*/
#[spec(prove, target = sub)]
public fun sub_spec(num1: I128, num2: I128): I128 {
    let diff_int = num1.to_int().sub(num2.to_int());
    asserts(is_i128(diff_int));
    let result = sub(num1, num2);
    ensures(result.to_int() == diff_int);
    result
}

/*
 ✅ Computes `num1 - num2` and returns a flag indicating overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = overflowing_sub)]
public fun overflowing_sub_spec(num1: I128, num2: I128): (I128, bool) {
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let diff_int = num1_int.sub(num2_int);
    let (result, overflow) = overflowing_sub(num1, num2);
    ensures(result.to_int() == diff_int.to_u128().to_signed_int());
    ensures(overflow == !is_i128(diff_int));
    (result, overflow)
}

/*
 ✅ Computes `num1 * num2`.
 ⏮️ The function aborts when the result does not fit in `I128`.
*/
#[spec(prove, target = mul)]
public fun mul_spec(num1: I128, num2: I128): I128 {
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let product_int = num1_int.mul(num2_int);
    asserts(is_i128(product_int));
    let result = mul(num1, num2);
    ensures(result.to_int() == product_int);
    result
}

/*
 ✅ Computes `num1 / num2` with truncation.
 ⏮️ The function aborts when the result does not fit in `I128`, or the denominator is zero.
*/
#[spec(prove, target = div)]
public fun div_spec(num1: I128, num2: I128): I128 {
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    asserts(num2_int != 0u128.to_int());
    let quotient_int = num1_int.div_trunc(num2_int);
    asserts(is_i128(quotient_int));
    let result = div(num1, num2);
    ensures(result.to_int() == quotient_int);
    result
}

/*
 ✅ Computes the absolute value of an `I128`.
 ⏮️ The function aborts when the input is `MIN_I128`, that is `-2^127`.
*/
#[spec(prove, target = abs)]
public fun abs_spec(v: I128): I128 {
    asserts(is_i128(v.to_int().abs()));
    let result = abs(v);
    ensures(result.to_int() == v.to_int().abs());
    result
}

/*
 ✅ Computes the absolute value of an `I128` as a `u128`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = abs_u128)]
public fun abs_u128_spec(v: I128): u128 {
    let result = abs_u128(v);
    ensures(result.to_int() == v.to_int().abs());
    result
}

/*
 ✅ Computes `v << shift`.
 ⏮️ The function aborts unless `shift < 128`.
*/
#[spec(prove, target = shl)]
public fun shl_spec(v: I128, shift: u8): I128 {
    asserts(shift < 128);
    let result = shl(v, shift);
    ensures(result.as_u128() == v.to_int().shl(shift.to_int()).to_u128());
    result
}

/*
 ✅ Computes `v >> shift`.
 ⏮️ The function aborts unless `shift < 128`.
 ⚠️ Proved in a separate package as it requires a custom prover configuration.
*/
#[spec(target = shr)]
public fun shr_spec(v: I128, shift: u8): I128 {
    asserts(shift < 128);
    let result = shr(v, shift);
    ensures(result.to_int() == v.to_int().shr(shift.to_int()));
    result
}

/*
 ✅ Converts an `I128` to an `I64`.
 ⏮️ The function aborts when the value does not fit in `I64`.
*/
#[spec(prove, target = as_i64)]
public fun as_i64_spec(v: I128): integer_library::i64::I64 {
    asserts(i64_specs::is_i64(v.to_int()));
    let result = as_i64(v);
    ensures(i64_specs::to_int(result) == v.to_int());
    result
}

/*
 ✅ Converts an `I128` to an `I32`.
 ⏮️ The function aborts when the value does not fit in `I32`.
*/
#[spec(prove, target = as_i32)]
public fun as_i32_spec(v: I128): integer_library::i32::I32 {
    asserts(i32_specs::is_i32(v.to_int()));
    let result = as_i32(v);
    ensures(i32_specs::to_int(result) == v.to_int());
    result
}

/*
 ✅ Returns `1` if the input is negative, `0` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = sign)]
public fun sign_spec(v: I128): u8 {
    let result = sign(v);
    if (v.to_int().is_neg()) {
        ensures(result == 1u8);
    } else {
        ensures(result == 0u8);
    };
    result
}

/*
 ✅ Returns `true` if the input is negative, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = is_neg)]
public fun is_neg_spec(v: I128): bool {
    let result = is_neg(v);
    ensures(result == v.to_int().is_neg());
    result
}

/*
 ✅ Compares two `I128`s.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = cmp)]
public fun cmp_spec(num1: I128, num2: I128): u8 {
    let result = cmp(num1, num2);
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    if (num1_int.lt(num2_int)) {
        ensures(result == 0); // LT
    } else if (num1_int == num2_int) {
        ensures(result == 1); // EQ
    } else {
        ensures(result == 2); // GT
    };
    result
}

/*
 ✅ Compares two `I128`s, returns `true` if they are equal, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = eq)]
public fun eq_spec(num1: I128, num2: I128): bool {
    let result = eq(num1, num2);
    ensures(result == (num1.to_int() == num2.to_int()));
    result
}

/*
 ✅ Compares two `I128`s, returns `true` if the first is greater than the second, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = gt)]
public fun gt_spec(num1: I128, num2: I128): bool {
    let result = gt(num1, num2);
    ensures(result == num1.to_int().gt(num2.to_int()));
    result
}

/*
 ✅ Compares two `I128`s, returns `true` if the first is greater than or equal to the second, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = gte)]
public fun gte_spec(num1: I128, num2: I128): bool {
    let result = gte(num1, num2);
    ensures(result == num1.to_int().gte(num2.to_int()));
    result
}

/*
 ✅ Compares two `I128`s, returns `true` if the first is less than the second, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = lt)]
public fun lt_spec(num1: I128, num2: I128): bool {
    let result = lt(num1, num2);
    ensures(result == num1.to_int().lt(num2.to_int()));
    result
}

/*
 ✅ Compares two `I128`s, returns `true` if the first is less than or equal to the second, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = lte)]
public fun lte_spec(num1: I128, num2: I128): bool {
    let result = lte(num1, num2);
    ensures(result == num1.to_int().lte(num2.to_int()));
    result
}

/*
 ✅ Computes the bitwise OR of two `I128`s.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = or)]
public fun or_spec(num1: I128, num2: I128): I128 {
    let result = or(num1, num2);
    ensures(result.to_int() == num1.to_int().bit_or(num2.to_int()));
    result
}

/*
 ✅ Computes the bitwise AND of two `I128`s.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = and)]
public fun and_spec(num1: I128, num2: I128): I128 {
    let result = and(num1, num2);
    ensures(result.to_int() == num1.to_int().bit_and(num2.to_int()));
    result
}

/*
 ✅ Computes the bitwise NOT of a `u128`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = u128_neg)]
public fun u128_neg_spec(v: u128): u128 {
    let result = u128_neg(v);
    let expected_result = 0xffffffffffffffffffffffffffffffff - v;
    ensures(result == expected_result);
    result
}

/*
 ✅ Computes the bitwise NOT of a `u8`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = u8_neg)]
public fun u8_neg_spec(v: u8): u8 {
    let result = u8_neg(v);
    ensures(result == std::u8::max_value!() - v);
    result
}

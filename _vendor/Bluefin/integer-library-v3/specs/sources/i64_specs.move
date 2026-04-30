module integer_library_specs::i64_specs;

use integer_library::i64::{
    I64,
    zero,
    from_u64,
    from,
    neg_from,
    wrapping_add,
    add,
    wrapping_sub,
    sub,
    mul,
    div,
    abs,
    abs_u64,
    shl,
    shr,
    mod,
    as_u64,
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
    u64_neg,
    u8_neg
};

#[spec_only]
use std::integer::Integer;
#[spec_only]
use prover::prover::{ensures, asserts};

const MIN_AS_U64: u64 = 0x8000000000000000;
const MAX_AS_U64: u64 = 0x7fffffffffffffff;

#[spec_only]
fun to_signed_int(x: u64): Integer {
    if (x <= MAX_AS_U64) {
        x.to_int()
    } else {
        x.to_int().sub(1u8.to_int().shl(64u8.to_int()))
    }
}

#[spec_only]
fun to_int(v: I64): Integer {
    v.as_u64().to_signed_int()
}

#[spec_only]
fun is_i64(v: Integer): bool {
    v.gte(MIN_AS_U64.to_signed_int()) && v.lte(MAX_AS_U64.to_signed_int())
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
public fun int_mod_trunc(x: Integer, y: Integer): Integer {
    x.sub(y.mul(x.div_trunc(y)))
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
    v.gte(0u64.to_int())
}

#[spec_only]
public fun int_is_neg(v: Integer): bool {
    v.lt(0u64.to_int())
}

use fun to_int as I64.to_int;
use fun to_signed_int as u64.to_signed_int;
use fun int_abs as Integer.abs;
use fun int_is_pos as Integer.is_pos;
use fun int_is_neg as Integer.is_neg;
use fun int_div_trunc as Integer.div_trunc;
use fun int_mod_trunc as Integer.mod_trunc;

/*
 ✅ Computes `0` as an `I64`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = zero)]
public fun zero_spec(): I64 {
    let result = zero();
    ensures(result.to_int() == 0u64.to_int());
    result
}

/*
 ✅ Computes an `I64` from a `u64`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = from_u64)]
public fun from_u64_spec(v: u64): I64 {
    let result = from_u64(v);
    ensures(result.to_int() == v.to_signed_int());
    result
}

/*
 ✅ Computes an `I64` from a `u64`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = from)]
public fun from_spec(v: u64): I64 {
    asserts(is_i64(v.to_int()));
    let result = from(v);
    ensures(result.to_int() == v.to_int());
    result
}

/*
 ✅ Computes an `I64` from a `u64`.
 ⏮️ The function aborts when the result does not fit in `I64`.
*/
#[spec(prove, target = neg_from)]
public fun neg_from_spec(v: u64): I64 {
    asserts(is_i64(v.to_int().neg()));
    let result = neg_from(v);
    ensures(result.to_int() == v.to_int().neg());
    result
}

/*
 ✅ Computes `num1 + num2` with wrapping overflow.
 ⏮️ The function does not abort.
 ⚠️ Proved in a separate package as it requires a custom prover configuration.
*/
#[spec(target = wrapping_add)]
public fun wrapping_add_spec(num1: I64, num2: I64): I64 {
    let result = wrapping_add(num1, num2);
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let sum_int = num1_int.add(num2_int);
    ensures(result.to_int() == sum_int.to_u64().to_signed_int());
    result
}

/*
 ✅ Computes `num1 + num2`.
 ⏮️ The function aborts when the result does not fit in `I64`.
*/
#[spec(prove, target = add)]
public fun add_spec(num1: I64, num2: I64): I64 {
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let sum_int = num1_int.add(num2_int);
    asserts(is_i64(sum_int));
    let result = add(num1, num2);
    ensures(result.to_int() == sum_int);
    result
}

/*
 ✅ Computes `num1 - num2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_sub)]
public fun wrapping_sub_spec(num1: I64, num2: I64): I64 {
    let result = wrapping_sub(num1, num2);
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let diff_int = num1_int.sub(num2_int);
    ensures(result.to_int() == diff_int.to_u64().to_signed_int());
    result
}

/*
 ✅ Computes `num1 - num2`.
 ⏮️ The function aborts when the result does not fit in `I64`.
*/
#[spec(prove, target = sub)]
public fun sub_spec(num1: I64, num2: I64): I64 {
    let diff_int = num1.to_int().sub(num2.to_int());
    asserts(is_i64(diff_int));
    let result = sub(num1, num2);
    ensures(result.to_int() == diff_int);
    result
}

/*
 ✅ Computes `num1 * num2`.
 ⏮️ The function aborts when the result does not fit in `I64`.
*/
#[spec(prove, target = mul)]
public fun mul_spec(num1: I64, num2: I64): I64 {
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let product_int = num1_int.mul(num2_int);
    asserts(is_i64(product_int));
    let result = mul(num1, num2);
    ensures(result.to_int() == product_int);
    result
}

/*
 ✅ Computes `num1 / num2` with truncation.
 ⏮️ The function aborts when the result does not fit in `I64`, or the denominator is zero.
*/
#[spec(prove, target = div)]
public fun div_spec(num1: I64, num2: I64): I64 {
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    asserts(num2_int != 0u64.to_int());
    let quotient_int = num1_int.div_trunc(num2_int);
    asserts(is_i64(quotient_int));
    let result = div(num1, num2);
    ensures(result.to_int() == quotient_int);
    result
}

/*
 ✅ Computes the absolute value of an `I64`.
 ⏮️ The function aborts when the input is `MIN_I64`, that is `-2^63`.
*/
#[spec(prove, target = abs)]
public fun abs_spec(v: I64): I64 {
    asserts(is_i64(v.to_int().abs()));
    let result = abs(v);
    ensures(result.to_int() == v.to_int().abs());
    result
}

/*
 ✅ Computes the absolute value of an `I64` as a `u64`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = abs_u64)]
public fun abs_u64_spec(v: I64): u64 {
    let result = abs_u64(v);
    ensures(result.to_int() == v.to_int().abs());
    result
}

/*
 ✅ Computes `v << shift`.
 ⏮️ The function aborts unless `shift < 64`.
*/
#[spec(prove, target = shl)]
public fun shl_spec(v: I64, shift: u8): I64 {
    asserts(shift < 64);
    let result = shl(v, shift);
    ensures(result.as_u64() == v.to_int().shl(shift.to_int()).to_u64());
    result
}

/*
 ✅ Computes `v >> shift`.
 ⏮️ The function aborts unless `shift < 64`.
 ⚠️ Proved in a separate package as it requires a custom prover configuration.
*/
#[spec(target = shr)]
public fun shr_spec(v: I64, shift: u8): I64 {
    asserts(shift < 64);
    let result = shr(v, shift);
    ensures(result.to_int() == v.to_int().shr(shift.to_int()));
    result
}

/*
 ✅ Computes `v % n`.
 ⏮️ The function aborts when the denominator is zero.
*/
#[spec(prove, target = mod)]
public fun mod_spec(v: I64, n: I64): I64 {
    let v_int = v.to_int();
    let n_int = n.to_int();
    asserts(n_int != 0u64.to_int());
    let result = mod(v, n);
    let remainder_int = v_int.mod_trunc(n_int);
    ensures(result.to_int() == remainder_int);
    result
}

/*
 ✅ Returns `1` if the input is negative, `0` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = sign)]
public fun sign_spec(v: I64): u8 {
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
public fun is_neg_spec(v: I64): bool {
    let result = is_neg(v);
    ensures(result == v.to_int().is_neg());
    result
}

/*
 ✅ Compares two `I64`s.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = cmp)]
public fun cmp_spec(num1: I64, num2: I64): u8 {
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
 ✅ Compares two `I64`s, returns `true` if they are equal, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = eq)]
public fun eq_spec(num1: I64, num2: I64): bool {
    let result = eq(num1, num2);
    ensures(result == (num1.to_int() == num2.to_int()));
    result
}

/*
 ✅ Compares two `I64`s, returns `true` if the first is greater than the second, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = gt)]
public fun gt_spec(num1: I64, num2: I64): bool {
    let result = gt(num1, num2);
    ensures(result == num1.to_int().gt(num2.to_int()));
    result
}

/*
 ✅ Compares two `I64`s, returns `true` if the first is greater than or equal to the second, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = gte)]
public fun gte_spec(num1: I64, num2: I64): bool {
    let result = gte(num1, num2);
    ensures(result == num1.to_int().gte(num2.to_int()));
    result
}

/*
 ✅ Compares two `I64`s, returns `true` if the first is less than the second, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = lt)]
public fun lt_spec(num1: I64, num2: I64): bool {
    let result = lt(num1, num2);
    ensures(result == num1.to_int().lt(num2.to_int()));
    result
}

/*
 ✅ Compares two `I64`s, returns `true` if the first is less than or equal to the second, `false` otherwise.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = lte)]
public fun lte_spec(num1: I64, num2: I64): bool {
    let result = lte(num1, num2);
    ensures(result == num1.to_int().lte(num2.to_int()));
    result
}

/*
 ✅ Computes the bitwise OR of two `I64`s.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = or)]
public fun or_spec(num1: I64, num2: I64): I64 {
    let result = or(num1, num2);
    ensures(result.to_int() == num1.to_int().bit_or(num2.to_int()));
    result
}

/*
 ✅ Computes the bitwise AND of two `I64`s.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = and)]
public fun and_spec(num1: I64, num2: I64): I64 {
    let result = and(num1, num2);
    ensures(result.to_int() == num1.to_int().bit_and(num2.to_int()));
    result
}

/*
 ✅ Computes the bitwise NOT of a `u64`.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = u64_neg)]
public fun u64_neg_spec(v: u64): u64 {
    let result = u64_neg(v);
    ensures(result == std::u64::max_value!() - v);
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

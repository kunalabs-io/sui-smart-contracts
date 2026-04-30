module integer_library_specs::full_math_u128_specs;

use integer_library::full_math_u128::{
    mul_div_floor,
    mul_div_round,
    mul_div_ceil,
    mul_shr,
    mul_shl,
    full_mul
};

#[spec_only]
use prover::prover::{ensures, asserts};

/*
 ✅ Computes `num1 * num2` using 256-bit arithmetic for intermediate product computation.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = full_mul)]
public fun full_mul_spec(num1: u128, num2: u128): u256 {
    let result = full_mul(num1, num2);
    let num1_int = num1.to_int();
    let num2_int = num2.to_int();
    let expected_result = num1_int.mul(num2_int);

    ensures(result.to_int() == expected_result);
    result
}

/*
 ✅ Computes `(num1 * num2) / denom` with floor division using 256-bit arithmetic for intermediate product computation.
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u128`.
*/
#[spec(prove, target = mul_div_floor)]
public fun mul_div_floor_spec(num1: u128, num2: u128, denom: u128): u128 {
    asserts(denom > 0);
    let denom_int = denom.to_int();
    let product_int = num1.to_int().mul(num2.to_int());
    let expected_result_int = product_int.div(denom_int);
    asserts(expected_result_int.lte(std::u128::max_value!().to_int()));
    let result = mul_div_floor(num1, num2, denom);
    ensures(result.to_int() == expected_result_int);
    let result_int = result.to_int();
    ensures(result_int.mul(denom_int).lte(product_int));
    ensures(product_int.lt(result_int.add(1u128.to_int()).mul(denom_int)));

    result
}

/*
 ✅ Computes `(num1 * num2) / denom` with rounding division using 256-bit arithmetic for intermediate product computation.
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u128`.
*/
#[spec(prove, target = mul_div_round)]
public fun mul_div_round_spec(num1: u128, num2: u128, denom: u128): u128 {
    asserts(denom > 0);
    let product_int = num1.to_int().mul(num2.to_int());
    let half_denom_int = denom.to_int().div(2u128.to_int());
    let expected_result_int = product_int.add(half_denom_int).div(denom.to_int());
    asserts(expected_result_int.lte(std::u128::max_value!().to_int()));

    let result = mul_div_round(num1, num2, denom);
    ensures(result.to_int() == expected_result_int);

    result
}

/*
 ✅ Computes `(num1 * num2) / denom` with ceiling division using 256-bit arithmetic for intermediate product computation.
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u128`.
*/
#[spec(prove, target = mul_div_ceil)]
public fun mul_div_ceil_spec(num1: u128, num2: u128, denom: u128): u128 {
    asserts(denom > 0);
    let product_int = num1.to_int().mul(num2.to_int());
    let denom_int = denom.to_int();
    let expected_result_int = product_int.add(denom_int.sub(1u128.to_int())).div(denom_int);
    asserts(expected_result_int.lte(std::u128::max_value!().to_int()));

    let result = mul_div_ceil(num1, num2, denom);
    ensures(result.to_int() == expected_result_int);

    let result_int = result.to_int();
    ensures(result_int.sub(1u128.to_int()).mul(denom_int).lt(product_int));
    ensures(product_int.lte(result_int.mul(denom_int)));

    result
}

/*
 ✅ Computes `(num1 * num2) >> shift` using 256-bit arithmetic for intermediate product computation.
 ⏮️ The function aborts unless `shift <= 255` and the result fits in `u128`.
*/
#[spec(prove, target = mul_shr)]
public fun mul_shr_spec(num1: u128, num2: u128, shift: u8): u128 {
    asserts(shift <= 255);
    let product_int = num1.to_int().mul(num2.to_int());
    let power_of_two = 2u128.to_int().pow(shift.to_int());
    let expected_result = product_int.div(power_of_two);

    asserts(expected_result.lte(std::u128::max_value!().to_int()));
    let result = mul_shr(num1, num2, shift);
    ensures(result.to_int() == expected_result);

    result
}

/*
 ✅ Computes `(num1 * num2) << shift` using 256-bit arithmetic for intermediate product computation.
 ⏮️ The function aborts unless `shift <= 255` and the result fits in `u128`.
 ⚠️ Note that due to `<<` not aborting when losing significant bits, the actual result is `((num1 * num2) << shift) mod 2^256` (note the modulo), which can be unintuitive to users.
*/
#[spec(prove, target = mul_shl)]
public fun mul_shl_spec(num1: u128, num2: u128, shift: u8): u128 {
    asserts(shift <= 255);
    let product_int = num1.to_int().mul(num2.to_int());
    let expected_result = product_int
        .shl(shift.to_int())
        .mod(std::u256::max_value!().to_int().add(1u128.to_int()));
    asserts(expected_result.lte(std::u128::max_value!().to_int()));

    let result = mul_shl(num1, num2, shift);

    ensures(result.to_int() == expected_result);

    result
}

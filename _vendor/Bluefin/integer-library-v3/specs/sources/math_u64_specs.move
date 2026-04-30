module integer_library_specs::math_u64_specs;

use integer_library::math_u64::{
    wrapping_add,
    overflowing_add,
    wrapping_sub,
    overflowing_sub,
    wrapping_mul,
    overflowing_mul,
    carry_add,
    add_check
};

#[spec_only]
use prover::prover::{ensures, asserts};

/*
 ✅ Computes `n1 + n2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_add)]
public fun wrapping_add_spec(n1: u64, n2: u64): u64 {
    let result = wrapping_add(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let sum_int = n1_int.add(n2_int);

    ensures(result == sum_int.to_u64());

    result
}

/*
 ✅ Computes `n1 + n2` with wrapping overflow and a boolean indicating overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = overflowing_add)]
public fun overflowing_add_spec(n1: u64, n2: u64): (u64, bool) {
    let (result, overflow) = overflowing_add(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let sum_int = n1_int.add(n2_int);

    ensures(result == sum_int.to_u64());
    // Check if overflow occurs
    ensures(overflow == sum_int.gt(std::u64::max_value!().to_int()));

    (result, overflow)
}

/*
 ✅ Computes `n1 - n2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_sub)]
public fun wrapping_sub_spec(n1: u64, n2: u64): u64 {
    let result = wrapping_sub(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let diff_int = n1_int.sub(n2_int);

    ensures(result == diff_int.to_u64());

    result
}

/*
 ✅ Computes `n1 - n2` with wrapping overflow and a boolean indicating overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = overflowing_sub)]
public fun overflowing_sub_spec(n1: u64, n2: u64): (u64, bool) {
    let (result, overflow) = overflowing_sub(n1, n2);
    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let diff_int = n1_int.sub(n2_int);

    ensures(result == diff_int.to_u64());
    // Overflow occurs when num1 < num2
    ensures(overflow == n1_int.lt(n2_int));

    (result, overflow)
}

/*
 ✅ Computes `n1 * n2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_mul)]
public fun wrapping_mul_spec(n1: u64, n2: u64): u64 {
    let result = wrapping_mul(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let product_int = n1_int.mul(n2_int);

    ensures(result == product_int.to_u64());

    result
}

/*
 ✅ Computes `n1 * n2` with overflowing overflow and a boolean indicating overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = overflowing_mul)]
public fun overflowing_mul_spec(n1: u64, n2: u64): (u64, bool) {
    let (result, overflow) = overflowing_mul(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let product_int = n1_int.mul(n2_int);

    ensures(result == product_int.to_u64());
    ensures(overflow == product_int.gt(std::u64::max_value!().to_int()));

    (result, overflow)
}

/*
 ✅ Computes `n1 + n2 + carry` returning the result and the new carry.
 ⏮️ The function aborts unless `carry <= 1`.
*/
#[spec(prove, target = carry_add)]
public fun carry_add_spec(n1: u64, n2: u64, carry: u64): (u64, u64) {
    asserts(carry <= 1);

    let (result, new_carry) = carry_add(n1, n2, carry);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();
    let carry_int = carry.to_int();
    let sum_int = n1_int.add(n2_int).add(carry_int);

    // The new carry is 1 if sum > 2^64 - 1, 0 otherwise
    ensures(new_carry == if (sum_int.gt(std::u64::max_value!().to_int())) { 1 } else { 0 });
    // The result is the lower 64 bits of the sum
    ensures(result == sum_int.to_u64());

    (result, new_carry)
}

/*
 ✅ Checks if `n1 + n2` will overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = add_check)]
public fun add_check_spec(n1: u64, n2: u64): bool {
    let result = add_check(n1, n2);

    let n1_int = n1.to_int();
    let n2_int = n2.to_int();

    // add_check returns true if addition won't overflow
    ensures(result == n1_int.add(n2_int).lte(std::u64::max_value!().to_int()));

    result
}

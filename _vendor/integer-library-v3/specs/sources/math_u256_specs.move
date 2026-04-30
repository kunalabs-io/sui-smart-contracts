module integer_library_specs::math_u256_specs;

use integer_library::math_u256::{add_check, checked_shlw, div_mod, div_round, shlw, shrw};

#[spec_only]
use prover::prover::{ensures, asserts};

/*
 ✅ Computes `num / denom` and `num % denom`.
 ⏮️ The function aborts if `denom == 0`.
*/
#[spec(prove, target = div_mod)]
public fun div_mod_spec(num: u256, denom: u256): (u256, u256) {
    asserts(denom != 0);
    let num_int = num.to_int();
    let denom_int = denom.to_int();
    let (p, r) = div_mod(num, denom);
    let p_int = p.to_int();
    let r_int = r.to_int();
    ensures(p_int.mul(denom_int).add(r_int) == num_int);
    ensures(r < denom);
    (p, r)
}

/*
 ✅ Shifts `n` left by 64 bits (one word) with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = shlw)]
public fun shlw_spec(n: u256): u256 {
    let res = shlw(n);
    let n_int = n.to_int();
    let res_int = res.to_int();
    let n_shifted = n_int.shl(64u64.to_int());
    let max_u256_plus_one = std::u256::max_value!().to_int().add(1u64.to_int());
    // The result should be equivalent to (n << 64) mod 2^256
    ensures(res_int == n_shifted.mod(max_u256_plus_one));
    res
}

/*
 ✅ Shifts `n` right by 64 bits (one word).
 ⏮️ The function does not abort.
*/
#[spec(prove, target = shrw)]
public fun shrw_spec(n: u256): u256 {
    let res = shrw(n);
    let n_shifted = n.to_int().shr(64u64.to_int());
    ensures(n_shifted == res.to_int());
    res
}

/*
 ✅ Shifts `n` left by 64 bits (one word) and returns a boolean indicating overflow.
 ⏮️ The function does not abort.
 ⚠️ Returns (0, true) when overflow occurs, not the wrapped value.
 ⚠️ Note that an incorrect version of this function was at the root of the Cetus exploit: 
    See our analysis here: https://x.com/AsymptoticTech/status/1925745737243013596
*/
#[spec(prove, target = checked_shlw)]
public fun checked_shlw_spec(n: u256): (u256, bool) {
    let (result, overflow) = checked_shlw(n);

    let n_shifted = n.to_int().shl(64u64.to_int());
    if (n_shifted.gt(std::u256::max_value!().to_int())) {
        ensures(overflow == true);
        ensures(result == 0);
    } else {
        ensures(overflow == false);
        ensures(result == n_shifted.to_u256());
    };

    (result, overflow)
}

/*
 ✅ Computes `num / denom` with optional rounding up.
 ⏮️ The function aborts if `denom == 0`.
*/
#[spec(prove, target = div_round)]
public fun div_round_spec(num: u256, denom: u256, round_up: bool): u256 {
    asserts(denom != 0);
    let num_int = num.to_int();
    let denom_int = denom.to_int();
    let res = div_round(num, denom, round_up);
    let res_int = res.to_int();

    if (!round_up) {
        ensures(res_int.mul(denom_int).lte(num_int));
        ensures(num_int.lt(res_int.add(1u64.to_int()).mul(denom_int)));
    } else {
        ensures(res_int.sub(1u64.to_int()).mul(denom_int).lt(num_int));
        ensures(num_int.lte(res_int.mul(denom_int)));
    };
    res
}

/*
 ✅ Checks if `num1 + num2` will overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = add_check)]
public fun add_check_spec(num1: u256, num2: u256): bool {
    let res = add_check(num1, num2);
    ensures(res == num1.to_int().add(num2.to_int()).lte(std::u256::max_value!().to_int()));
    res
}

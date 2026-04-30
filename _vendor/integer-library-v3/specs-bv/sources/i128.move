module integer_library_specs_bv::i128;

#[spec_only]
use prover::prover::{ensures, asserts, invariant};

public struct I128 has copy, drop, store {
    bits: u128,
}

public fun wrapping_add(num1: I128, num2: I128): I128 {
    let mut sum = num1.bits ^ num2.bits;
    let mut carry = (num1.bits & num2.bits) << 1;
    invariant!(|| {
        ensures(
            ((num1.bits as u256) + (num2.bits as u256)) % (1 << 128) == ((sum as u256) + (carry as u256)) % (1 << 128),
        );
    });
    while (carry != 0) {
        let a = sum;
        let b = carry;
        sum = a ^ b;
        carry = (a & b) << 1;
    };
    I128 {
        bits: sum,
    }
}

/*
 ✅ Computes `num1 + num2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_add)]
public fun wrapping_add_spec(num1: I128, num2: I128): I128 {
    let result = wrapping_add(num1, num2);
    ensures(result.bits == (((num1.bits as u256) + (num2.bits as u256)) % (1 << 128)) as u128);
    result
}

public fun shr(v: I128, shift: u8): I128 {
    if (shift == 0) {
        return v
    };
    let mask = 0xffffffffffffffffffffffffffffffff << (128 - shift);
    if (sign(v) == 1) {
        return I128 {
            bits: (v.bits >> shift) | mask,
        }
    };
    I128 {
        bits: v.bits >> shift,
    }
}

public fun sign(v: I128): u8 {
    ((v.bits >> 127) as u8)
}

public native fun ashr(x: u128, y: u128): u128;

/*
 ✅ Computes arithmetic right shift `v >> shift`.
 ⏮️ The function aborts unless `shift < 128`.
*/
#[spec(prove, target = shr)]
public fun shr_spec(v: I128, shift: u8): I128 {
    asserts(shift < 128);
    let result = shr(v, shift);
    ensures(result.bits == ashr(v.bits, shift as u128));
    result
}

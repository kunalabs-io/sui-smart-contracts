module integer_library_specs_bv::i64;

#[spec_only]
use prover::prover::{ensures, asserts, invariant};

public struct I64 has copy, drop, store {
    bits: u64,
}

public fun wrapping_add(num1: I64, num2: I64): I64 {
    let mut sum = num1.bits ^ num2.bits;
    let mut carry = (num1.bits & num2.bits) << 1;
    invariant!(|| {
        ensures(
            ((num1.bits as u128) + (num2.bits as u128)) % (1 << 64) == ((sum as u128) + (carry as u128)) % (1 << 64),
        );
    });
    while (carry != 0) {
        let a = sum;
        let b = carry;
        sum = a ^ b;
        carry = (a & b) << 1;
    };
    I64 {
        bits: sum,
    }
}

/*
 ✅ Computes `num1 + num2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_add)]
public fun wrapping_add_spec(num1: I64, num2: I64): I64 {
    let result = wrapping_add(num1, num2);
    ensures(result.bits == (((num1.bits as u128) + (num2.bits as u128)) % (1 << 64)) as u64);
    result
}

public fun shr(v: I64, shift: u8): I64 {
    if (shift == 0) {
        return v
    };
    let mask = 0xffffffffffffffff << (64 - shift);
    if (sign(v) == 1) {
        return I64 {
            bits: (v.bits >> shift) | mask,
        }
    };
    I64 {
        bits: v.bits >> shift,
    }
}

public fun sign(v: I64): u8 {
    ((v.bits >> 63) as u8)
}

public native fun ashr(x: u64, y: u64): u64;

/*
 ✅ Computes arithmetic right shift `v >> shift`.
 ⏮️ The function aborts unless `shift < 64`.
*/
#[spec(prove, target = shr)]
public fun shr_spec(v: I64, shift: u8): I64 {
    asserts(shift < 64);
    let result = shr(v, shift);
    ensures(result.bits == ashr(v.bits, shift as u64));
    result
}

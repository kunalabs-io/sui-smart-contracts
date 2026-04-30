module integer_library_specs_bv::i32;

#[spec_only]
use prover::prover::{ensures, asserts, invariant};

public struct I32 has copy, drop, store {
    bits: u32,
}

public fun wrapping_add(num1: I32, num2: I32): I32 {
    let mut sum = num1.bits ^ num2.bits;
    let mut carry = (num1.bits & num2.bits) << 1;
    invariant!(|| {
        ensures(
            ((num1.bits as u64) + (num2.bits as u64)) % (1 << 32) == ((sum as u64) + (carry as u64)) % (1 << 32),
        );
    });
    while (carry != 0) {
        let a = sum;
        let b = carry;
        sum = a ^ b;
        carry = (a & b) << 1;
    };
    I32 {
        bits: sum,
    }
}

/*
 ✅ Computes `num1 + num2` with wrapping overflow.
 ⏮️ The function does not abort.
*/
#[spec(prove, target = wrapping_add)]
public fun wrapping_add_spec(num1: I32, num2: I32): I32 {
    let result = wrapping_add(num1, num2);
    ensures(result.bits == (((num1.bits as u64) + (num2.bits as u64)) % (1 << 32)) as u32);
    result
}

public fun shr(v: I32, shift: u8): I32 {
    if (shift == 0) {
        return v
    };
    let mask = 0xffffffff << (32 - shift);
    if (sign(v) == 1) {
        return I32 {
            bits: (v.bits >> shift) | mask,
        }
    };
    I32 {
        bits: v.bits >> shift,
    }
}

public fun sign(v: I32): u8 {
    ((v.bits >> 31) as u8)
}

public native fun ashr(x: u32, y: u32): u32;

/*
 ✅ Computes arithmetic right shift `v >> shift`.
 ⏮️ The function aborts unless `shift < 32`.
*/
#[spec(prove, target = shr)]
public fun shr_spec(v: I32, shift: u8): I32 {
    asserts(shift < 32);
    let result = shr(v, shift);
    ensures(result.bits == ashr(v.bits, shift as u32));
    result
}

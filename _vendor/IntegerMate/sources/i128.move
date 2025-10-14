module integer_mate::i128 {
    use integer_mate::i64;
    use integer_mate::i32;

    const EOverflow: u64 = 0;

    const MIN_AS_U128: u128 = 1 << 127;
    const MAX_AS_U128: u128 = 0x7fffffffffffffffffffffffffffffff;

    const LT: u8 = 0;
    const EQ: u8 = 1;
    const GT: u8 = 2;

    public struct I128 has copy, drop, store {
        bits: u128
    }

    public fun zero(): I128 {
        I128 {
            bits: 0
        }
    }

    public fun from(v: u128): I128 {
        assert!(v <= MAX_AS_U128, EOverflow);
        I128 {
            bits: v
        }
    }

    public fun neg_from(v: u128): I128 {
        assert!(v <= MIN_AS_U128, EOverflow);
        if (v == 0) {
            I128 {
                bits: v
            }
        } else {
            I128 {
                bits: (u128_neg(v)  + 1) | (1 << 127)
            }
        }
    }

    public fun neg(v: I128): I128 {
        if (is_neg(v)) {
            abs(v)
        } else {
            neg_from(v.bits)
        }
    }

    public fun wrapping_add(num1: I128, num2:I128): I128 {
        let mut sum = num1.bits ^ num2.bits;
        let mut carry = (num1.bits & num2.bits) << 1;
        while (carry != 0) {
            let a = sum;
            let b = carry;
            sum = a ^ b;
            carry = (a & b) << 1;
        };
        I128 {
            bits: sum
        }
    }

    public fun add(num1: I128, num2: I128): I128 {
        let sum = wrapping_add(num1, num2);
        let overflow = (sign(num1) & sign(num2) & u8_neg(sign(sum))) + (u8_neg(sign(num1)) & u8_neg(sign(num2)) & sign(sum));
        assert!(overflow == 0, EOverflow);
        sum
    }

    public fun overflowing_add(num1: I128, num2: I128): (I128, bool) {
        let sum = wrapping_add(num1, num2);
        let overflow = (sign(num1) & sign(num2) & u8_neg(sign(sum))) + (u8_neg(sign(num1)) & u8_neg(sign(num2)) & sign(sum));
        (sum, overflow != 0)
    }

    public fun wrapping_sub(num1: I128, num2: I128): I128 {
        let sub_num = wrapping_add(I128 {
            bits: u128_neg(num2.bits)
        }, from(1));
        wrapping_add(num1, sub_num)
    }
    
    public fun sub(num1: I128, num2: I128): I128 {
        let (v, overflow) = overflowing_sub(num1, num2);
        assert!(!overflow, EOverflow);
        v
    }

    public fun overflowing_sub(num1: I128, num2: I128): (I128, bool) {
        let v = wrapping_sub(num1, num2);
        let overflow = sign(num1) != sign(num2) && sign(num1) != sign(v);
        (v, overflow)
    }

    public fun mul(num1: I128, num2: I128): I128 {
        let product = abs_u128(num1) * abs_u128(num2);
        if (sign(num1) != sign(num2)) {
           return neg_from(product)
        };
        return from(product)
    }

    public fun div(num1: I128, num2: I128): I128 {
        let result = abs_u128(num1) / abs_u128(num2);
        if (sign(num1) != sign(num2)) {
           return neg_from(result)
        };
        return from(result)
    }

    public fun abs(v: I128): I128 {
        if (sign(v) == 0) {
            v
        } else {
            assert!(v.bits > MIN_AS_U128, EOverflow);
            I128 {
                bits: u128_neg(v.bits - 1)
            }
        }
    }

    public fun abs_u128(v: I128): u128 {
        if (sign(v) == 0) {
            v.bits
        } else {
            u128_neg(v.bits - 1)
        }
    }

    public fun shl(v: I128, shift: u8): I128 {
        I128 {
            bits: v.bits << shift
        }
    }

    public fun shr(v: I128, shift: u8): I128 {
        if (shift == 0) {
            return v
        };
        let mask = 0xffffffffffffffffffffffffffffffff << (128 - shift);
        if (sign(v) == 1) {
            return I128 {
                bits: (v.bits >> shift) | mask
            }
        };
        I128 {
            bits: v.bits >> shift
        }
    }

    public fun as_u128(v: I128): u128 {
        v.bits
    }

    public fun as_i64(v: I128): i64::I64 {
        if (is_neg(v)) {
           return i64::neg_from((abs_u128(v) as u64))
        } else {
            return i64::from((abs_u128(v) as u64))
        }
    }

    public fun as_i32(v: I128): i32::I32 {
        if (is_neg(v)) {
            return i32::neg_from((abs_u128(v) as u32))
        } else {
            return i32::from((abs_u128(v) as u32))
        }
    }

    public fun sign(v: I128): u8 {
        ((v.bits >> 127) as u8)
    }

    public fun is_neg(v: I128): bool {
        sign(v) == 1
    }

    public fun cmp(num1: I128, num2: I128): u8 {
        if (num1.bits == num2.bits) return EQ;
        if (sign(num1) > sign(num2)) return LT;
        if (sign(num1) < sign(num2)) return GT;
        if (num1.bits > num2.bits) {
            return GT
        } else {
            return LT
        }
    }

    public fun eq(num1: I128, num2: I128): bool {
        num1.bits == num2.bits
    }

    public fun gt(num1: I128, num2: I128): bool {
        cmp(num1, num2) == GT
    }
    
    public fun gte(num1: I128, num2: I128): bool {
        cmp(num1, num2) >= EQ
    }
    
    public fun lt(num1: I128, num2: I128): bool {
        cmp(num1, num2) == LT
    }
    
    public fun lte(num1: I128, num2: I128): bool {
        cmp(num1, num2) <= EQ
    }

    public fun or(num1: I128, num2: I128): I128 {
        I128 {
            bits: (num1.bits | num2.bits)
        }
    }

    public fun and(num1: I128, num2: I128): I128 {
        I128 {
            bits: (num1.bits & num2.bits)
        }
    }

    fun u128_neg(v :u128) : u128 {
        v ^ 0xffffffffffffffffffffffffffffffff
    }

    fun u8_neg(v: u8): u8 {
        v ^ 0xff
    }
}


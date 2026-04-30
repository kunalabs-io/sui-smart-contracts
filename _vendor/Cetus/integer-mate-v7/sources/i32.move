module integer_mate::i32 {
    const EOverflow: u64 = 0;

    const MIN_AS_U32: u32 = 1 << 31;
    const MAX_AS_U32: u32 = 0x7fffffff;

    const LT: u8 = 0;
    const EQ: u8 = 1;
    const GT: u8 = 2;

    public struct I32 has copy, drop, store {
        bits: u32
    }

    public fun zero(): I32 {
        I32 {
            bits: 0
        }
    }

    public fun from_u32(v: u32): I32 {
        I32 {
            bits: v
        }
    }

    public fun from(v: u32): I32 {
        assert!(v <= MAX_AS_U32, EOverflow);
        I32 {
            bits: v
        }
    }

    public fun neg_from(v: u32): I32 {
        assert!(v <= MIN_AS_U32, EOverflow);
        if (v == 0) {
            I32 {
                bits: v
            }
        } else {
            I32 {
                bits: (u32_neg(v) + 1) | (1 << 31)
            }
        }
    }

    public fun wrapping_add(num1: I32, num2: I32): I32 {
        let mut sum = num1.bits ^ num2.bits;
        let mut carry = (num1.bits & num2.bits) << 1;
        while (carry != 0) {
            let a = sum;
            let b = carry;
            sum = a ^ b;
            carry = (a & b) << 1;
        };
        I32 {
            bits: sum
        }
    }

    public fun add(num1: I32, num2: I32): I32 {
        let sum = wrapping_add(num1, num2);
        let overflow = (sign(num1) & sign(num2) & u8_neg(sign(sum))) +
                (u8_neg(sign(num1)) & u8_neg(sign(num2)) & sign(sum));
        assert!(overflow == 0, EOverflow);
        sum
    }

    public fun wrapping_sub(num1: I32, num2: I32): I32 {
        let sub_num = wrapping_add(I32 {
            bits: u32_neg(num2.bits)
        }, from(1));
        wrapping_add(num1, sub_num)
    }

    public fun sub(num1: I32, num2: I32): I32 {
        let v = wrapping_sub(num1, num2);
        let overflow = sign(num1) != sign(num2) && sign(num1) != sign(v);
        assert!(!overflow, EOverflow);
        v
    }

    public fun mul(num1: I32, num2: I32): I32 {
        let product = abs_u32(num1) * abs_u32(num2);
        if (sign(num1) != sign(num2)) {
            return neg_from(product)
        };
        return from(product)
    }

    public fun div(num1: I32, num2: I32): I32 {
        let result = abs_u32(num1) / abs_u32(num2);
        if (sign(num1) != sign(num2)) {
            return neg_from(result)
        };
        return from(result)
    }

    public fun abs(v: I32): I32 {
        if (sign(v) == 0) {
            v
        } else {
            assert!(v.bits > MIN_AS_U32, EOverflow);
            I32 {
                bits: u32_neg(v.bits - 1)
            }
        }
    }

    public fun abs_u32(v: I32): u32 {
        if (sign(v) == 0) {
            v.bits
        } else {
            u32_neg(v.bits - 1)
        }
    }

    public fun shl(v: I32, shift: u8): I32 {
        I32 {
            bits: v.bits << shift
        }
    }

    public fun shr(v: I32, shift: u8): I32 {
        if (shift == 0) {
            return v
        };
        let mask = 0xffffffff << (32 - shift);
        if (sign(v) == 1) {
            return I32 {
                bits: (v.bits >> shift) | mask
            }
        };
        I32 {
            bits: v.bits >> shift
        }
    }

    public fun mod(v: I32, n: I32): I32 {
        if (sign(v) == 1) {
            neg_from((abs_u32(v) % abs_u32(n)))
        } else {
            from((as_u32(v) % abs_u32(n)))
        }
    }

    public fun as_u32(v: I32): u32 {
        v.bits
    }

    public fun sign(v: I32): u8 {
        ((v.bits >> 31) as u8)
    }

    public fun is_neg(v: I32): bool {
        sign(v) == 1
    }

    public fun cmp(num1: I32, num2: I32): u8 {
        if (num1.bits == num2.bits) return EQ;
        if (sign(num1) > sign(num2)) return LT;
        if (sign(num1) < sign(num2)) return GT;
        if (num1.bits > num2.bits) {
            return GT
        } else {
            return LT
        }
    }

    public fun eq(num1: I32, num2: I32): bool {
        num1.bits == num2.bits
    }

    public fun gt(num1: I32, num2: I32): bool {
        cmp(num1, num2) == GT
    }

    public fun gte(num1: I32, num2: I32): bool {
        cmp(num1, num2) >= EQ
    }

    public fun lt(num1: I32, num2: I32): bool {
        cmp(num1, num2) == LT
    }

    public fun lte(num1: I32, num2: I32): bool {
        cmp(num1, num2) <= EQ
    }

    public fun or(num1: I32, num2: I32): I32 {
        I32 {
            bits: (num1.bits | num2.bits)
        }
    }

    public fun and(num1: I32, num2: I32): I32 {
        I32 {
            bits: (num1.bits & num2.bits)
        }
    }

    fun u32_neg(v: u32): u32 {
        v ^ 0xffffffff
    }

    fun u8_neg(v: u8): u8 {
        v ^ 0xff
    }
}
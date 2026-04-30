module integer_mate::i64 {
    const EOverflow: u64 = 0;

    const MIN_AS_U64: u64 = 1 << 63;
    const MAX_AS_U64: u64 = 0x7fffffffffffffff;

    const LT: u8 = 0;
    const EQ: u8 = 1;
    const GT: u8 = 2;

    public struct I64 has copy, drop, store {
        bits: u64
    }

    public fun zero(): I64 {
        I64 {
            bits: 0
        }
    }

    public fun from_u64(v: u64): I64 {
        I64 {
            bits: v
        }
    }

    public fun from(v: u64): I64 {
        assert!(v <= MAX_AS_U64, EOverflow);
        I64 {
            bits: v
        }
    }

    public fun neg_from(v: u64): I64 {
        assert!(v <= MIN_AS_U64, EOverflow);
        if (v == 0) {
            I64 {
                bits: v
            }
        } else {
            I64 {
                bits: (u64_neg(v) + 1) | (1 << 63)
            }
        }
    }

    public fun wrapping_add(num1: I64, num2: I64): I64 {
        let mut sum = num1.bits ^ num2.bits;
        let mut carry = (num1.bits & num2.bits) << 1;
        while (carry != 0) {
            let a = sum;
            let b = carry;
            sum = a ^ b;
            carry = (a & b) << 1;
        };
        I64 {
            bits: sum
        }
    }

    public fun add(num1: I64, num2: I64): I64 {
        let sum = wrapping_add(num1, num2);
        let overflow = (sign(num1) & sign(num2) & u8_neg(sign(sum))) + (u8_neg(sign(num1)) & u8_neg(sign(num2)) & sign(
            sum
        ));
        assert!(overflow == 0, EOverflow);
        sum
    }

    public fun wrapping_sub(num1: I64, num2: I64): I64 {
        let sub_num = wrapping_add(I64 {
            bits: u64_neg(num2.bits)
        }, from(1));
        wrapping_add(num1, sub_num)
    }

    public fun sub(num1: I64, num2: I64): I64 {
        let v = wrapping_sub(num1, num2);
        let overflow = sign(num1) != sign(num2) && sign(num1) != sign(v);
        assert!(!overflow, EOverflow);
        v
    }

    public fun mul(num1: I64, num2: I64): I64 {
        let product = abs_u64(num1) * abs_u64(num2);
        if (sign(num1) != sign(num2)) {
            return neg_from(product)
        };
        return from(product)
    }

    public fun div(num1: I64, num2: I64): I64 {
        let result = abs_u64(num1) / abs_u64(num2);
        if (sign(num1) != sign(num2)) {
            return neg_from(result)
        };
        return from(result)
    }

    public fun abs(v: I64): I64 {
        if (sign(v) == 0) {
            v
        } else {
            assert!(v.bits > MIN_AS_U64, EOverflow);
            I64 {
                bits: u64_neg(v.bits - 1)
            }
        }
    }

    public fun abs_u64(v: I64): u64 {
        if (sign(v) == 0) {
            v.bits
        } else {
            u64_neg(v.bits - 1)
        }
    }

    public fun shl(v: I64, shift: u8): I64 {
        I64 {
            bits: v.bits << shift
        }
    }

    public fun shr(v: I64, shift: u8): I64 {
        if (shift == 0) {
            return v
        };
        let mask = 0xffffffffffffffff << (64 - shift);
        if (sign(v) == 1) {
            return I64 {
                bits: (v.bits >> shift) | mask
            }
        };
        I64 {
            bits: v.bits >> shift
        }
    }

    public fun mod(v: I64, n: I64): I64 {
        if (sign(v) == 1) {
            neg_from((abs_u64(v) % abs_u64(n)))
        } else {
            from((as_u64(v) % abs_u64(n)))
        }
    }

    public fun as_u64(v: I64): u64 {
        v.bits
    }

    public fun sign(v: I64): u8 {
        ((v.bits >> 63) as u8)
    }

    public fun is_neg(v: I64): bool {
        sign(v) == 1
    }

    public fun cmp(num1: I64, num2: I64): u8 {
        if (num1.bits == num2.bits) return EQ;
        if (sign(num1) > sign(num2)) return LT;
        if (sign(num1) < sign(num2)) return GT;
        if (num1.bits > num2.bits) {
            return GT
        } else {
            return LT
        }
    }

    public fun eq(num1: I64, num2: I64): bool {
        num1.bits == num2.bits
    }

    public fun gt(num1: I64, num2: I64): bool {
        cmp(num1, num2) == GT
    }

    public fun gte(num1: I64, num2: I64): bool {
        cmp(num1, num2) >= EQ
    }

    public fun lt(num1: I64, num2: I64): bool {
        cmp(num1, num2) == LT
    }

    public fun lte(num1: I64, num2: I64): bool {
        cmp(num1, num2) <= EQ
    }

    public fun or(num1: I64, num2: I64): I64 {
        I64 {
            bits: (num1.bits | num2.bits)
        }
    }

    public fun and(num1: I64, num2: I64): I64 {
        I64 {
            bits: (num1.bits & num2.bits)
        }
    }

    fun u64_neg(v: u64): u64 {
        v ^ 0xffffffffffffffff
    }

    fun u8_neg(v: u8): u8 {
        v ^ 0xff
    }
}
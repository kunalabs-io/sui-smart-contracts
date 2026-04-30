module integer_mate::math_u64 {
    const MAX_U64: u64 = 0xffffffffffffffff;

    const HI_64_MASK: u128 = 0xffffffffffffffff0000000000000000;
    const LO_64_MASK: u128 = 0x0000000000000000ffffffffffffffff;

    public fun wrapping_add(n1: u64, n2: u64): u64 {
        let (sum, _) = overflowing_add(n1, n2);
        sum
    }

    public fun overflowing_add(n1: u64, n2: u64): (u64, bool) {
        let sum = (n1 as u128) + (n2 as u128);
        if (sum > (MAX_U64 as u128)) {
            (((sum & LO_64_MASK) as u64), true)
        } else {
            ((sum as u64), false)
        }
    }

    public fun wrapping_sub(n1: u64, n2: u64): u64 {
        let (result, _) = overflowing_sub(n1, n2);
        result
    }

    public fun overflowing_sub(n1: u64, n2: u64): (u64, bool) {
        if (n1 >= n2) {
            ((n1 - n2), false)
        } else {
            ((MAX_U64 - n2 + n1 + 1), true)
        }
    }

    public fun wrapping_mul(n1: u64, n2: u64): u64 {
        let (m, _) = overflowing_mul(n1, n2);
        m
    }

    public fun overflowing_mul(n1: u64, n2: u64): (u64, bool) {
        let m = (n1 as u128) * (n2 as u128);
        (((m & LO_64_MASK) as u64), (m & HI_64_MASK) > 0)
    }

    public fun carry_add(n1: u64, n2: u64, carry: u64): (u64, u64) {
        assert!(carry <= 1, 0);
        let sum = (n1 as u128) + (n2 as u128) + (carry as u128);
        if (sum > LO_64_MASK) {
            (((sum & LO_64_MASK) as u64), 1)
        } else {
            ((sum as u64), 0)
        }
    }

    public fun add_check(n1: u64, n2: u64): bool {
        (MAX_U64 - n1 >= n2)
    }
}

#[test_only]
#[allow(deprecated_usage)]
module integer_mate::i64_tests {
    use integer_mate::i64::{
        I64,
        zero,
        from,
        from_u64,
        neg_from,
        abs,
        wrapping_add,
        add,
        sub,
        wrapping_sub,
        mul,
        div,
        shl,
        shr,
        sign,
        cmp,
        eq,
        lt,
        lte,
        gt,
        gte,
        is_neg,
        abs_u64,
        as_u64,
        or,
        and,
        mod
    };
    

    const MIN_AS_U64: u64 = 1 << 63;
    const MAX_AS_U64: u64 = 0x7fffffffffffffff;

    const LT: u8 = 0;
    const EQ: u8 = 1;
    const GT: u8 = 2;

    fun min() : I64 {
        neg_from(MIN_AS_U64)
    }

    fun max() : I64 {
        from(MAX_AS_U64)
    }

    #[test]
    fun test_zero() {
        assert!(as_u64(zero()) == 0, 0);
    }

    #[test]
    fun test_from() {
        assert!(as_u64(from(0)) == 0, 0);
        assert!(as_u64(from(1)) == 1, 0);
        assert!(as_u64(from(MAX_AS_U64)) == MAX_AS_U64, 0);
    }

    #[test]
    fun test_from_u32() {
        assert!(as_u64(from_u64(0)) == 0, 0);
        assert!(as_u64(from_u64(1)) == 1, 0);
        assert!(as_u64(from_u64(MAX_AS_U64)) == MAX_AS_U64, 0);
    }

    #[test]
    #[expected_failure]
    fun test_from_overflow() {
        from(MAX_AS_U64 + 1);
    }

    #[test]
    fun test_neg_from() {
        assert!(as_u64(neg_from(0)) == 0, 0);
        assert!(as_u64(neg_from(1)) == 0xffffffffffffffff, 0);
        assert!(as_u64(min()) == MIN_AS_U64, 0);
    }

    #[test]
    #[expected_failure]
    fun test_neg_from_overflow() {
        neg_from(MIN_AS_U64 + 1);
    }

    #[test]
    fun test_wrapping_add() {
        assert!(as_u64(wrapping_add(from(0), from(1))) == 1, 0);
        assert!(as_u64(wrapping_add(from(1), from(0))) == 1, 0);
        assert!(as_u64(wrapping_add(from(10000), from(99999))) == 109999, 0);
        assert!(as_u64(wrapping_add(from(99999), from(10000))) == 109999, 0);
        assert!(as_u64(wrapping_add(from(MAX_AS_U64 - 1), from(1))) == MAX_AS_U64, 0);
        assert!(as_u64(wrapping_add(from(0), from(0))) == 0, 0);

        assert!(as_u64(wrapping_add(neg_from(0), neg_from(0))) == 0, 1);
        assert!(as_u64(wrapping_add(neg_from(1), neg_from(0))) == 0xffffffffffffffff, 1);
        assert!(as_u64(wrapping_add(neg_from(0), neg_from(1))) == 0xffffffffffffffff, 1);
        assert!(as_u64(wrapping_add(neg_from(10000), neg_from(99999))) == 0xfffffffffffe5251, 1);
        assert!(as_u64(wrapping_add(neg_from(99999), neg_from(10000))) == 0xfffffffffffe5251, 1);
        assert!(as_u64(wrapping_add(neg_from(MIN_AS_U64 - 1), neg_from(1))) == MIN_AS_U64, 1);

        assert!(as_u64(wrapping_add(from(0), neg_from(0))) == 0, 2);
        assert!(as_u64(wrapping_add(neg_from(0), from(0))) == 0, 2);
        assert!(as_u64(wrapping_add(neg_from(1), from(1))) == 0, 2);
        assert!(as_u64(wrapping_add(from(1), neg_from(1))) == 0, 2);
        assert!(as_u64(wrapping_add(from(10000), neg_from(99999))) == 0xfffffffffffea071, 2);
        assert!(as_u64(wrapping_add(from(99999), neg_from(10000))) == 89999, 2);
        assert!(as_u64(wrapping_add(min(), from(1))) == 0x8000000000000001, 2);
        assert!(as_u64(wrapping_add(max(), neg_from(1))) == MAX_AS_U64 - 1, 2);

        assert!(as_u64(wrapping_add(max(), from(1))) == MIN_AS_U64, 2);
    }

    #[test]
    fun test_add() {
    }

    #[test]
    #[expected_failure]
    fun test_add_overflow_max_1() {
        add(max(), from(1));
    }

    #[test]
    #[expected_failure]
    fun test_add_overflow_1_max() {
        add(from(1), max());
    }

    #[test]
    #[expected_failure]
    fun test_add_overflow_max_max() {
        add(max(), max());
    }

    #[test]
    #[expected_failure]
    fun test_add_underflow_min_n1() {
        add(min(), neg_from(1));
    }

    #[test]
    #[expected_failure]
    fun test_add_underflow_min_min() {
        add(min(), min());
    }

    #[test]
    fun test_wrapping_sub() {
        assert!(as_u64(wrapping_sub(from(0), from(0))) == 0, 0);
        assert!(as_u64(wrapping_sub(from(1), from(0))) == 1, 0);
        assert!(as_u64(wrapping_sub(from(0), from(1))) == as_u64(neg_from(1)), 0);
        assert!(as_u64(wrapping_sub(from(1), from(1))) == as_u64(neg_from(0)), 0);
        assert!(as_u64(wrapping_sub(from(1), neg_from(1))) == as_u64(from(2)), 0);
        assert!(as_u64(wrapping_sub(neg_from(1), from(1))) == as_u64(neg_from(2)), 0);
        assert!(as_u64(wrapping_sub(from(1000000), from(1))) == 999999, 0);
        assert!(as_u64(wrapping_sub(neg_from(1000000), neg_from(1))) == as_u64(neg_from(999999)), 0);
        assert!(as_u64(wrapping_sub(from(1), from(1000000))) == as_u64(neg_from(999999)), 0);
        assert!(as_u64(wrapping_sub(max(), max())) == as_u64(from(0)), 0);
        assert!(as_u64(wrapping_sub(max(), from(1))) == as_u64(from(MAX_AS_U64 - 1)), 0);
        assert!(as_u64(wrapping_sub(max(), neg_from(1))) == as_u64(min()), 0);
        assert!(as_u64(wrapping_sub(min(), neg_from(1))) == as_u64(neg_from(MIN_AS_U64 - 1)), 0);
        assert!(as_u64(wrapping_sub(min(), from(1))) == as_u64(max()), 0);
    }

    #[test]
    fun test_sub() {
        assert!(as_u64(sub(from(0), from(0))) == 0, 0);
        assert!(as_u64(sub(from(1), from(0))) == 1, 0);
        assert!(as_u64(sub(from(0), from(1))) == as_u64(neg_from(1)), 0);
        assert!(as_u64(sub(from(1), from(1))) == as_u64(neg_from(0)), 0);
        assert!(as_u64(sub(from(1), neg_from(1))) == as_u64(from(2)), 0);
        assert!(as_u64(sub(neg_from(1), from(1))) == as_u64(neg_from(2)), 0);
        assert!(as_u64(sub(from(1000000), from(1))) == 999999, 0);
        assert!(as_u64(sub(neg_from(1000000), neg_from(1))) == as_u64(neg_from(999999)), 0);
        assert!(as_u64(sub(from(1), from(1000000))) == as_u64(neg_from(999999)), 0);
        assert!(as_u64(sub(max(), max())) == as_u64(from(0)), 0);
        assert!(as_u64(sub(max(), from(1))) == as_u64(from(MAX_AS_U64 - 1)), 0);
        assert!(as_u64(sub(min(), neg_from(1))) == as_u64(neg_from(MIN_AS_U64 - 1)), 0);
    }

    #[test]
    #[expected_failure]
    fun test_sub_overflow_max_n1() {
        sub(max(), neg_from(1));
    }

    #[test]
    #[expected_failure]
    fun test_sub_overflow_n2_max() {
        sub(neg_from(2), max());
    }

    #[test]
    #[expected_failure]
    fun test_sub_overflow_1_min() {
        sub(from(1), min());
    }

    #[test]
    #[expected_failure]
    fun test_sub_overflow_min_1() {
        sub(min(), from(1));
    }

    #[test]
    #[expected_failure]
    fun test_sub_overflow_min_max() {
        sub(min(), max());
    }

    #[test]
    #[expected_failure]
    fun test_sub_overflow_max_min() {
        sub(max(), min());
    }

    #[test]
    fun test_mul() {
        assert!(as_u64(mul(from(1), from(1))) == 1, 0);
        assert!(as_u64(mul(from(10), from(10))) == 100, 0);
        assert!(as_u64(mul(from(100), from(100))) == 10000, 0);
        assert!(as_u64(mul(from(10000), from(10000))) == 100000000, 0);

        assert!(as_u64(mul(neg_from(1), from(1))) == as_u64(neg_from(1)), 0);
        assert!(as_u64(mul(neg_from(10), from(10))) == as_u64(neg_from(100)), 0);
        assert!(as_u64(mul(neg_from(100), from(100))) == as_u64(neg_from(10000)), 0);
        assert!(as_u64(mul(neg_from(10000), from(10000))) == as_u64(neg_from(100000000)), 0);

        assert!(as_u64(mul(from(1), neg_from(1))) == as_u64(neg_from(1)), 0);
        assert!(as_u64(mul(from(10), neg_from(10))) == as_u64(neg_from(100)), 0);
        assert!(as_u64(mul(from(100), neg_from(100))) == as_u64(neg_from(10000)), 0);
        assert!(as_u64(mul(from(10000), neg_from(10000))) == as_u64(neg_from(100000000)), 0);
        assert!(as_u64(mul(from(MIN_AS_U64/2), neg_from(2))) == as_u64(neg_from(MIN_AS_U64)), 0);
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_2_max() {
        mul(from(2), max());
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_max_2() {
        mul(max(), from(2));
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_max_max() {
        mul(max(), max());
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_min_2() {
        mul(min(), from(2));
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_2_min() {
        mul(from(2), min());
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_min_max() {
        mul(min(), max());
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_max_min() {
        mul(max(), min());
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_min_min() {
        mul(min(), min());
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_min_n1() {
        mul(min(), neg_from(1));
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_n1_min() {
        mul(neg_from(1), min());
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_1l64_1l65() {
        mul(from(1<<64), from(1<<65));
    }

    #[test]
    #[expected_failure]
    fun test_mul_overflow_1l64_1l65_neg() {
        mul(neg_from(1<<64), neg_from(1<<65));
    }

    #[test]
    fun test_div() {
        assert!(as_u64(div(from(0), from(1))) == 0, 0);
        assert!(as_u64(div(from(10), from(1))) == 10, 0);
        assert!(as_u64(div(from(10), neg_from(1))) == as_u64(neg_from(10)), 0);
        assert!(as_u64(div(neg_from(10), neg_from(1))) == as_u64(from(10)), 0);
        assert!(as_u64(div(from(100000), from(3))) == 33333, 0);
        assert!(as_u64(div(from(100000), neg_from(3))) == as_u64(neg_from(33333)), 0);
        assert!(as_u64(div(neg_from(100000), from(3))) == as_u64(neg_from(33333)), 0);
        assert!(as_u64(div(neg_from(100000), neg_from(3))) == 33333, 0);
        assert!(as_u64(div(from(99999), from(100000))) == 0, 0);
        assert!(as_u64(div(neg_from(100000), from(99999))) == as_u64(neg_from(1)), 0);
        assert!(as_u64(div(neg_from(100000), neg_from(99999))) == 1, 0);
        assert!(as_u64(div(min(), from(1))) == MIN_AS_U64, 0);
        assert!(as_u64(div(min(), from(2))) == as_u64(neg_from(MIN_AS_U64/2)), 0);
        assert!(as_u64(div(min(), max())) == as_u64(neg_from(1)), 0);
        assert!(as_u64(div(max(), min())) == 0, 0);
        assert!(as_u64(div(min(), neg_from(2))) == as_u64(from(MIN_AS_U64/2)), 0);
        assert!(as_u64(div(max(), from(1))) == MAX_AS_U64, 0);
        assert!(as_u64(div(max(), from(2))) == as_u64(from(MAX_AS_U64/2)), 0);
        assert!(as_u64(div(max(), neg_from(1))) == as_u64(neg_from(MAX_AS_U64)), 0);
        assert!(as_u64(div(max(), neg_from(2))) == as_u64(neg_from(MAX_AS_U64/2)), 0);
    }

    #[test]
    fun test_abs() {
        assert!(as_u64(abs(from(0))) == 0, 0);
        assert!(as_u64(abs(from(1))) == 1, 0);
        assert!(as_u64(abs(from(100000))) == 100000, 0);
        assert!(as_u64(abs(neg_from(1))) == 1, 0);
        assert!(as_u64(abs(neg_from(100000))) == 100000, 0);
        assert!(as_u64(abs(max())) == MAX_AS_U64, 0);
        assert!(as_u64(abs(add(min(), from(1)))) == MAX_AS_U64, 0);
    }

    #[test]
    #[expected_failure]
    fun test_abs_overflow() {
        abs(min());
    }

    #[test]
    fun test_abs_u64() {
        assert!(abs_u64(from(0)) == 0, 0);
        assert!(abs_u64(from(1)) == 1, 0);
        assert!(abs_u64(from(100000)) == 100000, 0);
        assert!(abs_u64(neg_from(0)) == 0, 0);
        assert!(abs_u64(neg_from(1)) == 1, 0);
        assert!(abs_u64(neg_from(100000)) == 100000, 0);
        assert!(abs_u64(max()) == MAX_AS_U64, 0);
        assert!(abs_u64(min()) == MAX_AS_U64 + 1, 0);
    }

    #[test]
    fun test_shl() {
        assert!(as_u64(shl(from(10), 0)) == 10, 0);
        assert!(as_u64(shl(neg_from(10), 0)) == as_u64(neg_from(10)), 0);

        assert!(as_u64(shl(from(10), 1)) == 20, 0);
        assert!(as_u64(shl(neg_from(10), 1)) == as_u64(neg_from(20)), 0);

        assert!(as_u64(shl(from(10), 8)) == 2560, 0);
        assert!(as_u64(shl(neg_from(10), 8)) == as_u64(neg_from(2560)), 0);

        assert!(as_u64(shl(from(10), 32)) == 42949672960, 0);
        assert!(as_u64(shl(neg_from(10), 32)) == as_u64(neg_from(42949672960)), 0);

        assert!(as_u64(shl(from(10), 63)) == 0, 0);
        assert!(as_u64(shl(neg_from(10), 63)) == 0, 0);
    }

    #[test]
    fun test_shr() {
        assert!(as_u64(shr(from(10), 0)) == 10, 0);
        assert!(as_u64(shr(neg_from(10), 0)) == as_u64(neg_from(10)), 0);

        assert!(as_u64(shr(from(10), 1)) == 5, 0);
        assert!(as_u64(shr(neg_from(10), 1)) == as_u64(neg_from(5)), 0);

        assert!(as_u64(shr(max(), 8)) == 36028797018963967, 0);
        assert!(as_u64(shr(min(), 8)) == 0xff80000000000000, 0);

        assert!(as_u64(shr(max(), 32)) == 2147483647, 0);
        assert!(as_u64(shr(min(), 32)) == 0xffffffff80000000, 0);

        assert!(as_u64(shr(max(), 63)) == 0, 0);
        assert!(as_u64(shr(min(), 63)) == 0xffffffffffffffff, 0);
    }

    #[test]
    fun test_sign() {
        assert!(sign(from(0)) == 0, 0);
        assert!(sign(from(1)) == 0, 0);
        assert!(sign(from(100000)) == 0, 0);
        assert!(sign(neg_from(0)) == 0, 0);
        assert!(sign(neg_from(1)) == 1, 0);
        assert!(sign(neg_from(100000)) == 1, 0);
        assert!(sign(max()) == 0, 0);
        assert!(sign(min()) == 1, 0);
    }

    #[test]
    fun test_is_neg() {
        assert!(is_neg(from(0)) == false, 0);
        assert!(is_neg(from(1)) == false, 0);
        assert!(is_neg(from(100000)) == false, 0);
        assert!(is_neg(neg_from(0)) == false, 0);
        assert!(is_neg(neg_from(1)) == true, 0);
        assert!(is_neg(neg_from(100000)) == true, 0);
        assert!(is_neg(max()) == false, 0);
        assert!(is_neg(min()) == true, 0);
    }

    #[test]
    fun test_cmp() {
        assert!(cmp(from(1), from(0)) == GT, 0);
        assert!(cmp(from(0), from(1)) == LT, 0);

        assert!(cmp(from(0), neg_from(1)) == GT, 0);
        assert!(cmp(neg_from(0), neg_from(1)) == GT, 0);
        assert!(cmp(neg_from(1), neg_from(0)) == LT, 0);

        assert!(cmp(min(), max()) == LT, 0);
        assert!(cmp(max(), min()) == GT, 0);

        assert!(cmp(max(), from(MAX_AS_U64-1)) == GT, 0);
        assert!(cmp(from(MAX_AS_U64-1), max()) == LT, 0);

        assert!(cmp(min(), neg_from(MIN_AS_U64-1)) == LT, 0);
        assert!(cmp(neg_from(MIN_AS_U64-1), min()) == GT, 0);
    }

    #[test]
    fun test_eq() {
        assert!(eq(from(0), from(0)) == true, 0);
        assert!(eq(from(1), from(1)) == true, 0);
        assert!(eq(from(100000), from(100000)) == true, 0);
        assert!(eq(neg_from(0), neg_from(0)) == true, 0);
        assert!(eq(neg_from(1), neg_from(1)) == true, 0);
        assert!(eq(neg_from(100000), neg_from(100000)) == true, 0);
        assert!(eq(from(100000), neg_from(0)) == false, 0);
        assert!(eq(max(), max()) == true, 0);
        assert!(eq(min(), min()) == true, 0);
        assert!(eq(from(1), from(0)) == false, 0);
        assert!(eq(from(0), from(1)) == false, 0);
        assert!(eq(neg_from(1), neg_from(0)) == false, 0);
        assert!(eq(neg_from(0), neg_from(1)) == false, 0);
        assert!(eq(max(), min()) == false, 0);
        assert!(eq(min(), max()) == false, 0);
    }

    #[test]
    fun test_gt() {
        assert!(gt(from(0), from(0)) == false, 0);
        assert!(gt(from(1), from(0)) == true, 0);
        assert!(gt(from(0), from(1)) == false, 0);
        assert!(gt(from(0), neg_from(1)) == true, 0);
        assert!(gt(neg_from(1), neg_from(0)) == false, 0);
        assert!(gt(neg_from(0), from(1)) == false, 0);
        assert!(gt(from(100000), from(100000)) == false, 0);
        assert!(gt(neg_from(0), neg_from(1)) == true, 0);
        assert!(gt(from(100000), neg_from(0)) == true, 0);
        assert!(gt(neg_from(100000), neg_from(100001)) == true, 0);
        assert!(gt(from(100000), from(100001)) == false, 0);
        assert!(gt(max(), min()) == true, 0);
        assert!(gt(min(), max()) == false, 0);
        assert!(gt(max(), max()) == false, 0);
        assert!(gt(min(), min()) == false, 0);
        assert!(gt(max(), min()) == true, 0);
        assert!(gt(min(), max()) == false, 0);
    }

    #[test]
    fun test_gte() {
        assert!(gte(from(0), from(0)) == true, 0);
        assert!(gte(from(1), from(0)) == true, 0);
        assert!(gte(from(0), from(1)) == false, 0);
        assert!(gte(from(0), neg_from(1)) == true, 0);
        assert!(gte(neg_from(1), neg_from(0)) == false, 0);
        assert!(gte(neg_from(0), from(1)) == false, 0);
        assert!(gte(from(100000), from(100000)) == true, 0);
        assert!(gte(from(100000), neg_from(100000)) == true, 0);
        assert!(gte(neg_from(100000), from(100000)) == false, 0);
        assert!(gte(neg_from(100000), neg_from(100000)) == true, 0);
        assert!(gte(max(), min()) == true, 0);
        assert!(gte(min(), max()) == false, 0);
        assert!(gte(max(), max()) == true, 0);
        assert!(gte(min(), min()) == true, 0);
    }

    #[test]
    fun test_lt() {
        assert!(lt(from(0), from(0)) == false, 0);
        assert!(lt(from(1), from(0)) == false, 0);
        assert!(lt(from(0), from(1)) == true, 0);
        assert!(lt(from(0), neg_from(1)) == false, 0);
        assert!(lt(neg_from(1), neg_from(0)) == true, 0);
        assert!(lt(neg_from(0), from(1)) == true, 0);
        assert!(lt(from(100000), from(100000)) == false, 0);
        assert!(lt(from(100000), neg_from(0)) == false, 0);
        assert!(lt(neg_from(0), from(100000)) == true, 0);
        assert!(lt(neg_from(100000), from(100000)) == true, 0);
        assert!(lt(neg_from(100000), neg_from(100001)) == false, 0);
        assert!(lt(from(100000), from(100001)) == true, 0);
        assert!(lt(neg_from(100001), neg_from(100000)) == true, 0);
        assert!(lt(max(), min()) == false, 0);
        assert!(lt(min(), max()) == true, 0);
        assert!(lt(max(), max()) == false, 0);
        assert!(lt(min(), min()) == false, 0);
    }

    #[test]
    fun test_lte() {
        assert!(lte(from(0), from(0)) == true, 0);
        assert!(lte(from(1), from(0)) == false, 0);
        assert!(lte(from(0), from(1)) == true, 0);
        assert!(lte(from(0), neg_from(1)) == false, 0);
        assert!(lte(neg_from(1), neg_from(0)) == true, 0);
        assert!(lte(neg_from(0), from(1)) == true, 0);
        assert!(lte(from(100000), from(100000)) == true, 0);
        assert!(lte(from(100000), neg_from(0)) == false, 0);
        assert!(lte(neg_from(0), from(100000)) == true, 0);
        assert!(lte(neg_from(100000), from(100000)) == true, 0);
        assert!(lte(neg_from(100000), neg_from(100001)) == false, 0);
        assert!(lte(from(100000), from(100001)) == true, 0);
        assert!(lte(neg_from(100001), neg_from(100000)) == true, 0);
        assert!(lte(max(), min()) == false, 0);
        assert!(lte(min(), max()) == true, 0);
        assert!(lte(max(), max()) == true, 0);
        assert!(lte(min(), min()) == true, 0);
    }

    #[test]
    fun test_or() {
        // 0 | 0 = 0
        assert!(as_u64(or(from(0), from(0))) == 0, 0);
        // 0 | 1 = 1
        assert!(as_u64(or(from(0), from(1))) == 1, 0);
        // 1 | 0 = 1
        assert!(as_u64(or(from(1), from(0))) == 1, 0);
        // 1 | 1 = 1
        assert!(as_u64(or(from(1), from(1))) == 1, 0);
        // -1 | -1 = -1
        assert!(as_u64(or(neg_from(1), neg_from(1))) == 0xffffffffffffffff, 0);
        // 1 | 100000 = 100001
        assert!(as_u64(or(from(1), from(100000))) == 0x186a1, 0);
        // 1 | -100000 = -99999
        assert!(as_u64(or(from(1), neg_from(100000))) == 0xfffffffffffe7961, 0);
        // -1000000 | 1 = -999999
        assert!(as_u64(or(neg_from(1000000), from(1))) == 0xfffffffffff0bdc1, 0);
        // -1000000 | -1 = -1
        assert!(as_u64(or(neg_from(1000000), neg_from(1))) == 0xffffffffffffffff, 0);
        // -1000000 | 1000000 = -64
        assert!(as_u64(or(neg_from(1000000), from(1000000))) == 0xffffffffffffffc0, 0);
        // -9223372036854775808 | 0 = -9223372036854775808
        assert!(as_u64(or(min(), from(0))) == 0x8000000000000000, 0);
        // -9223372036854775808 | -9223372036854775808 = -9223372036854775808
        assert!(as_u64(or(min(), min())) == 0x8000000000000000, 0);
        // -9223372036854775808 | -100000 = -100000
        assert!(as_u64(or(min(), neg_from(100000))) == 0xfffffffffffe7960, 0);
        // -9223372036854775808 | 9223372036854775807 = -1
        assert!(as_u64(or(min(), max())) == 0xffffffffffffffff, 0);
        // 9223372036854775807 | 0 = 9223372036854775807
        assert!(as_u64(or(max(), from(0))) == 0x7fffffffffffffff, 0);
        // 9223372036854775807 | 1 = 9223372036854775807
        assert!(as_u64(or(max(), from(1))) == 0x7fffffffffffffff, 0);
        // 9223372036854775807 | 9223372036854775807 = 9223372036854775807
        assert!(as_u64(or(max(), max())) == 0x7fffffffffffffff, 0);
    }

    #[test]
    fun test_and() {
        // 0 | 0 = 0
        assert!(as_u64(and(from(0), from(0))) == 0, 0);
        // 0 | 1 = 0
        assert!(as_u64(and(from(0), from(1))) == 0, 0);
        // 1 | 0 = 0
        assert!(as_u64(and(from(1), from(0))) == 0, 0);
        // 1 | 1 = 1
        assert!(as_u64(and(from(1), from(1))) == 1, 0);
        // -1 | -1 = -1
        assert!(as_u64(and(neg_from(1), neg_from(1))) == 0xffffffffffffffff, 0);
        // 1 | 100000 = 0
        assert!(as_u64(and(from(1), from(100000))) == 0, 0);
        // 1 | -100000 = 0
        assert!(as_u64(and(from(1), neg_from(100000))) == 0, 0);
        // -1000000 | 1 = 0
        assert!(as_u64(and(neg_from(1000000), from(1))) == 0, 0);
        // -1000000 | -1 = -1000000
        assert!(as_u64(and(neg_from(1000000), neg_from(1))) == 0xfffffffffff0bdc0, 0);
        // -1000000 | 1000000 = 64
        assert!(as_u64(and(neg_from(1000000), from(1000000))) == 64, 0);
        // -9223372036854775808 | 0 = 0
        assert!(as_u64(and(min(), from(0))) == 0, 0);
        // -9223372036854775808 | -9223372036854775808 = -9223372036854775808
        assert!(as_u64(and(min(), min())) == 0x8000000000000000, 0);
        // -9223372036854775808 | -100000 = -9223372036854775808
        assert!(as_u64(and(min(), neg_from(100000))) == 0x8000000000000000, 0);
        // -9223372036854775808 | 9223372036854775807 = 0
        assert!(as_u64(and(min(), max())) == 0, 0);
        // 9223372036854775807 | 0 = 0
        assert!(as_u64(and(max(), from(0))) == 0, 0);
        // 9223372036854775807 | 1 = 1
        assert!(as_u64(and(max(), from(1))) == 1, 0);
        // 9223372036854775807 | 9223372036854775807 = 9223372036854775807
        assert!(as_u64(and(max(), max())) == 0x7fffffffffffffff, 0);
    }

    #[test]
    fun test_mod() {
        //use aptos_std::debug;
        let mut i = mod(neg_from(2), from(5));
        assert!(cmp(i, neg_from(2)) == EQ, 0);

        i = mod(neg_from(2), neg_from(5));
        assert!(cmp(i, neg_from(2)) == EQ, 0);

        i = mod(from(2), from(5));
        assert!(cmp(i, from(2)) == EQ, 0);

        i = mod(from(2), neg_from(5));
        assert!(cmp(i, from(2)) == EQ, 0);
    }
}


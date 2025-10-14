#[test_only]
#[allow(deprecated_usage)]
module integer_mate::i32_tests {
    use integer_mate::i32::{
        I32,
        zero,
        from,
        from_u32,
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
        abs_u32,
        or,
        and,
        mod
    };
    use integer_mate::i32::as_u32;
    

    const MIN_AS_U32: u32 = 1 << 31;
    const MAX_AS_U32: u32 = 0x7fffffff;

    const LT: u8 = 0;
    const EQ: u8 = 1;
    const GT: u8 = 2;

    fun min() : I32 {
        neg_from(0x80000000)
    }

    fun max() : I32 {
        from(0x7fffffff)
    }

    #[test]
    fun test_zero() {
        assert!(as_u32(zero()) == 0, 0);
    }

    #[test]
    fun test_from() {
        assert!(as_u32(from(0)) == 0, 0);
        assert!(as_u32(from(1)) == 1, 0);
        assert!(as_u32(from(MAX_AS_U32)) == MAX_AS_U32, 0);
    }

    #[test]
    fun test_from_u32() {
        assert!(as_u32(from_u32(0)) == 0, 0);
        assert!(as_u32(from_u32(1)) == 1, 0);
        assert!(as_u32(from_u32(MAX_AS_U32)) == MAX_AS_U32, 0);
    }

    #[test]
    #[expected_failure]
    fun test_from_overflow() {
        from(MAX_AS_U32 + 1);
    }

    #[test]
    fun test_neg_from() {
        assert!(as_u32(neg_from(0)) == 0, 0);
        assert!(as_u32(neg_from(1)) == 0xffffffff, 0);
        assert!(as_u32(neg_from(MIN_AS_U32)) == MIN_AS_U32, 0);
    }

    #[test]
    #[expected_failure]
    fun test_neg_from_overflow() {
        neg_from(MIN_AS_U32 + 1);
    }

    #[test]
    fun test_wrapping_add() {
        // wrapping_add(0 + 0) = 0
        assert!(as_u32(wrapping_add(from(0), from(0))) == 0, 0);
        // wrapping_add(0 + 1) = 1
        assert!(as_u32(wrapping_add(from(0), from(1))) == 1, 0);
        // wrapping_add(1 + 0) = 1
        assert!(as_u32(wrapping_add(from(1), from(0))) == 1, 0);
        // wrapping_add(1 + 1) = 2
        assert!(as_u32(wrapping_add(from(1), from(1))) == 2, 0);
        // wrapping_add(-1 + -1) = -2
        assert!(as_u32(wrapping_add(neg_from(1), neg_from(1))) == 0xfffffffe, 0);
        // wrapping_add(1 + 100000) = 100001
        assert!(as_u32(wrapping_add(from(1), from(100000))) == 0x186a1, 0);
        // wrapping_add(1 + -100000) = -99999
        assert!(as_u32(wrapping_add(from(1), neg_from(100000))) == 0xfffe7961, 0);
        // wrapping_add(-1000000 + 1) = -999999
        assert!(as_u32(wrapping_add(neg_from(1000000), from(1))) == 0xfff0bdc1, 0);
        // wrapping_add(-1000000 + -1) = -1000001
        assert!(as_u32(wrapping_add(neg_from(1000000), neg_from(1))) == 0xfff0bdbf, 0);
        // wrapping_add(-1000000 + 1000000) = 0
        assert!(as_u32(wrapping_add(neg_from(1000000), from(1000000))) == 0, 0);
        // wrapping_add(-2147483648 + 0) = -2147483648
        assert!(as_u32(wrapping_add(min(), from(0))) == 0x80000000, 0);
        // wrapping_add(-2147483648 + -1) = 2147483647
        assert!(as_u32(wrapping_add(min(), neg_from(1))) == 0x7fffffff, 0);
        // wrapping_add(-2147483648 + -1000000) = 2146483648
        assert!(as_u32(wrapping_add(min(), neg_from(1000000))) == 0x7ff0bdc0, 0);
        // wrapping_add(-2147483648 + -2147483647) = 1
        assert!(as_u32(wrapping_add(min(), neg_from(0x7fffffff))) == 1, 0);
        // wrapping_add(-2147483648 + -2147483648) = 0
        assert!(as_u32(wrapping_add(min(), min())) == 0, 0);
        // wrapping_add(2147483647 + 0) = 2147483647
        assert!(as_u32(wrapping_add(max(), from(0))) == 0x7fffffff, 0);
        // wrapping_add(2147483647 + 1) = -2147483648
        assert!(as_u32(wrapping_add(max(), from(1))) == 0x80000000, 0);
        // wrapping_add(2147483647 + -1) = 2147483646
        assert!(as_u32(wrapping_add(max(), neg_from(1))) == 0x7ffffffe, 0);
        // wrapping_add(2147483647 + 10000000) = -2137483649
        assert!(as_u32(wrapping_add(max(), from(0x989680))) == 0x8098967f, 0);
        // wrapping_add(2147483647 + 2147483647) = -2
        assert!(as_u32(wrapping_add(max(), max())) == 0xfffffffe, 0);
    }

    #[test]
    fun test_add() {
        assert!(as_u32(add(from(0), from(0))) == 0, 0);
        assert!(as_u32(add(from(0), from(1))) == 1, 0);
        assert!(as_u32(add(from(1), from(0))) == 1, 0);
        // 1 + 100000 = 100001
        assert!(as_u32(add(from(1), from(100000))) == 0x186a1, 0);
        // 1 + -100000 = -99999
        assert!(as_u32(add(from(1), neg_from(100000))) == 0xfffe7961, 0);
        // -1000000 + 1 = -999999
        assert!(as_u32(add(neg_from(1000000), from(1))) == 0xfff0bdc1, 0);
        // -1000000 + -1 = -1000001
        assert!(as_u32(add(neg_from(1000000), neg_from(1))) == 0xfff0bdbf, 0);
        // -1000000 + 1000000 = 0
        assert!(as_u32(add(neg_from(1000000), from(1000000))) == 0, 0);
        // -2147483648 + 0 = -2147483648
        assert!(as_u32(add(min(), from(0))) == 0x80000000, 0);
        // -2147483648 + 100000 = -2147383648
        assert!(as_u32(add(min(), from(100000))) == 0x800186a0, 0);
        // -2147483648 + 2147483647 = -1
        assert!(as_u32(add(min(), max())) == 0xffffffff, 0);
        // 2147483637 + 1 = 2147483638
        assert!(as_u32(add(from(0x7ffffff5), from(1))) == 0x7ffffff6, 0);
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
        add(neg_from(MIN_AS_U32), neg_from(1));
    }

    #[test]
    #[expected_failure]
    fun test_add_underflow_min_min() {
        add(min(), min());
    }

    #[test]
    fun test_wrapping_sub() {
        // wrapping_sub(0 - 0) = 0
        assert!(as_u32(wrapping_sub(from(0), from(0))) == 0, 0);
        // wrapping_sub(0 - 1) = -1
        assert!(as_u32(wrapping_sub(from(0), from(1))) == 0xffffffff, 0);
        // wrapping_sub(1 - 0) = 1
        assert!(as_u32(wrapping_sub(from(1), from(0))) == 1, 0);
        // wrapping_sub(1 - 1) = 0
        assert!(as_u32(wrapping_sub(from(1), from(1))) == 0, 0);
        // wrapping_sub(-1 - -1) = 0
        assert!(as_u32(wrapping_sub(neg_from(1), neg_from(1))) == 0, 0);
        // wrapping_sub(1 - 100000) = -99999
        assert!(as_u32(wrapping_sub(from(1), from(100000))) == 0xfffe7961, 0);
        // wrapping_sub(1 - -100000) = 100001
        assert!(as_u32(wrapping_sub(from(1), neg_from(100000))) == 0x186a1, 0);
        // wrapping_sub(-1000000 - 1) = -1000001
        assert!(as_u32(wrapping_sub(neg_from(1000000), from(1))) == 0xfff0bdbf, 0);
        // wrapping_sub(-1000000 - -1) = -999999
        assert!(as_u32(wrapping_sub(neg_from(1000000), neg_from(1))) == 0xfff0bdc1, 0);
        // wrapping_sub(-1000000 - 1000000) = -2000000
        assert!(as_u32(wrapping_sub(neg_from(1000000), from(1000000))) == 0xffe17b80, 0);
        // wrapping_sub(-2147483648 - 0) = -2147483648
        assert!(as_u32(wrapping_sub(min(), from(0))) == 0x80000000, 0);
        // wrapping_sub(-2147483648 - 1) = 2147483647
        assert!(as_u32(wrapping_sub(min(), from(1))) == 0x7fffffff, 0);
        // wrapping_sub(-2147483648 - 1000000) = 2146483648
        assert!(as_u32(wrapping_sub(min(), from(1000000))) == 0x7ff0bdc0, 0);
        // wrapping_sub(-2147483648 - 2147483647) = 1
        assert!(as_u32(wrapping_sub(min(), max())) == 1, 0);
        // wrapping_sub(2147483647 - 0) = 2147483647
        assert!(as_u32(wrapping_sub(max(), from(0))) == 0x7fffffff, 0);
        // wrapping_sub(2147483647 - -1) = -2147483648
        assert!(as_u32(wrapping_sub(max(), neg_from(1))) == 0x80000000, 0);
        // wrapping_sub(2147483647 - -10000000) = -2137483649
        assert!(as_u32(wrapping_sub(max(), neg_from(0x989680))) == 0x8098967f, 0);
        // wrapping_sub(2147483647 - -2147483647) = -2
        assert!(as_u32(wrapping_sub(max(), neg_from(0x7fffffff))) == 0xfffffffe, 0);
        // wrapping_sub(2147483647 - -2147483648) = -1
        assert!(as_u32(wrapping_sub(max(), min())) == 0xffffffff, 0);
    }

    #[test]
    fun test_sub() {
        // 0 - 0 = 0
        assert!(as_u32(sub(from(0), from(0))) == 0, 0);
        // 0 - 1 = -1
        assert!(as_u32(sub(from(0), from(1))) == 0xffffffff, 0);
        // 1 - 0 = 1
        assert!(as_u32(sub(from(1), from(0))) == 1, 0);
        // 1 - 1 = 0
        assert!(as_u32(sub(from(1), from(1))) == 0, 0);
        // -1 - -1 = 0
        assert!(as_u32(sub(neg_from(1), neg_from(1))) == 0, 0);
        // 1 - 100000 = -99999
        assert!(as_u32(sub(from(1), from(100000))) == 0xfffe7961, 0);
        // 1 - -100000 = 100001
        assert!(as_u32(sub(from(1), neg_from(100000))) == 0x186a1, 0);
        // -1000000 - 1 = -1000001
        assert!(as_u32(sub(neg_from(1000000), from(1))) == 0xfff0bdbf, 0);
        // -1000000 - -1 = -999999
        assert!(as_u32(sub(neg_from(1000000), neg_from(1))) == 0xfff0bdc1, 0);
        // -1000000 - 1000000 = -2000000
        assert!(as_u32(sub(neg_from(1000000), from(1000000))) == 0xffe17b80, 0);
        // -2147483648 - 0 = -2147483648
        assert!(as_u32(sub(min(), from(0))) == 0x80000000, 0);
        // -2147483648 - -100000 = -2147383648
        assert!(as_u32(sub(min(), neg_from(100000))) == 0x800186a0, 0);
        // -2147483648 - -2147483648 = 0
        assert!(as_u32(sub(min(), min())) == 0, 0);
        // 2147483647 - 0 = 2147483647
        assert!(as_u32(sub(max(), from(0))) == 0x7fffffff, 0);
        // 2147483647 - 1 = 2147483646
        assert!(as_u32(sub(max(), from(1))) == 0x7ffffffe, 0);
        // 2147483637 - 1 = 2147483636
        assert!(as_u32(sub(from(0x7ffffff5), from(1))) == 0x7ffffff4, 0);
        // 2147483647 - 100000000 = 2047483647
        assert!(as_u32(sub(max(), from(0x5f5e100))) == 0x7a0a1eff, 0);
        // 2147483647 - 2147483647 = 0
        assert!(as_u32(sub(max(), max())) == 0, 0);
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
        assert!(as_u32(mul(from(1), from(1))) == 1, 0);
        assert!(as_u32(mul(from(10), from(10))) == 100, 0);
        assert!(as_u32(mul(from(100), from(100))) == 10000, 0);
        assert!(as_u32(mul(from(10000), from(10000))) == 100000000, 0);

        assert!(as_u32(mul(neg_from(1), from(1))) == as_u32(neg_from(1)), 0);
        assert!(as_u32(mul(neg_from(10), from(10))) == as_u32(neg_from(100)), 0);
        assert!(as_u32(mul(neg_from(100), from(100))) == as_u32(neg_from(10000)), 0);
        assert!(as_u32(mul(neg_from(10000), from(10000))) == as_u32(neg_from(100000000)), 0);

        assert!(as_u32(mul(from(1), neg_from(1))) == as_u32(neg_from(1)), 0);
        assert!(as_u32(mul(from(10), neg_from(10))) == as_u32(neg_from(100)), 0);
        assert!(as_u32(mul(from(100), neg_from(100))) == as_u32(neg_from(10000)), 0);
        assert!(as_u32(mul(from(10000), neg_from(10000))) == as_u32(neg_from(100000000)), 0);
        assert!(as_u32(mul(from(MIN_AS_U32/2), neg_from(2))) == as_u32(neg_from(MIN_AS_U32)), 0);
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
        assert!(as_u32(div(from(0), from(1))) == 0, 0);
        assert!(as_u32(div(from(10), from(1))) == 10, 0);
        assert!(as_u32(div(from(10), neg_from(1))) == as_u32(neg_from(10)), 0);
        assert!(as_u32(div(neg_from(10), neg_from(1))) == as_u32(from(10)), 0);
        assert!(as_u32(div(from(100000), from(3))) == 33333, 0);
        assert!(as_u32(div(from(100000), neg_from(3))) == as_u32(neg_from(33333)), 0);
        assert!(as_u32(div(neg_from(100000), from(3))) == as_u32(neg_from(33333)), 0);
        assert!(as_u32(div(neg_from(100000), neg_from(3))) == 33333, 0);
        assert!(as_u32(div(from(99999), from(100000))) == 0, 0);
        assert!(as_u32(div(neg_from(100000), from(99999))) == as_u32(neg_from(1)), 0);
        assert!(as_u32(div(neg_from(100000), neg_from(99999))) == 1, 0);
        assert!(as_u32(div(min(), from(1))) == MIN_AS_U32, 0);
        assert!(as_u32(div(min(), from(2))) == as_u32(neg_from(MIN_AS_U32/2)), 0);
        assert!(as_u32(div(min(), max())) == as_u32(neg_from(1)), 0);
        assert!(as_u32(div(max(), min())) == 0, 0);
        assert!(as_u32(div(min(), neg_from(2))) == as_u32(from(MIN_AS_U32/2)), 0);
        assert!(as_u32(div(max(), from(1))) == MAX_AS_U32, 0);
        assert!(as_u32(div(max(), from(2))) == as_u32(from(MAX_AS_U32/2)), 0);
        assert!(as_u32(div(max(), neg_from(1))) == as_u32(neg_from(MAX_AS_U32)), 0);
        assert!(as_u32(div(max(), neg_from(2))) == as_u32(neg_from(MAX_AS_U32/2)), 0);
    }

    #[test]
    fun test_abs() {
        assert!(as_u32(abs(from(0))) == 0, 0);
        assert!(as_u32(abs(from(1))) == 1, 0);
        assert!(as_u32(abs(from(100000))) == 100000, 0);
        assert!(as_u32(abs(neg_from(1))) == 1, 0);
        assert!(as_u32(abs(neg_from(100000))) == 100000, 0);
        assert!(as_u32(abs(max())) == MAX_AS_U32, 0);
        assert!(as_u32(abs(add(min(), from(1)))) == MAX_AS_U32, 0);
    }

    #[test]
    #[expected_failure]
    fun test_abs_overflow() {
        abs(min());
    }

    #[test]
    fun test_abs_u32() {
        assert!(abs_u32(from(0)) == 0, 0);
        assert!(abs_u32(from(1)) == 1, 0);
        assert!(abs_u32(from(100000)) == 100000, 0);
        assert!(abs_u32(neg_from(0)) == 0, 0);
        assert!(abs_u32(neg_from(1)) == 1, 0);
        assert!(abs_u32(neg_from(100000)) == 100000, 0);
        assert!(abs_u32(max()) == MAX_AS_U32, 0);
        assert!(abs_u32(min()) == MAX_AS_U32 + 1, 0);
    }

    #[test]
    fun test_shl() {
        // 0 << 0 = 0
        assert!(as_u32(shl(from(0), 0)) == 0, 0);
        // 0 << 31 = 0
        assert!(as_u32(shl(from(0), 31)) == 0, 0);
        // 1 << 1 = 2
        assert!(as_u32(shl(from(1), 1)) == 2, 0);
        // 2 << 1 = 4
        assert!(as_u32(shl(from(2), 1)) == 4, 0);
        // 1 << 31 = -2147483648
        assert!(as_u32(shl(from(1), 31)) == 0x80000000, 0);
        // 10 << 20 = 10485760
        assert!(as_u32(shl(from(10), 20)) == 0xa00000, 0);
        // 2147483647 << 0 = 2147483647
        assert!(as_u32(shl(max(), 0)) == 0x7fffffff, 0);
        // 2147483647 << 10 = -1024
        assert!(as_u32(shl(max(), 10)) == 0xfffffc00, 0);
        // 2147483647 << 31 = -2147483648
        assert!(as_u32(shl(max(), 31)) == 0x80000000, 0);
        // -2147483648 << 0 = -2147483648
        assert!(as_u32(shl(min(), 0)) == 0x80000000, 0);
        // -2147483648 << 1 = 0
        assert!(as_u32(shl(min(), 1)) == 0, 0);
        // -2147483648 << 31 = 0
        assert!(as_u32(shl(min(), 31)) == 0, 0);
    }

    #[test]
    fun test_shr() {
        // 0 >> 0 = 0
        assert!(as_u32(shr(from(0), 0)) == 0, 0);
        // 0 >> 1 = 0
        assert!(as_u32(shr(from(0), 1)) == 0, 0);
        // 0 >> 31 = 0
        assert!(as_u32(shr(from(0), 31)) == 0, 0);
        // 1 >> 1 = 0
        assert!(as_u32(shr(from(1), 1)) == 0, 0);
        // 2 >> 1 = 1
        assert!(as_u32(shr(from(2), 1)) == 1, 0);
        // 1 >> 31 = 0
        assert!(as_u32(shr(from(1), 31)) == 0, 0);
        // 10 >> 20 = 0
        assert!(as_u32(shr(from(10), 20)) == 0, 0);
        // 2147483647 >> 0 = 2147483647
        assert!(as_u32(shr(max(), 0)) == 0x7fffffff, 0);
        // 2147483647 >> 1 = 1073741823
        assert!(as_u32(shr(max(), 1)) == 0x3fffffff, 0);
        // 2147483647 >> 10 = 2097151
        assert!(as_u32(shr(max(), 10)) == 0x1fffff, 0);
        // 2147483647 >> 31 = 0
        assert!(as_u32(shr(max(), 31)) == 0, 0);
        // -2147483648 >> 0 = -2147483648
        assert!(as_u32(shr(min(), 0)) == 0x80000000, 0);
        // -2147483648 >> 1 = -1073741824
        assert!(as_u32(shr(min(), 1)) == 0xc0000000, 0);
        // -2147483648 >> 10 = -2097152
        assert!(as_u32(shr(min(), 10)) == 0xffe00000, 0);
        // -2147483648 >> 31 = -1
        assert!(as_u32(shr(min(), 31)) == 0xffffffff, 0);
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

        assert!(cmp(neg_from(MIN_AS_U32), from(MAX_AS_U32)) == LT, 0);
        assert!(cmp(from(MAX_AS_U32), neg_from(MIN_AS_U32)) == GT, 0);

        assert!(cmp(from(MAX_AS_U32), from(MAX_AS_U32-1)) == GT, 0);
        assert!(cmp(from(MAX_AS_U32-1), from(MAX_AS_U32)) == LT, 0);

        assert!(cmp(neg_from(MIN_AS_U32), neg_from(MIN_AS_U32-1)) == LT, 0);
        assert!(cmp(neg_from(MIN_AS_U32-1), neg_from(MIN_AS_U32)) == GT, 0);
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
        assert!(gt(max(), neg_from(MIN_AS_U32)) == true, 0);
        assert!(gt(neg_from(MIN_AS_U32), max()) == false, 0);
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
        assert!(as_u32(or(from(0), from(0))) == 0, 0);
        // 0 | 1 = 1
        assert!(as_u32(or(from(0), from(1))) == 1, 0);
        // 1 | 0 = 1
        assert!(as_u32(or(from(1), from(0))) == 1, 0);
        // 1 | 1 = 1
        assert!(as_u32(or(from(1), from(1))) == 1, 0);
        // -1 | -1 = -1
        assert!(as_u32(or(neg_from(1), neg_from(1))) == 0xffffffff, 0);
        // 1 | 100000 = 100001
        assert!(as_u32(or(from(1), from(100000))) == 0x186a1, 0);
        // 1 | -100000 = -99999
        assert!(as_u32(or(from(1), neg_from(100000))) == 0xfffe7961, 0);
        // -1000000 | 1 = -999999
        assert!(as_u32(or(neg_from(1000000), from(1))) == 0xfff0bdc1, 0);
        // -1000000 | -1 = -1
        assert!(as_u32(or(neg_from(1000000), neg_from(1))) == 0xffffffff, 0);
        // -1000000 | 1000000 = -64
        assert!(as_u32(or(neg_from(1000000), from(1000000))) == 0xffffffc0, 0);
        // -2147483648 | 0 = -2147483648
        assert!(as_u32(or(min(), from(0))) == 0x80000000, 0);
        // -2147483648 | -2147483648 = -2147483648
        assert!(as_u32(or(min(), min())) == 0x80000000, 0);
        // -2147483648 | -100000 = -100000
        assert!(as_u32(or(min(), neg_from(100000))) == 0xfffe7960, 0);
        // -2147483648 | 2147483647 = -1
        assert!(as_u32(or(min(), max())) == 0xffffffff, 0);
        // 2147483647 | 0 = 2147483647
        assert!(as_u32(or(max(), from(0))) == 0x7fffffff, 0);
        // 2147483647 | 1 = 2147483647
        assert!(as_u32(or(max(), from(1))) == 0x7fffffff, 0);
        // 2147483647 | 2147483647 = 2147483647
        assert!(as_u32(or(max(), max())) == 0x7fffffff, 0);
    }

    #[test]
    fun test_and() {
        // 0 | 0 = 0
        assert!(as_u32(and(from(0), from(0))) == 0, 0);
        // 0 | 1 = 0
        assert!(as_u32(and(from(0), from(1))) == 0, 0);
        // 1 | 0 = 0
        assert!(as_u32(and(from(1), from(0))) == 0, 0);
        // 1 | 1 = 1
        assert!(as_u32(and(from(1), from(1))) == 1, 0);
        // -1 | -1 = -1
        assert!(as_u32(and(neg_from(1), neg_from(1))) == 0xffffffff, 0);
        // 1 | 100000 = 0
        assert!(as_u32(and(from(1), from(100000))) == 0, 0);
        // 1 | -100000 = 0
        assert!(as_u32(and(from(1), neg_from(100000))) == 0, 0);
        // -1000000 | 1 = 0
        assert!(as_u32(and(neg_from(1000000), from(1))) == 0, 0);
        // -1000000 | -1 = -1000000
        assert!(as_u32(and(neg_from(1000000), neg_from(1))) == 0xfff0bdc0, 0);
        // -1000000 | 1000000 = 64
        assert!(as_u32(and(neg_from(1000000), from(1000000))) == 64, 0);
        // -2147483648 | 0 = 0
        assert!(as_u32(and(min(), from(0))) == 0, 0);
        // -2147483648 | -2147483648 = -2147483648
        assert!(as_u32(and(min(), min())) == 0x80000000, 0);
        // -2147483648 | -100000 = -2147483648
        assert!(as_u32(and(min(), neg_from(100000))) == 0x80000000, 0);
        // -2147483648 | 2147483647 = 0
        assert!(as_u32(and(min(), max())) == 0, 0);
        // 2147483647 | 0 = 0
        assert!(as_u32(and(max(), from(0))) == 0, 0);
        // 2147483647 | 1 = 1
        assert!(as_u32(and(max(), from(1))) == 1, 0);
        // 2147483647 | 2147483647 = 2147483647
        assert!(as_u32(and(max(), max())) == 0x7fffffff, 0);
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


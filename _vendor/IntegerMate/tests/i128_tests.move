#[test_only]
#[allow(deprecated_usage)]
module integer_mate::i128_tests {
    use integer_mate::i128::{
        I128,
        zero,
        from,
        neg_from,
        neg,
        abs,
        wrapping_add,
        add,
        overflowing_add,
        overflowing_sub,
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
        as_u128,
        as_i64,
        as_i32,
        abs_u128,
        or,
        and
    };
    use integer_mate::i64::as_u64;
    use integer_mate::i32::as_u32;
    

    const MIN_AS_U128: u128 = 1 << 127;
    const MAX_AS_U128: u128 = 0x7fffffffffffffffffffffffffffffff;

    const LT: u8 = 0;
    const GT: u8 = 2;

    fun min() : I128 {
        neg_from(0x80000000000000000000000000000000)
    }

    fun max() : I128 {
        from(0x7fffffffffffffffffffffffffffffff)
    }

    #[test]
    fun test_zero() {
        assert!(as_u128(zero()) == 0, 0);
    }

    #[test]
    fun test_from() {
        assert!(as_u128(from(0)) == 0, 0);
        assert!(as_u128(from(1)) == 1, 0);
        assert!(as_u128(from(MAX_AS_U128)) == MAX_AS_U128, 0);
    }

    #[test]
    #[expected_failure]
    fun test_from_overflow() {
        from(MAX_AS_U128 + 1);
    }

    #[test]
    fun test_neg_from() {
        assert!(as_u128(neg_from(0)) == 0, 0);
        assert!(as_u128(neg_from(1)) == 0xffffffffffffffffffffffffffffffff, 0);
        assert!(as_u128(neg_from(MIN_AS_U128)) == MIN_AS_U128, 0);
    }

    #[test]
    #[expected_failure]
    fun test_neg_from_overflow() {
        neg_from(MIN_AS_U128 + 1);
    }

    #[test]
    fun test_neg() {
        assert!(as_u128(neg(from(0))) == 0, 0);
        assert!(as_u128(neg(from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        assert!(as_u128(neg(from(MAX_AS_U128))) == 0x80000000000000000000000000000001, 0);
        assert!(as_u128(neg(neg_from(1))) == 1, 0);
        assert!(as_u128(neg(neg_from(MIN_AS_U128-1))) == MAX_AS_U128, 0);
    }

    #[test]
    fun test_wrapping_add() {
        // wrapping_add(0 + 0) = 0
        assert!(as_u128(wrapping_add(from(0), from(0))) == 0, 0);
        // wrapping_add(0 + 1) = 1
        assert!(as_u128(wrapping_add(from(0), from(1))) == 1, 0);
        // wrapping_add(1 + 1) = 2
        assert!(as_u128(wrapping_add(from(1), from(1))) == 2, 0);
        // wrapping_add(1000 + 1000) = 2000
        assert!(as_u128(wrapping_add(from(1000), from(1000))) == 2000, 0);
        // wrapping_add(0 + -1) = -1
        assert!(as_u128(wrapping_add(from(0), neg_from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // wrapping_add(-1 + 0) = -1
        assert!(as_u128(wrapping_add(neg_from(1), from(0))) == 0xffffffffffffffffffffffffffffffff, 0);
        // wrapping_add(-1 + -1) = -2
        assert!(as_u128(wrapping_add(neg_from(1), neg_from(1))) == 0xfffffffffffffffffffffffffffffffe, 0);
        // wrapping_add(-1000 + -1000) = -2000
        assert!(as_u128(wrapping_add(neg_from(1000), neg_from(1000))) == 0xfffffffffffffffffffffffffffff830, 0);
        // wrapping_add(1 + -1) = 0
        assert!(as_u128(wrapping_add(from(1), neg_from(1))) == 0, 0);
        // wrapping_add(-1 + 1) = 0
        assert!(as_u128(wrapping_add(neg_from(1), from(1))) == 0, 0);
        // wrapping_add(1000 + -1000) = 0
        assert!(as_u128(wrapping_add(from(1000), neg_from(1000))) == 0, 0);
        // wrapping_add(0 + 170141183460469231731687303715884105727) = 170141183460469231731687303715884105727
        assert!(as_u128(wrapping_add(from(0), max())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // wrapping_add(1 + 170141183460469231731687303715884105727) = -170141183460469231731687303715884105728
        assert!(as_u128(wrapping_add(from(1), max())) == 0x80000000000000000000000000000000, 0);
        // wrapping_add(2 + 170141183460469231731687303715884105727) = -170141183460469231731687303715884105727
        assert!(as_u128(wrapping_add(from(2), max())) == 0x80000000000000000000000000000001, 0);
        // wrapping_add(1000 + 170141183460469231731687303715884105727) = -170141183460469231731687303715884104729
        assert!(as_u128(wrapping_add(from(1000), max())) == 0x800000000000000000000000000003e7, 0);
        // wrapping_add(0 + -170141183460469231731687303715884105728) = -170141183460469231731687303715884105728
        assert!(as_u128(wrapping_add(from(0), min())) == 0x80000000000000000000000000000000, 0);
        // wrapping_add(1 + -170141183460469231731687303715884105728) = -170141183460469231731687303715884105727
        assert!(as_u128(wrapping_add(from(1), min())) == 0x80000000000000000000000000000001, 0);
        // wrapping_add(-1 + -170141183460469231731687303715884105728) = 170141183460469231731687303715884105727
        assert!(as_u128(wrapping_add(neg_from(1), min())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // wrapping_add(-2 + -170141183460469231731687303715884105728) = 170141183460469231731687303715884105726
        assert!(as_u128(wrapping_add(neg_from(2), min())) == 0x7ffffffffffffffffffffffffffffffe, 0);
        // wrapping_add(-1000 + -170141183460469231731687303715884105728) = 170141183460469231731687303715884104728
        assert!(as_u128(wrapping_add(neg_from(1000), min())) == 0x7ffffffffffffffffffffffffffffc18, 0);
        // wrapping_add(170141183460469231731687303715884105727 + 170141183460469231731687303715884105727) = -2
        assert!(as_u128(wrapping_add(max(), max())) == 0xfffffffffffffffffffffffffffffffe, 0);
        // wrapping_add(-170141183460469231731687303715884105728 + -170141183460469231731687303715884105728) = 0
        assert!(as_u128(wrapping_add(min(), min())) == 0, 0);
        // wrapping_add(170141183460469231731687303715884105727 + -170141183460469231731687303715884105728) = -1
        assert!(as_u128(wrapping_add(max(), min())) == 0xffffffffffffffffffffffffffffffff, 0);
    }

    #[test]
    fun test_add() {
        // old tests
        assert!(as_u128(add(from(0), from(0))) == 0, 0);
        assert!(as_u128(add(from(0), from(1))) == 1, 0);
        assert!(as_u128(add(from(1), from(0))) == 1, 0);
        assert!(as_u128(add(from(10000), from(99999))) == 109999, 0);
        assert!(as_u128(add(from(99999), from(10000))) == 109999, 0);
        assert!(as_u128(add(from(MAX_AS_U128-1), from(1))) == MAX_AS_U128, 0);

        assert!(as_u128(add(neg_from(0), neg_from(0))) == 0, 1);
        assert!(as_u128(add(neg_from(1), neg_from(0))) == 0xffffffffffffffffffffffffffffffff, 1);
        assert!(as_u128(add(neg_from(0), neg_from(1))) == 0xffffffffffffffffffffffffffffffff, 1);
        assert!(as_u128(add(neg_from(10000), neg_from(99999))) == 0xfffffffffffffffffffffffffffe5251, 1);
        assert!(as_u128(add(neg_from(99999), neg_from(10000))) == 0xfffffffffffffffffffffffffffe5251, 1);
        assert!(as_u128(add(neg_from(MIN_AS_U128-1), neg_from(1))) == MIN_AS_U128, 1);

        assert!(as_u128(add(from(0), neg_from(0))) == 0, 2);
        assert!(as_u128(add(neg_from(0), from(0))) == 0, 2);
        assert!(as_u128(add(neg_from(1), from(1))) == 0, 2);
        assert!(as_u128(add(from(1), neg_from(1))) == 0, 2);
        assert!(as_u128(add(from(10000), neg_from(99999))) == 0xfffffffffffffffffffffffffffea071, 2);
        assert!(as_u128(add(from(99999), neg_from(10000))) == 89999, 2);
        assert!(as_u128(add(neg_from(MIN_AS_U128), from(1))) == 0x80000000000000000000000000000001, 2);
        assert!(as_u128(add(from(MAX_AS_U128), neg_from(1))) == MAX_AS_U128 - 1, 2);

        // new tests
        // 0 + 0 = 0
        assert!(as_u128(add(from(0), from(0))) == 0, 0);
        // 0 + 1 = 1
        assert!(as_u128(add(from(0), from(1))) == 1, 0);
        // 1 + 0 = 1
        assert!(as_u128(add(from(1), from(0))) == 1, 0);
        // 170141183460469231731687303715884105727 + 0 = 170141183460469231731687303715884105727
        assert!(as_u128(add(max(), from(0))) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 0 + 170141183460469231731687303715884105727 = 170141183460469231731687303715884105727
        assert!(as_u128(add(from(0), max())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 1 + 170141183460469231731687303715884105726 = 170141183460469231731687303715884105727
        assert!(as_u128(add(from(1), from(0x7ffffffffffffffffffffffffffffffe))) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105726 + 1 = 170141183460469231731687303715884105727
        assert!(as_u128(add(from(0x7ffffffffffffffffffffffffffffffe), from(1))) == 0x7fffffffffffffffffffffffffffffff, 0);
        // -1 + 0 = -1
        assert!(as_u128(add(neg_from(1), from(0))) == 0xffffffffffffffffffffffffffffffff, 0);
        // 0 + -1 = -1
        assert!(as_u128(add(from(0), neg_from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // -1 + 170141183460469231731687303715884105727 = 170141183460469231731687303715884105726
        assert!(as_u128(add(neg_from(1), max())) == 0x7ffffffffffffffffffffffffffffffe, 0);
        // 170141183460469231731687303715884105727 + -1 = 170141183460469231731687303715884105726
        assert!(as_u128(add(max(), neg_from(1))) == 0x7ffffffffffffffffffffffffffffffe, 0);
        // 10000 + -1 = 9999
        assert!(as_u128(add(from(10000), neg_from(1))) == 9999, 0);
        // -170141183460469231731687303715884105728 + 1 = -170141183460469231731687303715884105727
        assert!(as_u128(add(min(), from(1))) == 0x80000000000000000000000000000001, 0);
        // -170141183460469231731687303715884105727 + -1 = -170141183460469231731687303715884105728
        assert!(as_u128(add(neg_from(0x7fffffffffffffffffffffffffffffff), neg_from(1))) == 0x80000000000000000000000000000000, 0);
        // -170141183460469231731687303715884105727 + 1000000000 = -170141183460469231731687303714884105727
        assert!(as_u128(add(neg_from(0x7fffffffffffffffffffffffffffffff), from(0x3b9aca00))) == 0x8000000000000000000000003b9aca01, 0);
        // -170141183460469231731687303715884105728 + 170141183460469231731687303715884105727 = -1
        assert!(as_u128(add(min(), max())) == 0xffffffffffffffffffffffffffffffff, 0);
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
        add(neg_from(MIN_AS_U128), neg_from(1));
    }

    #[test]
    #[expected_failure]
    fun test_add_underflow_min_min() {
        add(min(), min());
    }

    #[test]
    fun test_overflowing_add() {
        let (result, overflow) = overflowing_add(from(0), from(0));
        assert!(overflow == false && as_u128(result) == 0, 0);
        let (result, overflow) = overflowing_add(from(0), from(1));
        assert!(overflow == false && as_u128(result) == 1, 0);
        let (result, overflow) = overflowing_add(from(1), from(0));
        assert!(overflow == false && as_u128(result) == 1, 0);
        let (result, overflow) = overflowing_add(from(1), from(1));
        assert!(overflow == false && as_u128(result) == 2, 0);
        let (result, overflow) = overflowing_add(from(10000), from(99999));
        assert!(overflow == false && as_u128(result) == 109999, 0);
        let (result, overflow) = overflowing_add(from(99999), from(10000));
        assert!(overflow == false && as_u128(result) == 109999, 0);
        let (result, overflow) = overflowing_add(from(MAX_AS_U128-1), from(1));
        assert!(overflow == false && as_u128(result) == MAX_AS_U128, 0);
        let (result, overflow) = overflowing_add(max(), neg_from(1));
        assert!(overflow == false && as_u128(result) == MAX_AS_U128 - 1, 1);
        let (result, overflow) = overflowing_add(min(), from(1));
        assert!(overflow == false && as_u128(result) == 0x80000000000000000000000000000001, 1);
        let (result, overflow) = overflowing_add(min(), max());
        assert!(overflow == false && as_u128(result) == as_u128(neg_from(1)), 1);
        let (_, overflow) = overflowing_add(max(), from(1));
        assert!(overflow == true, 1);
        let (_, overflow) = overflowing_add(from(1), max());
        assert!(overflow == true, 1);
        let (_, overflow) = overflowing_add(max(), max());
        assert!(overflow == true, 1);
        let (_, overflow) = overflowing_add(min(), min());
        assert!(overflow == true, 1);
        let (_, overflow) = overflowing_add(neg_from(1), min());
        assert!(overflow == true, 1);
        let (_, overflow) = overflowing_add(min(), neg_from(1));
        assert!(overflow == true, 1);
    }

    #[test]
    fun test_wrapping_sub() {
        // wrapping_sub(0 - 0) = 0
        assert!(as_u128(wrapping_sub(from(0), from(0))) == 0, 0);
        // wrapping_sub(0 - 1) = -1
        assert!(as_u128(wrapping_sub(from(0), from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // wrapping_sub(1 - 0) = 1
        assert!(as_u128(wrapping_sub(from(1), from(0))) == 1, 0);
        // wrapping_sub(1000 - 1000) = 0
        assert!(as_u128(wrapping_sub(from(1000), from(1000))) == 0, 0);
        // wrapping_sub(-1000 - -1000) = 0
        assert!(as_u128(wrapping_sub(neg_from(1000), neg_from(1000))) == 0, 0);
        // wrapping_sub(1000 - -1000) = 2000
        assert!(as_u128(wrapping_sub(from(1000), neg_from(1000))) == 2000, 0);
        // wrapping_sub(0 - -1) = 1
        assert!(as_u128(wrapping_sub(from(0), neg_from(1))) == 1, 0);
        // wrapping_sub(-1 - 0) = -1
        assert!(as_u128(wrapping_sub(neg_from(1), from(0))) == 0xffffffffffffffffffffffffffffffff, 0);
        // wrapping_sub(1 - -1) = 2
        assert!(as_u128(wrapping_sub(from(1), neg_from(1))) == 2, 0);
        // wrapping_sub(-1 - 1) = -2
        assert!(as_u128(wrapping_sub(neg_from(1), from(1))) == 0xfffffffffffffffffffffffffffffffe, 0);
        // wrapping_sub(-1 - -1) = 0
        assert!(as_u128(wrapping_sub(neg_from(1), neg_from(1))) == 0, 0);
        // wrapping_sub(0 - 170141183460469231731687303715884105727) = -170141183460469231731687303715884105727
        assert!(as_u128(wrapping_sub(from(0), max())) == 0x80000000000000000000000000000001, 0);
        // wrapping_sub(0 - -170141183460469231731687303715884105728) = -170141183460469231731687303715884105728
        assert!(as_u128(wrapping_sub(from(0), min())) == 0x80000000000000000000000000000000, 0);
        // wrapping_sub(-1 - 170141183460469231731687303715884105727) = -170141183460469231731687303715884105728
        assert!(as_u128(wrapping_sub(neg_from(1), max())) == 0x80000000000000000000000000000000, 0);
        // wrapping_sub(-2 - 170141183460469231731687303715884105727) = 170141183460469231731687303715884105727
        assert!(as_u128(wrapping_sub(neg_from(2), max())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // wrapping_sub(-1000 - 170141183460469231731687303715884105727) = 170141183460469231731687303715884104729
        assert!(as_u128(wrapping_sub(neg_from(1000), max())) == 0x7ffffffffffffffffffffffffffffc19, 0);
        // wrapping_sub(0 - -170141183460469231731687303715884105728) = -170141183460469231731687303715884105728
        assert!(as_u128(wrapping_sub(from(0), min())) == 0x80000000000000000000000000000000, 0);
        // wrapping_sub(1 - -170141183460469231731687303715884105728) = -170141183460469231731687303715884105727
        assert!(as_u128(wrapping_sub(from(1), min())) == 0x80000000000000000000000000000001, 0);
        // wrapping_sub(2 - -170141183460469231731687303715884105728) = -170141183460469231731687303715884105726
        assert!(as_u128(wrapping_sub(from(2), min())) == 0x80000000000000000000000000000002, 0);
        // wrapping_sub(1000 - -170141183460469231731687303715884105728) = -170141183460469231731687303715884104728
        assert!(as_u128(wrapping_sub(from(1000), min())) == 0x800000000000000000000000000003e8, 0);
        // wrapping_sub(-1 - -170141183460469231731687303715884105728) = 170141183460469231731687303715884105727
        assert!(as_u128(wrapping_sub(neg_from(1), min())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // wrapping_sub(-2 - -170141183460469231731687303715884105728) = 170141183460469231731687303715884105726
        assert!(as_u128(wrapping_sub(neg_from(2), min())) == 0x7ffffffffffffffffffffffffffffffe, 0);
        // wrapping_sub(-1000 - -170141183460469231731687303715884105728) = 170141183460469231731687303715884104728
        assert!(as_u128(wrapping_sub(neg_from(1000), min())) == 0x7ffffffffffffffffffffffffffffc18, 0);
        // wrapping_sub(170141183460469231731687303715884105727 - 170141183460469231731687303715884105727) = 0
        assert!(as_u128(wrapping_sub(max(), max())) == 0, 0);
        // wrapping_sub(-170141183460469231731687303715884105728 - -170141183460469231731687303715884105728) = 0
        assert!(as_u128(wrapping_sub(min(), min())) == 0, 0);
        // wrapping_sub(-170141183460469231731687303715884105728 - 170141183460469231731687303715884105727) = 1
        assert!(as_u128(wrapping_sub(min(), max())) == 1, 0);
        // wrapping_sub(170141183460469231731687303715884105727 - -170141183460469231731687303715884105728) = -1
        assert!(as_u128(wrapping_sub(max(), min())) == 0xffffffffffffffffffffffffffffffff, 0);
    }

    #[test]
    fun test_sub() {
        // 0 - 0 = 0
        assert!(as_u128(sub(from(0), from(0))) == 0, 0);
        // 0 - 1 = -1
        assert!(as_u128(sub(from(0), from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // 1 - 0 = 1
        assert!(as_u128(sub(from(1), from(0))) == 1, 0);
        // 1000 - 1000 = 0
        assert!(as_u128(sub(from(1000), from(1000))) == 0, 0);
        // -1000 - -1000 = 0
        assert!(as_u128(sub(neg_from(1000), neg_from(1000))) == 0, 0);
        // 1000 - -1000 = 2000
        assert!(as_u128(sub(from(1000), neg_from(1000))) == 2000, 0);
        // 0 - -1 = 1
        assert!(as_u128(sub(from(0), neg_from(1))) == 1, 0);
        // -1 - 0 = -1
        assert!(as_u128(sub(neg_from(1), from(0))) == 0xffffffffffffffffffffffffffffffff, 0);
        // 1 - -1 = 2
        assert!(as_u128(sub(from(1), neg_from(1))) == 2, 0);
        // -1 - 1 = -2
        assert!(as_u128(sub(neg_from(1), from(1))) == 0xfffffffffffffffffffffffffffffffe, 0);
        // -1 - -1 = 0
        assert!(as_u128(sub(neg_from(1), neg_from(1))) == 0, 0);
        // 0 - 170141183460469231731687303715884105727 = -170141183460469231731687303715884105727
        assert!(as_u128(sub(from(0), max())) == 0x80000000000000000000000000000001, 0);
        // 170141183460469231731687303715884105727 - 0 = 170141183460469231731687303715884105727
        assert!(as_u128(sub(max(), from(0))) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 - 1 = 170141183460469231731687303715884105726
        assert!(as_u128(sub(max(), from(1))) == 0x7ffffffffffffffffffffffffffffffe, 0);
        // 170141183460469231731687303715884105727 - 10000 = 170141183460469231731687303715884095727
        assert!(as_u128(sub(max(), from(10000))) == 0x7fffffffffffffffffffffffffffd8ef, 0);
        // 0 - 170141183460469231731687303715884105727 = -170141183460469231731687303715884105727
        assert!(as_u128(sub(from(0), max())) == 0x80000000000000000000000000000001, 0);
        // 1 - 170141183460469231731687303715884105727 = -170141183460469231731687303715884105726
        assert!(as_u128(sub(from(1), max())) == 0x80000000000000000000000000000002, 0);
        // 10000 - 170141183460469231731687303715884105727 = -170141183460469231731687303715884095727
        assert!(as_u128(sub(from(10000), max())) == 0x80000000000000000000000000002711, 0);
        // -1 - -170141183460469231731687303715884105728 = 170141183460469231731687303715884105727
        assert!(as_u128(sub(neg_from(1), min())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // -2 - -170141183460469231731687303715884105728 = 170141183460469231731687303715884105726
        assert!(as_u128(sub(neg_from(2), min())) == 0x7ffffffffffffffffffffffffffffffe, 0);
        // -170141183460469231731687303715884105728 - -2 = -170141183460469231731687303715884105726
        assert!(as_u128(sub(min(), neg_from(2))) == 0x80000000000000000000000000000002, 0);
        // -1000 - -170141183460469231731687303715884105728 = 170141183460469231731687303715884104728
        assert!(as_u128(sub(neg_from(1000), min())) == 0x7ffffffffffffffffffffffffffffc18, 0);
        // -170141183460469231731687303715884105728 - -1000 = -170141183460469231731687303715884104728
        assert!(as_u128(sub(min(), neg_from(1000))) == 0x800000000000000000000000000003e8, 0);
        // 170141183460469231731687303715884105727 - 170141183460469231731687303715884105726 = 1
        assert!(as_u128(sub(max(), from(0x7ffffffffffffffffffffffffffffffe))) == 1, 0);
        // -170141183460469231731687303715884105728 - -170141183460469231731687303715884105727 = -1
        assert!(as_u128(sub(min(), neg_from(0x7fffffffffffffffffffffffffffffff))) == 0xffffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 - 170141183460469231731687303715884105727 = 0
        assert!(as_u128(sub(max(), max())) == 0, 0);
        // -170141183460469231731687303715884105728 - -170141183460469231731687303715884105728 = 0
        assert!(as_u128(sub(min(), min())) == 0, 0);
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
    #[expected_failure]
    fun test_overflowing_sub() {
        let (result, overflow) = overflowing_sub(from(0), from(0));
        assert!(overflow == false && as_u128(result) == 0, 0);
        let (result, overflow) = overflowing_sub(from(0), from(1));
        assert!(overflow == false && as_u128(result) == 0xffffffffffffffffffffffffffffffff, 0);
        let (result, overflow) = overflowing_sub(from(1), from(0));
        assert!(overflow == false && as_u128(result) == 1, 0);
        let (result, overflow) = overflowing_sub(from(1), from(1));
        assert!(overflow == false && as_u128(result) == 0, 0);
        let (result, overflow) = overflowing_sub(from(10000), from(99999));
        assert!(overflow == false && as_u128(result) == 0xffffffffffffffffffffffffffffffff, 0);
        let (result, overflow) = overflowing_sub(from(99999), from(10000));
        assert!(overflow == false && as_u128(result) == 0xffffffffffffffffffffffffffffffff, 0);
        let (result, overflow) = overflowing_sub(from(MAX_AS_U128-1), from(1));
        assert!(overflow == false && as_u128(result) == 0x7ffffffffffffffffffffffffffffffe, 0);
        let (_result, overflow) = overflowing_sub(from(0), neg_from(MIN_AS_U128));
        assert!(overflow == true, 1);
        let (_result, overflow) = overflowing_sub(from(1), neg_from(MIN_AS_U128));
        assert!(overflow == true, 1);
        let (_result, overflow) = overflowing_sub(neg_from(MIN_AS_U128), from(1));
        assert!(overflow == true, 1);
        let (_result, overflow) = overflowing_sub(neg_from(MIN_AS_U128), from(0));
        assert!(overflow == false, 1);
        let (_result, overflow) = overflowing_sub(from(MAX_AS_U128), neg_from(1));
        assert!(overflow == true, 1);
        let (_result, overflow) = overflowing_sub(neg_from(2), from(MAX_AS_U128));
        assert!(overflow == true, 1);
    }

    #[test]
    fun test_mul() {
        assert!(as_u128(mul(from(1), from(1))) == 1, 0);
        assert!(as_u128(mul(from(10), from(10))) == 100, 0);
        assert!(as_u128(mul(from(100), from(100))) == 10000, 0);
        assert!(as_u128(mul(from(10000), from(10000))) == 100000000, 0);

        assert!(as_u128(mul(neg_from(1), from(1))) == as_u128(neg_from(1)), 0);
        assert!(as_u128(mul(neg_from(10), from(10))) == as_u128(neg_from(100)), 0);
        assert!(as_u128(mul(neg_from(100), from(100))) == as_u128(neg_from(10000)), 0);
        assert!(as_u128(mul(neg_from(10000), from(10000))) == as_u128(neg_from(100000000)), 0);

        assert!(as_u128(mul(from(1), neg_from(1))) == as_u128(neg_from(1)), 0);
        assert!(as_u128(mul(from(10), neg_from(10))) == as_u128(neg_from(100)), 0);
        assert!(as_u128(mul(from(100), neg_from(100))) == as_u128(neg_from(10000)), 0);
        assert!(as_u128(mul(from(10000), neg_from(10000))) == as_u128(neg_from(100000000)), 0);
        assert!(as_u128(mul(from(MIN_AS_U128/2), neg_from(2))) == as_u128(neg_from(MIN_AS_U128)), 0);
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
        assert!(as_u128(div(from(0), from(1))) == 0, 0);
        assert!(as_u128(div(from(10), from(1))) == 10, 0);
        assert!(as_u128(div(from(10), neg_from(1))) == as_u128(neg_from(10)), 0);
        assert!(as_u128(div(neg_from(10), neg_from(1))) == as_u128(from(10)), 0);
        assert!(as_u128(div(from(100000), from(3))) == 33333, 0);
        assert!(as_u128(div(from(100000), neg_from(3))) == as_u128(neg_from(33333)), 0);
        assert!(as_u128(div(neg_from(100000), from(3))) == as_u128(neg_from(33333)), 0);
        assert!(as_u128(div(neg_from(100000), neg_from(3))) == 33333, 0);
        assert!(as_u128(div(from(99999), from(100000))) == 0, 0);
        assert!(as_u128(div(neg_from(100000), from(99999))) == as_u128(neg_from(1)), 0);
        assert!(as_u128(div(neg_from(100000), neg_from(99999))) == 1, 0);
        assert!(as_u128(div(min(), from(1))) == MIN_AS_U128, 0);
        assert!(as_u128(div(min(), from(2))) == as_u128(neg_from(MIN_AS_U128/2)), 0);
        assert!(as_u128(div(min(), max())) == as_u128(neg_from(1)), 0);
        assert!(as_u128(div(max(), min())) == 0, 0);
        assert!(as_u128(div(min(), neg_from(2))) == as_u128(from(MIN_AS_U128/2)), 0);
        assert!(as_u128(div(max(), from(1))) == MAX_AS_U128, 0);
        assert!(as_u128(div(max(), from(2))) == as_u128(from(MAX_AS_U128/2)), 0);
        assert!(as_u128(div(max(), neg_from(1))) == as_u128(neg_from(MAX_AS_U128)), 0);
        assert!(as_u128(div(max(), neg_from(2))) == as_u128(neg_from(MAX_AS_U128/2)), 0);
    }

    #[test]
    fun test_abs() {
        assert!(as_u128(abs(from(0))) == 0, 0);
        assert!(as_u128(abs(from(1))) == 1, 0);
        assert!(as_u128(abs(from(100000))) == 100000, 0);
        assert!(as_u128(abs(neg_from(1))) == 1, 0);
        assert!(as_u128(abs(neg_from(100000))) == 100000, 0);
        assert!(as_u128(abs(max())) == MAX_AS_U128, 0);
        assert!(as_u128(abs(add(min(), from(1)))) == MAX_AS_U128, 0);
    }

    #[test]
    #[expected_failure]
    fun test_abs_overflow() {
        abs(min());
    }

    #[test]
    fun test_abs_u128() {
        assert!(abs_u128(from(0)) == 0, 0);
        assert!(abs_u128(from(1)) == 1, 0);
        assert!(abs_u128(from(100000)) == 100000, 0);
        assert!(abs_u128(neg_from(0)) == 0, 0);
        assert!(abs_u128(neg_from(1)) == 1, 0);
        assert!(abs_u128(neg_from(100000)) == 100000, 0);
        assert!(abs_u128(max()) == MAX_AS_U128, 0);
        assert!(abs_u128(min()) == MAX_AS_U128 + 1, 0);
    }

    #[test]
    fun test_shl() {
        // 0 << 0 = 0
        assert!(as_u128(shl(from(0), 0)) == 0, 0);
        // 0 << 1 = 0
        assert!(as_u128(shl(from(0), 1)) == 0, 0);
        // 0 << 127 = 0
        assert!(as_u128(shl(from(0), 127)) == 0, 0);
        // 1000 << 0 = 1000
        assert!(as_u128(shl(from(1000), 0)) == 1000, 0);
        // 1000 << 18 = 262144000
        assert!(as_u128(shl(from(1000), 18)) == 0xfa00000, 0);
        // 1000 << 64 = 18446744073709551616000
        assert!(as_u128(shl(from(1000), 64)) == 0x3e80000000000000000, 0);
        // 1000 << 127 = 0
        assert!(as_u128(shl(from(1000), 127)) == 0, 0);
        // -1000 << 0 = -1000
        assert!(as_u128(shl(neg_from(1000), 0)) == 0xfffffffffffffffffffffffffffffc18, 0);
        // -1000 << 8 = -256000
        assert!(as_u128(shl(neg_from(1000), 8)) == 0xfffffffffffffffffffffffffffc1800, 0);
        // -1000 << 64 = -18446744073709551616000
        assert!(as_u128(shl(neg_from(1000), 64)) == 0xfffffffffffffc180000000000000000, 0);
        // -1000 << 127 = 0
        assert!(as_u128(shl(neg_from(1000), 127)) == 0, 0);
        // 170141183460469231731687303715884105727 << 0 = 170141183460469231731687303715884105727
        assert!(as_u128(shl(max(), 0)) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 << 2 = -4
        assert!(as_u128(shl(max(), 2)) == 0xfffffffffffffffffffffffffffffffc, 0);
        // 170141183460469231731687303715884105727 << 8 = -256
        assert!(as_u128(shl(max(), 8)) == 0xffffffffffffffffffffffffffffff00, 0);
        // 170141183460469231731687303715884105727 << 64 = -18446744073709551616
        assert!(as_u128(shl(max(), 64)) == 0xffffffffffffffff0000000000000000, 0);
        // 170141183460469231731687303715884105727 << 127 = -170141183460469231731687303715884105728
        assert!(as_u128(shl(max(), 127)) == 0x80000000000000000000000000000000, 0);
        // -170141183460469231731687303715884105728 << 0 = -170141183460469231731687303715884105728
        assert!(as_u128(shl(min(), 0)) == 0x80000000000000000000000000000000, 0);
        // -170141183460469231731687303715884105728 << 2 = 0
        assert!(as_u128(shl(min(), 2)) == 0, 0);
        // -170141183460469231731687303715884105728 << 8 = 0
        assert!(as_u128(shl(min(), 8)) == 0, 0);
        // -170141183460469231731687303715884105728 << 64 = 0
        assert!(as_u128(shl(min(), 64)) == 0, 0);
        // -170141183460469231731687303715884105728 << 127 = 0
        assert!(as_u128(shl(min(), 127)) == 0, 0);
    }

    #[test]
    fun test_shr() {
        // 0 >> 0 = 0
        assert!(as_u128(shr(from(0), 0)) == 0, 0);
        // 0 >> 1 = 0
        assert!(as_u128(shr(from(0), 1)) == 0, 0);
        // 0 >> 127 = 0
        assert!(as_u128(shr(from(0), 127)) == 0, 0);
        // 1000 >> 1 = 500
        assert!(as_u128(shr(from(1000), 1)) == 500, 0);
        // 1000 >> 2 = 250
        assert!(as_u128(shr(from(1000), 2)) == 250, 0);
        // 1000 >> 4 = 62
        assert!(as_u128(shr(from(1000), 4)) == 62, 0);
        // 1000 >> 8 = 3
        assert!(as_u128(shr(from(1000), 8)) == 3, 0);
        // 1000 >> 64 = 0
        assert!(as_u128(shr(from(1000), 64)) == 0, 0);
        // 1000 >> 127 = 0
        assert!(as_u128(shr(from(1000), 127)) == 0, 0);
        // -1000 >> 1 = -500
        assert!(as_u128(shr(neg_from(1000), 1)) == 0xfffffffffffffffffffffffffffffe0c, 0);
        // -1000 >> 2 = -250
        assert!(as_u128(shr(neg_from(1000), 2)) == 0xffffffffffffffffffffffffffffff06, 0);
        // -1000 >> 4 = -63
        assert!(as_u128(shr(neg_from(1000), 4)) == 0xffffffffffffffffffffffffffffffc1, 0);
        // -1000 >> 8 = -4
        assert!(as_u128(shr(neg_from(1000), 8)) == 0xfffffffffffffffffffffffffffffffc, 0);
        // -1000 >> 64 = -1
        assert!(as_u128(shr(neg_from(1000), 64)) == 0xffffffffffffffffffffffffffffffff, 0);
        // -1000 >> 127 = -1
        assert!(as_u128(shr(neg_from(1000), 127)) == 0xffffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 >> 0 = 170141183460469231731687303715884105727
        assert!(as_u128(shr(max(), 0)) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 >> 2 = 42535295865117307932921825928971026431
        assert!(as_u128(shr(max(), 2)) == 0x1fffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 >> 8 = 664613997892457936451903530140172287
        assert!(as_u128(shr(max(), 8)) == 0x7fffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 >> 64 = 9223372036854775807
        assert!(as_u128(shr(max(), 64)) == 0x7fffffffffffffff, 0);
        // 170141183460469231731687303715884105727 >> 127 = 0
        assert!(as_u128(shr(max(), 127)) == 0, 0);
        // -170141183460469231731687303715884105728 >> 0 = -170141183460469231731687303715884105728
        assert!(as_u128(shr(min(), 0)) == 0x80000000000000000000000000000000, 0);
        // -170141183460469231731687303715884105728 >> 2 = -42535295865117307932921825928971026432
        assert!(as_u128(shr(min(), 2)) == 0xe0000000000000000000000000000000, 0);
        // -170141183460469231731687303715884105728 >> 8 = -664613997892457936451903530140172288
        assert!(as_u128(shr(min(), 8)) == 0xff800000000000000000000000000000, 0);
        // -170141183460469231731687303715884105728 >> 64 = -9223372036854775808
        assert!(as_u128(shr(min(), 64)) == 0xffffffffffffffff8000000000000000, 0);
        // -170141183460469231731687303715884105728 >> 127 = -1
        assert!(as_u128(shr(min(), 127)) == 0xffffffffffffffffffffffffffffffff, 0);
    }

    #[test]
    fun test_as_u128() {
        assert!(as_u128(from(0)) == 0, 0);
        assert!(as_u128(max()) == MAX_AS_U128, 0);
        assert!(as_u128(min()) == MIN_AS_U128, 0);
    }

    #[test]
    fun test_as_i64() {
        let i64_max = from(0x7fffffffffffffff);
        let i64_min = neg_from(0x8000000000000000);
        assert!(as_u64(as_i64(from(0))) == 0, 0);
        assert!(as_u64(as_i64(i64_max)) == 0x7fffffffffffffff, 0);
        assert!(as_u64(as_i64(i64_min)) == 0x8000000000000000, 0);
    }

    #[test]
    fun test_as_i32() {
        let i32_max = from(0x7fffffff);
        let i32_min = neg_from(0x80000000);
        assert!(as_u32(as_i32(from(0))) == 0, 0);
        assert!(as_u32(as_i32(i32_max)) == 0x7fffffff, 0);
        assert!(as_u32(as_i32(i32_min)) == 0x80000000, 0);
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

        assert!(cmp(neg_from(MIN_AS_U128), from(MAX_AS_U128)) == LT, 0);
        assert!(cmp(from(MAX_AS_U128), neg_from(MIN_AS_U128)) == GT, 0);

        assert!(cmp(from(MAX_AS_U128), from(MAX_AS_U128-1)) == GT, 0);
        assert!(cmp(from(MAX_AS_U128-1), from(MAX_AS_U128)) == LT, 0);

        assert!(cmp(neg_from(MIN_AS_U128), neg_from(MIN_AS_U128-1)) == LT, 0);
        assert!(cmp(neg_from(MIN_AS_U128-1), neg_from(MIN_AS_U128)) == GT, 0);
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
        assert!(gt(max(), neg_from(MIN_AS_U128)) == true, 0);
        assert!(gt(neg_from(MIN_AS_U128), max()) == false, 0);
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
        assert!(as_u128(or(from(0), from(0))) == 0, 0);
        // 0 | 1 = 1
        assert!(as_u128(or(from(0), from(1))) == 1, 0);
        // 1 | 0 = 1
        assert!(as_u128(or(from(1), from(0))) == 1, 0);
        // 1000 | 1000 = 1000
        assert!(as_u128(or(from(1000), from(1000))) == 1000, 0);
        // -1000 | -1000 = -1000
        assert!(as_u128(or(neg_from(1000), neg_from(1000))) == 0xfffffffffffffffffffffffffffffc18, 0);
        // 1000 | -1000 = -8
        assert!(as_u128(or(from(1000), neg_from(1000))) == 0xfffffffffffffffffffffffffffffff8, 0);
        // 0 | -1 = -1
        assert!(as_u128(or(from(0), neg_from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // -1 | 0 = -1
        assert!(as_u128(or(neg_from(1), from(0))) == 0xffffffffffffffffffffffffffffffff, 0);
        // 1 | -1 = -1
        assert!(as_u128(or(from(1), neg_from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // -1 | 1 = -1
        assert!(as_u128(or(neg_from(1), from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // -1 | -1 = -1
        assert!(as_u128(or(neg_from(1), neg_from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // 0 | 170141183460469231731687303715884105727 = 170141183460469231731687303715884105727
        assert!(as_u128(or(from(0), max())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 | 0 = 170141183460469231731687303715884105727
        assert!(as_u128(or(max(), from(0))) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 | 170141183460469231731687303715884105727 = 170141183460469231731687303715884105727
        assert!(as_u128(or(max(), max())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // -170141183460469231731687303715884105728 | -170141183460469231731687303715884105728 = -170141183460469231731687303715884105728
        assert!(as_u128(or(min(), min())) == 0x80000000000000000000000000000000, 0);
    }

    #[test]
    fun test_and() {
        // 0 & 0 = 0
        assert!(as_u128(and(from(0), from(0))) == 0, 0);
        // 0 & 1 = 0
        assert!(as_u128(and(from(0), from(1))) == 0, 0);
        // 1 & 0 = 0
        assert!(as_u128(and(from(1), from(0))) == 0, 0);
        // 1000 & 1000 = 1000
        assert!(as_u128(and(from(1000), from(1000))) == 1000, 0);
        // -1000 & -1000 = -1000
        assert!(as_u128(and(neg_from(1000), neg_from(1000))) == 0xfffffffffffffffffffffffffffffc18, 0);
        // 1000 & -1000 = 8
        assert!(as_u128(and(from(1000), neg_from(1000))) == 8, 0);
        // 0 & -1 = 0
        assert!(as_u128(and(from(0), neg_from(1))) == 0, 0);
        // -1 & 0 = 0
        assert!(as_u128(and(neg_from(1), from(0))) == 0, 0);
        // 1 & -1 = 1
        assert!(as_u128(and(from(1), neg_from(1))) == 1, 0);
        // -1 & 1 = 1
        assert!(as_u128(and(neg_from(1), from(1))) == 1, 0);
        // -1 & -1 = -1
        assert!(as_u128(and(neg_from(1), neg_from(1))) == 0xffffffffffffffffffffffffffffffff, 0);
        // 0 & 170141183460469231731687303715884105727 = 0
        assert!(as_u128(and(from(0), max())) == 0, 0);
        // 170141183460469231731687303715884105727 & 0 = 0
        assert!(as_u128(and(max(), from(0))) == 0, 0);
        // 170141183460469231731687303715884105727 & 170141183460469231731687303715884105727 = 170141183460469231731687303715884105727
        assert!(as_u128(and(max(), max())) == 0x7fffffffffffffffffffffffffffffff, 0);
        // 170141183460469231731687303715884105727 & -170141183460469231731687303715884105728 = 0
        assert!(as_u128(and(max(), min())) == 0, 0);
        // -170141183460469231731687303715884105728 & -170141183460469231731687303715884105728 = -170141183460469231731687303715884105728
        assert!(as_u128(and(min(), min())) == 0x80000000000000000000000000000000, 0);
    }
}


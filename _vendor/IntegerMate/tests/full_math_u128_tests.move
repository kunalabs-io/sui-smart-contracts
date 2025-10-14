#[test_only]
#[allow(deprecated_usage)]
module integer_mate::full_math_u128_tests {
    use integer_mate::full_math_u128;

    const MAX_U64: u128 =  0xFFFF_FFFF_FFFF_FFFF;
    const MAX_U128: u128 = 0xFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;

    #[test]
    fun test_mul_div_floor() {
        assert!(full_math_u128::mul_div_floor(0, 0, 1) == 0, 0);
        assert!(full_math_u128::mul_div_floor(2, 3, 1) == 6, 0);
        assert!(full_math_u128::mul_div_floor(100, 100, 2) == 5000, 0);
        assert!(full_math_u128::mul_div_floor(100, 100, 3) == 3333, 0);
        assert!(full_math_u128::mul_div_floor(200, 100, 3) == 6666, 0);
        assert!(full_math_u128::mul_div_floor(1, 1, MAX_U128) == 0, 0);
        assert!(full_math_u128::mul_div_floor(MAX_U128-1, 1, MAX_U128) == 0, 0);
        assert!(full_math_u128::mul_div_floor(MAX_U128, 1, 1) == MAX_U128, 0);
        assert!(full_math_u128::mul_div_floor(MAX_U128, 2, 2) == MAX_U128, 0);
        assert!(full_math_u128::mul_div_floor(MAX_U128, 2, 3) == 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 0);
        // mod = 2
        assert!(full_math_u128::mul_div_floor(MAX_U128, 2, 4) == 0x7fffffffffffffffffffffffffffffff, 0);
        // mod = 6
        assert!(full_math_u128::mul_div_floor(MAX_U128, 2, 8) == 0x3fffffffffffffffffffffffffffffff, 0);
        // mod = 4
        assert!(full_math_u128::mul_div_floor(MAX_U128, 2, 11) == 0x2e8ba2e8ba2e8ba2e8ba2e8ba2e8ba2e, 0);
        assert!(full_math_u128::mul_div_floor(MAX_U128, MAX_U128, MAX_U128) == MAX_U128, 0);
    }

    #[test]
    fun test_mul_div_round() {
        assert!(full_math_u128::mul_div_round(0, 0, 1) == 0, 0);
        assert!(full_math_u128::mul_div_round(2, 3, 1) == 6, 0);
        assert!(full_math_u128::mul_div_round(100, 100, 2) == 5000, 0);
        assert!(full_math_u128::mul_div_round(100, 100, 3) == 3333, 0);
        assert!(full_math_u128::mul_div_round(200, 100, 3) == 6667, 0);
        assert!(full_math_u128::mul_div_round(1, 1, MAX_U128) == 0, 0);
        assert!(full_math_u128::mul_div_round(MAX_U128-1, 1, MAX_U128) == 1, 0);
        assert!(full_math_u128::mul_div_round(MAX_U128, 1, 1) == MAX_U128, 0);
        assert!(full_math_u128::mul_div_round(MAX_U128, 2, 2) == MAX_U128, 0);
        assert!(full_math_u128::mul_div_round(MAX_U128, 2, 3) == 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 0);
        // mod = 2
        assert!(full_math_u128::mul_div_round(MAX_U128, 2, 4) == 0x80000000000000000000000000000000, 0);
        // mod = 6
        assert!(full_math_u128::mul_div_round(MAX_U128, 2, 8) == 0x40000000000000000000000000000000, 0);
        // mod = 4
        assert!(full_math_u128::mul_div_round(MAX_U128, 2, 11) == 0x2e8ba2e8ba2e8ba2e8ba2e8ba2e8ba2e, 0);
        assert!(full_math_u128::mul_div_round(MAX_U128, MAX_U128, MAX_U128) == MAX_U128, 0);
    }

    #[test]
    fun test_mul_div_ceil() {
        assert!(full_math_u128::mul_div_ceil(0, 0, 1) == 0, 0);
        assert!(full_math_u128::mul_div_ceil(2, 3, 1) == 6, 0);
        assert!(full_math_u128::mul_div_ceil(100, 100, 2) == 5000, 0);
        assert!(full_math_u128::mul_div_ceil(100, 100, 3) == 3334, 0);
        assert!(full_math_u128::mul_div_ceil(200, 100, 3) == 6667, 0);
        assert!(full_math_u128::mul_div_ceil(1, 1, MAX_U128) == 1, 0);
        assert!(full_math_u128::mul_div_ceil(MAX_U128-1, 1, MAX_U128) == 1, 0);
        assert!(full_math_u128::mul_div_ceil(MAX_U128, 1, 1) == MAX_U128, 0);
        assert!(full_math_u128::mul_div_ceil(MAX_U128, 2, 2) == MAX_U128, 0);
        assert!(full_math_u128::mul_div_ceil(MAX_U128, 2, 3) == 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 0);
        // mod = 2
        assert!(full_math_u128::mul_div_ceil(MAX_U128, 2, 4) == 0x80000000000000000000000000000000, 0);
        // mod = 6
        assert!(full_math_u128::mul_div_ceil(MAX_U128, 2, 8) == 0x40000000000000000000000000000000, 0);
        // mod = 4
        assert!(full_math_u128::mul_div_ceil(MAX_U128, 2, 11) == 0x2e8ba2e8ba2e8ba2e8ba2e8ba2e8ba2f, 0);
        assert!(full_math_u128::mul_div_ceil(MAX_U128, MAX_U128, MAX_U128) == MAX_U128, 0);
    }

    #[test]
    fun test_mul_shr() {
        assert!(full_math_u128::mul_shr(0, 0, 1) == 0, 0);
        assert!(full_math_u128::mul_shr(2, 3, 1) == (2 *3 ) >> 1, 0);
        assert!(full_math_u128::mul_shr(1, 1, 2) == 0, 0);
        assert!(full_math_u128::mul_shr(1, 1, 255) == 0, 0);
        assert!(full_math_u128::mul_shr(100, 100, 2) == (100 * 100) >> 2, 0);
        assert!(full_math_u128::mul_shr(MAX_U128, 2, 2) == MAX_U128 >> 1, 0);
        assert!(full_math_u128::mul_shr(MAX_U128, 1<<64, 64) == MAX_U128, 0);
        assert!(full_math_u128::mul_shr(MAX_U128, 1<<64, 64) == MAX_U128, 0);
        assert!(full_math_u128::mul_shr(MAX_U128, 1<<64, 192) == 0, 0);
        assert!(full_math_u128::mul_shr(1<<127, 1<<127, 253) == 2, 0);
        assert!(full_math_u128::mul_shr(1<<127, 1<<127, 254) == 1, 0);
        assert!(full_math_u128::mul_shr(1<<127, 1<<127, 255) == 0, 0);
    }

    #[test]
    fun test_mul_shl() {
        assert!(full_math_u128::mul_shl(0, 0, 1) == 0, 0);
        assert!(full_math_u128::mul_shl(2, 3, 1) == (2 *3 ) << 1, 0);
        assert!(full_math_u128::mul_shl(1, 1, 2) == (1 * 1) << 2, 0);
        assert!(full_math_u128::mul_shl(100, 100, 2) == (100 * 100) << 2, 0);
        assert!(full_math_u128::mul_shl(1, 1, 64) == 1 << 64, 0);
        assert!(full_math_u128::mul_shl(1<<127, 1<<127, 2) == 0, 0);
    }

    #[test]
    fun test_full_mul() {
        assert!(full_math_u128::full_mul(0, 0) == 0, 0);
        assert!(full_math_u128::full_mul(2, 3) == 6, 0);
        assert!(full_math_u128::full_mul(MAX_U128, MAX_U128) == 0xfffffffffffffffffffffffffffffffe00000000000000000000000000000001, 0);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_floor_overflow_div_zero() {
        full_math_u128::mul_div_floor(100, 100, 0);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_floor_overflow_1() {
        full_math_u128::mul_div_floor(MAX_U64 << 1, MAX_U64, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_floor_overflow_2() {
        full_math_u128::mul_div_floor(MAX_U128, 2, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_floor_overflow_3() {
        full_math_u128::mul_div_floor(MAX_U128, MAX_U128, 1);
    }


    #[test]
    #[expected_failure]
    fun test_mul_div_round_overflow_div_zero() {
        full_math_u128::mul_div_round(100, 100, 0);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_round_overflow_1() {
        full_math_u128::mul_div_round(MAX_U64 << 1, MAX_U64, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_round_overflow_2() {
        full_math_u128::mul_div_round(MAX_U128, 2, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_round_overflow_3() {
        full_math_u128::mul_div_round(MAX_U128, MAX_U128, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_ceil_overflow_div_zero() {
        full_math_u128::mul_div_ceil(100, 100, 0);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_ceil_overflow_1() {
        full_math_u128::mul_div_ceil(MAX_U64 << 1, MAX_U64, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_ceil_overflow_2() {
        full_math_u128::mul_div_ceil(MAX_U128, 2, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_div_ceil_overflow_3() {
        full_math_u128::mul_div_ceil(MAX_U128, MAX_U128, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_shr_overflow() {
        full_math_u128::mul_shr(MAX_U128, 1<<2, 1);
    }

    #[test]
    #[expected_failure]
    fun test_mul_shl_overflow() {
        full_math_u128::mul_shl(MAX_U128, 2, 1);
    }
}

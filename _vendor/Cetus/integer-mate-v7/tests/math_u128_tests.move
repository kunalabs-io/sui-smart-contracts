module integer_mate::math_u128_tests {
    use integer_mate::math_u128::{
        wrapping_add,
        wrapping_sub,
        wrapping_mul,
        overflowing_add,
        overflowing_sub,
        overflowing_mul,
        full_mul,
        hi,
        lo,
        hi_u128,
        lo_u128,
        from_lo_hi,
        checked_div_round,
        min,
        max,
        add_check,
    };

    #[test]
    fun test_wrapping_add() {
        // wrapping_add(0 + 0) = 0
        assert!(wrapping_add(0, 0) == 0, 0);
        // wrapping_add(0 + 1) = 1
        assert!(wrapping_add(0, 1) == 1, 0);
        // wrapping_add(340282366920938463463374607431768211455 + 0) = 340282366920938463463374607431768211455
        assert!(wrapping_add(0xffffffffffffffffffffffffffffffff, 0) == 0xffffffffffffffffffffffffffffffff, 0);
        // wrapping_add(340282366920938463463374607431768211455 + 1) = 0
        assert!(wrapping_add(0xffffffffffffffffffffffffffffffff, 1) == 0, 0);
        // wrapping_add(170141183460469231731687303715884105727 + 340282366920938463463374607431768211455) = 170141183460469231731687303715884105726
        assert!(wrapping_add(0x7fffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff) == 0x7ffffffffffffffffffffffffffffffe, 0);
        // wrapping_add(113427455640312821154458202477256070485 + 340282366920938463463374607431768211455) = 113427455640312821154458202477256070484
        assert!(wrapping_add(0x55555555555555555555555555555555, 0xffffffffffffffffffffffffffffffff) == 0x55555555555555555555555555555554, 0);
        // wrapping_add(340282366920938463463374607431768211455 + 340282366920938463463374607431768211455) = 340282366920938463463374607431768211454
        assert!(wrapping_add(0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff) == 0xfffffffffffffffffffffffffffffffe, 0);
    }

    #[test]
    fun test_wrapping_sub() {
        // wrapping_sub(0 - 0) = 0
        assert!(wrapping_sub(0, 0) == 0, 0);
        // wrapping_sub(0 - 10000) = 340282366920938463463374607431768201456
        assert!(wrapping_sub(0, 10000) == 0xffffffffffffffffffffffffffffd8f0, 0);
        // wrapping_sub(1 - 0) = 1
        assert!(wrapping_sub(1, 0) == 1, 0);
        // wrapping_sub(0 - 340282366920938463463374607431768211455) = 1
        assert!(wrapping_sub(0, 0xffffffffffffffffffffffffffffffff) == 1, 0);
        // wrapping_sub(3 - 340282366920938463463374607431768211453) = 6
        assert!(wrapping_sub(3, 0xfffffffffffffffffffffffffffffffd) == 6, 0);
        // wrapping_sub(170141183460469231731687303715884105727 - 340282366920938463463374607431768211455) = 170141183460469231731687303715884105728
        assert!(wrapping_sub(0x7fffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff) == 0x80000000000000000000000000000000, 0);
    }
    
    #[test]
    fun test_wrapping_mul() {
        // wrapping_mul(0 * 0) = 0
        assert!(wrapping_mul(0, 0) == 0, 0);
        // wrapping_mul(0 * 1) = 0
        assert!(wrapping_mul(0, 1) == 0, 0);
        // wrapping_mul(0 * 340282366920938463463374607431768211455) = 0
        assert!(wrapping_mul(0, 0xffffffffffffffffffffffffffffffff) == 0, 0);
        // wrapping_mul(3 * 170141183460469231731687303715884105727) = 170141183460469231731687303715884105725
        assert!(wrapping_mul(3, 0x7fffffffffffffffffffffffffffffff) == 0x7ffffffffffffffffffffffffffffffd, 0);
        // wrapping_mul(170141183460469231731687303715884105727 * 113427455640312821154458202477256070485) = 56713727820156410577229101238628035243
        assert!(wrapping_mul(0x7fffffffffffffffffffffffffffffff, 0x55555555555555555555555555555555) == 0x2aaaaaaaaaaaaaaaaaaaaaaaaaaaaaab, 0);
        // wrapping_mul(340282366920938463463374607431768211455 * 340282366920938463463374607431768211455) = 1
        assert!(wrapping_mul(0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff) == 1, 0);
    }

    #[test]
    fun test_overflowing_add() {
        let (result, overflowing) = overflowing_add(0, 0);
        assert!(result == 0 && !overflowing, 0);
        let (result, overflowing) = overflowing_add(0, 1);
        assert!(result == 1 && !overflowing, 0);
        let (result, overflowing) = overflowing_add(1, 0);
        assert!(result == 1 && !overflowing, 0);
        let (_, overflowing) = overflowing_add(1, 340282366920938463463374607431768211455);
        assert!(overflowing, 0);
        let (result, overflowing) = overflowing_add(170141183460469231731687303715884105727, 113427455640312821154458202477256070485);
        assert!(result == 0xd5555555555555555555555555555554 && !overflowing, 0);
        let (result, overflowing) = overflowing_add(170141183460469231731687303715884105727, 170141183460469231731687303715884105727);
        assert!(result == 0xfffffffffffffffffffffffffffffffe && !overflowing, 0);
        let (_, overflowing) = overflowing_add(340282366920938463463374607431768211455, 340282366920938463463374607431768211455);
        assert!(overflowing, 0);
    }

    #[test]
    fun test_overflowing_sub() {
        let (result, overflowing) = overflowing_sub(0, 0);
        assert!(result == 0 && !overflowing, 0);
        let (_, overflowing) = overflowing_sub(0, 10000);
        assert!(overflowing, 0);
        let (result, overflowing) = overflowing_sub(1, 0);
        assert!(result == 1 && !overflowing, 0);
        let (_, overflowing) = overflowing_sub(0, 340282366920938463463374607431768211455);
        assert!(overflowing, 0);
        let (_, overflowing) = overflowing_sub(3, 340282366920938463463374607431768211453);
        assert!(overflowing, 0);
        let (_, overflowing) = overflowing_sub(170141183460469231731687303715884105727, 340282366920938463463374607431768211455);
        assert!(overflowing, 0);
    }

    #[test]
    fun test_overflowing_mul() {
        let (result, overflowing) = overflowing_mul(0, 0);
        assert!(result == 0 && !overflowing, 0);
        let (result, overflowing) = overflowing_mul(0, 1);
        assert!(result == 0 && !overflowing, 0);
        let (result, overflowing) = overflowing_mul(1, 0);
        assert!(result == 0 && !overflowing, 0);
        let (result, overflowing) = overflowing_mul(1, 340282366920938463463374607431768211455);
        assert!(result == 0xffffffffffffffffffffffffffffffff && !overflowing, 0);
        let (_, overflowing) = overflowing_mul(170141183460469231731687303715884105727, 113427455640312821154458202477256070485);
        assert!(overflowing, 0);
        let (_, overflowing) = overflowing_mul(170141183460469231731687303715884105727, 170141183460469231731687303715884105727);
        assert!(overflowing, 0);
        let (_, overflowing) = overflowing_mul(340282366920938463463374607431768211455, 340282366920938463463374607431768211455);
        assert!(overflowing, 0);
    }
    
    #[test]
    fun test_full_mul() {
        let (lo, hi) = full_mul(0, 0);
        assert!(lo == 0 && hi == 0, 0);
        let (lo, hi) = full_mul(0, 1);
        assert!(lo == 0 && hi == 0, 0);
        let (lo, hi) = full_mul(1, 0);
        assert!(lo == 0 && hi == 0, 0);
        let (lo, hi) = full_mul(0, 0xffffffffffffffff);
        assert!(lo == 0 && hi == 0, 0);
        let (lo, hi) = full_mul(0, 0xffffffffffffffffffffffffffffffff);
        assert!(lo == 0 && hi == 0, 0);
        let (lo, hi) = full_mul(0xffffffffffffffff, 0xffffffffffffffff);
        assert!(lo == 0xfffffffffffffffe0000000000000001 && hi == 0, 0);
        let (lo, hi) = full_mul(0xffffffffffffffff, 0xffffffffffffffffffffffffffffffff);
        assert!(lo == 0xffffffffffffffff0000000000000001 && hi == 0xfffffffffffffffe, 0);
        let (lo, hi) = full_mul(0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff);
        assert!(lo == 1 && hi == 0xfffffffffffffffffffffffffffffffe, 0);
    }

    #[test]
    fun test_hi() {
        // hi(0) = 0
        assert!(hi(0) == 0, 0);
        // hi(1) = 0
        assert!(hi(1) == 0, 0);
        // hi(1000) = 0
        assert!(hi(1000) == 0, 0);
        // hi(0xffffffffffffffff) = 0
        assert!(hi(0xffffffffffffffff) == 0, 0);
        // hi(0x27100000000000000000) = 10000
        assert!(hi(0x27100000000000000000) == 10000, 0);
        // hi(0xffffffffffffffff00000000) = 0xffffffff
        assert!(hi(0xffffffffffffffff00000000) == 0xffffffff, 0);
        // hi(0xffffffffffffffffffffffffffffffff) = 0xffffffffffffffff
        assert!(hi(0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffff, 0);
    }
    
    #[test]
    fun test_lo() {
        // lo(0) = 0
        assert!(lo(0) == 0, 0);
        // lo(1) = 1
        assert!(lo(1) == 1, 0);
        // lo(1000) = 1000
        assert!(lo(1000) == 1000, 0);
        // lo(0xffffffffffffffff) = 0xffffffffffffffff
        assert!(lo(0xffffffffffffffff) == 0xffffffffffffffff, 0);
        // lo(0x27100000000000000000) = 0
        assert!(lo(0x27100000000000000000) == 0, 0);
        // lo(0xffffffffffffffff00000000) = 0xffffffff00000000
        assert!(lo(0xffffffffffffffff00000000) == 0xffffffff00000000, 0);
        // lo(0xffffffffffffffffffffffffffffffff) = 0xffffffffffffffff
        assert!(lo(0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffff, 0);
    }

    #[test]
    fun test_hi_u128() {
        // hi_u128(0) = 0
        assert!(hi_u128(0) == 0, 0);
        // hi_u128(1) = 0
        assert!(hi_u128(1) == 0, 0);
        // hi_u128(1000) = 0
        assert!(hi_u128(1000) == 0, 0);
        // hi_u128(0xffffffffffffffff) = 0
        assert!(hi_u128(0xffffffffffffffff) == 0, 0);
        // hi_u128(0x27100000000000000000) = 10000
        assert!(hi_u128(0x27100000000000000000) == 10000, 0);
        // hi_u128(0xffffffffffffffff00000000) = 0xffffffff
        assert!(hi_u128(0xffffffffffffffff00000000) == 0xffffffff, 0);
        // hi_u128(0xffffffffffffffffffffffffffffffff) = 0xffffffffffffffff
        assert!(hi_u128(0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffff, 0);
    }
    
    #[test]
    fun test_lo_u128() {
        // lo_u128(0) = 0
        assert!(lo_u128(0) == 0, 0);
        // lo_u128(1) = 1
        assert!(lo_u128(1) == 1, 0);
        // lo_u128(1000) = 1000
        assert!(lo_u128(1000) == 1000, 0);
        // lo_u128(0xffffffffffffffff) = 0xffffffffffffffff
        assert!(lo_u128(0xffffffffffffffff) == 0xffffffffffffffff, 0);
        // lo_u128(0x27100000000000000000) = 0
        assert!(lo_u128(0x27100000000000000000) == 0, 0);
        // lo_u128(0xffffffffffffffff00000000) = 0xffffffff00000000
        assert!(lo_u128(0xffffffffffffffff00000000) == 0xffffffff00000000, 0);
        // lo_u128(0xffffffffffffffffffffffffffffffff) = 0xffffffffffffffff
        assert!(lo_u128(0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffff, 0);
    }

    #[test]
    fun test_from_lo_hi() {
        assert!(from_lo_hi(0, 0) == 0, 0);
        assert!(from_lo_hi(0, 1) == 0x10000000000000000, 0);
        assert!(from_lo_hi(1, 0) == 1, 0);
        assert!(from_lo_hi(1000, 1000) == 0x3e800000000000003e8, 0);
        assert!(from_lo_hi(0xffffffffffffffff, 0xffffffffffffffff) == 0xffffffffffffffffffffffffffffffff, 0);
        assert!(from_lo_hi(0x7fffffffffffffff, 0x5555555555555555) == 0x55555555555555557fffffffffffffff, 0);
        assert!(from_lo_hi(0x7fffffffffffffff, 0x7fffffffffffffff) == 0x7fffffffffffffff7fffffffffffffff, 0);
        assert!(from_lo_hi(0xffffffffffffffff, 0xffffffffffffffff) == 0xffffffffffffffffffffffffffffffff, 0);
    }
    
    #[test]
    fun test_checked_div_round() {
        assert!(checked_div_round(0, 1, false) == 0, 0);
        assert!(checked_div_round(1, 1, false) == 1, 0);
        assert!(checked_div_round(1, 2, false) == 0, 0);
        assert!(checked_div_round(0x989680, 3, false) == 0x32dcd5, 0);
        assert!(checked_div_round(0x989680, 7, false) == 0x15cc5b, 0);
        assert!(checked_div_round(10000, 0x989680, false) == 0, 0);
        assert!(checked_div_round(0xffffffffffffffffffffffffffffffff, 0x3b9aca00, false) == 0x44b82fa09b5a52cb98b405447, 0);
        assert!(checked_div_round(0xffffffffffffffffffffffffffffffff, 0xfffffffffffffffffffffffffff0bdbf, false) == 1, 0);
        assert!(checked_div_round(0xffffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffff, false) == 2, 0);
        assert!(checked_div_round(0, 1, true) == 0, 0);
        assert!(checked_div_round(1, 1, true) == 1, 0);
        assert!(checked_div_round(1, 2, true) == 1, 0);
        assert!(checked_div_round(0x989680, 3, true) == 0x32dcd6, 0);
        assert!(checked_div_round(0x989680, 7, true) == 0x15cc5c, 0);
        assert!(checked_div_round(10000, 0x989680, true) == 1, 0);
        assert!(checked_div_round(0xffffffffffffffffffffffffffffffff, 0x3b9aca00, true) == 0x44b82fa09b5a52cb98b405448, 0);
        assert!(checked_div_round(0xffffffffffffffffffffffffffffffff, 0xfffffffffffffffffffffffffff0bdbf, true) == 2, 0);
        assert!(checked_div_round(0xffffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffff, true) == 3, 0);
    }

    #[test]
    #[expected_failure]
    fun test_checked_div_round_by_zero() {
        checked_div_round(1, 0, false);
    }

    #[test]
    fun test_max() {
        assert!(max(0, 0) == 0, 0);
        assert!(max(0, 1) == 1, 0);
        assert!(max(1, 0) == 1, 0);
        assert!(max(1000, 1000) == 1000, 0);
        assert!(max(0xfffffffffffffffe, 0xffffffffffffffff) == 0xffffffffffffffff, 0);
        assert!(max(0xffffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffff) == 0xffffffffffffffffffffffffffffffff, 0);
        assert!(max(0xfffffffffffffffffffffffffffffffe, 0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffffffffffffffffffff, 0);
        assert!(max(0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffffffffffffffffffff, 0);
    }
    
    #[test]
    fun test_min() {
        assert!(min(0, 0) == 0, 0);
        assert!(min(0, 1) == 0, 0);
        assert!(min(1, 0) == 0, 0);
        assert!(min(1000, 1000) == 1000, 0);
        assert!(min(0xfffffffffffffffe, 0xffffffffffffffff) == 0xfffffffffffffffe, 0);
        assert!(min(0xffffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffff) == 0x7fffffffffffffffffffffffffffffff, 0);
        assert!(min(0xfffffffffffffffffffffffffffffffe, 0xffffffffffffffffffffffffffffffff) == 0xfffffffffffffffffffffffffffffffe, 0);
        assert!(min(0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffffffffffffffffffff, 0);
    }

    #[test]
    fun test_add_check() {
        assert!(add_check(0, 0) == true, 0);
        assert!(add_check(0, 1) == true, 0);
        assert!(add_check(1, 0) == true, 0);
        assert!(add_check(1, 0xffffffffffffffffffffffffffffffff) == false, 0);
        assert!(add_check(0x7fffffffffffffffffffffffffffffff, 0x55555555555555555555555555555555) == true, 0);
        assert!(add_check(0x7fffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffff) == true, 0);
        assert!(add_check(0xffffffffffffffffffffffffffffffff, 0xffffffffffffffffffffffffffffffff) == false, 0);
    }
}
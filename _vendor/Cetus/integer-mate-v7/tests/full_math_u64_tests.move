#[test_only]
#[allow(deprecated_usage)]
module integer_mate::full_math_u64_tests {
    use integer_mate::full_math_u64;
    const MAX_U64: u64 = 0xFFFF_FFFF_FFFF_FFFF;
    const MAX_U32: u64 = 0xFFFF_FFFF;

    #[test]
    fun test_mul_div_floor() {
        assert!(full_math_u64::mul_div_floor(0, 0, 1) == 0, 0);
        assert!(full_math_u64::mul_div_floor(2, 3, 1) == 6, 0);
        assert!(full_math_u64::mul_div_floor(100, 100, 2) == 5000, 0);
        assert!(full_math_u64::mul_div_floor(100, 100, 3) == 3333, 0);
        assert!(full_math_u64::mul_div_floor(200, 100, 3) == 6666, 0);
        assert!(full_math_u64::mul_div_floor(1, 1, MAX_U64) == 0, 0);
        assert!(full_math_u64::mul_div_floor(MAX_U64-1, 1, MAX_U64) == 0, 0);
        assert!(full_math_u64::mul_div_floor(MAX_U64, 1, 1) == MAX_U64, 0);
        assert!(full_math_u64::mul_div_floor(MAX_U64, 2, 2) == MAX_U64, 0);
        // mod = 0
        assert!(full_math_u64::mul_div_floor(MAX_U64, 2, 3) == 0xaaaaaaaaaaaaaaaa, 0);
        // mod = 2
        assert!(full_math_u64::mul_div_floor(MAX_U64, 2, 4) == 0x7fffffffffffffff, 0);
        // mod = 2
        assert!(full_math_u64::mul_div_floor(MAX_U64, 2, 7) == 0x4924924924924924, 0);
        // mod = 6
        assert!(full_math_u64::mul_div_floor(MAX_U64, 2, 8) == 0x3fffffffffffffff, 0);
        assert!(full_math_u64::mul_div_floor(MAX_U64, MAX_U64, MAX_U64) == MAX_U64, 0);
    }

    #[test]
    fun test_mul_div_round() {
        assert!(full_math_u64::mul_div_round(0, 0, 1) == 0, 0);
        assert!(full_math_u64::mul_div_round(2, 3, 1) == 6, 0);
        assert!(full_math_u64::mul_div_round(100, 100, 2) == 5000, 0);
        assert!(full_math_u64::mul_div_round(100, 100, 3) == 3333, 0);
        assert!(full_math_u64::mul_div_round(200, 100, 3) == 6667, 0);
        assert!(full_math_u64::mul_div_round(1, 1, MAX_U64) == 0, 0);
        assert!(full_math_u64::mul_div_round(MAX_U64-1, 1, MAX_U64) == 1, 0);
        assert!(full_math_u64::mul_div_round(MAX_U64, 1, 1) == MAX_U64, 0);
        assert!(full_math_u64::mul_div_round(MAX_U64, 2, 2) == MAX_U64, 0);
        // mod = 0
        assert!(full_math_u64::mul_div_round(MAX_U64, 2, 3) == 0xaaaaaaaaaaaaaaaa, 0);
        // mod = 2
        assert!(full_math_u64::mul_div_round(MAX_U64, 2, 4) == 0x8000000000000000, 0);
        // mod = 2
        assert!(full_math_u64::mul_div_round(MAX_U64, 2, 7) == 0x4924924924924924, 0);
        // mod = 6
        assert!(full_math_u64::mul_div_round(MAX_U64, 2, 8) == 0x4000000000000000, 0);
        assert!(full_math_u64::mul_div_round(MAX_U64, MAX_U64, MAX_U64) == MAX_U64, 0);
    }
    
    #[test]
    fun test_mul_div_ceil() {
        assert!(full_math_u64::mul_div_ceil(0, 0, 1) == 0, 0);
        assert!(full_math_u64::mul_div_ceil(2, 3, 1) == 6, 0);
        assert!(full_math_u64::mul_div_ceil(100, 100, 2) == 5000, 0);
        assert!(full_math_u64::mul_div_ceil(100, 100, 3) == 3334, 0);
        assert!(full_math_u64::mul_div_ceil(200, 100, 3) == 6667, 0);
        assert!(full_math_u64::mul_div_ceil(1, 1, MAX_U64) == 1, 0);
        assert!(full_math_u64::mul_div_ceil(MAX_U64-1, 1, MAX_U64) == 1, 0);
        assert!(full_math_u64::mul_div_ceil(MAX_U64, 1, 1) == MAX_U64, 0);
        assert!(full_math_u64::mul_div_ceil(MAX_U64, 2, 2) == MAX_U64, 0);
        // mod = 0
        assert!(full_math_u64::mul_div_ceil(MAX_U64, 2, 3) == 0xaaaaaaaaaaaaaaaa, 0);
        // mod = 2
        assert!(full_math_u64::mul_div_ceil(MAX_U64, 2, 4) == 0x8000000000000000, 0);
        // mod = 2
        assert!(full_math_u64::mul_div_ceil(MAX_U64, 2, 7) == 0x4924924924924925, 0);
        // mod = 6
        assert!(full_math_u64::mul_div_ceil(MAX_U64, 2, 8) == 0x4000000000000000, 0);
        assert!(full_math_u64::mul_div_ceil(MAX_U64, MAX_U64, MAX_U64) == MAX_U64, 0);
    }
    
    #[test]
    fun test_mul_shr() {
        assert!(full_math_u64::mul_shr(0, 0, 1) == 0, 0);
        assert!(full_math_u64::mul_shr(2, 3, 1) == (2 *3 ) >> 1, 0);
        assert!(full_math_u64::mul_shr(1, 1, 2) == 0, 0);
        assert!(full_math_u64::mul_shr(1, 1, 127) == 0, 0);
        assert!(full_math_u64::mul_shr(100, 100, 2) == (100 * 100) >> 2, 0);
        assert!(full_math_u64::mul_shr(MAX_U64, 2, 2) == MAX_U64 >> 1, 0);
        assert!(full_math_u64::mul_shr(MAX_U64, 1<<32, 32) == MAX_U64, 0);
        assert!(full_math_u64::mul_shr(MAX_U64, 1<<32, 96) == 0, 0);
        assert!(full_math_u64::mul_shr(1<<63, 1<<63, 125) == 2, 0);
        assert!(full_math_u64::mul_shr(1<<63, 1<<63, 126) == 1, 0);
        assert!(full_math_u64::mul_shr(1<<63, 1<<63, 127) == 0, 0);
    }
    
    #[test]
    fun test_mul_shl() {
        assert!(full_math_u64::mul_shl(0, 0, 1) == 0, 0);
        assert!(full_math_u64::mul_shl(2, 3, 1) == (2 *3 ) << 1, 0);
        assert!(full_math_u64::mul_shl(1, 1, 2) == (1 * 1) << 2, 0);
        assert!(full_math_u64::mul_shl(100, 100, 2) == (100 * 100) << 2, 0);
        assert!(full_math_u64::mul_shl(1, 1, 32) == 1 << 32, 0);
        assert!(full_math_u64::mul_shl(1<<63, 1<<63, 2) == 0, 0);
    }
    
    #[test]
    fun test_full_mul() {
        assert!(full_math_u64::full_mul(0, 0) == 0, 0);
        assert!(full_math_u64::full_mul(2, 3) == 6, 0);
        assert!(full_math_u64::full_mul(MAX_U32, MAX_U32) == 0xfffffffe00000001, 0);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_floor_overflow_div_zero() {
        full_math_u64::mul_div_floor(100, 100, 0);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_floor_overflow_1() {
        full_math_u64::mul_div_floor(MAX_U32 << 1, MAX_U32, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_floor_overflow_2() {
        full_math_u64::mul_div_floor(MAX_U64, 2, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_floor_overflow_3() {
        full_math_u64::mul_div_floor(MAX_U64, MAX_U64, 1);
    }
    
    
    #[test]
    #[expected_failure]
    fun test_mul_div_round_overflow_div_zero() {
        full_math_u64::mul_div_round(100, 100, 0);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_round_overflow_1() {
        full_math_u64::mul_div_round(MAX_U32 << 1, MAX_U32, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_round_overflow_2() {
        full_math_u64::mul_div_round(MAX_U64, 2, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_round_overflow_3() {
        full_math_u64::mul_div_round(MAX_U64, MAX_U64, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_ceil_overflow_div_zero() {
        full_math_u64::mul_div_ceil(100, 100, 0);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_ceil_overflow_1() {
        full_math_u64::mul_div_ceil(MAX_U32 << 1, MAX_U32, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_ceil_overflow_2() {
        full_math_u64::mul_div_ceil(MAX_U64, 2, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_div_ceil_overflow_3() {
        full_math_u64::mul_div_ceil(MAX_U64, MAX_U64, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_shr_overflow() {
        full_math_u64::mul_shr(MAX_U64, 1<<2, 1);
    }
    
    #[test]
    #[expected_failure]
    fun test_mul_shl_overflow() {
        full_math_u64::mul_shl(MAX_U64, 2, 1);
    }
}

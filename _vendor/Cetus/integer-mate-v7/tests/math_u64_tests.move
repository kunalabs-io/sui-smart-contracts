module integer_mate::math_u64_tests {
    use integer_mate::math_u64::{
        wrapping_add,
        wrapping_sub,
        wrapping_mul,
        overflowing_add,
        overflowing_sub,
        overflowing_mul,
        carry_add,
        add_check,
    };

    #[test]
    fun test_wrapping_add() {
        // wrapping_add(0 + 0) = 0
        assert!(wrapping_add(0, 0) == 0, 0);
        // wrapping_add(0 + 1) = 1
        assert!(wrapping_add(0, 1) == 1, 0);
        // wrapping_add(18446744073709551615 + 0) = 18446744073709551615
        assert!(wrapping_add(0xffffffffffffffff, 0) == 0xffffffffffffffff, 0);
        // wrapping_add(18446744073709551615 + 1) = 0
        assert!(wrapping_add(0xffffffffffffffff, 1) == 0, 0);
        // wrapping_add(9223372036854775807 + 18446744073709551615) = 9223372036854775806
        assert!(wrapping_add(0x7fffffffffffffff, 0xffffffffffffffff) == 0x7ffffffffffffffe, 0);
        // wrapping_add(6148914691236517205 + 18446744073709551615) = 6148914691236517204
        assert!(wrapping_add(0x5555555555555555, 0xffffffffffffffff) == 0x5555555555555554, 0);
        // wrapping_add(18446744073709551615 + 18446744073709551615) = 18446744073709551614
        assert!(wrapping_add(0xffffffffffffffff, 0xffffffffffffffff) == 0xfffffffffffffffe, 0);
    }

    #[test]
    fun test_wrapping_sub() {
        // wrapping_sub(0 - 0) = 0
        assert!(wrapping_sub(0, 0) == 0, 0);
        // wrapping_sub(0 - 10000) = 18446744073709541616
        assert!(wrapping_sub(0, 10000) == 0xffffffffffffd8f0, 0);
        // wrapping_sub(1 - 0) = 1
        assert!(wrapping_sub(1, 0) == 1, 0);
        // wrapping_sub(0 - 18446744073709551615) = 1
        assert!(wrapping_sub(0, 0xffffffffffffffff) == 1, 0);
        // wrapping_sub(3 - 18446744073709551613) = 6
        assert!(wrapping_sub(3, 0xfffffffffffffffd) == 6, 0);
        // wrapping_sub(9223372036854775807 - 18446744073709551615) = 9223372036854775808
        assert!(wrapping_sub(0x7fffffffffffffff, 0xffffffffffffffff) == 0x8000000000000000, 0);
    }

    #[test]
    fun test_wrapping_mul() {
        // wrapping_mul(0 * 0) = 0
        assert!(wrapping_mul(0, 0) == 0, 0);
        // wrapping_mul(0 * 1) = 0
        assert!(wrapping_mul(0, 1) == 0, 0);
        // wrapping_mul(0 * 18446744073709551615) = 0
        assert!(wrapping_mul(0, 0xffffffffffffffff) == 0, 0);
        // wrapping_mul(3 * 9223372036854775807) = 9223372036854775805
        assert!(wrapping_mul(3, 0x7fffffffffffffff) == 0x7ffffffffffffffd, 0);
        // wrapping_mul(9223372036854775807 * 6148914691236517205) = 3074457345618258603
        assert!(wrapping_mul(0x7fffffffffffffff, 0x5555555555555555) == 0x2aaaaaaaaaaaaaab, 0);
        // wrapping_mul(18446744073709551615 * 18446744073709551615) = 1
        assert!(wrapping_mul(0xffffffffffffffff, 0xffffffffffffffff) == 1, 0);
    }
    
    #[test]
    fun test_overflowing_add() {
        let (result, overflowing) = overflowing_add(0, 0);
        assert!(result == 0 && !overflowing, 0);
        let (result, overflowing) = overflowing_add(0, 1);
        assert!(result == 1 && !overflowing, 0);
        let (result, overflowing) = overflowing_add(1, 0);
        assert!(result == 1 && !overflowing, 0);
        let (_, overflowing) = overflowing_add(1, 18446744073709551615);
        assert!(overflowing, 0);
        let (result, overflowing) = overflowing_add(9223372036854775807, 6148914691236517205);
        assert!(result == 0xd555555555555554 && !overflowing, 0);
        let (result, overflowing) = overflowing_add(9223372036854775807, 9223372036854775807);
        assert!(result == 0xfffffffffffffffe && !overflowing, 0);
        let (_, overflowing) = overflowing_add(18446744073709551615, 18446744073709551615);
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
        let (_, overflowing) = overflowing_sub(0, 18446744073709551615);
        assert!(overflowing, 0);
        let (_, overflowing) = overflowing_sub(3, 18446744073709551613);
        assert!(overflowing, 0);
        let (_, overflowing) = overflowing_sub(9223372036854775807, 18446744073709551615);
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
        let (result, overflowing) = overflowing_mul(1, 18446744073709551615);
        assert!(result == 0xffffffffffffffff && !overflowing, 0);
        let (_, overflowing) = overflowing_mul(9223372036854775807, 6148914691236517205);
        assert!(overflowing, 0);
        let (_, overflowing) = overflowing_mul(9223372036854775807, 9223372036854775807);
        assert!(overflowing, 0);
        let (_, overflowing) = overflowing_mul(18446744073709551615, 18446744073709551615);
        assert!(overflowing, 0);
    }

    #[test]
    fun test_carry_add() {
        let (result, carry_out) = carry_add(0, 0, 0);
        assert!((result == 0) && (carry_out == 0), 0);
        let (result, carry_out) = carry_add(0xffffffffffffffff, 0, 1);
        assert!((result == 0) && (carry_out == 1), 0);
        let (result, carry_out) = carry_add(0xffffffffffffffff, 0, 0);
        assert!((result == 0xffffffffffffffff) && (carry_out == 0), 0);
        let (result, carry_out) = carry_add(0xffffffffffffffff, 1, 1);
        assert!((result == 1) && (carry_out == 1), 0);
        let (result, carry_out) = carry_add(0xffffffffffffffff, 1, 0);
        assert!((result == 0) && (carry_out == 1), 0);
        let (result, carry_out) = carry_add(0xffffffffffffffff, 1000, 1);
        assert!((result == 1000) && (carry_out == 1), 0);
        let (result, carry_out) = carry_add(0xffffffffffffffff, 1000, 0);
        assert!((result == 999) && (carry_out == 1), 0);
        let (result, carry_out) = carry_add(0xffffffffffffffff, 0xffffffffffffffff, 0);
        assert!((result == 0xfffffffffffffffe) && (carry_out == 1), 0);
        let (result, carry_out) = carry_add(0xffffffffffffffff, 0xffffffffffffffff, 1);
        assert!((result == 0xffffffffffffffff) && (carry_out == 1), 0);
    }

    #[test]
    #[expected_failure]
    fun test_carry_add_with_carry_in_2() {
        carry_add(0xffffffffffffffff, 0xffffffffffffffff, 2);
    }

    #[test]
    fun test_add_check() {
        assert!(add_check(0, 0), 0);
        assert!(add_check(0, 1), 0);
        assert!(add_check(1, 0), 0);
        assert!(!add_check(1, 0xffffffffffffffff), 0);
        assert!(add_check(0x7fffffffffffffff, 0x5555555555555555), 0);
        assert!(add_check(0x7fffffffffffffff, 0x7fffffffffffffff), 0);
        assert!(!add_check(0xffffffffffffffff, 0xffffffffffffffff), 0);
    }
}
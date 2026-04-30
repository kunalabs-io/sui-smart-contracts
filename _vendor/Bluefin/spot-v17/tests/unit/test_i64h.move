/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_i64h {
    use bluefin_spot::i64H;
    use integer_mate::i64 as MateI64;
    use integer_library::i64 as LibraryI64;

    //===========================================================//
    //                    Helper Functions                       //
    //===========================================================//

    // Create test values for comprehensive testing
    fun create_mate_zero(): MateI64::I64 {
        MateI64::zero()
    }

    fun create_mate_positive(): MateI64::I64 {
        MateI64::from(100)
    }

    fun create_mate_negative(): MateI64::I64 {
        MateI64::neg_from(100)
    }

    fun create_mate_max_positive(): MateI64::I64 {
        MateI64::from(9223372036854775807) // Max positive i64 (2^63 - 1)
    }

    fun create_mate_min_negative(): MateI64::I64 {
        MateI64::neg_from(9223372036854775808) // Min negative i64 (-2^63)
    }

    fun create_library_zero(): LibraryI64::I64 {
        LibraryI64::zero()
    }

    fun create_library_positive(): LibraryI64::I64 {
        LibraryI64::from(100)
    }

    fun create_library_negative(): LibraryI64::I64 {
        LibraryI64::neg_from(100)
    }

    //===========================================================//
    //                 Conversion Function Tests                 //
    //===========================================================//

    #[test]
    fun test_mate_to_lib_zero() {
        let mate_zero = create_mate_zero();
        let lib_result = i64H::mate_to_lib(mate_zero);
        let expected = create_library_zero();
        
        assert!(LibraryI64::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_mate_to_lib_positive() {
        let mate_pos = create_mate_positive();
        let lib_result = i64H::mate_to_lib(mate_pos);
        let expected = create_library_positive();
        
        assert!(LibraryI64::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_mate_to_lib_negative() {
        let mate_neg = create_mate_negative();
        let lib_result = i64H::mate_to_lib(mate_neg);
        let expected = create_library_negative();
        
        assert!(LibraryI64::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_zero() {
        let lib_zero = create_library_zero();
        let mate_result = i64H::lib_to_mate(lib_zero);
        let expected = create_mate_zero();
        
        assert!(MateI64::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_positive() {
        let lib_pos = create_library_positive();
        let mate_result = i64H::lib_to_mate(lib_pos);
        let expected = create_mate_positive();
        
        assert!(MateI64::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_negative() {
        let lib_neg = create_library_negative();
        let mate_result = i64H::lib_to_mate(lib_neg);
        let expected = create_mate_negative();
        
        assert!(MateI64::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_conversion_roundtrip_positive() {
        let original = create_mate_positive();
        let converted = i64H::lib_to_mate(i64H::mate_to_lib(original));
        
        assert!(MateI64::eq(original, converted), 0);
    }

    #[test]
    fun test_conversion_roundtrip_negative() {
        let original = create_mate_negative();
        let converted = i64H::lib_to_mate(i64H::mate_to_lib(original));
        
        assert!(MateI64::eq(original, converted), 0);
    }

    #[test]
    fun test_conversion_roundtrip_zero() {
        let original = create_mate_zero();
        let converted = i64H::lib_to_mate(i64H::mate_to_lib(original));
        
        assert!(MateI64::eq(original, converted), 0);
    }

    #[test]
    fun test_conversion_roundtrip_max_values() {
        let max_pos = create_mate_max_positive();
        let min_neg = create_mate_min_negative();
        
        let converted_max = i64H::lib_to_mate(i64H::mate_to_lib(max_pos));
        let converted_min = i64H::lib_to_mate(i64H::mate_to_lib(min_neg));
        
        assert!(MateI64::eq(max_pos, converted_max), 0);
        assert!(MateI64::eq(min_neg, converted_min), 0);
    }

    //===========================================================//
    //                 Arithmetic Function Tests                 //
    //===========================================================//

    #[test]
    fun test_add_positive_numbers() {
        let a = MateI64::from(50);
        let b = MateI64::from(30);
        let result = i64H::add(a, b);
        let expected = MateI64::from(80);
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_add_negative_numbers() {
        let a = MateI64::neg_from(50);
        let b = MateI64::neg_from(30);
        let result = i64H::add(a, b);
        let expected = MateI64::neg_from(80);
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_add_positive_and_negative() {
        let a = MateI64::from(100);
        let b = MateI64::neg_from(30);
        let result = i64H::add(a, b);
        let expected = MateI64::from(70);
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_add_with_zero() {
        let a = MateI64::from(42);
        let b = MateI64::zero();
        let result = i64H::add(a, b);
        
        assert!(MateI64::eq(result, a), 0);
    }

    #[test]
    fun test_add_opposite_values() {
        let a = MateI64::from(100);
        let b = MateI64::neg_from(100);
        let result = i64H::add(a, b);
        let expected = MateI64::zero();
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_positive_numbers() {
        let a = MateI64::from(100);
        let b = MateI64::from(30);
        let result = i64H::sub(a, b);
        let expected = MateI64::from(70);
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_negative_numbers() {
        let a = MateI64::neg_from(50);
        let b = MateI64::neg_from(30);
        let result = i64H::sub(a, b);
        let expected = MateI64::neg_from(20);
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_positive_minus_negative() {
        let a = MateI64::from(50);
        let b = MateI64::neg_from(30);
        let result = i64H::sub(a, b);
        let expected = MateI64::from(80);
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_with_zero() {
        let a = MateI64::from(42);
        let b = MateI64::zero();
        let result = i64H::sub(a, b);
        
        assert!(MateI64::eq(result, a), 0);
    }

    #[test]
    fun test_sub_zero_minus_positive() {
        let a = MateI64::zero();
        let b = MateI64::from(42);
        let result = i64H::sub(a, b);
        let expected = MateI64::neg_from(42);
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_same_values() {
        let a = MateI64::from(100);
        let b = MateI64::from(100);
        let result = i64H::sub(a, b);
        let expected = MateI64::zero();
        
        assert!(MateI64::eq(result, expected), 0);
    }

    //===========================================================//
    //                 Comparison Function Tests                 //
    //===========================================================//

    #[test]
    fun test_eq_same_positive() {
        let a = MateI64::from(100);
        let b = MateI64::from(100);
        
        assert!(i64H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_same_negative() {
        let a = MateI64::neg_from(100);
        let b = MateI64::neg_from(100);
        
        assert!(i64H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_both_zero() {
        let a = MateI64::zero();
        let b = MateI64::zero();
        
        assert!(i64H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_different_values() {
        let a = MateI64::from(100);
        let b = MateI64::from(200);
        
        assert!(!i64H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_positive_vs_negative() {
        let a = MateI64::from(100);
        let b = MateI64::neg_from(100);
        
        assert!(!i64H::eq(a, b), 0);
    }

    #[test]
    fun test_lt_positive_numbers() {
        let a = MateI64::from(50);
        let b = MateI64::from(100);
        
        assert!(i64H::lt(a, b), 0);
        assert!(!i64H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_negative_numbers() {
        let a = MateI64::neg_from(100);
        let b = MateI64::neg_from(50);
        
        assert!(i64H::lt(a, b), 0);
        assert!(!i64H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_negative_vs_positive() {
        let a = MateI64::neg_from(50);
        let b = MateI64::from(50);
        
        assert!(i64H::lt(a, b), 0);
        assert!(!i64H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_with_zero() {
        let negative = MateI64::neg_from(50);
        let zero = MateI64::zero();
        let positive = MateI64::from(50);
        
        assert!(i64H::lt(negative, zero), 0);
        assert!(i64H::lt(zero, positive), 0);
        assert!(i64H::lt(negative, positive), 0);
    }

    #[test]
    fun test_lt_equal_values() {
        let a = MateI64::from(100);
        let b = MateI64::from(100);
        
        assert!(!i64H::lt(a, b), 0);
        assert!(!i64H::lt(b, a), 0);
    }

    #[test]
    fun test_gt_positive_numbers() {
        let a = MateI64::from(100);
        let b = MateI64::from(50);
        
        assert!(i64H::gt(a, b), 0);
        assert!(!i64H::gt(b, a), 0);
    }

    #[test]
    fun test_gt_negative_numbers() {
        let a = MateI64::neg_from(50);
        let b = MateI64::neg_from(100);
        
        assert!(i64H::gt(a, b), 0);
        assert!(!i64H::gt(b, a), 0);
    }

    #[test]
    fun test_gt_positive_vs_negative() {
        let a = MateI64::from(50);
        let b = MateI64::neg_from(50);
        
        assert!(i64H::gt(a, b), 0);
        assert!(!i64H::gt(b, a), 0);
    }

    #[test]
    fun test_lte_equal_values() {
        let a = MateI64::from(100);
        let b = MateI64::from(100);
        
        assert!(i64H::lte(a, b), 0);
        assert!(i64H::lte(b, a), 0);
    }

    #[test]
    fun test_lte_different_values() {
        let a = MateI64::from(50);
        let b = MateI64::from(100);
        
        assert!(i64H::lte(a, b), 0);
        assert!(!i64H::lte(b, a), 0);
    }

    #[test]
    fun test_gte_equal_values() {
        let a = MateI64::from(100);
        let b = MateI64::from(100);
        
        assert!(i64H::gte(a, b), 0);
        assert!(i64H::gte(b, a), 0);
    }

    #[test]
    fun test_gte_different_values() {
        let a = MateI64::from(100);
        let b = MateI64::from(50);
        
        assert!(i64H::gte(a, b), 0);
        assert!(!i64H::gte(b, a), 0);
    }

    //===========================================================//
    //                 Sign Detection Tests                      //
    //===========================================================//

    #[test]
    fun test_is_neg_positive() {
        let positive = MateI64::from(100);
        
        assert!(!i64H::is_neg(positive), 0);
    }

    #[test]
    fun test_is_neg_negative() {
        let negative = MateI64::neg_from(100);
        
        assert!(i64H::is_neg(negative), 0);
    }

    #[test]
    fun test_is_neg_zero() {
        let zero = MateI64::zero();
        
        assert!(!i64H::is_neg(zero), 0);
    }

    #[test]
    fun test_is_neg_max_values() {
        let max_pos = create_mate_max_positive();
        let min_neg = create_mate_min_negative();
        
        assert!(!i64H::is_neg(max_pos), 0);
        assert!(i64H::is_neg(min_neg), 0);
    }

    //===========================================================//
    //                 Edge Case Tests                           //
    //===========================================================//

    #[test]
    fun test_large_positive_values() {
        let large1 = MateI64::from(1000000000000000);
        let large2 = MateI64::from(2000000000000000);
        
        // Test conversion roundtrip
        let converted = i64H::lib_to_mate(i64H::mate_to_lib(large1));
        assert!(MateI64::eq(large1, converted), 0);
        
        // Test comparison
        assert!(i64H::lt(large1, large2), 0);
        assert!(i64H::gt(large2, large1), 0);
    }

    #[test]
    fun test_large_negative_values() {
        let large_neg1 = MateI64::neg_from(1000000000000000);
        let large_neg2 = MateI64::neg_from(2000000000000000);
        
        // Test conversion roundtrip
        let converted = i64H::lib_to_mate(i64H::mate_to_lib(large_neg1));
        assert!(MateI64::eq(large_neg1, converted), 0);
        
        // Test comparison (more negative is smaller)
        assert!(i64H::lt(large_neg2, large_neg1), 0);
        assert!(i64H::gt(large_neg1, large_neg2), 0);
    }

    #[test]
    fun test_arithmetic_with_large_values() {
        let large_pos = MateI64::from(1000000000000000);
        let large_neg = MateI64::neg_from(1000000000000000);
        
        // Adding opposite values should give zero
        let result = i64H::add(large_pos, large_neg);
        let zero = MateI64::zero();
        assert!(MateI64::eq(result, zero), 0);
        
        // Subtracting same values should give zero
        let result2 = i64H::sub(large_pos, large_pos);
        assert!(MateI64::eq(result2, zero), 0);
    }

    #[test]
    fun test_boundary_values() {
        let max_pos = create_mate_max_positive();
        let min_neg = create_mate_min_negative();
        let zero = MateI64::zero();
        
        // Test comparisons with boundary values
        assert!(i64H::gt(max_pos, zero), 0);
        assert!(i64H::lt(min_neg, zero), 0);
        assert!(i64H::gt(max_pos, min_neg), 0);
        
        // Test sign detection
        assert!(!i64H::is_neg(max_pos), 0);
        assert!(i64H::is_neg(min_neg), 0);
    }

    #[test]
    fun test_medium_range_values() {
        let med1 = MateI64::from(4294967296); // 2^32
        let med2 = MateI64::from(8589934592); // 2^33
        let med_neg = MateI64::neg_from(4294967296);
        
        // Test arithmetic operations
        let sum = i64H::add(med1, med1);
        assert!(MateI64::eq(sum, med2), 0);
        
        // Test with negative
        let result = i64H::add(med1, med_neg);
        assert!(MateI64::eq(result, MateI64::zero()), 0);
    }

    //===========================================================//
    //                 Comprehensive Integration Tests           //
    //===========================================================//

    #[test]
    fun test_comprehensive_arithmetic_operations() {
        let a = MateI64::from(150);
        let b = MateI64::from(50);
        let c = MateI64::neg_from(25);
        
        // Test: (a + b) - c = 150 + 50 - (-25) = 225
        let sum = i64H::add(a, b);
        let result = i64H::sub(sum, c);
        let expected = MateI64::from(225);
        
        assert!(MateI64::eq(result, expected), 0);
    }

    #[test]
    fun test_comprehensive_comparison_chain() {
        let neg_large = MateI64::neg_from(100);
        let neg_small = MateI64::neg_from(50);
        let zero = MateI64::zero();
        let pos_small = MateI64::from(50);
        let pos_large = MateI64::from(100);
        
        // Test ordering: -100 < -50 < 0 < 50 < 100
        assert!(i64H::lt(neg_large, neg_small), 0);
        assert!(i64H::lt(neg_small, zero), 0);
        assert!(i64H::lt(zero, pos_small), 0);
        assert!(i64H::lt(pos_small, pos_large), 0);
        
        // Test lte/gte consistency
        assert!(i64H::lte(neg_large, neg_small), 0);
        assert!(i64H::gte(pos_large, pos_small), 0);
    }

    #[test]
    fun test_sign_consistency() {
        let positive = MateI64::from(42);
        let negative = MateI64::neg_from(42);
        let zero = MateI64::zero();
        
        // Test sign detection
        assert!(!i64H::is_neg(positive), 0);
        assert!(i64H::is_neg(negative), 0);
        assert!(!i64H::is_neg(zero), 0);
    }

    #[test]
    fun test_arithmetic_properties() {
        let a = MateI64::from(30);
        let b = MateI64::from(20);
        let c = MateI64::from(10);
        
        // Test commutativity: a + b = b + a
        let sum1 = i64H::add(a, b);
        let sum2 = i64H::add(b, a);
        assert!(MateI64::eq(sum1, sum2), 0);
        
        // Test associativity: (a + b) + c = a + (b + c)
        let left_assoc = i64H::add(i64H::add(a, b), c);
        let right_assoc = i64H::add(a, i64H::add(b, c));
        assert!(MateI64::eq(left_assoc, right_assoc), 0);
    }

    #[test]
    fun test_subtraction_properties() {
        let a = MateI64::from(100);
        let b = MateI64::from(50);
        let zero = MateI64::zero();
        
        // Test: a - b + b = a
        let diff = i64H::sub(a, b);
        let result = i64H::add(diff, b);
        assert!(MateI64::eq(result, a), 0);
        
        // Test: a - a = 0
        let self_diff = i64H::sub(a, a);
        assert!(MateI64::eq(self_diff, zero), 0);
    }
}

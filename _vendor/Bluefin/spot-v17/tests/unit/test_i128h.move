/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_i128h {
    use bluefin_spot::i128H;
    use integer_mate::i128 as MateI128;
    use integer_library::i128 as LibraryI128;
    //===========================================================//
    //                    Helper Functions                       //
    //===========================================================//

    // Create test values for comprehensive testing
    fun create_mate_zero(): MateI128::I128 {
        MateI128::zero()
    }

    fun create_mate_positive(): MateI128::I128 {
        MateI128::from(100)
    }

    fun create_mate_negative(): MateI128::I128 {
        MateI128::neg_from(100)
    }

    fun create_library_zero(): LibraryI128::I128 {
        LibraryI128::zero()
    }

    fun create_library_positive(): LibraryI128::I128 {
        LibraryI128::from(100)
    }

    fun create_library_negative(): LibraryI128::I128 {
        LibraryI128::neg_from(100)
    }

    //===========================================================//
    //                 Conversion Function Tests                 //
    //===========================================================//

    #[test]
    fun test_mate_to_lib_zero() {
        let mate_zero = create_mate_zero();
        let lib_result = i128H::mate_to_lib(mate_zero);
        let expected = create_library_zero();
        
        assert!(LibraryI128::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_mate_to_lib_positive() {
        let mate_pos = create_mate_positive();
        let lib_result = i128H::mate_to_lib(mate_pos);
        let expected = create_library_positive();
        
        assert!(LibraryI128::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_mate_to_lib_negative() {
        let mate_neg = create_mate_negative();
        let lib_result = i128H::mate_to_lib(mate_neg);
        let expected = create_library_negative();
        
        assert!(LibraryI128::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_zero() {
        let lib_zero = create_library_zero();
        let mate_result = i128H::lib_to_mate(lib_zero);
        let expected = create_mate_zero();
        
        assert!(MateI128::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_positive() {
        let lib_pos = create_library_positive();
        let mate_result = i128H::lib_to_mate(lib_pos);
        let expected = create_mate_positive();
        
        assert!(MateI128::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_negative() {
        let lib_neg = create_library_negative();
        let mate_result = i128H::lib_to_mate(lib_neg);
        let expected = create_mate_negative();
        
        assert!(MateI128::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_conversion_roundtrip_positive() {
        let original = create_mate_positive();
        let converted = i128H::lib_to_mate(i128H::mate_to_lib(original));
        
        assert!(MateI128::eq(original, converted), 0);
    }

    #[test]
    fun test_conversion_roundtrip_negative() {
        let original = create_mate_negative();
        let converted = i128H::lib_to_mate(i128H::mate_to_lib(original));
        
        assert!(MateI128::eq(original, converted), 0);
    }

    #[test]
    fun test_conversion_roundtrip_zero() {
        let original = create_mate_zero();
        let converted = i128H::lib_to_mate(i128H::mate_to_lib(original));
        
        assert!(MateI128::eq(original, converted), 0);
    }

    //===========================================================//
    //                 Arithmetic Function Tests                 //
    //===========================================================//

    #[test]
    fun test_add_positive_numbers() {
        let a = MateI128::from(50);
        let b = MateI128::from(30);
        let result = i128H::add(a, b);
        let expected = MateI128::from(80);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_add_negative_numbers() {
        let a = MateI128::neg_from(50);
        let b = MateI128::neg_from(30);
        let result = i128H::add(a, b);
        let expected = MateI128::neg_from(80);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_add_positive_and_negative() {
        let a = MateI128::from(100);
        let b = MateI128::neg_from(30);
        let result = i128H::add(a, b);
        let expected = MateI128::from(70);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_add_with_zero() {
        let a = MateI128::from(42);
        let b = MateI128::zero();
        let result = i128H::add(a, b);
        
        assert!(MateI128::eq(result, a), 0);
    }

    #[test]
    fun test_sub_positive_numbers() {
        let a = MateI128::from(100);
        let b = MateI128::from(30);
        let result = i128H::sub(a, b);
        let expected = MateI128::from(70);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_negative_numbers() {
        let a = MateI128::neg_from(50);
        let b = MateI128::neg_from(30);
        let result = i128H::sub(a, b);
        let expected = MateI128::neg_from(20);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_positive_minus_negative() {
        let a = MateI128::from(50);
        let b = MateI128::neg_from(30);
        let result = i128H::sub(a, b);
        let expected = MateI128::from(80);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_with_zero() {
        let a = MateI128::from(42);
        let b = MateI128::zero();
        let result = i128H::sub(a, b);
        
        assert!(MateI128::eq(result, a), 0);
    }

    #[test]
    fun test_sub_zero_minus_positive() {
        let a = MateI128::zero();
        let b = MateI128::from(42);
        let result = i128H::sub(a, b);
        let expected = MateI128::neg_from(42);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    //===========================================================//
    //                 Comparison Function Tests                 //
    //===========================================================//

    #[test]
    fun test_eq_same_positive() {
        let a = MateI128::from(100);
        let b = MateI128::from(100);
        
        assert!(i128H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_same_negative() {
        let a = MateI128::neg_from(100);
        let b = MateI128::neg_from(100);
        
        assert!(i128H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_both_zero() {
        let a = MateI128::zero();
        let b = MateI128::zero();
        
        assert!(i128H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_different_values() {
        let a = MateI128::from(100);
        let b = MateI128::from(200);
        
        assert!(!i128H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_positive_vs_negative() {
        let a = MateI128::from(100);
        let b = MateI128::neg_from(100);
        
        assert!(!i128H::eq(a, b), 0);
    }

    #[test]
    fun test_lt_positive_numbers() {
        let a = MateI128::from(50);
        let b = MateI128::from(100);
        
        assert!(i128H::lt(a, b), 0);
        assert!(!i128H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_negative_numbers() {
        let a = MateI128::neg_from(100);
        let b = MateI128::neg_from(50);
        
        assert!(i128H::lt(a, b), 0);
        assert!(!i128H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_negative_vs_positive() {
        let a = MateI128::neg_from(50);
        let b = MateI128::from(50);
        
        assert!(i128H::lt(a, b), 0);
        assert!(!i128H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_with_zero() {
        let negative = MateI128::neg_from(50);
        let zero = MateI128::zero();
        let positive = MateI128::from(50);
        
        assert!(i128H::lt(negative, zero), 0);
        assert!(i128H::lt(zero, positive), 0);
        assert!(i128H::lt(negative, positive), 0);
    }

    #[test]
    fun test_gt_positive_numbers() {
        let a = MateI128::from(100);
        let b = MateI128::from(50);
        
        assert!(i128H::gt(a, b), 0);
        assert!(!i128H::gt(b, a), 0);
    }

    #[test]
    fun test_gt_negative_numbers() {
        let a = MateI128::neg_from(50);
        let b = MateI128::neg_from(100);
        
        assert!(i128H::gt(a, b), 0);
        assert!(!i128H::gt(b, a), 0);
    }

    #[test]
    fun test_lte_equal_values() {
        let a = MateI128::from(100);
        let b = MateI128::from(100);
        
        assert!(i128H::lte(a, b), 0);
        assert!(i128H::lte(b, a), 0);
    }

    #[test]
    fun test_lte_different_values() {
        let a = MateI128::from(50);
        let b = MateI128::from(100);
        
        assert!(i128H::lte(a, b), 0);
        assert!(!i128H::lte(b, a), 0);
    }

    #[test]
    fun test_gte_equal_values() {
        let a = MateI128::from(100);
        let b = MateI128::from(100);
        
        assert!(i128H::gte(a, b), 0);
        assert!(i128H::gte(b, a), 0);
    }

    #[test]
    fun test_gte_different_values() {
        let a = MateI128::from(100);
        let b = MateI128::from(50);
        
        assert!(i128H::gte(a, b), 0);
        assert!(!i128H::gte(b, a), 0);
    }

    //===========================================================//
    //                 Sign and Negation Tests                   //
    //===========================================================//

    #[test]
    fun test_is_neg_positive() {
        let positive = MateI128::from(100);
        
        assert!(!i128H::is_neg(positive), 0);
    }

    #[test]
    fun test_is_neg_negative() {
        let negative = MateI128::neg_from(100);
        
        assert!(i128H::is_neg(negative), 0);
    }

    #[test]
    fun test_is_neg_zero() {
        let zero = MateI128::zero();
        
        assert!(!i128H::is_neg(zero), 0);
    }

    #[test]
    fun test_neg_positive() {
        let positive = MateI128::from(100);
        let result = i128H::neg(positive);
        let expected = MateI128::neg_from(100);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_neg_negative() {
        let negative = MateI128::neg_from(100);
        let result = i128H::neg(negative);
        let expected = MateI128::from(100);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_neg_zero() {
        let zero = MateI128::zero();
        let result = i128H::neg(zero);
        
        assert!(MateI128::eq(result, zero), 0);
    }

    #[test]
    fun test_double_negation() {
        let original = MateI128::from(100);
        let double_neg = i128H::neg(i128H::neg(original));
        
        assert!(MateI128::eq(original, double_neg), 0);
    }

    //===========================================================//
    //                 Deprecated Function Tests                 //
    //===========================================================//

    #[test]
    #[expected_failure(abort_code = 1036, location = bluefin_spot::i128H)]
    fun test_neg_from_is_deprecated() {
        // This function is deprecated and should abort with error code 1036
        let dummy = MateI128::zero();
        i128H::neg_from(dummy);
    }

    //===========================================================//
    //                 Edge Case Tests                           //
    //===========================================================//

    #[test]
    fun test_large_positive_values() {
        let large1 = MateI128::from(1000000000000000000);
        let large2 = MateI128::from(2000000000000000000);
        
        // Test conversion roundtrip
        let converted = i128H::lib_to_mate(i128H::mate_to_lib(large1));
        assert!(MateI128::eq(large1, converted), 0);
        
        // Test comparison
        assert!(i128H::lt(large1, large2), 0);
        assert!(i128H::gt(large2, large1), 0);
    }

    #[test]
    fun test_large_negative_values() {
        let large_neg1 = MateI128::neg_from(1000000000000000000);
        let large_neg2 = MateI128::neg_from(2000000000000000000);
        
        // Test conversion roundtrip
        let converted = i128H::lib_to_mate(i128H::mate_to_lib(large_neg1));
        assert!(MateI128::eq(large_neg1, converted), 0);
        
        // Test comparison (more negative is smaller)
        assert!(i128H::lt(large_neg2, large_neg1), 0);
        assert!(i128H::gt(large_neg1, large_neg2), 0);
    }

    #[test]
    fun test_arithmetic_with_large_values() {
        let large_pos = MateI128::from(1000000000000000000);
        let large_neg = MateI128::neg_from(1000000000000000000);
        
        // Adding opposite values should give zero
        let result = i128H::add(large_pos, large_neg);
        let zero = MateI128::zero();
        assert!(MateI128::eq(result, zero), 0);
        
        // Subtracting same values should give zero
        let result2 = i128H::sub(large_pos, large_pos);
        assert!(MateI128::eq(result2, zero), 0);
    }

    //===========================================================//
    //                 Comprehensive Integration Tests           //
    //===========================================================//

    #[test]
    fun test_comprehensive_arithmetic_operations() {
        let a = MateI128::from(150);
        let b = MateI128::from(50);
        let c = MateI128::neg_from(25);
        
        // Test: (a + b) - c = 150 + 50 - (-25) = 225
        let sum = i128H::add(a, b);
        let result = i128H::sub(sum, c);
        let expected = MateI128::from(225);
        
        assert!(MateI128::eq(result, expected), 0);
    }

    #[test]
    fun test_comprehensive_comparison_chain() {
        let neg_large = MateI128::neg_from(100);
        let neg_small = MateI128::neg_from(50);
        let zero = MateI128::zero();
        let pos_small = MateI128::from(50);
        let pos_large = MateI128::from(100);
        
        // Test ordering: -100 < -50 < 0 < 50 < 100
        assert!(i128H::lt(neg_large, neg_small), 0);
        assert!(i128H::lt(neg_small, zero), 0);
        assert!(i128H::lt(zero, pos_small), 0);
        assert!(i128H::lt(pos_small, pos_large), 0);
        
        // Test lte/gte consistency
        assert!(i128H::lte(neg_large, neg_small), 0);
        assert!(i128H::gte(pos_large, pos_small), 0);
    }

    #[test]
    fun test_sign_consistency() {
        let positive = MateI128::from(42);
        let negative = MateI128::neg_from(42);
        let zero = MateI128::zero();
        
        // Test sign detection
        assert!(!i128H::is_neg(positive), 0);
        assert!(i128H::is_neg(negative), 0);
        assert!(!i128H::is_neg(zero), 0);
        
        // Test negation consistency
        assert!(MateI128::eq(i128H::neg(positive), negative), 0);
        assert!(MateI128::eq(i128H::neg(negative), positive), 0);
        assert!(MateI128::eq(i128H::neg(zero), zero), 0);
    }
}

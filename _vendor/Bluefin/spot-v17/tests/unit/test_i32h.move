/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_i32h {
    use bluefin_spot::i32H;
    use integer_mate::i32 as MateI32;
    use integer_library::i32 as LibraryI32;

    //===========================================================//
    //                    Helper Functions                       //
    //===========================================================//

    // Create test values for comprehensive testing
    fun create_mate_zero(): MateI32::I32 {
        MateI32::zero()
    }

    fun create_mate_positive(): MateI32::I32 {
        MateI32::from(100)
    }

    fun create_mate_negative(): MateI32::I32 {
        MateI32::neg_from(100)
    }

    fun create_mate_max_positive(): MateI32::I32 {
        MateI32::from(2147483647) // Max positive i32 (2^31 - 1)
    }

    fun create_mate_min_negative(): MateI32::I32 {
        MateI32::neg_from(2147483648) // Min negative i32 (-2^31)
    }

    fun create_library_zero(): LibraryI32::I32 {
        LibraryI32::zero()
    }

    fun create_library_positive(): LibraryI32::I32 {
        LibraryI32::from(100)
    }

    fun create_library_negative(): LibraryI32::I32 {
        LibraryI32::neg_from(100)
    }

    //===========================================================//
    //                 Conversion Function Tests                 //
    //===========================================================//

    #[test]
    fun test_mate_to_lib_zero() {
        let mate_zero = create_mate_zero();
        let lib_result = i32H::mate_to_lib(mate_zero);
        let expected = create_library_zero();
        
        assert!(LibraryI32::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_mate_to_lib_positive() {
        let mate_pos = create_mate_positive();
        let lib_result = i32H::mate_to_lib(mate_pos);
        let expected = create_library_positive();
        
        assert!(LibraryI32::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_mate_to_lib_negative() {
        let mate_neg = create_mate_negative();
        let lib_result = i32H::mate_to_lib(mate_neg);
        let expected = create_library_negative();
        
        assert!(LibraryI32::eq(lib_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_zero() {
        let lib_zero = create_library_zero();
        let mate_result = i32H::lib_to_mate(lib_zero);
        let expected = create_mate_zero();
        
        assert!(MateI32::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_positive() {
        let lib_pos = create_library_positive();
        let mate_result = i32H::lib_to_mate(lib_pos);
        let expected = create_mate_positive();
        
        assert!(MateI32::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_lib_to_mate_negative() {
        let lib_neg = create_library_negative();
        let mate_result = i32H::lib_to_mate(lib_neg);
        let expected = create_mate_negative();
        
        assert!(MateI32::eq(mate_result, expected), 0);
    }

    #[test]
    fun test_conversion_roundtrip_positive() {
        let original = create_mate_positive();
        let converted = i32H::lib_to_mate(i32H::mate_to_lib(original));
        
        assert!(MateI32::eq(original, converted), 0);
    }

    #[test]
    fun test_conversion_roundtrip_negative() {
        let original = create_mate_negative();
        let converted = i32H::lib_to_mate(i32H::mate_to_lib(original));
        
        assert!(MateI32::eq(original, converted), 0);
    }

    #[test]
    fun test_conversion_roundtrip_zero() {
        let original = create_mate_zero();
        let converted = i32H::lib_to_mate(i32H::mate_to_lib(original));
        
        assert!(MateI32::eq(original, converted), 0);
    }

    #[test]
    fun test_conversion_roundtrip_max_values() {
        let max_pos = create_mate_max_positive();
        let min_neg = create_mate_min_negative();
        
        let converted_max = i32H::lib_to_mate(i32H::mate_to_lib(max_pos));
        let converted_min = i32H::lib_to_mate(i32H::mate_to_lib(min_neg));
        
        assert!(MateI32::eq(max_pos, converted_max), 0);
        assert!(MateI32::eq(min_neg, converted_min), 0);
    }

    //===========================================================//
    //                 Arithmetic Function Tests                 //
    //===========================================================//

    #[test]
    fun test_add_positive_numbers() {
        let a = MateI32::from(50);
        let b = MateI32::from(30);
        let result = i32H::add(a, b);
        let expected = MateI32::from(80);
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_add_negative_numbers() {
        let a = MateI32::neg_from(50);
        let b = MateI32::neg_from(30);
        let result = i32H::add(a, b);
        let expected = MateI32::neg_from(80);
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_add_positive_and_negative() {
        let a = MateI32::from(100);
        let b = MateI32::neg_from(30);
        let result = i32H::add(a, b);
        let expected = MateI32::from(70);
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_add_with_zero() {
        let a = MateI32::from(42);
        let b = MateI32::zero();
        let result = i32H::add(a, b);
        
        assert!(MateI32::eq(result, a), 0);
    }

    #[test]
    fun test_add_opposite_values() {
        let a = MateI32::from(100);
        let b = MateI32::neg_from(100);
        let result = i32H::add(a, b);
        let expected = MateI32::zero();
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_positive_numbers() {
        let a = MateI32::from(100);
        let b = MateI32::from(30);
        let result = i32H::sub(a, b);
        let expected = MateI32::from(70);
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_negative_numbers() {
        let a = MateI32::neg_from(50);
        let b = MateI32::neg_from(30);
        let result = i32H::sub(a, b);
        let expected = MateI32::neg_from(20);
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_positive_minus_negative() {
        let a = MateI32::from(50);
        let b = MateI32::neg_from(30);
        let result = i32H::sub(a, b);
        let expected = MateI32::from(80);
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_with_zero() {
        let a = MateI32::from(42);
        let b = MateI32::zero();
        let result = i32H::sub(a, b);
        
        assert!(MateI32::eq(result, a), 0);
    }

    #[test]
    fun test_sub_zero_minus_positive() {
        let a = MateI32::zero();
        let b = MateI32::from(42);
        let result = i32H::sub(a, b);
        let expected = MateI32::neg_from(42);
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_sub_same_values() {
        let a = MateI32::from(100);
        let b = MateI32::from(100);
        let result = i32H::sub(a, b);
        let expected = MateI32::zero();
        
        assert!(MateI32::eq(result, expected), 0);
    }

    //===========================================================//
    //                 Comparison Function Tests                 //
    //===========================================================//

    #[test]
    fun test_eq_same_positive() {
        let a = MateI32::from(100);
        let b = MateI32::from(100);
        
        assert!(i32H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_same_negative() {
        let a = MateI32::neg_from(100);
        let b = MateI32::neg_from(100);
        
        assert!(i32H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_both_zero() {
        let a = MateI32::zero();
        let b = MateI32::zero();
        
        assert!(i32H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_different_values() {
        let a = MateI32::from(100);
        let b = MateI32::from(200);
        
        assert!(!i32H::eq(a, b), 0);
    }

    #[test]
    fun test_eq_positive_vs_negative() {
        let a = MateI32::from(100);
        let b = MateI32::neg_from(100);
        
        assert!(!i32H::eq(a, b), 0);
    }

    #[test]
    fun test_lt_positive_numbers() {
        let a = MateI32::from(50);
        let b = MateI32::from(100);
        
        assert!(i32H::lt(a, b), 0);
        assert!(!i32H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_negative_numbers() {
        let a = MateI32::neg_from(100);
        let b = MateI32::neg_from(50);
        
        assert!(i32H::lt(a, b), 0);
        assert!(!i32H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_negative_vs_positive() {
        let a = MateI32::neg_from(50);
        let b = MateI32::from(50);
        
        assert!(i32H::lt(a, b), 0);
        assert!(!i32H::lt(b, a), 0);
    }

    #[test]
    fun test_lt_with_zero() {
        let negative = MateI32::neg_from(50);
        let zero = MateI32::zero();
        let positive = MateI32::from(50);
        
        assert!(i32H::lt(negative, zero), 0);
        assert!(i32H::lt(zero, positive), 0);
        assert!(i32H::lt(negative, positive), 0);
    }

    #[test]
    fun test_lt_equal_values() {
        let a = MateI32::from(100);
        let b = MateI32::from(100);
        
        assert!(!i32H::lt(a, b), 0);
        assert!(!i32H::lt(b, a), 0);
    }

    #[test]
    fun test_gt_positive_numbers() {
        let a = MateI32::from(100);
        let b = MateI32::from(50);
        
        assert!(i32H::gt(a, b), 0);
        assert!(!i32H::gt(b, a), 0);
    }

    #[test]
    fun test_gt_negative_numbers() {
        let a = MateI32::neg_from(50);
        let b = MateI32::neg_from(100);
        
        assert!(i32H::gt(a, b), 0);
        assert!(!i32H::gt(b, a), 0);
    }

    #[test]
    fun test_gt_positive_vs_negative() {
        let a = MateI32::from(50);
        let b = MateI32::neg_from(50);
        
        assert!(i32H::gt(a, b), 0);
        assert!(!i32H::gt(b, a), 0);
    }

    #[test]
    fun test_lte_equal_values() {
        let a = MateI32::from(100);
        let b = MateI32::from(100);
        
        assert!(i32H::lte(a, b), 0);
        assert!(i32H::lte(b, a), 0);
    }

    #[test]
    fun test_lte_different_values() {
        let a = MateI32::from(50);
        let b = MateI32::from(100);
        
        assert!(i32H::lte(a, b), 0);
        assert!(!i32H::lte(b, a), 0);
    }

    #[test]
    fun test_gte_equal_values() {
        let a = MateI32::from(100);
        let b = MateI32::from(100);
        
        assert!(i32H::gte(a, b), 0);
        assert!(i32H::gte(b, a), 0);
    }

    #[test]
    fun test_gte_different_values() {
        let a = MateI32::from(100);
        let b = MateI32::from(50);
        
        assert!(i32H::gte(a, b), 0);
        assert!(!i32H::gte(b, a), 0);
    }

    //===========================================================//
    //                 Sign Detection Tests                      //
    //===========================================================//

    #[test]
    fun test_is_neg_positive() {
        let positive = MateI32::from(100);
        
        assert!(!i32H::is_neg(positive), 0);
    }

    #[test]
    fun test_is_neg_negative() {
        let negative = MateI32::neg_from(100);
        
        assert!(i32H::is_neg(negative), 0);
    }

    #[test]
    fun test_is_neg_zero() {
        let zero = MateI32::zero();
        
        assert!(!i32H::is_neg(zero), 0);
    }

    #[test]
    fun test_is_neg_max_values() {
        let max_pos = create_mate_max_positive();
        let min_neg = create_mate_min_negative();
        
        assert!(!i32H::is_neg(max_pos), 0);
        assert!(i32H::is_neg(min_neg), 0);
    }

    //===========================================================//
    //                 Edge Case Tests                           //
    //===========================================================//

    #[test]
    fun test_large_positive_values() {
        let large1 = MateI32::from(1000000);
        let large2 = MateI32::from(2000000);
        
        // Test conversion roundtrip
        let converted = i32H::lib_to_mate(i32H::mate_to_lib(large1));
        assert!(MateI32::eq(large1, converted), 0);
        
        // Test comparison
        assert!(i32H::lt(large1, large2), 0);
        assert!(i32H::gt(large2, large1), 0);
    }

    #[test]
    fun test_large_negative_values() {
        let large_neg1 = MateI32::neg_from(1000000);
        let large_neg2 = MateI32::neg_from(2000000);
        
        // Test conversion roundtrip
        let converted = i32H::lib_to_mate(i32H::mate_to_lib(large_neg1));
        assert!(MateI32::eq(large_neg1, converted), 0);
        
        // Test comparison (more negative is smaller)
        assert!(i32H::lt(large_neg2, large_neg1), 0);
        assert!(i32H::gt(large_neg1, large_neg2), 0);
    }

    #[test]
    fun test_arithmetic_with_large_values() {
        let large_pos = MateI32::from(1000000);
        let large_neg = MateI32::neg_from(1000000);
        
        // Adding opposite values should give zero
        let result = i32H::add(large_pos, large_neg);
        let zero = MateI32::zero();
        assert!(MateI32::eq(result, zero), 0);
        
        // Subtracting same values should give zero
        let result2 = i32H::sub(large_pos, large_pos);
        assert!(MateI32::eq(result2, zero), 0);
    }

    #[test]
    fun test_boundary_values() {
        let max_pos = create_mate_max_positive();
        let min_neg = create_mate_min_negative();
        let zero = MateI32::zero();
        
        // Test comparisons with boundary values
        assert!(i32H::gt(max_pos, zero), 0);
        assert!(i32H::lt(min_neg, zero), 0);
        assert!(i32H::gt(max_pos, min_neg), 0);
        
        // Test sign detection
        assert!(!i32H::is_neg(max_pos), 0);
        assert!(i32H::is_neg(min_neg), 0);
    }

    //===========================================================//
    //                 Comprehensive Integration Tests           //
    //===========================================================//

    #[test]
    fun test_comprehensive_arithmetic_operations() {
        let a = MateI32::from(150);
        let b = MateI32::from(50);
        let c = MateI32::neg_from(25);
        
        // Test: (a + b) - c = 150 + 50 - (-25) = 225
        let sum = i32H::add(a, b);
        let result = i32H::sub(sum, c);
        let expected = MateI32::from(225);
        
        assert!(MateI32::eq(result, expected), 0);
    }

    #[test]
    fun test_comprehensive_comparison_chain() {
        let neg_large = MateI32::neg_from(100);
        let neg_small = MateI32::neg_from(50);
        let zero = MateI32::zero();
        let pos_small = MateI32::from(50);
        let pos_large = MateI32::from(100);
        
        // Test ordering: -100 < -50 < 0 < 50 < 100
        assert!(i32H::lt(neg_large, neg_small), 0);
        assert!(i32H::lt(neg_small, zero), 0);
        assert!(i32H::lt(zero, pos_small), 0);
        assert!(i32H::lt(pos_small, pos_large), 0);
        
        // Test lte/gte consistency
        assert!(i32H::lte(neg_large, neg_small), 0);
        assert!(i32H::gte(pos_large, pos_small), 0);
    }

    #[test]
    fun test_sign_consistency() {
        let positive = MateI32::from(42);
        let negative = MateI32::neg_from(42);
        let zero = MateI32::zero();
        
        // Test sign detection
        assert!(!i32H::is_neg(positive), 0);
        assert!(i32H::is_neg(negative), 0);
        assert!(!i32H::is_neg(zero), 0);
    }

    #[test]
    fun test_arithmetic_properties() {
        let a = MateI32::from(30);
        let b = MateI32::from(20);
        let c = MateI32::from(10);
        
        // Test commutativity: a + b = b + a
        let sum1 = i32H::add(a, b);
        let sum2 = i32H::add(b, a);
        assert!(MateI32::eq(sum1, sum2), 0);
        
        // Test associativity: (a + b) + c = a + (b + c)
        let left_assoc = i32H::add(i32H::add(a, b), c);
        let right_assoc = i32H::add(a, i32H::add(b, c));
        assert!(MateI32::eq(left_assoc, right_assoc), 0);
    }
}

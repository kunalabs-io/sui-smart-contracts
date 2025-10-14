/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/


#[test_only]
module bluefin_spot::test_tick_bitmap {
    use sui::table::{Self, Table};
    use sui::test_scenario::{Self, Scenario};
    use bluefin_spot::tick_bitmap;
    use integer_mate::i32::{Self as MateI32, I32 as MateI32Type};

    const ADMIN: address = @0xAD;

    //===========================================================//
    //                   Helper Functions                       //
    //===========================================================//

    fun create_empty_bitmap(scenario: &mut Scenario): Table<MateI32Type, u256> {
        let ctx = test_scenario::ctx(scenario);
        table::new<MateI32Type, u256>(ctx)
    }

    //===========================================================//
    //                 cast_to_u8 Function Tests               //
    //===========================================================//

    #[test]
    fun test_cast_to_u8_positive_values() {
        // Test positive values within range
        let positive_values = vector[0u32, 1u32, 50u32, 100u32, 200u32, 255u32];
        let i = 0;
        while (i < std::vector::length(&positive_values)) {
            let value = *std::vector::borrow(&positive_values, i);
            let index = MateI32::from(value);
            let result = tick_bitmap::cast_to_u8(index);
            assert!(result == (value as u8), i);
            i = i + 1;
        };
    }

    #[test]
    fun test_cast_to_u8_negative_values() {
        // Test negative values within range
        let negative_values = vector[1u32, 50u32, 100u32, 200u32, 255u32];
        let expected_results = vector[255u8, 206u8, 156u8, 56u8, 1u8];
        
        let i = 0;
        while (i < std::vector::length(&negative_values)) {
            let value = *std::vector::borrow(&negative_values, i);
            let expected = *std::vector::borrow(&expected_results, i);
            let index = MateI32::neg_from(value);
            let result = tick_bitmap::cast_to_u8(index);
            assert!(result == expected, i);
            i = i + 1;
        };
    }

    #[test]
    fun test_cast_to_u8_boundary_values() {
        // Test boundary values
        let zero = MateI32::zero();
        assert!(tick_bitmap::cast_to_u8(zero) == 0u8, 0);
        
        let positive_255 = MateI32::from(255u32);
        assert!(tick_bitmap::cast_to_u8(positive_255) == 255u8, 1);
        
        let negative_255 = MateI32::neg_from(255u32);
        assert!(tick_bitmap::cast_to_u8(negative_255) == 1u8, 2);
    }

    #[test]
    fun test_cast_to_u8_edge_cases() {
        // Test values close to boundaries
        let values = vector[1u32, 254u32, 1u32, 2u32, 128u32, 128u32];
        let is_negative = vector[false, false, true, true, false, true];
        let expected = vector[1u8, 254u8, 255u8, 254u8, 128u8, 128u8];
        
        let i = 0;
        while (i < std::vector::length(&values)) {
            let value = *std::vector::borrow(&values, i);
            let negative = *std::vector::borrow(&is_negative, i);
            let expected_result = *std::vector::borrow(&expected, i);
            
            let index = if (negative) {
                MateI32::neg_from(value)
            } else {
                MateI32::from(value)
            };
            let result = tick_bitmap::cast_to_u8(index);
            assert!(result == expected_result, i);
            i = i + 1;
        };
    }

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::tick_bitmap)]
    fun test_cast_to_u8_out_of_range_positive() {
        // Test value > 255 should fail
        let large_value = MateI32::from(256u32);
        tick_bitmap::cast_to_u8(large_value);
    }

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::tick_bitmap)]
    fun test_cast_to_u8_out_of_range_negative() {
        // Test value < -255 should fail
        let large_negative = MateI32::neg_from(256u32);
        tick_bitmap::cast_to_u8(large_negative);
    }

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::tick_bitmap)]
    fun test_cast_to_u8_large_positive() {
        // Test very large positive value
        let large_value = MateI32::from(1000u32);
        tick_bitmap::cast_to_u8(large_value);
    }

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::tick_bitmap)]
    fun test_cast_to_u8_large_negative() {
        // Test very large negative value
        let large_negative = MateI32::neg_from(1000u32);
        tick_bitmap::cast_to_u8(large_negative);
    }

    //===========================================================//
    //        next_initialized_tick_within_one_word Tests      //
    //===========================================================//

    #[test]
    fun test_next_initialized_tick_empty_bitmap() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Search in empty bitmap - should return false for initialized
        let search_tick = MateI32::from(100u32);
        let (_, initialized_a2b) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, search_tick, 1, true);
        let (_, initialized_b2a) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, search_tick, 1, false);
        
        assert!(initialized_a2b == false, 0);
        assert!(initialized_b2a == false, 1);
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_next_initialized_tick_different_spacings() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test with different tick spacings on empty bitmap
        let spacings = vector[1u32, 2u32, 5u32, 10u32, 60u32, 200u32];
        let i = 0;
        while (i < std::vector::length(&spacings)) {
            let spacing = *std::vector::borrow(&spacings, i);
            let tick = MateI32::from(spacing * 5); // Ensure divisible by spacing
            
            let (_, initialized) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, spacing, false);
            assert!(initialized == false, i); // Should be false for empty bitmap
            
            i = i + 1;
        };
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_next_initialized_tick_zero_tick() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test with tick at zero
        let zero_tick = MateI32::zero();
        let (_, initialized_a2b) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, zero_tick, 1, true);
        let (_, initialized_b2a) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, zero_tick, 1, false);
        
        assert!(initialized_a2b == false, 0);
        assert!(initialized_b2a == false, 1);
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_next_initialized_tick_negative_ticks() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test negative tick indices
        let negative_ticks = vector[1u32, 10u32, 50u32, 100u32, 255u32];
        let i = 0;
        while (i < std::vector::length(&negative_ticks)) {
            let tick_value = *std::vector::borrow(&negative_ticks, i);
            let negative_tick = MateI32::neg_from(tick_value);
            
            let (_, initialized_a2b) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, negative_tick, 1, true);
            let (_, initialized_b2a) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, negative_tick, 1, false);
            
            assert!(initialized_a2b == false, i);
            assert!(initialized_b2a == false, i + 100);
            
            i = i + 1;
        };
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_next_initialized_tick_word_boundaries() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test ticks at word boundaries (multiples of 256)
        let boundary_ticks = vector[255u32, 256u32, 512u32, 768u32];
        let i = 0;
        while (i < std::vector::length(&boundary_ticks)) {
            let tick_value = *std::vector::borrow(&boundary_ticks, i);
            let tick = MateI32::from(tick_value);
            
            let (_, initialized) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, 1, false);
            assert!(initialized == false, i); // Should be false for empty bitmap
            
            i = i + 1;
        };
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_next_initialized_tick_large_spacing() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test with large tick spacing
        let large_spacings = vector[100u32, 200u32, 500u32];
        let i = 0;
        while (i < std::vector::length(&large_spacings)) {
            let spacing = *std::vector::borrow(&large_spacings, i);
            let tick = MateI32::from(spacing * 2); // Ensure divisible by spacing
            
            let (_, initialized_a2b) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, spacing, true);
            let (_, initialized_b2a) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, spacing, false);
            
            assert!(initialized_a2b == false, i);
            assert!(initialized_b2a == false, i + 100);
            
            i = i + 1;
        };
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_next_initialized_tick_direction_consistency() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test that both directions return consistent results for empty bitmap
        let test_ticks = vector[0u32, 50u32, 100u32, 200u32, 255u32];
        let i = 0;
        while (i < std::vector::length(&test_ticks)) {
            let tick_value = *std::vector::borrow(&test_ticks, i);
            let tick = MateI32::from(tick_value);
            
            let (tick_a2b, initialized_a2b) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, 1, true);
            let (tick_b2a, initialized_b2a) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, 1, false);
            
            // For empty bitmap, both should return false
            assert!(initialized_a2b == false, i);
            assert!(initialized_b2a == false, i + 100);
            
            // The returned ticks should be different (one goes left, one goes right)
            assert!(!MateI32::eq(tick_a2b, tick_b2a), i + 200);
            
            i = i + 1;
        };
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_next_initialized_tick_extreme_values() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test with extreme but valid tick values
        let extreme_ticks = vector[
            MateI32::from(255u32),      // Max positive for single byte
            MateI32::neg_from(255u32),  // Max negative for single byte
            MateI32::zero()             // Zero
        ];
        
        let i = 0;
        while (i < std::vector::length(&extreme_ticks)) {
            let tick = *std::vector::borrow(&extreme_ticks, i);
            
            let (_, initialized_a2b) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, 1, true);
            let (_, initialized_b2a) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, 1, false);
            
            assert!(initialized_a2b == false, i);
            assert!(initialized_b2a == false, i + 100);
            
            i = i + 1;
        };
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_next_initialized_tick_mixed_positive_negative() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test with both positive and negative ticks
        let positive_ticks = vector[10u32, 50u32, 100u32];
        let negative_tick_values = vector[25u32, 75u32, 125u32];
        
        // Test positive ticks
        let i = 0;
        while (i < std::vector::length(&positive_ticks)) {
            let tick_value = *std::vector::borrow(&positive_ticks, i);
            let tick = MateI32::from(tick_value);
            
            let (_, initialized) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, 1, false);
            assert!(initialized == false, i);
            
            i = i + 1;
        };
        
        // Test negative ticks
        i = 0;
        while (i < std::vector::length(&negative_tick_values)) {
            let tick_value = *std::vector::borrow(&negative_tick_values, i);
            let tick = MateI32::neg_from(tick_value);
            
            let (_, initialized) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, tick, 1, false);
            assert!(initialized == false, i + 100);
            
            i = i + 1;
        };
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    //===========================================================//
    //                 Integration Tests                        //
    //===========================================================//

    #[test]
    fun test_cast_to_u8_comprehensive() {
        // Test comprehensive range of cast_to_u8 function
        
        // Test all values from 0 to 255
        let i = 0u32;
        while (i <= 255u32) {
            let positive_index = MateI32::from(i);
            let result_positive = tick_bitmap::cast_to_u8(positive_index);
            assert!(result_positive == (i as u8), (i as u64));
            
            if (i > 0) {
                let negative_index = MateI32::neg_from(i);
                let result_negative = tick_bitmap::cast_to_u8(negative_index);
                // For negative values, the result should be (256 - i) % 256
                let expected_negative = if (i == 256) { 0u8 } else { ((256u32 - i) as u8) };
                assert!(result_negative == expected_negative, (i as u64) + 1000);
            };
            
            i = i + 1;
        };
    }

    #[test]
    fun test_bitmap_operations_consistency() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test that multiple calls to next_initialized_tick_within_one_word
        // return consistent results for the same parameters
        let test_tick = MateI32::from(42u32);
        let spacing = 1u32;
        
        // Call the function multiple times with same parameters
        let (tick1_a2b, init1_a2b) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, test_tick, spacing, true);
        let (tick2_a2b, init2_a2b) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, test_tick, spacing, true);
        let (tick1_b2a, init1_b2a) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, test_tick, spacing, false);
        let (tick2_b2a, init2_b2a) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, test_tick, spacing, false);
        
        // Results should be identical
        assert!(init1_a2b == init2_a2b, 0);
        assert!(init1_b2a == init2_b2a, 1);
        assert!(MateI32::eq(tick1_a2b, tick2_a2b ), 2);
        assert!(MateI32::eq(tick1_b2a, tick2_b2a), 3);
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_tick_spacing_validation() {
        let scenario = test_scenario::begin(ADMIN);
        let bitmap = create_empty_bitmap(&mut scenario);
        
        // Test various tick spacings
        let spacings = vector[1u32, 2u32, 3u32, 5u32, 10u32, 60u32, 200u32];
        let base_tick = MateI32::from(1000u32);
        
        let i = 0;
        while (i < std::vector::length(&spacings)) {
            let spacing = *std::vector::borrow(&spacings, i);
            
            // All calls should succeed (not abort) for valid spacings
            let (_, _) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, base_tick, spacing, true);
            let (_, _) = tick_bitmap::next_initialized_tick_within_one_word(&bitmap, base_tick, spacing, false);
            
            i = i + 1;
        };
        
        table::destroy_empty(bitmap);
        test_scenario::end(scenario);
    }
}
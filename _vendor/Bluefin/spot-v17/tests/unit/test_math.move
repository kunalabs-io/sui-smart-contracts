/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_math {
    use bluefin_spot::tick_math;
    use bluefin_spot::bit_math;
    use integer_library::i32::{Self};
    use bluefin_spot::i32H;

    //===========================================================//
    //                 Constants and Helpers Tests              //
    //===========================================================//

    #[test]
    fun test_max_sqrt_price() {
        // Test that max_sqrt_price returns the correct constant
        assert!(tick_math::max_sqrt_price() == 79226673515401279992447579055u128, 0);
    }

    #[test]
    fun test_min_sqrt_price() {
        // Test that min_sqrt_price returns the correct constant
        assert!(tick_math::min_sqrt_price() == 4295048016u128, 0);
    }

    #[test]
    fun test_max_tick() {
        // Test that max_tick returns the correct value
        let max_tick = tick_math::max_tick();
        let expected = i32H::lib_to_mate(i32::from(443636u32));
        assert!(i32H::eq(max_tick, expected), 0);
    }

    #[test]
    fun test_min_tick() {
        // Test that min_tick returns the correct value
        let min_tick = tick_math::min_tick();
        let expected = i32H::lib_to_mate(i32::neg_from(443636u32));
        assert!(i32H::eq(min_tick, expected), 0);
    }

    #[test]
    fun test_tick_bound() {
        // Test that tick_bound returns the correct constant
        assert!(tick_math::tick_bound() == 443636u32, 0);
    }

    //===========================================================//
    //                 is_valid_index Function Tests            //
    //===========================================================//

    #[test]
    fun test_is_valid_index_valid_cases() {
        // Test valid indices with different tick spacings
        
        // Test with tick spacing 1 (any tick in range should be valid)
        let tick_0 = i32H::lib_to_mate(i32::from(0u32));
        assert!(tick_math::is_valid_index(tick_0, 1), 0);
        
        let tick_100 = i32H::lib_to_mate(i32::from(100u32));
        assert!(tick_math::is_valid_index(tick_100, 1), 1);
        
        let tick_neg_100 = i32H::lib_to_mate(i32::neg_from(100u32));
        assert!(tick_math::is_valid_index(tick_neg_100, 1), 2);
        
        // Test with tick spacing 10
        let tick_10 = i32H::lib_to_mate(i32::from(10u32));
        assert!(tick_math::is_valid_index(tick_10, 10), 3);
        
        let tick_100_spacing_10 = i32H::lib_to_mate(i32::from(100u32));
        assert!(tick_math::is_valid_index(tick_100_spacing_10, 10), 4);
        
        let tick_neg_50 = i32H::lib_to_mate(i32::neg_from(50u32));
        assert!(tick_math::is_valid_index(tick_neg_50, 10), 5);
        
        // Test with tick spacing 60
        let tick_120 = i32H::lib_to_mate(i32::from(120u32));
        assert!(tick_math::is_valid_index(tick_120, 60), 6);
        
        let tick_neg_180 = i32H::lib_to_mate(i32::neg_from(180u32));
        assert!(tick_math::is_valid_index(tick_neg_180, 60), 7);
    }

    #[test]
    fun test_is_valid_index_invalid_spacing() {
        // Test indices that don't align with tick spacing
        
        // Test with tick spacing 10, but tick is not divisible by 10
        let tick_15 = i32H::lib_to_mate(i32::from(15u32));
        assert!(!tick_math::is_valid_index(tick_15, 10), 0);
        
        let tick_neg_7 = i32H::lib_to_mate(i32::neg_from(7u32));
        assert!(!tick_math::is_valid_index(tick_neg_7, 10), 1);
        
        // Test with tick spacing 60, but tick is not divisible by 60
        let tick_30 = i32H::lib_to_mate(i32::from(30u32));
        assert!(!tick_math::is_valid_index(tick_30, 60), 2);
        
        let tick_61 = i32H::lib_to_mate(i32::from(61u32));
        assert!(!tick_math::is_valid_index(tick_61, 60), 3);
    }

    #[test]
    fun test_is_valid_index_boundary_cases() {
        // Test boundary cases at min and max ticks
        let max_tick = tick_math::max_tick();
        let min_tick = tick_math::min_tick();
        
        // Max and min ticks should be valid with spacing 1
        assert!(tick_math::is_valid_index(max_tick, 1), 0);
        assert!(tick_math::is_valid_index(min_tick, 1), 1);
        
        // Test with larger spacing - depends on whether max/min tick is divisible
        // Since 443636 % 10 = 6, max_tick should not be valid with spacing 10
        assert!(!tick_math::is_valid_index(max_tick, 10), 2);
        assert!(!tick_math::is_valid_index(min_tick, 10), 3);
    }

    #[test]
    fun test_is_valid_index_out_of_range() {
        // Test indices that are out of the valid tick range
        let max_tick = tick_math::max_tick();
        let min_tick = tick_math::min_tick();
        
        // Create ticks beyond the boundaries
        let beyond_max = i32H::lib_to_mate(i32::add(i32H::mate_to_lib(max_tick), i32::from(1)));
        let beyond_min = i32H::lib_to_mate(i32::sub(i32H::mate_to_lib(min_tick), i32::from(1)));
        
        assert!(!tick_math::is_valid_index(beyond_max, 1), 0);
        assert!(!tick_math::is_valid_index(beyond_min, 1), 1);
    }

    //===========================================================//
    //              get_sqrt_price_at_tick Extended Tests       //
    //===========================================================//

    #[test]
    fun test_get_sqrt_price_at_tick_zero() {
        // Test sqrt price at tick 0 (should be around 1.0001^0 = 1 in Q64.64 format)
        let tick_0 = i32H::lib_to_mate(i32::from(0u32));
        let sqrt_price = tick_math::get_sqrt_price_at_tick(tick_0);
        
        // At tick 0, sqrt_price should be close to 2^64 (Q64.64 representation of 1)
        // The exact value is 18446744073709551616 (2^64)
        assert!(sqrt_price == 18446744073709551616u128, 0);
    }

    #[test]
    fun test_get_sqrt_price_at_tick_small_positive() {
        // Test small positive ticks
        let tick_1 = i32H::lib_to_mate(i32::from(1u32));
        let sqrt_price_1 = tick_math::get_sqrt_price_at_tick(tick_1);
        
        let tick_10 = i32H::lib_to_mate(i32::from(10u32));
        let sqrt_price_10 = tick_math::get_sqrt_price_at_tick(tick_10);
        
        let tick_100 = i32H::lib_to_mate(i32::from(100u32));
        let sqrt_price_100 = tick_math::get_sqrt_price_at_tick(tick_100);
        
        // Prices should increase with tick
        assert!(sqrt_price_1 > 18446744073709551616u128, 0); // > 2^64
        assert!(sqrt_price_10 > sqrt_price_1, 1);
        assert!(sqrt_price_100 > sqrt_price_10, 2);
    }

    #[test]
    fun test_get_sqrt_price_at_tick_small_negative() {
        // Test small negative ticks
        let tick_neg_1 = i32H::lib_to_mate(i32::neg_from(1u32));
        let sqrt_price_neg_1 = tick_math::get_sqrt_price_at_tick(tick_neg_1);
        
        let tick_neg_10 = i32H::lib_to_mate(i32::neg_from(10u32));
        let sqrt_price_neg_10 = tick_math::get_sqrt_price_at_tick(tick_neg_10);
        
        let tick_neg_100 = i32H::lib_to_mate(i32::neg_from(100u32));
        let sqrt_price_neg_100 = tick_math::get_sqrt_price_at_tick(tick_neg_100);
        
        // Prices should decrease with more negative tick
        assert!(sqrt_price_neg_1 < 18446744073709551616u128, 0); // < 2^64
        assert!(sqrt_price_neg_10 < sqrt_price_neg_1, 1);
        assert!(sqrt_price_neg_100 < sqrt_price_neg_10, 2);
    }

    #[test]
    fun test_get_sqrt_price_at_tick_symmetry() {
        // Test that positive and negative ticks have reciprocal relationship
        let test_ticks = vector[1u32, 10u32, 100u32, 1000u32];
        
        let i = 0;
        while (i < std::vector::length(&test_ticks)) {
            let tick_val = *std::vector::borrow(&test_ticks, i);
            let pos_tick = i32H::lib_to_mate(i32::from(tick_val));
            let neg_tick = i32H::lib_to_mate(i32::neg_from(tick_val));
            
            let pos_price = tick_math::get_sqrt_price_at_tick(pos_tick);
            let neg_price = tick_math::get_sqrt_price_at_tick(neg_tick);
            
            // For small ticks, pos_price * neg_price should be close to 2^128
            // This tests the reciprocal relationship
            let product = (pos_price as u256) * (neg_price as u256);
            let expected = (1u256 << 128); // 2^128
            
            // Allow for some precision loss in the calculation
            let diff = if (product > expected) {
                product - expected
            } else {
                expected - product
            };
            
            // The difference should be relatively small (less than 1% of expected)
            assert!(diff < expected / 100, i);
            
            i = i + 1;
        };
    }

    #[test]
    fun test_get_sqrt_price_at_tick_large_values() {
        // Test with larger tick values
        let large_ticks = vector[10000u32, 50000u32, 100000u32, 200000u32, 400000u32];
        
        let i = 0;
        while (i < std::vector::length(&large_ticks)) {
            let tick_val = *std::vector::borrow(&large_ticks, i);
            let pos_tick = i32H::lib_to_mate(i32::from(tick_val));
            let neg_tick = i32H::lib_to_mate(i32::neg_from(tick_val));
            
            let pos_price = tick_math::get_sqrt_price_at_tick(pos_tick);
            let neg_price = tick_math::get_sqrt_price_at_tick(neg_tick);
            
            // Prices should be within valid range
            assert!(pos_price >= tick_math::min_sqrt_price(), i);
            assert!(pos_price <= tick_math::max_sqrt_price(), i);
            assert!(neg_price >= tick_math::min_sqrt_price(), i);
            assert!(neg_price <= tick_math::max_sqrt_price(), i);
            
            // Positive tick should give higher price than negative
            assert!(pos_price > neg_price, i);
            
            i = i + 1;
        };
    }

    //===========================================================//
    //              get_tick_at_sqrt_price Extended Tests       //
    //===========================================================//

    #[test]
    fun test_get_tick_at_sqrt_price_round_trip() {
        // Test round trip: tick -> sqrt_price -> tick
        let test_ticks = vector[
            0u32, 1u32, 10u32, 100u32, 1000u32, 10000u32, 50000u32, 100000u32
        ];
        
        let i = 0;
        while (i < std::vector::length(&test_ticks)) {
            let tick_val = *std::vector::borrow(&test_ticks, i);
            
            // Test positive tick
            let original_tick = i32H::lib_to_mate(i32::from(tick_val));
            let sqrt_price = tick_math::get_sqrt_price_at_tick(original_tick);
            let recovered_tick = tick_math::get_tick_at_sqrt_price(sqrt_price);
            
            // The recovered tick should be equal to or very close to the original
            let original_val = i32::as_u32(i32H::mate_to_lib(original_tick));
            let recovered_val = i32::as_u32(i32H::mate_to_lib(recovered_tick));
            
            // Allow for small rounding differences
            let diff = if (original_val > recovered_val) {
                original_val - recovered_val
            } else {
                recovered_val - original_val
            };
            assert!(diff <= 1, i); // Should be exact or off by 1
            
            // Test negative tick (skip 0 as it's already tested)
            if (tick_val > 0) {
                let neg_original_tick = i32H::lib_to_mate(i32::neg_from(tick_val));
                let neg_sqrt_price = tick_math::get_sqrt_price_at_tick(neg_original_tick);
                let neg_recovered_tick = tick_math::get_tick_at_sqrt_price(neg_sqrt_price);
                
                let neg_original_lib = i32H::mate_to_lib(neg_original_tick);
                let neg_recovered_lib = i32H::mate_to_lib(neg_recovered_tick);
                
                let neg_diff = if (i32::gt(neg_original_lib, neg_recovered_lib)) {
                    i32::as_u32(i32::sub(neg_original_lib, neg_recovered_lib))
                } else {
                    i32::as_u32(i32::sub(neg_recovered_lib, neg_original_lib))
                };
                assert!(neg_diff <= 1, i + 100); // Should be exact or off by 1
            };
            
            i = i + 1;
        };
    }

    #[test]
    fun test_get_tick_at_sqrt_price_boundary_values() {
        // Test with boundary sqrt prices
        let min_sqrt_price = tick_math::min_sqrt_price();
        let max_sqrt_price = tick_math::max_sqrt_price();
        
        let tick_at_min = tick_math::get_tick_at_sqrt_price(min_sqrt_price);
        let tick_at_max = tick_math::get_tick_at_sqrt_price(max_sqrt_price);
        
        // These should be close to the min and max ticks
        let min_tick_lib = i32H::mate_to_lib(tick_math::min_tick());
        let max_tick_lib = i32H::mate_to_lib(tick_math::max_tick());
        
        let recovered_min_lib = i32H::mate_to_lib(tick_at_min);
        let recovered_max_lib = i32H::mate_to_lib(tick_at_max);
        
        // Should be very close to the boundary ticks
        let min_diff = if (i32::gt(min_tick_lib, recovered_min_lib)) {
            i32::as_u32(i32::sub(min_tick_lib, recovered_min_lib))
        } else {
            i32::as_u32(i32::sub(recovered_min_lib, min_tick_lib))
        };
        let max_diff = if (i32::gt(max_tick_lib, recovered_max_lib)) {
            i32::as_u32(i32::sub(max_tick_lib, recovered_max_lib))
        } else {
            i32::as_u32(i32::sub(recovered_max_lib, max_tick_lib))
        };
        
        assert!(min_diff <= 1, 0);
        assert!(max_diff <= 1, 1);
    }

    #[test]
    fun test_get_tick_at_sqrt_price_monotonic() {
        // Test that the function is monotonic (increasing sqrt_price gives increasing tick)
        let sqrt_prices = vector[
            tick_math::min_sqrt_price(),
            tick_math::min_sqrt_price() * 2,
            tick_math::min_sqrt_price() * 10,
            18446744073709551616u128, // Around tick 0
            tick_math::max_sqrt_price() / 10,
            tick_math::max_sqrt_price() / 2,
            tick_math::max_sqrt_price()
        ];
        
        let i = 0;
        while (i < std::vector::length(&sqrt_prices) - 1) {
            let price1 = *std::vector::borrow(&sqrt_prices, i);
            let price2 = *std::vector::borrow(&sqrt_prices, i + 1);
            
            let tick1 = tick_math::get_tick_at_sqrt_price(price1);
            let tick2 = tick_math::get_tick_at_sqrt_price(price2);
            
            // tick2 should be greater than or equal to tick1
            assert!(i32H::gte(tick2, tick1), i);
            
            i = i + 1;
        };
    }

    #[test]
    fun test_get_tick_at_sqrt_price_specific_values() {
        // Test with specific known values for precision
        
        // Test 2^64 should give tick ~0
        let sqrt_price_1 = 18446744073709551616u128;
        let expected_tick_1 = 0u32;
        let actual_tick_1 = tick_math::get_tick_at_sqrt_price(sqrt_price_1);
        let actual_tick_val_1 = i32::as_u32(i32::abs(i32H::mate_to_lib(actual_tick_1)));
        let diff_1 = if (expected_tick_1 > actual_tick_val_1) {
            expected_tick_1 - actual_tick_val_1
        } else {
            actual_tick_val_1 - expected_tick_1
        };
        assert!(diff_1 <= 1, 0);
        
        // Test min price should give min tick
        let sqrt_price_2 = tick_math::min_sqrt_price();
        let expected_tick_2 = 443636u32;
        let actual_tick_2 = tick_math::get_tick_at_sqrt_price(sqrt_price_2);
        let actual_tick_val_2 = i32::as_u32(i32::abs(i32H::mate_to_lib(actual_tick_2)));
        let diff_2 = if (expected_tick_2 > actual_tick_val_2) {
            expected_tick_2 - actual_tick_val_2
        } else {
            actual_tick_val_2 - expected_tick_2
        };
        assert!(diff_2 <= 1, 1);
        
        // Test max price should give max tick
        let sqrt_price_3 = tick_math::max_sqrt_price();
        let expected_tick_3 = 443636u32;
        let actual_tick_3 = tick_math::get_tick_at_sqrt_price(sqrt_price_3);
        let actual_tick_val_3 = i32::as_u32(i32::abs(i32H::mate_to_lib(actual_tick_3)));
        let diff_3 = if (expected_tick_3 > actual_tick_val_3) {
            expected_tick_3 - actual_tick_val_3
        } else {
            actual_tick_val_3 - expected_tick_3
        };
        assert!(diff_3 <= 1, 2);
    }

    //===========================================================//
    //                    Error Condition Tests                 //
    //===========================================================//

    #[test]
    #[expected_failure(abort_code = 1, location = bluefin_spot::tick_math)]
    fun test_get_sqrt_price_at_tick_above_max() {
        let above_max = i32H::lib_to_mate(i32::add(i32H::mate_to_lib(tick_math::max_tick()), i32::from(1)));
        tick_math::get_sqrt_price_at_tick(above_max);
    }

    #[test]
    #[expected_failure(abort_code = 1, location = bluefin_spot::tick_math)]
    fun test_get_sqrt_price_at_tick_below_min() {
        let below_min = i32H::lib_to_mate(i32::sub(i32H::mate_to_lib(tick_math::min_tick()), i32::from(1)));
        tick_math::get_sqrt_price_at_tick(below_min);
    }

    #[test]
    #[expected_failure(abort_code = 2, location = bluefin_spot::tick_math)]
    fun test_get_tick_at_sqrt_price_above_max() {
        tick_math::get_tick_at_sqrt_price(tick_math::max_sqrt_price() + 1);
    }

    #[test]
    #[expected_failure(abort_code = 2, location = bluefin_spot::tick_math)]
    fun test_get_tick_at_sqrt_price_below_min() {
        tick_math::get_tick_at_sqrt_price(tick_math::min_sqrt_price() - 1);
    }

    #[test]
    #[expected_failure(abort_code = 2, location = bluefin_spot::tick_math)]
    fun test_get_tick_at_sqrt_price_zero() {
        tick_math::get_tick_at_sqrt_price(0);
    }

    //===========================================================//
    //                    Edge Case Tests                       //
    //===========================================================//

    #[test]
    fun test_tick_spacing_edge_cases() {
        // Test edge cases for tick spacing validation
        
        // Test with tick spacing 1 (should accept all valid ticks)
        let test_ticks = vector[0u32, 1u32, 2u32, 3u32, 443635u32];
        let i = 0;
        while (i < std::vector::length(&test_ticks)) {
            let tick_val = *std::vector::borrow(&test_ticks, i);
            let tick = i32H::lib_to_mate(i32::from(tick_val));
            assert!(tick_math::is_valid_index(tick, 1), i);
            i = i + 1;
        };
        
        // Test with large tick spacing
        let large_spacing = 1000u32;
        let tick_1000 = i32H::lib_to_mate(i32::from(1000u32));
        let tick_2000 = i32H::lib_to_mate(i32::from(2000u32));
        let tick_999 = i32H::lib_to_mate(i32::from(999u32));
        
        assert!(tick_math::is_valid_index(tick_1000, large_spacing), 0);
        assert!(tick_math::is_valid_index(tick_2000, large_spacing), 1);
        assert!(!tick_math::is_valid_index(tick_999, large_spacing), 2);
    }

    #[test]
    fun test_precision_at_different_ranges() {
        // Test precision of calculations at different tick ranges
        let starts = vector[0u32, 1000u32, 10000u32, 100000u32, 400000u32];
        let ends = vector[100u32, 1100u32, 10100u32, 100100u32, 400100u32];
        
        let i = 0;
        while (i < std::vector::length(&starts)) {
            let start = *std::vector::borrow(&starts, i);
            let end = *std::vector::borrow(&ends, i);
            
            let tick1 = i32H::lib_to_mate(i32::from(start));
            let tick2 = i32H::lib_to_mate(i32::from(end));
            
            let price1 = tick_math::get_sqrt_price_at_tick(tick1);
            let price2 = tick_math::get_sqrt_price_at_tick(tick2);
            
            // Price should increase with tick
            assert!(price2 > price1, i);
            
            // Test round trip precision
            let recovered_tick1 = tick_math::get_tick_at_sqrt_price(price1);
            let recovered_tick2 = tick_math::get_tick_at_sqrt_price(price2);
            
            // Should recover original ticks with small tolerance
            let orig1 = i32::as_u32(i32H::mate_to_lib(tick1));
            let orig2 = i32::as_u32(i32H::mate_to_lib(tick2));
            let rec1 = i32::as_u32(i32H::mate_to_lib(recovered_tick1));
            let rec2 = i32::as_u32(i32H::mate_to_lib(recovered_tick2));
            
            let diff1 = if (orig1 > rec1) { orig1 - rec1 } else { rec1 - orig1 };
            let diff2 = if (orig2 > rec2) { orig2 - rec2 } else { rec2 - orig2 };
            
            assert!(diff1 <= 1, i + 100);
            assert!(diff2 <= 1, i + 200);
            
            i = i + 1;
        };
    }

    #[test]
    fun test_negative_tick_ranges() {
        // Test negative tick ranges specifically
        let start_abs_values = vector[100u32, 1100u32, 10100u32, 100100u32, 400100u32];
        let end_abs_values = vector[0u32, 1000u32, 10000u32, 100000u32, 400000u32];
        
        let i = 0;
        while (i < std::vector::length(&start_abs_values)) {
            let start_abs = *std::vector::borrow(&start_abs_values, i);
            let end_abs = *std::vector::borrow(&end_abs_values, i);
            
            let tick1 = i32H::lib_to_mate(i32::neg_from(start_abs));
            let tick2 = if (end_abs == 0) {
                i32H::lib_to_mate(i32::from(0u32))
            } else {
                i32H::lib_to_mate(i32::neg_from(end_abs))
            };
            
            let price1 = tick_math::get_sqrt_price_at_tick(tick1);
            let price2 = tick_math::get_sqrt_price_at_tick(tick2);
            
            // Price should increase as we go from more negative to less negative
            assert!(price2 > price1, i);
            
            // Test that prices are in valid range
            assert!(price1 >= tick_math::min_sqrt_price(), i + 100);
            assert!(price1 <= tick_math::max_sqrt_price(), i + 200);
            assert!(price2 >= tick_math::min_sqrt_price(), i + 300);
            assert!(price2 <= tick_math::max_sqrt_price(), i + 400);
            
            i = i + 1;
        };
    }

    #[test]
    fun test_bit_manipulation_coverage() {
        // Test specific tick values that exercise different bit patterns
        // This helps ensure all bit manipulation paths are covered
        
        let bit_test_ticks = vector[
            1u32,      // 0x1
            2u32,      // 0x2
            4u32,      // 0x4
            8u32,      // 0x8
            16u32,     // 0x10
            32u32,     // 0x20
            64u32,     // 0x40
            128u32,    // 0x80
            256u32,    // 0x100
            512u32,    // 0x200
            1024u32,   // 0x400
            2048u32,   // 0x800
            4096u32,   // 0x1000
            8192u32,   // 0x2000
            16384u32,  // 0x4000
            32768u32,  // 0x8000
            65536u32,  // 0x10000
            131072u32, // 0x20000
            262144u32  // 0x40000
        ];
        
        let i = 0;
        while (i < std::vector::length(&bit_test_ticks)) {
            let tick_val = *std::vector::borrow(&bit_test_ticks, i);
            
            // Test positive tick
            let pos_tick = i32H::lib_to_mate(i32::from(tick_val));
            let pos_price = tick_math::get_sqrt_price_at_tick(pos_tick);
            assert!(pos_price > 18446744073709551616u128, i); // Should be > 2^64
            
            // Test negative tick
            let neg_tick = i32H::lib_to_mate(i32::neg_from(tick_val));
            let neg_price = tick_math::get_sqrt_price_at_tick(neg_tick);
            assert!(neg_price < 18446744073709551616u128, i + 100); // Should be < 2^64
            
            // Test round trip
            let recovered_pos = tick_math::get_tick_at_sqrt_price(pos_price);
            let recovered_neg = tick_math::get_tick_at_sqrt_price(neg_price);
            
            // Should be close to original
            let orig_pos = i32::as_u32(i32H::mate_to_lib(pos_tick));
            let orig_neg_lib = i32H::mate_to_lib(neg_tick);
            let rec_pos = i32::as_u32(i32H::mate_to_lib(recovered_pos));
            let rec_neg_lib = i32H::mate_to_lib(recovered_neg);
            
            let diff_pos = if (orig_pos > rec_pos) { orig_pos - rec_pos } else { rec_pos - orig_pos };
            let diff_neg = if (i32::gt(orig_neg_lib, rec_neg_lib)) {
                i32::as_u32(i32::sub(orig_neg_lib, rec_neg_lib))
            } else {
                i32::as_u32(i32::sub(rec_neg_lib, orig_neg_lib))
            };
            
            assert!(diff_pos <= 1, i + 200);
            assert!(diff_neg <= 1, i + 300);
            
            i = i + 1;
        };
    }

    //===========================================================//
    //                 bit_math Module Tests                    //
    //===========================================================//

    #[test]
    fun test_least_significant_bit_single_bits() {
        // Test single bit positions
        let i = 0u8;
        while (i < 255u8) {
            let mask = 1u256 << (i as u8);
            let result = bit_math::least_significant_bit(mask);
            assert!(result == i, (i as u64));
            i = i + 1;
        };
        // Test the last bit (255) separately
        let mask = 1u256 << 255u8;
        let result = bit_math::least_significant_bit(mask);
        assert!(result == 255u8, 255);
    }

    #[test]
    fun test_most_significant_bit_single_bits() {
        // Test single bit positions
        let i = 0u8;
        while (i < 255u8) {
            let mask = 1u256 << (i as u8);
            let result = bit_math::most_significant_bit(mask);
            assert!(result == i, (i as u64));
            i = i + 1;
        };
        // Test the last bit (255) separately
        let mask = 1u256 << 255u8;
        let result = bit_math::most_significant_bit(mask);
        assert!(result == 255u8, 255);
    }

    #[test]
    fun test_least_significant_bit_multiple_bits() {
        // Test with multiple bits set - should return the lowest bit position
        
        // Test 0b11 (bits 0 and 1 set) - should return 0
        let mask1 = 3u256; // 0b11
        assert!(bit_math::least_significant_bit(mask1) == 0, 0);
        
        // Test 0b110 (bits 1 and 2 set) - should return 1
        let mask2 = 6u256; // 0b110
        assert!(bit_math::least_significant_bit(mask2) == 1, 1);
        
        // Test 0b1100 (bits 2 and 3 set) - should return 2
        let mask3 = 12u256; // 0b1100
        assert!(bit_math::least_significant_bit(mask3) == 2, 2);
        
        // Test 0b11110000 (bits 4-7 set) - should return 4
        let mask4 = 240u256; // 0b11110000
        assert!(bit_math::least_significant_bit(mask4) == 4, 3);
        
        // Test with high and low bits set
        let mask5 = (1u256 << 255) | 1u256; // Highest and lowest bits
        assert!(bit_math::least_significant_bit(mask5) == 0, 4);
        
        let mask6 = (1u256 << 200) | (1u256 << 100) | (1u256 << 50);
        assert!(bit_math::least_significant_bit(mask6) == 50, 5);
    }

    #[test]
    fun test_most_significant_bit_multiple_bits() {
        // Test with multiple bits set - should return the highest bit position
        
        // Test 0b11 (bits 0 and 1 set) - should return 1
        let mask1 = 3u256; // 0b11
        assert!(bit_math::most_significant_bit(mask1) == 1, 0);
        
        // Test 0b110 (bits 1 and 2 set) - should return 2
        let mask2 = 6u256; // 0b110
        assert!(bit_math::most_significant_bit(mask2) == 2, 1);
        
        // Test 0b1100 (bits 2 and 3 set) - should return 3
        let mask3 = 12u256; // 0b1100
        assert!(bit_math::most_significant_bit(mask3) == 3, 2);
        
        // Test 0b11110000 (bits 4-7 set) - should return 7
        let mask4 = 240u256; // 0b11110000
        assert!(bit_math::most_significant_bit(mask4) == 7, 3);
        
        // Test with high and low bits set
        let mask5 = (1u256 << 255) | 1u256; // Highest and lowest bits
        assert!(bit_math::most_significant_bit(mask5) == 255, 4);
        
        let mask6 = (1u256 << 200) | (1u256 << 100) | (1u256 << 50);
        assert!(bit_math::most_significant_bit(mask6) == 200, 5);
    }

    #[test]
    fun test_least_significant_bit_boundary_values() {
        // Test boundary values for different bit ranges
        
        // Test max u8 (255 = 0xFF)
        let max_u8 = 255u256;
        assert!(bit_math::least_significant_bit(max_u8) == 0, 0);
        
        // Test max u16 (65535 = 0xFFFF)
        let max_u16 = 65535u256;
        assert!(bit_math::least_significant_bit(max_u16) == 0, 1);
        
        // Test max u32 (4294967295 = 0xFFFFFFFF)
        let max_u32 = 4294967295u256;
        assert!(bit_math::least_significant_bit(max_u32) == 0, 2);
        
        // Test max u64 (18446744073709551615 = 0xFFFFFFFFFFFFFFFF)
        let max_u64 = 18446744073709551615u256;
        assert!(bit_math::least_significant_bit(max_u64) == 0, 3);
        
        // Test max u128
        let max_u128 = 340282366920938463463374607431768211455u256;
        assert!(bit_math::least_significant_bit(max_u128) == 0, 4);
        
        // Test max u256
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        assert!(bit_math::least_significant_bit(max_u256) == 0, 5);
    }

    #[test]
    fun test_most_significant_bit_boundary_values() {
        // Test boundary values for different bit ranges
        
        // Test max u8 (255 = 0xFF)
        let max_u8 = 255u256;
        assert!(bit_math::most_significant_bit(max_u8) == 7, 0);
        
        // Test max u16 (65535 = 0xFFFF)
        let max_u16 = 65535u256;
        assert!(bit_math::most_significant_bit(max_u16) == 15, 1);
        
        // Test max u32 (4294967295 = 0xFFFFFFFF)
        let max_u32 = 4294967295u256;
        assert!(bit_math::most_significant_bit(max_u32) == 31, 2);
        
        // Test max u64 (18446744073709551615 = 0xFFFFFFFFFFFFFFFF)
        let max_u64 = 18446744073709551615u256;
        assert!(bit_math::most_significant_bit(max_u64) == 63, 3);
        
        // Test max u128
        let max_u128 = 340282366920938463463374607431768211455u256;
        assert!(bit_math::most_significant_bit(max_u128) == 127, 4);
        
        // Test max u256
        let max_u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        assert!(bit_math::most_significant_bit(max_u256) == 255, 5);
    }

    #[test]
    fun test_least_significant_bit_powers_of_two() {
        // Test powers of 2 - LSB should equal the exponent
        let powers = vector[
            1u256,      // 2^0
            2u256,      // 2^1
            4u256,      // 2^2
            8u256,      // 2^3
            16u256,     // 2^4
            32u256,     // 2^5
            64u256,     // 2^6
            128u256,    // 2^7
            256u256,    // 2^8
            512u256,    // 2^9
            1024u256    // 2^10
        ];
        
        let i = 0;
        while (i < std::vector::length(&powers)) {
            let power = *std::vector::borrow(&powers, i);
            let result = bit_math::least_significant_bit(power);
            assert!(result == (i as u8), i);
            i = i + 1;
        };
    }

    #[test]
    fun test_most_significant_bit_powers_of_two() {
        // Test powers of 2 - MSB should equal the exponent
        let powers = vector[
            1u256,      // 2^0
            2u256,      // 2^1
            4u256,      // 2^2
            8u256,      // 2^3
            16u256,     // 2^4
            32u256,     // 2^5
            64u256,     // 2^6
            128u256,    // 2^7
            256u256,    // 2^8
            512u256,    // 2^9
            1024u256    // 2^10
        ];
        
        let i = 0;
        while (i < std::vector::length(&powers)) {
            let power = *std::vector::borrow(&powers, i);
            let result = bit_math::most_significant_bit(power);
            assert!(result == (i as u8), i);
            i = i + 1;
        };
    }

    #[test]
    fun test_least_significant_bit_powers_of_two_minus_one() {
        // Test (2^n - 1) patterns - LSB should always be 0
        let values = vector[
            1u256,      // 2^1 - 1 = 1
            3u256,      // 2^2 - 1 = 3
            7u256,      // 2^3 - 1 = 7
            15u256,     // 2^4 - 1 = 15
            31u256,     // 2^5 - 1 = 31
            63u256,     // 2^6 - 1 = 63
            127u256,    // 2^7 - 1 = 127
            255u256,    // 2^8 - 1 = 255
            511u256,    // 2^9 - 1 = 511
            1023u256    // 2^10 - 1 = 1023
        ];
        
        let i = 0;
        while (i < std::vector::length(&values)) {
            let value = *std::vector::borrow(&values, i);
            let result = bit_math::least_significant_bit(value);
            assert!(result == 0, i); // All should have LSB at position 0
            i = i + 1;
        };
    }

    #[test]
    fun test_most_significant_bit_powers_of_two_minus_one() {
        // Test (2^n - 1) patterns - MSB should be n-1
        let values = vector[
            1u256,      // 2^1 - 1 = 1, MSB = 0
            3u256,      // 2^2 - 1 = 3, MSB = 1
            7u256,      // 2^3 - 1 = 7, MSB = 2
            15u256,     // 2^4 - 1 = 15, MSB = 3
            31u256,     // 2^5 - 1 = 31, MSB = 4
            63u256,     // 2^6 - 1 = 63, MSB = 5
            127u256,    // 2^7 - 1 = 127, MSB = 6
            255u256,    // 2^8 - 1 = 255, MSB = 7
            511u256,    // 2^9 - 1 = 511, MSB = 8
            1023u256    // 2^10 - 1 = 1023, MSB = 9
        ];
        
        let expected_msb = vector[0u8, 1u8, 2u8, 3u8, 4u8, 5u8, 6u8, 7u8, 8u8, 9u8];
        
        let i = 0;
        while (i < std::vector::length(&values)) {
            let value = *std::vector::borrow(&values, i);
            let expected = *std::vector::borrow(&expected_msb, i);
            let result = bit_math::most_significant_bit(value);
            assert!(result == expected, i);
            i = i + 1;
        };
    }

    #[test]
    fun test_bit_math_alternating_patterns() {
        // Test alternating bit patterns
        
        // Test 0x55555555... (alternating 01010101...)
        let alt1 = 0x5555555555555555555555555555555555555555555555555555555555555555;
        assert!(bit_math::least_significant_bit(alt1) == 0, 0);
        assert!(bit_math::most_significant_bit(alt1) == 254, 1);
        
        // Test 0xAAAAAAAA... (alternating 10101010...)
        let alt2 = 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
        assert!(bit_math::least_significant_bit(alt2) == 1, 2);
        assert!(bit_math::most_significant_bit(alt2) == 255, 3);
        
        // Test 0x33333333... (alternating 00110011...)
        let alt3 = 0x3333333333333333333333333333333333333333333333333333333333333333;
        assert!(bit_math::least_significant_bit(alt3) == 0, 4);
        assert!(bit_math::most_significant_bit(alt3) == 253, 5);
        
        // Test 0xCCCCCCCC... (alternating 11001100...)
        let alt4 = 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc;
        assert!(bit_math::least_significant_bit(alt4) == 2, 6);
        assert!(bit_math::most_significant_bit(alt4) == 255, 7);
    }

    #[test]
    fun test_bit_math_sparse_patterns() {
        // Test sparse bit patterns with bits far apart
        
        // Test bits at positions 0, 64, 128, 192
        let sparse1 = 1u256 | (1u256 << 64) | (1u256 << 128) | (1u256 << 192);
        assert!(bit_math::least_significant_bit(sparse1) == 0, 0);
        assert!(bit_math::most_significant_bit(sparse1) == 192, 1);
        
        // Test bits at positions 1, 65, 129, 193
        let sparse2 = (1u256 << 1) | (1u256 << 65) | (1u256 << 129) | (1u256 << 193);
        assert!(bit_math::least_significant_bit(sparse2) == 1, 2);
        assert!(bit_math::most_significant_bit(sparse2) == 193, 3);
        
        // Test bits at positions 7, 15, 31, 63, 127, 255
        let sparse3 = (1u256 << 7) | (1u256 << 15) | (1u256 << 31) | (1u256 << 63) | (1u256 << 127) | (1u256 << 255);
        assert!(bit_math::least_significant_bit(sparse3) == 7, 4);
        assert!(bit_math::most_significant_bit(sparse3) == 255, 5);
    }

    #[test]
    fun test_bit_math_consecutive_bit_ranges() {
        // Test consecutive bit ranges
        
        // Test bits 0-7 (0xFF)
        let range1 = 255u256;
        assert!(bit_math::least_significant_bit(range1) == 0, 0);
        assert!(bit_math::most_significant_bit(range1) == 7, 1);
        
        // Test bits 8-15 (0xFF00)
        let range2 = 65280u256; // 0xFF << 8
        assert!(bit_math::least_significant_bit(range2) == 8, 2);
        assert!(bit_math::most_significant_bit(range2) == 15, 3);
        
        // Test bits 16-31 (0xFFFF0000)
        let range3 = 4294901760u256; // 0xFFFF << 16
        assert!(bit_math::least_significant_bit(range3) == 16, 4);
        assert!(bit_math::most_significant_bit(range3) == 31, 5);
        
        // Test bits 32-63 (0xFFFFFFFF00000000)
        let range4 = 18446744069414584320u256; // 0xFFFFFFFF << 32
        assert!(bit_math::least_significant_bit(range4) == 32, 6);
        assert!(bit_math::most_significant_bit(range4) == 63, 7);
        
        // Test bits 64-127
        let range5 = 340282366920938463444927863358058659840u256; // 0xFFFFFFFFFFFFFFFF << 64
        assert!(bit_math::least_significant_bit(range5) == 64, 8);
        assert!(bit_math::most_significant_bit(range5) == 127, 9);
        
        // Test bits 128-191
        let range6 = (0xffffffffffffffffu256 << 128);
        assert!(bit_math::least_significant_bit(range6) == 128, 10);
        assert!(bit_math::most_significant_bit(range6) == 191, 11);
    }

    #[test]
    fun test_bit_math_edge_cases() {
        // Test various edge cases
        
        // Test single bit at each boundary
        let boundaries = vector[0u8, 7u8, 8u8, 15u8, 16u8, 31u8, 32u8, 63u8, 64u8, 127u8, 128u8, 191u8, 192u8, 255u8];
        
        let i = 0;
        while (i < std::vector::length(&boundaries)) {
            let bit_pos = *std::vector::borrow(&boundaries, i);
            let mask = 1u256 << bit_pos;
            
            assert!(bit_math::least_significant_bit(mask) == bit_pos, i);
            assert!(bit_math::most_significant_bit(mask) == bit_pos, i + 100);
            
            i = i + 1;
        };
    }

    #[test]
    fun test_bit_math_consistency() {
        // Test consistency between LSB and MSB for single bits
        let i = 0u8;
        while (i < 255u8) {
            let mask = 1u256 << (i as u8);
            let lsb = bit_math::least_significant_bit(mask);
            let msb = bit_math::most_significant_bit(mask);
            
            // For single bits, LSB and MSB should be equal
            assert!(lsb == msb, (i as u64));
            assert!(lsb == i, (i as u64) + 256);
            
            i = i + 1;
        };
        // Test the last bit (255) separately
        let mask = 1u256 << 255u8;
        let lsb = bit_math::least_significant_bit(mask);
        let msb = bit_math::most_significant_bit(mask);
        assert!(lsb == msb, 255);
        assert!(lsb == 255u8, 511);
    }

    #[test]
    fun test_bit_math_random_patterns() {
        // Test various random-like patterns
        
        // Test 0x123456789abcdef0... - MSB should be at bit 252 (highest bit in 0x1)
        let pattern1 = 0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0;
        assert!(bit_math::least_significant_bit(pattern1) == 4, 0);
        assert!(bit_math::most_significant_bit(pattern1) == 252, 1);
        
        // Test 0xfedcba9876543210... - MSB should be at bit 255 (highest bit in 0xf)
        let pattern2 = 0xfedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210;
        assert!(bit_math::least_significant_bit(pattern2) == 4, 2);
        assert!(bit_math::most_significant_bit(pattern2) == 255, 3);
        
        // Test 0x0f0f0f0f... - The highest nibble is 0x0f, so MSB is at bit 251 (bit 3 of the top nibble)
        let pattern3 = 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
        assert!(bit_math::least_significant_bit(pattern3) == 0, 4);
        assert!(bit_math::most_significant_bit(pattern3) == 251, 5);
        
        // Test 0xf0f0f0f0... - MSB should be at bit 255 (highest bit in 0xf0 pattern)
        let pattern4 = 0xf0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0;
        assert!(bit_math::least_significant_bit(pattern4) == 4, 6);
        assert!(bit_math::most_significant_bit(pattern4) == 255, 7);
        
        // Test 0x00ff00ff... - The highest byte is 0x00ff, so MSB is at bit 247 (bit 7 of byte 30)
        let pattern5 = 0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
        assert!(bit_math::least_significant_bit(pattern5) == 0, 8);
        assert!(bit_math::most_significant_bit(pattern5) == 247, 9);
        
        // Test 0xff00ff00... - MSB should be at bit 255 (highest bit in 0xff00 pattern)
        let pattern6 = 0xff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00;
        assert!(bit_math::least_significant_bit(pattern6) == 8, 10);
        assert!(bit_math::most_significant_bit(pattern6) == 255, 11);
    }

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::bit_math)]
    fun test_least_significant_bit_zero_input() {
        // Test that LSB function fails with zero input
        bit_math::least_significant_bit(0);
    }

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::bit_math)]
    fun test_most_significant_bit_zero_input() {
        // Test that MSB function fails with zero input
        bit_math::most_significant_bit(0);
    }
}

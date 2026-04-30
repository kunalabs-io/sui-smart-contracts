/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_constants {
    use bluefin_spot::constants;
    use std::string;

    //===========================================================//
    //                 Protocol Configuration Tests              //
    //===========================================================//

    #[test]
    fun test_protocol_fee_share() {
        // Default protocol fee share should be 200000 (20%)
        assert!(constants::protocol_fee_share() == 200000, 0);
    }

    #[test]
    fun test_max_protocol_fee_share() {
        // Max allowed protocol fee share should be 500000 (50%)
        assert!(constants::max_protocol_fee_share() == 500000, 0);
    }

    #[test]
    fun test_protocol_fee_share_within_max() {
        // Default protocol fee should be less than or equal to max allowed
        assert!(constants::protocol_fee_share() <= constants::max_protocol_fee_share(), 0);
    }

    #[test]
    fun test_max_allowed_fee_rate() {
        // Max allowed fee rate should be 20000 (2%)
        assert!(constants::max_allowed_fee_rate() == 20000, 0);
    }

    #[test]
    fun test_max_allowed_tick_spacing() {
        // Max allowed tick spacing should be 400
        assert!(constants::max_allowed_tick_spacing() == 400, 0);
    }

    #[test]
    fun test_max_observation_cardinality() {
        // Max observation cardinality should be 1000
        assert!(constants::max_observation_cardinality() == 1000, 0);
    }

    //===========================================================//
    //                 Mathematical Constants Tests              //
    //===========================================================//

    #[test]
    fun test_q64_value() {
        // Q64 should be 2^64 = 18446744073709551616
        assert!(constants::q64() == 18446744073709551616, 0);
    }

    #[test]
    fun test_q64_power_of_two() {
        // Q64 should be exactly 2^64
        let expected_q64: u128 = 1;
        let i = 0;
        while (i < 64) {
            expected_q64 = expected_q64 * 2;
            i = i + 1;
        };
        assert!(constants::q64() == expected_q64, 0);
    }

    //===========================================================//
    //                 Maximum Value Constants Tests             //
    //===========================================================//

    #[test]
    fun test_max_u8() {
        // Max u8 should be 255 (0xff)
        assert!(constants::max_u8() == 255, 0);
        assert!(constants::max_u8() == 0xff, 0);
    }

    #[test]
    fun test_max_u16() {
        // Max u16 should be 65535 (0xffff)
        assert!(constants::max_u16() == 65535, 0);
        assert!(constants::max_u16() == 0xffff, 0);
    }

    #[test]
    fun test_max_u32() {
        // Max u32 should be 4294967295 (0xffffffff)
        assert!(constants::max_u32() == 4294967295, 0);
        assert!(constants::max_u32() == 0xffffffff, 0);
    }

    #[test]
    fun test_max_u64() {
        // Max u64 should be 18446744073709551615 (0xffffffffffffffff)
        assert!(constants::max_u64() == 18446744073709551615, 0);
        assert!(constants::max_u64() == 0xffffffffffffffff, 0);
    }

    #[test]
    fun test_max_u128() {
        // Max u128 should be 0xffffffffffffffffffffffffffffffff
        assert!(constants::max_u128() == 0xffffffffffffffffffffffffffffffff, 0);
    }

    #[test]
    fun test_max_u256() {
        // Max u256 should be 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        assert!(constants::max_u256() == 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0);
    }

    #[test]
    fun test_max_values_progression() {
        // Test that each max value is larger than the previous type's max
        assert!((constants::max_u8() as u16) < constants::max_u16(), 0);
        assert!((constants::max_u16() as u32) < constants::max_u32(), 0);
        assert!((constants::max_u32() as u64) < constants::max_u64(), 0);
        assert!((constants::max_u64() as u128) < constants::max_u128(), 0);
        assert!((constants::max_u128() as u256) < constants::max_u256(), 0);
    }

    #[test]
    fun test_max_values_bit_patterns() {
        // Test that max values have all bits set for their respective types
        // For u8: 2^8 - 1 = 255
        assert!(constants::max_u8() == 255, 0);
        
        // For u16: 2^16 - 1 = 65535  
        assert!(constants::max_u16() == 65535, 0);
        
        // For u32: 2^32 - 1 = 4294967295
        assert!(constants::max_u32() == 4294967295, 0);
        
        // For u64: 2^64 - 1 = 18446744073709551615
        assert!(constants::max_u64() == 18446744073709551615, 0);
    }

    //===========================================================//
    //                 String Constants Tests                    //
    //===========================================================//

    #[test]
    fun test_manager_string() {
        let expected = string::utf8(b"manager");
        assert!(constants::manager() == expected, 0);
    }

    #[test]
    fun test_blue_reward_type_string() {
        let expected = string::utf8(b"9753a815080c9a1a1727b4be9abb509014197e78ae09e33c146c786fac3731e0::bpoint::BPOINT");
        assert!(constants::blue_reward_type() == expected, 0);
    }

    #[test]
    fun test_pool_creation_fee_dynamic_key_string() {
        let expected = string::utf8(b"pool_creation_fee");
        assert!(constants::pool_creation_fee_dynamic_key() == expected, 0);
    }

    #[test]
    fun test_flash_swap_in_progress_key_bytes() {
        let expected = b"flash_swap_in_progress";
        assert!(constants::flash_swap_in_progress_key() == expected, 0);
    }

    #[test]
    fun test_string_constants_not_empty() {
        // Ensure all string constants are not empty
        assert!(string::length(&constants::manager()) > 0, 0);
        assert!(string::length(&constants::blue_reward_type()) > 0, 0);
        assert!(string::length(&constants::pool_creation_fee_dynamic_key()) > 0, 0);
        assert!(std::vector::length(&constants::flash_swap_in_progress_key()) > 0, 0);
    }

    #[test]
    fun test_blue_reward_type_format() {
        // Test that blue reward type follows the expected format (address::module::type)
        let blue_reward = constants::blue_reward_type();
        let blue_reward_bytes = string::as_bytes(&blue_reward);
        
        // Should contain "::" separators
        let has_double_colon = false;
        let i = 0;
        let len = std::vector::length(blue_reward_bytes);
        while (i < len - 1) {
            if (*std::vector::borrow(blue_reward_bytes, i) == 58 && // ':'
                *std::vector::borrow(blue_reward_bytes, i + 1) == 58) { // ':'
                has_double_colon = true;
                break
            };
            i = i + 1;
        };
        assert!(has_double_colon, 0);
    }

    //===========================================================//
    //                 Consistency Tests                         //
    //===========================================================//

    #[test]
    fun test_constants_consistency() {
        // Test that constants maintain their expected relationships
        
        // Protocol fee share should be reasonable (less than 100%)
        assert!(constants::protocol_fee_share() < 1000000, 0); // Less than 100%
        
        // Max protocol fee share should be reasonable (less than or equal to 100%)
        assert!(constants::max_protocol_fee_share() <= 1000000, 0); // Less than or equal to 100%
        
        // Fee rate should be reasonable (less than 100%)
        assert!(constants::max_allowed_fee_rate() < 1000000, 0);
        
        // Tick spacing should be positive
        assert!(constants::max_allowed_tick_spacing() > 0, 0);
        
        // Observation cardinality should be positive
        assert!(constants::max_observation_cardinality() > 0, 0);
    }

    #[test]
    fun test_q64_relationship_with_max_u64() {
        // Q64 should be 2^64, which is max_u64 + 1
        assert!(constants::q64() == (constants::max_u64() as u128) + 1, 0);
    }

    #[test]
    fun test_fee_percentages() {
        // Test that fee values make sense as percentages
        // Assuming fee values are in basis points (1/10000)
        
        // Protocol fee share: 200000 = 20%
        let protocol_fee_percent = (constants::protocol_fee_share() as u128) * 100 / 1000000;
        assert!(protocol_fee_percent == 20, 0);
        
        // Max protocol fee share: 500000 = 50%
        let max_protocol_fee_percent = (constants::max_protocol_fee_share() as u128) * 100 / 1000000;
        assert!(max_protocol_fee_percent == 50, 0);
        
        // Max fee rate: 20000 = 2%
        let max_fee_rate_percent = (constants::max_allowed_fee_rate() as u128) * 100 / 1000000;
        assert!(max_fee_rate_percent == 2, 0);
    }

    //===========================================================//
    //                 Immutability Tests                        //
    //===========================================================//

    #[test]
    fun test_constants_immutability() {
        // Test that calling the same function multiple times returns the same value
        assert!(constants::protocol_fee_share() == constants::protocol_fee_share(), 0);
        assert!(constants::max_protocol_fee_share() == constants::max_protocol_fee_share(), 0);
        assert!(constants::max_allowed_fee_rate() == constants::max_allowed_fee_rate(), 0);
        assert!(constants::max_allowed_tick_spacing() == constants::max_allowed_tick_spacing(), 0);
        assert!(constants::max_observation_cardinality() == constants::max_observation_cardinality(), 0);
        assert!(constants::q64() == constants::q64(), 0);
    }

    #[test]
    fun test_max_values_immutability() {
        // Test that max value functions are consistent
        assert!(constants::max_u8() == constants::max_u8(), 0);
        assert!(constants::max_u16() == constants::max_u16(), 0);
        assert!(constants::max_u32() == constants::max_u32(), 0);
        assert!(constants::max_u64() == constants::max_u64(), 0);
        assert!(constants::max_u128() == constants::max_u128(), 0);
        assert!(constants::max_u256() == constants::max_u256(), 0);
    }

    #[test]
    fun test_string_constants_immutability() {
        // Test that string constants are consistent
        assert!(constants::manager() == constants::manager(), 0);
        assert!(constants::blue_reward_type() == constants::blue_reward_type(), 0);
        assert!(constants::pool_creation_fee_dynamic_key() == constants::pool_creation_fee_dynamic_key(), 0);
        assert!(constants::flash_swap_in_progress_key() == constants::flash_swap_in_progress_key(), 0);
    }

    //===========================================================//
    //                 Boundary Value Tests                      //
    //===========================================================//

    #[test]
    fun test_protocol_configuration_boundaries() {
        // Test that protocol configuration values are within reasonable bounds
        
        // Protocol fee share should be non-zero but reasonable
        assert!(constants::protocol_fee_share() > 0, 0);
        assert!(constants::protocol_fee_share() < constants::max_protocol_fee_share(), 0);
        
        // Max values should be positive
        assert!(constants::max_protocol_fee_share() > 0, 0);
        assert!(constants::max_allowed_fee_rate() > 0, 0);
        assert!(constants::max_allowed_tick_spacing() > 0, 0);
        assert!(constants::max_observation_cardinality() > 0, 0);
    }

    #[test]
    fun test_mathematical_constants_properties() {
        // Test mathematical properties of Q64
        let q64 = constants::q64();
        
        // Q64 should be a power of 2
        assert!(q64 > 0, 0);
        
        // Q64 should be exactly 2^64
        assert!(q64 == 18446744073709551616, 0);
        
        // Q64 should be greater than max_u64
        assert!(q64 > (constants::max_u64() as u128), 0);
    }

    //===========================================================//
    //                 Integration Tests                         //
    //===========================================================//

    #[test]
    fun test_all_constants_accessible() {
        // Test that all constant getter functions are accessible and return values
        let _protocol_fee = constants::protocol_fee_share();
        let _max_protocol_fee = constants::max_protocol_fee_share();
        let _max_fee_rate = constants::max_allowed_fee_rate();
        let _max_tick_spacing = constants::max_allowed_tick_spacing();
        let _max_cardinality = constants::max_observation_cardinality();
        let _q64 = constants::q64();
        let _max_u8 = constants::max_u8();
        let _max_u16 = constants::max_u16();
        let _max_u32 = constants::max_u32();
        let _max_u64 = constants::max_u64();
        let _max_u128 = constants::max_u128();
        let _max_u256 = constants::max_u256();
        let _manager = constants::manager();
        let _blue_reward = constants::blue_reward_type();
        let _pool_fee_key = constants::pool_creation_fee_dynamic_key();
        let _flash_swap_key = constants::flash_swap_in_progress_key();
        
        // If we reach here, all constants are accessible
        assert!(true, 0);
    }
}

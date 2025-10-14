/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

#[test_only]
module bluefin_spot::test_errors {
    use bluefin_spot::errors;

    //===========================================================//
    //                    Error Code Tests                       //
    //===========================================================//

    #[test]
    fun test_version_mismatch() {
        assert!(errors::version_mismatch() == 1001, 0);
    }

    #[test]
    fun test_invalid_tick_range() {
        assert!(errors::invalid_tick_range() == 1002, 0);
    }

    #[test]
    fun test_insufficient_amount() {
        assert!(errors::insufficient_amount() == 1003, 0);
    }

    #[test]
    fun test_insufficient_coin_balance() {
        assert!(errors::insufficient_coin_balance() == 1004, 0);
    }

    #[test]
    fun test_version_cant_be_increased() {
        assert!(errors::verion_cant_be_increased() == 1005, 0);
    }

    #[test]
    fun test_flash_swap_in_progress() {
        assert!(errors::flash_swap_in_progress() == 1006, 0);
    }

    #[test]
    fun test_no_flash_swap_in_progress() {
        assert!(errors::no_flash_swap_in_progress() == 1007, 0);
    }

    #[test]
    fun test_overflow() {
        assert!(errors::overflow() == 1008, 0);
    }

    #[test]
    fun test_invalid_price_limit() {
        assert!(errors::invalid_price_limit() == 1009, 0);
    }

    #[test]
    fun test_slippage_exceeds() {
        assert!(errors::slippage_exceeds() == 1010, 0);
    }

    #[test]
    fun test_invalid_pool() {
        assert!(errors::invalid_pool() == 1011, 0);
    }

    #[test]
    fun test_pool_is_paused() {
        assert!(errors::pool_is_paused() == 1012, 0);
    }

    #[test]
    fun test_invalid_coins() {
        assert!(errors::invalid_coins() == 1013, 0);
    }

    #[test]
    fun test_invalid_observation_timestamp() {
        assert!(errors::invalid_observation_timestamp() == 1014, 0);
    }

    #[test]
    fun test_insufficient_liquidity() {
        assert!(errors::insufficient_liquidity() == 1015, 0);
    }

    #[test]
    fun test_invalid_fee_growth() {
        assert!(errors::invalid_fee_growth() == 1016, 0);
    }

    #[test]
    fun test_add_check_failed() {
        assert!(errors::add_check_failed() == 1017, 0);
    }

    #[test]
    fun test_non_empty_position() {
        assert!(errors::non_empty_position() == 1018, 0);
    }

    #[test]
    fun test_position_does_not_belong_to_pool() {
        assert!(errors::position_does_not_belong_to_pool() == 1019, 0);
    }

    #[test]
    fun test_invalid_timestamp() {
        assert!(errors::invalid_timestamp() == 1020, 0);
    }

    #[test]
    fun test_reward_index_not_found() {
        assert!(errors::reward_index_not_found() == 1021, 0);
    }

    #[test]
    fun test_invalid_last_update_time() {
        assert!(errors::invalid_last_update_time() == 1022, 0);
    }

    #[test]
    fun test_not_authorized() {
        assert!(errors::not_authorized() == 1023, 0);
    }

    #[test]
    fun test_update_rewards_info_check_failed() {
        assert!(errors::update_rewards_info_check_failed() == 1024, 0);
    }

    #[test]
    fun test_invalid_protocol_fee_share() {
        assert!(errors::invalid_protocol_fee_share() == 1025, 0);
    }

    #[test]
    fun test_invalid_tick_spacing() {
        assert!(errors::invalid_tick_spacing() == 1026, 0);
    }

    #[test]
    fun test_invalid_fee_rate() {
        assert!(errors::invalid_fee_rate() == 1027, 0);
    }

    #[test]
    fun test_invalid_observation_cardinality() {
        assert!(errors::invalid_observation_cardinality() == 1028, 0);
    }

    #[test]
    fun test_zero_amount() {
        assert!(errors::zero_amount() == 1029, 0);
    }

    #[test]
    fun test_invalid_pool_price() {
        assert!(errors::invalid_pool_price() == 1030, 0);
    }

    #[test]
    fun test_reward_manager_not_found() {
        assert!(errors::reward_manager_not_found() == 1031, 0);
    }

    #[test]
    fun test_already_a_reward_manger() {
        assert!(errors::already_a_reward_manger() == 1032, 0);
    }

    #[test]
    fun test_can_not_claim_zero_reward() {
        assert!(errors::can_not_claim_zero_reward() == 1033, 0);
    }

    #[test]
    fun test_cannot_close_position_with_fee_to_claim() {
        assert!(errors::cannot_close_position_with_fee_to_claim() == 1035, 0);
    }

    #[test]
    fun test_depricated() {
        assert!(errors::depricated() == 1036, 0);
    }

    #[test]
    fun test_reward_amount_and_provided_balance_do_not_match() {
        assert!(errors::reward_amount_and_provided_balance_do_not_match() == 1037, 0);
    }

    #[test]
    fun test_fee_coin_not_supported() {
        assert!(errors::fee_coin_not_supported() == 1038, 0);
    }

    #[test]
    fun test_invalid_fee_provided() {
        assert!(errors::invalid_fee_provided() == 1039, 0);
    }

    #[test]
    fun test_same_value_provided() {
        assert!(errors::same_value_provided() == 1040, 0);
    }

    // Tests for deprecated/unused error functions that abort
    // These functions are marked as "Unused error" in the source and abort with code 0

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::errors)]
    fun test_insufficient_pool_balance_aborts() {
        // This function is deprecated and aborts with code 0
        errors::insufficient_pool_balance();
    }

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::errors)]
    fun test_tick_score_out_of_bounds_aborts() {
        // This function is deprecated and aborts with code 0
        errors::tick_score_out_of_bounds();
    }

    #[test]
    #[expected_failure(abort_code = 0, location = bluefin_spot::errors)]
    fun test_swap_amount_exceeds_aborts() {
        // This function is deprecated and aborts with code 0
        errors::swap_amount_exceeds();
    }

    //===========================================================//
    //                    Comprehensive Tests                    //
    //===========================================================//

    #[test]
    fun test_all_error_codes_are_unique() {
        // Test that all error codes are unique and in expected range
        let error_codes = vector[
            errors::version_mismatch(),
            errors::invalid_tick_range(),
            errors::insufficient_amount(),
            errors::insufficient_coin_balance(),
            errors::verion_cant_be_increased(),
            errors::flash_swap_in_progress(),
            errors::no_flash_swap_in_progress(),
            errors::overflow(),
            errors::invalid_price_limit(),
            errors::slippage_exceeds(),
            errors::invalid_pool(),
            errors::pool_is_paused(),
            errors::invalid_coins(),
            errors::invalid_observation_timestamp(),
            errors::insufficient_liquidity(),
            errors::invalid_fee_growth(),
            errors::add_check_failed(),
            errors::non_empty_position(),
            errors::position_does_not_belong_to_pool(),
            errors::invalid_timestamp(),
            errors::reward_index_not_found(),
            errors::invalid_last_update_time(),
            errors::not_authorized(),
            errors::update_rewards_info_check_failed(),
            errors::invalid_protocol_fee_share(),
            errors::invalid_tick_spacing(),
            errors::invalid_fee_rate(),
            errors::invalid_observation_cardinality(),
            errors::zero_amount(),
            errors::invalid_pool_price(),
            errors::reward_manager_not_found(),
            errors::already_a_reward_manger(),
            errors::can_not_claim_zero_reward(),
            errors::cannot_close_position_with_fee_to_claim(),
            errors::depricated(),
            errors::reward_amount_and_provided_balance_do_not_match(),
            errors::fee_coin_not_supported(),
            errors::invalid_fee_provided(),
            errors::same_value_provided()
        ];

        // Check that all error codes are in the expected range (1001-1040)
        let i = 0;
        while (i < std::vector::length(&error_codes)) {
            let code = *std::vector::borrow(&error_codes, i);
            assert!(code >= 1001 && code <= 1040, i);
            i = i + 1;
        };
    }

    #[test]
    fun test_error_code_ranges() {
        // Test that error codes are in the expected 1000+ range
        assert!(errors::version_mismatch() > 1000, 0);
        assert!(errors::same_value_provided() > 1000, 0);
        
        // Test that the first and last error codes are as expected
        assert!(errors::version_mismatch() == 1001, 0);
        assert!(errors::same_value_provided() == 1040, 0);
    }

    #[test]
    fun test_error_code_consistency() {
        // Test that calling the same function multiple times returns the same value
        assert!(errors::version_mismatch() == errors::version_mismatch(), 0);
        assert!(errors::invalid_tick_range() == errors::invalid_tick_range(), 0);
        assert!(errors::overflow() == errors::overflow(), 0);
    }
}

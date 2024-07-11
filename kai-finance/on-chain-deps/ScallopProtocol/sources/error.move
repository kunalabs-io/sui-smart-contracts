module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::error {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun whitelist_error(): u64;
 #[native_interface]
    native public fun version_mismatch_error(): u64;
 #[native_interface]
    native public fun invalid_obligation_error(): u64;
 #[native_interface]
    native public fun obligation_locked(): u64;
 #[native_interface]
    native public fun obligation_unlock_with_wrong_key(): u64;
 #[native_interface]
    native public fun obligation_already_locked(): u64;
 #[native_interface]
    native public fun obligation_access_lock_key_not_in_store(): u64;
 #[native_interface]
    native public fun obligation_access_reward_key_not_in_store(): u64;
 #[native_interface]
    native public fun obligation_access_store_key_exists(): u64;
 #[native_interface]
    native public fun obligation_access_store_key_not_found(): u64;
 #[native_interface]
    native public fun obligation_cant_forcely_unlocked(): u64;
 #[native_interface]
    native public fun oracle_stale_price_error(): u64;
 #[native_interface]
    native public fun oracle_price_not_found_error(): u64;
 #[native_interface]
    native public fun oracle_zero_price_error(): u64;
 #[native_interface]
    native public fun borrow_too_much_error(): u64;
 #[native_interface]
    native public fun borrow_too_small_error(): u64;
 #[native_interface]
    native public fun flash_loan_repay_not_enough_error(): u64;
 #[native_interface]
    native public fun unable_to_borrow_a_collateral_coin(): u64;
 #[native_interface]
    native public fun unable_to_liquidate_error(): u64;
 #[native_interface]
    native public fun max_collateral_reached_error(): u64;
 #[native_interface]
    native public fun invalid_collateral_type_error(): u64;
 #[native_interface]
    native public fun withdraw_collateral_too_much_error(): u64;
 #[native_interface]
    native public fun unable_to_deposit_a_borrowed_coin(): u64;
 #[native_interface]
    native public fun mint_market_coin_too_small_error(): u64;
 #[native_interface]
    native public fun redeem_market_coin_too_small_error(): u64;
 #[native_interface]
    native public fun interest_model_type_not_match_error(): u64;
 #[native_interface]
    native public fun risk_model_type_not_match_error(): u64;
 #[native_interface]
    native public fun invalid_params_error(): u64;
 #[native_interface]
    native public fun outflow_reach_limit_error(): u64;
 #[native_interface]
    native public fun flash_loan_not_paid_enough(): u64;
 #[native_interface]
    native public fun base_asset_not_active_error(): u64;
 #[native_interface]
    native public fun collateral_not_active_error(): u64;
 #[native_interface]
    native public fun risk_model_param_error(): u64;
 #[native_interface]
    native public fun interest_model_param_error(): u64;
 #[native_interface]
    native public fun pool_liquidity_not_enough_error(): u64;
 #[native_interface]
    native public fun supply_limit_reached(): u64;
 #[native_interface]
    native public fun collateral_not_enough(): u64;
 #[native_interface]
    native public fun reserve_not_enough_error(): u64;
 #[native_interface]
    native public fun zero_repay_amount_error(): u64;

}

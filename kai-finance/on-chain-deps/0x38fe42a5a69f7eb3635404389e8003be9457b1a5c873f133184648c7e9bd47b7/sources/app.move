module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app {

    use sui::clock;
    use sui::object;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ac_table;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::one_time_lock_value;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::interest_model;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::limiter;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation_access;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::risk_model;

    struct APP has drop {
        dummy_field: bool,
    }
    struct AdminCap has store, key {
        id: object::UID,
        interest_model_cap: ac_table::AcTableCap<interest_model::InterestModels>,
        interest_model_change_delay: u64,
        risk_model_cap: ac_table::AcTableCap<risk_model::RiskModels>,
        risk_model_change_delay: u64,
        limiter_change_delay: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun extend_interest_model_change_delay(a0: &mut app::AdminCap, a1: u64);
    native public fun extend_risk_model_change_delay(a0: &mut app::AdminCap, a1: u64);
    native public fun extend_limiter_change_delay(a0: &mut app::AdminCap, a1: u64);
    native public fun ext(a0: &app::AdminCap, a1: &mut market::Market): &mut object::UID;
    native public fun add_whitelist_address(a0: &app::AdminCap, a1: &mut market::Market, a2: address);
    native public fun remove_whitelist_address(a0: &app::AdminCap, a1: &mut market::Market, a2: address);
    native public fun create_interest_model_change<T0>(a0: &app::AdminCap, a1: u64, a2: u64, a3: u64, a4: u64, a5: u64, a6: u64, a7: u64, a8: u64, a9: u64, a10: u64, a11: u64, a12: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<interest_model::InterestModel>;
    native public fun add_interest_model<T0>(a0: &mut market::Market, a1: &app::AdminCap, a2: one_time_lock_value::OneTimeLockValue<interest_model::InterestModel>, a3: &clock::Clock, a4: &mut tx_context::TxContext);
    native public fun update_interest_model<T0>(a0: &mut market::Market, a1: &app::AdminCap, a2: one_time_lock_value::OneTimeLockValue<interest_model::InterestModel>, a3: &mut tx_context::TxContext);
    native public fun create_risk_model_change<T0>(a0: &app::AdminCap, a1: u64, a2: u64, a3: u64, a4: u64, a5: u64, a6: u64, a7: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<risk_model::RiskModel>;
    native public entry fun add_risk_model<T0>(a0: &mut market::Market, a1: &app::AdminCap, a2: one_time_lock_value::OneTimeLockValue<risk_model::RiskModel>, a3: &mut tx_context::TxContext);
    native public entry fun update_risk_model<T0>(a0: &mut market::Market, a1: &app::AdminCap, a2: one_time_lock_value::OneTimeLockValue<risk_model::RiskModel>, a3: &mut tx_context::TxContext);
    native public entry fun add_limiter<T0>(a0: &app::AdminCap, a1: &mut market::Market, a2: u64, a3: u32, a4: u32, a5: &mut tx_context::TxContext);
    native public fun create_limiter_params_change<T0>(a0: &app::AdminCap, a1: u32, a2: u32, a3: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<limiter::LimiterUpdateParamsChange>;
    native public fun create_limiter_limit_change<T0>(a0: &app::AdminCap, a1: u64, a2: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<limiter::LimiterUpdateLimitChange>;
    native public entry fun apply_limiter_limit_change<T0>(a0: &app::AdminCap, a1: &mut market::Market, a2: one_time_lock_value::OneTimeLockValue<limiter::LimiterUpdateLimitChange>, a3: &mut tx_context::TxContext);
    native public entry fun apply_limiter_params_change<T0>(a0: &app::AdminCap, a1: &mut market::Market, a2: one_time_lock_value::OneTimeLockValue<limiter::LimiterUpdateParamsChange>, a3: &mut tx_context::TxContext);
    native public entry fun set_incentive_reward_factor<T0>(a0: &app::AdminCap, a1: &mut market::Market, a2: u64, a3: u64, a4: &mut tx_context::TxContext);
    native public entry fun set_flash_loan_fee<T0>(a0: &app::AdminCap, a1: &mut market::Market, a2: u64);
    native public entry fun set_base_asset_active_state<T0>(a0: &app::AdminCap, a1: &mut market::Market, a2: bool);
    native public entry fun set_collateral_active_state<T0>(a0: &app::AdminCap, a1: &mut market::Market, a2: bool);
    native public entry fun take_revenue<T0>(a0: &app::AdminCap, a1: &mut market::Market, a2: u64, a3: &mut tx_context::TxContext);
    native public entry fun add_lock_key<T0: drop>(a0: &app::AdminCap, a1: &mut obligation_access::ObligationAccessStore);
    native public entry fun remove_lock_key<T0: drop>(a0: &app::AdminCap, a1: &mut obligation_access::ObligationAccessStore);
    native public entry fun add_reward_key<T0: drop>(a0: &app::AdminCap, a1: &mut obligation_access::ObligationAccessStore);
    native public entry fun remove_reward_key<T0: drop>(a0: &app::AdminCap, a1: &mut obligation_access::ObligationAccessStore);
    native public entry fun update_borrow_fee<T0: drop>(a0: &app::AdminCap, a1: &mut market::Market, a2: u64, a3: u64);
    native public entry fun update_borrow_fee_recipient(a0: &app::AdminCap, a1: &mut market::Market, a2: address);

}

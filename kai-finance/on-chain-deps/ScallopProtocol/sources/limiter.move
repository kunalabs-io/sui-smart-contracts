module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::limiter {

    use 0x1::type_name;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::one_time_lock_value;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::limiter;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;

    friend app;
    friend market;

    struct Limiter has drop, store {
        outflow_limit: u64,
        outflow_cycle_duration: u32,
        outflow_segment_duration: u32,
        outflow_segments: vector<limiter::Segment>,
    }
    struct Limiters has drop {
        dummy_field: bool,
    }
    struct Segment has drop, store {
        index: u64,
        value: u64,
    }
    struct LimiterUpdateLimitChangeCreatedEvent has copy, drop {
        changes: limiter::LimiterUpdateLimitChange,
        current_epoch: u64,
        delay_epoches: u64,
        effective_epoches: u64,
    }
    struct LimiterUpdateParamsChangeCreatedEvent has copy, drop {
        changes: limiter::LimiterUpdateParamsChange,
        current_epoch: u64,
        delay_epoches: u64,
        effective_epoches: u64,
    }
    struct LimiterLimitChangeAppliedEvent has copy, drop {
        changes: limiter::LimiterUpdateLimitChange,
        current_epoch: u64,
    }
    struct LimiterParamsChangeAppliedEvent has copy, drop {
        changes: limiter::LimiterUpdateParamsChange,
        current_epoch: u64,
    }
    struct LimiterUpdateLimitChange has copy, drop, store {
        coin_type: type_name::TypeName,
        outflow_limit: u64,
    }
    struct LimiterUpdateParamsChange has copy, drop, store {
        coin_type: type_name::TypeName,
        outflow_cycle_duration: u32,
        outflow_segment_duration: u32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun create_limiter_params_change<T0>(a0: u32, a1: u32, a2: u64, a3: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<limiter::LimiterUpdateParamsChange>;
 #[native_interface]
    native public(friend) fun create_limiter_limit_change<T0>(a0: u64, a1: u64, a2: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<limiter::LimiterUpdateLimitChange>;
 #[native_interface]
    native public(friend) fun apply_limiter_limit_change(a0: &mut wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>, a1: one_time_lock_value::OneTimeLockValue<limiter::LimiterUpdateLimitChange>, a2: &mut tx_context::TxContext);
 #[native_interface]
    native public(friend) fun apply_limiter_params_change(a0: &mut wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>, a1: one_time_lock_value::OneTimeLockValue<limiter::LimiterUpdateParamsChange>, a2: &mut tx_context::TxContext);
 #[native_interface]
    native public(friend) fun init_table(a0: &mut tx_context::TxContext): wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>;
 #[native_interface]
    native public(friend) fun add_limiter<T0>(a0: &mut wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>, a1: u64, a2: u32, a3: u32);
 #[native_interface]
    native public(friend) fun add_outflow(a0: &mut wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>, a1: type_name::TypeName, a2: u64, a3: u64);
 #[native_interface]
    native public(friend) fun reduce_outflow(a0: &mut wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>, a1: type_name::TypeName, a2: u64, a3: u64);
 #[native_interface]
    native public fun count_current_outflow(a0: &wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>, a1: type_name::TypeName, a2: u64): u64;

}

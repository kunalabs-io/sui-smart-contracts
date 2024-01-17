module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::interest_model {

    use 0x1::fixed_point32;
    use 0x1::type_name;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ac_table;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::one_time_lock_value;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::interest_model;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;

    friend app;
    friend market;

    struct InterestModel has copy, drop, store {
        type: type_name::TypeName,
        base_borrow_rate_per_sec: fixed_point32::FixedPoint32,
        interest_rate_scale: u64,
        borrow_rate_on_mid_kink: fixed_point32::FixedPoint32,
        mid_kink: fixed_point32::FixedPoint32,
        borrow_rate_on_high_kink: fixed_point32::FixedPoint32,
        high_kink: fixed_point32::FixedPoint32,
        max_borrow_rate: fixed_point32::FixedPoint32,
        revenue_factor: fixed_point32::FixedPoint32,
        borrow_weight: fixed_point32::FixedPoint32,
        min_borrow_amount: u64,
    }
    struct InterestModelChangeCreated has copy, drop {
        interest_model: interest_model::InterestModel,
        current_epoch: u64,
        delay_epoches: u64,
        effective_epoches: u64,
    }
    struct InterestModelAdded has copy, drop {
        interest_model: interest_model::InterestModel,
        current_epoch: u64,
    }
    struct InterestModels has drop {
        dummy_field: bool,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun base_borrow_rate(a0: &interest_model::InterestModel): fixed_point32::FixedPoint32;
    native public fun interest_rate_scale(a0: &interest_model::InterestModel): u64;
    native public fun borrow_rate_on_mid_kink(a0: &interest_model::InterestModel): fixed_point32::FixedPoint32;
    native public fun mid_kink(a0: &interest_model::InterestModel): fixed_point32::FixedPoint32;
    native public fun borrow_rate_on_high_kink(a0: &interest_model::InterestModel): fixed_point32::FixedPoint32;
    native public fun high_kink(a0: &interest_model::InterestModel): fixed_point32::FixedPoint32;
    native public fun max_borrow_rate(a0: &interest_model::InterestModel): fixed_point32::FixedPoint32;
    native public fun revenue_factor(a0: &interest_model::InterestModel): fixed_point32::FixedPoint32;
    native public fun borrow_weight(a0: &interest_model::InterestModel): fixed_point32::FixedPoint32;
    native public fun min_borrow_amount(a0: &interest_model::InterestModel): u64;
    native public fun type_name(a0: &interest_model::InterestModel): type_name::TypeName;
    native public(friend) fun new(a0: &mut tx_context::TxContext): (ac_table::AcTable<interest_model::InterestModels, type_name::TypeName, interest_model::InterestModel>, ac_table::AcTableCap<interest_model::InterestModels>);
    native public(friend) fun create_interest_model_change<T0>(a0: &ac_table::AcTableCap<interest_model::InterestModels>, a1: u64, a2: u64, a3: u64, a4: u64, a5: u64, a6: u64, a7: u64, a8: u64, a9: u64, a10: u64, a11: u64, a12: u64, a13: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<interest_model::InterestModel>;
    native public(friend) fun add_interest_model<T0>(a0: &mut ac_table::AcTable<interest_model::InterestModels, type_name::TypeName, interest_model::InterestModel>, a1: &ac_table::AcTableCap<interest_model::InterestModels>, a2: one_time_lock_value::OneTimeLockValue<interest_model::InterestModel>, a3: &mut tx_context::TxContext);
    native public fun calc_interest(a0: &interest_model::InterestModel, a1: fixed_point32::FixedPoint32): (fixed_point32::FixedPoint32, u64);

}

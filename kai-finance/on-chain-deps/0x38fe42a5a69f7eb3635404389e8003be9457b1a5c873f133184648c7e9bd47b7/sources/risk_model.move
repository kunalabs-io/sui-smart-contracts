module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::risk_model {

    use 0x1::fixed_point32;
    use 0x1::type_name;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ac_table;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::one_time_lock_value;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::risk_model;

    friend app;
    friend market;

    struct RiskModels has drop {
        dummy_field: bool,
    }
    struct RiskModel has copy, drop, store {
        type: type_name::TypeName,
        collateral_factor: fixed_point32::FixedPoint32,
        liquidation_factor: fixed_point32::FixedPoint32,
        liquidation_penalty: fixed_point32::FixedPoint32,
        liquidation_discount: fixed_point32::FixedPoint32,
        liquidation_revenue_factor: fixed_point32::FixedPoint32,
        max_collateral_amount: u64,
    }
    struct RiskModelChangeCreated has copy, drop {
        risk_model: risk_model::RiskModel,
        current_epoch: u64,
        delay_epoches: u64,
        effective_epoches: u64,
    }
    struct RiskModelAdded has copy, drop {
        risk_model: risk_model::RiskModel,
        current_epoch: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun collateral_factor(a0: &risk_model::RiskModel): fixed_point32::FixedPoint32;
    native public fun liq_factor(a0: &risk_model::RiskModel): fixed_point32::FixedPoint32;
    native public fun liq_penalty(a0: &risk_model::RiskModel): fixed_point32::FixedPoint32;
    native public fun liq_discount(a0: &risk_model::RiskModel): fixed_point32::FixedPoint32;
    native public fun liq_revenue_factor(a0: &risk_model::RiskModel): fixed_point32::FixedPoint32;
    native public fun max_collateral_Amount(a0: &risk_model::RiskModel): u64;
    native public fun type_name(a0: &risk_model::RiskModel): type_name::TypeName;
    native public(friend) fun new(a0: &mut tx_context::TxContext): (ac_table::AcTable<risk_model::RiskModels, type_name::TypeName, risk_model::RiskModel>, ac_table::AcTableCap<risk_model::RiskModels>);
    native public(friend) fun create_risk_model_change<T0>(a0: &ac_table::AcTableCap<risk_model::RiskModels>, a1: u64, a2: u64, a3: u64, a4: u64, a5: u64, a6: u64, a7: u64, a8: &mut tx_context::TxContext): one_time_lock_value::OneTimeLockValue<risk_model::RiskModel>;
    native public(friend) fun add_risk_model<T0>(a0: &mut ac_table::AcTable<risk_model::RiskModels, type_name::TypeName, risk_model::RiskModel>, a1: &ac_table::AcTableCap<risk_model::RiskModels>, a2: one_time_lock_value::OneTimeLockValue<risk_model::RiskModel>, a3: &mut tx_context::TxContext);

}

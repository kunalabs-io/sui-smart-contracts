module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation_collaterals {

    use 0x1::type_name;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation_collaterals;

    friend obligation;

    struct Collateral has copy, drop, store {
        amount: u64,
    }
    struct ObligationCollaterals has drop {
        dummy_field: bool,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public(friend) fun new(a0: &mut tx_context::TxContext): wit_table::WitTable<obligation_collaterals::ObligationCollaterals, type_name::TypeName, obligation_collaterals::Collateral>;
    native public(friend) fun init_collateral_if_none(a0: &mut wit_table::WitTable<obligation_collaterals::ObligationCollaterals, type_name::TypeName, obligation_collaterals::Collateral>, a1: type_name::TypeName);
    native public(friend) fun increase(a0: &mut wit_table::WitTable<obligation_collaterals::ObligationCollaterals, type_name::TypeName, obligation_collaterals::Collateral>, a1: type_name::TypeName, a2: u64);
    native public(friend) fun decrease(a0: &mut wit_table::WitTable<obligation_collaterals::ObligationCollaterals, type_name::TypeName, obligation_collaterals::Collateral>, a1: type_name::TypeName, a2: u64);
    native public fun collateral(a0: &wit_table::WitTable<obligation_collaterals::ObligationCollaterals, type_name::TypeName, obligation_collaterals::Collateral>, a1: type_name::TypeName): u64;

}

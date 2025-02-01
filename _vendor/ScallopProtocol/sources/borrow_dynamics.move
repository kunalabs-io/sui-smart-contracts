module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow_dynamics {

    use 0x1::fixed_point32;
    use 0x1::type_name;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow_dynamics;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;

    friend market;

    struct BorrowDynamics has drop {
        dummy_field: bool,
    }
    struct BorrowDynamic has copy, store {
        interest_rate: fixed_point32::FixedPoint32,
        interest_rate_scale: u64,
        borrow_index: u64,
        last_updated: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun interest_rate(a0: &borrow_dynamics::BorrowDynamic): fixed_point32::FixedPoint32;
 #[native_interface]
    native public fun interest_rate_scale(a0: &borrow_dynamics::BorrowDynamic): u64;
 #[native_interface]
    native public fun borrow_index(a0: &borrow_dynamics::BorrowDynamic): u64;
 #[native_interface]
    native public fun last_updated(a0: &borrow_dynamics::BorrowDynamic): u64;
 #[native_interface]
    native public(friend) fun new(a0: &mut tx_context::TxContext): wit_table::WitTable<borrow_dynamics::BorrowDynamics, type_name::TypeName, borrow_dynamics::BorrowDynamic>;
 #[native_interface]
    native public(friend) fun register_coin<T0>(a0: &mut wit_table::WitTable<borrow_dynamics::BorrowDynamics, type_name::TypeName, borrow_dynamics::BorrowDynamic>, a1: fixed_point32::FixedPoint32, a2: u64, a3: u64);
 #[native_interface]
    native public fun borrow_index_by_type(a0: &wit_table::WitTable<borrow_dynamics::BorrowDynamics, type_name::TypeName, borrow_dynamics::BorrowDynamic>, a1: type_name::TypeName): u64;
 #[native_interface]
    native public fun last_updated_by_type(a0: &wit_table::WitTable<borrow_dynamics::BorrowDynamics, type_name::TypeName, borrow_dynamics::BorrowDynamic>, a1: type_name::TypeName): u64;
 #[native_interface]
    native public(friend) fun update_borrow_index(a0: &mut wit_table::WitTable<borrow_dynamics::BorrowDynamics, type_name::TypeName, borrow_dynamics::BorrowDynamic>, a1: type_name::TypeName, a2: u64);
 #[native_interface]
    native public(friend) fun update_interest_rate(a0: &mut wit_table::WitTable<borrow_dynamics::BorrowDynamics, type_name::TypeName, borrow_dynamics::BorrowDynamic>, a1: type_name::TypeName, a2: fixed_point32::FixedPoint32, a3: u64);

}

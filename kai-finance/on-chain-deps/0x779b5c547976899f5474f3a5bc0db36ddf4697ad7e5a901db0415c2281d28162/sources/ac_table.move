module 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ac_table {

    use 0x1::option;
    use sui::object;
    use sui::table;
    use sui::tx_context;
    use sui::vec_set;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ac_table;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ownership;

    struct AcTable<phantom T0: drop, T1: copy+ drop+ store, phantom T2: store> has store, key {
        id: object::UID,
        table: table::Table<T1, T2>,
        keys: option::Option<vec_set::VecSet<T1>>,
        with_keys: bool,
    }
    struct AcTableOwnership has drop {
        dummy_field: bool,
    }
    struct AcTableCap<phantom T0> has store, key {
        id: object::UID,
        ownership: ownership::Ownership<ac_table::AcTableOwnership>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new<T0: drop, T1: copy+ drop+ store, T2: store>(a0: T0, a1: bool, a2: &mut tx_context::TxContext): (ac_table::AcTable<T0, T1, T2>, ac_table::AcTableCap<T0>);
 #[native_interface]
    native public fun add<T0: drop, T1: copy+ drop+ store, T2: store>(a0: &mut ac_table::AcTable<T0, T1, T2>, a1: &ac_table::AcTableCap<T0>, a2: T1, a3: T2);
 #[native_interface]
    native public fun keys<T0: drop, T1: copy+ drop+ store, T2: store>(a0: &ac_table::AcTable<T0, T1, T2>): vector<T1>;
 #[native_interface]
    native public fun borrow<T0: drop, T1: copy+ drop+ store, T2: store>(a0: &ac_table::AcTable<T0, T1, T2>, a1: T1): &T2;
 #[native_interface]
    native public fun borrow_mut<T0: drop, T1: copy+ drop+ store, T2: store>(a0: &mut ac_table::AcTable<T0, T1, T2>, a1: &ac_table::AcTableCap<T0>, a2: T1): &mut T2;
 #[native_interface]
    native public fun remove<T0: drop, T1: copy+ drop+ store, T2: store>(a0: &mut ac_table::AcTable<T0, T1, T2>, a1: &ac_table::AcTableCap<T0>, a2: T1): T2;
 #[native_interface]
    native public fun contains<T0: drop, T1: copy+ drop+ store, T2: store>(a0: &ac_table::AcTable<T0, T1, T2>, a1: T1): bool;
 #[native_interface]
    native public fun length<T0: drop, T1: copy+ drop+ store, T2: store>(a0: &ac_table::AcTable<T0, T1, T2>): u64;
 #[native_interface]
    native public fun is_empty<T0: drop, T1: copy+ drop+ store, T2: store>(a0: &ac_table::AcTable<T0, T1, T2>): bool;
 #[native_interface]
    native public fun destroy_empty<T0: drop, T1: copy+ drop+ store, T2: store>(a0: ac_table::AcTable<T0, T1, T2>, a1: &ac_table::AcTableCap<T0>);
 #[native_interface]
    native public fun drop<T0: drop, T1: copy+ drop+ store, T2: drop+ store>(a0: ac_table::AcTable<T0, T1, T2>, a1: &ac_table::AcTableCap<T0>);

}

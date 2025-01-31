module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::set {

    use sui::table;
    use sui::tx_context;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::set;

    struct Empty has drop, store {
        dummy_field: bool,
    }
    struct Set<phantom T0: copy+ drop+ store> has store {
        items: table::Table<T0, set::Empty>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new<T0: copy+ drop+ store>(a0: &mut tx_context::TxContext): set::Set<T0>;
 #[native_interface]
    native public fun add<T0: copy+ drop+ store>(a0: &mut set::Set<T0>, a1: T0);
 #[native_interface]
    native public fun contains<T0: copy+ drop+ store>(a0: &set::Set<T0>, a1: T0): bool;
 #[native_interface]
    native public fun remove<T0: copy+ drop+ store>(a0: &mut set::Set<T0>, a1: T0);

}

module x::ownership {

    use sui::object;
    use sui::tx_context;
    use x::ownership;

    struct Ownership<phantom T0: drop> has store, key {
        id: object::UID,
        of: object::ID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun create_ownership<T0: drop>(a0: T0, a1: object::ID, a2: &mut tx_context::TxContext): ownership::Ownership<T0>;
 #[native_interface]
    native public fun is_owner<T0: drop, T1: key>(a0: &ownership::Ownership<T0>, a1: &T1): bool;
 #[native_interface]
    native public fun assert_owner<T0: drop, T1: key>(a0: &ownership::Ownership<T0>, a1: &T1);

}

module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::utils {

    use sui::clock;
    use sui::coin;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun check_deadline(a0: &clock::Clock, a1: u64);
 #[native_interface]
    native public fun is_ordered<T0, T1>(): bool;
 #[native_interface]
    native public fun check_order<T0, T1>();
 #[native_interface]
    native public fun to_seconds(a0: u64): u64;
 #[native_interface]
    native public fun refund<T0>(a0: coin::Coin<T0>, a1: address);

}

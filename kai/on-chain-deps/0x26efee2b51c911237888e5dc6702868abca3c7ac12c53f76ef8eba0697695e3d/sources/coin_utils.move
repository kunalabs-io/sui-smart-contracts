module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::coin_utils {

    use sui::balance;
    use sui::coin;
    use sui::tx_context;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun take_balance<T0>(a0: &mut coin::Coin<T0>, a1: u64): balance::Balance<T0>;
 #[native_interface]
    native public fun take_full_balance<T0>(a0: &mut coin::Coin<T0>): balance::Balance<T0>;
 #[native_interface]
    native public fun put_balance<T0>(a0: &mut coin::Coin<T0>, a1: balance::Balance<T0>): u64;
 #[native_interface]
    native public fun return_nonzero<T0>(a0: coin::Coin<T0>, a1: &tx_context::TxContext);

}

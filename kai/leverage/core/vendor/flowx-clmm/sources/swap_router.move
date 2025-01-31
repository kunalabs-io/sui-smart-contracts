module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::swap_router {

    use sui::balance;
    use sui::clock;
    use sui::coin;
    use sui::tx_context;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool_manager;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::versioned;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun swap_exact_x_to_y<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: coin::Coin<T0>, a2: u128, a3: &versioned::Versioned, a4: &clock::Clock, a5: &tx_context::TxContext): balance::Balance<T1>;
 #[native_interface]
    native public fun swap_exact_y_to_x<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: coin::Coin<T1>, a2: u128, a3: &versioned::Versioned, a4: &clock::Clock, a5: &tx_context::TxContext): balance::Balance<T0>;
 #[native_interface]
    native public fun swap_exact_input<T0, T1>(a0: &mut pool_manager::PoolRegistry, a1: u64, a2: coin::Coin<T0>, a3: u64, a4: u128, a5: u64, a6: &versioned::Versioned, a7: &clock::Clock, a8: &mut tx_context::TxContext): coin::Coin<T1>;
 #[native_interface]
    native public fun swap_x_to_exact_y<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: coin::Coin<T0>, a2: u64, a3: u128, a4: &versioned::Versioned, a5: &clock::Clock, a6: &mut tx_context::TxContext): balance::Balance<T1>;
 #[native_interface]
    native public fun swap_y_to_exact_x<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: coin::Coin<T1>, a2: u64, a3: u128, a4: &versioned::Versioned, a5: &clock::Clock, a6: &mut tx_context::TxContext): balance::Balance<T0>;
 #[native_interface]
    native public fun swap_exact_output<T0, T1>(a0: &mut pool_manager::PoolRegistry, a1: u64, a2: coin::Coin<T0>, a3: u64, a4: u128, a5: u64, a6: &versioned::Versioned, a7: &clock::Clock, a8: &mut tx_context::TxContext): coin::Coin<T1>;

}

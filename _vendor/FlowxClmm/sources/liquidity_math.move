module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::liquidity_math {

    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i128;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun add_delta(a0: u128, a1: i128::I128): u128;
 #[native_interface]
    native public fun get_liquidity_for_amount_x(a0: u128, a1: u128, a2: u64): u128;
 #[native_interface]
    native public fun get_liquidity_for_amount_y(a0: u128, a1: u128, a2: u64): u128;
 #[native_interface]
    native public fun get_liquidity_for_amounts(a0: u128, a1: u128, a2: u128, a3: u64, a4: u64): u128;
 #[native_interface]
    native public fun get_amount_x_for_liquidity(a0: u128, a1: u128, a2: u128, a3: bool): u64;
 #[native_interface]
    native public fun get_amount_y_for_liquidity(a0: u128, a1: u128, a2: u128, a3: bool): u64;
 #[native_interface]
    native public fun get_amounts_for_liquidity(a0: u128, a1: u128, a2: u128, a3: u128, a4: bool): (u64, u64);

}

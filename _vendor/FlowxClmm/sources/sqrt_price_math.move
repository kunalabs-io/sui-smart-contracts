module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::sqrt_price_math {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun get_next_sqrt_price_from_amount_x_rouding_up(a0: u128, a1: u128, a2: u64, a3: bool): u128;
 #[native_interface]
    native public fun get_next_sqrt_price_from_amount_y_rouding_down(a0: u128, a1: u128, a2: u64, a3: bool): u128;
 #[native_interface]
    native public fun get_next_sqrt_price_from_input(a0: u128, a1: u128, a2: u64, a3: bool): u128;
 #[native_interface]
    native public fun get_next_sqrt_price_from_output(a0: u128, a1: u128, a2: u64, a3: bool): u128;
 #[native_interface]
    native public fun get_amount_x_delta(a0: u128, a1: u128, a2: u128, a3: bool): u64;
 #[native_interface]
    native public fun get_amount_y_delta(a0: u128, a1: u128, a2: u128, a3: bool): u64;

}

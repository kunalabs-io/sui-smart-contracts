module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::tick_math {

    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i32;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun max_sqrt_price(): u128;
 #[native_interface]
    native public fun min_sqrt_price(): u128;
 #[native_interface]
    native public fun max_tick(): i32::I32;
 #[native_interface]
    native public fun min_tick(): i32::I32;
 #[native_interface]
    native public fun tick_bound(): u32;
 #[native_interface]
    native public fun get_sqrt_price_at_tick(a0: i32::I32): u128;
 #[native_interface]
    native public fun is_valid_index(a0: i32::I32, a1: u32): bool;
 #[native_interface]
    native public fun get_tick_at_sqrt_price(a0: u128): i32::I32;

}

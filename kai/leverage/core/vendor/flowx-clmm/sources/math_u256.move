module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::math_u256 {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun div_mod(a0: u256, a1: u256): (u256, u256);
 #[native_interface]
    native public fun shlw(a0: u256): u256;
 #[native_interface]
    native public fun shrw(a0: u256): u256;
 #[native_interface]
    native public fun checked_shlw(a0: u256): (u256, bool);
 #[native_interface]
    native public fun div_round(a0: u256, a1: u256, a2: bool): u256;
 #[native_interface]
    native public fun add_check(a0: u256, a1: u256): bool;
 #[native_interface]
    native public fun overflow_add(a0: u256, a1: u256): u256;

}

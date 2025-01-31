module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::full_math_u64 {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun mul_div_floor(a0: u64, a1: u64, a2: u64): u64;
 #[native_interface]
    native public fun mul_div_round(a0: u64, a1: u64, a2: u64): u64;
 #[native_interface]
    native public fun mul_div_ceil(a0: u64, a1: u64, a2: u64): u64;
 #[native_interface]
    native public fun mul_shr(a0: u64, a1: u64, a2: u8): u64;
 #[native_interface]
    native public fun mul_shl(a0: u64, a1: u64, a2: u8): u64;
 #[native_interface]
    native public fun full_mul(a0: u64, a1: u64): u128;
 #[native_interface]
    native public fun add_check(a0: u64, a1: u64): bool;

}

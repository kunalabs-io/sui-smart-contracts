module math::u128 {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun mul_div(a0: u128, a1: u128, a2: u128): u128;
 #[native_interface]
    native public fun checked_mul(a0: u128, a1: u128): u128;
 #[native_interface]
    native public fun is_safe_mul(a0: u128, a1: u128): bool;

}

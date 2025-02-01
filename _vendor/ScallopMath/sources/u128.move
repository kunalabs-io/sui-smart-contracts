module 0xAD013D5FDE39E15EABDA32B3DBDAFD67DAC32B798CE63237C27A8F73339B9B6F::u128 {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun mul_div(a0: u128, a1: u128, a2: u128): u128;
 #[native_interface]
    native public fun checked_mul(a0: u128, a1: u128): u128;
 #[native_interface]
    native public fun is_safe_mul(a0: u128, a1: u128): bool;

}

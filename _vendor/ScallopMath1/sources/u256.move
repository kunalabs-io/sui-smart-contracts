module 0x9C564002970CE40370B0C1A8328D2E91924DAB43CA2CB483AF67AAF0F7CBE44E::u256 {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun mul_div(a0: u256, a1: u256, a2: u256): u256;
 #[native_interface]
    native public fun checked_mul(a0: u256, a1: u256): u256;
 #[native_interface]
    native public fun is_safe_mul(a0: u256, a1: u256): bool;

}

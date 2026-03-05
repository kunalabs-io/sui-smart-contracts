module math::u64 {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun mul_div(a0: u64, a1: u64, a2: u64): u64;

}

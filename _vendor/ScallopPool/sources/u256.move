module scallop_pool::u256 {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun mul_div(a0: u256, a1: u256, a2: u256): u256;
    native public fun checked_mul(a0: u256, a1: u256): u256;
    native public fun is_safe_mul(a0: u256, a1: u256): bool;

}

module 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::u128 {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun mul_div(a0: u128, a1: u128, a2: u128): u128;
    native public fun checked_mul(a0: u128, a1: u128): u128;
    native public fun is_safe_mul(a0: u128, a1: u128): bool;

}

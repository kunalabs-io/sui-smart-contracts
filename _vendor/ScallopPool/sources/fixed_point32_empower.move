module 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::fixed_point32_empower {

    use 0x1::fixed_point32;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun add(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): fixed_point32::FixedPoint32;
    native public fun sub(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): fixed_point32::FixedPoint32;
    native public fun div(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): fixed_point32::FixedPoint32;
    native public fun mul(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): fixed_point32::FixedPoint32;
    native public fun from_u64(a0: u64): fixed_point32::FixedPoint32;
    native public fun zero(): fixed_point32::FixedPoint32;
    native public fun gt(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): bool;
    native public fun gte(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): bool;

}

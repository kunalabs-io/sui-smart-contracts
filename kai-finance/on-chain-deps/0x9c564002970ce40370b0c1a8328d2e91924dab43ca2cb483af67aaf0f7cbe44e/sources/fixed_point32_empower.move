module 0x9C564002970CE40370B0C1A8328D2E91924DAB43CA2CB483AF67AAF0F7CBE44E::fixed_point32_empower {

    use 0x1::fixed_point32;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun add(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): fixed_point32::FixedPoint32;
 #[native_interface]
    native public fun sub(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): fixed_point32::FixedPoint32;
 #[native_interface]
    native public fun div(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): fixed_point32::FixedPoint32;
 #[native_interface]
    native public fun mul(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): fixed_point32::FixedPoint32;
 #[native_interface]
    native public fun from_u64(a0: u64): fixed_point32::FixedPoint32;
 #[native_interface]
    native public fun zero(): fixed_point32::FixedPoint32;
 #[native_interface]
    native public fun gt(a0: fixed_point32::FixedPoint32, a1: fixed_point32::FixedPoint32): bool;

}

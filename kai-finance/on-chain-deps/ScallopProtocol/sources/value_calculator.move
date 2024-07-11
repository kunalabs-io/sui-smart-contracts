module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::value_calculator {

    use 0x1::fixed_point32;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun usd_value(a0: fixed_point32::FixedPoint32, a1: u64, a2: u8): fixed_point32::FixedPoint32;

}

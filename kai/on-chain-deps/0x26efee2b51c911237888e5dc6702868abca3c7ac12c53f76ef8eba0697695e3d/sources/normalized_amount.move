module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::normalized_amount {

    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::normalized_amount;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::cursor;

    struct NormalizedAmount has copy, drop, store {
        value: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun max_decimals(): u8;
 #[native_interface]
    native public fun cap_decimals(a0: u8): u8;
 #[native_interface]
    native public fun default(): normalized_amount::NormalizedAmount;
 #[native_interface]
    native public fun value(a0: &normalized_amount::NormalizedAmount): u64;
 #[native_interface]
    native public fun to_u256(a0: normalized_amount::NormalizedAmount): u256;
 #[native_interface]
    native public fun from_raw(a0: u64, a1: u8): normalized_amount::NormalizedAmount;
 #[native_interface]
    native public fun to_raw(a0: normalized_amount::NormalizedAmount, a1: u8): u64;
 #[native_interface]
    native public fun to_bytes(a0: normalized_amount::NormalizedAmount): vector<u8>;
 #[native_interface]
    native public fun take_bytes(a0: &mut cursor::Cursor<u8>): normalized_amount::NormalizedAmount;

}

module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes {

    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::cursor;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun push_u8(a0: &mut vector<u8>, a1: u8);
 #[native_interface]
    native public fun push_u16_be(a0: &mut vector<u8>, a1: u16);
 #[native_interface]
    native public fun push_u32_be(a0: &mut vector<u8>, a1: u32);
 #[native_interface]
    native public fun push_u64_be(a0: &mut vector<u8>, a1: u64);
 #[native_interface]
    native public fun push_u128_be(a0: &mut vector<u8>, a1: u128);
 #[native_interface]
    native public fun push_u256_be(a0: &mut vector<u8>, a1: u256);
 #[native_interface]
    native public fun take_u8(a0: &mut cursor::Cursor<u8>): u8;
 #[native_interface]
    native public fun take_u16_be(a0: &mut cursor::Cursor<u8>): u16;
 #[native_interface]
    native public fun take_u32_be(a0: &mut cursor::Cursor<u8>): u32;
 #[native_interface]
    native public fun take_u64_be(a0: &mut cursor::Cursor<u8>): u64;
 #[native_interface]
    native public fun take_u128_be(a0: &mut cursor::Cursor<u8>): u128;
 #[native_interface]
    native public fun take_u256_be(a0: &mut cursor::Cursor<u8>): u256;
 #[native_interface]
    native public fun take_bytes(a0: &mut cursor::Cursor<u8>, a1: u64): vector<u8>;

}

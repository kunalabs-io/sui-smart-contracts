module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes20 {

    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes20;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::cursor;

    struct Bytes20 has copy, drop, store {
        data: vector<u8>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun length(): u64;
 #[native_interface]
    native public fun new(a0: vector<u8>): bytes20::Bytes20;
 #[native_interface]
    native public fun default(): bytes20::Bytes20;
 #[native_interface]
    native public fun data(a0: &bytes20::Bytes20): vector<u8>;
 #[native_interface]
    native public fun from_bytes(a0: vector<u8>): bytes20::Bytes20;
 #[native_interface]
    native public fun to_bytes(a0: bytes20::Bytes20): vector<u8>;
 #[native_interface]
    native public fun take(a0: &mut cursor::Cursor<u8>): bytes20::Bytes20;
 #[native_interface]
    native public fun is_nonzero(a0: &bytes20::Bytes20): bool;

}

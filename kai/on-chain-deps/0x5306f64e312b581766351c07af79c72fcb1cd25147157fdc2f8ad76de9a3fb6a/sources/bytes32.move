module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32 {

    use 0x1::string;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::cursor;

    struct Bytes32 has copy, drop, store {
        data: vector<u8>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun length(): u64;
 #[native_interface]
    native public fun new(a0: vector<u8>): bytes32::Bytes32;
 #[native_interface]
    native public fun default(): bytes32::Bytes32;
 #[native_interface]
    native public fun data(a0: &bytes32::Bytes32): vector<u8>;
 #[native_interface]
    native public fun from_u256_be(a0: u256): bytes32::Bytes32;
 #[native_interface]
    native public fun to_u256_be(a0: bytes32::Bytes32): u256;
 #[native_interface]
    native public fun from_u64_be(a0: u64): bytes32::Bytes32;
 #[native_interface]
    native public fun to_u64_be(a0: bytes32::Bytes32): u64;
 #[native_interface]
    native public fun from_bytes(a0: vector<u8>): bytes32::Bytes32;
 #[native_interface]
    native public fun to_bytes(a0: bytes32::Bytes32): vector<u8>;
 #[native_interface]
    native public fun take_bytes(a0: &mut cursor::Cursor<u8>): bytes32::Bytes32;
 #[native_interface]
    native public fun to_address(a0: bytes32::Bytes32): address;
 #[native_interface]
    native public fun from_address(a0: address): bytes32::Bytes32;
 #[native_interface]
    native public fun from_utf8(a0: string::String): bytes32::Bytes32;
 #[native_interface]
    native public fun to_utf8(a0: bytes32::Bytes32): string::String;
 #[native_interface]
    native public fun is_nonzero(a0: &bytes32::Bytes32): bool;

}

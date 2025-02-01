module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address {

    use sui::object;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::cursor;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;

    struct ExternalAddress has copy, drop, store {
        value: bytes32::Bytes32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: bytes32::Bytes32): external_address::ExternalAddress;
 #[native_interface]
    native public fun default(): external_address::ExternalAddress;
 #[native_interface]
    native public fun new_nonzero(a0: bytes32::Bytes32): external_address::ExternalAddress;
 #[native_interface]
    native public fun to_bytes(a0: external_address::ExternalAddress): vector<u8>;
 #[native_interface]
    native public fun to_bytes32(a0: external_address::ExternalAddress): bytes32::Bytes32;
 #[native_interface]
    native public fun take_bytes(a0: &mut cursor::Cursor<u8>): external_address::ExternalAddress;
 #[native_interface]
    native public fun take_nonzero(a0: &mut cursor::Cursor<u8>): external_address::ExternalAddress;
 #[native_interface]
    native public fun to_address(a0: external_address::ExternalAddress): address;
 #[native_interface]
    native public fun from_address(a0: address): external_address::ExternalAddress;
 #[native_interface]
    native public fun from_id(a0: object::ID): external_address::ExternalAddress;
 #[native_interface]
    native public fun is_nonzero(a0: &external_address::ExternalAddress): bool;

}

module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian_signature {

    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian_signature;

    struct GuardianSignature has drop, store {
        r: bytes32::Bytes32,
        s: bytes32::Bytes32,
        recovery_id: u8,
        index: u8,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: bytes32::Bytes32, a1: bytes32::Bytes32, a2: u8, a3: u8): guardian_signature::GuardianSignature;
 #[native_interface]
    native public fun r(a0: &guardian_signature::GuardianSignature): bytes32::Bytes32;
 #[native_interface]
    native public fun s(a0: &guardian_signature::GuardianSignature): bytes32::Bytes32;
 #[native_interface]
    native public fun recovery_id(a0: &guardian_signature::GuardianSignature): u8;
 #[native_interface]
    native public fun index(a0: &guardian_signature::GuardianSignature): u8;
 #[native_interface]
    native public fun index_as_u64(a0: &guardian_signature::GuardianSignature): u64;
 #[native_interface]
    native public fun to_rsv(a0: guardian_signature::GuardianSignature): vector<u8>;

}

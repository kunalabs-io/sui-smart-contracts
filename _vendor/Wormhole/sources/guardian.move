module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian {

    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes20;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian_signature;

    struct Guardian has store {
        pubkey: bytes20::Bytes20,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: vector<u8>): guardian::Guardian;
 #[native_interface]
    native public fun pubkey(a0: &guardian::Guardian): bytes20::Bytes20;
 #[native_interface]
    native public fun as_bytes(a0: &guardian::Guardian): vector<u8>;
 #[native_interface]
    native public fun verify(a0: &guardian::Guardian, a1: guardian_signature::GuardianSignature, a2: vector<u8>): bool;

}

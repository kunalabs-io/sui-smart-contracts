module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::consumed_vaas {

    use sui::tx_context;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::consumed_vaas;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::set;

    struct ConsumedVAAs has store {
        hashes: set::Set<bytes32::Bytes32>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: &mut tx_context::TxContext): consumed_vaas::ConsumedVAAs;
 #[native_interface]
    native public fun consume(a0: &mut consumed_vaas::ConsumedVAAs, a1: bytes32::Bytes32);

}

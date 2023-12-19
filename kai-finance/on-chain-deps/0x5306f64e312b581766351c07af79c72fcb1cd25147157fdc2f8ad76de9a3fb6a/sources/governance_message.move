module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message {

    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::consumed_vaas;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::vaa;

    struct DecreeTicket<phantom T0> {
        governance_chain: u16,
        governance_contract: external_address::ExternalAddress,
        module_name: bytes32::Bytes32,
        action: u8,
        global: bool,
    }
    struct DecreeReceipt<phantom T0> {
        payload: vector<u8>,
        digest: bytes32::Bytes32,
        sequence: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun authorize_verify_global<T0: drop>(a0: T0, a1: u16, a2: external_address::ExternalAddress, a3: bytes32::Bytes32, a4: u8): governance_message::DecreeTicket<T0>;
 #[native_interface]
    native public fun authorize_verify_local<T0: drop>(a0: T0, a1: u16, a2: external_address::ExternalAddress, a3: bytes32::Bytes32, a4: u8): governance_message::DecreeTicket<T0>;
 #[native_interface]
    native public fun sequence<T0>(a0: &governance_message::DecreeReceipt<T0>): u64;
 #[native_interface]
    native public fun take_payload<T0>(a0: &mut consumed_vaas::ConsumedVAAs, a1: governance_message::DecreeReceipt<T0>): vector<u8>;
 #[native_interface]
    native public fun payload<T0>(a0: &governance_message::DecreeReceipt<T0>): vector<u8>;
 #[native_interface]
    native public fun destroy<T0>(a0: governance_message::DecreeReceipt<T0>);
 #[native_interface]
    native public fun verify_vaa<T0>(a0: &state::State, a1: vaa::VAA, a2: governance_message::DecreeTicket<T0>): governance_message::DecreeReceipt<T0>;

}

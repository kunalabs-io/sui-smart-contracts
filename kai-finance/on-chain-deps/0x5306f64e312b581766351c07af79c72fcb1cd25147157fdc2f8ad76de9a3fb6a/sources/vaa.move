module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::vaa {

    use sui::clock;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::consumed_vaas;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::vaa;

    struct VAA {
        guardian_set_index: u32,
        timestamp: u32,
        nonce: u32,
        emitter_chain: u16,
        emitter_address: external_address::ExternalAddress,
        sequence: u64,
        consistency_level: u8,
        payload: vector<u8>,
        digest: bytes32::Bytes32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun guardian_set_index(a0: &vaa::VAA): u32;
 #[native_interface]
    native public fun timestamp(a0: &vaa::VAA): u32;
 #[native_interface]
    native public fun nonce(a0: &vaa::VAA): u32;
 #[native_interface]
    native public fun batch_id(a0: &vaa::VAA): u32;
 #[native_interface]
    native public fun payload(a0: &vaa::VAA): vector<u8>;
 #[native_interface]
    native public fun digest(a0: &vaa::VAA): bytes32::Bytes32;
 #[native_interface]
    native public fun emitter_chain(a0: &vaa::VAA): u16;
 #[native_interface]
    native public fun emitter_address(a0: &vaa::VAA): external_address::ExternalAddress;
 #[native_interface]
    native public fun emitter_info(a0: &vaa::VAA): (u16, external_address::ExternalAddress, u64);
 #[native_interface]
    native public fun sequence(a0: &vaa::VAA): u64;
 #[native_interface]
    native public fun consistency_level(a0: &vaa::VAA): u8;
 #[native_interface]
    native public fun finality(a0: &vaa::VAA): u8;
 #[native_interface]
    native public fun take_payload(a0: vaa::VAA): vector<u8>;
 #[native_interface]
    native public fun take_emitter_info_and_payload(a0: vaa::VAA): (u16, external_address::ExternalAddress, vector<u8>);
 #[native_interface]
    native public fun parse_and_verify(a0: &state::State, a1: vector<u8>, a2: &clock::Clock): vaa::VAA;
 #[native_interface]
    native public fun consume(a0: &mut consumed_vaas::ConsumedVAAs, a1: &vaa::VAA);
 #[native_interface]
    native public fun compute_message_hash(a0: &vaa::VAA): bytes32::Bytes32;

}

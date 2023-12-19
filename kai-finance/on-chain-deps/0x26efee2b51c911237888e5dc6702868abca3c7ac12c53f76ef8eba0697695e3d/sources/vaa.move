module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::vaa {

    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer_with_payload;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::create_wrapped;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::state;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::vaa as vaa_1;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::vaa;

    friend complete_transfer;
    friend complete_transfer_with_payload;
    friend create_wrapped;

    struct TokenBridgeMessage {
        emitter_chain: u16,
        emitter_address: external_address::ExternalAddress,
        sequence: u64,
        payload: vector<u8>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun verify_only_once(a0: &mut state::State, a1: vaa::VAA): vaa_1::TokenBridgeMessage;
 #[native_interface]
    native public fun emitter_chain(a0: &vaa_1::TokenBridgeMessage): u16;
 #[native_interface]
    native public fun emitter_address(a0: &vaa_1::TokenBridgeMessage): external_address::ExternalAddress;
 #[native_interface]
    native public fun sequence(a0: &vaa_1::TokenBridgeMessage): u64;
 #[native_interface]
    native public(friend) fun take_payload(a0: vaa_1::TokenBridgeMessage): vector<u8>;

}

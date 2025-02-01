module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer_with_payload {

    use sui::coin;
    use sui::tx_context;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer_with_payload;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::state;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_with_payload;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::vaa;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::emitter;

    struct RedeemerReceipt<phantom T0> {
        source_chain: u16,
        parsed: transfer_with_payload::TransferWithPayload,
        bridged_out: coin::Coin<T0>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun authorize_transfer<T0>(a0: &mut state::State, a1: vaa::TokenBridgeMessage, a2: &mut tx_context::TxContext): complete_transfer_with_payload::RedeemerReceipt<T0>;
 #[native_interface]
    native public fun redeem_coin<T0>(a0: &emitter::EmitterCap, a1: complete_transfer_with_payload::RedeemerReceipt<T0>): (coin::Coin<T0>, transfer_with_payload::TransferWithPayload, u16);

}

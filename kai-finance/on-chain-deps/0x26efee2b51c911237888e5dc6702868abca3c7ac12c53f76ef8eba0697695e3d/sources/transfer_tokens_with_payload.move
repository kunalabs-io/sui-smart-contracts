module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_tokens_with_payload {

    use sui::balance;
    use sui::coin;
    use sui::object;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::normalized_amount;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::state;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::token_registry;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_tokens_with_payload;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::emitter;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::publish_message;

    struct TransferTicket<phantom T0> {
        asset_info: token_registry::VerifiedAsset<T0>,
        bridged_in: balance::Balance<T0>,
        norm_amount: normalized_amount::NormalizedAmount,
        sender: object::ID,
        redeemer_chain: u16,
        redeemer: vector<u8>,
        payload: vector<u8>,
        nonce: u32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun prepare_transfer<T0>(a0: &emitter::EmitterCap, a1: token_registry::VerifiedAsset<T0>, a2: coin::Coin<T0>, a3: u16, a4: vector<u8>, a5: vector<u8>, a6: u32): (transfer_tokens_with_payload::TransferTicket<T0>, coin::Coin<T0>);
 #[native_interface]
    native public fun transfer_tokens_with_payload<T0>(a0: &mut state::State, a1: transfer_tokens_with_payload::TransferTicket<T0>): publish_message::MessageTicket;

}

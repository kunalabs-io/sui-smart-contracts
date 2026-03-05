module token_bridge::transfer_tokens_with_payload {

    use sui::balance;
    use sui::coin;
    use sui::object;
    use token_bridge::normalized_amount;
    use token_bridge::state;
    use token_bridge::token_registry;
    use token_bridge::transfer_tokens_with_payload;
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

module token_bridge::transfer_tokens {

    use sui::balance;
    use sui::coin;
    use token_bridge::normalized_amount;
    use token_bridge::state;
    use token_bridge::token_registry;
    use token_bridge::transfer_tokens;
    use token_bridge::transfer_tokens_with_payload;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::publish_message;

    friend transfer_tokens_with_payload;

    struct TransferTicket<phantom T0> {
        asset_info: token_registry::VerifiedAsset<T0>,
        bridged_in: balance::Balance<T0>,
        norm_amount: normalized_amount::NormalizedAmount,
        recipient_chain: u16,
        recipient: vector<u8>,
        relayer_fee: u64,
        nonce: u32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun prepare_transfer<T0>(a0: token_registry::VerifiedAsset<T0>, a1: coin::Coin<T0>, a2: u16, a3: vector<u8>, a4: u64, a5: u32): (transfer_tokens::TransferTicket<T0>, coin::Coin<T0>);
 #[native_interface]
    native public fun transfer_tokens<T0>(a0: &mut state::State, a1: transfer_tokens::TransferTicket<T0>): publish_message::MessageTicket;
 #[native_interface]
    native public(friend) fun take_truncated_amount<T0>(a0: &token_registry::VerifiedAsset<T0>, a1: &mut coin::Coin<T0>): (balance::Balance<T0>, normalized_amount::NormalizedAmount);
 #[native_interface]
    native public(friend) fun burn_or_deposit_funds<T0>(a0: &state::LatestOnly, a1: &mut state::State, a2: &token_registry::VerifiedAsset<T0>, a3: balance::Balance<T0>): (u16, external_address::ExternalAddress);

}

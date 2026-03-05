module token_bridge::complete_transfer {

    use sui::balance;
    use sui::coin;
    use sui::tx_context;
    use token_bridge::complete_transfer;
    use token_bridge::complete_transfer_with_payload;
    use token_bridge::normalized_amount;
    use token_bridge::state;
    use token_bridge::token_registry;
    use token_bridge::vaa;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;

    friend complete_transfer_with_payload;

    struct TransferRedeemed has copy, drop {
        emitter_chain: u16,
        emitter_address: external_address::ExternalAddress,
        sequence: u64,
    }
    struct RelayerReceipt<phantom T0> {
        payout: coin::Coin<T0>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun authorize_transfer<T0>(a0: &mut state::State, a1: vaa::TokenBridgeMessage, a2: &mut tx_context::TxContext): complete_transfer::RelayerReceipt<T0>;
 #[native_interface]
    native public fun redeem_relayer_payout<T0>(a0: complete_transfer::RelayerReceipt<T0>): coin::Coin<T0>;
 #[native_interface]
    native public(friend) fun verify_and_bridge_out<T0>(a0: &state::LatestOnly, a1: &mut state::State, a2: u16, a3: external_address::ExternalAddress, a4: u16, a5: normalized_amount::NormalizedAmount): (token_registry::VerifiedAsset<T0>, balance::Balance<T0>);
 #[native_interface]
    native public(friend) fun emit_transfer_redeemed(a0: &vaa::TokenBridgeMessage): u16;

}

module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer {

    use sui::balance;
    use sui::coin;
    use sui::tx_context;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer_with_payload;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::normalized_amount;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::state;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::token_registry;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::vaa;
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

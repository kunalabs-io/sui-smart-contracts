module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::create_wrapped {

    use sui::coin;
    use sui::object;
    use sui::package;
    use sui::tx_context;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::create_wrapped;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::state;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::vaa;

    struct WrappedAssetSetup<phantom T0, phantom T1> has store, key {
        id: object::UID,
        treasury_cap: coin::TreasuryCap<T0>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun prepare_registration<T0: drop, T1>(a0: T0, a1: u8, a2: &mut tx_context::TxContext): create_wrapped::WrappedAssetSetup<T0, T1>;
 #[native_interface]
    native public fun complete_registration<T0: drop, T1>(a0: &mut state::State, a1: &mut coin::CoinMetadata<T0>, a2: create_wrapped::WrappedAssetSetup<T0, T1>, a3: package::UpgradeCap, a4: vaa::TokenBridgeMessage);
 #[native_interface]
    native public fun update_attestation<T0>(a0: &mut state::State, a1: &mut coin::CoinMetadata<T0>, a2: vaa::TokenBridgeMessage);
 #[native_interface]
    native public fun incomplete_metadata<T0>(a0: &coin::CoinMetadata<T0>): bool;

}

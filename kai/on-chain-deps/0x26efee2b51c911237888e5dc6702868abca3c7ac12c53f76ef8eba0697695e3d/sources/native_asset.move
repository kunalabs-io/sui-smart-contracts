module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::native_asset {

    use sui::balance;
    use sui::coin;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::complete_transfer;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::native_asset;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::token_registry;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::transfer_tokens;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;

    friend complete_transfer;
    friend token_registry;
    friend transfer_tokens;

    struct NativeAsset<phantom T0> has store {
        custody: balance::Balance<T0>,
        token_address: external_address::ExternalAddress,
        decimals: u8,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun canonical_address<T0>(a0: &coin::CoinMetadata<T0>): external_address::ExternalAddress;
 #[native_interface]
    native public(friend) fun new<T0>(a0: &coin::CoinMetadata<T0>): native_asset::NativeAsset<T0>;
 #[native_interface]
    native public fun token_address<T0>(a0: &native_asset::NativeAsset<T0>): external_address::ExternalAddress;
 #[native_interface]
    native public fun decimals<T0>(a0: &native_asset::NativeAsset<T0>): u8;
 #[native_interface]
    native public fun custody<T0>(a0: &native_asset::NativeAsset<T0>): u64;
 #[native_interface]
    native public fun canonical_info<T0>(a0: &native_asset::NativeAsset<T0>): (u16, external_address::ExternalAddress);
 #[native_interface]
    native public(friend) fun deposit<T0>(a0: &mut native_asset::NativeAsset<T0>, a1: balance::Balance<T0>);
 #[native_interface]
    native public(friend) fun withdraw<T0>(a0: &mut native_asset::NativeAsset<T0>, a1: u64): balance::Balance<T0>;

}

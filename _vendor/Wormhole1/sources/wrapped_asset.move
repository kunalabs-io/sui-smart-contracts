module token_bridge::wrapped_asset {

    use 0x1::string;
    use sui::balance;
    use sui::coin;
    use sui::package;
    use token_bridge::asset_meta;
    use token_bridge::complete_transfer;
    use token_bridge::create_wrapped;
    use token_bridge::token_registry;
    use token_bridge::transfer_tokens;
    use token_bridge::wrapped_asset;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;

    friend complete_transfer;
    friend create_wrapped;
    friend token_registry;
    friend transfer_tokens;

    struct ForeignInfo<phantom T0> has store {
        token_chain: u16,
        token_address: external_address::ExternalAddress,
        native_decimals: u8,
        symbol: string::String,
    }
    struct WrappedAsset<phantom T0> has store {
        info: wrapped_asset::ForeignInfo<T0>,
        treasury_cap: coin::TreasuryCap<T0>,
        decimals: u8,
        upgrade_cap: package::UpgradeCap,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun new<T0>(a0: asset_meta::AssetMeta, a1: &mut coin::CoinMetadata<T0>, a2: coin::TreasuryCap<T0>, a3: package::UpgradeCap): wrapped_asset::WrappedAsset<T0>;
 #[native_interface]
    native public(friend) fun update_metadata<T0>(a0: &mut wrapped_asset::WrappedAsset<T0>, a1: &mut coin::CoinMetadata<T0>, a2: asset_meta::AssetMeta);
 #[native_interface]
    native public fun info<T0>(a0: &wrapped_asset::WrappedAsset<T0>): &wrapped_asset::ForeignInfo<T0>;
 #[native_interface]
    native public fun token_chain<T0>(a0: &wrapped_asset::ForeignInfo<T0>): u16;
 #[native_interface]
    native public fun token_address<T0>(a0: &wrapped_asset::ForeignInfo<T0>): external_address::ExternalAddress;
 #[native_interface]
    native public fun native_decimals<T0>(a0: &wrapped_asset::ForeignInfo<T0>): u8;
 #[native_interface]
    native public fun symbol<T0>(a0: &wrapped_asset::ForeignInfo<T0>): string::String;
 #[native_interface]
    native public fun total_supply<T0>(a0: &wrapped_asset::WrappedAsset<T0>): u64;
 #[native_interface]
    native public fun decimals<T0>(a0: &wrapped_asset::WrappedAsset<T0>): u8;
 #[native_interface]
    native public fun canonical_info<T0>(a0: &wrapped_asset::WrappedAsset<T0>): (u16, external_address::ExternalAddress);
 #[native_interface]
    native public(friend) fun burn<T0>(a0: &mut wrapped_asset::WrappedAsset<T0>, a1: balance::Balance<T0>): u64;
 #[native_interface]
    native public(friend) fun mint<T0>(a0: &mut wrapped_asset::WrappedAsset<T0>, a1: u64): balance::Balance<T0>;

}

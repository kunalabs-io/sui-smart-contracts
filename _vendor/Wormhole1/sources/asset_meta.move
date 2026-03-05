module token_bridge::asset_meta {

    use 0x1::string;
    use sui::coin;
    use token_bridge::asset_meta;
    use token_bridge::attest_token;
    use token_bridge::create_wrapped;
    use token_bridge::wrapped_asset;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;

    friend attest_token;
    friend create_wrapped;
    friend wrapped_asset;

    struct AssetMeta {
        token_address: external_address::ExternalAddress,
        token_chain: u16,
        native_decimals: u8,
        symbol: string::String,
        name: string::String,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun from_metadata<T0>(a0: &coin::CoinMetadata<T0>): asset_meta::AssetMeta;
 #[native_interface]
    native public(friend) fun unpack(a0: asset_meta::AssetMeta): (external_address::ExternalAddress, u16, u8, string::String, string::String);
 #[native_interface]
    native public fun token_chain(a0: &asset_meta::AssetMeta): u16;
 #[native_interface]
    native public fun token_address(a0: &asset_meta::AssetMeta): external_address::ExternalAddress;
 #[native_interface]
    native public(friend) fun serialize(a0: asset_meta::AssetMeta): vector<u8>;
 #[native_interface]
    native public(friend) fun deserialize(a0: vector<u8>): asset_meta::AssetMeta;

}

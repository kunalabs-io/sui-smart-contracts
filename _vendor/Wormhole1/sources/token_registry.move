module token_bridge::token_registry {

    use 0x1::ascii;
    use sui::coin;
    use sui::object;
    use sui::package;
    use sui::table;
    use sui::tx_context;
    use token_bridge::asset_meta;
    use token_bridge::attest_token;
    use token_bridge::complete_transfer;
    use token_bridge::create_wrapped;
    use token_bridge::native_asset;
    use token_bridge::state;
    use token_bridge::token_registry;
    use token_bridge::transfer_tokens;
    use token_bridge::wrapped_asset;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;

    friend attest_token;
    friend complete_transfer;
    friend create_wrapped;
    friend state;
    friend transfer_tokens;

    struct TokenRegistry has store, key {
        id: object::UID,
        num_wrapped: u64,
        num_native: u64,
        coin_types: table::Table<token_registry::CoinTypeKey, ascii::String>,
    }
    struct VerifiedAsset<phantom T0> has drop {
        is_wrapped: bool,
        chain: u16,
        addr: external_address::ExternalAddress,
        coin_decimals: u8,
    }
    struct Key<phantom T0> has copy, drop, store {
        dummy_field: bool,
    }
    struct CoinTypeKey has copy, drop, store {
        chain: u16,
        addr: vector<u8>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun new(a0: &mut tx_context::TxContext): token_registry::TokenRegistry;
 #[native_interface]
    native public fun has<T0>(a0: &token_registry::TokenRegistry): bool;
 #[native_interface]
    native public fun assert_has<T0>(a0: &token_registry::TokenRegistry);
 #[native_interface]
    native public fun verified_asset<T0>(a0: &token_registry::TokenRegistry): token_registry::VerifiedAsset<T0>;
 #[native_interface]
    native public fun is_wrapped<T0>(a0: &token_registry::VerifiedAsset<T0>): bool;
 #[native_interface]
    native public fun token_chain<T0>(a0: &token_registry::VerifiedAsset<T0>): u16;
 #[native_interface]
    native public fun token_address<T0>(a0: &token_registry::VerifiedAsset<T0>): external_address::ExternalAddress;
 #[native_interface]
    native public fun coin_decimals<T0>(a0: &token_registry::VerifiedAsset<T0>): u8;
 #[native_interface]
    native public(friend) fun add_new_wrapped<T0>(a0: &mut token_registry::TokenRegistry, a1: asset_meta::AssetMeta, a2: &mut coin::CoinMetadata<T0>, a3: coin::TreasuryCap<T0>, a4: package::UpgradeCap): external_address::ExternalAddress;
 #[native_interface]
    native public(friend) fun add_new_native<T0>(a0: &mut token_registry::TokenRegistry, a1: &coin::CoinMetadata<T0>): external_address::ExternalAddress;
 #[native_interface]
    native public fun borrow_wrapped<T0>(a0: &token_registry::TokenRegistry): &wrapped_asset::WrappedAsset<T0>;
 #[native_interface]
    native public(friend) fun borrow_mut_wrapped<T0>(a0: &mut token_registry::TokenRegistry): &mut wrapped_asset::WrappedAsset<T0>;
 #[native_interface]
    native public fun borrow_native<T0>(a0: &token_registry::TokenRegistry): &native_asset::NativeAsset<T0>;
 #[native_interface]
    native public(friend) fun borrow_mut_native<T0>(a0: &mut token_registry::TokenRegistry): &mut native_asset::NativeAsset<T0>;

}

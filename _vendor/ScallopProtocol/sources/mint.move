module scallop_protocol::mint {

    use 0x1::type_name;
    use sui::clock;
    use sui::coin;
    use sui::tx_context;
    use scallop_protocol::market;
    use scallop_protocol::reserve;
    use scallop_protocol::version;

    struct MintEvent has copy, drop {
        minter: address,
        deposit_asset: type_name::TypeName,
        deposit_amount: u64,
        mint_asset: type_name::TypeName,
        mint_amount: u64,
        time: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public entry fun mint_entry<T0>(a0: &version::Version, a1: &mut market::Market, a2: coin::Coin<T0>, a3: &clock::Clock, a4: &mut tx_context::TxContext);
 #[native_interface]
    native public fun mint<T0>(a0: &version::Version, a1: &mut market::Market, a2: coin::Coin<T0>, a3: &clock::Clock, a4: &mut tx_context::TxContext): coin::Coin<reserve::MarketCoin<T0>>;

}

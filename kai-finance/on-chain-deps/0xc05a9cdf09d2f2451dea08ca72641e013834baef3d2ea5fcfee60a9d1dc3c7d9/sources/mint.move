module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::mint {

    use 0x1::type_name;
    use sui::clock;
    use sui::coin;
    use sui::tx_context;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::reserve;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

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

module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::liquidate {

    use 0x1::type_name;
    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle;
    use 0xCA5A5A62F01C79A104BF4D31669E29DAA387F325C241DE4EDBE30986A9BC8B0D::coin_decimals_registry;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

    struct LiquidateEvent has copy, drop {
        liquidator: address,
        obligation: object::ID,
        debt_type: type_name::TypeName,
        collateral_type: type_name::TypeName,
        repay_on_behalf: u64,
        repay_revenue: u64,
        liq_amount: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun liquidate_entry<T0, T1>(a0: &version::Version, a1: &mut obligation::Obligation, a2: &mut market::Market, a3: coin::Coin<T0>, a4: &coin_decimals_registry::CoinDecimalsRegistry, a5: &x_oracle::XOracle, a6: &clock::Clock, a7: &mut tx_context::TxContext);
    native public fun liquidate<T0, T1>(a0: &version::Version, a1: &mut obligation::Obligation, a2: &mut market::Market, a3: coin::Coin<T0>, a4: &coin_decimals_registry::CoinDecimalsRegistry, a5: &x_oracle::XOracle, a6: &clock::Clock, a7: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T1>);

}

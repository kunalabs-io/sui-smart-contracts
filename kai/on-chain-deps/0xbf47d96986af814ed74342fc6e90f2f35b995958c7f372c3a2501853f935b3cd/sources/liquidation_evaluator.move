module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::liquidation_evaluator {

    use sui::clock;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle;
    use 0xCA5A5A62F01C79A104BF4D31669E29DAA387F325C241DE4EDBE30986A9BC8B0D::coin_decimals_registry;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun liquidation_amounts<T0, T1>(a0: &obligation::Obligation, a1: &market::Market, a2: &coin_decimals_registry::CoinDecimalsRegistry, a3: u64, a4: &x_oracle::XOracle, a5: &clock::Clock): (u64, u64, u64);
    native public fun max_liquidation_amounts<T0, T1>(a0: &obligation::Obligation, a1: &market::Market, a2: &coin_decimals_registry::CoinDecimalsRegistry, a3: &x_oracle::XOracle, a4: &clock::Clock): (u64, u64);

}

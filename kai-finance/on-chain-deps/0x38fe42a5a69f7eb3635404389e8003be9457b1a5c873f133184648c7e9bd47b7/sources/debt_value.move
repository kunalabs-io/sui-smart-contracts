module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::debt_value {

    use 0x1::fixed_point32;
    use sui::clock;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle;
    use 0xCA5A5A62F01C79A104BF4D31669E29DAA387F325C241DE4EDBE30986A9BC8B0D::coin_decimals_registry;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun debts_value_usd(a0: &obligation::Obligation, a1: &coin_decimals_registry::CoinDecimalsRegistry, a2: &x_oracle::XOracle, a3: &clock::Clock): fixed_point32::FixedPoint32;
    native public fun debts_value_usd_with_weight(a0: &obligation::Obligation, a1: &coin_decimals_registry::CoinDecimalsRegistry, a2: &market::Market, a3: &x_oracle::XOracle, a4: &clock::Clock): fixed_point32::FixedPoint32;

}

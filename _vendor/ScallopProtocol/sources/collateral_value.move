module scallop_protocol::collateral_value {

    use 0x1::fixed_point32;
    use sui::clock;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle;
    use 0xCA5A5A62F01C79A104BF4D31669E29DAA387F325C241DE4EDBE30986A9BC8B0D::coin_decimals_registry;
    use scallop_protocol::market;
    use scallop_protocol::obligation;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun collaterals_value_usd_for_borrow(a0: &obligation::Obligation, a1: &market::Market, a2: &coin_decimals_registry::CoinDecimalsRegistry, a3: &x_oracle::XOracle, a4: &clock::Clock): fixed_point32::FixedPoint32;
 #[native_interface]
    native public fun collaterals_value_usd_for_liquidation(a0: &obligation::Obligation, a1: &market::Market, a2: &coin_decimals_registry::CoinDecimalsRegistry, a3: &x_oracle::XOracle, a4: &clock::Clock): fixed_point32::FixedPoint32;

}

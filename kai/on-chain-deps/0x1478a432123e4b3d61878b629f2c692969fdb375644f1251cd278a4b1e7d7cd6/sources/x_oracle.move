module 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle {

    use 0x1::type_name;
    use sui::clock;
    use sui::object;
    use sui::table;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::price_feed;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::price_update_policy;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle;

    struct X_ORACLE has drop {
        dummy_field: bool,
    }
    struct XOracle has key {
        id: object::UID,
        primary_price_update_policy: price_update_policy::PriceUpdatePolicy,
        secondary_price_update_policy: price_update_policy::PriceUpdatePolicy,
        prices: table::Table<type_name::TypeName, price_feed::PriceFeed>,
        ema_prices: table::Table<type_name::TypeName, price_feed::PriceFeed>,
    }
    struct XOraclePolicyCap has store, key {
        id: object::UID,
        primary_price_update_policy_cap: price_update_policy::PriceUpdatePolicyCap,
        secondary_price_update_policy_cap: price_update_policy::PriceUpdatePolicyCap,
    }
    struct XOraclePriceUpdateRequest<phantom T0> {
        primary_price_update_request: price_update_policy::PriceUpdateRequest<T0>,
        secondary_price_update_request: price_update_policy::PriceUpdateRequest<T0>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun prices(a0: &x_oracle::XOracle): &table::Table<type_name::TypeName, price_feed::PriceFeed>;
 #[native_interface]
    native public fun add_primary_price_update_rule<T0: drop>(a0: &mut x_oracle::XOracle, a1: &x_oracle::XOraclePolicyCap);
 #[native_interface]
    native public fun remove_primary_price_update_rule<T0: drop>(a0: &mut x_oracle::XOracle, a1: &x_oracle::XOraclePolicyCap);
 #[native_interface]
    native public fun add_secondary_price_update_rule<T0: drop>(a0: &mut x_oracle::XOracle, a1: &x_oracle::XOraclePolicyCap);
 #[native_interface]
    native public fun remove_secondary_price_update_rule<T0: drop>(a0: &mut x_oracle::XOracle, a1: &x_oracle::XOraclePolicyCap);
 #[native_interface]
    native public fun price_update_request<T0>(a0: &x_oracle::XOracle): x_oracle::XOraclePriceUpdateRequest<T0>;
 #[native_interface]
    native public fun set_primary_price<T0, T1: drop>(a0: T1, a1: &mut x_oracle::XOraclePriceUpdateRequest<T0>, a2: price_feed::PriceFeed);
 #[native_interface]
    native public fun set_secondary_price<T0, T1: drop>(a0: T1, a1: &mut x_oracle::XOraclePriceUpdateRequest<T0>, a2: price_feed::PriceFeed);
 #[native_interface]
    native public fun confirm_price_update_request<T0>(a0: &mut x_oracle::XOracle, a1: x_oracle::XOraclePriceUpdateRequest<T0>, a2: &clock::Clock);

}

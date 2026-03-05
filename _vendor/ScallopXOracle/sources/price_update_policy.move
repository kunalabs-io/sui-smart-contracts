module x_oracle::price_update_policy {

    use 0x1::type_name;
    use sui::object;
    use sui::tx_context;
    use sui::vec_set;
    use x_oracle::price_feed;
    use x_oracle::price_update_policy;

    struct PriceUpdateRequest<phantom T0> {
        for: object::ID,
        receipts: vec_set::VecSet<type_name::TypeName>,
        price_feeds: vector<price_feed::PriceFeed>,
    }
    struct PriceUpdatePolicy has store, key {
        id: object::UID,
        rules: vec_set::VecSet<type_name::TypeName>,
    }
    struct PriceUpdatePolicyCap has store, key {
        id: object::UID,
        for: object::ID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: &mut tx_context::TxContext): (price_update_policy::PriceUpdatePolicy, price_update_policy::PriceUpdatePolicyCap);
 #[native_interface]
    native public fun new_request<T0>(a0: &price_update_policy::PriceUpdatePolicy): price_update_policy::PriceUpdateRequest<T0>;
 #[native_interface]
    native public fun add_rule<T0>(a0: &mut price_update_policy::PriceUpdatePolicy, a1: &price_update_policy::PriceUpdatePolicyCap);
 #[native_interface]
    native public fun remove_rule<T0>(a0: &mut price_update_policy::PriceUpdatePolicy, a1: &price_update_policy::PriceUpdatePolicyCap);
 #[native_interface]
    native public fun add_price_feed<T0, T1: drop>(a0: T1, a1: &mut price_update_policy::PriceUpdateRequest<T0>, a2: price_feed::PriceFeed);
 #[native_interface]
    native public fun confirm_request<T0>(a0: price_update_policy::PriceUpdateRequest<T0>, a1: &price_update_policy::PriceUpdatePolicy): vector<price_feed::PriceFeed>;

}

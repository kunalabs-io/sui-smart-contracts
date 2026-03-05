module x_oracle::price_feed {

    use x_oracle::price_feed;

    struct PriceFeed has copy, drop, store {
        value: u64,
        last_updated: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: u64, a1: u64): price_feed::PriceFeed;
 #[native_interface]
    native public fun value(a0: &price_feed::PriceFeed): u64;
 #[native_interface]
    native public fun decimals(): u8;
 #[native_interface]
    native public fun last_updated(a0: &price_feed::PriceFeed): u64;

}

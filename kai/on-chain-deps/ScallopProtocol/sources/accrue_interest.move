module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::accrue_interest {

    use sui::clock;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun accrue_interest_for_market(a0: &version::Version, a1: &mut market::Market, a2: &clock::Clock);
 #[native_interface]
    native public fun accrue_interest_for_market_and_obligation(a0: &version::Version, a1: &mut market::Market, a2: &mut obligation::Obligation, a3: &clock::Clock);

}

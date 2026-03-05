module scallop_protocol::accrue_interest {

    use sui::clock;
    use scallop_protocol::market;
    use scallop_protocol::obligation;
    use scallop_protocol::version;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun accrue_interest_for_market(a0: &version::Version, a1: &mut market::Market, a2: &clock::Clock);
 #[native_interface]
    native public fun accrue_interest_for_market_and_obligation(a0: &version::Version, a1: &mut market::Market, a2: &mut obligation::Obligation, a3: &clock::Clock);

}

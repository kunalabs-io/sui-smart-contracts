module token_bridge::attest_token {

    use sui::coin;
    use token_bridge::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::publish_message;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun attest_token<T0>(a0: &mut state::State, a1: &coin::CoinMetadata<T0>, a2: u32): publish_message::MessageTicket;

}

module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::utils {

    use sui::coin;
    use sui::tx_context;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun merge_coins<T0>(a0: vector<coin::Coin<T0>>, a1: &mut tx_context::TxContext): coin::Coin<T0>;
    native public fun send_coin<T0>(a0: coin::Coin<T0>, a1: address);
    native public fun transfer_coin_to_sender<T0>(a0: coin::Coin<T0>, a1: &tx_context::TxContext);

}

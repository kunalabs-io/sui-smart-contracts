module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::router {

    use sui::clock;
    use sui::coin;
    use sui::tx_context;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool;
    use 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::router;

    struct CalculatedRouterSwapResult has copy, drop, store {
        amount_in: u64,
        amount_medium: u64,
        amount_out: u64,
        is_exceed: bool,
        current_sqrt_price_ab: u128,
        current_sqrt_price_cd: u128,
        target_sqrt_price_ab: u128,
        target_sqrt_price_cd: u128,
    }
    struct CalculatedRouterSwapResultEvent has copy, drop, store {
        data: router::CalculatedRouterSwapResult,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    public native fun swap<T0, T1>(
        global_config: &config::GlobalConfig,
        pool: &mut pool::Pool<T0, T1>,
        coin1: coin::Coin<T0>,
        coin2: coin::Coin<T1>,
        bool1: bool,
        bool2: bool,
        u64: u64,
        u128: u128,
        bool3: bool,
        clock: &clock::Clock,
        a10: &mut tx_context::TxContext,
    ): (coin::Coin<T0>, coin::Coin<T1>);
    native public fun swap_ab_bc<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut pool::Pool<T1, T2>, a3: coin::Coin<T0>, a4: coin::Coin<T2>, a5: bool, a6: u64, a7: u64, a8: u128, a9: u128, a10: &clock::Clock, a11: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T2>);
    native public fun swap_ab_cb<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut pool::Pool<T2, T1>, a3: coin::Coin<T0>, a4: coin::Coin<T2>, a5: bool, a6: u64, a7: u64, a8: u128, a9: u128, a10: &clock::Clock, a11: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T2>);
    native public fun swap_ba_bc<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T1, T0>, a2: &mut pool::Pool<T1, T2>, a3: coin::Coin<T0>, a4: coin::Coin<T2>, a5: bool, a6: u64, a7: u64, a8: u128, a9: u128, a10: &clock::Clock, a11: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T2>);
    native public fun swap_ba_cb<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T1, T0>, a2: &mut pool::Pool<T2, T1>, a3: coin::Coin<T0>, a4: coin::Coin<T2>, a5: bool, a6: u64, a7: u64, a8: u128, a9: u128, a10: &clock::Clock, a11: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T2>);
    native public fun calculate_router_swap_result<T0, T1, T2, T3>(a0: &mut pool::Pool<T0, T1>, a1: &mut pool::Pool<T2, T3>, a2: bool, a3: bool, a4: bool, a5: u64);
    native public fun check_coin_threshold<T0>(a0: &coin::Coin<T0>, a1: u64);

}

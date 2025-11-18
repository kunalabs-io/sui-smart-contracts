module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::router_with_partner {

    use sui::clock;
    use sui::coin;
    use sui::tx_context;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::partner;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun swap_with_partner<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut partner::Partner, a3: coin::Coin<T0>, a4: coin::Coin<T1>, a5: bool, a6: bool, a7: u64, a8: u128, a9: bool, a10: &clock::Clock, a11: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T1>);
    native public fun swap_ab_bc_with_partner<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut pool::Pool<T1, T2>, a3: &mut partner::Partner, a4: coin::Coin<T0>, a5: coin::Coin<T2>, a6: bool, a7: u64, a8: u64, a9: u128, a10: u128, a11: &clock::Clock, a12: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T2>);
    native public fun swap_ab_cb_with_partner<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut pool::Pool<T2, T1>, a3: &mut partner::Partner, a4: coin::Coin<T0>, a5: coin::Coin<T2>, a6: bool, a7: u64, a8: u64, a9: u128, a10: u128, a11: &clock::Clock, a12: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T2>);
    native public fun swap_ba_bc_with_partner<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T1, T0>, a2: &mut pool::Pool<T1, T2>, a3: &mut partner::Partner, a4: coin::Coin<T0>, a5: coin::Coin<T2>, a6: bool, a7: u64, a8: u64, a9: u128, a10: u128, a11: &clock::Clock, a12: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T2>);
    native public fun swap_ba_cb_with_partner<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T1, T0>, a2: &mut pool::Pool<T2, T1>, a3: &mut partner::Partner, a4: coin::Coin<T0>, a5: coin::Coin<T2>, a6: bool, a7: u64, a8: u64, a9: u128, a10: u128, a11: &clock::Clock, a12: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T2>);

}

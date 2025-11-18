module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::pool_script_v3 {

    use sui::clock;
    use sui::coin;
    use sui::tx_context;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::position;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::rewarder;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun collect_fee<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: &mut coin::Coin<T0>, a4: &mut coin::Coin<T1>, a5: &mut tx_context::TxContext);
    native public fun collect_reward<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: &mut rewarder::RewarderGlobalVault, a4: &mut coin::Coin<T2>, a5: &clock::Clock, a6: &mut tx_context::TxContext);

}

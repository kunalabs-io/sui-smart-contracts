module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::stable_farming {

    use sui::clock;
    use sui::coin;
    use sui::tx_context;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::config;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::pool as pool_1;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config as config_1;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::rewarder;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun collect_fee<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut pool::Pool<T0, T1>, a3: &pool_1::WrappedPositionNFT, a4: &mut coin::Coin<T0>, a5: &mut coin::Coin<T1>, a6: &mut tx_context::TxContext);
    native public entry fun collect_clmm_reward<T0, T1, T2>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut pool::Pool<T1, T2>, a3: &pool_1::WrappedPositionNFT, a4: &mut rewarder::RewarderGlobalVault, a5: &mut coin::Coin<T0>, a6: &clock::Clock, a7: &mut tx_context::TxContext);

}

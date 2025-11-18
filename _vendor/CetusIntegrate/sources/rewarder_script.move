module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::rewarder_script {

    use sui::coin;
    use sui::tx_context;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::rewarder;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun deposit_reward<T0>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderGlobalVault, a2: vector<coin::Coin<T0>>, a3: u64, a4: &mut tx_context::TxContext);
    native public entry fun emergent_withdraw<T0>(a0: &config::AdminCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderGlobalVault, a3: u64, a4: address, a5: &mut tx_context::TxContext);
    native public entry fun emergent_withdraw_all<T0>(a0: &config::AdminCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderGlobalVault, a3: address, a4: &mut tx_context::TxContext);

}

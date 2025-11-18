module 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::router {

    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::config;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::pool as pool_1;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::rewarder;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config as config_1;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::position;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::rewarder as rewarder_1;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun set_roles(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u128);
    native public entry fun add_role(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u8);
    native public entry fun remove_role(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u8);
    native public entry fun add_operator(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: u128, a3: address, a4: &mut tx_context::TxContext);
    native public entry fun deposit_rewarder<T0>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: vector<coin::Coin<T0>>, a3: u64, a4: &mut tx_context::TxContext);
    native public entry fun emergent_withdraw<T0>(a0: &config::AdminCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: u64, a4: &mut tx_context::TxContext);
    native public entry fun create_rewarder<T0>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: u128, a4: &clock::Clock, a5: &mut tx_context::TxContext);
    native public entry fun update_rewarder<T0>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: u128, a4: &clock::Clock);
    native public entry fun create_pool<T0, T1>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &pool::Pool<T0, T1>, a4: u32, a5: u32, a6: u128, a7: &mut tx_context::TxContext);
    native public entry fun update_effective_tick_range<T0, T1>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool_1::Pool, a4: &pool::Pool<T0, T1>, a5: u32, a6: u32, a7: u128, a8: vector<object::ID>, a9: u64, a10: &clock::Clock);
    native public entry fun add_rewarder<T0>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool_1::Pool, a4: u64, a5: &clock::Clock);
    native public entry fun update_pool_allocate_point<T0>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &pool_1::Pool, a4: u64, a5: &clock::Clock);
    native public entry fun deposit(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool_1::Pool, a3: position::Position, a4: &clock::Clock, a5: &mut tx_context::TxContext);
    native public entry fun withdraw(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool_1::Pool, a3: pool_1::WrappedPositionNFT, a4: &clock::Clock, a5: &tx_context::TxContext);
    native public entry fun harvest<T0>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool_1::Pool, a3: &pool_1::WrappedPositionNFT, a4: &clock::Clock, a5: &mut tx_context::TxContext);
    native public fun accumulated_position_rewards(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool_1::Pool, a3: object::ID, a4: &clock::Clock);
    native public entry fun add_liquidity<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool_1::Pool, a4: &mut pool::Pool<T0, T1>, a5: &mut pool_1::WrappedPositionNFT, a6: coin::Coin<T0>, a7: coin::Coin<T1>, a8: u64, a9: u64, a10: u128, a11: &clock::Clock, a12: &mut tx_context::TxContext);
    native public entry fun add_liquidity_fix_coin<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool_1::Pool, a4: &mut pool::Pool<T0, T1>, a5: &mut pool_1::WrappedPositionNFT, a6: coin::Coin<T0>, a7: coin::Coin<T1>, a8: u64, a9: u64, a10: bool, a11: &clock::Clock, a12: &mut tx_context::TxContext);
    native public entry fun remove_liquidity<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool_1::Pool, a4: &mut pool::Pool<T0, T1>, a5: &mut pool_1::WrappedPositionNFT, a6: u128, a7: u64, a8: u64, a9: &clock::Clock, a10: &mut tx_context::TxContext);
    native public entry fun collect_fee<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut pool::Pool<T0, T1>, a3: &pool_1::WrappedPositionNFT, a4: &mut tx_context::TxContext);
    native public entry fun collect_clmm_reward<T0, T1, T2>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut pool::Pool<T1, T2>, a3: &pool_1::WrappedPositionNFT, a4: &mut rewarder_1::RewarderGlobalVault, a5: coin::Coin<T0>, a6: &clock::Clock, a7: &mut tx_context::TxContext);
    native public fun close_position<T0, T1>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool_1::Pool, a3: &config_1::GlobalConfig, a4: &mut pool::Pool<T0, T1>, a5: pool_1::WrappedPositionNFT, a6: u64, a7: u64, a8: &clock::Clock, a9: &mut tx_context::TxContext);
    native public fun send_coin<T0>(a0: coin::Coin<T0>, a1: address);
    native public fun merge_coins<T0>(a0: vector<coin::Coin<T0>>, a1: &mut tx_context::TxContext): coin::Coin<T0>;

}

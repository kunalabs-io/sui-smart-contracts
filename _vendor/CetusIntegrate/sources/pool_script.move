module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::pool_script {

    use 0x1::string;
    use sui::clock;
    use sui::coin;
    use sui::package;
    use sui::tx_context;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::factory;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::partner;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::position;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::rewarder;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun create_pool<T0, T1>(a0: &config::GlobalConfig, a1: &mut factory::Pools, a2: u32, a3: u128, a4: string::String, a5: &clock::Clock, a6: &mut tx_context::TxContext);
    native public entry fun create_pool_with_liquidity_with_all<T0, T1>(a0: &config::GlobalConfig, a1: &mut factory::Pools, a2: u32, a3: u128, a4: string::String, a5: vector<coin::Coin<T0>>, a6: vector<coin::Coin<T1>>, a7: u32, a8: u32, a9: u64, a10: u64, a11: bool, a12: &clock::Clock, a13: &mut tx_context::TxContext);
    native public entry fun create_pool_with_liquidity_only_a<T0, T1>(a0: &config::GlobalConfig, a1: &mut factory::Pools, a2: u32, a3: u128, a4: string::String, a5: vector<coin::Coin<T0>>, a6: u32, a7: u32, a8: u64, a9: &clock::Clock, a10: &mut tx_context::TxContext);
    native public entry fun create_pool_with_liquidity_only_b<T0, T1>(a0: &config::GlobalConfig, a1: &mut factory::Pools, a2: u32, a3: u128, a4: string::String, a5: vector<coin::Coin<T1>>, a6: u32, a7: u32, a8: u64, a9: &clock::Clock, a10: &mut tx_context::TxContext);
    native public entry fun open_position<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: u32, a3: u32, a4: &mut tx_context::TxContext);
    native public entry fun open_position_with_liquidity_with_all<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: u32, a3: u32, a4: vector<coin::Coin<T0>>, a5: vector<coin::Coin<T1>>, a6: u64, a7: u64, a8: bool, a9: &clock::Clock, a10: &mut tx_context::TxContext);
    native public entry fun open_position_with_liquidity_only_a<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: u32, a3: u32, a4: vector<coin::Coin<T0>>, a5: u64, a6: &clock::Clock, a7: &mut tx_context::TxContext);
    native public entry fun open_position_with_liquidity_only_b<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: u32, a3: u32, a4: vector<coin::Coin<T1>>, a5: u64, a6: &clock::Clock, a7: &mut tx_context::TxContext);
    native public entry fun add_liquidity_with_all<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: vector<coin::Coin<T0>>, a4: vector<coin::Coin<T1>>, a5: u64, a6: u64, a7: u128, a8: &clock::Clock, a9: &mut tx_context::TxContext);
    native public entry fun add_liquidity_only_a<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: vector<coin::Coin<T0>>, a4: u64, a5: u128, a6: &clock::Clock, a7: &mut tx_context::TxContext);
    native public entry fun add_liquidity_only_b<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: vector<coin::Coin<T1>>, a4: u64, a5: u128, a6: &clock::Clock, a7: &mut tx_context::TxContext);
    native public entry fun add_liquidity_fix_coin_with_all<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: vector<coin::Coin<T0>>, a4: vector<coin::Coin<T1>>, a5: u64, a6: u64, a7: bool, a8: &clock::Clock, a9: &mut tx_context::TxContext);
    native public entry fun add_liquidity_fix_coin_only_a<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: vector<coin::Coin<T0>>, a4: u64, a5: &clock::Clock, a6: &mut tx_context::TxContext);
    native public entry fun add_liquidity_fix_coin_only_b<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: vector<coin::Coin<T1>>, a4: u64, a5: &clock::Clock, a6: &mut tx_context::TxContext);
    native public entry fun remove_liquidity<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: u128, a4: u64, a5: u64, a6: &clock::Clock, a7: &mut tx_context::TxContext);
    native public entry fun close_position<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: position::Position, a3: u64, a4: u64, a5: &clock::Clock, a6: &mut tx_context::TxContext);
    native public entry fun collect_fee<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: &mut tx_context::TxContext);
    native public entry fun collect_reward<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut position::Position, a3: &mut rewarder::RewarderGlobalVault, a4: &clock::Clock, a5: &mut tx_context::TxContext);
    native public entry fun collect_protocol_fee<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut tx_context::TxContext);
    native public entry fun swap_a2b<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: vector<coin::Coin<T0>>, a3: bool, a4: u64, a5: u64, a6: u128, a7: &clock::Clock, a8: &mut tx_context::TxContext);
    native public entry fun swap_b2a<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: vector<coin::Coin<T1>>, a3: bool, a4: u64, a5: u64, a6: u128, a7: &clock::Clock, a8: &mut tx_context::TxContext);
    native public entry fun swap_a2b_with_partner<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut partner::Partner, a3: vector<coin::Coin<T0>>, a4: bool, a5: u64, a6: u64, a7: u128, a8: &clock::Clock, a9: &mut tx_context::TxContext);
    native public entry fun swap_b2a_with_partner<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut partner::Partner, a3: vector<coin::Coin<T1>>, a4: bool, a5: u64, a6: u64, a7: u128, a8: &clock::Clock, a9: &mut tx_context::TxContext);
    native public entry fun update_fee_rate<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: u64, a3: &tx_context::TxContext);
    native public entry fun initialize_rewarder<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &mut tx_context::TxContext);
    native public entry fun update_rewarder_emission<T0, T1, T2>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &rewarder::RewarderGlobalVault, a3: u128, a4: &clock::Clock, a5: &mut tx_context::TxContext);
    native public entry fun pause_pool<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &tx_context::TxContext);
    native public entry fun unpause_pool<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: &tx_context::TxContext);
    native public entry fun update_position_url<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: string::String, a3: &tx_context::TxContext);
    native public entry fun set_display<T0, T1>(a0: &config::GlobalConfig, a1: &package::Publisher, a2: string::String, a3: string::String, a4: string::String, a5: string::String, a6: string::String, a7: string::String, a8: &mut tx_context::TxContext);

}

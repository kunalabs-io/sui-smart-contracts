module 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::rewarder {

    use 0x1::type_name;
    use sui::bag;
    use sui::balance;
    use sui::clock;
    use sui::linked_table;
    use sui::object;
    use sui::tx_context;
    use sui::vec_map;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::config;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::pool;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::rewarder;

    friend pool;

    struct PoolRewarderInfo has store {
        allocate_point: u64,
        acc_per_share: u128,
        last_reward_time: u64,
        reward_released: u128,
        reward_harvested: u64,
    }
    struct Rewarder has store {
        reward_coin: type_name::TypeName,
        total_allocate_point: u64,
        emission_per_second: u128,
        last_reward_time: u64,
        total_reward_released: u128,
        total_reward_harvested: u64,
        pools: linked_table::LinkedTable<object::ID, rewarder::PoolRewarderInfo>,
    }
    struct RewarderManager has store, key {
        id: object::UID,
        vault: bag::Bag,
        pool_shares: linked_table::LinkedTable<object::ID, u128>,
        rewarders: linked_table::LinkedTable<type_name::TypeName, rewarder::Rewarder>,
    }
    struct InitRewarderManagerEvent has copy, drop {
        id: object::ID,
    }
    struct CreateRewarderEvent has copy, drop {
        reward_coin: type_name::TypeName,
        emission_per_second: u128,
    }
    struct UpdateRewarderEvent has copy, drop {
        reward_coin: type_name::TypeName,
        emission_per_second: u128,
    }
    struct DepositEvent has copy, drop {
        reward_type: type_name::TypeName,
        deposit_amount: u64,
        after_amount: u64,
    }
    struct EmergentWithdrawEvent has copy, drop, store {
        reward_type: type_name::TypeName,
        withdraw_amount: u64,
        after_amount: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun deposit_rewarder<T0>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: balance::Balance<T0>);
    native public fun emergent_withdraw<T0>(a0: &config::AdminCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: u64): balance::Balance<T0>;
    native public fun create_rewarder<T0>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: u128, a4: &clock::Clock, a5: &mut tx_context::TxContext);
    native public fun update_rewarder<T0>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: u128, a4: &clock::Clock);
    native public(friend) fun register_pool(a0: &mut rewarder::RewarderManager, a1: object::ID);
    native public(friend) fun add_pool<T0>(a0: &mut rewarder::RewarderManager, a1: object::ID, a2: u64, a3: &clock::Clock);
    native public(friend) fun set_pool<T0>(a0: &mut rewarder::RewarderManager, a1: object::ID, a2: u64, a3: &clock::Clock): u128;
    native public(friend) fun pool_rewards_settle(a0: &mut rewarder::RewarderManager, a1: vector<type_name::TypeName>, a2: object::ID, a3: &clock::Clock): vec_map::VecMap<type_name::TypeName, u128>;
    native public(friend) fun set_pool_share(a0: &mut rewarder::RewarderManager, a1: object::ID, a2: u128);
    native public(friend) fun withdraw_reward<T0>(a0: &mut rewarder::RewarderManager, a1: object::ID, a2: u64): balance::Balance<T0>;
    native public fun borrow_rewarder<T0>(a0: &rewarder::RewarderManager): &rewarder::Rewarder;
    native public fun borrow_pool_share(a0: &rewarder::RewarderManager, a1: object::ID): u128;
    native public fun borrow_pool_rewarder_info(a0: &rewarder::Rewarder, a1: object::ID): &rewarder::PoolRewarderInfo;
    native public fun borrow_pool_allocate_point(a0: &rewarder::RewarderManager, a1: type_name::TypeName, a2: object::ID): u64;
    native public fun pool_share(a0: &rewarder::RewarderManager, a1: object::ID): u128;
    native public fun emission_per_second(a0: &rewarder::Rewarder): u128;
    native public fun vault_balance<T0>(a0: &rewarder::RewarderManager): u64;
    native public fun total_allocate_point(a0: &rewarder::Rewarder): u64;
    native public fun last_reward_time(a0: &rewarder::Rewarder): u64;
    native public fun total_reward_released(a0: &rewarder::Rewarder): u128;
    native public fun total_reward_harvested(a0: &rewarder::Rewarder): u64;
    native public fun pool_last_reward_time(a0: &rewarder::PoolRewarderInfo): u64;
    native public fun pool_allocate_point(a0: &rewarder::PoolRewarderInfo): u64;
    native public fun pool_acc_per_share(a0: &rewarder::PoolRewarderInfo): u128;
    native public fun pool_reward_released(a0: &rewarder::PoolRewarderInfo): u128;
    native public fun pool_reward_harvested(a0: &rewarder::PoolRewarderInfo): u64;

}

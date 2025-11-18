module 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::pool {

    use 0x1::option;
    use 0x1::string;
    use 0x1::type_name;
    use sui::balance;
    use sui::clock;
    use sui::coin;
    use sui::linked_table;
    use sui::object;
    use sui::tx_context;
    use sui::vec_map;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::config;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::pool;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::rewarder;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config as config_1;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool as pool_1;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::position;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::rewarder as rewarder_1;
    use 0x714A63A0DBA6DA4F017B42D5D0FB78867F18BCDE904868E51D951A5A6F5B7F57::i32;

    struct POOL has drop {
        dummy_field: bool,
    }
    struct WrappedPositionNFT has store, key {
        id: object::UID,
        pool_id: object::ID,
        clmm_postion: position::Position,
        url: string::String,
    }
    struct PositionRewardInfo has copy, drop, store {
        reward: u128,
        reward_debt: u128,
        reward_harvested: u64,
    }
    struct WrappedPositionInfo has store {
        id: object::ID,
        pool_id: object::ID,
        clmm_pool_id: object::ID,
        clmm_position_id: object::ID,
        tick_lower: i32::I32,
        tick_upper: i32::I32,
        liquidity: u128,
        effective_tick_lower: i32::I32,
        effective_tick_upper: i32::I32,
        sqrt_price: u128,
        share: u128,
        rewards: vec_map::VecMap<type_name::TypeName, pool::PositionRewardInfo>,
    }
    struct Pool has store, key {
        id: object::UID,
        clmm_pool_id: object::ID,
        effective_tick_lower: i32::I32,
        effective_tick_upper: i32::I32,
        sqrt_price: u128,
        total_share: u128,
        rewarders: vector<type_name::TypeName>,
        positions: linked_table::LinkedTable<object::ID, pool::WrappedPositionInfo>,
    }
    struct CreatePoolEvent has copy, drop {
        pool_id: object::ID,
        clmm_pool_id: object::ID,
        sqrt_price: u128,
        effective_tick_lower: i32::I32,
        effective_tick_upper: i32::I32,
    }
    struct UpdateEffectiveTickRangeEvent has copy, drop {
        pool_id: object::ID,
        clmm_pool_id: object::ID,
        effective_tick_lower: i32::I32,
        effective_tick_upper: i32::I32,
        sqrt_price: u128,
        start: vector<object::ID>,
        end: option::Option<object::ID>,
        limit: u64,
    }
    struct AddRewardEvent has copy, drop {
        pool_id: object::ID,
        clmm_pool_id: object::ID,
        rewarder: type_name::TypeName,
        allocate_point: u64,
    }
    struct UpdatePoolAllocatePointEvent has copy, drop {
        pool_id: object::ID,
        clmm_pool_id: object::ID,
        old_allocate_point: u64,
        new_allocate_point: u64,
    }
    struct DepositEvent has copy, drop {
        pool_id: object::ID,
        wrapped_position_id: object::ID,
        clmm_pool_id: object::ID,
        clmm_position_id: object::ID,
        effective_tick_lower: i32::I32,
        effective_tick_upper: i32::I32,
        sqrt_price: u128,
        liquidity: u128,
        share: u128,
        pool_total_share: u128,
    }
    struct WithdrawEvent has copy, drop {
        pool_id: object::ID,
        wrapped_position_id: object::ID,
        clmm_pool_id: object::ID,
        clmm_position_id: object::ID,
        share: u128,
    }
    struct HarvestEvent has copy, drop {
        pool_id: object::ID,
        wrapped_position_id: object::ID,
        clmm_pool_id: object::ID,
        clmm_position_id: object::ID,
        rewarder_type: type_name::TypeName,
        amount: u64,
    }
    struct AccumulatedPositionRewardsEvent has copy, drop {
        pool_id: object::ID,
        wrapped_position_id: object::ID,
        clmm_position_id: object::ID,
        rewards: vec_map::VecMap<type_name::TypeName, u64>,
    }
    struct AddLiquidityEvent has copy, drop {
        pool_id: object::ID,
        wrapped_position_id: object::ID,
        clmm_poo_id: object::ID,
        clmm_position_id: object::ID,
        effective_tick_lower: i32::I32,
        effective_tick_upper: i32::I32,
        sqrt_price: u128,
        old_liquidity: u128,
        new_liquidity: u128,
        old_share: u128,
        new_share: u128,
    }
    struct AddLiquidityFixCoinEvent has copy, drop {
        pool_id: object::ID,
        wrapped_position_id: object::ID,
        clmm_poo_id: object::ID,
        clmm_position_id: object::ID,
        effective_tick_lower: i32::I32,
        effective_tick_upper: i32::I32,
        sqrt_price: u128,
        old_liquidity: u128,
        new_liquidity: u128,
        old_share: u128,
        new_share: u128,
    }
    struct RemoveLiquidityEvent has copy, drop {
        pool_id: object::ID,
        wrapped_position_id: object::ID,
        clmm_poo_id: object::ID,
        clmm_position_id: object::ID,
        effective_tick_lower: i32::I32,
        effective_tick_upper: i32::I32,
        sqrt_price: u128,
        old_liquidity: u128,
        new_liquidity: u128,
        old_share: u128,
        new_share: u128,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun create_pool<T0, T1>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &pool_1::Pool<T0, T1>, a4: i32::I32, a5: i32::I32, a6: u128, a7: &mut tx_context::TxContext);
    native public fun governance_update_effective_tick_range<T0, T1>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool::Pool, a4: &pool_1::Pool<T0, T1>, a5: i32::I32, a6: i32::I32, a7: u128, a8: vector<object::ID>, a9: u64, a10: &clock::Clock): option::Option<object::ID>;
    native public fun update_effective_tick_range<T0, T1>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool::Pool, a4: &pool_1::Pool<T0, T1>, a5: i32::I32, a6: i32::I32, a7: u128, a8: vector<object::ID>, a9: u64, a10: &clock::Clock): option::Option<object::ID>;
    native public fun add_rewarder<T0>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool::Pool, a4: u64, a5: &clock::Clock);
    native public fun update_pool_allocate_point<T0>(a0: &config::OperatorCap, a1: &config::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &pool::Pool, a4: u64, a5: &clock::Clock);
    native public fun deposit(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool::Pool, a3: position::Position, a4: &clock::Clock, a5: &mut tx_context::TxContext): pool::WrappedPositionNFT;
    native public fun deposit_v2<T0, T1>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool::Pool, a3: &pool_1::Pool<T0, T1>, a4: position::Position, a5: &clock::Clock, a6: &mut tx_context::TxContext): pool::WrappedPositionNFT;
    native public fun withdraw(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool::Pool, a3: pool::WrappedPositionNFT, a4: &clock::Clock): position::Position;
    native public fun harvest<T0>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool::Pool, a3: &pool::WrappedPositionNFT, a4: &clock::Clock): balance::Balance<T0>;
    native public fun borrow_clmm_position(a0: &pool::WrappedPositionNFT): &position::Position;
    native public fun borrow_wrapped_position_info(a0: &pool::Pool, a1: object::ID): &pool::WrappedPositionInfo;
    native public fun borrow_rewarders(a0: &pool::WrappedPositionInfo): &vec_map::VecMap<type_name::TypeName, pool::PositionRewardInfo>;
    native public fun position_rewarder_info(a0: &pool::WrappedPositionInfo, a1: &type_name::TypeName): pool::PositionRewardInfo;
    native public fun borrow_position_rewarder_info(a0: &pool::WrappedPositionInfo, a1: &type_name::TypeName): &pool::PositionRewardInfo;
    native public fun share(a0: &pool::WrappedPositionInfo): u128;
    native public fun reward_debt(a0: &pool::PositionRewardInfo): u128;
    native public fun reward(a0: &pool::PositionRewardInfo): u128;
    native public fun reward_harvested(a0: &pool::PositionRewardInfo): u64;
    native public fun borrow_pool_rewarders(a0: &pool::Pool): &vector<type_name::TypeName>;
    native public fun total_share(a0: &pool::Pool): u128;
    native public fun clmm_pool_id(a0: &pool::Pool): object::ID;
    native public fun effective_tick_lower(a0: &pool::Pool): i32::I32;
    native public fun effective_tick_upper(a0: &pool::Pool): i32::I32;
    native public fun sqrt_price(a0: &pool::Pool): u128;
    native public fun add_liquidity<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool::Pool, a4: &mut pool_1::Pool<T0, T1>, a5: &mut pool::WrappedPositionNFT, a6: coin::Coin<T0>, a7: coin::Coin<T1>, a8: u64, a9: u64, a10: u128, a11: &clock::Clock, a12: &mut tx_context::TxContext): (balance::Balance<T0>, balance::Balance<T1>);
    native public fun add_liquidity_fix_coin<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool::Pool, a4: &mut pool_1::Pool<T0, T1>, a5: &mut pool::WrappedPositionNFT, a6: coin::Coin<T0>, a7: coin::Coin<T1>, a8: u64, a9: u64, a10: bool, a11: &clock::Clock, a12: &mut tx_context::TxContext): (balance::Balance<T0>, balance::Balance<T1>);
    native public fun remove_liquidity<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut rewarder::RewarderManager, a3: &mut pool::Pool, a4: &mut pool_1::Pool<T0, T1>, a5: &mut pool::WrappedPositionNFT, a6: u128, a7: u64, a8: u64, a9: &clock::Clock): (balance::Balance<T0>, balance::Balance<T1>);
    native public fun collect_fee<T0, T1>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut pool_1::Pool<T0, T1>, a3: &pool::WrappedPositionNFT, a4: bool): (balance::Balance<T0>, balance::Balance<T1>);
    native public fun collect_clmm_reward<T0, T1, T2>(a0: &config::GlobalConfig, a1: &config_1::GlobalConfig, a2: &mut pool_1::Pool<T1, T2>, a3: &pool::WrappedPositionNFT, a4: &mut rewarder_1::RewarderGlobalVault, a5: coin::Coin<T0>, a6: bool, a7: &clock::Clock, a8: &mut tx_context::TxContext): balance::Balance<T0>;
    native public fun close_position<T0, T1>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool::Pool, a3: &config_1::GlobalConfig, a4: &mut pool_1::Pool<T0, T1>, a5: pool::WrappedPositionNFT, a6: u64, a7: u64, a8: &clock::Clock): (balance::Balance<T0>, balance::Balance<T1>);
    native public fun close_position_v2<T0, T1>(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool::Pool, a3: &config_1::GlobalConfig, a4: &mut pool_1::Pool<T0, T1>, a5: pool::WrappedPositionNFT, a6: u64, a7: u64, a8: &clock::Clock, a9: &tx_context::TxContext): (balance::Balance<T0>, balance::Balance<T1>);
    native public fun accumulated_position_rewards(a0: &config::GlobalConfig, a1: &mut rewarder::RewarderManager, a2: &mut pool::Pool, a3: object::ID, a4: &clock::Clock);
    native public fun calculate_position_share(a0: i32::I32, a1: i32::I32, a2: u128, a3: u128, a4: i32::I32, a5: i32::I32): u128;
    native public fun check_effective_range(a0: i32::I32, a1: i32::I32, a2: u128);

}

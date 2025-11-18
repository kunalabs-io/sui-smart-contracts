module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::fetcher_script {

    use sui::clock;
    use sui::object;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::factory;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::position;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::tick;

    struct FetchTicksResultEvent has copy, drop, store {
        ticks: vector<tick::Tick>,
    }
    struct CalculatedSwapResultEvent has copy, drop, store {
        data: pool::CalculatedSwapResult,
    }
    struct FetchPositionsEvent has copy, drop, store {
        positions: vector<position::PositionInfo>,
    }
    struct FetchPoolsEvent has copy, drop, store {
        pools: vector<factory::PoolSimpleInfo>,
    }
    struct FetchPositionRewardsEvent has copy, drop, store {
        data: vector<u64>,
        position_id: object::ID,
    }
    struct FetchPositionFeesEvent has copy, drop, store {
        position_id: object::ID,
        fee_owned_a: u64,
        fee_owned_b: u64,
    }
    struct FetchPositionPointsEvent has copy, drop, store {
        position_id: object::ID,
        points_owned: u128,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun fetch_ticks<T0, T1>(a0: &pool::Pool<T0, T1>, a1: vector<u32>, a2: u64);
    native public entry fun fetch_positions<T0, T1>(a0: &pool::Pool<T0, T1>, a1: vector<object::ID>, a2: u64);
    native public entry fun fetch_pools(a0: &factory::Pools, a1: vector<object::ID>, a2: u64);
    native public entry fun calculate_swap_result<T0, T1>(a0: &pool::Pool<T0, T1>, a1: bool, a2: bool, a3: u64);
    native public entry fun fetch_position_rewards<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: object::ID, a3: &clock::Clock);
    native public entry fun fetch_position_fees<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T1>, a2: object::ID);
    native public entry fun fetch_position_points<T0, T1>(a0: &config::GlobalConfig, a1: &mut pool::Pool<T0, T0>, a2: object::ID, a3: &clock::Clock);

}

// Copyright (c) Cetus Technology Limited

#[allow(unused_type_parameter, unused_field)]
// The factory module is provided to create and manage pools.
// The `Pools` is a singleton, and the `Pools` is initialized when the contract is deployed.
// The pools are organized in a linked list, and the key is generate by hash([coin_type_a + coin_type_b]). The details can be found in `new_pool_key` function.
// When create a pool, the `CoinTypeA` and `CoinTypeB` must be different, and the `CoinTypeA` must be the bigger one(string order).
module cetusclmm::factory {
    use std::string::String;
    use std::type_name::TypeName;

    use sui::clock::Clock;
    use sui::tx_context::TxContext;
    use sui::object::{ID, UID};
    use sui::coin::{Coin, TreasuryCap};
    use sui::table::{Table};
    use sui::vec_set::{VecSet};
    use sui::coin::CoinMetadata;

    use move_stl::linked_table::LinkedTable;

    use cetusclmm::config::{GlobalConfig};
    use cetusclmm::position::Position;
    
    // === Structs ===
    
    struct PoolSimpleInfo has store, copy, drop {
        pool_id: ID,
        pool_key: ID,
        coin_type_a: TypeName,
        coin_type_b: TypeName,
        tick_spacing: u32,
    }

    
    /// hold the pool list, and the pool list is organized in a linked list.
    /// index is the max index used by pools.
    struct Pools has key, store {
        id: UID,
        list: LinkedTable<ID, PoolSimpleInfo>,
        index: u64,
    }

    // === Events ===

    
    /// Emit when init factory.
    struct InitFactoryEvent has copy, drop {
        pools_id: ID,
    }

    
    /// Emit when create pool.
    struct CreatePoolEvent has copy, drop {
        pool_id: ID,
        coin_type_a: String,
        coin_type_b: String,
        tick_spacing: u32,
    }

    struct DenyCoinList has key, store {
        id: UID,
        denied_list: Table<TypeName, bool>,
        allowed_list: Table<TypeName, bool>,
    }

    struct PoolKey has store, copy, drop {
        coin_a: TypeName,
        coin_b: TypeName,
        tick_spacing: u32,
    }

    struct PermissionPairManager has key, store {
        id: UID,
        allowed_pair_config: Table<TypeName, VecSet<u32>>,
        pool_key_to_cap: Table<ID, ID>,
        // pool_key -> cap_id
        cap_to_pool_key: Table<ID, Table<ID, PoolKey>>,
        // cap_id -> pool_key -> PoolKey
        coin_type_to_cap: Table<TypeName, ID>,
    }

    struct PoolCreationCap has key, store {
        id: UID,
        coin_type: TypeName,
    }

    public fun pool_id(_info: &PoolSimpleInfo): ID {
        abort 0
    }

    public fun pool_key(_info: &PoolSimpleInfo): ID {
        abort 0
    }

    public fun coin_types(_info: &PoolSimpleInfo): (TypeName, TypeName) {
        abort 0
    }

    public fun tick_spacing(_info: &PoolSimpleInfo): u32 {
        abort 0
    }

    public fun index(_pools: &Pools): u64 {
        abort 0
    }

    public fun pool_simple_info(_pools: &Pools, _pool_key: ID): &PoolSimpleInfo {
        abort 0
    }

    public fun in_allowed_list<Coin>(_pools: &Pools): bool {
        abort 0
    }

    public fun in_denied_list<Coin>(_pools: &Pools): bool {
        abort 0
    }

    public fun is_allowed_coin<Coin>(_pools: &mut Pools, _metadata: &CoinMetadata<Coin>): bool {
        abort 0
    }

    public fun is_permission_pair<CoinTypeA, CoinTypeB>(_pools: &Pools, _tick_spacing: u32): bool {
        abort 0
    }

    public fun permission_pair_cap<CoinTypeA, CoinTypeB>(_pools: &Pools, _tick_spacing: u32): ID {
        abort 0
    }

    public fun add_allowed_list<Coin>(_config: &GlobalConfig, _pools: &mut Pools, _ctx: &TxContext) {
        abort 0
    }

    public fun remove_allowed_list<Coin>(_config: &GlobalConfig, _pools: &mut Pools, _ctx: &TxContext) {
        abort 0
    }

    public fun add_denied_list<Coin>(_config: &GlobalConfig, _pools: &mut Pools, _ctx: &TxContext) {
        abort 0
    }

    public fun remove_denied_list<Coin>(_config: &GlobalConfig, _pools: &mut Pools, _ctx: &TxContext) {
        abort 0
    }

    public fun add_allowed_pair_config<Coin>(
        _config: &GlobalConfig,
        _pools: &mut Pools,
        _tick_spacing: u32,
        _ctx: &TxContext
    ) {
        abort 0
    }

    public fun remove_allowed_pair_config<Coin>(
        _config: &GlobalConfig,
        _pools: &mut Pools,
        _tick_spacing: u32,
        _ctx: &TxContext
    ) {
        abort 0
    }

    public fun mint_pool_creation_cap<Coin>(
        _config: &GlobalConfig,
        _pools: &mut Pools,
        _treasury_cap: &mut TreasuryCap<Coin>,
        _ctx: &mut TxContext
    ): PoolCreationCap {
        abort 0
    }

    public fun mint_pool_creation_cap_by_admin<Coin>(
        _config: &GlobalConfig,
        _pools: &mut Pools,
        _ctx: &mut TxContext
    ): PoolCreationCap {
        abort 0
    }

    public fun register_permission_pair<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        _pools: &mut Pools,
        _tick_spacing: u32,
        _pool_creation_cap: &PoolCreationCap,
        _ctx: &mut TxContext
    ) {
        abort 0
    }

    public fun unregister_permission_pair<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        _pools: &mut Pools,
        _tick_spacing: u32,
        _cap: &PoolCreationCap,
    ) {
        abort 0
    }


    #[allow(unused_type_parameter)]
    public fun create_pool<CoinTypeA, CoinTypeB>(
        _pools: &mut Pools,
        _config: &GlobalConfig,
        _tick_spacing: u32,
        _initialize_price: u128,
        _url: String,
        _clock: &Clock,
        _ctx: &mut TxContext
    ) {
        abort 0
    }

    public fun create_pool_with_liquidity<CoinTypeA, CoinTypeB>(
        _pools: &mut Pools,
        _config: &GlobalConfig,
        _tick_spacing: u32,
        _initialize_price: u128,
        _url: String,
        _tick_lower_idx: u32,
        _tick_upper_idx: u32,
        _coin_a: Coin<CoinTypeA>,
        _coin_b: Coin<CoinTypeB>,
        _amount_a: u64,
        _amount_b: u64,
        _fix_amount_a: bool,
        _clock: &Clock,
        _ctx: &mut TxContext
    ): (Position, Coin<CoinTypeA>, Coin<CoinTypeB>) {
        abort 0
    }

    public fun fetch_pools(
        _pools: &Pools,
        _start: vector<ID>,
        _limit: u64
    ): vector<PoolSimpleInfo> {
        abort 0
    }

    #[allow(unused_type_parameter)]
    public fun new_pool_key<CoinTypeA, CoinTypeB>(_tick_spacing: u32): ID {
        abort 0
    }

    #[test_only]
    use move_stl::linked_table;
    #[test_only]
    use sui::object;

    #[test_only]
    public fun new_pools_for_test(ctx: &mut TxContext): Pools {
        Pools {
            id: object::new(ctx),
            list: linked_table::new(ctx),
            index: 0
        }
    }
}

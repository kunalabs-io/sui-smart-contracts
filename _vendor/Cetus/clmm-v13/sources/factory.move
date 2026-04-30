// Copyright (c) Cetus Technology Limited

// The factory module is provided to create and manage pools.
// The `Pools` is a singleton, and the `Pools` is initialized when the contract is deployed.
// The pools are organized in a linked list, and the key is generate by hash([coin_type_a + coin_type_b]). The details can be found in `new_pool_key` function.
// When create a pool, the `CoinTypeA` and `CoinTypeB` must be different, and the `CoinTypeA` must be the bigger one(string order).

module cetus_clmm::factory;

use cetus_clmm::config::{
    Self,
    GlobalConfig,
    checked_package_version,
    check_pool_manager_role,
    fee_tiers
};
use cetus_clmm::pool::{Self, Pool, liquidity};
use cetus_clmm::position::Position;
use cetus_clmm::tick_math;
use move_stl::linked_table::{Self, LinkedTable};
use std::ascii;
use std::bcs;
use std::string::{Self, String};
use std::type_name::{Self, TypeName};
use sui::clock::Clock;
use sui::coin::{Self, Coin, TreasuryCap, CoinMetadata};
use sui::dynamic_object_field;
use sui::event;
use sui::hash;
use sui::sui::SUI;
use sui::table::{Self, Table};
use sui::vec_map;
use sui::vec_set::{Self, VecSet};

const POOL_DEFAULT_URI: vector<u8> =
    b"https://bq7bkvdje7gvgmv66hrxdy7wx5h5ggtrrnmt66rdkkehb64rvz3q.arweave.net/DD4VVGknzVMyvvHjceP2v0_TGnGLWT96I1KIcPuRrnc";
const DENY_COIN_LIST_KEY: vector<u8> = b"deny_coin_list";
const PERMISSION_PAIR_MANAGER_KEY: vector<u8> = b"permission_pair_manager";
const TICK_SPACING_200: u32 = 200;

// =============== Errors =================
const EPoolAlreadyExist: u64 = 1;
const EInvalidSqrtPrice: u64 = 2;
const ESameCoinType: u64 = 3;
const EAmountInAboveMaxLimit: u64 = 4;
const EAmountOutBelowMinLimit: u64 = 5;
const EInvalidCoinTypeSequence: u64 = 6;
const EQuoteCoinTypeNotInAllowedPairConfig: u64 = 7;
const ETickSpacingNotInAllowedPairConfig: u64 = 8;
const EPoolKeyAlreadyRegistered: u64 = 9;
const EPoolKeyNotRegistered: u64 = 10;
const ECapAlreadyRegistered: u64 = 11;
const ECoinTypeNotAllowed: u64 = 12;
const ECapNotMatchWithCoinType: u64 = 13;
const ECoinAlreadyExistsInList: u64 = 14;
const EcoinNotExistsInList: u64 = 15;
const ELiquidityCheckFailed: u64 = 16;
const ETickSpacingNotExistsInFeeTier: u64 = 17;
const ETickSpacingAlreadyExistsInAllowedPairConfig: u64 = 18;
const EMethodDeprecated: u64 = 19;
const EDenyCoinListNotExists: u64 = 20;
const EDenyCoinListAlreadyExists: u64 = 21;
const EPermissionPairManagerNotExists: u64 = 22;
const EPermissionPairManagerAlreadyExists: u64 = 23;
const ECoinAlreadyExistsInAllowedPairConfig: u64 = 24;
const ECoinNotExistsInAllowedPairConfig: u64 = 25;

/// Struct containing basic information about a pool
/// * `pool_id` - The unique identifier of the pool
/// * `pool_key` - The unique identifier of the pool configuration
/// * `coin_type_a` - The type name of the first coin in the pool
/// * `coin_type_b` - The type name of the second coin in the pool
/// * `tick_spacing` - The tick spacing used for price discretization in the pool
public struct PoolSimpleInfo has copy, drop, store {
    pool_id: ID,
    pool_key: ID,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    tick_spacing: u32,
}

/// Holds the pool list, organized as a linked list.
/// `index` tracks the highest index used by pools.
public struct Pools has key, store {
    id: UID,
    list: LinkedTable<ID, PoolSimpleInfo>,
    index: u64,
}

/// Manages a list of denied coin types
/// * `id` - The unique identifier for this list
/// * `denied_list` - A table mapping coin types to boolean values indicating if they are denied
/// * `allowed_list` - A table mapping coin types to boolean values indicating if they are allowed
public struct DenyCoinList has key, store {
    id: UID,
    denied_list: Table<TypeName, bool>,
    allowed_list: Table<TypeName, bool>,
}

/// Represents a unique pool configuration
/// * `coin_a` - The type name of the first coin in the pool
/// * `coin_b` - The type name of the second coin in the pool
/// * `tick_spacing` - The tick spacing used for price discretization in the pool
public struct PoolKey has copy, drop, store {
    coin_a: TypeName,
    coin_b: TypeName,
    tick_spacing: u32,
}

/// Manages permission pairs for pool creation
/// * `id` - The unique identifier for this manager
/// * `allowed_pair_config` - A table mapping coin types to sets of allowed tick spacings
/// * `pool_key_to_cap` - A table mapping pool keys to their corresponding creation caps
/// * `cap_to_pool_key` - A table mapping creation caps to their corresponding pool keys
/// * `coin_type_to_cap` - A table mapping coin types to their corresponding creation caps
public struct PermissionPairManager has key, store {
    id: UID,
    allowed_pair_config: Table<TypeName, VecSet<u32>>,
    // pool_key -> cap_id
    pool_key_to_cap: Table<ID, ID>,
    // cap_id -> pool_key -> PoolKey
    cap_to_pool_key: Table<ID, Table<ID, PoolKey>>,
    coin_type_to_cap: Table<TypeName, ID>,
}

/// Represents a capability to create a specific coin pool
/// * `id` - The unique identifier for this capability
/// * `coin_type` - The type name of the coin this capability allows creation of
public struct PoolCreationCap has key, store {
    id: UID,
    coin_type: TypeName,
}

/// Event emitted when the factory is initialized
/// * `pools_id` - The unique identifier of the pools object
public struct InitFactoryEvent has copy, drop {
    pools_id: ID,
}

/// Event emitted when a pool is created
/// * `pool_id` - The unique identifier of the created pool
/// * `coin_type_a` - The type name of the first coin in the pool
/// * `coin_type_b` - The type name of the second coin in the pool
/// * `tick_spacing` - The tick spacing used for price discretization in the pool
public struct CreatePoolEvent has copy, drop {
    pool_id: ID,
    coin_type_a: String,
    coin_type_b: String,
    tick_spacing: u32,
}

/// Event emitted when a coin is added to the allowed list
/// * `coin_type` - The type name of the coin that was added
public struct AddAllowedListEvent has copy, drop {
    coin_type: String,
}

/// Event emitted when a coin is removed from the allowed list
/// * `coin_type` - The type name of the coin that was removed
public struct RemoveAllowedListEvent has copy, drop {
    coin_type: String,
}

/// Event emitted when a coin is added to the denied list
/// * `coin_type` - The type name of
public struct AddDeniedListEvent has copy, drop {
    coin_type: String,
}

/// Event emitted when a coin is removed from the denied list
/// * `coin_type` - The type name of the coin that was removed
public struct RemoveDeniedListEvent has copy, drop {
    coin_type: String,
}

/// Event emitted when the permission pair manager is initialized
/// * `manager_id` - The unique identifier of the permission pair manager
/// * `denied_list_id` - The unique identifier of the denied coin list
public struct InitPermissionPairManagerEvent has copy, drop {
    manager_id: ID,
    denied_list_id: ID,
}

/// Event emitted when a permission pair is registered
/// * `cap` - The unique identifier of the capability
/// * `pool_key` - The unique identifier of the pool key
/// * `coin_type` - The type name of the coin
/// * `coin_pair` - The type name of the coin pair
/// * `tick_spacing` - The tick spacing used for price discretization in the pool
public struct RegisterPermissionPairEvent has copy, drop {
    cap: ID,
    pool_key: ID,
    coin_type: String,
    coin_pair: String,
    tick_spacing: u32,
}

/// Event emitted when a permission pair is unregistered
/// * `cap` - The unique identifier of the capability
/// * `pool_key` - The unique identifier of the pool key
/// * `coin_type` - The type name of the coin
/// * `coin_pair` - The type name of the coin pair
/// * `tick_spacing` - The tick spacing used for price discretization in the pool
public struct UnregisterPermissionPairEvent has copy, drop {
    cap: ID,
    pool_key: ID,
    coin_type: String,
    coin_pair: String,
    tick_spacing: u32,
}

/// Event emitted when a allowed pair config is added
/// * `coin_type` - The type name of the coin
/// * `tick_spacing` - The tick spacing used for price discretization in the pool
public struct AddAllowedPairConfigEvent has copy, drop {
    coin_type: String,
    tick_spacing: u32,
}

/// Event emitted when a allowed pair config is removed
/// * `coin_type` - The type name of the coin
/// * `tick_spacing` - The tick spacing used for price discretization in the pool
public struct RemoveAllowedPairConfigEvent has copy, drop {
    coin_type: String,
    tick_spacing: u32,
}

/// Event emitted when a pool creation cap is minted
/// * `coin_type` - The type name of the coin
/// * `cap` - The unique identifier of the capability
public struct MintPoolCreationCap has copy, drop {
    coin_type: String,
    cap: ID,
}

/// Event emitted when a pool creation cap is minted by admin
/// * `coin_type` - The type name of the coin
/// * `cap` - The unique identifier of the capability
public struct MintPoolCreationCapByAdmin has copy, drop {
    coin_type: String,
    cap: ID,
}

/// Initialize the factory
/// * `ctx` - Transaction context used to initialize the factory
fun init(ctx: &mut TxContext) {
    let pools = Pools {
        id: object::new(ctx),
        list: linked_table::new(ctx),
        index: 0,
    };
    let pools_id = object::id(&pools);
    transfer::share_object(pools);
    event::emit(InitFactoryEvent {
        pools_id,
    });
}

/// Get the pool_id from the pool simple info
/// * `info` - The pool simple info
public fun pool_id(info: &PoolSimpleInfo): ID {
    info.pool_id
}

/// Get the pool_key from the pool simple info
/// * `info` - The pool simple info
public fun pool_key(info: &PoolSimpleInfo): ID {
    info.pool_key
}

/// Get the coin types from the pool simple info
/// * `info` - The pool simple info
public fun coin_types(info: &PoolSimpleInfo): (TypeName, TypeName) {
    (info.coin_type_a, info.coin_type_b)
}

/// Get the tick spacing from the pool simple info
/// * `info` - The pool simple info
public fun tick_spacing(info: &PoolSimpleInfo): u32 {
    info.tick_spacing
}

/// Get the pool index from the pools
/// * `pools` - The pools
public fun index(pools: &Pools): u64 {
    pools.index
}

/// Get the pool simple info from the pools
/// * `pools` - The pools
/// * `pool_key` - The pool key
public fun pool_simple_info(pools: &Pools, pool_key: ID): &PoolSimpleInfo {
    assert!(linked_table::contains(&pools.list, pool_key), EPoolKeyNotRegistered);
    linked_table::borrow(&pools.list, pool_key)
}

/// Check if a coin is in the allowed list
/// * `pools` - The pools
/// * `Coin` - The coin type
public fun in_allowed_list<Coin>(pools: &Pools): bool {
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(DENY_COIN_LIST_KEY)),
        EDenyCoinListNotExists,
    );
    let coin_list = dynamic_object_field::borrow<String, DenyCoinList>(
        &pools.id,
        string::utf8(DENY_COIN_LIST_KEY),
    );
    table::contains<TypeName, bool>(&coin_list.allowed_list, type_name::get<Coin>())
}

/// Check if a coin is in the denied list
/// * `pools` - The pools
/// * `Coin` - The coin type
public fun in_denied_list<Coin>(pools: &Pools): bool {
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(DENY_COIN_LIST_KEY)),
        EDenyCoinListNotExists,
    );
    let coin_list = dynamic_object_field::borrow<String, DenyCoinList>(
        &pools.id,
        string::utf8(DENY_COIN_LIST_KEY),
    );
    table::contains<TypeName, bool>(&coin_list.denied_list, type_name::get<Coin>())
}

/// Check if a coin is allowed
/// * `pools` - The pools
/// * `Coin` - The coin type
/// * `_metadata` - The coin metadata
public fun is_allowed_coin<Coin>(pools: &mut Pools, _metadata: &CoinMetadata<Coin>): bool {
    let mut is_allowed = in_allowed_list<Coin>(pools);
    is_allowed = is_allowed || !in_denied_list<Coin>(pools);
    is_allowed
    // TODO: add_denied_coin
}

/// Check if a permission pair exists
/// * `pools` - The pools
/// * `CoinTypeA` - The type name of the first coin
/// * `CoinTypeB` - The type name of the second coin
/// * `tick_spacing` - The tick spacing
public fun is_permission_pair<CoinTypeA, CoinTypeB>(pools: &Pools, tick_spacing: u32): bool {
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY)),
        EPermissionPairManagerNotExists,
    );
    let manager = dynamic_object_field::borrow<String, PermissionPairManager>(
        &pools.id,
        string::utf8(PERMISSION_PAIR_MANAGER_KEY),
    );
    let pool_key = new_pool_key<CoinTypeA, CoinTypeB>(tick_spacing);
    table::contains<ID, ID>(&manager.pool_key_to_cap, pool_key)
}

/// Get the permission pair cap from the pools
/// * `pools` - The pools
/// * `CoinTypeA` - The type name of the first coin
/// * `CoinTypeB` - The type name of the second coin
/// * `tick_spacing` - The tick spacing
public fun permission_pair_cap<CoinTypeA, CoinTypeB>(pools: &Pools, tick_spacing: u32): ID {
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY)),
        EPermissionPairManagerNotExists,
    );
    let manager = dynamic_object_field::borrow<String, PermissionPairManager>(
        &pools.id,
        string::utf8(PERMISSION_PAIR_MANAGER_KEY),
    );
    let pool_key = new_pool_key<CoinTypeA, CoinTypeB>(tick_spacing);
    assert!(table::contains(&manager.pool_key_to_cap, pool_key), EPoolKeyNotRegistered);
    *table::borrow<ID, ID>(&manager.pool_key_to_cap, pool_key)
}

/// Initialize the permission pair manager and the whitelist
/// * `config` - The global config
/// * `pools` - The pools
/// * `ctx` - Transaction context used to initialize the permission pair manager and the whitelist
#[allow(lint(public_entry))]
public entry fun init_manager_and_whitelist(
    config: &GlobalConfig,
    pools: &mut Pools,
    ctx: &mut TxContext,
) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    let mut manager = PermissionPairManager {
        id: object::new(ctx),
        allowed_pair_config: table::new(ctx),
        pool_key_to_cap: table::new(ctx),
        cap_to_pool_key: table::new(ctx),
        coin_type_to_cap: table::new(ctx),
    };
    let fee_tiers_ = fee_tiers(config);
    let tick_spacing_200 = TICK_SPACING_200;
    assert!(vec_map::contains(fee_tiers_, &tick_spacing_200), ETickSpacingNotExistsInFeeTier);
    assert!(
        !table::contains(&manager.allowed_pair_config, type_name::get<SUI>()),
        ECoinAlreadyExistsInAllowedPairConfig,
    );
    table::add(
        &mut manager.allowed_pair_config,
        type_name::get<SUI>(),
        vec_set::singleton(tick_spacing_200),
    );
    let manager_id = object::id(&manager);
    assert!(
        !dynamic_object_field::exists_(&pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY)),
        EPermissionPairManagerAlreadyExists,
    );
    dynamic_object_field::add(&mut pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY), manager);
    let whitelist = DenyCoinList {
        id: object::new(ctx),
        denied_list: table::new(ctx),
        allowed_list: table::new(ctx),
    };
    let denied_list_id = object::id(&whitelist);
    assert!(
        !dynamic_object_field::exists_(&pools.id, string::utf8(DENY_COIN_LIST_KEY)),
        EDenyCoinListAlreadyExists,
    );
    dynamic_object_field::add(&mut pools.id, string::utf8(DENY_COIN_LIST_KEY), whitelist);
    event::emit(InitPermissionPairManagerEvent {
        manager_id,
        denied_list_id,
    });
}

/// Add a coin to the allowed list
/// * `config` - The global config
/// * `pools` - The pools
/// * `ctx` - Transaction context used to add the coin to the allowed list
public fun add_allowed_list<Coin>(config: &GlobalConfig, pools: &mut Pools, ctx: &TxContext) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    let c_type = type_name::get<Coin>();
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(DENY_COIN_LIST_KEY)),
        EDenyCoinListNotExists,
    );
    let coin_list = dynamic_object_field::borrow_mut<String, DenyCoinList>(
        &mut pools.id,
        string::utf8(DENY_COIN_LIST_KEY),
    );
    assert!(!table::contains(&coin_list.allowed_list, c_type), ECoinAlreadyExistsInList);
    table::add(&mut coin_list.allowed_list, c_type, true);
    event::emit(AddAllowedListEvent {
        coin_type: string::from_ascii(type_name::into_string(c_type)),
    });
}

/// Remove a coin from the allowed list
/// * `config` - The global config
/// * `pools` - The pools
/// * `ctx` - Transaction context used to remove the coin from the allowed list
public fun remove_allowed_list<Coin>(config: &GlobalConfig, pools: &mut Pools, ctx: &TxContext) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    let c_type = type_name::get<Coin>();
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(DENY_COIN_LIST_KEY)),
        EDenyCoinListNotExists,
    );
    let coin_list = dynamic_object_field::borrow_mut<String, DenyCoinList>(
        &mut pools.id,
        string::utf8(DENY_COIN_LIST_KEY),
    );
    assert!(table::contains(&coin_list.allowed_list, c_type), EcoinNotExistsInList);
    table::remove(&mut coin_list.allowed_list, c_type);
    event::emit(RemoveAllowedListEvent {
        coin_type: string::from_ascii(type_name::into_string(c_type)),
    });
}

/// Add a coin to the denied list
/// * `config` - The global config
/// * `pools` - The pools
/// * `ctx` - Transaction context used to add the coin to the denied list
public fun add_denied_list<Coin>(config: &GlobalConfig, pools: &mut Pools, ctx: &TxContext) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    add_denied_coin<Coin>(pools);
}

/// Remove a coin from the denied list
/// * `config` - The global config
/// * `pools` - The pools
/// * `ctx` - Transaction context used to remove the coin from the denied list
public fun remove_denied_list<Coin>(config: &GlobalConfig, pools: &mut Pools, ctx: &TxContext) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    let c_type = type_name::get<Coin>();
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(DENY_COIN_LIST_KEY)),
        EDenyCoinListNotExists,
    );
    let coin_list = dynamic_object_field::borrow_mut<String, DenyCoinList>(
        &mut pools.id,
        string::utf8(DENY_COIN_LIST_KEY),
    );
    assert!(table::contains(&coin_list.denied_list, c_type), EcoinNotExistsInList);
    table::remove(&mut coin_list.denied_list, c_type);
    event::emit(RemoveDeniedListEvent {
        coin_type: string::from_ascii(type_name::into_string(c_type)),
    });
}

/// Add a allowed pair config
/// * `config` - The global config
/// * `pools` - The pools
/// * `tick_spacing` - The tick spacing
/// * `ctx` - Transaction context used to add the allowed pair config
public fun add_allowed_pair_config<Coin>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    ctx: &TxContext,
) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    let fee_tiers_ = fee_tiers(config);
    assert!(vec_map::contains(fee_tiers_, &tick_spacing), ETickSpacingNotExistsInFeeTier);

    let name = type_name::get<Coin>();
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY)),
        EPermissionPairManagerNotExists,
    );
    let manager = dynamic_object_field::borrow_mut<String, PermissionPairManager>(
        &mut pools.id,
        string::utf8(PERMISSION_PAIR_MANAGER_KEY),
    );
    if (!table::contains<TypeName, VecSet<u32>>(&manager.allowed_pair_config, name)) {
        table::add(&mut manager.allowed_pair_config, name, vec_set::empty());
    };
    let vec_set = table::borrow_mut<TypeName, VecSet<u32>>(
        &mut manager.allowed_pair_config,
        name,
    );
    assert!(
        !vec_set::contains(vec_set, &tick_spacing),
        ETickSpacingAlreadyExistsInAllowedPairConfig,
    );
    vec_set::insert(vec_set, tick_spacing);
    event::emit(AddAllowedPairConfigEvent {
        coin_type: string::from_ascii(type_name::into_string(name)),
        tick_spacing,
    });
}

/// Remove a allowed pair config
/// * `config` - The global config
/// * `pools` - The pools
/// * `tick_spacing` - The tick spacing
/// * `ctx` - Transaction context used to remove the allowed pair config
public fun remove_allowed_pair_config<Coin>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    ctx: &TxContext,
) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    let coin_type = type_name::get<Coin>();
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY)),
        EPermissionPairManagerNotExists,
    );
    let manager = dynamic_object_field::borrow_mut<String, PermissionPairManager>(
        &mut pools.id,
        string::utf8(PERMISSION_PAIR_MANAGER_KEY),
    );
    assert!(
        table::contains<TypeName, VecSet<u32>>(
            &manager.allowed_pair_config,
            coin_type,
        ),
        ECoinNotExistsInAllowedPairConfig,
    );
    let vec_set = table::borrow_mut<TypeName, VecSet<u32>>(
        &mut manager.allowed_pair_config,
        coin_type,
    );
    assert!(vec_set::contains(vec_set, &tick_spacing), ETickSpacingNotInAllowedPairConfig);
    vec_set::remove(vec_set, &tick_spacing);
    if (vec_set.is_empty()) {
        manager.allowed_pair_config.remove(coin_type);
    };
    event::emit(RemoveAllowedPairConfigEvent {
        coin_type: string::from_ascii(type_name::into_string(coin_type)),
        tick_spacing,
    });
}

/// Mint a pool creation cap
/// * `config` - The global config
/// * `pools` - The pools
/// * `_` - The treasury cap
/// * `ctx` - Transaction context used to mint the pool creation cap
public fun mint_pool_creation_cap<Coin>(
    config: &GlobalConfig,
    pools: &mut Pools,
    _: &mut TreasuryCap<Coin>,
    ctx: &mut TxContext,
): PoolCreationCap {
    checked_package_version(config);
    let c_type = type_name::get<Coin>();
    let cap = mint_pool_creation_cap_internal(pools, c_type, ctx);

    event::emit(MintPoolCreationCap {
        coin_type: string::from_ascii(type_name::into_string(c_type)),
        cap: object::id(&cap),
    });
    cap
}

/// Mint a pool creation cap by admin
/// * `config` - The global config
/// * `pools` - The pools
/// * `ctx` - Transaction context used to mint the pool creation cap by admin
public fun mint_pool_creation_cap_by_admin<Coin>(
    config: &GlobalConfig,
    pools: &mut Pools,
    ctx: &mut TxContext,
): PoolCreationCap {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    let c_type = type_name::get<Coin>();
    let cap = mint_pool_creation_cap_internal(pools, c_type, ctx);

    event::emit(MintPoolCreationCapByAdmin {
        coin_type: string::from_ascii(type_name::into_string(c_type)),
        cap: object::id(&cap),
    });
    cap
}

/// Register PermissionPair
/// * `config` - The global config
/// * `pools` - The pools
/// * `tick_spacing` - The tick spacing
/// * `pool_creation_cap` - The pool creation cap
/// * `ctx` - Transaction context used to register the permission pair
public fun register_permission_pair<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    pool_creation_cap: &PoolCreationCap,
    ctx: &mut TxContext,
) {
    checked_package_version(config);
    register_permission_pair_internal<CoinTypeA, CoinTypeB>(
        pools,
        pool_creation_cap,
        tick_spacing,
        ctx,
    );
}

/// Unregister PermissionPair
/// * `config` - The global config
/// * `pools` - The pools
/// * `tick_spacing` - The tick spacing
/// * `cap` - The pool creation cap
/// * `ctx` - Transaction context used to unregister the permission pair
public fun unregister_permission_pair<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    cap: &PoolCreationCap,
) {
    checked_package_version(config);
    unregister_permission_pair_internal<CoinTypeA, CoinTypeB>(pools, cap, tick_spacing);
}

fun register_permission_pair_internal<CoinTypeA, CoinTypeB>(
    pools: &mut Pools,
    cap: &PoolCreationCap,
    tick_spacing: u32,
    ctx: &mut TxContext,
) {
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY)),
        EPermissionPairManagerNotExists,
    );
    let manager = dynamic_object_field::borrow_mut<String, PermissionPairManager>(
        &mut pools.id,
        string::utf8(PERMISSION_PAIR_MANAGER_KEY),
    );
    let quote_coin = type_name::get<CoinTypeB>();
    assert!(
        table::contains<TypeName, VecSet<u32>>(&manager.allowed_pair_config, quote_coin),
        EQuoteCoinTypeNotInAllowedPairConfig,
    );
    let vec_set = table::borrow<TypeName, VecSet<u32>>(&manager.allowed_pair_config, quote_coin);
    assert!(vec_set::contains(vec_set, &tick_spacing), ETickSpacingNotInAllowedPairConfig);

    assert!(type_name::get<CoinTypeA>() == cap.coin_type, ECapNotMatchWithCoinType);
    let is_right = is_right_order<CoinTypeA, CoinTypeB>();

    let (pool_key, coin_a, coin_b) = if (is_right) {
        (new_pool_key<CoinTypeA, CoinTypeB>(tick_spacing), cap.coin_type, quote_coin)
    } else {
        (new_pool_key<CoinTypeB, CoinTypeA>(tick_spacing), quote_coin, cap.coin_type)
    };
    assert!(!table::contains(&manager.pool_key_to_cap, pool_key), EPoolKeyAlreadyRegistered);
    let cap_id = object::id(cap);
    table::add(&mut manager.pool_key_to_cap, pool_key, cap_id);
    if (!table::contains(&manager.cap_to_pool_key, cap_id)) {
        table::add(&mut manager.cap_to_pool_key, cap_id, table::new(ctx));
    };
    let cap_keys = table::borrow_mut<ID, Table<ID, PoolKey>>(&mut manager.cap_to_pool_key, cap_id);
    table::add(
        cap_keys,
        pool_key,
        PoolKey {
            coin_a,
            coin_b,
            tick_spacing,
        },
    );
    event::emit(RegisterPermissionPairEvent {
        cap: cap_id,
        pool_key,
        coin_type: string::from_ascii(type_name::into_string(cap.coin_type)),
        coin_pair: string::from_ascii(type_name::into_string(quote_coin)),
        tick_spacing,
    });
}

fun unregister_permission_pair_internal<CoinTypeA, CoinTypeB>(
    pools: &mut Pools,
    cap: &PoolCreationCap,
    tick_spacing: u32,
) {
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY)),
        EPermissionPairManagerNotExists,
    );
    let manager = dynamic_object_field::borrow_mut<String, PermissionPairManager>(
        &mut pools.id,
        string::utf8(PERMISSION_PAIR_MANAGER_KEY),
    );
    let quote_coin = type_name::get<CoinTypeB>();

    let is_right = is_right_order<CoinTypeA, CoinTypeB>();
    let pool_key = if (is_right) {
        new_pool_key<CoinTypeA, CoinTypeB>(tick_spacing)
    } else {
        new_pool_key<CoinTypeB, CoinTypeA>(tick_spacing)
    };
    assert!(table::contains(&manager.pool_key_to_cap, pool_key), EPoolKeyNotRegistered);
    let cap_id = object::id(cap);
    let _cap_id = table::remove(&mut manager.pool_key_to_cap, pool_key);
    assert!(_cap_id == cap_id, ECapNotMatchWithCoinType);
    let cap_keys = table::borrow_mut<ID, Table<ID, PoolKey>>(&mut manager.cap_to_pool_key, cap_id);
    table::remove(cap_keys, pool_key);
    if (cap_keys.is_empty()) {
        let cap_keys = manager.cap_to_pool_key.remove(cap_id);
        cap_keys.destroy_empty();
    };
    event::emit(UnregisterPermissionPairEvent {
        cap: cap_id,
        pool_key,
        coin_type: string::from_ascii(type_name::into_string(cap.coin_type)),
        coin_pair: string::from_ascii(type_name::into_string(quote_coin)),
        tick_spacing,
    });
}

fun add_denied_coin<Coin>(pools: &mut Pools) {
    let c_type = type_name::get<Coin>();
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(DENY_COIN_LIST_KEY)),
        EDenyCoinListNotExists,
    );
    let coin_list = dynamic_object_field::borrow_mut<String, DenyCoinList>(
        &mut pools.id,
        string::utf8(DENY_COIN_LIST_KEY),
    );
    assert!(!table::contains(&coin_list.denied_list, c_type), ECoinAlreadyExistsInList);
    table::add(&mut coin_list.denied_list, c_type, true);
    event::emit(AddDeniedListEvent {
        coin_type: string::from_ascii(type_name::into_string(c_type)),
    });
}

fun mint_pool_creation_cap_internal(
    pools: &mut Pools,
    coin_type: TypeName,
    ctx: &mut TxContext,
): PoolCreationCap {
    assert!(
        dynamic_object_field::exists_(&pools.id, string::utf8(PERMISSION_PAIR_MANAGER_KEY)),
        EPermissionPairManagerNotExists,
    );
    let manager = dynamic_object_field::borrow_mut<String, PermissionPairManager>(
        &mut pools.id,
        string::utf8(PERMISSION_PAIR_MANAGER_KEY),
    );
    assert!(!table::contains(&manager.coin_type_to_cap, coin_type), ECapAlreadyRegistered);
    let cap = PoolCreationCap {
        id: object::new(ctx),
        coin_type,
    };
    table::add(&mut manager.coin_type_to_cap, coin_type, object::id(&cap));
    cap
}

#[allow(lint(share_owned))]
/// Create pool
/// * `CoinTypeA` - The type name of the first coin
/// * `CoinTypeB` - The type name of the second coin
/// * `pools` - The global pools
/// * `config` - The global config
/// * `tick_spacing` - The tick spacing of the pool
/// * `initialize_price` - The initial price of the pool
/// * `url` - The url of the pool which is used in position nft
/// * `clock` - The clock
/// * `ctx` - Transaction context used to create the pool
public fun create_pool<CoinTypeA, CoinTypeB>(
    pools: &mut Pools,
    config: &GlobalConfig,
    tick_spacing: u32,
    initialize_price: u128,
    url: String,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    checked_package_version(config);
    config::check_pool_manager_role(config, tx_context::sender(ctx));
    let pool = create_pool_internal<CoinTypeA, CoinTypeB>(
        pools,
        config,
        tick_spacing,
        initialize_price,
        url,
        clock,
        ctx,
    );
    transfer::public_share_object(pool)
}

#[allow(lint(share_owned))]
/// @Deprecated
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
    _ctx: &mut TxContext,
): (Position, Coin<CoinTypeA>, Coin<CoinTypeB>) {
    abort EMethodDeprecated
}

#[allow(lint(share_owned))]
/// Create pool and add liquidity.
/// * `config` - The global config
/// * `pools` - The global pools
/// * `tick_spacing` - The tick spacing of the pool
/// * `initialize_price` - The initial price of the pool
/// * `url` - The url of the pool which is used in position nft
/// * `tick_lower_idx` - The lower tick index of the pool
/// * `tick_upper_idx` - The upper tick index of the pool
/// * `coin_a` - The coin a
/// * `coin_b` - The coin b
/// * `metadata_a` - The metadata of the coin a
/// * `metadata_b` - The metadata of the coin b
/// * `amount_a` - The amount of coin a
/// * `amount_b` - The amount of coin b
/// * `fix_amount_a` - Fix the amount of coin a or b
/// * `clock` - The clock
/// * `ctx` - Transaction context used to create the pool and add liquidity
public(package) fun create_pool_v2_<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    initialize_price: u128,
    url: String,
    tick_lower_idx: u32,
    tick_upper_idx: u32,
    mut coin_a: Coin<CoinTypeA>,
    mut coin_b: Coin<CoinTypeB>,
    metadata_a: &CoinMetadata<CoinTypeA>,
    metadata_b: &CoinMetadata<CoinTypeB>,
    amount_a: u64,
    amount_b: u64,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext,
): (Position, Coin<CoinTypeA>, Coin<CoinTypeB>) {
    checked_package_version(config);
    assert!(is_allowed_coin<CoinTypeA>(pools, metadata_a), ECoinTypeNotAllowed);
    assert!(is_allowed_coin<CoinTypeB>(pools, metadata_b), ECoinTypeNotAllowed);
    let mut pool = create_pool_internal<CoinTypeA, CoinTypeB>(
        pools,
        config,
        tick_spacing,
        initialize_price,
        url,
        clock,
        ctx,
    );
    let mut position_nft = pool::open_position(
        config,
        &mut pool,
        tick_lower_idx,
        tick_upper_idx,
        ctx,
    );
    let amount = if (fix_amount_a) amount_a else amount_b;
    let receipt = pool::add_liquidity_fix_coin(
        config,
        &mut pool,
        &mut position_nft,
        amount,
        fix_amount_a,
        clock,
    );

    let (amount_need_a, amount_need_b) = pool::add_liquidity_pay_amount(&receipt);
    assert!(amount_need_a > 0, ELiquidityCheckFailed);
    assert!(amount_need_b > 0, ELiquidityCheckFailed);
    assert!(liquidity(&pool) > 0, ELiquidityCheckFailed);

    if (fix_amount_a) {
        assert!(amount_need_b <= amount_b, EAmountInAboveMaxLimit)
    } else {
        assert!(amount_need_a <= amount_a, EAmountOutBelowMinLimit)
    };
    let (balance_a, balance_b) = (
        coin::into_balance(coin::split(&mut coin_a, amount_need_a, ctx)),
        coin::into_balance(coin::split(&mut coin_b, amount_need_b, ctx)),
    );
    pool::repay_add_liquidity(config, &mut pool, balance_a, balance_b, receipt);
    transfer::public_share_object(pool);

    (position_nft, coin_a, coin_b)
}

fun create_pool_internal<CoinTypeA, CoinTypeB>(
    pools: &mut Pools,
    global_config: &GlobalConfig,
    tick_spacing: u32,
    initialize_price: u128,
    url: String,
    clock: &Clock,
    ctx: &mut TxContext,
): Pool<CoinTypeA, CoinTypeB> {
    assert!(
        initialize_price > tick_math::min_sqrt_price() && initialize_price < tick_math::max_sqrt_price(),
        EInvalidSqrtPrice,
    );

    let (coin_type_a, coin_type_b) = (type_name::get<CoinTypeA>(), type_name::get<CoinTypeB>());
    assert!(coin_type_a != coin_type_b, ESameCoinType);
    let pool_key = new_pool_key<CoinTypeA, CoinTypeB>(tick_spacing);
    // Check pool if exist
    assert!(!linked_table::contains(&pools.list, pool_key), EPoolAlreadyExist);

    // Create pool
    let fee_rate = config::get_fee_rate(tick_spacing, global_config);
    let uri = if (string::length(&url) == 0) {
        string::utf8(POOL_DEFAULT_URI)
    } else {
        url
    };
    let pool = pool::new<CoinTypeA, CoinTypeB>(
        tick_spacing,
        initialize_price,
        fee_rate,
        uri,
        pools.index,
        clock,
        ctx,
    );
    pools.index = pools.index + 1;

    // Record simple pool info for query.
    let pool_id = object::id(&pool);
    linked_table::push_back(
        &mut pools.list,
        pool_key,
        PoolSimpleInfo {
            pool_id,
            pool_key,
            coin_type_a,
            coin_type_b,
            tick_spacing,
        },
    );

    event::emit(CreatePoolEvent {
        pool_id,
        coin_type_a: string::from_ascii(type_name::into_string(coin_type_a)),
        coin_type_b: string::from_ascii(type_name::into_string(coin_type_b)),
        tick_spacing,
    });

    pool
}

/// Fetch pool simple infos.
/// * `pools` - The global pools
/// * `start` - The start pool id
/// * `limit` - The max number of Pool to fetch
public fun fetch_pools(pools: &Pools, start: vector<ID>, limit: u64): vector<PoolSimpleInfo> {
    if (limit == 0) {
        return vector::empty<PoolSimpleInfo>()
    };
    let mut simple_pools = vector::empty<PoolSimpleInfo>();
    let mut next_pool_key = if (vector::is_empty(&start)) {
        linked_table::head(&pools.list)
    } else {
        let pool_key = *vector::borrow(&start, 0);
        assert!(linked_table::contains(&pools.list, pool_key), EPoolKeyNotRegistered);
        option::some(pool_key)
    };
    let mut count = 0;
    while (option::is_some(&next_pool_key) && count < limit) {
        let key = *option::borrow(&next_pool_key);
        let node = linked_table::borrow_node(&pools.list, key);
        next_pool_key = linked_table::next(node);
        let simple_pool_info = *linked_table::borrow_value(node);
        vector::push_back(&mut simple_pools, simple_pool_info);
        count = count + 1
    };
    simple_pools
}

/// Generate the pool unique key by CoinTypeA ,CoinTypeB and tick_spacing.
/// The key is used to check if the pool already exist.
/// the order or CoinTypeA and CoinTypeB is checked, or error is EInvalidCoinTypeSequence.
/// if the CoinTypeA and CoinTypeB is the same, error is ESameCoinType.
/// key = hash([CoinTypeA, CoinTypeB, tick_spacing])
///
/// * `CoinTypeA` - The type name of the first coin
/// * `CoinTypeB` - The type name of the second coin
/// * `tick_spacing` - The tick spacing
public fun new_pool_key<CoinTypeA, CoinTypeB>(tick_spacing: u32): ID {
    let mut coin_type_a = *ascii::as_bytes(&type_name::into_string(type_name::get<CoinTypeA>()));
    let coin_type_b = *ascii::as_bytes(&type_name::into_string(type_name::get<CoinTypeB>()));
    let (len_a, len_b) = (vector::length(&coin_type_a), vector::length((&coin_type_b)));
    let mut i = 0;
    let mut check_pass = false;
    while (i < len_b) {
        let byte_b = *vector::borrow(&coin_type_b, i);
        if (!check_pass && i < len_a) {
            let byte_a = *vector::borrow(&coin_type_a, i);
            if (byte_a < byte_b) {
                abort EInvalidCoinTypeSequence
            };
            if (byte_a > byte_b) {
                check_pass = true
            };
        };
        vector::push_back(&mut coin_type_a, byte_b);
        i = i + 1;
    };
    if (!check_pass) {
        assert!(len_a != len_b, ESameCoinType);
        assert!(len_a > len_b, EInvalidCoinTypeSequence);
        // if (len_a < len_b) {
        //     abort EInvalidCoinTypeSequence
        // };
        // if (len_a == len_b) {
        //     abort ESameCoinType
        // };
    };
    vector::append(&mut coin_type_a, bcs::to_bytes(&tick_spacing));
    object::id_from_bytes(hash::blake2b256(&coin_type_a))
}

/// Check if the order of CoinTypeA and CoinTypeB is right
/// * `CoinTypeA` - The type name of the first coin
/// * `CoinTypeB` - The type name of the second coin
public fun is_right_order<CoinTypeA, CoinTypeB>(): bool {
    let coin_type_a = *ascii::as_bytes(&type_name::into_string(type_name::get<CoinTypeA>()));
    let coin_type_b = *ascii::as_bytes(&type_name::into_string(type_name::get<CoinTypeB>()));
    let (len_a, len_b) = (vector::length(&coin_type_a), vector::length((&coin_type_b)));
    let mut i = 0;
    let mut check_pass = false;
    while (i < len_b) {
        let byte_b = *vector::borrow(&coin_type_b, i);
        if (!check_pass && i < len_a) {
            let byte_a = *vector::borrow(&coin_type_a, i);
            if (byte_a < byte_b) {
                return false
            };
            if (byte_a > byte_b) {
                check_pass = true
            };
        };
        i = i + 1;
    };
    if (!check_pass) {
        if (len_a < len_b) {
            return false
        };
        if (len_a == len_b) {
            abort ESameCoinType
        };
    };
    return true
}

#[test_only]
public fun new_pools_for_test(ctx: &mut TxContext): Pools {
    Pools {
        id: object::new(ctx),
        list: linked_table::new(ctx),
        index: 0,
    }
}

#[test]
fun test_init() {
    let mut sc = sui::test_scenario::begin(@0x91);
    init(sc.ctx());
    sc.next_tx(@91);
    let pools = sui::test_scenario::take_shared<Pools>(&sc);
    sui::test_scenario::return_shared(pools);
    sc.end();
}

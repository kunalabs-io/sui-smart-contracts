module cetus_clmm::pool_creator;

use cetus_clmm::config::GlobalConfig;
use cetus_clmm::factory::{Self, Pools, permission_pair_cap, PoolCreationCap};
use cetus_clmm::position::Position;
use cetus_clmm::tick_math::{Self, get_sqrt_price_at_tick};
use integer_mate::i32;
use std::string::String;
use sui::clock::Clock;
use sui::coin::{Self, Coin, CoinMetadata};

const EPoolIsPermission: u64 = 1;
#[allow(unused_const)]
const EInvalidTickLower: u64 = 2;
#[allow(unused_const)]
const EInvalidTickUpper: u64 = 3;
const ECapNotMatchWithPoolKey: u64 = 4;
const EInitSqrtPriceNotBetweenLowerAndUpper: u64 = 5;
const EMethodDeprecated: u64 = 6;

/// DEPRECATED
public fun create_pool_v2_by_creation_cap<CoinTypeA, CoinTypeB>(
    _config: &GlobalConfig,
    _pools: &mut Pools,
    _cap: &PoolCreationCap,
    _tick_spacing: u32,
    _initialize_price: u128,
    _url: String,
    _coin_a: Coin<CoinTypeA>,
    _coin_b: Coin<CoinTypeB>,
    _metadata_a: &CoinMetadata<CoinTypeA>,
    _metadata_b: &CoinMetadata<CoinTypeB>,
    _fix_amount_a: bool,
    _clock: &Clock,
    _ctx: &mut TxContext,
): (Position, Coin<CoinTypeA>, Coin<CoinTypeB>) {
    abort EMethodDeprecated
}

/// Create pool with creation cap
/// * `config` - The global configuration
/// * `pools` - The mutable reference to the `Pools` object
/// * `cap` - The reference to the `PoolCreationCap` object
/// * `tick_spacing` - The tick spacing
/// * `initialize_price` - The initial price
/// * `url` - The URL of the pool
/// * `tick_lower_idx` - The lower tick index
/// * `tick_upper_idx` - The upper tick index
/// * `coin_a` - The coin A
/// * `coin_b` - The coin B
/// * `metadata_a` - The metadata of the coin A
/// * `metadata_b` - The metadata of the coin B
/// * `fix_amount_a` - Whether to fix the amount of the coin A
/// * `clock` - The clock object
/// * `ctx` - The transaction context
/// * Returns the position, coin A, and coin B
public fun create_pool_v2_with_creation_cap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    cap: &PoolCreationCap,
    tick_spacing: u32,
    initialize_price: u128,
    url: String,
    tick_lower_idx: u32,
    tick_upper_idx: u32,
    coin_a: Coin<CoinTypeA>,
    coin_b: Coin<CoinTypeB>,
    metadata_a: &CoinMetadata<CoinTypeA>,
    metadata_b: &CoinMetadata<CoinTypeB>,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext,
): (Position, Coin<CoinTypeA>, Coin<CoinTypeB>) {
    let (amount_a, amount_b) = (coin::value(&coin_a), coin::value(&coin_b));
    assert!(
        permission_pair_cap<CoinTypeA, CoinTypeB>(pools, tick_spacing) == object::id(cap),
        ECapNotMatchWithPoolKey,
    );
    let lower_sqrt_price = get_sqrt_price_at_tick(i32::from_u32(tick_lower_idx));
    let upper_sqrt_price = get_sqrt_price_at_tick(i32::from_u32(tick_upper_idx));
    assert!(
        lower_sqrt_price < initialize_price && upper_sqrt_price > initialize_price,
        EInitSqrtPriceNotBetweenLowerAndUpper,
    );

    let (position, coin_a, coin_b) = factory::create_pool_v2_<CoinTypeA, CoinTypeB>(
        config,
        pools,
        tick_spacing,
        initialize_price,
        url,
        tick_lower_idx,
        tick_upper_idx,
        coin_a,
        coin_b,
        metadata_a,
        metadata_b,
        amount_a,
        amount_b,
        fix_amount_a,
        clock,
        ctx,
    );
    (position, coin_a, coin_b)
}

/// Create pool with custom tick range
/// * `config` - The global configuration
/// * `pools` - The mutable reference to the `Pools` object
/// * `tick_spacing` - The tick spacing
/// * `initialize_price` - The initial price
/// * `url` - The URL of the pool
/// * `tick_lower_idx` - The lower tick index
/// * `tick_upper_idx` - The upper tick index
/// * `coin_a` - The coin A
/// * `coin_b` - The coin B
/// * `metadata_a` - The metadata of the coin A
/// * `metadata_b` - The metadata of the coin B
/// * `fix_amount_a` - Whether to fix the amount of the coin A
/// * `clock` - The clock object
/// * `ctx` - The transaction context
/// * Returns the position, coin A, and coin B
public fun create_pool_v2<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    initialize_price: u128,
    url: String,
    tick_lower_idx: u32,
    tick_upper_idx: u32,
    coin_a: Coin<CoinTypeA>,
    coin_b: Coin<CoinTypeB>,
    metadata_a: &CoinMetadata<CoinTypeA>,
    metadata_b: &CoinMetadata<CoinTypeB>,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext,
): (Position, Coin<CoinTypeA>, Coin<CoinTypeB>) {
    let lower_sqrt_price = get_sqrt_price_at_tick(i32::from_u32(tick_lower_idx));
    let upper_sqrt_price = get_sqrt_price_at_tick(i32::from_u32(tick_upper_idx));
    assert!(
        lower_sqrt_price < initialize_price && upper_sqrt_price > initialize_price,
        EInitSqrtPriceNotBetweenLowerAndUpper,
    );

    assert!(
        !factory::is_permission_pair<CoinTypeA, CoinTypeB>(pools, tick_spacing),
        EPoolIsPermission,
    );
    let (amount_a, amount_b) = (coin::value(&coin_a), coin::value(&coin_b));
    let (position, coin_a, coin_b) = factory::create_pool_v2_<CoinTypeA, CoinTypeB>(
        config,
        pools,
        tick_spacing,
        initialize_price,
        url,
        tick_lower_idx,
        tick_upper_idx,
        coin_a,
        coin_b,
        metadata_a,
        metadata_b,
        amount_a,
        amount_b,
        fix_amount_a,
        clock,
        ctx,
    );
    (position, coin_a, coin_b)
}

/// Get the full range tick range
/// * `tick_spacing` - The tick spacing
/// * Returns the full range tick range
public fun full_range_tick_range(tick_spacing: u32): (u32, u32) {
    let mod = i32::from_u32(tick_math::tick_bound() % tick_spacing);
    let full_min_tick = i32::add(tick_math::min_tick(), mod);
    let full_max_tick = i32::sub(tick_math::max_tick(), mod);
    (i32::as_u32(full_min_tick), i32::as_u32(full_max_tick))
}

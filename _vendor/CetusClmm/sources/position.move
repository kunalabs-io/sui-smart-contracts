// Copyright (c) Cetus Technology Limited

/// The `position` module is designed for the convenience of the `Pool`'s position and all `position` related
/// operations are completed by this module. Regarding the `position` of `clmmpool`,
/// there are several points that need to be explained:
///
/// 1. `clmmpool` specifies the ownership of the `position` through an `Object` named `position_nft`,
/// rather than a wallet address. This means that whoever owns the `position_nft` owns the position it holds.
/// This also means that `clmmpool`'s `position` can be transferred between users freely.
/// 2. `position_nft` records some basic information about the position, but these data do not participate in the
/// related calculations of the position, they are only used for display. The data that actually participates in the
/// calculation is stored in `position_info`, which corresponds one-to-one with `position_nft` and is stored in
/// `PositionManager`. The reason for this design is that in our other contracts, we need to read the information of
/// multiple positions in the `Pool`.
module cetus_clmm::position;

use cetus_clmm::config::{GlobalConfig, checked_package_version};
use cetus_clmm::tick_math;
use cetus_clmm::utils;
use integer_mate::full_math_u128;
use integer_mate::i32::{Self, I32};
use integer_mate::math_u128;
use integer_mate::math_u64;
use move_stl::linked_table;
use std::string::{Self, String, utf8};
use std::type_name::{Self, TypeName};
use sui::display;
use sui::package::{Self, Publisher};
use sui::tx_context::sender;

/// Consts
const NAME: vector<u8> = b"name";
const COIN_A: vector<u8> = b"coin_a";
const COIN_B: vector<u8> = b"coin_b";
const LINK: vector<u8> = b"link";
const IMAGE_URL: vector<u8> = b"image_url";
const DESCRIPTION: vector<u8> = b"description";
const PROJECT_URL: vector<u8> = b"project_url";
const CREATOR: vector<u8> = b"creator";
const DEFAULT_DESCRIPTION: vector<u8> = b"Cetus Liquidity Position";
const DEFAULT_LINK: vector<u8> = b"https://app.cetus.zone/position?chain=sui&id={id}";
const DEFAULT_PROJECT_URL: vector<u8> = b"https://cetus.zone";
const DEFAULT_CREATOR: vector<u8> = b"Cetus";

/// Errors
#[allow(unused_const)]
const ERemainderAmountUnderflow: u64 = 0;
const EFeeOwnedOverflow: u64 = 1;
const ERewardOwnedOverflow: u64 = 2;
const EPointsOwnedOverflow: u64 = 3;
#[allow(unused_const)]
const EInvalidDeltaLiquidity: u64 = 4;
const EInvalidPositionTickRange: u64 = 5;
const EPositionNotExist: u64 = 6;
const EPositionIsNotEmpty: u64 = 7;
const ELiquidityChangeOverflow: u64 = 8;
const ELiquidityChangeUnderflow: u64 = 9;
const EInvalidRewardIndex: u64 = 10;
const EPublisherNotMatchWithModule: u64 = 11;

/// The position manager for Cetus CLMM pools
/// * `tick_spacing` - The tick spacing for this position manager
/// * `position_index` - The index counter for positions
/// * `positions` - A linked table mapping position IDs to their PositionInfo
public struct PositionManager has store {
    tick_spacing: u32,
    position_index: u64,
    positions: linked_table::LinkedTable<ID, PositionInfo>,
}

public struct POSITION has drop {}

/// The Cetus clmmpool's position NFT.
/// * `id` - The unique identifier for this Position object
/// * `pool` - The pool ID
/// * `index` - The position index
/// * `coin_type_a` - The type name of coin A
/// * `coin_type_b` - The type name of coin B
/// * `name` - The name of the position
/// * `description` - The description of the position
/// * `url` - The URL of the position
/// * `tick_lower_index` - The lower tick index
/// * `tick_upper_index` - The upper tick index
/// * `liquidity` - The liquidity of the position
public struct Position has key, store {
    id: UID,
    pool: ID,
    index: u64,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    name: String,
    description: String,
    url: String,
    tick_lower_index: I32,
    tick_upper_index: I32,
    liquidity: u128,
}

/// The PositionInfo struct that stores the position info
/// * `position_id` - The unique identifier for this PositionInfo object
/// * `liquidity` - The liquidity of the position
/// * `tick_lower_index` - The lower tick index
/// * `tick_upper_index` - The upper tick index
/// * `fee_growth_inside_a` - The fee growth inside of coin A
/// * `fee_growth_inside_b` - The fee growth inside of coin B
/// * `fee_owned_a` - The fee owned of coin A
/// * `fee_owned_b` - The fee owned of coin B
/// * `points_owned` - The points owned of the position
/// * `points_growth_inside` - The points growth inside of the position
/// * `rewards` - The rewards of the position
public struct PositionInfo has copy, drop, store {
    position_id: ID,
    liquidity: u128,
    tick_lower_index: I32,
    tick_upper_index: I32,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
    fee_owned_a: u64,
    fee_owned_b: u64,
    points_owned: u128,
    points_growth_inside: u128,
    rewards: vector<PositionReward>,
}

/// The Position's rewarder
/// * `growth_inside` - The growth inside of the reward
/// * `amount_owned` - The amount owned of the reward
public struct PositionReward has copy, drop, store {
    growth_inside: u128,
    amount_owned: u64,
}

fun init(otw: POSITION, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);

    update_display_internal(
        &publisher,
        utf8(DEFAULT_DESCRIPTION),
        utf8(DEFAULT_LINK),
        utf8(DEFAULT_PROJECT_URL),
        utf8(DEFAULT_CREATOR),
        ctx,
    );
    transfer::public_transfer(publisher, sender(ctx));
}

#[allow(lint(self_transfer))]
/// Set `Display` for the position NFT.
/// * `config` - The global configuration
/// * `publisher` - The publisher of the position NFT
/// * `description` - The description of the position
/// * `link` - The link of the position
/// * `website` - The website of the position
/// * `creator` - The creator of the position
/// * `ctx` - The transaction context
public fun set_display(
    config: &GlobalConfig,
    publisher: &Publisher,
    description: String,
    link: String,
    project_url: String,
    creator: String,
    ctx: &mut TxContext,
) {
    checked_package_version(config);
    assert!(package::from_module<Position>(publisher), EPublisherNotMatchWithModule);
    update_display_internal(
        publisher,
        description,
        link,
        project_url,
        creator,
        ctx,
    );
}

#[allow(lint(self_transfer))]
fun update_display_internal(
    publisher: &Publisher,
    description: String,
    link: String,
    project_url: String,
    creator: String,
    ctx: &mut TxContext,
) {
    let keys = vector[
        utf8(NAME),
        utf8(COIN_A),
        utf8(COIN_B),
        utf8(LINK),
        utf8(IMAGE_URL),
        utf8(DESCRIPTION),
        utf8(PROJECT_URL),
        utf8(CREATOR),
    ];
    let values = vector[
        utf8(b"{name}"),
        utf8(b"{coin_type_a}"),
        utf8(b"{coin_type_b}"),
        link,
        utf8(b"{url}"),
        description,
        project_url,
        creator,
    ];
    let mut display = display::new_with_fields<Position>(
        publisher,
        keys,
        values,
        ctx,
    );
    display::update_version(&mut display);
    transfer::public_transfer(display, ctx.sender());
}

/// Create a new PositionManager
/// * `tick_spacing` - The tick spacing for this position manager
/// * `ctx` - The transaction context
/// * Returns a new PositionManager
public(package) fun new(tick_spacing: u32, ctx: &mut TxContext): PositionManager {
    PositionManager {
        tick_spacing,
        position_index: 0,
        positions: linked_table::new<ID, PositionInfo>(ctx),
    }
}

/// Open a position
/// * `manager` - The position manager
/// * `pool_id` - The pool ID
/// * `pool_index` - The pool index
/// * `url` - The URL of the position
/// * `tick_lower_index` - The lower tick index
/// * `tick_upper_index` - The upper tick index
/// * `ctx` - The transaction context
/// * Returns the position
public(package) fun open_position<CoinTypeA, CoinTypeB>(
    manager: &mut PositionManager,
    pool_id: ID,
    pool_index: u64,
    url: String,
    tick_lower_index: I32,
    tick_upper_index: I32,
    ctx: &mut TxContext,
): Position {
    check_position_tick_range(tick_lower_index, tick_upper_index, manager.tick_spacing);
    let position_index = manager.position_index + 1;
    let position_nft = Position {
        id: object::new(ctx),
        pool: pool_id,
        index: position_index,
        coin_type_a: type_name::get<CoinTypeA>(),
        coin_type_b: type_name::get<CoinTypeB>(),
        name: new_position_name(pool_index, position_index),
        description: string::utf8(DEFAULT_DESCRIPTION),
        url,
        tick_lower_index,
        tick_upper_index,
        liquidity: 0,
    };
    let position_id = object::id(&position_nft);
    let position_info = PositionInfo {
        position_id,
        liquidity: 0,
        tick_lower_index,
        tick_upper_index,
        fee_growth_inside_a: 0,
        fee_owned_a: 0,
        fee_growth_inside_b: 0,
        fee_owned_b: 0,
        rewards: vector::empty<PositionReward>(),
        //rewards: vector[
        //    default_rewarder_info(),
        //    default_rewarder_info(),
        //    default_rewarder_info(),
        //],
        points_owned: 0,
        points_growth_inside: 0,
    };
    linked_table::push_back(&mut manager.positions, position_id, position_info);
    manager.position_index = position_index;
    position_nft
}

/// Close the position, remove position_id from `PositionManager`, and destroy the position nft.
/// * `manager` - The position manager
/// * `position_nft` - The position NFT
public(package) fun close_position(manager: &mut PositionManager, position_nft: Position) {
    let position_id = object::id(&position_nft);
    let position_info = borrow_mut_position_info(manager, position_id);
    if (!is_empty(position_info)) {
        abort EPositionIsNotEmpty
    };
    linked_table::remove(&mut manager.positions, position_id);
    destroy(position_nft);
}

/// Remove the position info for restore
/// * `manager` - The position manager
/// * `position_id` - The position ID
public(package) fun remove_position_info_for_restore(
    manager: &mut PositionManager,
    position_id: ID,
) {
    assert!(linked_table::contains(&manager.positions, position_id), EPositionNotExist);
    linked_table::remove(&mut manager.positions, position_id);
}

/// Increase liquidity from position.
/// * `manager` - The position manager
/// * `position_nft` - The position NFT
/// * `delta_liquidity` - The liquidity to increase
/// * `fee_growth_inside_a` - The latest position range fee_growth_inside_a
/// * `fee_growth_inside_b` - The latest position range fee_growth_inside_b
/// * `points_growth_inside` - The latest position range points_growth_inside
/// * `rewards_growth_inside` - The latest position range rewards_growth_inside
/// * Returns the new liquidity
public(package) fun increase_liquidity(
    manager: &mut PositionManager,
    position_nft: &mut Position,
    delta_liquidity: u128,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
    points_growth_inside: u128,
    rewards_growth_inside: vector<u128>,
): u128 {
    let position_id = object::id(position_nft);
    let position_info = borrow_mut_position_info(manager, position_id);

    update_fee_internal(position_info, fee_growth_inside_a, fee_growth_inside_b);
    update_points_internal(position_info, points_growth_inside);
    update_rewards_internal(position_info, rewards_growth_inside);
    assert!(
        math_u128::add_check(position_info.liquidity, delta_liquidity),
        ELiquidityChangeOverflow,
    );
    position_info.liquidity = position_info.liquidity + delta_liquidity;
    position_nft.liquidity = position_info.liquidity;

    position_info.liquidity
}

/// Decrease liquidity from position.
/// * `manager` - The position manager
/// * `position_nft` - The position NFT
/// * `delta_liquidity` - The liquidity to decrease
/// * `fee_growth_inside_a` - The latest position range fee_growth_inside_a
/// * `fee_growth_inside_b` - The latest position range fee_growth_inside_b
/// * `points_growth_inside` - The latest position range points_growth_inside
/// * `rewards_growth_inside` - The latest position range rewards_growth_inside
public(package) fun decrease_liquidity(
    manager: &mut PositionManager,
    position_nft: &mut Position,
    delta_liquidity: u128,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
    points_growth_inside: u128,
    rewards_growth_inside: vector<u128>,
): u128 {
    let position_id = object::id(position_nft);
    let position_info = borrow_mut_position_info(manager, position_id);
    if (delta_liquidity == 0) {
        return position_info.liquidity
    };

    update_fee_internal(position_info, fee_growth_inside_a, fee_growth_inside_b);
    update_points_internal(position_info, points_growth_inside);
    update_rewards_internal(position_info, rewards_growth_inside);
    assert!(position_info.liquidity >= delta_liquidity, ELiquidityChangeUnderflow);
    position_info.liquidity = position_info.liquidity - delta_liquidity;
    position_nft.liquidity = position_info.liquidity;

    position_info.liquidity
}

/// Apply liquidity cut to the position.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * `delta_liquidity` - The liquidity to decrease
/// * `fee_growth_inside_a` - The latest position range fee_growth_inside_a
/// * `fee_growth_inside_b` - The latest position range fee_growth_inside_b
/// * `points_growth_inside` - The latest position range points_growth_inside
/// * `rewards_growth_inside` - The latest position range rewards_growth_inside
/// * Returns the new liquidity
public(package) fun apply_liquidity_cut(
    manager: &mut PositionManager,
    position_id: ID,
    delta_liquidity: u128,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
    points_growth_inside: u128,
    rewards_growth_inside: vector<u128>,
): u128 {
    let position_info = borrow_mut_position_info(manager, position_id);
    if (delta_liquidity == 0) {
        return position_info.liquidity
    };

    update_fee_internal(position_info, fee_growth_inside_a, fee_growth_inside_b);
    update_points_internal(position_info, points_growth_inside);
    update_rewards_internal(position_info, rewards_growth_inside);
    assert!(position_info.liquidity >= delta_liquidity, ELiquidityChangeUnderflow);
    position_info.liquidity = position_info.liquidity - delta_liquidity;

    position_info.liquidity
}

/// Update `PositionInfo` fee, return the fee_owned.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * `fee_growth_inside_a` - The latest position range fee_growth_inside_a
/// * `fee_growth_inside_b` - The latest position range fee_growth_inside_b
/// * Returns the fee_owned
public(package) fun update_fee(
    manager: &mut PositionManager,
    position_id: ID,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
): (u64, u64) {
    let position_info = borrow_mut_position_info(manager, position_id);
    update_fee_internal(position_info, fee_growth_inside_a, fee_growth_inside_b);
    info_fee_owned(position_info)
}

/// Update `PositionInfo` points, return the points_owned.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * `points_growth_inside` - The latest position range points_growth_inside
/// * Returns the points_owned
public(package) fun update_points(
    manager: &mut PositionManager,
    position_id: ID,
    points_growth_inside: u128,
): u128 {
    let position_info = borrow_mut_position_info(manager, position_id);
    update_points_internal(position_info, points_growth_inside);
    position_info.points_owned
}

/// Update `PositionInfo` rewards, return the amount_owned vector.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * `rewards_growth_inside` - The latest position range rewards_growth_inside
/// * Returns the amount_owned vector
public(package) fun update_rewards(
    manager: &mut PositionManager,
    position_id: ID,
    rewards_growth_inside: vector<u128>,
): vector<u64> {
    let position_info = borrow_mut_position_info(manager, position_id);
    update_rewards_internal(position_info, rewards_growth_inside);
    let rewards = info_rewards(position_info);
    let mut idx = 0;
    let length = vector::length(rewards);
    let mut owned_amounts = vector::empty<u64>();
    while (idx < length) {
        let reward = vector::borrow(rewards, idx);
        vector::push_back(&mut owned_amounts, reward_amount_owned(reward));
        idx = idx + 1;
    };
    owned_amounts
}

/// Update `PositionInfo` fee, reset the fee_owned_a and fee_owned_b and return the amount_owned.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * `fee_growth_inside_a` - The latest position range fee_growth_inside_a
/// * `fee_growth_inside_b` - The latest position range fee_growth_inside_b
/// * Returns the amount_owned
public(package) fun update_and_reset_fee(
    manager: &mut PositionManager,
    position_id: ID,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
): (u64, u64) {
    let position_info = borrow_mut_position_info(manager, position_id);
    update_fee_internal(position_info, fee_growth_inside_a, fee_growth_inside_b);
    let (owned_a, owned_b) = (position_info.fee_owned_a, position_info.fee_owned_b);
    position_info.fee_owned_a = 0;
    position_info.fee_owned_b = 0;
    (owned_a, owned_b)
}

/// Update `PositionInfo` rewards
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * `rewards_growth_inside` - The latest position range rewards_growth_inside
/// * `rewarder_idx` - The rewarder index
/// * Returns the amount_owned
public(package) fun update_and_reset_rewards(
    manager: &mut PositionManager,
    position_id: ID,
    rewards_growth_inside: vector<u128>,
    rewarder_idx: u64,
): u64 {
    assert!(vector::length(&rewards_growth_inside) > rewarder_idx, EInvalidRewardIndex);
    let position_info = borrow_mut_position_info(manager, position_id);
    update_rewards_internal(position_info, rewards_growth_inside);
    let position_rewarder = vector::borrow_mut(&mut position_info.rewards, rewarder_idx);
    let amount_owned = position_rewarder.amount_owned;
    position_rewarder.amount_owned = 0;
    amount_owned
}

/// Reset the fee's amount owned to 0 and return the fee amount owned.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * Returns the fee amount owned
public(package) fun reset_fee(manager: &mut PositionManager, position_id: ID): (u64, u64) {
    let position_info = borrow_mut_position_info(manager, position_id);
    let (owned_a, owned_b) = (position_info.fee_owned_a, position_info.fee_owned_b);
    position_info.fee_owned_a = 0;
    position_info.fee_owned_b = 0;
    (owned_a, owned_b)
}

/// Reset the rewarder's amount owned to 0 and return the reward num owned.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * `rewarder_idx` - The rewarder index
/// * Returns the reward amount owned
public(package) fun reset_rewarder(
    manager: &mut PositionManager,
    position_id: ID,
    rewarder_idx: u64,
): u64 {
    let position_info = borrow_mut_position_info(manager, position_id);
    let position_rewarder = vector::borrow_mut(&mut position_info.rewards, rewarder_idx);
    let amount_owned = position_rewarder.amount_owned;
    position_rewarder.amount_owned = 0;
    amount_owned
}

/// the inited reward count in `PositionInfo`.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * Returns the inited reward count
public fun inited_rewards_count(manager: &PositionManager, position_id: ID): u64 {
    let position_info = borrow_position_info(manager, position_id);
    vector::length(&position_info.rewards)
}

/// Fetch `PositionInfo` List.
/// * `manager` - The position manager
/// * `start` - The start position id
/// * `limit` - The max count of `PositionInfo` to fetch
/// * Returns the `PositionInfo` list
public fun fetch_positions(
    manager: &PositionManager,
    start: vector<ID>,
    limit: u64,
): vector<PositionInfo> {
    if (limit == 0) {
        return vector::empty<PositionInfo>()
    };
    let mut positions = vector::empty<PositionInfo>();
    let mut next_position_id = if (vector::is_empty(&start)) {
        linked_table::head(&manager.positions)
    } else {
        let pos_id = *vector::borrow(&start, 0);
        assert!(linked_table::contains(&manager.positions, pos_id), EPositionNotExist);
        option::some(pos_id)
    };
    let mut count = 0;
    while (option::is_some(&next_position_id)) {
        let address = *option::borrow(&next_position_id);
        let node = linked_table::borrow_node(&manager.positions, address);
        next_position_id = linked_table::next(node);
        let position_info = *linked_table::borrow_value(node);
        vector::push_back(&mut positions, position_info);
        count = count + 1;
        if (count == limit) {
            break
        }
    };
    positions
}

/// Get the pool_id of a position.
/// * `position_nft` - The position NFT
/// * Returns the pool ID
public fun pool_id(position_nft: &Position): ID {
    position_nft.pool
}

/// Get the tick range tuple of position.
/// * `position_nft` - The position NFT
/// * Returns the tick range tuple
public fun tick_range(position_nft: &Position): (I32, I32) {
    (position_nft.tick_lower_index, position_nft.tick_upper_index)
}

/// Get the index of position.
/// * `position_nft` - The position NFT
/// * Returns the index
public fun index(position_nft: &Position): u64 {
    position_nft.index
}

/// Get the name of position.
/// * `position_nft` - The position NFT
/// * Returns the name
public fun name(position_nft: &Position): String {
    position_nft.name
}

/// Get the description of position.
/// * `position_nft` - The position NFT
/// * Returns the description
public fun description(position_nft: &Position): String {
    position_nft.description
}

/// Get the url of position.
/// * `position_nft` - The position NFT
/// * Returns the url
public fun url(position_nft: &Position): String {
    position_nft.url
}

/// Get the liquidity of position.
/// * `position_nft` - The position NFT
/// * Returns the liquidity
public fun liquidity(position_nft: &Position): u128 {
    position_nft.liquidity
}

/// Get the position_id of `PositionInfo`.
/// * `info` - The `PositionInfo`
/// * Returns the position ID
public fun info_position_id(info: &PositionInfo): ID {
    info.position_id
}

/// Get the liquidity of `PositionInfo`.
/// * `info` - The `PositionInfo`
/// * Returns the liquidity
public fun info_liquidity(info: &PositionInfo): u128 {
    info.liquidity
}

/// Get the tick range tuple of `PositionInfo`.
/// * `info` - The `PositionInfo`
/// * Returns the tick range tuple
public fun info_tick_range(info: &PositionInfo): (I32, I32) {
    (info.tick_lower_index, info.tick_upper_index)
}

/// Get the fee_growth_inside tuple of `PositionInfo`.
/// * `info` - The `PositionInfo`
/// * Returns the fee growth inside tuple
public fun info_fee_growth_inside(info: &PositionInfo): (u128, u128) {
    (info.fee_growth_inside_a, info.fee_growth_inside_b)
}

/// Get the fee_owned tuple of `PositionInfo`.
/// * `info` - The `PositionInfo`
/// * Returns the fee owned tuple
public fun info_fee_owned(info: &PositionInfo): (u64, u64) {
    (info.fee_owned_a, info.fee_owned_b)
}

/// Get the points_owned of `PositionInfo`.
/// * `info` - The `PositionInfo`
/// * Returns the points owned
public fun info_points_owned(info: &PositionInfo): u128 {
    info.points_owned
}

/// Get the points_growth_inside of `PositionInfo`.
/// * `info` - The `PositionInfo`
/// * Returns the points growth inside
public fun info_points_growth_inside(info: &PositionInfo): u128 {
    info.points_growth_inside
}

/// Get the rewards of `PositionInfo`.
/// * `info` - The `PositionInfo`
/// * Returns the rewards
public fun info_rewards(info: &PositionInfo): &vector<PositionReward> {
    &info.rewards
}

/// Returns the reward growth by `PositionReward`.
/// * `reward` - The `PositionReward`
/// * Returns the reward growth
public fun reward_growth_inside(reward: &PositionReward): u128 {
    reward.growth_inside
}

/// Returns the reward owned by `PositionReward`.
/// * `reward` - The `PositionReward`
/// * Returns the reward amount owned
public fun reward_amount_owned(reward: &PositionReward): u64 {
    reward.amount_owned
}

/// Returns the amount of rewards owned by the position.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * Returns the rewards amount owned vector
public(package) fun rewards_amount_owned(manager: &PositionManager, position_id: ID): vector<u64> {
    let position_info = borrow_position_info(manager, position_id);
    let rewards = info_rewards(position_info);
    let mut idx = 0;
    let length = vector::length(rewards);
    let mut owned_amounts = vector::empty<u64>();
    while (idx < length) {
        let reward = vector::borrow(rewards, idx);
        vector::push_back(&mut owned_amounts, reward_amount_owned(reward));
        idx = idx + 1;
    };
    owned_amounts
}

/// Borrow `PositionInfo` by position_id.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * Returns the `PositionInfo`
public fun borrow_position_info(manager: &PositionManager, position_id: ID): &PositionInfo {
    assert!(linked_table::contains(&manager.positions, position_id), EPositionNotExist);
    let position_info = linked_table::borrow(&manager.positions, position_id);
    assert!(position_info.position_id == position_id, EPositionNotExist);
    position_info
}

/// Check if a position is empty
/// 1. liquidity == 0
/// 2. fee_owned_a == 0
/// 3. fee_owned_b == 0
/// 4. [reward.amount_owned == 0 for reward in position_info.rewards]
/// * `position_info` - The `PositionInfo`
/// * Returns true if the position is empty, false otherwise
public fun is_empty(position_info: &PositionInfo): bool {
    let mut rewards_is_empty = true;
    let mut i = 0;
    while (i < vector::length(&position_info.rewards)) {
        rewards_is_empty =
            rewards_is_empty && vector::borrow(&position_info.rewards, i).amount_owned == 0;
        i = i + 1;
    };
    position_info.liquidity == 0
            && position_info.fee_owned_a == 0
            && position_info.fee_owned_b == 0
            && rewards_is_empty
}

/// Check if a position tick range is valid.
/// 1. lower < upper
/// 2. (lower >= min_tick) && (upper <= max_tick)
/// 3. (lower % tick_spacing == 0) && (upper % tick_spacing == 0)
/// * `lower` - The lower tick index
/// * `upper` - The upper tick index
/// * `tick_spacing` - The tick spacing
public fun check_position_tick_range(lower: I32, upper: I32, tick_spacing: u32) {
    assert!(
        i32::lt(lower, upper) &&
                i32::gte(lower, tick_math::min_tick()) &&
                i32::lte(upper, tick_math::max_tick()) &&
                i32::mod(lower, i32::from(tick_spacing)) == i32::zero() &&
                i32::mod(upper, i32::from(tick_spacing)) == i32::zero(),
        EInvalidPositionTickRange,
    );
}

/// check if the position exists in `PositionManager` by position_id.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * Returns true if the position exists, false otherwise
public fun is_position_exist(manager: &PositionManager, position_id: ID): bool {
    linked_table::contains(&manager.positions, position_id)
}

/// Update position rewards.
/// * `position_info` - The `PositionInfo`
/// * `rewards_growths_inside` - The rewards growth inside vector
fun update_rewards_internal(
    position_info: &mut PositionInfo,
    rewards_growths_inside: vector<u128>,
) {
    let rewards_count = vector::length(&rewards_growths_inside);
    let inited_count = vector::length(&position_info.rewards);
    if (rewards_count > 0) {
        let mut idx = 0;
        while (idx < rewards_count) {
            let current_growth = *vector::borrow(&rewards_growths_inside, idx);
            if (inited_count > idx) {
                let rewarder = vector::borrow_mut(&mut position_info.rewards, idx);
                let growth_delta = math_u128::wrapping_sub(current_growth, rewarder.growth_inside);
                let amount_owend_delta_ = full_math_u128::mul_shr(
                    growth_delta,
                    position_info.liquidity,
                    64,
                );
                assert!(
                    amount_owend_delta_ <= std::u64::max_value!() as u128,
                    ERewardOwnedOverflow,
                );
                let amount_owend_delta = (amount_owend_delta_ as u64);
                assert!(
                    math_u64::add_check(rewarder.amount_owned, amount_owend_delta),
                    ERewardOwnedOverflow,
                );
                rewarder.growth_inside = current_growth;
                rewarder.amount_owned = rewarder.amount_owned + amount_owend_delta;
            } else {
                let amount_owend_delta_ = full_math_u128::mul_shr(
                    current_growth,
                    position_info.liquidity,
                    64,
                );
                assert!(
                    amount_owend_delta_ <= std::u64::max_value!() as u128,
                    ERewardOwnedOverflow,
                );
                let amount_owend_delta = (amount_owend_delta_ as u64);
                vector::push_back(
                    &mut position_info.rewards,
                    PositionReward {
                        growth_inside: current_growth,
                        amount_owned: amount_owend_delta,
                    },
                )
            };
            idx = idx + 1;
        };
    };
}

/// Update position fee.
/// * `position_info` - The `PositionInfo`
/// * `fee_growth_inside_a` - The fee growth inside of coin A
/// * `fee_growth_inside_b` - The fee growth inside of coin B
fun update_fee_internal(
    position_info: &mut PositionInfo,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
) {
    let growth_delta_a = math_u128::wrapping_sub(
        fee_growth_inside_a,
        position_info.fee_growth_inside_a,
    );
    let fee_delta_a_ = full_math_u128::mul_shr(position_info.liquidity, growth_delta_a, 64);
    assert!(fee_delta_a_ <= std::u64::max_value!() as u128, EFeeOwnedOverflow);
    let fee_delta_a = (fee_delta_a_ as u64);
    let growth_delta_b = math_u128::wrapping_sub(
        fee_growth_inside_b,
        position_info.fee_growth_inside_b,
    );
    let fee_delta_b_ = full_math_u128::mul_shr(position_info.liquidity, growth_delta_b, 64);
    assert!(fee_delta_b_ <= std::u64::max_value!() as u128, EFeeOwnedOverflow);
    let fee_delta_b = (fee_delta_b_ as u64);
    assert!(math_u64::add_check(position_info.fee_owned_a, fee_delta_a), EFeeOwnedOverflow);
    assert!(math_u64::add_check(position_info.fee_owned_b, fee_delta_b), EFeeOwnedOverflow);
    position_info.fee_owned_a = position_info.fee_owned_a + fee_delta_a;
    position_info.fee_owned_b = position_info.fee_owned_b + fee_delta_b;
    position_info.fee_growth_inside_a = fee_growth_inside_a;
    position_info.fee_growth_inside_b = fee_growth_inside_b;
}

/// Update position points.
/// * `position_info` - The `PositionInfo`
/// * `points_growth_inside` - The points growth inside
fun update_points_internal(position_info: &mut PositionInfo, points_growth_inside: u128) {
    let growth_delta = math_u128::wrapping_sub(
        points_growth_inside,
        position_info.points_growth_inside,
    );
    let points_delta = full_math_u128::mul_shr(position_info.liquidity, growth_delta, 64);
    assert!(math_u128::add_check(position_info.points_owned, points_delta), EPointsOwnedOverflow);
    position_info.points_owned = position_info.points_owned + points_delta;
    position_info.points_growth_inside = points_growth_inside;
}

/// Generate position name by pool_index and position_index.
/// * `pool_index` - The pool index
/// * `position_index` - The position index
/// * Returns the position name
fun new_position_name(pool_index: u64, position_index: u64): String {
    let mut name = string::utf8(b"Cetus LP | Pool");
    string::append(&mut name, utils::str(pool_index));
    string::append_utf8(&mut name, b"-");
    string::append(&mut name, utils::str(position_index));
    name
}

/// borrow mutable `PositionInfo` by position_id.
/// * `manager` - The position manager
/// * `position_id` - The position ID
/// * Returns the mutable `PositionInfo`
fun borrow_mut_position_info(manager: &mut PositionManager, position_id: ID): &mut PositionInfo {
    assert!(linked_table::contains(&manager.positions, position_id), EPositionNotExist);
    let position_info = linked_table::borrow_mut(&mut manager.positions, position_id);
    assert!(position_info.position_id == position_id, EPositionNotExist);
    position_info
}

/// Destory `Position`.
/// * `position_nft` - The position NFT
fun destroy(position_nft: Position) {
    let Position {
        id,
        pool: _,
        index: _,
        coin_type_a: _,
        coin_type_b: _,
        name: _,
        description: _,
        url: _,
        tick_lower_index: _,
        tick_upper_index: _,
        liquidity: _,
    } = position_nft;
    object::delete(id);
}

#[test_only]
public fun new_position_info_for_test(): PositionInfo {
    let position_info = PositionInfo {
        position_id: object::id_from_address(@1234),
        liquidity: 1000000000,
        tick_lower_index: i32::from_u32(0),
        tick_upper_index: i32::from_u32(1000),
        fee_growth_inside_a: 0,
        fee_owned_a: 0,
        fee_growth_inside_b: 0,
        fee_owned_b: 0,
        rewards: vector::empty<PositionReward>(),
        points_owned: 0,
        points_growth_inside: 0,
    };
    position_info
}

#[test_only]
public fun new_position_info_for_test_from_address(addr: address): PositionInfo {
    let position_info = PositionInfo {
        position_id: object::id_from_address(addr),
        liquidity: 1000000000,
        tick_lower_index: i32::from_u32(0),
        tick_upper_index: i32::from_u32(1000),
        fee_growth_inside_a: 0,
        fee_owned_a: 0,
        fee_growth_inside_b: 0,
        fee_owned_b: 0,
        rewards: vector::empty<PositionReward>(),
        points_owned: 0,
        points_growth_inside: 0,
    };
    position_info
}

#[test_only]
public fun positions(m: &PositionManager): &linked_table::LinkedTable<ID, PositionInfo> {
    &m.positions
}

#[test_only]
public fun mut_positions(
    m: &mut PositionManager,
): &mut linked_table::LinkedTable<ID, PositionInfo> {
    &mut m.positions
}

#[test_only]
public fun update_points_internal_test(
    position_info: &mut PositionInfo,
    points_growth_inside: u128,
) {
    update_points_internal(position_info, points_growth_inside);
}

#[test_only]
public fun update_fee_internal_test(
    position_info: &mut PositionInfo,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
) {
    update_fee_internal(position_info, fee_growth_inside_a, fee_growth_inside_b);
}

#[test_only]
public fun update_rewards_internal_test(
    position_info: &mut PositionInfo,
    rewards_growths_inside: vector<u128>,
) {
    update_rewards_internal(position_info, rewards_growths_inside);
}

#[test_only]
public fun new_position_info_custom(
    liquidity: u128,
    tick_lower_index: I32,
    tick_upper_index: I32,
    fee_growth_inside_a: u128,
    fee_growth_inside_b: u128,
    fee_owned_a: u64,
    fee_owned_b: u64,
    rewards: vector<PositionReward>,
    points_owned: u128,
    points_growth_inside: u128,
): PositionInfo {
    PositionInfo {
        position_id: object::id_from_address(@1234),
        liquidity,
        tick_lower_index,
        tick_upper_index,
        fee_growth_inside_a,
        fee_owned_a,
        fee_growth_inside_b,
        fee_owned_b,
        rewards,
        points_owned,
        points_growth_inside,
    }
}

#[test_only]
public fun new_position_reward_for_test(growth_inside: u128, amount_owned: u64): PositionReward {
    PositionReward {
        growth_inside,
        amount_owned,
    }
}

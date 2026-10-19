module cetus_clmm::position_snapshot;

use cetus_clmm::position::{Self, PositionInfo};
use integer_mate::full_math_u128;
use integer_mate::i32::I32;
use move_stl::linked_table;

// Parts Per Million
const PPM: u64 = 1000000;

const EPositionSnapshotAlreadyExists: u64 = 1;
const EPositionSnapshotNotFound: u64 = 2;

/// PositionLiquiditySnapshot struct that stores the snapshot of the position 
/// * `id` - The unique identifier for this PositionLiquiditySnapshot object
/// * `current_sqrt_price` - The current sqrt price
/// * `remove_percent` - The remove percent
/// * `total_value_cut` - The total value cut
/// * `snapshots` - A linked table storing the snapshots of the position
public struct PositionLiquiditySnapshot has key, store {
    id: UID,
    current_sqrt_price: u128,
    remove_percent: u64,
    total_value_cut: u64,
    snapshots: linked_table::LinkedTable<ID, PositionSnapshot>,
}

/// PositionSnapshot of a position
/// * `position_id` - position id
/// * `liquidity` - liquidity of the position
/// * `tick_lower_index` - lower tick index
/// * `tick_upper_index` - upper tick index
/// * `fee_owned_a` - The fee owned by the position a
/// * `fee_owned_b` - The fee owned by the position b
/// * `rewards` - The rewards of the position
/// * `value_cut` - The value cut of the position
public struct PositionSnapshot has copy, drop, store {
    position_id: ID,
    liquidity: u128,
    tick_lower_index: I32,
    tick_upper_index: I32,
    fee_owned_a: u64,
    fee_owned_b: u64,
    rewards: vector<u64>,
    value_cut: u64,
}

/// Create a new PositionLiquiditySnapshot
/// * `current_sqrt_price` - The current sqrt price
/// * `remove_percent` - The remove percent
/// * `ctx` - The transaction context
/// * Returns a new PositionLiquiditySnapshot
public(package) fun new(
    current_sqrt_price: u128,
    remove_percent: u64,
    ctx: &mut TxContext,
): PositionLiquiditySnapshot {
    PositionLiquiditySnapshot {
        id: object::new(ctx),
        current_sqrt_price,
        remove_percent,
        total_value_cut: 0,
        snapshots: linked_table::new(ctx),
    }
}

/// Get the remove percent of the PositionLiquiditySnapshot
/// * `snapshot` - The PositionLiquiditySnapshot
/// * Returns the remove percent
public fun remove_percent(snapshot: &PositionLiquiditySnapshot): u64 {
    snapshot.remove_percent
}

/// Get the current sqrt price of the PositionLiquiditySnapshot
/// * `snapshot` - The PositionLiquiditySnapshot
/// * Returns the current sqrt price
public fun current_sqrt_price(snapshot: &PositionLiquiditySnapshot): u128 {
    snapshot.current_sqrt_price
}

/// Get the total value cut of the PositionLiquiditySnapshot
/// * `snapshot` - The PositionLiquiditySnapshot
/// * Returns the total value cut
public fun total_value_cut(snapshot: &PositionLiquiditySnapshot): u64 {
    snapshot.total_value_cut
}

/// Get the value cut of the PositionSnapshot
/// * `snapshot` - The PositionSnapshot
/// * Returns the value cut
public fun value_cut(snapshot: &PositionSnapshot): u64 {
    snapshot.value_cut
}

/// Get the rewards of the PositionSnapshot
/// * `snapshot` - The PositionSnapshot
/// * Returns the rewards
public fun rewards(snapshot: &PositionSnapshot): vector<u64> {
    snapshot.rewards
}

/// Get the fee owned of the PositionSnapshot
/// * `snapshot` - The PositionSnapshot
/// * Returns
public fun fee_owned(snapshot: &PositionSnapshot): (u64, u64) {
    (snapshot.fee_owned_a, snapshot.fee_owned_b)
}

/// Get the tick range of the PositionSnapshot
/// * `snapshot` - The PositionSnapshot
/// * Returns the tick range
public fun tick_range(snapshot: &PositionSnapshot): (I32, I32) {
    (snapshot.tick_lower_index, snapshot.tick_upper_index)
}

/// Get the liquidity of the PositionSnapshot
/// * `snapshot` - The PositionSnapshot
/// * Returns the liquidity
public fun liquidity(snapshot: &PositionSnapshot): u128 {
    snapshot.liquidity
}

/// Get the position id of the PositionSnapshot
/// * `snapshot` - The PositionSnapshot
/// * Returns the position id
public fun position_id(snapshot: &PositionSnapshot): ID {
    snapshot.position_id
}

/// Calculate the remove liquidity
/// * `snapshot` - The PositionLiquiditySnapshot
/// * `position_info` - The position info
/// * Returns the remove liquidity
public fun calculate_remove_liquidity(
    snapshot: &PositionLiquiditySnapshot,
    position_info: &PositionInfo,
): u128 {
    let liquidity = position::info_liquidity(position_info);
    full_math_u128::mul_div_ceil((snapshot.remove_percent as u128), liquidity, (PPM as u128))
}

/// Add a new PositionSnapshot to the PositionLiquiditySnapshot
/// * `snapshot` - The PositionLiquiditySnapshot
/// * `position_id` - The position id
/// * `value_cut` - The value cut
/// * `position_info` - The position info
public(package) fun add(
    snapshot: &mut PositionLiquiditySnapshot,
    position_id: ID,
    value_cut: u64,
    position_info: PositionInfo,
) {
    assert!(
        !linked_table::contains(&snapshot.snapshots, position_id),
        EPositionSnapshotAlreadyExists,
    );
    let mut rewards = vector::empty<u64>();
    let mut idx = 0;
    let reward_infos = position::info_rewards(&position_info);
    while (idx < vector::length(reward_infos)) {
        let reward = vector::borrow(reward_infos, idx);
        let amount_owned = position::reward_amount_owned(reward);
        vector::push_back(&mut rewards, amount_owned);
        idx = idx + 1;
    };
    let (tick_lower_index, tick_upper_index) = position::info_tick_range(&position_info);
    let (fee_owned_a, fee_owned_b) = position::info_fee_owned(&position_info);
    let position_snapshot = PositionSnapshot {
        position_id,
        liquidity: position::info_liquidity(&position_info),
        tick_lower_index,
        tick_upper_index,
        fee_owned_a,
        fee_owned_b,
        rewards,
        value_cut,
    };
    snapshot.total_value_cut = snapshot.total_value_cut + value_cut;
    linked_table::push_back(&mut snapshot.snapshots, position_id, position_snapshot);
}

/// Get the PositionSnapshot from the PositionLiquiditySnapshot
/// * `snapshot` - The PositionLiquiditySnapshot
/// * `position_id` - The position id
/// * Returns the PositionSnapshot
public fun get(snapshot: &PositionLiquiditySnapshot, position_id: ID): PositionSnapshot {
    assert!(linked_table::contains(&snapshot.snapshots, position_id), EPositionSnapshotNotFound);
    *linked_table::borrow(&snapshot.snapshots, position_id)
}

/// Check if the PositionLiquiditySnapshot contains the PositionSnapshot
/// * `snapshot` - The PositionLiquiditySnapshot
/// * `position_id` - The position id
/// * Returns true if the PositionLiquiditySnapshot contains the PositionSnapshot for the position id, false otherwise
public fun contains(snapshot: &PositionLiquiditySnapshot, position_id: ID): bool {
    linked_table::contains(&snapshot.snapshots, position_id)
}

/// Remove the PositionSnapshot from the PositionLiquiditySnapshot
/// * `snapshot` - The PositionLiquiditySnapshot
/// * `position_id` - The position id
public(package) fun remove(snapshot: &mut PositionLiquiditySnapshot, position_id: ID) {
    assert!(linked_table::contains(&snapshot.snapshots, position_id), EPositionSnapshotNotFound);
    let position_snapshot = linked_table::remove(&mut snapshot.snapshots, position_id);
    snapshot.total_value_cut = snapshot.total_value_cut - position_snapshot.value_cut;
}

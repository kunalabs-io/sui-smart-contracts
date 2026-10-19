#[test_only]
module cetus_clmm::position_snapshot_tests;


use cetus_clmm::position::new_position_info_custom;
use integer_mate::i32;
use cetus_clmm::position::new_position_reward_for_test;
use cetus_clmm::tick_math::get_sqrt_price_at_tick;
use cetus_clmm::position_snapshot;
use std::unit_test::assert_eq;

#[test]
fun test_calculate_remove_liquidity() {
    let position_info = new_position_info_custom(
        591619209017,
        i32::from_u32(0),
        i32::from_u32(1000),
        0,
        0,
        0,
        0,
        vector[
            new_position_reward_for_test(2 << 89, 0),
            new_position_reward_for_test(2 << 90, 0),
            new_position_reward_for_test(3 << 91, 0),
        ],
        0,
        0,
    );
    let current_sqrt_price = get_sqrt_price_at_tick(i32::from_u32(0));
    let mut ctx = tx_context::dummy();
    let position_liquidity_snapshot = position_snapshot::new(current_sqrt_price, 5000,&mut  ctx);
    let remove_liquidity = position_liquidity_snapshot.calculate_remove_liquidity(&position_info);
    assert!(remove_liquidity == 591619209017 * 5000 / 1000000 + 1, 1);
    transfer::public_share_object(position_liquidity_snapshot);
}

#[test]
fun test_snapshot_add_and_remove() {
    let position_info = new_position_info_custom(
        591619209017,
        i32::from_u32(0),
        i32::from_u32(1000),
        0,
        0,
        0,
        0,
        vector[
            new_position_reward_for_test(2 << 89, 0),
            new_position_reward_for_test(2 << 90, 0),
            new_position_reward_for_test(3 << 91, 0),
        ],
        0,
        0,
    );
    let current_sqrt_price = get_sqrt_price_at_tick(i32::from_u32(0));
    let mut ctx = tx_context::dummy();
    let mut position_liquidity_snapshot = position_snapshot::new(current_sqrt_price, 5000,&mut  ctx);
    position_liquidity_snapshot.add(object::id_from_address(@1234), 5000, position_info);
    let snapshot = position_liquidity_snapshot.get(object::id_from_address(@1234));
    assert!(snapshot.liquidity() == 591619209017, 1);
    assert_eq!(snapshot.value_cut(),5000);
    assert_eq!(snapshot.position_id(), object::id_from_address(@1234));
    let (tick_lower_index, tick_upper_index) = snapshot.tick_range();
    assert!(tick_lower_index == i32::from_u32(0), 2);
    assert!(tick_upper_index == i32::from_u32(1000), 3);
    let (fee_owned_a, fee_owned_b) = snapshot.fee_owned();
    assert!(fee_owned_a == 0, 4);
    assert!(fee_owned_b == 0, 5);
    let rewards = snapshot.rewards();
    assert!(rewards.length() == 3, 6);
    assert!(position_liquidity_snapshot.total_value_cut() == 5000, 7);
    assert!(position_liquidity_snapshot.current_sqrt_price() == current_sqrt_price, 8);
    assert!(position_liquidity_snapshot.remove_percent() == 5000, 9);
    assert!(position_liquidity_snapshot.contains(object::id_from_address(@1234)), 10);
    position_liquidity_snapshot.remove(object::id_from_address(@1234));
    assert!(!position_liquidity_snapshot.contains(object::id_from_address(@1234)), 11);
    transfer::public_share_object(position_liquidity_snapshot);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position_snapshot::EPositionSnapshotAlreadyExists)]
fun test_add_snapshot_already_exists(){
    let mut ctx = tx_context::dummy();
    let mut snapshot = position_snapshot::new(get_sqrt_price_at_tick(i32::from_u32(0)), 5000, &mut ctx);
    let position_info = new_position_info_custom(
        591619209017,
        i32::from_u32(0),
        i32::from_u32(1000),
        0,
        0,
        0,
        0,
        vector[
            new_position_reward_for_test(2 << 89, 0),
            new_position_reward_for_test(2 << 90, 0),
            new_position_reward_for_test(3 << 91, 0),
        ],
        0,
        0,
    );
    snapshot.add(object::id_from_address(@1234), 500, position_info);
    snapshot.add(object::id_from_address(@1234), 500, position_info); 
    transfer::public_share_object(snapshot);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position_snapshot::EPositionSnapshotNotFound)]
fun test_snapshot_remove_not_exists(){
    let mut ctx = tx_context::dummy();
    let mut snapshot = position_snapshot::new(get_sqrt_price_at_tick(i32::from_u32(0)), 5000, &mut ctx);
    snapshot.remove(object::id_from_address(@1234));
    transfer::public_share_object(snapshot);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position_snapshot::EPositionSnapshotNotFound)]
fun test_snapshot_get_not_exists(){
    let mut ctx = tx_context::dummy();
    let snapshot = position_snapshot::new(get_sqrt_price_at_tick(i32::from_u32(0)), 5000, &mut ctx);
    snapshot.get(object::id_from_address(@1234));
    transfer::public_share_object(snapshot);
}
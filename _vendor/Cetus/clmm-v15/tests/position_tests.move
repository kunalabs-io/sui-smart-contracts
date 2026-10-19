#[test_only]
module cetus_clmm::position_tests;

use cetus_clmm::position::{
    Self,
    open_position,
    close_position,
    increase_liquidity,
    decrease_liquidity,
    update_and_reset_fee,
    update_and_reset_rewards,
    reset_fee,
    borrow_position_info,
    is_empty,
    reset_rewarder,
    new_position_info_for_test,
    update_points_internal_test,
    update_fee_internal_test,
    update_rewards_internal_test,
    PositionManager,
    new,
    new_position_info_custom,
    new_position_reward_for_test,
    new_position_info_for_test_from_address,
    fetch_positions
};
use integer_mate::full_math_u128;
use integer_mate::i32;
use move_stl::linked_table;
use std::string;
use std::unit_test::assert_eq;

#[test_only]
public struct CoinA {}

#[test_only]
public struct CoinB {}

#[test_only]
public struct TestPool has key {
    id: UID,
    position: PositionManager,
}

#[test_only]
public fun return_manager(m: PositionManager, ctx: &mut TxContext) {
    let p = TestPool {
        id: object::new(ctx),
        position: m,
    };
    transfer::share_object(p);
}

fun calculate_owned(liquidity: u128, growth_delta: u128): u64 {
    (full_math_u128::mul_shr(liquidity, growth_delta, 64) as u64)
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EInvalidPositionTickRange)]
fun test_open_position_failure_with_tick_error() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(110),
        &mut ctx,
    );
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_open_position() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert_eq!(pos.index(), 1);
    assert_eq!(pos.name(), string::utf8(b"Cetus LP | Pool1-1"));
    assert_eq!(pos.description(), string::utf8(b"Cetus Liquidity Position"));
    assert_eq!(pos.url(), string::utf8(b""));
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EPositionIsNotEmpty)]
fun test_close_position_failure() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    increase_liquidity(&mut m, &mut pos, 1000, 0, 0, 0, vector[0, 0, 0]);
    close_position(&mut m, pos);
    return_manager(m, &mut ctx);
}

#[test]
fun test_close_position() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    close_position(&mut m, pos);
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EPositionNotExist)]
fun test_borrow_position_info_not_exists() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    let pos_id = object::id(&pos);
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    close_position(&mut m, pos);
    assert!(is_empty(borrow_position_info(&m, pos_id)), 3);
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::ELiquidityChangeOverflow)]
fun test_increase_liquidity_overflow() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);

    increase_liquidity(&mut m, &mut pos, 1 << 127, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    increase_liquidity(&mut m, &mut pos, 1 << 127, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_increase_liquidity() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);

    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    let info = *borrow_position_info(&m, object::id(&pos));
    assert!(info.info_liquidity()== 1 << 70, 3);
    let (fee_growth_inside_a, fee_growth_inside_b) = info.info_fee_growth_inside();
    assert!(fee_growth_inside_a == 2 << 50, 4);
    assert!(fee_growth_inside_b == 3 << 50, 5);
    let (fee_owned_a, fee_owned_b) = info.info_fee_owned();
    assert!(fee_owned_a == 0, 6);
    assert!(fee_owned_b == 0, 7);
    assert!(info.info_points_growth_inside() == 3 << 80, 8);
    assert!(info.info_points_owned() == 0, 9);

    let info_last = copy info;
    increase_liquidity(
        &mut m,
        &mut pos,
        1 << 70,
        3 << 51,
        4 << 50,
        4 << 90,
        vector[2 << 30, 3 << 21, 4 << 15],
    );
    let info = *borrow_position_info(&m, object::id(&pos));
    assert!(info.info_liquidity() == 1 << 71, 10);
    let (fee_growth_inside_a, fee_growth_inside_b) = info.info_fee_growth_inside();
    assert!(fee_growth_inside_a == 3 << 51, 11);
    assert!(fee_growth_inside_b == 4 << 50, 12);
    let (fee_owned_a_last, fee_owned_b_last) = info_last.info_fee_owned();
    let (fee_growth_inside_a_last, _fee_growth_inside_b_last) = info_last.info_fee_growth_inside();
    let (fee_owned_a, fee_owned_b) = info.info_fee_owned();
    assert!(
        fee_owned_a == fee_owned_a_last + calculate_owned(
                info_last.info_liquidity(),
                (3 << 51) - fee_growth_inside_a_last
            ),
        13,
    );

    assert!(
        fee_owned_b == fee_owned_b_last + calculate_owned(info_last.info_liquidity(), (4 << 50) - (3 << 50)),
        14,
    );
    assert!(info.info_points_growth_inside() == 4 << 90, 15);
    assert!(
        info.info_points_owned() == full_math_u128::mul_shr(info_last.info_liquidity(), (4 << 90) - (3 << 80), 64),
        16,
    );
    let reward = vector::borrow(info.info_rewards(), 0);
    assert!(reward.reward_growth_inside()== 2 << 30, 17);
    assert!(
        reward.reward_amount_owned() == calculate_owned(
                info_last.info_liquidity(),
                (2 << 30) - (0 << 30)
            ),
        18,
    );
    let reward = vector::borrow(info.info_rewards(), 1);
    assert!(reward.reward_growth_inside() == 3 << 21, 19);
    assert!(
        reward.reward_amount_owned() == calculate_owned(
                info_last.info_liquidity(),
                (3 << 21) - (0 << 21)
            ),
        20,
    );
    let reward = vector::borrow(info.info_rewards(), 2);
    assert!(reward.reward_growth_inside() == 4 << 15, 21);
    assert!(
        reward.reward_amount_owned() == calculate_owned(
                info_last.info_liquidity(),
                (4 << 15) - (0 << 15)
            ),
        22,
    );

    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_decrease_liquidity_zero() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);

    decrease_liquidity(&mut m, &mut pos, 0, 3 << 50, 4 << 50, 5 << 80, vector[0, 0, 0]);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::ELiquidityChangeUnderflow)]
fun test_decrease_liquidity_underflow() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);

    decrease_liquidity(&mut m, &mut pos, 2<<74, 3 << 50, 4 << 50, 5 << 80, vector[0, 0, 0]);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_apply_liquidity_cut() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    position::apply_liquidity_cut(
        &mut m,
        object::id(&pos),
        1 << 10,
        2 << 50,
        3 << 50,
        3 << 80,
        vector[0, 0, 0],
    );

    let info = *borrow_position_info(&m, object::id(&pos));
    assert!(info.info_liquidity() == (1 << 70) - (1 << 10), 3);
    assert!(pos.liquidity() != info.info_liquidity(), 4);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_apply_liquidity_cut_zero() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    position::apply_liquidity_cut(
        &mut m,
        object::id(&pos),
        0,
        2 << 50,
        3 << 50,
        3 << 80,
        vector[0, 0, 0],
    );

    let info = *borrow_position_info(&m, object::id(&pos));
    assert!(info.info_liquidity() == (1 << 70), 3);
    assert!(pos.liquidity() == info.info_liquidity(), 4);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::ELiquidityChangeUnderflow)]
fun test_apply_liquidity_cut_underflow() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    position::apply_liquidity_cut(
        &mut m,
        object::id(&pos),
        1 << 71,
        2 << 50,
        3 << 50,
        3 << 80,
        vector[0, 0, 0],
    );

    let info = *borrow_position_info(&m, object::id(&pos));
    assert!(info.info_liquidity() == (1 << 70) - (1 << 10), 3);
    assert!(pos.liquidity() != info.info_liquidity(), 4);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_decrease_liquidity() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 1);
    assert!(linked_table::contains(m.positions(), object::id(&pos)), 2);
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);

    decrease_liquidity(&mut m, &mut pos, 1 << 69, 3 << 50, 4 << 50, 5 << 80, vector[0, 0, 0]);
    let info = *borrow_position_info(&m, object::id(&pos));
    assert!(info.info_liquidity() == 1 << 69, 3);
    let (fee_growth_inside_a, fee_growth_inside_b) = info.info_fee_growth_inside();
    assert!(fee_growth_inside_a == 3 << 50, 4);
    assert!(fee_growth_inside_b == 4 << 50, 5);
    let (fee_owned_a, fee_owned_b) = info.info_fee_owned();
    assert!(fee_owned_a == calculate_owned(1 << 70, (3 << 50) - (2 << 50)), 6);
    assert!(fee_owned_b == calculate_owned(1 << 70, (4 << 50) - (3 << 50)), 7);
    assert!(info.info_points_growth_inside() == 5 << 80, 8);
    assert!(
        info.info_points_owned() == full_math_u128::mul_shr(1 << 70, (5 << 80) - (3 << 80), 64),
        9,
    );
    let info_last = *borrow_position_info(&m, object::id(&pos));
    decrease_liquidity(&mut m, &mut pos, 1 << 69, 4 << 50, 5 << 50, 6 << 80, vector[0, 0, 0]);
    let info = *borrow_position_info(&m, object::id(&pos));
    assert!(info.info_liquidity() == 0, 10);
    let (fee_growth_inside_a, fee_growth_inside_b) = info.info_fee_growth_inside();
    assert!(fee_growth_inside_a == 4 << 50, 11);
    assert!(fee_growth_inside_b == 5 << 50, 12);
    let (fee_owned_a_last, fee_owned_b_last) = info_last.info_fee_owned();
    let (fee_owned_a, fee_owned_b) = info.info_fee_owned();
    assert!(fee_owned_a == fee_owned_a_last + calculate_owned(1 << 69, (4 << 50) - (3 << 50)), 13);
    assert!(fee_owned_b == fee_owned_b_last + calculate_owned(1 << 69, (5 << 50) - (4 << 50)), 14);
    assert!(info.info_points_growth_inside() == 6 << 80, 15);
    assert!(
        info.info_points_owned() == info_last.info_points_owned() + full_math_u128::mul_shr(1 << 69, (6 << 80) - (5 << 80), 64),
        16,
    );
    reset_fee(&mut m, object::id(&pos));
    assert!(is_empty(borrow_position_info(&m, object::id(&pos))), 17);
    close_position(&mut m, pos);
    // transfer::public_transfer(pos, tx_context::sender(&mut ctx));
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EPositionNotExist)]
fun test_borrow_mut_position_info_not_exists() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    let pos_id = object::id(&pos);
    close_position(&mut m, pos);
    update_and_reset_fee(&mut m, pos_id, 2 << 55, 3 << 55);
    return_manager(m, &mut ctx);
}

#[test]
fun test_update_and_reset_fee() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    let (fee_a, fee_b) = update_and_reset_fee(&mut m, object::id(&pos), 2 << 55, 3 << 55);
    let info = *borrow_position_info(&m, object::id(&pos));
    let (fee_growth_inside_a, fee_growth_inside_b) = info.info_fee_growth_inside();
    assert!(fee_growth_inside_a == 2 << 55, 1);
    assert!(fee_growth_inside_b == 3 << 55, 2);
    let (fee_owned_a, fee_owned_b) = info.info_fee_owned();
    assert!(fee_owned_a == 0, 3);
    assert!(fee_owned_b == 0, 4);
    assert!(fee_a == calculate_owned(1 << 70, (2 << 55) - (2 << 50)), 5);
    assert!(fee_b == calculate_owned(1 << 70, (3 << 55) - (3 << 50)), 6);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_update_and_reset_reward() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    let rewarder_0 = update_and_reset_rewards(
        &mut m,
        object::id(&pos),
        vector[2 << 40, 3 << 40, 4 << 40],
        0,
    );
    let rewarder_1 = update_and_reset_rewards(
        &mut m,
        object::id(&pos),
        vector[2 << 40, 3 << 40, 4 << 40],
        1,
    );
    let rewarder_2 = update_and_reset_rewards(
        &mut m,
        object::id(&pos),
        vector[2 << 40, 3 << 40, 4 << 40],
        2,
    );
    let info = *borrow_position_info(&m, object::id(&pos));
    let (fee_growth_inside_a, fee_growth_inside_b) = info.info_fee_growth_inside();
    assert!(fee_growth_inside_a == 2 << 50, 1);
    assert!(fee_growth_inside_b == 3 << 50, 2);
    assert!(rewarder_0 == calculate_owned(1 << 70, (2 << 40)), 3);
    assert!(rewarder_1 == calculate_owned(1 << 70, (3 << 40)), 4);
    assert!(rewarder_2 == calculate_owned(1 << 70, (4 << 40)), 5);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EInvalidRewardIndex)]
fun test_update_and_reset_reward_invalid_index() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    let _rewarder_0 = update_and_reset_rewards(
        &mut m,
        object::id(&pos),
        vector[2 << 40, 3 << 40, 4 << 40],
        4,
    );
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_reset_fee() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 54, 3 << 54, 3 << 80, vector[0, 0, 0]);
    let (fee_a, fee_b) = reset_fee(&mut m, object::id(&pos));
    assert!(fee_a == calculate_owned(1 << 70, (2 << 54) - (2 << 50)), 1);
    assert!(fee_b == calculate_owned(1 << 70, (3 << 54) - (3 << 50)), 2);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_reset_reward() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let mut pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    increase_liquidity(&mut m, &mut pos, 1 << 70, 2 << 50, 3 << 50, 3 << 80, vector[0, 0, 0]);
    increase_liquidity(
        &mut m,
        &mut pos,
        1 << 70,
        2 << 54,
        3 << 54,
        3 << 80,
        vector[3 << 50, 4 << 51, 5 << 52],
    );
    let rewarder_0 = reset_rewarder(&mut m, object::id(&pos), 0);
    let rewarder_1 = reset_rewarder(&mut m, object::id(&pos), 1);
    let rewarder_2 = reset_rewarder(&mut m, object::id(&pos), 2);
    assert!(rewarder_0 == calculate_owned(1 << 70, (3 << 50)), 1);
    assert!(rewarder_1 == calculate_owned(1 << 70, (4 << 51)), 2);
    assert!(rewarder_2 == calculate_owned(1 << 70, (5 << 52)), 3);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EPointsOwnedOverflow)]
fun test_update_points_internal_overflow() {
    let mut info = new_position_info_custom(
        1 << 10,
        i32::from_u32(0),
        i32::from_u32(1000),
        0,
        0,
        0,
        0,
        vector[],
        std::u128::max_value!()- 100,
        1<<10,
    );
    update_points_internal_test(&mut info, 3 << 101);
}

#[test]
fun test_update_points_internal() {
    let mut info = new_position_info_for_test();
    update_points_internal_test(&mut info, 3 << 101);
    assert!(
        info.info_points_owned() == full_math_u128::mul_shr(info.info_liquidity(), 3 << 101, 64),
        1,
    );
    assert!(info.info_points_growth_inside() == 3 << 101, 2);
    let owned = info.info_points_owned();
    update_points_internal_test(&mut info, 3 << 104);
    assert!(
        info.info_points_owned() == owned + full_math_u128::mul_shr(info.info_liquidity(), (3 << 104) - (3 << 101), 64),
        3,
    );
    assert!(info.info_points_growth_inside() == 3 << 104, 4);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EFeeOwnedOverflow)]
fun test_update_fee_internal_overflow() {
    let mut info = new_position_info_custom(
        1 << 10,
        i32::from_u32(0),
        i32::from_u32(1000),
        0,
        0,
        std::u64::max_value!()- 100,
        0,
        vector[
            new_position_reward_for_test(0, 0),
            new_position_reward_for_test(0, 0),
            new_position_reward_for_test(0, 0),
        ],
        0,
        0,
    );
    update_fee_internal_test(&mut info, 2 << 89, 4 << 90);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EFeeOwnedOverflow)]
fun test_update_fee_internal_overflow_b() {
    let mut info = new_position_info_custom(
        1 << 10,
        i32::from_u32(0),
        i32::from_u32(1000),
        0,
        0,
        std::u64::max_value!()- 100,
        0,
        vector[
            new_position_reward_for_test(0, 0),
            new_position_reward_for_test(0, 0),
            new_position_reward_for_test(0, 0),
        ],
        0,
        0,
    );
    update_fee_internal_test(&mut info, 2 << 89, 4 << 90);
}

#[test]
fun test_update_fee_internal() {
    let mut info = new_position_info_for_test();
    update_fee_internal_test(&mut info, 2 << 89, 4 << 90);
    let (fee_owned_a, fee_owned_b) = info.info_fee_owned();
    let (fee_growth_inside_a, fee_growth_inside_b) = info.info_fee_growth_inside();
    assert!(fee_owned_a == (full_math_u128::mul_shr(info.info_liquidity(), 2 << 89, 64) as u64), 1);
    assert!(fee_growth_inside_a == 2 << 89, 2);
    assert!(fee_owned_b == (full_math_u128::mul_shr(info.info_liquidity(), 4 << 90, 64) as u64), 3);
    assert!(fee_growth_inside_b == 4 << 90, 4);
    let (fee_owned_a_last, fee_owned_b_last) = info.info_fee_owned();
    update_fee_internal_test(&mut info, 2 << 90, 4 << 91);
    let (fee_owned_a, fee_owned_b) = info.info_fee_owned();
    assert!(
        fee_owned_a == fee_owned_a_last + (full_math_u128::mul_shr(info.info_liquidity(), (2 << 90) - (2 << 89), 64) as u64),
        5,
    );
    let (fee_growth_inside_a, fee_growth_inside_b) = info.info_fee_growth_inside();
    assert!(fee_growth_inside_a == 2 << 90, 6);
    assert!(
        fee_owned_b == fee_owned_b_last + (full_math_u128::mul_shr(info.info_liquidity(), (4 << 91) - (4 << 90), 64) as u64),
        7,
    );
    assert!(fee_growth_inside_b == 4 << 91, 8);
}

#[test]
fun test_update_rewards_internal_case_1() {
    let mut info = new_position_info_for_test();
    update_rewards_internal_test(&mut info, vector[1 << 70]);
    let reward = vector::borrow(info.info_rewards(), 0);
    assert!(reward.reward_growth_inside() == 1 << 70, 1);
    assert!(
        reward.reward_amount_owned() == (full_math_u128::mul_shr(
                info.info_liquidity(),
                1 << 70,
                64
            ) as u64),
        2,
    );
    let reward_0 = vector::borrow(info.info_rewards(), 0).reward_amount_owned();
    update_rewards_internal_test(&mut info, vector[1 << 80, 1 << 70]);
    let reward = vector::borrow(info.info_rewards(), 0);
    assert!(reward.reward_growth_inside() == 1 << 80, 3);
    assert!(
        reward.reward_amount_owned() == reward_0 + (full_math_u128::mul_shr(
                info.info_liquidity(),
                (1 << 80) - (1 << 70),
                64
            ) as u64),
        4,
    );
    let reward = vector::borrow(info.info_rewards(), 1);
    assert!(reward.reward_growth_inside() == 1 << 70, 5);
    assert!(
        reward.reward_amount_owned() == (full_math_u128::mul_shr(
                info.info_liquidity(),
                1 << 70,
                64
            ) as u64),
        6,
    );
    let reward_1 = vector::borrow(info.info_rewards(), 1).reward_amount_owned();
    let reward_0 = vector::borrow(info.info_rewards(), 0).reward_amount_owned();
    update_rewards_internal_test(&mut info, vector[1 << 90, 1 << 80, 1 << 90]);
    let reward = vector::borrow(info.info_rewards(), 0);
    assert!(reward.reward_growth_inside() == 1 << 90, 7);
    assert!(
        reward.reward_amount_owned() == reward_0 + (full_math_u128::mul_shr(
                info.info_liquidity(),
                (1 << 90) - (1 << 80),
                64
            ) as u64),
        8,
    );
    let reward = vector::borrow(info.info_rewards(), 1);
    assert!(reward.reward_growth_inside() == 1 << 80, 9);
    assert!(
        reward.reward_amount_owned() == reward_1 + (full_math_u128::mul_shr(
                info.info_liquidity(),
                (1 << 80) - (1 << 70),
                64
            ) as u64),
        10,
    );
    let reward = vector::borrow(info.info_rewards(), 2);
    assert!(reward.reward_growth_inside() == 1 << 90, 11);
    assert!(
        reward.reward_amount_owned() == (full_math_u128::mul_shr(
                info.info_liquidity(),
                1 << 90,
                64
            ) as u64),
        12,
    );
}

#[test]
fun test_update_rewards_case_2() {
    let mut position_info = new_position_info_custom(
        1000000000,
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
    update_rewards_internal_test(&mut position_info, vector[2 << 90, 2 << 91, 5 << 92]);
    let reward = vector::borrow(position_info.info_rewards(), 0);
    assert!(reward.reward_growth_inside() == 2 << 90, 1);
    assert!(
        reward.reward_amount_owned() == (full_math_u128::mul_shr(
            position_info.info_liquidity(),
            (2 << 90) - (2 << 89),
            64
        ) as u64),
        2,
    );
    let reward = vector::borrow(position_info.info_rewards(), 1);
    assert!(reward.reward_growth_inside() == 2 << 91, 3);
    assert!(
        reward.reward_amount_owned() == (full_math_u128::mul_shr(
            position_info.info_liquidity(),
            (2 << 91) - (2 << 90),
            64
        ) as u64),
        4,
    );
    let reward = vector::borrow(position_info.info_rewards(), 2);
    assert!(reward.reward_growth_inside() == 5 << 92, 5);
    assert!(
        reward.reward_amount_owned() == (full_math_u128::mul_shr(
            position_info.info_liquidity(),
            (5 << 92) - (3 << 91),
            64
        ) as u64),
        6,
    );
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::ERewardOwnedOverflow)]
fun test_update_rewards_case_overflow() {
    let mut position_info = new_position_info_custom(
        1000000000,
        i32::from_u32(0),
        i32::from_u32(1000),
        0,
        0,
        0,
        0,
        vector[
            new_position_reward_for_test(2 << 89, std::u64::max_value!()- 100),
            new_position_reward_for_test(2 << 90, std::u64::max_value!()- 100),
            new_position_reward_for_test(3 << 91, std::u64::max_value!()- 100),
        ],
        0,
        0,
    );
    update_rewards_internal_test(&mut position_info, vector[2 << 90, 2 << 91, 5 << 92]);
}

#[test]
fun test_fetch_positions() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let a = new_position_info_for_test_from_address(@1234);
    let b = new_position_info_for_test_from_address(@1235);
    let c = new_position_info_for_test_from_address(@1236);
    let d = new_position_info_for_test_from_address(@1237);
    linked_table::push_back(m.mut_positions(), a.info_position_id(), a);
    linked_table::push_back(m.mut_positions(), b.info_position_id(), b);
    linked_table::push_back(m.mut_positions(), c.info_position_id(), c);
    linked_table::push_back(m.mut_positions(), d.info_position_id(), d);
    let poss = fetch_positions(&m, vector[], 5);
    assert!(vector::length(&poss) == 4, 1);
    assert!(vector::borrow(&poss, 0).info_position_id() == object::id_from_address(@1234), 1);

    let poss = fetch_positions(&m, vector[object::id_from_address(@1234)], 5);
    assert!(vector::borrow(&poss, 0).info_position_id() == object::id_from_address(@1234), 1);
    assert!(vector::length(&poss) == 4, 1);
    let poss = fetch_positions(&m, vector[object::id_from_address(@1234)], 1);
    assert!(vector::length(&poss) == 1, 1);
    assert!(vector::borrow(&poss, 0).info_position_id() == object::id_from_address(@1234), 1);
    return_manager(m, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EPositionNotExist)]
fun test_fetch_positions_position_not_exist() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let a = new_position_info_for_test_from_address(@1234);
    let b = new_position_info_for_test_from_address(@1235);
    let c = new_position_info_for_test_from_address(@1236);
    let d = new_position_info_for_test_from_address(@1237);
    linked_table::push_back(m.mut_positions(), a.info_position_id(), a);
    linked_table::push_back(m.mut_positions(), b.info_position_id(), b);
    linked_table::push_back(m.mut_positions(), c.info_position_id(), c);
    linked_table::push_back(m.mut_positions(), d.info_position_id(), d);
    let poss = fetch_positions(&m, vector[], 5);
    assert!(vector::length(&poss) == 4, 1);
    assert!(vector::borrow(&poss, 0).info_position_id() == object::id_from_address(@1234), 1);

    let _poss = fetch_positions(&m, vector[object::id_from_address(@2234)], 5);
    return_manager(m, &mut ctx);
}

#[test]
fun test_remove_position_info_for_restore() {
    let mut ctx = tx_context::dummy();
    let mut m = new(20, &mut ctx);
    let pos = open_position<CoinA, CoinB>(
        &mut m,
        object::id_from_address(@1234),
        1,
        string::utf8(b""),
        i32::from_u32(0),
        i32::from_u32(120),
        &mut ctx,
    );
    assert!(m.is_position_exist(object::id(&pos)), 1);
    m.remove_position_info_for_restore(object::id(&pos));
    assert!(!m.is_position_exist(object::id(&pos)), 2);
    transfer::public_transfer(pos, tx_context::sender(&ctx));
    return_manager(m, &mut ctx);
}

#[test]
fun test_check_position_tick_range() {
    position::check_position_tick_range(i32::from(100), i32::from(200), 100);
    position::check_position_tick_range(i32::from(10), i32::from(20), 10);
    position::check_position_tick_range(i32::from(10), i32::from(20), 10);
    position::check_position_tick_range(i32::from(10), i32::from(20), 10);
    position::check_position_tick_range(i32::neg_from(443636), i32::from(443636), 2);
    position::check_position_tick_range(i32::neg_from(443630), i32::from(443630), 10);
    position::check_position_tick_range(i32::neg_from(443600), i32::from(443600), 100);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EInvalidPositionTickRange)]
fun test_check_position_tick_range_invalid_tick_range_0() {
    position::check_position_tick_range(i32::from(40), i32::from(20), 10);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EInvalidPositionTickRange)]
fun test_check_position_tick_range_invalid_tick_range_1() {
    position::check_position_tick_range(i32::from(2), i32::from(20), 10);
}
#[test]
#[expected_failure(abort_code = cetus_clmm::position::EInvalidPositionTickRange)]
fun test_check_position_tick_range_invalid_tick_range_11() {
    position::check_position_tick_range(i32::from(10), i32::from(22), 10);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EInvalidPositionTickRange)]
fun test_check_position_tick_range_invalid_tick_range_2() {
    position::check_position_tick_range(i32::neg_from(444400), i32::from(20), 10);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::position::EInvalidPositionTickRange)]
fun test_check_position_tick_range_invalid_tick_range_3() {
    position::check_position_tick_range(i32::neg_from(10), i32::from(444400), 10);
}

#[test]
fun test_is_empty() {
    let pos_info = new_position_info_custom(
        0,
        i32::from_u32(0),
        i32::from_u32(0),
        0,
        0,
        0,
        0,
        vector[
            new_position_reward_for_test(0, 0),
            new_position_reward_for_test(0, 0),
            new_position_reward_for_test(0, 0),
        ],
        0,
        0,
    );
    assert!(is_empty(&pos_info), 1);
}

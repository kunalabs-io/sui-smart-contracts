#[test_only]
module cetus_clmm::tick_tests;

use cetus_clmm::tick::{
    Self,
    update_by_liquidity_test,
    TickManager,
    cross_by_swap,
    borrow_tick,
    default_rewards_growth_outside_test,
    default_tick_test,
    get_points_in_range,
    get_fee_in_range,
    get_rewards_in_range,
    first_score_for_swap
};
use cetus_clmm::tick_math;
use integer_mate::i128;
use integer_mate::i32;
use integer_mate::math_u128;
use move_stl::option_u64;
use move_stl::skip_list;
use std::unit_test::assert_eq;

fun tick_score(tick: i32::I32): u64 {
    let t = i32::as_u32(i32::add(tick, i32::from(tick_math::tick_bound())));
    assert!((t >= 0) && (t <= (tick_math::tick_bound() * 2)), 100);
    (t as u64)
}

#[test_only]
public fun return_manager(m: TickManager, ctx: &mut TxContext) {
    let p = TestPool {
        id: object::new(ctx),
        position: m,
    };
    transfer::share_object(p);
}

#[test_only]
public struct TestPool has key {
    id: UID,
    position: TickManager,
}

#[test]
fun test_tick_score() {
    assert!(tick_score(i32::from(0)) == 443636, 1);
    assert!(tick_score(i32::from(1)) == 443637, 2);
    assert!(tick_score(i32::neg_from(1)) == 443635, 3);
    assert!(tick_score(i32::from(443636)) == 443636 * 2, 4);
    assert!(tick_score(i32::neg_from(443636)) == 0, 5);
}

#[test]
fun test_default_rewards_growth_inside() {
    assert!(default_rewards_growth_outside_test(0) == vector::empty<u128>(), 1);
    assert!(default_rewards_growth_outside_test(1) == vector[0], 2);
    assert!(default_rewards_growth_outside_test(2) == vector[0, 0], 3);
    assert!(default_rewards_growth_outside_test(3) == vector[0, 0, 0], 4);
}

#[test]
fun test_update_by_liquidity_lower_tick() {
    // tick is greater than current_tick.
    let mut tick = default_tick_test(i32::from(0));
    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        true,
        true,
        false,
        0,
        0,
        0,
        vector[1, 1, 1],
    );
    assert!(tick.liquidity_gross() == 2 << 64, 1);
    assert!(tick.liquidity_net() == i128::from(2 << 64), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 3);
    assert!(fee_growth_outside_b == 0, 4);
    assert!(tick.points_growth_outside() == 0, 5);
    assert!(tick.rewards_growth_outside() == vector[0, 0, 0], 6);

    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        false,
        true,
        false,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 65, 7);
    assert!(tick.liquidity_net() == i128::from(2 << 65), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 3);
    assert!(fee_growth_outside_b == 0, 4);
    assert!(tick.points_growth_outside() == 0, 5);
    assert!(tick.rewards_growth_outside() == vector[0, 0, 0], 6);
    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        false,
        false,
        false,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 64, 1);
    assert!(tick.liquidity_net() == i128::from(2 << 64), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 3);
    assert!(fee_growth_outside_b == 0, 4);
    assert!(tick.points_growth_outside() == 0, 5);
    assert!(tick.rewards_growth_outside() == vector[0, 0, 0], 6);

    // tick is lower than current_tick.
    let mut tick = default_tick_test(i32::from(0));
    update_by_liquidity_test(
        &mut tick,
        i32::from(100),
        2 << 64,
        true,
        true,
        false,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 64, 1);
    assert!(tick.liquidity_net() == i128::from(2 << 64), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 30, 3);
    assert!(fee_growth_outside_b == 2 << 34, 4);
    assert!(tick.points_growth_outside() == 2 << 50, 5);
    assert!(tick.rewards_growth_outside() == vector[2 << 100, 2 << 100, 2 << 100], 6);

    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        false,
        true,
        false,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 65, 7);
    assert!(tick.liquidity_net() == i128::from(2 << 65), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 30, 3);
    assert!(fee_growth_outside_b == 2 << 34, 4);
    assert!(tick.points_growth_outside() == 2 << 50, 5);
    assert!(tick.rewards_growth_outside() == vector[2 << 100, 2 << 100, 2 << 100], 6);
    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        false,
        false,
        false,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 64, 1);
    assert!(tick.liquidity_net() == i128::from(2 << 64), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 30, 3);
    assert!(fee_growth_outside_b == 2 << 34, 4);
    assert!(tick.points_growth_outside() == 2 << 50, 5);
    assert!(tick.rewards_growth_outside() == vector[2 << 100, 2 << 100, 2 << 100], 6);
}

#[test]
fun test_update_by_liquidity_upper_tick() {
    // tick is greater than current_tick.
    let mut tick = default_tick_test(i32::from(0));
    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        true,
        true,
        true,
        0,
        0,
        0,
        vector[1, 1, 1],
    );
    assert!(tick.liquidity_gross() == 2 << 64, 1);
    assert!(tick.liquidity_net() == i128::neg_from(2 << 64), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 3);
    assert!(fee_growth_outside_b == 0, 4);
    assert!(tick.points_growth_outside() == 0, 5);
    assert!(tick.rewards_growth_outside() == vector[0, 0, 0], 6);

    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        false,
        true,
        true,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 65, 7);
    assert!(tick.liquidity_net() == i128::neg_from(2 << 65), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 3);
    assert!(fee_growth_outside_b == 0, 4);
    assert!(tick.points_growth_outside() == 0, 5);
    assert!(tick.rewards_growth_outside() == vector[0, 0, 0], 6);
    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        false,
        false,
        true,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 64, 1);
    assert!(tick.liquidity_net() == i128::neg_from(2 << 64), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 3);
    assert!(fee_growth_outside_b == 0, 4);
    assert!(tick.points_growth_outside() == 0, 5);
    assert!(tick.rewards_growth_outside() == vector[0, 0, 0], 6);

    // tick is lower than current_tick.
    let mut tick = default_tick_test(i32::from(0));
    update_by_liquidity_test(
        &mut tick,
        i32::from(100),
        2 << 64,
        true,
        true,
        true,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 64, 1);
    assert!(tick.liquidity_net() == i128::neg_from(2 << 64), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 30, 3);
    assert!(fee_growth_outside_b == 2 << 34, 4);
    assert!(tick.points_growth_outside() == 2 << 50, 5);
    assert!(tick.rewards_growth_outside() == vector[2 << 100, 2 << 100, 2 << 100], 6);

    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        false,
        true,
        true,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 65, 7);
    assert!(tick.liquidity_net() == i128::neg_from(2 << 65), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 30, 3);
    assert!(fee_growth_outside_b == 2 << 34, 4);
    assert!(tick.points_growth_outside() == 2 << 50, 5);
    assert!(tick.rewards_growth_outside() == vector[2 << 100, 2 << 100, 2 << 100], 6);
    update_by_liquidity_test(
        &mut tick,
        i32::neg_from(100),
        2 << 64,
        false,
        false,
        true,
        2 << 30,
        2 << 34,
        2 << 50,
        vector[2 << 100, 2 << 100, 2 << 100],
    );
    assert!(tick.liquidity_gross() == 2 << 64, 1);
    assert!(tick.liquidity_net() == i128::neg_from(2 << 64), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 30, 3);
    assert!(fee_growth_outside_b == 2 << 34, 4);
    assert!(tick.points_growth_outside() == 2 << 50, 5);
    assert!(tick.rewards_growth_outside() == vector[2 << 100, 2 << 100, 2 << 100], 6);
}

#[test]
fun test_cross_swap() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2 << 32, &mut ctx);

    // prepare ticks.
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::neg_from(100)),
        tick::new_tick_for_test(
            i32::neg_from(100),
            i128::from(2 << 50),
            2 << 50,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::from(0)),
        tick::new_tick_for_test(
            i32::from(0),
            i128::from(2 << 30),
            2 << 30,
            0,
            0,
            0,
            vector[0, 0],
        ),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::from(100)),
        tick::new_tick_for_test(
            i32::from(100),
            i128::neg_from(2 << 50),
            2 << 50,
            0,
            0,
            0,
            vector[0, 0],
        ),
    );

    // cross swap b2a
    let mut pool_current_liquidity = 0;
    pool_current_liquidity =
        cross_by_swap(
            &mut manager,
            i32::neg_from(100),
            false,
            pool_current_liquidity,
            2 << 32,
            2 << 32,
            2 << 32,
            vector[2 << 77, 2 << 77, 2 << 77],
        );
    let tick = borrow_tick(&manager, i32::neg_from(100));
    assert!(pool_current_liquidity == 2 << 50, 1);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 32, 2);
    assert!(fee_growth_outside_b == 2 << 32, 3);
    assert!(tick.points_growth_outside() == 2 << 32, 4);
    assert!(tick.rewards_growth_outside() == vector[2 << 77, 2 << 77, 2 << 77], 5);

    pool_current_liquidity =
        cross_by_swap(
            &mut manager,
            i32::from(0),
            false,
            pool_current_liquidity,
            2 << 32,
            2 << 32,
            2 << 32,
            vector[2 << 77, 2 << 77, 2 << 77],
        );
    let tick = borrow_tick(&manager, i32::neg_from(0));
    assert!(pool_current_liquidity == (2 << 50) + (2 << 30), 6);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 32, 7);
    assert!(fee_growth_outside_b == 2 << 32, 8);
    assert!(tick.points_growth_outside() == 2 << 32, 9);
    assert!(tick.rewards_growth_outside() == vector[2 << 77, 2 << 77, 2 << 77], 10);
    pool_current_liquidity =
        cross_by_swap(
            &mut manager,
            i32::from(100),
            false,
            pool_current_liquidity,
            2 << 32,
            2 << 32,
            2 << 32,
            vector[2 << 77, 2 << 77, 2 << 77],
        );
    let tick = borrow_tick(&manager, i32::from(100));
    assert!(pool_current_liquidity == 2 << 30, 11);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 32, 12);
    assert!(fee_growth_outside_b == 2 << 32, 13);
    assert!(tick.points_growth_outside() == 2 << 32, 14);
    assert!(tick.rewards_growth_outside() == vector[2 << 77, 2 << 77, 2 << 77], 15);

    // cross a2b
    pool_current_liquidity =
        cross_by_swap(
            &mut manager,
            i32::from(100),
            true,
            pool_current_liquidity,
            2 << 42,
            2 << 42,
            2 << 42,
            vector[2 << 87, 2 << 77, 2 << 97],
        );
    let tick = borrow_tick(&manager, i32::from(100));
    assert!(pool_current_liquidity == (2 << 50) + (2 << 30), 16);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == (2 << 42) - (2 << 32), 17);
    assert!(fee_growth_outside_b == (2 << 42) - (2 << 32), 18);
    assert!(tick.points_growth_outside() == (2 << 42) - (2 << 32), 19);
    assert!(
        tick.rewards_growth_outside() == vector[(2 << 87) - (2 << 77), (2 << 77) - (2 << 77), (2 << 97) - (2 << 77)],
        20,
    );
    pool_current_liquidity =
        cross_by_swap(
            &mut manager,
            i32::from(0),
            true,
            pool_current_liquidity,
            2 << 42,
            2 << 42,
            2 << 42,
            vector[2 << 87, 2 << 77, 2 << 97],
        );
    let tick = borrow_tick(&manager, i32::from(0));
    assert!(pool_current_liquidity == 2 << 50, 21);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == (2 << 42) - (2 << 32), 22);
    assert!(fee_growth_outside_b == (2 << 42) - (2 << 32), 23);
    assert!(tick.points_growth_outside() == (2 << 42) - (2 << 32), 24);
    assert!(
        tick.rewards_growth_outside() == vector[(2 << 87) - (2 << 77), (2 << 77) - (2 << 77), (2 << 97) - (2 << 77)],
        25,
    );
    pool_current_liquidity =
        cross_by_swap(
            &mut manager,
            i32::neg_from(100),
            true,
            pool_current_liquidity,
            2 << 42,
            2 << 42,
            2 << 42,
            vector[2 << 87, 2 << 77, 2 << 97],
        );
    let tick = borrow_tick(&manager, i32::neg_from(100));
    assert!(pool_current_liquidity == 0, 26);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick.fee_growth_outside();
    assert!(fee_growth_outside_a == (2 << 42) - (2 << 32), 27);
    assert!(fee_growth_outside_b == (2 << 42) - (2 << 32), 28);
    assert!(tick.points_growth_outside() == (2 << 42) - (2 << 32), 29);
    assert!(
        tick.rewards_growth_outside() == vector[(2 << 87) - (2 << 77), (2 << 77) - (2 << 77), (2 << 97) - (2 << 77)],
        30,
    );
    return_manager(manager, &mut ctx);
}

#[test]
///         -100            0               100
///         |               |               |
///  ---------------------------------------------------
fun test_get_points_in_range() {
    let tick_lower = tick::new_tick_for_test(
        i32::neg_from(100),
        i128::neg_from(2 << 50),
        2 << 50,
        0,
        0,
        2 << 20,
        vector[0, 0],
    );
    let tick_mid = tick::new_tick_for_test(
        i32::from(0),
        i128::neg_from(2 << 50),
        2 << 50,
        0,
        0,
        2 << 45,
        vector[0, 0],
    );
    let tick_upper = tick::new_tick_for_test(
        i32::from(100),
        i128::neg_from(2 << 50),
        2 << 50,
        0,
        0,
        2 << 34,
        vector[0, 0],
    );
    assert!(
        get_points_in_range(i32::neg_from(140), 2 << 60, option::none(), option::some(tick_lower)) ==
            math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 2 << 60),
                2 << 20
            ),
        1,
    );
    assert!(
        get_points_in_range(i32::neg_from(140), 2 << 60, option::none(), option::some(tick_upper)) ==
            math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 2 << 60),
                2 << 34
            ),
        2,
    );
    assert!(
        get_points_in_range(i32::from(140), 2 << 60, option::none(), option::some(tick_mid)) ==
            math_u128::wrapping_sub(2 << 45, 2 << 60),
        3,
    );

    assert!(
        get_points_in_range(i32::neg_from(40), 2 << 60, option::some(tick_lower), option::some(tick_mid)) ==
            math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 45), 2 << 20),
        4,
    );
    assert!(
        get_points_in_range(i32::neg_from(140), 2 << 60, option::some(tick_lower), option::some(tick_upper)) ==
            math_u128::wrapping_sub(2 << 20, 2 << 34),
        5,
    );
    assert!(
        get_points_in_range(i32::from(140), 2 << 60, option::some(tick_lower), option::some(tick_upper)) ==
            math_u128::wrapping_sub(2 << 34, 2 << 20),
        6,
    );
    assert!(
        get_points_in_range(i32::from(40), 2 << 60, option::some(tick_mid), option::some(tick_upper)) ==
            math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 2 << 45),
                2 << 34
            ),
        7,
    );

    assert!(
        get_points_in_range(i32::neg_from(80), 2 << 60, option::some(tick_upper), option::none()) ==
            2 << 34,
        8,
    );
    assert!(
        get_points_in_range(i32::from(80), 2 << 60, option::some(tick_mid), option::none()) ==
            math_u128::wrapping_sub(2 << 60, 2 << 45),
        9,
    );
    assert!(
        get_points_in_range(i32::from(120), 2 << 60, option::some(tick_lower), option::none()) ==
            math_u128::wrapping_sub(2 << 60, 2 << 20),
        10,
    );
}

#[test]
fun test_get_fee_in_range() {
    let tick_lower = tick::new_tick_for_test(
        i32::neg_from(100),
        i128::neg_from(2 << 50),
        2 << 50,
        2 << 20,
        2 << 20,
        2 << 20,
        vector[0, 0],
    );
    let tick_mid = tick::new_tick_for_test(
        i32::from(0),
        i128::neg_from(2 << 50),
        2 << 50,
        2 << 45,
        2 << 45,
        2 << 45,
        vector[0, 0],
    );
    let tick_upper = tick::new_tick_for_test(
        i32::from(100),
        i128::neg_from(2 << 50),
        2 << 50,
        2 << 34,
        2 << 34,
        2 << 34,
        vector[0, 0],
    );
    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::neg_from(140),
        2 << 60,
        2 << 60,
        option::none(),
        option::some(tick_lower),
    );
    assert!(
        fee_owned_a == math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 60), 2 << 20),
        1,
    );
    assert!(
        fee_owned_b == math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 60), 2 << 20),
        1,
    );
    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::neg_from(140),
        2 << 60,
        2 << 60,
        option::none(),
        option::some(tick_upper),
    );
    assert!(
        fee_owned_a == math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 60), 2 << 34),
        2,
    );
    assert!(
        fee_owned_b == math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 60), 2 << 34),
        2,
    );

    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::from(140),
        2 << 60,
        2 << 60,
        option::none(),
        option::some(tick_mid),
    );
    assert!(fee_owned_a == math_u128::wrapping_sub(2 << 45, 2 << 60), 3);
    assert!(fee_owned_b == math_u128::wrapping_sub(2 << 45, 2 << 60), 3);

    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::neg_from(40),
        2 << 60,
        2 << 60,
        option::some(tick_lower),
        option::some(tick_mid),
    );
    assert!(
        fee_owned_a == math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 45), 2 << 20),
        4,
    );
    assert!(
        fee_owned_b == math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 45), 2 << 20),
        4,
    );
    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::neg_from(140),
        2 << 60,
        2 << 60,
        option::some(tick_lower),
        option::some(tick_upper),
    );
    assert!(fee_owned_a == math_u128::wrapping_sub(2 << 20, 2 << 34), 5);
    assert!(fee_owned_b == math_u128::wrapping_sub(2 << 20, 2 << 34), 5);

    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::from(140),
        2 << 60,
        2 << 60,
        option::some(tick_lower),
        option::some(tick_upper),
    );
    assert!(fee_owned_a == math_u128::wrapping_sub(2 << 34, 2 << 20), 6);
    assert!(fee_owned_b == math_u128::wrapping_sub(2 << 34, 2 << 20), 6);

    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::from(40),
        2 << 60,
        2 << 60,
        option::some(tick_mid),
        option::some(tick_upper),
    );
    assert!(
        fee_owned_a == math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 45), 2 << 34),
        7,
    );
    assert!(
        fee_owned_b == math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 45), 2 << 34),
        7,
    );

    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::neg_from(80),
        2 << 60,
        2 << 60,
        option::some(tick_upper),
        option::none(),
    );
    assert!(fee_owned_a == 2 << 34, 8);
    assert!(fee_owned_b == 2 << 34, 8);

    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::from(80),
        2 << 60,
        2 << 60,
        option::some(tick_mid),
        option::none(),
    );
    assert!(fee_owned_a == math_u128::wrapping_sub(2 << 60, 2 << 45), 10);
    assert!(fee_owned_b == math_u128::wrapping_sub(2 << 60, 2 << 45), 10);

    let (fee_owned_a, fee_owned_b) = get_fee_in_range(
        i32::from(120),
        2 << 60,
        2 << 60,
        option::some(tick_lower),
        option::none(),
    );
    assert!(fee_owned_a == math_u128::wrapping_sub(2 << 60, 2 << 20), 10);
    assert!(fee_owned_b == math_u128::wrapping_sub(2 << 60, 2 << 20), 10);
}

#[test]
fun test_get_rewards_in_range() {
    let tick_lower = tick::new_tick_for_test(
        i32::neg_from(100),
        i128::neg_from(2 << 50),
        2 << 50,
        0,
        0,
        2 << 20,
        vector[],
    );
    let tick_mid = tick::new_tick_for_test(
        i32::from(0),
        i128::neg_from(2 << 50),
        2 << 50,
        0,
        0,
        2 << 45,
        vector[2 << 40, 0],
    );
    let tick_upper = tick::new_tick_for_test(
        i32::from(100),
        i128::neg_from(2 << 50),
        2 << 50,
        0,
        0,
        2 << 34,
        vector[2 << 40, 2 << 40, 3 << 40],
    );
    let rewards = get_rewards_in_range(
        i32::neg_from(140),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::none(),
        option::some(tick_lower),
    );
    assert!(rewards == vector[0, 0, 0], 1);

    let rewards = get_rewards_in_range(
        i32::neg_from(140),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::none(),
        option::some(tick_upper),
    );
    assert!(
        rewards == vector[
            math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 2 << 60),
                2 << 40
            ), math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 2 << 60),
                2 << 40
            ), math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 2 << 60),
                3 << 40
            )],
        2,
    );
    let rewards = get_rewards_in_range(
        i32::from(140),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::none(),
        option::some(tick_mid),
    );
    assert!(
        rewards == vector[math_u128::wrapping_sub(2 << 40, 2 << 60),
            math_u128::wrapping_sub(0, 2 << 60),
            math_u128::wrapping_sub(0, 2 << 60)
        ],
        3,
    );
    let rewards = get_rewards_in_range(
        i32::neg_from(40),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::some(tick_lower),
        option::some(tick_mid),
    );
    assert!(
        rewards == vector[
            math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 2 << 40), 0),
            math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 0), 0),
            math_u128::wrapping_sub(math_u128::wrapping_sub(2 << 60, 0), 0)
        ],
        4,
    );
    let rewards = get_rewards_in_range(
        i32::neg_from(140),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::some(tick_lower),
        option::some(tick_upper),
    );
    assert!(
        rewards == vector[
            math_u128::wrapping_sub(0, 2 << 40),
            math_u128::wrapping_sub(0, 2 << 40),
            math_u128::wrapping_sub(0, 3 << 40)
        ],
        5,
    );
    let rewards = get_rewards_in_range(
        i32::from(140),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::some(tick_lower),
        option::some(tick_upper),
    );
    assert!(
        rewards == vector[
            2 << 40,
            2 << 40,
            3 << 40
        ],
        6,
    );
    let rewards = get_rewards_in_range(
        i32::from(40),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::some(tick_mid),
        option::some(tick_upper),
    );
    assert!(
        rewards == vector[
            math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 2 << 40),
                2 << 40
            ),
            math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 2 << 40),
                0
            ), math_u128::wrapping_sub(
                math_u128::wrapping_sub(2 << 60, 3 << 40),
                0
            )
        ],
        7,
    );
    let rewards = get_rewards_in_range(
        i32::from(80),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::some(tick_upper),
        option::none(),
    );
    assert!(rewards == vector[2 << 40, 2 << 40, 3 << 40], 8);

    let rewards = get_rewards_in_range(
        i32::from(80),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::some(tick_mid),
        option::none(),
    );
    assert!(
        rewards == vector[
            math_u128::wrapping_sub(2 << 60, 2 << 40),
            2 << 60,
            2 << 60
        ],
        9,
    );
    let rewards = get_rewards_in_range(
        i32::from(120),
        vector[2 << 60, 2 << 60, 2 << 60],
        option::some(tick_lower),
        option::none(),
    );
    assert!(rewards == vector[2 << 60, 2 << 60, 2 << 60], 10);
}

#[test]
fun test_increase_liquidity() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2 << 32, &mut ctx);
    // lower   cur     upper
    //  |      |       |
    // ------------------
    tick::increase_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        2 << 34,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    let tick_lower = borrow_tick(&manager, i32::neg_from(100));
    let tick_upper = borrow_tick(&manager, i32::from(100));
    assert!(tick_lower.liquidity_gross() == 2 << 34, 1);
    assert!(tick_lower.liquidity_net() == i128::from(2 << 34), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_lower.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 56, 3);
    assert!(fee_growth_outside_b == 2 << 56, 4);
    assert!(tick_lower.points_growth_outside() == 2 << 70, 5);
    assert!(tick_lower.rewards_growth_outside() == vector[1, 1, 1], 6);
    assert!(tick_upper.liquidity_gross() == 2 << 34, 7);
    assert!(tick_upper.liquidity_net() == i128::neg_from(2 << 34), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_upper.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 9);
    assert!(fee_growth_outside_b == 0, 10);
    assert!(tick_upper.points_growth_outside() == 0, 11);
    assert!(tick_upper.rewards_growth_outside() == vector[0, 0, 0], 12);
    tick::increase_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        2 << 34,
        2 << 66,
        2 << 66,
        2 << 60,
        vector[1, 1, 1],
    );
    let tick_lower = borrow_tick(&manager, i32::neg_from(100));
    let tick_upper = borrow_tick(&manager, i32::from(100));
    assert!(tick_lower.liquidity_gross() == 2 << 35, 1);
    assert!(tick_lower.liquidity_net() == i128::from(2 << 35), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_lower.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 56, 3);
    assert!(fee_growth_outside_b == 2 << 56, 4);
    assert!(tick_lower.points_growth_outside() == 2 << 70, 5);
    assert!(tick_lower.rewards_growth_outside() == vector[1, 1, 1], 6);
    assert!(tick_upper.liquidity_gross() == 2 << 35, 7);
    assert!(tick_upper.liquidity_net() == i128::neg_from(2 << 35), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_upper.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 9);
    assert!(fee_growth_outside_b == 0, 10);
    assert!(tick_upper.points_growth_outside() == 0, 11);
    assert!(tick_upper.rewards_growth_outside() == vector[0, 0, 0], 12);

    // cur     lower   upper
    //  |      |       |
    // ------------------
    tick::increase_liquidity(
        &mut manager,
        i32::neg_from(200),
        i32::neg_from(50),
        i32::from(50),
        2 << 34,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    let tick_lower = borrow_tick(&manager, i32::neg_from(50));
    let tick_upper = borrow_tick(&manager, i32::from(50));
    assert!(tick_lower.liquidity_gross() == 2 << 34, 1);
    assert!(tick_lower.liquidity_net() == i128::from(2 << 34), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_lower.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 3);
    assert!(fee_growth_outside_b == 0, 4);
    assert!(tick_lower.points_growth_outside() == 0, 5);
    assert!(tick_lower.rewards_growth_outside() == vector[0, 0, 0], 6);
    assert!(tick_upper.liquidity_gross() == 2 << 34, 7);
    assert!(tick_upper.liquidity_net() == i128::neg_from(2 << 34), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_upper.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 9);
    assert!(fee_growth_outside_b == 0, 10);
    assert!(tick_upper.points_growth_outside() == 0, 11);
    assert!(tick_upper.rewards_growth_outside() == vector[0, 0, 0], 12);
    // lower   upper   cur
    //  |      |       |
    // ------------------
    tick::increase_liquidity(
        &mut manager,
        i32::from(200),
        i32::neg_from(150),
        i32::from(150),
        2 << 34,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    let tick_lower = borrow_tick(&manager, i32::neg_from(150));
    let tick_upper = borrow_tick(&manager, i32::from(150));
    assert!(tick_lower.liquidity_gross() == 2 << 34, 1);
    assert!(tick_lower.liquidity_net() == i128::from(2 << 34), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_lower.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 56, 3);
    assert!(fee_growth_outside_b == 2 << 56, 4);
    assert!(tick_lower.points_growth_outside() == 2 << 70, 5);
    assert!(tick_lower.rewards_growth_outside() == vector[1, 1, 1], 6);
    assert!(tick_upper.liquidity_gross() == 2 << 34, 7);
    assert!(tick_upper.liquidity_net() == i128::neg_from(2 << 34), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_upper.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 56, 9);
    assert!(fee_growth_outside_b == 2 << 56, 10);
    assert!(tick_upper.points_growth_outside() == 2 << 70, 11);
    assert!(tick_upper.rewards_growth_outside() == vector[1, 1, 1], 12);
    return_manager(manager, &mut ctx);
}

#[test]
fun test_decrease_liquidity() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2 << 32, &mut ctx);
    // lower   cur     upper
    //  |      |       |
    // ------------------
    tick::increase_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        2 << 34,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    tick::decrease_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        2 << 33,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    let tick_lower = borrow_tick(&manager, i32::neg_from(100));
    let tick_upper = borrow_tick(&manager, i32::from(100));
    assert!(tick_lower.liquidity_gross() == 2 << 33, 1);
    assert!(tick_lower.liquidity_net() == i128::from(2 << 33), 2);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_lower.fee_growth_outside();
    assert!(fee_growth_outside_a == 2 << 56, 3);
    assert!(fee_growth_outside_b == 2 << 56, 4);
    assert!(tick_lower.points_growth_outside() == 2 << 70, 5);
    assert!(tick_lower.rewards_growth_outside() == vector[1, 1, 1], 6);
    assert!(tick_upper.liquidity_gross() == 2 << 33, 7);
    assert!(tick_upper.liquidity_net() == i128::neg_from(2 << 33), 8);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_upper.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 9);
    assert!(fee_growth_outside_b == 0, 10);
    assert!(tick_upper.points_growth_outside() == 0, 11);
    assert!(tick_upper.rewards_growth_outside() == vector[0, 0, 0], 12);
    tick::decrease_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        2 << 33,
        2 << 66,
        2 << 66,
        2 << 60,
        vector[1, 1, 1],
    );
    let a = tick::tick_manager(&manager);
    assert!(!skip_list::contains(a, tick_score(i32::neg_from(100))), 13);
    assert!(!skip_list::contains(a, tick_score(i32::from(100))), 14);

    // cur     lower   upper
    //  |      |       |
    // ------------------
    tick::increase_liquidity(
        &mut manager,
        i32::neg_from(200),
        i32::neg_from(50),
        i32::from(50),
        2 << 34,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    let tick_lower = borrow_tick(&manager, i32::neg_from(50));
    let tick_upper = borrow_tick(&manager, i32::from(50));
    assert!(tick_lower.liquidity_gross() == 2 << 34, 15);
    assert!(tick_lower.liquidity_net() == i128::from(2 << 34), 16);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_lower.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 17);
    assert!(fee_growth_outside_b == 0, 18);
    assert!(tick_lower.points_growth_outside() == 0, 19);
    assert!(tick_lower.rewards_growth_outside() == vector[0, 0, 0], 20);
    assert!(tick_upper.liquidity_gross() == 2 << 34, 21);
    assert!(tick_upper.liquidity_net() == i128::neg_from(2 << 34), 22);
    let (fee_growth_outside_a, fee_growth_outside_b) = tick_upper.fee_growth_outside();
    assert!(fee_growth_outside_a == 0, 23);
    assert!(fee_growth_outside_b == 0, 24);
    assert!(tick_upper.points_growth_outside() == 0, 25);
    assert!(tick_upper.rewards_growth_outside() == vector[0, 0, 0], 26);
    tick::decrease_liquidity(
        &mut manager,
        i32::neg_from(200),
        i32::neg_from(50),
        i32::from(50),
        2 << 34,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );

    let a = tick::tick_manager(&manager);
    assert!(!skip_list::contains(a, tick_score(i32::neg_from(50))), 27);
    assert!(!skip_list::contains(a, tick_score(i32::from(50))), 28);
    // lower   upper   cur
    //  |      |       |
    // ------------------
    tick::increase_liquidity(
        &mut manager,
        i32::from(200),
        i32::neg_from(150),
        i32::from(150),
        2 << 34,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    tick::decrease_liquidity(
        &mut manager,
        i32::neg_from(200),
        i32::neg_from(150),
        i32::from(150),
        2 << 34,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );

    let a = tick::tick_manager(&manager);
    assert!(!skip_list::contains(a, tick_score(i32::neg_from(150))), 29);
    assert!(!skip_list::contains(a, tick_score(i32::from(150))), 30);
    return_manager(manager, &mut ctx);
}

#[test]
fun test_first_score_for_swap() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2 << 23, &mut ctx);
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::neg_from(100)),
        default_tick_test(i32::neg_from(100)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::from(100)),
        default_tick_test(i32::from(100)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::neg_from(50)),
        default_tick_test(i32::neg_from(50)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::from(50)),
        default_tick_test(i32::from(50)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::neg_from(150)),
        default_tick_test(i32::neg_from(150)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::from(150)),
        default_tick_test(i32::from(150)),
    );
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::neg_from(100), true)) == tick_score(
                i32::neg_from(100)
            ),
        1,
    );
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::neg_from(110), true)) == tick_score(
                i32::neg_from(150)
            ),
        2,
    );
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::neg_from(100), false)) == tick_score(
                i32::neg_from(50)
            ),
        3,
    );
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::neg_from(110), false)) == tick_score(
                i32::neg_from(100)
            ),
        4,
    );
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::from(100), true)) == tick_score(i32::from(100)),
        5,
    );
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::from(110), false)) == tick_score(i32::from(150)),
        6,
    );
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::neg_from(150), true)) == tick_score(
                i32::neg_from(150)
            ),
        7,
    );
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::neg_from(151), false)) == tick_score(
                i32::neg_from(150)
            ),
        8,
    );
    assert!(option_u64::is_none(&first_score_for_swap(&manager, i32::from(443636), false)), 8);
    assert!(
        option_u64::borrow(&first_score_for_swap(&manager, i32::from(150), true)) == tick_score(i32::from(150)),
        9,
    );
    return_manager(manager, &mut ctx);
}

#[test]
fun test_fetch_ticks() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2 << 23, &mut ctx);
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::neg_from(100)),
        default_tick_test(i32::neg_from(100)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::from(100)),
        default_tick_test(i32::from(100)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::neg_from(50)),
        default_tick_test(i32::neg_from(50)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::from(50)),
        default_tick_test(i32::from(50)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::neg_from(150)),
        default_tick_test(i32::neg_from(150)),
    );
    skip_list::insert(
        manager.mut_tick_manager(),
        tick_score(i32::from(150)),
        default_tick_test(i32::from(150)),
    );
    assert_eq!(manager.tick_count(), 6);
    let ticks = tick::fetch_ticks(&manager, vector[4294967146], 20);
    assert!(vector::borrow(&ticks, 0).index() == i32::neg_from(150), 1);
    assert!(vector::length(&ticks) == 6, 1);

    let ticks = tick::fetch_ticks(&manager, vector[], 20);
    assert!(vector::borrow(&ticks, 0).index() == i32::neg_from(150), 1);
    assert!(vector::length(&ticks) == 6, 1);
    return_manager(manager, &mut ctx);
}

#[test]
fun test_increase_liquidity_zero() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2, &mut ctx);
    assert_eq!(manager.tick_spacing(), 2);
    tick::increase_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        0,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    tick::decrease_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        0,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::tick::ETickNotFound)]
fun test_increase_liquidity_tick_not_found() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2, &mut ctx);
    tick::decrease_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        2<< 23,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::tick::ETickNotFound)]
fun test_increase_liquidity_tick_not_found_2() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2, &mut ctx);
    tick::increase_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        2<< 22,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    tick::decrease_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(200),
        2<< 11,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::tick::ELiquidityUnderflow)]
fun test_cross_by_swap() {
    let mut ctx = tx_context::dummy();
    let mut manager = tick::new(2, 2, &mut ctx);
    tick::increase_liquidity(
        &mut manager,
        i32::from(0),
        i32::neg_from(100),
        i32::from(100),
        2<< 22,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    manager.cross_by_swap(
        i32::from(100),
        false,
        2 << 20,
        2 << 56,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::tick::ELiquidityOverflow)]
fun test_update_by_liquidity_overflow() {
    let mut tick = default_tick_test(i32::from(10));
    tick::update_by_liquidity_test(
        &mut tick,
        i32::from(100),
        (1<< 127) -1,
        true,
        true,
        true,
        2 << 20,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    tick::update_by_liquidity_test(
        &mut tick,
        i32::from(100),
        std::u128::max_value!() - (1<<127) + 2,
        true,
        true,
        true,
        2 << 20,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
}

#[test]
#[expected_failure(abort_code = cetus_clmm::tick::ELiquidityOverflow)]
fun test_update_by_liquidity_overflow_case_2() {
    let mut tick = default_tick_test(i32::from(10));
    tick::update_by_liquidity_test(
        &mut tick,
        i32::from(100),
        (1<< 127) -1,
        true,
        true,
        true,
        2 << 20,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    tick::update_by_liquidity_test(
        &mut tick,
        i32::from(100),
        std::u128::max_value!() - (1<<127),
        true,
        true,
        true,
        2 << 20,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
}

#[test]
#[expected_failure(abort_code = cetus_clmm::tick::ELiquidityUnderflow)]
fun test_update_by_liquidity_underflow() {
    let mut tick = default_tick_test(i32::from(10));
    tick::update_by_liquidity_test(
        &mut tick,
        i32::from(100),
        170141183460469231731687303715884105727,
        true,
        true,
        true,
        2 << 20,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
    tick::update_by_liquidity_test(
        &mut tick,
        i32::from(100),
        170141183460469231731687303715884105727+ 100,
        false,
        false,
        true,
        2 << 20,
        2 << 56,
        2 << 70,
        vector[1, 1, 1],
    );
}

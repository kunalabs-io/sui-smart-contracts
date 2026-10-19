#[test_only]
module cetus_clmm::swap_tests;

use cetus_clmm::config;
use cetus_clmm::factory_tests::{CoinA, CoinB, CoinC};
use cetus_clmm::pool;
use cetus_clmm::pool_tests::{
    pt,
    nt,
    swap,
    add_liquidity_for_swap,
    open_position_with_liquidity,
    remove_liquidity
};
use cetus_clmm::rewarder;
use cetus_clmm::tick;
use cetus_clmm::tick_math::{Self, get_sqrt_price_at_tick};
use integer_mate::i128;
use integer_mate::i32;
use std::string;
use std::unit_test::assert_eq;
use sui::clock;

#[test]
public fun test_swap_verify() {
    //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //|  index  |          sqrt_price           | liquidity_net  | liquidity_gross | fee_growth_outside_a | fee_growth_outside_b |  points_growth_outside   |    rewards_outside     |
    //|---------|-------------------------------|----------------|-----------------|----------------------|----------------------|--------------------------|------------------------|
    //| -443636 |          4295048016           |    3383805     |     3383805     |          0           |          0           |            0             |       [0, 0, 0]        |
    //|  -4056  |     15060840354818686363      |   1291105259   |   1291105259    |     35690725982      |    74254907353328    |            0             |          [0]           |
    //|  -1000  |     17547129613991598777      |   896544652    |    896544652    |     35690725982      |    74254907353328    |            0             |          [0]           |
    //|   -6    |     18441211157107643397      |   6668000044   |   6668000044    |          0           |          0           |            0             |           []           |
    //|   -4    |     18443055278223354162      |   6664722064   |   6664722064    |          0           |     221263904357     |            0             |           []           |
    //|   -2    |     18444899583751176498      | 8861984406924  |  8861984406924  |          0           |          0           |            0             |           []           |
    //|    2    |     18448588748116922571      |    -400039     |     400039      |          0           |     146569530227     | 18315901437100576056941  |       [0, 0, 0]        |
    //|    4    |     18450433606991734263      | -8861984006885 |  8861984006885  |     35690725982      |     330892876818     | 18316729349634071718224  |       [0, 0, 0]        |
    //|    6    |     18452278650352433436      |  -13332722108  |   13332722108   |     35690725982      |     478923680058     | 18316729349634071718224  |       [0, 0, 0]        |
    //|   548   |     18959147107529850169      |   231964850    |    231964850    |    10060485047214    |    74928443098177    |            0             |          [0]           |
    //|   816   |     19214896586356138629      |    30594502    |    30594502     |    10060485047214    |    74928443098177    |            0             |          [0]           |
    //|   820   |     19218739757822375721      |   -30594502    |    30594502     |          0           |          0           |            0             |       [0, 0, 0]        |
    //|   910   |     19305414625256680593      |   -231964850   |    231964850    |          0           |          0           |            0             |       [0, 0, 0]        |
    //|   946   |     19340193924625646706      |  15313241696   |   15313241696   |     502682728422     |          0           | 264220590889522333448784 | [27731076341762168138] |
    //|   948   |     19342127944018109271      |  131100125586  |  131100125586   |          0           |          0           |            0             |       [0, 0, 0]        |
    //|   956   |     19349865955800763602      | -131100125586  |  131100125586   |          0           |          0           |            0             |       [0, 0, 0]        |
    //|   960   |     19353736122490583312      |  -15313241696  |   15313241696   |          0           |          0           |            0             |       [0, 0, 0]        |
    //|  1000   |     19392480388906836277      |   -896544652   |    896544652    |          0           |          0           |            0             |       [0, 0, 0]        |
    //|  5010   |     23697637456172827896      |  -1291105259   |   1291105259    |          0           |          0           |            0             |       [0, 0, 0]        |
    //| 443636  | 79226673515401279992447579055 |    -3383805    |     3383805     |          0           |          0           |            0             |       [0, 0, 0]        |
    //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    let ctx = &mut tx_context::dummy();
    let mut clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        19218706184437883591,
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let ticks = vector[
        tick::new_tick_for_test(nt(443636), i128::from(3383805), 3383805, 0, 0, 0, vector[0, 0, 0]),
        tick::new_tick_for_test(
            nt(4056),
            i128::from(1291105259),
            1291105259,
            35690725982,
            74254907353328,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            nt(1000),
            i128::from(896544652),
            896544652,
            35690725982,
            74254907353328,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(nt(6), i128::from(6668000044), 6668000044, 0, 0, 0, vector[]),
        tick::new_tick_for_test(
            nt(4),
            i128::from(6664722064),
            6664722064,
            0,
            221263904357,
            0,
            vector[],
        ),
        tick::new_tick_for_test(nt(2), i128::from(8861984406924), 8861984406924, 0, 0, 0, vector[]),
        tick::new_tick_for_test(
            pt(2),
            i128::neg_from(400039),
            400039,
            0,
            146569530227,
            18315901437100576056941,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(4),
            i128::neg_from(8861984006885),
            8861984006885,
            35690725982,
            330892876818,
            18316729349634071718224,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(6),
            i128::neg_from(13332722108),
            13332722108,
            35690725982,
            478923680058,
            18316729349634071718224,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(548),
            i128::from(231964850),
            231964850,
            10060485047214,
            74928443098177,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            pt(816),
            i128::from(30594502),
            30594502,
            10060485047214,
            74928443098177,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            pt(820),
            i128::neg_from(30594502),
            30594502,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(910),
            i128::neg_from(231964850),
            231964850,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(946),
            i128::from(15313241696),
            15313241696,
            502682728422,
            0,
            264220590889522333448784,
            vector[27731076341762168138],
        ),
        tick::new_tick_for_test(
            pt(948),
            i128::from(131100125586),
            131100125586,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(956),
            i128::neg_from(131100125586),
            131100125586,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(960),
            i128::neg_from(15313241696),
            15313241696,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(1000),
            i128::neg_from(896544652),
            896544652,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(5010),
            i128::neg_from(1291105259),
            1291105259,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(443636),
            i128::neg_from(3383805),
            3383805,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
    ];
    let rewarders = vector[
        rewarder::new_rewarder_for_test<CoinC>(2135039823346012918518, 27805703433573585662),
    ];
    pool::update_for_swap_test(
        &mut pool,
        306402720,
        3045044692,
        2453593068,
        19218706184437883591,
        pt(819),
        10060485047214,
        74928443098177,
        605,
        13256,
        ticks,
        rewarders,
        2942366360221115740061696000000,
        264879563432616161785695,
        1681893635,
    );

    clock::increment_for_testing(&mut clock, 1681910349 * 1000);

    let tick_1 = *pool::borrow_tick(&pool, pt(820));
    let tick_2 = *pool::borrow_tick(&pool, pt(816));
    let tick_3 = *pool::borrow_tick(&pool, pt(548));
    let tick_4 = *pool::borrow_tick(&pool, pt(6));
    let tick_5 = *pool::borrow_tick(&pool, pt(4));
    let tick_6 = *pool::borrow_tick(&pool, pt(2));
    let tick_7 = *pool::borrow_tick(&pool, nt(2));
    let tick_8 = *pool::borrow_tick(&pool, nt(4));
    let tick_9 = *pool::borrow_tick(&pool, nt(6));
    let tick_10 = *pool::borrow_tick(&pool, nt(1000));
    let tick_11 = *pool::borrow_tick(&pool, nt(4056));
    let tick_12 = *pool::borrow_tick(&pool, nt(443636));
    pool::update_pool_fee_rate(&mut pool, 0);
    swap(
        &mut pool,
        &config,
        true,
        true,
        3095226563,
        11024038130778859745,
        &clock,
        ctx,
    );

    assert!(pool::current_sqrt_price(&pool) == 11024038130778859745, 0);
    let tick_a1 = *pool::borrow_tick(&pool, pt(820));
    let tick_a2 = *pool::borrow_tick(&pool, pt(816));
    let tick_a3 = *pool::borrow_tick(&pool, pt(548));
    let tick_a4 = *pool::borrow_tick(&pool, pt(6));
    let tick_a5 = *pool::borrow_tick(&pool, pt(4));
    let tick_a6 = *pool::borrow_tick(&pool, pt(2));
    let tick_a7 = *pool::borrow_tick(&pool, nt(2));
    let tick_a8 = *pool::borrow_tick(&pool, nt(4));
    let tick_a9 = *pool::borrow_tick(&pool, nt(6));
    let tick_a10 = *pool::borrow_tick(&pool, nt(1000));
    let tick_a11 = *pool::borrow_tick(&pool, nt(4056));
    let tick_a12 = *pool::borrow_tick(&pool, nt(443636));
    assert!(tick::is_tick_equal(&tick_1, &tick_a1), 0);
    assert!(!tick::is_tick_equal(&tick_2, &tick_a2), 0);
    assert!(!tick::is_tick_equal(&tick_3, &tick_a3), 0);
    assert!(!tick::is_tick_equal(&tick_4, &tick_a4), 0);
    assert!(!tick::is_tick_equal(&tick_5, &tick_a5), 0);
    assert!(!tick::is_tick_equal(&tick_6, &tick_a6), 0);
    assert!(!tick::is_tick_equal(&tick_7, &tick_a7), 0);
    assert!(!tick::is_tick_equal(&tick_8, &tick_a8), 0);
    assert!(!tick::is_tick_equal(&tick_9, &tick_a9), 0);
    assert!(!tick::is_tick_equal(&tick_10, &tick_a10), 0);
    assert!(!tick::is_tick_equal(&tick_11, &tick_a11), 0);
    assert!(tick::is_tick_equal(&tick_12, &tick_a12), 0);
    swap(
        &mut pool,
        &config,
        false,
        true,
        1000000000000000,
        19218706184437883591,
        &clock,
        ctx,
    );

    assert!(pool::current_sqrt_price(&pool) == 19218706184437883591, 0);
    let tick_b1 = pool::borrow_tick(&pool, pt(820));
    let tick_b2 = pool::borrow_tick(&pool, pt(816));
    let tick_b3 = pool::borrow_tick(&pool, pt(548));
    let tick_b4 = pool::borrow_tick(&pool, pt(6));
    let tick_b5 = pool::borrow_tick(&pool, pt(4));
    let tick_b6 = pool::borrow_tick(&pool, pt(2));
    let tick_b7 = pool::borrow_tick(&pool, nt(2));
    let tick_b8 = pool::borrow_tick(&pool, nt(4));
    let tick_b9 = pool::borrow_tick(&pool, nt(6));
    let tick_b10 = pool::borrow_tick(&pool, nt(1000));
    let tick_b11 = pool::borrow_tick(&pool, nt(4056));
    let tick_b12 = pool::borrow_tick(&pool, nt(443636));

    assert!(tick::is_tick_equal(tick_b1, &tick_1), 0);
    assert!(tick::is_tick_equal(tick_b2, &tick_2), 0);
    assert!(tick::is_tick_equal(tick_b3, &tick_3), 0);
    assert!(tick::is_tick_equal(tick_b4, &tick_4), 0);
    assert!(tick::is_tick_equal(tick_b5, &tick_5), 0);
    assert!(tick::is_tick_equal(tick_b6, &tick_6), 0);
    assert!(tick::is_tick_equal(tick_b7, &tick_7), 0);
    assert!(tick::is_tick_equal(tick_b8, &tick_8), 0);
    assert!(tick::is_tick_equal(tick_b9, &tick_9), 0);
    assert!(tick::is_tick_equal(tick_b10, &tick_10), 0);
    assert!(tick::is_tick_equal(tick_b11, &tick_11), 0);
    assert!(tick::is_tick_equal(tick_b12, &tick_12), 0);

    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    clock::destroy_for_testing(clock);
}

#[test]
public fun calculate_swap_result() {
    let ctx = &mut tx_context::dummy();
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        19218706184437883591,
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let ticks = vector[
        tick::new_tick_for_test(nt(443636), i128::from(3383805), 3383805, 0, 0, 0, vector[0, 0, 0]),
        tick::new_tick_for_test(
            nt(4056),
            i128::from(1291105259),
            1291105259,
            35690725982,
            74254907353328,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            nt(1000),
            i128::from(896544652),
            896544652,
            35690725982,
            74254907353328,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(nt(6), i128::from(6668000044), 6668000044, 0, 0, 0, vector[]),
        tick::new_tick_for_test(
            nt(4),
            i128::from(6664722064),
            6664722064,
            0,
            221263904357,
            0,
            vector[],
        ),
        tick::new_tick_for_test(nt(2), i128::from(8861984406924), 8861984406924, 0, 0, 0, vector[]),
        tick::new_tick_for_test(
            pt(2),
            i128::neg_from(400039),
            400039,
            0,
            146569530227,
            18315901437100576056941,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(4),
            i128::neg_from(8861984006885),
            8861984006885,
            35690725982,
            330892876818,
            18316729349634071718224,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(6),
            i128::neg_from(13332722108),
            13332722108,
            35690725982,
            478923680058,
            18316729349634071718224,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(548),
            i128::from(231964850),
            231964850,
            10060485047214,
            74928443098177,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            pt(816),
            i128::from(30594502),
            30594502,
            10060485047214,
            74928443098177,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            pt(820),
            i128::neg_from(30594502),
            30594502,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(910),
            i128::neg_from(231964850),
            231964850,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(946),
            i128::from(15313241696),
            15313241696,
            502682728422,
            0,
            264220590889522333448784,
            vector[27731076341762168138],
        ),
        tick::new_tick_for_test(
            pt(948),
            i128::from(131100125586),
            131100125586,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(956),
            i128::neg_from(131100125586),
            131100125586,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(960),
            i128::neg_from(15313241696),
            15313241696,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(1000),
            i128::neg_from(896544652),
            896544652,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(5010),
            i128::neg_from(1291105259),
            1291105259,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(443636),
            i128::neg_from(3383805),
            3383805,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
    ];
    let rewarders = vector[
        rewarder::new_rewarder_for_test<CoinC>(2135039823346012918518, 27805703433573585662),
    ];
    pool::update_for_swap_test(
        &mut pool,
        306402720,
        3045044692,
        2453593068,
        19218706184437883591,
        pt(819),
        10060485047214,
        74928443098177,
        605,
        13256,
        ticks,
        rewarders,
        2942366360221115740061696000000,
        264879563432616161785695,
        1681893635,
    );
    transfer::public_transfer(admin_cap, @0x124);
    transfer::public_share_object(config);
    clock.destroy_for_testing();
    let res = pool.calculate_swap_result(true, true, 100000000);
    assert_eq!(
        res.calculated_swap_result_amount_in() + res.calculated_swap_result_fee_amount(),
        100000000,
    );
    transfer::public_share_object(pool);
}
// Run this test need back function inter-mate::math_u256::checked_shlw to bug version
//  public fun checked_shlw(n: u256): (u256, bool) {
//     let mask = 0xffffffffffffffff << 192;
//     if (n > mask) {
//         (0, true)
//     } else {
//         ((n << 64), false)
//     }
// }
#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EMULTIPLICATION_OVERFLOW)]
public fun test_emergency_restore_pool_state() {
    let ctx = &mut tx_context::dummy();
    let mut clock = clock::create_for_testing(ctx);
    let (admin_cap, mut config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        19218706184437883591,
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let ticks = vector[
        tick::new_tick_for_test(nt(443636), i128::from(3383805), 3383805, 0, 0, 0, vector[0, 0, 0]),
        tick::new_tick_for_test(
            nt(4056),
            i128::from(1291105259),
            1291105259,
            35690725982,
            74254907353328,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            nt(1000),
            i128::from(896544652),
            896544652,
            35690725982,
            74254907353328,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(nt(6), i128::from(6668000044), 6668000044, 0, 0, 0, vector[]),
        tick::new_tick_for_test(
            nt(4),
            i128::from(6664722064),
            6664722064,
            0,
            221263904357,
            0,
            vector[],
        ),
        tick::new_tick_for_test(nt(2), i128::from(8861984406924), 8861984406924, 0, 0, 0, vector[]),
        tick::new_tick_for_test(
            pt(2),
            i128::neg_from(400039),
            400039,
            0,
            146569530227,
            18315901437100576056941,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(4),
            i128::neg_from(8861984006885),
            8861984006885,
            35690725982,
            330892876818,
            18316729349634071718224,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(6),
            i128::neg_from(13332722108),
            13332722108,
            35690725982,
            478923680058,
            18316729349634071718224,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(548),
            i128::from(231964850),
            231964850,
            10060485047214,
            74928443098177,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            pt(816),
            i128::from(30594502),
            30594502,
            10060485047214,
            74928443098177,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(
            pt(820),
            i128::neg_from(30594502),
            30594502,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(910),
            i128::neg_from(231964850),
            231964850,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(946),
            i128::from(15313241696),
            15313241696,
            502682728422,
            0,
            264220590889522333448784,
            vector[27731076341762168138],
        ),
        tick::new_tick_for_test(
            pt(948),
            i128::from(131100125586),
            131100125586,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(956),
            i128::neg_from(131100125586),
            131100125586,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(960),
            i128::neg_from(15313241696),
            15313241696,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(1000),
            i128::neg_from(896544652),
            896544652,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(5010),
            i128::neg_from(1291105259),
            1291105259,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(443636),
            i128::neg_from(3383805),
            3383805,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
    ];
    let rewarders = vector[
        rewarder::new_rewarder_for_test<CoinC>(2135039823346012918518, 27805703433573585662),
    ];
    pool::update_for_swap_test(
        &mut pool,
        20364318607948,
        2693345937652262,
        2453593068,
        19218706184437883591,
        pt(819),
        10060485047214,
        74928443098177,
        605,
        13256,
        ticks,
        rewarders,
        2942366360221115740061696000000,
        264879563432616161785695,
        1681893635,
    );

    let current_liquidity = pool::liquidity(&pool);
    clock::increment_for_testing(&mut clock, 1681910349 * 1000);

    pool::update_pool_fee_rate(&mut pool, 0);
    swap(
        &mut pool,
        &config,
        true,
        true,
        3095226563,
        11024038130778859745,
        &clock,
        ctx,
    );

    assert!(pool::current_sqrt_price(&pool) == 11024038130778859745, 0);

    // pool::update_pool_balance(&mut pool, ctx);
    // swap(
    //     &mut pool,
    //     &config,
    //     false,
    //     true,
    //     1000000000000000,
    //     19218706184437883591,
    //     &clock,
    //     ctx
    // );
    let mut position_nft = open_position_with_liquidity(
        &config,
        &mut pool,
        pt(300000),
        pt(300060),
        34673429775949185766360837292402478,
        &clock,
        ctx,
    );
    let object_id = object::id(&position_nft);
    std::debug::print(&1234567);
    // std::debug::print(&position::liquidity(&position_nft));
    let (recv_a, recv_b) = remove_liquidity<CoinA, CoinB>(
        &config,
        &mut pool,
        &mut position_nft,
        22208187626482299498890,
        &clock,
        ctx,
    );
    std::debug::print(&recv_a);
    std::debug::print(&recv_b);
    transfer::public_transfer(position_nft, @0x123);
    pool::emergency_remove_malicious_position(
        &mut config,
        &mut pool,
        object_id,
        ctx,
    );
    pool::emergency_restore_pool_state(
        &mut config,
        &mut pool,
        19218706184437883591,
        current_liquidity,
        &clock,
        ctx,
    );

    assert!(pool::current_sqrt_price(&pool) == 19218706184437883591, 0);
    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    clock::destroy_for_testing(clock);
}

#[test]
public fun test_repair_tick_crossed_boudary_pool() {
    let ctx = &mut tx_context::dummy();
    let mut clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(0)),
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let ticks = vector[
        tick::new_tick_for_test(nt(443636), i128::from(0), 0, 0, 0, 0, vector[0, 0, 0]),
        tick::new_tick_for_test(
            nt(36696),
            i128::from(1717314347),
            1717314347,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            nt(18970),
            i128::neg_from(1717314347),
            1717314347,
            35690725982,
            74254907353328,
            0,
            vector[0],
        ),
        tick::new_tick_for_test(pt(443636), i128::from(0), 0, 0, 0, 0, vector[0, 0, 0]),
    ];
    clock::increment_for_testing(&mut clock, 1681910349 * 1000);
    pool::update_for_swap_test(
        &mut pool,
        6342726712,
        18214,
        0,
        4295048016,
        nt(443637),
        10060485047214,
        74928443098177,
        605,
        13256,
        ticks,
        vector[],
        2942366360221115740061696000000,
        264879563432616161785695,
        1681893635,
    );
    add_liquidity_for_swap(
        &config,
        &mut pool,
        nt(443636),
        pt(443636),
        100,
        &clock,
        ctx,
    );

    //pool::repair_tick_crossed_bounday_pool(&admin_cap, &mut pool);
    //assert!(i32::eq(pool::current_tick_index(&pool), nt(36697)), 1);

    let (recv, pay) = swap(
        &mut pool,
        &config,
        false,
        true,
        1000000,
        tick_math::max_sqrt_price(),
        &clock,
        ctx,
    );
    assert!(recv == 429527739024, 0);
    assert!(pay == 1000000, 0);

    //debug::print(&pool);

    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    clock::destroy_for_testing(clock);
}

#[test]
public fun test_verify_tick_cross_boudary() {
    let ctx = &mut tx_context::dummy();
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(0)),
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );

    add_liquidity_for_swap(
        &config,
        &mut pool,
        nt(10),
        pt(10),
        10000,
        &clock,
        ctx,
    );

    swap(
        &mut pool,
        &config,
        true,
        true,
        1000000,
        get_sqrt_price_at_tick(nt(10)),
        &clock,
        ctx,
    );
    assert!(i32::eq(pool::current_tick_index(&pool), nt(11)), 0);
    swap(
        &mut pool,
        &config,
        false,
        true,
        1000000,
        get_sqrt_price_at_tick(pt(10)),
        &clock,
        ctx,
    );
    assert!(i32::eq(pool::current_tick_index(&pool), pt(10)), 0);

    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    clock::destroy_for_testing(clock);
}

// Run this test need back function inter-mate::math_u256::checked_shlw to bug version
//  public fun checked_shlw(n: u256): (u256, bool) {
//     let mask = 0xffffffffffffffff << 192;
//     if (n > mask) {
//         (0, true)
//     } else {
//         ((n << 64), false)
//     }
// }
#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EMULTIPLICATION_OVERFLOW)]
fun test_0xbec7ef988a9cf880b1e3d80260ad1e972e680f0f340fc87fd6f014d32b83e526() {
    let ctx = &mut tx_context::dummy();
    let mut clock = clock::create_for_testing(ctx);
    let (admin_cap, mut config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        1,
        1405321012426839402037,
        10,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let ticks = vector[
        tick::new_tick_for_test(
            pt(79580),
            i128::from(245902088972011),
            245902088972011,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(92108),
            i128::neg_from(245902088972011),
            245902088972011,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(300000),
            i128::from(10365647984363941928176864624093585),
            10365647984363941928176864624093585,
            0,
            0,
            0,
            vector[],
        ),
        tick::new_tick_for_test(
            pt(300200),
            i128::neg_from(10365647984363941928176864624093585),
            10365647984363941928176864624093585,
            0,
            0,
            0,
            vector[],
        ),
    ];

    pool::update_for_swap_test(
        &mut pool,
        768794450447,
        5589382085398003,
        245902088972011,
        1405321012426839402037,
        pt(86666),
        1103741188277,
        6279293203033624,
        3626294,
        20578748281,
        ticks,
        vector[],
        0,
        264879563432616161785695,
        1681893635,
    );

    let current_liquidity = pool::liquidity(&pool);
    clock::increment_for_testing(&mut clock, 1681910349 * 1000);

    let (amount_out, amount_in) = swap(
        &mut pool,
        &config,
        true,
        true,
        768794450447,
        1134992181692617189035,
        &clock,
        ctx,
    );
    assert!(amount_out == 3603585755908344, 0);
    assert!(amount_in == 768794450447, 0);

    assert!(pool::current_sqrt_price(&pool) == 1134992181692617189035, 0);
    let mut position_nft = open_position_with_liquidity(
        &config,
        &mut pool,
        pt(300000),
        pt(300200),
        10365647984364446732462244378333008,
        &clock,
        ctx,
    );
    let object_id = object::id(&position_nft);
    // std::debug::print(&position::liquidity(&position_nft));
    let (recv_a, recv_b) = remove_liquidity<CoinA, CoinB>(
        &config,
        &mut pool,
        &mut position_nft,
        252402142689877119711,
        &clock,
        ctx,
    );
    std::debug::print(&recv_a);
    std::debug::print(&recv_b);
    assert!(recv_a == 768794450447, 0);
    assert!(recv_b == 0, 0);
    transfer::public_transfer(position_nft, @0x123);
    pool::emergency_remove_malicious_position(
        &mut config,
        &mut pool,
        object_id,
        ctx,
    );
    pool::emergency_restore_pool_state(
        &mut config,
        &mut pool,
        1405321012426839402037,
        current_liquidity,
        &clock,
        ctx,
    );

    assert!(pool::current_sqrt_price(&pool) == 1405321012426839402037, 0);
    assert!(pool::liquidity(&pool) == current_liquidity, 0);
    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    clock::destroy_for_testing(clock);
}

// Run this test need back function inter-mate::math_u256::checked_shlw to bug version
//  public fun checked_shlw(n: u256): (u256, bool) {
//     let mask = 0xffffffffffffffff << 192;
//     if (n > mask) {
//         (0, true)
//     } else {
//         ((n << 64), false)
//     }
// }
#[test]
#[expected_failure(abort_code = cetus_clmm::clmm_math::EMULTIPLICATION_OVERFLOW)]
fun test_0x6bd95ea11d8f932311d1b4e032de66dc61d3938cbb490216db4d2093c72be868() {
    let ctx = &mut tx_context::dummy();
    let mut clock = clock::create_for_testing(ctx);
    let (admin_cap, mut config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        200,
        63752604216060371,
        10000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let ticks = vector[
        tick::new_tick_for_test(
            nt(443600),
            i128::from(4472147549437038),
            4472147549437038,
            0,
            0,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            nt(131400),
            i128::from(18035848655),
            18035848655,
            332780721608526467268,
            3037196271007475,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            nt(114400),
            i128::neg_from(18035848655),
            18035848655,
            149699710212049017307,
            1987777651885278,
            0,
            vector[0, 0, 0],
        ),
        tick::new_tick_for_test(
            pt(300000),
            i128::from(10365647072995912738376108183161027),
            10365647072995912738376108183161027,
            0,
            0,
            0,
            vector[],
        ),
        tick::new_tick_for_test(
            pt(300200),
            i128::neg_from(10365647072995912738376108183161027),
            10365647072995912738376108183161027,
            0,
            0,
            0,
            vector[],
        ),
        tick::new_tick_for_test(
            pt(443600),
            i128::neg_from(4472147549437038),
            4472147549437038,
            0,
            0,
            0,
            vector[],
        ),
    ];
    pool::update_for_swap_test(
        &mut pool,
        1387973698994220290,
        16408281852101,
        4472147549437038,
        63752604216060371,
        nt(113359),
        350308193943030300939,
        3473752476255627,
        9035756805578589,
        110187188995,
        ticks,
        vector[],
        0,
        264879563432616161785695,
        1681893635,
    );

    let current_liquidity = pool::liquidity(&pool);
    clock::increment_for_testing(&mut clock, 1681910349 * 1000);

    let (amount_out, amount_in) = swap(
        &mut pool,
        &config,
        true,
        true,
        1387973698994220290,
        18333138564144692,
        &clock,
        ctx,
    );
    assert!(amount_out == 7959919014634, 0);
    std::debug::print(&amount_in);
    assert!(amount_in == 1387973698994220290, 0);

    assert!(pool::current_sqrt_price(&pool) == 30919596479242781, 0);
    let mut position_nft = open_position_with_liquidity(
        &config,
        &mut pool,
        pt(300000),
        pt(300200),
        10365647984364446732462244378333008,
        &clock,
        ctx,
    );
    let object_id = object::id(&position_nft);
    // std::debug::print(&position::liquidity(&position_nft));
    let (recv_a, recv_b) = remove_liquidity<CoinA, CoinB>(
        &config,
        &mut pool,
        &mut position_nft,
        455684266997043068097585990,
        &clock,
        ctx,
    );
    assert!(recv_a == 1387973698994220290, 0);
    assert!(recv_b == 0, 0);
    transfer::public_transfer(position_nft, @0x123);
    pool::emergency_remove_malicious_position(
        &mut config,
        &mut pool,
        object_id,
        ctx,
    );
    pool::emergency_restore_pool_state(
        &mut config,
        &mut pool,
        63752604216060371,
        current_liquidity,
        &clock,
        ctx,
    );

    assert!(pool::current_sqrt_price(&pool) == 63752604216060371, 0);
    assert!(pool::liquidity(&pool) == current_liquidity, 0);
    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    clock::destroy_for_testing(clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EAmountIncorrect)]
public fun test_repay_flash_swap_invalid_amount_a() {
    let ctx = &mut tx_context::dummy();
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(0)),
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );

    add_liquidity_for_swap(
        &config,
        &mut pool,
        nt(10),
        pt(10),
        10000000000,
        &clock,
        ctx,
    );
    let (recv_balance_a, recv_balance_b, receipt) = pool::flash_swap(
        &config,
        &mut pool,
        true,
        true,
        10000,
        4295048016,
        &clock,
    );
    pool::repay_flash_swap(
        &config,
        &mut pool,
        recv_balance_a,
        recv_balance_b,
        receipt,
    );

    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    clock::destroy_for_testing(clock);
}


#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EAmountIncorrect)]
public fun test_repay_flash_swap_invalid_amount_b() {
    let ctx = &mut tx_context::dummy();
    let clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(0)),
        100,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );

    add_liquidity_for_swap(
        &config,
        &mut pool,
        nt(10),
        pt(10),
        10000000000,
        &clock,
        ctx,
    );
    let (recv_balance_a, recv_balance_b, receipt) = pool::flash_swap(
        &config,
        &mut pool,
        false,
        true,
        10000,
        79226673515401279992447579055,
        &clock,
    );
    pool::repay_flash_swap(
        &config,
        &mut pool,
        recv_balance_a,
        recv_balance_b,
        receipt,
    );

    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    clock::destroy_for_testing(clock);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EFlashSwapReceiptNotMatch)]
public fun test_repay_flash_swap_receipt_not_match() {
    let ctx = &mut tx_context::dummy();
    let mut clock = clock::create_for_testing(ctx);
    let (admin_cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        2,
        get_sqrt_price_at_tick(i32::from(0)),
        10000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );

    add_liquidity_for_swap(
        &config,
        &mut pool,
        nt(10),
        pt(10),
        10000000000,
        &clock,
        ctx,
    );
    let (cap, partner) = cetus_clmm::partner::create_partner_for_test(
        string::utf8(b"test"),
        10000-1,
        0,
        10000000000,
        &clock,
        ctx,
    );
    clock::increment_for_testing(&mut clock, 1000000);
    let (recv_balance_a, recv_balance_b, receipt) = pool::flash_swap_with_partner(
        &config,
        &mut pool,
        &partner,
        false,
        true,
        100000,
        79226673515401279992447579055,
        &clock,
    );
    pool::repay_flash_swap(
        &config,
        &mut pool,
        recv_balance_a,
        recv_balance_b,
        receipt,
    );

    transfer::public_transfer(cap, @0x123);
    transfer::public_transfer(pool, @0x123);
    transfer::public_transfer(admin_cap, @0x123);
    transfer::public_transfer(config, @0x123);
    transfer::public_transfer(partner, @0x123);
    clock::destroy_for_testing(clock);
}
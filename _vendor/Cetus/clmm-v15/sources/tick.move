// Copyright (c) Cetus Technology Limited

/// The `tick` module is a module that is designed to facilitate the management of `tick` owned by `Pool`.
/// All `tick` related operations of `Pool` are handled by this module.
module cetus_clmm::tick;

use cetus_clmm::tick_math;
use integer_mate::i128::{Self, I128};
use integer_mate::i32::{Self, I32};
use integer_mate::math_u128;
use move_stl::option_u64::{Self, OptionU64};
use move_stl::skip_list::{Self, SkipList};

const ELiquidityOverflow: u64 = 0;
const ELiquidityUnderflow: u64 = 1;
const EInvalidTick: u64 = 2;
const ETickNotFound: u64 = 3;

/// Manages ticks of a pool using a SkipList data structure.
/// The SkipList provides efficient insertion, deletion and lookup of ticks.
/// Each tick represents a price point in the pool where liquidity can be added or removed.
/// * `tick_spacing` - The spacing between initialized ticks
/// * `ticks` - The SkipList containing all initialized ticks
public struct TickManager has store {
    tick_spacing: u32,
    ticks: SkipList<Tick>,
}

/// Represents the state of a tick in the pool.
/// * `index` - The tick index
/// * `sqrt_price` - The sqrt price at this tick
/// * `liquidity_net` - The net liquidity change when crossing this tick
/// * `liquidity_gross` - The total liquidity at this tick
/// * `fee_growth_outside_a` - The fee growth of token A outside this tick
/// * `fee_growth_outside_b` - The fee growth of token B outside this tick
/// * `points_growth_outside` - The points growth outside this tick
/// * `rewards_growth_outside` - The rewards growth outside this tick
public struct Tick has copy, drop, store {
    index: I32,
    sqrt_price: u128,
    liquidity_net: I128,
    liquidity_gross: u128,
    fee_growth_outside_a: u128,
    fee_growth_outside_b: u128,
    points_growth_outside: u128,
    rewards_growth_outside: vector<u128>,
}

/// Initialize the TickManager.
/// * `tick_spacing` - The spacing between initialized ticks
/// * `seed` - The seed for the SkipList
/// * `ctx` - The transaction context
/// * Returns the new TickManager
public(package) fun new(tick_spacing: u32, seed: u64, ctx: &mut TxContext): TickManager {
    let manager = TickManager {
        tick_spacing,
        ticks: skip_list::new(16, 2, seed, ctx),
    };
    manager
}

/// Increase liquidity on Ticks.
/// If the tick not exists, insert into skip_list first.
/// * `manager` - The TickManager
/// * `pool_current_tick_idx` - The current tick index
/// * `tick_lower_idx` - The lower tick index
/// * `tick_upper_idx` - The upper tick index
/// * `delta_liquidity` - The delta liquidity
/// * `fee_growth_global_a` - The fee growth global of token A
/// * `fee_growth_global_b` - The fee growth global of token B
/// * `points_growth_global` - The points growth global
/// * `rewards_growth_global` - The rewards growth global
public(package) fun increase_liquidity(
    manager: &mut TickManager,
    pool_current_tick_idx: I32,
    tick_lower_idx: I32,
    tick_upper_idx: I32,
    delta_liquidity: u128,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    points_growth_global: u128,
    rewards_growth_global: vector<u128>,
) {
    if (delta_liquidity == 0) {
        return
    };
    let (lower_score, upper_score) = (tick_score(tick_lower_idx), tick_score(tick_upper_idx));

    let (mut first_init_lower, mut first_init_upper) = (false, false);
    if (!skip_list::contains(&manager.ticks, lower_score)) {
        skip_list::insert(&mut manager.ticks, lower_score, default(tick_lower_idx));
        first_init_lower = true;
    };
    if (!skip_list::contains(&manager.ticks, upper_score)) {
        skip_list::insert(&mut manager.ticks, upper_score, default(tick_upper_idx));
        first_init_upper = true;
    };

    // Update tick lower
    let tick_lower = skip_list::borrow_mut(&mut manager.ticks, lower_score);
    update_by_liquidity(
        tick_lower,
        pool_current_tick_idx,
        delta_liquidity,
        first_init_lower,
        true,
        false,
        fee_growth_global_a,
        fee_growth_global_b,
        points_growth_global,
        rewards_growth_global,
    );

    // Update tick upper
    let tick_upper = skip_list::borrow_mut(&mut manager.ticks, upper_score);
    update_by_liquidity(
        tick_upper,
        pool_current_tick_idx,
        delta_liquidity,
        first_init_upper,
        true,
        true,
        fee_growth_global_a,
        fee_growth_global_b,
        points_growth_global,
        rewards_growth_global,
    );
}

/// Decrease liquidity on Ticks.
/// if the tick liquidity is zero, remove from skip_list(skip for max_tick and min_tick);
/// * `manager` - The TickManager
/// * `pool_current_tick_index` - The current tick index
/// * `tick_lower_idx` - The lower tick index
/// * `tick_upper_idx` - The upper tick index
/// * `delta_liquidity` - The delta liquidity
/// * `fee_growth_global_a` - The fee growth global of token A
/// * `fee_growth_global_b` - The fee growth global of token B
/// * `points_growth_global` - The points growth global
/// * `rewards_growth_global` - The rewards growth global
public(package) fun decrease_liquidity(
    manager: &mut TickManager,
    pool_current_tick_index: I32,
    tick_lower_idx: I32,
    tick_upper_idx: I32,
    delta_liquidity: u128,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    points_growth_global: u128,
    rewards_growth_global: vector<u128>,
) {
    if (delta_liquidity == 0) {
        return
    };
    let (lower_score, upper_socre) = (tick_score(tick_lower_idx), tick_score(tick_upper_idx));
    assert!(skip_list::contains(&manager.ticks, lower_score), ETickNotFound);
    assert!(skip_list::contains(&manager.ticks, upper_socre), ETickNotFound);
    let tick_lower = skip_list::borrow_mut(&mut manager.ticks, lower_score);
    let after_liquidity_gross = update_by_liquidity(
        tick_lower,
        pool_current_tick_index,
        delta_liquidity,
        false,
        false,
        false,
        fee_growth_global_a,
        fee_growth_global_b,
        points_growth_global,
        rewards_growth_global,
    );
    if (after_liquidity_gross == 0) {
        skip_list::remove(&mut manager.ticks, lower_score);
    };

    let tick_upper = skip_list::borrow_mut(&mut manager.ticks, upper_socre);
    let after_liquidity_gross = update_by_liquidity(
        tick_upper,
        pool_current_tick_index,
        delta_liquidity,
        false,
        false,
        true,
        fee_growth_global_a,
        fee_growth_global_b,
        points_growth_global,
        rewards_growth_global,
    );
    if (after_liquidity_gross == 0) {
        skip_list::remove(&mut manager.ticks, upper_socre);
    };
}

/// Return the next tick index for swap.
/// * `manager` - The TickManager
/// * `current_tick_idx` - The current tick index
/// * `a2b` - If the swap is a2b or b2a
/// * Returns the next tick index for swap
public fun first_score_for_swap(
    manager: &TickManager,
    current_tick_idx: I32,
    a2b: bool,
): OptionU64 {
    let opt_next_score = if (a2b) {
        let current_tick_score = tick_score(current_tick_idx);
        skip_list::find_prev(&manager.ticks, current_tick_score, true)
    } else {
        if (i32::eq(current_tick_idx, i32::neg_from(tick_math::tick_bound() + 1))) {
            let current_tick_score = tick_score(tick_math::min_tick());
            skip_list::find_next(&manager.ticks, current_tick_score, true)
        } else {
            let current_tick_score = tick_score(current_tick_idx);
            skip_list::find_next(&manager.ticks, current_tick_score, false)
        }
    };
    opt_next_score
}

/// Borrow Tick by score and return the next tick score for swap.
/// * `manager` - The TickManager
/// * `score` - The score of the tick
/// * `a2b` - If the swap is a2b or b2a
/// * Returns the tick and the next tick score for swap
public fun borrow_tick_for_swap(manager: &TickManager, score: u64, a2b: bool): (&Tick, OptionU64) {
    assert!(skip_list::contains(&manager.ticks, score), ETickNotFound);
    let node = skip_list::borrow_node(&manager.ticks, score);
    let opt_next_target_score = if (a2b) {
        skip_list::prev_score(node)
    } else {
        skip_list::next_score(node)
    };
    (skip_list::borrow_value(node), opt_next_target_score)
}

/// Try borrow tick by tick index.
/// * `manager` - The TickManager
/// * `tick_idx` - The tick index
/// * Returns the tick if it exists, otherwise returns None
public(package) fun try_borrow_tick(manager: &TickManager, tick_idx: I32): Option<Tick> {
    let score = tick_score(tick_idx);
    if (!skip_list::contains(&manager.ticks, score)) {
        return option::none<Tick>()
    };
    let tick = skip_list::borrow(&manager.ticks, score);
    option::some(*tick)
}

/// Get tick_spacing.
/// * `manager` - The TickManager
/// * Returns the tick spacing
public fun tick_spacing(manager: &TickManager): u32 {
    manager.tick_spacing
}

/// Get tick index
/// * `tick` - The tick
/// * Returns the tick index
public fun index(tick: &Tick): I32 {
    tick.index
}

/// Get tick sqrt_price
/// * `tick` - The tick
/// * Returns the tick sqrt price
public fun sqrt_price(tick: &Tick): u128 {
    tick.sqrt_price
}

/// Get tick liquidity_net
/// * `tick` - The tick
/// * Returns the tick liquidity net
public fun liquidity_net(tick: &Tick): I128 {
    tick.liquidity_net
}

/// Get tick liquidity_gross
/// * `tick` - The tick
/// * Returns the tick liquidity gross
public fun liquidity_gross(tick: &Tick): u128 {
    tick.liquidity_gross
}

/// Get tick fee_growth_insides
/// * `tick` - The tick
/// * Returns the tick fee growth outside
public fun fee_growth_outside(tick: &Tick): (u128, u128) {
    (tick.fee_growth_outside_a, tick.fee_growth_outside_b)
}

/// Get tick points_growth_outside
/// * `tick` - The tick
/// * Returns the tick points growth outside
public fun points_growth_outside(tick: &Tick): u128 {
    tick.points_growth_outside
}

/// Get tick rewards_growth_outside
/// * `tick` - The tick
/// * Returns the tick rewards growth outside
public fun rewards_growth_outside(tick: &Tick): &vector<u128> {
    &tick.rewards_growth_outside
}

/// Borrow Tick by index
/// * `manager` - The TickManager
/// * `idx` - The tick index
/// * Returns the tick
public fun borrow_tick(manager: &TickManager, idx: I32): &Tick {
    skip_list::borrow(&manager.ticks, tick_score(idx))
}

/// Get the tick reward_growth_outside by index.
/// * `tick` - The tick
/// * `idx` - The index of the reward growth outside
/// * Returns the tick reward growth outside
public fun get_reward_growth_outside(tick: &Tick, idx: u64): u128 {
    if (vector::length(&tick.rewards_growth_outside) <= idx) {
        0
    } else {
        *vector::borrow(&tick.rewards_growth_outside, idx)
    }
}

/// Get the fee inside in tick range.
/// * `pool_current_tick_index` - The current tick index
/// * `fee_growth_global_a` - The fee growth global of token A
/// * `fee_growth_global_b` - The fee growth global of token B
/// * `op_tick_lower` - The lower tick
/// * `op_tick_upper` - The upper tick
/// * Returns the fee growth inside
public fun get_fee_in_range(
    pool_current_tick_index: I32,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    op_tick_lower: Option<Tick>,
    op_tick_upper: Option<Tick>,
): (u128, u128) {
    let current_tick_index = pool_current_tick_index;
    let (fee_growth_below_a, fee_growth_below_b) = if (option::is_none<Tick>(&op_tick_lower)) {
        (fee_growth_global_a, fee_growth_global_b)
    } else {
        let tick_lower = option::borrow<Tick>(&op_tick_lower);
        if (i32::lt(current_tick_index, tick_lower.index)) {
            (
                math_u128::wrapping_sub(fee_growth_global_a, tick_lower.fee_growth_outside_a),
                math_u128::wrapping_sub(fee_growth_global_b, tick_lower.fee_growth_outside_b),
            )
        } else {
            (tick_lower.fee_growth_outside_a, tick_lower.fee_growth_outside_b)
        }
    };
    let (fee_growth_above_a, fee_growth_above_b) = if (option::is_none<Tick>(&op_tick_upper)) {
        (0, 0)
    } else {
        let tick_upper = option::borrow<Tick>(&op_tick_upper);
        if (i32::lt(current_tick_index, tick_upper.index)) {
            (tick_upper.fee_growth_outside_a, tick_upper.fee_growth_outside_b)
        } else {
            (
                math_u128::wrapping_sub(fee_growth_global_a, tick_upper.fee_growth_outside_a),
                math_u128::wrapping_sub(fee_growth_global_b, tick_upper.fee_growth_outside_b),
            )
        }
    };
    (
        math_u128::wrapping_sub(
            math_u128::wrapping_sub(fee_growth_global_a, fee_growth_below_a),
            fee_growth_above_a,
        ),
        math_u128::wrapping_sub(
            math_u128::wrapping_sub(fee_growth_global_b, fee_growth_below_b),
            fee_growth_above_b,
        ),
    )
}

/// Get the rewards inside in tick range.
/// * `pool_current_tick_index` - The current tick index
/// * `rewards_growth_globals` - The rewards growth globals
/// * `op_tick_lower` - The lower tick
/// * `op_tick_upper` - The upper tick
/// * Returns the rewards inside
public fun get_rewards_in_range(
    pool_current_tick_index: I32,
    rewards_growth_globals: vector<u128>,
    op_tick_lower: Option<Tick>,
    op_tick_upper: Option<Tick>,
): vector<u128> {
    let mut rewards_inside = vector::empty<u128>();
    let mut idx = 0;
    while (idx < vector::length(&rewards_growth_globals)) {
        let growth_global = *vector::borrow(&rewards_growth_globals, idx);
        let reward_growth_below = if (option::is_none(&op_tick_lower)) {
            growth_global
        } else {
            let tick_lower = option::borrow<Tick>(&op_tick_lower);
            if (i32::lt(pool_current_tick_index, tick_lower.index)) {
                //math_u128::wrapping_sub(growth_global, *vector::borrow(&tick_lower.rewards_growth_outside, idx))
                math_u128::wrapping_sub(growth_global, get_reward_growth_outside(tick_lower, idx))
            } else {
                //*vector::borrow(&tick_lower.rewards_growth_outside, idx)
                get_reward_growth_outside(tick_lower, idx)
            }
        };
        let rewarder_growths_above = if (option::is_none(&op_tick_upper)) {
            0
        } else {
            let tick_upper = option::borrow<Tick>(&op_tick_upper);
            if (i32::lt(pool_current_tick_index, tick_upper.index)) {
                //*vector::borrow(&tick_upper.rewards_growth_outside, idx)
                get_reward_growth_outside(tick_upper, idx)
            } else {
                //math_u128::wrapping_sub(growth_global, *vector::borrow(&tick_upper.rewards_growth_outside, idx))
                math_u128::wrapping_sub(growth_global, get_reward_growth_outside(tick_upper, idx))
            }
        };
        let rewarder_inside = math_u128::wrapping_sub(
            math_u128::wrapping_sub(growth_global, reward_growth_below),
            rewarder_growths_above,
        );
        vector::push_back(&mut rewards_inside, rewarder_inside);
        idx = idx + 1;
    };
    rewards_inside
}

/// Get the points inside in tick range.
/// * `pool_current_tick_index` - The current tick index
/// * `points_growth_global` - The points growth global
/// * `op_tick_lower` - The lower tick
/// * `op_tick_upper` - The upper tick
/// * Returns the points inside
public fun get_points_in_range(
    pool_current_tick_index: I32,
    points_growth_global: u128,
    op_tick_lower: Option<Tick>,
    op_tick_upper: Option<Tick>,
): u128 {
    let points_growth_below = if (option::is_none<Tick>(&op_tick_lower)) {
        points_growth_global
    } else {
        let tick_lower = option::borrow<Tick>(&op_tick_lower);
        if (i32::lt(pool_current_tick_index, tick_lower.index)) {
            math_u128::wrapping_sub(points_growth_global, tick_lower.points_growth_outside)
        } else {
            tick_lower.points_growth_outside
        }
    };
    let points_growth_above = if (option::is_none<Tick>(&op_tick_upper)) {
        0
    } else {
        let tick_upper = option::borrow<Tick>(&op_tick_upper);
        if (i32::lt(pool_current_tick_index, tick_upper.index)) {
            tick_upper.points_growth_outside
        } else {
            math_u128::wrapping_sub(points_growth_global, tick_upper.points_growth_outside)
        }
    };
    math_u128::wrapping_sub(
        math_u128::wrapping_sub(points_growth_global, points_growth_below),
        points_growth_above,
    )
}

/// When the swap cross the tick, the current liquidity of the pool will change.
/// Also the Tick infos will reverse.
/// * `manager` - The TickManager
/// * `tick_idx` - The tick index
/// * `a2b` - If the swap is a2b or b2a
/// * `pool_current_liquidity` - The current liquidity of the pool
/// * `fee_growth_global_a` - The fee growth global of token A
/// * `fee_growth_global_b` - The fee growth global of token B
/// * `points_growth_global` - The points growth global
/// * `reward_growth_globals` - The rewards growth globals
/// * Returns the after pool liquidity
public(package) fun cross_by_swap(
    manager: &mut TickManager,
    tick_idx: I32,
    a2b: bool,
    pool_current_liquidity: u128,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    points_growth_global: u128,
    reward_growth_globals: vector<u128>,
): u128 {
    let tick = skip_list::borrow_mut(&mut manager.ticks, tick_score(tick_idx));
    let liquidity_change = if (a2b) {
        i128::neg(tick.liquidity_net)
    } else {
        tick.liquidity_net
    };

    // update pool liquidity
    let after_pool_liquidity = if (!i128::is_neg(liquidity_change)) {
        let liquidity_change_abs = i128::abs_u128(liquidity_change);
        assert!(
            math_u128::add_check(liquidity_change_abs, pool_current_liquidity),
            ELiquidityUnderflow,
        );
        pool_current_liquidity + liquidity_change_abs
    } else {
        let liquidity_change_abs = i128::abs_u128(liquidity_change);
        assert!(pool_current_liquidity >= liquidity_change_abs, ELiquidityUnderflow);
        pool_current_liquidity - liquidity_change_abs
    };

    // update tick's fee_growth_outside_[ab]
    tick.fee_growth_outside_a =
        math_u128::wrapping_sub(fee_growth_global_a, tick.fee_growth_outside_a);
    tick.fee_growth_outside_b =
        math_u128::wrapping_sub(fee_growth_global_b, tick.fee_growth_outside_b);

    // update tick's rewarder
    let rewards_count = vector::length(&reward_growth_globals);
    if (rewards_count > 0) {
        let inited_count = vector::length(&tick.rewards_growth_outside);
        let mut idx = 0;
        while (idx < rewards_count) {
            let growth_global = *vector::borrow(&reward_growth_globals, idx);
            if (inited_count > idx) {
                let reward_growth_outside = *vector::borrow(&tick.rewards_growth_outside, idx);
                *vector::borrow_mut(&mut tick.rewards_growth_outside, idx) =
                    math_u128::wrapping_sub(growth_global, reward_growth_outside);
            } else {
                vector::push_back(&mut tick.rewards_growth_outside, growth_global);
            };
            idx = idx + 1;
        }
    };

    // update tick's points
    tick.points_growth_outside =
        math_u128::wrapping_sub(points_growth_global, tick.points_growth_outside);
    after_pool_liquidity
}

/// Fetch Ticks
/// * `manager` - The TickManager
/// * `start` - The start tick index
/// * `limit` - The max number of ticks to fetch
/// * Returns the ticks
public fun fetch_ticks(manager: &TickManager, start: vector<u32>, limit: u64): vector<Tick> {
    if(limit == 0) {
        return vector::empty<Tick>()
    };
    let mut ticks = vector::empty<Tick>();
    let mut opt_next_score = if (vector::is_empty(&start)) {
        skip_list::head(&manager.ticks)
    } else {
        let score = tick_score(i32::from_u32(*vector::borrow(&start, 0)));
        assert!(skip_list::contains(&manager.ticks, score), ETickNotFound);
        option_u64::some(score)
    };

    let mut count = 0;
    while (option_u64::is_some(&opt_next_score)) {
        let node = skip_list::borrow_node(&manager.ticks, option_u64::borrow(&opt_next_score));
        vector::push_back(&mut ticks, *skip_list::borrow_value(node));
        opt_next_score = skip_list::next_score(node);
        count = count + 1;
        if (count == limit) {
            break
        }
    };
    ticks
}

/// Get the number of ticks in the TickManager.
/// * `manager` - The TickManager
/// * Returns the number of ticks
public fun tick_count(manager: &TickManager): u64 {
    skip_list::length(&manager.ticks)
}

/// Update Tick Infos
/// * `tick` - The tick info
/// * `pool_current_tick_index` - The current tick index of pool
/// * `delta_liquidity` - The liquidity changes(add or remove)
/// * `first_init` - If the Tick not inited before, set to true
/// * `is_increase` - If the liquidity is increase or decrease.
/// * `is_upper_tick` - If the tick is upper tick or lower tick.
/// * `fee_growth_global_a` - The fee growth global of token A
/// * `fee_growth_global_b` - The fee growth global of token B
/// * `points_growth_global` - The points growth global
/// * `reward_growth_globals` - The rewards growth globals
/// * Returns the liquidity gross
fun update_by_liquidity(
    tick: &mut Tick,
    pool_current_tick_index: I32,
    delta_liquidity: u128,
    first_init: bool,
    is_increase: bool,
    is_upper_tick: bool,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    points_growth_global: u128,
    reward_growth_globals: vector<u128>,
): u128 {
    let liquidity_gross = if (is_increase) {
        assert!(math_u128::add_check(tick.liquidity_gross, delta_liquidity), ELiquidityOverflow);
        tick.liquidity_gross + delta_liquidity
    } else {
        assert!(tick.liquidity_gross >= delta_liquidity, ELiquidityUnderflow);
        tick.liquidity_gross - delta_liquidity
    };

    // If liquidity gross is zero, the pool will remove this tick
    if (liquidity_gross == 0) {
        return liquidity_gross
    };

    let (
        fee_growth_outside_a,
        fee_growth_outside_b,
        reward_growth_outside,
        points_growth_outside,
    ) = if (first_init) {
        if (i32::lt(pool_current_tick_index, tick.index)) {
            //(0u128, 0u128, vector[0, 0, 0], 0)
            (
                0u128,
                0u128,
                default_rewards_growth_outside(vector::length(&reward_growth_globals)),
                0,
            )
        } else {
            (fee_growth_global_a, fee_growth_global_b, reward_growth_globals, points_growth_global)
        }
    } else {
        (
            tick.fee_growth_outside_a,
            tick.fee_growth_outside_b,
            tick.rewards_growth_outside,
            tick.points_growth_outside,
        )
    };
    let (liquidity_net, overflow) = if (is_increase) {
        if (is_upper_tick) {
            i128::overflowing_sub(tick.liquidity_net, i128::from(delta_liquidity))
        } else {
            i128::overflowing_add(tick.liquidity_net, i128::from(delta_liquidity))
        }
    } else {
        if (is_upper_tick) {
            i128::overflowing_add(tick.liquidity_net, i128::from(delta_liquidity))
        } else {
            i128::overflowing_sub(tick.liquidity_net, i128::from(delta_liquidity))
        }
    };
    if (overflow) {
        abort ELiquidityOverflow
    };
    tick.liquidity_gross = liquidity_gross;
    tick.liquidity_net = liquidity_net;
    tick.fee_growth_outside_a = fee_growth_outside_a;
    tick.fee_growth_outside_b = fee_growth_outside_b;
    tick.rewards_growth_outside = reward_growth_outside;
    tick.points_growth_outside = points_growth_outside;
    liquidity_gross
}

/// Init a default Tick.
/// * `tick_idx` - The tick index
/// * Returns the default tick
fun default(tick_idx: I32): Tick {
    Tick {
        index: tick_idx,
        sqrt_price: tick_math::get_sqrt_price_at_tick(tick_idx),
        liquidity_net: i128::from(0),
        liquidity_gross: 0,
        fee_growth_outside_a: 0,
        fee_growth_outside_b: 0,
        points_growth_outside: 0,
        //rewards_growth_outside: vector<u128>[0, 0, 0],
        rewards_growth_outside: vector::empty<u128>(),
    }
}

/// generate default reward_growth_outsides by reward_count.
/// the default reward_growth_outside is 0.
/// * `reward_count` - The number of rewards
/// * Returns the default rewards growth outside
fun default_rewards_growth_outside(reward_count: u64): vector<u128> {
    if (reward_count <= 0) {
        vector::empty<u128>()
    } else {
        let mut outsides = vector::empty<u128>();
        let mut idx = 0;
        while (idx < reward_count) {
            vector::push_back(&mut outsides, 0);
            idx = idx + 1;
        };
        outsides
    }
}

/// For store Ticks in LinkedTable, convert the tick index of I32 to u64
/// Convert tick range[-443636, 443636] to [0, 443636*2].
/// * `tick` - The tick index
/// * Returns the tick score
fun tick_score(tick: I32): u64 {
    let t = i32::as_u32(i32::add(tick, i32::from(tick_math::tick_bound())));
    assert!((t >= 0) && (t <= (tick_math::tick_bound() * 2)), EInvalidTick);
    (t as u64)
}

#[test_only]
public fun mut_tick_manager(m: &mut TickManager): &mut SkipList<Tick> {
    &mut m.ticks
}

#[test_only]
public fun tick_manager(m: &TickManager): &SkipList<Tick> {
    &m.ticks
}

#[test_only]
public fun new_tick_for_test(
    index: I32,
    liquidity_net: I128,
    liquidity_gross: u128,
    fee_growth_outside_a: u128,
    fee_growth_outside_b: u128,
    points_growth_outside: u128,
    rewards_growth_outside: vector<u128>,
): Tick {
    Tick {
        index,
        sqrt_price: tick_math::get_sqrt_price_at_tick(index),
        liquidity_net,
        liquidity_gross,
        fee_growth_outside_a,
        fee_growth_outside_b,
        points_growth_outside,
        rewards_growth_outside,
    }
}

#[test_only]
public fun add_ticks_for_test(manager: &mut TickManager, ticks: vector<Tick>) {
    let mut idx = 0;
    while (idx < vector::length(&ticks)) {
        let tick = *vector::borrow(&ticks, idx);
        let score = tick_score(tick.index);
        if (skip_list::contains(&manager.ticks, score)) {
            skip_list::remove(&mut manager.ticks, score);
        };
        skip_list::insert(&mut manager.ticks, score, tick);
        idx = idx + 1;
    }
}

#[test_only]
public fun copy_tick_with_default(manager: &TickManager, tick_idx: I32): Tick {
    if (!skip_list::contains(&manager.ticks, tick_score(tick_idx))) {
        default(tick_idx)
    } else {
        *borrow_tick(manager, tick_idx)
    }
}

#[test_only]
public fun is_tick_equal(tick1: &Tick, tick2: &Tick): bool {
    // let idx = 0;
    // while (idx < vector::length(&tick1.rewards_growth_outside)) {
    //     if (*vector::borrow(&tick1.rewards_growth_outside, idx) != *vector::borrow(&tick2.rewards_growth_outside, idx)) {
    //         return false;
    //     };
    //     idx = idx + 1;
    // };
    i32::eq(tick1.index, tick2.index) &&
        tick1.sqrt_price== tick2.sqrt_price &&
        i128::eq(tick1.liquidity_net, tick2.liquidity_net) &&
        tick1.liquidity_gross == tick2.liquidity_gross &&
        tick1.fee_growth_outside_a == tick2.fee_growth_outside_a &&
        tick1.fee_growth_outside_b == tick2.fee_growth_outside_b &&
        tick1.points_growth_outside == tick2.points_growth_outside
}

#[test_only]
public fun insert_tick(
    manager: &mut TickManager,
    index: I32,
    sqrt_price: u128,
    liquidity_net: I128,
    liquidity_gross: u128,
    fee_growth_outside_a: u128,
    fee_growth_outside_b: u128,
    points_growth_outside: u128,
    rewards_growth_outside: vector<u128>,
) {
    let tick = Tick {
        index,
        sqrt_price,
        liquidity_net,
        liquidity_gross,
        fee_growth_outside_a,
        fee_growth_outside_b,
        points_growth_outside,
        rewards_growth_outside,
    };
    let score = tick_score(tick.index);
    if (skip_list::contains(&manager.ticks, score)) {
        skip_list::remove(&mut manager.ticks, score);
    };
    skip_list::insert(&mut manager.ticks, score, tick);
}

#[test_only]
public fun default_rewards_growth_outside_test(reward_count: u64): vector<u128> {
    default_rewards_growth_outside(reward_count)
}

#[test_only]
public fun default_tick_test(tick_idx: I32): Tick {
    default(tick_idx)
}

#[test_only]
public fun update_by_liquidity_test(
    tick: &mut Tick,
    pool_current_tick_index: I32,
    delta_liquidity: u128,
    first_init: bool,
    is_increase: bool,
    is_upper_tick: bool,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    points_growth_global: u128,
    reward_growth_globals: vector<u128>,
): u128 {
    update_by_liquidity(
        tick,
        pool_current_tick_index,
        delta_liquidity,
        first_init,
        is_increase,
        is_upper_tick,
        fee_growth_global_a,
        fee_growth_global_b,
        points_growth_global,
        reward_growth_globals,
    )
}

#[test]
#[expected_failure(abort_code = cetus_clmm::tick::EInvalidTick)]
fun test_tick_score_invalid_tick() {
    tick_score(i32::from(443637));
}

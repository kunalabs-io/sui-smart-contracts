#[test_only]
module kai_leverage::mock_dex;

use integer_mate::i32::{Self, I32};
use kai_leverage::balance_bag::{Self, BalanceBag};
use kai_leverage::mock_dex_math;
use sui::balance::{Self, Balance};
use sui::vec_set;

public use fun position_key_liquidity as PositionKey.liquidity;
public use fun position_tick_range as PositionKey.tick_range;
public use fun position_key_idx as PositionKey.idx;

public struct MockDexPosition has store {
    tick_a: I32,
    tick_b: I32,
    liquidity: u128,
    fees: BalanceBag,
    rewards: BalanceBag,
}

public struct MockDexPool<phantom X, phantom Y> has key {
    id: UID,
    current_sqrt_price_x64: u128,
    positions: vector<MockDexPosition>,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
}

public struct PositionKey has key, store {
    id: UID,
    idx: u64,
    tick_a: I32,
    tick_b: I32,
    liquidity: u128,
}

public struct LiquidityListItem has copy, drop, store {
    tick_end: I32,
    liquidity: u128,
}

public fun tick_a(position: &PositionKey): I32 {
    position.tick_a
}

public fun tick_b(position: &PositionKey): I32 {
    position.tick_b
}

public fun position_key_liquidity(position: &PositionKey): u128 {
    position.liquidity
}

public fun position_key_idx(position: &PositionKey): u64 {
    position.idx
}

public fun position_tick_range(position: &PositionKey): (I32, I32) {
    (position.tick_a, position.tick_b)
}

public fun current_tick_index<X, Y>(pool: &MockDexPool<X, Y>): I32 {
    mock_dex_math::get_tick_at_sqrt_price(pool.current_sqrt_price_x64)
}

public fun current_sqrt_price_x64<X, Y>(pool: &MockDexPool<X, Y>): u128 {
    pool.current_sqrt_price_x64
}

public fun calc_deposit_amounts_by_liquidity<X, Y>(
    pool: &MockDexPool<X, Y>,
    tick_a: I32,
    tick_b: I32,
    delta_l: u128,
): (u64, u64) {
    mock_dex_math::get_amount_by_liquidity(
        tick_a,
        tick_b,
        pool.current_tick_index(),
        pool.current_sqrt_price_x64,
        delta_l,
        true,
    )
}

public fun liquidity_at_tick<X, Y>(pool: &MockDexPool<X, Y>, tick: I32): u128 {
    let mut total = 0;
    vector::do_ref!(&pool.positions, |p| {
        if (p.tick_a.lte(tick) && p.tick_b.gt(tick)) {
            total = total + p.liquidity;
        }
    });
    total
}

public fun active_liquidity<X, Y>(pool: &MockDexPool<X, Y>): u128 {
    pool.liquidity_at_tick(pool.current_tick_index())
}

public fun get_liquidity_list_downwards<X, Y>(pool: &MockDexPool<X, Y>): vector<LiquidityListItem> {
    if (pool.positions.length() == 0) {
        return vector::empty()
    };

    let current_tick_index = pool.current_tick_index();

    let mut tick_set = vec_set::empty<I32>();
    pool.positions.do_ref!(|position| {
        if (position.tick_a.lte(current_tick_index) && !tick_set.contains(&position.tick_a)) {
            tick_set.insert(position.tick_a)
        };
        if (position.tick_b.lte(current_tick_index) && !tick_set.contains(&position.tick_b)) {
            tick_set.insert(position.tick_b)
        };
    });

    let mut tick_list = tick_set.into_keys();
    tick_list.insertion_sort_by!(|a, b| (*a).gte(*b));

    tick_list.map!(|tick| {
        LiquidityListItem {
            tick_end: tick,
            liquidity: pool.liquidity_at_tick(tick),
        }
    })
}

public fun get_liquidity_list_upwards<X, Y>(pool: &MockDexPool<X, Y>): vector<LiquidityListItem> {
    if (pool.positions.length() == 0) {
        return vector::empty()
    };

    let current_tick_index = pool.current_tick_index();

    let mut tick_set = vec_set::empty<I32>();
    pool.positions.do_ref!(|position| {
        if (position.tick_a.gt(current_tick_index) && !tick_set.contains(&position.tick_a)) {
            tick_set.insert(position.tick_a)
        };
        if (position.tick_b.gt(current_tick_index) && !tick_set.contains(&position.tick_b)) {
            tick_set.insert(position.tick_b)
        };
    });

    let mut tick_list = tick_set.into_keys();
    tick_list.insertion_sort_by!(|a, b| (*a).lte(*b));

    tick_list.map!(|tick| {
        LiquidityListItem {
            tick_end: tick,
            liquidity: pool.liquidity_at_tick(tick.sub(i32::from(1))),
        }
    })
}

public fun create_mock_dex_pool<X, Y>(
    current_sqrt_price_x64: u128,
    ctx: &mut TxContext,
): MockDexPool<X, Y> {
    MockDexPool {
        id: object::new(ctx),
        current_sqrt_price_x64,
        positions: vector::empty(),
        balance_x: balance::zero(),
        balance_y: balance::zero(),
    }
}

public fun open_position<X, Y>(
    pool: &mut MockDexPool<X, Y>,
    tick_a: I32,
    tick_b: I32,
    liquidity: u128,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
    ctx: &mut TxContext,
): PositionKey {
    let (need_x, need_y) = pool.calc_deposit_amounts_by_liquidity(
        tick_a,
        tick_b,
        liquidity,
    );
    assert!(balance_x.value() == need_x);
    assert!(balance_y.value() == need_y);

    pool.balance_x.join(balance_x);
    pool.balance_y.join(balance_y);

    let position = MockDexPosition {
        tick_a,
        tick_b,
        liquidity,
        fees: balance_bag::empty(ctx),
        rewards: balance_bag::empty(ctx),
    };
    pool.positions.push_back(position);

    PositionKey {
        id: object::new(ctx),
        idx: pool.positions.length() - 1,
        tick_a,
        tick_b,
        liquidity,
    }
}

public fun add_liquidity<X, Y>(
    pool: &mut MockDexPool<X, Y>,
    key: &mut PositionKey,
    balance_x: Balance<X>,
    balance_y: Balance<Y>,
    delta_l: u128,
): (u64, u64) {
    let (amt_x, amt_y) = mock_dex_math::get_amount_by_liquidity(
        key.tick_a,
        key.tick_b,
        pool.current_tick_index(),
        pool.current_sqrt_price_x64,
        delta_l,
        true,
    );
    assert!(balance_x.value() == amt_x);
    assert!(balance_y.value() == amt_y);

    pool.balance_x.join(balance_x);
    pool.balance_y.join(balance_y);

    let new_liquidity = pool.positions[key.idx].liquidity + delta_l;
    pool.positions[key.idx].liquidity = new_liquidity;
    key.liquidity = new_liquidity;

    (amt_x, amt_y)
}

public fun remove_liquidity<X, Y>(
    pool: &mut MockDexPool<X, Y>,
    key: &mut PositionKey,
    delta_l: u128,
): (Balance<X>, Balance<Y>) {
    let (amt_x, amt_y) = mock_dex_math::get_amount_by_liquidity(
        key.tick_a,
        key.tick_b,
        pool.current_tick_index(),
        pool.current_sqrt_price_x64,
        delta_l,
        false,
    );
    pool.positions[key.idx].liquidity = pool.positions[key.idx].liquidity - delta_l;
    key.liquidity = pool.positions[key.idx].liquidity;

    (pool.balance_x.split(amt_x), pool.balance_y.split(amt_y))
}

public fun swap_x_in<X, Y>(pool: &mut MockDexPool<X, Y>, mut balance_in: Balance<X>): Balance<Y> {
    let liquidity_list = pool.get_liquidity_list_downwards();
    assert!(liquidity_list.length() > 0);

    let a_to_b = true;
    let by_amount_in = true;
    let fee_rate = 0;

    let mut balance_out = balance::zero();

    let mut i = 0;
    while (i < liquidity_list.length()) {
        let liquidity_info = liquidity_list[i];
        let next_tick_sqrt_price_x64 = mock_dex_math::get_sqrt_price_at_tick(liquidity_info.tick_end);

        let (
            amount_in,
            amount_out,
            sqrt_price_after_swap_x64,
            _,
        ) = mock_dex_math::compute_swap_step(
            pool.current_sqrt_price_x64,
            next_tick_sqrt_price_x64,
            liquidity_info.liquidity,
            balance_in.value(),
            fee_rate,
            a_to_b,
            by_amount_in,
        );

        pool.balance_x.join(balance_in.split(amount_in));
        balance_out.join(pool.balance_y.split(amount_out));

        pool.current_sqrt_price_x64 = sqrt_price_after_swap_x64;

        if (balance_in.value() == 0) {
            break
        };

        i = i + 1;
    };

    assert!(balance_in.value() == 0);
    balance_in.destroy_zero();

    balance_out
}

public fun swap_y_in<X, Y>(pool: &mut MockDexPool<X, Y>, mut balance_in: Balance<Y>): Balance<X> {
    let liquidity_list = pool.get_liquidity_list_upwards();
    assert!(liquidity_list.length() > 0);

    let a_to_b = false;
    let by_amount_in = true;
    let fee_rate = 0;

    let mut balance_out = balance::zero();

    let mut i = 0;
    while (i < liquidity_list.length()) {
        let liquidity_info = liquidity_list[i];
        let next_tick_sqrt_price_x64 = mock_dex_math::get_sqrt_price_at_tick(liquidity_info.tick_end);

        let (
            amount_in,
            amount_out,
            sqrt_price_after_swap_x64,
            _,
        ) = mock_dex_math::compute_swap_step(
            pool.current_sqrt_price_x64,
            next_tick_sqrt_price_x64,
            liquidity_info.liquidity,
            balance_in.value(),
            fee_rate,
            a_to_b,
            by_amount_in,
        );

        pool.balance_y.join(balance_in.split(amount_in));
        balance_out.join(pool.balance_x.split(amount_out));

        pool.current_sqrt_price_x64 = sqrt_price_after_swap_x64;

        if (balance_in.value() == 0) {
            break
        };

        i = i + 1;
    };

    assert!(balance_in.value() == 0);
    balance_in.destroy_zero();

    balance_out
}

public fun add_fees_to_position<X, Y>(
    pool: &mut MockDexPool<X, Y>,
    position_idx: u64,
    fees_x: Balance<X>,
    fees_y: Balance<Y>,
) {
    pool.positions[position_idx].fees.add(fees_x);
    pool.positions[position_idx].fees.add(fees_y);
}

public fun add_reward_to_position<X, Y, T>(
    pool: &mut MockDexPool<X, Y>,
    position_idx: u64,
    rewards: Balance<T>,
) {
    pool.positions[position_idx].rewards.add(rewards);
}

public fun collect_fees<X, Y>(
    pool: &mut MockDexPool<X, Y>,
    position_key: &PositionKey,
): (Balance<X>, Balance<Y>) {
    (
        pool.positions[position_key.idx].fees.take_all(),
        pool.positions[position_key.idx].fees.take_all(),
    )
}

public fun collect_reward<X, Y, T>(
    pool: &mut MockDexPool<X, Y>,
    position_key: &PositionKey,
): Balance<T> {
    pool.positions[position_key.idx].rewards.take_all()
}

public fun close_position<X, Y>(pool: &mut MockDexPool<X, Y>, position_key: PositionKey) {
    let PositionKey { id, idx, .. } = position_key;
    object::delete(id);

    let position = pool.positions.remove(idx);
    let MockDexPosition { fees, rewards, .. } = position;
    fees.destroy_empty();
    rewards.destroy_empty();
}

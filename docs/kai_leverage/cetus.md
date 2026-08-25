
<a name="kai_leverage_cetus"></a>

# Module `kai_leverage::cetus`

Cetus DEX integration for leveraged concentrated liquidity positions.

This module provides a complete adapter layer for integrating Kai Leverage
with the Cetus concentrated liquidity AMM. It translates between the generic
position management interface and Cetus-specific pool operations, handling
liquidity provision, fee collection, and reward distribution.


-  [Struct `AHandleExploitedPosition`](#kai_leverage_cetus_AHandleExploitedPosition)
-  [Function `slippage_tolerance_assertion`](#kai_leverage_cetus_slippage_tolerance_assertion)
-  [Function `calc_deposit_amounts_by_liquidity`](#kai_leverage_cetus_calc_deposit_amounts_by_liquidity)
-  [Function `remove_liquidity`](#kai_leverage_cetus_remove_liquidity)
-  [Function `create_position_ticket`](#kai_leverage_cetus_create_position_ticket)
-  [Function `create_position_ticket_v2`](#kai_leverage_cetus_create_position_ticket_v2)
-  [Function `create_position_ticket_v3`](#kai_leverage_cetus_create_position_ticket_v3)
-  [Function `borrow_for_position_x`](#kai_leverage_cetus_borrow_for_position_x)
-  [Function `borrow_for_position_y`](#kai_leverage_cetus_borrow_for_position_y)
-  [Function `create_position`](#kai_leverage_cetus_create_position)
-  [Function `create_deleverage_ticket`](#kai_leverage_cetus_create_deleverage_ticket)
-  [Function `create_deleverage_ticket_v2`](#kai_leverage_cetus_create_deleverage_ticket_v2)
-  [Function `create_deleverage_ticket_for_liquidation`](#kai_leverage_cetus_create_deleverage_ticket_for_liquidation)
-  [Function `create_deleverage_ticket_for_liquidation_v2`](#kai_leverage_cetus_create_deleverage_ticket_for_liquidation_v2)
-  [Function `deleverage`](#kai_leverage_cetus_deleverage)
-  [Function `deleverage_v2`](#kai_leverage_cetus_deleverage_v2)
-  [Function `deleverage_for_liquidation`](#kai_leverage_cetus_deleverage_for_liquidation)
-  [Function `deleverage_for_liquidation_v2`](#kai_leverage_cetus_deleverage_for_liquidation_v2)
-  [Function `liquidate_col_x`](#kai_leverage_cetus_liquidate_col_x)
-  [Function `liquidate_col_x_v2`](#kai_leverage_cetus_liquidate_col_x_v2)
-  [Function `liquidate_col_y`](#kai_leverage_cetus_liquidate_col_y)
-  [Function `liquidate_col_y_v2`](#kai_leverage_cetus_liquidate_col_y_v2)
-  [Function `repay_bad_debt_x`](#kai_leverage_cetus_repay_bad_debt_x)
-  [Function `repay_bad_debt_x_v2`](#kai_leverage_cetus_repay_bad_debt_x_v2)
-  [Function `repay_bad_debt_y`](#kai_leverage_cetus_repay_bad_debt_y)
-  [Function `repay_bad_debt_y_v2`](#kai_leverage_cetus_repay_bad_debt_y_v2)
-  [Function `reduce`](#kai_leverage_cetus_reduce)
-  [Function `reduce_v2`](#kai_leverage_cetus_reduce_v2)
-  [Function `add_liquidity`](#kai_leverage_cetus_add_liquidity)
-  [Function `add_liquidity_v2`](#kai_leverage_cetus_add_liquidity_v2)
-  [Function `add_liquidity_fix_coin`](#kai_leverage_cetus_add_liquidity_fix_coin)
-  [Function `repay_debt_x`](#kai_leverage_cetus_repay_debt_x)
-  [Function `repay_debt_y`](#kai_leverage_cetus_repay_debt_y)
-  [Function `owner_collect_fee`](#kai_leverage_cetus_owner_collect_fee)
-  [Function `owner_collect_reward`](#kai_leverage_cetus_owner_collect_reward)
-  [Function `owner_take_stashed_rewards`](#kai_leverage_cetus_owner_take_stashed_rewards)
-  [Function `delete_position`](#kai_leverage_cetus_delete_position)
-  [Function `rebalance_collect_fee`](#kai_leverage_cetus_rebalance_collect_fee)
-  [Function `rebalance_collect_reward`](#kai_leverage_cetus_rebalance_collect_reward)
-  [Function `rebalance_add_liquidity`](#kai_leverage_cetus_rebalance_add_liquidity)
-  [Function `rebalance_add_liquidity_v2`](#kai_leverage_cetus_rebalance_add_liquidity_v2)
-  [Function `rebalance_add_liquidity_by_fix_coin`](#kai_leverage_cetus_rebalance_add_liquidity_by_fix_coin)
-  [Function `sync_exploited_position_liquidity_by_small_withdraw`](#kai_leverage_cetus_sync_exploited_position_liquidity_by_small_withdraw)
-  [Function `destruct_exploited_position_and_return_lp`](#kai_leverage_cetus_destruct_exploited_position_and_return_lp)
-  [Function `position_model`](#kai_leverage_cetus_position_model)
-  [Function `calc_liquidate_col_x`](#kai_leverage_cetus_calc_liquidate_col_x)
-  [Function `calc_liquidate_col_x_v2`](#kai_leverage_cetus_calc_liquidate_col_x_v2)
-  [Function `calc_liquidate_col_y`](#kai_leverage_cetus_calc_liquidate_col_y)
-  [Function `calc_liquidate_col_y_v2`](#kai_leverage_cetus_calc_liquidate_col_y_v2)


<pre><code><b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::i64;
<b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price;
<b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price_feed;
<b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price_identifier;
<b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price_info;
<b>use</b> (pyth=0x8D97F1CD6AC663735BE08D1D2B6D02A159E711586461306CE60A2B7A6A565A9E)::i64;
<b>use</b> (pyth=0x8D97F1CD6AC663735BE08D1D2B6D02A159E711586461306CE60A2B7A6A565A9E)::price;
<b>use</b> (pyth=0x8D97F1CD6AC663735BE08D1D2B6D02A159E711586461306CE60A2B7A6A565A9E)::price_feed;
<b>use</b> (pyth=0x8D97F1CD6AC663735BE08D1D2B6D02A159E711586461306CE60A2B7A6A565A9E)::price_identifier;
<b>use</b> (pyth=0x8D97F1CD6AC663735BE08D1D2B6D02A159E711586461306CE60A2B7A6A565A9E)::price_info;
<b>use</b> <a href="../../dependencies/access_management/access.md#access_management_access">access_management::access</a>;
<b>use</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map">access_management::dynamic_map</a>;
<b>use</b> cetus_clmm::acl;
<b>use</b> cetus_clmm::clmm_math;
<b>use</b> cetus_clmm::config;
<b>use</b> cetus_clmm::partner;
<b>use</b> cetus_clmm::pool;
<b>use</b> cetus_clmm::position;
<b>use</b> cetus_clmm::position_snapshot;
<b>use</b> cetus_clmm::rewarder;
<b>use</b> cetus_clmm::tick;
<b>use</b> cetus_clmm::tick_math;
<b>use</b> cetus_clmm::utils;
<b>use</b> integer_mate::full_math_u128;
<b>use</b> integer_mate::full_math_u64;
<b>use</b> integer_mate::i128;
<b>use</b> integer_mate::i32;
<b>use</b> integer_mate::i64;
<b>use</b> integer_mate::math_u128;
<b>use</b> integer_mate::math_u256;
<b>use</b> integer_mate::math_u64;
<b>use</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag">kai_leverage::balance_bag</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt">kai_leverage::debt</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag">kai_leverage::debt_bag</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info">kai_leverage::debt_info</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity">kai_leverage::equity</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm">kai_leverage::lp_shape_clmm</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price">kai_leverage::oracle_price</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise">kai_leverage::piecewise</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm">kai_leverage::position_core_clmm</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm">kai_leverage::position_model_clmm</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth">kai_leverage::pyth</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool">kai_leverage::supply_pool</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util">kai_leverage::util</a>;
<b>use</b> move_stl::linked_table;
<b>use</b> move_stl::option_u64;
<b>use</b> move_stl::random;
<b>use</b> move_stl::skip_list;
<b>use</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter">rate_limiter::net_sliding_sum_limiter</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator">rate_limiter::ring_aggregator</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter">rate_limiter::sliding_sum_limiter</a>;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/internal.md#std_internal">std::internal</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/u128.md#std_u128">std::u128</a>;
<b>use</b> <a href="../../dependencies/std/u64.md#std_u64">std::u64</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../../dependencies/sui/accumulator_settlement.md#sui_accumulator_settlement">sui::accumulator_settlement</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../../dependencies/sui/bcs.md#sui_bcs">sui::bcs</a>;
<b>use</b> <a href="../../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../../dependencies/sui/coin_registry.md#sui_coin_registry">sui::coin_registry</a>;
<b>use</b> <a href="../../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../../dependencies/sui/derived_object.md#sui_derived_object">sui::derived_object</a>;
<b>use</b> <a href="../../dependencies/sui/display.md#sui_display">sui::display</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../../dependencies/sui/funds_accumulator.md#sui_funds_accumulator">sui::funds_accumulator</a>;
<b>use</b> <a href="../../dependencies/sui/hash.md#sui_hash">sui::hash</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/package.md#sui_package">sui::package</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/protocol_config.md#sui_protocol_config">sui::protocol_config</a>;
<b>use</b> <a href="../../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_leverage_cetus_AHandleExploitedPosition"></a>

## Struct `AHandleExploitedPosition`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_AHandleExploitedPosition">AHandleExploitedPosition</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_cetus_slippage_tolerance_assertion"></a>

## Function `slippage_tolerance_assertion`

Assert that current pool price is within slippage tolerance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_slippage_tolerance_assertion">slippage_tolerance_assertion</a>&lt;X, Y&gt;(pool: &cetus_clmm::pool::Pool&lt;X, Y&gt;, p0_desired_x128: u256, max_slippage_bps: u16)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_slippage_tolerance_assertion">slippage_tolerance_assertion</a>&lt;X, Y&gt;(
    pool: &cetus_pool::Pool&lt;X, Y&gt;,
    p0_desired_x128: u256,
    max_slippage_bps: u16,
) {
    core::slippage_tolerance_assertion!(pool, p0_desired_x128, max_slippage_bps);
}
</code></pre>



</details>

<a name="kai_leverage_cetus_calc_deposit_amounts_by_liquidity"></a>

## Function `calc_deposit_amounts_by_liquidity`

Calculate token amounts needed for given liquidity on Cetus.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_deposit_amounts_by_liquidity">calc_deposit_amounts_by_liquidity</a>&lt;X, Y&gt;(pool: &cetus_clmm::pool::Pool&lt;X, Y&gt;, tick_a: integer_mate::i32::I32, tick_b: integer_mate::i32::I32, delta_l: u128): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_deposit_amounts_by_liquidity">calc_deposit_amounts_by_liquidity</a>&lt;X, Y&gt;(
    pool: &cetus_pool::Pool&lt;X, Y&gt;,
    tick_a: I32,
    tick_b: I32,
    delta_l: u128,
): (u64, u64) {
    <b>let</b> current_tick = pool.current_tick_index();
    <b>let</b> sqrt_p0_x64 = pool.current_sqrt_price();
    cetus_pool::get_amount_by_liquidity(
        tick_a,
        tick_b,
        current_tick,
        sqrt_p0_x64,
        delta_l,
        <b>true</b>,
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_remove_liquidity"></a>

## Function `remove_liquidity`

Remove liquidity from a Cetus position and return token balances.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_remove_liquidity">remove_liquidity</a>&lt;X, Y&gt;(config: &cetus_clmm::config::GlobalConfig, pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, lp_position: &<b>mut</b> cetus_clmm::position::Position, delta_l: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_remove_liquidity">remove_liquidity</a>&lt;X, Y&gt;(
    config: &cetus_config::GlobalConfig,
    pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    lp_position: &<b>mut</b> CetusPosition,
    delta_l: u128,
    clock: &Clock,
): (Balance&lt;X&gt;, Balance&lt;Y&gt;) {
    <b>if</b> (delta_l &gt; 0) {
        cetus_pool::remove_liquidity(config, pool, lp_position, delta_l, clock)
    } <b>else</b> {
        (balance::zero(), balance::zero())
    }
}
</code></pre>



</details>

<a name="kai_leverage_cetus_create_position_ticket"></a>

## Function `create_position_ticket`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_position_ticket">create_position_ticket</a>&lt;X, Y&gt;(_cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _tick_a: integer_mate::i32::I32, _tick_b: integer_mate::i32::I32, _principal_x: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, _principal_y: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, _delta_l: u128, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, integer_mate::i32::I32&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_position_ticket">create_position_ticket</a>&lt;X, Y&gt;(
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _config: &<b>mut</b> PositionConfig,
    _tick_a: I32,
    _tick_b: I32,
    _principal_x: Balance&lt;X&gt;,
    _principal_y: Balance&lt;Y&gt;,
    _delta_l: u128,
    _price_info: &PythPriceInfo,
    _ctx: &<b>mut</b> TxContext,
): CreatePositionTicket&lt;X, Y, I32&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_create_position_ticket_v2"></a>

## Function `create_position_ticket_v2`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_position_ticket_v2">create_position_ticket_v2</a>&lt;X, Y&gt;(_cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _tick_a: integer_mate::i32::I32, _tick_b: integer_mate::i32::I32, _principal_x: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, _principal_y: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, _delta_l: u128, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, _ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, integer_mate::i32::I32&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_position_ticket_v2">create_position_ticket_v2</a>&lt;X, Y&gt;(
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _config: &<b>mut</b> PositionConfig,
    _tick_a: I32,
    _tick_b: I32,
    _principal_x: Balance&lt;X&gt;,
    _principal_y: Balance&lt;Y&gt;,
    _delta_l: u128,
    _price_info: &PythPriceInfo,
    _clock: &Clock,
    _ctx: &<b>mut</b> TxContext,
): CreatePositionTicket&lt;X, Y, I32&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_create_position_ticket_v3"></a>

## Function `create_position_ticket_v3`

Like [create_position_ticket_v2], taking the rail-agnostic price collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_position_ticket_v3">create_position_ticket_v3</a>&lt;X, Y&gt;(cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, tick_a: integer_mate::i32::I32, tick_b: integer_mate::i32::I32, principal_x: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, principal_y: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, delta_l: u128, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, integer_mate::i32::I32&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_position_ticket_v3">create_position_ticket_v3</a>&lt;X, Y&gt;(
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    config: &<b>mut</b> PositionConfig,
    tick_a: I32,
    tick_b: I32,
    principal_x: Balance&lt;X&gt;,
    principal_y: Balance&lt;Y&gt;,
    delta_l: u128,
    price_info: &PriceCollection,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): CreatePositionTicket&lt;X, Y, I32&gt; {
    core::create_position_ticket!(
        cetus_pool,
        config,
        tick_a,
        tick_b,
        principal_x,
        principal_y,
        delta_l,
        price_info,
        clock,
        ctx,
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_borrow_for_position_x"></a>

## Function `borrow_for_position_x`

Borrow X tokens for position creation.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_borrow_for_position_x">borrow_for_position_x</a>&lt;X, Y, SX&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, integer_mate::i32::I32&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_borrow_for_position_x">borrow_for_position_x</a>&lt;X, Y, SX&gt;(
    ticket: &<b>mut</b> CreatePositionTicket&lt;X, Y, I32&gt;,
    config: &PositionConfig,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
) {
    core::borrow_for_position_x!(ticket, config, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_cetus_borrow_for_position_y"></a>

## Function `borrow_for_position_y`

Borrow Y tokens for position creation.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_borrow_for_position_y">borrow_for_position_y</a>&lt;X, Y, SY&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, integer_mate::i32::I32&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_borrow_for_position_y">borrow_for_position_y</a>&lt;X, Y, SY&gt;(
    ticket: &<b>mut</b> CreatePositionTicket&lt;X, Y, I32&gt;,
    config: &PositionConfig,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
) {
    core::borrow_for_position_y!(ticket, config, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_cetus_create_position"></a>

## Function `create_position`

Create a leveraged position from a prepared ticket.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_position">create_position</a>&lt;X, Y&gt;(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, integer_mate::i32::I32&gt;, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_global_config: &cetus_clmm::config::GlobalConfig, creation_fee: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_position">create_position</a>&lt;X, Y&gt;(
    config: &PositionConfig,
    ticket: CreatePositionTicket&lt;X, Y, I32&gt;,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_global_config: &cetus_config::GlobalConfig,
    creation_fee: Balance&lt;SUI&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): PositionCap {
    core::create_position!(
        config,
        ticket,
        cetus_pool,
        creation_fee,
        ctx,
        |pool, tick_a, tick_b, delta_l, balance_x0, balance_y0| {
            <b>let</b> <b>mut</b> lp_position = cetus_pool::open_position(
                cetus_global_config,
                pool,
                i32::as_u32(tick_a),
                i32::as_u32(tick_b),
                ctx,
            );
            <b>let</b> receipt = cetus_pool::add_liquidity(
                cetus_global_config,
                pool,
                &<b>mut</b> lp_position,
                delta_l,
                clock,
            );
            cetus_pool::repay_add_liquidity(
                cetus_global_config,
                pool,
                balance_x0,
                balance_y0,
                receipt,
            );
            lp_position
        },
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_create_deleverage_ticket"></a>

## Function `create_deleverage_ticket`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket">create_deleverage_ticket</a>&lt;X, Y&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_global_config: &cetus_clmm::config::GlobalConfig, _max_delta_l: u128, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, _ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket">create_deleverage_ticket</a>&lt;X, Y&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_global_config: &cetus_config::GlobalConfig,
    _max_delta_l: u128,
    _clock: &Clock,
    _ctx: &<b>mut</b> TxContext,
): (DeleverageTicket, ActionRequest) {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_create_deleverage_ticket_v2"></a>

## Function `create_deleverage_ticket_v2`

Like [create_deleverage_ticket], taking the rail-agnostic price collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket_v2">create_deleverage_ticket_v2</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_global_config: &cetus_clmm::config::GlobalConfig, max_delta_l: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket_v2">create_deleverage_ticket_v2</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    price_info: &PriceCollection,
    debt_info: &DebtInfo,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_global_config: &cetus_config::GlobalConfig,
    max_delta_l: u128,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): (DeleverageTicket, ActionRequest) {
    core::create_deleverage_ticket!(
        position,
        config,
        price_info,
        debt_info,
        cetus_pool,
        max_delta_l,
        ctx,
        |
            pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> CetusPosition,
            delta_l: u128,
        | <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_remove_liquidity">remove_liquidity</a>(cetus_global_config, pool, lp_position, delta_l, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_create_deleverage_ticket_for_liquidation"></a>

## Function `create_deleverage_ticket_for_liquidation`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket_for_liquidation">create_deleverage_ticket_for_liquidation</a>&lt;X, Y&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_global_config: &cetus_clmm::config::GlobalConfig, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket_for_liquidation">create_deleverage_ticket_for_liquidation</a>&lt;X, Y&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_global_config: &cetus_config::GlobalConfig,
    _clock: &Clock,
): DeleverageTicket {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_create_deleverage_ticket_for_liquidation_v2"></a>

## Function `create_deleverage_ticket_for_liquidation_v2`

Like [create_deleverage_ticket_for_liquidation], taking the rail-agnostic price collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket_for_liquidation_v2">create_deleverage_ticket_for_liquidation_v2</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_global_config: &cetus_clmm::config::GlobalConfig, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket_for_liquidation_v2">create_deleverage_ticket_for_liquidation_v2</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    price_info: &PriceCollection,
    debt_info: &DebtInfo,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_global_config: &cetus_config::GlobalConfig,
    clock: &Clock,
): DeleverageTicket {
    core::create_deleverage_ticket_for_liquidation!(
        position,
        config,
        price_info,
        debt_info,
        cetus_pool,
        |
            pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> CetusPosition,
            delta_l: u128,
        | <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_remove_liquidity">remove_liquidity</a>(cetus_global_config, pool, lp_position, delta_l, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_deleverage"></a>

## Function `deleverage`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_deleverage">deleverage</a>&lt;X, Y, SX, SY&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, _supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_global_config: &cetus_clmm::config::GlobalConfig, _max_delta_l: u128, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, _ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_deleverage">deleverage</a>&lt;X, Y, SX, SY&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _price_info: &PythPriceInfo,
    _supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    _supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_global_config: &cetus_config::GlobalConfig,
    _max_delta_l: u128,
    _clock: &Clock,
    _ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_deleverage_v2"></a>

## Function `deleverage_v2`

Like [deleverage], taking the rail-agnostic price collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_deleverage_v2">deleverage_v2</a>&lt;X, Y, SX, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_global_config: &cetus_clmm::config::GlobalConfig, max_delta_l: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_deleverage_v2">deleverage_v2</a>&lt;X, Y, SX, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    price_info: &PriceCollection,
    supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_global_config: &cetus_config::GlobalConfig,
    max_delta_l: u128,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> <b>mut</b> debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
    debt_info.add_from_supply_pool(supply_pool_x, clock);
    debt_info.add_from_supply_pool(supply_pool_y, clock);
    <b>let</b> (<b>mut</b> ticket, request) = <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket_v2">create_deleverage_ticket_v2</a>(
        position,
        config,
        price_info,
        &debt_info,
        cetus_pool,
        cetus_global_config,
        max_delta_l,
        clock,
        ctx,
    );
    core::deleverage_ticket_repay_x(position, config, &<b>mut</b> ticket, supply_pool_x, clock);
    core::deleverage_ticket_repay_y(position, config, &<b>mut</b> ticket, supply_pool_y, clock);
    core::destroy_deleverage_ticket(position, ticket);
    request
}
</code></pre>



</details>

<a name="kai_leverage_cetus_deleverage_for_liquidation"></a>

## Function `deleverage_for_liquidation`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_deleverage_for_liquidation">deleverage_for_liquidation</a>&lt;X, Y, SX, SY&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, _supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_global_config: &cetus_clmm::config::GlobalConfig, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_deleverage_for_liquidation">deleverage_for_liquidation</a>&lt;X, Y, SX, SY&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _price_info: &PythPriceInfo,
    _supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    _supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_global_config: &cetus_config::GlobalConfig,
    _clock: &Clock,
) {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_deleverage_for_liquidation_v2"></a>

## Function `deleverage_for_liquidation_v2`

Like [deleverage_for_liquidation], taking the rail-agnostic price collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_deleverage_for_liquidation_v2">deleverage_for_liquidation_v2</a>&lt;X, Y, SX, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_global_config: &cetus_clmm::config::GlobalConfig, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_deleverage_for_liquidation_v2">deleverage_for_liquidation_v2</a>&lt;X, Y, SX, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    price_info: &PriceCollection,
    supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_global_config: &cetus_config::GlobalConfig,
    clock: &Clock,
) {
    <b>let</b> <b>mut</b> debt_info = debt_info::empty(object::id(config.lend_facil_cap()));
    debt_info.add_from_supply_pool(supply_pool_x, clock);
    debt_info.add_from_supply_pool(supply_pool_y, clock);
    <b>let</b> <b>mut</b> ticket = <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_create_deleverage_ticket_for_liquidation_v2">create_deleverage_ticket_for_liquidation_v2</a>(
        position,
        config,
        price_info,
        &debt_info,
        cetus_pool,
        cetus_global_config,
        clock,
    );
    core::deleverage_ticket_repay_x(position, config, &<b>mut</b> ticket, supply_pool_x, clock);
    core::deleverage_ticket_repay_y(position, config, &<b>mut</b> ticket, supply_pool_y, clock);
    core::destroy_deleverage_ticket(position, ticket);
}
</code></pre>



</details>

<a name="kai_leverage_cetus_liquidate_col_x"></a>

## Function `liquidate_col_x`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_liquidate_col_x">liquidate_col_x</a>&lt;X, Y, SY&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, _supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_liquidate_col_x">liquidate_col_x</a>&lt;X, Y, SY&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &PositionConfig,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _repayment: &<b>mut</b> Balance&lt;Y&gt;,
    _supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    _clock: &Clock,
): Balance&lt;X&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_liquidate_col_x_v2"></a>

## Function `liquidate_col_x_v2`

Liquidate X collateral by repaying Y debt. The position needs to be fully deleveraged and
below the liquidation margin threshold.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_liquidate_col_x_v2">liquidate_col_x_v2</a>&lt;X, Y, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_liquidate_col_x_v2">liquidate_col_x_v2</a>&lt;X, Y, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    price_info: &PriceCollection,
    debt_info: &DebtInfo,
    repayment: &<b>mut</b> Balance&lt;Y&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
): Balance&lt;X&gt; {
    <b>let</b> shape = core::lp_shape!(position);
    core::liquidate_col_x(
        position,
        config,
        price_info,
        debt_info,
        repayment,
        supply_pool,
        shape,
        clock,
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_liquidate_col_y"></a>

## Function `liquidate_col_y`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_liquidate_col_y">liquidate_col_y</a>&lt;X, Y, SX&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, _supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_liquidate_col_y">liquidate_col_y</a>&lt;X, Y, SX&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &PositionConfig,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _repayment: &<b>mut</b> Balance&lt;X&gt;,
    _supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    _clock: &Clock,
): Balance&lt;Y&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_liquidate_col_y_v2"></a>

## Function `liquidate_col_y_v2`

Liquidate Y collateral by repaying X debt. The position needs to be fully deleveraged and
below the liquidation margin threshold.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_liquidate_col_y_v2">liquidate_col_y_v2</a>&lt;X, Y, SX&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_liquidate_col_y_v2">liquidate_col_y_v2</a>&lt;X, Y, SX&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    price_info: &PriceCollection,
    debt_info: &DebtInfo,
    repayment: &<b>mut</b> Balance&lt;X&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
): Balance&lt;Y&gt; {
    <b>let</b> shape = core::lp_shape!(position);
    core::liquidate_col_y(
        position,
        config,
        price_info,
        debt_info,
        repayment,
        supply_pool,
        shape,
        clock,
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_repay_bad_debt_x"></a>

## Function `repay_bad_debt_x`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_bad_debt_x">repay_bad_debt_x</a>&lt;X, Y, SX&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, _repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, _ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_bad_debt_x">repay_bad_debt_x</a>&lt;X, Y, SX&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &PositionConfig,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    _repayment: &<b>mut</b> Balance&lt;X&gt;,
    _clock: &Clock,
    _ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_repay_bad_debt_x_v2"></a>

## Function `repay_bad_debt_x_v2`

Repay bad debt for X tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_bad_debt_x_v2">repay_bad_debt_x_v2</a>&lt;X, Y, SX&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_bad_debt_x_v2">repay_bad_debt_x_v2</a>&lt;X, Y, SX&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    _price_info: &PriceCollection,
    _debt_info: &DebtInfo,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    repayment: &<b>mut</b> Balance&lt;X&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> shape = core::lp_shape!(position);
    core::repay_bad_debt(
        position,
        config,
        supply_pool,
        repayment,
        shape,
        clock,
        ctx,
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_repay_bad_debt_y"></a>

## Function `repay_bad_debt_y`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_bad_debt_y">repay_bad_debt_y</a>&lt;X, Y, SY&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, _repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, _ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_bad_debt_y">repay_bad_debt_y</a>&lt;X, Y, SY&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &PositionConfig,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    _repayment: &<b>mut</b> Balance&lt;Y&gt;,
    _clock: &Clock,
    _ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_repay_bad_debt_y_v2"></a>

## Function `repay_bad_debt_y_v2`

Repay bad debt for Y tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_bad_debt_y_v2">repay_bad_debt_y_v2</a>&lt;X, Y, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_bad_debt_y_v2">repay_bad_debt_y_v2</a>&lt;X, Y, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    _price_info: &PriceCollection,
    _debt_info: &DebtInfo,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    repayment: &<b>mut</b> Balance&lt;Y&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> shape = core::lp_shape!(position);
    core::repay_bad_debt(
        position,
        config,
        supply_pool,
        repayment,
        shape,
        clock,
        ctx,
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_reduce"></a>

## Function `reduce`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_reduce">reduce</a>&lt;X, Y, SX, SY&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, _supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_global_config: &cetus_clmm::config::GlobalConfig, _factor_x64: u128, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_reduce">reduce</a>&lt;X, Y, SX, SY&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _cap: &PositionCap,
    _price_info: &PythPriceInfo,
    _supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    _supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_global_config: &cetus_config::GlobalConfig,
    _factor_x64: u128,
    _clock: &Clock,
): (Balance&lt;X&gt;, Balance&lt;Y&gt;, ReductionRepaymentTicket&lt;SX, SY&gt;) {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_reduce_v2"></a>

## Function `reduce_v2`

Initialize position size reduction (withdraw), while preserving mathematical safety guarantees.
A factor_x64 percentage of the position is withdrawn and the same percentage of debt is repaid.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_reduce_v2">reduce_v2</a>&lt;X, Y, SX, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_global_config: &cetus_clmm::config::GlobalConfig, factor_x64: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_reduce_v2">reduce_v2</a>&lt;X, Y, SX, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    cap: &PositionCap,
    price_info: &PriceCollection,
    supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_global_config: &cetus_config::GlobalConfig,
    factor_x64: u128,
    clock: &Clock,
): (Balance&lt;X&gt;, Balance&lt;Y&gt;, ReductionRepaymentTicket&lt;SX, SY&gt;) {
    core::reduce!(
        position,
        config,
        cap,
        price_info,
        supply_pool_x,
        supply_pool_y,
        cetus_pool,
        factor_x64,
        clock,
        |
            pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> CetusPosition,
            delta_l: u128,
        | <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_remove_liquidity">remove_liquidity</a>(cetus_global_config, pool, lp_position, delta_l, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_add_liquidity"></a>

## Function `add_liquidity`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_add_liquidity">add_liquidity</a>&lt;X, Y&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_config: &cetus_clmm::config::GlobalConfig, _delta_l: u128, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): cetus_clmm::pool::AddLiquidityReceipt&lt;X, Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_add_liquidity">add_liquidity</a>&lt;X, Y&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _cap: &PositionCap,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_config: &cetus_config::GlobalConfig,
    _delta_l: u128,
    _clock: &Clock,
): cetus_pool::AddLiquidityReceipt&lt;X, Y&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_add_liquidity_v2"></a>

## Function `add_liquidity_v2`

Add liquidity to the inner LP position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_add_liquidity_v2">add_liquidity_v2</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_config: &cetus_clmm::config::GlobalConfig, delta_l: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): cetus_clmm::pool::AddLiquidityReceipt&lt;X, Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_add_liquidity_v2">add_liquidity_v2</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    cap: &PositionCap,
    price_info: &PriceCollection,
    debt_info: &DebtInfo,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_config: &cetus_config::GlobalConfig,
    delta_l: u128,
    clock: &Clock,
): cetus_pool::AddLiquidityReceipt&lt;X, Y&gt; {
    core::add_liquidity_with_receipt!(
        position,
        config,
        cap,
        price_info,
        debt_info,
        cetus_pool,
        |pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;, lp_position: &<b>mut</b> CetusPosition| {
            <b>let</b> receipt = cetus_pool::add_liquidity(
                cetus_config,
                pool,
                lp_position,
                delta_l,
                clock,
            );
            <b>let</b> (delta_x, delta_y) = receipt.add_liquidity_pay_amount();
            (delta_l, delta_x, delta_y, receipt)
        },
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_add_liquidity_fix_coin"></a>

## Function `add_liquidity_fix_coin`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_add_liquidity_fix_coin">add_liquidity_fix_coin</a>&lt;X, Y&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_config: &cetus_clmm::config::GlobalConfig, _amount: u64, _fix_amount_x: bool, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): cetus_clmm::pool::AddLiquidityReceipt&lt;X, Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_add_liquidity_fix_coin">add_liquidity_fix_coin</a>&lt;X, Y&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _cap: &PositionCap,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_config: &cetus_config::GlobalConfig,
    _amount: u64,
    _fix_amount_x: bool,
    _clock: &Clock,
): cetus_pool::AddLiquidityReceipt&lt;X, Y&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_repay_debt_x"></a>

## Function `repay_debt_x`

Repay as much X token debt as possible using the available balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_debt_x">repay_debt_x</a>&lt;X, Y, SX&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_debt_x">repay_debt_x</a>&lt;X, Y, SX&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    cap: &PositionCap,
    balance: &<b>mut</b> Balance&lt;X&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
) {
    core::repay_debt_x(position, cap, balance, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_cetus_repay_debt_y"></a>

## Function `repay_debt_y`

Repay as much Y token debt as possible using the available balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_debt_y">repay_debt_y</a>&lt;X, Y, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_repay_debt_y">repay_debt_y</a>&lt;X, Y, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    cap: &PositionCap,
    balance: &<b>mut</b> Balance&lt;Y&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
) {
    core::repay_debt_y(position, cap, balance, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_cetus_owner_collect_fee"></a>

## Function `owner_collect_fee`

Collect accumulated AMM fees for position owner directly.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_owner_collect_fee">owner_collect_fee</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_config: &cetus_clmm::config::GlobalConfig): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_owner_collect_fee">owner_collect_fee</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    cap: &PositionCap,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_config: &cetus_config::GlobalConfig,
): (Balance&lt;X&gt;, Balance&lt;Y&gt;) {
    core::owner_collect_fee!(
        position,
        config,
        cap,
        cetus_pool,
        |
            pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> CetusPosition,
        | cetus_pool::collect_fee(cetus_config, pool, lp_position, <b>true</b>),
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_owner_collect_reward"></a>

## Function `owner_collect_reward`

Collect accumulated AMM rewards for position owner directly.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_owner_collect_reward">owner_collect_reward</a>&lt;X, Y, T&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_config: &cetus_clmm::config::GlobalConfig, cetus_vault: &<b>mut</b> cetus_clmm::rewarder::RewarderGlobalVault, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_owner_collect_reward">owner_collect_reward</a>&lt;X, Y, T&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    cap: &PositionCap,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_config: &cetus_config::GlobalConfig,
    cetus_vault: &<b>mut</b> RewarderGlobalVault,
    clock: &Clock,
): Balance&lt;T&gt; {
    core::owner_collect_reward!(
        position,
        config,
        cap,
        cetus_pool,
        |
            pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> CetusPosition,
        | cetus_pool::collect_reward(cetus_config, pool, lp_position, cetus_vault, <b>true</b>, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_owner_take_stashed_rewards"></a>

## Function `owner_take_stashed_rewards`

Withdraw stashed rewards from position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_owner_take_stashed_rewards">owner_take_stashed_rewards</a>&lt;X, Y, T&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, amount: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_owner_take_stashed_rewards">owner_take_stashed_rewards</a>&lt;X, Y, T&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    cap: &PositionCap,
    amount: Option&lt;u64&gt;,
): Balance&lt;T&gt; {
    core::owner_take_stashed_rewards(position, cap, amount)
}
</code></pre>



</details>

<a name="kai_leverage_cetus_delete_position"></a>

## Function `delete_position`

Delete position. The position needs to be fully reduced and all assets withdrawn first.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_delete_position">delete_position</a>&lt;X, Y&gt;(position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_config: &cetus_clmm::config::GlobalConfig, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_delete_position">delete_position</a>&lt;X, Y&gt;(
    position: Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    cap: PositionCap,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_config: &cetus_config::GlobalConfig,
    ctx: &<b>mut</b> TxContext,
) {
    core::delete_position!(
        position,
        config,
        cap,
        |lp_position| cetus_pool::close_position(cetus_config, cetus_pool, lp_position),
        ctx,
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_rebalance_collect_fee"></a>

## Function `rebalance_collect_fee`

Collects AMM trading fees for a leveraged CLMM position during rebalancing,
applies protocol fee, and updates the <code>RebalanceReceipt</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_collect_fee">rebalance_collect_fee</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_config: &cetus_clmm::config::GlobalConfig): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_collect_fee">rebalance_collect_fee</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    receipt: &<b>mut</b> RebalanceReceipt,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_config: &cetus_config::GlobalConfig,
): (Balance&lt;X&gt;, Balance&lt;Y&gt;) {
    core::rebalance_collect_fee!(
        position,
        config,
        receipt,
        cetus_pool,
        |
            pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> CetusPosition,
        | cetus_pool::collect_fee(cetus_config, pool, lp_position, <b>true</b>),
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_rebalance_collect_reward"></a>

## Function `rebalance_collect_reward`

Collects AMM rewards for a leveraged CLMM position during rebalancing,
applies protocol fee, and updates the <code>RebalanceReceipt</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_collect_reward">rebalance_collect_reward</a>&lt;X, Y, T&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_config: &cetus_clmm::config::GlobalConfig, cetus_vault: &<b>mut</b> cetus_clmm::rewarder::RewarderGlobalVault, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_collect_reward">rebalance_collect_reward</a>&lt;X, Y, T&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    receipt: &<b>mut</b> RebalanceReceipt,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_config: &cetus_config::GlobalConfig,
    cetus_vault: &<b>mut</b> RewarderGlobalVault,
    clock: &Clock,
): Balance&lt;T&gt; {
    core::rebalance_collect_reward!(
        position,
        config,
        receipt,
        cetus_pool,
        |
            pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> CetusPosition,
        | cetus_pool::collect_reward(cetus_config, pool, lp_position, cetus_vault, <b>true</b>, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_rebalance_add_liquidity"></a>

## Function `rebalance_add_liquidity`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_add_liquidity">rebalance_add_liquidity</a>&lt;X, Y&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_config: &cetus_clmm::config::GlobalConfig, _delta_l: u128, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): cetus_clmm::pool::AddLiquidityReceipt&lt;X, Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_add_liquidity">rebalance_add_liquidity</a>&lt;X, Y&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _receipt: &<b>mut</b> RebalanceReceipt,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_config: &cetus_config::GlobalConfig,
    _delta_l: u128,
    _clock: &Clock,
): cetus_pool::AddLiquidityReceipt&lt;X, Y&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_rebalance_add_liquidity_v2"></a>

## Function `rebalance_add_liquidity_v2`

Adds liquidity to a the underlying LP position during rebalancing.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_add_liquidity_v2">rebalance_add_liquidity_v2</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, cetus_config: &cetus_clmm::config::GlobalConfig, delta_l: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): cetus_clmm::pool::AddLiquidityReceipt&lt;X, Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_add_liquidity_v2">rebalance_add_liquidity_v2</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    receipt: &<b>mut</b> RebalanceReceipt,
    price_info: &PriceCollection,
    debt_info: &DebtInfo,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    cetus_config: &cetus_config::GlobalConfig,
    delta_l: u128,
    clock: &Clock,
): cetus_pool::AddLiquidityReceipt&lt;X, Y&gt; {
    core::rebalance_add_liquidity_with_receipt!(
        position,
        config,
        receipt,
        price_info,
        debt_info,
        cetus_pool,
        |pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;, lp_position: &<b>mut</b> CetusPosition| {
            <b>let</b> receipt = cetus_pool::add_liquidity(
                cetus_config,
                pool,
                lp_position,
                delta_l,
                clock,
            );
            <b>let</b> (delta_x, delta_y) = receipt.add_liquidity_pay_amount();
            (delta_l, delta_x, delta_y, receipt)
        },
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_rebalance_add_liquidity_by_fix_coin"></a>

## Function `rebalance_add_liquidity_by_fix_coin`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_add_liquidity_by_fix_coin">rebalance_add_liquidity_by_fix_coin</a>&lt;X, Y&gt;(_position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, _cetus_config: &cetus_clmm::config::GlobalConfig, _amount: u64, _fix_amount_x: bool, _clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): cetus_clmm::pool::AddLiquidityReceipt&lt;X, Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_rebalance_add_liquidity_by_fix_coin">rebalance_add_liquidity_by_fix_coin</a>&lt;X, Y&gt;(
    _position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    _config: &<b>mut</b> PositionConfig,
    _receipt: &<b>mut</b> RebalanceReceipt,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    _cetus_config: &cetus_config::GlobalConfig,
    _amount: u64,
    _fix_amount_x: bool,
    _clock: &Clock,
): cetus_pool::AddLiquidityReceipt&lt;X, Y&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_sync_exploited_position_liquidity_by_small_withdraw"></a>

## Function `sync_exploited_position_liquidity_by_small_withdraw`

Sync exploited position liquidity by performing a small withdrawal to update
the position's liquidity state after a Cetus incident.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_sync_exploited_position_liquidity_by_small_withdraw">sync_exploited_position_liquidity_by_small_withdraw</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cetus_config: &cetus_clmm::config::GlobalConfig, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, balance_bag: &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_sync_exploited_position_liquidity_by_small_withdraw">sync_exploited_position_liquidity_by_small_withdraw</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, CetusPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    cetus_config: &cetus_config::GlobalConfig,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    balance_bag: &<b>mut</b> BalanceBag,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    core::check_versions(position, config);
    <b>assert</b>!(position.config_id() == object::id(config)); // EInvalidConfig
    <b>assert</b>!(config.pool_object_id() == object::id(cetus_pool)); // EInvalidPool
    <b>assert</b>!(position.ticket_active() == <b>false</b>); // ETicketActive
    <b>let</b> position_id = object::id(position.lp_position());
    <b>assert</b>!(cetus_pool.is_attacked_position(position_id)); // EPositionNotExploited
    <b>let</b> position_info = cetus_pool.borrow_position_info(position_id);
    <b>let</b> info_liquidity = position_info.info_liquidity();
    <b>assert</b>!(info_liquidity != position.lp_position().liquidity()); // EPositionAlreadySynced
    <b>let</b> delta_l = 1;
    <b>let</b> initial_liquidity = position.lp_position().liquidity();
    <b>let</b> (delta_x, delta_y) = <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_remove_liquidity">remove_liquidity</a>(
        cetus_config,
        cetus_pool,
        position.lp_position_mut(),
        delta_l,
        clock,
    );
    config.decrease_current_global_l(initial_liquidity - position.lp_position().liquidity());
    balance_bag.add(delta_x);
    balance_bag.add(delta_y);
    access::new_request(<a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_AHandleExploitedPosition">AHandleExploitedPosition</a>(), ctx)
}
</code></pre>



</details>

<a name="kai_leverage_cetus_destruct_exploited_position_and_return_lp"></a>

## Function `destruct_exploited_position_and_return_lp`

Destruct an exploited position and return the underlying LP position for recovery.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_destruct_exploited_position_and_return_lp">destruct_exploited_position_and_return_lp</a>&lt;X, Y&gt;(position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, cetus_pool: &<b>mut</b> cetus_clmm::pool::Pool&lt;X, Y&gt;, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): cetus_clmm::position::Position
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_destruct_exploited_position_and_return_lp">destruct_exploited_position_and_return_lp</a>&lt;X, Y&gt;(
    position: Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    cap: PositionCap,
    cetus_pool: &<b>mut</b> cetus_pool::Pool&lt;X, Y&gt;,
    ctx: &<b>mut</b> TxContext,
): CetusPosition {
    core::check_versions(&position, config);
    <b>assert</b>!(position.config_id() == object::id(config)); // EInvalidConfig
    <b>assert</b>!(cap.position_id() == object::id(&position)); // EInvalidPositionCap
    <b>assert</b>!(position.ticket_active() == <b>false</b>); // ETicketActive
    <b>assert</b>!(!config.delete_position_disabled()); // EDeletePositionDisabled
    <b>let</b> position_id = object::id(position.lp_position());
    <b>assert</b>!(cetus_pool.is_attacked_position(position_id)); // EPositionNotExploited
    // delete position
    <b>let</b> (
        id,
        _config_id,
        lp_position,
        col_x,
        col_y,
        debt_bag,
        collected_fees,
        owner_reward_stash,
        _ticket_active,
        _version,
    ) = core::position_deconstructor(position);
    id.delete();
    col_x.destroy_zero();
    col_y.destroy_zero();
    debt_bag.destroy_empty();
    owner_reward_stash.destroy_empty();
    // delete cap
    <b>let</b> (id, position_id) = core::position_cap_deconstructor(cap);
    <b>let</b> cap_id = id.to_inner();
    id.delete();
    <b>if</b> (collected_fees.is_empty()) {
        collected_fees.destroy_empty()
    } <b>else</b> {
        core::share_deleted_position_collected_fees(
            position_id,
            collected_fees,
            ctx,
        );
    };
    core::emit_delete_position_info(position_id, cap_id);
    lp_position
}
</code></pre>



</details>

<a name="kai_leverage_cetus_position_model"></a>

## Function `position_model`

Create validated position model for analysis and calculations.
Used to obtain position models for risk assessment,
liquidation calculations, and other analytical operations.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_position_model">position_model</a>&lt;X, Y&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>): <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_position_model">position_model</a>&lt;X, Y&gt;(
    position: &Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    debt_info: &DebtInfo,
): PositionModel {
    core::validated_model_for_position!(position, config, debt_info)
}
</code></pre>



</details>

<a name="kai_leverage_cetus_calc_liquidate_col_x"></a>

## Function `calc_liquidate_col_x`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_liquidate_col_x">calc_liquidate_col_x</a>&lt;X, Y&gt;(_position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _max_repayment_amt_y: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_liquidate_col_x">calc_liquidate_col_x</a>&lt;X, Y&gt;(
    _position: &Position&lt;X, Y, CetusPosition&gt;,
    _config: &PositionConfig,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _max_repayment_amt_y: u64,
): (u64, u64) {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_calc_liquidate_col_x_v2"></a>

## Function `calc_liquidate_col_x_v2`

Calculate the required amounts to liquidate X collateral by repaying Y debt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_liquidate_col_x_v2">calc_liquidate_col_x_v2</a>&lt;X, Y&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, max_repayment_amt_y: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_liquidate_col_x_v2">calc_liquidate_col_x_v2</a>&lt;X, Y&gt;(
    position: &Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    price_info: &PriceCollection,
    debt_info: &DebtInfo,
    max_repayment_amt_y: u64,
): (u64, u64) {
    <b>let</b> shape = core::lp_shape!(position);
    core::calc_liquidate_col_x(
        position,
        config,
        price_info,
        debt_info,
        max_repayment_amt_y,
        shape,
    )
}
</code></pre>



</details>

<a name="kai_leverage_cetus_calc_liquidate_col_y"></a>

## Function `calc_liquidate_col_y`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_liquidate_col_y">calc_liquidate_col_y</a>&lt;X, Y&gt;(_position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, _config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, _max_repayment_amt_x: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_liquidate_col_y">calc_liquidate_col_y</a>&lt;X, Y&gt;(
    _position: &Position&lt;X, Y, CetusPosition&gt;,
    _config: &PositionConfig,
    _price_info: &PythPriceInfo,
    _debt_info: &DebtInfo,
    _max_repayment_amt_x: u64,
): (u64, u64) {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_cetus_calc_liquidate_col_y_v2"></a>

## Function `calc_liquidate_col_y_v2`

Calculate the required amounts to liquidate Y collateral by repaying X debt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_liquidate_col_y_v2">calc_liquidate_col_y_v2</a>&lt;X, Y&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, cetus_clmm::position::Position&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, max_repayment_amt_x: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/cetus.md#kai_leverage_cetus_calc_liquidate_col_y_v2">calc_liquidate_col_y_v2</a>&lt;X, Y&gt;(
    position: &Position&lt;X, Y, CetusPosition&gt;,
    config: &PositionConfig,
    price_info: &PriceCollection,
    debt_info: &DebtInfo,
    max_repayment_amt_x: u64,
): (u64, u64) {
    <b>let</b> shape = core::lp_shape!(position);
    core::calc_liquidate_col_y(
        position,
        config,
        price_info,
        debt_info,
        max_repayment_amt_x,
        shape,
    )
}
</code></pre>



</details>


<a name="kai_leverage_bluefin_spot"></a>

# Module `kai_leverage::bluefin_spot`

Bluefin Spot DEX integration for leveraged concentrated liquidity positions.

This module provides an adapter layer for integrating Kai Leverage with the
Bluefin Spot concentrated liquidity AMM. It translates between the generic
position management interface and Bluefin-specific pool operations, handling
liquidity provision, fee collection, and reward distribution.


-  [Function `slippage_tolerance_assertion`](#kai_leverage_bluefin_spot_slippage_tolerance_assertion)
-  [Function `calc_deposit_amounts_by_liquidity`](#kai_leverage_bluefin_spot_calc_deposit_amounts_by_liquidity)
-  [Function `position_tick_range`](#kai_leverage_bluefin_spot_position_tick_range)
-  [Function `remove_liquidity`](#kai_leverage_bluefin_spot_remove_liquidity)
-  [Function `create_position_ticket`](#kai_leverage_bluefin_spot_create_position_ticket)
-  [Function `create_position_ticket_v2`](#kai_leverage_bluefin_spot_create_position_ticket_v2)
-  [Function `borrow_for_position_x`](#kai_leverage_bluefin_spot_borrow_for_position_x)
-  [Function `borrow_for_position_y`](#kai_leverage_bluefin_spot_borrow_for_position_y)
-  [Function `create_position`](#kai_leverage_bluefin_spot_create_position)
-  [Function `create_deleverage_ticket`](#kai_leverage_bluefin_spot_create_deleverage_ticket)
-  [Function `create_deleverage_ticket_for_liquidation`](#kai_leverage_bluefin_spot_create_deleverage_ticket_for_liquidation)
-  [Function `deleverage`](#kai_leverage_bluefin_spot_deleverage)
-  [Function `deleverage_for_liquidation`](#kai_leverage_bluefin_spot_deleverage_for_liquidation)
-  [Function `liquidate_col_x`](#kai_leverage_bluefin_spot_liquidate_col_x)
-  [Function `liquidate_col_y`](#kai_leverage_bluefin_spot_liquidate_col_y)
-  [Function `repay_bad_debt_x`](#kai_leverage_bluefin_spot_repay_bad_debt_x)
-  [Function `repay_bad_debt_y`](#kai_leverage_bluefin_spot_repay_bad_debt_y)
-  [Function `reduce`](#kai_leverage_bluefin_spot_reduce)
-  [Function `add_liquidity`](#kai_leverage_bluefin_spot_add_liquidity)
-  [Function `repay_debt_x`](#kai_leverage_bluefin_spot_repay_debt_x)
-  [Function `repay_debt_y`](#kai_leverage_bluefin_spot_repay_debt_y)
-  [Function `owner_collect_fee`](#kai_leverage_bluefin_spot_owner_collect_fee)
-  [Function `owner_collect_reward`](#kai_leverage_bluefin_spot_owner_collect_reward)
-  [Function `owner_take_stashed_rewards`](#kai_leverage_bluefin_spot_owner_take_stashed_rewards)
-  [Function `delete_position`](#kai_leverage_bluefin_spot_delete_position)
-  [Function `rebalance_collect_fee`](#kai_leverage_bluefin_spot_rebalance_collect_fee)
-  [Function `rebalance_collect_reward`](#kai_leverage_bluefin_spot_rebalance_collect_reward)
-  [Function `rebalance_add_liquidity`](#kai_leverage_bluefin_spot_rebalance_add_liquidity)
-  [Function `position_model`](#kai_leverage_bluefin_spot_position_model)
-  [Function `calc_liquidate_col_x`](#kai_leverage_bluefin_spot_calc_liquidate_col_x)
-  [Function `calc_liquidate_col_y`](#kai_leverage_bluefin_spot_calc_liquidate_col_y)


<pre><code><b>use</b> (cetusclmm=0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB)::tick_math;
<b>use</b> <a href="../../dependencies/wal/wal.md#0x356A26EB9E012A68958082340D4C4116E7F55615CF27AFFCFF209CF0AE544F59_wal">0x356A26EB9E012A68958082340D4C4116E7F55615CF27AFFCFF209CF0AE544F59::wal</a>;
<b>use</b> <a href="../../dependencies/suiusdt/usdt.md#0x375F70CF2AE4C00BF37117D0C85A2C71545E6EE05C4A5C7D282CD66A4504B068_usdt">0x375F70CF2AE4C00BF37117D0C85A2C71545E6EE05C4A5C7D282CD66A4504B068::usdt</a>;
<b>use</b> <a href="../../dependencies/lbtc/lbtc.md#0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040_lbtc">0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040::lbtc</a>;
<b>use</b> <a href="../../dependencies/whusdce/coin.md#0x5D4B302506645C37FF133B98C4B50A5AE14841659738D6D733D59D0D217A93BF_coin">0x5D4B302506645C37FF133B98C4B50A5AE14841659738D6D733D59D0D217A93BF::coin</a>;
<b>use</b> <a href="../../dependencies/xbtc/xbtc.md#0x876A4B7BCE8AEAEF60464C11F4026903E9AFACAB79B9B142686158AA86560B50_xbtc">0x876A4B7BCE8AEAEF60464C11F4026903E9AFACAB79B9B142686158AA86560B50::xbtc</a>;
<b>use</b> <a href="../../dependencies/usdy/usdy.md#0x960B531667636F39E85867775F52F6B1F220A058C4DE786905BDF761E06A56BB_usdy">0x960B531667636F39E85867775F52F6B1F220A058C4DE786905BDF761E06A56BB::usdy</a>;
<b>use</b> <a href="../../dependencies/wbtc/btc.md#0xAAFB102DD0902F5055CADECD687FB5B71CA82EF0E0285D90AFDE828EC58CA96B_btc">0xAAFB102DD0902F5055CADECD687FB5B71CA82EF0E0285D90AFDE828EC58CA96B::btc</a>;
<b>use</b> <a href="../../dependencies/whusdte/coin.md#0xC060006111016B8A020AD5B33834984A437AAA7D3C74C18E09A95D48ACEAB08C_coin">0xC060006111016B8A020AD5B33834984A437AAA7D3C74C18E09A95D48ACEAB08C::coin</a>;
<b>use</b> <a href="../../dependencies/deep/deep.md#0xDEEB7A4662EEC9F2F3DEF03FB937A663DDDAA2E215B8078A284D026B7946C270_deep">0xDEEB7A4662EEC9F2F3DEF03FB937A663DDDAA2E215B8078A284D026B7946C270::deep</a>;
<b>use</b> <a href="../../dependencies/access_management/access.md#access_management_access">access_management::access</a>;
<b>use</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map">access_management::dynamic_map</a>;
<b>use</b> <a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config">bluefin_spot::config</a>;
<b>use</b> <a href="../../dependencies/bluefin_spot/oracle.md#bluefin_spot_oracle">bluefin_spot::oracle</a>;
<b>use</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool">bluefin_spot::pool</a>;
<b>use</b> <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position">bluefin_spot::position</a>;
<b>use</b> <a href="../../dependencies/bluefin_spot/tick.md#bluefin_spot_tick">bluefin_spot::tick</a>;
<b>use</b> <a href="../../dependencies/integer_mate/full_math_u128.md#integer_mate_full_math_u128">integer_mate::full_math_u128</a>;
<b>use</b> <a href="../../dependencies/integer_mate/i128.md#integer_mate_i128">integer_mate::i128</a>;
<b>use</b> <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32">integer_mate::i32</a>;
<b>use</b> <a href="../../dependencies/integer_mate/i64.md#integer_mate_i64">integer_mate::i64</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag">kai_leverage::balance_bag</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt">kai_leverage::debt</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag">kai_leverage::debt_bag</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info">kai_leverage::debt_info</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity">kai_leverage::equity</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise">kai_leverage::piecewise</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm">kai_leverage::position_core_clmm</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm">kai_leverage::position_model_clmm</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth">kai_leverage::pyth</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool">kai_leverage::supply_pool</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util">kai_leverage::util</a>;
<b>use</b> <a href="../../dependencies/pyth/i64.md#pyth_i64">pyth::i64</a>;
<b>use</b> <a href="../../dependencies/pyth/price.md#pyth_price">pyth::price</a>;
<b>use</b> <a href="../../dependencies/pyth/price_feed.md#pyth_price_feed">pyth::price_feed</a>;
<b>use</b> <a href="../../dependencies/pyth/price_identifier.md#pyth_price_identifier">pyth::price_identifier</a>;
<b>use</b> <a href="../../dependencies/pyth/price_info.md#pyth_price_info">pyth::price_info</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter">rate_limiter::net_sliding_sum_limiter</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator">rate_limiter::ring_aggregator</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter">rate_limiter::sliding_sum_limiter</a>;
<b>use</b> <a href="../../dependencies/stablecoin/mint_allowance.md#stablecoin_mint_allowance">stablecoin::mint_allowance</a>;
<b>use</b> <a href="../../dependencies/stablecoin/roles.md#stablecoin_roles">stablecoin::roles</a>;
<b>use</b> <a href="../../dependencies/stablecoin/treasury.md#stablecoin_treasury">stablecoin::treasury</a>;
<b>use</b> <a href="../../dependencies/stablecoin/version_control.md#stablecoin_version_control">stablecoin::version_control</a>;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/u128.md#std_u128">std::u128</a>;
<b>use</b> <a href="../../dependencies/std/u64.md#std_u64">std::u64</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/package.md#sui_package">sui::package</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
<b>use</b> <a href="../../dependencies/sui_extensions/two_step_role.md#sui_extensions_two_step_role">sui_extensions::two_step_role</a>;
<b>use</b> <a href="../../dependencies/sui_extensions/upgrade_service.md#sui_extensions_upgrade_service">sui_extensions::upgrade_service</a>;
<b>use</b> <a href="../../dependencies/usdc/usdc.md#usdc_usdc">usdc::usdc</a>;
</code></pre>



<a name="kai_leverage_bluefin_spot_slippage_tolerance_assertion"></a>

## Function `slippage_tolerance_assertion`

Assert that current pool price is within slippage tolerance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_slippage_tolerance_assertion">slippage_tolerance_assertion</a>&lt;X, Y&gt;(pool: &<a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, p0_desired_x128: u256, max_slippage_bps: u16)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_slippage_tolerance_assertion">slippage_tolerance_assertion</a>&lt;X, Y&gt;(
    pool: &bluefin_pool::Pool&lt;X, Y&gt;,
    p0_desired_x128: u256,
    max_slippage_bps: u16,
) {
    core::slippage_tolerance_assertion!(pool, p0_desired_x128, max_slippage_bps);
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_calc_deposit_amounts_by_liquidity"></a>

## Function `calc_deposit_amounts_by_liquidity`

Calculate token amounts needed for to deposit given liquidity.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_calc_deposit_amounts_by_liquidity">calc_deposit_amounts_by_liquidity</a>&lt;X, Y&gt;(pool: &<a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, tick_a: <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>, tick_b: <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>, delta_l: u128): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_calc_deposit_amounts_by_liquidity">calc_deposit_amounts_by_liquidity</a>&lt;X, Y&gt;(
    pool: &bluefin_pool::Pool&lt;X, Y&gt;,
    tick_a: I32,
    tick_b: I32,
    delta_l: u128,
): (u64, u64) {
    <b>let</b> current_tick = pool.current_tick_index();
    <b>let</b> sqrt_p0_x64 = pool.current_sqrt_price();
    bluefin_pool::get_amount_by_liquidity(
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

<a name="kai_leverage_bluefin_spot_position_tick_range"></a>

## Function `position_tick_range`

Get the tick range of a Bluefin position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_position_tick_range">position_tick_range</a>(position: &<a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>): (<a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>, <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_position_tick_range">position_tick_range</a>(position: &BluefinPosition): (I32, I32) {
    (position.lower_tick(), position.upper_tick())
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_remove_liquidity"></a>

## Function `remove_liquidity`

Remove liquidity from a Bluefin position and return token balances.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_remove_liquidity">remove_liquidity</a>&lt;X, Y&gt;(config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, lp_position: &<b>mut</b> <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>, delta_l: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_remove_liquidity">remove_liquidity</a>&lt;X, Y&gt;(
    config: &bluefin_config::GlobalConfig,
    pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    lp_position: &<b>mut</b> BluefinPosition,
    delta_l: u128,
    clock: &Clock,
): (Balance&lt;X&gt;, Balance&lt;Y&gt;) {
    <b>if</b> (delta_l &gt; 0) {
        <b>let</b> (_, _, delta_x, delta_y) = bluefin_pool::remove_liquidity(
            config,
            pool,
            lp_position,
            delta_l,
            clock,
        );
        (delta_x, delta_y)
    } <b>else</b> {
        (balance::zero(), balance::zero())
    }
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_create_position_ticket"></a>

## Function `create_position_ticket`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_position_ticket">create_position_ticket</a>&lt;X, Y&gt;(_: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, _: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, _: <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>, _: <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>, _: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, _: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, _: u128, _: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, _: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_position_ticket">create_position_ticket</a>&lt;X, Y&gt;(
    _: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    _: &<b>mut</b> PositionConfig,
    _: I32,
    _: I32,
    _: Balance&lt;X&gt;,
    _: Balance&lt;Y&gt;,
    _: u128,
    _: &PythPriceInfo,
    _: &<b>mut</b> TxContext,
): CreatePositionTicket&lt;X, Y, I32&gt; {
    <b>abort</b> e_function_deprecated!()
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_create_position_ticket_v2"></a>

## Function `create_position_ticket_v2`

Initialize position creation for a leveraged Bluefin position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_position_ticket_v2">create_position_ticket_v2</a>&lt;X, Y&gt;(bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, tick_a: <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>, tick_b: <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>, principal_x: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, principal_y: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, delta_l: u128, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_position_ticket_v2">create_position_ticket_v2</a>&lt;X, Y&gt;(
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    config: &<b>mut</b> PositionConfig,
    tick_a: I32,
    tick_b: I32,
    principal_x: Balance&lt;X&gt;,
    principal_y: Balance&lt;Y&gt;,
    delta_l: u128,
    price_info: &PythPriceInfo,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): CreatePositionTicket&lt;X, Y, I32&gt; {
    core::create_position_ticket!(
        bluefin_pool,
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

<a name="kai_leverage_bluefin_spot_borrow_for_position_x"></a>

## Function `borrow_for_position_x`

Borrow X tokens for position creation.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_borrow_for_position_x">borrow_for_position_x</a>&lt;X, Y, SX&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_borrow_for_position_x">borrow_for_position_x</a>&lt;X, Y, SX&gt;(
    ticket: &<b>mut</b> CreatePositionTicket&lt;X, Y, I32&gt;,
    config: &PositionConfig,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
) {
    core::borrow_for_position_x!(ticket, config, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_borrow_for_position_y"></a>

## Function `borrow_for_position_y`

Borrow Y tokens for position creation.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_borrow_for_position_y">borrow_for_position_y</a>&lt;X, Y, SY&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_borrow_for_position_y">borrow_for_position_y</a>&lt;X, Y, SY&gt;(
    ticket: &<b>mut</b> CreatePositionTicket&lt;X, Y, I32&gt;,
    config: &PositionConfig,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
) {
    core::borrow_for_position_y!(ticket, config, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_create_position"></a>

## Function `create_position`

Create a leveraged position from a prepared ticket.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_position">create_position</a>&lt;X, Y&gt;(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, <a href="../../dependencies/integer_mate/i32.md#integer_mate_i32_I32">integer_mate::i32::I32</a>&gt;, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_global_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, creation_fee: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_position">create_position</a>&lt;X, Y&gt;(
    config: &PositionConfig,
    ticket: CreatePositionTicket&lt;X, Y, I32&gt;,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    creation_fee: Balance&lt;SUI&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): PositionCap {
    core::create_position!(
        config,
        ticket,
        bluefin_pool,
        creation_fee,
        ctx,
        |pool, tick_a, tick_b, delta_l, balance_x0, balance_y0| {
            <b>let</b> <b>mut</b> lp_position = bluefin_pool::open_position(
                bluefin_global_config,
                pool,
                i32::as_u32(tick_a),
                i32::as_u32(tick_b),
                ctx,
            );
            <b>let</b> (_, _, residual_x, residual_y) = bluefin_pool::add_liquidity(
                clock,
                bluefin_global_config,
                pool,
                &<b>mut</b> lp_position,
                balance_x0,
                balance_y0,
                delta_l,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();
            lp_position
        },
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_create_deleverage_ticket"></a>

## Function `create_deleverage_ticket`

Initialize deleveraging for a position that has fallen below
the deleverage margin threshold (permissioned).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_deleverage_ticket">create_deleverage_ticket</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_global_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, max_delta_l: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_deleverage_ticket">create_deleverage_ticket</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    max_delta_l: u128,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): (DeleverageTicket, ActionRequest) {
    core::create_deleverage_ticket!(
        position,
        config,
        price_info,
        debt_info,
        bluefin_pool,
        max_delta_l,
        ctx,
        |
            pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> BluefinPosition,
            delta_l: u128,
        | <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_remove_liquidity">remove_liquidity</a>(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_create_deleverage_ticket_for_liquidation"></a>

## Function `create_deleverage_ticket_for_liquidation`

Initialize deleveraging for a position that has fallen below
the liquidation margin threshold (permissionless).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_deleverage_ticket_for_liquidation">create_deleverage_ticket_for_liquidation</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_global_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_create_deleverage_ticket_for_liquidation">create_deleverage_ticket_for_liquidation</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): DeleverageTicket {
    core::create_deleverage_ticket_for_liquidation!(
        position,
        config,
        price_info,
        debt_info,
        bluefin_pool,
        |
            pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> BluefinPosition,
            delta_l: u128,
        | <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_remove_liquidity">remove_liquidity</a>(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_deleverage"></a>

## Function `deleverage`

Execute deleveraging for a position that has fallen below
the deleverage margin threshold (permissioned).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_deleverage">deleverage</a>&lt;X, Y, SX, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_global_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, max_delta_l: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_deleverage">deleverage</a>&lt;X, Y, SX, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    max_delta_l: u128,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    core::deleverage!(
        position,
        config,
        price_info,
        supply_pool_x,
        supply_pool_y,
        bluefin_pool,
        max_delta_l,
        clock,
        ctx,
        |
            pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> BluefinPosition,
            delta_l: u128,
        | <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_remove_liquidity">remove_liquidity</a>(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_deleverage_for_liquidation"></a>

## Function `deleverage_for_liquidation`

Execute deleveraging for a position that has fallen below
the liquidation margin threshold (permissionless).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_deleverage_for_liquidation">deleverage_for_liquidation</a>&lt;X, Y, SX, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_global_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_deleverage_for_liquidation">deleverage_for_liquidation</a>&lt;X, Y, SX, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    price_info: &PythPriceInfo,
    supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_global_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
) {
    core::deleverage_for_liquidation!(
        position,
        config,
        price_info,
        supply_pool_x,
        supply_pool_y,
        bluefin_pool,
        clock,
        |
            pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> BluefinPosition,
            delta_l: u128,
        | <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_remove_liquidity">remove_liquidity</a>(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_liquidate_col_x"></a>

## Function `liquidate_col_x`

Liquidate X collateral by repaying Y debt. The position needs to be fully deleveraged and
below the liquidation margin threshold.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_liquidate_col_x">liquidate_col_x</a>&lt;X, Y, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_liquidate_col_x">liquidate_col_x</a>&lt;X, Y, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &<b>mut</b> Balance&lt;Y&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
): Balance&lt;X&gt; {
    core::liquidate_col_x!(position, config, price_info, debt_info, repayment, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_liquidate_col_y"></a>

## Function `liquidate_col_y`

Liquidate Y collateral by repaying X debt. The position needs to be fully deleveraged and
below the liquidation margin threshold.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_liquidate_col_y">liquidate_col_y</a>&lt;X, Y, SX&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_liquidate_col_y">liquidate_col_y</a>&lt;X, Y, SX&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    repayment: &<b>mut</b> Balance&lt;X&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
): Balance&lt;Y&gt; {
    core::liquidate_col_y!(position, config, price_info, debt_info, repayment, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_repay_bad_debt_x"></a>

## Function `repay_bad_debt_x`

Repay bad debt for X tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_repay_bad_debt_x">repay_bad_debt_x</a>&lt;X, Y, SX&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_repay_bad_debt_x">repay_bad_debt_x</a>&lt;X, Y, SX&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    repayment: &<b>mut</b> Balance&lt;X&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    core::repay_bad_debt!(
        position,
        config,
        price_info,
        debt_info,
        supply_pool,
        repayment,
        clock,
        ctx,
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_repay_bad_debt_y"></a>

## Function `repay_bad_debt_y`

Repay bad debt for Y tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_repay_bad_debt_y">repay_bad_debt_y</a>&lt;X, Y, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_repay_bad_debt_y">repay_bad_debt_y</a>&lt;X, Y, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    repayment: &<b>mut</b> Balance&lt;Y&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    core::repay_bad_debt!(
        position,
        config,
        price_info,
        debt_info,
        supply_pool,
        repayment,
        clock,
        ctx,
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_reduce"></a>

## Function `reduce`

Initialize position size reduction (withdraw), while preserving mathematical safety guarantees.
A factor_x64 percentage of the position is withdrawn and the same percentage of debt is repaid.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_reduce">reduce</a>&lt;X, Y, SX, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_global_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, factor_x64: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_reduce">reduce</a>&lt;X, Y, SX, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    supply_pool_x: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    supply_pool_y: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_global_config: &bluefin_config::GlobalConfig,
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
        bluefin_pool,
        factor_x64,
        clock,
        |
            pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> BluefinPosition,
            delta_l: u128,
        | <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_remove_liquidity">remove_liquidity</a>(bluefin_global_config, pool, lp_position, delta_l, clock),
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_add_liquidity"></a>

## Function `add_liquidity`

Add liquidity to the inner LP position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_add_liquidity">add_liquidity</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, delta_l: u128, balance_x: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, balance_y: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_add_liquidity">add_liquidity</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    cap: &PositionCap,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_config: &bluefin_config::GlobalConfig,
    delta_l: u128,
    balance_x: Balance&lt;X&gt;,
    balance_y: Balance&lt;Y&gt;,
    clock: &Clock,
) {
    <b>let</b> (delta_x, delta_y) = <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_calc_deposit_amounts_by_liquidity">calc_deposit_amounts_by_liquidity</a>(
        bluefin_pool,
        position.lp_position().lower_tick(),
        position.lp_position().upper_tick(),
        delta_l,
    );
    <b>assert</b>!(balance_x.value() == delta_x, e_invalid_balance_value!());
    <b>assert</b>!(balance_y.value() == delta_y, e_invalid_balance_value!());
    core::add_liquidity!(
        position,
        config,
        cap,
        price_info,
        debt_info,
        bluefin_pool,
        |pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;, lp_position: &<b>mut</b> BluefinPosition| {
            <b>let</b> (delta_x, delta_y, residual_x, residual_y) = bluefin_pool::add_liquidity(
                clock,
                bluefin_config,
                pool,
                lp_position,
                balance_x,
                balance_y,
                delta_l,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();
            (delta_l, delta_x, delta_y)
        },
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_repay_debt_x"></a>

## Function `repay_debt_x`

Repay as much X token debt as possible using the available balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_repay_debt_x">repay_debt_x</a>&lt;X, Y, SX&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_repay_debt_x">repay_debt_x</a>&lt;X, Y, SX&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    cap: &PositionCap,
    balance: &<b>mut</b> Balance&lt;X&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
) {
    core::repay_debt_x(position, cap, balance, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_repay_debt_y"></a>

## Function `repay_debt_y`

Repay as much Y token debt as possible using the available balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_repay_debt_y">repay_debt_y</a>&lt;X, Y, SY&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_repay_debt_y">repay_debt_y</a>&lt;X, Y, SY&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    cap: &PositionCap,
    balance: &<b>mut</b> Balance&lt;Y&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
) {
    core::repay_debt_y(position, cap, balance, supply_pool, clock)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_owner_collect_fee"></a>

## Function `owner_collect_fee`

Collect accumulated AMM fees for position owner directly.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_owner_collect_fee">owner_collect_fee</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_owner_collect_fee">owner_collect_fee</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    cap: &PositionCap,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): (Balance&lt;X&gt;, Balance&lt;Y&gt;) {
    core::owner_collect_fee!(
        position,
        config,
        cap,
        bluefin_pool,
        |pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;, lp_position: &<b>mut</b> BluefinPosition| {
            <b>let</b> (_, _, balance_x, balance_y) = bluefin_pool::collect_fee(
                clock,
                bluefin_config,
                pool,
                lp_position,
            );
            (balance_x, balance_y)
        },
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_owner_collect_reward"></a>

## Function `owner_collect_reward`

Collect accumulated AMM rewards for position owner directly.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_owner_collect_reward">owner_collect_reward</a>&lt;X, Y, T&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_owner_collect_reward">owner_collect_reward</a>&lt;X, Y, T&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    cap: &PositionCap,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): Balance&lt;T&gt; {
    core::owner_collect_reward!(
        position,
        config,
        cap,
        bluefin_pool,
        |
            pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> BluefinPosition,
        | bluefin_pool::collect_reward(
            clock,
            bluefin_config,
            pool,
            lp_position,
        ),
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_owner_take_stashed_rewards"></a>

## Function `owner_take_stashed_rewards`

Withdraw stashed rewards from position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_owner_take_stashed_rewards">owner_take_stashed_rewards</a>&lt;X, Y, T&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, amount: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_owner_take_stashed_rewards">owner_take_stashed_rewards</a>&lt;X, Y, T&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    cap: &PositionCap,
    amount: Option&lt;u64&gt;,
): Balance&lt;T&gt; {
    core::owner_take_stashed_rewards(position, cap, amount)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_delete_position"></a>

## Function `delete_position`

Delete position. The position needs to be fully reduced and all assets withdrawn first.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_delete_position">delete_position</a>&lt;X, Y&gt;(position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, cap: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_delete_position">delete_position</a>&lt;X, Y&gt;(
    position: Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    cap: PositionCap,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    core::delete_position!(
        position,
        config,
        cap,
        |lp_position| bluefin_pool::close_position_v2(
            clock,
            bluefin_config,
            bluefin_pool,
            lp_position,
        ),
        ctx,
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_rebalance_collect_fee"></a>

## Function `rebalance_collect_fee`

Collects AMM trading fees for a leveraged CLMM position during rebalancing,
applies protocol fee, and updates the <code>RebalanceReceipt</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_rebalance_collect_fee">rebalance_collect_fee</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_rebalance_collect_fee">rebalance_collect_fee</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    receipt: &<b>mut</b> RebalanceReceipt,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): (Balance&lt;X&gt;, Balance&lt;Y&gt;) {
    core::rebalance_collect_fee!(
        position,
        config,
        receipt,
        bluefin_pool,
        |pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;, lp_position: &<b>mut</b> BluefinPosition| {
            <b>let</b> (_, _, balance_x, balance_y) = bluefin_pool::collect_fee(
                clock,
                bluefin_config,
                pool,
                lp_position,
            );
            (balance_x, balance_y)
        },
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_rebalance_collect_reward"></a>

## Function `rebalance_collect_reward`

Collects AMM rewards for a leveraged CLMM position during rebalancing,
applies protocol fee, and updates the <code>RebalanceReceipt</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_rebalance_collect_reward">rebalance_collect_reward</a>&lt;X, Y, T&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_rebalance_collect_reward">rebalance_collect_reward</a>&lt;X, Y, T&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    receipt: &<b>mut</b> RebalanceReceipt,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_config: &bluefin_config::GlobalConfig,
    clock: &Clock,
): Balance&lt;T&gt; {
    core::rebalance_collect_reward!(
        position,
        config,
        receipt,
        bluefin_pool,
        |
            pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
            lp_position: &<b>mut</b> BluefinPosition,
        | bluefin_pool::collect_reward(
            clock,
            bluefin_config,
            pool,
            lp_position,
        ),
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_rebalance_add_liquidity"></a>

## Function `rebalance_add_liquidity`

Adds liquidity to a the underlying LP position during rebalancing.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_rebalance_add_liquidity">rebalance_add_liquidity</a>&lt;X, Y&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, bluefin_pool: &<b>mut</b> <a href="../../dependencies/bluefin_spot/pool.md#bluefin_spot_pool_Pool">bluefin_spot::pool::Pool</a>&lt;X, Y&gt;, bluefin_config: &<a href="../../dependencies/bluefin_spot/config.md#bluefin_spot_config_GlobalConfig">bluefin_spot::config::GlobalConfig</a>, delta_l: u128, balance_x: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, balance_y: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_rebalance_add_liquidity">rebalance_add_liquidity</a>&lt;X, Y&gt;(
    position: &<b>mut</b> Position&lt;X, Y, BluefinPosition&gt;,
    config: &<b>mut</b> PositionConfig,
    receipt: &<b>mut</b> RebalanceReceipt,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    bluefin_pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;,
    bluefin_config: &bluefin_config::GlobalConfig,
    delta_l: u128,
    balance_x: Balance&lt;X&gt;,
    balance_y: Balance&lt;Y&gt;,
    clock: &Clock,
) {
    <b>let</b> (delta_x, delta_y) = <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_calc_deposit_amounts_by_liquidity">calc_deposit_amounts_by_liquidity</a>(
        bluefin_pool,
        position.lp_position().lower_tick(),
        position.lp_position().upper_tick(),
        delta_l,
    );
    <b>assert</b>!(balance_x.value() == delta_x, e_invalid_balance_value!());
    <b>assert</b>!(balance_y.value() == delta_y, e_invalid_balance_value!());
    core::rebalance_add_liquidity!(
        position,
        config,
        receipt,
        price_info,
        debt_info,
        bluefin_pool,
        |pool: &<b>mut</b> bluefin_pool::Pool&lt;X, Y&gt;, lp_position: &<b>mut</b> BluefinPosition| {
            <b>let</b> (delta_x, delta_y, residual_x, residual_y) = bluefin_pool::add_liquidity(
                clock,
                bluefin_config,
                pool,
                lp_position,
                balance_x,
                balance_y,
                delta_l,
            );
            residual_x.destroy_zero();
            residual_y.destroy_zero();
            (delta_l, delta_x, delta_y)
        },
    )
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_position_model"></a>

## Function `position_model`

Create validated position model for analysis and calculations.
Used to obtain position models for risk assessment,
liquidation calculations, and other analytical operations.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_position_model">position_model</a>&lt;X, Y&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>): <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_position_model">position_model</a>&lt;X, Y&gt;(
    position: &Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    debt_info: &DebtInfo,
): PositionModel {
    core::validated_model_for_position!(position, config, debt_info)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_calc_liquidate_col_x"></a>

## Function `calc_liquidate_col_x`

Calculate the required amounts to liquidate X collateral by repaying Y debt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_calc_liquidate_col_x">calc_liquidate_col_x</a>&lt;X, Y&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, max_repayment_amt_y: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_calc_liquidate_col_x">calc_liquidate_col_x</a>&lt;X, Y&gt;(
    position: &Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_y: u64,
): (u64, u64) {
    core::calc_liquidate_col_x!(position, config, price_info, debt_info, max_repayment_amt_y)
}
</code></pre>



</details>

<a name="kai_leverage_bluefin_spot_calc_liquidate_col_y"></a>

## Function `calc_liquidate_col_y`

Calculate the required amounts to liquidate Y collateral by repaying X debt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_calc_liquidate_col_y">calc_liquidate_col_y</a>&lt;X, Y&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, <a href="../../dependencies/bluefin_spot/position.md#bluefin_spot_position_Position">bluefin_spot::position::Position</a>&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, max_repayment_amt_x: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/bluefin_spot.md#kai_leverage_bluefin_spot_calc_liquidate_col_y">calc_liquidate_col_y</a>&lt;X, Y&gt;(
    position: &Position&lt;X, Y, BluefinPosition&gt;,
    config: &PositionConfig,
    price_info: &PythPriceInfo,
    debt_info: &DebtInfo,
    max_repayment_amt_x: u64,
): (u64, u64) {
    core::calc_liquidate_col_y!(position, config, price_info, debt_info, max_repayment_amt_x)
}
</code></pre>



</details>

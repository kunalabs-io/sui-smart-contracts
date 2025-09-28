
<a name="kai_leverage_equity"></a>

# Module `kai_leverage::equity`

Equity share management system for supply pools, with fungible equity coin minting.

This module provides the core infrastructure for tracking equity stakes in pools or other systems.
It implements a share-based system where equity is represented as shares that maintain their
proportional value even as the total pool value changes due to deposits, withdrawals, or yield accrual.

In addition to share-based accounting, this module supports minting equity as fungible coins,
enabling seamless integration with token-based protocols and facilitating transferability of ownership positions.

Importantly, this system is designed to prevent value leakage due to integer arithmetic rounding:
whenever fractional values arise from division or share calculations, the rounding is always
performed in a way that favors the pool rather than the withdrawing party. This ensures
that the system never underestimates liabilities or overestimates ownership due to rounding,
preserving the solvency and integrity of the protocol.


-  [Struct `EquityShareBalance`](#kai_leverage_equity_EquityShareBalance)
-  [Struct `EquityRegistry`](#kai_leverage_equity_EquityRegistry)
-  [Struct `EquityTreasury`](#kai_leverage_equity_EquityTreasury)
-  [Constants](#@Constants_0)
-  [Function `value_x64`](#kai_leverage_equity_value_x64)
-  [Function `supply_x64`](#kai_leverage_equity_supply_x64)
-  [Function `underlying_value_x64`](#kai_leverage_equity_underlying_value_x64)
-  [Function `borrow_registry`](#kai_leverage_equity_borrow_registry)
-  [Function `borrow_mut_registry`](#kai_leverage_equity_borrow_mut_registry)
-  [Function `borrow_treasury_cap`](#kai_leverage_equity_borrow_treasury_cap)
-  [Function `create_registry`](#kai_leverage_equity_create_registry)
-  [Function `create_registry_with_cap`](#kai_leverage_equity_create_registry_with_cap)
-  [Function `create_treasury`](#kai_leverage_equity_create_treasury)
-  [Function `zero`](#kai_leverage_equity_zero)
-  [Function `increase_value_and_issue_x64`](#kai_leverage_equity_increase_value_and_issue_x64)
-  [Function `increase_value_and_issue`](#kai_leverage_equity_increase_value_and_issue)
-  [Function `increase_value_x64`](#kai_leverage_equity_increase_value_x64)
-  [Function `increase_value`](#kai_leverage_equity_increase_value)
-  [Function `decrease_value_x64`](#kai_leverage_equity_decrease_value_x64)
-  [Function `decrease_value`](#kai_leverage_equity_decrease_value)
-  [Function `calc_redeem_x64`](#kai_leverage_equity_calc_redeem_x64)
-  [Function `redeem_x64`](#kai_leverage_equity_redeem_x64)
-  [Function `calc_redeem_lossy`](#kai_leverage_equity_calc_redeem_lossy)
-  [Function `redeem_lossy`](#kai_leverage_equity_redeem_lossy)
-  [Function `calc_redeem_for_amount_x64`](#kai_leverage_equity_calc_redeem_for_amount_x64)
-  [Function `calc_redeem_for_amount`](#kai_leverage_equity_calc_redeem_for_amount)
-  [Function `calc_balance_redeem_for_amount`](#kai_leverage_equity_calc_balance_redeem_for_amount)
-  [Function `into_balance_lossy`](#kai_leverage_equity_into_balance_lossy)
-  [Function `into_balance`](#kai_leverage_equity_into_balance)
-  [Function `from_balance`](#kai_leverage_equity_from_balance)
-  [Function `split_x64`](#kai_leverage_equity_split_x64)
-  [Function `withdraw_all`](#kai_leverage_equity_withdraw_all)
-  [Function `split`](#kai_leverage_equity_split)
-  [Function `join`](#kai_leverage_equity_join)
-  [Function `destroy_zero`](#kai_leverage_equity_destroy_zero)
-  [Function `destroy_empty_registry`](#kai_leverage_equity_destroy_empty_registry)


<pre><code><b>use</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util">kai_leverage::util</a>;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
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
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_leverage_equity_EquityShareBalance"></a>

## Struct `EquityShareBalance`

Represents a balance of equity shares in Q64.64 format.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;<b>phantom</b> T&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: u128</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_equity_EquityRegistry"></a>

## Struct `EquityRegistry`

Registry tracking total equity shares and underlying asset value.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;<b>phantom</b> T&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>: u128</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>: u128</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_equity_EquityTreasury"></a>

## Struct `EquityTreasury`

Treasury combining equity registry with coin minting capability.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a>&lt;<b>phantom</b> T&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>registry: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>cap: <a href="../../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;T&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_equity_Q64"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>: u128 = 18446744073709551616;
</code></pre>



<a name="kai_leverage_equity_ENonZero"></a>

For when trying to destroy a non-zero share balance.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_ENonZero">ENonZero</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_equity_value_x64"></a>

## Function `value_x64`

Get the share value in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>&lt;T&gt;(share: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>&lt;T&gt;(share: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;): u128 {
    share.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_equity_supply_x64"></a>

## Function `supply_x64`

Get the total share supply in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;): u128 {
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_equity_underlying_value_x64"></a>

## Function `underlying_value_x64`

Get the total underlying value in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;): u128 {
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_equity_borrow_registry"></a>

## Function `borrow_registry`

Borrow immutable reference to the equity registry.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_borrow_registry">borrow_registry</a>&lt;T&gt;(treasury: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;T&gt;): &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_borrow_registry">borrow_registry</a>&lt;T&gt;(treasury: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a>&lt;T&gt;): &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt; {
    &treasury.registry
}
</code></pre>



</details>

<a name="kai_leverage_equity_borrow_mut_registry"></a>

## Function `borrow_mut_registry`

Borrow mutable reference to the equity registry.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_borrow_mut_registry">borrow_mut_registry</a>&lt;T&gt;(treasury: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;T&gt;): &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_borrow_mut_registry">borrow_mut_registry</a>&lt;T&gt;(treasury: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a>&lt;T&gt;): &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt; {
    &<b>mut</b> treasury.registry
}
</code></pre>



</details>

<a name="kai_leverage_equity_borrow_treasury_cap"></a>

## Function `borrow_treasury_cap`

Borrow the treasury capability for minting equity tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_borrow_treasury_cap">borrow_treasury_cap</a>&lt;T&gt;(treasury: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;T&gt;): &<a href="../../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_borrow_treasury_cap">borrow_treasury_cap</a>&lt;T&gt;(treasury: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a>&lt;T&gt;): &TreasuryCap&lt;T&gt; {
    &treasury.cap
}
</code></pre>



</details>

<a name="kai_leverage_equity_create_registry"></a>

## Function `create_registry`

Create a new empty equity registry.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_create_registry">create_registry</a>&lt;T: drop&gt;(_: T): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_create_registry">create_registry</a>&lt;T: drop&gt;(_: T): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt; {
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a> {
        <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>: 0,
        <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>: 0,
    }
}
</code></pre>



</details>

<a name="kai_leverage_equity_create_registry_with_cap"></a>

## Function `create_registry_with_cap`

Create a new equity registry using an existing treasury cap.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_create_registry_with_cap">create_registry_with_cap</a>&lt;T: drop&gt;(_: &<a href="../../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;T&gt;): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_create_registry_with_cap">create_registry_with_cap</a>&lt;T: drop&gt;(_: &TreasuryCap&lt;T&gt;): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt; {
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a> {
        <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>: 0,
        <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>: 0,
    }
}
</code></pre>



</details>

<a name="kai_leverage_equity_create_treasury"></a>

## Function `create_treasury`

Create a new equity treasury. The treasury has the ability to mint equity as fungible coins.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_create_treasury">create_treasury</a>&lt;T: drop&gt;(witness: T, decimals: u8, symbol: vector&lt;u8&gt;, name: vector&lt;u8&gt;, description: vector&lt;u8&gt;, icon_url: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../../dependencies/sui/url.md#sui_url_Url">sui::url::Url</a>&gt;, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;T&gt;, <a href="../../dependencies/sui/coin.md#sui_coin_CoinMetadata">sui::coin::CoinMetadata</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_create_treasury">create_treasury</a>&lt;T: drop&gt;(
    witness: T,
    decimals: u8,
    symbol: vector&lt;u8&gt;,
    name: vector&lt;u8&gt;,
    description: vector&lt;u8&gt;,
    icon_url: Option&lt;Url&gt;,
    ctx: &<b>mut</b> TxContext,
): (<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a>&lt;T&gt;, CoinMetadata&lt;T&gt;) {
    <b>let</b> registry = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt; {
        <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>: 0,
        <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>: 0,
    };
    <b>let</b> (cap, metadata) = coin::create_currency(
        witness,
        decimals,
        symbol,
        name,
        description,
        icon_url,
        ctx,
    );
    <b>let</b> treasury = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a> { registry, cap };
    (treasury, metadata)
}
</code></pre>



</details>

<a name="kai_leverage_equity_zero"></a>

## Function `zero`

Create a zero equity share balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_zero">zero</a>&lt;T&gt;(): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_zero">zero</a>&lt;T&gt;(): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt; {
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> {
        <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: 0,
    }
}
</code></pre>



</details>

<a name="kai_leverage_equity_increase_value_and_issue_x64"></a>

## Function `increase_value_and_issue_x64`

Increase the underlying value and issue corresponding shares. Input value is in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value_and_issue_x64">increase_value_and_issue_x64</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: u128): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value_and_issue_x64">increase_value_and_issue_x64</a>&lt;T&gt;(
    registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;,
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: u128,
): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt; {
    <b>if</b> (registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> == 0) {
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>;
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a> = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>;
        <b>return</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> }
    };
    <b>let</b> amt_shares_x64 = util::muldiv_u128(
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>,
        <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>,
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>,
    );
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> = registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> + <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>;
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a> = registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a> + amt_shares_x64;
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: amt_shares_x64 }
}
</code></pre>



</details>

<a name="kai_leverage_equity_increase_value_and_issue"></a>

## Function `increase_value_and_issue`

Increase the underlying value and issue corresponding shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value_and_issue">increase_value_and_issue</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, value: u64): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value_and_issue">increase_value_and_issue</a>&lt;T&gt;(
    registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;,
    value: u64,
): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt; {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = (value <b>as</b> u128) * <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>;
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value_and_issue_x64">increase_value_and_issue_x64</a>(registry, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>)
}
</code></pre>



</details>

<a name="kai_leverage_equity_increase_value_x64"></a>

## Function `increase_value_x64`

Increase the underlying value without issuing new shares. Input value is in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value_x64">increase_value_x64</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value_x64">increase_value_x64</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: u128) {
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> = registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> + <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>;
}
</code></pre>



</details>

<a name="kai_leverage_equity_increase_value"></a>

## Function `increase_value`

Increase the underlying value without issuing new shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value">increase_value</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, value: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value">increase_value</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, value: u64) {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = (value <b>as</b> u128) * <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>;
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_increase_value_x64">increase_value_x64</a>(registry, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>)
}
</code></pre>



</details>

<a name="kai_leverage_equity_decrease_value_x64"></a>

## Function `decrease_value_x64`

Decrease the underlying value without redeeming shares. Input value is in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_decrease_value_x64">decrease_value_x64</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_decrease_value_x64">decrease_value_x64</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: u128) {
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> = registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> - <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>;
}
</code></pre>



</details>

<a name="kai_leverage_equity_decrease_value"></a>

## Function `decrease_value`

Decrease the underlying value without redeeming shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_decrease_value">decrease_value</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, value: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_decrease_value">decrease_value</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, value: u64) {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = (value <b>as</b> u128) * <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>;
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_decrease_value_x64">decrease_value_x64</a>(registry, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>)
}
</code></pre>



</details>

<a name="kai_leverage_equity_calc_redeem_x64"></a>

## Function `calc_redeem_x64`

Calculate the amount of underlying value that would be redeemed for the given share value when calling the
<code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_x64">redeem_x64</a></code> function.
The input and return values are in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_x64">calc_redeem_x64</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, share_value_x64: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_x64">calc_redeem_x64</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, share_value_x64: u128): u128 {
    util::muldiv_u128(
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>,
        share_value_x64,
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>,
    )
}
</code></pre>



</details>

<a name="kai_leverage_equity_redeem_x64"></a>

## Function `redeem_x64`

Redeem the shares for the underlying value. Reduces the underlying value and supply.
Returns the value redeemed (the amount the underlying value was reduced by).
The returned value is in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_x64">redeem_x64</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, share: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_x64">redeem_x64</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, share: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;): u128 {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: share_value_x64 } = share;
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = util::muldiv_u128(
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>,
        share_value_x64,
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>,
    );
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> = registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> - <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>;
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a> = registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a> - share_value_x64;
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_equity_calc_redeem_lossy"></a>

## Function `calc_redeem_lossy`

Calculate the amount of underlying value that would be redeemed for the given share value when calling the
<code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_lossy">redeem_lossy</a></code> function.
The input and return values are in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_lossy">calc_redeem_lossy</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, share_value_x64: u128): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_lossy">calc_redeem_lossy</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, share_value_x64: u128): u64 {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_x64">calc_redeem_x64</a>(registry, share_value_x64);
    ((<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> / <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>) <b>as</b> u64)
}
</code></pre>



</details>

<a name="kai_leverage_equity_redeem_lossy"></a>

## Function `redeem_lossy`

Lossy. Redeem the shares for the underlying value. Reduces the underlying value and supply.
Returns the value redeemed (i.e., the amount by which the underlying value was reduced).

The redeemed amount is rounded down, and any fractional difference is added back to the total
underlying value. This effectively increases the value of other shares by that fraction.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_lossy">redeem_lossy</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, share: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_lossy">redeem_lossy</a>&lt;T&gt;(registry: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, share: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;): u64 {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_x64">redeem_x64</a>(registry, share);
    <b>let</b> value = ((<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> / <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>) <b>as</b> u64);
    <b>let</b> fraction = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> % <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>;
    registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> = registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> + fraction;
    value
}
</code></pre>



</details>

<a name="kai_leverage_equity_calc_redeem_for_amount_x64"></a>

## Function `calc_redeem_for_amount_x64`

Calculate the amount of shares required to redeem the given amount of underlying value when calling the
<code>redeem_for_amount_x64</code> function.
Since the resulting redeemed value can sometimes be different from the required due to integer
arithmetic, the function also returns the calculated redeemed value (the amount the underlying value
would be reduced by). This value is always greater than or equal to the required amount.
Returns <code>(share_amount_x64, redeemed_value_x64)</code> tuple. The input and return values are in
Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_for_amount_x64">calc_redeem_for_amount_x64</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, amount_x64: u128): (u128, u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_for_amount_x64">calc_redeem_for_amount_x64</a>&lt;T&gt;(
    registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;,
    amount_x64: u128,
): (u128, u128) {
    <b>let</b> share_amount_x64 = util::muldiv_round_up_u128(
        amount_x64,
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>,
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>,
    );
    (share_amount_x64, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_x64">calc_redeem_x64</a>(registry, share_amount_x64))
}
</code></pre>



</details>

<a name="kai_leverage_equity_calc_redeem_for_amount"></a>

## Function `calc_redeem_for_amount`

Calculate the amount of <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code> required to redeem the given amount of underlying
value when calling the <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_lossy">redeem_lossy</a></code> function.
The resulting redeemed amount will always be exactly equal to the specified amount.
Returns the share amount. The input and return values are in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_for_amount">calc_redeem_for_amount</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, amount: u64): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_for_amount">calc_redeem_for_amount</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;, amount: u64): u128 {
    util::muldiv_round_up_u128(
        (amount <b>as</b> u128) * <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>,
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>,
        registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>,
    )
}
</code></pre>



</details>

<a name="kai_leverage_equity_calc_balance_redeem_for_amount"></a>

## Function `calc_balance_redeem_for_amount`

Calculate the amount of share <code>Balance</code> required to redeem the given amount of underlying value
when calling the <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_redeem_lossy">redeem_lossy</a></code> function.
Since the resulting redeemed value can sometimes be different from the required due to
integer arithmetic, the function also returns the calculated redeemed value (the amount
the underlying value would be reduced by). This value is always greater than or equal to the
required amount.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_balance_redeem_for_amount">calc_balance_redeem_for_amount</a>&lt;T&gt;(registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;, amount: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_balance_redeem_for_amount">calc_balance_redeem_for_amount</a>&lt;T&gt;(
    registry: &<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;,
    amount: u64,
): (u64, u64) {
    <b>let</b> share_amount = (
        util::muldiv_round_up_u128(
            (amount <b>as</b> u128),
            registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>,
            registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a>,
        ) <b>as</b> u64,
    );
    <b>let</b> redeemed_value = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_calc_redeem_lossy">calc_redeem_lossy</a>(registry, (share_amount <b>as</b> u128) * <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>);
    (share_amount, redeemed_value)
}
</code></pre>



</details>

<a name="kai_leverage_equity_into_balance_lossy"></a>

## Function `into_balance_lossy`

Lossy. Converts the <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code> to a corresponding <code>Balance</code>.
The fractional difference from rounding down is subtracted from the total supply of shares,
which effectively increases the value of other shares against the underlying.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_into_balance_lossy">into_balance_lossy</a>&lt;T&gt;(share: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;, treasury: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;T&gt;): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_into_balance_lossy">into_balance_lossy</a>&lt;T&gt;(
    share: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;,
    treasury: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a>&lt;T&gt;,
): Balance&lt;T&gt; {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: share_value_x64 } = share;
    <b>let</b> value = ((share_value_x64 / <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>) <b>as</b> u64);
    <b>let</b> fraction = share_value_x64 % <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>;
    treasury.registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a> = treasury.registry.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a> - fraction;
    coin::mint_balance(&<b>mut</b> treasury.cap, value)
}
</code></pre>



</details>

<a name="kai_leverage_equity_into_balance"></a>

## Function `into_balance`

Convert a <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code> to a <code>Balance</code> while preserving the fractional part.
Not lossy but doesn't consume all the shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_into_balance">into_balance</a>&lt;T&gt;(share: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;, treasury: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;T&gt;): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_into_balance">into_balance</a>&lt;T&gt;(
    share: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;,
    treasury: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a>&lt;T&gt;,
): Balance&lt;T&gt; {
    <b>let</b> whole_amt = share.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> / <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a> * <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>;
    <b>let</b> share = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_split_x64">split_x64</a>(share, whole_amt);
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_into_balance_lossy">into_balance_lossy</a>(share, treasury)
}
</code></pre>



</details>

<a name="kai_leverage_equity_from_balance"></a>

## Function `from_balance`

Converts the <code>Balance</code> to a corresponding <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_from_balance">from_balance</a>&lt;T&gt;(treasury: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;T&gt;, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_from_balance">from_balance</a>&lt;T&gt;(
    treasury: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">EquityTreasury</a>&lt;T&gt;,
    balance: Balance&lt;T&gt;,
): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt; {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = (balance::value(&balance) <b>as</b> u128) * <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>;
    balance::decrease_supply(
        coin::supply_mut(&<b>mut</b> treasury.cap),
        balance,
    );
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> }
}
</code></pre>



</details>

<a name="kai_leverage_equity_split_x64"></a>

## Function `split_x64`

Split a <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code> and take a sub balance from it. Input amount is in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_split_x64">split_x64</a>&lt;T&gt;(shares: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;, amount_x64: u128): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_split_x64">split_x64</a>&lt;T&gt;(
    shares: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;,
    amount_x64: u128,
): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt; {
    <b>let</b> new_shares = <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: amount_x64 };
    shares.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = shares.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> - amount_x64;
    new_shares
}
</code></pre>



</details>

<a name="kai_leverage_equity_withdraw_all"></a>

## Function `withdraw_all`

Withdraw all shares from a <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_withdraw_all">withdraw_all</a>&lt;T&gt;(shares: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_withdraw_all">withdraw_all</a>&lt;T&gt;(shares: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt; {
    <b>let</b> amount_x64 = shares.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>;
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_split_x64">split_x64</a>(shares, amount_x64)
}
</code></pre>



</details>

<a name="kai_leverage_equity_split"></a>

## Function `split`

Split a <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code> and take a sub balance from it.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_split">split</a>&lt;T&gt;(share: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;, amount: u64): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_split">split</a>&lt;T&gt;(share: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;, amount: u64): <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt; {
    <b>let</b> amount_x64 = (amount <b>as</b> u128) * <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_Q64">Q64</a>;
    <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_split_x64">split_x64</a>(share, amount_x64)
}
</code></pre>



</details>

<a name="kai_leverage_equity_join"></a>

## Function `join`

Join two <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code>s. The second balance is consumed.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_join">join</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;, other: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_join">join</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;, other: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;) {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> } = other;
    self.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> = self.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> + <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>;
}
</code></pre>



</details>

<a name="kai_leverage_equity_destroy_zero"></a>

## Function `destroy_zero`

Destroy a <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a></code> with zero value.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_destroy_zero">destroy_zero</a>&lt;T&gt;(shares: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_destroy_zero">destroy_zero</a>&lt;T&gt;(shares: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a>&lt;T&gt;) {
    <b>assert</b>!(shares.<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a> == 0, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_ENonZero">ENonZero</a>);
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">EquityShareBalance</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_value_x64">value_x64</a>: _ } = shares;
}
</code></pre>



</details>

<a name="kai_leverage_equity_destroy_empty_registry"></a>

## Function `destroy_empty_registry`

Destroy an empty <code><a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_destroy_empty_registry">destroy_empty_registry</a>&lt;T&gt;(registry: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">kai_leverage::equity::EquityRegistry</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_destroy_empty_registry">destroy_empty_registry</a>&lt;T&gt;(registry: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a>&lt;T&gt;) {
    <b>let</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityRegistry">EquityRegistry</a> { <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a>, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> } = registry;
    <b>assert</b>!(<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_supply_x64">supply_x64</a> == 0, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_ENonZero">ENonZero</a>);
    <b>assert</b>!(<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_underlying_value_x64">underlying_value_x64</a> == 0, <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_ENonZero">ENonZero</a>);
}
</code></pre>



</details>


<a name="kai_leverage_position_model_clmm"></a>

# Module `kai_leverage::position_model_clmm`

Mathematical model for leveraged CLMM position analysis implementing formal theoretical guarantees.

This module implements the mathematical framework from "Concentrated Liquidity with Leverage"
([arXiv:2409.12803](https://arxiv.org/pdf/2409.12803)), providing analytical functions for position
valuation, risk assessment, and safety validation with formal mathematical proofs.


<a name="@Theoretical_Foundation_0"></a>

### Theoretical Foundation


The module implements key mathematical concepts from the paper:
- **Position Value**: V_pos(P) = L·f(P, p_a, p_b) where f varies by price range
- **Asset Value**: A(P) = V_pos(P) + x_C·P + y_C (total position assets)
- **Debt Value**: D(P) = x_D·P + y_D (linear debt evolution)
- **Margin Function**: M(P) = A(P)/D(P) with proven monotonicity properties


    -  [Theoretical Foundation](#@Theoretical_Foundation_0)
-  [Struct `PositionModel`](#kai_leverage_position_model_clmm_PositionModel)
-  [Constants](#@Constants_1)
-  [Function `create`](#kai_leverage_position_model_clmm_create)
-  [Function `sqrt_pa_x64`](#kai_leverage_position_model_clmm_sqrt_pa_x64)
-  [Function `sqrt_pb_x64`](#kai_leverage_position_model_clmm_sqrt_pb_x64)
-  [Function `l`](#kai_leverage_position_model_clmm_l)
-  [Function `cx`](#kai_leverage_position_model_clmm_cx)
-  [Function `cy`](#kai_leverage_position_model_clmm_cy)
-  [Function `dx`](#kai_leverage_position_model_clmm_dx)
-  [Function `dy`](#kai_leverage_position_model_clmm_dy)
-  [Function `x_by_liquidity_x64`](#kai_leverage_position_model_clmm_x_by_liquidity_x64)
-  [Function `y_by_liquidity_x64`](#kai_leverage_position_model_clmm_y_by_liquidity_x64)
-  [Function `x_x64`](#kai_leverage_position_model_clmm_x_x64)
-  [Function `y_x64`](#kai_leverage_position_model_clmm_y_x64)
-  [Function `assets_x128`](#kai_leverage_position_model_clmm_assets_x128)
-  [Function `debt_x128`](#kai_leverage_position_model_clmm_debt_x128)
-  [Function `margin_x64`](#kai_leverage_position_model_clmm_margin_x64)
-  [Function `mul_x64`](#kai_leverage_position_model_clmm_mul_x64)
-  [Function `sqrt_pl_x64`](#kai_leverage_position_model_clmm_sqrt_pl_x64)
-  [Function `sqrt_ph_x64`](#kai_leverage_position_model_clmm_sqrt_ph_x64)
-  [Function `calc_max_deleverage_delta_l`](#kai_leverage_position_model_clmm_calc_max_deleverage_delta_l)
-  [Function `calc_max_liq_factor_x64`](#kai_leverage_position_model_clmm_calc_max_liq_factor_x64)
-  [Function `is_fully_deleveraged`](#kai_leverage_position_model_clmm_is_fully_deleveraged)
-  [Function `margin_below_threshold`](#kai_leverage_position_model_clmm_margin_below_threshold)
-  [Function `calc_liquidate_col_x`](#kai_leverage_position_model_clmm_calc_liquidate_col_x)
-  [Function `calc_liquidate_col_y`](#kai_leverage_position_model_clmm_calc_liquidate_col_y)


<pre><code><b>use</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util">kai_leverage::util</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/u64.md#std_u64">std::u64</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
</code></pre>



<a name="kai_leverage_position_model_clmm_PositionModel"></a>

## Struct `PositionModel`

Immutable snapshot of a position's parameters.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>: u128</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>: u128</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>: u128</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_1"></a>

## Constants


<a name="kai_leverage_position_model_clmm_U128_MAX"></a>

Maximum value for <code>u128</code>, <code>(1 &lt;&lt; 128) - 1</code>.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_U128_MAX">U128_MAX</a>: u128 = 340282366920938463463374607431768211455;
</code></pre>



<a name="kai_leverage_position_model_clmm_EInsufficientLiquidity"></a>

The requested <code>delta_l</code> is greater than the available liquidity in the position.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_EInsufficientLiquidity">EInsufficientLiquidity</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_position_model_clmm_create"></a>

## Function `create`

Create a new <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a></code> from range, liquidity, collateral and debt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_create">create</a>(<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>: u128, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>: u128, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>: u128, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>: u64, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>: u64, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>: u64, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>: u64): <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_create">create</a>(
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>: u128,
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>: u128,
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>: u128,
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>: u64,
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>: u64,
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>: u64,
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>: u64,
): <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a> {
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a> {
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>,
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>,
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>,
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>,
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>,
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>,
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>,
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_sqrt_pa_x64"></a>

## Function `sqrt_pa_x64`

Lower bound price sqrt in Q64.64.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_sqrt_pb_x64"></a>

## Function `sqrt_pb_x64`

Upper bound price sqrt in Q64.64.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_l"></a>

## Function `l`

Current position liquidity.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_cx"></a>

## Function `cx`

Additional collateral in token X (outside LP).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>): u64 {
    self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_cy"></a>

## Function `cy`

Additional collateral in token Y (outside LP).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>): u64 {
    self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_dx"></a>

## Function `dx`

Debt amount of token X.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>): u64 {
    self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_dy"></a>

## Function `dy`

Debt amount of token Y.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>): u64 {
    self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_x_by_liquidity_x64"></a>

## Function `x_by_liquidity_x64`

Calculate the amount of X in the LP position for a given price and liquidity.

NOTE: This function may not always return a fully precise Q64.64 result.
E.g. for very large prices, it can underestimate the amount of X.
The maximum absolute error is 1 (2^64), and the maximum relative error is 1/2^64.
Any inaccuracy in the result will always underestimate the amount of X (rounds down).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_by_liquidity_x64">x_by_liquidity_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, sqrt_p_x64: u128, delta_l: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_by_liquidity_x64">x_by_liquidity_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>, sqrt_p_x64: u128, delta_l: u128): u128 {
    <b>assert</b>!(delta_l &lt;= self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_EInsufficientLiquidity">EInsufficientLiquidity</a>);
    <b>if</b> (sqrt_p_x64 &gt;= self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>) {
        <b>return</b> 0
    };
    <b>if</b> (sqrt_p_x64 &lt; self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>) {
        <b>return</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_by_liquidity_x64">x_by_liquidity_x64</a>(self, self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>, delta_l)
    };
    // L * (sqrt(pb) - sqrt(p)) / (sqrt(p) * sqrt(pb))
    <b>let</b> num = (delta_l <b>as</b> u256) * ((self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a> - sqrt_p_x64) <b>as</b> u256);
    <b>let</b> denom = (sqrt_p_x64 <b>as</b> u256) * (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a> <b>as</b> u256);
    // 2^256 / denom
    <b>let</b> div256_denom = (u256::max_value!() - denom) / denom + 1;
    ((num * div256_denom) &gt;&gt; 128) <b>as</b> u128
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_y_by_liquidity_x64"></a>

## Function `y_by_liquidity_x64`

Calculate the amount of Y in the LP position for a given price and liquidity.
Aborts if there's not enough liquidity in the position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_by_liquidity_x64">y_by_liquidity_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, sqrt_p_x64: u128, delta_l: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_by_liquidity_x64">y_by_liquidity_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>, sqrt_p_x64: u128, delta_l: u128): u128 {
    <b>assert</b>!(delta_l &lt;= self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_EInsufficientLiquidity">EInsufficientLiquidity</a>);
    <b>if</b> (sqrt_p_x64 &lt;= self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>) {
        <b>return</b> 0
    };
    <b>if</b> (sqrt_p_x64 &gt; self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>) {
        <b>return</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_by_liquidity_x64">y_by_liquidity_x64</a>(self, self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pb_x64">sqrt_pb_x64</a>, delta_l)
    };
    // L * (sqrt(p) - sqrt(pa))
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a> = (delta_l <b>as</b> u256) * ((sqrt_p_x64 - self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pa_x64">sqrt_pa_x64</a>) <b>as</b> u256);
    // In some extreme cases the calculation can overflow. The AMM itself can never
    // reach such a state, but in cases where we're doing some kind of a simulation it's possible in
    // principle.
    // We handle this by limiting the result to `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_U128_MAX">U128_MAX</a>` (which is the max amount of token in
    // existence).
    (util::min_u256(<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a>, (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_U128_MAX">U128_MAX</a> <b>as</b> u256)) <b>as</b> u128)
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_x_x64"></a>

## Function `x_x64`

Calculate the amount of X in the LP position for a given price.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, sqrt_p_x64: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>, sqrt_p_x64: u128): u128 {
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_by_liquidity_x64">x_by_liquidity_x64</a>(self, sqrt_p_x64, self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>)
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_y_x64"></a>

## Function `y_x64`

Calculate the amount of Y in the LP position for a given price.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, sqrt_p_x64: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>, sqrt_p_x64: u128): u128 {
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_by_liquidity_x64">y_by_liquidity_x64</a>(self, sqrt_p_x64, self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>)
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_assets_x128"></a>

## Function `assets_x128`

Calculate the total value of assets for the whole position (incl. LP and collateral)
for a given price, expressed in Y.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_assets_x128">assets_x128</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p_x128: u256): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_assets_x128">assets_x128</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>, p_x128: u256): u256 {
    <b>let</b> p_x64 = p_x128 &gt;&gt; 64;
    <b>let</b> sqrt_p_x64 = (util::sqrt_u256(p_x128) <b>as</b> u128);
    <b>let</b> cx_x64 = (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> <b>as</b> u256) &lt;&lt; 64;
    <b>let</b> cy_x64 = (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> <b>as</b> u256) &lt;&lt; 64;
    // (x(p) + <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>) * p + y(p) + <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a> = (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a>(self, sqrt_p_x64) <b>as</b> u256);
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a> = (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a>(self, sqrt_p_x64) <b>as</b> u256);
    (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a> + cx_x64) * p_x64 + (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a> + cy_x64) &lt;&lt; 64
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_debt_x128"></a>

## Function `debt_x128`

Calculate the value of debt for the position for a given price, expressed in Y.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_debt_x128">debt_x128</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p_x128: u256): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_debt_x128">debt_x128</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>, p_x128: u256): u256 {
    <b>let</b> p_x64 = p_x128 &gt;&gt; 64;
    <b>let</b> dx_x64 = (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> <b>as</b> u256) &lt;&lt; 64;
    <b>let</b> dy_x128 = (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> <b>as</b> u256) &lt;&lt; 128;
    // <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> * p + <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>
    dx_x64 * p_x64 + dy_x128
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_margin_x64"></a>

## Function `margin_x64`

Calculate the margin level for the position at a given price.
If the debt is 0, returns <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_U128_MAX">U128_MAX</a></code> representing infinite margin.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p_x128: u256): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>, p_x128: u256): u128 {
    <b>if</b> (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> == 0 && self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> == 0) {
        <b>return</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_U128_MAX">U128_MAX</a>
    };
    <b>let</b> dx_x64 = (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> <b>as</b> u256) &lt;&lt; 64;
    <b>let</b> dy_x128 = (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> <b>as</b> u256) &lt;&lt; 128;
    <b>let</b> cx_x64 = (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> <b>as</b> u256) &lt;&lt; 64;
    <b>let</b> cy_x128 = (self.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> <b>as</b> u256) &lt;&lt; 128;
    <b>let</b> sqrt_p_x64 = (util::sqrt_u256(p_x128) <b>as</b> u128);
    <b>let</b> p_x64 = (p_x128 &gt;&gt; 64) <b>as</b> u256;
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a> = <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a>(self, sqrt_p_x64) <b>as</b> u256;
    <b>let</b> y_x128 = (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a>(self, sqrt_p_x64) <b>as</b> u256) &lt;&lt; 64;
    <b>let</b> asset_value_x128 = (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a> + cx_x64) * p_x64 + y_x128 + cy_x128;
    <b>let</b> debt_value_x64 = (dx_x64 * p_x64 + dy_x128) &gt;&gt; 64;
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a> = (asset_value_x128 / debt_value_x64);
    (util::min_u256(<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a>, (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_U128_MAX">U128_MAX</a> <b>as</b> u256)) <b>as</b> u128)
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_mul_x64"></a>

## Function `mul_x64`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_mul_x64">mul_x64</a>(a_x64: u128, b_x64: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_mul_x64">mul_x64</a>(a_x64: u128, b_x64: u128): u128 {
    ((a_x64 <b>as</b> u256) * (b_x64 <b>as</b> u256) &gt;&gt; 64) <b>as</b> u128
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_sqrt_pl_x64"></a>

## Function `sqrt_pl_x64`

Calculate the price that is delta bps away from the given price (lower bound).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pl_x64">sqrt_pl_x64</a>(sqrt_p_x64: u128, delta_bps: u16): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_pl_x64">sqrt_pl_x64</a>(sqrt_p_x64: u128, delta_bps: u16): u128 {
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_mul_x64">mul_x64</a>(
            sqrt_p_x64,
            util::sqrt_u256((10000 - (delta_bps <b>as</b> u256)) &lt;&lt; 128) <b>as</b> u128
        ) / 100
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_sqrt_ph_x64"></a>

## Function `sqrt_ph_x64`

Calculate the price that is delta bps away from the given price (upper bound).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_ph_x64">sqrt_ph_x64</a>(sqrt_p_x64: u128, delta_bps: u16): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_sqrt_ph_x64">sqrt_ph_x64</a>(sqrt_p_x64: u128, delta_bps: u16): u128 {
    <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_mul_x64">mul_x64</a>(
            sqrt_p_x64,
            util::sqrt_u256((10000 + (delta_bps <b>as</b> u256)) &lt;&lt; 128) <b>as</b> u128
        ) / 100
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_calc_max_deleverage_delta_l"></a>

## Function `calc_max_deleverage_delta_l`

Calculate the <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a></code> by which the LP position must be reduced so that the margin level goes above
the deleverage threshold after debt repayment w.r.t. the <code>base_deleverage_factor</code>.
It assumes that conversion between X and Y is not done, so <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a></code> is only repaid using available
<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a></code> and the X amounts from the LP position, and same for Y.

The <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a></code> is calculated so that the position reaches a target margin level after the debt
repayment. The target margin level is defined as the margin level that would be reached if
<code>deleverage_factor_bps</code> of the debt is repaid at the moment margin falls below the deleverage
threshold. This means that the returned <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a></code> increases as the margin level decreases.

When extra collateral <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a></code> or <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a></code> is present, it is assumed that this will also be used to
repay debt, and together with returned <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a></code> will amount to <code>deleverage_factor_bps</code> of debt
repaid.

Summary:
- when <code>M &gt;= Md</code> returns 0
- when <code>Md &gt; M &gt; 1</code> returns <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a></code> such that the position reaches a constant target margin after
the deleverage
- when <code>1 &gt;= M</code> returns <code>position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a></code>
- if the position has no debt, returns 0
- when extra collateral <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a></code> or <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a></code> is present, it is assumed that this will also be used to
repay debt, and together with returned <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a></code> will amount to <code>deleverage_factor_bps</code> of debt
repaid
- if extra collateral <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a></code> and <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a></code> are enough to repay all debt, returns 0
- if the target debt value cannot be repaid with position's total liquidity and extra collateral
(<code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a></code> and <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a></code>), returns <code>position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a></code>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_max_deleverage_delta_l">calc_max_deleverage_delta_l</a>(position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p_x128: u256, deleverage_margin_bps: u16, base_deleverage_factor_bps: u16): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_max_deleverage_delta_l">calc_max_deleverage_delta_l</a>(
    position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>,
    p_x128: u256,
    deleverage_margin_bps: u16,
    base_deleverage_factor_bps: u16,
): u128 {
    <b>if</b> (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> == 0 && position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> == 0) {
        <b>return</b> 0
    };
    <b>let</b> deleverage_margin_x64 = (((deleverage_margin_bps <b>as</b> u256) &lt;&lt; 64) / 10000); // 64.64
    <b>let</b> current_margin_x64 = <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a>(position, p_x128) <b>as</b> u256; // 64.64
    <b>let</b> base_deleverage_factor_x64 = util::min_u256(
        ((base_deleverage_factor_bps <b>as</b> u256) &lt;&lt; 64) / 10000,
        1 &lt;&lt; 64,
    ); // 1.64
    <b>if</b> (current_margin_x64 &gt;= deleverage_margin_x64) {
        <b>return</b> 0
    };
    <b>if</b> (current_margin_x64 &lt;= (1 &lt;&lt; 64)) {
        <b>return</b> position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>
    };
    <b>let</b> p_x64 = (p_x128 &gt;&gt; 64) <b>as</b> u128; // 64.64
    <b>let</b> sqrt_p_x64 = util::sqrt_u256(p_x128) <b>as</b> u128;
    // handle `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>` and `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>`
    <b>let</b> (dx_x64, dy_x64, deleverage_factor_x64) = {
        // f = (Md - M + base_deleverage_factor * (M - 1)) / (Md - 1)
        <b>let</b> num = (
            (deleverage_margin_x64 &lt;&lt; 64) - (current_margin_x64 &lt;&lt; 64) +
                base_deleverage_factor_x64 * (current_margin_x64 - (1 &lt;&lt; 64)),
        );
        <b>let</b> denom = (deleverage_margin_x64 - (1 &lt;&lt; 64));
        <b>let</b> target_deleverage_factor_x64 = (num / denom <b>as</b> u256); // 0.64
        <b>let</b> original_debt_val_x64 =
            (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> <b>as</b> u256) * (p_x64 <b>as</b> u256) + ((position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> <b>as</b> u256) &lt;&lt; 64); // 128.64
        <b>let</b> can_repay_x = u64::min(position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>, position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a>);
        <b>let</b> can_repay_y = u64::min(position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>, position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a>);
        <b>let</b> value_repaid_x64 =
            (can_repay_x <b>as</b> u256) * (p_x64 <b>as</b> u256) + ((can_repay_y <b>as</b> u256) &lt;&lt; 64); // 128.64
        // f' = (D * f - R) / (D - R)
        <b>if</b> ((value_repaid_x64 &lt;&lt; 64) &gt;= original_debt_val_x64 * target_deleverage_factor_x64) {
            <b>return</b> 0
        };
        <b>if</b> (original_debt_val_x64 - value_repaid_x64 == 0) {
            <b>return</b> 0
        };
        <b>let</b> remaining_deleverage_factor_x64 = (
            (
                (original_debt_val_x64 * target_deleverage_factor_x64 - (value_repaid_x64 &lt;&lt; 64)) /
                (original_debt_val_x64 - value_repaid_x64),
            ) <b>as</b> u256,
        ); // 0.64
        <b>let</b> dx_x64 = ((position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> - can_repay_x) <b>as</b> u128) &lt;&lt; 64;
        <b>let</b> dy_x64 = ((position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> - can_repay_y) <b>as</b> u128) &lt;&lt; 64;
        (dx_x64, dy_x64, remaining_deleverage_factor_x64)
    };
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a> = <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a>(position, sqrt_p_x64); // 64.64
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a> = <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a>(position, sqrt_p_x64); // 64.64
    <b>let</b> lp_val_x64 = (((<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a> <b>as</b> u256) * (p_x64 <b>as</b> u256)) &gt;&gt; 64) + (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a> <b>as</b> u256); // 128.64
    <b>let</b> debt_val_x64 = (((dx_x64 <b>as</b> u256) * (p_x64 <b>as</b> u256)) &gt;&gt; 64) + (dy_x64 <b>as</b> u256); // 128.64
    <b>let</b> to_deleverage_val_x64 = util::divide_and_round_up_u256(
        debt_val_x64 * deleverage_factor_x64,
        1 &lt;&lt; 64,
    ); // 128.64
    <b>let</b> deleverage_l = <b>if</b> (to_deleverage_val_x64 &gt;= lp_val_x64) {
        position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>
    } <b>else</b> {
        (
            util::divide_and_round_up_u256(
                (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a> <b>as</b> u256) * ((to_deleverage_val_x64 &lt;&lt; 64) / lp_val_x64),
                1 &lt;&lt; 64,
            ) <b>as</b> u128,
        )
    };
    <b>let</b> got_x_x64 = <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_by_liquidity_x64">x_by_liquidity_x64</a>(position, sqrt_p_x64, deleverage_l);
    <b>let</b> got_y_x64 = <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_by_liquidity_x64">y_by_liquidity_x64</a>(position, sqrt_p_x64, deleverage_l);
    <b>if</b> (got_x_x64 &lt;= dx_x64 && got_y_x64 &lt;= dy_x64) {
        deleverage_l
    } <b>else</b> <b>if</b> (got_x_x64 &gt;= dx_x64 && got_y_x64 &gt;= dy_x64) {
        // this shouldn't be possible because it would imply M &lt; 1, but <b>for</b> completeness,
        // find minimum `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>` such that `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>` and `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>` are fully repaid
        <b>if</b> (got_x_x64 == dx_x64 || got_y_x64 == dy_x64) {
            <b>return</b> deleverage_l
        };
        <b>let</b> deleverage_l = <b>if</b> (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_mul_x64">mul_x64</a>(got_x_x64, dy_x64) &gt; <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_mul_x64">mul_x64</a>(got_y_x64, dx_x64)) {
            util::saturating_muldiv_round_up_u128(position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>, dy_x64, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a>)
        } <b>else</b> {
            util::saturating_muldiv_round_up_u128(position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>, dx_x64, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a>)
        };
        util::min_u128(deleverage_l, position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>)
    } <b>else</b> <b>if</b> (got_x_x64 &lt; dx_x64) {
        // got_x &lt; <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> and got_y &gt;= <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>
        // since got_y &gt;= <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a>, getting more y won't help towards repaying debt value
        // so we need to get more x
        <b>let</b> need_x_x64 = util::muldiv_round_up_u128(got_y_x64 - dy_x64, 1 &lt;&lt; 64, p_x64) + got_x_x64;
        <b>if</b> (need_x_x64 &gt;= <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a> || <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a> == 0) {
            <b>return</b> position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>
        };
        util::muldiv_round_up_u128(position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>, need_x_x64, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_x_x64">x_x64</a>)
    } <b>else</b> {
        // got_y &lt; <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> and got_x &gt;= <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a>
        // similar to the above case, we need to get more y
        <b>let</b> need_y_x64 = util::muldiv_round_up_u128(got_x_x64 - dx_x64, p_x64, 1 &lt;&lt; 64) + got_y_x64;
        <b>if</b> (need_y_x64 &gt;= <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a> || <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a> == 0) {
            <b>return</b> position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>
        };
        util::muldiv_round_up_u128(position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a>, need_y_x64, <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_y_x64">y_x64</a>)
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_calc_max_liq_factor_x64"></a>

## Function `calc_max_liq_factor_x64`

Calculate the maximum factor by which the debt can be liquidated (% of debt amount).
0 means no liquidation and <code>1 &lt;&lt; 64</code> means full liquidation (Q64.64 format).

The factor is calculated so that the position is above the liquidation threshold after the
liquidation. The target margin level is one that would be reached if <code>base_liq_factor_bps</code> of
the debt is repaid at the moment margin falls below the liquidation threshold. This means that
the returned factor increases as the margin level decreases.

If the margin level is below the half-way point between the liquidation threshold and the
critical margin level, the factor is 1. The critical margin level is defined as the margin
level at which the position cannot be liquidated without incurring bad debt (while respecting
the liquidation bonus, <code>Mc = 1 + liq_bonus</code>).

If the margin level is below the critical margin level, then the factor is calculated so that
the maximum possible amount of debt is liquidated while making sure there's enough collateral
to cover the liquidation bonus. This means that as the current margin falls below the critical
margin level, the factor decreases.

Summary:
- when <code>M &gt;= Ml</code> returns 0
- when <code>Ml &gt; M &gt; (Ml + Mc) / 2</code> returns a factor so that the position reaches a constant target
margin after liquidation
- when <code>(Ml + Mc) / 2 &gt;= M &gt;= Mc</code> returns 1
- when <code>Mc &gt; M</code> returns a factor so that maximum possible debt is liquidated while respecting
the liquidation bonus


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_max_liq_factor_x64">calc_max_liq_factor_x64</a>(current_margin_x64: u128, liq_margin_bps: u16, liq_bonus_bps: u16, base_liq_factor_bps: u16): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_max_liq_factor_x64">calc_max_liq_factor_x64</a>(
    current_margin_x64: u128,
    liq_margin_bps: u16,
    liq_bonus_bps: u16,
    base_liq_factor_bps: u16,
): u128 {
    <b>let</b> current_margin_x64 = current_margin_x64 <b>as</b> u256;
    <b>let</b> liq_margin_x64 = ((liq_margin_bps <b>as</b> u256) &lt;&lt; 64) / 10000;
    <b>let</b> crit_margin_x64 = ((10000 &lt;&lt; 64) + ((liq_bonus_bps <b>as</b> u256) &lt;&lt; 64)) / 10000;
    <b>let</b> base_liq_factor_x64 = ((base_liq_factor_bps <b>as</b> u256) &lt;&lt; 64) / 10000;
    // <b>for</b> sanity, normally `liq_margin_x64 &gt; crit_margin_x64`
    <b>let</b> liq_margin_x64 = util::max_u256(liq_margin_x64, crit_margin_x64);
    <b>let</b> base_liq_factor_x64 = util::min_u256(base_liq_factor_x64, 1 &lt;&lt; 64);
    <b>if</b> (current_margin_x64 &gt;= liq_margin_x64) {
        0
    } <b>else</b> <b>if</b> (current_margin_x64 &lt; crit_margin_x64) {
        // M / Mc
        ((current_margin_x64 &lt;&lt; 64) / crit_margin_x64) <b>as</b> u128
    } <b>else</b> <b>if</b> (liq_margin_x64 - current_margin_x64 &gt;= current_margin_x64 - crit_margin_x64) {
        // M &lt; (Ml + Mc) / 2
        1 &lt;&lt; 64
    } <b>else</b> {
        // (Ml - M + base_liq_factor * (M - Mc)) / (Ml - Mc)
        <b>let</b> num = (
            (liq_margin_x64 &lt;&lt; 64) - (current_margin_x64 &lt;&lt; 64) +
                base_liq_factor_x64 * (current_margin_x64 - crit_margin_x64),
        );
        <b>let</b> denom = (liq_margin_x64 - crit_margin_x64);
        (num / denom) <b>as</b> u128
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_is_fully_deleveraged"></a>

## Function `is_fully_deleveraged`

Returns <code><b>true</b></code> if the position is "fully deleveraged".
A position is considered fully deleveraged when all the liquidity has been withdrawn
from the AMM pool and the debt that can be repaid directly (i.e. <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> -&gt; <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a></code>, <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> -&gt; <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a></code>)
has been repaid.
If this is true, then <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> &gt; 0</code> implies <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> = 0</code> and <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> &gt; 0</code> implies <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> = 0</code>.
Also, if <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> &gt; 0 && <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> &gt; 0</code> then <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> == 0 && <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> == 0</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_is_fully_deleveraged">is_fully_deleveraged</a>(position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_is_fully_deleveraged">is_fully_deleveraged</a>(position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>): bool {
    <b>if</b> (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_l">l</a> &gt; 0) {
        <b>return</b> <b>false</b>
    };
    <b>if</b> (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> &gt; 0 && position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> &gt; 0) {
        <b>return</b> <b>false</b>
    };
    <b>if</b> (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> &gt; 0 && position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> &gt; 0) {
        <b>return</b> <b>false</b>
    };
    <b>true</b>
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_margin_below_threshold"></a>

## Function `margin_below_threshold`

Returns <code><b>true</b></code> if position's margin is below the given threshold.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_below_threshold">margin_below_threshold</a>(position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p_x128: u256, margin_threshold_bps: u16): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_below_threshold">margin_below_threshold</a>(
    position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>,
    p_x128: u256,
    margin_threshold_bps: u16,
): bool {
    <b>let</b> current_margin_x64 = <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a>(position, p_x128);
    <b>let</b> threshold_margin_x64 = ((margin_threshold_bps <b>as</b> u128) &lt;&lt; 64) / 10000;
    current_margin_x64 &lt; threshold_margin_x64
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_calc_liquidate_col_x"></a>

## Function `calc_liquidate_col_x`

Liquidates the collateral X from the position for the given <code>repayment_amt_y</code>.
Returns <code>(repayment_amt_y, reward_amt_x)</code> where:
- <code>repayment_amt_y</code> is the amount of Y repaid (up to <code>max_repayment_amt_y</code>)
- <code>reward_amt_x</code> is the amount of X returned to the liquidator.

Notes:
- Returns <code>(0, 0)</code> when the position can't be liquidated:
- It's not below the liquidation threshold
- It's not "fully deleveraged"
- <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> == 0</code>
- The position is liquidated so that the margin level is above the liquidation threshold after
the liquidation, if possible for the given <code>max_repayment_amt_y</code> and available collateral.
- Always respects the liquidation bonus, even if there's not enough collateral to cover a full
liquidation.
- Never aborts.

See documentation for <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_max_liq_factor_x64">calc_max_liq_factor_x64</a></code> for more details on how the liquidation factor
is calculated.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_liquidate_col_x">calc_liquidate_col_x</a>(position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p_x128: u256, max_repayment_amt_y: u64, liq_margin_bps: u16, liq_bonus_bps: u16, base_liq_factor_bps: u16): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_liquidate_col_x">calc_liquidate_col_x</a>(
    position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>,
    p_x128: u256,
    max_repayment_amt_y: u64,
    liq_margin_bps: u16,
    liq_bonus_bps: u16,
    base_liq_factor_bps: u16,
): (u64, u64) {
    <b>if</b> (!<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_below_threshold">margin_below_threshold</a>(position, p_x128, liq_margin_bps)) {
        <b>return</b> (0, 0)
    };
    <b>if</b> (!<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_is_fully_deleveraged">is_fully_deleveraged</a>(position)) {
        <b>return</b> (0, 0)
    };
    <b>if</b> (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> == 0 || max_repayment_amt_y == 0) {
        <b>return</b> (0, 0)
    };
    // after the above, we know that `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> &gt; 0`, `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> == 0`,`<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> &gt; 0` and `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> == 0`
    <b>let</b> p_x64 = p_x128 &gt;&gt; 64; // 64.64
    <b>let</b> liq_bonus_x64 = ((liq_bonus_bps <b>as</b> u256) &lt;&lt; 64) / 10000; // 16.64
    <b>let</b> debt_value_x64 = (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> <b>as</b> u256) &lt;&lt; 64; // 64.64
    <b>let</b> asset_value_x64 = (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> <b>as</b> u256) * p_x64; // 128.64
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a> = util::min_u256(
        (asset_value_x64 &lt;&lt; 64) / debt_value_x64,
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_U128_MAX">U128_MAX</a> <b>as</b> u256,
    ); // 64.64
    // calc repayment value
    <b>let</b> max_repayment_value_x64 = (max_repayment_amt_y <b>as</b> u256) &lt;&lt; 64; // 64.64
    <b>let</b> possible_repayment_factor_x64 = (max_repayment_value_x64 &lt;&lt; 64) / debt_value_x64; // 64.64
    <b>let</b> max_liq_factor_x64 =
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_max_liq_factor_x64">calc_max_liq_factor_x64</a>(
            (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a> <b>as</b> u128),
            liq_margin_bps,
            liq_bonus_bps,
            base_liq_factor_bps,
        ) <b>as</b> u256; // 64.64
    <b>let</b> liq_factor_x64 = util::min_u256(possible_repayment_factor_x64, max_liq_factor_x64); // 64.64
    <b>let</b> repayment_value_x64 = (liq_factor_x64 * debt_value_x64) &gt;&gt; 64; // 64.64
    <b>let</b> repayment_value_with_bonus_x64 = (repayment_value_x64 * ((1 &lt;&lt; 64) + liq_bonus_x64)) &gt;&gt; 64; // 81.64
    // calc repayment and reward amt
    <b>let</b> repayment_amt_y =
        util::min_u256(
            util::divide_and_round_up_u256(repayment_value_x64, 1 &lt;&lt; 64),
            max_repayment_amt_y <b>as</b> u256,
        ) <b>as</b> u64;
    <b>let</b> reward_amt_x =
        util::min_u256(
            util::divide_and_round_up_u256(
                repayment_value_with_bonus_x64 * (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> <b>as</b> u256),
                asset_value_x64,
            ),
            position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> <b>as</b> u256,
        ) <b>as</b> u64;
    (repayment_amt_y, reward_amt_x)
}
</code></pre>



</details>

<a name="kai_leverage_position_model_clmm_calc_liquidate_col_y"></a>

## Function `calc_liquidate_col_y`

Liquidates the collateral Y from the position for the given <code>repayment_amt_x</code>.
Returns <code>(repayment_amt_x, reward_amt_y)</code> where <code>repayment_amt_x</code> is the amount of X repaid
(up to given <code>max_repayment_amt_x</code>) and <code>reward_amt_y</code> is the amount of Y returned to the
liquidator.

Note:
- Returns <code>(0, 0)</code> when the position can't be liquidated:
- It's not below the liquidation threshold
- It's not "fully deleveraged"
- <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> == 0</code>
- The position is liquidated so that the margin level is above the liquidation threshold after
the liquidation, if possible for the given <code>max_repayment_amt_x</code> and available collateral.
- Always respects the liquidation bonus, even if there's not enough collateral to cover a full
liquidation.
- Never aborts.

See documentation for <code><a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_max_liq_factor_x64">calc_max_liq_factor_x64</a></code> for more details on how the liquidation factor
is calculated.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_liquidate_col_y">calc_liquidate_col_y</a>(position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p_x128: u256, max_repayment_amt_x: u64, liq_margin_bps: u16, liq_bonus_bps: u16, base_liq_factor_bps: u16): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_liquidate_col_y">calc_liquidate_col_y</a>(
    position: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">PositionModel</a>,
    p_x128: u256,
    max_repayment_amt_x: u64,
    liq_margin_bps: u16,
    liq_bonus_bps: u16,
    base_liq_factor_bps: u16,
): (u64, u64) {
    <b>if</b> (!<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_below_threshold">margin_below_threshold</a>(position, p_x128, liq_margin_bps)) {
        <b>return</b> (0, 0)
    };
    <b>if</b> (!<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_is_fully_deleveraged">is_fully_deleveraged</a>(position)) {
        <b>return</b> (0, 0)
    };
    <b>if</b> (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> == 0 || max_repayment_amt_x == 0) {
        <b>return</b> (0, 0)
    };
    // after the above, we know that `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> &gt; 0`, `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dy">dy</a> == 0`,`<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> &gt; 0` and `<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cx">cx</a> == 0`
    <b>let</b> p_x64 = p_x128 &gt;&gt; 64; // 64.64
    <b>let</b> liq_bonus_x64 = ((liq_bonus_bps <b>as</b> u256) &lt;&lt; 64) / 10000; // 16.64
    <b>let</b> debt_value_x64 = (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> <b>as</b> u256) * p_x64; // 128.64
    <b>let</b> asset_value_x64 = (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> <b>as</b> u256) &lt;&lt; 64; // 64.64
    <b>let</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a> = util::min_u256(
        (asset_value_x64 &lt;&lt; 64) / debt_value_x64,
        (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_U128_MAX">U128_MAX</a> <b>as</b> u256),
    ); // 64.64
    // calc repayment value
    <b>let</b> possible_repayment_factor_x64 =
        ((max_repayment_amt_x <b>as</b> u256) &lt;&lt; 64) / (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> <b>as</b> u256); // 64.64
    <b>let</b> max_liq_factor_x64 = (
        <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_calc_max_liq_factor_x64">calc_max_liq_factor_x64</a>(
            (<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_margin_x64">margin_x64</a> <b>as</b> u128),
            liq_margin_bps,
            liq_bonus_bps,
            base_liq_factor_bps,
        ) <b>as</b> u256,
    ); // 64.64
    <b>let</b> liq_factor_x64 = util::min_u256(possible_repayment_factor_x64, max_liq_factor_x64); // 64.64
    <b>let</b> repayment_value_x64 = (liq_factor_x64 * debt_value_x64) &gt;&gt; 64; // 64.64
    <b>let</b> repayment_value_with_bonus_x64 = (repayment_value_x64 * ((1 &lt;&lt; 64) + liq_bonus_x64)) &gt;&gt; 64; // 81.64
    // calc repayment and reward amt
    <b>let</b> repayment_amt_x =
        util::min_u256(
            util::divide_and_round_up_u256(liq_factor_x64 * (position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_dx">dx</a> <b>as</b> u256), 1 &lt;&lt; 64),
            max_repayment_amt_x <b>as</b> u256,
        ) <b>as</b> u64;
    <b>let</b> reward_amt_y =
        util::min_u256(
            util::divide_and_round_up_u256(repayment_value_with_bonus_x64, 1 &lt;&lt; 64),
            position.<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_cy">cy</a> <b>as</b> u256,
        ) <b>as</b> u64;
    (repayment_amt_x, reward_amt_y)
}
</code></pre>



</details>

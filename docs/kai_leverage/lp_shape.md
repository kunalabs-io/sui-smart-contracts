
<a name="kai_leverage_lp_shape_clmm"></a>

# Module `kai_leverage::lp_shape_clmm`

Geometry of a CLMM LP position: price range bounds and liquidity.
A micro-leaf shared by position orchestration and model math.


-  [Struct `LpShape`](#kai_leverage_lp_shape_clmm_LpShape)
-  [Constants](#@Constants_0)
-  [Function `new`](#kai_leverage_lp_shape_clmm_new)
-  [Function `sqrt_pa_x64`](#kai_leverage_lp_shape_clmm_sqrt_pa_x64)
-  [Function `sqrt_pb_x64`](#kai_leverage_lp_shape_clmm_sqrt_pb_x64)
-  [Function `l`](#kai_leverage_lp_shape_clmm_l)


<pre><code></code></pre>



<a name="kai_leverage_lp_shape_clmm_LpShape"></a>

## Struct `LpShape`

Geometry of a CLMM LP position: price range bounds and liquidity.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">LpShape</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pa_x64">sqrt_pa_x64</a>: u128</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pb_x64">sqrt_pb_x64</a>: u128</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_l">l</a>: u128</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_lp_shape_clmm_EInvalidLpShape"></a>

The LP shape's price range bounds are not strictly increasing.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_EInvalidLpShape">EInvalidLpShape</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_lp_shape_clmm_new"></a>

## Function `new`

Create an <code><a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">LpShape</a></code>, asserting the price range bounds are ordered.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_new">new</a>(<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pa_x64">sqrt_pa_x64</a>: u128, <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pb_x64">sqrt_pb_x64</a>: u128, <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_l">l</a>: u128): <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">kai_leverage::lp_shape_clmm::LpShape</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_new">new</a>(<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pa_x64">sqrt_pa_x64</a>: u128, <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pb_x64">sqrt_pb_x64</a>: u128, <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_l">l</a>: u128): <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">LpShape</a> {
    <b>assert</b>!(<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pa_x64">sqrt_pa_x64</a> &lt; <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pb_x64">sqrt_pb_x64</a>, <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_EInvalidLpShape">EInvalidLpShape</a>);
    <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">LpShape</a> { <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pa_x64">sqrt_pa_x64</a>, <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pb_x64">sqrt_pb_x64</a>, <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_l">l</a> }
}
</code></pre>



</details>

<a name="kai_leverage_lp_shape_clmm_sqrt_pa_x64"></a>

## Function `sqrt_pa_x64`

Lower bound price sqrt in Q64.64.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pa_x64">sqrt_pa_x64</a>(self: &<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">kai_leverage::lp_shape_clmm::LpShape</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pa_x64">sqrt_pa_x64</a>(self: &<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">LpShape</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pa_x64">sqrt_pa_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_lp_shape_clmm_sqrt_pb_x64"></a>

## Function `sqrt_pb_x64`

Upper bound price sqrt in Q64.64.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pb_x64">sqrt_pb_x64</a>(self: &<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">kai_leverage::lp_shape_clmm::LpShape</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pb_x64">sqrt_pb_x64</a>(self: &<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">LpShape</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_sqrt_pb_x64">sqrt_pb_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_lp_shape_clmm_l"></a>

## Function `l`

LP position liquidity.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_l">l</a>(self: &<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">kai_leverage::lp_shape_clmm::LpShape</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_l">l</a>(self: &<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_LpShape">LpShape</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/lp_shape.md#kai_leverage_lp_shape_clmm_l">l</a>
}
</code></pre>



</details>

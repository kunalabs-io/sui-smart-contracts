
<a name="kai_leverage_util"></a>

# Module `kai_leverage::util`

Utility functions for mathematical operations and time handling.


-  [Function `muldiv`](#kai_leverage_util_muldiv)
-  [Function `muldiv_round_up`](#kai_leverage_util_muldiv_round_up)
-  [Function `muldiv_u128`](#kai_leverage_util_muldiv_u128)
-  [Function `muldiv_round_up_u128`](#kai_leverage_util_muldiv_round_up_u128)
-  [Function `saturating_muldiv_round_up_u128`](#kai_leverage_util_saturating_muldiv_round_up_u128)
-  [Function `divide_and_round_up_u128`](#kai_leverage_util_divide_and_round_up_u128)
-  [Function `divide_and_round_up_u256`](#kai_leverage_util_divide_and_round_up_u256)
-  [Function `abs_diff`](#kai_leverage_util_abs_diff)
-  [Function `min_u128`](#kai_leverage_util_min_u128)
-  [Function `max_u128`](#kai_leverage_util_max_u128)
-  [Function `min_u256`](#kai_leverage_util_min_u256)
-  [Function `max_u256`](#kai_leverage_util_max_u256)
-  [Function `log2_u256`](#kai_leverage_util_log2_u256)
-  [Function `sqrt_u256`](#kai_leverage_util_sqrt_u256)
-  [Function `timestamp_sec`](#kai_leverage_util_timestamp_sec)


<pre><code><b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
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



<a name="kai_leverage_util_muldiv"></a>

## Function `muldiv`

Multiply and divide u64 values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_muldiv">muldiv</a>(a: u64, b: u64, c: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_muldiv">muldiv</a>(a: u64, b: u64, c: u64): u64 {
    (((a <b>as</b> u128) * (b <b>as</b> u128)) / (c <b>as</b> u128)) <b>as</b> u64
}
</code></pre>



</details>

<a name="kai_leverage_util_muldiv_round_up"></a>

## Function `muldiv_round_up`

Multiply and divide with rounding up.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_muldiv_round_up">muldiv_round_up</a>(a: u64, b: u64, c: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_muldiv_round_up">muldiv_round_up</a>(a: u64, b: u64, c: u64): u64 {
    <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_divide_and_round_up_u128">divide_and_round_up_u128</a>(
        (a <b>as</b> u128) * (b <b>as</b> u128),
        c <b>as</b> u128,
    ) <b>as</b> u64
}
</code></pre>



</details>

<a name="kai_leverage_util_muldiv_u128"></a>

## Function `muldiv_u128`

Multiply and divide u128 values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_muldiv_u128">muldiv_u128</a>(a: u128, b: u128, c: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_muldiv_u128">muldiv_u128</a>(a: u128, b: u128, c: u128): u128 {
    (((a <b>as</b> u256) * (b <b>as</b> u256)) / (c <b>as</b> u256)) <b>as</b> u128
}
</code></pre>



</details>

<a name="kai_leverage_util_muldiv_round_up_u128"></a>

## Function `muldiv_round_up_u128`

Multiply and divide u128 values with rounding up.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_muldiv_round_up_u128">muldiv_round_up_u128</a>(a: u128, b: u128, c: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_muldiv_round_up_u128">muldiv_round_up_u128</a>(a: u128, b: u128, c: u128): u128 {
    <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_divide_and_round_up_u256">divide_and_round_up_u256</a>(
        (a <b>as</b> u256) * (b <b>as</b> u256),
        c <b>as</b> u256,
    ) <b>as</b> u128
}
</code></pre>



</details>

<a name="kai_leverage_util_saturating_muldiv_round_up_u128"></a>

## Function `saturating_muldiv_round_up_u128`

Saturating multiply and divide with rounding up.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_saturating_muldiv_round_up_u128">saturating_muldiv_round_up_u128</a>(a: u128, b: u128, c: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_saturating_muldiv_round_up_u128">saturating_muldiv_round_up_u128</a>(a: u128, b: u128, c: u128): u128 {
    <b>let</b> res = <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_divide_and_round_up_u256">divide_and_round_up_u256</a>(
        (a <b>as</b> u256) * (b <b>as</b> u256),
        (c <b>as</b> u256),
    );
    <b>if</b> (res &gt; (1 &lt;&lt; 128) - 1) {
        ((1 &lt;&lt; 128) - 1) <b>as</b> u128
    } <b>else</b> {
        res <b>as</b> u128
    }
}
</code></pre>



</details>

<a name="kai_leverage_util_divide_and_round_up_u128"></a>

## Function `divide_and_round_up_u128`

Divide with rounding up for 128-bit values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_divide_and_round_up_u128">divide_and_round_up_u128</a>(a: u128, b: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_divide_and_round_up_u128">divide_and_round_up_u128</a>(a: u128, b: u128): u128 {
    <a href="../../dependencies/std/macros.md#std_macros_num_divide_and_round_up">std::macros::num_divide_and_round_up</a>!(a, b)
}
</code></pre>



</details>

<a name="kai_leverage_util_divide_and_round_up_u256"></a>

## Function `divide_and_round_up_u256`

Divide with rounding up for u256 values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_divide_and_round_up_u256">divide_and_round_up_u256</a>(a: u256, b: u256): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_divide_and_round_up_u256">divide_and_round_up_u256</a>(a: u256, b: u256): u256 {
    <a href="../../dependencies/std/macros.md#std_macros_num_divide_and_round_up">std::macros::num_divide_and_round_up</a>!(a, b)
}
</code></pre>



</details>

<a name="kai_leverage_util_abs_diff"></a>

## Function `abs_diff`

Calculate absolute difference between two numbers.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_abs_diff">abs_diff</a>(a: u64, b: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_abs_diff">abs_diff</a>(a: u64, b: u64): u64 {
    <b>if</b> (a &gt; b) a - b <b>else</b> b - a
}
</code></pre>



</details>

<a name="kai_leverage_util_min_u128"></a>

## Function `min_u128`

Get minimum of two 128-bit values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_min_u128">min_u128</a>(a: u128, b: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_min_u128">min_u128</a>(a: u128, b: u128): u128 {
    <b>if</b> (a &lt; b) a <b>else</b> b
}
</code></pre>



</details>

<a name="kai_leverage_util_max_u128"></a>

## Function `max_u128`

Get maximum of two 128-bit values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_max_u128">max_u128</a>(a: u128, b: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_max_u128">max_u128</a>(a: u128, b: u128): u128 {
    <b>if</b> (a &gt; b) a <b>else</b> b
}
</code></pre>



</details>

<a name="kai_leverage_util_min_u256"></a>

## Function `min_u256`

Get minimum of two 256-bit values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_min_u256">min_u256</a>(a: u256, b: u256): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_min_u256">min_u256</a>(a: u256, b: u256): u256 {
    <b>if</b> (a &lt; b) a <b>else</b> b
}
</code></pre>



</details>

<a name="kai_leverage_util_max_u256"></a>

## Function `max_u256`

Get maximum of two 256-bit values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_max_u256">max_u256</a>(a: u256, b: u256): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_max_u256">max_u256</a>(a: u256, b: u256): u256 {
    <b>if</b> (a &gt; b) a <b>else</b> b
}
</code></pre>



</details>

<a name="kai_leverage_util_log2_u256"></a>

## Function `log2_u256`

Calculate base-2 logarithm of a 256-bit value.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_log2_u256">log2_u256</a>(x: u256): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_log2_u256">log2_u256</a>(<b>mut</b> x: u256): u8 {
    <b>let</b> <b>mut</b> result = 0;
    <b>if</b> (x &gt;&gt; 128 &gt; 0) {
        x = x &gt;&gt; 128;
        result = result + 128;
    };
    <b>if</b> (x &gt;&gt; 64 &gt; 0) {
        x = x &gt;&gt; 64;
        result = result + 64;
    };
    <b>if</b> (x &gt;&gt; 32 &gt; 0) {
        x = x &gt;&gt; 32;
        result = result + 32;
    };
    <b>if</b> (x &gt;&gt; 16 &gt; 0) {
        x = x &gt;&gt; 16;
        result = result + 16;
    };
    <b>if</b> (x &gt;&gt; 8 &gt; 0) {
        x = x &gt;&gt; 8;
        result = result + 8;
    };
    <b>if</b> (x &gt;&gt; 4 &gt; 0) {
        x = x &gt;&gt; 4;
        result = result + 4;
    };
    <b>if</b> (x &gt;&gt; 2 &gt; 0) {
        x = x &gt;&gt; 2;
        result = result + 2;
    };
    <b>if</b> (x &gt;&gt; 1 &gt; 0) result = result + 1;
    result
}
</code></pre>



</details>

<a name="kai_leverage_util_sqrt_u256"></a>

## Function `sqrt_u256`

Calculate square root of a 256-bit value.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_sqrt_u256">sqrt_u256</a>(x: u256): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_sqrt_u256">sqrt_u256</a>(x: u256): u256 {
    <b>if</b> (x == 0) <b>return</b> 0;
    <b>let</b> <b>mut</b> result = 1 &lt;&lt; ((<a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_log2_u256">log2_u256</a>(x) &gt;&gt; 1) <b>as</b> u8);
    result = (result + x / result) &gt;&gt; 1;
    result = (result + x / result) &gt;&gt; 1;
    result = (result + x / result) &gt;&gt; 1;
    result = (result + x / result) &gt;&gt; 1;
    result = (result + x / result) &gt;&gt; 1;
    result = (result + x / result) &gt;&gt; 1;
    result = (result + x / result) &gt;&gt; 1;
    <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_min_u256">min_u256</a>(result, x / result)
}
</code></pre>



</details>

<a name="kai_leverage_util_timestamp_sec"></a>

## Function `timestamp_sec`

Get current clock timestamp in seconds.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_timestamp_sec">timestamp_sec</a>(clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util_timestamp_sec">timestamp_sec</a>(clock: &Clock): u64 {
    clock::timestamp_ms(clock) / 1000
}
</code></pre>



</details>

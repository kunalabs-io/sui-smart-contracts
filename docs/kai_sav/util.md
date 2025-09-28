
<a name="kai_sav_util"></a>

# Module `kai_sav::util`

Utility functions for mathematical operations and time handling.


-  [Function `timestamp_sec`](#kai_sav_util_timestamp_sec)
-  [Function `muldiv`](#kai_sav_util_muldiv)
-  [Function `muldiv_round_up`](#kai_sav_util_muldiv_round_up)


<pre><code><b>use</b> <a href="../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
</code></pre>



<a name="kai_sav_util_timestamp_sec"></a>

## Function `timestamp_sec`

Get current clock timestamp in seconds.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/util.md#kai_sav_util_timestamp_sec">timestamp_sec</a>(clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/util.md#kai_sav_util_timestamp_sec">timestamp_sec</a>(clock: &Clock): u64 {
    clock::timestamp_ms(clock) / 1000
}
</code></pre>



</details>

<a name="kai_sav_util_muldiv"></a>

## Function `muldiv`

Multiply and divide u64 values.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/util.md#kai_sav_util_muldiv">muldiv</a>(a: u64, b: u64, c: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/util.md#kai_sav_util_muldiv">muldiv</a>(a: u64, b: u64, c: u64): u64 {
    (((a <b>as</b> u128) * (b <b>as</b> u128)) / (c <b>as</b> u128) <b>as</b> u64)
}
</code></pre>



</details>

<a name="kai_sav_util_muldiv_round_up"></a>

## Function `muldiv_round_up`

Multiply and divide with rounding up.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/util.md#kai_sav_util_muldiv_round_up">muldiv_round_up</a>(a: u64, b: u64, c: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/util.md#kai_sav_util_muldiv_round_up">muldiv_round_up</a>(a: u64, b: u64, c: u64): u64 {
    <b>let</b> ab = (a <b>as</b> u128) * (b <b>as</b> u128);
    <b>let</b> c = (c <b>as</b> u128);
    <b>if</b> (ab % c == 0) {
        ((ab / c) <b>as</b> u64)
    } <b>else</b> {
        ((ab / c + 1) <b>as</b> u64)
    }
}
</code></pre>



</details>

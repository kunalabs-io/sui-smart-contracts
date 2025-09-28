
<a name="rate_limiter_sliding_sum_limiter"></a>

# Module `rate_limiter::sliding_sum_limiter`

Time-based rate limiter that enforces maximum sum limits over a sliding window.

Wraps the RingAggregator to provide time-based rate limiting functionality with
configurable maximum sum limits. Uses Sui's Clock object for position tracking
and enforces limits by aborting when the maximum sum would be exceeded.


<a name="@Examples_0"></a>

## Examples


```move
// Create rate limiter with 5-minute buckets, 12 buckets total (1 hour window)
let mut limiter = sliding_sum_limiter::new(
5 * 60 * 1000,  // 5 minutes per bucket
12,             // 12 buckets (1 hour total)
option::some(10000), // Maximum sum limit
&clock
);

// Consume values (will abort if limit exceeded)
limiter.consume(1000, &clock);  // Add 1000 to current bucket
limiter.consume(2000, &clock);  // Add 2000 to current bucket

// Check current state
let total = limiter.total_sum(); // Returns 3000
```


-  [Examples](#@Examples_0)
-  [Struct `SlidingSumLimiter`](#rate_limiter_sliding_sum_limiter_SlidingSumLimiter)
-  [Constants](#@Constants_1)
-  [Function `new`](#rate_limiter_sliding_sum_limiter_new)
-  [Function `ring_aggregator`](#rate_limiter_sliding_sum_limiter_ring_aggregator)
-  [Function `total_sum`](#rate_limiter_sliding_sum_limiter_total_sum)
-  [Function `max_sum_limit`](#rate_limiter_sliding_sum_limiter_max_sum_limit)
-  [Function `set_max_sum_limit`](#rate_limiter_sliding_sum_limiter_set_max_sum_limit)
-  [Function `consume`](#rate_limiter_sliding_sum_limiter_consume)


<pre><code><b>use</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator">rate_limiter::ring_aggregator</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
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



<a name="rate_limiter_sliding_sum_limiter_SlidingSumLimiter"></a>

## Struct `SlidingSumLimiter`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>: <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_1"></a>

## Constants


<a name="rate_limiter_sliding_sum_limiter_EMaxSumLimitExceeded"></a>



<pre><code>#[error]
<b>const</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_EMaxSumLimitExceeded">EMaxSumLimitExceeded</a>: vector&lt;u8&gt; = b"Max sum limit exceeded";
</code></pre>



<a name="rate_limiter_sliding_sum_limiter_new"></a>

## Function `new`

Create a new SlidingSumLimiter with the specified configuration.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_new">new</a>(bucket_width_ms: u64, bucket_count: u64, <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_new">new</a>(
    bucket_width_ms: u64,
    bucket_count: u64,
    <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>: Option&lt;u256&gt;,
    clock: &Clock,
): <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a> {
    <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a> {
        <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>: ring_aggregator::new_with_initial_position(
            bucket_width_ms,
            bucket_count,
            clock.timestamp_ms() <b>as</b> u256,
        ),
        <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>,
    }
}
</code></pre>



</details>

<a name="rate_limiter_sliding_sum_limiter_ring_aggregator"></a>

## Function `ring_aggregator`

Return a reference to the internal ring aggregator for inspection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>): &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>): &RingAggregator {
    &self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>
}
</code></pre>



</details>

<a name="rate_limiter_sliding_sum_limiter_total_sum"></a>

## Function `total_sum`

Return the total sum of all values currently in the sliding window.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>): u256 {
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a>()
}
</code></pre>



</details>

<a name="rate_limiter_sliding_sum_limiter_max_sum_limit"></a>

## Function `max_sum_limit`

Return the current maximum sum limit.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>): <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>): Option&lt;u256&gt; {
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>
}
</code></pre>



</details>

<a name="rate_limiter_sliding_sum_limiter_set_max_sum_limit"></a>

## Function `set_max_sum_limit`

Update the maximum sum limit for the limiter.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_set_max_sum_limit">set_max_sum_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>, <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_set_max_sum_limit">set_max_sum_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>, <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>: Option&lt;u256&gt;) {
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a> = <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>;
}
</code></pre>



</details>

<a name="rate_limiter_sliding_sum_limiter_consume"></a>

## Function `consume`

Consume a value and add it to the current time bucket, enforcing the maximum sum limit.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_consume">consume</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>, value: u64, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_consume">consume</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>, value: u64, clock: &Clock) {
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>.advance_and_add(clock.timestamp_ms() <b>as</b> u256, value);
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>.do_ref!(|<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>| {
        <b>assert</b>!(self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a>() &lt;= *<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>, <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_EMaxSumLimitExceeded">EMaxSumLimitExceeded</a>);
    });
}
</code></pre>



</details>

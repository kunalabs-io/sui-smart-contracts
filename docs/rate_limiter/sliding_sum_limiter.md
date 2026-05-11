
<a name="rate_limiter_sliding_sum_limiter"></a>

# Module `rate_limiter::sliding_sum_limiter`

Time-based rate limiter that enforces maximum sum limits over a sliding window.

Wraps the RingAggregator to provide time-based rate limiting functionality with
configurable maximum sum limits. Uses Sui's Clock object for position tracking
and enforces limits by aborting when the maximum sum would be exceeded.


<a name="@Cap_sizing_0"></a>

## Cap sizing


The window slides in discrete bucket steps, not continuously. An adversarial
caller timing a bucket boundary can extract up to ~2× <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a></code> over
approximately one window length: one full-cap call at the end of a bucket,
then another at the moment that bucket rolls out of the window (<code>(N - 1) × W</code>
later, where <code>N = bucket_count</code> and <code>W = bucket_width_ms</code>). The long-run
sustained rate converges to <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a> / (N × W)</code>.

Treat <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a></code> as the worst single-window burst that can be absorbed,
not as a long-term volume budget. Pick <code>N × W</code> (the total window length) to
match the detection / response time on whatever activity is being limited:
the burst that can occur before a response is bounded by ~2× cap, so the
window length determines how long an attacker has to wait between bursts.


<a name="@Examples_1"></a>

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


-  [Cap sizing](#@Cap_sizing_0)
-  [Examples](#@Examples_1)
-  [Struct `SlidingSumLimiter`](#rate_limiter_sliding_sum_limiter_SlidingSumLimiter)
-  [Constants](#@Constants_2)
-  [Function `new`](#rate_limiter_sliding_sum_limiter_new)
-  [Function `ring_aggregator`](#rate_limiter_sliding_sum_limiter_ring_aggregator)
-  [Function `total_sum`](#rate_limiter_sliding_sum_limiter_total_sum)
-  [Function `total_sum_at`](#rate_limiter_sliding_sum_limiter_total_sum_at)
-  [Function `max_sum_limit`](#rate_limiter_sliding_sum_limiter_max_sum_limit)
-  [Function `set_max_sum_limit`](#rate_limiter_sliding_sum_limiter_set_max_sum_limit)
-  [Function `advance`](#rate_limiter_sliding_sum_limiter_advance)
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

<a name="@Constants_2"></a>

## Constants


<a name="rate_limiter_sliding_sum_limiter_EMaxSumLimitExceeded"></a>



<pre><code>#[error]
<b>const</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_EMaxSumLimitExceeded">EMaxSumLimitExceeded</a>: vector&lt;u8&gt; = b"Max sum limit exceeded";
</code></pre>



<a name="rate_limiter_sliding_sum_limiter_new"></a>

## Function `new`

Create a new SlidingSumLimiter with the specified configuration.

See the module-level "Cap sizing" note: <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a></code> is a per-window
burst ceiling, not a smooth budget — worst-case extraction is ~2× cap
over roughly one window length (<code>bucket_count × bucket_width_ms</code>).


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

Return the cached total sum from the underlying ring aggregator.

**Caution:** this is a cached value from the last <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_consume">consume</a></code> or <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_advance">advance</a></code>
call. Buckets that should have rolled out since then are still counted.
For an accurate current-clock read, use <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum_at">total_sum_at</a>(clock)</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>): u256 {
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a>()
}
</code></pre>



</details>

<a name="rate_limiter_sliding_sum_limiter_total_sum_at"></a>

## Function `total_sum_at`

Compute the total sum that would be in the sliding window at the
current clock time, without mutating the limiter. Read-only and
always fresh.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum_at">total_sum_at</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum_at">total_sum_at</a>(self: &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>, clock: &Clock): u256 {
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum_at">total_sum_at</a>(clock.timestamp_ms() <b>as</b> u256)
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

See the module-level "Cap sizing" note: this is a per-window burst
ceiling, not a smooth budget.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_set_max_sum_limit">set_max_sum_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>, <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_set_max_sum_limit">set_max_sum_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>, <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>: Option&lt;u256&gt;) {
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a> = <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_max_sum_limit">max_sum_limit</a>;
}
</code></pre>



</details>

<a name="rate_limiter_sliding_sum_limiter_advance"></a>

## Function `advance`

Advance the underlying ring aggregator to the current clock time without
recording a new value. Use this to refresh <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a>()</code> for accurate
reads or to keep parallel limiters synchronized in time.

Cap-safe: the underlying advance can only decrease <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_total_sum">total_sum</a></code> (bucket
roll-out), so this call cannot trigger <code><a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_EMaxSumLimitExceeded">EMaxSumLimitExceeded</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_advance">advance</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_advance">advance</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">SlidingSumLimiter</a>, clock: &Clock) {
    self.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_ring_aggregator">ring_aggregator</a>.<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_advance">advance</a>(clock.timestamp_ms() <b>as</b> u256);
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

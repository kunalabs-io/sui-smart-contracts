
<a name="rate_limiter_net_sliding_sum_limiter"></a>

# Module `rate_limiter::net_sliding_sum_limiter`

Net rate limiter that tracks both input and output values using sliding sum windows.

Provides bidirectional rate limiting by maintaining separate sliding sum limiters
for input and output values, allowing calculation of net values (input - output)
while enforcing maximum limits on both directions independently.


<a name="@Gross_vs._net_caps_0"></a>

## Gross vs. net caps


Each side has two independent bounds: a *gross* cap on the per-side total
over the window (<code>max_inflow_limit</code>, <code>max_outflow_limit</code>) and a *net* cap on
<code>|inflow − outflow|</code> (<code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a></code>, <code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a></code>).
They are not interchangeable.

The net cap is a secondary check that bounds wash-style flows where both
sides grow together; it does *not* bound damage on its own. The effective
outflow ceiling over the window is:

```text
min(max_outflow_limit, max_net_outflow_limit + inflow_sum)
```

If <code>max_outflow_limit = None</code>, the ceiling scales 1:1 with however much
inflow has accumulated in the window — including inflow from unrelated
callers. A caller can therefore inflate their own outflow headroom by
first generating inflow, or by waiting for inflow from any other source.
The same relationship holds symmetrically on the inflow side.

Set both the gross and the net cap on a given side unless the ceiling is
intended to float with the opposite side.

See <code>sliding_sum_limiter</code>'s module-level "Cap sizing" note for the
per-side burst behavior that applies to each gross cap.


<a name="@Examples_1"></a>

## Examples


```move
// Create net limiter with 5-minute buckets, 12 buckets total (1 hour window)
let mut net_limiter = net_sliding_sum_limiter::new(
    5 * 60 * 1000,       // 5 minutes per bucket
    12,                  // 12 buckets (1 hour total)
    option::some(10000), // Gross inflow cap (per-window total)
    option::some(8000),  // Gross outflow cap (per-window total)
    option::some(5000),  // Net inflow cap  (bound on inflow - outflow)
    option::some(3000),  // Net outflow cap (bound on outflow - inflow)
    &clock
);

// Consume inflow and outflow values
net_limiter.consume_inflow(1000, &clock);  // Add 1000 to inflow
net_limiter.consume_outflow(500, &clock);  // Add 500 to outflow

// Check current state
let (net_amount, is_outflow) = net_limiter.net_value(); // Returns (500, false)
let inflow_total = net_limiter.inflow_total(); // Returns 1000
let outflow_total = net_limiter.outflow_total(); // Returns 500
```


-  [Gross vs. net caps](#@Gross_vs._net_caps_0)
-  [Examples](#@Examples_1)
-  [Struct `NetSlidingSumLimiter`](#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter)
-  [Constants](#@Constants_2)
-  [Function `new`](#rate_limiter_net_sliding_sum_limiter_new)
-  [Function `inflow_limiter`](#rate_limiter_net_sliding_sum_limiter_inflow_limiter)
-  [Function `outflow_limiter`](#rate_limiter_net_sliding_sum_limiter_outflow_limiter)
-  [Function `inflow_total`](#rate_limiter_net_sliding_sum_limiter_inflow_total)
-  [Function `inflow_total_at`](#rate_limiter_net_sliding_sum_limiter_inflow_total_at)
-  [Function `outflow_total`](#rate_limiter_net_sliding_sum_limiter_outflow_total)
-  [Function `outflow_total_at`](#rate_limiter_net_sliding_sum_limiter_outflow_total_at)
-  [Function `net_value`](#rate_limiter_net_sliding_sum_limiter_net_value)
-  [Function `net_value_at`](#rate_limiter_net_sliding_sum_limiter_net_value_at)
-  [Function `set_max_inflow_limit`](#rate_limiter_net_sliding_sum_limiter_set_max_inflow_limit)
-  [Function `set_max_outflow_limit`](#rate_limiter_net_sliding_sum_limiter_set_max_outflow_limit)
-  [Function `max_net_inflow_limit`](#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit)
-  [Function `max_net_outflow_limit`](#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit)
-  [Function `set_max_net_inflow_limit`](#rate_limiter_net_sliding_sum_limiter_set_max_net_inflow_limit)
-  [Function `set_max_net_outflow_limit`](#rate_limiter_net_sliding_sum_limiter_set_max_net_outflow_limit)
-  [Function `check_net_limits`](#rate_limiter_net_sliding_sum_limiter_check_net_limits)
-  [Function `consume_inflow`](#rate_limiter_net_sliding_sum_limiter_consume_inflow)
-  [Function `consume_outflow`](#rate_limiter_net_sliding_sum_limiter_consume_outflow)


<pre><code><b>use</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator">rate_limiter::ring_aggregator</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter">rate_limiter::sliding_sum_limiter</a>;
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



<a name="rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter"></a>

## Struct `NetSlidingSumLimiter`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>: <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>: <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_2"></a>

## Constants


<a name="rate_limiter_net_sliding_sum_limiter_ENetLimitExceeded"></a>



<pre><code>#[error]
<b>const</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_ENetLimitExceeded">ENetLimitExceeded</a>: vector&lt;u8&gt; = b"Net limit exceeded";
</code></pre>



<a name="rate_limiter_net_sliding_sum_limiter_new"></a>

## Function `new`

Create a new NetSlidingSumLimiter with the specified configuration.

See the module-level "Gross vs. net caps" note: set both the gross and the
net cap on a given side unless the ceiling on that side is intended to
float with the opposite side. See <code>sliding_sum_limiter</code>'s "Cap sizing"
note for the per-side burst behavior of each gross cap.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_new">new</a>(bucket_width_ms: u64, bucket_count: u64, max_inflow_limit: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;, max_outflow_limit: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;, <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;, <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_new">new</a>(
    bucket_width_ms: u64,
    bucket_count: u64,
    max_inflow_limit: Option&lt;u256&gt;,
    max_outflow_limit: Option&lt;u256&gt;,
    <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>: Option&lt;u256&gt;,
    <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>: Option&lt;u256&gt;,
    clock: &Clock,
): <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a> {
    <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a> {
        <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>: sliding_sum_limiter::new(
            bucket_width_ms,
            bucket_count,
            max_inflow_limit,
            clock,
        ),
        <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>: sliding_sum_limiter::new(
            bucket_width_ms,
            bucket_count,
            max_outflow_limit,
            clock,
        ),
        <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>,
        <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>,
    }
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_inflow_limiter"></a>

## Function `inflow_limiter`

Return a reference to the inflow limiter for inspection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>): &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>): &SlidingSumLimiter {
    &self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_outflow_limiter"></a>

## Function `outflow_limiter`

Return a reference to the outflow limiter for inspection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>): &<a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter_SlidingSumLimiter">rate_limiter::sliding_sum_limiter::SlidingSumLimiter</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>): &SlidingSumLimiter {
    &self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_inflow_total"></a>

## Function `inflow_total`

Return the cached inflow total from the last <code>consume_*</code> or
<code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>.advance</code>.

**Caution:** cached, may be stale across time gaps. For an accurate
current-clock read, use <code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_total_at">inflow_total_at</a>(clock)</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_total">inflow_total</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_total">inflow_total</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>): u256 {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>.total_sum()
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_inflow_total_at"></a>

## Function `inflow_total_at`

Compute the inflow total that would be in the sliding window at the
current clock time, without mutating the limiter.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_total_at">inflow_total_at</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_total_at">inflow_total_at</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>, clock: &Clock): u256 {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>.total_sum_at(clock)
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_outflow_total"></a>

## Function `outflow_total`

Return the cached outflow total from the last <code>consume_*</code> or
<code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>.advance</code>.

**Caution:** cached, may be stale across time gaps. For an accurate
current-clock read, use <code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_total_at">outflow_total_at</a>(clock)</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_total">outflow_total</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_total">outflow_total</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>): u256 {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>.total_sum()
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_outflow_total_at"></a>

## Function `outflow_total_at`

Compute the outflow total that would be in the sliding window at the
current clock time, without mutating the limiter.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_total_at">outflow_total_at</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_total_at">outflow_total_at</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>, clock: &Clock): u256 {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>.total_sum_at(clock)
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_net_value"></a>

## Function `net_value`

Return the net value as (absolute_difference, is_outflow), computed
from cached inflow / outflow totals.

**Caution:** cached, may be stale across time gaps. If the two sides
were last advanced at different positions (e.g., outside the
<code>consume_*</code> paths), the absolute_difference and direction may not
reflect the current sliding-window state. For an accurate
current-clock read, use <code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_net_value_at">net_value_at</a>(clock)</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_net_value">net_value</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>): (u256, bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_net_value">net_value</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>): (u256, bool) {
    <b>let</b> inflow_sum = self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>.total_sum();
    <b>let</b> outflow_sum = self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>.total_sum();
    <b>if</b> (inflow_sum &gt;= outflow_sum) {
        (inflow_sum - outflow_sum, <b>false</b>)
    } <b>else</b> {
        (outflow_sum - inflow_sum, <b>true</b>)
    }
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_net_value_at"></a>

## Function `net_value_at`

Compute the net value that would be in the sliding window at the
current clock time, without mutating the limiter. Returns
(absolute_difference, is_outflow), where is_outflow is true if outflow
dominates inflow.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_net_value_at">net_value_at</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (u256, bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_net_value_at">net_value_at</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>, clock: &Clock): (u256, bool) {
    <b>let</b> inflow_sum = self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>.total_sum_at(clock);
    <b>let</b> outflow_sum = self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>.total_sum_at(clock);
    <b>if</b> (inflow_sum &gt;= outflow_sum) {
        (inflow_sum - outflow_sum, <b>false</b>)
    } <b>else</b> {
        (outflow_sum - inflow_sum, <b>true</b>)
    }
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_set_max_inflow_limit"></a>

## Function `set_max_inflow_limit`

Update the maximum inflow limit for the limiter.

See the module-level "Gross vs. net caps" note: this is the *gross* per-window
inflow ceiling. Leaving it as <code>None</code> while keeping <code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a></code> set
makes the effective inflow ceiling float with concurrent outflow.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_set_max_inflow_limit">set_max_inflow_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, max_inflow_limit: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_set_max_inflow_limit">set_max_inflow_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>, max_inflow_limit: Option&lt;u256&gt;) {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>.set_max_sum_limit(max_inflow_limit);
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_set_max_outflow_limit"></a>

## Function `set_max_outflow_limit`

Update the maximum outflow limit for the limiter.

See the module-level "Gross vs. net caps" note: this is the *gross* per-window
outflow ceiling. Leaving it as <code>None</code> while keeping <code><a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a></code> set
makes the effective outflow ceiling float with concurrent inflow.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_set_max_outflow_limit">set_max_outflow_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, max_outflow_limit: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_set_max_outflow_limit">set_max_outflow_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>, max_outflow_limit: Option&lt;u256&gt;) {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>.set_max_sum_limit(max_outflow_limit);
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit"></a>

## Function `max_net_inflow_limit`

Return the current maximum net inflow limit.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>): <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>): Option&lt;u256&gt; {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit"></a>

## Function `max_net_outflow_limit`

Return the current maximum net outflow limit.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>): <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>): Option&lt;u256&gt; {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_set_max_net_inflow_limit"></a>

## Function `set_max_net_inflow_limit`

Update the maximum net inflow limit for the limiter.

See the module-level "Gross vs. net caps" note: this bounds <code>inflow - outflow</code>,
not gross inflow. It is a secondary check on top of <code>max_inflow_limit</code> and
does not by itself bound how much can flow in.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_set_max_net_inflow_limit">set_max_net_inflow_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_set_max_net_inflow_limit">set_max_net_inflow_limit</a>(
    self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>,
    <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>: Option&lt;u256&gt;,
) {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a> = <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>;
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_set_max_net_outflow_limit"></a>

## Function `set_max_net_outflow_limit`

Update the maximum net outflow limit for the limiter.

See the module-level "Gross vs. net caps" note: this bounds <code>outflow - inflow</code>,
not gross outflow. It is a secondary check on top of <code>max_outflow_limit</code> and
does not by itself bound how much can flow out.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_set_max_net_outflow_limit">set_max_net_outflow_limit</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_set_max_net_outflow_limit">set_max_net_outflow_limit</a>(
    self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>,
    <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>: Option&lt;u256&gt;,
) {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a> = <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>;
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_check_net_limits"></a>

## Function `check_net_limits`

Check net limits and abort if exceeded.


<pre><code><b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_check_net_limits">check_net_limits</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_check_net_limits">check_net_limits</a>(self: &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>) {
    // Early <b>return</b> <b>if</b> no net limits are set
    <b>if</b> (
        option::is_none(&self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>) && option::is_none(&self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>)
    ) {
        <b>return</b>
    };
    <b>let</b> (net_amount, is_outflow) = self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_net_value">net_value</a>();
    <b>if</b> (is_outflow) {
        // Net is outflow, check outflow limit
        self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>.do_ref!(|<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>| {
            <b>assert</b>!(net_amount &lt;= *<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_outflow_limit">max_net_outflow_limit</a>, <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_ENetLimitExceeded">ENetLimitExceeded</a>);
        });
    } <b>else</b> {
        // Net is inflow, check inflow limit
        self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>.do_ref!(|<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>| {
            <b>assert</b>!(net_amount &lt;= *<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_max_net_inflow_limit">max_net_inflow_limit</a>, <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_ENetLimitExceeded">ENetLimitExceeded</a>);
        });
    };
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_consume_inflow"></a>

## Function `consume_inflow`

Consume an inflow value and add it to the current time bucket, enforcing the maximum inflow limit and net limits.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_consume_inflow">consume_inflow</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, value: u64, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_consume_inflow">consume_inflow</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>, value: u64, clock: &Clock) {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>.consume(value, clock);
    // Advance the opposite (outflow) side to the same clock position so
    // `<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_check_net_limits">check_net_limits</a>` reads fresh `total_sum` values from both sides.
    // Without this, a stale outflow `total_sum` (cached at its last consume
    // time) can cause `<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_net_value">net_value</a>` to misreport direction and route the cap
    // check to the wrong limit branch.
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>.advance(clock);
    <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_check_net_limits">check_net_limits</a>(self);
}
</code></pre>



</details>

<a name="rate_limiter_net_sliding_sum_limiter_consume_outflow"></a>

## Function `consume_outflow`

Consume an outflow value and add it to the current time bucket, enforcing the maximum outflow limit and net limits.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_consume_outflow">consume_outflow</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>, value: u64, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_consume_outflow">consume_outflow</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">NetSlidingSumLimiter</a>, value: u64, clock: &Clock) {
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_outflow_limiter">outflow_limiter</a>.consume(value, clock);
    // See note in `<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_consume_inflow">consume_inflow</a>`. Advancing the inflow side keeps both
    // limiters at the same clock position before the net cap check.
    self.<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_inflow_limiter">inflow_limiter</a>.advance(clock);
    <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_check_net_limits">check_net_limits</a>(self);
}
</code></pre>



</details>

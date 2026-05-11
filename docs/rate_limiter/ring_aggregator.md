
<a name="rate_limiter_ring_aggregator"></a>

# Module `rate_limiter::ring_aggregator`

Ring buffer-based aggregator for maintaining sliding window sums over positions.

Maintains a fixed number of buckets in a circular buffer. As positions advance,
the aggregator automatically rotates through buckets, zeroing out old buckets
and maintaining an accurate sum of values within the sliding window.

Supports configurable bucket width and count, with O(1) operations for adding
values and advancing positions. Validates that positions can only advance forward.


<a name="@Examples_0"></a>

## Examples


```move
// Create aggregator with 10 buckets of width 1000
let mut agg = ring_aggregator::new(1000, 10);

// Add values at different positions
agg.advance_and_add(500, 100);   // Add 100 at position 500
agg.advance_and_add(1500, 200);  // Add 200 at position 1500

// Check current state
let total = agg.total_sum();           // Returns 300
let position = agg.current_position(); // Returns 1500
```


-  [Examples](#@Examples_0)
-  [Struct `RingAggregator`](#rate_limiter_ring_aggregator_RingAggregator)
-  [Constants](#@Constants_1)
-  [Function `create_empty_buckets`](#rate_limiter_ring_aggregator_create_empty_buckets)
-  [Function `new`](#rate_limiter_ring_aggregator_new)
-  [Function `new_with_initial_position`](#rate_limiter_ring_aggregator_new_with_initial_position)
-  [Function `bucket_count`](#rate_limiter_ring_aggregator_bucket_count)
-  [Function `bucket_width`](#rate_limiter_ring_aggregator_bucket_width)
-  [Function `current_position`](#rate_limiter_ring_aggregator_current_position)
-  [Function `total_sum`](#rate_limiter_ring_aggregator_total_sum)
-  [Function `total_sum_at`](#rate_limiter_ring_aggregator_total_sum_at)
-  [Function `borrow_buckets`](#rate_limiter_ring_aggregator_borrow_buckets)
-  [Function `get_bucket_index`](#rate_limiter_ring_aggregator_get_bucket_index)
-  [Function `get_current_bucket_index`](#rate_limiter_ring_aggregator_get_current_bucket_index)
-  [Function `advance`](#rate_limiter_ring_aggregator_advance)
-  [Function `advance_and_add`](#rate_limiter_ring_aggregator_advance_and_add)


<pre><code></code></pre>



<a name="rate_limiter_ring_aggregator_RingAggregator"></a>

## Struct `RingAggregator`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>buckets: vector&lt;u128&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>: u256</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a>: u256</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_1"></a>

## Constants


<a name="rate_limiter_ring_aggregator_EInvalidPosition"></a>



<pre><code>#[error]
<b>const</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidPosition">EInvalidPosition</a>: vector&lt;u8&gt; = b"New position must be greater than or equal to the current position";
</code></pre>



<a name="rate_limiter_ring_aggregator_EInvalidBucketWidth"></a>



<pre><code>#[error]
<b>const</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidBucketWidth">EInvalidBucketWidth</a>: vector&lt;u8&gt; = b"<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a> must be greater than zero";
</code></pre>



<a name="rate_limiter_ring_aggregator_EInvalidBucketCount"></a>



<pre><code>#[error]
<b>const</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidBucketCount">EInvalidBucketCount</a>: vector&lt;u8&gt; = b"<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> must be greater than zero";
</code></pre>



<a name="rate_limiter_ring_aggregator_create_empty_buckets"></a>

## Function `create_empty_buckets`



<pre><code><b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_create_empty_buckets">create_empty_buckets</a>(count: u64): vector&lt;u128&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_create_empty_buckets">create_empty_buckets</a>(count: u64): vector&lt;u128&gt; {
    <b>let</b> <b>mut</b> buckets = vector::empty();
    count.do!(|_| {
        vector::push_back(&<b>mut</b> buckets, 0);
    });
    buckets
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_new"></a>

## Function `new`

Create a new RingAggregator with the specified bucket configuration.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_new">new</a>(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>: u64, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>: u64): <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_new">new</a>(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>: u64, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>: u64): <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a> {
    <b>assert</b>!(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a> &gt; 0, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidBucketWidth">EInvalidBucketWidth</a>);
    <b>assert</b>!(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> &gt; 0, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidBucketCount">EInvalidBucketCount</a>);
    <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a> {
        buckets: <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_create_empty_buckets">create_empty_buckets</a>(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>),
        <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>,
        <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>: 0,
        <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a>: 0,
    }
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_new_with_initial_position"></a>

## Function `new_with_initial_position`

Create a new RingAggregator with the specified bucket configuration and initial position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_new_with_initial_position">new_with_initial_position</a>(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>: u64, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>: u64, initial_position: u256): <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_new_with_initial_position">new_with_initial_position</a>(
    <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>: u64,
    <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>: u64,
    initial_position: u256,
): <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a> {
    <b>assert</b>!(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a> &gt; 0, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidBucketWidth">EInvalidBucketWidth</a>);
    <b>assert</b>!(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> &gt; 0, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidBucketCount">EInvalidBucketCount</a>);
    <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a> {
        buckets: <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_create_empty_buckets">create_empty_buckets</a>(<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>),
        <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>,
        <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>: initial_position,
        <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a>: 0,
    }
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_bucket_count"></a>

## Function `bucket_count`

Return the number of buckets in the ring aggregator.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>): u64 {
    self.buckets.length()
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_bucket_width"></a>

## Function `bucket_width`

Return the width of each bucket in milliseconds.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>): u64 {
    self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_current_position"></a>

## Function `current_position`

Return the current position (timestamp) of the aggregator.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>): u256 {
    self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_total_sum"></a>

## Function `total_sum`

Return the cached total sum from the last <code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance">advance</a></code> (or <code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance_and_add">advance_and_add</a></code>).

**Caution:** this is a cached field, not a fresh windowed-sum
computation. Buckets that should have rolled out since the last advance
are still counted. For an accurate current-time read, use
<code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum_at">total_sum_at</a>(position)</code>. See module-level note on staleness footguns.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>): u256 {
    self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a>
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_total_sum_at"></a>

## Function `total_sum_at`

Compute the total sum that would be in the sliding window at <code>position</code>,
without mutating the aggregator. Use this when you need an accurate
read but cannot — or do not want to — <code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance">advance</a></code> the aggregator.

Aborts if <code>position &lt; self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a></code> (a sliding-window
aggregator does not support reading the past).


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum_at">total_sum_at</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>, position: u256): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum_at">total_sum_at</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>, position: u256): u256 {
    <b>assert</b>!(position &gt;= self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidPosition">EInvalidPosition</a>);
    <b>let</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> = self.buckets.length();
    <b>let</b> bucket_width_u256 = self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a> <b>as</b> u256;
    <b>let</b> steps = (position / bucket_width_u256) - (self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a> / bucket_width_u256);
    <b>if</b> (steps &gt;= <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> <b>as</b> u256) {
        <b>return</b> 0
    };
    <b>if</b> (steps == 0) {
        <b>return</b> self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a>
    };
    <b>let</b> start_bucket_index = self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_get_current_bucket_index">get_current_bucket_index</a>() + 1;
    <b>let</b> <b>mut</b> rolled_out_sum: u256 = 0;
    (steps <b>as</b> u64).do!(|i| {
        <b>let</b> bucket_value = &self.buckets[((start_bucket_index + (i <b>as</b> u64)) % <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>)];
        rolled_out_sum = rolled_out_sum + (*bucket_value <b>as</b> u256);
    });
    self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a> - rolled_out_sum
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_borrow_buckets"></a>

## Function `borrow_buckets`

Return a reference to the internal bucket vector for inspection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_borrow_buckets">borrow_buckets</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>): &vector&lt;u128&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_borrow_buckets">borrow_buckets</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>): &vector&lt;u128&gt; {
    &self.buckets
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_get_bucket_index"></a>

## Function `get_bucket_index`



<pre><code><b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_get_bucket_index">get_bucket_index</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>, position: u256): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_get_bucket_index">get_bucket_index</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>, position: u256): u64 {
    <b>let</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> = (self.buckets.length() <b>as</b> u256);
    <b>let</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a> = (self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a> <b>as</b> u256);
    ((position % (<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> * <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>)) / <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a>) <b>as</b> u64
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_get_current_bucket_index"></a>

## Function `get_current_bucket_index`



<pre><code><b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_get_current_bucket_index">get_current_bucket_index</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_get_current_bucket_index">get_current_bucket_index</a>(self: &<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>): u64 {
    <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_get_bucket_index">get_bucket_index</a>(self, self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>)
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_advance"></a>

## Function `advance`

Advance the aggregator to the specified position, zeroing any buckets that
fall outside the sliding window. Does not add a value.

Useful for refreshing <code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a></code> (and the underlying bucket vector) without
recording new activity — for example, to keep two parallel aggregators on
the same <code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a></code> so that a downstream comparison sees fresh
totals on both sides.

Cap-safe: bucket roll-out can only decrease <code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a></code> (or leave it
unchanged when <code>position</code> is within the current bucket), so callers can
invoke <code><a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance">advance</a></code> without a cap-exceedance check.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance">advance</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>, position: u256)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance">advance</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>, position: u256) {
    <b>assert</b>!(position &gt;= self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a>, <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_EInvalidPosition">EInvalidPosition</a>);
    <b>let</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> = self.buckets.length();
    <b>let</b> bucket_width_u256 = self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_width">bucket_width</a> <b>as</b> u256;
    <b>let</b> steps = (position / bucket_width_u256) - (self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a> / bucket_width_u256);
    <b>if</b> (steps &gt;= <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a> <b>as</b> u256) {
        self.buckets = <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_create_empty_buckets">create_empty_buckets</a>(self.buckets.length());
        self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a> = 0;
    } <b>else</b> <b>if</b> (steps &gt; 0) {
        <b>let</b> start_bucket_index = self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_get_current_bucket_index">get_current_bucket_index</a>() + 1;
        (steps <b>as</b> u64).do!(|i| {
            <b>let</b> bucket_value =
                &<b>mut</b> self.buckets[((start_bucket_index + (i <b>as</b> u64)) % <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_bucket_count">bucket_count</a>)];
            self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a> = self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a> - (*bucket_value <b>as</b> u256);
            *bucket_value = 0;
        });
    };
    self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_current_position">current_position</a> = position;
}
</code></pre>



</details>

<a name="rate_limiter_ring_aggregator_advance_and_add"></a>

## Function `advance_and_add`

Advance the aggregator to the specified position and add a value to the corresponding bucket.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance_and_add">advance_and_add</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">rate_limiter::ring_aggregator::RingAggregator</a>, position: u256, value: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance_and_add">advance_and_add</a>(self: &<b>mut</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_RingAggregator">RingAggregator</a>, position: u256, value: u64) {
    self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_advance">advance</a>(position);
    <b>let</b> bucket_index = self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_get_bucket_index">get_bucket_index</a>(position);
    <b>let</b> bucket_value = &<b>mut</b> self.buckets[bucket_index];
    *bucket_value = *bucket_value + (value <b>as</b> u128);
    self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a> = self.<a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator_total_sum">total_sum</a> + (value <b>as</b> u256);
}
</code></pre>



</details>

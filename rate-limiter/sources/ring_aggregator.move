/// Ring buffer-based aggregator for maintaining sliding window sums over positions.
/// 
/// Maintains a fixed number of buckets in a circular buffer. As positions advance,
/// the aggregator automatically rotates through buckets, zeroing out old buckets
/// and maintaining an accurate sum of values within the sliding window.
/// 
/// Supports configurable bucket width and count, with O(1) operations for adding
/// values and advancing positions. Validates that positions can only advance forward.
/// 
/// # Examples
/// 
/// ```move
/// // Create aggregator with 10 buckets of width 1000
/// let mut agg = ring_aggregator::new(1000, 10);
/// 
/// // Add values at different positions
/// agg.advance_and_add(500, 100);   // Add 100 at position 500
/// agg.advance_and_add(1500, 200);  // Add 200 at position 1500
/// 
/// // Check current state
/// let total = agg.total_sum();           // Returns 300
/// let position = agg.current_position(); // Returns 1500
/// ```
module rate_limiter::ring_aggregator;

#[error(code = 0)]
const EInvalidPosition: vector<u8> =
    b"New position must be greater than or equal to the current position";

public struct RingAggregator has copy, drop, store {
    buckets: vector<u128>,
    bucket_width: u64,
    current_position: u256,
    total_sum: u256,
}

fun create_empty_buckets(count: u64): vector<u128> {
    let mut buckets = vector::empty();
    count.do!(|_| {
        vector::push_back(&mut buckets, 0);
    });
    buckets
}

/// Create a new RingAggregator with the specified bucket configuration.
public fun new(bucket_width: u64, bucket_count: u64): RingAggregator {
    RingAggregator {
        buckets: create_empty_buckets(bucket_count),
        bucket_width,
        current_position: 0,
        total_sum: 0,
    }
}

/// Create a new RingAggregator with the specified bucket configuration and initial position.
public fun new_with_initial_position(
    bucket_width: u64,
    bucket_count: u64,
    initial_position: u256,
): RingAggregator {
    RingAggregator {
        buckets: create_empty_buckets(bucket_count),
        bucket_width,
        current_position: initial_position,
        total_sum: 0,
    }
}

/// Return the number of buckets in the ring aggregator.
public fun bucket_count(self: &RingAggregator): u64 {
    self.buckets.length()
}

/// Return the width of each bucket in milliseconds.
public fun bucket_width(self: &RingAggregator): u64 {
    self.bucket_width
}

/// Return the current position (timestamp) of the aggregator.
public fun current_position(self: &RingAggregator): u256 {
    self.current_position
}

/// Return the total sum of all values currently in the sliding window.
public fun total_sum(self: &RingAggregator): u256 {
    self.total_sum
}

/// Return a reference to the internal bucket vector for inspection.
public fun borrow_buckets(self: &RingAggregator): &vector<u128> {
    &self.buckets
}

fun get_bucket_index(self: &RingAggregator, position: u256): u64 {
    let bucket_count = (self.buckets.length() as u256);
    let bucket_width = (self.bucket_width as u256);

    ((position % (bucket_count * bucket_width)) / bucket_width) as u64
}

fun get_current_bucket_index(self: &RingAggregator): u64 {
    get_bucket_index(self, self.current_position)
}

/// Advance the aggregator to the specified position and add a value to the corresponding bucket.
public fun advance_and_add(self: &mut RingAggregator, position: u256, value: u64) {
    assert!(position >= self.current_position, EInvalidPosition);

    let bucket_count = self.buckets.length();

    let bucket_width_u256 = self.bucket_width as u256;
    let steps = (position / bucket_width_u256) - (self.current_position / bucket_width_u256);
    if (steps >= bucket_count as u256) {
        self.buckets = create_empty_buckets(self.buckets.length());
        self.total_sum = 0;
    } else if (steps > 0) {
        let start_bucket_index = self.get_current_bucket_index() + 1;
        (steps as u64).do!(|i| {
            let bucket_value =
                &mut self.buckets[((start_bucket_index + (i as u64)) % bucket_count)];
            self.total_sum = self.total_sum - (*bucket_value as u256);

            *bucket_value = 0;
        });
    };

    let bucket_index = self.get_bucket_index(position);
    let bucket_value = &mut self.buckets[bucket_index];
    *bucket_value = *bucket_value + (value as u128);

    self.total_sum = self.total_sum + (value as u256);
    self.current_position = position;
}

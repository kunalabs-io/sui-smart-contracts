/// Time-based rate limiter that enforces maximum sum limits over a sliding window.
/// 
/// Wraps the RingAggregator to provide time-based rate limiting functionality with
/// configurable maximum sum limits. Uses Sui's Clock object for position tracking
/// and enforces limits by aborting when the maximum sum would be exceeded.
/// 
/// # Examples
/// 
/// ```move
/// // Create rate limiter with 5-minute buckets, 12 buckets total (1 hour window)
/// let mut limiter = sliding_sum_limiter::new(
///     5 * 60 * 1000,  // 5 minutes per bucket
///     12,             // 12 buckets (1 hour total)
///     option::some(10000), // Maximum sum limit
///     &clock
/// );
/// 
/// // Consume values (will abort if limit exceeded)
/// limiter.consume(1000, &clock);  // Add 1000 to current bucket
/// limiter.consume(2000, &clock);  // Add 2000 to current bucket
/// 
/// // Check current state
/// let total = limiter.total_sum(); // Returns 3000
/// ```
module rate_limiter::sliding_sum_limiter;

use rate_limiter::ring_aggregator::{Self, RingAggregator};
use sui::clock::Clock;

#[error(code = 0)]
const EMaxSumLimitExceeded: vector<u8> = b"Max sum limit exceeded";

public struct SlidingSumLimiter has copy, drop, store {
    ring_aggregator: RingAggregator,
    max_sum_limit: Option<u256>,
}

/// Create a new SlidingSumLimiter with the specified configuration.
public fun new(
    bucket_width_ms: u64,
    bucket_count: u64,
    max_sum_limit: Option<u256>,
    clock: &Clock,
): SlidingSumLimiter {
    SlidingSumLimiter {
        ring_aggregator: ring_aggregator::new_with_initial_position(
            bucket_width_ms,
            bucket_count,
            clock.timestamp_ms() as u256,
        ),
        max_sum_limit,
    }
}

/// Return a reference to the internal ring aggregator for inspection.
public fun ring_aggregator(self: &SlidingSumLimiter): &RingAggregator {
    &self.ring_aggregator
}

/// Return the total sum of all values currently in the sliding window.
public fun total_sum(self: &SlidingSumLimiter): u256 {
    self.ring_aggregator.total_sum()
}

/// Return the current maximum sum limit.
public fun max_sum_limit(self: &SlidingSumLimiter): Option<u256> {
    self.max_sum_limit
}

/// Update the maximum sum limit for the limiter.
public fun set_max_sum_limit(self: &mut SlidingSumLimiter, max_sum_limit: Option<u256>) {
    self.max_sum_limit = max_sum_limit;
}

/// Consume a value and add it to the current time bucket, enforcing the maximum sum limit.
public fun consume(self: &mut SlidingSumLimiter, value: u64, clock: &Clock) {
    self.ring_aggregator.advance_and_add(clock.timestamp_ms() as u256, value);

    self.max_sum_limit.do_ref!(|max_sum_limit| {
        assert!(self.ring_aggregator.total_sum() <= *max_sum_limit, EMaxSumLimitExceeded);
    });
}

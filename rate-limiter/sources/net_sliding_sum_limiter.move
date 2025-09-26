/// Net rate limiter that tracks both input and output values using sliding sum windows.
///
/// Provides bidirectional rate limiting by maintaining separate sliding sum limiters
/// for input and output values, allowing calculation of net values (input - output)
/// while enforcing maximum limits on both directions independently.
///
/// # Examples
///
/// ```move
/// // Create net limiter with 5-minute buckets, 12 buckets total (1 hour window)
/// let mut net_limiter = net_sliding_sum_limiter::new(
///     5 * 60 * 1000,  // 5 minutes per bucket
///     12,             // 12 buckets (1 hour total)
///     option::some(10000), // Maximum inflow limit
///     option::some(8000),  // Maximum outflow limit
///     &clock
/// );
///
/// // Consume inflow and outflow values
/// net_limiter.consume_inflow(1000, &clock);  // Add 1000 to inflow
/// net_limiter.consume_outflow(500, &clock);  // Add 500 to outflow
///
/// // Check current state
/// let (net_amount, is_outflow) = net_limiter.net_value(); // Returns (500, false)
/// let inflow_total = net_limiter.inflow_total(); // Returns 1000
/// let outflow_total = net_limiter.outflow_total(); // Returns 500
/// ```
module rate_limiter::net_sliding_sum_limiter;

use rate_limiter::sliding_sum_limiter::{Self, SlidingSumLimiter};
use sui::clock::Clock;

#[error(code = 0)]
const ENetLimitExceeded: vector<u8> = b"Net limit exceeded";

public struct NetSlidingSumLimiter has copy, drop, store {
    inflow_limiter: SlidingSumLimiter,
    outflow_limiter: SlidingSumLimiter,
    max_net_inflow_limit: Option<u256>,
    max_net_outflow_limit: Option<u256>,
}

/// Create a new NetSlidingSumLimiter with the specified configuration.
public fun new(
    bucket_width_ms: u64,
    bucket_count: u64,
    max_inflow_limit: Option<u256>,
    max_outflow_limit: Option<u256>,
    max_net_inflow_limit: Option<u256>,
    max_net_outflow_limit: Option<u256>,
    clock: &Clock,
): NetSlidingSumLimiter {
    NetSlidingSumLimiter {
        inflow_limiter: sliding_sum_limiter::new(
            bucket_width_ms,
            bucket_count,
            max_inflow_limit,
            clock,
        ),
        outflow_limiter: sliding_sum_limiter::new(
            bucket_width_ms,
            bucket_count,
            max_outflow_limit,
            clock,
        ),
        max_net_inflow_limit,
        max_net_outflow_limit,
    }
}

/// Return a reference to the inflow limiter for inspection.
public fun inflow_limiter(self: &NetSlidingSumLimiter): &SlidingSumLimiter {
    &self.inflow_limiter
}

/// Return a reference to the outflow limiter for inspection.
public fun outflow_limiter(self: &NetSlidingSumLimiter): &SlidingSumLimiter {
    &self.outflow_limiter
}

/// Return the total sum of all inflow values currently in the sliding window.
public fun inflow_total(self: &NetSlidingSumLimiter): u256 {
    self.inflow_limiter.total_sum()
}

/// Return the total sum of all outflow values currently in the sliding window.
public fun outflow_total(self: &NetSlidingSumLimiter): u256 {
    self.outflow_limiter.total_sum()
}

/// Return the net value as (absolute_difference, is_outflow). It's inflow if inflow >= outflow, otherwise outflow.
/// Returns (inflow - outflow, false) if inflow >= outflow, otherwise (outflow - inflow, true).
public fun net_value(self: &NetSlidingSumLimiter): (u256, bool) {
    let inflow_sum = self.inflow_limiter.total_sum();
    let outflow_sum = self.outflow_limiter.total_sum();

    if (inflow_sum >= outflow_sum) {
        (inflow_sum - outflow_sum, false)
    } else {
        (outflow_sum - inflow_sum, true)
    }
}

/// Update the maximum inflow limit for the limiter.
public fun set_max_inflow_limit(self: &mut NetSlidingSumLimiter, max_inflow_limit: Option<u256>) {
    self.inflow_limiter.set_max_sum_limit(max_inflow_limit);
}

/// Update the maximum outflow limit for the limiter.
public fun set_max_outflow_limit(self: &mut NetSlidingSumLimiter, max_outflow_limit: Option<u256>) {
    self.outflow_limiter.set_max_sum_limit(max_outflow_limit);
}

/// Return the current maximum net inflow limit.
public fun max_net_inflow_limit(self: &NetSlidingSumLimiter): Option<u256> {
    self.max_net_inflow_limit
}

/// Return the current maximum net outflow limit.
public fun max_net_outflow_limit(self: &NetSlidingSumLimiter): Option<u256> {
    self.max_net_outflow_limit
}

/// Update the maximum net inflow limit for the limiter.
public fun set_max_net_inflow_limit(
    self: &mut NetSlidingSumLimiter,
    max_net_inflow_limit: Option<u256>,
) {
    self.max_net_inflow_limit = max_net_inflow_limit;
}

/// Update the maximum net outflow limit for the limiter.
public fun set_max_net_outflow_limit(
    self: &mut NetSlidingSumLimiter,
    max_net_outflow_limit: Option<u256>,
) {
    self.max_net_outflow_limit = max_net_outflow_limit;
}

/// Check net limits and abort if exceeded.
fun check_net_limits(self: &NetSlidingSumLimiter) {
    // Early return if no net limits are set
    if (
        option::is_none(&self.max_net_inflow_limit) && option::is_none(&self.max_net_outflow_limit)
    ) {
        return
    };

    let (net_amount, is_outflow) = self.net_value();

    if (is_outflow) {
        // Net is outflow, check outflow limit
        self.max_net_outflow_limit.do_ref!(|max_net_outflow_limit| {
            assert!(net_amount <= *max_net_outflow_limit, ENetLimitExceeded);
        });
    } else {
        // Net is inflow, check inflow limit
        self.max_net_inflow_limit.do_ref!(|max_net_inflow_limit| {
            assert!(net_amount <= *max_net_inflow_limit, ENetLimitExceeded);
        });
    };
}

/// Consume an inflow value and add it to the current time bucket, enforcing the maximum inflow limit and net limits.
public fun consume_inflow(self: &mut NetSlidingSumLimiter, value: u64, clock: &Clock) {
    self.inflow_limiter.consume(value, clock);
    check_net_limits(self);
}

/// Consume an outflow value and add it to the current time bucket, enforcing the maximum outflow limit and net limits.
public fun consume_outflow(self: &mut NetSlidingSumLimiter, value: u64, clock: &Clock) {
    self.outflow_limiter.consume(value, clock);
    check_net_limits(self);
}

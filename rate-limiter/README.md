# Rate Limiter

A time-based rate limiting library for Sui Move smart contracts with sliding window support.

## Overview

The Rate Limiter package provides efficient rate limiting capabilities through two core modules:

- **`ring_aggregator`**: Ring buffer implementation for time-based aggregation
- **`sliding_sum_limiter`**: Rate limiter that enforces maximum sum limits over sliding time windows

## Key Features

- Efficient time-based aggregation with ring buffers
- Sliding window support with configurable time windows
- Dynamic maximum sum limits
- Constant memory usage

## Architecture

### Ring Aggregator

Maintains a circular buffer of time buckets with automatic rotation and sum recalculation.

### Sliding Sum Limiter

Wraps the RingAggregator to provide rate limiting functionality with configurable limits and Sui Clock integration.

## Usage

```move
use rate_limiter::sliding_sum_limiter;

// Create a rate limiter
let mut limiter = sliding_sum_limiter::new(
    5 * 60 * 1000,  // 5 minutes per bucket
    12,             // 12 buckets (1 hour window)
    option::some(10000), // Maximum sum limit
    &clock
);

// Consume values
limiter.consume(1000, &clock);
limiter.consume(2000, &clock);

// Check state
let total = limiter.total_sum();
```

## Performance

- O(1) time complexity for all operations
- Constant memory usage regardless of time window size

## License

This package is licensed under the Apache License, Version 2.0. See the LICENSE file for details.

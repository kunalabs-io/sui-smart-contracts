# Rate Limiter

A time-based rate limiting library for Sui Move smart contracts with sliding window support.

## Overview

The Rate Limiter package provides efficient rate limiting capabilities through three core modules:

- **`ring_aggregator`**: Ring buffer implementation for time-based aggregation
- **`sliding_sum_limiter`**: Rate limiter that enforces maximum sum limits over sliding time windows
- **`net_sliding_sum_limiter`**: Bidirectional rate limiter that tracks both inflow and outflow values with net calculation and net limits

## Key Features

- Efficient time-based aggregation with ring buffers
- Sliding window support with configurable time windows
- Dynamic maximum sum limits
- Bidirectional rate limiting (inflow/outflow tracking)
- Net value calculation (inflow - outflow)
- Net limit enforcement (separate limits for net inflow and net outflow)
- Constant memory usage

## Architecture

### Ring Aggregator

Maintains a circular buffer of time buckets with automatic rotation and sum recalculation.

### Sliding Sum Limiter

Wraps the RingAggregator to provide rate limiting functionality with configurable limits and Sui Clock integration.

### Net Sliding Sum Limiter

Maintains separate sliding sum limiters for inflow and outflow values, enabling bidirectional rate limiting with net value calculation and net limit enforcement. Perfect for tracking flows where you need to monitor both incoming and outgoing values while calculating net differences and enforcing net flow limits.

## Usage

### Basic Rate Limiting

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

### Bidirectional Rate Limiting

```move
use rate_limiter::net_sliding_sum_limiter;

// Create a net rate limiter
let mut net_limiter = net_sliding_sum_limiter::new(
    5 * 60 * 1000,  // 5 minutes per bucket
    12,             // 12 buckets (1 hour window)
    option::some(10000), // Maximum inflow limit
    option::some(8000),  // Maximum outflow limit
    option::some(5000),  // Maximum net inflow limit
    option::some(3000),  // Maximum net outflow limit
    &clock
);

// Consume inflow and outflow values
net_limiter.consume_inflow(1000, &clock);
net_limiter.consume_outflow(500, &clock);

// Check net value
let (net_amount, is_outflow) = net_limiter.net_value();
// Returns (500, false) - net inflow of 500
```

## Performance

- O(1) time complexity for all operations
- Constant memory usage regardless of time window size

## License

This package is licensed under the Apache License, Version 2.0. See the LICENSE file for details.

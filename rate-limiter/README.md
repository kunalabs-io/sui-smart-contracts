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
    5 * 60 * 1000,       // 5 minutes per bucket
    12,                  // 12 buckets (1 hour window)
    option::some(10000), // Gross inflow cap  (per-window total)
    option::some(8000),  // Gross outflow cap (per-window total)
    option::some(5000),  // Net inflow cap    (bound on inflow - outflow)
    option::some(3000),  // Net outflow cap   (bound on outflow - inflow)
    &clock
);

// Consume inflow and outflow values
net_limiter.consume_inflow(1000, &clock);
net_limiter.consume_outflow(500, &clock);

// Check net value
let (net_amount, is_outflow) = net_limiter.net_value();
// Returns (500, false) - net inflow of 500
```

## Configuration notes

Two properties of the limiter are easy to misread from the API surface. See the
`sliding_sum_limiter` and `net_sliding_sum_limiter` module docs for full
details; the short version:

- **Set both the gross and the net cap on each side.** The net caps
  (`max_net_inflow_limit`, `max_net_outflow_limit`) bound `|inflow − outflow|`,
  not the gross flow. The effective outflow ceiling over the window is
  `min(max_outflow_limit, max_net_outflow_limit + inflow_sum)` — leaving
  `max_outflow_limit = None` lets the ceiling scale 1:1 with inflow from any
  source. Treat the gross cap as the hard ceiling and the net cap as a
  secondary check on wash-style flows. The same relationship holds on the
  inflow side.

- **The cap is a per-window burst, not a smooth budget.** The window slides in
  discrete bucket steps, so an adversarial caller timing a bucket boundary can
  extract up to ~2× cap over approximately one window length; the long-run
  sustained rate converges to `cap / (bucket_count × bucket_width)`. Size the
  cap as the worst single-window burst that can be absorbed, and choose the
  window length to match the detection / response time on whatever activity is
  being limited.

## Performance

- O(1) time complexity for all operations
- Constant memory usage regardless of time window size

## License

This package is licensed under the Apache License, Version 2.0. See the LICENSE file for details.

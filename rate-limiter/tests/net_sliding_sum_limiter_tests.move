#[test_only]
module rate_limiter::net_sliding_sum_limiter_tests;

use rate_limiter::net_sliding_sum_limiter;
use rate_limiter::sliding_sum_limiter;
use sui::clock;
use std::unit_test::destroy;

#[test]
fun consume_inflow_outflow_is_correct() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let one_minute = 60 * 1000;

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * one_minute,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &clock,
    );
    assert!(net_limiter.inflow_total() == 0);
    assert!(net_limiter.outflow_total() == 0);
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 0);
    assert!(is_outflow == false);

    // consume inflow
    net_limiter.consume_inflow(1000, &clock);
    assert!(net_limiter.inflow_total() == 1000);
    assert!(net_limiter.outflow_total() == 0);
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 1000);
    assert!(is_outflow == false);

    // consume outflow
    net_limiter.consume_outflow(500, &clock);
    assert!(net_limiter.inflow_total() == 1000);
    assert!(net_limiter.outflow_total() == 500);
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 500);
    assert!(is_outflow == false);

    // consume more outflow to make net outflow
    net_limiter.consume_outflow(800, &clock);
    assert!(net_limiter.inflow_total() == 1000);
    assert!(net_limiter.outflow_total() == 1300);
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 300);
    assert!(is_outflow == true);

    destroy(clock);
}

#[test]
fun time_advancement_works_correctly() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let one_minute = 60 * 1000;

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * one_minute,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &clock,
    );

    // consume values
    net_limiter.consume_inflow(1000, &clock);
    net_limiter.consume_outflow(500, &clock);
    assert!(net_limiter.inflow_total() == 1000);
    assert!(net_limiter.outflow_total() == 500);

    // advance time and consume more
    clock::set_for_testing(&mut clock, 13500000 - 1); // ~58 minutes
    net_limiter.consume_inflow(2000, &clock);
    net_limiter.consume_outflow(1000, &clock);
    assert!(net_limiter.inflow_total() == 3000);
    assert!(net_limiter.outflow_total() == 1500);

    // advance time past window
    clock::increment_for_testing(&mut clock, 60 * 70 * 1000); // 1 hour + 10 minutes
    net_limiter.consume_inflow(500, &clock);
    net_limiter.consume_outflow(200, &clock);
    assert!(net_limiter.inflow_total() == 500);
    assert!(net_limiter.outflow_total() == 200);

    destroy(clock);
}

#[test, expected_failure(abort_code = sliding_sum_limiter::EMaxSumLimitExceeded)]
fun consume_inflow_aborts_on_max_inflow_limit_exceeded() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::some(5000),
        option::none(),
        option::none(),
        option::none(),
        &clock,
    );

    net_limiter.consume_inflow(2000, &clock);
    assert!(net_limiter.inflow_total() == 2000);

    net_limiter.consume_inflow(2000, &clock);
    assert!(net_limiter.inflow_total() == 4000);

    net_limiter.consume_inflow(1500, &clock); // should abort (4000 + 1500 > 5000)

    destroy(clock);
}

#[test, expected_failure(abort_code = sliding_sum_limiter::EMaxSumLimitExceeded)]
fun consume_outflow_aborts_on_max_outflow_limit_exceeded() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::some(3000),
        option::none(),
        option::none(),
        &clock,
    );

    net_limiter.consume_outflow(1000, &clock);
    assert!(net_limiter.outflow_total() == 1000);

    net_limiter.consume_outflow(1000, &clock);
    assert!(net_limiter.outflow_total() == 2000);

    net_limiter.consume_outflow(1500, &clock); // should abort (2000 + 1500 > 3000)

    destroy(clock);
}

#[test]
fun set_max_limits_works() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &clock,
    );

    // Set limits
    net_limiter.set_max_inflow_limit(option::some(10000));
    net_limiter.set_max_outflow_limit(option::some(8000));

    // Consume within limits
    net_limiter.consume_inflow(5000, &clock);
    net_limiter.consume_outflow(3000, &clock);
    assert!(net_limiter.inflow_total() == 5000);
    assert!(net_limiter.outflow_total() == 3000);

    destroy(clock);
}

#[test]
fun net_value_calculation_edge_cases() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &clock,
    );

    // Test equal inflow and outflow
    net_limiter.consume_inflow(1000, &clock);
    net_limiter.consume_outflow(1000, &clock);
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 0);
    assert!(is_outflow == false);

    // Test zero inflow, positive outflow
    net_limiter.consume_outflow(500, &clock);
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 500);
    assert!(is_outflow == true);

    // Test additional inflow (cumulative: inflow=1300, outflow=1500)
    net_limiter.consume_inflow(300, &clock);
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 200);
    assert!(is_outflow == true);

    destroy(clock);
}

#[test]
fun inflow_outflow_limiter_access() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &clock,
    );

    // Test that we can access the underlying limiters for read-only inspection
    let inflow_limiter = net_limiter.inflow_limiter();
    let outflow_limiter = net_limiter.outflow_limiter();

    assert!(inflow_limiter.total_sum() == 0);
    assert!(outflow_limiter.total_sum() == 0);

    // Consume values through net limiter and verify through underlying limiters
    net_limiter.consume_inflow(1000, &clock);
    net_limiter.consume_outflow(500, &clock);

    // Re-access limiters to check updated state
    let inflow_limiter = net_limiter.inflow_limiter();
    let outflow_limiter = net_limiter.outflow_limiter();

    assert!(inflow_limiter.total_sum() == 1000);
    assert!(outflow_limiter.total_sum() == 500);

    destroy(clock);
}

#[test, expected_failure(abort_code = net_sliding_sum_limiter::ENetLimitExceeded)]
fun consume_inflow_aborts_on_max_net_inflow_limit_exceeded() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::some(1000),
        option::none(),
        &clock,
    );

    net_limiter.consume_inflow(800, &clock);
    net_limiter.consume_outflow(200, &clock);
    // Net is now 600, within limit

    net_limiter.consume_inflow(500, &clock); // Net would be 1100, exceeds inflow limit of 1000

    destroy(clock);
}

#[test, expected_failure(abort_code = net_sliding_sum_limiter::ENetLimitExceeded)]
fun consume_outflow_aborts_on_max_net_outflow_limit_exceeded() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::some(1000),
        &clock,
    );

    net_limiter.consume_inflow(200, &clock);
    net_limiter.consume_outflow(800, &clock);
    // Net is now -600, within outflow limit

    net_limiter.consume_outflow(500, &clock); // Net would be -1100, exceeds outflow limit of 1000

    destroy(clock);
}

#[test]
fun net_limit_getters_and_setters() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::some(5000),
        option::some(3000),
        &clock,
    );

    // Test getters
    assert!(net_limiter.max_net_inflow_limit() == option::some(5000));
    assert!(net_limiter.max_net_outflow_limit() == option::some(3000));

    // Test setters
    net_limiter.set_max_net_inflow_limit(option::some(8000));
    net_limiter.set_max_net_outflow_limit(option::some(4000));

    assert!(net_limiter.max_net_inflow_limit() == option::some(8000));
    assert!(net_limiter.max_net_outflow_limit() == option::some(4000));

    destroy(clock);
}

#[test]
fun net_limit_coverage_comprehensive() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    // Test 1: Only inflow limit set, net inflow (success)
    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::some(1000),
        option::none(),
        &clock,
    );
    net_limiter.consume_inflow(500, &clock);
    net_limiter.consume_outflow(200, &clock);
    // Net is 300, within inflow limit

    // Test 2: Only outflow limit set, net outflow (success)
    let mut net_limiter2 = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::some(1000),
        &clock,
    );
    net_limiter2.consume_inflow(200, &clock);
    net_limiter2.consume_outflow(500, &clock);
    // Net is -300, within outflow limit

    // Test 3: Inflow limit set but net outflow (limit doesn't apply)
    let mut net_limiter3 = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::some(1000),
        option::none(),
        &clock,
    );
    net_limiter3.consume_inflow(100, &clock);
    net_limiter3.consume_outflow(500, &clock);
    // Net is -400 (outflow), inflow limit doesn't apply

    // Test 4: Outflow limit set but net inflow (limit doesn't apply)
    let mut net_limiter4 = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::some(1000),
        &clock,
    );
    net_limiter4.consume_inflow(500, &clock);
    net_limiter4.consume_outflow(100, &clock);
    // Net is 400 (inflow), outflow limit doesn't apply

    // Test 5: Both limits set, both success paths
    let mut net_limiter5 = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::some(1000),
        option::some(1000),
        &clock,
    );
    net_limiter5.consume_inflow(500, &clock);
    net_limiter5.consume_outflow(0, &clock);
    // Net is 500, within inflow limit
    net_limiter5.consume_inflow(0, &clock);
    net_limiter5.consume_outflow(500, &clock);
    // Net is -500, within outflow limit

    destroy(clock);
}

#[test, expected_failure(abort_code = net_sliding_sum_limiter::ENetLimitExceeded)]
fun net_limit_coverage_abort_scenarios() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    // Test 1: Inflow limit exceeded
    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::some(1000),
        option::none(),
        &clock,
    );
    net_limiter.consume_inflow(1000, &clock);
    net_limiter.consume_outflow(0, &clock);
    // Net is exactly 1000, at inflow limit
    
    // Verify we're at the exact limit before attempting to exceed
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 1000);
    assert!(is_outflow == false);
    assert!(net_limiter.max_net_inflow_limit() == option::some(1000));
    assert!(net_limiter.max_net_outflow_limit() == option::none());
    
    net_limiter.consume_inflow(1, &clock); // Should abort

    destroy(clock);
}

#[test, expected_failure(abort_code = net_sliding_sum_limiter::ENetLimitExceeded)]
fun net_limit_coverage_abort_outflow_scenario() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    // Test 2: Outflow limit exceeded
    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::some(1000),
        &clock,
    );
    net_limiter.consume_inflow(0, &clock);
    net_limiter.consume_outflow(1000, &clock);
    // Net is exactly -1000, at outflow limit
    
    // Verify we're at the exact limit before attempting to exceed
    let (net_amount, is_outflow) = net_limiter.net_value();
    assert!(net_amount == 1000);
    assert!(is_outflow == true);
    assert!(net_limiter.max_net_inflow_limit() == option::none());
    assert!(net_limiter.max_net_outflow_limit() == option::some(1000));
    
    net_limiter.consume_outflow(1, &clock); // Should abort

    destroy(clock);
}

// Regression test for the cross-side staleness bug in `check_net_limits`.
//
// `consume_inflow` and `consume_outflow` each advance only their own side's
// `RingAggregator`. `check_net_limits` then reads `total_sum()` from BOTH
// sides — a cached field that is only refreshed inside `advance_and_add`.
// If a `consume_*` call happens after a long enough quiet period for the
// opposite side's buckets to have rolled out of the window, the cap-check
// runs against a stale total and can pick the wrong limit branch, allowing
// the actual net to exceed `max_net_outflow_limit` (or `max_net_inflow_limit`).
#[test, expected_failure(abort_code = net_sliding_sum_limiter::ENetLimitExceeded)]
fun consume_outflow_aborts_when_stale_inflow_would_otherwise_bypass_net_outflow_cap() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10_000_000);

    // 5-minute buckets, 12 buckets = 1-hour window.
    // No per-direction caps; only max_net_outflow_limit = 500.
    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::some(500),
        &clock,
    );

    // t=0: large inflow lands in bucket 0.
    net_limiter.consume_inflow(1500, &clock);

    // t = 65 min: the full 1-hour window has rolled. The bucket holding
    // the 1500 should have been zeroed ~5 minutes after t=0, but the
    // inflow side has not been advanced since — its cached `total_sum`
    // is still 1500.
    clock.set_for_testing(10_000_000 + 65 * 60 * 1000);

    // Should abort with ENetLimitExceeded: the actual within-window net is
    // 800 outflow, which exceeds the 500 max_net_outflow_limit.
    //
    // BUG: stale inflow.total_sum() = 1500 makes net_value() return
    // (700, false) ("inflow-dominant"), so check_net_limits consults
    // max_net_inflow_limit (= None) and the 800 outflow passes.
    net_limiter.consume_outflow(800, &clock);

    destroy(clock);
}

// Verifies the read-only `*_at` getters report fresh windowed values without
// requiring a consume/advance, while the cached getters retain their
// last-advance snapshots until the next consume.
#[test]
fun at_getters_report_fresh_values_while_cached_getters_remain_stale() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10_000_000);

    let mut net_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000,
        12,
        option::none(),
        option::none(),
        option::none(),
        option::none(),
        &clock,
    );

    // t=0: inflow lands in the window.
    net_limiter.consume_inflow(1500, &clock);

    // Same clock — cached and _at agree.
    assert!(net_limiter.inflow_total() == 1500);
    assert!(net_limiter.inflow_total_at(&clock) == 1500);
    assert!(net_limiter.outflow_total() == 0);
    assert!(net_limiter.outflow_total_at(&clock) == 0);
    let (net, is_outflow) = net_limiter.net_value();
    assert!(net == 1500);
    assert!(is_outflow == false);
    let (net_at, is_outflow_at) = net_limiter.net_value_at(&clock);
    assert!(net_at == 1500);
    assert!(is_outflow_at == false);

    // t=65min: full window has rolled. No consume happens — cached values
    // remain frozen at their last-advance state.
    clock.set_for_testing(10_000_000 + 65 * 60 * 1000);

    assert!(net_limiter.inflow_total() == 1500);          // cached, stale
    assert!(net_limiter.outflow_total() == 0);            // cached
    let (net_cached, is_outflow_cached) = net_limiter.net_value();
    assert!(net_cached == 1500);                          // cached, stale
    assert!(is_outflow_cached == false);

    // _at variants reflect the actual rolled-out window.
    assert!(net_limiter.inflow_total_at(&clock) == 0);    // fresh
    assert!(net_limiter.outflow_total_at(&clock) == 0);   // fresh
    let (net_at2, is_outflow_at2) = net_limiter.net_value_at(&clock);
    assert!(net_at2 == 0);
    assert!(is_outflow_at2 == false);

    // Read-only invariant: the _at calls did not mutate the cached state.
    assert!(net_limiter.inflow_total() == 1500);
    let (net_cached2, _) = net_limiter.net_value();
    assert!(net_cached2 == 1500);

    destroy(clock);
}

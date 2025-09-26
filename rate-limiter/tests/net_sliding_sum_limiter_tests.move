#[test_only]
module rate_limiter::net_sliding_sum_limiter_tests;

use rate_limiter::net_sliding_sum_limiter;
use rate_limiter::sliding_sum_limiter;
use sui::clock;
use sui::test_utils::destroy;

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

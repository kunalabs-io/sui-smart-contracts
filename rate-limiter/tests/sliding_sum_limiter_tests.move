#[test_only]
module rate_limiter::sliding_sum_limiter_tests;

use rate_limiter::sliding_sum_limiter;
use sui::clock;
use sui::test_utils::destroy;

fun empty_buckets(count: u64): vector<u128> {
    let mut buckets = vector::empty();
    count.do!(|_| {
        vector::push_back(&mut buckets, 0);
    });
    buckets
}

#[test]
fun consume_is_correct() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let one_minute = 60 * 1000;

    let mut limiter = sliding_sum_limiter::new(5 * one_minute, 12, option::none(), &clock);
    assert!(limiter.total_sum() == 0);
    assert!(limiter.max_sum_limit() == option::none());
    let ring_aggregator = limiter.ring_aggregator();
    assert!(ring_aggregator.total_sum() == 0);
    assert!(ring_aggregator.current_position() == 10000_000);
    assert!(ring_aggregator.bucket_width() == 5 * one_minute);
    assert!(ring_aggregator.bucket_count() == 12);
    assert!(ring_aggregator.borrow_buckets() == &empty_buckets(12));

    // consume
    limiter.consume(1000, &clock);
    assert!(limiter.total_sum() == 1000);
    assert!(limiter.ring_aggregator().current_position() == 10000_000);

    limiter.consume(2000, &clock);
    assert!(limiter.total_sum() == 3000);
    assert!(limiter.ring_aggregator().current_position() == 10000_000);

    // advance and consume
    clock::set_for_testing(&mut clock, 13500000 - 1); // ~58 minutes (align with very end of 8th bucket)
    limiter.consume(4000, &clock);
    assert!(limiter.total_sum() == 7000);
    assert!(
        limiter.ring_aggregator().current_position() == 13500000 - 1
    );

    // advance and consume should overwrite the existing bucket
    clock::increment_for_testing(&mut clock, 1); // 1ms
    limiter.consume(5000, &clock);
    assert!(limiter.total_sum() == 9000);
    assert!(
        limiter.ring_aggregator().current_position() == 13500000
    );

    // advance for more than one hour
    clock::increment_for_testing(&mut clock, 60 * 70 * 1000); // 1 hour + 10 minutes
    limiter.consume(6000, &clock);
    assert!(limiter.total_sum() == 6000);
    assert!(
        limiter.ring_aggregator().current_position() == 13500000 + 60 * 70 * 1000
    );

    destroy(clock);
}

#[test, expected_failure(abort_code = sliding_sum_limiter::EMaxSumLimitExceeded)]
fun consume_aborts_on_max_sum_limit_exceeded() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);

    clock.set_for_testing(10000_000);

    let mut limiter = sliding_sum_limiter::new(5 * 60 * 1000, 12, option::some(5000), &clock);
    assert!(limiter.max_sum_limit() == option::some(5000));
    limiter.consume(1000, &clock);
    assert!(limiter.total_sum() == 1000);
    limiter.consume(1000, &clock);
    assert!(limiter.total_sum() == 2000);

    limiter.set_max_sum_limit(option::some(2100));
    limiter.consume(1000, &clock); // should abort

    destroy(clock);
}

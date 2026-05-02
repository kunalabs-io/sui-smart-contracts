#[test_only]
module rate_limiter::ring_aggregator_tests;

use rate_limiter::ring_aggregator;

fun filled_buckets(count: u64, value: u128): vector<u128> {
    let mut buckets = vector::empty();
    count.do!(|_| {
        vector::push_back(&mut buckets, value);
    });
    buckets
}

fun empty_buckets(count: u64): vector<u128> {
    filled_buckets(count, 0)
}

#[test]
fun advance_and_add_is_correct() {
    let mut agg = ring_aggregator::new(10, 7);

    let mut exp_buckets = empty_buckets(7);
    assert!(agg.bucket_width() == 10);
    assert!(agg.bucket_count() == 7);
    assert!(agg.current_position() == 0);
    assert!(agg.total_sum() == 0);
    assert!(agg.borrow_buckets() == &exp_buckets);

    // initial add
    agg.advance_and_add(12, 5);
    *exp_buckets.borrow_mut(1) = 5;
    assert!(agg.borrow_buckets() == &exp_buckets);
    assert!(agg.current_position() == 12);
    assert!(agg.total_sum() == 5);

    // add to same position
    agg.advance_and_add(12, 6);
    *exp_buckets.borrow_mut(1) = 11;
    assert!(agg.borrow_buckets() == &exp_buckets);
    assert!(agg.current_position() == 12);
    assert!(agg.total_sum() == 11);

    // add to next position
    agg.advance_and_add(28, 7);
    *exp_buckets.borrow_mut(2) = 7;
    assert!(agg.borrow_buckets() == &exp_buckets);
    assert!(agg.current_position() == 28);
    assert!(agg.total_sum() == 18);

    // add to position two over
    agg.advance_and_add(48, 8);
    *exp_buckets.borrow_mut(4) = 8;
    assert!(agg.borrow_buckets() == &exp_buckets);
    assert!(agg.current_position() == 48);
    assert!(agg.total_sum() == 26);

    // add to position loops around
    agg.advance_and_add(71, 9);
    *exp_buckets.borrow_mut(0) = 9;
    assert!(agg.borrow_buckets() == &exp_buckets);
    assert!(agg.current_position() == 71);
    assert!(agg.total_sum() == 35);

    // add to position will overwrite existing bucket
    agg.advance_and_add(94, 10);
    *exp_buckets.borrow_mut(1) = 0;
    *exp_buckets.borrow_mut(2) = 10;
    assert!(agg.borrow_buckets() == &exp_buckets);
    assert!(agg.current_position() == 94);
    assert!(agg.total_sum() == 27);

    // loops around many times
    let next_position = 70 * (2 << 64) + 33; // bucket index 3
    agg.advance_and_add(next_position, 11);
    let mut exp_buckets = empty_buckets(7);
    *exp_buckets.borrow_mut(3) = 11;
    assert!(agg.borrow_buckets() == &exp_buckets);
    assert!(agg.current_position() == next_position);
    assert!(agg.total_sum() == 11);

    // new with initial position
    let agg = ring_aggregator::new_with_initial_position(10, 7, 100);
    assert!(agg.bucket_width() == 10);
    assert!(agg.bucket_count() == 7);
    assert!(agg.current_position() == 100);
    assert!(agg.total_sum() == 0);
    assert!(agg.borrow_buckets() == &empty_buckets(7));
}

#[test]
fun advance_moves_to_correct_bucket() {
    let mut agg = ring_aggregator::new(10, 4);

    // fill all buckets with 1
    agg.advance_and_add(10, 1);
    agg.advance_and_add(20, 1);
    agg.advance_and_add(30, 1);
    agg.advance_and_add(47, 1);

    let mut exp_buckets = filled_buckets(4, 1);
    assert!(agg.borrow_buckets() == &exp_buckets);

    agg.advance_and_add(48, 1);
    *exp_buckets.borrow_mut(0) = 2;
    assert!(agg.borrow_buckets() == &exp_buckets);

    agg.advance_and_add(50, 5);
    *exp_buckets.borrow_mut(1) = 5;
    assert!(agg.borrow_buckets() == &exp_buckets);

    agg.advance_and_add(51, 5);
    *exp_buckets.borrow_mut(1) = 10;
    assert!(agg.borrow_buckets() == &exp_buckets);

    agg.advance_and_add(70, 5);
    *exp_buckets.borrow_mut(2) = 0;
    *exp_buckets.borrow_mut(3) = 5;
    assert!(agg.borrow_buckets() == &exp_buckets);
}

#[test, expected_failure(abort_code = ring_aggregator::EInvalidPosition)]
fun advance_and_add_aborts_on_invalid_position() {
    let mut agg = ring_aggregator::new(10, 7);
    agg.advance_and_add(12, 5);
    assert!(agg.current_position() == 12);
    assert!(agg.total_sum() == 5);

    agg.advance_and_add(10, 6);
}

#[test]
fun total_sum_at_returns_cached_when_position_unchanged() {
    let mut agg = ring_aggregator::new(10, 7);
    agg.advance_and_add(0, 1);
    agg.advance_and_add(10, 2);
    agg.advance_and_add(20, 3);

    // Same position as current — no buckets have rolled out.
    assert!(agg.total_sum_at(20) == 6);

    // Read-only invariant: cached state unchanged.
    assert!(agg.total_sum() == 6);
    assert!(agg.current_position() == 20);
}

#[test]
fun total_sum_at_subtracts_rolled_out_buckets() {
    let mut agg = ring_aggregator::new(10, 7);
    // Fill all 7 buckets with 1, 2, ..., 7.
    agg.advance_and_add(0, 1);
    agg.advance_and_add(10, 2);
    agg.advance_and_add(20, 3);
    agg.advance_and_add(30, 4);
    agg.advance_and_add(40, 5);
    agg.advance_and_add(50, 6);
    agg.advance_and_add(60, 7);
    assert!(agg.total_sum() == 28);

    // Same position — nothing rolled out.
    assert!(agg.total_sum_at(60) == 28);

    // 1 step forward (position 70..79 = bucket index 0): bucket 0 (value 1)
    // would roll out.
    assert!(agg.total_sum_at(70) == 27);
    assert!(agg.total_sum_at(75) == 27);

    // 2 steps forward (position 80..89): buckets at indices 0, 1
    // (values 1, 2) would roll out.
    assert!(agg.total_sum_at(80) == 25);

    // 6 steps forward (position 120): buckets 0..5 (values 1..6) roll out;
    // only bucket 6 (value 7) remains.
    assert!(agg.total_sum_at(120) == 7);

    // 7 steps forward (position 130): full window has rolled, all out.
    assert!(agg.total_sum_at(130) == 0);

    // Far in the future: still 0.
    assert!(agg.total_sum_at(1_000_000) == 0);

    // After all those reads, cached state is unchanged.
    assert!(agg.total_sum() == 28);
    assert!(agg.current_position() == 60);
}

#[test, expected_failure(abort_code = ring_aggregator::EInvalidPosition)]
fun total_sum_at_aborts_on_backward_position() {
    let mut agg = ring_aggregator::new(10, 7);
    agg.advance_and_add(50, 5);
    // Reading at a position before current_position is not meaningful for a
    // sliding-window aggregator and should abort.
    let _ = agg.total_sum_at(40);
}

#[test, expected_failure(abort_code = ring_aggregator::EInvalidBucketWidth)]
fun new_aborts_on_zero_bucket_width() {
    let _ = ring_aggregator::new(0, 7);
}

#[test, expected_failure(abort_code = ring_aggregator::EInvalidBucketCount)]
fun new_aborts_on_zero_bucket_count() {
    let _ = ring_aggregator::new(10, 0);
}

#[test, expected_failure(abort_code = ring_aggregator::EInvalidBucketWidth)]
fun new_with_initial_position_aborts_on_zero_bucket_width() {
    let _ = ring_aggregator::new_with_initial_position(0, 7, 100);
}

#[test, expected_failure(abort_code = ring_aggregator::EInvalidBucketCount)]
fun new_with_initial_position_aborts_on_zero_bucket_count() {
    let _ = ring_aggregator::new_with_initial_position(10, 0, 100);
}

module token_distribution::primitives_util {
    use sui::clock::{Self, Clock};

    /// Get current clock timestamp in seconds.
    public fun timestamp_sec(clock: &Clock): u64 {
        clock::timestamp_ms(clock) / 1000
    }

    #[test_only]
    use sui::tx_context;

    #[test]
    fun test_timstamp_sec() {
        let ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);

        assert!(timestamp_sec(&clock) == 0, 0);

        clock::increment_for_testing(&mut clock, 900);
        assert!(timestamp_sec(&clock) == 0, 0);

        clock::increment_for_testing(&mut clock, 100);
        assert!(timestamp_sec(&clock) == 1, 0);

        clock::increment_for_testing(&mut clock, 500);
        assert!(timestamp_sec(&clock) == 1, 0);
        
        clock::increment_for_testing(&mut clock, 700);
        assert!(timestamp_sec(&clock) == 2, 0);

        clock::increment_for_testing(&mut clock, 500);
        assert!(timestamp_sec(&clock) == 2, 0);

        clock::increment_for_testing(&mut clock, 500);
        assert!(timestamp_sec(&clock) == 3, 0);

        clock::destroy_for_testing(clock);
    }
}
module kai::util {
    use sui::clock::{Self, Clock};

    /// Get current clock timestamp in seconds.
    public fun timestamp_sec(clock: &Clock): u64 {
        clock::timestamp_ms(clock) / 1000
    }

    public fun muldiv(a: u64, b: u64, c: u64): u64 {
        (((a as u128) * (b as u128)) / (c as u128) as u64)
    }

    public fun muldiv_round_up(a: u64, b: u64, c: u64): u64 {
        let ab = (a as u128) * (b as u128);
        let c = (c as u128);
        if (ab % c == 0) {
            ((ab / c) as u64)
        } else {
            ((ab / c + 1) as u64)
        }
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

    #[test]
    fun test_muldiv_round_up() {
        assert!(muldiv_round_up(0, 0, 1) == 0, 0);
        assert!(muldiv_round_up(2, 1, 1) == 2, 0);
        assert!(muldiv_round_up(2, 2, 1) == 4, 0);
        assert!(muldiv_round_up(2, 2, 2) == 2, 0);
        assert!(muldiv_round_up(2, 2, 3) == 2, 0);
        assert!(muldiv_round_up(2, 2, 4) == 1, 0);
        assert!(muldiv_round_up(2, 2, 5) == 1, 0);
    }
}
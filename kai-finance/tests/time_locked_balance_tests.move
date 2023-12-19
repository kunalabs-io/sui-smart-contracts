module yieldoptimizer::time_locked_balance_tests {
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use yieldoptimizer::time_locked_balance as tlb;
    use yieldoptimizer::time_locked_balance::{TimeLockedBalance};

    struct FOO has  drop {}

    fun assert_tlb_values<T>(
        tlb: &TimeLockedBalance<T>,
        exp_locked_value: u64,
        exp_unlock_start_ts: u64,
        exp_unlock_per_second: u64,
        exp_unlocked_value: u64,
        exp_final_unlock_ts: u64
    ) {
        let (
            act_locked_value,
            act_unlock_start_ts,
            act_unlock_per_second,
            act_unlocked_value,
            act_final_unlock_ts
        ) = tlb::get_all_values(tlb);
        assert!(exp_locked_value == act_locked_value, 0);
        assert!(exp_unlock_start_ts == act_unlock_start_ts, 0);
        assert!(exp_unlock_per_second == act_unlock_per_second, 0);
        assert!(exp_unlocked_value == act_unlocked_value, 0);
        assert!(exp_final_unlock_ts == act_final_unlock_ts, 0);
    }

    fun assert_and_destroy_balance<T>(balance: Balance<T>, value: u64) {
        assert!(balance::value(&balance) == value, 0);
        balance::destroy_for_testing(balance);
    }

    fun create_clock_at_sec(ts: u64, ctx: &mut TxContext): Clock {
        let clock = clock::create_for_testing(ctx);
        clock::set_for_testing(&mut clock, ts * 1000);
        clock
    }

    fun set_clock_sec(clock: &mut Clock, ts: u64) {
        clock::set_for_testing(clock, ts * 1000);
    }

    fun increment_clock_sec(clock: &mut Clock, ts: u64) {
        clock::increment_for_testing(clock, ts * 1000);
    }

    #[test]
    fun test_create_clock_locked_balance() {
        // 10 seconds, round
        let tlb = tlb::create(
            balance::create_for_testing<FOO>(100), 133, 10
        );
        assert_tlb_values(&tlb, 100, 133, 10, 0, 143);
        tlb::destroy_for_testing(tlb);

        // 10 seconds, with extraneous
        let tlb = tlb::create(
            balance::create_for_testing<FOO>(101), 133, 10
        );
        assert_tlb_values(&tlb, 101, 133, 10, 0, 143);
        tlb::destroy_for_testing(tlb);

        // zero balance
        let tlb = tlb::create(
            balance::create_for_testing<FOO>(0), 133, 10
        );
        assert_tlb_values(&tlb, 0, 133, 10, 0, 133);
        tlb::destroy_for_testing(tlb);

        // zero unlock per second
        let tlb = tlb::create(
            balance::create_for_testing<FOO>(100), 133, 0
        );
        assert_tlb_values(&tlb, 100, 133, 0, 0, 0);
        tlb::destroy_for_testing(tlb);
    }

    #[test]
    fun test_extraneous_locked_amount() {
        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        ); 
        assert!(tlb::extraneous_locked_amount(&tlb) == 7, 0);
        tlb::destroy_for_testing(tlb); 

        // unlock_per_second is 0
        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 0
        ); 
        assert!(tlb::extraneous_locked_amount(&tlb) == 1021, 0);
        tlb::destroy_for_testing(tlb); 
    }

    #[test]
    fun test_max_withdrawable() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check

        // clock 100
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 0, 0);

        // clock 158
        set_clock_sec(&mut clock, 158);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 0, 0);

        // clock 159
        increment_clock_sec(&mut clock, 1);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 13, 0);

        // clock 161
        increment_clock_sec(&mut clock, 2);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 39, 0);

        // clock 400
        set_clock_sec(&mut clock, 400);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 1014, 0);

        // clock 161, withdraw
        clock::destroy_for_testing(clock);
        let clock = create_clock_at_sec(161, ctx);

        balance::destroy_for_testing(tlb::withdraw(&mut tlb, 0, &clock));
        assert_tlb_values(&tlb, 982, 158, 13, 39, 236); // sanity check
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 39, 0);

        balance::destroy_for_testing(tlb::withdraw(&mut tlb, 15, &clock));
        assert_tlb_values(&tlb, 982, 158, 13, 24, 236); // sanity check
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 24, 0);

        // clock 164
        increment_clock_sec(&mut clock, 3);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 63, 0);

        // clock 400
        set_clock_sec(&mut clock, 400);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 999, 0);

        // clean up
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 999);
        assert_and_destroy_balance(tlb::skim_extraneous_balance(&mut tlb), 7);
        tlb::destroy_empty(tlb); 

        // unlock per second 0
        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 0
        );
        assert_tlb_values(&tlb, 1021, 158, 0, 0, 0); // sanity check


        clock::destroy_for_testing(clock);
        let clock = create_clock_at_sec(100, ctx);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 0, 0);
        set_clock_sec(&mut clock, 200);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 0, 0);
        set_clock_sec(&mut clock, 400);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 0, 0);

        // clean up
        assert_and_destroy_balance(tlb::skim_extraneous_balance(&mut tlb), 1021);
        tlb::destroy_empty(tlb); 

        // initial balance 0
        let tlb = tlb::create(
            balance::create_for_testing<FOO>(0), 158, 13
        );
        assert_tlb_values(&tlb, 0, 158, 13, 0, 158); // sanity check

        clock::destroy_for_testing(clock);
        let clock = create_clock_at_sec(100, ctx);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 0, 0);
        set_clock_sec(&mut clock, 200);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 0, 0);
        set_clock_sec(&mut clock, 400);
        assert!(tlb::max_withdrawable(&mut tlb, &clock) == 0, 0);

        // clean up
        tlb::destroy_empty(tlb); 
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_remaining_unlock() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check

        // before start
        assert!(tlb::remaining_unlock(&tlb, &clock) == 1014, 0);

        // at start
        set_clock_sec(&mut clock, 158);
        assert!(tlb::remaining_unlock(&tlb, &clock) == 1014, 0);
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check

        // one second later
        set_clock_sec(&mut clock, 159);
        assert!(tlb::remaining_unlock(&tlb, &clock) == 1001, 0);
        assert!(tlb::max_withdrawable(&tlb, &clock) == 13, 0); // sanity check
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 13); // sanity check
        assert_tlb_values(&tlb, 1008, 158, 13, 0, 236); // sanity check

        // unlock_per_second 0
        tlb::change_unlock_per_second(&mut tlb, 0, &clock);
        assert!(tlb::remaining_unlock(&tlb, &clock) == 0, 0);
        assert_tlb_values(&tlb, 1008, 158, 0, 0, 0); // sanity check
        tlb::change_unlock_per_second(&mut tlb, 13, &clock); // change back to 13
        assert_tlb_values(&tlb, 1008, 158, 13, 0, 236); // sanity check

        // one second before end
        set_clock_sec(&mut clock, 235);
        assert!(tlb::remaining_unlock(&tlb, &clock) == 13, 0);

        // at end
        set_clock_sec(&mut clock, 236);
        assert!(tlb::remaining_unlock(&tlb, &clock) == 0, 0);

        // after end
        set_clock_sec(&mut clock, 300);
        assert!(tlb::remaining_unlock(&tlb, &clock) == 0, 0);

        // clean up
        tlb::destroy_for_testing(tlb); 
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_withdraw() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check

        // clock 100
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 0, &clock), 0);

        // clock 158
        set_clock_sec(&mut clock, 158);
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 0, &clock), 0);

        // clock 159
        increment_clock_sec(&mut clock, 1);
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 7, &clock), 7);
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 6, &clock), 6);
        assert_tlb_values(&tlb, 1008, 158, 13, 0, 236); // sanity check

        // clock 161, 162, and 163
        increment_clock_sec(&mut clock, 2);
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 7, &clock), 7);
        assert_tlb_values(&tlb, 982, 158, 13, 19, 236); // sanity check

        increment_clock_sec(&mut clock, 1);
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 10, &clock), 10);
        assert_tlb_values(&tlb, 969, 158, 13, 22, 236); // sanity check

        increment_clock_sec(&mut clock, 1);
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 23, &clock), 23);
        assert_tlb_values(&tlb, 956, 158, 13, 12, 236); // sanity check

        // clock 300
        set_clock_sec(&mut clock, 300);
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 951, &clock), 951);
        assert_tlb_values(&tlb, 7, 158, 13, 10, 236); // sanity check

        increment_clock_sec(&mut clock, 10);
        assert_and_destroy_balance(tlb::withdraw(&mut tlb, 10, &clock), 10);
        assert_tlb_values(&tlb, 7, 158, 13, 0, 236); // sanity check

        // clean up
        assert_and_destroy_balance(tlb::skim_extraneous_balance(&mut tlb), 7);
        tlb::destroy_empty(tlb); 
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = balance::ENotEnough)]
    public fun test_withdraw_fails_on_amount_too_large() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check 

        // clock 159
        increment_clock_sec(&mut clock, 1);
        let out = tlb::withdraw(&mut tlb, 14, &clock); // should fail

        // clean up
        tlb::destroy_empty(tlb); 
        clock::destroy_for_testing(clock);
        balance::destroy_for_testing(out);
    }

    #[test]
    public fun test_withdraw_all() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check

        // clock 100
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 0);

        // clock 158
        set_clock_sec(&mut clock, 158);
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 0);

        // clock 159
        increment_clock_sec(&mut clock, 1);
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 13);
        assert_tlb_values(&tlb, 1008, 158, 13, 0, 236); // sanity check

        // clock 161
        increment_clock_sec(&mut clock, 2);
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 26);
        assert_tlb_values(&tlb, 982, 158, 13, 0, 236); // sanity check

        // clock 300
        set_clock_sec(&mut clock, 300);
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 975);
        assert_tlb_values(&tlb, 7, 158, 13, 0, 236); // sanity check

        increment_clock_sec(&mut clock, 10);
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 0);
        assert_tlb_values(&tlb, 7, 158, 13, 0, 236); // sanity check

        // clean up
        assert_and_destroy_balance(tlb::skim_extraneous_balance(&mut tlb), 7);
        tlb::destroy_empty(tlb); 
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_top_up() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity checks
        assert!(tlb::extraneous_locked_amount(&tlb) == 7, 0);

        // add round
        tlb::top_up(&mut tlb, balance::create_for_testing<FOO>(13), &clock);
        assert_tlb_values(&tlb, 1034, 158, 13, 0, 237);
        assert!(tlb::extraneous_locked_amount(&tlb) == 7, 0);

        // add not enough to round
        tlb::top_up(&mut tlb, balance::create_for_testing<FOO>(5), &clock);
        assert_tlb_values(&tlb, 1039, 158, 13, 0, 237);
        assert!(tlb::extraneous_locked_amount(&tlb) == 12, 0);

        // add just enough to round
        tlb::top_up(&mut tlb, balance::create_for_testing<FOO>(1), &clock);
        assert_tlb_values(&tlb, 1040, 158, 13, 0, 238);
        assert!(tlb::extraneous_locked_amount(&tlb) == 0, 0);

        // after start
        set_clock_sec(&mut clock, 159);
        tlb::top_up(&mut tlb, balance::create_for_testing(25), &clock);
        assert_tlb_values(&tlb, 1052, 158, 13, 13, 239);
        assert!(tlb::extraneous_locked_amount(&tlb) == 12, 0);

        // after finish
        set_clock_sec(&mut clock, 300);
        tlb::top_up(&mut tlb, balance::create_for_testing(1), &clock);
        assert_tlb_values(&tlb, 13, 158, 13, 1053, 301);

        // clean up
        balance::destroy_for_testing(tlb::skim_extraneous_balance(&mut tlb));
        tlb::destroy_for_testing(tlb); 
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_change_unlock_per_second() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check

        // change unlock_per_second to 11
        // unlock no rewards, change to 11, update final_unlock_ts
        tlb::change_unlock_per_second(&mut tlb, 11, &clock);
        assert_tlb_values(&tlb, 1021, 158, 11, 0, 250);

        // change unlock_per_second back to 13
        // unlock no rewards, change to 11, update final_unlock_ts
        tlb::change_unlock_per_second(&mut tlb, 13, &clock);
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236);

        // move clock and then change to 11
        // unlock 13 rewards, change to 11, update final_unlock_ts
        set_clock_sec(&mut clock, 159);
        tlb::change_unlock_per_second(&mut tlb, 11, &clock);
        assert_tlb_values(&tlb, 1008, 158, 11, 13, 250);

        // change to 0
        // unlock to rewards, update final_unlock_ts to 0
        set_clock_sec(&mut clock, 159);
        tlb::change_unlock_per_second(&mut tlb, 0, &clock);
        assert_tlb_values(&tlb, 1008, 158, 0, 13, 0);

        // change back to 11
        tlb::change_unlock_per_second(&mut tlb, 11, &clock);
        assert_tlb_values(&tlb, 1008, 158, 11, 13, 250);

        // move clock to 249 and change to 19
        // updating to 19 implies that final_unlock_ts is at the current clockstamp
        set_clock_sec(&mut clock, 249);
        tlb::change_unlock_per_second(&mut tlb, 19, &clock);
        assert_tlb_values(&tlb, 18, 158, 19, 1003, 249);

        // move clock to 300 and change to 9
        // unlocks no rewards, updates final_unlock_ts to 302
        set_clock_sec(&mut clock, 300);
        tlb::change_unlock_per_second(&mut tlb, 9, &clock);
        assert_tlb_values(&tlb, 18, 158, 9, 1003, 302);

        // move clock to 302 and unlock all rewards
        increment_clock_sec(&mut clock, 2);
        assert_and_destroy_balance(tlb::withdraw_all(&mut tlb, &clock), 1021);
        assert_tlb_values(&tlb, 0, 158, 9, 0, 302);

        // clean up
        tlb::destroy_empty(tlb); 
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_change_unlock_start_ts() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check 

        // change 8 seconds back (unlocks not yet started)
        tlb::change_unlock_start_ts_sec(&mut tlb, 150, &clock);
        assert_tlb_values(&tlb, 1021, 150, 13, 0, 228);

        // change to past (doesn't go below current clock)
        tlb::change_unlock_start_ts_sec(&mut tlb, 99, &clock);
        assert_tlb_values(&tlb, 1021, 100, 13, 0, 178);

        // forward clock and move unlock to future
        set_clock_sec(&mut clock, 102);
        tlb::change_unlock_start_ts_sec(&mut tlb, 110, &clock);
        assert_tlb_values(&tlb, 995, 110, 13, 26, 186);

        // forward clock and move unlock to past
        set_clock_sec(&mut clock, 111);
        tlb::change_unlock_start_ts_sec(&mut tlb, 100, &clock);
        assert_tlb_values(&tlb, 982, 111, 13, 39, 186);

        // clean up
        tlb::destroy_for_testing(tlb);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_skim_extraneous_balance() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(100, ctx);

        let tlb = tlb::create(
            balance::create_for_testing<FOO>(1021), 158, 13
        );
        assert_tlb_values(&tlb, 1021, 158, 13, 0, 236); // sanity check

        // skim
        assert_and_destroy_balance(tlb::skim_extraneous_balance(&mut tlb), 7);
        assert_tlb_values(&tlb, 1014, 158, 13, 0, 236);

        // top up and skim
        tlb::top_up(&mut tlb, balance::create_for_testing(1), &clock);
        assert_and_destroy_balance(tlb::skim_extraneous_balance(&mut tlb), 1);
        assert_tlb_values(&tlb, 1014, 158, 13, 0, 236);

        // top up over round and skim
        tlb::top_up(&mut tlb, balance::create_for_testing(14), &clock);
        assert_and_destroy_balance(tlb::skim_extraneous_balance(&mut tlb), 1);
        assert_tlb_values(&tlb, 1027, 158, 13, 0, 237);

        // skim when unlock_per_second is zero
        tlb::change_unlock_per_second(&mut tlb, 0, &clock);
        assert_and_destroy_balance(tlb::skim_extraneous_balance(&mut tlb), 1027);
        assert_tlb_values(&tlb, 0, 158, 0, 0, 0);

        // clean up
        tlb::destroy_empty(tlb); 
        clock::destroy_for_testing(clock);
    }
}

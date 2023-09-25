#[test_only]
module token_distribution::time_distributor_tests {
    use std::vector;
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use token_distribution::time_distributor as td;
    use token_distribution::time_distributor::{TimeDistributor};

    struct FOO has drop {}

    fun assert_values<T, K: copy>(
        td: &TimeDistributor<T, K>, total_weight: u64, unlocked_balance: u64, update_ts: u64
    ) {
        let (act_total_weight, act_unlocked_balance, act_update_ts) = td::get_values(td);
        assert!(total_weight == act_total_weight, 0);
        assert!(unlocked_balance == act_unlocked_balance, 0);
        assert!(update_ts == act_update_ts, 0);
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
    public fun test_no_balance() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let td = td::create(balance::create_for_testing<FOO>(0), 10);

        assert_values(&td, 0, 0, 0); // sanity checks
        td::assert_members_size(&td, 0);

        // add member
        td::add_member(&mut td, 0, 100, &clock);

        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 0
        );

        assert_values(&td, 100, 0, 50); // sanity checks
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // change unlock_per_second, top up, and withdraw
        set_clock_sec(&mut clock, 60);
        td::change_unlock_per_second(&mut td, 1, &clock);

        set_clock_sec(&mut clock, 70);
        td::top_up(&mut td, balance::create_for_testing(100), &clock);

        set_clock_sec(&mut clock, 80);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 10
        );

        assert_values(&td, 100, 0, 70); // sanity checks
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 10);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_with_one_member() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            vector::singleton(0),
            vector::singleton(100),
            500,
            13,
            &clock
        );
        
        // sanity checks
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // one second before start
        set_clock_sec(&mut clock, 499);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 0
        );

        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // at start
        set_clock_sec(&mut clock, 500);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 0
        );

        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // one second after start
        set_clock_sec(&mut clock, 501);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 13
        );

        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 13);

        // two seconds forward
        increment_clock_sec(&mut clock, 2);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 26
        );

        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 39);

        // after finish
        set_clock_sec(&mut clock, 600);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 949
        );

        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 988);

        // once more after finish
        set_clock_sec(&mut clock, 700);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 0
        );

        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 988);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_with_two_members() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let keys = vector::empty();
        vector::push_back(&mut keys, 0);
        vector::push_back(&mut keys, 1);
        let weights = vector::empty();
        vector::push_back(&mut weights, 300);
        vector::push_back(&mut weights, 100);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            keys,
            weights,
            500,
            13,
            &clock
        );
        
        // sanity check
        assert_values(&td, 400, 0, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // one second before start
        set_clock_sec(&mut clock, 499);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 0
        );
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 1, &clock), 0
        );

        assert_values(&td, 400, 0, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // at start
        set_clock_sec(&mut clock, 500);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 0
        );
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 1, &clock), 0
        );

        assert_values(&td, 400, 0, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // one second after start
        set_clock_sec(&mut clock, 501);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 9
        );
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 1, &clock), 3
        );

        assert_values(&td, 400, 1, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 9);
        td::assert_member_values(&td, 1, &1, 100, 0, 3);

        // two seconds forward
        increment_clock_sec(&mut clock, 2);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 20
        );
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 1, &clock), 6
        );

        assert_values(&td, 400, 1, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 29);
        td::assert_member_values(&td, 1, &1, 100, 0, 9);

        // after finish
        set_clock_sec(&mut clock, 600);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 712
        );
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 1, &clock), 238
        );

        assert_values(&td, 400, 0, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 741);
        td::assert_member_values(&td, 1, &1, 100, 0, 247);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_add_member() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            vector::singleton(0),
            vector::singleton(100),
            500, // start_ts
            13, // unlock_per_second
            &clock
        );

        // sanity check
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // add member before start
        set_clock_sec(&mut clock, 300);

        td::add_member(&mut td, 1, 100, &clock);

        assert_values(&td, 200, 0, 300);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // add member after start
        set_clock_sec(&mut clock, 510);

        td::add_member(&mut td, 2, 100, &clock);

        assert_values(&td, 300, 0, 510);
        td::assert_members_size(&td, 3);
        td::assert_member_values(&td, 0, &0, 100, 65, 0);
        td::assert_member_values(&td, 1, &1, 100, 65, 0);
        td::assert_member_values(&td, 2, &2, 100, 0, 0);

        // add member after end
        set_clock_sec(&mut clock, 600);

        td::add_member(&mut td, 3, 100, &clock);

        assert_values(&td, 400, 0, 600);
        td::assert_members_size(&td, 4);
        td::assert_member_values(&td, 0, &0, 100, 351, 0);
        td::assert_member_values(&td, 1, &1, 100, 351, 0);
        td::assert_member_values(&td, 2, &2, 100, 286, 0);
        td::assert_member_values(&td, 3, &3, 100, 0, 0);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = td::EZeroWeight)]
    public fun test_add_member_fails_on_zero_weight() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            vector::singleton(0),
            vector::singleton(100),
            500, // start_ts
            13, // unlock_per_second
            &clock
        );

        td::add_member(&mut td, 1, 0, &clock);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_remove_member() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let keys = vector::empty();
        vector::push_back(&mut keys, 0);
        vector::push_back(&mut keys, 1);
        vector::push_back(&mut keys, 2);
        vector::push_back(&mut keys, 3);
        let weights = vector::empty();
        vector::push_back(&mut weights, 100);
        vector::push_back(&mut weights, 100); 
        vector::push_back(&mut weights, 100); 
        vector::push_back(&mut weights, 100); 

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            keys,
            weights,
            500,
            13,
            &clock
        );

        // sanity check
        assert_values(&td, 400, 0, 50);
        td::assert_members_size(&td, 4);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);        
        td::assert_member_values(&td, 2, &2, 100, 0, 0);        
        td::assert_member_values(&td, 3, &3, 100, 0, 0);        

        // remove member before start (by key)
        set_clock_sec(&mut clock, 300);

        let (_, b) = td::remove_member(&mut td, &2, &clock);
        assert_and_destroy_balance(b, 0);

        assert_values(&td, 300, 0, 300);
        td::assert_members_size(&td, 3);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);        
        td::assert_member_values(&td, 2, &3, 100, 0, 0);        

        // remove member after start (by idx)
        set_clock_sec(&mut clock, 510);

        let (_, b) = td::remove_member_by_idx(&mut td, 1, &clock);
        assert_and_destroy_balance(b, 43);

        assert_values(&td, 200, 0, 510);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 100, 43, 0);
        td::assert_member_values(&td, 1, &3, 100, 43, 0);        

        // remove member after finish
        set_clock_sec(&mut clock, 600);

        let (_, b) = td::remove_member(&mut td, &3, &clock);
        assert_and_destroy_balance(b, 478);

        assert_values(&td, 100, 0, 600);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 478, 0);

        // remove final member
        set_clock_sec(&mut clock, 700);

        let (_, b) = td::remove_member(&mut td, &0, &clock);
        assert_and_destroy_balance(b, 478);

        assert_values(&td, 0, 0, 700);
        td::assert_members_size(&td, 0);
        assert!(td::unlock_per_second(&td) == 0, 0);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_change_weights() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let keys = vector::empty();
        vector::push_back(&mut keys, 0);
        vector::push_back(&mut keys, 1);
        let weights = vector::empty();
        vector::push_back(&mut weights, 100);
        vector::push_back(&mut weights, 100); 

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            keys,
            weights,
            500,
            13,
            &clock
        );

        // sanity check
        assert_values(&td, 200, 0, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);   

        // change weights before start
        set_clock_sec(&mut clock, 300);

        let idxs = vector::empty();
        vector::push_back(&mut idxs, 0);
        vector::push_back(&mut idxs, 1);
        let weights = vector::empty();
        vector::push_back(&mut weights, 300);
        vector::push_back(&mut weights, 100);

        td::change_weights_by_idxs(&mut td, idxs, weights, &clock);

        assert_values(&td, 400, 0, 300);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);        

        // change weights after start
        set_clock_sec(&mut clock, 520);

        let idxs = vector::empty();
        vector::push_back(&mut idxs, 0);
        let weights = vector::empty();
        vector::push_back(&mut weights, 200);

        td::change_weights_by_idxs(&mut td, idxs, weights, &clock);

        assert_values(&td, 300, 0, 520);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 200, 195, 0);
        td::assert_member_values(&td, 1, &1, 100, 65, 0);        

        // change weights after end
        set_clock_sec(&mut clock, 600);

        let idxs = vector::empty();
        vector::push_back(&mut idxs, 0);
        let weights = vector::empty();
        vector::push_back(&mut weights, 100);

        td::change_weights_by_idxs(&mut td, idxs, weights, &clock);

        assert_values(&td, 200, 0, 600);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 100, 680, 0);
        td::assert_member_values(&td, 1, &1, 100, 307, 0);        

        // once more after end
        increment_clock_sec(&mut clock, 1);

        let idxs = vector::empty();
        vector::push_back(&mut idxs, 0);
        let weights = vector::empty();
        vector::push_back(&mut weights, 200);

        td::change_weights_by_idxs(&mut td, idxs, weights, &clock);

        assert_values(&td, 300, 0, 601);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 200, 686, 0);
        td::assert_member_values(&td, 1, &1, 100, 313, 0);        

        assert!(td::extraneous_locked_amount(&td) == 1, 0);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_change_unlock_per_second() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            vector::singleton(0),
            vector::singleton(100),
            500, // start_ts
            13, // unlock_per_second
            &clock
        );

        // sanity check
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // change before start
        set_clock_sec(&mut clock, 100);

        td::change_unlock_per_second(&mut td, 50, &clock);

        assert!(td::unlock_per_second(&td) == 50, 0);
        assert_values(&td, 100, 0, 100);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // change after start
        set_clock_sec(&mut clock, 510);

        td::change_unlock_per_second(&mut td, 13, &clock);

        assert!(td::unlock_per_second(&td) == 13, 0);
        assert_values(&td, 100, 0, 510);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 500, 0);

        // change after end
        set_clock_sec(&mut clock, 600);

        td::change_unlock_per_second(&mut td, 5, &clock);

        assert!(td::unlock_per_second(&td) == 5, 0);
        assert_values(&td, 100, 0, 600);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 994, 0);

        // withdraw all
        increment_clock_sec(&mut clock, 1);

        assert_and_destroy_balance(
            td::member_withdraw_all(&mut td, &0, &clock), 999
        );

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = td::ENoMembers)]
    public fun test_change_unlock_per_second_fails_when_no_members() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            vector::singleton(0),
            vector::singleton(100),
            500, // start_ts
            13, // unlock_per_second
            &clock
        );

        // sanity check
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // remove member
        set_clock_sec(&mut clock, 510);

        let (_, b) = td::remove_member(&mut td, &0, &clock);
        assert_and_destroy_balance(b, 130);

        assert_values(&td, 0, 0, 510);
        td::assert_members_size(&td, 0);

        // changing unlock per second will fail
        set_clock_sec(&mut clock, 600);
        td::change_unlock_per_second(&mut td, 10, &clock); // fails

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_change_unlock_start_ts() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            vector::singleton(0),
            vector::singleton(100),
            500, // start_ts
            13, // unlock_per_second
            &clock
        );

        // sanity check
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // change before start
        set_clock_sec(&mut clock, 70);

        td::change_unlock_start_ts_sec(&mut td, 200, &clock);

        assert!(td::unlock_start_ts_sec(&td) == 200, 0);
        assert_values(&td, 100, 0, 70);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // change after start
        set_clock_sec(&mut clock, 210);

        td::change_unlock_start_ts_sec(&mut td, 300, &clock);

        assert!(td::unlock_start_ts_sec(&td) == 300, 0);
        assert_values(&td, 100, 0, 210);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 130, 0);

        // witdraw all then set to past (will set to current clock)
        set_clock_sec(&mut clock, 310);

        assert_and_destroy_balance(
            td::member_withdraw_all(&mut td, &0, &clock), 260
        );

        assert!(td::unlock_start_ts_sec(&td) == 300, 0);
        assert_values(&td, 100, 0, 210);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 130);

        set_clock_sec(&mut clock, 320);
        td::change_unlock_start_ts_sec(&mut td, 200, &clock);

        assert!(td::unlock_start_ts_sec(&td) == 320, 0);
        assert_values(&td, 100, 0, 320);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 130, 0);

        // change after end
        set_clock_sec(&mut clock, 1000);

        td::change_unlock_start_ts_sec(&mut td, 1010, &clock);

        assert!(td::unlock_start_ts_sec(&td) == 1010, 0);
        assert_values(&td, 100, 0, 1000);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 728, 0);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_top_up() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            vector::singleton(0),
            vector::singleton(100),
            500, // start_ts
            13, // unlock_per_second
            &clock
        );

        // sanity check
        assert!(td::final_unlock_ts_sec(&td) == 576, 0);
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // top up before start
        set_clock_sec(&mut clock, 70); 

        td::top_up(&mut td, balance::create_for_testing(100), &clock);

        assert!(td::final_unlock_ts_sec(&td) == 584, 0);
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // top up after start
        set_clock_sec(&mut clock, 510); 

        td::top_up(&mut td, balance::create_for_testing(100), &clock);

        assert!(td::final_unlock_ts_sec(&td) == 592, 0);
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // top up at finish
        set_clock_sec(&mut clock, 592); 

        assert_and_destroy_balance(
            td::member_withdraw_all(&mut td, &0, &clock), 1196
        );
        td::top_up(&mut td, balance::create_for_testing(10), &clock);

        increment_clock_sec(&mut clock, 1); 
        assert_and_destroy_balance(
            td::member_withdraw_all(&mut td, &0, &clock), 13
        );

        assert!(td::final_unlock_ts_sec(&td) == 593, 0);
        assert_values(&td, 100, 0, 50);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 1209);

        // top up after finish
        set_clock_sec(&mut clock, 700);

        td::top_up(&mut td, balance::create_for_testing(103), &clock);

        assert!(td::final_unlock_ts_sec(&td) == 708, 0);
        assert_values(&td, 100, 0, 700);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_withdraw_all_then_update() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let keys = vector::empty();
        vector::push_back(&mut keys, 0);
        vector::push_back(&mut keys, 1);
        let weights = vector::empty();
        vector::push_back(&mut weights, 300);
        vector::push_back(&mut weights, 100);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            keys,
            weights,
            500,
            13,
            &clock
        );
        
        // sanity check
        assert_values(&td, 400, 0, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // first member withdraws
        set_clock_sec(&mut clock, 510);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 97
        );

        assert_values(&td, 400, 33, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 97);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // forward 10 seconds and withdraw from second member
        increment_clock_sec(&mut clock, 10); // ts 520
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 1, &clock), 65
        );

        assert_values(&td, 400, 98, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 97);
        td::assert_member_values(&td, 1, &1, 100, 0, 65);

        // forward 10 seconds and trigger update all
        increment_clock_sec(&mut clock, 10); // ts 530
        td::change_unlock_per_second(&mut td, 11, &clock);

        assert_values(&td, 400, 0, 530);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 195, 0);
        td::assert_member_values(&td, 1, &1, 100, 32, 0);

        // withdraw all at the same ts
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 195
        );
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 1, &clock), 32
        );

        assert_values(&td, 400, 0, 530);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // increment by one and withdraw all
        set_clock_sec(&mut clock, 531);

        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 8
        );
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 1, &clock), 2
        );

        assert_values(&td, 400, 1, 530);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 8);
        td::assert_member_values(&td, 1, &1, 100, 0, 2);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }

    #[test]
    public fun test_after_finish() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let keys = vector::empty();
        vector::push_back(&mut keys, 0);
        vector::push_back(&mut keys, 1);
        let weights = vector::empty();
        vector::push_back(&mut weights, 300);
        vector::push_back(&mut weights, 100);

        let td = td::create_with_members(
            balance::create_for_testing<FOO>(1000),
            keys,
            weights,
            500,
            13,
            &clock
        );
        
        // sanity check
        assert_values(&td, 400, 0, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // first member withdraws after finish
        set_clock_sec(&mut clock, 600);
        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 741
        );

        assert_values(&td, 400, 247, 50);
        td::assert_members_size(&td, 2);
        td::assert_member_values(&td, 0, &0, 300, 0, 741);
        td::assert_member_values(&td, 1, &1, 100, 0, 0);

        // increment clock by 10 and remove second member
        set_clock_sec(&mut clock, 610);

        let (_, b) = td::remove_member(&mut td, &1, &clock);
        assert_and_destroy_balance(b, 247);

        assert_values(&td, 300, 0, 610);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);

        // change unlock per second to 12
        td::change_unlock_per_second(&mut td, 12, &clock);

        assert_values(&td, 300, 0, 610);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 300, 0, 0);

        // increment clock by one and remove last member
        set_clock_sec(&mut clock, 611);

        let (_, b) = td::remove_member(&mut td, &0, &clock);
        assert_and_destroy_balance(b, 12);

        assert_values(&td, 0, 0, 611);
        td::assert_members_size(&td, 0);
        assert!(td::extraneous_locked_amount(&td) == 0, 0);

        // increment clock and top up
        set_clock_sec(&mut clock, 700);

        td::top_up(&mut td, balance::create_for_testing(100), &clock);
        assert!(td::extraneous_locked_amount(&td) == 100, 0);

        td::add_member(&mut td, 0, 100, &clock);
        td::change_unlock_per_second(&mut td, 50, &clock);

        assert_values(&td, 100, 0, 700);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 0);

        // increment clock by one second and withdraw
        set_clock_sec(&mut clock, 701);

        assert_and_destroy_balance(
            td::member_withdraw_all_by_idx(&mut td, 0, &clock), 50
        );

        assert_values(&td, 100, 0, 700);
        td::assert_members_size(&td, 1);
        td::assert_member_values(&td, 0, &0, 100, 0, 50);

        // clean up
        td::destroy_for_testing(td);
        clock::destroy_for_testing(clock);
    }
}
#[test_only]
module token_distribution::farm_tests {
    use std::vector;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::object;
    use sui::test_scenario;
    use sui::clock::{Self, Clock};
    use token_distribution::farm::{Self, ForcefulRemovalReceipt};

    // witness types for test coins
    struct FOO has drop {}
    struct BAR has drop {}

    fun assert_and_destroy_balance<T>(balance: Balance<T>, value: u64) {
        assert!(balance::value(&balance) == value, 0);
        balance::destroy_for_testing(balance);
    }

    fun vector_two<T>(first: T, second: T): vector<T> {
        let ret = vector::empty();
        vector::push_back(&mut ret, first);
        vector::push_back(&mut ret, second);
        ret
    }

    fun create_clock_at_sec(ts: u64, ctx: &mut TxContext): Clock {
        let clock = clock::create_for_testing(ctx);
        clock::set_for_testing(&mut clock, ts * 1000);
        clock
    }

    fun set_clock_sec(clock: &mut Clock, ts: u64) {
        clock::set_for_testing(clock, ts * 1000);
    }

    #[test]
    public fun test_add_and_remove_member() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        assert!(farm::key_memberships(&key) == 0, 0); // sanity checks
        assert!(farm::size(&farm) == 0, 0);

        // add member
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);

        assert!(farm::key_memberships(&key) == 1, 0);
        assert!(farm::size(&farm) == 1, 0);

        // remove member
        farm::change_unlock_per_second(&cap, &mut farm, 10, &clock);
        set_clock_sec(&mut clock, 110);

        let balance = farm::remove_member(&mut farm, &mut key, &clock);
        assert_and_destroy_balance(balance, 100);

        assert!(farm::key_memberships(&key) == 0, 0);
        assert!(farm::size(&farm) == 0, 0);

        // add members
        let keys = vector_two(key, farm::create_member_key(ctx));

        farm::add_members(&cap, &mut farm, &mut keys, vector_two(100, 300), &clock);

        let key2 = vector::pop_back(&mut keys);
        let key1 = vector::pop_back(&mut keys);

        assert!(farm::key_memberships(&key1) == 1, 0);
        assert!(farm::key_memberships(&key2) == 1, 0);
        assert!(farm::size(&farm) == 2, 0);

        // remove members
        farm::change_unlock_per_second(&cap, &mut farm, 10, &clock);
        set_clock_sec(&mut clock, 120);

        let balance = farm::remove_member(&mut farm, &mut key1, &clock);
        assert_and_destroy_balance(balance, 25);
        let balance = farm::remove_member(&mut farm, &mut key2, &clock);
        assert_and_destroy_balance(balance, 75);

        assert!(farm::key_memberships(&key1) == 0, 0);
        assert!(farm::key_memberships(&key2) == 0, 0);
        assert!(farm::size(&farm) == 0, 0);

        // clean up
        vector::destroy_empty(keys);
        farm::destroy_member_key(key1);
        farm::destroy_member_key(key2);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::EInvalidAdminCap)]
    public fun test_add_member_aborts_when_admin_cap_wrong() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, wrong_cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&wrong_cap, &mut farm, &mut key, 100, &clock); // aborts here

        // clean up
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        farm::destroy_for_testing(farm2);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(wrong_cap);
    }

    #[test]
    #[expected_failure(abort_code = sui::vec_map::EKeyAlreadyExists)]
    public fun test_add_member_aborts_when_key_already_a_member() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock); // aborts here

        // clean up
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::EKeyLocked)]
    public fun test_add_member_aborts_when_key_locked() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        let ticket = farm::new_withdraw_all_ticket(&mut key);

        farm::add_member(&cap, &mut farm, &mut key, 100, &clock); // aborts here

        // clean up
        farm::destroy_withdraw_all_ticket(ticket, &mut key);
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::EInvalidAdminCap)]
    public fun test_add_members_aborts_when_admin_cap_wrong() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, wrong_cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let keys = vector::singleton(farm::create_member_key(ctx));

        farm::add_members(&wrong_cap, &mut farm, &mut keys, vector::singleton(100), &clock); // aborts here

        // clean up
        let key = vector::pop_back(&mut keys);
        farm::destroy_member_key(key);
        vector::destroy_empty(keys);
        farm::destroy_for_testing(farm);
        farm::destroy_for_testing(farm2);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(wrong_cap);
    }

    #[test]
    #[expected_failure(abort_code = sui::vec_map::EKeyAlreadyExists)]
    public fun test_add_members_aborts_when_key_already_a_member() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);

        let keys = vector_two(farm::create_member_key(ctx), key);
        farm::add_members(&cap, &mut farm, &mut keys, vector_two(100, 100), &clock); // aborts here

        // clean up
        let key = vector::pop_back(&mut keys);
        farm::destroy_member_key(key);
        let key = vector::pop_back(&mut keys);
        farm::destroy_member_key(key);
        vector::destroy_empty(keys);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::EKeyLocked)]
    public fun test_add_members_aborts_when_key_locked() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key1 = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key1, 100, &clock);

        let ticket = farm::new_withdraw_all_ticket(&mut key1);
        let keys = vector_two(farm::create_member_key(ctx), key1);
        farm::add_members(&cap, &mut farm, &mut keys, vector_two(100, 100), &clock); // aborts here

        // clean up
        let key1 = vector::pop_back(&mut keys);
        farm::destroy_withdraw_all_ticket(ticket, &mut key1);
        farm::destroy_member_key(key1);
        let key2 = vector::pop_back(&mut keys);
        farm::destroy_member_key(key2);
        vector::destroy_empty(keys);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::EKeyLocked)]
    public fun test_remove_member_fails_when_key_locked() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);

        let ticket = farm::new_withdraw_all_ticket(&mut key);
        let balance = farm::remove_member(&mut farm, &mut key, &clock); // aborts here
        balance::destroy_for_testing(balance);

        // clean up
        farm::destroy_withdraw_all_ticket(ticket, &mut key);
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
    }

    #[test]
    public fun test_forcefully_remove_member() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);
        farm::change_unlock_per_second(&cap, &mut farm, 10, &clock);
        assert!(farm::key_memberships(&key) == 1, 0); // sanity checks
        assert!(farm::size(&farm) == 1, 0);

        let scenario = test_scenario::begin(@0xABBA);
        {
            let ctx = test_scenario::ctx(&mut scenario);

            set_clock_sec(&mut clock, 110);
            farm::forcefully_remove_member(
                &cap, &mut farm, object::id(&key), &clock, ctx
            );
            assert!(farm::key_memberships(&key) == 1, 0); // sanity checks
            assert!(farm::size(&farm) == 0, 0);
        };
        test_scenario::next_tx(&mut scenario, @0xABBA);
        {
            let receipt = test_scenario::take_shared<ForcefulRemovalReceipt<FOO>>(&mut scenario);

            let balance = farm::redeem_forceful_removal_receipt(&mut receipt, &mut key);
            assert_and_destroy_balance(balance, 100);
            assert!(farm::key_memberships(&key) == 0, 0);
            assert!(farm::size(&farm) == 0, 0);

            test_scenario::return_shared(receipt);
        };
        test_scenario::end(scenario);

        // clean up
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::EReceiptSpent)]
    public fun test_forcefully_remove_member_aborts_on_spent_receipt() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);
        farm::change_unlock_per_second(&cap, &mut farm, 10, &clock);
        assert!(farm::key_memberships(&key) == 1, 0); // sanity checks
        assert!(farm::size(&farm) == 1, 0);

        let scenario = test_scenario::begin(@0xABBA);
        {
            let ctx = test_scenario::ctx(&mut scenario);

            set_clock_sec(&mut clock, 110);
            farm::forcefully_remove_member(
                &cap, &mut farm, object::id(&key), &clock, ctx
            );
            assert!(farm::key_memberships(&key) == 1, 0); // sanity checks
            assert!(farm::size(&farm) == 0, 0);
        };
        test_scenario::next_tx(&mut scenario, @0xABBA);
        {
            let receipt = test_scenario::take_shared<ForcefulRemovalReceipt<FOO>>(&mut scenario);

            let balance = farm::redeem_forceful_removal_receipt(&mut receipt, &mut key);
            assert_and_destroy_balance(balance, 100);
            assert!(farm::key_memberships(&key) == 0, 0);
            assert!(farm::size(&farm) == 0, 0);

            test_scenario::return_shared(receipt);
        };
        test_scenario::next_tx(&mut scenario, @0xABBA);
        {
            let receipt = test_scenario::take_shared<ForcefulRemovalReceipt<FOO>>(&mut scenario);

            let balance = farm::redeem_forceful_removal_receipt(&mut receipt, &mut key); // aborts here
            balance::destroy_for_testing(balance);

            test_scenario::return_shared(receipt);
        };
        test_scenario::end(scenario);

        // clean up
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::EInvalidKey)]
    public fun test_redeem_forceful_removal_receipt_aborts_on_invalid_key() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);
        farm::change_unlock_per_second(&cap, &mut farm, 10, &clock);

        let scenario = test_scenario::begin(@0xABBA);
        {
            let ctx = test_scenario::ctx(&mut scenario);

            set_clock_sec(&mut clock, 110);
            farm::forcefully_remove_member(
                &cap, &mut farm, object::id(&key), &clock, ctx
            );
        };
        test_scenario::next_tx(&mut scenario, @0xABBA);
        {
            let receipt = test_scenario::take_shared<ForcefulRemovalReceipt<FOO>>(&mut scenario);

            let wrong_key = farm::create_member_key(ctx);
            let balance = farm::redeem_forceful_removal_receipt(&mut receipt, &mut wrong_key); // aborts here
            balance::destroy_for_testing(balance);
            assert!(farm::key_memberships(&key) == 0, 0);
            assert!(farm::size(&farm) == 0, 0);

            farm::destroy_member_key(wrong_key);
            test_scenario::return_shared(receipt);
        };
        test_scenario::end(scenario);

        // clean up
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap); 
    }

    #[test]
    #[expected_failure(abort_code = farm::EKeyLocked)]
    public fun test_redeem_forceful_removal_receipt_aborts_on_key_locked() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);
        farm::change_unlock_per_second(&cap, &mut farm, 10, &clock);

        let scenario = test_scenario::begin(@0xABBA);
        {
            let ctx = test_scenario::ctx(&mut scenario);

            set_clock_sec(&mut clock, 110);
            farm::forcefully_remove_member(
                &cap, &mut farm, object::id(&key), &clock, ctx
            );
        };
        test_scenario::next_tx(&mut scenario, @0xABBA);
        {
            let receipt = test_scenario::take_shared<ForcefulRemovalReceipt<FOO>>(&mut scenario);

            let ticket = farm::new_withdraw_all_ticket(&mut key);
            let balance = farm::redeem_forceful_removal_receipt(&mut receipt, &mut key); // aborts here
            balance::destroy_for_testing(balance);
            assert!(farm::key_memberships(&key) == 0, 0);
            assert!(farm::size(&farm) == 0, 0);

            farm::destroy_withdraw_all_ticket(ticket, &mut key);
            test_scenario::return_shared(receipt);
        };
        test_scenario::end(scenario);

        // clean up
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap); 
    }

    #[test]
    public fun test_withdraw_from_multiple_using_ticket() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm1, cap1) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, cap2) = farm::create(balance::create_for_testing<BAR>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap1, &mut farm1, &mut key, 100, &clock);
        farm::add_member(&cap2, &mut farm2, &mut key, 100, &clock);
        farm::change_unlock_per_second(&cap1, &mut farm1, 10, &clock);
        farm::change_unlock_per_second(&cap2, &mut farm2, 10, &clock);

        set_clock_sec(&mut clock, 110);
        let ticket = farm::new_withdraw_all_ticket(&mut key);
        let balance1 = farm::member_withdraw_all_with_ticket(&mut farm1, &mut ticket, &clock);
        let balance2 = farm::member_withdraw_all_with_ticket(&mut farm2, &mut ticket, &clock);
        farm::destroy_withdraw_all_ticket(ticket, &mut key);
        assert_and_destroy_balance(balance1, 100);
        assert_and_destroy_balance(balance2, 100);

        // clean up
        balance::destroy_for_testing(farm::remove_member(&mut farm1, &mut key, &clock));
        balance::destroy_for_testing(farm::remove_member(&mut farm2, &mut key, &clock));
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm1);
        farm::destroy_for_testing(farm2);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap1); 
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap2); 
    }

    #[test]
    #[expected_failure(abort_code = farm::EAlreadyWithdrawn)]
    public fun test_destroy_withdraw_all_ticket_aborts_when_already_withdrawn() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);
        farm::change_unlock_per_second(&cap, &mut farm, 10, &clock);

        set_clock_sec(&mut clock, 110);
        let ticket = farm::new_withdraw_all_ticket(&mut key);
        let balance = farm::member_withdraw_all_with_ticket(&mut farm, &mut ticket, &clock);
        balance::destroy_for_testing(balance);
        let balance = farm::member_withdraw_all_with_ticket(&mut farm, &mut ticket, &clock); // aborts here
        balance::destroy_for_testing(balance);
        farm::destroy_withdraw_all_ticket(ticket, &mut key); 

        // clean up
        balance::destroy_for_testing(farm::remove_member(&mut farm, &mut key, &clock));
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap); 

    }

    #[test]
    #[expected_failure(abort_code = farm::ENotAllWithdrawn)]
    public fun test_destroy_withdraw_all_ticket_aborts_when_not_all_withdrawn() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm1, cap1) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, cap2) = farm::create(balance::create_for_testing<BAR>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap1, &mut farm1, &mut key, 100, &clock);
        farm::add_member(&cap2, &mut farm2, &mut key, 100, &clock);
        farm::change_unlock_per_second(&cap1, &mut farm1, 10, &clock);
        farm::change_unlock_per_second(&cap2, &mut farm2, 10, &clock);

        set_clock_sec(&mut clock, 110);
        let ticket = farm::new_withdraw_all_ticket(&mut key);
        let balance1 = farm::member_withdraw_all_with_ticket(&mut farm1, &mut ticket, &clock);
        assert_and_destroy_balance(balance1, 100);
        farm::destroy_withdraw_all_ticket(ticket, &mut key); // aborts here

        // clean up
        balance::destroy_for_testing(farm::remove_member(&mut farm1, &mut key, &clock));
        balance::destroy_for_testing(farm::remove_member(&mut farm2, &mut key, &clock));
        farm::destroy_member_key(key);
        farm::destroy_for_testing(farm1);
        farm::destroy_for_testing(farm2);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap1); 
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap2); 
    }

    #[test]
    #[expected_failure(abort_code = farm::EInvalidKey)]
    public fun test_destroy_withdraw_all_ticket_aborts_when_invalid_key() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);

        let key = farm::create_member_key(ctx);
        farm::add_member(&cap, &mut farm, &mut key, 100, &clock);
        farm::change_unlock_per_second(&cap, &mut farm, 10, &clock);

        set_clock_sec(&mut clock, 110);
        let ticket = farm::new_withdraw_all_ticket(&mut key);
        let balance = farm::member_withdraw_all_with_ticket(&mut farm, &mut ticket, &clock);
        balance::destroy_for_testing(balance);

        let wrong_key = farm::create_member_key(ctx);
        farm::destroy_withdraw_all_ticket(ticket, &mut wrong_key); 

        // clean up
        balance::destroy_for_testing(farm::remove_member(&mut farm, &mut key, &clock));
        farm::destroy_member_key(key);
        farm::destroy_member_key(wrong_key);
        farm::destroy_for_testing(farm);
        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(cap); 
    }
}
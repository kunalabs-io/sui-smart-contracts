#[test_only]
module token_distribution::pool_tests {
    use sui::tx_context;
    use sui::balance::{Self, Balance};
    use sui::tx_context::TxContext;
    use sui::test_scenario;
    use sui::clock::{Self, Clock};
    use token_distribution::farm::{Self, ForcefulRemovalReceipt};
    use token_distribution::pool;

    // witness types for test coins
    struct FOO has drop {}
    struct BAR has drop {}
    struct SHARES has drop {}

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

    #[test]
    public fun test_deposit_and_withdraw() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm1, farm_cap1) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, farm_cap2) = farm::create(balance::create_for_testing<BAR>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap1, &mut farm1, &pool_cap, &mut pool, 100, &clock);
        pool::add_to_farm(&farm_cap2, &mut farm2, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap1, &mut farm1, 10, &clock);
        farm::change_unlock_per_second(&farm_cap2, &mut farm2, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 110); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let stake = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(100), ticket, ctx
        );
        pool::assert_stake_shares_amount(&stake, 100);

        // withdraw shares
        set_clock_sec(&mut clock, 120);
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let balance = pool::withdraw_shares(
            &mut pool, &mut stake, 100, ticket
        );
        assert_and_destroy_balance(balance, 100);
        pool::assert_stake_shares_amount(&stake, 0);

        // deposit shares
        set_clock_sec(&mut clock, 130);
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        pool::deposit_shares(
            &mut pool, &mut stake, balance::create_for_testing<SHARES>(100), ticket
        );
        pool::assert_stake_shares_amount(&stake, 100);

        // withdraw shares
        set_clock_sec(&mut clock, 140);
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let balance = pool::withdraw_shares(
            &mut pool, &mut stake, 100, ticket
        );
        assert_and_destroy_balance(balance, 100);
        pool::assert_stake_shares_amount(&stake, 0);

        // clean up
        assert_and_destroy_balance(
            pool::collect_rewards_direct<FOO, SHARES>(&mut pool, &mut stake, 200), 200
        );
        assert_and_destroy_balance(
            pool::collect_rewards_direct<BAR, SHARES>(&mut pool, &mut stake, 200), 200
        );
        pool::destroy_empty_stake(stake);

        pool::remove_from_farm(&pool_cap, &mut farm1, &mut pool, &clock);
        pool::remove_from_farm(&pool_cap, &mut farm2, &mut pool, &clock);
        farm::destroy_for_testing(farm1);
        farm::destroy_for_testing(farm2);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_balance<BAR, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 200);
        pool::acc_assert_and_destroy_extraneous_balance<BAR, SHARES>(&mut pool, 200);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap1);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap2);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::ENotAllWithdrawn)]
    public fun test_deposit_shares_new_fails_when_not_fully_topped_up() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm1, farm_cap1) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, farm_cap2) = farm::create(balance::create_for_testing<BAR>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap1, &mut farm1, &pool_cap, &mut pool, 100, &clock);
        pool::add_to_farm(&farm_cap2, &mut farm2, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap1, &mut farm1, 10, &clock);
        farm::change_unlock_per_second(&farm_cap2, &mut farm2, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 110); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        let stake = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(100), ticket, ctx
        ); // aborts here

        // clean up
        pool::destroy_empty_stake(stake);

        pool::remove_from_farm(&pool_cap, &mut farm1, &mut pool, &clock);
        pool::remove_from_farm(&pool_cap, &mut farm2, &mut pool, &clock);
        farm::destroy_for_testing(farm1);
        farm::destroy_for_testing(farm2);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_balance<BAR, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_extraneous_balance<BAR, SHARES>(&mut pool, 100);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap1);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap2);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::ENotAllWithdrawn)]
    public fun test_deposit_shares_fails_when_not_fully_topped_up() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm1, farm_cap1) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, farm_cap2) = farm::create(balance::create_for_testing<BAR>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap1, &mut farm1, &pool_cap, &mut pool, 100, &clock);
        pool::add_to_farm(&farm_cap2, &mut farm2, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap1, &mut farm1, 10, &clock);
        farm::change_unlock_per_second(&farm_cap2, &mut farm2, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 110); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let stake = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(100), ticket, ctx
        );

        // deposit shares
        set_clock_sec(&mut clock, 120); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::deposit_shares(
            &mut pool, &mut stake, balance::create_for_testing<SHARES>(100), ticket
        ); // aborts here

        // clean up
        pool::destroy_empty_stake(stake);

        pool::remove_from_farm(&pool_cap, &mut farm1, &mut pool, &clock);
        pool::remove_from_farm(&pool_cap, &mut farm2, &mut pool, &clock);
        farm::destroy_for_testing(farm1);
        farm::destroy_for_testing(farm2);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_balance<BAR, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_extraneous_balance<BAR, SHARES>(&mut pool, 100);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap1);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap2);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::ENotAllWithdrawn)]
    public fun test_withdraw_shares_fails_when_not_fully_topped_up() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm1, farm_cap1) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, farm_cap2) = farm::create(balance::create_for_testing<BAR>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap1, &mut farm1, &pool_cap, &mut pool, 100, &clock);
        pool::add_to_farm(&farm_cap2, &mut farm2, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap1, &mut farm1, 10, &clock);
        farm::change_unlock_per_second(&farm_cap2, &mut farm2, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 110); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let stake = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(100), ticket, ctx
        );

        // withdraw shares
        set_clock_sec(&mut clock, 120); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        let balance = pool::withdraw_shares(
            &mut pool, &mut stake, 100, ticket
        ); // aborts here
        balance::destroy_for_testing(balance);

        // clean up
        pool::destroy_empty_stake(stake);

        pool::remove_from_farm(&pool_cap, &mut farm1, &mut pool, &clock);
        pool::remove_from_farm(&pool_cap, &mut farm2, &mut pool, &clock);
        farm::destroy_for_testing(farm1);
        farm::destroy_for_testing(farm2);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_balance<BAR, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_extraneous_balance<BAR, SHARES>(&mut pool, 100);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap1);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap2);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }

    #[test]
    public fun test_merge_stakes() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, farm_cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap, &mut farm, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap, &mut farm, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 110); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm, &mut pool, &mut ticket, &clock);
        let stake1 = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(100), ticket, ctx
        );
        pool::assert_stake_shares_amount(&stake1, 100);
        assert!(pool::total_shares(&pool) == 100, 0);

        // deposit shares new again
        set_clock_sec(&mut clock, 120); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm, &mut pool, &mut ticket, &clock);
        let stake2 = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(100), ticket, ctx
        );
        pool::assert_stake_shares_amount(&stake2, 100);
        assert!(pool::total_shares(&pool) == 200, 0);

        // deposit new zero stake just to trigger update
        set_clock_sec(&mut clock, 130); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm, &mut pool, &mut ticket, &clock);
        let stake3 = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(0), ticket, ctx
        );
        pool::destroy_empty_stake(stake3);
        assert!(pool::total_shares(&pool) == 200, 0);

        // merge
        pool::merge_stakes(&mut pool, &mut stake1, stake2);
        pool::assert_stake_shares_amount(&stake1, 200);
        assert!(pool::total_shares(&pool) == 200, 0);

        // withdraw
        set_clock_sec(&mut clock, 140); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm, &mut pool, &mut ticket, &clock);
        let balance = pool::withdraw_shares(&mut pool, &mut stake1, 200, ticket);
        assert_and_destroy_balance(balance, 200);

        // clean up
        assert_and_destroy_balance(
            pool::collect_rewards_direct<FOO, SHARES>(&mut pool, &mut stake1, 300), 300
        );
        pool::destroy_empty_stake(stake1);

        pool::remove_from_farm(&pool_cap, &mut farm, &mut pool, &clock);
        farm::destroy_for_testing(farm);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 100);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }

    #[test]
    public fun test_collect_rewards() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm1, farm_cap1) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, farm_cap2) = farm::create(balance::create_for_testing<BAR>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap1, &mut farm1, &pool_cap, &mut pool, 100, &clock);
        pool::add_to_farm(&farm_cap2, &mut farm2, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap1, &mut farm1, 10, &clock);
        farm::change_unlock_per_second(&farm_cap2, &mut farm2, 10, &clock);   

        // deposit shares
        set_clock_sec(&mut clock, 110);
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let stake1 = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing(100), ticket, ctx
        );
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let stake2 = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing(300), ticket, ctx
        );

        // withdraw
        set_clock_sec(&mut clock, 120);

        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let balance: Balance<FOO> = pool::collect_all_rewards(&mut pool, &mut stake1, ticket);
        assert_and_destroy_balance(balance, 25);

        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let balance: Balance<FOO> = pool::collect_rewards(&mut pool, &mut stake2, 25, ticket);
        assert_and_destroy_balance(balance, 25);

        // withdraw direct from stake2
        let balance: Balance<FOO> = pool::collect_rewards_direct(&mut pool, &mut stake2, 25);
        assert_and_destroy_balance(balance, 25);

        // withdraw all
        set_clock_sec(&mut clock, 130);

        let ticket = pool::new_top_up_ticket(&mut pool); // stake1
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let balance: Balance<FOO> = pool::collect_all_rewards(&mut pool, &mut stake1, ticket);
        assert_and_destroy_balance(balance, 25);

        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let balance: Balance<BAR> = pool::collect_all_rewards(&mut pool, &mut stake1, ticket);
        assert_and_destroy_balance(balance, 50);

        let ticket = pool::new_top_up_ticket(&mut pool); // stake2
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let balance: Balance<FOO> = pool::collect_all_rewards(&mut pool, &mut stake2, ticket);
        assert_and_destroy_balance(balance, 100);

        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm1, &mut pool, &mut ticket, &clock);
        pool::top_up(&mut farm2, &mut pool, &mut ticket, &clock);
        let balance: Balance<BAR> = pool::collect_all_rewards(&mut pool, &mut stake2, ticket);
        assert_and_destroy_balance(balance, 150);

        // clean up
        pool::remove_from_farm(&pool_cap, &mut farm1, &mut pool, &clock);
        pool::remove_from_farm(&pool_cap, &mut farm2, &mut pool, &clock);
        farm::destroy_for_testing(farm1);
        farm::destroy_for_testing(farm2);

        let ticket = pool::new_top_up_ticket(&mut pool);
        let balance = pool::withdraw_shares(&mut pool, &mut stake1, 100, ticket);
        assert_and_destroy_balance(balance, 100);
        pool::destroy_empty_stake(stake1);

        let ticket = pool::new_top_up_ticket(&mut pool);
        let balance = pool::withdraw_shares(&mut pool, &mut stake2, 300, ticket);
        assert_and_destroy_balance(balance, 300);
        pool::destroy_empty_stake(stake2);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_balance<BAR, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 100);
        pool::acc_assert_and_destroy_extraneous_balance<BAR, SHARES>(&mut pool, 100);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap1);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap2);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }

    #[test]
    public fun test_remove_from_farm() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, farm_cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap, &mut farm, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap, &mut farm, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 90); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm, &mut pool, &mut ticket, &clock);
        let stake = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(100), ticket, ctx
        );

        // remove from farm
        set_clock_sec(&mut clock, 110);
        pool::remove_from_farm(&pool_cap, &mut farm, &mut pool, &clock);

        // assert withdraw
        set_clock_sec(&mut clock, 130);
        let ticket = pool::new_top_up_ticket(&mut pool);
        let balance: Balance<FOO> = pool::collect_all_rewards(
            &mut pool, &mut stake, ticket
        );
        assert_and_destroy_balance(balance, 100);

        // clean up
        let ticket = pool::new_top_up_ticket(&mut pool);
        assert_and_destroy_balance(
            pool::withdraw_shares(&mut pool, &mut stake, 100, ticket), 100
        );
        pool::destroy_empty_stake(stake);

        farm::destroy_for_testing(farm);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 0);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }


    #[test]
    #[expected_failure(abort_code = pool::EInvalidAdminCap)]
    public fun test_remove_from_farm_aborts_on_invalid_cap() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, farm_cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        let (pool2, wrong_cap) = pool::create<SHARES>(ctx);

        pool::add_to_farm(&farm_cap, &mut farm, &wrong_cap, &mut pool, 100, &clock); // aborts here

        // clean up
        pool::destroy_for_testing(pool);
        pool::destroy_for_testing(pool2);
        farm::destroy_for_testing(farm);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(wrong_cap);
    }

    #[test]
    public fun test_redeem_forceful_removal_receipt() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, farm_cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap, &mut farm, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap, &mut farm, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 90); // increment clock by 10 seconds
        let ticket = pool::new_top_up_ticket(&mut pool);
        pool::top_up(&mut farm, &mut pool, &mut ticket, &clock);
        let stake = pool::deposit_shares_new(
            &mut pool, balance::create_for_testing<SHARES>(100), ticket, ctx
        );

        // forcefully remove
        let scenario = test_scenario::begin(@0xABBA);
        {
            set_clock_sec(&mut clock, 110);

            let id = pool::farm_key_id(&pool);
            farm::forcefully_remove_member(&farm_cap, &mut farm, id, &clock, ctx);
        };

        // redeem receipt
        test_scenario::next_tx(&mut scenario, @0xABBA);
        {
            let receipt = test_scenario::take_shared<ForcefulRemovalReceipt<FOO>>(&mut scenario);

            set_clock_sec(&mut clock, 130);
            pool::redeem_forceful_removal_receipt(&mut pool, &mut receipt);

            test_scenario::return_shared(receipt);
        };
        test_scenario::end(scenario);

        // withdraw shares and rewards
        let ticket = pool::new_top_up_ticket(&mut pool);
        let balance = pool::withdraw_shares(
            &mut pool, &mut stake, 100, ticket
        );
        assert_and_destroy_balance(balance, 100);

        let ticket = pool::new_top_up_ticket(&mut pool);
        let balance: Balance<FOO> = pool::collect_all_rewards(&mut pool, &mut stake, ticket);
        assert_and_destroy_balance(balance, 100);

        // clean up
        pool::destroy_empty_stake(stake);
        farm::destroy_for_testing(farm);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 0);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }
}
#[test_only]
module token_distribution::pool_util_tests {
    use sui::tx_context;
    use sui::balance::{Self, Balance};
    use sui::clock::{Self, Clock};
    use sui::tx_context::TxContext;
    use token_distribution::farm;
    use token_distribution::pool;
    use token_distribution::pool_util;

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
    public fun test_single_deposit_and_withdraw_shares() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm, farm_cap) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap, &mut farm, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap, &mut farm, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 110); // increment clock by 10 seconds
        let stake = pool_util::single_deposit_shares_new(
            &mut farm, &mut pool, balance::create_for_testing<SHARES>(100), &clock, ctx
        );
        pool::assert_stake_shares_amount(&stake, 100);

        // withdraw shares
        set_clock_sec(&mut clock, 120);
        let balance = pool_util::single_withdraw_shares(
            &mut farm, &mut pool, &mut stake, 100, &clock
        );
        assert_and_destroy_balance(balance, 100);
        pool::assert_stake_shares_amount(&stake, 0);

        // deposit shares
        set_clock_sec(&mut clock, 130);
        pool_util::single_deposit_shares(
            &mut farm, &mut pool, &mut stake, balance::create_for_testing<SHARES>(100), &clock
        );
        pool::assert_stake_shares_amount(&stake, 100);

        // withdraw shares
        set_clock_sec(&mut clock, 140);
        let balance = pool_util::single_withdraw_shares(
            &mut farm, &mut pool, &mut stake, 100, &clock
        );
        assert_and_destroy_balance(balance, 100);
        pool::assert_stake_shares_amount(&stake, 0);

        // clean up
        assert_and_destroy_balance(
            pool::collect_rewards_direct<FOO, SHARES>(&mut pool, &mut stake, 200), 200
        );
        pool::destroy_empty_stake(stake);

        pool::remove_from_farm(&pool_cap, &mut farm, &mut pool, &clock);
        farm::destroy_for_testing(farm);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 200);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }

    #[test]
    #[expected_failure(abort_code = farm::ENotAllWithdrawn)]
    public fun test_single_deposit_shares_aborts_when_pool_is_member_of_multiple_farms() {
        let ctx = &mut tx_context::dummy();
        let clock = create_clock_at_sec(50, ctx);

        let (farm1, farm_cap1) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (farm2, farm_cap2) = farm::create(balance::create_for_testing<FOO>(1000), 100, ctx);
        let (pool, pool_cap) = pool::create<SHARES>(ctx);
        pool::add_to_farm(&farm_cap1, &mut farm1, &pool_cap, &mut pool, 100, &clock);
        pool::add_to_farm(&farm_cap2, &mut farm2, &pool_cap, &mut pool, 100, &clock);
        farm::change_unlock_per_second(&farm_cap1, &mut farm1, 10, &clock);
        farm::change_unlock_per_second(&farm_cap2, &mut farm2, 10, &clock);

        // deposit shares new
        set_clock_sec(&mut clock, 110); // increment clock by 10 seconds
        let stake = pool_util::single_deposit_shares_new(
            &mut farm1, &mut pool, balance::create_for_testing<SHARES>(100), &clock, ctx
        ); // aborts here
        pool::assert_stake_shares_amount(&stake, 100); 

        // clean up
        pool::destroy_empty_stake(stake);
        pool::remove_from_farm(&pool_cap, &mut farm1, &mut pool, &clock);
        pool::remove_from_farm(&pool_cap, &mut farm2, &mut pool, &clock);
        farm::destroy_for_testing(farm1);
        farm::destroy_for_testing(farm2);

        pool::acc_assert_and_destroy_balance<FOO, SHARES>(&mut pool, 0);
        pool::acc_assert_and_destroy_extraneous_balance<FOO, SHARES>(&mut pool, 200);
        pool::destroy_for_testing(pool);

        clock::destroy_for_testing(clock);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap1);
        farm::destroy_admin_cap_irreversibly_i_know_what_im_doing(farm_cap2);
        pool::destroy_admin_cap_irreversibly_i_know_what_im_doing(pool_cap);
    }
}
#[test_only]
module 0x0::amm_tests {
    use sui::test_scenario;
    use sui::tx_context::TxContext;
    use sui::balance;
    use sui::object;
    use sui::coin::{Self, Coin};

    use 0x0::amm::{Self, Pool, PoolAdminCap, LPCoin};

    const ADMIN: address = @0xABBA;
    const USER: address = @0xB0B;

    // OTWs for currencies used in tests
    struct A has drop {}
    struct B has drop {}

    fun mint_coin<T>(
        amount: u64, ctx: &mut TxContext
    ): Coin<T> {
        coin::from_balance(
            balance::create_for_testing<T>(amount),
            ctx
        )
    }

    fun scenario_create_pool(
        scenario: &mut test_scenario::Scenario,
        init_a: u64,
        init_b: u64,
        lp_fee_bps: u64,
        admin_fee_pct: u64
    ) {
        let ctx = test_scenario::ctx(scenario);

        let init_a = mint_coin<A>(init_a, ctx);
        let init_b = mint_coin<B>(init_b, ctx);

        amm::new_pool_(init_a, init_b, lp_fee_bps, admin_fee_pct, ctx)
    }

    /* ================= new_pool tests ================= */

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_new_pool_fails_on_init_a_zero() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        {
            let ctx = test_scenario::ctx(scenario);

            let init_a = coin::zero<A>(ctx);
            let init_b = mint_coin<B>(100, ctx);

            amm::new_pool_(init_a, init_b, 0, 0, ctx);
        };
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_new_pool_fails_on_init_b_zero() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        {
            let ctx = test_scenario::ctx(scenario);

            let init_a = mint_coin<A>(100, ctx);
            let init_b = coin::zero<B>(ctx);

            amm::new_pool_(init_a, init_b, 0, 0, ctx);
        };
    }

    #[test]
    #[expected_failure(abort_code = 4)]
    fun test_new_pool_fails_on_invalid_lp_fee() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        {
            let ctx = test_scenario::ctx(scenario);

            let init_a = mint_coin<A>(100, ctx);
            let init_b = mint_coin<B>(100, ctx);

            amm::new_pool_(init_a, init_b, 10001, 0, ctx);
        };
    }

    #[test]
    #[expected_failure(abort_code = 4)]
    fun test_new_pool_fails_on_invalid_admin_fee() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        {
            let ctx = test_scenario::ctx(scenario);

            let init_a = mint_coin<A>(100, ctx);
            let init_b = mint_coin<B>(100, ctx);

            amm::new_pool_(init_a, init_b, 30, 101, ctx);
        };
    }

    #[test]
    fun test_new_pool() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        {
            let ctx = test_scenario::ctx(scenario);

            let init_a = mint_coin<A>(200, ctx);
            let init_b = mint_coin<B>(100, ctx);

            amm::new_pool_(init_a, init_b, 30, 10, ctx);
        };

        test_scenario::next_tx(scenario, &ADMIN);
        {
            // test pool
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let (a_value, b_value, lp_supply_value) = amm::pool_values(pool);
            assert!(a_value == 200, 0);
            assert!(b_value == 100, 0);
            assert!(lp_supply_value == 141, 0);

            let (lp_fee_bps, admin_fee_pct) = amm::pool_fees(pool);
            assert!(lp_fee_bps == 30, 0);
            assert!(admin_fee_pct == 10, 0);

            // test admin cap
            let admin_cap = test_scenario::take_owned<PoolAdminCap>(scenario);

            let admin_cap_pool_id = amm::admin_cap_pool_id(&admin_cap);
            let pool_id = object::borrow_id(pool);
            assert!(admin_cap_pool_id == pool_id, 0);

            // return objects
            test_scenario::return_shared(scenario, pool_);
            test_scenario::return_owned(scenario, admin_cap);
        };
    }

    /* ================= deposit tests ================= */


    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_deposit_fails_on_amount_a_zero() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            amm::deposit_(pool, mint_coin<A>(0, ctx), mint_coin<B>(10, ctx), 1, ctx);

            test_scenario::return_shared(scenario, pool_);
        }
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_deposit_fails_on_amount_b_zero() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            amm::deposit_(pool, mint_coin<A>(10, ctx), mint_coin<B>(0, ctx), 1, ctx);

            test_scenario::return_shared(scenario, pool_);
        }
    }

    #[test]
    fun test_deposit_on_empty_pool() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        // withdraw liquidity to make pool balances 0
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let lp_coin = test_scenario::take_owned<LPCoin<A,B>>(scenario);
            amm::withdraw_(pool, lp_coin, 0, 0, test_scenario::ctx(scenario));

            // sanity check
            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 0 && b == 0 && lp == 0, 0);

            test_scenario::return_shared(scenario, pool_);
        };

        // do the deposit
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            amm::deposit_(pool, mint_coin<A>(200, ctx), mint_coin<B>(100, ctx), 141, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            // balances
            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 200, 0);
            assert!(b == 100, 0);
            assert!(lp == 141, 0);

            // lp transferred to user
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);
            assert!(amm::lp_coin_value(&lp_coin) == 141, 0);
            assert!(amm::lp_coin_pool_id(&lp_coin) == object::borrow_id(pool), 0);

            // coins are fully used up
            assert!(test_scenario::can_take_owned<Coin<A>>(scenario) == false, 0);
            assert!(test_scenario::can_take_owned<Coin<B>>(scenario) == false, 0);

            // return
            test_scenario::return_owned(scenario, lp_coin);
            test_scenario::return_shared(scenario, pool_);
        };
    }

    #[test]
    fun test_deposit() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 50, 30, 10);

        // deposit exact (100, 50, 70); -> (300, 150, 210)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            amm::deposit_(pool, mint_coin<A>(200, ctx), mint_coin<B>(100, ctx), 140, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            // balances
            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 300, 0);
            assert!(b == 150, 0);
            assert!(lp == 210, 0);

            // lp transferred to user
            let lp_coin = test_scenario::take_last_created_owned<LPCoin<A, B>>(scenario);
            assert!(amm::lp_coin_value(&lp_coin) == 140, 0);
            assert!(amm::lp_coin_pool_id(&lp_coin) == object::borrow_id(pool), 0);

            // coins are fully used up
            assert!(test_scenario::can_take_owned<Coin<A>>(scenario) == false, 0);
            assert!(test_scenario::can_take_owned<Coin<B>>(scenario) == false, 0);

            // return
            test_scenario::return_shared(scenario, pool_);
            amm::lp_coin_destroy_for_testing(lp_coin);
        };

        // deposit max B (slippage); (300, 150, 210) -> (400, 200, 280)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            amm::deposit_(pool, mint_coin<A>(110, ctx), mint_coin<B>(50, ctx), 70, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            // balances
            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 400, 0);
            assert!(b == 200, 0);
            assert!(lp == 280, 0);

            // lp transferred to user
            let lp_coin = test_scenario::take_last_created_owned<LPCoin<A, B>>(scenario);
            assert!(amm::lp_coin_value(&lp_coin) == 70, 0);
            assert!(amm::lp_coin_pool_id(&lp_coin) == object::borrow_id(pool), 0);

            // there's extra coin A
            let a_extra = test_scenario::take_last_created_owned<Coin<A>>(scenario);
            assert!(coin::value(&a_extra) == 10, 0);
            assert!(test_scenario::can_take_owned<Coin<B>>(scenario) == false, 0);

            // return
            test_scenario::return_shared(scenario, pool_);
            amm::lp_coin_destroy_for_testing(lp_coin);
            coin::destroy_for_testing(a_extra);
        };

        // deposit max A (slippage); (400, 200, 280) -> (500, 250, 350)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            amm::deposit_(pool, mint_coin<A>(100, ctx), mint_coin<B>(60, ctx), 70, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            // balances
            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 500, 0);
            assert!(b == 250, 0);
            assert!(lp == 350, 0);

            // lp transferred to user
            let lp_coin = test_scenario::take_last_created_owned<LPCoin<A, B>>(scenario);
            assert!(amm::lp_coin_value(&lp_coin) == 70, 0);
            assert!(amm::lp_coin_pool_id(&lp_coin) == object::borrow_id(pool), 0);

            // there's extra coin B
            assert!(test_scenario::can_take_owned<Coin<A>>(scenario) == false, 0);
            let b_extra = test_scenario::take_last_created_owned<Coin<B>>(scenario);
            assert!(coin::value(&b_extra) == 10, 0);

            // return
            test_scenario::return_shared(scenario, pool_);
            amm::lp_coin_destroy_for_testing(lp_coin);
            coin::destroy_for_testing(b_extra);
        };

        // no lp issued when input small; (500, 250, 350) -> (501, 251, 350)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            amm::deposit_(pool, mint_coin<A>(1, ctx), mint_coin<B>(1, ctx), 0, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            // balances
            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 501, 0);
            assert!(b == 251, 0);
            assert!(lp == 350, 0);

            // no lp transferred to user
            assert!(test_scenario::can_take_owned<LPCoin<A, B>>(scenario) == false, 0);

            // coins are fully used up
            assert!(test_scenario::can_take_owned<Coin<A>>(scenario) == false, 0);
            assert!(test_scenario::can_take_owned<Coin<B>>(scenario) == false, 0);

            // return
            test_scenario::return_shared(scenario, pool_);
        };
    } 

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_deposit_fails_on_min_lp_out() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            amm::deposit_(pool, mint_coin<A>(200, ctx), mint_coin<B>(200, ctx), 201, ctx);

            test_scenario::return_shared(scenario, pool_);
        };
    }

    /* ================= withdraw tests ================= */

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_withdraw_fails_on_invalid_lp_coin() {
        let scenario = &mut test_scenario::begin(&ADMIN);

        scenario_create_pool(scenario, 100, 100, 30, 10);
        test_scenario::next_tx(scenario, &ADMIN);
        let lp_coin_1 = test_scenario::take_owned<LPCoin<A, B>>(scenario);

        scenario_create_pool(scenario, 100, 100, 30, 10);
        test_scenario::next_tx(scenario, &ADMIN);

        let pool_2_ = test_scenario::take_last_created_shared<Pool<A, B>>(scenario);
        let pool_2 = test_scenario::borrow_mut(&mut pool_2_);

        amm::withdraw_(pool_2, lp_coin_1, 0, 0, test_scenario::ctx(scenario));

        test_scenario::return_shared(scenario, pool_2_);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_withdraw_fails_on_zero_input() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let lp_coin = amm::lp_coin_zero(pool, ctx);
            amm::withdraw_(pool, lp_coin, 0, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
        }
    }

    #[test]
    fun test_withdraw() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 13, 30, 10);

        // withdraw (100, 13, 36) -> (64, 9, 23)
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);
            assert!(amm::lp_coin_value(&lp_coin) == 36, 0); // sanity check

            let ctx = test_scenario::ctx(scenario);
            let lp_in = amm::lp_coin_split(&mut lp_coin, 13, ctx);
            amm::withdraw_(pool, lp_in, 36, 4, ctx);

            test_scenario::return_shared(scenario, pool_);
            test_scenario::return_owned(scenario, lp_coin);
        };

        // check
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let out_a = test_scenario::take_owned<Coin<A>>(scenario);
            let out_b = test_scenario::take_owned<Coin<B>>(scenario);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 64, 0);
            assert!(b == 9, 0);
            assert!(lp == 23, 0);

            assert!(coin::value(&out_a) == 36, 0);
            assert!(coin::value(&out_b) == 4, 0);

            test_scenario::return_shared(scenario, pool_);
            coin::destroy_for_testing(out_a);
            coin::destroy_for_testing(out_b);
        };

        // withdraw small amount (64, 9, 23) -> (62, 9, 22)
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);
            assert!(amm::lp_coin_value(&lp_coin) == 23, 0); // sanity check

            let ctx = test_scenario::ctx(scenario);
            let lp_in = amm::lp_coin_split(&mut lp_coin, 1, ctx);
            amm::withdraw_(pool, lp_in, 2, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
            test_scenario::return_owned(scenario, lp_coin);
        };

        // check
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let out_a = test_scenario::take_owned<Coin<A>>(scenario);
            assert!(test_scenario::can_take_owned<Coin<B>>(scenario) == false, 0);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 62, 0);
            assert!(b == 9, 0);
            assert!(lp == 22, 0);

            assert!(coin::value(&out_a) == 2, 0);

            test_scenario::return_shared(scenario, pool_);
            coin::destroy_for_testing(out_a);
        };

        // withdraw all (62, 9, 22) -> (0, 0, 0)
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);

            let ctx = test_scenario::ctx(scenario);
            amm::withdraw_(pool, lp_coin, 62, 9, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let out_a = test_scenario::take_owned<Coin<A>>(scenario);
            let out_b = test_scenario::take_owned<Coin<B>>(scenario);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 0, 0);
            assert!(b == 0, 0);
            assert!(lp == 0, 0);

            assert!(coin::value(&out_a) == 62, 0);
            assert!(coin::value(&out_b) == 9, 0);

            test_scenario::return_shared(scenario, pool_);
            coin::destroy_for_testing(out_a);
            coin::destroy_for_testing(out_b);
        }
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_withdraw_fails_on_min_a_out() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);

            let ctx = test_scenario::ctx(scenario);
            let lp_in = amm::lp_coin_split(&mut lp_coin, 50, ctx);
            amm::withdraw_(pool, lp_coin, 51, 50, ctx);

            test_scenario::return_shared(scenario, pool_);
            amm::lp_coin_destroy_for_testing(lp_in);
        }
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_withdraw_fails_on_min_b_out() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);

            let ctx = test_scenario::ctx(scenario);
            let lp_in = amm::lp_coin_split(&mut lp_coin, 50, ctx);
            amm::withdraw_(pool, lp_coin, 50, 51, ctx);

            test_scenario::return_shared(scenario, pool_);
            amm::lp_coin_destroy_for_testing(lp_in);
        }
    }

    /* ================= swap tests ================= */

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_swap_a_fails_on_zero_input_a() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let a_in = coin::zero<A>(ctx);
            amm::swap_a_(pool, a_in, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
        } 
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_swap_b_fails_on_zero_input_b() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let b_in = coin::zero<B>(ctx);
            amm::swap_b_(pool, b_in, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
        } 
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    fun test_swap_a_fails_on_zero_pool_balances() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);

            let ctx = test_scenario::ctx(scenario);
            amm::withdraw_(pool, lp_coin, 0, 0, ctx);

            let a_in = coin::mint_for_testing<A>(10, ctx);
            amm::swap_a_(pool, a_in, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
        } 
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    fun test_swap_b_fails_on_zero_pool_balances() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 100, 100, 30, 10);

        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);

            let ctx = test_scenario::ctx(scenario);
            amm::withdraw_(pool, lp_coin, 0, 0, ctx);

            let b_in = coin::mint_for_testing<B>(10, ctx);
            amm::swap_b_(pool, b_in, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
        } 
    }

    #[test]
    fun test_swap_a_without_lp_fees() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 200, 100, 0, 10);

        // swap; (200, 100, 141) -> (213, 94, 141)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let a_in = coin::mint_for_testing<A>(13, ctx);
            amm::swap_a_(pool, a_in, 6, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let b_out = test_scenario::take_owned<Coin<B>>(scenario);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 213, 0);
            assert!(b == 94, 0);
            assert!(lp == 141, 0);
            assert!(coin::value(&b_out) == 6, 0);
            // admin fees should also be 0 because they're calcluated
            // as percentage of lp fees
            assert!(amm::pool_admin_fee_value(pool) == 0, 0); 

            test_scenario::return_shared(scenario, pool_);
            test_scenario::return_owned(scenario, b_out);
        }
    }

    #[test]
    fun test_swap_b_without_lp_fees() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 200, 100, 0, 10);

        // swap; (200, 100, 141) -> (177, 113, 141)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let b_in = coin::mint_for_testing<B>(13, ctx);
            amm::swap_b_(pool, b_in, 23, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let a_out = test_scenario::take_owned<Coin<A>>(scenario);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 177, 0);
            assert!(b == 113, 0);
            assert!(lp == 141, 0);
            assert!(coin::value(&a_out) == 23, 0);
            // admin fees should also be 0 because they're calcluated
            // as percentage of lp fees
            assert!(amm::pool_admin_fee_value(pool) == 0, 0); 

            test_scenario::return_shared(scenario, pool_);
            test_scenario::return_owned(scenario, a_out);
        }
    }

    #[test]
    fun test_swap_a_with_lp_fees() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 20000, 10000, 30, 0); // lp fee 30 bps

        // swap; (20000, 10000, 14142) -> (21300, 9302, 14142)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let a_in = coin::mint_for_testing<A>(1300, ctx);
            amm::swap_a_(pool, a_in, 608, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let b_out = test_scenario::take_owned<Coin<B>>(scenario);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 21300, 0);
            assert!(b == 9392, 0);
            assert!(lp == 14142, 0);
            assert!(coin::value(&b_out) == 608, 0);
            assert!(amm::pool_admin_fee_value(pool) == 0, 0); 

            test_scenario::return_shared(scenario, pool_);
            coin::destroy_for_testing(b_out);
        };

        // swap small amount; (21300, 9302, 14142) -> (21301, 9302, 14142)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let a_in = coin::mint_for_testing<A>(1, ctx);
            amm::swap_a_(pool, a_in, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            assert!(test_scenario::can_take_owned<Coin<B>>(scenario) == false, 0);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 21301, 0);
            assert!(b == 9392, 0);
            assert!(lp == 14142, 0);
            assert!(amm::pool_admin_fee_value(pool) == 0, 0); 

            test_scenario::return_shared(scenario, pool_);
        }
    }

    #[test]
    fun test_swap_b_with_lp_fees() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 20000, 10000, 30, 0); // lp fee 30 bps

        // swap; (20000, 10000, 14142) -> (17706, 11300, 14142)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let b_in = coin::mint_for_testing<B>(1300, ctx);
            amm::swap_b_(pool, b_in, 2294, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let a_out = test_scenario::take_owned<Coin<A>>(scenario);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 17706, 0);
            assert!(b == 11300, 0);
            assert!(lp == 14142, 0);
            assert!(coin::value(&a_out) == 2294, 0);
            assert!(amm::pool_admin_fee_value(pool) == 0, 0); 

            test_scenario::return_shared(scenario, pool_);
            coin::destroy_for_testing(a_out);
        };

        // swap small amount; (17706, 11300, 14142) -> (17706, 11301, 14142)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let b_in = coin::mint_for_testing<B>(1, ctx);
            amm::swap_b_(pool, b_in, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            assert!(test_scenario::can_take_owned<Coin<A>>(scenario) == false, 0);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 17706, 0);
            assert!(b == 11301, 0);
            assert!(lp == 14142, 0);
            assert!(amm::pool_admin_fee_value(pool) == 0, 0); 

            test_scenario::return_shared(scenario, pool_);
        }
    }

    #[test]
    fun test_swap_a_with_admin_fees() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 20000, 10000, 30, 30);

        // swap; (20000, 10000, 14142) -> (25000, 8005, 14143)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let a_in = coin::mint_for_testing<A>(5000, ctx);
            amm::swap_a_(pool, a_in, 1995, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let b_out = test_scenario::take_owned<Coin<B>>(scenario);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 25000, 0);
            assert!(b == 8005, 0);
            assert!(lp == 14143, 0);
            assert!(coin::value(&b_out) == 1995, 0);
            assert!(amm::pool_admin_fee_value(pool) == 1, 0); 

            test_scenario::return_shared(scenario, pool_);
            coin::destroy_for_testing(b_out);
        };
    }

    #[test]
    fun test_swap_b_with_admin_fees() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 20000, 10000, 30, 30);

        // swap; (20000, 10000, 14142) -> (13002, 15400, 14144)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let b_in = coin::mint_for_testing<B>(5400, ctx);
            amm::swap_b_(pool, b_in, 6998, ctx);

            test_scenario::return_shared(scenario, pool_);
        };

        // check
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let a_out = test_scenario::take_owned<Coin<A>>(scenario);

            let (a, b, lp) = amm::pool_values(pool);
            assert!(a == 13002, 0);
            assert!(b == 15400, 0);
            assert!(lp == 14144, 0);
            assert!(coin::value(&a_out) == 6998, 0);
            assert!(amm::pool_admin_fee_value(pool) == 2, 0); 

            test_scenario::return_shared(scenario, pool_);
            coin::destroy_for_testing(a_out);
        };
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_swap_a_fails_on_min_out() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 200, 100, 0, 10);

        // swap; (200, 100, 141) -> (213, 94, 141)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let a_in = coin::mint_for_testing<A>(13, ctx);
            amm::swap_a_(pool, a_in, 7, ctx);

            test_scenario::return_shared(scenario, pool_);
        };
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_swap_b_fails_on_min_out() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 200, 100, 0, 10);

        // swap; (200, 100, 141) -> (177, 113, 141)
        test_scenario::next_tx(scenario, &USER);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);

            let ctx = test_scenario::ctx(scenario);
            let b_in = coin::mint_for_testing<B>(13, ctx);
            amm::swap_b_(pool, b_in, 24, ctx);

            test_scenario::return_shared(scenario, pool_);
        };
    }

    /* ================= admin fee withdraw tests ================= */

    #[test]
    fun test_admin_withdraw_fees() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 20000, 10000, 30, 30);

        // generate fees and withdraw 1 
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let cap = test_scenario::take_owned<PoolAdminCap>(scenario);

            // generate fees
            let ctx = test_scenario::ctx(scenario);
            let b_in = coin::mint_for_testing<B>(5400, ctx);
            amm::swap_b_(pool, b_in, 6998, ctx);
            assert!(amm::pool_admin_fee_value(pool) == 2, 0); // sanity check

            // withdraw
            let ctx = test_scenario::ctx(scenario);
            amm::admin_withdraw_fees_(pool, &cap, 1, ctx);

            test_scenario::return_shared(scenario, pool_);
            test_scenario::return_owned(scenario, cap);
        };

        // check
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_out = test_scenario::take_last_created_owned<LPCoin<A, B>>(scenario);

            assert!(amm::pool_admin_fee_value(pool) == 1, 0);
            assert!(amm::lp_coin_value(&lp_out) == 1, 0);
            assert!(amm::lp_coin_pool_id(&lp_out) == object::borrow_id(pool), 0);

            test_scenario::return_shared(scenario, pool_);
            amm::lp_coin_destroy_for_testing(lp_out);
        };

        // withdraw all
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let cap = test_scenario::take_owned<PoolAdminCap>(scenario);

            // withdraw
            let ctx = test_scenario::ctx(scenario);
            amm::admin_withdraw_fees_(pool, &cap, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
            test_scenario::return_owned(scenario, cap);
        };

        // check
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let lp_out = test_scenario::take_last_created_owned<LPCoin<A, B>>(scenario);

            assert!(amm::pool_admin_fee_value(pool) == 0, 0);
            assert!(amm::lp_coin_value(&lp_out) == 1, 0);
            assert!(amm::lp_coin_pool_id(&lp_out) == object::borrow_id(pool), 0);

            test_scenario::return_shared(scenario, pool_);
            amm::lp_coin_destroy_for_testing(lp_out);
        };
    }

    #[test]
    #[expected_failure(abort_code = 5)]
    fun test_admin_withdraw_fees_fails_on_invalid_lp_coin() {
        let scenario = &mut test_scenario::begin(&ADMIN);

        scenario_create_pool(scenario, 100, 100, 30, 10);
        test_scenario::next_tx(scenario, &ADMIN);
        let cap_1 = test_scenario::take_last_created_owned<PoolAdminCap>(scenario);

        scenario_create_pool(scenario, 100, 100, 30, 10);
        test_scenario::next_tx(scenario, &ADMIN);

        let pool_2_ = test_scenario::take_last_created_shared<Pool<A, B>>(scenario);
        let pool_2 = test_scenario::borrow_mut(&mut pool_2_);

        let ctx = test_scenario::ctx(scenario);
        amm::admin_withdraw_fees_(pool_2, &cap_1, 0, ctx);

        test_scenario::return_shared(scenario, pool_2_);
        test_scenario::return_owned(scenario, cap_1);
    }

    #[test]
    fun test_admin_withdraw_fees_amount_0_and_balance_0() {
        let scenario = &mut test_scenario::begin(&ADMIN);
        scenario_create_pool(scenario, 20000, 10000, 30, 30);

        // generate fees and withdraw 1 
        test_scenario::next_tx(scenario, &ADMIN);
        {
            let pool_ = test_scenario::take_shared<Pool<A, B>>(scenario);
            let pool = test_scenario::borrow_mut(&mut pool_);
            let cap = test_scenario::take_owned<PoolAdminCap>(scenario);

            // destroy initial LPCoin
            let lp_coin = test_scenario::take_owned<LPCoin<A, B>>(scenario);
            amm::lp_coin_destroy_for_testing(lp_coin);

            // withdraw
            let ctx = test_scenario::ctx(scenario);
            amm::admin_withdraw_fees_(pool, &cap, 0, ctx);

            test_scenario::return_shared(scenario, pool_);
            test_scenario::return_owned(scenario, cap);
        };
        
        // check
        test_scenario::next_tx(scenario, &ADMIN);
        assert!(test_scenario::can_take_owned<LPCoin<A, B>>(scenario) == false, 0)
    }
}

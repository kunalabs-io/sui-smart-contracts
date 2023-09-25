#[test_only]
module token_distribution::accumulation_distributor_tests {
    use std::vector;
    use std::type_name;
    use sui::tx_context;
    use sui::balance::{Self, Balance};
    use sui::vec_map;
    use token_distribution::accumulation_distributor as ad;

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

    #[test]
    public fun test_create() {
        let ctx = tx_context::dummy();

        let ad = ad::create(&mut ctx);

        ad::assert_balances_length(&ad, 0);
        ad::assert_extraneous_balances_length(&ad, 0);
        ad::assert_acc_rewards_per_share_x64(&ad, vector::empty(), vector::empty());
        ad::assert_total_shares(&ad, 0);

        ad::destroy_for_testing(ad);
    }

    #[test]
    public fun test_extraneous_balance() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx);

        // top up
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(100));

        ad::assert_extraneous_balances_length(&ad, 1);
        ad::assert_extraneous_balance_value<FOO>(&ad, 100);
        ad::assert_balances_length(&ad, 0); // sanity
        ad::assert_acc_rewards_per_share_x64(&ad, vector::empty(), vector::empty());
        ad::assert_total_shares(&ad, 0);

        // top up again
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(200));

        ad::assert_extraneous_balances_length(&ad, 1);
        ad::assert_extraneous_balance_value<FOO>(&ad, 300);
        ad::assert_balances_length(&ad, 0); // sanity
        ad::assert_acc_rewards_per_share_x64(&ad, vector::empty(), vector::empty());
        ad::assert_total_shares(&ad, 0);

        // another balance
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(100));

        ad::assert_extraneous_balances_length(&ad, 2);
        ad::assert_extraneous_balance_value<FOO>(&ad, 300);
        ad::assert_extraneous_balance_value<BAR>(&ad, 100);
        ad::assert_balances_length(&ad, 0); // sanity
        ad::assert_acc_rewards_per_share_x64(&ad, vector::empty(), vector::empty());
        ad::assert_total_shares(&ad, 0);

        // remove balances
        let foo = ad::remove_extraneous_balance<FOO>(&mut ad);
        assert_and_destroy_balance(foo, 300);
        let bar = ad::remove_extraneous_balance<BAR>(&mut ad);
        assert_and_destroy_balance(bar, 100);

        // clean up
        ad::destroy_for_testing(ad);
    }

    #[test]
    // The `top_up` function assumes that vec_map::insert will push back and the
    // inserted element will be at the last index. This is a sanity check that
    // this invariant holds.
    public fun test_vec_map_pushes_back() {
        let map = vec_map::empty<u8, u64>();
        vec_map::insert(&mut map, 11, 11111);
        vec_map::insert(&mut map, 22, 22222);

        let (k, v) = vec_map::get_entry_by_idx(&map, 0);
        assert!(k == &11, 0);
        assert!(v == &11111, 0);
        let (k, v) = vec_map::get_entry_by_idx(&map, 1);
        assert!(k == &22, 0);
        assert!(v == &22222, 0);
    }

    #[test]
    public fun test_top_up() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx);

        let position = ad::deposit_shares_new(&mut ad, 123);

        // top up
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(568));

        ad::assert_balances_length(&ad, 1); 
        ad::assert_balance_value<FOO>(&ad, 568);
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(85184964502983945673)
        );

        ad::assert_extraneous_balances_length(&ad, 0); // sanity
        ad::assert_total_shares(&ad, 123);

        // top up new currency
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(246));

        ad::assert_balances_length(&ad, 2); 
        ad::assert_balance_value<FOO>(&ad, 568);
        ad::assert_balance_value<BAR>(&ad, 246);

        let types = vector::empty();
        vector::push_back(&mut types, type_name::get<FOO>());
        vector::push_back(&mut types, type_name::get<BAR>());
        let acc = vector::empty();
        vector::push_back(&mut acc, 85184964502983945673);
        vector::push_back(&mut acc, 36893488147419103232);
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            types,
            acc
        );

        ad::assert_extraneous_balances_length(&ad, 0); // sanity
        ad::assert_total_shares(&ad, 123);

        // top up the first one again
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(467));

        ad::assert_balances_length(&ad, 2); 
        ad::assert_balance_value<FOO>(&ad, 1035);
        ad::assert_balance_value<BAR>(&ad, 246);

        let types = vector::empty();
        vector::push_back(&mut types, type_name::get<FOO>());
        vector::push_back(&mut types, type_name::get<BAR>());
        let acc = vector::empty();
        vector::push_back(&mut acc, 155222602571458422133);
        vector::push_back(&mut acc, 36893488147419103232);
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            types,
            acc
        );

        ad::assert_extraneous_balances_length(&ad, 0); // sanity
        ad::assert_total_shares(&ad, 123);

        // clean up
        ad::withdraw_shares(&mut ad, &mut position, 123);
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position),
            1034
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position),
            246
        );
        ad::position_destroy_empty(position);
        ad::assert_and_destroy_balance<FOO>(&mut ad, 1);
        ad::assert_and_destroy_balance<BAR>(&mut ad, 0);
        ad::destroy_for_testing(ad);
    }

    #[test]
    public fun test_deposit_and_withdraw_shares() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx);

        // deposit on empty
        let position = ad::deposit_shares_new(&mut ad, 123);

        ad::assert_position_shares(&position, 123);
        ad::assert_position_balances(
            &position,
            vector::empty(),
            vector::empty(),
            vector::empty()
        );
        ad::assert_total_shares(&ad, 123); 

        ad::assert_balances_length(&ad, 0);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::empty(),
            vector::empty()
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // deposit again
        ad::deposit_shares(&mut ad, &mut position, 77);

        ad::assert_position_shares(&position, 200);
        ad::assert_position_balances(
            &position,
            vector::empty(),
            vector::empty(),
            vector::empty()
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 0);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::empty(),
            vector::empty()
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // withdraw on empty
        ad::withdraw_shares(&mut ad, &mut position, 50);

        ad::assert_position_shares(&position, 150);
        ad::assert_position_balances(
            &position,
            vector::empty(),
            vector::empty(),
            vector::empty()
        );
        ad::assert_total_shares(&ad, 150); 

        ad::assert_balances_length(&ad, 0);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::empty(),
            vector::empty()
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up and deposit
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1000));
        ad::deposit_shares(&mut ad, &mut position, 60);

        ad::assert_position_shares(&position, 210);
        ad::assert_position_balances(
            &position,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(999),
            vector::singleton(122978293824730344106)
        );
        ad::assert_total_shares(&ad, 210); 

        ad::assert_balances_length(&ad, 1);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(122978293824730344106)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up and withdraw
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1000));
        ad::withdraw_shares(&mut ad, &mut position, 50);

        ad::assert_position_shares(&position, 160);
        ad::assert_position_balances(
            &position,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(1998),
            vector::singleton(210819932270966304182)
        );
        ad::assert_total_shares(&ad, 160); 

        ad::assert_balances_length(&ad, 1);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(210819932270966304182)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up new and withdraw
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(1000));
        ad::withdraw_shares(&mut ad, &mut position, 50);

        ad::assert_position_shares(&position, 110);
        ad::assert_position_balances(
            &position,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(1998, 1000),
            vector_two(210819932270966304182, 115292150460684697600)
        );
        ad::assert_total_shares(&ad, 110); 

        ad::assert_balances_length(&ad, 2);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(210819932270966304182, 115292150460684697600)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up both and deposit
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1000));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(1000));
        ad::deposit_shares(&mut ad, &mut position, 100);

        ad::assert_position_shares(&position, 210);
        ad::assert_position_balances(
            &position,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(2997, 1999),
            vector_two(378517605668325864327, 282989823858044257745)
        );
        ad::assert_total_shares(&ad, 210); 

        ad::assert_balances_length(&ad, 2);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(378517605668325864327, 282989823858044257745)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // withdraw again (without top up)
        ad::withdraw_shares(&mut ad, &mut position, 30);

        ad::assert_position_shares(&position, 180);
        ad::assert_position_balances(
            &position,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(2997, 1999),
            vector_two(378517605668325864327, 282989823858044257745)
        );
        ad::assert_total_shares(&ad, 180); 

        ad::assert_balances_length(&ad, 2);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(378517605668325864327, 282989823858044257745)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up both and create new position
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1000));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(1000));

        let position2 = ad::deposit_shares_new(&mut ad, 500);

        ad::assert_position_shares(&position, 180); // position 1
        ad::assert_position_balances(
            &position,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(2997, 1999),
            vector_two(378517605668325864327, 282989823858044257745)
        );

        ad::assert_position_shares(&position2, 500); // position 2
        ad::assert_position_balances(
            &position2,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(0, 0),
            vector_two(480999517188934484415, 385471735378652877833)
        );

        ad::assert_total_shares(&ad, 680); 
        ad::assert_balances_length(&ad, 2);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(480999517188934484415, 385471735378652877833)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up and withdraw all from both positions
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1000));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(1000));

        ad::withdraw_shares(&mut ad, &mut position, 180);
        ad::withdraw_shares(&mut ad, &mut position2, 500);

        ad::assert_position_shares(&position, 0); // position 1
        ad::assert_position_balances(
            &position,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(4261, 3263),
            vector_two(508127082003213236791, 412599300192931630209)
        );

        ad::assert_position_shares(&position2, 0); // position 2
        ad::assert_position_balances(
            &position2,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(735, 735),
            vector_two(508127082003213236791, 412599300192931630209)
        );

        ad::assert_total_shares(&ad, 0); 
        ad::assert_balances_length(&ad, 2);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(508127082003213236791, 412599300192931630209)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // clean up
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position),
            4261
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position),
            3263
        );
        ad::position_destroy_empty(position);

        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position2),
            735
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position2),
            735
        );
        ad::position_destroy_empty(position2);

        ad::assert_and_destroy_balance<FOO>(&mut ad, 4);
        ad::assert_and_destroy_balance<BAR>(&mut ad, 2);
        ad::destroy_for_testing(ad);
    }

    #[test]
    #[expected_failure(abort_code = ad::EInvalidPosition)]
    public fun test_deposit_shares_aborts_on_invalid_id() {
        let ctx = tx_context::dummy();
        let ad1 = ad::create(&mut ctx);
        let ad2 = ad::create(&mut ctx);

        let position = ad::deposit_shares_new(&mut ad1, 100);
        ad::deposit_shares(&mut ad2, &mut position, 100);

        ad::destroy_for_testing(ad1);
        ad::destroy_for_testing(ad2);
        ad::position_destroy_empty(position);
    }

    #[test]
    #[expected_failure(abort_code = ad::EInvalidPosition)]
    public fun test_withdraw_shares_aborts_on_invalid_id() {
        let ctx = tx_context::dummy();
        let ad1 = ad::create(&mut ctx);
        let ad2 = ad::create(&mut ctx);

        let position = ad::deposit_shares_new(&mut ad1, 100);
        ad::withdraw_shares(&mut ad2, &mut position, 100);

        ad::destroy_for_testing(ad1);
        ad::destroy_for_testing(ad2);
        ad::position_destroy_empty(position);
    }

    #[test]
    #[expected_failure(abort_code = ad::ENotEnough)]
    public fun test_withdraw_shares_aborts_on_amount_too_large() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx);

        let position = ad::deposit_shares_new(&mut ad, 100);
        ad::withdraw_shares(&mut ad, &mut position, 101);

        ad::position_destroy_empty(position);
        ad::destroy_for_testing(ad);
    }

    #[test]
    #[expected_failure(abort_code = ad::EInvalidPosition)]
    public fun test_merge_positions_aborts_on_into_invalid_id() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx);
        let ad_other = ad::create(&mut ctx);

        let from = ad::deposit_shares_new(&mut ad, 100);
        let into = ad::deposit_shares_new(&mut ad_other, 100);

        ad::merge_positions(&mut ad, &mut into, from);

        ad::position_destroy_empty(into);
        ad::destroy_for_testing(ad);
        ad::destroy_for_testing(ad_other);
    }

    #[test]
    #[expected_failure(abort_code = ad::EInvalidPosition)]
    public fun test_merge_positions_aborts_on_from_invalid_id() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx);
        let ad_other = ad::create(&mut ctx);

        let from = ad::deposit_shares_new(&mut ad_other, 100);
        let into = ad::deposit_shares_new(&mut ad, 100);

        ad::merge_positions(&mut ad, &mut into, from);

        ad::position_destroy_empty(into);
        ad::destroy_for_testing(ad);
        ad::destroy_for_testing(ad_other);
    }

    #[test]
    public fun test_merge_positions() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx); 

        let position1 = ad::deposit_shares_new(&mut ad, 100);
        let position2 = ad::deposit_shares_new(&mut ad, 100);

        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1111));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(2222));

        ad::withdraw_shares(&mut ad, &mut position1, 1); // withdraw to trigger update

        ad::top_up(&mut ad, balance::create_for_testing<FOO>(3333));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(4444));

        // sanity checks
        ad::assert_position_shares(&position1, 99); // position 1
        ad::assert_position_balances(
            &position1,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(555, 1110),
            vector_two(102471663329456559226, 204943326658913118453)
        );

        ad::assert_position_shares(&position2, 100); // position 2
        ad::assert_position_balances(
            &position2,
            vector::empty(),
            vector::empty(),
            vector::empty()
        );

        ad::assert_total_shares(&ad, 199); 
        ad::assert_balances_length(&ad, 2);
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(411431452262491411166, 616889711902959587706)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // merge check
        ad::merge_positions(&mut ad, &mut position2, position1);

        ad::assert_position_shares(&position2, 199); // position 2
        ad::assert_position_balances(
            &position2,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(4443, 6664),
            vector_two(411431452262491411166, 616889711902959587706)
        );

        ad::assert_total_shares(&ad, 199); // sanity
        ad::assert_balances_length(&ad, 2);
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(411431452262491411166, 616889711902959587706)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // clean up
        ad::withdraw_shares(&mut ad, &mut position2, 199);
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position2),
            4443
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position2),
            6664
        );
        ad::position_destroy_empty(position2);

        ad::assert_and_destroy_balance<FOO>(&mut ad, 1);
        ad::assert_and_destroy_balance<BAR>(&mut ad, 2);
        ad::destroy_for_testing(ad);
    }

    #[test]
    #[expected_failure(abort_code = ad::ENotEmpty)]
    public fun test_position_destroy_empty_aborts_when_shares_non_zero() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx); 

        let position = ad::deposit_shares_new(&mut ad, 100);

        ad::position_destroy_empty(position);

        ad::destroy_for_testing(ad);
    }

    #[test]
    #[expected_failure(abort_code = ad::ENotEmpty)]
    public fun test_position_destroy_empty_aborts_when_unlocked_non_zero() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx); 

        let position = ad::deposit_shares_new(&mut ad, 100);

        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1000));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(1000));

        ad::withdraw_shares(&mut ad, &mut position, 100);
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position),
            1000
        );

        ad::position_destroy_empty(position);

        ad::destroy_for_testing(ad);
    }

    #[test]
    public fun test_position_destroy_empty() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx); 

        let position = ad::deposit_shares_new(&mut ad, 100);

        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1000));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(1000));

        ad::withdraw_shares(&mut ad, &mut position, 100);
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position),
            1000
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position),
            1000
        );
        ad::position_destroy_empty(position);

        // clean up
        ad::assert_and_destroy_balance<FOO>(&mut ad, 0);
        ad::assert_and_destroy_balance<BAR>(&mut ad, 0);
        ad::destroy_for_testing(ad);    
    }

    #[test]
    #[expected_failure(abort_code = ad::EInvalidPosition)]
    public fun test_withdraw_unlocked_aborts_when_id_doesnt_match() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx); 
        let ad_other = ad::create(&mut ctx);

        let position_other = ad::deposit_shares_new(&mut ad_other, 100);

        let bal = ad::withdraw_rewards<FOO>(&mut ad, &mut position_other, 0);
        balance::destroy_for_testing(bal);
        
        // clean up
        ad::position_destroy_empty(position_other);
        ad::destroy_for_testing(ad);
        ad::destroy_for_testing(ad_other);
    }

    #[test]
    #[expected_failure(abort_code = ad::EInvalidPosition)]
    public fun test_withdraw_all_unlocked_aborts_when_id_doesnt_match() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx); 
        let ad_other = ad::create(&mut ctx);

        let position_other = ad::deposit_shares_new(&mut ad_other, 100);

        let bal = ad::withdraw_all_rewards<FOO>(&mut ad, &mut position_other);
        balance::destroy_for_testing(bal);
        
        // clean up
        ad::position_destroy_empty(position_other);
        ad::destroy_for_testing(ad);
        ad::destroy_for_testing(ad_other);
    }

    #[test]
    #[expected_failure(abort_code = ad::ENotEnough)]
    public fun test_withdraw_unlocked_aborts_when_not_enough() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx); 

        let position = ad::deposit_shares_new(&mut ad, 100);
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1000));

        let b = ad::withdraw_rewards<FOO>(&mut ad, &mut position, 1001);
        balance::destroy_for_testing(b);

        // clean up
        ad::position_destroy_empty(position);
        ad::destroy_for_testing(ad);
    }

    #[test]
    public fun test_withdraw_unlocked() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx);

        let position = ad::deposit_shares_new(&mut ad, 200); // deposit shares
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(0)); // top up 0

        ad::assert_position_shares(&position, 200); // sanity checks
        ad::assert_position_balances(
            &position,
            vector::empty(),
            vector::empty(),
            vector::empty()
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 1);
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(0)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // withdraw on empty
        assert_and_destroy_balance(
            ad::withdraw_rewards<FOO>(&mut ad, &mut position, 0),
            0
        );

        ad::assert_position_shares(&position, 200);
        ad::assert_position_balances(
            &position,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(0),
            vector::singleton(0)
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 1);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(0)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up and withdraw
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1111));

        assert_and_destroy_balance(
            ad::withdraw_rewards<FOO>(&mut ad, &mut position, 100),
            100
        );

        ad::assert_position_shares(&position, 200);
        ad::assert_position_balances(
            &position,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(1010),
            vector::singleton(102471663329456559226)
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 1);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(102471663329456559226)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up and withdraw without triggering update
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1111));

        assert_and_destroy_balance(
            ad::withdraw_rewards<FOO>(&mut ad, &mut position, 100),
            100
        );

        ad::assert_position_shares(&position, 200);
        ad::assert_position_balances(
            &position,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(910),
            vector::singleton(102471663329456559226)
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 1);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(204943326658913118452)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // withdraw and trigger update
        assert_and_destroy_balance(
            ad::withdraw_rewards<FOO>(&mut ad, &mut position, 1010),
            1010
        );

        ad::assert_position_shares(&position, 200);
        ad::assert_position_balances(
            &position,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(1010),
            vector::singleton(204943326658913118452)
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 1);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(204943326658913118452)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top_up and withdraw all
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1111));

        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position),
            2120
        );

        ad::assert_position_shares(&position, 200);
        ad::assert_position_balances(
            &position,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(0),
            vector::singleton(307414989988369677678)
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 1);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(307414989988369677678)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // withdraw all again (zero)
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position),
            0
        );

        ad::assert_position_shares(&position, 200);
        ad::assert_position_balances(
            &position,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(0),
            vector::singleton(307414989988369677678)
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 1);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector::singleton(type_name::get<FOO>()),
            vector::singleton(307414989988369677678)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up new and withdraw
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(1111));

        assert_and_destroy_balance(
            ad::withdraw_rewards<FOO>(&mut ad, &mut position, 0),
            0
        );
        assert_and_destroy_balance(
            ad::withdraw_rewards<BAR>(&mut ad, &mut position, 500),
            500
        );

        ad::assert_position_shares(&position, 200);
        ad::assert_position_balances(
            &position,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(0, 610),
            vector_two(307414989988369677678, 102471663329456559226)
        );
        ad::assert_total_shares(&ad, 200); 

        ad::assert_balances_length(&ad, 2);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(307414989988369677678, 102471663329456559226)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up both, create a new position, and withdraw
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1111));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(1111));

        let position1 = position;
        let position2 = ad::deposit_shares_new(&mut ad, 500);

        assert_and_destroy_balance(
            ad::withdraw_rewards<FOO>(&mut ad, &mut position1, 500),
            500
        ); // will trigger update
        assert_and_destroy_balance(
            ad::withdraw_rewards<BAR>(&mut ad, &mut position1, 500),
            500
        ); // will not trigger update

        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position2),
            0
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position2),
            0
        );

        ad::assert_position_shares(&position1, 200); // position 1
        ad::assert_position_balances(
            &position1,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(610, 110),
            vector_two(409886653317826236904, 102471663329456559226)
        );

        ad::assert_position_shares(&position2, 500); // position 2
        ad::assert_position_balances(
            &position2,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(0, 0),
            vector_two(409886653317826236904, 204943326658913118452)
        );

        ad::assert_total_shares(&ad, 700); 
        ad::assert_balances_length(&ad, 2);  // sanity
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(409886653317826236904, 204943326658913118452)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // top up and withdraw all from both positions
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(1111));
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(2222));

        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position1),
            927
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position1),
            1855
        );

        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position2),
            793
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position2),
            1587
        );

        ad::assert_position_shares(&position1, 200); // position 1
        ad::assert_position_balances(
            &position1,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(0, 0),
            vector_two(439164271411956682397, 263498562847174009438)
        );

        ad::assert_position_shares(&position2, 500); // position 2
        ad::assert_position_balances(
            &position2,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(0, 0),
            vector_two(439164271411956682397, 263498562847174009438)
        );

        ad::assert_total_shares(&ad, 700);  // sanity
        ad::assert_balances_length(&ad, 2);
        ad::assert_acc_rewards_per_share_x64(
            &ad,
            vector_two(type_name::get<FOO>(), type_name::get<BAR>()),
            vector_two(439164271411956682397, 263498562847174009438)
        );
        ad::assert_extraneous_balances_length(&ad, 0);

        // clean up
        ad::withdraw_shares(&mut ad, &mut position1, 200); // position 1
        ad::position_destroy_empty(position1);

        ad::withdraw_shares(&mut ad, &mut position2, 500); // position 2
        ad::position_destroy_empty(position2);

        ad::assert_and_destroy_balance<FOO>(&mut ad, 5);
        ad::assert_and_destroy_balance<BAR>(&mut ad, 2);
        ad::destroy_for_testing(ad);
    }

    #[test]
    public fun test_has_balance() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx);

        assert!(ad::has_balance(&ad, &type_name::get<FOO>()) == false, 0);
        assert!(ad::has_balance_with_type<FOO>(&ad) == false, 0);

        let position = ad::deposit_shares_new(&mut ad, 100);
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(0));

        assert!(ad::has_balance(&ad, &type_name::get<FOO>()) == true, 0);
        assert!(ad::has_balance_with_type<FOO>(&ad) == true, 0);

        assert!(ad::has_balance(&ad, &type_name::get<BAR>()) == false, 0);
        assert!(ad::has_balance_with_type<BAR>(&ad) == false, 0);

        ad::top_up(&mut ad, balance::create_for_testing<BAR>(0));
        assert!(ad::has_balance(&ad, &type_name::get<BAR>()) == true, 0);
        assert!(ad::has_balance_with_type<BAR>(&ad) == true, 0);

        // clean up
        ad::withdraw_shares(&mut ad, &mut position, 100);
        ad::position_destroy_empty(position);

        ad::assert_and_destroy_balance<FOO>(&mut ad, 0);
        ad::assert_and_destroy_balance<BAR>(&mut ad, 0);
        ad::destroy_for_testing(ad); 
    }

    #[test]
    public fun test_position_unlocked_balance_value() {
        let ctx = tx_context::dummy();
        let ad = ad::create(&mut ctx); 

        let position = ad::deposit_shares_new(&mut ad, 100);
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(0));

        // check empty
        assert!(ad::position_rewards_value(&ad, &position, type_name::get<FOO>()) == 0, 0);
        assert!(ad::position_rewards_value_with_type<FOO>(&ad, &position) == 0, 0);

        // top up and check
        ad::top_up(&mut ad, balance::create_for_testing<FOO>(100));
        assert!(ad::position_rewards_value(&ad, &position, type_name::get<FOO>()) == 100, 0);
        assert!(ad::position_rewards_value_with_type<FOO>(&ad, &position) == 100, 0);

        // withdraw and check
        assert_and_destroy_balance(
            ad::withdraw_rewards<FOO>(&mut ad, &mut position, 50),
            50
        );
        assert!(ad::position_rewards_value(&ad, &position, type_name::get<FOO>()) == 50, 0);
        assert!(ad::position_rewards_value_with_type<FOO>(&ad, &position) == 50, 0);

        // top up other and check
        ad::top_up(&mut ad, balance::create_for_testing<BAR>(111));
        assert!(ad::position_rewards_value(&ad, &position, type_name::get<FOO>()) == 50, 0);
        assert!(ad::position_rewards_value_with_type<FOO>(&ad, &position) == 50, 0);
        assert!(ad::position_rewards_value(&ad, &position, type_name::get<BAR>()) == 110, 0);
        assert!(ad::position_rewards_value_with_type<BAR>(&ad, &position) == 110, 0);

        // clean up
        ad::withdraw_shares(&mut ad, &mut position, 100);
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<FOO>(&mut ad, &mut position),
            50
        );
        assert_and_destroy_balance(
            ad::withdraw_all_rewards<BAR>(&mut ad, &mut position),
            110
        );
        ad::position_destroy_empty(position);

        ad::assert_and_destroy_balance<FOO>(&mut ad, 0);
        ad::assert_and_destroy_balance<BAR>(&mut ad, 1);
        ad::destroy_for_testing(ad); 
    }
}
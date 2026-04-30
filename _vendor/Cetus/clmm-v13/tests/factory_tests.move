#[test_only]
module cetus_clmm::factory_tests {
    use cetus_clmm::cetus;
    use cetus_clmm::config::{Self, AdminCap, GlobalConfig};
    use cetus_clmm::factory::{Self, Pools};
    use cetus_clmm::pool::Pool;
    use cetus_clmm::tick_math;
    use cetus_clmm::usdc;
    use integer_mate::i32;
    use std::string;
    use std::type_name;
    use std::unit_test::assert_eq;
    use sui::clock::{Self, Clock};
    use sui::coin;
    use sui::sui::SUI;
    use sui::test_scenario;
    use cetus_clmm::tick_math::max_sqrt_price;
    use cetus_clmm::tick_math::min_sqrt_price;

    const TEST_ADDR: address = @0x12345;

    public struct CoinA has drop {}

    public struct CoinB {}

    public struct CoinC {}

    public struct CoinD {}

    public struct CoinE {}

    public struct USDC {}

    public fun init_test(ctx: &mut TxContext): (Clock, AdminCap, GlobalConfig, Pools) {
        let (cap, config) = config::new_global_config_for_test(
            ctx,
            2000,
        );
        let pools = factory::new_pools_for_test(ctx);
        (clock::create_for_testing(ctx), cap, config, pools)
    }

    fun close_test(cap: AdminCap, config: GlobalConfig, pools: Pools) {
        transfer::public_transfer(cap, TEST_ADDR);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
    }

    #[test]
    fun test_create_pool() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);

        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );

        factory::create_pool<CoinB, CoinA>(
            &mut pools,
            &config,
            10,
            tick_math::get_sqrt_price_at_tick(i32::from(0)),
            string::utf8(b""),
            &clock,
            ctx,
        );
        let pool_key = factory::new_pool_key<CoinB, CoinA>(10);
        let info = factory::pool_simple_info(
            &pools,
            pool_key,
        );
        assert!(pool_key == factory::pool_key(info), 0);
        assert!(10 == factory::tick_spacing(info), 0);
        assert!(1 == factory::index(&pools), 0);
        let (ca, cb) = factory::coin_types(info);
        assert!(ca == type_name::get<CoinB>() && cb == type_name::get<CoinA>(), 0);

        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ESameCoinType)]
    fun test_create_pool_use_same_coin() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );

        factory::create_pool<CoinA, CoinA>(
            &mut pools,
            &config,
            10,
            tick_math::get_sqrt_price_at_tick(i32::from(0)),
            string::utf8(b""),
            &clock,
            ctx,
        );
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EInvalidCoinTypeSequence)]
    fun test_create_pool_use_incorret_coin_sequence() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );

        factory::create_pool<CoinA, CoinB>(
            &mut pools,
            &config,
            10,
            tick_math::get_sqrt_price_at_tick(i32::from(0)),
            string::utf8(b""),
            &clock,
            ctx,
        );
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::config::EFeeTierNotFound)]
    fun test_create_pool_use_invalid_tick_spacing() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, config, mut pools) = init_test(ctx);
        factory::create_pool<CoinB, CoinA>(
            &mut pools,
            &config,
            10,
            tick_math::get_sqrt_price_at_tick(i32::from(0)),
            string::utf8(b""),
            &clock,
            ctx,
        );
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EInvalidSqrtPrice)]
    fun test_create_pool_use_invalid_init_price() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );
        factory::create_pool<CoinB, CoinA>(
            &mut pools,
            &config,
            10,
            tick_math::get_sqrt_price_at_tick(i32::from(443636)) + 1,
            string::utf8(b""),
            &clock,
            ctx,
        );
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
    }

    #[test]
    fun test_create_pool_use_sui() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );
        factory::create_pool<CoinA, SUI>(
            &mut pools,
            &config,
            10,
            1844674407370955161,
            string::utf8(b""),
            &clock,
            ctx,
        );
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
    }

    #[test]
    fun test_fetch_pools() {
        let mut scenario = test_scenario::begin(@0x223);
        let ctx = scenario.ctx();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );
        factory::create_pool<CoinA, SUI>(
            &mut pools,
            &config,
            10,
            1844674407370955161,
            string::utf8(b""),
            &clock,
            ctx,
        );
        close_test(admin_cap, config, pools);
        scenario.next_tx(@0x234);
        let pool = test_scenario::take_shared<Pool<CoinA, SUI>>(&scenario);
        let pools = test_scenario::take_shared<Pools>(&scenario);
        let pool_id = object::id(&pool);
        let pool_key = factory::new_pool_key<CoinA, SUI>(10);
        let pool_infos = factory::fetch_pools(&pools, vector::empty(), 10);
        assert_eq!(pool_infos.length(), 1);
        let pool_info = pool_infos[0];
        assert_eq!(pool_info.pool_id(), pool_id);
        assert_eq!(pool_info.tick_spacing(), 10);
        let (ca, cb) = factory::coin_types(&pool_info);
        assert_eq!(ca, type_name::get<CoinA>());
        assert_eq!(cb, type_name::get<SUI>());
        assert_eq!(pool_key, pool_info.pool_key());

        let pool_infos = factory::fetch_pools(&pools, vector::singleton(pool_key), 10);
        assert_eq!(pool_infos.length(), 1);
        let pool_info = pool_infos[0];
        assert_eq!(pool_info.pool_id(), pool_id);
        assert_eq!(pool_info.tick_spacing(), 10);
        let (ca, cb) = factory::coin_types(&pool_info);
        assert_eq!(ca, type_name::get<CoinA>());
        assert_eq!(cb, type_name::get<SUI>());
        assert_eq!(pool_key, pool_info.pool_key());
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(pool);
        test_scenario::return_shared(pools);
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EPoolKeyNotRegistered)]
    fun test_fetch_pools_pool_key_not_registered() {
        let mut scenario = test_scenario::begin(@0x223);
        let ctx = scenario.ctx();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );
        factory::create_pool<CoinA, SUI>(
            &mut pools,
            &config,
            10,
            1844674407370955161,
            string::utf8(b""),
            &clock,
            ctx,
        );
        close_test(admin_cap, config, pools);
        scenario.next_tx(@0x234);
        let pool = test_scenario::take_shared<Pool<CoinA, SUI>>(&scenario);
        let pools = test_scenario::take_shared<Pools>(&scenario);
        let pool_key = factory::new_pool_key<CoinB, SUI>(10);
        factory::fetch_pools(&pools, vector::singleton(pool_key), 10);
        clock::destroy_for_testing(clock);
        test_scenario::return_shared(pool);
        test_scenario::return_shared(pools);
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EMethodDeprecated)]
    fun test_create_pool_with_liquidity() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);

        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );

        let (position, coin_a, coin_b) = factory::create_pool_with_liquidity<CoinB, CoinA>(
            &mut pools,
            &config,
            10,
            tick_math::get_sqrt_price_at_tick(i32::from(100)),
            string::utf8(b""),
            0,
            200,
            coin::mint_for_testing<CoinB>(1000000000, ctx),
            coin::mint_for_testing<CoinA>(1200000000, ctx),
            1000000000,
            1200000000,
            true,
            &clock,
            ctx,
        );
        transfer::public_transfer(coin_a, tx_context::sender(ctx));
        transfer::public_transfer(coin_b, tx_context::sender(ctx));
        transfer::public_transfer(position, tx_context::sender(ctx));
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ECoinTypeNotAllowed)]
    fun test_create_pool_v2_not_allowed_coin() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        factory::add_denied_list<cetus::CETUS>(&config, &mut pools, ctx);
        factory::add_denied_list<usdc::USDC>(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(1000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(1200000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            10,
            1844674407370955161,
            string::utf8(b""),
            0,
            200,
            coin_a,
            coin_b,
            &metadata_a,
            &metadata_b,
            1000000000,
            1200000000,
            true,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ECoinTypeNotAllowed)]
    fun test_create_pool_v2_not_allowed_coin_2() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(
            &mut config,
            10,
            2000,
            ctx,
        );
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        factory::add_denied_list<usdc::USDC>(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(1000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(1200000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            10,
            1844674407370955161,
            string::utf8(b""),
            0,
            200,
            coin_a,
            coin_b,
            &metadata_a,
            &metadata_b,
            1000000000,
            1200000000,
            true,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    fun test_create_pool_v2_fix_amount_b() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(&mut config, 10, 2000, ctx);
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(1000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(3000000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            10,
            18446744073709551616,
            string::utf8(b""),
            i32::neg_from(100).as_u32(),
            200,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            3000000000,
            1000000000,
            false,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ELiquidityCheckFailed)]
    fun test_create_pool_v2_liquidity_check_failed() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(1000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(3000000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            200,
            18446744073709551616,
            string::utf8(b""),
            i32::neg_from(200).as_u32(),
            0,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            3000000000,
            1000000000,
            false,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ELiquidityCheckFailed)]
    fun test_create_pool_v2_liquidity_check_failed_coin_a() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(1000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(3000000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            200,
            18446744073709551616,
            string::utf8(b""),
            0,
            i32::from(200).as_u32(),
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            3000000000,
            1000000000,
            true,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EAmountInAboveMaxLimit)]
    fun test_create_pool_v2_amount_in_above_max_limit() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(1000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(3000000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            200,
            18446744073709551616,
            string::utf8(b""),
            i32::neg_from(200).as_u32(),
            i32::from(200).as_u32(),
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            3000000000,
            1000000000,
            true,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EAmountOutBelowMinLimit)]
    fun test_create_pool_v2_amount_out_below_min_limit() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(2000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(1000000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            200,
            18446744073709551616,
            string::utf8(b""),
            i32::neg_from(200).as_u32(),
            i32::from(200).as_u32(),
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            1000000000,
            2000000000,
            false,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EInvalidSqrtPrice)]
    fun test_create_pool_v2_init_sqrt_price_invalid() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(2000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(1000000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            200,
            max_sqrt_price() + 100,
            string::utf8(b""),
            i32::neg_from(200).as_u32(),
            i32::from(200).as_u32(),
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            1000000000,
            2000000000,
            false,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EInvalidSqrtPrice)]
    fun test_create_pool_v2_init_sqrt_price_invalid_2() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(2000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(1000000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            200,
            min_sqrt_price() - 100,
            string::utf8(b""),
            i32::neg_from(200).as_u32(),
            i32::from(200).as_u32(),
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            1000000000,
            2000000000,
            false,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EPoolAlreadyExist)]
    fun test_create_pool_v2_pool_already_exists() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        config::add_fee_tier(&mut config, 200, 2000, ctx);
        factory::init_manager_and_whitelist(&config, &mut pools, ctx);
        let coin_a = coin::mint_for_testing<cetus::CETUS>(1000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(1000000000, ctx);
        let metadata_a = cetus::init_coin(ctx);
        let metadata_b = usdc::init_coin(ctx);
        let (position, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            200,
            18446744073709551616,
            string::utf8(b""),
            i32::neg_from(200).as_u32(),
            i32::from(200).as_u32(),
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            1000000000,
            1000000000,
            false,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        let coin_a = coin::mint_for_testing<cetus::CETUS>(1000000000, ctx);
        let coin_b = coin::mint_for_testing<usdc::USDC>(1000000000, ctx);
        let (position2, coin_a, coin_b) = factory::create_pool_v2_(
            &config,
            &mut pools,
            200,
            18446744073709551616,
            string::utf8(b""),
            i32::neg_from(200).as_u32(),
            i32::from(200).as_u32(),
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            1000000000,
            1000000000,
            false,
            &clock,
            ctx,
        );
        coin_a.burn_for_testing();
        coin_b.burn_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_transfer(position2, ctx.sender());
        clock::destroy_for_testing(clock);
        close_test(admin_cap, config, pools);
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ESameCoinType)]
    fun test_new_pool_key_same_coin_type() {
        factory::new_pool_key<SUI, SUI>(10);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EInvalidCoinTypeSequence)]
    fun test_new_pool_key_invalid_coin_sequence() {
        factory::new_pool_key<CoinA, CoinB>(10);
    }

    #[test]
    fun test_is_right_order() {
        let r = factory::is_right_order<CoinA, SUI>();
        assert!(r, 1);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ESameCoinType)]
    fun test_is_right_order_same_coin_type() {
        factory::is_right_order<CoinA, CoinA>();
    }
}

#[test_only]
module cetus_clmm::test_coin {
    use cetus_clmm::ausdc::{Self, AUSDC};
    use cetus_clmm::config::{AdminCap, GlobalConfig, add_fee_tier};
    use cetus_clmm::factory::{
        init_manager_and_whitelist,
        is_allowed_coin,
        Pools,
        in_allowed_list,
        add_allowed_list,
        remove_allowed_list,
        in_denied_list,
        add_denied_list,
        remove_denied_list,
        add_allowed_pair_config,
        mint_pool_creation_cap,
        register_permission_pair,
        remove_allowed_pair_config,
        is_permission_pair,
        permission_pair_cap,
        unregister_permission_pair,
        mint_pool_creation_cap_by_admin,
        is_right_order
    };
    use cetus_clmm::factory_tests::init_test;
    use std::option::none;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, TreasuryCap, CoinMetadata};
    use sui::sui::SUI;
    use sui::test_utils;
    use sui::url::Url;

    #[test_only]
    fun test_init_prepare(): (
        TreasuryCap<TEST_COIN>,
        CoinMetadata<TEST_COIN>,
        Clock,
        AdminCap,
        GlobalConfig,
        Pools,
    ) {
        let ctx = &mut tx_context::dummy();
        let witness = test_utils::create_one_time_witness<TEST_COIN>();

        let (cap, m) = coin::create_currency<TEST_COIN>(
            witness,
            8,
            b"COIN",
            b"",
            b"",
            none<Url>(),
            ctx,
        );
        let (clock, admin_cap, mut config, mut pools) = init_test(ctx);
        add_fee_tier(&mut config, 200, 1000, ctx);
        init_manager_and_whitelist(&config, &mut pools, ctx);
        (cap, m, clock, admin_cap, config, pools)
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ETickSpacingNotExistsInFeeTier)]
    fun test_init_manager_and_whitelist() {
        let ctx = &mut tx_context::dummy();
        let (clock, admin_cap, config, mut pools) = init_test(ctx);
        init_manager_and_whitelist(&config, &mut pools, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        clock::destroy_for_testing(clock);
    }

    public struct TEST_COIN has drop {}

    public struct COINA has drop {}

    public struct COINB has drop {}

    #[test]
    fun test_add_remove_allowed_list() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, config, mut pools) = test_init_prepare();
        assert!(is_allowed_coin(&mut pools, &coin_metadtata), 1);
        assert!(!in_allowed_list<TEST_COIN>(&pools), 1);
        add_allowed_list<TEST_COIN>(&config, &mut pools, ctx);
        assert!(in_allowed_list<TEST_COIN>(&pools), 1);

        remove_allowed_list<TEST_COIN>(&config, &mut pools, ctx);
        assert!(!in_allowed_list<TEST_COIN>(&pools), 1);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    fun test_add_remove_denied_list() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, config, mut pools) = test_init_prepare();
        assert!(is_allowed_coin(&mut pools, &coin_metadtata), 1);
        assert!(!in_denied_list<TEST_COIN>(&pools), 1);
        add_denied_list<TEST_COIN>(&config, &mut pools, ctx);
        assert!(in_denied_list<TEST_COIN>(&pools), 1);

        remove_denied_list<TEST_COIN>(&config, &mut pools, ctx);
        assert!(!in_denied_list<TEST_COIN>(&pools), 1);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ECoinAlreadyExistsInList)]
    fun test_add_denied_list_error_1() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, config, mut pools) = test_init_prepare();
        add_denied_list<TEST_COIN>(&config, &mut pools, ctx);
        add_denied_list<TEST_COIN>(&config, &mut pools, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    fun test_is_allowed_coin() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, config, mut pools) = test_init_prepare();
        assert!(is_allowed_coin(&mut pools, &coin_metadtata), 1);
        add_denied_list<TEST_COIN>(&config, &mut pools, ctx);
        assert!(!is_allowed_coin(&mut pools, &coin_metadtata), 1);
        add_allowed_list<TEST_COIN>(&config, &mut pools, ctx);
        assert!(is_allowed_coin(&mut pools, &coin_metadtata), 1);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ECoinAlreadyExistsInList)]
    fun test_add_allowed_list_error_1() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, config, mut pools) = test_init_prepare();
        add_allowed_list<TEST_COIN>(&config, &mut pools, ctx);
        add_allowed_list<TEST_COIN>(&config, &mut pools, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EcoinNotExistsInList)]
    fun test_remove_allowed_list_error_1() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, config, mut pools) = test_init_prepare();
        remove_allowed_list<TEST_COIN>(&config, &mut pools, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EcoinNotExistsInList)]
    fun test_remove_denied_list_error_1() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, config, mut pools) = test_init_prepare();
        remove_denied_list<TEST_COIN>(&config, &mut pools, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[
        expected_failure(
            abort_code = cetus_clmm::factory::ETickSpacingAlreadyExistsInAllowedPairConfig,
        ),
    ]
    fun test_add_allowed_config_error_1() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, mut config, mut pools) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<TEST_COIN>(&config, &mut pools, 2, ctx);
        add_allowed_pair_config<TEST_COIN>(&config, &mut pools, 2, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ETickSpacingNotInAllowedPairConfig)]
    fun test_remove_allowed_config_error_1() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, mut config, mut pools) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<TEST_COIN>(&config, &mut pools, 2, ctx);
        remove_allowed_pair_config<TEST_COIN>(&config, &mut pools, 10, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    fun test_add_allowed_pair_config() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        assert!(!is_permission_pair<TEST_COIN, SUI>(&pools, 200), 1);
        assert!(!is_permission_pair<TEST_COIN, COINA>(&pools, 2), 1);
        register_permission_pair<TEST_COIN, SUI>(&config, &mut pools, 200, &pool_creator_cap, ctx);
        register_permission_pair<TEST_COIN, COINA>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        assert!(is_permission_pair<TEST_COIN, SUI>(&pools, 200), 1);
        assert!(is_permission_pair<TEST_COIN, COINA>(&pools, 2), 1);
        assert!(
            permission_pair_cap<TEST_COIN, SUI>(&pools, 200) == object::id(&pool_creator_cap),
            1,
        );
        assert!(
            permission_pair_cap<TEST_COIN, COINA>(&pools, 2) == object::id(&pool_creator_cap),
            1,
        );
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EQuoteCoinTypeNotInAllowedPairConfig)]
    fun test_register_permission_pair_error_0() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        assert!(!is_permission_pair<TEST_COIN, COINB>(&pools, 2), 1);
        register_permission_pair<TEST_COIN, COINB>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        assert!(is_permission_pair<TEST_COIN, COINB>(&pools, 2), 1);
        assert!(
            permission_pair_cap<TEST_COIN, COINB>(&pools, 2) == object::id(&pool_creator_cap),
            1,
        );
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EPoolKeyNotRegistered)]
    fun test_permission_pair_cap_pool_key_not_registered() {
        let ctx = &tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, config, pools) = test_init_prepare();
        assert!(!is_permission_pair<TEST_COIN, COINA>(&pools, 2), 1);
        assert!(permission_pair_cap<TEST_COIN, COINA>(&pools, 2) == object::id(&cap), 1);
        clock::destroy_for_testing(clock);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ETickSpacingNotExistsInFeeTier)]
    fun test_register_permission_pair_error_4() {
        let ctx = &mut tx_context::dummy();
        let (mut cap, coin_metadtata, clock, admin_cap, config, mut pools) = test_init_prepare();
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        assert!(!is_permission_pair<TEST_COIN, COINB>(&pools, 2), 1);
        register_permission_pair<TEST_COIN, COINB>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        assert!(is_permission_pair<TEST_COIN, COINB>(&pools, 2), 1);
        assert!(
            permission_pair_cap<TEST_COIN, COINB>(&pools, 2) == object::id(&pool_creator_cap),
            1,
        );
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EPoolKeyAlreadyRegistered)]
    fun test_register_permission_pair_error_1() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        assert!(!is_permission_pair<TEST_COIN, COINA>(&pools, 2), 1);
        register_permission_pair<TEST_COIN, COINA>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        assert!(is_permission_pair<TEST_COIN, COINA>(&pools, 2), 1);
        assert!(
            permission_pair_cap<TEST_COIN, COINA>(&pools, 2) == object::id(&pool_creator_cap),
            1,
        );
        register_permission_pair<TEST_COIN, COINA>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EPoolKeyNotRegistered)]
    fun test_register_permission_pair_error_2() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        unregister_permission_pair<TEST_COIN, COINA>(&config, &mut pools, 2, &pool_creator_cap);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ECapNotMatchWithCoinType)]
    fun test_register_permission_pair_error_3() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        register_permission_pair<COINB, COINA>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    fun test_unregister_permission_pair() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);
        // let (usdc_cap, m) = usdc::test_init_usec();
        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        register_permission_pair<TEST_COIN, COINA>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        unregister_permission_pair<TEST_COIN, COINA>(&config, &mut pools, 2, &pool_creator_cap);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    fun test_unregister_permission_pair_1() {
        let ctx = &mut tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, mut config, mut pools) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);
        let (mut usdc_cap, metadata) = ausdc::test_init_ausdc();
        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut usdc_cap, ctx);
        register_permission_pair<AUSDC, COINA>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        unregister_permission_pair<AUSDC, COINA>(&config, &mut pools, 2, &pool_creator_cap);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(usdc_cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        transfer::public_freeze_object(metadata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EPoolKeyNotRegistered)]
    fun test_unregister_permission_pair_not_registered() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);
        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        unregister_permission_pair<AUSDC, COINA>(&config, &mut pools, 2, &pool_creator_cap);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ECapAlreadyRegistered)]
    fun test_mint_cap_error_0() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        let pool_creator_cap_2 = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap_2, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ECapAlreadyRegistered)]
    fun test_mint_cap_by_admin_error_2() {
        let ctx = &mut tx_context::dummy();
        let (cap, coin_metadtata, clock, admin_cap, mut config, mut pools) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap_by_admin<COINA>(&config, &mut pools, ctx);
        let pool_creator_cap_2 = mint_pool_creation_cap_by_admin<COINA>(&config, &mut pools, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap_2, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    fun test_mint_cap() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        let pool_creator_cap_2 = mint_pool_creation_cap_by_admin<COINB>(&config, &mut pools, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap_2, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::EQuoteCoinTypeNotInAllowedPairConfig)]
    fun test_remove_allowed_pair_config() {
        let ctx = &mut tx_context::dummy();
        let (
            mut cap,
            coin_metadtata,
            clock,
            admin_cap,
            mut config,
            mut pools,
        ) = test_init_prepare();
        add_fee_tier(&mut config, 2, 1000, ctx);
        add_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);

        let pool_creator_cap = mint_pool_creation_cap(&config, &mut pools, &mut cap, ctx);
        register_permission_pair<TEST_COIN, SUI>(&config, &mut pools, 200, &pool_creator_cap, ctx);
        remove_allowed_pair_config<COINA>(&config, &mut pools, 2, ctx);
        register_permission_pair<TEST_COIN, COINA>(&config, &mut pools, 2, &pool_creator_cap, ctx);
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(pool_creator_cap, tx_context::sender(ctx));
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(coin_metadtata);
        clock::destroy_for_testing(clock);
    }

    #[test]
    fun test_is_right_order() {
        assert!(is_right_order<TEST_COIN, COINB>(), 1);
    }
}

module cetus_clmm::ausdc {
    use std::option::none;
    use sui::coin::{Self, CoinMetadata, TreasuryCap};
    use sui::test_utils;
    use sui::url::Url;

    public struct AUSDC has drop {}

    #[test_only]
    public fun test_init_ausdc(): (TreasuryCap<AUSDC>, CoinMetadata<AUSDC>) {
        let ctx = &mut tx_context::dummy();
        let witness = test_utils::create_one_time_witness<AUSDC>();

        let (cap, m) = coin::create_currency<AUSDC>(
            witness,
            6,
            b"AUSDC",
            b"AUSDC",
            b"",
            none<Url>(),
            ctx,
        );

        (cap, m)
    }
}

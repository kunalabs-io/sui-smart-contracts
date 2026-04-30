#[test_only]
module cetus_clmm::pool_creator_tests {
    use cetus_clmm::cetus;
    use cetus_clmm::config::new_global_config_for_test;
    use cetus_clmm::factory::{Self, new_pools_for_test, init_manager_and_whitelist};
    use cetus_clmm::pool_creator::{
        create_pool_v2,
        full_range_tick_range,
        create_pool_v2_with_creation_cap,
        create_pool_v2_by_creation_cap
    };
    use cetus_clmm::tick_math::{tick_bound, get_sqrt_price_at_tick};
    use cetus_clmm::usdc;
    use integer_mate::i32;
    use std::string;
    use sui::balance;
    use sui::clock;

    #[test]
    fun test_create_pool_v2() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let metadata_a = cetus::init_coin(&mut ctx);
        let metadata_b = usdc::init_coin(&mut ctx);
        let (admin_cap, mut config) = new_global_config_for_test(&mut ctx, 1000);
        config.add_fee_tier(200, 1000, &ctx);
        let coin_a = balance::create_for_testing<cetus::CETUS>(10000000).into_coin(&mut ctx);
        let coin_b = balance::create_for_testing<usdc::USDC>(10000000).into_coin(&mut ctx);
        let mut pools = new_pools_for_test(&mut ctx);
        init_manager_and_whitelist(&config, &mut pools, &mut ctx);
        let (position, coin_a, coin_b) = create_pool_v2(
            &config,
            &mut pools,
            200,
            get_sqrt_price_at_tick(i32::from(1000)),
            string::utf8(b"https://cetus.zone"),
            0,
            2000,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            false,
            &clock,
            &mut ctx,
        );
        transfer::public_transfer(admin_cap, ctx.sender());
        coin_a.into_balance().destroy_for_testing();
        coin_b.into_balance().destroy_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        clock.destroy_for_testing();
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[
        expected_failure(
            abort_code = cetus_clmm::pool_creator::EInitSqrtPriceNotBetweenLowerAndUpper,
        ),
    ]
    fun test_create_pool_v2_sqrt_price_error() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let metadata_a = cetus::init_coin(&mut ctx);
        let metadata_b = usdc::init_coin(&mut ctx);
        let (admin_cap, mut config) = new_global_config_for_test(&mut ctx, 1000);
        config.add_fee_tier(200, 1000, &ctx);
        let coin_a = balance::create_for_testing<cetus::CETUS>(10000000).into_coin(&mut ctx);
        let coin_b = balance::create_for_testing<usdc::USDC>(10000000).into_coin(&mut ctx);
        let mut pools = new_pools_for_test(&mut ctx);
        init_manager_and_whitelist(&config, &mut pools, &mut ctx);
        let (position, coin_a, coin_b) = create_pool_v2(
            &config,
            &mut pools,
            200,
            get_sqrt_price_at_tick(i32::neg_from(1000)),
            string::utf8(b"https://cetus.zone"),
            0,
            2000,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            false,
            &clock,
            &mut ctx,
        );
        transfer::public_transfer(admin_cap, ctx.sender());
        coin_a.into_balance().destroy_for_testing();
        coin_b.into_balance().destroy_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        clock.destroy_for_testing();
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::pool_creator::EPoolIsPermission)]
    fun test_create_pool_v2_pool_is_permissioned() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let metadata_a = cetus::init_coin(&mut ctx);
        let metadata_b = usdc::init_coin(&mut ctx);
        let (admin_cap, mut config) = new_global_config_for_test(&mut ctx, 1000);
        config.add_fee_tier(200, 1000, &ctx);
        let coin_a = balance::create_for_testing<cetus::CETUS>(10000000).into_coin(&mut ctx);
        let coin_b = balance::create_for_testing<usdc::USDC>(10000000).into_coin(&mut ctx);
        let mut pools = new_pools_for_test(&mut ctx);
        init_manager_and_whitelist(&config, &mut pools, &mut ctx);
        let cap = factory::mint_pool_creation_cap_by_admin<cetus::CETUS>(
            &config,
            &mut pools,
            &mut ctx,
        );
        factory::add_allowed_pair_config<usdc::USDC>(&config, &mut pools, 200, &ctx);
        factory::register_permission_pair<cetus::CETUS, usdc::USDC>(
            &config,
            &mut pools,
            200,
            &cap,
            &mut ctx,
        );
        let (position, coin_a, coin_b) = create_pool_v2(
            &config,
            &mut pools,
            200,
            get_sqrt_price_at_tick(i32::from(1000)),
            string::utf8(b"https://cetus.zone"),
            0,
            2000,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            false,
            &clock,
            &mut ctx,
        );
        transfer::public_transfer(cap, ctx.sender());
        transfer::public_transfer(admin_cap, ctx.sender());
        coin_a.into_balance().destroy_for_testing();
        coin_b.into_balance().destroy_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        clock.destroy_for_testing();
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    fun test_create_pool_v2_with_creation_cap() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let metadata_a = cetus::init_coin(&mut ctx);
        let metadata_b = usdc::init_coin(&mut ctx);
        let (admin_cap, mut config) = new_global_config_for_test(&mut ctx, 1000);
        config.add_fee_tier(200, 1000, &ctx);
        let coin_a = balance::create_for_testing<cetus::CETUS>(10000000).into_coin(&mut ctx);
        let coin_b = balance::create_for_testing<usdc::USDC>(10000000).into_coin(&mut ctx);
        let mut pools = new_pools_for_test(&mut ctx);
        init_manager_and_whitelist(&config, &mut pools, &mut ctx);
        let cap = factory::mint_pool_creation_cap_by_admin<cetus::CETUS>(
            &config,
            &mut pools,
            &mut ctx,
        );
        factory::add_allowed_pair_config<usdc::USDC>(&config, &mut pools, 200, &ctx);
        factory::register_permission_pair<cetus::CETUS, usdc::USDC>(
            &config,
            &mut pools,
            200,
            &cap,
            &mut ctx,
        );
        let (position, coin_a, coin_b) = create_pool_v2_with_creation_cap(
            &config,
            &mut pools,
            &cap,
            200,
            get_sqrt_price_at_tick(i32::from(1000)),
            string::utf8(b"https://cetus.zone"),
            0,
            2000,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            false,
            &clock,
            &mut ctx,
        );
        transfer::public_transfer(cap, ctx.sender());
        transfer::public_transfer(admin_cap, ctx.sender());
        coin_a.into_balance().destroy_for_testing();
        coin_b.into_balance().destroy_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        clock.destroy_for_testing();
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::factory::ECapNotMatchWithCoinType)]
    fun test_create_pool_v2_with_creation_cap_error_cap_not_match_with_coin_type() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let metadata_a = cetus::init_coin(&mut ctx);
        let metadata_b = usdc::init_coin(&mut ctx);
        let (admin_cap, mut config) = new_global_config_for_test(&mut ctx, 1000);
        config.add_fee_tier(200, 1000, &ctx);
        let coin_a = balance::create_for_testing<cetus::CETUS>(10000000).into_coin(&mut ctx);
        let coin_b = balance::create_for_testing<usdc::USDC>(10000000).into_coin(&mut ctx);
        let mut pools = new_pools_for_test(&mut ctx);
        init_manager_and_whitelist(&config, &mut pools, &mut ctx);
        let cap = factory::mint_pool_creation_cap_by_admin<usdc::USDC>(
            &config,
            &mut pools,
            &mut ctx,
        );
        factory::add_allowed_pair_config<usdc::USDC>(&config, &mut pools, 200, &ctx);
        factory::register_permission_pair<cetus::CETUS, usdc::USDC>(
            &config,
            &mut pools,
            200,
            &cap,
            &mut ctx,
        );
        let (position, coin_a, coin_b) = create_pool_v2_with_creation_cap(
            &config,
            &mut pools,
            &cap,
            200,
            get_sqrt_price_at_tick(i32::from(1000)),
            string::utf8(b"https://cetus.zone"),
            0,
            2000,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            false,
            &clock,
            &mut ctx,
        );
        transfer::public_transfer(cap, ctx.sender());
        transfer::public_transfer(admin_cap, ctx.sender());
        coin_a.into_balance().destroy_for_testing();
        coin_b.into_balance().destroy_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        clock.destroy_for_testing();
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[
        expected_failure(
            abort_code = cetus_clmm::pool_creator::EInitSqrtPriceNotBetweenLowerAndUpper,
        ),
    ]
    fun test_create_pool_v2_with_creation_cap_sqrt_price_error() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let metadata_a = cetus::init_coin(&mut ctx);
        let metadata_b = usdc::init_coin(&mut ctx);
        let (admin_cap, mut config) = new_global_config_for_test(&mut ctx, 1000);
        config.add_fee_tier(200, 1000, &ctx);
        let coin_a = balance::create_for_testing<cetus::CETUS>(10000000).into_coin(&mut ctx);
        let coin_b = balance::create_for_testing<usdc::USDC>(10000000).into_coin(&mut ctx);
        let mut pools = new_pools_for_test(&mut ctx);
        init_manager_and_whitelist(&config, &mut pools, &mut ctx);
        let cap = factory::mint_pool_creation_cap_by_admin<cetus::CETUS>(
            &config,
            &mut pools,
            &mut ctx,
        );
        factory::add_allowed_pair_config<usdc::USDC>(&config, &mut pools, 200, &ctx);
        factory::register_permission_pair<cetus::CETUS, usdc::USDC>(
            &config,
            &mut pools,
            200,
            &cap,
            &mut ctx,
        );
        let (position, coin_a, coin_b) = create_pool_v2_with_creation_cap(
            &config,
            &mut pools,
            &cap,
            200,
            get_sqrt_price_at_tick(i32::neg_from(1000)),
            string::utf8(b"https://cetus.zone"),
            0,
            2000,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            false,
            &clock,
            &mut ctx,
        );
        transfer::public_transfer(cap, ctx.sender());
        transfer::public_transfer(admin_cap, ctx.sender());
        coin_a.into_balance().destroy_for_testing();
        coin_b.into_balance().destroy_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        clock.destroy_for_testing();
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::pool_creator::EMethodDeprecated)]
    fun test_create_pool_v2_by_creation_cap() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let metadata_a = cetus::init_coin(&mut ctx);
        let metadata_b = usdc::init_coin(&mut ctx);
        let (admin_cap, mut config) = new_global_config_for_test(&mut ctx, 1000);
        config.add_fee_tier(200, 1000, &ctx);
        let coin_a = balance::create_for_testing<cetus::CETUS>(10000000).into_coin(&mut ctx);
        let coin_b = balance::create_for_testing<usdc::USDC>(10000000).into_coin(&mut ctx);
        let mut pools = new_pools_for_test(&mut ctx);
        init_manager_and_whitelist(&config, &mut pools, &mut ctx);
        let cap = factory::mint_pool_creation_cap_by_admin<cetus::CETUS>(
            &config,
            &mut pools,
            &mut ctx,
        );
        factory::add_allowed_pair_config<usdc::USDC>(&config, &mut pools, 200, &ctx);
        factory::register_permission_pair<cetus::CETUS, usdc::USDC>(
            &config,
            &mut pools,
            200,
            &cap,
            &mut ctx,
        );
        let (position, coin_a, coin_b) = create_pool_v2_by_creation_cap(
            &config,
            &mut pools,
            &cap,
            200,
            get_sqrt_price_at_tick(i32::from(1000)),
            string::utf8(b"https://cetus.zone"),
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            false,
            &clock,
            &mut ctx,
        );
        transfer::public_transfer(cap, ctx.sender());
        transfer::public_transfer(admin_cap, ctx.sender());
        coin_a.into_balance().destroy_for_testing();
        coin_b.into_balance().destroy_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        clock.destroy_for_testing();
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }

    #[test]
    fun test_full_range_tick_range() {
        let (min_tick, max_tick) = full_range_tick_range(1);
        assert!(min_tick == i32::neg_from(tick_bound()).as_u32(), 0);
        assert!(max_tick == tick_bound(), 0);
        let (min_tick, max_tick) = full_range_tick_range(2);
        assert!(min_tick == i32::neg_from(tick_bound()).as_u32(), 0);
        assert!(max_tick == tick_bound(), 0);
        let (min_tick, max_tick) = full_range_tick_range(10);

        assert!(min_tick == i32::neg_from(443630).as_u32(), 0);
        assert!(max_tick == 443630, 0);
        let (min_tick, max_tick) = full_range_tick_range(200);
        assert!(min_tick == i32::neg_from(443600).as_u32(), 0);
        assert!(max_tick == 443600, 0);
    }

    #[test]
    #[expected_failure(abort_code = cetus_clmm::pool_creator::ECapNotMatchWithPoolKey)]
    fun test_create_pool_v2_with_creation_cap_not_match_with_pool_key() {
        let mut ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);
        let metadata_a = cetus::init_coin(&mut ctx);
        let metadata_b = usdc::init_coin(&mut ctx);
        let (admin_cap, mut config) = new_global_config_for_test(&mut ctx, 1000);
        config.add_fee_tier(200, 1000, &ctx);
        let coin_a = balance::create_for_testing<cetus::CETUS>(10000000).into_coin(&mut ctx);
        let coin_b = balance::create_for_testing<usdc::USDC>(10000000).into_coin(&mut ctx);
        let mut pools = new_pools_for_test(&mut ctx);
        init_manager_and_whitelist(&config, &mut pools, &mut ctx);
        let cap = factory::mint_pool_creation_cap_by_admin<cetus::CETUS>(
            &config,
            &mut pools,
            &mut ctx,
        );
        let error_cap = factory::mint_pool_creation_cap_by_admin<usdc::USDC>(
            &config,
            &mut pools,
            &mut ctx,
        );
        factory::add_allowed_pair_config<usdc::USDC>(&config, &mut pools, 200, &ctx);
        factory::register_permission_pair<cetus::CETUS, usdc::USDC>(
            &config,
            &mut pools,
            200,
            &cap,
            &mut ctx,
        );
        let (position, coin_a, coin_b) = create_pool_v2_with_creation_cap(
            &config,
            &mut pools,
            &error_cap,
            200,
            get_sqrt_price_at_tick(i32::from(1000)),
            string::utf8(b"https://cetus.zone"),
            0,
            2000,
            coin_b,
            coin_a,
            &metadata_b,
            &metadata_a,
            false,
            &clock,
            &mut ctx,
        );
        transfer::public_transfer(cap, ctx.sender());
        transfer::public_transfer(error_cap, ctx.sender());
        transfer::public_transfer(admin_cap, ctx.sender());
        coin_a.into_balance().destroy_for_testing();
        coin_b.into_balance().destroy_for_testing();
        transfer::public_transfer(position, ctx.sender());
        transfer::public_share_object(config);
        transfer::public_share_object(pools);
        clock.destroy_for_testing();
        transfer::public_freeze_object(metadata_a);
        transfer::public_freeze_object(metadata_b);
    }
}

#[test_only]
module cetus_clmm::cetus {
    use sui::coin::{Self, CoinMetadata};
    use sui::test_utils;

    public struct CETUS has drop {}

    #[allow(lint(self_transfer))]
    public fun init_coin(ctx: &mut TxContext): CoinMetadata<CETUS> {
        let (treasury_cap_cetus, metadata_cetus) = coin::create_currency(
            test_utils::create_one_time_witness<CETUS>(),
            9,
            b"CETUS",
            b"CETUS",
            b"CETUS",
            option::none(),
            ctx,
        );
        transfer::public_transfer(treasury_cap_cetus, ctx.sender());
        metadata_cetus
    }
}

#[test_only]
module cetus_clmm::usdc {
    use sui::coin::{Self, CoinMetadata};
    use sui::test_utils;

    public struct USDC has drop {}

    #[allow(lint(self_transfer))]
    public fun init_coin(ctx: &mut TxContext): CoinMetadata<USDC> {
        let (treasury_cap, metadata) = coin::create_currency(
            test_utils::create_one_time_witness<USDC>(),
            6,
            b"USDC",
            b"USDC",
            b"USDC",
            option::none(),
            ctx,
        );
        transfer::public_transfer(treasury_cap, ctx.sender());
        metadata
    }
}

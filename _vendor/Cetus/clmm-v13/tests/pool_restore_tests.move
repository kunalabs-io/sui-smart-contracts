#[test_only]
module cetus_clmm::pool_restore_tests;

use cetus_clmm::config;
use cetus_clmm::pool;
use sui::test_scenario;
use integer_mate::i32;
use cetus_clmm::tick_math::get_sqrt_price_at_tick;
use std::string;
use sui::clock;
use cetus_clmm::pool_tests::add_liquidity;
use sui::clock::Clock;
use cetus_clmm::config::AdminCap;
use cetus_clmm::config::GlobalConfig;
use cetus_clmm::pool::Pool;
use cetus_clmm::position::Position;
use sui::test_scenario::Scenario;
use std::unit_test::assert_eq;
use sui::coin;

public struct CoinA {}
public struct CoinB {}

const EMERGENCY_RESTORE_NEED_VERSION: u64 = 9223372036854775807;
const EMERGENCY_RESTORE_VERSION: u64 = 18446744073709551000;

fun prepare(): (Clock, AdminCap, GlobalConfig, Pool<CoinA, CoinB>, Position, Scenario) {
    let mut scenerio = test_scenario::begin(@0x1234);
    let ctx = scenerio.ctx();
    let (cap, config) = config::new_global_config_for_test(
        ctx,
        2000,
    );
    let clock = clock::create_for_testing(ctx);
    let mut pool = pool::new_for_test<CoinA, CoinB>(
        100,
        get_sqrt_price_at_tick(i32::zero()),
        2000,
        string::utf8(b""),
        0,
        &clock,
        ctx,
    );
    let (tick_lower, tick_upper) = (i32::neg_from(1000), i32::from(1000));
    let mut position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        ctx,
    );
    add_liquidity(&config, &mut pool, &mut position_nft, 100000000, &clock);
    (clock, cap, config, pool, position_nft, scenerio)
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EDeprecatedFunction)]
fun test_emergency_restore(){
    let (clock, admin_cap, mut config, mut pool, position_nft, mut scenerio) = prepare();
    let origin_position_info = pool::borrow_position_info(&pool, object::id(&position_nft));
    let origin_liquidity = origin_position_info.info_liquidity();
    
    config::add_role(&admin_cap, &mut config, @0x1234, 0);

    // construct attack position
    let (tick_lower, tick_upper) = (i32::from(300000), i32::from(300100));
    let mut attack_position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        scenerio.ctx(),
    );
    add_liquidity(&config, &mut pool, &mut attack_position_nft, 9381000597014909076, &clock);
    pool.pause_pool();

    config::update_package_version_for_test(&admin_cap, &mut config, EMERGENCY_RESTORE_VERSION);
    // init position snapshow, remove 10%
    pool::init_position_snapshot(&config, &mut pool, 100000, scenerio.ctx());

    // emergency restore
    pool::emergency_remove_malicious_position(&mut config, &mut pool, object::id(&attack_position_nft), scenerio.ctx());

    // pool restore
    let current_sqrt_price = pool::current_sqrt_price(&pool);
    let current_liquidity = pool::liquidity(&pool);
    pool::emergency_restore_pool_state(&mut config, &mut pool, current_sqrt_price, current_liquidity, &clock, scenerio.ctx());

    assert!(!pool::is_position_exist(&pool, object::id(&attack_position_nft)), 0);
    // apply liquidity cut
    pool::apply_liquidity_cut(&config, &mut pool, object::id(&position_nft), 32000000, &clock, scenerio.ctx());
    let om_position_info = pool::borrow_position_info(&pool, object::id(&position_nft));
    assert!(om_position_info.info_liquidity() != origin_liquidity, 0);
    assert!(pool::is_attacked_position(&pool, object::id(&position_nft)), 0);
    let snapshot = pool::get_position_snapshot_by_position_id(&pool, object::id(&position_nft));
    assert!(snapshot.liquidity() == origin_liquidity, 0);

    clock.destroy_for_testing();
    transfer::public_share_object(position_nft);
    transfer::public_share_object(attack_position_nft);
    transfer::public_share_object(admin_cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    scenerio.end();

}


#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EDeprecatedFunction)]
fun test_emergency_restore_cannot_close_position(){
    let (clock, admin_cap, mut config, mut pool, position_nft, mut scenerio) = prepare();
    let origin_position_info = pool::borrow_position_info(&pool, object::id(&position_nft));
    let origin_liquidity = origin_position_info.info_liquidity();
    
    config::add_role(&admin_cap, &mut config, @0x1234, 0);

    // construct attack position
    let (tick_lower, tick_upper) = (i32::from(300000), i32::from(300100));
    let mut attack_position_nft = pool::open_position(
        &config,
        &mut pool,
        i32::as_u32(tick_lower),
        i32::as_u32(tick_upper),
        scenerio.ctx(),
    );
    add_liquidity(&config, &mut pool, &mut attack_position_nft, 9381000597014909076, &clock);
    // pool::pause(&config, &mut pool, scenerio.ctx());
    pool.pause_pool();

    config::update_package_version_for_test(&admin_cap, &mut config, EMERGENCY_RESTORE_VERSION);
    // init position snapshow, remove 10%
    pool::init_position_snapshot(&config, &mut pool, 100000, scenerio.ctx());

    // emergency restore
    pool::emergency_remove_malicious_position(&mut config, &mut pool, object::id(&attack_position_nft), scenerio.ctx());

    // pool restore
    let current_sqrt_price = pool::current_sqrt_price(&pool);
    let current_liquidity = pool::liquidity(&pool);
    pool::emergency_restore_pool_state(&mut config, &mut pool, current_sqrt_price, current_liquidity, &clock, scenerio.ctx());

    assert!(!pool::is_position_exist(&pool, object::id(&attack_position_nft)), 0);
    // apply liquidity cut
    pool::apply_liquidity_cut(&config, &mut pool, object::id(&position_nft), 32000000, &clock, scenerio.ctx());
    let om_position_info = pool::borrow_position_info(&pool, object::id(&position_nft));
    assert!(om_position_info.info_liquidity() != origin_liquidity, 0);

    config::update_package_version(&admin_cap, &mut config, 10);
    // pool::unpause(&config, &mut pool, scenerio.ctx());
    pool.unpause_pool();
    pool::close_position(&config, &mut pool, position_nft);

    clock.destroy_for_testing();
    transfer::public_share_object(attack_position_nft);
    transfer::public_share_object(admin_cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    scenerio.end();

}

#[test]
fun test_init_position_snapshot(){
    let (clock, admin_cap, mut config, mut pool, position_nft, mut scenerio) = prepare();
    
    config::add_role(&admin_cap, &mut config, @0x1234, 0);
    // pool::pause(&config, &mut pool, scenerio.ctx());
    pool.pause_pool();
    config::update_package_version_for_test(&admin_cap, &mut config, EMERGENCY_RESTORE_VERSION);

    // init position snapshow, remove 10%
    pool::init_position_snapshot(&config, &mut pool, 100000, scenerio.ctx());
    let lp = pool.position_liquidity_snapshot();
    assert!(lp.remove_percent() == 100000, 0);
    assert_eq!(lp.current_sqrt_price(), pool.current_sqrt_price());

    clock.destroy_for_testing();
    transfer::public_share_object(position_nft);
    transfer::public_share_object(admin_cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    scenerio.end();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EPoolNotPaused)]
fun test_init_position_snapshot_not_paused(){
    let (clock, admin_cap, mut config, mut pool, position_nft, mut scenerio) = prepare();
    
    config::add_role(&admin_cap, &mut config, @0x1234, 0);
    config::update_package_version_for_test(&admin_cap, &mut config, EMERGENCY_RESTORE_VERSION);

    // init position snapshow, remove 10%
    pool::init_position_snapshot(&config, &mut pool, 100000, scenerio.ctx());

    clock.destroy_for_testing();
    transfer::public_share_object(position_nft);
    transfer::public_share_object(admin_cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    scenerio.end();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EInvalidRemovePercent)]
fun test_init_position_snapshot_ppm_error(){
    let (clock, admin_cap, mut config, mut pool, position_nft, mut scenerio) = prepare();
    
    config::add_role(&admin_cap, &mut config, @0x1234, 0);
    // pool::pause(&config, &mut pool, scenerio.ctx());
    pool.pause_pool();
    config::update_package_version_for_test(&admin_cap, &mut config, EMERGENCY_RESTORE_VERSION);

    // init position snapshow, remove 10%
    pool::init_position_snapshot(&config, &mut pool, 1000001, scenerio.ctx());

    clock.destroy_for_testing();
    transfer::public_share_object(position_nft);
    transfer::public_share_object(admin_cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    scenerio.end();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EDeprecatedFunction)]
fun test_governance_fund_injection(){
    let (clock, admin_cap, mut config, mut pool, position_nft, mut scenerio) = prepare();
    
    config::add_role(&admin_cap, &mut config, @0x1234, 0);
    // pool::pause(&config, &mut pool, scenerio.ctx());
    pool.pause_pool();
    config::update_package_version_for_test(&admin_cap, &mut config, EMERGENCY_RESTORE_VERSION);

    // init position snapshow, remove 10%
    let coin_a = coin::mint_for_testing(1000000000, scenerio.ctx() );
    let coin_b = coin::mint_for_testing(1000000000, scenerio.ctx() );
    let (balance_a, balance_b) = pool.balances();
    let value_a = balance_a.value();
    let value_b = balance_b.value();
    pool::governance_fund_injection<CoinA, CoinB>(&mut config, &mut pool, coin_a, coin_b, scenerio.ctx());
    let (balance_a, balance_b) = pool.balances();
    assert!(balance_a.value() == value_a + 1000000000, 0);
    assert!(balance_b.value() == value_b + 1000000000, 0);

    clock.destroy_for_testing();
    transfer::public_share_object(position_nft);
    transfer::public_share_object(admin_cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    scenerio.end();
}

#[test]
#[expected_failure(abort_code = cetus_clmm::pool::EDeprecatedFunction)]
fun test_governance_fund_withdrawal(){
    let (clock, admin_cap, mut config, mut pool, position_nft, mut scenerio) = prepare();
    
    config::add_role(&admin_cap, &mut config, @0x1234, 0);
    // pool::pause(&config, &mut pool, scenerio.ctx());
    pool.pause_pool();
    config::update_package_version(&admin_cap, &mut config, EMERGENCY_RESTORE_NEED_VERSION);

    // init position snapshow, remove 10%
    let coin_a = coin::mint_for_testing(1000000000, scenerio.ctx() );
    let coin_b = coin::mint_for_testing(1000000000, scenerio.ctx() );
    let (balance_a, balance_b) = pool.balances();
    let value_a = balance_a.value();
    let value_b = balance_b.value();
    pool::governance_fund_injection<CoinA, CoinB>(&mut config, &mut pool, coin_a, coin_b, scenerio.ctx());
    let (balance_a, balance_b) = pool.balances();
    assert!(balance_a.value() == value_a + 1000000000, 0);
    assert!(balance_b.value() == value_b + 1000000000, 0);
    pool::governance_fund_withdrawal<CoinA, CoinB>(&mut config, &mut pool, 1000000000, 1000000000, scenerio.ctx());
    let (balance_a, balance_b) = pool.balances();
    assert!(balance_a.value() == value_a, 0);
    assert!(balance_b.value() == value_b, 0);

    clock.destroy_for_testing();
    transfer::public_share_object(position_nft);
    transfer::public_share_object(admin_cap);
    transfer::public_share_object(config);
    transfer::public_share_object(pool);
    scenerio.end();
}
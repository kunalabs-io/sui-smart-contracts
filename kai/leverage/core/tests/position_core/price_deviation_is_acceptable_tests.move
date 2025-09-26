#[test_only]
module kai_leverage::position_core_price_deviation_is_acceptable_tests;

use kai_leverage::position_core_clmm as core;
use kai_leverage::position_core_test_util;
use sui::clock;
use sui::test_scenario;
use sui::test_utils::destroy;

#[test]
fun test_price_deviation_is_acceptable() {
    let mut scenario = test_scenario::begin(@0);
    let package_admin = position_core_test_util::create_admin_for_testing(scenario.ctx());
    let mut clock = clock::create_for_testing(scenario.ctx());
    clock.set_for_testing(1755000000000);

    let (
        sui_pio,
        usdc_pio,
        pool,
        supply_pool_x,
        supply_pool_y,
    ) = position_core_test_util::initialize_config_for_testing(
        &mut scenario,
        &package_admin,
        &clock,
    );
    scenario.next_tx(@0);

    let config = scenario.take_shared();

    // Test case 1: Oracle price 3.00, Pool price 3.00 (same price) - should be acceptable
    {
        let oracle_ema_price_x128 = (3_00 << 128) / 100;
        let pool_price_x128 = (3_00 << 128) / 100;
        assert!(
            core::price_deviation_is_acceptable(
                &config,
                oracle_ema_price_x128,
                pool_price_x128,
            ),
        );
    };
    // Test case 2: Oracle price 3.00, Pool price 4.60 (>30% deviation)
    {
        let oracle_ema_price_x128 = (3_00 << 128) / 100;
        let pool_price_x128 = (4_60 << 128) / 100;
        assert!(
            !core::price_deviation_is_acceptable(
                &config,
                oracle_ema_price_x128,
                pool_price_x128,
            ),
        );
    };
    // Test case 3: Oracle price 4.60, Pool price 3.00 (>30% deviation)
    {
        let oracle_ema_price_x128 = (4_60 << 128) / 100;
        let pool_price_x128 = (3_00 << 128) / 100;
        assert!(
            !core::price_deviation_is_acceptable(
                &config,
                oracle_ema_price_x128,
                pool_price_x128,
            ),
        );
    };
    // Test case 4: Oracle price 3.00, Pool price just below upper boundary (3.00 * 1.3 = 3.90)
    {
        let oracle_ema_price_x128 = (3_00 << 128) / 100;
        let pool_price_x128 = (3_90 << 128) / 100;
        assert!(
            core::price_deviation_is_acceptable(
                &config,
                oracle_ema_price_x128,
                pool_price_x128,
            ),
        );
    };
    // Test case 5: Oracle price 3.00, Pool price just above lower boundary (3.00 * 0.7 = 2.10)
    {
        let oracle_ema_price_x128 = (3_00 << 128) / 100;
        let pool_price_x128 = ((2_101 << 128) + 3) / 1000;
        assert!(
            core::price_deviation_is_acceptable(
                &config,
                oracle_ema_price_x128,
                pool_price_x128,
            ),
        );
    };
    // Test case 6: Oracle price 3.00, Pool price just above upper boundary (3.90 + 0.01 = 3.91)
    {
        let oracle_ema_price_x128 = (3_00 << 128) / 100;
        let pool_price_x128 = (3_91 << 128) / 100;
        assert!(
            !core::price_deviation_is_acceptable(
                &config,
                oracle_ema_price_x128,
                pool_price_x128,
            ),
        );
    };
    // Test case 7: Oracle price 3.00, Pool price just below lower boundary (2.10 - 0.01 = 2.09)
    {
        let oracle_ema_price_x128 = (3_00 << 128) / 100;
        let pool_price_x128 = (2_09 << 128) / 100;
        assert!(
            !core::price_deviation_is_acceptable(
                &config,
                oracle_ema_price_x128,
                pool_price_x128,
            ),
        );
    };

    test_scenario::return_shared(config);

    scenario.end();
    destroy(pool);
    destroy(supply_pool_x);
    destroy(supply_pool_y);
    destroy(package_admin);
    destroy(clock);
    destroy(sui_pio);
    destroy(usdc_pio);
}

#[test_only]
module kai_leverage::position_core_test_util_macros;

use access_management::access::PackageAdmin;
use kai_leverage::piecewise;
use kai_leverage::position_core_clmm::{Self as core, PositionConfig};
use kai_leverage::position_core_test_util;
use kai_leverage::pyth_test_util;
use kai_leverage::supply_pool::SupplyPool;
use kai_leverage::supply_pool_tests::{Self, SSUI, SUSDC};
use pyth::price_info::PriceInfoObject;
use rate_limiter::net_sliding_sum_limiter;
use std::type_name;
use std::u128;
use std::u64;
use sui::clock::Clock;
use sui::sui::SUI;
use sui::test_scenario::{Self, Scenario};
use usdc::usdc::USDC;

public macro fun initialize_config_for_testing<$Pool>(
    $scenario: &mut Scenario,
    $package_admin: &PackageAdmin,
    $clock: &Clock,
    $create_pool: |u128, &Clock, &mut TxContext| -> $Pool,
): (
    PriceInfoObject,
    PriceInfoObject,
    $Pool,
    SupplyPool<SUI, SSUI>,
    SupplyPool<USDC, SUSDC>,
) {
    let clock = $clock;
    let scenario = $scenario;
    let package_admin = $package_admin;

    let (sui_pio, usdc_pio, pool, mut supply_pool_x, mut supply_pool_y) = {
        let sui_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
            3_50,
            clock,
            scenario.ctx(),
        );
        let usdc_pio = pyth_test_util::create_pyth_pio_with_price_human_mul_100(
            1_00,
            clock,
            scenario.ctx(),
        );

        let current_sqrt_price_x64 = position_core_test_util::price_mul_100_human_to_sqrt_x64<
            SUI,
            USDC,
        >(3_50);

        let pool = $create_pool(
            current_sqrt_price_x64,
            clock,
            scenario.ctx(),
        );

        let mut supply_pool_x = supply_pool_tests::create_sui_supply_pool_for_testing();
        let mut supply_pool_y = supply_pool_tests::create_usdc_supply_pool_for_testing();
        supply_pool_tests::supply_for_testing(
            &mut supply_pool_x,
            1000000_000000000,
            clock,
            scenario.ctx(),
        );
        supply_pool_tests::supply_for_testing(
            &mut supply_pool_y,
            1000000_000000,
            clock,
            scenario.ctx(),
        );

        (sui_pio, usdc_pio, pool, supply_pool_x, supply_pool_y)
    };

    // create config
    scenario.next_tx(@0);
    {
        let (_, request) = core::create_empty_config(object::id(&pool), scenario.ctx());
        request.admin_approve_request(package_admin);
    };

    // configure config
    scenario.next_tx(@0);
    {
        let mut config = scenario.take_shared<PositionConfig>();

        config.set_allow_new_positions(true, scenario.ctx()).admin_approve_request(package_admin);
        config
            .set_min_liq_start_price_delta_bps(30_00, scenario.ctx())
            .admin_approve_request(package_admin);
        config.set_min_init_margin_bps(1_5000, scenario.ctx()).admin_approve_request(package_admin);
        config
            .set_deleverage_margin_bps(1_3100, scenario.ctx())
            .admin_approve_request(package_admin);
        config
            .set_base_deleverage_factor_bps(50_00, scenario.ctx())
            .admin_approve_request(package_admin);
        config.set_liq_margin_bps(1_3000, scenario.ctx()).admin_approve_request(package_admin);
        config.set_base_liq_factor_bps(50_00, scenario.ctx()).admin_approve_request(package_admin);
        config.set_liq_bonus_bps(5_00, scenario.ctx()).admin_approve_request(package_admin);
        config
            .set_max_global_l(u128::max_value!(), scenario.ctx())
            .admin_approve_request(package_admin);
        config
            .set_max_position_l(u128::max_value!(), scenario.ctx())
            .admin_approve_request(package_admin);
        config.set_rebalance_fee_bps(1_00, scenario.ctx()).admin_approve_request(package_admin);
        config.set_liq_fee_bps(10_00, scenario.ctx()).admin_approve_request(package_admin);
        config
            .set_position_creation_fee_sui(1_000000000, scenario.ctx())
            .admin_approve_request(package_admin);

        // configure lend facil
        let interest_model = piecewise::create(
            0,
            10_00,
            vector::singleton(piecewise::section(100_00, 10_00)),
        );
        let request = supply_pool_x.add_lend_facil(
            object::id(config.lend_facil_cap()),
            interest_model,
            scenario.ctx(),
        );
        request.admin_approve_request(package_admin);
        let request = supply_pool_y.add_lend_facil(
            object::id(config.lend_facil_cap()),
            interest_model,
            scenario.ctx(),
        );
        request.admin_approve_request(package_admin);
        let request = supply_pool_x.set_lend_facil_max_liability_outstanding(
            object::id(config.lend_facil_cap()),
            u64::max_value!(),
            scenario.ctx(),
        );
        request.admin_approve_request(package_admin);
        let request = supply_pool_x.set_lend_facil_max_utilization_bps(
            object::id(config.lend_facil_cap()),
            90_00,
            scenario.ctx(),
        );
        request.admin_approve_request(package_admin);
        let request = supply_pool_y.set_lend_facil_max_liability_outstanding(
            object::id(config.lend_facil_cap()),
            u64::max_value!(),
            scenario.ctx(),
        );
        request.admin_approve_request(package_admin);
        let request = supply_pool_y.set_lend_facil_max_utilization_bps(
            object::id(config.lend_facil_cap()),
            90_00,
            scenario.ctx(),
        );
        request.admin_approve_request(package_admin);

        // add pyth config
        let request = config.config_add_empty_pyth_config(scenario.ctx());
        request.admin_approve_request(package_admin);
        let request = config.set_pyth_config_max_age_secs(60, scenario.ctx());
        request.admin_approve_request(package_admin);
        let request = config.pyth_config_allow_pio(
            type_name::with_defining_ids<SUI>(),
            object::id(&sui_pio),
            scenario.ctx(),
        );
        request.admin_approve_request(package_admin);
        let request = config.pyth_config_allow_pio(
            type_name::with_defining_ids<USDC>(),
            object::id(&usdc_pio),
            scenario.ctx(),
        );
        request.admin_approve_request(package_admin);

        // add rate limiter
        let rate_limiter = net_sliding_sum_limiter::new(
            5 * 60 * 1000, // 5 minutes per bucket
            12, // 12 buckets (1 hour total)
            option::none(), // no max inflow limit
            option::none(), // no max outflow limit
            option::none(), // no max net inflow limit
            option::none(), // no max net outflow limit
            clock,
        );
        let request = config.add_create_withdraw_limiter(rate_limiter, scenario.ctx());
        request.admin_approve_request(package_admin);

        test_scenario::return_shared(config);
    };

    (sui_pio, usdc_pio, pool, supply_pool_x, supply_pool_y)
}

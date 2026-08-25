#[test_only]
module kai_leverage::supply_pool_tests;

use kai_leverage::equity;
use kai_leverage::piecewise;
use kai_leverage::supply_pool::{Self, SupplyPool};
use sui::balance;
use sui::clock::{Self, Clock};
use sui::sui::SUI;
use sui::test_scenario;
use std::unit_test::destroy;
use usdc::usdc::USDC;

public struct SSUI has drop {}
public struct SUSDC has drop {}

public struct WRONG_SSUI has drop {}
public struct WRONG_SUSDC has drop {}

public fun create_sui_supply_pool_for_testing(): SupplyPool<SUI, SSUI> {
    let mut test = test_scenario::begin(@0);

    let treasury = equity::create_treasury_for_testing<SSUI>(test.ctx());

    let request = supply_pool::create_pool<SUI, SSUI>(treasury, test.ctx());
    destroy(request);

    test.next_tx(@0);
    let pool = test.take_shared();
    test.end();

    pool
}

public fun create_wrong_sui_supply_pool_for_testing(): SupplyPool<SUI, WRONG_SSUI> {
    let mut test = test_scenario::begin(@0);

    let treasury = equity::create_treasury_for_testing<WRONG_SSUI>(test.ctx());

    let request = supply_pool::create_pool<SUI, WRONG_SSUI>(treasury, test.ctx());
    destroy(request);

    test.next_tx(@0);
    let pool = test.take_shared();
    test.end();

    pool
}

public fun create_usdc_supply_pool_for_testing(): SupplyPool<USDC, SUSDC> {
    let mut test = test_scenario::begin(@0);

    let treasury = equity::create_treasury_for_testing<SUSDC>(test.ctx());

    let request = supply_pool::create_pool<USDC, SUSDC>(treasury, test.ctx());
    destroy(request);

    test.next_tx(@0);
    let pool = test.take_shared();
    test.end();

    pool
}

public fun create_wrong_usdc_supply_pool_for_testing(): SupplyPool<USDC, WRONG_SUSDC> {
    let mut test = test_scenario::begin(@0);

    let treasury = equity::create_treasury_for_testing<WRONG_SUSDC>(test.ctx());

    let request = supply_pool::create_pool<USDC, WRONG_SUSDC>(treasury, test.ctx());
    destroy(request);

    test.next_tx(@0);
    let pool = test.take_shared();
    test.end();

    pool
}

public fun supply_for_testing<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    amount: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let (shares, request) = pool.supply(
        balance::create_for_testing(amount),
        clock,
        ctx,
    );
    destroy(request);
    destroy(shares);
}

#[test]
fun test_available_balance_value() {
    let mut test = test_scenario::begin(@0);
    let clock = clock::create_for_testing(test.ctx());
    let mut pool = create_sui_supply_pool_for_testing();

    assert!(pool.available_balance_value() == 0);

    supply_for_testing(&mut pool, 1_000_000, &clock, test.ctx());
    assert!(pool.available_balance_value() == 1_000_000);
    assert!(pool.utilization_bps() == 0);

    let facil_cap = supply_pool::create_lend_facil_cap(test.ctx());
    let facil_id = object::id(&facil_cap);
    destroy(
        pool.add_lend_facil(
            facil_id,
            piecewise::create(0, 10_00, vector::singleton(piecewise::section(100_00, 10_00))),
            test.ctx(),
        ),
    );
    destroy(
        pool.set_lend_facil_max_liability_outstanding(facil_id, 1_000_000_000_000, test.ctx()),
    );
    destroy(pool.set_lend_facil_max_utilization_bps(facil_id, 100_00, test.ctx()));

    let (borrowed, shares) = supply_pool::borrow(&mut pool, &facil_cap, 400_000, &clock);
    assert!(borrowed.value() == 400_000);

    // The borrowed amount leaves the available balance while staying in the pool's total
    // value, so `available_balance_value` tracks exactly what a withdrawal can be paid from.
    assert!(pool.available_balance_value() == 600_000);
    assert!(pool.utilization_bps() == 40_00);

    destroy(borrowed);
    destroy(shares);
    destroy(facil_cap);
    destroy(pool);
    clock::destroy_for_testing(clock);
    test.end();
}

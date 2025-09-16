#[test_only]
module kai_leverage::supply_pool_tests;

use kai_leverage::equity;
use kai_leverage::supply_pool::{Self, SupplyPool};
use sui::balance;
use sui::clock::Clock;
use sui::sui::SUI;
use sui::test_scenario;
use sui::test_utils::destroy;
use usdc::usdc::USDC;

public struct SSUI has drop {}
public struct SUSDC has drop {}

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

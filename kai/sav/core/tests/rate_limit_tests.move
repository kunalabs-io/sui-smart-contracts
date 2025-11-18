// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module kai_sav::rate_limit_tests;

use kai_sav::vault::{Self, AdminCap, Vault};
use rate_limiter::net_sliding_sum_limiter;
use rate_limiter::sliding_sum_limiter;
use sui::balance;
use sui::clock::{Self, Clock};
use sui::coin;
use sui::sui::SUI;
use sui::test_utils::destroy;
use sui::test_scenario::{Self as scenario};

public struct YSUI has drop {}

fun create_vault_with_rate_limiter(
    max_inflow_limit: Option<u256>,
    max_outflow_limit: Option<u256>,
    clock: &Clock,
    ctx: &mut TxContext,
): (Vault<SUI, YSUI>, AdminCap<YSUI>) {
    let mut test_scenario = scenario::begin(@0);
    
    let ya_treasury = coin::create_treasury_cap_for_testing<YSUI>(ctx);
    let admin_cap = vault::new<SUI, YSUI>(ya_treasury, ctx);
    
    // The vault was shared by new, so take it from scenario
    test_scenario.next_tx(@0);
    let mut vault = test_scenario.take_shared<Vault<SUI, YSUI>>();
    
    let rate_limiter = net_sliding_sum_limiter::new(
        5 * 60 * 1000, // 5 minutes per bucket
        12,            // 12 buckets (1 hour total)
        max_inflow_limit,
        max_outflow_limit,
        option::none(), // max_net_inflow_limit - not tested
        option::none(), // max_net_outflow_limit - not tested
        clock,
    );
    
    vault::set_rate_limiter(&admin_cap, &mut vault, rate_limiter);
    vault::set_max_inflow_and_outflow_limits(
        &admin_cap,
        &mut vault,
        max_inflow_limit,
        max_outflow_limit,
    );
    
    scenario::return_shared(vault);

    test_scenario.next_tx(@1);
    let vault = test_scenario.take_shared<Vault<SUI, YSUI>>();
    scenario::end(test_scenario);
    
    (vault, admin_cap)
}

#[test]
fun test_deposit_within_inflow_limit() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, 10000_000);
    
    let (mut vault, admin_cap) = create_vault_with_rate_limiter(
        option::some(10000), // max_inflow_limit
        option::none(),
        &clock,
        &mut ctx,
    );
    
    // Deposit within limit
    let deposit1 = balance::create_for_testing<SUI>(3000);
    let lp = vault::deposit(&mut vault, deposit1, &clock);
    assert!(balance::value(&lp) == 3000, 0);
    destroy(lp);
    
    // Deposit more within limit
    let deposit2 = balance::create_for_testing<SUI>(5000);
    let lp = vault::deposit(&mut vault, deposit2, &clock);
    assert!(balance::value(&lp) > 0, 0);
    destroy(lp);
    
    // Total deposits: 8000, still within limit of 10000
    let deposit3 = balance::create_for_testing<SUI>(1500);
    let lp = vault::deposit(&mut vault, deposit3, &clock);
    assert!(balance::value(&lp) > 0, 0);
    destroy(lp);
    
    destroy(vault);
    destroy(admin_cap);
    destroy(clock);
}

#[test, expected_failure(abort_code = sliding_sum_limiter::EMaxSumLimitExceeded)]
fun test_deposit_exceeds_max_inflow_limit() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, 10000_000);
    
    let (mut vault, admin_cap) = create_vault_with_rate_limiter(
        option::some(10000), // max_inflow_limit
        option::none(),
        &clock,
        &mut ctx,
    );
    
    // Deposit up to limit
    let deposit1 = balance::create_for_testing<SUI>(10000);
    let lp = vault::deposit(&mut vault, deposit1, &clock);
    destroy(lp);
    
    // This deposit should exceed the limit
    let deposit2 = balance::create_for_testing<SUI>(1);
    let lp = vault::deposit(&mut vault, deposit2, &clock);
    destroy(lp);
    
    destroy(vault);
    destroy(admin_cap);
    destroy(clock);
}

#[test]
fun test_deposit_sliding_window_reset() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, 10000_000);
    
    let (mut vault, admin_cap) = create_vault_with_rate_limiter(
        option::some(10000), // max_inflow_limit
        option::none(),
        &clock,
        &mut ctx,
    );
    
    // Deposit up to limit
    let deposit1 = balance::create_for_testing<SUI>(10000);
    let lp = vault::deposit(&mut vault, deposit1, &clock);
    destroy(lp);
    
    // Advance time beyond the sliding window (1 hour + 10 minutes)
    clock::increment_for_testing(&mut clock, 60 * 70 * 1000);
    
    // Now deposits should succeed again as the window has reset
    let deposit2 = balance::create_for_testing<SUI>(5000);
    let lp = vault::deposit(&mut vault, deposit2, &clock);
    assert!(balance::value(&lp) > 0, 0);
    destroy(lp);
    
    destroy(vault);
    destroy(admin_cap);
    destroy(clock);
}

#[test]
fun test_withdraw_within_outflow_limit() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, 10000_000);
    
    let (mut vault, admin_cap) = create_vault_with_rate_limiter(
        option::none(),
        option::some(10000), // max_outflow_limit
        &clock,
        &mut ctx,
    );
    
    // First deposit to have LP tokens
    let deposit = balance::create_for_testing<SUI>(20000);
    let mut lp = vault::deposit(&mut vault, deposit, &clock);
    let lp_amount = balance::value(&lp);
    
    // Withdraw within limit
    let lp_balance1 = balance::split(&mut lp, lp_amount / 4);
    let ticket1 = vault::withdraw(&mut vault, lp_balance1, &clock);
    let withdrawn1 = vault::redeem_withdraw_ticket(&mut vault, ticket1);
    assert!(balance::value(&withdrawn1) > 0, 0);
    destroy(withdrawn1);
    
    // Withdraw more within limit
    let lp_balance2 = balance::split(&mut lp, lp_amount / 4);
    let ticket2 = vault::withdraw(&mut vault, lp_balance2, &clock);
    let withdrawn2 = vault::redeem_withdraw_ticket(&mut vault, ticket2);
    assert!(balance::value(&withdrawn2) > 0, 0);
    destroy(withdrawn2);
    
    destroy(lp);
    destroy(vault);
    destroy(admin_cap);
    destroy(clock);
}

#[test, expected_failure(abort_code = sliding_sum_limiter::EMaxSumLimitExceeded)]
fun test_withdraw_exceeds_max_outflow_limit() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, 10000_000);
    
    let (mut vault, admin_cap) = create_vault_with_rate_limiter(
        option::none(),
        option::some(10000), // max_outflow_limit
        &clock,
        &mut ctx,
    );
    
    // First deposit to have LP tokens
    let deposit = balance::create_for_testing<SUI>(20000);
    let mut lp = vault::deposit(&mut vault, deposit, &clock);
    let lp_amount = balance::value(&lp);
    
    // Withdraw exactly at limit (half of deposit = 10000)
    let lp_balance1 = balance::split(&mut lp, lp_amount / 2);
    let ticket1 = vault::withdraw(&mut vault, lp_balance1, &clock);
    let withdrawn1 = vault::redeem_withdraw_ticket(&mut vault, ticket1);
    destroy(withdrawn1);
    
    // Now try to withdraw more, which should exceed the limit
    // Withdrawing the remaining LP tokens should calculate a withdrawal amount >= 10000
    // which exceeds the limit since we already withdrew 10000
    let remaining_lp_value = balance::value(&lp);
    let lp_balance2 = balance::split(&mut lp, remaining_lp_value);
    let ticket2 = vault::withdraw(&mut vault, lp_balance2, &clock);
    let withdrawn2 = vault::redeem_withdraw_ticket(&mut vault, ticket2);
    
    destroy(lp);
    destroy(vault);
    destroy(admin_cap);
    destroy(clock);
    destroy(withdrawn2);
}

#[test]
fun test_withdraw_sliding_window_reset() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, 10000_000);
    
    let (mut vault, admin_cap) = create_vault_with_rate_limiter(
        option::none(),
        option::some(10000), // max_outflow_limit
        &clock,
        &mut ctx,
    );
    
    // First deposit to have LP tokens
    let deposit = balance::create_for_testing<SUI>(20000);
    let mut lp = vault::deposit(&mut vault, deposit, &clock);
    let lp_amount = balance::value(&lp);
    
    // Withdraw up to limit
    let lp_balance1 = balance::split(&mut lp, lp_amount / 2);
    let ticket1 = vault::withdraw(&mut vault, lp_balance1, &clock);
    let withdrawn1 = vault::redeem_withdraw_ticket(&mut vault, ticket1);
    destroy(withdrawn1);
    
    // Advance time beyond the sliding window (1 hour + 10 minutes)
    clock::increment_for_testing(&mut clock, 60 * 70 * 1000);
    
    // Now withdrawals should succeed again as the window has reset
    let lp_balance2 = balance::split(&mut lp, lp_amount / 4);
    let ticket2 = vault::withdraw(&mut vault, lp_balance2, &clock);
    let withdrawn2 = vault::redeem_withdraw_ticket(&mut vault, ticket2);
    assert!(balance::value(&withdrawn2) > 0, 0);
    destroy(withdrawn2);
    
    destroy(lp);
    destroy(vault);
    destroy(admin_cap);
    destroy(clock);
}

#[test]
fun test_rate_limiter_without_limits() {
    let mut ctx = tx_context::dummy();
    let mut clock = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clock, 10000_000);
    
    let (mut vault, admin_cap) = create_vault_with_rate_limiter(
        option::none(), // no limits
        option::none(),
        &clock,
        &mut ctx,
    );
    
    // Deposits should work without limits
    let deposit1 = balance::create_for_testing<SUI>(50000);
    let mut lp = vault::deposit(&mut vault, deposit1, &clock);
    assert!(balance::value(&lp) == 50000, 0);
    
    // More deposits should work
    let deposit2 = balance::create_for_testing<SUI>(50000);
    let lp2 = vault::deposit(&mut vault, deposit2, &clock);
    assert!(balance::value(&lp2) > 0, 0);
    
    // Withdrawals should work without limits
    let lp_amount = balance::value(&lp);
    let mut lp_balance = balance::split(&mut lp, lp_amount);
    balance::join(&mut lp_balance, lp2);
    destroy(lp);
    
    let ticket = vault::withdraw(&mut vault, lp_balance, &clock);
    let withdrawn = vault::redeem_withdraw_ticket(&mut vault, ticket);
    assert!(balance::value(&withdrawn) > 0, 0);
    destroy(withdrawn);
    
    destroy(vault);
    destroy(admin_cap);
    destroy(clock);
}

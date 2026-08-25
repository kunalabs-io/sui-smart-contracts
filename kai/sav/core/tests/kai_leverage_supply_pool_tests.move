// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module kai_sav::kai_leverage_supply_pool_tests;

use access_management::access;
use kai_leverage::equity;
use kai_leverage::piecewise;
use kai_leverage::supply_pool::{Self, SupplyPool};
use kai_sav::kai_leverage_supply_pool::{
    Self,
    Strategy,
    AdminCap,
    EInsufficientPoolLiquidity
};
use kai_sav::vault::{Self, Vault, AdminCap as VaultAdminCap};
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin;
use sui::test_scenario::{Self, Scenario};
use sui::test_utils::destroy;

public struct A has drop {}
public struct SA has drop {}
public struct YA has drop {}

/// Builds a vault with a single supply-pool strategy holding `deposit_amt` of `A`, an access
/// policy letting the strategy supply into the pool, and `borrow_amt` lent back out of it.
fun setup(
    test: &mut Scenario,
    clock: &Clock,
    deposit_amt: u64,
    borrow_amt: u64,
): (
    Vault<A, YA>,
    VaultAdminCap<YA>,
    Strategy<A, SA>,
    AdminCap,
    SupplyPool<A, SA>,
    access::Policy,
    address,
    supply_pool::LendFacilCap,
    Balance<YA>,
) {
    let treasury = equity::create_treasury_for_testing<SA>(test.ctx());
    destroy(supply_pool::create_pool<A, SA>(treasury, test.ctx()));

    let ya_treasury = coin::create_treasury_cap_for_testing<YA>(test.ctx());
    let vault_cap = vault::new<A, YA>(ya_treasury, test.ctx());

    test.next_tx(@0);
    let mut supply_pool: SupplyPool<A, SA> = test.take_shared();
    kai_leverage_supply_pool::new<A, SA>(&supply_pool, test.ctx());

    test.next_tx(@0);
    let mut vault: Vault<A, YA> = test.take_shared();
    let mut strategy: Strategy<A, SA> = test.take_shared();
    let strategy_cap: AdminCap = test.take_from_sender();

    strategy.join_vault(&strategy_cap, &mut vault, &vault_cap, test.ctx());

    // Policy allowing the strategy to supply into the pool.
    let admin = access::create_admin_for_testing<supply_pool::ADeposit>(test.ctx());
    let mut policy = access::create_empty_policy(&admin, test.ctx());
    policy.allowlist_entity(&admin, &strategy.entity_id_for_testing());
    let rule_id = access::add_empty_rule(&mut policy, &admin, test.ctx());
    access::add_action_to_rule<supply_pool::ADeposit>(&mut policy, &admin, rule_id);

    // Deposit into the vault, then rebalance it all into the supply pool.
    let lp = vault.deposit(balance::create_for_testing<A>(deposit_amt), clock);
    let amounts = vault.calc_rebalance_amounts(clock);
    strategy.rebalance(
        &strategy_cap,
        &mut vault,
        &amounts,
        &mut supply_pool,
        &policy,
        rule_id,
        clock,
        test.ctx(),
    );
    assert!(strategy.underlying_nominal_value_t_for_testing() == deposit_amt);
    assert!(supply_pool.available_balance_value() == deposit_amt);

    // Lend `borrow_amt` back out to drive the pool's utilization up.
    let facil_cap = supply_pool::create_lend_facil_cap(test.ctx());
    let facil_id = object::id(&facil_cap);
    destroy(
        supply_pool.add_lend_facil(
            facil_id,
            piecewise::create(0, 10_00, vector::singleton(piecewise::section(100_00, 10_00))),
            test.ctx(),
        ),
    );
    destroy(
        supply_pool.set_lend_facil_max_liability_outstanding(
            facil_id,
            1_000_000_000_000_000,
            test.ctx(),
        ),
    );
    destroy(supply_pool.set_lend_facil_max_utilization_bps(facil_id, 100_00, test.ctx()));

    let (borrowed, debt_shares) = supply_pool::borrow_for_testing(
        &mut supply_pool,
        &facil_cap,
        borrow_amt,
        clock,
    );
    destroy(borrowed);
    destroy(debt_shares);

    destroy(admin);
    (vault, vault_cap, strategy, strategy_cap, supply_pool, policy, rule_id, facil_cap, lp)
}

/* ================= reserve arithmetic ================= */

#[test]
fun test_withdraw_leaves_reserve_boundary() {
    // A 1_000_000 pool at 90% utilization. The largest allowed withdrawal `x` satisfies
    // `100_000 - x >= (1_000_000 - x) / 100`, i.e. `x <= 90_910`.
    assert!(kai_leverage_supply_pool::withdraw_leaves_reserve(100_000, 900_000, 90_909));
    assert!(kai_leverage_supply_pool::withdraw_leaves_reserve(100_000, 900_000, 90_910));
    assert!(!kai_leverage_supply_pool::withdraw_leaves_reserve(100_000, 900_000, 90_911));
    assert!(!kai_leverage_supply_pool::withdraw_leaves_reserve(100_000, 900_000, 100_000));
}

#[test]
fun test_withdraw_leaves_reserve_more_than_available() {
    assert!(!kai_leverage_supply_pool::withdraw_leaves_reserve(100_000, 900_000, 100_001));
    assert!(!kai_leverage_supply_pool::withdraw_leaves_reserve(0, 900_000, 1));
}

#[test]
fun test_withdraw_leaves_reserve_no_liabilities() {
    // With nothing lent out the pool can be drained completely — utilization stays at zero.
    assert!(kai_leverage_supply_pool::withdraw_leaves_reserve(1_000_000, 0, 1_000_000));
    assert!(kai_leverage_supply_pool::withdraw_leaves_reserve(1_000_000, 0, 999_999));
    // An empty pool is trivially fine.
    assert!(kai_leverage_supply_pool::withdraw_leaves_reserve(0, 0, 0));
}

#[test]
fun test_withdraw_leaves_reserve_at_full_utilization() {
    // Sitting exactly on the reserve. Principal withdrawals are refused, bar a rounding unit
    // of slack in the floor division.
    assert!(!kai_leverage_supply_pool::withdraw_leaves_reserve(10_000, 990_000, 2));
    assert!(!kai_leverage_supply_pool::withdraw_leaves_reserve(10_000, 990_000, 1_000));

    // Below the reserve, where skimming is allowed to take the pool, nothing may be
    // withdrawn. Zero-amount calls remain no-ops.
    assert!(!kai_leverage_supply_pool::withdraw_leaves_reserve(5_000, 990_000, 1));
    assert!(kai_leverage_supply_pool::withdraw_leaves_reserve(5_000, 990_000, 0));
    assert!(kai_leverage_supply_pool::withdraw_leaves_reserve(10_000, 990_000, 0));
}

#[test]
fun test_max_withdraw_within_reserve() {
    // Same pool as above. The result may be a rounding unit more conservative than the
    // `withdraw_leaves_reserve` boundary, but must never exceed it.
    let max = kai_leverage_supply_pool::max_withdraw_within_reserve(100_000, 900_000);
    assert!(max == 90_909);
    assert!(kai_leverage_supply_pool::withdraw_leaves_reserve(100_000, 900_000, max));

    // Nothing lent out means the pool can be drained completely.
    assert!(kai_leverage_supply_pool::max_withdraw_within_reserve(1_000_000, 0) == 1_000_000);

    // Sitting exactly on the reserve, or below it after skimming, yields nothing.
    assert!(kai_leverage_supply_pool::max_withdraw_within_reserve(10_000, 990_000) == 0);
    assert!(kai_leverage_supply_pool::max_withdraw_within_reserve(5_000, 990_000) == 0);
    assert!(kai_leverage_supply_pool::max_withdraw_within_reserve(0, 0) == 0);
}

/* ================= profit skimming ================= */

/// The incident: a fully utilized pool made `collect_and_hand_over_profit` abort inside
/// `balance::split`, which failed the whole (batched) rebalance transaction.
#[test]
fun test_collect_and_hand_over_profit_does_not_abort_at_full_utilization() {
    let mut test = test_scenario::begin(@0);
    let mut clock = clock::create_for_testing(test.ctx());

    let (
        mut vault,
        vault_cap,
        mut strategy,
        strategy_cap,
        mut supply_pool,
        policy,
        _rule_id,
        facil_cap,
        lp,
    ) = setup(&mut test, &clock, 1_000_000, 1_000_000);

    // Everything is lent out.
    assert!(supply_pool.available_balance_value() == 0);
    assert!(supply_pool.utilization_bps() == 100_00);

    // Accrue a year of interest, so there is real profit to skim.
    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);
    let share_value = supply_pool.calc_withdraw_by_shares(
        strategy.shares_value_for_testing(),
        &clock,
    );
    assert!(share_value > strategy.underlying_nominal_value_t_for_testing());

    // Would previously abort with `balance::split` ENotEnough. Now it is a no-op.
    let shares_before = strategy.shares_value_for_testing();
    strategy.collect_and_hand_over_profit(&strategy_cap, &mut vault, &mut supply_pool, &clock);
    assert!(strategy.shares_value_for_testing() == shares_before);

    destroy(lp);
    destroy(vault);
    destroy(vault_cap);
    destroy(strategy);
    destroy(strategy_cap);
    destroy(supply_pool);
    destroy(policy);
    destroy(facil_cap);
    destroy(clock);
    test.end();
}

/// With partial liquidity back in the pool, the skim takes what it can and leaves the rest in
/// the strategy's shares for a later call.
#[test]
fun test_skim_is_clamped_to_available_balance() {
    let mut test = test_scenario::begin(@0);
    let mut clock = clock::create_for_testing(test.ctx());

    let (
        mut vault,
        vault_cap,
        mut strategy,
        strategy_cap,
        mut supply_pool,
        policy,
        _rule_id,
        facil_cap,
        lp,
    ) = setup(&mut test, &clock, 1_000_000, 1_000_000);

    clock.increment_for_testing(365 * 24 * 60 * 60 * 1000);

    // Someone supplies a small amount, far less than the accrued profit.
    let available = 1_000;
    let (shares, request) = supply_pool.supply(
        balance::create_for_testing<A>(available),
        &clock,
        test.ctx(),
    );
    destroy(request);
    destroy(shares);
    assert!(supply_pool.available_balance_value() == available);

    let share_value = supply_pool.calc_withdraw_by_shares(
        strategy.shares_value_for_testing(),
        &clock,
    );
    assert!(share_value - strategy.underlying_nominal_value_t_for_testing() > available);

    let shares_before = strategy.shares_value_for_testing();
    let nominal_before = strategy.underlying_nominal_value_t_for_testing();
    strategy.collect_and_hand_over_profit(&strategy_cap, &mut vault, &mut supply_pool, &clock);

    // The skim drained the available balance and no more, taking the value out of the
    // strategy's shares and leaving the cost basis untouched.
    assert!(supply_pool.available_balance_value() < available);
    assert!(strategy.shares_value_for_testing() < shares_before);
    assert!(strategy.underlying_nominal_value_t_for_testing() == nominal_before);

    // The rest of the profit is still owned by the strategy, ready for a later skim.
    let share_value_after = supply_pool.calc_withdraw_by_shares(
        strategy.shares_value_for_testing(),
        &clock,
    );
    assert!(share_value_after > strategy.underlying_nominal_value_t_for_testing());

    destroy(lp);
    destroy(vault);
    destroy(vault_cap);
    destroy(strategy);
    destroy(strategy_cap);
    destroy(supply_pool);
    destroy(policy);
    destroy(facil_cap);
    destroy(clock);
    test.end();
}

/* ================= principal withdrawals ================= */

/// A user redemption is refused once the pool has been drawn down to the reserve, rather than
/// being partially filled (which `vault::redeem_withdraw_ticket` would charge to the user).
#[test]
#[expected_failure(abort_code = EInsufficientPoolLiquidity)]
fun test_withdraw_aborts_at_reserve() {
    let mut test = test_scenario::begin(@0);
    let clock = clock::create_for_testing(test.ctx());

    // Borrow 99% of the pool, leaving exactly the 1% reserve available. Without the reserve
    // this redemption would succeed, since there is enough balance to pay it out.
    let (
        mut vault,
        vault_cap,
        mut strategy,
        strategy_cap,
        mut supply_pool,
        policy,
        _rule_id,
        facil_cap,
        mut lp,
    ) = setup(&mut test, &clock, 1_000_000, 990_000);

    assert!(supply_pool.available_balance_value() == 10_000);
    assert!(supply_pool.utilization_bps() == 99_00);

    let mut ticket = vault.withdraw(lp.split(5_000), &clock);
    strategy.withdraw(&mut ticket, &mut supply_pool, &clock);

    destroy(ticket);
    destroy(lp);
    destroy(vault);
    destroy(vault_cap);
    destroy(strategy);
    destroy(strategy_cap);
    destroy(supply_pool);
    destroy(policy);
    destroy(facil_cap);
    destroy(clock);
    test.end();
}

/// A rebalance returning principal to the vault is clamped rather than aborted, so one
/// over-utilized pool cannot fail a rebalance transaction that batches every vault.
#[test]
fun test_rebalance_repay_is_clamped_to_reserve() {
    let mut test = test_scenario::begin(@0);
    let clock = clock::create_for_testing(test.ctx());

    // 100_000 available against 900_000 lent out, so at most 90_909 can be withdrawn while
    // leaving the 1% reserve intact.
    let (
        mut vault,
        vault_cap,
        mut strategy,
        strategy_cap,
        mut supply_pool,
        policy,
        rule_id,
        facil_cap,
        lp,
    ) = setup(&mut test, &clock, 1_000_000, 900_000);

    // Register a second strategy and split the allocation with it, so the vault now wants
    // half of the first strategy's principal back.
    let dummy_access = vault::add_strategy(&vault_cap, &mut vault, test.ctx());
    let ids = vector[
        vault::vault_access_id(strategy.vault_access_for_testing()),
        vault::vault_access_id(&dummy_access),
    ];
    vault::set_target_alloc_weights_for_testing(
        &vault_cap,
        &mut vault,
        ids,
        vector[5_000, 5_000],
    );

    let (_, to_repay) = vault::rebalance_amounts_get(
        &vault.calc_rebalance_amounts(&clock),
        strategy.vault_access_for_testing(),
    );
    assert!(to_repay == 500_000);

    let nominal_before = strategy.underlying_nominal_value_t_for_testing();
    let amounts = vault.calc_rebalance_amounts(&clock);
    strategy.rebalance(
        &strategy_cap,
        &mut vault,
        &amounts,
        &mut supply_pool,
        &policy,
        rule_id,
        &clock,
        test.ctx(),
    );

    // Far less than `to_repay` was returned, the pool was left on (not below) the reserve,
    // and the strategy's cost basis dropped by exactly what it actually repaid.
    let repaid = nominal_before - strategy.underlying_nominal_value_t_for_testing();
    assert!(repaid > 0 && repaid < to_repay);
    assert!(repaid <= 90_909);
    assert!(supply_pool.available_balance_value() >= 9_090);
    assert!(vault.free_balance() == repaid);

    // The vault's `borrowed` fell by the same `repaid`, so a short repayment leaves the two
    // sides of the accounting in step. Repaying only moves value from `borrowed` into
    // `free_balance`, so the target allocation is unchanged and `to_repay` drops by `repaid`.
    let (_, to_repay_after) = vault::rebalance_amounts_get(
        &vault.calc_rebalance_amounts(&clock),
        strategy.vault_access_for_testing(),
    );
    assert!(to_repay_after == to_repay - repaid);

    destroy(dummy_access);
    destroy(lp);
    destroy(vault);
    destroy(vault_cap);
    destroy(strategy);
    destroy(strategy_cap);
    destroy(supply_pool);
    destroy(policy);
    destroy(facil_cap);
    destroy(clock);
    test.end();
}

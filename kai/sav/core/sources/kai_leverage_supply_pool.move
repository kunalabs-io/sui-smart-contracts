// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Kai Leverage supply pool strategy for SAV integration.
/// Implements basic compounding of rewards.
module kai_sav::kai_leverage_supply_pool;

use access_management::access::{Self, Entity, Policy};
use kai_sav::util::muldiv;
use kai_sav::vault::{
    Self,
    Vault,
    VaultAccess,
    AdminCap as VaultAdminCap,
    RebalanceAmounts,
    WithdrawTicket,
    StrategyRemovalTicket
};
use kai_leverage::supply_pool::SupplyPool;
use std::u128;
use std::u64;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::event;

/* ================= constants ================= */

const MODULE_VERSION: u64 = 1;

/// Fraction of the supply pool's total value, in basis points, that principal withdrawals must
/// leave in its available balance. Profit skimming is exempt and may draw it down: `vault`
/// counts strategy principal at cost basis, so a skim that cannot withdraw means the vault
/// stops recognizing yield altogether.
const WITHDRAW_RESERVE_BPS: u64 = 100;

/* ================= errors ================= */

/// Invalid `AdminCap` has been provided for the strategy
const EInvalidAdmin: u64 = 0;

/// The strategy cannot be removed from vault if it has pending rewards
const EHasPendingRewards: u64 = 1;

/// Calling functions from the wrong package version
const EWrongVersion: u64 = 2;

/// Migration is not an upgrade
const ENotUpgrade: u64 = 3;

/// The withdrawal would leave the supply pool below its liquidity reserve
const EInsufficientPoolLiquidity: u64 = 4;

/* ================= events ================= */

/// Incentive injection event.
public struct IncentiveInjectInfo has copy, drop {
    strategy_id: ID,
    amount: u64,
}

/* ================= AdminCap ================= */

/// Administrative capability for strategy management.
public struct AdminCap has key, store {
    id: UID,
}

/* ================= Strategy ================= */

/// Strategy managing supply pool integration with vault.
/// 
/// Deposits funds from a Kai Single Asset Vault into a Kai Leverage supply pool,
/// managing deposits, withdrawals, and profit collection while maintaining
/// proper accounting of shares and underlying values.
public struct Strategy<phantom T, phantom ST> has key {
    id: UID,
    /// ID of the admin capability that controls this strategy
    admin_cap_id: ID,
    /// Vault access token for vault interactions
    vault_access: Option<VaultAccess>,
    /// Access Management entity for authentication and authorization in Kai Leverage
    entity: Entity,
    /// Balance of supply pool share tokens representing stake in the supply pool
    shares: Balance<ST>,
    /// Nominal value of underlying assets deposited to the supply pool
    underlying_nominal_value_t: u64,
    /// Accumulated profits collected from the supply pool
    collected_profit_t: Balance<T>,
    /// Version number for upgrade compatibility
    version: u64,
}

#[lint_allow(self_transfer)]
public(package) entry fun new<T, ST>(_supply_pool: &SupplyPool<T, ST>, ctx: &mut TxContext) {
    let admin_cap = AdminCap { id: object::new(ctx) };
    let admin_cap_id = object::id(&admin_cap);

    let entity = access::create_entity(ctx);

    let strategy = Strategy<T, ST> {
        id: object::new(ctx),
        admin_cap_id,
        vault_access: option::none(),
        entity,
        shares: balance::zero(),
        underlying_nominal_value_t: 0,
        collected_profit_t: balance::zero(),
        version: MODULE_VERSION,
    };
    transfer::share_object(strategy);

    transfer::transfer(
        admin_cap,
        tx_context::sender(ctx),
    );
}

fun assert_version<T, ST>(strategy: &Strategy<T, ST>) {
    assert!(strategy.version == MODULE_VERSION, EWrongVersion);
}

/* ================= read ================= */

/// Get the admin capability ID from strategy.
public fun admin_cap_id<T, ST>(strategy: &Strategy<T, ST>): ID {
    strategy.admin_cap_id
}

/* ================= admin ================= */

fun assert_admin<T, ST>(cap: &AdminCap, strategy: &Strategy<T, ST>) {
    let admin_cap_id = object::id(cap);
    assert!(admin_cap_id == strategy.admin_cap_id, EInvalidAdmin);
}

/// Join the strategy to a vault.
public fun join_vault<T, ST, YT>(
    strategy: &mut Strategy<T, ST>,
    strategy_cap: &AdminCap,
    vault: &mut Vault<T, YT>,
    vault_cap: &VaultAdminCap<YT>,
    ctx: &mut TxContext,
) {
    assert_version(strategy);
    assert_admin(strategy_cap, strategy);

    let access = vault::add_strategy(vault_cap, vault, ctx);
    strategy.vault_access.fill(access); // aborts if `is_some`
}

/// Remove strategy from vault and return removal ticket.
public fun remove_from_vault<T, ST, YT>(
    strategy: &mut Strategy<T, ST>,
    cap: &AdminCap,
    supply_pool: &mut SupplyPool<T, ST>,
    clock: &Clock,
): StrategyRemovalTicket<T, YT> {
    assert_admin(cap, strategy);
    assert_version(strategy);

    assert!(balance::value(&strategy.collected_profit_t) == 0, EHasPendingRewards);

    // Full teardown, so the withdrawal reserve is not enforced. Doing so would make the
    // strategy unremovable whenever the pool has any utilization at all.
    let redeemed_balance = supply_pool.withdraw(strategy.shares.withdraw_all(), clock);
    strategy.underlying_nominal_value_t = 0;

    vault::new_strategy_removal_ticket(
        option::extract(&mut strategy.vault_access),
        redeemed_balance,
    )
}

/// Migrate strategy to current module version.
entry fun migrate<T, ST>(cap: &AdminCap, strategy: &mut Strategy<T, ST>) {
    assert_admin(cap, strategy);
    assert!(strategy.version < MODULE_VERSION, ENotUpgrade);
    strategy.version = MODULE_VERSION;
}

/* ================= strategy operations ================= */

/// Whether withdrawing `amount` leaves at least `WITHDRAW_RESERVE_BPS` of the pool's total
/// value available. `available` and `liabilities` describe the pool before the withdrawal.
public(package) fun withdraw_leaves_reserve(available: u64, liabilities: u128, amount: u64): bool {
    // Never breaches the reserve, even if skimming has already taken the pool below it.
    if (amount == 0) {
        return true
    };
    if (available < amount) {
        return false
    };

    // Equivalent to capping post-withdrawal utilization at `10000 - WITHDRAW_RESERVE_BPS`:
    // the withdrawal lowers available and total value alike, and leaves liabilities untouched.
    let available_after = (available - amount) as u128;
    let total_value_after = available_after + liabilities;
    let reserve = total_value_after * (WITHDRAW_RESERVE_BPS as u128) / 10000;

    available_after >= reserve
}

/// The largest amount withdrawable from a pool holding `available` with `liabilities` out on
/// loan that still leaves the reserve. Zero if the pool is already at or below it.
public(package) fun max_withdraw_within_reserve(available: u64, liabilities: u128): u64 {
    // Solves `available_after * (10000 - WITHDRAW_RESERVE_BPS) >= liabilities *
    // WITHDRAW_RESERVE_BPS`, rounding up so the result never breaches the reserve.
    let bps = WITHDRAW_RESERVE_BPS as u128;
    let min_available = u128::div_ceil(liabilities * bps, 10000 - bps);

    // The result is bounded by `available`, so the downcast is lossless.
    u128::saturating_sub(available as u128, min_available) as u64
}

/// Rebalance strategy position based on vault requirements.
public fun rebalance<T, ST, YT>(
    strategy: &mut Strategy<T, ST>,
    cap: &AdminCap,
    vault: &mut Vault<T, YT>,
    amounts: &RebalanceAmounts,
    supply_pool: &mut SupplyPool<T, ST>,
    policy: &Policy,
    rule_id: address,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert_admin(cap, strategy);
    assert_version(strategy);

    let vault_access = option::borrow(&strategy.vault_access);
    let (can_borrow, to_repay) = vault::rebalance_amounts_get(amounts, vault_access);
    if (to_repay > 0) {
        let redeem_st_amt = muldiv(
            strategy.shares.value(),
            to_repay,
            strategy.underlying_nominal_value_t,
        );
        // Clamped rather than aborted: `vault::strategy_repay` reduces `borrowed` by the
        // amount actually repaid, so a short repayment stays exactly accounted and the rest is
        // repaid on a later rebalance. Aborting would fail the whole rebalance transaction,
        // which batches every vault. `calc_withdraw_by_shares` also accrues interest, so the
        // pool state read below is current.
        let withdraw_amt = supply_pool.calc_withdraw_by_shares(redeem_st_amt, clock);
        let max_withdraw_amt = max_withdraw_within_reserve(
            supply_pool.available_balance_value(),
            supply_pool.total_liabilities_x64() >> 64,
        );
        let redeem_st_amt = if (withdraw_amt > max_withdraw_amt) {
            let (share_amt, _) = supply_pool.calc_withdraw_by_amount(max_withdraw_amt, clock);
            // redeem 1 share less to avoid withdrawing more than `max_withdraw_amt` due to
            // rounding in `calc_withdraw_by_amount`
            u64::max(share_amt, 1) - 1
        } else {
            redeem_st_amt
        };
        if (redeem_st_amt == 0) {
            return
        };

        let mut redeemed_balance_t = supply_pool.withdraw(
            strategy.shares.split(redeem_st_amt),
            clock,
        );

        if (redeemed_balance_t.value() > to_repay) {
            let extra_amt = redeemed_balance_t.value() - to_repay;
            strategy.collected_profit_t.join(redeemed_balance_t.split(extra_amt));
        };

        let repaid = redeemed_balance_t.value();
        vault.strategy_repay(vault_access, redeemed_balance_t);

        strategy.underlying_nominal_value_t = strategy.underlying_nominal_value_t - repaid;
    } else if (can_borrow > 0) {
        let borrow_amt = u64::min(can_borrow, vault.free_balance());
        let borrowed = vault.strategy_borrow(vault_access, borrow_amt);

        let (new_shares, action_request) = supply_pool.supply(borrowed, clock, ctx);
        access::approve_request(action_request, &strategy.entity, policy, rule_id);

        strategy.shares.join(new_shares);
        strategy.underlying_nominal_value_t = strategy.underlying_nominal_value_t + borrow_amt;
    }
}

/// Skim the profits earned on base APY.
fun skim_base_profits<T, ST>(
    strategy: &mut Strategy<T, ST>,
    supply_pool: &mut SupplyPool<T, ST>,
    clock: &Clock,
) {
    let share_value = supply_pool.calc_withdraw_by_shares(strategy.shares.value(), clock);
    if (share_value > strategy.underlying_nominal_value_t) {
        // Skim at most what the pool can pay out, otherwise the split below underflows and
        // aborts. The rest stays in `strategy.shares`, keeps accruing, and is skimmed once
        // liquidity returns; `underlying_nominal_value_t` is untouched, so deferring loses no
        // profit. Deliberately ignores `WITHDRAW_RESERVE_BPS` — the skim is the path the
        // reserve exists to keep alive.
        let profit_amt = u64::min(
            share_value - strategy.underlying_nominal_value_t,
            supply_pool.available_balance_value(),
        );
        if (profit_amt == 0) {
            return
        };

        let (redeem_share_amount, _) = supply_pool.calc_withdraw_by_amount(profit_amt, clock);
        // redeem 1 share less to avoid withdrawing more than `profit_amt` due to rounding
        // in `calc_withdraw_by_amount`
        let redeem_share_amount = u64::max(redeem_share_amount, 1) - 1;

        let redeemed_balance = supply_pool.withdraw(
            strategy.shares.split(redeem_share_amount),
            clock,
        );
        strategy.collected_profit_t.join(redeemed_balance);
    }
}

/// Inject incentives into the strategy.
public fun inject_incentives<T, ST>(strategy: &mut Strategy<T, ST>, balance: Balance<T>) {
    event::emit(IncentiveInjectInfo {
        strategy_id: strategy.id.to_inner(),
        amount: balance.value(),
    });
    strategy.collected_profit_t.join(balance);
}

/// Collect profits and transfer to vault.
public fun collect_and_hand_over_profit<T, ST, YT>(
    strategy: &mut Strategy<T, ST>,
    cap: &AdminCap,
    vault: &mut Vault<T, YT>,
    supply_pool: &mut SupplyPool<T, ST>,
    clock: &Clock,
) {
    assert_admin(cap, strategy);
    assert_version(strategy);

    skim_base_profits(strategy, supply_pool, clock);
    let profit = strategy.collected_profit_t.withdraw_all();

    let vault_access = strategy.vault_access.borrow();
    vault::strategy_hand_over_profit(vault, vault_access, profit, clock);
}

/* ================= user operations ================= */

/// Process withdrawal request from vault.
public fun withdraw<T, ST, YT>(
    strategy: &mut Strategy<T, ST>,
    ticket: &mut WithdrawTicket<T, YT>,
    supply_pool: &mut SupplyPool<T, ST>,
    clock: &Clock,
) {
    assert_version(strategy);

    let vault_access = strategy.vault_access.borrow();
    let to_withdraw = vault::withdraw_ticket_to_withdraw(ticket, vault_access);
    if (to_withdraw == 0) {
        return
    };

    let redeem_st_amt = muldiv(
        strategy.shares.value(),
        to_withdraw,
        strategy.underlying_nominal_value_t,
    );
    // Aborts rather than filling partially on purpose: `vault::redeem_withdraw_ticket` treats
    // a short fill as a `StrategyLossEvent` charged to the redeeming user, which would turn a
    // liquidity limit into a realized loss. `calc_withdraw_by_shares` also accrues interest,
    // so the state the check reads is current.
    let withdraw_amt = supply_pool.calc_withdraw_by_shares(redeem_st_amt, clock);
    let leaves_reserve = withdraw_leaves_reserve(
        supply_pool.available_balance_value(),
        supply_pool.total_liabilities_x64() >> 64,
        withdraw_amt,
    );
    assert!(leaves_reserve, EInsufficientPoolLiquidity);

    let mut redeemed_balance_t = supply_pool.withdraw(
        strategy.shares.split(redeem_st_amt),
        clock,
    );

    if (redeemed_balance_t.value() > to_withdraw) {
        let profit_amt = redeemed_balance_t.value() - to_withdraw;
        strategy.collected_profit_t.join(redeemed_balance_t.split(profit_amt));
    };

    vault::strategy_withdraw_to_ticket(ticket, vault_access, redeemed_balance_t);

    // `to_withdraw` amount is used intentionally here instead of the actual amount which
    // can be lower in some cases (see comments in `vault::redeem_withdraw_ticket`)
    strategy.underlying_nominal_value_t = strategy.underlying_nominal_value_t - to_withdraw;
}

/* ================= testing ================= */

#[test_only]
public(package) fun shares_value_for_testing<T, ST>(strategy: &Strategy<T, ST>): u64 {
    strategy.shares.value()
}

#[test_only]
public(package) fun underlying_nominal_value_t_for_testing<T, ST>(
    strategy: &Strategy<T, ST>,
): u64 {
    strategy.underlying_nominal_value_t
}

#[test_only]
public(package) fun entity_id_for_testing<T, ST>(strategy: &Strategy<T, ST>): ID {
    object::id(&strategy.entity)
}

#[test_only]
public(package) fun vault_access_for_testing<T, ST>(strategy: &Strategy<T, ST>): &VaultAccess {
    strategy.vault_access.borrow()
}

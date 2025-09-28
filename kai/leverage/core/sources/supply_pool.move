// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Core supply pool module for Kai Leverage lending facilities.
///
/// The supply pool is the heart of the lending and borrowing system. It manages
/// the available liquidity, tracks total liabilities, and coordinates the interaction
/// between liquidity suppliers and leveraged positions. The supply pool enforces
/// risk and utilization limits, accrues interest, and collects protocol fees.
///
/// Key responsibilities:
/// - Maintains the available balance and total liabilities for each lending facility.
/// - Issues and redeems equity shares representing claims on pool assets.
/// - Issues and tracks debt shares for borrowers, ensuring precise debt accounting.
/// - Enforces risk parameters such as maximum utilization and outstanding debt.
/// - Accrues interest and protocol fees over time.
module kai_leverage::supply_pool;

use access_management::access::{Self, ActionRequest};
use kai_leverage::debt::{Self, DebtRegistry, DebtShareBalance};
use kai_leverage::debt_bag::{Self, DebtBag};
use kai_leverage::equity::{Self, EquityTreasury, EquityShareBalance};
use kai_leverage::piecewise::Piecewise;
use kai_leverage::util;
use std::type_name::TypeName;
use std::u128;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::event;
use sui::vec_map::{Self, VecMap};

public use fun fds_facil_id as FacilDebtShare.facil_id;
public use fun fds_borrow_inner as FacilDebtShare.borrow_inner;
public use fun fds_value_x64 as FacilDebtShare.value_x64;
public use fun fds_split_x64 as FacilDebtShare.split_x64;
public use fun fds_split as FacilDebtShare.split;
public use fun fds_withdraw_all as FacilDebtShare.withdraw_all;
public use fun fds_join as FacilDebtShare.join;
public use fun fds_destroy_zero as FacilDebtShare.destroy_zero;

public use fun fdb_add as FacilDebtBag.add;
public use fun fdb_take_amt as FacilDebtBag.take_amt;
public use fun fdb_take_all as FacilDebtBag.take_all;
public use fun fdb_get_share_amount_by_asset_type as FacilDebtBag.get_share_amount_by_asset_type;
public use fun fdb_get_share_amount_by_share_type as FacilDebtBag.get_share_amount_by_share_type;
public use fun fdb_get_share_type_for_asset as FacilDebtBag.get_share_type_for_asset;
public use fun fdb_share_type_matches_asset_if_any_exists as
    FacilDebtBag.share_type_matches_asset_if_any_exists;
public use fun fdb_is_empty as FacilDebtBag.is_empty;
public use fun fdb_destroy_empty as FacilDebtBag.destroy_empty;
public use fun fdb_length as FacilDebtBag.length;

/* ================= constants ================= */

// Seconds in a year
const SECONDS_IN_YEAR: u128 = 365 * 24 * 60 * 60;

const MODULE_VERSION: u16 = 1;

/* ================= errors ================= */

/// The share treasury for the supply shares must be empty, without any outstanding shares.
const EShareTreasuryNotEmpty: u64 = 0;
/// The provided repay balance does not match the amount that needs to be repaid.
const EInvalidRepayAmount: u64 = 1;
/// The provided shares do not belong to the correct lending facility.
const EShareFacilMismatch: u64 = 2;
/// The maximum utilization has been reached or exceeded for the lending facility.
const EMaxUtilizationReached: u64 = 3;
/// The maximum amount of debt has been reached or exceeded for the lending facility.
const EMaxLiabilityOutstandingReached: u64 = 4;
/// The `SupplyPool` version does not match the module version.
const EInvalidSupplyPoolVersion: u64 = 5;
/// The migration is not allowed because the object version is higher or equal to the module
/// version.
const ENotUpgrade: u64 = 6;

/* ================= access ================= */

/// Access control witness for pool creation.
public struct ACreatePool has drop {}
/// Access control witness for lending facility configuration.
public struct AConfigLendFacil has drop {}
/// Access control witness for fee configuration.
public struct AConfigFees has drop {}
/// Access control witness for taking collected fees.
public struct ATakeFees has drop {}
/// Access control witness for deposits.
public struct ADeposit has drop {}
/// Access control witness for migrations.
public struct AMigrate has drop {}

/* ================= structs ================= */

/// Event emitted for a supply operation.
public struct SupplyInfo has copy, drop {
    supply_pool_id: ID,
    deposited: u64,
    share_balance: u64,
}

/// Event emitted for a withdraw operation.
public struct WithdrawInfo has copy, drop {
    supply_pool_id: ID,
    share_balance: u64,
    withdrawn: u64,
}

/// Capability for managing a lending facility. Enables the owner to borrow from the pool.
public struct LendFacilCap has key, store {
    id: UID,
}

/// Configuration and state for a lending facility.
public struct LendFacilInfo<phantom ST> has store {
    interest_model: Piecewise,
    // Shares of the debt (borrowed amount). Its total liability value is the total amount lent out,
    // and when added to the available balance it is equal to the underlying value of the
    // supply shares.
    debt_registry: DebtRegistry<ST>,
    /// The maximum amount of debt after which the borrowing will be capped.
    max_liability_outstanding: u64,
    /// The maximum utilization after which the borrowing will be capped.
    max_utilization_bps: u64,
}

/// Debt shares for a specific lending facility.
public struct FacilDebtShare<phantom ST> has store {
    facil_id: ID,
    inner: DebtShareBalance<ST>,
}

/// Collection of debt shares for a lending facility.
public struct FacilDebtBag has key, store {
    id: UID,
    facil_id: ID,
    inner: DebtBag,
}

/// The central structure for managing lending and borrowing operations within the supply pool.
/// Tracks available balances, liabilities, interest, and equity shares for robust pool management.
public struct SupplyPool<phantom T, phantom ST> has key {
    id: UID,
    // The unutilized balance of the pool.
    available_balance: Balance<T>,
    // The interest fee in basis points.
    interest_fee_bps: u16,
    // Debt information for each lending facility.
    debt_info: VecMap<ID, LendFacilInfo<ST>>,
    // Total amount lent out.
    total_liabilities_x64: u128,
    // Last time the interest was accrued.
    last_update_ts_sec: u64,
    // Shares of the supply.
    supply_equity: EquityTreasury<ST>,
    // Shares of the collected fees.
    collected_fees: EquityShareBalance<ST>,
    // Versioning to facilitate upgrades.
    version: u16,
}

/* ================= upgrade ================= */

public(package) fun check_version<T, ST>(pool: &SupplyPool<T, ST>) {
    assert!(pool.version == MODULE_VERSION, EInvalidSupplyPoolVersion);
}

/// Migrate supply pool to current module version.
public fun migrate_supply_pool_version<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    ctx: &mut TxContext,
): ActionRequest {
    assert!(pool.version < MODULE_VERSION, ENotUpgrade);
    pool.version = MODULE_VERSION;
    access::new_request(AMigrate {}, ctx)
}

/* ================= Pool ================= */

/// Create a new supply pool with empty equity treasury.
public fun create_pool<T, ST: drop>(
    equity_treasury: EquityTreasury<ST>,
    ctx: &mut TxContext,
): ActionRequest {
    let registry = equity_treasury.borrow_registry();
    assert!(
        registry.supply_x64() == 0
        && registry.underlying_value_x64() == 0
        && equity_treasury.borrow_treasury_cap().total_supply() == 0,
        EShareTreasuryNotEmpty,
    );

    let pool = SupplyPool<T, ST> {
        id: object::new(ctx),
        available_balance: balance::zero(),
        interest_fee_bps: 0,
        debt_info: vec_map::empty(),
        total_liabilities_x64: 0,
        last_update_ts_sec: 0,
        supply_equity: equity_treasury,
        collected_fees: equity::zero(),
        version: MODULE_VERSION,
    };
    transfer::share_object(pool);

    access::new_request(ACreatePool {}, ctx)
}

/// Get total liabilities in Q64.64 format.
public fun total_liabilities_x64<T, ST>(pool: &SupplyPool<T, ST>): u128 {
    pool.total_liabilities_x64
}

/// Create a lending facility capability.
public fun create_lend_facil_cap(ctx: &mut TxContext): LendFacilCap {
    LendFacilCap { id: object::new(ctx) }
}

/// Add a new lending facility to the supply pool.
public fun add_lend_facil<T, ST: drop>(
    pool: &mut SupplyPool<T, ST>,
    facil_id: ID,
    interest_model: Piecewise,
    ctx: &mut TxContext,
): ActionRequest {
    check_version(pool);

    let debt_registry = debt::create_registry_with_cap(pool.supply_equity.borrow_treasury_cap());
    pool
        .debt_info
        .insert(
            facil_id,
            LendFacilInfo {
                interest_model,
                debt_registry,
                max_liability_outstanding: 0,
                max_utilization_bps: 10_000,
            },
        );

    access::new_request(AConfigLendFacil {}, ctx)
}

/// Remove a lending facility from the supply pool.
public fun remove_lend_facil<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    facil_id: ID,
    ctx: &mut TxContext,
): ActionRequest {
    check_version(pool);

    let (_, info) = pool.debt_info.remove(&facil_id);
    let LendFacilInfo { interest_model: _, debt_registry, .. } = info;
    debt_registry.destroy_empty();

    access::new_request(AConfigLendFacil {}, ctx)
}

/// Set the interest model for a lending facility.
public fun set_lend_facil_interest_model<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    facil_id: ID,
    interest_model: Piecewise,
    ctx: &mut TxContext,
): ActionRequest {
    check_version(pool);

    let info = &mut pool.debt_info[&facil_id];
    info.interest_model = interest_model;

    access::new_request(AConfigLendFacil {}, ctx)
}

/// Set the maximum liability outstanding for a lending facility.
public fun set_lend_facil_max_liability_outstanding<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    facil_id: ID,
    max_liability_outstanding: u64,
    ctx: &mut TxContext,
): ActionRequest {
    check_version(pool);

    let info = &mut pool.debt_info[&facil_id];
    info.max_liability_outstanding = max_liability_outstanding;

    access::new_request(AConfigLendFacil {}, ctx)
}

/// Set the maximum utilization in basis points for a lending facility.
public fun set_lend_facil_max_utilization_bps<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    facil_id: ID,
    max_utilization_bps: u64,
    ctx: &mut TxContext,
): ActionRequest {
    check_version(pool);

    let info = &mut pool.debt_info[&facil_id];
    info.max_utilization_bps = max_utilization_bps;

    access::new_request(AConfigLendFacil {}, ctx)
}

/// Set the interest fee in basis points for the supply pool.
public fun set_interest_fee_bps<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    fee_bps: u16,
    ctx: &mut TxContext,
): ActionRequest {
    check_version(pool);

    pool.interest_fee_bps = fee_bps;
    access::new_request(AConfigFees {}, ctx)
}

/// Take all collected fees from the supply pool.
public fun take_collected_fees<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    ctx: &mut TxContext,
): (EquityShareBalance<ST>, ActionRequest) {
    check_version(pool);
    (pool.collected_fees.withdraw_all(), access::new_request(ATakeFees {}, ctx))
}

/// Total balance of the pool. This is the sum of the available balance and the borrowed amount
/// which is out on loan, or the total supply equity underlying value. In `UQ64.64` format.
public fun total_value_x64<T, ST>(pool: &SupplyPool<T, ST>): u128 {
    pool.supply_equity.borrow_registry().underlying_value_x64()
}

/// Get current utilization in basis points.
public fun utilization_bps<T, ST>(pool: &SupplyPool<T, ST>): u64 {
    let total_value_x64 = total_value_x64(pool);
    if (total_value_x64 == 0) {
        return 0
    };

    util::muldiv_u128(
        pool.total_liabilities_x64,
        10000,
        total_value_x64,
    ) as u64
}

/// Update the interest accrued since the last update and distribute the interest fee.
public fun update_interest<T, ST>(pool: &mut SupplyPool<T, ST>, clock: &Clock) {
    check_version(pool);

    let dt = util::timestamp_sec(clock) - pool.last_update_ts_sec;
    if (dt == 0) {
        return
    };
    let utilization_bps = utilization_bps(pool);

    let mut total_liabilities_x64 = 0;
    let mut i = 0;
    let n = pool.debt_info.length();
    while (i < n) {
        let (_, info) = pool.debt_info.get_entry_by_idx_mut(i);

        let apr_bps = info.interest_model.value_at(utilization_bps);
        let accrued_interest_x64 = util::muldiv_u128(
            info.debt_registry.liability_value_x64(),
            (apr_bps as u128) * (dt as u128),
            100_00 * SECONDS_IN_YEAR,
        );
        let fee_x64 = util::muldiv_u128(accrued_interest_x64, pool.interest_fee_bps as u128, 10000);

        // increase supply shares underlying value by the accrued interest, and collect the fee
        let share_registry = pool.supply_equity.borrow_mut_registry();
        share_registry.increase_value_x64(accrued_interest_x64 - fee_x64);
        equity::join(
            &mut pool.collected_fees,
            equity::increase_value_and_issue_x64(share_registry, fee_x64),
        );

        // increase debt shares liability by the accrued interest
        info.debt_registry.increase_liability_x64(accrued_interest_x64);

        total_liabilities_x64 = total_liabilities_x64 + info.debt_registry.liability_value_x64();

        i = i + 1;
    };

    pool.total_liabilities_x64 = total_liabilities_x64;
    pool.last_update_ts_sec = util::timestamp_sec(clock);
}

public(package) fun borrow_debt_registry<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    id: &ID,
    clock: &Clock,
): &DebtRegistry<ST> {
    check_version(pool);

    update_interest(pool, clock);
    let info = &pool.debt_info[id];
    &info.debt_registry
}

/// Supply liquidity to the pool and receive shares.
public fun supply<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    balance: Balance<T>,
    clock: &Clock,
    ctx: &mut TxContext,
): (Balance<ST>, ActionRequest) {
    check_version(pool);
    update_interest(pool, clock);

    let deposited = balance.value();

    let registry = pool.supply_equity.borrow_mut_registry();
    let shares = registry.increase_value_and_issue(balance.value());
    pool.available_balance.join(balance);

    let share_balance = shares.into_balance_lossy(&mut pool.supply_equity);

    event::emit(SupplyInfo {
        supply_pool_id: pool.id.to_inner(),
        deposited,
        share_balance: share_balance.value(),
    });

    (share_balance, access::new_request(ADeposit {}, ctx))
}

/// Calculates the amount that will be withdrawn for the given amount of supply shares.
public fun calc_withdraw_by_shares<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    share_amount: u64,
    clock: &Clock,
): u64 {
    check_version(pool);
    update_interest(pool, clock);
    equity::calc_redeem_lossy(
        pool.supply_equity.borrow_registry(),
        ((share_amount as u128) << 64),
    )
}

/// Calculates the amount of shares needed to withdraw the given amount. 
/// Since the redeemed amount can sometimes be higher than the requested amount due to rounding, 
/// this function also returns the actual amount that will be withdrawn.
/// Returns `(share_amount, redeem_amount)`.
public fun calc_withdraw_by_amount<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    amount: u64,
    clock: &Clock,
): (u64, u64) {
    check_version(pool);
    update_interest(pool, clock);
    equity::calc_balance_redeem_for_amount(
        pool.supply_equity.borrow_registry(),
        amount,
    )
}

/// Withdraw tokens from the pool using shares.
public fun withdraw<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    balance: Balance<ST>,
    clock: &Clock,
): Balance<T> {
    check_version(pool);
    update_interest(pool, clock);

    let share_balance = balance.value();

    let shares = equity::from_balance(&mut pool.supply_equity, balance);
    let value = pool.supply_equity.borrow_mut_registry().redeem_lossy(shares);

    event::emit(WithdrawInfo {
        supply_pool_id: pool.id.to_inner(),
        share_balance,
        withdrawn: value,
    });

    pool.available_balance.split(value)
}

public(package) fun borrow<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    facil_cap: &LendFacilCap,
    amount: u64,
    clock: &Clock,
): (Balance<T>, FacilDebtShare<ST>) {
    check_version(pool);
    update_interest(pool, clock);
    let facil_id = object::id(facil_cap);

    let info = &mut pool.debt_info[&facil_id];
    let max_utilization_bps = info.max_utilization_bps;
    let max_liability_outstanding = info.max_liability_outstanding;

    let shares = info.debt_registry.increase_liability_and_issue(amount);
    let balance = pool.available_balance.split(amount);

    pool.total_liabilities_x64 = pool.total_liabilities_x64 + ((amount as u128) << 64);

    let liability_after_borrow = ((info.debt_registry.liability_value_x64() >> 64) as u64);
    let utilization_after_borrow = utilization_bps(pool);
    assert!(liability_after_borrow < max_liability_outstanding, EMaxLiabilityOutstandingReached);
    assert!(utilization_after_borrow <= max_utilization_bps, EMaxUtilizationReached);

    let facil_shares = FacilDebtShare { facil_id, inner: shares };
    (balance, facil_shares)
}

/// Calculates the debt amount that needs to be repaid for the given amount of debt shares.
public fun calc_repay_by_shares<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    fac_id: ID,
    share_value_x64: u128,
    clock: &Clock,
): u64 {
    check_version(pool);
    update_interest(pool, clock);
    let info = &pool.debt_info[&fac_id];
    debt::calc_repay_lossy(&info.debt_registry, share_value_x64)
}

/// Calculates the debt share amount required to repay the given amount of debt.
public fun calc_repay_by_amount<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    fac_id: ID,
    amount: u64,
    clock: &Clock,
): u128 {
    check_version(pool);
    update_interest(pool, clock);
    let info = &pool.debt_info[&fac_id];
    debt::calc_repay_for_amount(&info.debt_registry, amount)
}

public(package) fun repay<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    shares: FacilDebtShare<ST>,
    balance: Balance<T>,
    clock: &Clock,
) {
    check_version(pool);
    update_interest(pool, clock);
    let FacilDebtShare { facil_id, inner: shares } = shares;

    let info = &mut pool.debt_info[&facil_id];
    let amount = info.debt_registry.repay_lossy(shares);
    assert!(balance.value() == amount, EInvalidRepayAmount);

    let amount_x64 = u128::min(pool.total_liabilities_x64, (amount as u128) << 64);
    pool.total_liabilities_x64 = pool.total_liabilities_x64 - amount_x64;

    pool.available_balance.join(balance);
}

/// Repays the maximum possible amount of debt shares given the balance.
/// Returns the amount of debt shares and balance repaid.
public(package) fun repay_max_possible<T, ST>(
    pool: &mut SupplyPool<T, ST>,
    shares: &mut FacilDebtShare<ST>,
    balance: &mut Balance<T>,
    clock: &Clock,
): (u128, u64) {
    check_version(pool);

    let facil_id = shares.facil_id;
    let balance_by_shares = calc_repay_by_shares(pool, facil_id, shares.value_x64(), clock);
    let shares_by_balance = calc_repay_by_amount(pool, facil_id, balance.value(), clock);

    let (share_amt, balance_amt) = if (balance.value() >= balance_by_shares) {
        (shares.value_x64(), balance_by_shares)
    } else {
        // `shares_by_balance <= shares` here, this can be proven with an SMT solver
        (shares_by_balance, balance.value())
    };
    repay(
        pool,
        shares.split_x64(share_amt),
        balance.split(balance_amt),
        clock,
    );

    (share_amt, balance_amt)
}

/* ================= FacilDebtShare ================= */

public(package) fun fds_facil_id<ST>(self: &FacilDebtShare<ST>): ID {
    self.facil_id
}

public(package) fun fds_borrow_inner<ST>(self: &FacilDebtShare<ST>): &DebtShareBalance<ST> {
    &self.inner
}

public(package) fun fds_value_x64<ST>(self: &FacilDebtShare<ST>): u128 {
    self.inner.value_x64()
}

public(package) fun fds_split_x64<ST>(
    self: &mut FacilDebtShare<ST>,
    amount: u128,
): FacilDebtShare<ST> {
    let inner = self.inner.split_x64(amount);
    FacilDebtShare { facil_id: self.facil_id, inner }
}

public(package) fun fds_split<ST>(self: &mut FacilDebtShare<ST>, amount: u64): FacilDebtShare<ST> {
    let inner = self.inner.split(amount);
    FacilDebtShare { facil_id: self.facil_id, inner }
}

public(package) fun fds_withdraw_all<ST>(self: &mut FacilDebtShare<ST>): FacilDebtShare<ST> {
    let inner = self.inner.withdraw_all();
    FacilDebtShare { facil_id: self.facil_id, inner }
}

public(package) fun fds_join<ST>(self: &mut FacilDebtShare<ST>, other: FacilDebtShare<ST>) {
    assert!(self.facil_id == other.facil_id, EShareFacilMismatch);

    let FacilDebtShare { facil_id: _, inner: other } = other;
    self.inner.join(other);
}

public(package) fun fds_destroy_zero<ST>(shares: FacilDebtShare<ST>) {
    let FacilDebtShare { facil_id: _, inner: shares } = shares;
    shares.destroy_zero();
}

/* ================= FacilDebtBag ================= */

public(package) fun empty_facil_debt_bag(facil_id: ID, ctx: &mut TxContext): FacilDebtBag {
    FacilDebtBag {
        id: object::new(ctx),
        facil_id,
        inner: debt_bag::empty(ctx),
    }
}

public(package) fun fdb_add<T, ST>(self: &mut FacilDebtBag, shares: FacilDebtShare<ST>) {
    assert!(self.facil_id == shares.facil_id, EShareFacilMismatch);

    let FacilDebtShare { facil_id: _, inner: shares } = shares;
    self.inner.add<T, ST>(shares);
}

public(package) fun fdb_take_amt<ST>(self: &mut FacilDebtBag, amount: u128): FacilDebtShare<ST> {
    let shares = self.inner.take_amt(amount);
    FacilDebtShare { facil_id: self.facil_id, inner: shares }
}

public(package) fun fdb_take_all<ST>(self: &mut FacilDebtBag): FacilDebtShare<ST> {
    let shares = self.inner.take_all();
    FacilDebtShare { facil_id: self.facil_id, inner: shares }
}

public(package) fun fdb_get_share_amount_by_asset_type<T>(self: &FacilDebtBag): u128 {
    self.inner.get_share_amount_by_asset_type<T>()
}

public(package) fun fdb_get_share_amount_by_share_type<ST>(self: &FacilDebtBag): u128 {
    self.inner.get_share_amount_by_share_type<ST>()
}

public(package) fun fdb_share_type_matches_asset_if_any_exists<T, ST>(self: &FacilDebtBag): bool {
    self.inner.share_type_matches_asset_if_any_exists<T, ST>()
}

public(package) fun fdb_get_share_type_for_asset<T>(self: &FacilDebtBag): TypeName {
    self.inner.get_share_type_for_asset<T>()
}

public(package) fun fdb_is_empty(self: &FacilDebtBag): bool {
    self.inner.is_empty()
}

public(package) fun fdb_destroy_empty(self: FacilDebtBag) {
    let FacilDebtBag { id, facil_id: _, inner } = self;
    id.delete();
    inner.destroy_empty();
}

public(package) fun fdb_length(self: &FacilDebtBag): u64 {
    self.inner.length()
}

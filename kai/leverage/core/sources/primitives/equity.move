// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Equity share management system for supply pools, with fungible equity coin minting.
///
/// This module provides the core infrastructure for tracking equity stakes in pools or other systems.
/// It implements a share-based system where equity is represented as shares that maintain their
/// proportional value even as the total pool value changes due to deposits, withdrawals, or yield accrual.
/// 
/// In addition to share-based accounting, this module supports minting equity as fungible coins,
/// enabling seamless integration with token-based protocols and facilitating transferability of ownership positions.
/// 
/// Importantly, this system is designed to prevent value leakage due to integer arithmetic rounding:
/// whenever fractional values arise from division or share calculations, the rounding is always
/// performed in a way that favors the pool rather than the withdrawing party. This ensures
/// that the system never underestimates liabilities or overestimates ownership due to rounding,
/// preserving the solvency and integrity of the protocol.
module kai_leverage::equity;

use kai_leverage::util;
use sui::balance::{Self, Balance};
use sui::coin::{Self, TreasuryCap, CoinMetadata};
use sui::url::Url;

public use fun destroy_empty_registry as EquityRegistry.destroy_empty;

/* ================= constants ================= */

const Q64: u128 = 1 << 64;

/* ================= errors ================= */

/// For when trying to destroy a non-zero share balance.
const ENonZero: u64 = 0;

/* ================= structs ================= */

/// Represents a balance of equity shares in Q64.64 format.
public struct EquityShareBalance<phantom T> has store {
    value_x64: u128,
}

/// Registry tracking total equity shares and underlying asset value.
public struct EquityRegistry<phantom T> has store {
    supply_x64: u128,
    underlying_value_x64: u128,
}

/// Treasury combining equity registry with coin minting capability.
public struct EquityTreasury<phantom T> has store {
    registry: EquityRegistry<T>,
    cap: TreasuryCap<T>,
}

/* ================= read ================= */

/// Get the share value in Q64.64 format.
public fun value_x64<T>(share: &EquityShareBalance<T>): u128 {
    share.value_x64
}

/// Get the total share supply in Q64.64 format.
public fun supply_x64<T>(registry: &EquityRegistry<T>): u128 {
    registry.supply_x64
}

/// Get the total underlying value in Q64.64 format.
public fun underlying_value_x64<T>(registry: &EquityRegistry<T>): u128 {
    registry.underlying_value_x64
}

/// Borrow immutable reference to the equity registry.
public fun borrow_registry<T>(treasury: &EquityTreasury<T>): &EquityRegistry<T> {
    &treasury.registry
}

/// Borrow mutable reference to the equity registry.
public fun borrow_mut_registry<T>(treasury: &mut EquityTreasury<T>): &mut EquityRegistry<T> {
    &mut treasury.registry
}

/// Borrow the treasury capability for minting equity tokens.
public fun borrow_treasury_cap<T>(treasury: &EquityTreasury<T>): &TreasuryCap<T> {
    &treasury.cap
}

/* ================= impl ================= */

/// Create a new empty equity registry.
public fun create_registry<T: drop>(_: T): EquityRegistry<T> {
    EquityRegistry {
        supply_x64: 0,
        underlying_value_x64: 0,
    }
}

/// Create a new equity registry using an existing treasury cap.
public fun create_registry_with_cap<T: drop>(_: &TreasuryCap<T>): EquityRegistry<T> {
    EquityRegistry {
        supply_x64: 0,
        underlying_value_x64: 0,
    }
}

/// Create a new equity treasury. The treasury has the ability to mint equity as fungible coins.
public fun create_treasury<T: drop>(
    witness: T,
    decimals: u8,
    symbol: vector<u8>,
    name: vector<u8>,
    description: vector<u8>,
    icon_url: Option<Url>,
    ctx: &mut TxContext,
): (EquityTreasury<T>, CoinMetadata<T>) {
    let registry = EquityRegistry<T> {
        supply_x64: 0,
        underlying_value_x64: 0,
    };
    let (cap, metadata) = coin::create_currency(
        witness,
        decimals,
        symbol,
        name,
        description,
        icon_url,
        ctx,
    );

    let treasury = EquityTreasury { registry, cap };

    (treasury, metadata)
}

/// Create a zero equity share balance.
public fun zero<T>(): EquityShareBalance<T> {
    EquityShareBalance {
        value_x64: 0,
    }
}

/// Increase the underlying value and issue corresponding shares. Input value is in Q64.64 format.
public fun increase_value_and_issue_x64<T>(
    registry: &mut EquityRegistry<T>,
    value_x64: u128,
): EquityShareBalance<T> {
    if (registry.underlying_value_x64 == 0) {
        registry.underlying_value_x64 = value_x64;
        registry.supply_x64 = value_x64;
        return EquityShareBalance { value_x64 }
    };

    let amt_shares_x64 = util::muldiv_u128(
        registry.supply_x64,
        value_x64,
        registry.underlying_value_x64,
    );
    registry.underlying_value_x64 = registry.underlying_value_x64 + value_x64;
    registry.supply_x64 = registry.supply_x64 + amt_shares_x64;

    EquityShareBalance { value_x64: amt_shares_x64 }
}

/// Increase the underlying value and issue corresponding shares.
public fun increase_value_and_issue<T>(
    registry: &mut EquityRegistry<T>,
    value: u64,
): EquityShareBalance<T> {
    let value_x64 = (value as u128) * Q64;
    increase_value_and_issue_x64(registry, value_x64)
}

/// Increase the underlying value without issuing new shares. Input value is in Q64.64 format.
public fun increase_value_x64<T>(registry: &mut EquityRegistry<T>, value_x64: u128) {
    registry.underlying_value_x64 = registry.underlying_value_x64 + value_x64;
}

/// Increase the underlying value without issuing new shares.
public fun increase_value<T>(registry: &mut EquityRegistry<T>, value: u64) {
    let value_x64 = (value as u128) * Q64;
    increase_value_x64(registry, value_x64)
}

/// Decrease the underlying value without redeeming shares. Input value is in Q64.64 format.
public fun decrease_value_x64<T>(registry: &mut EquityRegistry<T>, value_x64: u128) {
    registry.underlying_value_x64 = registry.underlying_value_x64 - value_x64;
}

/// Decrease the underlying value without redeeming shares.
public fun decrease_value<T>(registry: &mut EquityRegistry<T>, value: u64) {
    let value_x64 = (value as u128) * Q64;
    decrease_value_x64(registry, value_x64)
}

/// Calculate the amount of underlying value that would be redeemed for the given share value when calling the
/// `redeem_x64` function.
/// The input and return values are in Q64.64 format.
public fun calc_redeem_x64<T>(registry: &EquityRegistry<T>, share_value_x64: u128): u128 {
    util::muldiv_u128(
        registry.underlying_value_x64,
        share_value_x64,
        registry.supply_x64,
    )
}

/// Redeem the shares for the underlying value. Reduces the underlying value and supply.
/// Returns the value redeemed (the amount the underlying value was reduced by).
/// The returned value is in Q64.64 format.
public fun redeem_x64<T>(registry: &mut EquityRegistry<T>, share: EquityShareBalance<T>): u128 {
    let EquityShareBalance { value_x64: share_value_x64 } = share;

    let value_x64 = util::muldiv_u128(
        registry.underlying_value_x64,
        share_value_x64,
        registry.supply_x64,
    );
    registry.underlying_value_x64 = registry.underlying_value_x64 - value_x64;
    registry.supply_x64 = registry.supply_x64 - share_value_x64;

    value_x64
}

/// Calculate the amount of underlying value that would be redeemed for the given share value when calling the
/// `redeem_lossy` function.
/// The input and return values are in Q64.64 format.
public fun calc_redeem_lossy<T>(registry: &EquityRegistry<T>, share_value_x64: u128): u64 {
    let value_x64 = calc_redeem_x64(registry, share_value_x64);
    ((value_x64 / Q64) as u64)
}

/// Lossy. Redeem the shares for the underlying value. Reduces the underlying value and supply.
/// Returns the value redeemed (i.e., the amount by which the underlying value was reduced).
///
/// The redeemed amount is rounded down, and any fractional difference is added back to the total
/// underlying value. This effectively increases the value of other shares by that fraction.
public fun redeem_lossy<T>(registry: &mut EquityRegistry<T>, share: EquityShareBalance<T>): u64 {
    let value_x64 = redeem_x64(registry, share);
    let value = ((value_x64 / Q64) as u64);
    let fraction = value_x64 % Q64;
    registry.underlying_value_x64 = registry.underlying_value_x64 + fraction;

    value
}

/// Calculate the amount of shares required to redeem the given amount of underlying value when calling the
/// `redeem_for_amount_x64` function.
/// Since the resulting redeemed value can sometimes be different from the required due to integer
/// arithmetic, the function also returns the calculated redeemed value (the amount the underlying value
/// would be reduced by). This value is always greater than or equal to the required amount.
/// Returns `(share_amount_x64, redeemed_value_x64)` tuple. The input and return values are in
/// Q64.64 format.
public fun calc_redeem_for_amount_x64<T>(
    registry: &EquityRegistry<T>,
    amount_x64: u128,
): (u128, u128) {
    let share_amount_x64 = util::muldiv_round_up_u128(
        amount_x64,
        registry.supply_x64,
        registry.underlying_value_x64,
    );

    (share_amount_x64, calc_redeem_x64(registry, share_amount_x64))
}

/// Calculate the amount of `EquityShareBalance` required to redeem the given amount of underlying
/// value when calling the `redeem_lossy` function.
/// The resulting redeemed amount will always be exactly equal to the specified amount.
/// Returns the share amount. The input and return values are in Q64.64 format.
public fun calc_redeem_for_amount<T>(registry: &EquityRegistry<T>, amount: u64): u128 {
    util::muldiv_round_up_u128(
        (amount as u128) * Q64,
        registry.supply_x64,
        registry.underlying_value_x64,
    )
}

/// Calculate the amount of share `Balance` required to redeem the given amount of underlying value
/// when calling the `redeem_lossy` function.
/// Since the resulting redeemed value can sometimes be different from the required due to
/// integer arithmetic, the function also returns the calculated redeemed value (the amount
/// the underlying value would be reduced by). This value is always greater than or equal to the
/// required amount.
public fun calc_balance_redeem_for_amount<T>(
    registry: &EquityRegistry<T>,
    amount: u64,
): (u64, u64) {
    let share_amount = (
        util::muldiv_round_up_u128(
            (amount as u128),
            registry.supply_x64,
            registry.underlying_value_x64,
        ) as u64,
    );
    let redeemed_value = calc_redeem_lossy(registry, (share_amount as u128) * Q64);

    (share_amount, redeemed_value)
}

/// Lossy. Converts the `EquityShareBalance` to a corresponding `Balance`.
/// The fractional difference from rounding down is subtracted from the total supply of shares,
/// which effectively increases the value of other shares against the underlying.
public fun into_balance_lossy<T>(
    share: EquityShareBalance<T>,
    treasury: &mut EquityTreasury<T>,
): Balance<T> {
    let EquityShareBalance { value_x64: share_value_x64 } = share;

    let value = ((share_value_x64 / Q64) as u64);
    let fraction = share_value_x64 % Q64;
    treasury.registry.supply_x64 = treasury.registry.supply_x64 - fraction;

    coin::mint_balance(&mut treasury.cap, value)
}

/// Convert a `EquityShareBalance` to a `Balance` while preserving the fractional part.
/// Not lossy but doesn't consume all the shares.
public fun into_balance<T>(
    share: &mut EquityShareBalance<T>,
    treasury: &mut EquityTreasury<T>,
): Balance<T> {
    let whole_amt = share.value_x64 / Q64 * Q64;
    let share = split_x64(share, whole_amt);

    into_balance_lossy(share, treasury)
}

/// Converts the `Balance` to a corresponding `EquityShareBalance`.
public fun from_balance<T>(
    treasury: &mut EquityTreasury<T>,
    balance: Balance<T>,
): EquityShareBalance<T> {
    let value_x64 = (balance::value(&balance) as u128) * Q64;
    balance::decrease_supply(
        coin::supply_mut(&mut treasury.cap),
        balance,
    );

    EquityShareBalance { value_x64 }
}

/// Split a `EquityShareBalance` and take a sub balance from it. Input amount is in Q64.64 format.
public fun split_x64<T>(
    shares: &mut EquityShareBalance<T>,
    amount_x64: u128,
): EquityShareBalance<T> {
    let new_shares = EquityShareBalance { value_x64: amount_x64 };
    shares.value_x64 = shares.value_x64 - amount_x64;

    new_shares
}

/// Withdraw all shares from a `EquityShareBalance`.
public fun withdraw_all<T>(shares: &mut EquityShareBalance<T>): EquityShareBalance<T> {
    let amount_x64 = shares.value_x64;
    split_x64(shares, amount_x64)
}

/// Split a `EquityShareBalance` and take a sub balance from it.
public fun split<T>(share: &mut EquityShareBalance<T>, amount: u64): EquityShareBalance<T> {
    let amount_x64 = (amount as u128) * Q64;
    split_x64(share, amount_x64)
}

/// Join two `EquityShareBalance`s. The second balance is consumed.
public fun join<T>(self: &mut EquityShareBalance<T>, other: EquityShareBalance<T>) {
    let EquityShareBalance { value_x64 } = other;
    self.value_x64 = self.value_x64 + value_x64;
}

/// Destroy a `EquityShareBalance` with zero value.
public fun destroy_zero<T>(shares: EquityShareBalance<T>) {
    assert!(shares.value_x64 == 0, ENonZero);
    let EquityShareBalance { value_x64: _ } = shares;
}

/// Destroy an empty `EquityRegistry`.
public fun destroy_empty_registry<T>(registry: EquityRegistry<T>) {
    let EquityRegistry { supply_x64, underlying_value_x64 } = registry;
    assert!(supply_x64 == 0, ENonZero);
    assert!(underlying_value_x64 == 0, ENonZero);
}

#[test_only]
public fun create_treasury_for_testing<T: drop>(ctx: &mut TxContext): EquityTreasury<T> {
    let registry = EquityRegistry<T> {
        supply_x64: 0,
        underlying_value_x64: 0,
    };
    let cap = coin::create_treasury_cap_for_testing(ctx);

    let treasury = EquityTreasury { registry, cap };

    treasury
}

module kai_leverage::debt;

use kai_leverage::util;
use sui::balance::{Self, Balance};
use sui::coin::{Self, TreasuryCap, CoinMetadata};
use sui::url::Url;

public use fun destroy_empty_registry as DebtRegistry.destroy_empty;

/* ================= constants ================= */

const Q64: u128 = 1 << 64;

/* ================= errors ================= */

/// For when trying to destroy a non-empty share balance or registry.
const ENonZero: u64 = 0;

/* ================= structs ================= */

public struct DebtShareBalance<phantom T> has store {
    value_x64: u128,
}

public struct DebtRegistry<phantom T> has store {
    supply_x64: u128,
    liability_value_x64: u128,
}

public struct DebtTreasury<phantom T> has store {
    registry: DebtRegistry<T>,
    cap: TreasuryCap<T>,
}

/* ================= read ================= */

public fun value_x64<T>(share: &DebtShareBalance<T>): u128 {
    share.value_x64
}

public fun supply_x64<T>(registry: &DebtRegistry<T>): u128 {
    registry.supply_x64
}

public fun liability_value_x64<T>(registry: &DebtRegistry<T>): u128 {
    registry.liability_value_x64
}

public fun borrow_registry<T>(treasury: &DebtTreasury<T>): &DebtRegistry<T> {
    &treasury.registry
}

public fun borrow_mut_registry<T>(treasury: &mut DebtTreasury<T>): &mut DebtRegistry<T> {
    &mut treasury.registry
}

public fun borrow_treasury_cap<T>(treasury: &DebtTreasury<T>): &TreasuryCap<T> {
    &treasury.cap
}

/* ================= impl ================= */

public fun create_registry<T: drop>(_: T): DebtRegistry<T> {
    DebtRegistry {
        supply_x64: 0,
        liability_value_x64: 0,
    }
}

public fun create_registry_with_cap<T: drop>(_: &TreasuryCap<T>): DebtRegistry<T> {
    DebtRegistry {
        supply_x64: 0,
        liability_value_x64: 0,
    }
}

public fun create_treasury<T: drop>(
    witness: T,
    decimals: u8,
    symbol: vector<u8>,
    name: vector<u8>,
    description: vector<u8>,
    icon_url: Option<Url>,
    ctx: &mut TxContext,
): (DebtTreasury<T>, CoinMetadata<T>) {
    let registry = DebtRegistry<T> {
        supply_x64: 0,
        liability_value_x64: 0,
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

    let treasury = DebtTreasury { registry, cap };

    (treasury, metadata)
}

public fun zero<T>(): DebtShareBalance<T> {
    DebtShareBalance {
        value_x64: 0,
    }
}

/// Increase the liability value and issue corresponding debt shares. Input value is in `UQ64.64`
/// format.
public fun increase_liability_and_issue_x64<T>(
    registry: &mut DebtRegistry<T>,
    value_x64: u128,
): DebtShareBalance<T> {
    if (registry.liability_value_x64 == 0) {
        registry.liability_value_x64 = value_x64;
        registry.supply_x64 = value_x64;
        return DebtShareBalance { value_x64 }
    };

    let amt_shares_x64 = util::muldiv_round_up_u128(
        registry.supply_x64,
        value_x64,
        registry.liability_value_x64,
    );
    registry.liability_value_x64 = registry.liability_value_x64 + value_x64;
    registry.supply_x64 = registry.supply_x64 + amt_shares_x64;

    DebtShareBalance { value_x64: amt_shares_x64 }
}

/// Increase the liability value and issue corresponding debt shares.
public fun increase_liability_and_issue<T>(
    registry: &mut DebtRegistry<T>,
    value: u64,
): DebtShareBalance<T> {
    let value_x64 = (value as u128) * Q64;
    increase_liability_and_issue_x64(registry, value_x64)
}

/// Increase the liability without issuing new shares. Input value is in `UQ64.64` format.
public fun increase_liability_x64<T>(registry: &mut DebtRegistry<T>, value_x64: u128) {
    registry.liability_value_x64 = registry.liability_value_x64 + value_x64;
}

/// Increase the liability without issuing new shares.
public fun increase_liability<T>(registry: &mut DebtRegistry<T>, value: u64) {
    let value_x64 = (value as u128) * Q64;
    increase_liability_x64(registry, value_x64)
}

/// Decrease the liability without repaying shares. Input value is in `UQ64.64` format.
public fun decrease_liability_x64<T>(registry: &mut DebtRegistry<T>, value_x64: u128) {
    registry.liability_value_x64 = registry.liability_value_x64 - value_x64;
}

/// Decrease the liability without redeeming shares.
public fun decrease_liability<T>(registry: &mut DebtRegistry<T>, value: u64) {
    let value_x64 = (value as u128) * Q64;
    decrease_liability_x64(registry, value_x64)
}

/// Calculate the liability amount that would be repaid for the given share value when calling the
/// `repay_x64` function.
/// The input and return values are in `UQ64.64` format.
public fun calc_repay_x64<T>(registry: &DebtRegistry<T>, share_value_x64: u128): u128 {
    util::muldiv_round_up_u128(
        registry.liability_value_x64,
        share_value_x64,
        registry.supply_x64,
    )
}

/// Repay the share debt. Reduces the total liability and supply.
/// Returns the value repaid (the amount the liability was reduced by).
/// The returned value is in `UQ64.64` format.
public fun repay_x64<T>(registry: &mut DebtRegistry<T>, share: DebtShareBalance<T>): u128 {
    let DebtShareBalance { value_x64: share_value_x64 } = share;

    let value_x64 = util::muldiv_round_up_u128(
        registry.liability_value_x64,
        share_value_x64,
        registry.supply_x64,
    );
    registry.liability_value_x64 = registry.liability_value_x64 - value_x64;
    registry.supply_x64 = registry.supply_x64 - share_value_x64;

    value_x64
}

/// Calculate the liability amount that would be repaid for the given share value when calling the
/// `repay_lossy` function.
/// The input and return values are in `UQ64.64` format.
public fun calc_repay_lossy<T>(registry: &DebtRegistry<T>, share_value_x64: u128): u64 {
    let value_x64 = calc_repay_x64(registry, share_value_x64);
    (util::divide_and_round_up_u128(value_x64, Q64) as u64)
}

/// Lossy. Repay the share debt. Reduces the total liability and supply.
/// Returns the value repaid (the amount the liability was reduced by).
/// The repaid amount is rounded up and the fractional difference is reduced from the total
/// liability,
/// effectively reducing the debt of other shares against the total liability by that fraction.
public fun repay_lossy<T>(registry: &mut DebtRegistry<T>, share: DebtShareBalance<T>): u64 {
    let value_x64 = repay_x64(registry, share);
    // this cast will abort if `value_x64` is larger than `(Q64 - 1) * Q64` but this is a very
    // rare edge case and the shares can be redeemed in smaller chunks to avoid this.
    let value = (util::divide_and_round_up_u128(value_x64, Q64) as u64);

    // Note: this can fail in situations where all or almost all remaining shares are being redeemed
    // due to the fact that the value is calculated by rounding up which may mean the fractional
    // part
    // is larger that the total remaining liability. Use `repay_x64` to handle this edge case if
    // needed.
    let fraction = if (value_x64 % Q64 == 0) {
        0
    } else {
        Q64 - (value_x64 % Q64)
    };
    registry.liability_value_x64 = registry.liability_value_x64 - fraction;

    value
}

/// Calculate the `EquityShareBalance` required to repay the given amount when calling the
/// `repay_x64` function.
/// Since the resulting repaid value can sometimes be different from the required due to integer
/// arithmetic,
/// the function also returns the calculated repaid value (the amount the liability would be reduced
/// by).
/// This value is always lower than or equal to the required amount.
/// Returns `(share_amount_x64, repaid_value_x64)` tuple. The input and return values are in
/// `UQ64.64` format.
public fun calc_repay_for_amount_x64<T>(
    registry: &DebtRegistry<T>,
    amount_x64: u128,
): (u128, u128) {
    // smallest share amount which will result in up to `amount_x64` being repaid
    let share_amount_x64 = util::muldiv_u128(
        amount_x64,
        registry.supply_x64,
        registry.liability_value_x64,
    );
    let repaid_value_x64 = calc_repay_x64(registry, share_amount_x64);

    (share_amount_x64, repaid_value_x64)
}

/// Calculate the `EquityShareBalance` required to repay the given amount when calling the
/// `repay_lossy` function.
/// The resulting repaid amount will always be exactly equal to the specified amount.
/// Returns the share amount. The input and return values are in `UQ64.64` format.
public fun calc_repay_for_amount<T>(registry: &DebtRegistry<T>, amount: u64): u128 {
    util::muldiv_u128(
        (amount as u128) * Q64,
        registry.supply_x64,
        registry.liability_value_x64,
    )
}

/// Calculate the share `Balance` required to repay the given amount when calling the `repay_lossy`
/// function.
/// Since the resulting repaid value can sometimes be different from the required due to integer
/// arithmetic,
/// the function also returns the calculated repaid value (the amount the liability would be reduced
/// by).
/// This value is always lower than or equal to the required amount.
public fun calc_balance_repay_for_amount<T>(registry: &DebtRegistry<T>, amount: u64): (u64, u64) {
    let share_amount = (
        util::muldiv_u128(
            (amount as u128),
            registry.supply_x64,
            registry.liability_value_x64,
        ) as u64,
    );
    let repaid_value = calc_repay_lossy(registry, (share_amount as u128) * Q64);

    (share_amount, repaid_value)
}

/// Lossy. Converts the `DebtShareBalance` to a corresponding `Balance`. The fractional difference
/// from rounding
/// up is added to the total supply of shares which effectively reduces the debt of other shares
/// against the total liability.
public fun into_balance_lossy<T>(
    share: DebtShareBalance<T>,
    treasury: &mut DebtTreasury<T>,
): Balance<T> {
    let DebtShareBalance { value_x64: share_value_x64 } = share;

    // this cast will abort if `share_value_x64` is larger than `(Q64 - 1) * Q64` but this is a very
    // rare edge case and the shares can be converted in smaller chunks to avoid this.
    let value = (util::divide_and_round_up_u128(share_value_x64, Q64) as u64);

    let fraction = if (share_value_x64 % Q64 == 0) {
        0
    } else {
        Q64 - (share_value_x64 % Q64)
    };
    treasury.registry.supply_x64 = treasury.registry.supply_x64 + fraction;

    // the share supply can become larger than `(Q64 - 1) * Q64` and in this case not all shares can
    // be converted
    // as the coin for the final `Q64 - 1` shares can't be minted due to u64 max on the coin supply,
    // but this
    // edge case is not very important to support in practice
    coin::mint_balance(&mut treasury.cap, value)
}

/// Convert a `DebtShareBalance` to a `Balance` while preserving the fractional part. Not lossy but
/// doesn't
/// consume all the shares.
public fun into_balance<T>(
    share: &mut DebtShareBalance<T>,
    treasury: &mut DebtTreasury<T>,
): Balance<T> {
    let whole_amt = share.value_x64 / Q64 * Q64;
    let share = split_x64(share, whole_amt);

    into_balance_lossy(share, treasury)
}

/// Converts the `Balance` to a corresponding `DebtShareBalance`.
public fun from_balance<T>(
    treasury: &mut DebtTreasury<T>,
    balance: Balance<T>,
): DebtShareBalance<T> {
    let value_x64 = (balance::value(&balance) as u128) * Q64;
    balance::decrease_supply(
        coin::supply_mut(&mut treasury.cap),
        balance,
    );

    DebtShareBalance { value_x64 }
}

/// Split a `DebtShareBalance` and take a sub balance from it. Input amount is in `UQ64.64` format.
public fun split_x64<T>(shares: &mut DebtShareBalance<T>, amount_x64: u128): DebtShareBalance<T> {
    let new_shares = DebtShareBalance { value_x64: amount_x64 };
    shares.value_x64 = shares.value_x64 - amount_x64;

    new_shares
}

/// Split a `DebtShareBalance` and take a sub balance from it.
public fun split<T>(shares: &mut DebtShareBalance<T>, amount: u64): DebtShareBalance<T> {
    let amount_x64 = (amount as u128) * Q64;
    split_x64(shares, amount_x64)
}

/// Withdraw all shares from a `DebtShareBalance`.
public fun withdraw_all<T>(shares: &mut DebtShareBalance<T>): DebtShareBalance<T> {
    let amount_x64 = shares.value_x64;
    split_x64(shares, amount_x64)
}

/// Join two `DebtShareBalance`s. The second balance is consumed.
public fun join<T>(self: &mut DebtShareBalance<T>, other: DebtShareBalance<T>) {
    let DebtShareBalance { value_x64 } = other;
    self.value_x64 = self.value_x64 + value_x64;
}

/// Destroy a `DebtShareBalance` with zero value.
public fun destroy_zero<T>(shares: DebtShareBalance<T>) {
    assert!(shares.value_x64 == 0, ENonZero);
    let DebtShareBalance { value_x64: _ } = shares;
}

/// Destroy an empty `DebtRegistry`.
public fun destroy_empty_registry<T>(registry: DebtRegistry<T>) {
    let DebtRegistry { supply_x64, liability_value_x64 } = registry;
    assert!(supply_x64 == 0, ENonZero);
    assert!(liability_value_x64 == 0, ENonZero);
}

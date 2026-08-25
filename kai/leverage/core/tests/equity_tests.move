#[test_only]
module kai_leverage::equity_tests;

use kai_leverage::equity::{Self, EquityRegistry, EquityShareBalance};
use std::unit_test::destroy;
use sui::test_scenario;

public struct EQUITY_TESTS has drop {}

const Q64: u128 = 1 << 64;

/// A fresh registry issues shares 1:1 against the deposited value.
#[test]
fun test_issue_on_empty_registry() {
    let mut registry = equity::create_registry(EQUITY_TESTS {});

    let shares = registry.increase_value_and_issue(1000);

    assert!(shares.value_x64() == 1000 * Q64);
    assert!(registry.supply_x64() == 1000 * Q64);
    assert!(registry.underlying_value_x64() == 1000 * Q64);

    let redeemed = registry.redeem_lossy(shares);
    assert!(redeemed == 1000);

    registry.destroy_empty();
}

/// A registry with shares outstanding issues proportionally, so value accrued between
/// deposits stays with the existing holders instead of being shared with the new one.
#[test]
fun test_issue_proportional_with_existing_supply() {
    let mut registry = equity::create_registry(EQUITY_TESTS {});

    let first = registry.increase_value_and_issue(1000);

    // the pool doubles in value without issuing shares (e.g. accrued interest)
    registry.increase_value_x64(1000 * Q64);

    // so a second supplier depositing the same amount gets half as many shares
    let second = registry.increase_value_and_issue(1000);
    assert!(second.value_x64() == 500 * Q64);
    assert!(registry.supply_x64() == 1500 * Q64);
    assert!(registry.underlying_value_x64() == 3000 * Q64);

    // the first supplier keeps the accrued value, the second gets back what they put in
    assert!(registry.redeem_lossy(first) == 2000);
    assert!(registry.redeem_lossy(second) == 1000);

    registry.destroy_empty();
}

/// When the last holder exits, `redeem_lossy` rounds their payout down to whole units and
/// adds the remainder back, leaving sub-unit dust in `underlying_value_x64` with
/// `supply_x64` at zero. The next deposit must still be issued shares: keying the
/// empty-registry check off `underlying_value_x64` issues zero shares here, absorbing the
/// deposit and bricking the registry permanently.
#[test]
fun test_issue_after_full_redemption_leaves_dust() {
    let mut registry = equity::create_registry(EQUITY_TESTS {});

    let shares = registry.increase_value_and_issue(1000);

    // interest accrues an amount that is not a whole number of units
    registry.increase_value_x64(Q64 / 2);

    // the only holder redeems everything and is paid the whole-unit part
    assert!(registry.redeem_lossy(shares) == 1000);

    // leaving no shares outstanding, but half a unit of ownerless dust behind
    assert!(registry.supply_x64() == 0);
    assert!(registry.underlying_value_x64() == Q64 / 2);

    // the next deposit is issued 1:1 and the dust, which has no backing balance, is dropped
    let new_shares = registry.increase_value_and_issue(500);
    assert!(new_shares.value_x64() == 500 * Q64);
    assert!(registry.supply_x64() == 500 * Q64);
    assert!(registry.underlying_value_x64() == 500 * Q64);

    // and the new holder can redeem the full amount back out
    assert!(registry.redeem_lossy(new_shares) == 500);

    registry.destroy_empty();
}

/// A registry whose share price is above one and not a whole number of units, so that share
/// and value conversions both round. Issues 1000 units of shares, then accrues value against
/// them without issuing more.
fun registry_with_fractional_price(): (EquityRegistry<EQUITY_TESTS>, EquityShareBalance<EQUITY_TESTS>) {
    let mut registry = equity::create_registry(EQUITY_TESTS {});
    let shares = registry.increase_value_and_issue(1000);
    registry.increase_value_x64(500 * Q64 + 7_777_777_777_777_777);
    (registry, shares)
}

/* ================= calc_* agreement ================= */

/// `calc_redeem_lossy` is what `supply_pool::calc_withdraw_by_shares` reports to callers before
/// they commit to a withdrawal, so it has to predict `redeem_lossy` exactly.
#[test]
fun test_calc_redeem_lossy_matches_redeem_lossy() {
    let (mut registry, mut shares) = registry_with_fractional_price();

    // redeem in uneven chunks so each call rounds differently
    let mut i = 0;
    while (i < 4) {
        let third = shares.value_x64() / 3;
        let chunk = shares.split_x64(third);
        let predicted = registry.calc_redeem_lossy(chunk.value_x64());
        assert!(registry.redeem_lossy(chunk) == predicted);
        i = i + 1;
    };

    let predicted = registry.calc_redeem_lossy(shares.value_x64());
    assert!(registry.redeem_lossy(shares) == predicted);

    destroy(registry);
}

/// `calc_redeem_for_amount` promises the redeemed amount is *exactly* the amount asked for.
/// The promise holds only while the share price is below `Q64`, which is not stated on the
/// function but is guaranteed in practice.
#[test]
fun test_calc_redeem_for_amount_redeems_exactly() {
    let (mut registry, mut shares) = registry_with_fractional_price();

    let mut amount = 1;
    while (amount < 500) {
        let share_amount_x64 = registry.calc_redeem_for_amount(amount);
        let chunk = shares.split_x64(share_amount_x64);
        assert!(registry.redeem_lossy(chunk) == amount);
        amount = amount * 7;
    };

    destroy(registry);
    destroy(shares);
}

/// `calc_balance_redeem_for_amount` works in whole share coins, so it can only round up to the
/// next coin. It must never report a redemption that falls short of the requested amount --
/// `skim_base_profits` subtracts a share from the result precisely because it over-redeems.
#[test]
fun test_calc_balance_redeem_for_amount_is_never_short() {
    let (mut registry, mut shares) = registry_with_fractional_price();

    let mut amount = 1;
    while (amount < 500) {
        let (share_amount, redeemed_value) = registry.calc_balance_redeem_for_amount(amount);
        assert!(redeemed_value >= amount);

        // and redeeming that many whole share coins really does yield the reported value
        let chunk = shares.split_x64((share_amount as u128) * Q64);
        assert!(registry.redeem_lossy(chunk) == redeemed_value);
        amount = amount * 7;
    };

    destroy(registry);
    destroy(shares);
}

/* ================= supply accounting across balance conversions ================= */

/// `into_balance_lossy` truncates to whole share coins and burns the remainder from the supply;
/// `from_balance` converts coins back. Across both, `supply_x64` must stay equal to the total
/// shares actually outstanding -- the invariant whose breach strands holders.
#[test]
fun test_balance_conversion_preserves_supply_accounting() {
    let mut test = test_scenario::begin(@0);
    let mut treasury = equity::create_treasury_for_testing<EQUITY_TESTS>(test.ctx());

    let registry = treasury.borrow_mut_registry();
    let held = registry.increase_value_and_issue(1000);
    registry.increase_value_x64(500 * Q64 + 7_777_777_777_777_777);

    // issue a fractional share amount, so the conversion has a remainder to burn
    let converted = treasury.borrow_mut_registry().increase_value_and_issue(333);
    let converted_x64 = converted.value_x64();
    assert!(converted_x64 % Q64 > 0);

    let supply_before = treasury.borrow_registry().supply_x64();
    let coins = converted.into_balance_lossy(&mut treasury);

    // the coins carry the whole part, the fractional part is burned from the supply
    assert!(coins.value() == ((converted_x64 / Q64) as u64));
    assert!(treasury.borrow_registry().supply_x64() == supply_before - converted_x64 % Q64);

    // converting back yields shares worth exactly the coins, leaving the registry untouched
    let supply_mid = treasury.borrow_registry().supply_x64();
    let coins_value = coins.value();
    let restored = equity::from_balance(&mut treasury, coins);
    assert!(restored.value_x64() == (coins_value as u128) * Q64);
    assert!(treasury.borrow_registry().supply_x64() == supply_mid);

    // the invariant: recorded supply equals the shares actually held
    assert!(
        treasury.borrow_registry().supply_x64() == held.value_x64() + restored.value_x64(),
    );

    destroy(treasury);
    destroy(held);
    destroy(restored);
    test.end();
}

/* ================= no value leakage ================= */

/// The module's central claim is that rounding always favours the pool. No sequence of
/// redemptions may pay out more whole units than the registry recorded as underlying value,
/// and the order holders exit in must not change that.
#[test]
fun test_redemptions_never_exceed_recorded_value() {
    let (mut r1, mut a1) = registry_with_fractional_price();
    let third = a1.value_x64() / 3;
    let b1 = a1.split_x64(third);
    let budget = r1.underlying_value_x64() / Q64;

    let first = r1.redeem_lossy(a1) + r1.redeem_lossy(b1);
    assert!(first <= (budget as u64));

    // same registry, holders exiting in the opposite order
    let (mut r2, mut a2) = registry_with_fractional_price();
    let third = a2.value_x64() / 3;
    let b2 = a2.split_x64(third);
    assert!(r2.underlying_value_x64() / Q64 == budget);

    let second = r2.redeem_lossy(b2) + r2.redeem_lossy(a2);
    assert!(second <= (budget as u64));

    destroy(r1);
    destroy(r2);
}

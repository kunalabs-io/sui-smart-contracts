#[test_only]
module kai_leverage::debt_tests;

use kai_leverage::debt::{Self, DebtRegistry, DebtShareBalance};
use std::unit_test::destroy;
use sui::test_scenario;

public struct DEBT_TESTS has drop {}

const Q64: u128 = 1 << 64;

/// Drive a registry into the degenerate state left behind by `repay_lossy`: shares still
/// outstanding while the recorded liability has been clamped to zero.
///
/// A borrower repays all but `Q64 / 1000` of the shares. Their payment is rounded up to whole
/// units, and the resulting overpayment (`0.999 * Q64`) is larger than the liability left over
/// (`0.001 * Q64`), so the clamp added in b69be563 pins the liability at zero instead of
/// underflowing. Returns the registry and the shares still held by the dust borrower.
fun registry_with_dust_shares(): (DebtRegistry<DEBT_TESTS>, DebtShareBalance<DEBT_TESTS>) {
    let mut registry = debt::create_registry(DEBT_TESTS {});

    let mut shares = registry.increase_liability_and_issue(1000);
    registry.increase_liability_x64(Q64 / 500);

    let repaid = shares.split_x64(1000 * Q64 - Q64 / 1000);
    assert!(registry.repay_lossy(repaid) == 1001);

    assert!(registry.supply_x64() == Q64 / 1000);
    assert!(registry.liability_value_x64() == 0);

    (registry, shares)
}

/// With no new borrow in between, the dust holder can always exit: their shares redeem against
/// a zero liability, so they repay nothing and the registry closes out cleanly.
#[test]
fun test_dust_holder_exits_for_zero() {
    let (mut registry, dust) = registry_with_dust_shares();

    assert!(registry.repay_lossy(dust) == 0);

    assert!(registry.supply_x64() == 0);
    assert!(registry.liability_value_x64() == 0);
    registry.destroy_empty();
}

/// A borrow landing while the dust shares are still outstanding must not drop them from the
/// registry. `supply_x64` has to keep counting them, otherwise the outstanding share balances
/// exceed the recorded supply and the last repayment underflows.
#[test]
fun test_borrow_preserves_outstanding_dust_shares() {
    let (mut registry, dust) = registry_with_dust_shares();

    let borrowed = registry.increase_liability_and_issue(100);

    // the new borrower holds 100 units of shares, the dust holder still holds theirs, and the
    // registry must account for both
    assert!(borrowed.value_x64() == 100 * Q64);
    assert!(registry.supply_x64() == 100 * Q64 + Q64 / 1000);
    assert!(registry.liability_value_x64() == 100 * Q64);

    // the new borrower repays what they took out, and the dust holder still owes nothing
    assert!(registry.repay_lossy(borrowed) == 100);
    assert!(registry.repay_lossy(dust) == 0);

    assert!(registry.supply_x64() == 0);
    assert!(registry.liability_value_x64() == 0);
    registry.destroy_empty();
}

/// The same, with the two repayments in the opposite order. Neither ordering may strand a
/// holder, since transaction order is not something either party controls.
///
/// The order does shift who pays the rounding unit: the dust holder's sub-unit debt rounds up
/// to one whole unit, and `repay_lossy` credits that overpayment to the remaining borrower, who
/// then owes one less. The total collected is 100 either way.
#[test]
fun test_borrow_then_dust_holder_repays_first() {
    let (mut registry, dust) = registry_with_dust_shares();

    let borrowed = registry.increase_liability_and_issue(100);

    assert!(registry.repay_lossy(dust) == 1);
    assert!(registry.repay_lossy(borrowed) == 99);

    assert!(registry.supply_x64() == 0);
    assert!(registry.liability_value_x64() == 0);
    registry.destroy_empty();
}

/// A registry whose liability per share is above one and not a whole number of units, so that
/// share and value conversions both round. Issues 1000 units of debt, then accrues interest
/// against it without issuing more shares.
fun registry_with_accrued_interest(): (DebtRegistry<DEBT_TESTS>, DebtShareBalance<DEBT_TESTS>) {
    let mut registry = debt::create_registry(DEBT_TESTS {});
    let shares = registry.increase_liability_and_issue(1000);
    registry.increase_liability_x64(500 * Q64 + 7_777_777_777_777_777);
    (registry, shares)
}

/* ================= b69be563 regression ================= */

/// Repaying every outstanding share against a liability that is not a whole number of units.
/// `repay_x64` drives the liability to exactly zero, but the payment is rounded up, so the
/// overpayment credited back to other borrowers has nothing left to reduce. Without the clamp
/// in `repay_lossy` this underflows, which is what made full repayment impossible.
#[test]
fun test_full_repayment_with_fractional_liability() {
    let (mut registry, shares) = registry_with_accrued_interest();

    assert!(registry.liability_value_x64() % Q64 > 0);
    assert!(shares.value_x64() == registry.supply_x64());

    // the whole-unit part is 1500, rounded up because the liability carries a fraction
    assert!(registry.repay_lossy(shares) == 1501);

    assert!(registry.supply_x64() == 0);
    assert!(registry.liability_value_x64() == 0);
    registry.destroy_empty();
}

/* ================= calc_* agreement ================= */

/// `calc_repay_lossy` backs `supply_pool::calc_repay_by_shares`, which position reductions use
/// to size a repayment before committing to it, so it has to predict `repay_lossy` exactly.
#[test]
fun test_calc_repay_lossy_matches_repay_lossy() {
    let (mut registry, mut shares) = registry_with_accrued_interest();

    let mut i = 0;
    while (i < 4) {
        let third = shares.value_x64() / 3;
        let chunk = shares.split_x64(third);
        let predicted = registry.calc_repay_lossy(chunk.value_x64());
        assert!(registry.repay_lossy(chunk) == predicted);
        i = i + 1;
    };

    let predicted = registry.calc_repay_lossy(shares.value_x64());
    assert!(registry.repay_lossy(shares) == predicted);

    destroy(registry);
}

/// `calc_repay_for_amount` promises the repaid amount is exactly the amount asked for. Note the
/// debt side rounds the opposite way to equity: it floors the share amount, so the borrower is
/// never handed shares that repay more of the liability than they paid for.
#[test]
fun test_calc_repay_for_amount_repays_exactly() {
    let (mut registry, mut shares) = registry_with_accrued_interest();

    let mut amount = 1;
    while (amount < 500) {
        let share_amount_x64 = registry.calc_repay_for_amount(amount);
        let chunk = shares.split_x64(share_amount_x64);
        assert!(registry.repay_lossy(chunk) == amount);
        amount = amount * 7;
    };

    destroy(registry);
    destroy(shares);
}

/// `calc_balance_repay_for_amount` works in whole share coins and floors, so the reported
/// repayment may fall short of the request -- but must never exceed it, or a caller sizing a
/// repayment from it would reduce more liability than it paid for.
#[test]
fun test_calc_balance_repay_for_amount_never_overshoots() {
    let (mut registry, mut shares) = registry_with_accrued_interest();

    let mut amount = 1;
    while (amount < 500) {
        let (share_amount, repaid_value) = registry.calc_balance_repay_for_amount(amount);
        assert!(repaid_value <= amount);

        let chunk = shares.split_x64((share_amount as u128) * Q64);
        assert!(registry.repay_lossy(chunk) == repaid_value);
        amount = amount * 7;
    };

    destroy(registry);
    destroy(shares);
}

/* ================= supply accounting across balance conversions ================= */

/// `into_balance_lossy` rounds the debt coins *up* and adds the difference to the supply, the
/// mirror of equity burning it. Across a conversion round trip `supply_x64` must still equal
/// the shares actually outstanding.
#[test]
fun test_balance_conversion_preserves_supply_accounting() {
    let mut test = test_scenario::begin(@0);
    let mut treasury = debt::create_treasury_for_testing<DEBT_TESTS>(test.ctx());

    let registry = treasury.borrow_mut_registry();
    let held = registry.increase_liability_and_issue(1000);
    registry.increase_liability_x64(500 * Q64 + 7_777_777_777_777_777);

    let converted = treasury.borrow_mut_registry().increase_liability_and_issue(333);
    let converted_x64 = converted.value_x64();
    assert!(converted_x64 % Q64 > 0);

    let supply_before = treasury.borrow_registry().supply_x64();
    let coins = converted.into_balance_lossy(&mut treasury);

    // the coins carry the rounded-up whole part, and the supply grows to match
    assert!(coins.value() == ((converted_x64 / Q64) as u64) + 1);
    assert!(
        treasury.borrow_registry().supply_x64() == supply_before + (Q64 - converted_x64 % Q64),
    );

    let supply_mid = treasury.borrow_registry().supply_x64();
    let coins_value = coins.value();
    let restored = debt::from_balance(&mut treasury, coins);
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

/// Rounding must always favour the pool: no sequence of repayments may clear the liability for
/// less than it was recorded at, and the order borrowers repay in must not change that.
#[test]
fun test_repayments_never_fall_short_of_recorded_liability() {
    let (mut r1, mut a1) = registry_with_accrued_interest();
    let third = a1.value_x64() / 3;
    let b1 = a1.split_x64(third);
    let owed = r1.liability_value_x64() / Q64;

    let first = r1.repay_lossy(a1) + r1.repay_lossy(b1);
    assert!(first >= (owed as u64));

    let (mut r2, mut a2) = registry_with_accrued_interest();
    let third = a2.value_x64() / 3;
    let b2 = a2.split_x64(third);
    assert!(r2.liability_value_x64() / Q64 == owed);

    let second = r2.repay_lossy(b2) + r2.repay_lossy(a2);
    assert!(second >= (owed as u64));

    destroy(r1);
    destroy(r2);
}

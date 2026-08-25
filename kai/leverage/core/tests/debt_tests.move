#[test_only]
module kai_leverage::debt_tests;

use kai_leverage::debt::{Self, DebtRegistry};

public struct DEBT_TESTS has drop {}

const Q64: u128 = 1 << 64;

/// Drive a registry into the degenerate state left behind by `repay_lossy`: shares still
/// outstanding while the recorded liability has been clamped to zero.
///
/// A borrower repays all but `Q64 / 1000` of the shares. Their payment is rounded up to whole
/// units, and the resulting overpayment (`0.999 * Q64`) is larger than the liability left over
/// (`0.001 * Q64`), so the clamp added in b69be563 pins the liability at zero instead of
/// underflowing. Returns the registry and the shares still held by the dust borrower.
fun registry_with_dust_shares(): (DebtRegistry<DEBT_TESTS>, debt::DebtShareBalance<DEBT_TESTS>) {
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

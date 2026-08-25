#[test_only]
module kai_leverage::equity_tests;

use kai_leverage::equity;

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

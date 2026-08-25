#[test_only]
/// Regression tests for the rounding of the liquidator reward in
/// `position_model_clmm::calc_liquidate_col_x` / `calc_liquidate_col_y`.
///
/// The reward is derived from the repayment amount actually charged (which rounds up) and is then
/// rounded down. Two properties have to hold at once, and they pull in opposite directions:
///
/// - the reward must never be worth more than the bonus-adjusted value of the repayment, otherwise
///   dust-sized liquidations over-extract collateral and can be repeated to mint bad debt;
/// - the maximum liquidation below the critical margin must still pay out the *entire* collateral,
///   otherwise a wei-sized residue permanently blocks `repay_bad_debt`.
module kai_leverage::position_model_liquidate_rounding_tests;

use kai_leverage::position_model_clmm::{Self as model, calc_liquidate_col_x, calc_liquidate_col_y};

const LIQ_MARGIN_BPS: u16 = 12500; // 1.25
const LIQ_BONUS_BPS: u16 = 750; // 0.075
const BASE_LIQ_FACTOR_BPS: u16 = 3500; // 0.35

const U64_MAX: u64 = 18446744073709551615;

fun liq_col_x(cx: u64, dy: u64, p_x128: u256, max_repayment_amt_y: u64): (u64, u64) {
    let position = model::create(0, 0, 0, cx, 0, 0, dy);
    calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        LIQ_MARGIN_BPS,
        LIQ_BONUS_BPS,
        BASE_LIQ_FACTOR_BPS,
    )
}

fun liq_col_y(cy: u64, dx: u64, p_x128: u256, max_repayment_amt_x: u64): (u64, u64) {
    let position = model::create(0, 0, 0, 0, cy, dx, 0);
    calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        LIQ_MARGIN_BPS,
        LIQ_BONUS_BPS,
        BASE_LIQ_FACTOR_BPS,
    )
}

#[test]
fun dust_repayment_is_not_over_rewarded() {
    // A 1 wei repayment must not be rewarded with more collateral than the bonus allows. When the
    // reward was rounded up this returned `(1, 2)`: 1 wei in, 2 wei out, a realized bonus of
    // ~108% instead of the configured 7.5%.
    let (repayment_amt_y, reward_amt_x) = liq_col_x(10000, 9000, (104 << 128) / 100, 1);
    assert!(repayment_amt_y == 1);
    assert!(reward_amt_x == 1);

    // Cross-decimal (8 decimal collateral against 6 decimal debt, ~300 Y wei per X wei): a wei of
    // debt is worth a fraction of a wei of collateral, so the reward rounds down to zero and no
    // collateral leaves the position. Rounding up used to hand over a whole wei of the far more
    // valuable asset.
    let (repayment_amt_y, reward_amt_x) = liq_col_x(
        100000000,
        26000000000,
        (30000000000 << 128) / 100000000,
        1,
    );
    assert!(repayment_amt_y == 1);
    assert!(reward_amt_x == 0);

    // both mirrored on the other side: collateral Y, debt X
    let (repayment_amt_x, reward_amt_y) = liq_col_y(10000, 9000, 1 << 128, 1);
    assert!(repayment_amt_x == 1);
    assert!(reward_amt_y == 1);

    let (repayment_amt_x, reward_amt_y) = liq_col_y(
        100000000,
        26000000000,
        (100000000 << 128) / 30000000000,
        1,
    );
    assert!(repayment_amt_x == 1);
    assert!(reward_amt_y == 0);
}

#[test]
fun max_liquidation_drains_collateral() {
    // Below the critical margin the maximum liquidation must pay out the entire collateral. A
    // wei-sized residue would leave the position holding assets, which permanently blocks
    // `repay_bad_debt` (it requires the position to hold none), so the outstanding liability could
    // never be cleared. Rounding the reward down without deriving it from the (rounded up)
    // repayment amount leaves exactly 1 wei behind in every one of these cases.
    let (_, reward_amt_x) = liq_col_x(1, 1, (104 << 128) / 100, U64_MAX);
    assert!(reward_amt_x == 1);
    let (_, reward_amt_x) = liq_col_x(17, 17, (104 << 128) / 100, U64_MAX);
    assert!(reward_amt_x == 17);
    let (_, reward_amt_x) = liq_col_x(
        100000000,
        29126213592,
        (30000000000 << 128) / 100000000,
        U64_MAX,
    );
    assert!(reward_amt_x == 100000000);

    let (_, reward_amt_y) = liq_col_y(1, 1, 1 << 128, U64_MAX);
    assert!(reward_amt_y == 1);
    let (_, reward_amt_y) = liq_col_y(17, 17, 1 << 128, U64_MAX);
    assert!(reward_amt_y == 17);
    let (_, reward_amt_y) = liq_col_y(
        100000000,
        29126213592,
        (100000000 << 128) / 30000000000,
        U64_MAX,
    );
    assert!(reward_amt_y == 100000000);
}

#[test]
fun repeated_dust_liquidation_does_not_drain_collateral() {
    // Repeatedly liquidating 1 wei at a time used to drain the collateral outright: the reward
    // rounded up to 2 wei per 1 wei repaid, so `cx` reached 0 while most of `dy` was still
    // outstanding, minting bad debt against the supply pool. Each call now takes at most the
    // bonus, so the loop restores the position's margin and then stops on its own.
    let p_x128 = (104 << 128) / 100; // 1.04
    let mut cx = 10000;
    let mut dy = 9000;
    let mut calls = 0;
    let mut total_repaid = 0;
    let mut total_reward = 0;
    while (calls < 20000) {
        let (repayment_amt_y, reward_amt_x) = liq_col_x(cx, dy, p_x128, 1);
        if (repayment_amt_y == 0 || reward_amt_x == 0) {
            break
        };
        cx = cx - reward_amt_x;
        dy = dy - repayment_amt_y;
        total_repaid = total_repaid + repayment_amt_y;
        total_reward = total_reward + reward_amt_x;
        calls = calls + 1;
    };

    // the loop stops because the position rises back above the liquidation threshold
    assert!(calls == 4048);
    assert!(cx == 5952);
    assert!(dy == 4952);
    // collateral is never drained, so no bad debt is created
    assert!(cx > 0);
    assert!(dy > 0);
    // and the liquidator never took out more collateral than it repaid in debt
    assert!(total_reward == total_repaid);
}

#[test]
fun reward_never_exceeds_liq_bonus() {
    // The collateral paid out must never be worth more than the bonus-adjusted value of the
    // repayment actually charged. This is the invariant the rounding defect violated, and it has
    // to hold across every liquidation regime, not just at the sizes the fixed cases cover.
    let liq_bonus_x64 = ((LIQ_BONUS_BPS as u256) << 64) / 10000;
    let bonus_multiplier_x64 = (1 << 64) + liq_bonus_x64;

    let mut p_num: u256 = 100;
    while (p_num <= 130) {
        let p_x128 = (p_num << 128) / 100;
        let p_x128_y = (100 << 128) / p_num; // sweeps the same margin range on the other side

        let mut max_repayment_amt = 1;
        while (max_repayment_amt <= 100000) {
            let (repayment_amt_y, reward_amt_x) = liq_col_x(10000, 10000, p_x128, max_repayment_amt);
            if (repayment_amt_y > 0) {
                let reward_value_x64 = (reward_amt_x as u256) * (p_x128 >> 64);
                let charged_value_with_bonus_x64 =
                    (((repayment_amt_y as u256) << 64) * bonus_multiplier_x64) >> 64;
                assert!(reward_value_x64 <= charged_value_with_bonus_x64);
            };

            let (repayment_amt_x, reward_amt_y) = liq_col_y(
                10000,
                10000,
                p_x128_y,
                max_repayment_amt,
            );
            if (repayment_amt_x > 0) {
                let reward_value_x64 = (reward_amt_y as u256) << 64;
                let charged_value_with_bonus_x64 =
                    (((repayment_amt_x as u256) * (p_x128_y >> 64)) * bonus_multiplier_x64) >> 64;
                assert!(reward_value_x64 <= charged_value_with_bonus_x64);
            };

            max_repayment_amt = max_repayment_amt * 10;
        };
        p_num = p_num + 1;
    };
}

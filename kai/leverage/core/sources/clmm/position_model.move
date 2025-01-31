module kai_leverage::position_model_clmm;

use kai_leverage::util;
use std::u64;

/// Maximum value for `u128`, `(1 << 128) - 1`.
const U128_MAX: u128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

/// The requested `delta_l` is greater than the available liquidity in the position.
const EInsufficientLiquidity: u64 = 0;

public struct PositionModel has copy, drop {
    // range low
    sqrt_pa_x64: u128,
    // range high
    sqrt_pb_x64: u128,
    // LP position liquidity
    l: u128,
    // additional collateral of X (not used in LP position)
    cx: u64,
    // additional collateral of Y (not used in LP position)
    cy: u64,
    // X debt (amount of X borrowed)
    dx: u64,
    // Y debt (amount of Y borrowed)
    dy: u64,
}

public fun create(
    sqrt_pa_x64: u128,
    sqrt_pb_x64: u128,
    l: u128,
    cx: u64,
    cy: u64,
    dx: u64,
    dy: u64,
): PositionModel {
    PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx,
        cy,
        dx,
        dy,
    }
}

public fun sqrt_pa_x64(self: &PositionModel): u128 {
    self.sqrt_pa_x64
}

public fun sqrt_pb_x64(self: &PositionModel): u128 {
    self.sqrt_pb_x64
}

public fun l(self: &PositionModel): u128 {
    self.l
}

public fun cx(self: &PositionModel): u64 {
    self.cx
}

public fun cy(self: &PositionModel): u64 {
    self.cy
}

public fun dx(self: &PositionModel): u64 {
    self.dx
}

public fun dy(self: &PositionModel): u64 {
    self.dy
}

/// Calculate the amount of X in the LP position for a given price and liquidity.
/// Aborts if there's not enough liquidity in the position.
public fun x_by_liquidity_x64(self: &PositionModel, sqrt_p_x64: u128, delta_l: u128): u128 {
    assert!(delta_l <= self.l, EInsufficientLiquidity);
    if (sqrt_p_x64 >= self.sqrt_pb_x64) {
        return 0
    };
    if (sqrt_p_x64 < self.sqrt_pa_x64) {
        return x_by_liquidity_x64(self, self.sqrt_pa_x64, delta_l)
    };

    // L * (sqrt(pb) - sqrt(p)) / (sqrt(p) * sqrt(pb))
    let num = ((self.sqrt_pb_x64 - sqrt_p_x64) as u256) << 128;
    let denom = (sqrt_p_x64 as u256) * (self.sqrt_pb_x64 as u256);

    let x_x64 = (delta_l as u256) * (num / denom);
    // In some extreme cases the calculation can overflow. The AMM itself can never
    // reach such a state, but in cases where we're doing some kind of a simulation it's possible in
    // principle.
    // We handle this by limiting the result to `U128_MAX` (which is the max amount of token in
    // existence).
    (util::min_u256(x_x64, (U128_MAX as u256)) as u128)
}

/// Calculate the amount of Y in the LP position for a given price and liquidity.
/// Aborts if there's not enough liquidity in the position.
public fun y_by_liquidity_x64(self: &PositionModel, sqrt_p_x64: u128, delta_l: u128): u128 {
    assert!(delta_l <= self.l, EInsufficientLiquidity);
    if (sqrt_p_x64 <= self.sqrt_pa_x64) {
        return 0
    };
    if (sqrt_p_x64 > self.sqrt_pb_x64) {
        return y_by_liquidity_x64(self, self.sqrt_pb_x64, delta_l)
    };

    // L * (sqrt(p) - sqrt(pa))
    let y_x64 = (delta_l as u256) * ((sqrt_p_x64 - self.sqrt_pa_x64) as u256);
    // In some extreme cases the calculation can overflow. The AMM itself can never
    // reach such a state, but in cases where we're doing some kind of a simulation it's possible in
    // principle.
    // We handle this by limiting the result to `U128_MAX` (which is the max amount of token in
    // existence).
    (util::min_u256(y_x64, (U128_MAX as u256)) as u128)
}

/// Calculate the amount of X in the LP position for a given price.
public fun x_x64(self: &PositionModel, sqrt_p_x64: u128): u128 {
    x_by_liquidity_x64(self, sqrt_p_x64, self.l)
}

/// Calculate the amount of Y in the LP position for a given price.
public fun y_x64(self: &PositionModel, sqrt_p_x64: u128): u128 {
    y_by_liquidity_x64(self, sqrt_p_x64, self.l)
}

/// Calculate the total value of assets for the whole position (incl. LP and collateral)
/// for a given price, expressed in Y.
public fun assets_x128(self: &PositionModel, p_x128: u256): u256 {
    let p_x64 = p_x128 >> 64;
    let sqrt_p_x64 = (util::sqrt_u256(p_x128) as u128);
    let cx_x64 = (self.cx as u256) << 64;
    let cy_x64 = (self.cy as u256) << 64;

    // (x(p) + cx) * p + y(p) + cy
    let y_x64 = (y_x64(self, sqrt_p_x64) as u256);
    let x_x64 = (x_x64(self, sqrt_p_x64) as u256);

    (x_x64 + cx_x64) * p_x64 + (y_x64 + cy_x64) << 64
}

/// Calculate the value of debt for the position for a given price, expressed in Y.
public fun debt_x128(self: &PositionModel, p_x128: u256): u256 {
    let p_x64 = p_x128 >> 64;
    let dx_x64 = (self.dx as u256) << 64;
    let dy_x128 = (self.dy as u256) << 128;

    // dx * p + dy
    dx_x64 * p_x64 + dy_x128
}

/// Calculate the margin level for the position at a given price.
/// If the debt is 0, returns `U128_MAX` representing infinite margin.
public fun margin_x64(self: &PositionModel, p_x128: u256): u128 {
    if (self.dx == 0 && self.dy == 0) {
        return U128_MAX
    };

    let dx_x64 = (self.dx as u256) << 64;
    let dy_x128 = (self.dy as u256) << 128;
    let cx_x64 = (self.cx as u256) << 64;
    let cy_x128 = (self.cy as u256) << 128;

    let sqrt_p_x64 = (util::sqrt_u256(p_x128) as u128);
    let p_x64 = (p_x128 >> 64) as u256;
    let x_x64 = x_x64(self, sqrt_p_x64) as u256;
    let y_x128 = (y_x64(self, sqrt_p_x64) as u256) << 64;

    let asset_value_x128 = (x_x64 + cx_x64) * p_x64 + y_x128 + cy_x128;
    let debt_value_x64 = (dx_x64 * p_x64 + dy_x128) >> 64;
    let margin_x64 = (asset_value_x128 / debt_value_x64);

    (util::min_u256(margin_x64, (U128_MAX as u256)) as u128)
}

fun mul_x64(a_x64: u128, b_x64: u128): u128 {
    ((a_x64 as u256) * (b_x64 as u256) >> 64) as u128
}

/// Calculate the price that is delta bps away from the given price (lower bound).
public fun sqrt_pl_x64(sqrt_p_x64: u128, delta_bps: u16): u128 {
    mul_x64(
            sqrt_p_x64,
            util::sqrt_u256((10000 - (delta_bps as u256)) << 128) as u128
        ) / 100
}

/// Calculate the price that is delta bps away from the given price (upper bound).
public fun sqrt_ph_x64(sqrt_p_x64: u128, delta_bps: u16): u128 {
    mul_x64(
            sqrt_p_x64,
            util::sqrt_u256((10000 + (delta_bps as u256)) << 128) as u128
        ) / 100
}

/// Calculate the `l` by which the LP position must be reduced so that the margin level goes above
/// the
/// deleverage threshold after debt repayment w.r.t. the `base_deleverage_factor`. It assumes that
/// conversion between X and Y is not done so `dx` is only repaid using available `cx` and the X
/// amounts from
/// the LP position and same for Y.
///
/// The `l` is calculated so that the position reaches a target margin level after the debt
/// repayment.
/// The target margin level is defined as the margin level that would be reached if
/// `deleverage_factor_bps`
/// of the debt is repaid at the moment margin falls below the deleverage threshold. This means that
/// the returned
/// `l` increases as the margin level decreases.
///
/// When extra collateral `cx` or `cy` is present, it is assumed that this will also be used to
/// repay debt and together
/// with returned `l` will amount to `deleverage_factor_bps` of debt repaid.
///
/// Summary:
/// - when `M >= Md` returns 0
/// - when `Md > M > 1` returns `l` such that the position reaches a constant target margin after
/// the deleverage
/// - when `1 >= M` returns `position.l`
/// - if the position has no debt, returns 0
/// - when extra collateral `cx` or `cy` is present, it is assumed that this will also be used to
/// repay debt and together
///   with returned `l` will amount to `deleverage_factor_bps` of debt repaid.
/// - if extra collateral `cx` and `cy` are enough to repay all debt, returns 0.
/// - if the target debt value cannot be repaid with position's total liquidity and extra collateral
/// (`cx` and `cy`),
///   returns `position.l`
public fun calc_max_deleverage_delta_l(
    position: &PositionModel,
    p_x128: u256,
    deleverage_margin_bps: u16,
    base_deleverage_factor_bps: u16,
): u128 {
    if (position.dx == 0 && position.dy == 0) {
        return 0
    };

    let deleverage_margin_x64 = (((deleverage_margin_bps as u256) << 64) / 10000); // 64.64
    let current_margin_x64 = margin_x64(position, p_x128) as u256; // 64.64
    let base_deleverage_factor_x64 = util::min_u256(
        ((base_deleverage_factor_bps as u256) << 64) / 10000,
        1 << 64,
    ); // 1.64

    if (current_margin_x64 >= deleverage_margin_x64) {
        return 0
    };
    if (current_margin_x64 <= (1 << 64)) {
        return position.l
    };

    let p_x64 = (p_x128 >> 64) as u128; // 64.64
    let sqrt_p_x64 = util::sqrt_u256(p_x128) as u128;

    // handle `cx` and `cy`
    let (dx_x64, dy_x64, deleverage_factor_x64) = {
        // f = (Md - M + base_deleverage_factor * (M - 1)) / (Md - 1)
        let num = (
            (deleverage_margin_x64 << 64) - (current_margin_x64 << 64) +
                base_deleverage_factor_x64 * (current_margin_x64 - (1 << 64)),
        );
        let denom = (deleverage_margin_x64 - (1 << 64));
        let target_deleverage_factor_x64 = (num / denom as u256); // 0.64

        let original_debt_val_x64 =
            (position.dx as u256) * (p_x64 as u256) + ((position.dy as u256) << 64); // 128.64

        let can_repay_x = u64::min(position.dx, position.cx);
        let can_repay_y = u64::min(position.dy, position.cy);
        let value_repaid_x64 =
            (can_repay_x as u256) * (p_x64 as u256) + ((can_repay_y as u256) << 64); // 128.64

        // f' = (D * f - R) / (D - R)
        if ((value_repaid_x64 << 64) >= original_debt_val_x64 * target_deleverage_factor_x64) {
            return 0
        };
        if (original_debt_val_x64 - value_repaid_x64 == 0) {
            return 0
        };
        let remaining_deleverage_factor_x64 = (
            (
                (original_debt_val_x64 * target_deleverage_factor_x64 - (value_repaid_x64 << 64)) /
                (original_debt_val_x64 - value_repaid_x64),
            ) as u256,
        ); // 0.64

        let dx_x64 = ((position.dx - can_repay_x) as u128) << 64;
        let dy_x64 = ((position.dy - can_repay_y) as u128) << 64;
        (dx_x64, dy_x64, remaining_deleverage_factor_x64)
    };

    let x_x64 = x_x64(position, sqrt_p_x64); // 64.64
    let y_x64 = y_x64(position, sqrt_p_x64); // 64.64
    let lp_val_x64 = (((x_x64 as u256) * (p_x64 as u256)) >> 64) + (y_x64 as u256); // 128.64
    let debt_val_x64 = (((dx_x64 as u256) * (p_x64 as u256)) >> 64) + (dy_x64 as u256); // 128.64
    let to_deleverage_val_x64 = util::divide_and_round_up_u256(
        debt_val_x64 * deleverage_factor_x64,
        1 << 64,
    ); // 128.64

    let deleverage_l = if (to_deleverage_val_x64 >= lp_val_x64) {
        position.l
    } else {
        (
            util::divide_and_round_up_u256(
                (position.l as u256) * ((to_deleverage_val_x64 << 64) / lp_val_x64),
                1 << 64,
            ) as u128,
        )
    };

    let got_x_x64 = x_by_liquidity_x64(position, sqrt_p_x64, deleverage_l);
    let got_y_x64 = y_by_liquidity_x64(position, sqrt_p_x64, deleverage_l);

    if (got_x_x64 <= dx_x64 && got_y_x64 <= dy_x64) {
        deleverage_l
    } else if (got_x_x64 >= dx_x64 && got_y_x64 >= dy_x64) {
        // this shouldn't be possible because it would imply M < 1, but for completeness,
        // find minimum `l` such that `dx` and `dy` are fully repaid
        if (got_x_x64 == dx_x64 || got_y_x64 == dy_x64) {
            return deleverage_l
        };

        let deleverage_l = if (mul_x64(got_x_x64, dy_x64) > mul_x64(got_y_x64, dx_x64)) {
            util::saturating_muldiv_round_up_u128(position.l, dy_x64, y_x64)
        } else {
            util::saturating_muldiv_round_up_u128(position.l, dx_x64, x_x64)
        };
        util::min_u128(deleverage_l, position.l)
    } else if (got_x_x64 < dx_x64) {
        // got_x < dx and got_y >= dy
        // since got_y >= dy, getting more y won't help towards repaying debt value
        // so we need to get more x
        let need_x_x64 = util::muldiv_round_up_u128(got_y_x64 - dy_x64, 1 << 64, p_x64) + got_x_x64;
        if (need_x_x64 >= x_x64 || x_x64 == 0) {
            return position.l
        };
        util::muldiv_round_up_u128(position.l, need_x_x64, x_x64)
    } else {
        // got_y < dy and got_x >= dx
        // similar to the above case, we need to get more y
        let need_y_x64 = util::muldiv_round_up_u128(got_x_x64 - dx_x64, p_x64, 1 << 64) + got_y_x64;
        if (need_y_x64 >= y_x64 || y_x64 == 0) {
            return position.l
        };
        util::muldiv_round_up_u128(position.l, need_y_x64, y_x64)
    }
}

/// Calculate the maximum factor by which the debt can be liquidated (% of debt amount).
/// 0 means no liquidation and `1 << 64` means full liquidation (Q64.64 format).
///
/// The factor is calculated so that the position is above the liquidation threshold after the
/// liquidation.
/// The target margin level is one that would be reached if `base_liq_factor_bps` of the debt is
/// repaid
/// at the moment margin falls below the liquidation threshold. This means that the returned factor
/// increases
/// as the margin level decreases.
///
/// If the margin level is below the half-way point between the liquidation threshold and the
/// critical margin level,
/// the factor is 1. The critical margin level is defined as the margin level at which the position
/// cannot be
/// liquidated without incuring bad debt (while respecting the liquidation bonus, `Mc = 1 +
/// liq_bonus`).
///
/// If the margin level is below the critical margin level, then the factor is calculated so that
/// maximum possible
/// of debt amount is liquidated while making sure there's enough collateral to cover the
/// liquidation bonus.
/// This means that as the current margin falls below the critical margin level, the factor
/// decreases.
///
/// Summary:
/// - when `M >= Ml` returns 0
/// - when `Ml > M > (Ml + Mc) / 2` returns a factor so that the position reaches a constant target
/// margin after liquidation
/// - when `(Ml + Mc) / 2 >= M >= Mc` returns 1
/// - when `Mc > M` returns a factor so that maximum possible debt is liquidated while respecting
/// the liquidation bonus
///
public fun calc_max_liq_factor_x64(
    current_margin_x64: u128,
    liq_margin_bps: u16,
    liq_bonus_bps: u16,
    base_liq_factor_bps: u16,
): u128 {
    let current_margin_x64 = current_margin_x64 as u256;
    let liq_margin_x64 = ((liq_margin_bps as u256) << 64) / 10000;
    let crit_margin_x64 = ((10000 << 64) + ((liq_bonus_bps as u256) << 64)) / 10000;
    let base_liq_factor_x64 = ((base_liq_factor_bps as u256) << 64) / 10000;

    // for sanity, normally `liq_margin_x64 > crit_margin_x64`
    let liq_margin_x64 = util::max_u256(liq_margin_x64, crit_margin_x64);
    let base_liq_factor_x64 = util::min_u256(base_liq_factor_x64, 1 << 64);

    if (current_margin_x64 >= liq_margin_x64) {
        0
    } else if (current_margin_x64 < crit_margin_x64) {
        // M / Mc
        ((current_margin_x64 << 64) / crit_margin_x64) as u128
    } else if (liq_margin_x64 - current_margin_x64 >= current_margin_x64 - crit_margin_x64) {
        // M < (Ml + Mc) / 2
        1 << 64
    } else {
        // (Ml - M + base_liq_factor * (M - Mc)) / (Ml - Mc)
        let num = (
            (liq_margin_x64 << 64) - (current_margin_x64 << 64) +
                base_liq_factor_x64 * (current_margin_x64 - crit_margin_x64),
        );
        let denom = (liq_margin_x64 - crit_margin_x64);
        (num / denom) as u128
    }
}

/// Returns `true` if the position is "fully deleveraged". A position is considered fully
/// deleveraged
/// when all the liquidity has been withdrawn from the AMM pool and the debt that can be repaid
/// directly
/// (i.e. cx -> dx, cy -> dy) has been repaid.
/// If this is true, then `dx > 0` implies `cx = 0` and `dy > 0` implies `cy = 0`. Also if `dx > 0
/// && dy > 0`
/// then `cx == 0 && cy == 0`.
public fun is_fully_deleveraged(position: &PositionModel): bool {
    if (position.l > 0) {
        return false
    };
    if (position.dx > 0 && position.cx > 0) {
        return false
    };
    if (position.dy > 0 && position.cy > 0) {
        return false
    };
    true
}

/// Returns `true` if position's margin is below the given threshold.
public fun margin_below_threshold(
    position: &PositionModel,
    p_x128: u256,
    margin_threshold_bps: u16,
): bool {
    let current_margin_x64 = margin_x64(position, p_x128);
    let threshold_margin_x64 = ((margin_threshold_bps as u128) << 64) / 10000;
    current_margin_x64 < threshold_margin_x64
}

/// Liquidates the collateral X from the position for the given `repayment_amt_y`.
/// Returns `(repayment_amt_y, reward_amt_x)` where `repayment_amt_y` is the amount of Y repaid
/// (up to given `max_repayment_amt_y`) and `reward_amt_x` is the amount of X returned to the
/// liquidator.
///
/// Note:
/// - returns `(0, 0)` when the position can't be liquidated:
///   - it's not below the liquidation threshold
///   - it's not "fully deleveraged"
///   - `cx == 0`
/// - the position is liquidated so that the margin level is above the liquidation threshold after
/// the liquidation
///   if possible for the the given `max_repayment_amt_y` and available collateral.
/// - always respects the liquidation bonus, even if there's not enough collateral to cover a full
/// liquidation
/// - never aborts
///
/// See documentation for `calc_max_liq_factor_x64` for more details on how the liquidation factor
/// is calculated.
///
public fun calc_liquidate_col_x(
    position: &PositionModel,
    p_x128: u256,
    max_repayment_amt_y: u64,
    liq_margin_bps: u16,
    liq_bonus_bps: u16,
    base_liq_factor_bps: u16,
): (u64, u64) {
    if (!margin_below_threshold(position, p_x128, liq_margin_bps)) {
        return (0, 0)
    };
    if (!is_fully_deleveraged(position)) {
        return (0, 0)
    };
    if (position.cx == 0 || max_repayment_amt_y == 0) {
        return (0, 0)
    };

    // after the above, we know that `cx > 0`, `dx == 0`,`dy > 0` and `cy == 0`
    let p_x64 = p_x128 >> 64; // 64.64
    let liq_bonus_x64 = ((liq_bonus_bps as u256) << 64) / 10000; // 16.64
    let debt_value_x64 = (position.dy as u256) << 64; // 64.64
    let asset_value_x64 = (position.cx as u256) * p_x64; // 128.64
    let margin_x64 = util::min_u256(
        (asset_value_x64 << 64) / debt_value_x64,
        U128_MAX as u256,
    ); // 64.64

    // calc repayment value
    let max_repayment_value_x64 = (max_repayment_amt_y as u256) << 64; // 64.64
    let possible_repayment_factor_x64 = (max_repayment_value_x64 << 64) / debt_value_x64; // 64.64

    let max_liq_factor_x64 =
        calc_max_liq_factor_x64(
            (margin_x64 as u128),
            liq_margin_bps,
            liq_bonus_bps,
            base_liq_factor_bps,
        ) as u256; // 64.64
    let liq_factor_x64 = util::min_u256(possible_repayment_factor_x64, max_liq_factor_x64); // 64.64
    let repayment_value_x64 = (liq_factor_x64 * debt_value_x64) >> 64; // 64.64
    let repayment_value_with_bonus_x64 = (repayment_value_x64 * ((1 << 64) + liq_bonus_x64)) >> 64; // 81.64

    // calc repayment and reward amt
    let repayment_amt_y =
        util::min_u256(
            util::divide_and_round_up_u256(repayment_value_x64, 1 << 64),
            max_repayment_amt_y as u256,
        ) as u64;
    let reward_amt_x =
        util::min_u256(
            util::divide_and_round_up_u256(
                repayment_value_with_bonus_x64 * (position.cx as u256),
                asset_value_x64,
            ),
            position.cx as u256,
        ) as u64;

    (repayment_amt_y, reward_amt_x)
}

/// Liquidates the collateral Y from the position for the given `repayment_amt_x`.
/// Returns `(repayment_amt_x, reward_amt_y)` where `repayment_amt_x` is the amount of X repaid
/// (up to given `max_repayment_amt_x`) and `reward_amt_y` is the amount of Y returned to the
/// liquidator.
///
/// Note:
/// - returns `(0, 0)` when the position can't be liquidated:
///   - it's not below the liquidation threshold
///   - it's not "fully deleveraged"
///   - `cy == 0`
/// - the position is liquidated so that the margin level is above the liquidation threshold after
/// the liquidation
///   if possible for the the given `max_repayment_amt_x` and available collateral.
/// - always respects the liquidation bonus, even if there's not enough collateral to cover a full
/// liquidation
/// - never aborts
///
/// See documentation for `calc_max_liq_factor_x64` for more details on how the liquidation factor
/// is calculated.
///
public fun calc_liquidate_col_y(
    position: &PositionModel,
    p_x128: u256,
    max_repayment_amt_x: u64,
    liq_margin_bps: u16,
    liq_bonus_bps: u16,
    base_liq_factor_bps: u16,
): (u64, u64) {
    if (!margin_below_threshold(position, p_x128, liq_margin_bps)) {
        return (0, 0)
    };
    if (!is_fully_deleveraged(position)) {
        return (0, 0)
    };
    if (position.cy == 0 || max_repayment_amt_x == 0) {
        return (0, 0)
    };

    // after the above, we know that `cy > 0`, `dy == 0`,`dx > 0` and `cx == 0`
    let p_x64 = p_x128 >> 64; // 64.64
    let liq_bonus_x64 = ((liq_bonus_bps as u256) << 64) / 10000; // 16.64
    let debt_value_x64 = (position.dx as u256) * p_x64; // 128.64
    let asset_value_x64 = (position.cy as u256) << 64; // 64.64
    let margin_x64 = util::min_u256(
        (asset_value_x64 << 64) / debt_value_x64,
        (U128_MAX as u256),
    ); // 64.64

    // calc repayment value
    let possible_repayment_factor_x64 =
        ((max_repayment_amt_x as u256) << 64) / (position.dx as u256); // 64.64

    let max_liq_factor_x64 = (
        calc_max_liq_factor_x64(
            (margin_x64 as u128),
            liq_margin_bps,
            liq_bonus_bps,
            base_liq_factor_bps,
        ) as u256,
    ); // 64.64
    let liq_factor_x64 = util::min_u256(possible_repayment_factor_x64, max_liq_factor_x64); // 64.64
    let repayment_value_x64 = (liq_factor_x64 * debt_value_x64) >> 64; // 64.64
    let repayment_value_with_bonus_x64 = (repayment_value_x64 * ((1 << 64) + liq_bonus_x64)) >> 64; // 81.64

    // calc repayment and reward amt
    let repayment_amt_x =
        util::min_u256(
            util::divide_and_round_up_u256(liq_factor_x64 * (position.dx as u256), 1 << 64),
            max_repayment_amt_x as u256,
        ) as u64;
    let reward_amt_y =
        util::min_u256(
            util::divide_and_round_up_u256(repayment_value_with_bonus_x64, 1 << 64),
            position.cy as u256,
        ) as u64;

    (repayment_amt_x, reward_amt_y)
}

#[test]
fun test_margin() {
    let sqrt_pa_x64: u128 = 17499818628114608849; // ~0.9
    let sqrt_pb_x64: u128 = 26086568254500584001; // ~2
    let l: u128 = 3902203900; // x = 426748400; y = 1077311878
    let p_x128: u256 = (15 << 128) / 10; // 1.5

    // without cx, dx
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx: 0,
        cy: 0,
        dx: 384073560,
        dy: 969580690,
    };
    assert!(margin_x64(&position, p_x128) == 20496382321088983824, 0);
    //assert!(margin_x64(&position, p_x128, true) == 20496382321088983824, 0);

    // with cx, dx
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx: 10000000,
        cy: 10000000,
        dx: 394073560,
        dy: 979580690,
    };
    assert!(margin_x64(&position, p_x128) == 20463759128363113475, 0);
    // assert!(margin_x64(&position, p_x128, true) == 20496382321088983824, 0);

    // debt 0
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx: 0,
        cy: 0,
        dx: 0,
        dy: 0,
    };
    assert!(margin_x64(&position, p_x128) == U128_MAX, 0);
    // assert!(margin_x64(&position, p_x128, true) == U128_MAX, 0);

    // debt 0, returned from cx, cy
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx: 1000000000,
        cy: 1000000000,
        dx: 384073560,
        dy: 969580690,
    };
    assert!(margin_x64(&position, p_x128) == 50332138166986516813, 0);
    // assert!(margin_x64(&position, p_x128, true) == U128_MAX, 0);
}

#[test]
fun test_calc_max_deleverage_delta_l() {
    let sqrt_pa_x64: u128 = 17499818628114608849; // ~0.9
    let sqrt_pb_x64: u128 = 26086568254500584001; // ~2
    let l: u128 = 3902203900; // x = 426748400; y = 1077311878
    let deleverage_margin_bps = 11500; // 1.15

    // dx == 0 && dy == 0
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx: 0,
        cy: 0,
        dx: 0,
        dy: 0,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        2000,
    );
    assert!(delta_l == 0, 0);

    // M > Md
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx: 0,
        cy: 0,
        dx: 384073560,
        dy: 969580690,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        11000,
        2000,
    );
    assert!(delta_l == 0, 0);

    // M < 1
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l: 2902203900,
        cx: 0,
        cy: 0,
        dx: 384073560,
        dy: 969580690,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        2000,
    );
    assert!(delta_l == 2902203900, 0);

    // got_x <= dx && got_y <= dy
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx: 0,
        cy: 0,
        dx: 384073560,
        dy: 969580690,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        2000,
    );
    assert!(delta_l == 1430808079, 0);

    // got_x < dx && got_y >= dy
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l: 1502203900,
        cx: 0,
        cy: 0,
        dx: 384073560,
        dy: 9580690,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        2000,
    );
    assert!(delta_l == 1058695541, 0);

    // got_y < dy && got_x >= dx
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l: 2502203900,
        cx: 0,
        cy: 0,
        dx: 4073560,
        dy: 969580690,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        2000,
    );
    assert!(delta_l == 1086064359, 0);

    // col can repay all
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx: 384073560,
        cy: 969580690,
        dx: 384073560,
        dy: 969580690,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        2000,
    );
    assert!(delta_l == 0, 0);

    // col can repay some
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l: 3822039000,
        cx: 10000000,
        cy: 20000000,
        dx: 384073560,
        dy: 969580690,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        2000,
    );
    assert!(delta_l == 1354702666, 0);

    // col can repay some, 100%
    let position = PositionModel {
        sqrt_pa_x64,
        sqrt_pb_x64,
        l: 3822039000,
        cx: 10000000,
        cy: 20000000,
        dx: 384073560,
        dy: 969580690,
    };
    let p_x128: u256 = (15 << 128) / 10; // 1.5
    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        10000,
    );
    assert!(delta_l == 3439540163, 0);

    // no bitwise shift overflow on target_deleverage_factor_x64 calculation
    let position = PositionModel {
        sqrt_pa_x64: 18441211157107643397,
        sqrt_pb_x64: 18443055278223354162,
        l: 82237462179,
        cx: 10000,
        cy: 10000,
        dx: 3643197,
        dy: 3579706,
    };
    let p_x128 = 340174455799473328521578011296941203462;
    let deleverage_margin_bps = 20000;
    let base_deleverage_factor_bps = 5000;

    let delta_l = calc_max_deleverage_delta_l(
        &position,
        p_x128,
        deleverage_margin_bps,
        base_deleverage_factor_bps,
    );
    assert!(delta_l == 82237462179);
}

#[test]
fun test_is_fully_deleveraged() {
    // not fully deleveraged (l > 0)
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 1,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    assert!(is_fully_deleveraged(&position) == false, 0);

    // not fully deleveraged (cx > 0 && dx > 0)
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 1,
        dy: 10000,
    };
    assert!(is_fully_deleveraged(&position) == false, 0);

    // not fully deleveraged (cy > 0 && dy > 0)
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 1,
        dx: 0,
        dy: 10000,
    };
    assert!(is_fully_deleveraged(&position) == false, 0);

    // ok #1
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    assert!(is_fully_deleveraged(&position) == true, 0);

    // ok #2
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 1000,
        dx: 1000,
        dy: 0,
    };
    assert!(is_fully_deleveraged(&position) == true, 0);
}

#[test]
fun test_calc_max_liq_factor() {
    let liq_margin_bps = 12500; // 1.25
    let liq_bonus_bps = 750; // 0.075
    let base_liq_factor_bps = 3500; // 0.35

    // M > liq_margin
    let current_margin_x64 = (126 << 64) / 100;
    let max_liq_factor_x64 = calc_max_liq_factor_x64(
        current_margin_x64,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(max_liq_factor_x64 == 0, 0);

    // M = liq_margin
    let current_margin_x64 = ((liq_margin_bps as u128) << 64) / 10000;
    let max_liq_factor_x64 = calc_max_liq_factor_x64(
        current_margin_x64,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(max_liq_factor_x64 == 0, 0);

    // Ml > M > (Ml + Mc) / 2
    let current_margin_x64 = (120 << 64) / 100;
    let max_liq_factor_x64 = calc_max_liq_factor_x64(
        current_margin_x64,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(max_liq_factor_x64 == 9882184325201545508, 0);

    // M < (Ml + Mc) / 2
    let current_margin_x64 = (11625 << 64) / 10000;
    let max_liq_factor_x64 = calc_max_liq_factor_x64(
        current_margin_x64,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(max_liq_factor_x64 == 1 << 64, 0);

    // M = Mc
    let current_margin_x64 = ((10000 << 64) + ((liq_bonus_bps as u128) << 64)) / 10000;
    let max_liq_factor_x64 = calc_max_liq_factor_x64(
        current_margin_x64,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(max_liq_factor_x64 == 1 << 64, 0);

    // M < Mc
    let current_margin_x64 = (104 << 64) / 100;
    let max_liq_factor_x64 = calc_max_liq_factor_x64(
        current_margin_x64,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(max_liq_factor_x64 == 17846152406193426679, 0);
}

#[test]
fun test_calc_liquidate_col_x() {
    let liq_margin_bps = 12500; // 1.25
    let liq_bonus_bps = 750; // 0.075
    let base_liq_factor_bps = 3500; // 0.35

    // not below liq. margin
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (126 << 128) / 100;
    let max_repayment_amt_y = 12000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 0, 0);
    assert!(reward_amt_x == 0, 0);

    // not fully deleveraged (l > 0)
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 1,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (120 << 128) / 100;
    let max_repayment_amt_y = 12000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 0, 0);
    assert!(reward_amt_x == 0, 0);

    // no cx
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (120 << 128) / 100;
    let max_repayment_amt_y = 12000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 0, 0);
    assert!(reward_amt_x == 0, 0);

    // max_repayment_amt_y = 0
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (120 << 128) / 100;
    let max_repayment_amt_y = 0;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 0, 0);
    assert!(reward_amt_x == 0, 0);

    // M < Ml, max_repayment_amt_y can cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (120 << 128) / 100; // 1.2
    let max_repayment_amt_y = 50000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 5358, 0);
    assert!(reward_amt_x == 4800, 0);

    // M < Ml, max_repayment_amt_y can't cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (120 << 128) / 100; // 1.2
    let max_repayment_amt_y = 3000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 3000, 0);
    assert!(reward_amt_x == 2688, 0);

    // M < (Ml + Mc) / 2, max_repayment_amt_y can cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (111 << 128) / 100; // 1.11
    let max_repayment_amt_y = 10000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 10000, 0);
    assert!(reward_amt_x == 9685, 0);

    // M < (Ml + Mc) / 2, max_repayment_amt_y can't cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (111 << 128) / 100; // 1.11
    let max_repayment_amt_y = 5000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 5000, 0);
    assert!(reward_amt_x == 4843, 0);

    // M < Mc, max_repayment_amt_y can cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (104 << 128) / 100; // 1.04
    let max_repayment_amt_y = 50000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 9675, 0);
    assert!(reward_amt_x == 10000, 0);

    // M < Mc, max_repayment_amt_y can't cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 10000,
        cy: 0,
        dx: 0,
        dy: 10000,
    };
    let p_x128 = (104 << 128) / 100; // 1.04
    let max_repayment_amt_y = 5000;
    let (repayment_amt_y, reward_amt_x) = calc_liquidate_col_x(
        &position,
        p_x128,
        max_repayment_amt_y,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_y == 5000, 0);
    assert!(reward_amt_x == 5169, 0);
}

#[test]
fun test_calc_liquidate_col_y() {
    let liq_margin_bps = 12500; // 1.25
    let liq_bonus_bps = 750; // 0.075
    let base_liq_factor_bps = 3500; // 0.35

    // not below liq. margin
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (6 << 128) / 10; // 0.6
    let max_repayment_amt_x = 12000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 0, 0);
    assert!(reward_amt_y == 0, 0);

    // not fully deleveraged (l > 0)
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 1,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (82 << 128) / 100; // 0.82
    let max_repayment_amt_x = 12000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 0, 0);
    assert!(reward_amt_y == 0, 0);

    // no cy
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 0,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (82 << 128) / 100; // 0.82
    let max_repayment_amt_x = 12000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 0, 0);
    assert!(reward_amt_y == 0, 0);

    // max_repayment_amt_x = 0
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (82 << 128) / 100; // 0.82
    let max_repayment_amt_x = 0;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 0, 0);
    assert!(reward_amt_y == 0, 0);

    // M < Ml, max_repayment_amt_x can cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (82 << 128) / 100; // 0.82
    let max_repayment_amt_x = 50000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 4633, 0);
    assert!(reward_amt_y == 4084, 0);

    // M < Ml, max_repayment_amt_x can't cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (82 << 128) / 100; // 0.82
    let max_repayment_amt_x = 3000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 3000, 0);
    assert!(reward_amt_y == 2645, 0);

    // M < (Ml + Mc) / 2, max_repayment_amt_x can cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (9 << 128) / 10; // 0.9
    let max_repayment_amt_x = 10000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 10000, 0);
    assert!(reward_amt_y == 9675, 0);

    // M < (Ml + Mc) / 2, max_repayment_amt_x can't cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (9 << 128) / 10; // 0.9
    let max_repayment_amt_x = 5000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 5000, 0);
    assert!(reward_amt_y == 4838, 0);

    // M < Mc, max_repayment_amt_x can cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (1 << 128); // 1
    let max_repayment_amt_x = 50000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 9303, 0);
    assert!(reward_amt_y == 10000, 0);

    // M < Mc, max_repayment_amt_x can't cover
    let position = PositionModel {
        sqrt_pa_x64: 0,
        sqrt_pb_x64: 0,
        l: 0,
        cx: 0,
        cy: 10000,
        dx: 10000,
        dy: 0,
    };
    let p_x128 = (1 << 128) / 1; // 1
    let max_repayment_amt_x = 5000;
    let (repayment_amt_x, reward_amt_y) = calc_liquidate_col_y(
        &position,
        p_x128,
        max_repayment_amt_x,
        liq_margin_bps,
        liq_bonus_bps,
        base_liq_factor_bps,
    );
    assert!(repayment_amt_x == 5000, 0);
    assert!(reward_amt_y == 5375, 0);
}

// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Geometry of a CLMM LP position: price range bounds and liquidity.
/// A micro-leaf shared by position orchestration and model math.
module kai_leverage::lp_shape_clmm;

/// The LP shape's price range bounds are not strictly increasing.
const EInvalidLpShape: u64 = 0;

/// Geometry of a CLMM LP position: price range bounds and liquidity.
public struct LpShape has copy, drop {
    sqrt_pa_x64: u128,
    sqrt_pb_x64: u128,
    l: u128,
}

/// Create an `LpShape`, asserting the price range bounds are ordered.
public(package) fun new(sqrt_pa_x64: u128, sqrt_pb_x64: u128, l: u128): LpShape {
    assert!(sqrt_pa_x64 < sqrt_pb_x64, EInvalidLpShape);
    LpShape { sqrt_pa_x64, sqrt_pb_x64, l }
}

/// Lower bound price sqrt in Q64.64.
public(package) fun sqrt_pa_x64(self: &LpShape): u128 {
    self.sqrt_pa_x64
}

/// Upper bound price sqrt in Q64.64.
public(package) fun sqrt_pb_x64(self: &LpShape): u128 {
    self.sqrt_pb_x64
}

/// LP position liquidity.
public(package) fun l(self: &LpShape): u128 {
    self.l
}

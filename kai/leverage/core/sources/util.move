// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Utility functions for mathematical operations and time handling.
module kai_leverage::util;

use sui::clock::{Self, Clock};

/// Multiply and divide u64 values.
public fun muldiv(a: u64, b: u64, c: u64): u64 {
    (((a as u128) * (b as u128)) / (c as u128)) as u64
}

/// Multiply and divide with rounding up.
public fun muldiv_round_up(a: u64, b: u64, c: u64): u64 {
    divide_and_round_up_u128(
        (a as u128) * (b as u128),
        c as u128,
    ) as u64
}

/// Multiply and divide u128 values.
public fun muldiv_u128(a: u128, b: u128, c: u128): u128 {
    (((a as u256) * (b as u256)) / (c as u256)) as u128
}

/// Multiply and divide u128 values with rounding up.
public fun muldiv_round_up_u128(a: u128, b: u128, c: u128): u128 {
    divide_and_round_up_u256(
        (a as u256) * (b as u256),
        c as u256,
    ) as u128
}

/// Saturating multiply and divide with rounding up.
public fun saturating_muldiv_round_up_u128(a: u128, b: u128, c: u128): u128 {
    let res = divide_and_round_up_u256(
        (a as u256) * (b as u256),
        (c as u256),
    );
    if (res > (1 << 128) - 1) {
        ((1 << 128) - 1) as u128
    } else {
        res as u128
    }
}

/// Divide with rounding up for 128-bit values.
public fun divide_and_round_up_u128(a: u128, b: u128): u128 {
    std::macros::num_divide_and_round_up!(a, b)
}

/// Divide with rounding up for u256 values.
public fun divide_and_round_up_u256(a: u256, b: u256): u256 {
    std::macros::num_divide_and_round_up!(a, b)
}

/// Calculate absolute difference between two numbers.
public fun abs_diff(a: u64, b: u64): u64 {
    if (a > b) a - b else b - a
}

/// Get minimum of two 128-bit values.
public fun min_u128(a: u128, b: u128): u128 {
    if (a < b) a else b
}

/// Get maximum of two 128-bit values.
public fun max_u128(a: u128, b: u128): u128 {
    if (a > b) a else b
}

/// Get minimum of two 256-bit values.
public fun min_u256(a: u256, b: u256): u256 {
    if (a < b) a else b
}

/// Get maximum of two 256-bit values.
public fun max_u256(a: u256, b: u256): u256 {
    if (a > b) a else b
}

/// Calculate base-2 logarithm of a 256-bit value.
public fun log2_u256(mut x: u256): u8 {
    let mut result = 0;
    if (x >> 128 > 0) {
        x = x >> 128;
        result = result + 128;
    };

    if (x >> 64 > 0) {
        x = x >> 64;
        result = result + 64;
    };

    if (x >> 32 > 0) {
        x = x >> 32;
        result = result + 32;
    };

    if (x >> 16 > 0) {
        x = x >> 16;
        result = result + 16;
    };

    if (x >> 8 > 0) {
        x = x >> 8;
        result = result + 8;
    };

    if (x >> 4 > 0) {
        x = x >> 4;
        result = result + 4;
    };

    if (x >> 2 > 0) {
        x = x >> 2;
        result = result + 2;
    };

    if (x >> 1 > 0) result = result + 1;

    result
}

/// Calculate square root of a 256-bit value.
public fun sqrt_u256(x: u256): u256 {
    if (x == 0) return 0;

    let mut result = 1 << ((log2_u256(x) >> 1) as u8);

    result = (result + x / result) >> 1;
    result = (result + x / result) >> 1;
    result = (result + x / result) >> 1;
    result = (result + x / result) >> 1;
    result = (result + x / result) >> 1;
    result = (result + x / result) >> 1;
    result = (result + x / result) >> 1;

    min_u256(result, x / result)
}

/// Get current clock timestamp in seconds.
public fun timestamp_sec(clock: &Clock): u64 {
    clock::timestamp_ms(clock) / 1000
}

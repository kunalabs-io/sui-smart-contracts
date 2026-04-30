# Integer Library

A formally verified library of common unsigned and signed operations.

## Overview

We have formally verified all non-trivial functions of this library using the Sui Prover. Verification was performed by [Asymptotic](https://asymptotic.tech) in partnership with [Bluefin](https://bluefin.io).

This library is a fork the widely-used [integer-mate library](https://github.com/CetusProtocol/integer-mate) but with a focus on security and correctness, and backed by full formal verification. 

The verification effort covers **126 functions** across multiple integer types (u64, u128, u256, i32, i64, i128). The only public functions not verified are wrappers-unwrappers of signed integers, as they are both trivial and needed as part of the verification itself.

## Key Highlights

### 🔍 Security Findings

1. **Cetus Protocol Vulnerability Discovery**: After the Cetus protocol exploit we checked both the exitance of the bug and the correctness of the fix using formal verification. [See our detailed analysis](https://x.com/AsymptoticTech/status/1925745737243013596).

2. **Integer Library Bug**: During the initial formal verification of the library we discovered and reported a new bug in the signed `::sub` function that could cause incorrect results under specific conditions. We coordinated with the Sui Foundation for an ecosystem-wide fix. [See our report](https://x.com/AsymptoticTech/status/1932152623316230630). The buggy version is preserved as `sub_buggy` in the codebase for educational purposes.

### 📊 Verification Coverage

- **Total Functions Verified**: 126
- **Integer Types Covered**: u64, u128, u256, I32, I64, I128
- **Operation Categories**: 
  - Arithmetic operations (add, sub, mul, div, mod)
  - Bitwise operations (shl, shr, and, or, not)
  - Overflow-safe variants (wrapping, checked, overflowing)
  - Comparison operations (eq, lt, gt, lte, gte)
  - Type conversions and utility functions

### 🎯 What We Proved

Through formal verification, we established comprehensive mathematical guarantees for every possible input:

**Functional Correctness:**
- **Exact computation**: Every function produces the mathematically correct result for all valid inputs
- **Abort conditions**: Precise specification of when functions abort (division by zero, overflow in non-wrapping functions, shift amounts out of bounds)
- **No undefined behavior**: Every input produces either a well-defined result or a well-defined abort

**Overflow Behavior:**
- **Wrapping semantics**: `wrapping_*` functions correctly implement modular arithmetic (mod 2^n)
- **Overflow detection**: `overflowing_*` functions correctly return both wrapped result and overflow flag
- **Checked operations**: Functions without `wrapping_` abort on overflow, preventing silent errors
- **Full precision**: Operations like `full_mul` correctly compute results in higher precision (e.g., 256-bit product from two 128-bit inputs)

**Integer Type Properties:**
- **Two's complement correctness**: Signed integer operations correctly implement two's complement arithmetic
- **Sign handling**: Negation, absolute value, and sign detection work correctly for all values including boundary cases
- **Type conversions**: Conversions between integer types correctly preserve values when in range and abort when out of range
- **Boundary correctness**: Operations handle MIN/MAX values correctly (e.g., `abs(MIN_I128)` correctly aborts)

**Bit Operations:**
- **Shift correctness**: Left and right shifts produce correct results with proper bounds checking
- **Arithmetic right shift**: Signed right shifts correctly extend the sign bit
- **Bitwise operations**: AND, OR, NOT operations compute correct bit-level results

**Division and Modulo:**
- **Division modes**: Correct implementation of floor, ceiling, and truncating division
- **Zero handling**: All division operations correctly abort on division by zero
- **Remainder correctness**: `div_mod` returns quotient and remainder satisfying `dividend = quotient * divisor + remainder`

### ⚠️ Notable Patterns

Several functions exhibit important behavioral patterns that users should be aware of:
- Functions with `wrapping_` prefix perform modular arithmetic and never abort
- Functions with `checked_` prefix return overflow indicators
- Some shift operations use modular arithmetic which can be unintuitive (see warnings in function descriptions)
- Certain operations require custom prover configurations due to complexity

**✅ indicates that the specification is proved. All functions have been proved.**

## How to replicate the results

1. Install Sui Prover
2. Run `sui-prover` in the `specs` directory
3. Run `sui-prover --no-bv-int-encoding` in the `specs-bv` directory

## `i128.move`

### `wrapping_add(num1: I128, num2: I128): I128`
 ✅ Computes `num1 + num2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `shr(v: I128, shift: u8): I128`
 ✅ Computes arithmetic right shift `v >> shift`.\
 ⏮️ The function aborts unless `shift < 128`.


## `i32.move`

### `wrapping_add(num1: I32, num2: I32): I32`
 ✅ Computes `num1 + num2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `shr(v: I32, shift: u8): I32`
 ✅ Computes arithmetic right shift `v >> shift`.\
 ⏮️ The function aborts unless `shift < 32`.


## `i64.move`

### `wrapping_add(num1: I64, num2: I64): I64`
 ✅ Computes `num1 + num2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `shr(v: I64, shift: u8): I64`
 ✅ Computes arithmetic right shift `v >> shift`.\
 ⏮️ The function aborts unless `shift < 64`.


## `full_math_u128_specs.move`

### `full_mul(num1: u128, num2: u128): u256`
 ✅ Computes `num1 * num2` using 256-bit arithmetic for intermediate product computation.\
 ⏮️ The function does not abort.

### `mul_div_floor(num1: u128, num2: u128, denom: u128): u128`
 ✅ Computes `(num1 * num2) / denom` with floor division using 256-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u128`.

### `mul_div_round(num1: u128, num2: u128, denom: u128): u128`
 ✅ Computes `(num1 * num2) / denom` with rounding division using 256-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u128`.

### `mul_div_ceil(num1: u128, num2: u128, denom: u128): u128`
 ✅ Computes `(num1 * num2) / denom` with ceiling division using 256-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u128`.

### `mul_shr(num1: u128, num2: u128, shift: u8): u128`
 ✅ Computes `(num1 * num2) >> shift` using 256-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `shift <= 255` and the result fits in `u128`.

### `mul_shl(num1: u128, num2: u128, shift: u8): u128`
 ✅ Computes `(num1 * num2) << shift` using 256-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `shift <= 255` and the result fits in `u128`.\
 ⚠️ Note that due to `<<` not aborting when losing significant bits, the actual result is `((num1 * num2) << shift) mod 2^256` (note the modulo), which can be unintuitive to users.


## `full_math_u64_specs.move`

### `full_mul(num1: u64, num2: u64): u128`
 ✅ Computes `num1 * num2` using 128-bit arithmetic for intermediate product computation.\
 ⏮️ The function does not abort.

### `mul_div_floor(num1: u64, num2: u64, denom: u64): u64`
 ✅ Computes `(num1 * num2) / denom` with floor division using 128-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u64`.

### `mul_div_round(num1: u64, num2: u64, denom: u64): u64`
 ✅ Computes `(num1 * num2) / denom` with rounding division using 128-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u64`.

### `mul_div_ceil(num1: u64, num2: u64, denom: u64): u64`
 ✅ Computes `(num1 * num2) / denom` with ceiling division using 128-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `denom > 0` and the result fits in `u64`.

### `mul_shr(num1: u64, num2: u64, shift: u8): u64`
 ✅ Computes `(num1 * num2) >> shift` using 128-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `shift <= 127` and the result fits in `u64`.

### `mul_shl(num1: u64, num2: u64, shift: u8): u64`
 ✅ Computes `(num1 * num2) << shift` using 128-bit arithmetic for intermediate product computation.\
 ⏮️ The function aborts unless `shift <= 127` and the result fits in `u64`.\
 ⚠️ Note that due to `<<` not aborting when losing significant bits, the actual result is `((num1 * num2) << shift) mod 2^128` (note the modulo), which can be unintuitive to users.


## `i128_specs.move`

### `zero(): I128`
 ✅ Computes `0` as an `I128`.\
 ⏮️ The function does not abort.

### `from(v: u128): I128`
 ✅ Computes an `I128` from a `u128`.\
 ⏮️ The function aborts when the value exceeds `I128::MAX`.

### `neg_from(v: u128): I128`
 ✅ Computes an `I128` from the negation of a `u128`.\
 ⏮️ The function aborts when the result does not fit in `I128`.

### `neg(v: I128): I128`
 ✅ Computes the negation of an `I128`.\
 ⏮️ The function aborts when the input is `MIN_I128`, that is `-2^127`.

### `wrapping_add(num1: I128, num2: I128): I128`
 ✅ Computes `num1 + num2` with wrapping overflow.\
 ⏮️ The function does not abort.\
 ⚠️ Proved in a separate package as it requires a custom prover configuration.

### `add(num1: I128, num2: I128): I128`
 ✅ Computes `num1 + num2`.\
 ⏮️ The function aborts when the result does not fit in `I128`.

### `overflowing_add(num1: I128, num2: I128): (I128, bool)`
 ✅ Computes `num1 + num2` and returns a flag indicating overflow.\
 ⏮️ The function does not abort.

### `wrapping_sub(num1: I128, num2: I128): I128`
 ✅ Computes `num1 - num2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `sub(num1: I128, num2: I128): I128`
 ✅ Computes `num1 - num2`.\
 ⏮️ The function aborts when the result does not fit in `I128`.

### `overflowing_sub(num1: I128, num2: I128): (I128, bool)`
 ✅ Computes `num1 - num2` and returns a flag indicating overflow.\
 ⏮️ The function does not abort.

### `mul(num1: I128, num2: I128): I128`
 ✅ Computes `num1 * num2`.\
 ⏮️ The function aborts when the result does not fit in `I128`.

### `div(num1: I128, num2: I128): I128`
 ✅ Computes `num1 / num2` with truncation.\
 ⏮️ The function aborts when the result does not fit in `I128`, or the denominator is zero.

### `abs(v: I128): I128`
 ✅ Computes the absolute value of an `I128`.\
 ⏮️ The function aborts when the input is `MIN_I128`, that is `-2^127`.

### `abs_u128(v: I128): u128`
 ✅ Computes the absolute value of an `I128` as a `u128`.\
 ⏮️ The function does not abort.

### `shl(v: I128, shift: u8): I128`
 ✅ Computes `v << shift`.\
 ⏮️ The function aborts unless `shift < 128`.

### `shr(v: I128, shift: u8): I128`
 ✅ Computes `v >> shift`.\
 ⏮️ The function aborts unless `shift < 128`.\
 ⚠️ Proved in a separate package as it requires a custom prover configuration.

### `as_i64(v: I128): integer_mate::i64::I64`
 ✅ Converts an `I128` to an `I64`.\
 ⏮️ The function aborts when the value does not fit in `I64`.

### `as_i32(v: I128): integer_mate::i32::I32`
 ✅ Converts an `I128` to an `I32`.\
 ⏮️ The function aborts when the value does not fit in `I32`.

### `sign(v: I128): u8`
 ✅ Returns `1` if the input is negative, `0` otherwise.\
 ⏮️ The function does not abort.

### `is_neg(v: I128): bool`
 ✅ Returns `true` if the input is negative, `false` otherwise.\
 ⏮️ The function does not abort.

### `cmp(num1: I128, num2: I128): u8`
 ✅ Compares two `I128`s.\
 ⏮️ The function does not abort.

### `eq(num1: I128, num2: I128): bool`
 ✅ Compares two `I128`s, returns `true` if they are equal, `false` otherwise.\
 ⏮️ The function does not abort.

### `gt(num1: I128, num2: I128): bool`
 ✅ Compares two `I128`s, returns `true` if the first is greater than the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `gte(num1: I128, num2: I128): bool`
 ✅ Compares two `I128`s, returns `true` if the first is greater than or equal to the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `lt(num1: I128, num2: I128): bool`
 ✅ Compares two `I128`s, returns `true` if the first is less than the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `lte(num1: I128, num2: I128): bool`
 ✅ Compares two `I128`s, returns `true` if the first is less than or equal to the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `or(num1: I128, num2: I128): I128`
 ✅ Computes the bitwise OR of two `I128`s.\
 ⏮️ The function does not abort.

### `and(num1: I128, num2: I128): I128`
 ✅ Computes the bitwise AND of two `I128`s.\
 ⏮️ The function does not abort.

### `u128_neg(v: u128): u128`
 ✅ Computes the bitwise NOT of a `u128`.\
 ⏮️ The function does not abort.

### `u8_neg(v: u8): u8`
 ✅ Computes the bitwise NOT of a `u8`.\
 ⏮️ The function does not abort.


## `i32_specs.move`

### `zero(): I32`
 ✅ Computes `0` as an `I32`.\
 ⏮️ The function does not abort.

### `from_u32(v: u32): I32`
 ✅ Computes an `I32` from a `u32`.\
 ⏮️ The function does not abort.

### `from(v: u32): I32`
 ✅ Computes an `I32` from a `u32`.\
 ⏮️ The function does not abort.

### `neg_from(v: u32): I32`
 ✅ Computes an `I32` from a `u32`.\
 ⏮️ The function aborts when the result does not fit in `I32`.

### `wrapping_add(num1: I32, num2: I32): I32`
 ✅ Computes `num1 + num2` with wrapping overflow.\
 ⏮️ The function does not abort.\
 ⚠️ Proved in a separate package as it requires a custom prover configuration.

### `add(num1: I32, num2: I32): I32`
 ✅ Computes `num1 + num2`.\
 ⏮️ The function aborts when the result does not fit in `I32`.

### `wrapping_sub(num1: I32, num2: I32): I32`
 ✅ Computes `num1 - num2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `sub(num1: I32, num2: I32): I32`
 ✅ Computes `num1 - num2`.\
 ⏮️ The function aborts when the result does not fit in `I32`.\
 ⚠️ This function was initially incorrect but fixed after our reporting. Replace the target with `sub_buggy` to see the how the bug is caught.

### `mul(num1: I32, num2: I32): I32`
 ✅ Computes `num1 * num2`.\
 ⏮️ The function aborts when the result does not fit in `I32`.

### `div(num1: I32, num2: I32): I32`
 ✅ Computes `num1 / num2` with truncation.\
 ⏮️ The function aborts when the result does not fit in `I32`, or the denominator is zero.

### `abs(v: I32): I32`
 ✅ Computes the absolute value of an `I32`.\
 ⏮️ The function aborts when the input is `MIN_I32`, that is `-2^31`.

### `abs_u32(v: I32): u32`
 ✅ Computes the absolute value of an `I32` as a `u32`.\
 ⏮️ The function does not abort.

### `shl(v: I32, shift: u8): I32`
 ✅ Computes `v << shift`.\
 ⏮️ The function aborts unless `shift < 32`.

### `shr(v: I32, shift: u8): I32`
 ✅ Computes `v >> shift`.\
 ⏮️ The function aborts unless `shift < 32`.\
 ⚠️ Proved in a separate package as it requires a custom prover configuration.

### `mod(v: I32, n: I32): I32`
 ✅ Computes `v % n`.\
 ⏮️ The function aborts when the denominator is zero.

### `sign(v: I32): u8`
 ✅ Returns `1` if the input is negative, `0` otherwise.\
 ⏮️ The function does not abort.

### `is_neg(v: I32): bool`
 ✅ Returns `true` if the input is negative, `false` otherwise.\
 ⏮️ The function does not abort.

### `cmp(num1: I32, num2: I32): u8`
 ✅ Compares two `I32`s.\
 ⏮️ The function does not abort.

### `eq(num1: I32, num2: I32): bool`
 ✅ Compares two `I32`s, returns `true` if they are equal, `false` otherwise.\
 ⏮️ The function does not abort.

### `gt(num1: I32, num2: I32): bool`
 ✅ Compares two `I32`s, returns `true` if the first is greater than the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `gte(num1: I32, num2: I32): bool`
 ✅ Compares two `I32`s, returns `true` if the first is greater than or equal to the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `lt(num1: I32, num2: I32): bool`
 ✅ Compares two `I32`s, returns `true` if the first is less than the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `lte(num1: I32, num2: I32): bool`
 ✅ Compares two `I32`s, returns `true` if the first is less than or equal to the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `or(num1: I32, num2: I32): I32`
 ✅ Computes the bitwise OR of two `I32`s.\
 ⏮️ The function does not abort.

### `and(num1: I32, num2: I32): I32`
 ✅ Computes the bitwise AND of two `I32`s.\
 ⏮️ The function does not abort.

### `u32_neg(v: u32): u32`
 ✅ Computes the bitwise NOT of a `u32`.\
 ⏮️ The function does not abort.

### `u8_neg(v: u8): u8`
 ✅ Computes the bitwise NOT of a `u8`.\
 ⏮️ The function does not abort.


## `i64_specs.move`

### `zero(): I64`
 ✅ Computes `0` as an `I64`.\
 ⏮️ The function does not abort.

### `from_u64(v: u64): I64`
 ✅ Computes an `I64` from a `u64`.\
 ⏮️ The function does not abort.

### `from(v: u64): I64`
 ✅ Computes an `I64` from a `u64`.\
 ⏮️ The function does not abort.

### `neg_from(v: u64): I64`
 ✅ Computes an `I64` from a `u64`.\
 ⏮️ The function aborts when the result does not fit in `I64`.

### `wrapping_add(num1: I64, num2: I64): I64`
 ✅ Computes `num1 + num2` with wrapping overflow.\
 ⏮️ The function does not abort.\
 ⚠️ Proved in a separate package as it requires a custom prover configuration.

### `add(num1: I64, num2: I64): I64`
 ✅ Computes `num1 + num2`.\
 ⏮️ The function aborts when the result does not fit in `I64`.

### `wrapping_sub(num1: I64, num2: I64): I64`
 ✅ Computes `num1 - num2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `sub(num1: I64, num2: I64): I64`
 ✅ Computes `num1 - num2`.\
 ⏮️ The function aborts when the result does not fit in `I64`.

### `mul(num1: I64, num2: I64): I64`
 ✅ Computes `num1 * num2`.\
 ⏮️ The function aborts when the result does not fit in `I64`.

### `div(num1: I64, num2: I64): I64`
 ✅ Computes `num1 / num2` with truncation.\
 ⏮️ The function aborts when the result does not fit in `I64`, or the denominator is zero.

### `abs(v: I64): I64`
 ✅ Computes the absolute value of an `I64`.\
 ⏮️ The function aborts when the input is `MIN_I64`, that is `-2^63`.

### `abs_u64(v: I64): u64`
 ✅ Computes the absolute value of an `I64` as a `u64`.\
 ⏮️ The function does not abort.

### `shl(v: I64, shift: u8): I64`
 ✅ Computes `v << shift`.\
 ⏮️ The function aborts unless `shift < 64`.

### `shr(v: I64, shift: u8): I64`
 ✅ Computes `v >> shift`.\
 ⏮️ The function aborts unless `shift < 64`.\
 ⚠️ Proved in a separate package as it requires a custom prover configuration.

### `mod(v: I64, n: I64): I64`
 ✅ Computes `v % n`.\
 ⏮️ The function aborts when the denominator is zero.

### `sign(v: I64): u8`
 ✅ Returns `1` if the input is negative, `0` otherwise.\
 ⏮️ The function does not abort.

### `is_neg(v: I64): bool`
 ✅ Returns `true` if the input is negative, `false` otherwise.\
 ⏮️ The function does not abort.

### `cmp(num1: I64, num2: I64): u8`
 ✅ Compares two `I64`s.\
 ⏮️ The function does not abort.

### `eq(num1: I64, num2: I64): bool`
 ✅ Compares two `I64`s, returns `true` if they are equal, `false` otherwise.\
 ⏮️ The function does not abort.

### `gt(num1: I64, num2: I64): bool`
 ✅ Compares two `I64`s, returns `true` if the first is greater than the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `gte(num1: I64, num2: I64): bool`
 ✅ Compares two `I64`s, returns `true` if the first is greater than or equal to the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `lt(num1: I64, num2: I64): bool`
 ✅ Compares two `I64`s, returns `true` if the first is less than the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `lte(num1: I64, num2: I64): bool`
 ✅ Compares two `I64`s, returns `true` if the first is less than or equal to the second, `false` otherwise.\
 ⏮️ The function does not abort.

### `or(num1: I64, num2: I64): I64`
 ✅ Computes the bitwise OR of two `I64`s.\
 ⏮️ The function does not abort.

### `and(num1: I64, num2: I64): I64`
 ✅ Computes the bitwise AND of two `I64`s.\
 ⏮️ The function does not abort.

### `u64_neg(v: u64): u64`
 ✅ Computes the bitwise NOT of a `u64`.\
 ⏮️ The function does not abort.

### `u8_neg(v: u8): u8`
 ✅ Computes the bitwise NOT of a `u8`.\
 ⏮️ The function does not abort.


## `math_u128_specs.move`

### `wrapping_add(n1: u128, n2: u128): u128`
 ✅ Computes `n1 + n2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `overflowing_add(n1: u128, n2: u128): (u128, bool)`
 ✅ Computes `n1 + n2` with wrapping overflow and a boolean indicating overflow.\
 ⏮️ The function does not abort.

### `wrapping_sub(n1: u128, n2: u128): u128`
 ✅ Computes `n1 - n2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `overflowing_sub(n1: u128, n2: u128): (u128, bool)`
 ✅ Computes `n1 - n2` with wrapping overflow and a boolean indicating overflow.\
 ⏮️ The function does not abort.

### `wrapping_mul(n1: u128, n2: u128): u128`
 ✅ Computes `n1 * n2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `overflowing_mul(n1: u128, n2: u128): (u128, bool)`
 ✅ Computes `n1 * n2` with wrapping overflow and a boolean indicating overflow.\
 ⏮️ The function does not abort.

### `full_mul(n1: u128, n2: u128): (u128, u128)`
 ✅ Computes the full 256-bit product of `n1 * n2` as two u128 values (lo, hi).\
 ⏮️ The function does not abort.

### `hi(n: u128): u64`
 ✅ Extracts the high 64 bits of a u128 value.\
 ⏮️ The function does not abort.

### `lo(n: u128): u64`
 ✅ Extracts the low 64 bits of a u128 value.\
 ⏮️ The function does not abort.

### `hi_u128(n: u128): u128`
 ✅ Extracts the high 64 bits of a u128 value as a u128.\
 ⏮️ The function does not abort.

### `lo_u128(n: u128): u128`
 ✅ Extracts the low 64 bits of a u128 value as a u128.\
 ⏮️ The function does not abort.

### `from_lo_hi(lo: u64, hi: u64): u128`
 ✅ Constructs a u128 from low and high u64 components.\
 ⏮️ The function does not abort.

### `checked_div_round(num: u128, denom: u128, round_up: bool): u128`
 ✅ Computes `num / denom` with optional rounding up.\
 ⏮️ The function aborts if `denom == 0`.

### `max(num1: u128, num2: u128): u128`
 ✅ Returns the maximum of two u128 values.\
 ⏮️ The function does not abort.

### `min(num1: u128, num2: u128): u128`
 ✅ Returns the minimum of two u128 values.\
 ⏮️ The function does not abort.

### `add_check(num1: u128, num2: u128): bool`
 ✅ Checks if `num1 + num2` will overflow.\
 ⏮️ The function does not abort.


## `math_u256_specs.move`

### `div_mod(num: u256, denom: u256): (u256, u256)`
 ✅ Computes `num / denom` and `num % denom`.\
 ⏮️ The function aborts if `denom == 0`.

### `shlw(n: u256): u256`
 ✅ Shifts `n` left by 64 bits (one word) with wrapping overflow.\
 ⏮️ The function does not abort.

### `shrw(n: u256): u256`
 ✅ Shifts `n` right by 64 bits (one word).\
 ⏮️ The function does not abort.

### `checked_shlw(n: u256): (u256, bool)`
 ✅ Shifts `n` left by 64 bits (one word) and returns a boolean indicating overflow.\
 ⏮️ The function does not abort.\
 ⚠️ Returns (0, true) when overflow occurs, not the wrapped value.

### `div_round(num: u256, denom: u256, round_up: bool): u256`
 ✅ Computes `num / denom` with optional rounding up.\
 ⏮️ The function aborts if `denom == 0`.

### `add_check(num1: u256, num2: u256): bool`
 ✅ Checks if `num1 + num2` will overflow.\
 ⏮️ The function does not abort.


## `math_u64_specs.move`

### `wrapping_add(n1: u64, n2: u64): u64`
 ✅ Computes `n1 + n2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `overflowing_add(n1: u64, n2: u64): (u64, bool)`
 ✅ Computes `n1 + n2` with wrapping overflow and a boolean indicating overflow.\
 ⏮️ The function does not abort.

### `wrapping_sub(n1: u64, n2: u64): u64`
 ✅ Computes `n1 - n2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `overflowing_sub(n1: u64, n2: u64): (u64, bool)`
 ✅ Computes `n1 - n2` with wrapping overflow and a boolean indicating overflow.\
 ⏮️ The function does not abort.

### `wrapping_mul(n1: u64, n2: u64): u64`
 ✅ Computes `n1 * n2` with wrapping overflow.\
 ⏮️ The function does not abort.

### `overflowing_mul(n1: u64, n2: u64): (u64, bool)`
 ✅ Computes `n1 * n2` with overflowing overflow and a boolean indicating overflow.\
 ⏮️ The function does not abort.

### `carry_add(n1: u64, n2: u64, carry: u64): (u64, u64)`
 ✅ Computes `n1 + n2 + carry` returning the result and the new carry.\
 ⏮️ The function aborts unless `carry <= 1`.

### `add_check(n1: u64, n2: u64): bool`
 ✅ Checks if `n1 + n2` will overflow.\
 ⏮️ The function does not abort.


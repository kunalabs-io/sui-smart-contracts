module cetus_clmm::clmm_math;

use cetus_clmm::tick_math;
use integer_mate::full_math_u128;
use integer_mate::full_math_u64;
use integer_mate::i32::{Self, I32};
use integer_mate::math_u128;
use integer_mate::math_u256;

/// Error when token amount exceeds maximum allowed value
const ETOKEN_AMOUNT_MAX_EXCEEDED: u64 = 0;
/// Error when token amount is below minimum required value
const ETOKEN_AMOUNT_MIN_SUBCEEDED: u64 = 1;
/// Error when multiplication operation results in overflow
const EMULTIPLICATION_OVERFLOW: u64 = 2;
/// Error when integer downcast operation results in overflow
#[allow(unused_const)]
const EINTEGER_DOWNCAST_OVERFLOW: u64 = 3;
/// Error when sqrt price input is invalid
const EINVALID_SQRT_PRICE_INPUT: u64 = 4;
/// Error when subtraction operation results in underflow
const ESUBTRACTION_UNDERFLOW: u64 = 5;
/// Error when casting amount to u64 results in overflow
const EAMOUNT_CAST_TO_U64_OVERFLOW: u64 = 6;
/// Error when amount cast to u128 results in overflow
const EAMOUNT_CAST_TO_U128_OVERFLOW: u64 = 7;
/// Error when tick range is invalid
const EINVALID_TICK_RANGE: u64 = 8;
/// Error when fixed token type is invalid
const EINVALID_FIXED_TOKEN_TYPE: u64 = 3018;

/// The denominator used for fee rate calculations, where fee rate is expressed as parts per million (1000000 = 100%)
const FEE_RATE_DENOMINATOR: u64 = 1000000;

/// The maximum value that can be stored in a u64 integer (2^64 - 1)
#[allow(unused_const)]
const UINT64_MAX: u256 = 18446744073709551615;

/// Returns the denominator used for fee rate calculations, where fee rate is expressed as parts per million (1000000 = 100%)
public fun fee_rate_denominator(): u64 {
    FEE_RATE_DENOMINATOR
}

public fun get_liquidity_from_a(
    sqrt_price_0: u128,
    sqrt_price_1: u128,
    amount_a: u64,
    round_up: bool,
): u128 {
    assert!(sqrt_price_0 != sqrt_price_1, EINVALID_SQRT_PRICE_INPUT);
    let sqrt_price_diff = if (sqrt_price_0 > sqrt_price_1) {
        sqrt_price_0 - sqrt_price_1
    } else {
        sqrt_price_1 - sqrt_price_0
    };

    // Here sqrt_price is Q32.64, less than 2**96, so the product is less than 2**192, multiply by amount_a is less than 2**256
    assert!(sqrt_price_0 <= tick_math::max_sqrt_price(), EINVALID_SQRT_PRICE_INPUT);
    assert!(sqrt_price_1 <= tick_math::max_sqrt_price(), EINVALID_SQRT_PRICE_INPUT);
    let numberator = full_math_u128::full_mul(sqrt_price_0, sqrt_price_1) * (amount_a as u256);
    let div_res = math_u256::div_round(numberator, ((sqrt_price_diff as u256) << 64), round_up);
    assert!(div_res <= std::u128::max_value!() as u256, EAMOUNT_CAST_TO_U128_OVERFLOW);
    (div_res as u128)
}

public fun get_liquidity_from_b(
    sqrt_price_0: u128,
    sqrt_price_1: u128,
    amount_b: u64,
    round_up: bool,
): u128 {
    assert!(sqrt_price_0 != sqrt_price_1, EINVALID_SQRT_PRICE_INPUT);
    let sqrt_price_diff = if (sqrt_price_0 > sqrt_price_1) {
        sqrt_price_0 - sqrt_price_1
    } else {
        sqrt_price_1 - sqrt_price_0
    };

    let div_res = math_u256::div_round(
        ((amount_b as u256) << 64),
        (sqrt_price_diff as u256),
        round_up,
    );
    assert!(div_res <= std::u128::max_value!() as u256, EAMOUNT_CAST_TO_U128_OVERFLOW);
    (div_res as u128)
}

public fun get_delta_a(
    sqrt_price_0: u128,
    sqrt_price_1: u128,
    liquidity: u128,
    round_up: bool,
): u64 {
    let sqrt_price_diff = if (sqrt_price_0 > sqrt_price_1) {
        sqrt_price_0 - sqrt_price_1
    } else {
        sqrt_price_1 - sqrt_price_0
    };
    if (sqrt_price_diff == 0 || liquidity == 0) {
        return 0
    };

    let (numberator, overflowing) = math_u256::checked_shlw(
        full_math_u128::full_mul(liquidity, sqrt_price_diff),
    );
    if (overflowing) {
        abort EMULTIPLICATION_OVERFLOW
    };
    let denominator = full_math_u128::full_mul(sqrt_price_0, sqrt_price_1);
    let quotient = math_u256::div_round(numberator, denominator, round_up);
    assert!(quotient <= std::u64::max_value!() as u256, EAMOUNT_CAST_TO_U64_OVERFLOW);
    (quotient as u64)
}

public fun get_delta_b(
    sqrt_price_0: u128,
    sqrt_price_1: u128,
    liquidity: u128,
    round_up: bool,
): u64 {
    let sqrt_price_diff = if (sqrt_price_0 > sqrt_price_1) {
        sqrt_price_0 - sqrt_price_1
    } else {
        sqrt_price_1 - sqrt_price_0
    };
    if (sqrt_price_diff == 0 || liquidity == 0) {
        return 0
    };

    let lo64_mask = 0x000000000000000000000000000000000000000000000000ffffffffffffffff;
    let product = full_math_u128::full_mul(liquidity, sqrt_price_diff);
    let should_round_up = (round_up) && ((product & lo64_mask) > 0);
    if (should_round_up) {
        assert!(
            ((product >> 64) + 1) <= std::u64::max_value!() as u256,
            EAMOUNT_CAST_TO_U64_OVERFLOW,
        );
        return (((product >> 64) + 1) as u64)
    };
    assert!((product >> 64) <= std::u64::max_value!() as u256, EAMOUNT_CAST_TO_U64_OVERFLOW);
    ((product >> 64) as u64)
}

public fun get_next_sqrt_price_a_up(
    sqrt_price: u128,
    liquidity: u128,
    amount: u64,
    by_amount_input: bool,
): u128 {
    if (amount == 0) {
        return sqrt_price
    };

    let (numberator, overflowing) = math_u256::checked_shlw(
        full_math_u128::full_mul(sqrt_price, liquidity),
    );
    if (overflowing) {
        abort EMULTIPLICATION_OVERFLOW
    };

    let liquidity_shl_64 = (liquidity as u256) << 64;
    let product = full_math_u128::full_mul(sqrt_price, (amount as u128));
    let new_sqrt_price = if (by_amount_input) {
        math_u256::div_round(numberator, (liquidity_shl_64 + product), true)
    } else {
        if (liquidity_shl_64 <= product) {
            abort ESUBTRACTION_UNDERFLOW
        };
        math_u256::div_round(numberator, (liquidity_shl_64 - product), true)
    };
    assert!(new_sqrt_price >= tick_math::min_sqrt_price() as u256, ETOKEN_AMOUNT_MIN_SUBCEEDED);
    assert!(new_sqrt_price <= tick_math::max_sqrt_price() as u256, ETOKEN_AMOUNT_MAX_EXCEEDED);

    new_sqrt_price as u128
}

public fun get_next_sqrt_price_b_down(
    sqrt_price: u128,
    liquidity: u128,
    amount: u64,
    by_amount_input: bool,
): u128 {
    let delta_sqrt_price = math_u128::checked_div_round(
        ((amount as u128) << 64),
        liquidity,
        !by_amount_input,
    );
    let new_sqrt_price = if (by_amount_input) {
        sqrt_price + delta_sqrt_price
    } else {
        if (sqrt_price < delta_sqrt_price) {
            abort ESUBTRACTION_UNDERFLOW
        };
        sqrt_price - delta_sqrt_price
    };

    if (new_sqrt_price > tick_math::max_sqrt_price()) {
        abort ETOKEN_AMOUNT_MAX_EXCEEDED
    } else if (new_sqrt_price < tick_math::min_sqrt_price()) {
        abort ETOKEN_AMOUNT_MIN_SUBCEEDED
    };

    new_sqrt_price
}

public fun get_next_sqrt_price_from_input(
    sqrt_price: u128,
    liquidity: u128,
    amount: u64,
    a_to_b: bool,
): u128 {
    if (a_to_b) {
        get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, true)
    } else {
        get_next_sqrt_price_b_down(sqrt_price, liquidity, amount, true)
    }
}

public fun get_next_sqrt_price_from_output(
    sqrt_price: u128,
    liquidity: u128,
    amount: u64,
    a_to_b: bool,
): u128 {
    if (a_to_b) {
        get_next_sqrt_price_b_down(sqrt_price, liquidity, amount, false)
    } else {
        get_next_sqrt_price_a_up(sqrt_price, liquidity, amount, false)
    }
}

public fun get_delta_up_from_input(
    current_sqrt_price: u128,
    target_sqrt_price: u128,
    liquidity: u128,
    a_to_b: bool,
): u256 {
    let sqrt_price_diff = if (current_sqrt_price > target_sqrt_price) {
        current_sqrt_price - target_sqrt_price
    } else {
        target_sqrt_price - current_sqrt_price
    };
    if (sqrt_price_diff == 0 || liquidity == 0) {
        return 0
    };
    if (a_to_b) {
        let (numberator, overflowing) = math_u256::checked_shlw(
            full_math_u128::full_mul(liquidity, sqrt_price_diff),
        );
        if (overflowing) {
            abort EMULTIPLICATION_OVERFLOW
        };
        let denominator = full_math_u128::full_mul(current_sqrt_price, target_sqrt_price);
        math_u256::div_round(numberator, denominator, true)
    } else {
        let product = full_math_u128::full_mul(liquidity, sqrt_price_diff);
        let lo64_mask = 0x000000000000000000000000000000000000000000000000ffffffffffffffff;
        let should_round_up = (product & lo64_mask) > 0;
        if (should_round_up) {
            return (product >> 64) + 1
        };
        product >> 64
    }
}

public fun get_delta_down_from_output(
    current_sqrt_price: u128,
    target_sqrt_price: u128,
    liquidity: u128,
    a_to_b: bool,
): u256 {
    let sqrt_price_diff = if (current_sqrt_price > target_sqrt_price) {
        current_sqrt_price - target_sqrt_price
    } else {
        target_sqrt_price - current_sqrt_price
    };
    if (sqrt_price_diff == 0 || liquidity == 0) {
        return 0
    };
    if (a_to_b) {
        let product = full_math_u128::full_mul(liquidity, sqrt_price_diff);
        product >> 64
    } else {
        let (numberator, overflowing) = math_u256::checked_shlw(
            full_math_u128::full_mul(liquidity, sqrt_price_diff),
        );
        if (overflowing) {
            abort EMULTIPLICATION_OVERFLOW
        };
        let denominator = full_math_u128::full_mul(current_sqrt_price, target_sqrt_price);
        math_u256::div_round(numberator, denominator, false)
    }
}

public fun compute_swap_step(
    current_sqrt_price: u128,
    target_sqrt_price: u128,
    liquidity: u128,
    amount: u64,
    fee_rate: u64,
    a2b: bool,
    by_amount_in: bool,
): (u64, u64, u128, u64) {
    let mut next_sqrt_price = target_sqrt_price;
    let mut amount_in: u64 = 0;
    let mut amount_out: u64 = 0;
    let mut fee_amount: u64 = 0;
    if (liquidity == 0 || current_sqrt_price == target_sqrt_price) {
        return (amount_in, amount_out, next_sqrt_price, fee_amount)
    };
    if (a2b) {
        assert!(current_sqrt_price > target_sqrt_price, EINVALID_SQRT_PRICE_INPUT)
    } else {
        assert!(current_sqrt_price < target_sqrt_price, EINVALID_SQRT_PRICE_INPUT)
    };

    if (by_amount_in) {
        let amount_remain = full_math_u64::mul_div_floor(
            amount,
            (FEE_RATE_DENOMINATOR - fee_rate),
            FEE_RATE_DENOMINATOR,
        );
        let max_amount_in = get_delta_up_from_input(
            current_sqrt_price,
            target_sqrt_price,
            liquidity,
            a2b,
        );
        if (max_amount_in > (amount_remain as u256)) {
            amount_in = amount_remain;
            fee_amount = amount - amount_remain;
            next_sqrt_price =
                get_next_sqrt_price_from_input(
                    current_sqrt_price,
                    liquidity,
                    amount_remain,
                    a2b,
                );
        } else {
            // it will never overflow here, because max_amount_in < amount_remain and amount_remain's type is u64
            amount_in = (max_amount_in as u64);
            fee_amount =
                full_math_u64::mul_div_ceil(amount_in, fee_rate, (FEE_RATE_DENOMINATOR - fee_rate));
            next_sqrt_price = target_sqrt_price;
        };
        let amount_out_ = get_delta_down_from_output(
            current_sqrt_price,
            next_sqrt_price,
            liquidity,
            a2b,
        );
        assert!(amount_out_ <= std::u64::max_value!() as u256, EAMOUNT_CAST_TO_U64_OVERFLOW);
        amount_out = (amount_out_ as u64);
    } else {
        let max_amount_out = get_delta_down_from_output(
            current_sqrt_price,
            target_sqrt_price,
            liquidity,
            a2b,
        );
        if (max_amount_out > (amount as u256)) {
            amount_out = amount;
            next_sqrt_price =
                get_next_sqrt_price_from_output(current_sqrt_price, liquidity, amount, a2b);
        } else {
            amount_out = (max_amount_out as u64);
            next_sqrt_price = target_sqrt_price;
        };
        let in_amount_ = get_delta_up_from_input(
            current_sqrt_price,
            next_sqrt_price,
            liquidity,
            a2b,
        );
        assert!(in_amount_ <= std::u64::max_value!() as u256, EAMOUNT_CAST_TO_U64_OVERFLOW);
        amount_in = (in_amount_ as u64);
        fee_amount =
            full_math_u64::mul_div_ceil(amount_in, fee_rate, (FEE_RATE_DENOMINATOR - fee_rate));
    };

    (amount_in, amount_out, next_sqrt_price, fee_amount)
}

public fun get_amount_by_liquidity(
    tick_lower: I32,
    tick_upper: I32,
    current_tick_index: I32,
    current_sqrt_price: u128,
    liquidity: u128,
    round_up: bool,
): (u64, u64) {
    if (liquidity == 0) {
        return (0, 0)
    };
    assert!(tick_lower.lt(tick_upper), EINVALID_TICK_RANGE);
    let lower_price = tick_math::get_sqrt_price_at_tick(tick_lower);
    let upper_price = tick_math::get_sqrt_price_at_tick(tick_upper);
    // Only coin a

    let (amount_a, amount_b) = if (i32::lt(current_tick_index, tick_lower)) {
        (get_delta_a(lower_price, upper_price, liquidity, round_up), 0)
    } else if (i32::lt(current_tick_index, tick_upper)) {
        (
            get_delta_a(current_sqrt_price, upper_price, liquidity, round_up),
            get_delta_b(lower_price, current_sqrt_price, liquidity, round_up),
        )
    } else {
        (0, get_delta_b(lower_price, upper_price, liquidity, round_up))
    };
    (amount_a, amount_b)
}

public fun get_liquidity_by_amount(
    lower_index: I32,
    upper_index: I32,
    _current_tick_index: I32,
    current_sqrt_price: u128,
    amount: u64,
    is_fixed_a: bool,
): (u128, u64, u64) {
    let lower_price = tick_math::get_sqrt_price_at_tick(lower_index);
    let upper_price = tick_math::get_sqrt_price_at_tick(upper_index);
    let mut amount_a: u64 = 0;
    let mut amount_b: u64 = 0;
    let mut _liquidity: u128 = 0;
    if (is_fixed_a) {
        assert!(current_sqrt_price < upper_price, EINVALID_FIXED_TOKEN_TYPE);
        if (current_sqrt_price <= lower_price) {
            // Only A
            _liquidity = get_liquidity_from_a(lower_price, upper_price, amount, false);
        } else {
            // Both A and B
            _liquidity = get_liquidity_from_a(current_sqrt_price, upper_price, amount, false);
            amount_b = get_delta_b(current_sqrt_price, lower_price, _liquidity, true);
        };
        amount_a = amount;
    } else {
        assert!(current_sqrt_price > lower_price, EINVALID_FIXED_TOKEN_TYPE);
        if (current_sqrt_price >= upper_price) {
            // Only B
            _liquidity = get_liquidity_from_b(lower_price, upper_price, amount, false);
        } else {
            // Both A and B
            _liquidity = get_liquidity_from_b(lower_price, current_sqrt_price, amount, false);
            amount_a = get_delta_a(current_sqrt_price, upper_price, _liquidity, true);
        };
        amount_b = amount;
    };
    (_liquidity, amount_a, amount_b)
}

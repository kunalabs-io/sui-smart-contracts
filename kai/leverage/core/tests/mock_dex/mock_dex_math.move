#[test_only]
module kai_leverage::mock_dex_math;

use integer_mate::full_math_u128;
use integer_mate::i128;
use integer_mate::i32::{Self, I32};
use integer_mate::math_u256;

#[error]
const EInvalidTick: vector<u8> = b"The tick is out of bounds";
#[error]
const EInvalidSqrtPrice: vector<u8> = b"The sqrt price is out of bounds";
#[error]
const EMultiplicationOverflow: vector<u8> = b"Multiplication overflow";
#[error]
const ETokenAmountMaxExceeded: vector<u8> = b"Token amount max exceeded";
#[error]
const ETokenAmountMinSubceeded: vector<u8> = b"Token amount min subceeded";
#[error]
const EInvalidSqrtPriceInput: vector<u8> = b"The sqrt price input is out of bounds";

const TICK_BOUND: u32 = 443636;
const MAX_SQRT_PRICE_X64: u128 = 79226673515401279992447579055;
const MIN_SQRT_PRICE_X64: u128 = 4295048016;
const FEE_RATE_DENOMINATOR: u64 = 1000000;

public macro fun fee_rate_denominator(): u64 {
    1000000
}

/* ================= tick math ================= */

macro fun as_u8($b: bool): u8 {
    if ($b) {
        1
    } else {
        0
    }
}

public fun max_tick(): i32::I32 {
    i32::from(TICK_BOUND)
}

public fun min_tick(): i32::I32 {
    i32::neg_from(TICK_BOUND)
}

public fun get_sqrt_price_at_tick(tick: i32::I32): u128 {
    assert!(i32::gte(tick, min_tick()) && i32::lte(tick, max_tick()), EInvalidTick);
    if (i32::is_neg(tick)) {
        get_sqrt_price_at_negative_tick(tick)
    } else {
        get_sqrt_price_at_positive_tick(tick)
    }
}

fun get_sqrt_price_at_negative_tick(tick: i32::I32): u128 {
    let abs_tick = i32::as_u32(i32::abs(tick));
    let mut ratio = if (abs_tick & 0x1 != 0) {
        18445821805675392311u128
    } else {
        18446744073709551616u128
    };
    if (abs_tick & 0x2 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 18444899583751176498u128, 64u8)
    };
    if (abs_tick & 0x4 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 18443055278223354162u128, 64u8);
    };
    if (abs_tick & 0x8 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 18439367220385604838u128, 64u8);
    };
    if (abs_tick & 0x10 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 18431993317065449817u128, 64u8);
    };
    if (abs_tick & 0x20 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 18417254355718160513u128, 64u8);
    };
    if (abs_tick & 0x40 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 18387811781193591352u128, 64u8);
    };
    if (abs_tick & 0x80 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 18329067761203520168u128, 64u8);
    };
    if (abs_tick & 0x100 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 18212142134806087854u128, 64u8);
    };
    if (abs_tick & 0x200 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 17980523815641551639u128, 64u8);
    };
    if (abs_tick & 0x400 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 17526086738831147013u128, 64u8);
    };
    if (abs_tick & 0x800 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 16651378430235024244u128, 64u8);
    };
    if (abs_tick & 0x1000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 15030750278693429944u128, 64u8);
    };
    if (abs_tick & 0x2000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 12247334978882834399u128, 64u8);
    };
    if (abs_tick & 0x4000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 8131365268884726200u128, 64u8);
    };
    if (abs_tick & 0x8000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 3584323654723342297u128, 64u8);
    };
    if (abs_tick & 0x10000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 696457651847595233u128, 64u8);
    };
    if (abs_tick & 0x20000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 26294789957452057u128, 64u8);
    };
    if (abs_tick & 0x40000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 37481735321082u128, 64u8);
    };

    ratio
}

fun get_sqrt_price_at_positive_tick(tick: i32::I32): u128 {
    let abs_tick = i32::as_u32(i32::abs(tick));
    let mut ratio = if (abs_tick & 0x1 != 0) {
        79232123823359799118286999567u128
    } else {
        79228162514264337593543950336u128
    };

    if (abs_tick & 0x2 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 79236085330515764027303304731u128, 96u8)
    };
    if (abs_tick & 0x4 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 79244008939048815603706035061u128, 96u8)
    };
    if (abs_tick & 0x8 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 79259858533276714757314932305u128, 96u8)
    };
    if (abs_tick & 0x10 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 79291567232598584799939703904u128, 96u8)
    };
    if (abs_tick & 0x20 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 79355022692464371645785046466u128, 96u8)
    };
    if (abs_tick & 0x40 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 79482085999252804386437311141u128, 96u8)
    };
    if (abs_tick & 0x80 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 79736823300114093921829183326u128, 96u8)
    };
    if (abs_tick & 0x100 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 80248749790819932309965073892u128, 96u8)
    };
    if (abs_tick & 0x200 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 81282483887344747381513967011u128, 96u8)
    };
    if (abs_tick & 0x400 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 83390072131320151908154831281u128, 96u8)
    };
    if (abs_tick & 0x800 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 87770609709833776024991924138u128, 96u8)
    };
    if (abs_tick & 0x1000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 97234110755111693312479820773u128, 96u8)
    };
    if (abs_tick & 0x2000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 119332217159966728226237229890u128, 96u8)
    };
    if (abs_tick & 0x4000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 179736315981702064433883588727u128, 96u8)
    };
    if (abs_tick & 0x8000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 407748233172238350107850275304u128, 96u8)
    };
    if (abs_tick & 0x10000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 2098478828474011932436660412517u128, 96u8)
    };
    if (abs_tick & 0x20000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 55581415166113811149459800483533u128, 96u8)
    };
    if (abs_tick & 0x40000 != 0) {
        ratio = full_math_u128::mul_shr(ratio, 38992368544603139932233054999993551u128, 96u8)
    };

    ratio >> 32
}

public fun get_tick_at_sqrt_price(sqrt_price: u128): i32::I32 {
    assert!(
        sqrt_price >= MIN_SQRT_PRICE_X64 && sqrt_price <= MAX_SQRT_PRICE_X64,
        EInvalidSqrtPrice,
    );
    let mut r = sqrt_price;
    let mut msb = 0;

    let mut f: u8 = as_u8!(r >= 0x10000000000000000) << 6; // If r >= 2^64, f = 64 else 0
    msb = msb | f;
    r = r >> f;
    f = as_u8!(r >= 0x100000000) << 5; // 2^32
    msb = msb | f;
    r = r >> f;
    f = as_u8!(r >= 0x10000) << 4; // 2^16
    msb = msb | f;
    r = r >> f;
    f = as_u8!(r >= 0x100) << 3; // 2^8
    msb = msb | f;
    r = r >> f;
    f = as_u8!(r >= 0x10) << 2; // 2^4
    msb = msb | f;
    r = r >> f;
    f = as_u8!(r >= 0x4) << 1; // 2^2
    msb = msb | f;
    r = r >> f;
    f = as_u8!(r >= 0x2) << 0; // 2^0
    msb = msb | f;

    let mut log_2_x32 = i128::shl(i128::sub(i128::from((msb as u128)), i128::from(64)), 32);

    r = if (msb >= 64) {
        sqrt_price >> (msb - 63)
    } else {
        sqrt_price << (63 - msb)
    };

    let mut shift = 31;
    while (shift >= 18) {
        r = ((r * r) >> 63);
        f = ((r >> 64) as u8);
        log_2_x32 = i128::or(log_2_x32, i128::shl(i128::from((f as u128)), shift));
        r = r >> f;
        shift = shift - 1;
    };

    let log_sqrt_10001 = i128::mul(log_2_x32, i128::from(59543866431366u128));

    let tick_low = i128::as_i32(
        i128::shr(i128::sub(log_sqrt_10001, i128::from(184467440737095516u128)), 64),
    );
    let tick_high = i128::as_i32(
        i128::shr(i128::add(log_sqrt_10001, i128::from(15793534762490258745u128)), 64),
    );

    if (i32::eq(tick_low, tick_high)) {
        tick_low
    } else if (get_sqrt_price_at_tick(tick_high) <= sqrt_price) {
        tick_high
    } else {
        tick_low
    }
}

/* ================= clmm math ================= */

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
    //let (numberator, overflowing) = u256::checked_shlw(full_math_u128::full_mul(liquidity, sqrt_price_diff));
    //if (overflowing) {
    //    abort EMULTIPLICATION_OVERFLOW
    //};
    //let denomminator = full_math_u128::full_mul(sqrt_price_0, sqrt_price_1);
    //let quotient = u256::checked_div_round(numberator, denomminator, round_up);
    //(u256::as_u64(quotient))
    let (numberator, overflowing) = math_u256::checked_shlw(
        full_math_u128::full_mul(liquidity, sqrt_price_diff),
    );
    if (overflowing) {
        abort EMultiplicationOverflow
    };
    let denominator = full_math_u128::full_mul(sqrt_price_0, sqrt_price_1);
    let quotient = math_u256::div_round(numberator, denominator, round_up);
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
    // let product = full_math_u128::full_mul(liquidity, sqrt_price_diff);
    // let should_round_up = (round_up) && (u256::get(&product, 0) > 0);
    // if (should_round_up) {
    //     return u256::as_u64(u256::shrw(product)) + 1
    // };
    // (u256::as_u64(u256::shrw(product)))

    let lo64_mask = 0x000000000000000000000000000000000000000000000000ffffffffffffffff;
    let product = full_math_u128::full_mul(liquidity, sqrt_price_diff);
    let should_round_up = (round_up) && ((product & lo64_mask) > 0);
    if (should_round_up) {
        return (((product >> 64) + 1) as u64)
    };
    ((product >> 64) as u64)
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
    let lower_price = get_sqrt_price_at_tick(tick_lower);
    let upper_price = get_sqrt_price_at_tick(tick_upper);
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

/* ================= swap math ================= */

public fun get_next_sqrt_price_a_up(
    sqrt_price: u128,
    liquidity: u128,
    amount: u64,
    by_amount_input: bool,
): u128 {
    if (amount == 0) {
        return sqrt_price
    };

    // let numberator = u256::shlw(full_math_u128::full_mul(sqrt_price, liquidity));
    // let liquidity_shl_64 = u256::shlw(u256::from(liquidity));
    // let product = full_math_u128::full_mul(sqrt_price, (amount as u128));
    // let quotient = if (by_amount_input) {
    //     u256::checked_div_round(numberator, u256::add(liquidity_shl_64, product), true)
    // } else {
    //     u256::checked_div_round(numberator, u256::sub(liquidity_shl_64, product), true)
    // };
    // let new_sqrt_price = u256::as_u128(quotient);

    let (numberator, overflowing) = math_u256::checked_shlw(
        full_math_u128::full_mul(sqrt_price, liquidity),
    );
    if (overflowing) {
        abort EMultiplicationOverflow
    };

    let liquidity_shl_64 = (liquidity as u256) << 64;
    let product = full_math_u128::full_mul(sqrt_price, (amount as u128));
    let new_sqrt_price = if (by_amount_input) {
        (math_u256::div_round(numberator, (liquidity_shl_64 + product), true) as u128)
    } else {
        (math_u256::div_round(numberator, (liquidity_shl_64 - product), true) as u128)
    };

    if (new_sqrt_price > MAX_SQRT_PRICE_X64) {
        abort ETokenAmountMaxExceeded
    } else if (new_sqrt_price < MIN_SQRT_PRICE_X64) {
        abort ETokenAmountMinSubceeded
    };

    new_sqrt_price
}

public fun checked_div_round(num: u128, denom: u128, round_up: bool): u128 {
    let quotient = num / denom;
    let remainer = num % denom;
    if (round_up && (remainer > 0)) {
        return (quotient + 1)
    };
    quotient
}

public fun get_next_sqrt_price_b_down(
    sqrt_price: u128,
    liquidity: u128,
    amount: u64,
    by_amount_input: bool,
): u128 {
    let delta_sqrt_price = checked_div_round(((amount as u128) << 64), liquidity, !by_amount_input);
    let new_sqrt_price = if (by_amount_input) {
        sqrt_price + delta_sqrt_price
    } else {
        sqrt_price - delta_sqrt_price
    };

    if (new_sqrt_price > MAX_SQRT_PRICE_X64) {
        abort ETokenAmountMaxExceeded
    } else if (new_sqrt_price < MIN_SQRT_PRICE_X64) {
        abort ETokenAmountMinSubceeded
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
        // let (numberator, overflowing) = u256::checked_shlw(full_math_u128::full_mul(liquidity, sqrt_price_diff));
        // if (overflowing) {
        //     abort EMULTIPLICATION_OVERFLOW
        // };
        // let denomminator = full_math_u128::full_mul(current_sqrt_price, target_sqrt_price);
        // u256::checked_div_round(numberator, denomminator, true)
        let (numberator, overflowing) = math_u256::checked_shlw(
            full_math_u128::full_mul(liquidity, sqrt_price_diff),
        );
        if (overflowing) {
            abort EMultiplicationOverflow
        };
        let denominator = full_math_u128::full_mul(current_sqrt_price, target_sqrt_price);
        math_u256::div_round(numberator, denominator, true)
    } else {
        // let product = full_math_u128::full_mul(liquidity, sqrt_price_diff);
        // let should_round_up = u256::get(&product, 0) > 0;
        // if (should_round_up) {
        //     return u256::add(u256::shrw(product), u256::from(1))
        // };
        // u256::shrw(product)

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
        // let product = full_math_u128::full_mul(liquidity, sqrt_price_diff);
        // u256::shrw(product)
        let product = full_math_u128::full_mul(liquidity, sqrt_price_diff);
        product >> 64
    } else {
        // let (numberator, overflowing) = u256::checked_shlw(full_math_u128::full_mul(liquidity, sqrt_price_diff));
        // if (overflowing) {
        //     abort EMULTIPLICATION_OVERFLOW
        // };
        // let denomminator = full_math_u128::full_mul(current_sqrt_price, target_sqrt_price);
        // u256::checked_div_round(numberator, denomminator, false)

        let (numberator, overflowing) = math_u256::checked_shlw(
            full_math_u128::full_mul(liquidity, sqrt_price_diff),
        );
        if (overflowing) {
            abort EMultiplicationOverflow
        };
        let denominator = full_math_u128::full_mul(current_sqrt_price, target_sqrt_price);
        math_u256::div_round(numberator, denominator, false)
    }
}

public fun full_mul(num1: u64, num2: u64): u128 {
    ((num1 as u128) * (num2 as u128))
}

public fun mul_div_floor(num1: u64, num2: u64, denom: u64): u64 {
    let r = full_mul(num1, num2) / (denom as u128);
    (r as u64)
}

public fun mul_div_round(num1: u64, num2: u64, denom: u64): u64 {
    let r = (full_mul(num1, num2) + ((denom as u128) >> 1)) / (denom as u128);
    (r as u64)
}

public fun mul_div_ceil(num1: u64, num2: u64, denom: u64): u64 {
    let r = (full_mul(num1, num2) + ((denom as u128) - 1)) / (denom as u128);
    (r as u64)
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
    if (liquidity == 0) {
        return (amount_in, amount_out, next_sqrt_price, fee_amount)
    };
    if (a2b) {
        assert!(current_sqrt_price >= target_sqrt_price, EInvalidSqrtPriceInput)
    } else {
        assert!(current_sqrt_price < target_sqrt_price, EInvalidSqrtPriceInput)
    };
    //let a_to_b = current_sqrt_price >= target_sqrt_price;

    if (by_amount_in) {
        let amount_remain = mul_div_floor(
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
        // if (u256::gt(max_amount_in, u256::from((amount_remain as u128)))) {
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
            // amount_in = u256::as_u64(max_amount_in);
            amount_in = (max_amount_in as u64);
            fee_amount = mul_div_ceil(amount_in, fee_rate, (FEE_RATE_DENOMINATOR - fee_rate));
            next_sqrt_price = target_sqrt_price;
        };
        // amount_out = u256::as_u64(get_delta_down_from_output(current_sqrt_price, next_sqrt_price, liquidity, a2b));
        amount_out = (
            get_delta_down_from_output(current_sqrt_price, next_sqrt_price, liquidity, a2b) as u64,
        );
    } else {
        let max_amount_out = get_delta_down_from_output(
            current_sqrt_price,
            target_sqrt_price,
            liquidity,
            a2b,
        );
        // if ( u256::gt(max_amount_out, u256::from((amount as u128)))) {
        if (max_amount_out > (amount as u256)) {
            amount_out = amount;
            next_sqrt_price =
                get_next_sqrt_price_from_output(current_sqrt_price, liquidity, amount, a2b);
        } else {
            // amount_out = u256::as_u64(max_amount_out);
            amount_out = (max_amount_out as u64);
            next_sqrt_price = target_sqrt_price;
        };
        // amount_in = u256::as_u64(get_delta_up_from_input(current_sqrt_price, next_sqrt_price, liquidity, a2b));
        amount_in = (
            get_delta_up_from_input(current_sqrt_price, next_sqrt_price, liquidity, a2b) as u64,
        );
        fee_amount = mul_div_ceil(amount_in, fee_rate, (FEE_RATE_DENOMINATOR - fee_rate));
    };

    (amount_in, amount_out, next_sqrt_price, fee_amount)
}

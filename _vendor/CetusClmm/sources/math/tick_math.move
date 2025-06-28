module cetusclmm::tick_math {
    use integer_mate::full_math_u128;
    use integer_mate::i32::{Self, I32};
    use integer_mate::i128;

    const TICK_BOUND: u32 = 443636;
    const MAX_SQRT_PRICE_X64: u128 = 79226673515401279992447579055;
    const MIN_SQRT_PRICE_X64: u128 = 4295048016;

    /// Errors
    const EINVALID_TICK: u64 = 1;
    const EINVALID_SQRT_PRICE: u64 =2;

    public fun max_sqrt_price(): u128 {
        MAX_SQRT_PRICE_X64
    }

    public fun min_sqrt_price(): u128 {
        MIN_SQRT_PRICE_X64
    }

    public fun max_tick(): i32::I32 {
        i32::from(TICK_BOUND)
    }

    public fun min_tick(): i32::I32 {
        i32::neg_from(TICK_BOUND)
    }

    public fun tick_bound(): u32 {
        TICK_BOUND
    }

    public fun get_sqrt_price_at_tick(tick: i32::I32): u128 {
        assert!(i32::gte(tick, min_tick()) && i32::lte(tick, max_tick()), EINVALID_TICK);
        if (i32::is_neg(tick)) {
            get_sqrt_price_at_negative_tick(tick)
        } else {
            get_sqrt_price_at_positive_tick(tick)
        }
    }

    public fun is_valid_index(index: I32, tick_spacing: u32): bool {
        let in_range = i32::gte(index, min_tick()) && i32::lte(index, max_tick());
        in_range && (i32::mod(index, i32::from(tick_spacing)) == i32::from(0))
    }

    public fun get_tick_at_sqrt_price(sqrt_price: u128): i32::I32 {
        assert!(sqrt_price >= MIN_SQRT_PRICE_X64 && sqrt_price <= MAX_SQRT_PRICE_X64, EINVALID_SQRT_PRICE);
        let r = sqrt_price;
        let msb = 0;

        let f: u8 = as_u8(r >= 0x10000000000000000) << 6; // If r >= 2^64, f = 64 else 0
        msb = msb | f;
        r = r >> f;
        f = as_u8(r >= 0x100000000) << 5; // 2^32
        msb = msb | f;
        r = r >> f;
        f = as_u8(r >= 0x10000) << 4; // 2^16
        msb = msb | f;
        r = r >> f;
        f = as_u8(r >= 0x100) << 3; // 2^8
        msb = msb | f;
        r = r >> f;
        f = as_u8(r >= 0x10) << 2; // 2^4
        msb = msb | f;
        r = r >> f;
        f = as_u8(r >= 0x4) << 1; // 2^2
        msb = msb | f;
        r = r >> f;
        f = as_u8(r >= 0x2) << 0; // 2^0
        msb = msb | f;

        let log_2_x32 = i128::shl(i128::sub(i128::from((msb as u128)), i128::from(64)), 32);

        r = if (msb >= 64) {
            sqrt_price >> (msb - 63)
        } else {
            sqrt_price << (63 - msb)
        };

        let shift = 31;
        while (shift >= 18) {
            r = ((r * r) >> 63);
            f = ((r >> 64) as u8);
            log_2_x32 = i128::or(log_2_x32, i128::shl(i128::from((f as u128)), shift));
            r = r >> f;
            shift = shift - 1;
        };

        let log_sqrt_10001 = i128::mul(log_2_x32, i128::from(59543866431366u128));

        let tick_low = i128::as_i32(i128::shr(i128::sub(log_sqrt_10001, i128::from(184467440737095516u128)), 64));
        let tick_high = i128::as_i32(i128::shr(i128::add(log_sqrt_10001, i128::from(15793534762490258745u128)), 64));

        if (i32::eq(tick_low, tick_high)) {
            return tick_low
        } else if (get_sqrt_price_at_tick(tick_high) <= sqrt_price) {
            return tick_high
        } else {
            return tick_low
        }
    }

    fun as_u8(b: bool): u8 {
        if (b) {
            1
        } else {
            0
        }
    }

    fun get_sqrt_price_at_negative_tick(tick: i32::I32): u128 {
        let abs_tick = i32::as_u32(i32::abs(tick));
        let ratio = if (abs_tick & 0x1 != 0) {
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
        let ratio = if (abs_tick & 0x1 != 0) {
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

    #[test]
    fun test_get_sqrt_price_at_tick() {
        // min tick
        assert!(get_sqrt_price_at_tick(i32::neg_from(TICK_BOUND)) == 4295048016u128, 2);
        // max tick
        assert!(get_sqrt_price_at_tick(i32::from(TICK_BOUND)) == 79226673515401279992447579055u128, 1);
        assert!(get_sqrt_price_at_tick(i32::neg_from(435444u32)) == 6469134034u128, 3);
        assert!(get_sqrt_price_at_tick(i32::from(408332u32)) == 13561044167458152057771544136u128, 4);
    }

    #[test]
    fun test_get_tick_at_sqrt_price_1() {
        assert!(i32::eq(get_tick_at_sqrt_price(6469134034u128), i32::neg_from(435444)) == true, 0);
        assert!(i32::eq(get_tick_at_sqrt_price(13561044167458152057771544136u128), i32::from(408332u32)) == true, 0);
    }

    #[test]
    #[expected_failure]
    fun test_get_sqrt_price_at_invalid_upper_tick() {
        get_sqrt_price_at_tick(i32::add(max_tick(), i32::from(1)));
    }

    #[test]
    #[expected_failure]
    fun test_get_sqrt_price_at_invalid_lower_tick() {
        get_sqrt_price_at_tick(i32::sub(min_tick(), i32::from(1)));
    }

    #[test]
    #[expected_failure]
    fun test_get_tick_at_invalid_lower_sqrt_price() {
        get_tick_at_sqrt_price(MAX_SQRT_PRICE_X64 + 1);
    }

    #[test]
    #[expected_failure]
    fun test_get_tick_at_invalid_upper_sqrt_price() {
        get_tick_at_sqrt_price(MIN_SQRT_PRICE_X64 - 1);
    }
}

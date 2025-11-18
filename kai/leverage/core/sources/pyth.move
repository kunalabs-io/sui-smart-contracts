// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Pyth price feed integration for Kai Leverage.
module kai_leverage::pyth;

use pyth::i64;
use pyth::price::Price;
use pyth::price_info::{Self, PriceInfoObject, PriceInfo};
use std::type_name::{TypeName};
use std::u64;
use sui::clock::Clock;
use sui::vec_map::{Self, VecMap};

const EUnsupportedCoinType: u64 = 0;
const EStalePrice: u64 = 1;
const EPriceUndefined: u64 = 2;

const SUI_TYPE_NAME: vector<u8> = b"0000000000000000000000000000000000000000000000000000000000000002::sui::SUI";
const WHUSDCE_TYPE_NAME: vector<u8> = b"5d4b302506645c37ff133b98c4b50a5ae14841659738d6d733d59d0d217a93bf::coin::COIN";
const WHUSDTE_TYPE_NAME: vector<u8> = b"c060006111016b8a020ad5b33834984a437aaa7d3c74c18e09a95d48aceab08c::coin::COIN";
const USDC_TYPE_NAME: vector<u8> = b"dba34672e30cb065b1f93e3ab55318768fd6fef66c15942c9f7cb846e2f900e7::usdc::USDC";
const SUIUSDT_TYPE_NAME: vector<u8> = b"375f70cf2ae4c00bf37117d0c85a2c71545e6ee05c4a5c7d282cd66a4504b068::usdt::USDT";
const USDY_TYPE_NAME: vector<u8> = b"960b531667636f39e85867775f52f6b1f220a058c4de786905bdf761e06a56bb::usdy::USDY";
const DEEP_TYPE_NAME: vector<u8> = b"deeb7a4662eec9f2f3def03fb937a663dddaa2e215b8078a284d026b7946c270::deep::DEEP";
const WAL_TYPE_NAME: vector<u8> = b"356a26eb9e012a68958082340d4c4116e7f55615cf27affcff209cf0ae544f59::wal::WAL";
const LBTC_TYPE_NAME: vector<u8> = b"3e8e9423d80e1774a7ca128fccd8bf5f1f7753be658c5e645929037f7c819040::lbtc::LBTC";
const WBTC_TYPE_NAME: vector<u8> = b"aafb102dd0902f5055cadecd687fb5b71ca82ef0e0285d90afde828ec58ca96b::btc::BTC";
const XBTC_TYPE_NAME: vector<u8> = b"876a4b7bce8aeaef60464c11f4026903e9afacab79b9b142686158aa86560b50::xbtc::XBTC";

/// Collection of Pyth price information objects.
public struct PythPriceInfo has copy, drop {
    pio_map: VecMap<ID, PriceInfo>,
    current_ts_sec: u64,
    max_age_secs: u64,
}

/// Validated Pyth price information ready for calculations.
public struct ValidatedPythPriceInfo has copy, drop {
    map: VecMap<TypeName, PriceInfo>,
    current_ts_sec: u64,
    max_age_secs: u64,
}

/// Create a new Pyth price info collection.
public fun create(clock: &Clock): PythPriceInfo {
    PythPriceInfo {
        pio_map: vec_map::empty(),
        current_ts_sec: clock.timestamp_ms() / 1000,
        max_age_secs: 0,
    }
}

/// Add a price info object to the collection.
public fun add(self: &mut PythPriceInfo, info: &PriceInfoObject) {
    let price_info = price_info::get_price_info_from_price_info_object(info);
    let price = price_info.get_price_feed().get_price();

    let key = object::id(info);
    if (!self.pio_map.contains(&key)) {
        self.pio_map.insert(key, price_info);
    };

    let age = self.current_ts_sec - price.get_timestamp();
    self.max_age_secs = u64::max(self.max_age_secs, age);
}

/// Validate price info against age limits and allowlist.
public fun validate(
    info: &PythPriceInfo,
    max_age_secs: u64,
    pio_allowlist: &VecMap<TypeName, ID>,
): ValidatedPythPriceInfo {
    assert!(info.max_age_secs <= max_age_secs, EStalePrice);

    let mut map = vec_map::empty();
    let mut i = 0;
    let n = pio_allowlist.length();
    while (i < n) {
        let (coin_type, id) = pio_allowlist.get_entry_by_idx(i);
        let price_info = info.pio_map[id];

        vec_map::insert(&mut map, *coin_type, price_info);

        i = i + 1;
    };

    ValidatedPythPriceInfo {
        map,
        current_ts_sec: info.current_ts_sec,
        max_age_secs: info.max_age_secs,
    }
}

/// Get the maximum age of price feeds in seconds.
public fun max_age_secs(self: &ValidatedPythPriceInfo): u64 {
    self.max_age_secs
}

#[allow(implicit_const_copy)]
/// Get the decimal places for a supported token type.
public fun decimals(`type`: TypeName): u8 {
    let type_name = `type`.as_string().as_bytes();

    if (type_name == &SUI_TYPE_NAME) {
        9
    } else if (type_name == &WHUSDCE_TYPE_NAME) {
        6
    } else if (type_name == &WHUSDTE_TYPE_NAME) {
        6
    } else if (type_name == &USDC_TYPE_NAME) {
        6
    } else if (type_name == &SUIUSDT_TYPE_NAME) {
        6
    } else if (type_name == &USDY_TYPE_NAME) {
        6
    } else if (type_name == &DEEP_TYPE_NAME) {
        6
    } else if (type_name == &WAL_TYPE_NAME) {
        9
    } else if (type_name == &LBTC_TYPE_NAME) {
        8
    } else if (type_name == &WBTC_TYPE_NAME) {
        8
    } else if (type_name == &XBTC_TYPE_NAME) {
        8
    } else {
        abort (EUnsupportedCoinType)
    }
}

/// Get the current price for a token type.
public fun get_price(self: &ValidatedPythPriceInfo, `type`: TypeName): Price {
    let info = vec_map::get(&self.map, &`type`);
    info.get_price_feed().get_price()
}

/// Get the EMA price for a token type.
public fun get_ema_price(self: &ValidatedPythPriceInfo, `type`: TypeName): Price {
    let info = vec_map::get(&self.map, &`type`);
    info.get_price_feed().get_ema_price()
}

fun get_price_lo_hi_expo_dec(
    price_info: &ValidatedPythPriceInfo,
    t: TypeName,
): (u64, u64, u64, u64, u64) {
    let price = get_price(price_info, t);

    let conf = price.get_conf();
    let p = i64::get_magnitude_if_positive(&price.get_price());
    let expo = i64::get_magnitude_if_negative(&price.get_expo());
    let dec = decimals(t) as u64;

    (p, p - conf, p + conf, expo, dec)
}

fun get_ema_price_lo_hi_expo_dec(
    price_info: &ValidatedPythPriceInfo,
    t: TypeName,
): (u64, u64, u64, u64, u64) {
    let price = get_ema_price(price_info, t);

    let conf = price.get_conf();
    let p = i64::get_magnitude_if_positive(&price.get_price());
    let expo = i64::get_magnitude_if_negative(&price.get_expo());
    let dec = decimals(t) as u64;

    (p, p - conf, p + conf, expo, dec)
}

fun div_price_numeric_x128_inner(
    price_info: &ValidatedPythPriceInfo,
    x: TypeName,
    y: TypeName,
    use_ema: bool,
): u256 {
    let (price_x, _, _, ex, dx) = if (use_ema) {
        get_ema_price_lo_hi_expo_dec(price_info, x)
    } else {
        get_price_lo_hi_expo_dec(price_info, x)
    };
    let (price_y, _, _, ey, dy) = if (use_ema) {
        get_ema_price_lo_hi_expo_dec(price_info, y)
    } else {
        get_price_lo_hi_expo_dec(price_info, y)
    };

    let (scale_num, scale_denom) = if (ey + dy > ex + dx) {
        let exp = (ey + dy - ex - dx as u8);
        (u64::pow(10, exp), 1)
    } else {
        let exp = (ex + dx - ey - dy as u8);
        (1, u64::pow(10, exp))
    };

    assert!(price_y > 0, EPriceUndefined);

    let val =
        ((price_x as u256) * (scale_num as u256) << 128) /
            ((price_y as u256) * (scale_denom as u256));

    let q64_128_max = ((1 << 64) << 128) - 1;
    assert!(val <= q64_128_max, EPriceUndefined);

    val
}

/// Returns the price of `Y` in `X` such that `X * price = Y` i.e. `price = Y / X`.
/// The returned value is in Q64.128 format.
public fun div_price_numeric_x128(
    price_info: &ValidatedPythPriceInfo,
    x: TypeName,
    y: TypeName,
): u256 {
    div_price_numeric_x128_inner(price_info, x, y, false)
}

/// Returns the price of `Y` in `X` such that `X * price = Y` i.e. `price = Y / X`.
/// The returned value is in Q64.128 format.
/// Uses EMA price instead of spot price.
public fun div_ema_price_numeric_x128(
    price_info: &ValidatedPythPriceInfo,
    x: TypeName,
    y: TypeName,
): u256 {
    div_price_numeric_x128_inner(price_info, x, y, true)
}

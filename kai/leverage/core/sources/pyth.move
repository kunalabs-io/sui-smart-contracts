// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_leverage::pyth;

use pyth::i64;
use pyth::price::Price;
use pyth::price_info::{Self, PriceInfoObject, PriceInfo};
use std::type_name::{Self, TypeName};
use std::u64;
use sui::clock::Clock;
use sui::sui::SUI;
use sui::vec_map::{Self, VecMap};
use usdc::usdc::USDC;
use whusdce::coin::COIN as WHUSDCE;
use whusdte::coin::COIN as WHUSDTE;
use suiusdt::usdt::USDT as SUIUSDT;
use usdy::usdy::USDY;
use deep::deep::DEEP;
use wal::wal::WAL;
use lbtc::lbtc::LBTC;
use wbtc::btc::BTC as WBTC;
use xbtc::xbtc::XBTC;

const EUnsupportedPriceFeed: u64 = 0;
const EStalePrice: u64 = 1;
const EPriceUndefined: u64 = 2;

public struct PythPriceInfo has copy, drop {
    pio_map: VecMap<ID, PriceInfo>,
    current_ts_sec: u64,
    max_age_secs: u64,
}

public struct ValidatedPythPriceInfo has copy, drop {
    map: VecMap<TypeName, PriceInfo>,
    current_ts_sec: u64,
    max_age_secs: u64,
}

public fun create(clock: &Clock): PythPriceInfo {
    PythPriceInfo {
        pio_map: vec_map::empty(),
        current_ts_sec: clock.timestamp_ms() / 1000,
        max_age_secs: 60,
    }
}

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

public fun validate(
    info: &PythPriceInfo,
    max_age_secs: u64,
    pio_allowlist: &VecMap<TypeName, ID>,
): ValidatedPythPriceInfo {
    assert!(info.max_age_secs <= max_age_secs, EStalePrice);

    let mut map = vec_map::empty();
    let mut i = 0;
    let n = pio_allowlist.size();
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

public fun max_age_secs(self: &ValidatedPythPriceInfo): u64 {
    self.max_age_secs
}

public fun decimals(`type`: TypeName): u8 {
    if (`type` == type_name::get<SUI>()) {
        9
    } else if (`type` == type_name::get<WHUSDCE>()) {
        6
    } else if (`type` == type_name::get<WHUSDTE>()) {
        6
    } else if (`type` == type_name::get<USDC>()) {
        6
    } else if (`type` == type_name::get<SUIUSDT>()) {
        6
    } else if (`type` == type_name::get<USDY>()) {
        6
    } else if (`type` == type_name::get<DEEP>()) {
        6
    } else if (`type` == type_name::get<WAL>()) {
        9
    } else if (`type` == type_name::get<LBTC>()) {
        8
    } else if (`type` == type_name::get<WBTC>()) {
        8
    } else if (`type` == type_name::get<XBTC>()) {
        8
    } else {
        abort (EUnsupportedPriceFeed)
    }
}

public fun get_price(self: &ValidatedPythPriceInfo, `type`: TypeName): Price {
    let info = vec_map::get(&self.map, &`type`);
    info.get_price_feed().get_price()
}

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

/// Returns the price of `Y` in `X` such that `X * price = Y` i.e. `price = Y / X`.
/// The returned value is in Q64.128 format.
public fun div_price_numeric_x128(
    price_info: &ValidatedPythPriceInfo,
    x: TypeName,
    y: TypeName,
): u256 {
    let (price_x, _, _, ex, dx) = get_price_lo_hi_expo_dec(price_info, x);
    let (price_y, _, _, ey, dy) = get_price_lo_hi_expo_dec(price_info, y);

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

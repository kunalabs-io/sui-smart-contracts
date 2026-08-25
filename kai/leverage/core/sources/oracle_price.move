// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Rail-agnostic oracle price collection for Kai Leverage.
///
/// Oracle data is reduced to plain numbers at ingestion (`add_*`), so the
/// downstream interface never mentions an oracle package's types and a new
/// oracle rail is a purely additive `add_<rail>` function in an upgrade.
/// Entry points take `&PriceCollection` forever; the caller picks the rail
/// by choosing which `add_*` to call, and the per-market config allowlist
/// (object IDs) decides which price objects actually validate.
module kai_leverage::oracle_price;

use pyth_pro::i64 as pro_i64;
use pyth_pro::price_info::{Self as pro_price_info, PriceInfoObject as ProPriceInfoObject};
use std::type_name::{Self, TypeName};
use std::u64;
use sui::clock::Clock;
use sui::coin_registry::Currency;
use sui::vec_map::{Self, VecMap};

const EStalePrice: u64 = 1;
const EPriceUndefined: u64 = 2;
const EPriceObjectMissing: u64 = 3;
const ESmoothedPriceUnavailable: u64 = 4;
const EDecimalsMissing: u64 = 5;

/// A single oracle price point. `price` is always positive and `expo_neg`
/// is the magnitude of the (always negative) decimal exponent — both
/// enforced at ingestion, so garbage feeds abort at `add_*`, not mid-math.
public struct Quote has copy, drop {
    price: u64,
    /// Dispersion behind the price (Pyth confidence, Switchboard stdev, …).
    /// `None` = the rail provides none — deliberately distinct from zero,
    /// which would claim perfect confidence. Reserved: not consumed yet.
    conf: Option<u64>,
    expo_neg: u64,
}

/// Price data for one oracle price object, reduced to plain numbers.
public struct PriceData has copy, drop {
    spot: Quote,
    /// Manipulation-resistant reference price (Pyth fills this with EMA).
    /// The *role*, not the provenance. `None` = the rail provides none;
    /// consumers abort rather than silently substituting spot — adopting a
    /// rail without native smoothing is a risk-policy decision taken in
    /// config and code, never a silent fill at ingestion.
    smoothed: Option<Quote>,
    timestamp_sec: u64,
}

/// Collection of oracle price data, keyed by the on-chain price object's ID
/// (which is what config allowlists reference). Coin decimals ride along as
/// caller-supplied evidence sourced from the system coin registry.
public struct PriceCollection has copy, drop {
    map: VecMap<ID, PriceData>,
    decimals: VecMap<TypeName, u8>,
    created_at_sec: u64,
}

/// Validated price set, keyed by coin type — the only thing position math
/// accepts. Constructible solely via `validate`.
public struct ValidatedPrices has copy, drop {
    map: VecMap<TypeName, PriceData>,
    decimals: VecMap<TypeName, u8>,
    current_ts_sec: u64,
    max_age_secs: u64,
}

/// Create a new, empty price collection.
public fun create(clock: &Clock): PriceCollection {
    PriceCollection {
        map: vec_map::empty(),
        decimals: vec_map::empty(),
        created_at_sec: clock.timestamp_ms() / 1000,
    }
}

/// Add a price from the Pyth Pro ("pro-compatible") package's price object.
public fun add_pyth_pro(self: &mut PriceCollection, info: &ProPriceInfoObject) {
    let key = object::id(info);
    if (self.map.contains(&key)) {
        return
    };

    let price_info = pro_price_info::get_price_info_from_price_info_object(info);
    let price_feed = price_info.get_price_feed();
    let price = price_feed.get_price();
    let ema = price_feed.get_ema_price();

    let data = PriceData {
        spot: Quote {
            price: pro_i64::get_magnitude_if_positive(&price.get_price()),
            conf: option::some(price.get_conf()),
            expo_neg: pro_i64::get_magnitude_if_negative(&price.get_expo()),
        },
        smoothed: option::some(Quote {
            price: pro_i64::get_magnitude_if_positive(&ema.get_price()),
            conf: option::some(ema.get_conf()),
            expo_neg: pro_i64::get_magnitude_if_negative(&ema.get_expo()),
        }),
        timestamp_sec: price.get_timestamp(),
    };
    self.map.insert(key, data);
}

/// Record the decimals for coin type `T` from its canonical registry
/// `Currency<T>` object (`sui::coin_registry`, shared object `0xc`) —
/// uniqueness per coin type is enforced by the framework, so the value is
/// evidence, not caller opinion.
public fun add_currency<T>(self: &mut PriceCollection, currency: &Currency<T>) {
    let key = type_name::with_defining_ids<T>();
    if (self.decimals.contains(&key)) {
        return
    };
    self.decimals.insert(key, currency.decimals());
}

/// Validate a collection against a config's age limit and allowlist.
/// Staleness is checked per allowlisted entry — only feeds the config
/// relies on gate validation. Every allowlisted coin must also carry a
/// registry-sourced decimals entry (`add_currency`).
public(package) fun validate(
    self: &PriceCollection,
    max_age_secs: u64,
    price_object_allowlist: &VecMap<TypeName, ID>,
): ValidatedPrices {
    let mut map = vec_map::empty();
    let mut decimals = vec_map::empty();
    let mut max_age_seen = 0;
    let mut i = 0;
    let n = price_object_allowlist.length();
    while (i < n) {
        let (coin_type, id) = price_object_allowlist.get_entry_by_idx(i);
        let data_opt = self.map.try_get(id);
        assert!(data_opt.is_some(), EPriceObjectMissing);
        let data = data_opt.destroy_some();

        let age = self.created_at_sec - data.timestamp_sec;
        assert!(age <= max_age_secs, EStalePrice);
        max_age_seen = u64::max(max_age_seen, age);

        let dec_opt = self.decimals.try_get(coin_type);
        assert!(dec_opt.is_some(), EDecimalsMissing);

        map.insert(*coin_type, data);
        decimals.insert(*coin_type, dec_opt.destroy_some());
        i = i + 1;
    };

    ValidatedPrices {
        map,
        decimals,
        current_ts_sec: self.created_at_sec,
        max_age_secs: max_age_seen,
    }
}

/// Maximum observed age among the validated price feeds, in seconds.
public fun max_age_secs(self: &ValidatedPrices): u64 {
    self.max_age_secs
}

/// Get the spot quote for a coin type.
public fun get_price(self: &ValidatedPrices, `type`: TypeName): Quote {
    let data = &self.map[&`type`];
    data.spot
}

/// Get the smoothed (manipulation-resistant reference) quote for a coin
/// type. Aborts if the rail that supplied this price provides none —
/// substituting spot here is a risk-policy decision that must be taken
/// explicitly in code, never implied.
public fun get_smoothed_price(self: &ValidatedPrices, `type`: TypeName): Quote {
    let data = &self.map[&`type`];
    assert!(data.smoothed.is_some(), ESmoothedPriceUnavailable);
    *data.smoothed.borrow()
}

public fun quote_price(self: &Quote): u64 { self.price }

public fun quote_conf(self: &Quote): Option<u64> { self.conf }

public fun quote_expo_neg(self: &Quote): u64 { self.expo_neg }

/// Get the registry-sourced decimal places for a validated coin type.
public fun decimals(self: &ValidatedPrices, `type`: TypeName): u8 {
    *self.decimals.get(&`type`)
}

fun quote_price_expo_dec(self: &ValidatedPrices, quote: &Quote, t: TypeName): (u64, u64, u64) {
    (quote.price, quote.expo_neg, decimals(self, t) as u64)
}

fun div_numeric_x128_inner(
    self: &ValidatedPrices,
    x: TypeName,
    y: TypeName,
    use_smoothed: bool,
): u256 {
    let (price_x, ex, dx) = if (use_smoothed) {
        quote_price_expo_dec(self, &get_smoothed_price(self, x), x)
    } else {
        quote_price_expo_dec(self, &get_price(self, x), x)
    };
    let (price_y, ey, dy) = if (use_smoothed) {
        quote_price_expo_dec(self, &get_smoothed_price(self, y), y)
    } else {
        quote_price_expo_dec(self, &get_price(self, y), y)
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
public fun div_price_numeric_x128(self: &ValidatedPrices, x: TypeName, y: TypeName): u256 {
    div_numeric_x128_inner(self, x, y, false)
}

/// Returns the price of `Y` in `X` such that `X * price = Y` i.e. `price = Y / X`.
/// The returned value is in Q64.128 format.
/// Uses the smoothed (manipulation-resistant) price instead of spot.
public fun div_smoothed_price_numeric_x128(
    self: &ValidatedPrices,
    x: TypeName,
    y: TypeName,
): u256 {
    div_numeric_x128_inner(self, x, y, true)
}

#[test, expected_failure(abort_code = ESmoothedPriceUnavailable)]
fun get_smoothed_price_aborts_when_rail_provides_none() {
    // No live rail can produce `smoothed: none` (Pyth always fills it) —
    // built by struct literal here precisely because it must be
    // unreachable through the public API.
    let t = std::type_name::with_defining_ids<sui::sui::SUI>();
    let data = PriceData {
        spot: Quote { price: 3_50 * 10u64.pow(6), conf: option::none(), expo_neg: 8 },
        smoothed: option::none(),
        timestamp_sec: 1755000000,
    };
    let mut map = vec_map::empty();
    map.insert(t, data);
    let validated = ValidatedPrices {
        map,
        decimals: vec_map::empty(),
        current_ts_sec: 1755000000,
        max_age_secs: 0,
    };
    get_smoothed_price(&validated, t);
}

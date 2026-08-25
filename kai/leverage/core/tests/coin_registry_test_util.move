// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module kai_leverage::coin_registry_test_util;

use std::unit_test::destroy;
use sui::coin;
use sui::coin_registry::{Self, CoinRegistry, Currency};
use sui::test_utils;

/// Create a test `CoinRegistry`. The tx sender must be `@0x0`
/// (`tx_context::dummy()` or a `test_scenario` tx from `@0`).
public fun create_registry_for_testing(ctx: &mut TxContext): CoinRegistry {
    coin_registry::create_coin_data_registry_for_testing(ctx)
}

#[allow(deprecated_usage)]
/// Create a canonical `Currency<T>` in the given test registry via the
/// legacy-metadata migration path (`coin::create_currency` mirrors how the
/// production coins were actually registered). `T` must be OTW-shaped (the
/// vendored test coins' witnesses, `sui::sui::SUI`, wormhole `::coin::COIN`).
public fun create_currency_for_testing<T: drop>(
    registry: &mut CoinRegistry,
    decimals: u8,
    ctx: &mut TxContext,
): Currency<T> {
    let otw = test_utils::create_one_time_witness<T>();
    let (treasury_cap, metadata) = coin::create_currency(
        otw,
        decimals,
        b"COIN",
        b"",
        b"",
        option::none(),
        ctx,
    );
    let currency = coin_registry::migrate_legacy_metadata_for_testing(registry, &metadata, ctx);
    destroy(treasury_cap);
    destroy(metadata);
    currency
}

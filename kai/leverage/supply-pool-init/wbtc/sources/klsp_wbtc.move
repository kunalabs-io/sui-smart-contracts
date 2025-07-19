// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module klsp_wbtc::klwbtc;

use kai_leverage::equity;
use klsp_init::init;
use wbtc::btc::BTC as WBTC;

public struct KLWBTC has drop {}

fun init(w: KLWBTC, ctx: &mut TxContext) {
    let decimals = 8;
    let symbol = b"klWBTC";
    let name = b"klWBTC";
    let description = b"Kai Leverage WBTC Supply Pool LP Token";
    let icon_url = option::none();
    let (treasury, coin_metadata) = equity::create_treasury(
        w,
        decimals,
        symbol,
        name,
        description,
        icon_url,
        ctx,
    );

    let sender = tx_context::sender(ctx);
    let ticket = init::new_pool_creation_ticket<WBTC, KLWBTC>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

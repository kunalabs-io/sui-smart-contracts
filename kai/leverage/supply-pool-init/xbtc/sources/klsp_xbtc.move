// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module klsp_xbtc::klxbtc;

use kai_leverage::equity;
use klsp_init::init;
use xbtc::xbtc::XBTC;

public struct KLXBTC has drop {}

fun init(w: KLXBTC, ctx: &mut TxContext) {
    let decimals = 8;
    let symbol = b"klXBTC";
    let name = b"klXBTC";
    let description = b"Kai Leverage XBTC Supply Pool LP Token";
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
    let ticket = init::new_pool_creation_ticket<XBTC, KLXBTC>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

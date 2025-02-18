// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module klsp_deep::kldeep;

use kai_leverage::equity;
use klsp_init::init;
use deep::deep::DEEP;

public struct KLDEEP has drop {}

fun init(w: KLDEEP, ctx: &mut TxContext) {
    let decimals = 6;
    let symbol = b"klDEEP";
    let name = b"klDEEP";
    let description = b"Kai Leverage DEEP Supply Pool LP Token";
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
    let ticket = init::new_pool_creation_ticket<DEEP, KLDEEP>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

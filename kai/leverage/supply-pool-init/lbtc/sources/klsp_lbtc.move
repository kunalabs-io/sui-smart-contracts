// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module klsp_lbtc::kllbtc;

use kai_leverage::equity;
use klsp_init::init;
use lbtc::lbtc::LBTC;

public struct KLLBTC has drop {}

fun init(w: KLLBTC, ctx: &mut TxContext) {
    let decimals = 8;
    let symbol = b"klLBTC";
    let name = b"klLBTC";
    let description = b"Kai Leverage LBTC Supply Pool LP Token";
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
    let ticket = init::new_pool_creation_ticket<LBTC, KLLBTC>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

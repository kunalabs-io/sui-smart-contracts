// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module klsp_usdsui::klusdsui;

use kai_leverage::equity;
use klsp_init::init;
use usdsui::usdsui::USDSUI;

public struct KLUSDSUI has drop {}

#[allow(deprecated_usage)]
fun init(w: KLUSDSUI, ctx: &mut TxContext) {
    let decimals = 6;
    let symbol = b"klUSDSUI";
    let name = b"klUSDSUI";
    let description = b"Kai Leverage USDSUI Supply Pool LP Token";
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
    let ticket = init::new_pool_creation_ticket<USDSUI, KLUSDSUI>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

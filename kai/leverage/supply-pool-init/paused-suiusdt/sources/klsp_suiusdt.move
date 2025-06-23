// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module paused_klsp_suiusdt::klsuiusdt;

use kai_leverage::equity;
use klsp_init::init;
use suiusdt::usdt::USDT as SUIUSDT;

public struct KLSUIUSDT has drop {}

fun init(w: KLSUIUSDT, ctx: &mut TxContext) {
    let decimals = 6;
    let symbol = b"klsuiUSDT";
    let name = b"klsuiUSDT";
    let description = b"Kai Leverage suiUSDT Supply Pool LP Token";
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
    let ticket = init::new_pool_creation_ticket<SUIUSDT, KLSUIUSDT>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

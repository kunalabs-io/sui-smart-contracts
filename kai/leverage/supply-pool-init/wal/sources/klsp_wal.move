// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module klsp_wal::klwal;

use kai_leverage::equity;
use klsp_init::init;
use wal::wal::WAL;

public struct KLWAL has drop {}

fun init(w: KLWAL, ctx: &mut TxContext) {
    let decimals = 9;
    let symbol = b"klWAL";
    let name = b"klWAL";
    let description = b"Kai Leverage WAL Supply Pool LP Token";
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
    let ticket = init::new_pool_creation_ticket<WAL, KLWAL>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_ywhusdte_ysui::ywhusdte;

use sui::coin;

public struct YWHUSDTE has drop {}

#[lint_allow(share_owned)]
fun init(witness: YWHUSDTE, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        6,
        b"yUSDT",
        b"",
        b"",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

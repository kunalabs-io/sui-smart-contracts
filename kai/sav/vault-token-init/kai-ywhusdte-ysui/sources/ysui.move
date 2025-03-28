// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_ywhusdte_ysui::ysui;

use sui::coin;

public struct YSUI has drop {}

#[lint_allow(share_owned)]
fun init(witness: YSUI, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        9,
        b"ySUI",
        b"",
        b"",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_yusdsui::yusdsui;

use sui::coin;

public struct YUSDSUI has drop {}

#[lint_allow(share_owned)]
fun init(witness: YUSDSUI, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        6,
        b"yUSDSUI",
        b"Kai Vault USDSUI",
        b"Kai Vault yield-bearing USDSUI",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

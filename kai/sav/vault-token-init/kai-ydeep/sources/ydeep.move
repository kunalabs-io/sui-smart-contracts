// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_ydeep::ydeep;

use sui::coin;

public struct YDEEP has drop {}

#[lint_allow(share_owned)]
fun init(witness: YDEEP, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        6,
        b"yDEEP",
        b"Kai Vault DEEP",
        b"Kai Vault yield-bearing DEEP",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

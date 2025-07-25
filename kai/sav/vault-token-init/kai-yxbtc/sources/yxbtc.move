// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_yxbtc::yxbtc;

use sui::coin;

public struct YXBTC has drop {}

#[lint_allow(share_owned)]
fun init(witness: YXBTC, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        8,
        b"yXBTC",
        b"Kai Vault xBTC",
        b"Kai Vault yield-bearing xBTC",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

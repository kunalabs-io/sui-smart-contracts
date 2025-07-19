// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_ywbtc::ywbtc;

use sui::coin;

public struct YWBTC has drop {}

#[lint_allow(share_owned)]
fun init(witness: YWBTC, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        8,
        b"yWBTC",
        b"Kai Vault wBTC",
        b"Kai Vault yield-bearing wBTC",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

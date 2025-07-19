// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_ylbtc::ylbtc;

use sui::coin;

public struct YLBTC has drop {}

#[lint_allow(share_owned)]
fun init(witness: YLBTC, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        8,
        b"yLBTC",
        b"Kai Vault LBTC",
        b"Kai Vault yield-bearing Lombard LBTC",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

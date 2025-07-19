// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_ywal::ywal;

use sui::coin;

public struct YWAL has drop {}

#[lint_allow(share_owned)]
fun init(witness: YWAL, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        9,
        b"yWAL",
        b"Kai Vault WAL",
        b"Kai Vault yield-bearing WAL",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

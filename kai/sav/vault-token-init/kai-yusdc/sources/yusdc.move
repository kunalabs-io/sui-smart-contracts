// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_yusdc::yusdc;

use sui::coin;

public struct YUSDC has drop {}

#[lint_allow(share_owned)]
fun init(witness: YUSDC, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        6,
        b"yUSDC",
        b"",
        b"",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

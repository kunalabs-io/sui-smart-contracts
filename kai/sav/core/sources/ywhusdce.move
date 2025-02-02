// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_sav::ywhusdce;

use kai_sav::vault;
use sui::coin;
use whusdce::coin::COIN as WHUSDCE;

public struct YWHUSDCE has drop {}

#[lint_allow(share_owned)]
fun init(witness: YWHUSDCE, ctx: &mut TxContext) {
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

    let admin_cap = vault::new<WHUSDCE, YWHUSDCE>(treasury, ctx);
    transfer::public_transfer(admin_cap, tx_context::sender(ctx));
}

// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module klsp_usdc::klusdc;

use kai_leverage::equity;
use klsp_init::init;
use usdc::usdc::USDC;

public struct KLUSDC has drop {}

fun init(w: KLUSDC, ctx: &mut TxContext) {
    let decimals = 6;
    let symbol = b"klUSDC-2";
    let name = b"klUSDC-2";
    let description = b"Kai Leverage USDC Supply Pool LP Token";
    let icon_url = option::none();
    let (treasury, coin_metadata) = equity::create_treasury(
        w,
        decimals,
        symbol,
        name,
        description,
        icon_url,
        ctx,
    );

    let sender = tx_context::sender(ctx);
    let ticket = init::new_pool_creation_ticket<USDC, KLUSDC>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

module klsp_whusdte::klwhusdte;

use kai_leverage::equity;
use klsp_init::init;
use whusdte::coin::COIN as WHUSDTE;

public struct KLWHUSDTE has drop {}

fun init(w: KLWHUSDTE, ctx: &mut TxContext) {
    let decimals = 6;
    let symbol = b"klWHUSDTE";
    let name = b"klWHUSDTE";
    let description = b"Kai Leverage WHUSDTE Supply Pool LP Token";
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
    let ticket = init::new_pool_creation_ticket<WHUSDTE, KLWHUSDTE>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

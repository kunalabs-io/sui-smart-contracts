module klsp_usdy::klusdy;

use kai_leverage::equity;
use klsp_init::init;
use usdy::usdy::USDY;

public struct KLUSDY has drop {}

fun init(w: KLUSDY, ctx: &mut TxContext) {
    let decimals = 6;
    let symbol = b"klUSDY";
    let name = b"klUSDY";
    let description = b"Kai Leverage USDY Supply Pool LP Token";
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
    let ticket = init::new_pool_creation_ticket<USDY, KLUSDY>(treasury, ctx);
    transfer::public_transfer(ticket, sender);
    transfer::public_transfer(coin_metadata, sender);
}

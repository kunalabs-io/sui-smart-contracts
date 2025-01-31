module klsp_whusdce::klwhusdce {
    use kai_leverage::equity;
    use klsp_init::init;
    use whusdce::coin::COIN as WHUSDCE;

    public struct KLWHUSDCE has drop {}

    fun init(w: KLWHUSDCE, ctx: &mut TxContext) {
        let decimals = 6;
        let symbol = b"klWHUSDCE";
        let name = b"klWHUSDCE";
        let description = b"Kai Leverage WHUSDCE Supply Pool LP Token";
        let icon_url = option::none();
        let (treasury, coin_metadata) = equity::create_treasury(
            w, decimals, symbol, name, description, icon_url, ctx 
        );

        let sender = tx_context::sender(ctx);
        let ticket = init::new_pool_creation_ticket<WHUSDCE, KLWHUSDCE>(treasury, ctx);
        transfer::public_transfer(ticket, sender);
        transfer::public_transfer(coin_metadata, sender);
    }
}

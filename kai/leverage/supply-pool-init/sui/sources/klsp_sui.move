module klsp_sui::klsui {
    use kai_leverage::equity;
    use klsp_init::init;
    use sui::sui::SUI;

    public struct KLSUI has drop {}

    fun init(w: KLSUI, ctx: &mut TxContext) {
        let decimals = 6;
        let symbol = b"klSUI";
        let name = b"klSUI";
        let description = b"Kai Leverage SUI Supply Pool LP Token";
        let icon_url = option::none();
        let (treasury, coin_metadata) = equity::create_treasury(
            w, decimals, symbol, name, description, icon_url, ctx 
        );

        let sender = tx_context::sender(ctx);
        let ticket = init::new_pool_creation_ticket<SUI, KLSUI>(treasury, ctx);
        transfer::public_transfer(ticket, sender);
        transfer::public_transfer(coin_metadata, sender);
    }
}

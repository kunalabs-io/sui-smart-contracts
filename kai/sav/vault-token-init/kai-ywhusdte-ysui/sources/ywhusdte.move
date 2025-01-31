module kai_ywhusdte_ysui::ywhusdte {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin;
    use std::option;

    struct YWHUSDTE has drop {}

    #[lint_allow(share_owned)]
    fun init(witness: YWHUSDTE, ctx: &mut TxContext) {
        let (treasury, meta) = coin::create_currency(
            witness, 6, b"yUSDT", b"", b"", option::none(), ctx
        );
        transfer::public_share_object(meta);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }
}
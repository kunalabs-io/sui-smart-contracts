module kai_ywhusdte_ysui::ysui {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin;
    use std::option;

    struct YSUI has drop {}

    #[lint_allow(share_owned)]
    fun init(witness: YSUI, ctx: &mut TxContext) {
        let (treasury, meta) = coin::create_currency(
            witness, 9, b"ySUI", b"", b"", option::none(), ctx
        );
        transfer::public_share_object(meta);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }
}
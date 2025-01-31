module kai_yusdc::yusdc {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin;
    use std::option;

    struct YUSDC has drop {}

    #[lint_allow(share_owned)]
    fun init(witness: YUSDC, ctx: &mut TxContext) {
        let (treasury, meta) = coin::create_currency(
            witness, 6, b"yUSDC", b"", b"", option::none(), ctx
        );
        transfer::public_share_object(meta);
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }
}
module yieldoptimizer::ywhusdte {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin;
    use std::option;
    use yieldoptimizer::vault;

    use whusdte::coin::COIN as WHUSDTE;

    struct YWHUSDTE has drop {}

    #[lint_allow(share_owned)]
    fun init(witness: YWHUSDTE, ctx: &mut TxContext) {
        let (treasury, meta) = coin::create_currency(
            witness, 6, b"yUSDT", b"", b"", option::none(), ctx
        );
        transfer::public_share_object(meta);

        let admin_cap = vault::new<WHUSDTE, YWHUSDTE>(treasury, ctx);
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
    }
}
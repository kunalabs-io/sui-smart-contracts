/*
    NOTE: This module is deprecated. It was added in an upgrade which means that
    the init function wasn't called. The related `TreasuryCap` was never created
    and so wasn't the `Vault`.
*/
module kai::ywhusdte {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin;
    use std::option;
    use kai::vault;

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
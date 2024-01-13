/*
    NOTE: This module is deprecated. It was added in an upgrade which means that
    the init function wasn't called. The related `TreasuryCap` was never created
    and so wasn't the `Vault`.
    The corrected package was published at `0xb8dc843a816b51992ee10d2ddc6d28aab4f0a1d651cd7289a7897902eb631613`.
*/
module kai::ysui {
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin;
    use sui::sui::SUI;
    use std::option;
    use kai::vault;

    struct YSUI has drop {}

    #[lint_allow(share_owned)]
    fun init(witness: YSUI, ctx: &mut TxContext) {
        let (treasury, meta) = coin::create_currency(
            witness, 9, b"ySUI", b"", b"", option::none(), ctx
        );
        transfer::public_share_object(meta);

        let admin_cap = vault::new<SUI, YSUI>(treasury, ctx);
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
    }
}
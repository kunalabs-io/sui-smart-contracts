module kai_yusdy::yusdy;

use sui::coin;

public struct YUSDY has drop {}

#[lint_allow(share_owned)]
fun init(witness: YUSDY, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        6,
        b"yUSDY",
        b"Kai Vault USDY",
        b"Kai Vault yield-bearing USDY",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

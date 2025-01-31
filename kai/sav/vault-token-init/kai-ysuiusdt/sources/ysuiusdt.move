module kai_ysuiusdt::ysuiusdt;

use sui::coin;

public struct YSUIUSDT has drop {}

#[lint_allow(share_owned)]
fun init(witness: YSUIUSDT, ctx: &mut TxContext) {
    let (treasury, meta) = coin::create_currency(
        witness,
        6,
        b"ysuiUSDT",
        b"Kai Vault suiUSDT",
        b"Kai Vault yield-bearing suiUSDT",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    transfer::public_transfer(treasury, tx_context::sender(ctx));
}

/// The functions in this module help with dealing with Coin objects that have
/// different value than desired on the client side.

module 0x0::periphery {
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use 0x0::amm::{Self, Pool, PoolRegistry};

    /// Splits the provided Coin to desired amount (if needed) and returns it.
    /// Transfers the remainder to the sender.
    public fun maybe_split_and_transfer_rest<T>(
        input: Coin<T>, amount: u64, recipient: address, ctx: &mut TxContext
    ): Coin<T> {
        if (coin::value(&input) == amount) {
            return input
        };

        let out = coin::split(&mut input, amount, ctx);
        transfer::transfer(input, recipient);

        return out
    }

    /// Splits the input Coins to desired values and then does the pool creation. Returns the remainders
    /// to the sender (if any).
    public entry fun maybe_split_then_create_pool<A, B>(
        registry: &mut PoolRegistry,
        input_a: Coin<A>,
        amount_a: u64,
        input_b: Coin<B>,
        amount_b: u64,
        lp_fee_bps: u64,
        admin_fee_pct: u64,
        ctx: &mut TxContext
    ) {
        let init_a = maybe_split_and_transfer_rest(input_a, amount_a, tx_context::sender(ctx), ctx);
        let init_b = maybe_split_and_transfer_rest(input_b, amount_b, tx_context::sender(ctx), ctx);
        amm::create_pool_(registry, init_a, init_b, lp_fee_bps, admin_fee_pct, ctx);
    }

    /// Splits the input Coin to desired value and then does the swap. Returns the remainder
    /// to the sender (if any).
    public entry fun maybe_split_then_swap_a<A, B>(
        pool: &mut Pool<A, B>, input: Coin<A>, amount: u64, min_out: u64, ctx: &mut TxContext
    ) {
        let input = maybe_split_and_transfer_rest(input, amount, tx_context::sender(ctx), ctx);
        amm::swap_a_(pool, input, min_out, ctx);
    }

    /// Splits the input Coin to desired value and then does the swap. Returns the remainder
    /// to the sender (if any).
    public entry fun maybe_split_then_swap_b<A, B>(
        pool: &mut Pool<A, B>, input: Coin<B>, amount: u64, min_out: u64, ctx: &mut TxContext
    ) {
        let input = maybe_split_and_transfer_rest(input, amount, tx_context::sender(ctx), ctx);
        amm::swap_b_(pool, input, min_out, ctx);
    }

    /// Splits the input Coins to desired values and then does the deposit. Returns the remainders
    /// to the sender (if any).
    public entry fun maybe_split_then_deposit<A, B>(
        pool: &mut Pool<A, B>,
        input_a: Coin<A>,
        amount_a: u64,
        input_b: Coin<B>,
        amount_b: u64,
        min_lp_out: u64,
        ctx: &mut TxContext
    ) {
        let input_a = maybe_split_and_transfer_rest(input_a, amount_a, tx_context::sender(ctx), ctx);
        let input_b = maybe_split_and_transfer_rest(input_b, amount_b, tx_context::sender(ctx), ctx);
        amm::deposit_(pool, input_a, input_b, min_lp_out, ctx);
    }
}

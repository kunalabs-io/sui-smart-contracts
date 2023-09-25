/// This module contains some helper functions to work with pools that are members of only one farm for convenience
/// (avoids the need to use `TopUpTicket` manually).

module token_distribution::pool_util {
    use sui::balance::{Balance};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::clock::Clock;
    use token_distribution::farm::{Farm};
    use token_distribution::pool::{Self, Pool, Stake};

    public fun single_deposit_shares_new<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, balance: Balance<S>, clock: &Clock, ctx: &mut TxContext
    ): Stake<S> {
        let ticket = pool::new_top_up_ticket(pool);
        pool::top_up(farm, pool, &mut ticket, clock);
        pool::deposit_shares_new(pool, balance, ticket, ctx)
    }

    public fun single_deposit_shares_new_and_transfer<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, coin: Coin<S>, clock: &Clock, ctx: &mut TxContext
    ) {
        let stake = single_deposit_shares_new(farm, pool, coin::into_balance(coin), clock, ctx);
        transfer::public_transfer(stake, tx_context::sender(ctx));
    }

    public fun single_deposit_shares<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, stake: &mut Stake<S>, balance: Balance<S>, clock: &Clock
    ) {
        let ticket = pool::new_top_up_ticket(pool);
        pool::top_up(farm, pool, &mut ticket, clock);
        pool::deposit_shares(pool, stake, balance, ticket);
    }

    public fun single_deposit_shares_coin<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, stake: &mut Stake<S>, coin: Coin<S>, clock: &Clock
    ) {
        single_deposit_shares(farm, pool, stake, coin::into_balance(coin), clock);
    }

    public fun single_withdraw_shares<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, stake: &mut Stake<S>, amount: u64, clock: &Clock
    ): Balance<S> {
        let ticket = pool::new_top_up_ticket(pool);
        pool::top_up(farm, pool, &mut ticket, clock);
        pool::withdraw_shares(pool, stake, amount, ticket)
    }

    public fun single_withdraw_shares_and_transfer<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, stake: &mut Stake<S>, amount: u64, clock: &Clock, ctx: &mut TxContext
    ) {
        let balance = single_withdraw_shares(farm, pool, stake, amount, clock);
        transfer::public_transfer(coin::from_balance(balance, ctx), tx_context::sender(ctx))
    }

    public fun single_collect_all_rewards<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, stake: &mut Stake<S>, clock: &Clock
    ): Balance<T> {
        let ticket = pool::new_top_up_ticket(pool);
        pool::top_up(farm, pool, &mut ticket, clock);
        pool::collect_all_rewards(pool, stake, ticket)
    }

    public fun single_collect_all_rewards_and_transfer<T, S>(
        farm: &mut Farm<T>, pool: &mut Pool<S>, stake: &mut Stake<S>, clock: &Clock, ctx: &mut TxContext
    ) {
        let balance = single_collect_all_rewards(farm, pool, stake, clock);
        transfer::public_transfer(coin::from_balance(balance, ctx), tx_context::sender(ctx))
    }
}
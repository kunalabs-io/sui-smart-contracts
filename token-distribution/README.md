# Token Distribution Protocol

A highly composable, flexible, and modular token distribution protocol for Sui.
It consists of low-level building blocks and higher-level components that can be used
to implement various token distribution schemes, such as vesting and liquidity mining.

## Overview

This modules in this package are split into "primitives" and "farm" subfolders.

Primitives:

- `time_locked_balance`
- `time_distributor`
- `accumulation_distributor`

Farm:

- `farm`
- `pool`

The primitives implement different core functionalities (math and accounting) but cannot be used directly from the client side -- they're used as building blocks for other modules.

Farm is a composable liquidity mining smart contract that uses the primitives under the hood and implements functionality similar to one pioneered by SushiSwap where a token (reward) is distributed across multiple different pools each of which can have any number of participants deposit stake and receive their share of rewards.

## Primitives

### Time Locked Balance

`TimeLockedBalance` locks a `Balance<T>` such that only `unlock_per_second` of the amount
gets unlocked (and becomes withdrawable) every second starting from `unlock_start_ts`.
It allows for `unlock_per_second` and `unlock_start_ts` to be safely changed and allows for aditional
balance to be added at any point via the `top_up` function.

This module doesn't implement any permission functionality and it is intended to be used
as a basic building block and to provide safety guarantees for building more complex token
emission modules (e.g. vesting).

### Time Distributor

`TimeDistributor` is component that locks a `Balance<T>` and then distributes it over time to
multiple (arbitrary) members where each member recieves a share proportional to its "weight".

For example, if the distributor has a balance of 100 with an unlock rate of 10 per second and 2 members with
wieghts of 100 and 300, the the duration of the distribution will be 10 seconds and the members
will recieve 25 and 75 of the original balance respectively.

The difference between this module and `accumulation_distributor` is that here the distribution balance is
pre-allocated and distributed over time using the internal `time_locked_balance` continuously instead of
being distributed using manual top-ups discretely. Also, since member weights are all stored in the distributor
object, any member's weight can be modified by the holder of the distributor object (but this also means there's
a limit to the number of members since most of the operations are `O(n)`).

This module doesn't implement any permission functionality and it's intended to be used as a
building block for other modules.

Usage:

```move
// create time distributor
let td = td::create<SUI, ID>(balance, 10);
let id: ID = <...>;
td::add_member(&mut td, id, 100, &time);
td::change_unlock_per_second(&mut td, id, &time);

// after some time, member withdraw
let balance = member_withdraw_all(&mut td, &id, &time);
```

The functioning of `TimeDistributor` is defined through the following adjustable parameters:

- distribution start (`change_unlock_start_ts`)
- distribution rate (`change_unlock_per_second`)
- balance to distribute (`top_up`)
- members and their weights (`add_member`, `remove_member`, `change_weight`, and similar)

Internally, members are stored in a `vec_map` and can be referenced (e.g. when collecting their unlocked balance)
either using their `vec_map` index or their key. The key can be of any type that has `copy`
capability (its exact type is defined during `TimeDistributor` creation by the caller).

The distributor avoids rounding errors whenever possible. For example, if the distribution rate is 13 per second
and there are two members with equal weights, and if a members withdraws after the first second
it will recieve 6 (nominally it should be 6.5 but it rounds down). But then if there's another withdraw
after the second second it will recieve 7 making the total over two seconds for that member 13 as expected (26 / 2).

In some situations, the balance amount can't be distributed exactly across all members. This can happen when:

- the total balance amount isn't evenly divisible w.r.t. member weights (e.g. the balance is 55 and there
  are two members with equal weights)
- a function that changes one of the parameters (distribution start, adding / removing members or changing
  their weight, changing distribution rate) is called before the distribution is finished
  In the above cases (due to rounding down) there can be a remainder balance. This balance will be topped up back
  to the distributor having the same effect as calling the `top_up` function with it - either it will end up as
  "extraneous balance" or it will prolong the duration of the distribution (increment `final_unlock_ts`).
  Ultimately, all deposited balance is accounted for - ether it will be distributed to memers or be stored
  as extraneous.

Extraneous balance is balance that cannot be evenly distributed w.r.t. the initial balance amount and
`unlock_per_second` value. E.g., if the initial balance is 55 and `unlock_per_second` is 50 then extraneous
balance is 5 (see `time_locked_balance` module docs for more info). When `unlock_per_second` is 0 then
all of the balance in the distributor (that hasne't already been distributed to members) is considered extraneous.

Distributor's `unlock_per_second` is always `0` when there are no members. Calling `change_unlock_per_second`
with a positive value when there are no members will result in an error `ENoMembers`. Removing the last member
will automatically set `unlock_per_second` to `0`. If a member is later added (on an empty distributor),
`unlock_per_second` also needs to be set to start the distribution again.

Almost all operations are `O(n)` (where `n` is the number of members). The exceptions are:

- `member_withdraw_all_by_idx` (`O(1)`)
- `member_withdraw_all` (`O(n)` only in the worst case due to `vec_map` key lookup)
- `top_up` (`O(1)` if it's called before `final_unlock_ts` and `O(n)` if it's called after)

### Accumulation Distributor

`AccumulationDistributor` is a component that distributes balances to multiple participants
proportionally based on the number number of "shares" they have staked in the distributor.
Unlike the `TimeDistributor` the emissions are not based on the passage of time but rather
on discrete (manual) deposits using the `top_up` function.

For example, if there are two positions with 100 and 300 shares each, and if a balance
of 100 of coin type `T` is then deposited (via the `top_up` function) into the distributor,
the stake holders will recieve 25 and 75 of the deposited balance respectively.

This distributor can handle distribution of multiple different coin types simultaniously
(notice that the `AccumulationDistributor` struct has no type parameters). This works transparently
by simply depositing any coin type at any time using the `top_up` function. The heterogeneous coin
balances are stored internally using `sui::bag`.

When there is no stake in the distributor (`total_shares` is 0), then the `top_up` deposits
go to the `extraneous_balances` bag and can be withdrawn directly by the owner of the
`AccumulationDistributor` object (they don't get distributed to stake holders).

This module doesn't implement any permission functionality and it's intended to be used as a
building block for other modules.

Usage:

```move
let ad = ad::create(&mut ctx);
let position = ad::deposit_shares_new(&mut ad, 100);

let balance: Balance<FOO> = <...>;
ad::top_up(&mut ad, balance);

let balance = ad::withdraw_all_unlocked<FOO>(&mut ad, &mut position);
```

Since stake holder positions are stored as separate `Position` objects, this distributor has virtually
no limit on the number of participants that can provide the stake. The limitation is only on the number of
distinct coin types that are handeled by the distributor due to which there is `O(n)` complexity on
certain operations (`top_up`, `deposit_shares_new`, `deposit_shares`, `withdraw_shares`, and `merge_positions`).

## Farm and Pool

### Farm

`Farm` is essentially a wrapper around `TimeDistributor` and implements permission functionality
on top of it with composability and flexibility in mind.

It's intended to be used with `Pool` (from the `token_distribution::pool` module) to enable yield farming
functionality where an amount of coins is allocated to be distributed across multiple different
pools in each of which any number of participants can deposit tokens to recieve a share of the
rewards (similar to liquidity mining functionality pioneered by SushiSwap and then implemented by
many other DeFi platforms also).

Nonetheless, it is not required to use this module with `Pool`. In order to add a member to a `Farm`,
one creates a `FarmMemberKey` (anyone is allowed to create it), and then an admin can add this key
to a `Farm` and adjust its weight. The owner of `FarmMemberKey` has the authority to withdraw
rewards distributed for that key. This setup allows for any custom implementation of `Pool` to
transparently work with this module.

A `FarmMemberKey` can be a member of multiple `Farms` at once and there is support for enforcing
atomic withdrawals from all the farms the key is a member of (implemented via the
`MemberWithdrawAllTicket` hot potato struct). This allows for `Pools` to distribute rewards
of multiple different token types simultaneously.
///
Usage:

```
let admin_cap = admin_cap::create(ctx);
let farm = farm::create(balance, 1670758154, admin_cap);

let key = farm::create_member_key(ctx);
farm::add_member(&admin_cap, &mut farm, &mut key, 100, &time);
farm::change_unlock_per_second(&admin_cap, &mut farm, 50, &time);

/// some time later...
let balance = farm::mebmer_withdraw_all(&mut farm, &mut key, &time);
```

Similar to `TimeDistributor` most operations are `O(n)` where `n` is the number of members. See
`TimeDistributor` docs for more details.

### Pool

`Pool` is a wrapper around `AccumulationDistributor` intended to be used with `Farm` to enable
any amount of participants to receive coin emissions proportional to their stake (shares in the pool).

A `Pool` can be a member of multiple `Farms` simultaneously which means that stake holders
can recieve rewards in multiple different currencies at once, but the currency used to provide
stake is limited only to one type `S`. Anyone is allowed to deposit shares into the pool.

Since a `Pool` can be a member of multiple `Farms`, for correctness, a lot of operations require
`TopUpTicket` to be used. `TupUpTicket` is a wrapper arround `token_distribution::farm::MemberWithdrawAllTicket` and
guarantees that the pool is fully topped up with (potentially heterogeneous) balances from all the `Farms`
the pool is a member of. This is needed to guarantee the correctness of the reward amounts distributed
to each stake holder w.r.t. their share amount.

Usage:

```
// create pool
let pool_cap = admin_cap::create(ctx);
let pool = pool::create<FOO>(&pool_cap, ctx);
pool::add_to_farm(&farm_cap, farm, &pool_cap, &mut pool, 100, &time);

// deposit shares
let ticket = pool::new_top_up_ticket ;
pool::top_up(farm, &mut pool, &mut ticket, &time);
let balance: Balance<FOO> = <...>;
let stake = pool::deposit_shares_new(&mut pool, balance, ticket, ctx);

// collect rewards (some time later)
let ticket = pool::new_top_up_ticket ;
pool::top_up(farm, &mut pool, &mut ticket, &time);
let balance = pool::collect_all_rewards(&mut pool, &mut stake, ticket);
```

Similar to `AccumulationDistributor`, there is virtually no limit on the number of stake holders
that can participate in the `Pool`. The limits are on the number of distinct coin types handled by
the pool and the number of farms the pool is a member of (both at separately at `O(n)`).

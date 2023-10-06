# Token Distribution Protocol

A highly composable, flexible, and modular token distribution protocol for Sui.
It consists of low-level building blocks and higher-level components that can be used
to implement various token distribution schemes, such as vesting and liquidity mining.

## Overview

The modules in this package are split into "primitives" and "farm" subfolders.

Primitives:

- `time_locked_balance`
- `time_distributor`
- `accumulation_distributor`

Farm:

- `farm`
- `pool`

The **primitives** implement different core functionalities (math and accounting) but cannot be used directly from the client side -- they're used as building blocks for other modules.

For example, you can deposit some tokens into `TimeLockedBalance` and send it over to another person, where the tokens you deposited will be unlocked gradually over time as a basic form of vesting. The recipient retains direct ownership of these tokens but can only withdraw them as they get unlocked over time on a second-by-second basis. You can configure the unlock start time on it, and you have a cliff.

The `TimeDistributor` is a generalization of `TimeLockedBalance` (and uses it internally) such that it's able to distribute tokens over time to multiple beneficiaries based on weights. For example, suppose you want to distribute a set amount of tokens to 5 beneficiaries over time, where one should receive 50% of the total tokens and the remaining 4 each 12.5%. You can easily achieve this functionality with the `TimeDistributor` by setting appropriate weights for each beneficiary. The `TimeDistributor` also allows you to dynamically change the distribution rate, add or remove beneficiaries, or change beneficiaries' weights at any time without losing precision.

The `AccumulationDistributor` is analogous to the `TimeDistributor` in that it distributes tokens to multiple beneficiaries but uses different math internally to achieve different properties. For example, one of the limitations of the `TimeDistributor` is that it's limited w.r.t. the number of beneficiaries it can accommodate since it exhibits `O(n)` on most of its operations (`n` being the number of beneficiaries). `AccumulationDistributor`, on the other hand, can accommodate virtually any number of beneficiaries since its operations are `O(1)`. It doesn't distribute tokens over time but works such that when you deposit tokens into it, they get distributed proportionally to all the beneficiaries at once based on the amount of their current shares. `AccumulationDistributor` also transparently supports the handling of multiple token types at once, so rewards can get distributed in the form of multiple different tokens, which can be added dynamically without any additional interaction from the beneficiaries.

You can now see that by combining these primitives, you can achieve higher-level functionality, such as advanced forms of vesting and liquidity mining.

The composable **Farm** smart contract uses the above primitives to implement liquidity mining functionality. It operates similarly to the contracts pioneered by SushiSwap, where a token (reward) is distributed across multiple pools. Each pool can have multiple liquidity providers, of which each will receive their share of the rewards.

The protocol has been constructed to enable some very powerful features. For example, each `Pool` can be a member of multiple different `Farms`, which means that users who stake in `Pool` can receive rewards in multiple different tokens. These `Farm` memberships for each `Pool` can be dynamically added and removed by the admin at any time without any loss of rewards or additional steps required for the users.

To give a more concrete example, suppose a DEX creates liquidity mining pools for their AMM pairs where they distribute their native token as rewards. Now, suppose another project lists its token on this DEX. While this newly listed pair already receives rewards in the form of DEX' native token, the project creators can incentivize additional liquidity on that pair by distributing additional rewards to the LPs in the form of other tokens. The DEX owners retain control over which additional rewards are allowed to be distributed (allow or deny another `Farm` on the `Pool`), and the project owners retain control over the distribution rate of the rewards they have added (distribution rate on the added `Farm`, given it's allowed by the DEX). Once a `Pool` has been added to an additional `Farm`, the users start receiving the additional rewards immediately.

Additionally, it is not a requirement that a `Pool` object is the only type that is allowed to join a `Farm`. You can have any custom type be a member of a `Farm`. This gives you the flexibility to create custom `Pool` implementations or any other way for collecting the rewards.

## Implementation and Usage

### Time Locked Balance

`TimeLockedBalance` locks a `Balance<T>` such that only `unlock_per_second` of the amount
gets unlocked (and becomes withdrawable) every second, starting from `unlock_start_ts`.
It allows for `unlock_per_second` and `unlock_start_ts` to be safely changed and allows for additional
balance to be added at any point via the `top_up` function.

This module doesn't implement any permission functionality. It is intended to be used
as a basic building block and to provide safety guarantees for building more complex token
emission modules (e.g. vesting).

### Time Distributor

`TimeDistributor` is a primitive that locks a `Balance<T>` and then distributes it over time to
multiple (arbitrary) beneficiaries where each beneficiary receives a share proportional to its "weight".

For example, if the distributor has a balance of 100 with an unlock rate of 10 per second and 2 beneficiaries with
weights of 100 and 300, the duration of the distribution will be 10 seconds, and the beneficiaries
will receive 25 and 75 of the original balance.

The difference between this module and `accumulation_distributor` is that here the distribution balance is
pre-allocated and distributed over time using the internal `time_locked_balance` continuously instead of
being distributed using manual top-ups discretely. Also, since member weights are all stored in the distributor
object, any member's weight can be modified by the holder of the distributor object (but this also means there is
a limit to the number of beneficiaries since most of the operations are `O(n)`).

This module doesn't implement any permission functionality, and it's intended to be used as a
building block for other modules.

Usage:

```move
// create time distributor
let td = td::create<SUI, ID>(balance, 10);
let id: ID = <...>;
td::add_member(&mut td, id, 100, &time);
td::change_unlock_per_second(&mut td, id, &time);

// after some time, member withdraws
let balance = member_withdraw_all(&mut td, &id, &time);
```

The functioning of `TimeDistributor` is defined through the following adjustable parameters:

- distribution start (`change_unlock_start_ts`)
- distribution rate (`change_unlock_per_second`)
- balance to distribute (`top_up`)
- beneficiaries aka members and their weights (`add_member`, `remove_member`, `change_weight`, and similar)

Internally, members are stored in a `vec_map` and can be referenced (e.g. when collecting their unlocked balance)
either using their `vec_map` index or their key. The key can be of any type that has `copy`
capability (its exact type is defined during `TimeDistributor` creation by the caller).

The distributor avoids rounding errors whenever possible. For example, if the distribution rate is 13 per second
and there are two members with equal weights, and if a member withdraws after the first second,
it will receive 6 (nominally, it should be 6.5, but it rounds down). But then, if there's another withdrawal
after the 2nd second, it will receive 7, making the total over two seconds for that member 13 as expected (26 / 2).

In some situations, the balance amount can't be distributed exactly across all members. This can happen when:

- the total balance amount isn't evenly divisible w.r.t. member weights (e.g. the balance is 55 and there
  are two members with equal weights)
- a function that changes one of the parameters (distribution start, adding/removing members, or changing
  their weight, changing distribution rate) is called before the distribution is finished
  In the above cases (due to rounding down), there can be a remainder balance. This balance will be topped up back
  to the distributor having the same effect as calling the `top_up` function with it - either it will end up as
  "extraneous balance" or it will prolong the duration of the distribution (increment `final_unlock_ts`).
  Ultimately, all deposited balance is accounted for - either it will be distributed to members or be stored
  as extraneous.

Extraneous balance is a balance that cannot be evenly distributed w.r.t. the initial balance amount and
`unlock_per_second` value. E.g., if the initial balance is 55 and `unlock_per_second` is 50, then the extraneous
balance is 5 (see `time_locked_balance` module docs for more info). When `unlock_per_second` is 0, then
all of the balance in the distributor (that hasn't already been distributed to members) is considered extraneous.

Distributor's `unlock_per_second` is always `0` when there are no members. Calling `change_unlock_per_second`
with a positive value when there are no members will result in an error `ENoMembers`. Removing the last member
will automatically set `unlock_per_second` to `0`. If a member is later added (on an empty distributor),
`unlock_per_second` also needs to be set to start the distribution again.

Almost all operations are `O(n)` (where `n` is the number of members). The exceptions are:

- `member_withdraw_all_by_idx` (`O(1)`)
- `member_withdraw_all` (`O(n)` only in the worst case due to `vec_map` key lookup)
- `top_up` (`O(1)` if it's called before `final_unlock_ts` and `O(n)` if it's called after)

### Accumulation Distributor

`AccumulationDistributor` is a component that distributes balances to multiple beneficiaries
proportionally based on the number of "shares" they have staked in the distributor.
Unlike the `TimeDistributor`, the emissions are not based on the passage of time but rather
on discrete (manual) deposits using the `top_up` function.

For example, if there are two positions with 100 and 300 shares each, and if a balance
of 100 of coin type `T` is then deposited (via the `top_up` function) into the distributor,
the stakeholders will receive 25 and 75 of the deposited balance, respectively.

This distributor can handle the distribution of multiple coin types simultaneously
(notice that the `AccumulationDistributor` struct has no type parameters). This works transparently
by simply depositing any coin type at any time using the `top_up` function. The heterogeneous coin
balances are stored internally using `sui::bag`.

When there is no stake in the distributor (`total_shares` is 0), then the `top_up` deposits
go to the `extraneous_balances` bag and can be withdrawn directly by the owner of the
`AccumulationDistributor` object (they don't get distributed to stakeholders).

This module doesn't implement any permission functionality, and it's intended to be used as a
building block for other modules.

Usage:

```move
let ad = ad::create(&mut ctx);
let position = ad::deposit_shares_new(&mut ad, 100);

let balance: Balance<FOO> = <...>;
ad::top_up(&mut ad, balance);

let balance = ad::withdraw_all_unlocked<FOO>(&mut ad, &mut position);
```

Since stakeholder positions are stored as separate `Position` objects, this distributor has virtually
no limit on the number of participants that can provide the stake. The limitation is only on the number of
distinct coin types that are handled by the distributor due to which there is `O(n)` complexity on
certain operations (`top_up`, `deposit_shares_new`, `deposit_shares`, `withdraw_shares`, and `merge_positions`).

### Farm

`Farm` is essentially a wrapper around `TimeDistributor` and implements permission functionality
on top of it, with composability and flexibility in mind.

It's intended to be used with `Pool` (from the `token_distribution::pool` module) to enable yield farming
functionality where an amount of coins is allocated to be distributed across multiple different
pools in each of which any number of liquidity providers can deposit tokens to receive a share of the
rewards (similar to liquidity mining functionality pioneered by SushiSwap and then implemented by
many other DeFi platforms also).

Nonetheless, it is not required to use this module with `Pool`. In order to add a member to a `Farm`,
one creates a `FarmMemberKey` (anyone is allowed to create it), and then an admin can add this key
to a `Farm` and adjust its weight. The owner of `FarmMemberKey` has the authority to withdraw
rewards distributed for that key. This setup allows for any custom implementation of `Pool` to
work transparently with this module.

A `FarmMemberKey` can be a member of multiple `Farms` at once, and there is support for enforcing
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

Like `TimeDistributor`, most operations are `O(n)` where `n` is the number of members. See
`TimeDistributor` docs for more details.

### Pool

`Pool` is a wrapper around `AccumulationDistributor` intended to be used with `Farm` to enable
any amount of participants to receive coin emissions proportional to their stake (shares in the pool).

A `Pool` can be a member of multiple `Farms` simultaneously, which means that stakeholders
can receive rewards in multiple different currencies at once, but the currency used to provide
stake is limited only to one type, `S`. Anyone is allowed to deposit shares into the pool.

Since a `Pool` can be a member of multiple `Farms`, for correctness, a lot of operations require
`TopUpTicket` to be used. `TupUpTicket` is a wrapper around `token_distribution::farm::MemberWithdrawAllTicket` and
guarantees that the pool is fully topped up with (potentially heterogeneous) balances from all the `Farms`
the pool is a member of. This is needed to guarantee the correctness of the reward amounts distributed
to each stakeholder w.r.t. their share amount.

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

// collect rewards (sometime later)
let ticket = pool::new_top_up_ticket ;
pool::top_up(farm, &mut pool, &mut ticket, &time);
let balance = pool::collect_all_rewards(&mut pool, &mut stake, ticket);
```

Similar to `AccumulationDistributor`, there is virtually no limit on the number of stakeholders
that can participate in the `Pool`. The limits are on the number of distinct coin types handled by
the pool and the number of farms the pool is a member of. Each is limited at `O(n)`.

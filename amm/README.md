# AMM

A UniswapV2-style AMM implementation for Sui.

**Features:**
- constant product curve ( $A \cdot B = k$ )
- swap between any `Coin<A>` and `Coin<B>`
- deposit and withdraw liquidity
- permissionless and dynamic pool creation for any `Coin` pair
- LP and admin fee support

## Implementation Notes

### LPCoin

Sui differentiates between different token types (currencies) on the type level statically and not by dynamic checks (like it's the case on non-Move platforms). This provides some very nice safety and ergonomics features but it has some limitations also.

In case of AMMs we want a single smart contract to be able to create multiple different `Pools`, but the LP tokens between different pools musn't be fungible. So if we want to have LP tokens also be of the `Coin` type, we can implement them in one of these two ways:

1. Limit pool creation so that there can only be one pool per token pair (e.g. `Pool<A, B>`) and have the LP coin type for that pool match the pair (e.g. `Coin<LP<A, B>>`)
2. Allow for creation of multiple pools for the same pair but add an additional type parameter `T` to differentiate between them (e.g. `Pool<A, B, T>` and `Coin<LP<A, B, T>>` where `T` is an arbitrary one time witness)

In this implementation I've decided to go with 1. This is because currently there's no way to dynamically create types in Move so acquiring a new one time witness necessary for the pool creation in 2. would require publishing a new module each time. This would mean that it would not be possible (or would be difficult) to enable users to create new pools from the client side.

The limitation of 1. though is that there can be only one `Pool` per token pair. Guaranteeing uniqueness of `Pools` is not yet possible on Sui because there's no support for reflection (it's landed on the main branch but not yet on devnet https://github.com/MystenLabs/sui/issues/4202). To go around this, as a temporary solution I've implemented LP tokens as a special `LPCoin` type which do fungibility checks dynamically (this also coincidentally allows for creation of multiple pools per pair).

Once https://github.com/MystenLabs/sui/issues/4202 lands to devnet I will implement LP tokens to be `Coin`. Additionally, once https://github.com/MystenLabs/sui/issues/4203 becomes available, I will implement the pool uniqueness checks using dynamic child object loading APIs in order to avoid any potential issues with `VecMap` when then number of pools is large as `VecMap` is `O(n)`.

### u128 and u256 math

I've included `u128` and `u256` math libraries which are needed for some operations. Those will be removed as `u256` lands in Move (https://github.com/move-language/move/pull/547) and `u128`/`u256` math functions become available in Move / Sui standard library.


### Prover Specs

I haven't included any Prover specs since the Prover isn't yet available on Sui. I will do once it does.


## TODO
- [ ] TypeScript SDK 
- [ ] implement LP tokens as `Coin` instead of the special `LPCoin` type (requires reflection / dynamic child object loading)
- [ ] make it possible for admin to change fees after pool creation
- [ ] internal price oracle
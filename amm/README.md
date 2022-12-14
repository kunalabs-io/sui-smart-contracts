# AMM

A UniswapV2-style AMM implementation for Sui.

**Features:**

- constant product curve ( $A \cdot B = k$ )
- swap between any `Coin<A>` and `Coin<B>`
- deposit and withdraw liquidity
- permissionless and dynamic pool creation for any `Coin` pair
- LP and admin fee support

## Implementation Notes

### Pool Creation

Sui differentiates between different token types (currencies) on the type level statically and not by dynamic checks (like it's the case on non-Move platforms). This provides some very nice safety and ergonomics features but it has some limitations also.

In case of AMMs we want a single smart contract to be able to create multiple different `Pools`, but the LP tokens between different pools musn't be fungible. So if we want to have LP tokens also be of the `Coin` type, we can implement them in one of these two ways:

1. Limit pool creation so that there can only be one pool per token pair (e.g. `Pool<A, B>`) and have the LP coin type for that pool match the pair (e.g. `Coin<LP<A, B>>`)
2. Allow for creation of multiple pools for the same pair but add an additional type parameter `T` to differentiate between them (e.g. `Pool<A, B, T>` and `Coin<LP<A, B, T>>` where `T` is an arbitrary one time witness)

In this implementation I've decided to go with 1. This is because currently there's no way to dynamically create types in Move so acquiring a new one time witness necessary for the pool creation in 2. would require publishing a new module each time. This would mean that it would not be possible (or would be difficult) to enable users to create new pools from the client side.

The limitation of 1. though is that there can be only one `Pool` per token pair.

### Periphery

`periphery.move` contains `maybe_split_then...` functions which enable the pool functions be called with Coin objects which have a different (larger) value than desired. This is helpful because otherwise the client-side code would have to create two transactions for each operation -- first split the Coin to desired value and then call the pool function. This is a bit cumbersome because it requires the user to sign two transactions for each call.

## TODO

- [ ] TypeScript SDK
- [ ] make it possible for admin to change fees after pool creation
- [ ] internal price oracle
- [ ] flash lending / swaps

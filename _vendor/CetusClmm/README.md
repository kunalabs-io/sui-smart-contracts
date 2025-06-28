# Cetus clmm interface

This is an endpoint to help everyone integrate with the Cetus CLMM contract.

- [cetus\-clmm\-interface](#cetus-clmm-interface)
  - [Cetus Swap and Liquidity operations](#cetus-swap-and-liquidity-operations)
  - [Tags corresponding to different networks](#tags-corresponding-to-different-networks)
  - [Usage](#usage)
  - [Cetus protocol](#cetus-protocol)
    - [Data Structure](#data-structure)
    - [Function](#function)
  - [Use Case](#use-case)
    - [Position related operations](#position-related-operations)
    - [Pool related operations](#pool-related-operations)

## Cetus Swap and Liquidity operations

This section shows how to construct and execute a trade or liquidity operation on the Cetus protocol.

## Tags corresponding to different networks

| Tag of Repo     | Network | Latest published at address                                        |
| --------------- | ------- | ------------------------------------------------------------------ |
| mainnet-v1.49.0 | mainnet | 0x75b2e9ecad34944b8d0c874e568c90db0cf9437f0d7392abfd4cb902972f3e40 |
| testnet-v1.25.0 | testnet | 0xb2a1d27337788bda89d350703b8326952413bd94b35b9b573ac8401b9803d018 |

eg:

mainnet:

```
CetusClmm = { git = "https://github.com/CetusProtocol/cetus-clmm-interface.git", subdir = "sui/cetus_clmm", rev = "mainnet-v1.49.0" }
```

testnet:

```
CetusClmm = { git = "https://github.com/CetusProtocol/cetus-clmm-interface.git", subdir = "sui/cetus_clmm", rev = "testnet-v1.25.0" }
```

## Usage

Cetus clmm interface is not complete(just have function definition), so it will fails when sui client check the code version. However, this does not affect its actual functionality. Therefore, we need to add a `--dependencies-are-root` during the build.

```bash
sui move build --dependencies-are-root && sui client publish --dependencies-are-root
```

## Cetus protocol

I'll start by presenting and describing the methods used in the cetus contract, then give application examples to help you integrate our algorithm into your own contract.

### Data Structure

1. Position

```rust

/// The Cetus clmmpool's position NFT.
struct Position has key, store {
    id: UID,
    pool: ID,
    index: u64,
    coin_type_a: TypeName,
    coin_type_b: TypeName,
    name: String,
    description: String,
    url: String,
    tick_lower_index: I32,
    tick_upper_index: I32,
    liquidity: u128,
}

```

2. Rewarder

```rust

struct Rewarder has copy, drop, store {
    reward_coin: TypeName,
    emissions_per_second: u128,
    growth_global: u128,
}

```

3. Pool

```rust

/// The clmmpool
struct Pool<phantom CoinTypeA, phantom CoinTypeB> has key, store {
    id: UID,

    coin_a: Balance<CoinTypeA>,
    coin_b: Balance<CoinTypeB>,

    /// The tick spacing
    tick_spacing: u32,

    /// The numerator of fee rate, the denominator is 1_000_000.
    fee_rate: u64,

    /// The liquidity of current tick index
    liquidity: u128,

    /// The current sqrt price
    current_sqrt_price: u128,

    /// The current tick index
    current_tick_index: I32,

    /// The global fee growth of coin a,b as Q64.64
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,

    /// The amounts of coin a,b owned to protocol
    fee_protocol_coin_a: u64,
    fee_protocol_coin_b: u64,

    /// The tick manager
    tick_manager: TickManager,

    /// The rewarder manager
    rewarder_manager: RewarderManager,

    /// The position manager
    position_manager: PositionManager,

    /// is the pool pause
    is_pause: bool,

    /// The pool index
    index: u64,

    /// The url for pool and position
    url: String,

}

```

4. AddLiquidityReceipt

```rust

/// Flash loan resource for add_liquidity
struct AddLiquidityReceipt<phantom CoinTypeA, phantom CoinTypeB> {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64
}

```

5. FlashSwapReceipt

```rust

/// Flash loan resource for swap.
/// There is no way in Move to pass calldata and make dynamic calls, but a resource can be used for this purpose.
/// To make the execution into a single transaction, the flash loan function must return a resource
/// that cannot be copied, cannot be saved, cannot be dropped, or cloned.
struct FlashSwapReceipt<phantom CoinTypeA, phantom CoinTypeB> {
    pool_id: ID,
    a2b: bool,
    partner_id: ID,
    pay_amount: u64,
    ref_fee_amount: u64
}

```

### Function

1. Open position

- cetus_clmm/sources/pool.move

```rust

/// Open a new position within the given tick range in the specified pool.
///
/// # Arguments
///
/// _ `config` - A reference to the `GlobalConfig` object.
/// _ `pool` - A mutable reference to the `Pool` object.
/// _ `tick_lower` - The lower tick index for the pool.
/// _ `tick_upper` - The upper tick index for the pool.
///
/// # Generic Type Parameters
///
/// _ `CoinTypeA` - The type of the first coin in the pool.
/// _ `CoinTypeB` - The type of the second coin in the pool.
///
/// # Returns
///
/// \* `Position` - The new `Position` object that was opened, also means position nft.
public fun open_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower: u32,
    tick_upper: u32,
    ctx: &mut TxContext
): Position {}

```

2. Add liquidity with fixed coin

- cetus_clmm/sources/pool.move

```rust

/// Add liquidity to an existing position in the specified pool by fixing one of the coin types.
///
/// # Arguments
///
/// _ `config` - A reference to the `GlobalConfig` object.
/// _ `pool` - A mutable reference to the `Pool` object.
/// _ `position_nft` - A mutable reference to the `Position` object representing the existing position to add liquidity to.
/// _ `amount` - The amount of the fixed coin type to add to the position.
/// _ `fix_amount_a` - A boolean indicating whether to fix the amount of `CoinTypeA` or `CoinTypeB`.
/// _ `clock` - A reference to the `Clock` object used to determine the current time.
///
/// # Generic Type Parameters
///
/// _ `CoinTypeA` - The type of the first coin in the pool.
/// _ `CoinTypeB` - The type of the second coin in the pool.
///
/// # Returns
///
/// The `AddLiquidityReceipt` object representing the results of the liquidity addition.

public fun add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    amount: u64,
    fix_amount_a: bool,
    clock: &Clock
): AddLiquidityReceipt<CoinTypeA, CoinTypeB> {}

```

3. Repay the receipt about add liquidity

- cetus_clmm/sources/pool.move

```rust

/// Repay the amount of borrowed liquidity and add liquidity to the pool.
///
/// # Arguments
///
/// _ `config` - A reference to the `GlobalConfig` object.
/// _ `pool` - A mutable reference to the `Pool` object.
/// _ `balance_a` - The balance of `CoinTypeA` to use for the repayment.
/// _ `balance_b` - The balance of `CoinTypeB` to use for the repayment.
/// _ `receipt` - The `AddLiquidityReceipt` object representing the liquidity addition results to use for the repayment.
///
/// # Generic Type Parameters
///
/// _ `CoinTypeA` - The type of the first coin in the pool.
/// \* `CoinTypeB` - The type of the second coin in the pool.
pub fun repay_add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    balance_a: Balance<CoinTypeA>,
    balance_b: Balance<CoinTypeB>,
    receipt: AddLiquidityReceipt<CoinTypeA, CoinTypeB>
) {}

```

5. Get position liquidity

- cetus_clmm/sources/position.move

```rust

/// Get the amount of liquidity held in a given position.
///
/// # Arguments
///
/// \* `position_nft` - A reference to the `Position` object to get the liquidity of.
///
/// # Returns
///
/// The amount of liquidity held in the position.
pub fun liquidity(position_nft: &Position): u128 {}

```

6. Remove liquidity

- cetus_clmm/sources/pool.move

```rust

/// Remove liquidity from the pool.
///
/// # Arguments
///
/// _ `config` - A reference to the `GlobalConfig` object.
/// _ `pool` - A mutable reference to the `Pool` object.
/// _ `position_nft` - A mutable reference to the `Position` object representing the liquidity position to remove from.
/// _ `delta_liquidity` - The amount of liquidity to remove. you can use position.liquidity() to get it.
/// _ `clock` - A reference to the `Clock` object used to determine the current time.
///
/// # Generic Type Parameters
///
/// _ `CoinTypeA` - The type of the first coin in the pool.
/// \* `CoinTypeB` - The type of the second coin in the pool.
///
/// # Returns
///
/// A tuple containing the resulting balances of `CoinTypeA` and `CoinTypeB` after removing liquidity.
pub fun remove_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {}

```

7. Collect fee

- cetus_clmm/sources/pool.move

```rust

/// Collect the fees earned from a given position.
///
/// # Arguments
///
/// _ `config` - A reference to the `GlobalConfig` object.
/// _ `pool` - A mutable reference to the `Pool` object.
/// _ `position_nft` - A reference to the `Position` object to collect fees from.
/// _ `recalculate` - A boolean indicating whether to recalculate the fees earned before collecting them.
///
/// # Generic Type Parameters
///
/// _ `CoinTypeA` - The type of the first coin in the pool.
/// _ `CoinTypeB` - The type of the second coin in the pool.
///
/// # Returns
///
/// A tuple containing the updated balances of `CoinTypeA` and `CoinTypeB`.
pub fun collect_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &Position,
    recalculate: bool,
): (Balance<CoinTypeA>, Balance<CoinTypeB>)

```

8. Collect reward

- cetus_clmm/sources/pool.move

```rust

/// Collect reward for a given position.
///
/// # Arguments
///
/// _ config - A reference to the GlobalConfig object.
/// _ pool - A mutable reference to the Pool object.
/// _ position_nft - A reference to the Position object for which to collect rewards.
/// _ vault - A mutable reference to the RewarderGlobalVault object.
/// _ recalculate - A boolean indicating whether to recalculate the reward rate.
/// _ clock - A reference to the Clock object used to determine the current time.
///
/// # Generic Type Parameters
///
/// _ CoinTypeA - The type of the first coin in the pool.
/// _ CoinTypeB - The type of the second coin in the pool.
/// \* CoinTypeC - The type of the reward coin.
///
/// # Returns
///
/// Returns the collected reward as a Balance of type CoinTypeC.

public fun collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &Position,
    vault: &mut RewarderGlobalVault,
    recalculate: bool,
    clock: &Clock
): Balance<CoinTypeC> {}

```

10. Close position

- cetus_clmm/sources/pool.move

```rust

/// Close a position by burning the corresponding NFT.
///
/// # Arguments
///
/// _ config - A reference to the GlobalConfig object.
/// _ pool - A mutable reference to the Pool object.
/// _ position_nft - The Position NFT to burn and close the corresponding position.
///
/// # Generic Type Parameters
///
/// _ CoinTypeA - The type of the first coin in the pool.
/// \* CoinTypeB - The type of the second coin in the pool.
///
/// # Returns
///
/// This function does not return a value.

public fun close_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: Position,
) {}

```

11. Flash loan

- cetus_clmm/sources/pool.move

```rust
    /// Flash loan from pool
    /// Params
    ///     - `config` The global config of clmm package.
    ///     - `pool` The clmm pool object.
    ///     - `loan_a` A flag indicating whether to loan coin A (true) or coin B (false).
    ///     - `amount` The amount to loan.
    /// Returns
    ///     - `Balance<CoinTypeA>` The balance of coin A to loan.
    ///     - `Balance<CoinTypeB>` The balance of coin B to loan.
    ///     - `FlashLoanReceipt` The receipt for repaying the flash loan.
    public fun flash_loan<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        _pool: &mut Pool<CoinTypeA, CoinTypeB>,
        _loan_a: bool,
        _amount: u64
    ): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt) {}
```

12. Flash loan with partner

- cetus_clmm/sources/pool.move

```rust
    /// Flash loan with partner, like flash loan but there has a partner object for receive ref fee.
    /// Params
    ///     - `config` The global config of clmm package.
    ///     - `pool` The clmm pool object.
    ///     - `partner` The partner object for receiving ref fee.
    ///     - `loan_a` A flag indicating whether to loan coin A (true) or coin B (false).
    ///     - `amount` The amount to loan.
    ///     - `clock` The CLOCK of sui framework, used to get current timestamp.
    /// Returns
    ///     - `Balance<CoinTypeA>` The balance of coin A to loan.
    ///     - `Balance<CoinTypeB>` The balance of coin B to loan.
    ///     - `FlashLoanReceipt` The receipt for repaying the flash loan.
    public fun flash_loan_with_partner<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        _pool: &mut Pool<CoinTypeA, CoinTypeB>,
        _partner: &Partner,
        _loan_a: bool,
        _amount: u64,
        _clock: &Clock
    ): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt) {}
```

13. Repay flash loan

- cetus_clmm/sources/pool.move

```rust
    /// Repay for flash loan
    /// Params
    ///     - `config` The global config of clmm package.
    ///     - `pool` The clmm pool object.
    ///     - `balance_a` The balance of `CoinTypeA` will pay for flash loan,
    /// if `loan_a` is true the value need equal `amount + fee_amount` else it need with zero value.
    ///     - `balance_b` The balance of `CoinTypeB` will pay for flash loan,
    /// if `loan_a` is false the value need equal `amount + fee_amount` else it need with zero value.
    ///     - `receipt` The receipt which will be destroyed.
    /// Returns
    ///     Null
    public fun repay_flash_loan<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        _pool: &mut Pool<CoinTypeA, CoinTypeB>,
        _balance_a: Balance<CoinTypeA>,
        _balance_b: Balance<CoinTypeB>,
        _receipt: FlashLoanReceipt,
    ) {}
```

14. Repay flash loan with partner

- cetus_clmm/sources/pool.move

```rust
    /// Repay for flash loan with partner for receive ref fee.
    /// Params
    ///     - `config` The global config of clmm package.
    ///     - `pool` The clmm pool object.
    ///     - `partner` The partner object which will receive ref fee.
    ///     - `balance_a` The balance of `CoinTypeA` will pay for flash loan,
    /// if `loan_a` is true the value need equal `amount + fee_amount` else it need with zero value.
    ///     - `balance_b` The balance of `CoinTypeB` will pay for flash loan,
    /// if `loan_a` is false the value need equal `amount + fee_amount` else it need with zero value.
    ///     - `receipt` The receipt which will be destroyed.
    /// Returns
    ///     Null
    public fun repay_flash_loan_with_partner<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        _pool: &mut Pool<CoinTypeA, CoinTypeB>,
        _partner: &mut Partner,
        _balance_a: Balance<CoinTypeA>,
        _balance_b: Balance<CoinTypeB>,
        _receipt: FlashLoanReceipt,
    ) {}
```

## Use Case

### Position related operations

**Notes**:
Sui does not support passing empty vector, so we provide three functions about add liquidity with different coins.

- pass coin_a and coin_b (all)
- only pass coin_a
- only pass coin_b

1. Open position with liquidity with all.

   If you want to support open_position_with_liquidity_with_all, this method you need to implement by your contract, here the example about it.
   Firstly, you need to open position and get the position nft `Position`.
   Secondly, you need to add liquidity with fixed coin. If `fix_amount_a` is true, it means fixed coin a, others means fixed coin b.
   Finally, you need to repay the receipt when add liquidity.

```rust

public entry fun open_position_with_liquidity_with_all<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower_idx: u32,
    tick_upper_idx: u32,
    coins_a: vector<Coin<CoinTypeA>>,
    coins_b: vector<Coin<CoinTypeB>>,
    amount_a: u64,
    amount_b: u64,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let position_nft = pool::open_position(
        config,
        pool,
        tick_lower_idx,
        tick_upper_idx,
        ctx
    );
    let amount = if (fix_amount_a) amount_a else amount_b;
    let receipt = pool::add_liquidity_fix_coin(
        config,
        pool,
        &mut position_nft,
        amount,
        fix_amount_a,
        clock
    );
    repay_add_liquidity(config, pool, receipt, coins_a, coins_b, amount_a, amount_b, ctx);
    // transfer::public_transfer(position_nft, tx_context::sender(ctx));
}

```

2. Open position with liquidity only coin_a.

   This method is similar to the previous method. The only difference is coin_b is zero.

```rust

public entry fun open_position_with_liquidity_only_a<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower_idx: u32,
    tick_upper_idx: u32,
    coins_a: vector<Coin<CoinTypeA>>,
    amount: u64,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let position_nft = pool::open_position(
        config,
        pool,
        tick_lower_idx,
        tick_upper_idx,
        ctx
    );
    let receipt = pool::add_liquidity_fix_coin(
        config,
        pool,
        &mut position_nft,
        amount,
        true,
        clock
    );
    repay_add_liquidity(config, pool, receipt, coins_a, vector::empty(), amount, 0, ctx);
    transfer::public_transfer(position_nft, tx_context::sender(ctx));
}

```

3. Open position with liquidity only coin_b.

   This method is similar to the previous method. The only difference is coin_a is zero.

```rust

public entry fun open_position_with_liquidity_only_b<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower_idx: u32,
    tick_upper_idx: u32,
    coins_b: vector<Coin<CoinTypeB>>,
    amount: u64,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let position_nft = pool::open_position(
        config,
        pool,
        tick_lower_idx,
        tick_upper_idx,
        ctx
    );
    let receipt = pool::add_liquidity_fix_coin(
        config,
        pool,
        &mut position_nft,
        amount,
        false,
        clock
    );
    repay_add_liquidity(config, pool, receipt, vector::empty(), coins_b, 0, amount, ctx);
    // transfer::public_transfer(position_nft, tx_context::sender(ctx));
}

```

4. Add liquidity with all.

```rust

public entry fun add_liquidity_with_all<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    coins_a: vector<Coin<CoinTypeA>>,
    coins_b: vector<Coin<CoinTypeB>>,
    amount_limit_a: u64,
    amount_limit_b: u64,
    delta_liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let receipt = pool::add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        position_nft,
        delta_liquidity,
        clock
    );
    repay_add_liquidity(config, pool, receipt, coins_a, coins_b, amount_limit_a, amount_limit_b, ctx);
}

```

5. Add liquidity only coin_a.

```rust

public entry fun add_liquidity_only_a<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    coins_a: vector<Coin<CoinTypeA>>,
    amount_limit: u64,
    delta_liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let receipt = pool::add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        position_nft,
        delta_liquidity,
        clock
    );
    repay_add_liquidity(config, pool, receipt, coins_a, vector::empty(), amount_limit, 0, ctx);
}

```

6. Add liquidity only coin_b.

```rust

public entry fun add_liquidity_only_b<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    coins_b: vector<Coin<CoinTypeB>>,
    amount_limit: u64,
    delta_liquidity: u128,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let receipt = pool::add_liquidity<CoinTypeA, CoinTypeB>(
        config,
        pool,
        position_nft,
        delta_liquidity,
        clock
    );
    repay_add_liquidity(config, pool, receipt, vector::empty(), coins_b, 0, amount_limit, ctx);
}

```

7. Remove liquidity

```rust

public entry fun remove_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    min_amount_a: u64,
    min_amount_b: u64,
    clock: &Clock,
    ctx: &mut TxContext
) {
let (balance_a, balance_b) = pool::remove_liquidity<CoinTypeA, CoinTypeB>(
    config,
    pool,
    position_nft,
    delta_liquidity,
    clock
);

    let (fee_a, fee_b) = pool::collect_fee(
        config,
        pool,
        position_nft,
        false
    );

    // you can implement these methods by yourself methods.
    // balance::join(&mut balance_a, fee_a);
    // balance::join(&mut balance_b, fee_b);
    // send_coin(coin::from_balance(balance_a, ctx), tx_context::sender(ctx));
    // send_coin(coin::from_balance(balance_b, ctx), tx_context::sender(ctx));

}

```

8. Close position

```rust

public entry fun close_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: Position,
    min_amount_a: u64,
    min_amount_b: u64,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let all_liquidity = position::liquidity(&mut position_nft);
    if (all_liquidity > 0) {
        remove_liquidity(
            config,
            pool,
            &mut position_nft,
            all_liquidity,
            min_amount_a,
            min_amount_b,
            clock,
            ctx
        );
    };
    pool::close_position<CoinTypeA, CoinTypeB>(config, pool, position_nft);
}

```

9. Collect fee

```rust

public entry fun collect_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position: &mut Position,
    ctx: &mut TxContext,
) {
    let (balance_a, balance_b) = pool::collect_fee<CoinTypeA, CoinTypeB>(config, pool, position, true);
    // send_coin(coin::from_balance<CoinTypeA>(balance_a, ctx), tx_context::sender(ctx));
    // send_coin(coin::from_balance<CoinTypeB>(balance_b, ctx), tx_context::sender(ctx));
}

```

10. Collect reward

```rust

public entry fun collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    vault: &mut RewarderGlobalVault,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let reward_balance = pool::collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
        config,
        pool,
        position_nft,
        vault,
        true,
        clock
    );
    send_coin(coin::from_balance(reward_balance, ctx), tx_context::sender(ctx));
}

```

11. Get coin amount about position: pass pool and position id.

```rust
    /// Calculate the position's amount_a/amount_b
    /// Params
    ///     - `pool` The clmm pool object.
    ///     - `position_id` The object id of position's NFT.
    /// Returns
    ///     - `amount_a` The amount of `CoinTypeA`
    ///     - `amount_b` The amount of `CoinTypeB`
    public fun get_position_amounts<CoinTypeA, CoinTypeB>(
        _pool: &mut Pool<CoinTypeA, CoinTypeB>,
        _position_id: ID,
    ): (u64, u64) {
        abort 0
    }
```

12. Repay add liquidity

```rust

fun repay_add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    receipt: AddLiquidityReceipt<CoinTypeA, CoinTypeB>,
    coins_a: vector<Coin<CoinTypeA>>,
    coins_b: vector<Coin<CoinTypeB>>,
    amount_limit_a: u64,
    amount_limit_b: u64,
    ctx: &mut TxContext
) {
    let (amount_need_a, amount_need_b) = pool::add_liquidity_pay_amount(&receipt);

    // let (balance_a, balance_b) = (
    //     coin::into_balance(coin::split(&mut coin_a, amount_need_a, ctx)),
    //     coin::into_balance(coin::split(&mut coin_b, amount_need_b, ctx)),
    // );

    pool::repay_add_liquidity(config, pool, balance_a, balance_b, receipt);

    // ...

}
```

### Pool related operations

This swap and swap with partner, you need to implement by yourself, here is the example.

```rust

// Swap
fun swap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coins_a: vector<Coin<CoinTypeA>>,
    coins_b: vector<Coin<CoinTypeB>>,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    amount_limit: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let (coin_a, coin_b) = (merge_coins(coins_a, ctx), merge_coins(coins_b, ctx));
    let (receive_a, receive_b, flash_receipt) = pool::flash_swap<CoinTypeA, CoinTypeB>(
        config,
        pool,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        clock
    );
    let (in_amount, out_amount) = (
        pool::swap_pay_amount(&flash_receipt),
        if (a2b) balance::value(&receive_b) else balance::value(&receive_a)
    );

    // pay for flash swap
    let (pay_coin_a, pay_coin_b) = if (a2b) {
        (coin::into_balance(coin::split(&mut coin_a, in_amount, ctx)), balance::zero<CoinTypeB>())
    } else {
        (balance::zero<CoinTypeA>(), coin::into_balance(coin::split(&mut coin_b, in_amount, ctx)))
    };

    coin::join(&mut coin_b, coin::from_balance(receive_b, ctx));
    coin::join(&mut coin_a, coin::from_balance(receive_a, ctx));

    pool::repay_flash_swap<CoinTypeA, CoinTypeB>(
        config,
        pool,
        pay_coin_a,
        pay_coin_b,
        flash_receipt
    );

    // ... send coins

}

/// Swap with partner.
fun swap_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &mut Partner,
    coins_a: vector<Coin<CoinTypeA>>,
    coins_b: vector<Coin<CoinTypeB>>,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    amount_limit: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext
) {
    let (coin_a, coin_b) = (merge_coins(coins_a, ctx), merge_coins(coins_b, ctx));
    let (receive_a, receive_b, flash_receipt) = pool::flash_swap_with_partner<CoinTypeA, CoinTypeB>(
        config,
        pool,
        partner,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        clock
    );
    let (in_amount, out_amount) = (
        pool::swap_pay_amount(&flash_receipt),
        if (a2b) balance::value(&receive_b) else balance::value(&receive_a)
    );

    // pay for flash swap
    let (pay_coin_a, pay_coin_b) = if (a2b) {
        (coin::into_balance(coin::split(&mut coin_a, in_amount, ctx)), balance::zero<CoinTypeB>())
    } else {
        (balance::zero<CoinTypeA>(), coin::into_balance(coin::split(&mut coin_b, in_amount, ctx)))
    };

    coin::join(&mut coin_b, coin::from_balance(receive_b, ctx));
    coin::join(&mut coin_a, coin::from_balance(receive_a, ctx));

    pool::repay_flash_swap_with_partner<CoinTypeA, CoinTypeB>(
        config,
        pool,
        partner,
        pay_coin_a,
        pay_coin_b,
        flash_receipt
    );

    // ... send coins

}

```

1. Swap a to b

```rust

public entry fun swap_a2b<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coins_a: vector<Coin<CoinTypeA>>,
    by_amount_in: bool,
    amount: u64,
    amount_limit: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext
) {
    swap(
        config,
        pool,
        coins_a,
        vector::empty(),
        true,
        by_amount_in,
        amount,
        amount_limit,
        sqrt_price_limit,
        clock,
        ctx
    );
}

```

2. Swap b to a

```rust

public entry fun swap_b2a<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coins_b: vector<Coin<CoinTypeB>>,
    by_amount_in: bool,
    amount: u64,
    amount_limit: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext
) {
    swap(
        config,
        pool,
        vector::empty(),
        coins_b,
        false,
        by_amount_in,
        amount,
        amount_limit,
        sqrt_price_limit,
        clock,
        ctx
    );
}

```

3. Swap a to b with partner

```rust

public entry fun swap_a2b_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &mut Partner,
    coins_a: vector<Coin<CoinTypeA>>,
    by_amount_in: bool,
    amount: u64,
    amount_limit: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext
) {
    swap_with_partner(
        config,
        pool,
        partner,
        coins_a,
        vector::empty(),
        true,
        by_amount_in,
        amount,
        amount_limit,
        sqrt_price_limit,
        clock,
        ctx
    );
}

```

4. Swap b to a with partner

```rust

public entry fun swap_b2a_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &mut Partner,
    coins_b: vector<Coin<CoinTypeB>>,
    by_amount_in: bool,
    amount: u64,
    amount_limit: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
    ctx: &mut TxContext
) {
    swap_with_partner(
        config,
        pool,
        partner,
        vector::empty(),
        coins_b,
        false,
        by_amount_in,
        amount,
        amount_limit,
        sqrt_price_limit,
        clock,
        ctx
    );
}

```

5. Pre swap
   clmmpool/sources/pool

```rust

/// The step swap result
struct SwapStepResult has copy, drop, store {
    current_sqrt_price: u128,
    target_sqrt_price: u128,
    current_liquidity: u128,
    amount_in: u64,
    amount_out: u64,
    fee_amount: u64,
    remainer_amount: u64
}

/// The calculated swap result
struct CalculatedSwapResult has copy, drop, store {
    amount_in: u64,
    amount_out: u64,
    fee_amount: u64,
    fee_rate: u64,
    after_sqrt_price: u128,
    is_exceed: bool,
    step_results: vector<SwapStepResult>
}
// Calculate Swap Result

public fun calculate_swap_result<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
): CalculatedSwapResult {}

```

6. Flash loan

```rust
     let (balance_a, balance_b, receipt) = pool::flash_loan(&config, &mut pool, true, 10000);
     assert!(balance::value(&balance_a) == 10000, 0);
     assert!(balance::value(&balance_b) == 0, 0);
     // ... use balance_a for arbitrage
     let balance_a_after =swap(..., balance_a);
     let repay_balance_a = balance::split(&mut balance_a_after, 10000);
     pool::repay_flash_loan(&config, &mut pool, repay_balance_a, balance_b, receipt);
     transfer::public_transfer(balance_a_after, tx_context::sender(ctx));
```

### Pool Creation

For general pool creation, use the `create_pool_v2` function in the `pool_creator` module.

Note that the coin amount must be exactly what you want to deposit. For example, if `fix_amount_a` is true, the amount of coin A must match the exact amount you want to add.

```rust

public fun create_pool_v2<CoinTypeA, CoinTypeB>(
        _config: &GlobalConfig,
        _pools: &mut Pools,
        _tick_spacing: u32,
        _initialize_price: u128,
        _url: String,
        _tick_lower_idx: u32,
        _tick_upper_idx: u32,
        _coin_a: Coin<CoinTypeA>,
        _coin_b: Coin<CoinTypeB>,
        _metadata_a: &CoinMetadata<CoinTypeA>,
        _metadata_b: &CoinMetadata<CoinTypeB>,
        _fix_amount_a: bool,
        _clock: &Clock,
        _ctx: &mut TxContext
    ):  (Position, Coin<CoinTypeA>, Coin<CoinTypeB>) {
        abort 0
    }
```

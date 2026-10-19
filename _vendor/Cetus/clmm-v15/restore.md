# 🛠️ CLMM Pools Recovery Process

## Background

Due to an exploit, some CLMM pools suffered partial fund loss and cannot be fully restored. Before reopening the pools for trading, several recovery steps are required to restore pool state and adjust user positions proportionally.

This document outlines the steps and functions needed to perform the recovery process.

---

## 📋 Recovery Steps
---

### 1. Remove Malicious Positions

**Function**: `emergency_remove_malicious_position`

```rust
public fun emergency_remove_malicious_position<CoinTypeA, CoinTypeB>(
    config: &mut GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    ctx: &mut TxContext
)
```

**Description**:

* Removes malicious positions that were created during the attack.
* Decreases the associated liquidity from both ticks of the position.
* Can be called multiple times to remove multiple malicious positions.

---

### 2. Restore Pool State

**Function**: `emergency_restore_pool_state`

```rust
public fun emergency_restore_pool_state<CoinTypeA, CoinTypeB>(
    config: &mut GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    target_sqrt_price: u128,
    current_liquidity: u128,
    clk: &Clock,
    ctx: &mut TxContext
)
```

**Description**:

* Brings the pool’s internal price and liquidity back to a known-good pre-attack state.
* Swaps the pool to a `target_sqrt_price` representing the expected price.
* Verifies that the resulting `current_liquidity` matches the expected value to ensure state consistency.

---

### 3. Inject Governance Funds

**Function**: `governance_fund_injection`

```rust
public fun governance_fund_injection<CoinTypeA, CoinTypeB>(
    config: &mut GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coin_a: Coin<CoinTypeA>,
    coin_b: Coin<CoinTypeB>,
    ctx: &mut TxContext
)
```

**Description**:

* Governance-only function.
* Injects additional token liquidity into the pool to restore value lost during the attack.


### 4. Snapshot All Positions init

**Function**: `init_position_snapshot`
```rust
 public entry fun init_position_snapshot<CoinTypeA, CoinTypeB>(
        config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        remove_percent: u64,
        ctx: &mut TxContext,
    ) 
```
**Argument**:

```rust
remove_percent: u128
```


**Description**:

* Since pool funds cannot be fully restored, each position’s liquidity must be reduced by a specified percentage before reopening.
* This function snapshots the current state of each user’s position to preserve the original data, which is useful for future liquidation tracking or reconciliation.


---

### 5. Apply Liquidity Cut

**Function**: `apply_liquidity_cut`

```rust
public fun apply_liquidity_cut<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clock: &Clock,
    ctx: &mut TxContext,
)
```

**Description**:

* Applies a proportional reduction to a position’s liquidity based on the `remove_percent` specified earlier.
* Must be called **after** restoring pool state and **before** reopening trading.
* Snapshots the position before applying the cut to allow future auditing or accounting.


## 🔒 Fine-Grained Pool Controls


###  ✨ Feature Overview

To enhance the security and flexibility of CLMM operations, we introduce a fine-grained status control mechanism. This feature allows governance to selectively disable or enable specific functionalities on a per-pool basis.

---

## 🧱 Data Structures

### `Status`

```move
struct Status has copy, drop, store {
    disable_add_liquidity: bool,
    disable_remove_liquidity: bool,
    disable_swap: bool,
    disable_flash_loan: bool,
    disable_collect_fee: bool,
    disable_collect_reward: bool,
}
```

* Each field toggles a core operation of the CLMM pool.
* `true` = disabled, `false` = enabled.

### `PoolStatus`

```move
struct PoolStatus has key, store {
    id: UID,
    status: Status,
}
```

* Maintains the status config per pool.
* Stored and accessed via the pool dynamic field by name `pool_status`

---

## 🚦 Integration Points

Each core pool method (e.g. `add_liquidity`, `swap`, `collect_fee`, etc.) must **check the corresponding status flag** before proceeding.

### Example (in `add_liquidity`):

```move
assert!(is_allow_add_liquidity(pool), EOperationNotPermitted);
```

This pattern ensures that pool-level behaviors can be dynamically governed or paused.

---

## 🔐 Governance Control

Only authorized governance (e.g., a multisig or acl role manager) should be allowed to:

* Initialize `PoolStatus`
* Update the `Status` values dynamically

method:

```move
public fun set_pool_status<CoinTypeA, CoinTypeB>(
        config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        disable_add_liquidity: bool,
        disable_remove_liquidity: bool,
        disable_swap: bool,
        disable_flash_loan: bool,
        disable_collect_fee: bool,
        disable_collect_reward: bool,
        ctx: &mut TxContext,
    ) 
```

---
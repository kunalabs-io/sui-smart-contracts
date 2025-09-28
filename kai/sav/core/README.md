# Kai Single Asset Vault (SAV)

Kai Single Asset Vault (SAV) is a sophisticated vault system that accepts deposits of a single asset type and distributes funds across multiple yield-generating strategies. It provides automated rebalancing, fee management, time-locked profit distribution, and comprehensive risk management features for optimal yield optimization.

## Overview

The Kai SAV Core provides a robust framework to:

- **Accept single-asset deposits:** Users deposit one asset type and receive yield-bearing tokens representing their share of the vault
- **Multi-strategy allocation:** Automatically distribute funds across multiple yield-generating strategies based on configurable target weights
- **Automated rebalancing:** Continuously optimize allocations across strategies to maintain target weights and maximize yield
- **Time-locked profit distribution:** Gradually unlock profits over time to prevent sandwich attacks during rebalancing
- **Performance fee management:** Collect fees on generated profits while maintaining transparency
- **Risk management:** Implement TVL caps, strategy-specific borrow limits, and withdrawal priority ordering
- **Strategy integration:** Seamlessly integrate with various DeFi protocols like Scallop and Kai Leverage

## Architecture and Modules

The project is organized into several key modules:

### Core Vault Management

- **`kai_sav::vault`**  
  Contains the core vault logic for managing single-asset deposits and multi-strategy allocation. It provides functions for creating vaults, managing strategies, handling deposits/withdrawals, automated rebalancing, and profit distribution with time-locked mechanisms.

### Time-Locked Balance Management

- **`kai_sav::time_locked_balance`**  
  Implements a sophisticated time-locked balance system that gradually unlocks tokens over time. This prevents sandwich attacks during rebalancing by distributing profits slowly rather than all at once. It supports configurable unlock rates, start times, and handles extraneous balances that cannot be evenly distributed.

### Strategy Implementations

The core includes several strategy implementations that integrate with external DeFi protocols:

- **Scallop Protocol Strategies**  
  Strategies integrating with the Scallop Protocol, including:

  - `kai_sav::scallop_sui_proper` for SUI staking pools,
  - `kai_sav::scallop_whusdce` for whUSDC.e pools,
  - `kai_sav::scallop_whusdte_proper` for whUSDT.e pools

- **`kai_sav::kai_leverage_supply_pool`**  
  Strategy that deposits into supply pools whose funds are then used to power leveraged LP positions.

## Key Features

### Multi-Strategy Architecture

The vault supports multiple concurrent strategies, each with:

- Configurable target allocation weights (in basis points)
- Individual borrow limits for risk management
- Priority ordering for withdrawal operations
- Independent profit collection and reporting

### Automated Rebalancing

The system continuously monitors strategy allocations and automatically rebalances to maintain target weights:

- Calculates optimal borrow/repay amounts for each strategy
- Ensures all vault funds are allocated across strategies
- Maintains strategy-specific constraints and limits
- Provides idempotent rebalancing calculations

### Time-Locked Profit Distribution

Profits are distributed gradually over time to prevent manipulation:

- Configurable unlock duration (default: 100 minutes)
- Smooth profit distribution prevents sandwich attacks
- Extraneous balance handling for uneven distributions
- Real-time unlock calculations based on elapsed time

### Risk Management

Comprehensive risk controls include:

- TVL caps to limit total vault size
- Strategy-specific maximum borrow limits
- Withdrawal priority ordering for emergency situations
- Performance fee collection on all generated profits
- Rate limiting integration for additional protection

## Usage Flow

### Vault Creation

Create a vault with a specific yield token type:

```move
let lp_treasury = coin::create_currency<YSUI>(ctx);
let admin_cap = vault::new<SUI, YSUI>(lp_treasury, ctx);
```

### Strategy Addition

Add strategies to the vault:

```move
let vault_access = vault::add_strategy(&admin_cap, &mut vault, ctx);
strategy::join_vault(&vault_admin_cap, &mut vault, &strategy_admin_cap, &mut strategy, ctx);
```

### Deposit and Withdrawal

Users deposit assets and receive yield tokens:

```move
// Deposit
let yield_tokens = vault.deposit(deposit_balance, ctx);

// Withdraw
// Example: Withdrawing from a vault with a joined kai_leverage_supply_pool strategy

// Assume `vault` has a kai_leverage_supply_pool strategy already joined.
// User initiates a withdrawal by burning yield tokens (LP tokens) for a withdraw ticket.
let mut withdraw_ticket = vault.withdraw(yield_tokens, &clock);

// The strategy must process the withdrawal ticket and withdraw the required amount from the supply pool.
strategy.withdraw(
    &mut withdraw_ticket,    // the withdraw ticket from the vault
    &mut supply_pool,        // the supply pool the strategy manages
    &clock,                  // current clock
);

// After all strategies have processed the ticket, the user redeems the ticket to receive their withdrawn balance.
let withdrawn_balance = vault.redeem_withdraw_ticket(withdraw_ticket);
```

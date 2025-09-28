# Kai Finance Protocol

Kai Finance is a comprehensive DeFi protocol built on Sui that combines yield optimization, leveraged liquidity provisioning, and sophisticated risk management. The protocol consists of two main components that work together to maximize capital efficiency while maintaining security.

## Architecture Overview

```
┌───────────────────────────────────────────────────────────────┐
│                    KAI FINANCE ECOSYSTEM                     │
└───────────────────────────────────────────────────────────────┘

Users deposit funds
         │
         ▼
┌─────────────────┐
│   SAVs          │  Single-asset vaults (USDC, SUI, USDT)
│ (Savings)       │  • Multi-strategy yield optimization
│                 │  • Automated rebalancing
│                 │  • Time-locked profit distribution
└─────────────────┘
         │
         ▼
┌─────────────────┐
│   Strategies    │  Supply pool strategies
│                 │  • Borrow from SAVs
│                 │  • Invest in supply pools
└─────────────────┘
         │
         ▼
┌─────────────────┐
│  Supply Pools   │  Liquidity provision infrastructure
│                 │  • Fund leveraged LP positions
│                 │  • Manage debt and equity
└─────────────────┘
         │
         ▼
┌─────────────────┐
│  LP Positions   │  Leveraged concentrated liquidity
│                 │  • Cetus, Bluefin Spot integration
│                 │  • Automated deleveraging
│                 │  • Liquidation protection
└─────────────────┘
```

## Core Components

### SAV (Single Asset Vault)

The **SAV** system provides yield optimization for single-asset deposits:

- **Multi-strategy allocation**: Automatically distributes funds across yield-generating strategies
- **Automated rebalancing**: Maintains target weights and maximizes yield
- **Time-locked profits**: Prevents sandwich attacks during rebalancing
- **Risk management**: TVL caps, strategy limits, withdrawal priorities

**Key Modules:**

- `kai_sav::vault` - Core vault management
- `kai_sav::time_locked_balance` - Gradual profit unlocking
- Strategy integrations (Scallop, Kai Leverage)

### Kai Leverage

The **Leverage** system enables leveraged concentrated liquidity provisioning:

- **Position management**: Create and manage leveraged LP positions
- **Debt/equity tracking**: Precise accounting of debt shares and equity tokens
- **Supply pool management**: Handle lending operations and interest accrual
- **Protocol integration**: Support for Cetus, Bluefin Spot, and other AMMs

**Key Modules:**

- `kai_leverage::position_core_clmm` - Core position logic
- `kai_leverage::supply_pool` - Lending infrastructure
- `kai_leverage::equity` & `kai_leverage::debt` - Tokenized accounting

## How Components Work Together

1. **Deposit Flow**: Users deposit assets into SAVs, receiving yield tokens
2. **Strategy Allocation**: SAVs automatically allocate funds to strategies based on target weights
3. **Supply Pool Investment**: Strategies borrow from SAVs and invest in supply pools
4. **Leveraged Positions**: Supply pools provide liquidity to leveraged LP positions
5. **Yield Generation**: LP positions earn fees from AMM trading
6. **Profit Distribution**: Profits flow back through the chain with time-locked distribution

## Documentation

For detailed technical documentation, see:

- **[SAV Core README](./sav/core/README.md)** - Complete SAV system documentation
- **[Kai Leverage README](./leverage/core/README.md)** - Detailed leverage system documentation

---

_Kai Finance powers real-world DeFi applications at [https://kai.finance](https://kai.finance)_

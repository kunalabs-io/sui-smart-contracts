# Kai Leverage

Kai Leverage is a suite of Move smart contracts that powers leveraged concentrated liquidity provisioning, built on the models and findings from [_"Concentrated Liquidity with Leverage"_](https://arxiv.org/pdf/2409.12803) (_arXiv:2409.12803_). It provides robust core functionality for creating and managing leveraged positions, including precise debt and equity accounting, dynamic liquidity supply pool management, and secure operations for deleveraging and liquidation operations—while ensuring safe margin levels across price ranges. Its modular design supports integrations with protocols like Cetus and Bluefin Spot, enhancing capital efficiency and mitigating market risks such as price manipulation.

Overall, Kai Leverage seamlessly integrates robust theoretical models with a practical, modular design to provide a secure and efficient infrastructure for leveraged liquidity provisioning. These smart contracts power real-world DeFi applications at [https://kai.finance](https://kai.finance).

## Overview

Kai Leverage provides a robust framework to:

- **Create and manage leveraged positions:** Users can open positions with specified collateral, borrow funds, and track their debt, margin, and yield.
- **Manage debt and equity:** The system tracks debt share balances and issues equity tokens (or shares) representing claims on supply pool assets.
- **Supply liquidity:** Dedicated supply pools collect fees and handle lending operations while managing interest accrual and risk limits.
- **Deleverage and liquidate positions:** Automated processes calculate the optimal liquidity delta to remove from positions to restore safe margin levels.
- **Support multiple protocols:** Separate modules (e.g., for Cetus and Bluefin Spot) handle protocol-specific logic for adding/removing liquidity and other AMM interactions.
- **Offer utility functions:** A collection of helper functions (e.g., piecewise functions and precise arithmetic utilities) make calculations robust and flexible.

## Architecture and Modules

The project is organized into several key modules:

### Core Position Management

- **`kai_leverage::position_core_clmm`**  
  Contains the core logic for managing leveraged positions. It provides functions and macros to create, modify, and delete positions, handle collateral deposits, fee collection, and coordinate with other modules such as deleveraging and liquidation.

### Position Model

- **`kai_leverage::position_model_clmm`**  
  Implements the mathematics behind a position’s state. This module calculates collateral amounts, debt levels, margin ratios, and determines liquidation or deleveraging parameters based on current prices.

### Debt Information

- **`kai_leverage::debt_info`**  
  Maintains a registry of debt information for each lending facility. It is used to track liabilities and calculate the share of debt to repay, ensuring consistency when users repay borrowed funds.

### Piecewise Functions

- **`kai_leverage::piecewise`**  
  Provides a simple framework to define piecewise linear functions. This is useful for modeling interest rate curves and other functions that change over intervals.

### Debt and Equity Bags

- **`kai_leverage::debt_bag`** and **`kai_leverage::balance_bag`**  
  These modules manage collections (or “bags”) of debt and balance objects. They support operations such as splitting, joining, and transferring shares, which are critical for precise accounting.

### Equity Management

- **`kai_leverage::equity`**  
  Handles the issuance, redemption, and conversion of equity shares representing a portion of the supply pool’s assets. This module tracks underlying value and maintains the treasury for supply-side capital.

### Debt Operations

- **`kai_leverage::debt`**  
  Complements the equity module by providing functions for issuing debt shares, calculating repayment amounts, and converting between debt shares and the underlying debt value.

### Supply Pool

- **`kai_leverage::supply_pool`**  
  This is the heart of the lending functionality. It maintains the available balance, tracks total liabilities, and manages the interaction between users supplying liquidity and positions taking funds. It uses both debt and equity registries and enforces risk and utilization limits.

  Additionally, it includes:

  - **Lending Facility Configuration:** Defines parameters such as interest fee, maximum utilization, and maximum outstanding debt.
  - **Accrual and Fee Management:** Updates supply pool balances over time and collects protocol fees.

## Protocol-Specific Modules

Kai Leverage also includes protocol-specific logic that leverages the core modules:

- **Cetus Module (`kai_leverage::cetus`):**  
  Implements pool and position operations specific to the Cetus AMM.
- **Bluefin Spot Module (`kai_leverage::bluefin_spot`):**  
  Provides analogous functionality for the Bluefin Spot protocol.
- _(Other protocols that implement concentrated liquidity may be included similarly.)_

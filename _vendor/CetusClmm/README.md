# Cetus CLMM

**Decentralized Concentrated Liquidity Market Maker (CLMM) Protocol Implementation on Sui**

Cetus CLMM is a concentrated liquidity market maker protocol built on the Sui blockchain, allowing liquidity providers to provide liquidity within specific price ranges for higher capital efficiency.

## Project Overview

Cetus CLMM is the core contract implementation of the Cetus protocol, providing complete decentralized trading functionality. The protocol enables users to:

- Provide liquidity within specific price ranges
- Execute token swaps
- Earn trading fees and rewards
- Manage liquidity positions

## Features

### Core Modules

- **Pool**: Core pool logic and swap functionality
- **Factory**: Pool creation and management
- **Position**: Liquidity position management with NFT-based ownership
- **Tick**: Tick management for price ranges and liquidity
- **Rewarder**: Liquidity incentive system supporting multiple reward tokens
- **Partner**: Partner fee sharing mechanism
- **Config**: Global configuration and access control management
- **ACL**: Access control list for role-based permissions
- **Pool Creator**: Utilities for creating new pools
- **Math**: Mathematical calculations (CLMM math and tick math)

### Key Features

- **Concentrated Liquidity**: Liquidity providers can provide liquidity within specific price ranges
- **Multi-token Rewards**: Support for up to 5 different reward tokens
- **NFT Positions**: Liquidity positions exist as NFTs and can be freely transferred
- **Flexible Fee Structure**: Support for multiple fee tiers and partner fee sharing
- **Flash Loan Support**: Built-in flash loan functionality
- **Fine-grained Access Control**: Role-based access control system

## Getting Started

### Prerequisites

- **Sui CLI**: Latest version

### Build and Test

```bash
# Clone the repository
git clone https://github.com/CetusProtocol/cetus-contracts.git
cd cetus-contracts/packages/cetus_clmm

# Build the contracts
sui move build

# Run tests
sui move test
```

### Deployment

```bash
# Deploy to local testnet
sui client publish --gas-budget 100000000

```

## Project Structure

```
sources/
├── acl.move              # Access control list
├── config.move           # Global configuration management
├── factory.move          # Pool factory
├── pool.move             # Core pool logic and swap functionality
├── position.move         # Position management
├── position_snapshot.move # Position snapshot functionality
├── rewarder.move         # Reward system
├── partner.move          # Partner system
├── pool_creator.move     # Pool creation utilities
├── tick.move             # Tick management for price ranges
├── utils.move            # Utility functions
└── math/
    ├── clmm_math.move    # CLMM mathematical calculations
    └── tick_math.move    # Tick mathematical calculations
```


## Public Function Interfaces

This section documents all public functions available in the Cetus CLMM protocol modules.

### Pool Module (`pool.move`)

The core pool module provides trading and liquidity management functionality.

#### Position Management

**Open a new liquidity position**
```move
public fun open_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower: u32,
    tick_upper: u32,
    ctx: &mut TxContext,
): Position
```

**Close a liquidity position**
```move
public fun close_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: Position,
)
```

**Add liquidity to a position**
```move
public fun add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    clock: &Clock,
): AddLiquidityReceipt<CoinTypeA, CoinTypeB>
```

**Add liquidity with fixed coin amount**
```move
public fun add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    amount: u64,
    fix_amount_a: bool,
    clock: &Clock,
): AddLiquidityReceipt<CoinTypeA, CoinTypeB> 
```

**Repay the add liquidity receipt**
```move
public fun repay_add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    balance_a: Balance<CoinTypeA>,
    balance_b: Balance<CoinTypeB>,
    receipt: AddLiquidityReceipt<CoinTypeA, CoinTypeB>,
) 
```

**Remove liquidity from a position**
```move
public fun remove_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>)
```

**Remove liquidity with slippage protection**
```move
public fun remove_liquidity_with_slippage<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    min_amount_a: u64,
    min_amount_b: u64,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>)
```

#### Fee and Reward Collection

**Collect trading fees from a position**
```move
public fun collect_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &Position,
    recalculate: bool,
): (Balance<CoinTypeA>, Balance<CoinTypeB>)
```

**Collect rewards from a position**
```move
public fun collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &Position,
    vault: &mut RewarderGlobalVault,
    recalculate: bool,
    clock: &Clock,
): Balance<CoinTypeC> 
```

**Calculate and update position rewards**
```move
public fun calculate_and_update_rewards<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clock: &Clock,
): vector<u64>
```

**Calculate and update specific reward**
```move
public fun calculate_and_update_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clock: &Clock,
): u64 
```

**Calculate and update position points**
```move
public fun calculate_and_update_points<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clock: &Clock,
): u128
```

**Calculate and update position fees**
```move
public fun calculate_and_update_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): (u64, u64)
```

#### Flash Loans and Swaps

**Execute flash swap**
```move
public fun flash_swap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>)
```

**Repay flash swap**
```move
public fun repay_flash_swap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coin_a: Balance<CoinTypeA>,
    coin_b: Balance<CoinTypeB>,
    receipt: FlashSwapReceipt<CoinTypeA, CoinTypeB>,
)
```

**Execute flash swap with partner**
```move
public fun flash_swap_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &Partner,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>)
```

**Repay flash swap with partner**
```move
public fun repay_flash_swap_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &mut Partner,
    mut coin_a: Balance<CoinTypeA>,
    mut coin_b: Balance<CoinTypeB>,
    receipt: FlashSwapReceipt<CoinTypeA, CoinTypeB>,
)
```

**Execute flash loan**
```move
public fun flash_loan<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    loan_a: bool,
    amount: u64,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt)
```

**Execute flash loan with partner**
```move
public fun flash_loan_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &Partner,
    loan_a: bool,
    amount: u64,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt)
```

**Repay flash loan**
```move
public fun repay_flash_loan<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    balance_a: Balance<CoinTypeA>,
    balance_b: Balance<CoinTypeB>,
    receipt: FlashLoanReceipt,
) 
```

**Repay flash loan with partner**
```move
public fun repay_flash_loan_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &mut Partner,
    mut balance_a: Balance<CoinTypeA>,
    mut balance_b: Balance<CoinTypeB>,
    receipt: FlashLoanReceipt,
)
```

#### Pool Management

**Initialize rewarder for pool**
```move
public fun initialize_rewarder<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    ctx: &TxContext,
)
```

**Update reward emission rate**
```move
public fun update_emission<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    vault: &RewarderGlobalVault,
    emissions_per_second: u128,
    clock: &Clock,
    ctx: &TxContext,
)
```

**Update pool fee rate**
```move
public fun update_fee_rate<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    fee_rate: u64,
    ctx: &TxContext,
)
```

**Set pool status**
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

**Collect protocol fee**
```move
public fun collect_protocol_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    ctx: &TxContext,
): (Balance<CoinTypeA>, Balance<CoinTypeB>)
```

**Collect protocol fee with cap**
```move
public fun collect_protocol_fee_with_cap<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    config: &GlobalConfig,
    cap: &ProtocolFeeCollectCap,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) 
```

#### Query Functions

**Get position token amounts (v2)**
```move
public fun get_position_amounts_v2<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): (u64, u64)
```

**Calculate swap result**
```move
public fun calculate_swap_result<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
): CalculatedSwapResult
```

**Fetch ticks**
```move
public fun fetch_ticks<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    start: vector<u32>,
    limit: u64,
): vector<Tick>
```
**Fetch Positions**
```move
public fun fetch_positions<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    start: vector<ID>,
    limit: u64,
): vector<PositionInfo>
```

### Factory Module (`factory.move`)

The factory module manages pool creation and configuration.

#### Pool Creation

**Create a new pool by manager**
```move
public fun create_pool<CoinTypeA, CoinTypeB>(
    pools: &mut Pools,
    config: &GlobalConfig,
    tick_spacing: u32,
    initialize_price: u128,
    url: String,
    clock: &Clock,
    ctx: &mut TxContext,
)
```

#### Permission Management

**register permission pair**
```move
public fun register_permission_pair<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    pool_creation_cap: &PoolCreationCap,
    ctx: &mut TxContext,
)
```

**unregister permission pair**
```move
public fun unregister_permission_pair<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    cap: &PoolCreationCap,
)
```

**Add coin to allowed list**
```move
public fun add_allowed_list<Coin>(config: &GlobalConfig, pools: &mut Pools, ctx: &TxContext)
```

**Remove coin from allowed list**
```move
public fun remove_allowed_list<Coin>(config: &GlobalConfig, pools: &mut Pools, ctx: &TxContext)
```

**Add coin to denied list**
```move
public fun add_denied_list<Coin>(config: &GlobalConfig, pools: &mut Pools, ctx: &TxContext)
```

**Remove coin from denied list**
```move
public fun remove_denied_list<Coin>(config: &GlobalConfig, pools: &mut Pools, ctx: &TxContext)
```

#### Query Functions

**Get all pools**
```move
public fun fetch_pools(pools: &Pools, start: vector<ID>, limit: u64): vector<PoolSimpleInfo>
```

**Is the two coin type is right order to create pool**
```move
public fun is_right_order<CoinTypeA, CoinTypeB>(): bool
```

**new pool key**
```move
public fun new_pool_key<CoinTypeA, CoinTypeB>(tick_spacing: u32): ID
```

**is coin_type in allowed_list**
```move
public fun in_allowed_list<Coin>(pools: &Pools): bool
```

**is coin_type in denied_list**
```move
public fun in_denied_list<Coin>(pools: &Pools): bool
```

**is allowed coin to create pool**
```move
public fun is_allowed_coin<Coin>(pools: &mut Pools, _metadata: &CoinMetadata<Coin>): bool
```

**is permission pair to create pool**
```move
public fun is_permission_pair<CoinTypeA, CoinTypeB>(pools: &Pools, tick_spacing: u32): bool
```

**get the permission cap by coin_type and pair coin_type**
```move
public fun permission_pair_cap<CoinTypeA, CoinTypeB>(pools: &Pools, tick_spacing: u32): ID
```

### Position Module (`position.move`)

The position module manages liquidity position NFTs and metadata.

#### Position Management

**Set position display metadata**
```move
public fun set_display(
    config: &GlobalConfig,
    publisher: &Publisher,
    description: String,
    link: String,
    project_url: String,
    creator: String,
    ctx: &mut TxContext,
)
```

#### Query Functions
**check position tick range is right**
```move
public fun check_position_tick_range(lower: I32, upper: I32, tick_spacing: u32) 
```

**Get pool ID from position**
```move
public fun pool_id(position: &Position): ID
```

**Get position index**
```move
public fun index(position: &Position): u64
```

**Get lower tick index**
```move
public fun tick_lower_index(position: &Position): I32
```

**Get upper tick index**
```move
public fun tick_upper_index(position: &Position): I32
```

**Get position liquidity**
```move
public fun liquidity(position: &Position): u128
```

**Get position name**
```move
public fun name(position: &Position): String
```

**Get position description**
```move
public fun description(position: &Position): String
```

**Get position URL**
```move
public fun url(position: &Position): String
```

### Config Module (`config.move`)

The config module manages global configuration and access control.

#### Configuration Management

**Update protocol fee rate**
```move
public fun update_protocol_fee_rate(
    config: &mut GlobalConfig,
    protocol_fee_rate: u64,
    ctx: &TxContext,
)
```

**Add new fee tier**
```move
public fun add_fee_tier(
    config: &mut GlobalConfig,
    tick_spacing: u32,
    fee_rate: u64,
    ctx: &TxContext,
) 
```

**Delete fee tier**
```move
public fun delete_fee_tier(config: &mut GlobalConfig, tick_spacing: u32, ctx: &TxContext)
```

**Update fee tier**
```move
public fun update_fee_tier(
    config: &mut GlobalConfig,
    tick_spacing: u32,
    new_fee_rate: u64,
    ctx: &TxContext,
)
```

#### Access Control

**Set member roles**
```move
public fun set_roles(_: &AdminCap, config: &mut GlobalConfig, member: address, roles: u128)
```

**Add role to member**
```move
public fun add_role(_: &AdminCap, config: &mut GlobalConfig, member: address, role: u8)
```

**Remove role from member**
```move
public fun remove_role(_: &AdminCap, config: &mut GlobalConfig, member: address, role: u8) 
```

**Remove member**
```move
public fun remove_member(_: &AdminCap, config: &mut GlobalConfig, member: address)
```

#### Query Functions

**Get all members**
```move
public fun get_members(config: &GlobalConfig): vector<acl::Member>
```

**Get protocol fee rate**
```move
public fun get_protocol_fee_rate(global_config: &GlobalConfig): u64
```

**Get fee rate for tick spacing**
```move
public fun get_fee_rate(tick_spacing: u32, global_config: &GlobalConfig): u64
```

**Check if member is pool manager**
```move
public fun is_pool_manager(config: &GlobalConfig, member: address): bool
```

**Get all fee tiers**
```move
public fun fee_tiers(config: &GlobalConfig): &VecMap<u32, FeeTier>
```

**Get access control list**
```move
public fun acl(config: &GlobalConfig): &acl::ACL
```

### Rewarder Module (`rewarder.move`)

The rewarder module manages liquidity incentives and rewards.

#### Reward Management

**Deposit reward tokens**
```move
public fun deposit_reward<CoinType>(
    config: &GlobalConfig,
    vault: &mut RewarderGlobalVault,
    balance: Balance<CoinType>,
): u64 
```

**Emergency withdraw rewards**
```move
public fun emergent_withdraw<CoinType>(
    _: &AdminCap,
    config: &GlobalConfig,
    vault: &mut RewarderGlobalVault,
    amount: u64,
): Balance<CoinType>
```

#### Query Functions

**Get reward amount**
```move
public fun get_reward_amount<CoinType>(global_vault: &RewarderGlobalVault): u64
```

**Get global rewards growth**
```move
public fun get_rewards_growth_global<CoinTypeA, CoinTypeB, CoinTypeC>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    rewarder_manager: &RewarderManager,
): u128
```

**Global Vault balance**
```move
public fun balance_of<CoinType>(vault: &RewarderGlobalVault): u64
```

### Partner Module (`partner.move`)

The partner module manages partner fee sharing.

#### Partner Management

**Create new partner**
```move
public fun create_partner(
    config: &GlobalConfig,
    partners: &mut Partners,
    name: String,
    ref_fee_rate: u64,
    start_time: u64,
    end_time: u64,
    recipient: address,
    clock: &Clock,
    ctx: &mut TxContext,
)
```

**Update partner fee rate**
```move
public fun update_ref_fee_rate(
    config: &GlobalConfig,
    partner: &mut Partner,
    new_fee_rate: u64,
    ctx: &TxContext,
)
```

**Claim partner fees**
```move
public fun claim_ref_fee<T>(
    config: &GlobalConfig,
    partner_cap: &PartnerCap,
    partner: &mut Partner,
    ctx: &mut TxContext,
)
```


### ACL Module (`acl.move`)

The access control list module manages permissions.

#### ACL Management

**Create new ACL**
```move
public fun new(ctx: &mut TxContext): ACL
```

**Check if member has role**
```move
public fun has_role(acl: &ACL, member: address, role: u8): bool
```

**Set member roles**
```move
public fun set_roles(acl: &mut ACL, member: address, roles: u128)
```

**Add role to member**
```move
public fun add_role(acl: &mut ACL, member: address, role: u8)
```

**Remove role from member**
```move
public fun remove_role(acl: &mut ACL, member: address, role: u8)
```

**Remove member**
```move
public fun remove_member(acl: &mut ACL, member: address)
```

### Pool Creator Module (`pool_creator.move`)

The pool creator module provides utilities for creating pools.

#### Pool Creation

**Create pool with creation cap**
```move
public fun create_pool_v2_with_creation_cap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    cap: &PoolCreationCap,
    tick_spacing: u32,
    initialize_price: u128,
    url: String,
    tick_lower_idx: u32,
    tick_upper_idx: u32,
    coin_a: Coin<CoinTypeA>,
    coin_b: Coin<CoinTypeB>,
    metadata_a: &CoinMetadata<CoinTypeA>,
    metadata_b: &CoinMetadata<CoinTypeB>,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext,
): (Position, Coin<CoinTypeA>, Coin<CoinTypeB>)
```
**Create pool**
```move
public fun create_pool_v2<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pools: &mut Pools,
    tick_spacing: u32,
    initialize_price: u128,
    url: String,
    tick_lower_idx: u32,
    tick_upper_idx: u32,
    coin_a: Coin<CoinTypeA>,
    coin_b: Coin<CoinTypeB>,
    metadata_a: &CoinMetadata<CoinTypeA>,
    metadata_b: &CoinMetadata<CoinTypeB>,
    fix_amount_a: bool,
    clock: &Clock,
    ctx: &mut TxContext,
): (Position, Coin<CoinTypeA>, Coin<CoinTypeB>)
```

### Math Modules

#### CLMM Math (`clmm_math.move`)

**Get fee rate denominator**
```move
public fun fee_rate_denominator(): u64
```

**Calculate liquidity from token A**
```move
public fun get_liquidity_from_a(
    sqrt_price_0: u128,
    sqrt_price_1: u128,
    amount_a: u64,
    round_up: bool,
): u128 
```

**Calculate liquidity from token B**
```move
public fun get_liquidity_from_b(
    sqrt_price_0: u128,
    sqrt_price_1: u128,
    amount_b: u64,
    round_up: bool,
): u128
```

**Calculate delta A**
```move
public fun get_delta_a(
    sqrt_price_0: u128,
    sqrt_price_1: u128,
    liquidity: u128,
    round_up: bool,
): u64
```

**Calculate delta B**
```move
public fun get_delta_b(
    sqrt_price_0: u128,
    sqrt_price_1: u128,
    liquidity: u128,
    round_up: bool,
): u64
```

#### Tick Math (`tick_math.move`)

**Get maximum sqrt price**
```move
public fun max_sqrt_price(): u128
```

**Get minimum sqrt price**
```move
public fun min_sqrt_price(): u128
```

**Get maximum tick**
```move
public fun max_tick(): i32::I32
```

**Get minimum tick**
```move
public fun min_tick(): i32::I32
```

**Get tick bound**
```move
public fun tick_bound(): u32
```

**Get sqrt price at tick**
```move
public fun get_sqrt_price_at_tick(tick: i32::I32): u128
```

**Check if tick index is valid**
```move
public fun is_valid_index(index: I32, tick_spacing: u32): bool
```

**Get tick at sqrt price**
```move
public fun get_tick_at_sqrt_price(sqrt_price: u128): i32::I32
```

## Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Write test cases
4. Submit a Pull Request

### Code Standards

- Follow Move language best practices
- All public functions must have complete documentation comments
- Use `sui move test` to run all tests

### Commit Standards

- Use clear commit messages
- Ensure all tests pass before committing

## Links

- [Cetus Website](https://app.cetus.zone/)
- [Documentation](https://cetus-1.gitbook.io/cetus-developer-docs)

## Version History

For detailed version update records, please refer to [CHANGELOG.md](CHANGELOG.md).

## License

This project is licensed under the [Apache-2.0](LICENSE) license.
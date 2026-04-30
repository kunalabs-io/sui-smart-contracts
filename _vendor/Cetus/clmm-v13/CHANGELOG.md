# Changelog 

## (2024-10-28)
- Online Version: 8

### `config` Module Updates
- Add `is_pool_manager` public method

### `factory` Module Updates
### New Share Objects & Structs
- Share Objects:
  - `DenyCoinList`
  - `PermissionPairManager`
- Structs:
  - `PoolKey`
  - `PoolCreationCap`

### New Events
- DenyCoinList Events:
  - `AddAllowedListEvent`
  - `RemoveAllowedListEvent`
  - `AddDeniedListEvent`
  - `RemoveDeniedListEvent`
- Permission Pair Events:
  - `InitPermissionPairManagerEvent`
  - `RegisterPermissionPairEvent`
  - `UnregisterPermissionPairEvent`
  - `AddAllowedPairConfigEvent`
  - `RemoveAllowedPairConfigEvent`
- PoolCreationCap Events:
  - `MintPoolCreationCap`
  - `MintPoolCreationCapByAdmin`

### New Methods
#### Public Methods
- Init Entry Function:
  - `init_manager_and_whitelist`
- DenyCoinList Management:
  - `in_allowed_list`
  - `in_denied_list`
  - `is_allowed_coin`
  - `add_allowed_list`
  - `remove_allowed_list`
  - `add_denied_list`
  - `remove_denied_list`
- Pool Creation:
  - `permission_pair_cap`
  - `is_permission_pair`
  - `add_allowed_pair_config`
  - `remove_allowed_pair_config`
  - `mint_pool_creation_cap`
  - `mint_pool_creation_cap_by_admin`
  - `register_permission_pair`
  - `unregister_permission_pair`

#### Private Methods
- `add_denied_coin`
- `unregister_permission_pair_internal`
- `register_permission_pair_internal`
- `create_pool_v2_internal`

#### New public(friend) Methods
- `create_pool_v2_`

### Method Changes
- Modified `create_pool` to require permission
- Deprecated `create_pool_with_liquidity`

## New Module
### `pool_creator` Module
- Add `create_pool_v2_by_creation_cap` method
- Add `create_pool_v2` method

## Breaking Changes & Migration Guide
### Deprecated Methods
The `create_pool_with_liquidity` method has been deprecated. Instead, users should:
- For registered pools: Use `create_pool_v2_by_creation_cap` method
- For non-registered pools: Use `create_pool_v2` method

### New Requirements
- Mandatory full-range liquidity provision for new pool creation
- Token issuers can register pool creation permissions by specified with quote coin and tick_spacing
- All pool creation functionality has been migrated to the new `pool_creator` module
- Users should update their integration to use the new v2 methods

## 2024-11-20
- Online Version: 9

### Added
* Add amount check to `create_pool_v2`
* Performed code optimizations
* Added new event `CollectRewardV2Event` to pool module
* No longer enforce the full-range liquidity constraint in the pool creation process.
* Deprecated `create_pool_v2_by_creation_cap` method and implemented new method `create_pool_v2_with_creation_cap`. The `create_pool_v2` method is no longer intended for manager use.


## 2025-02-07
- Online Version: 10
### Added
- Support flash loan

- Reward num per pool up to 5

### Changed

- Ignore remaining rewarder check when update_emission if new emission speed slower than old

```
    public(friend) fun update_emission<CoinType>(
        vault: &RewarderGlobalVault,
        manager: &mut RewarderManager,
        liquidity: u128,
        emissions_per_second: u128,
        timestamp: u64,
    ) {
        ...
        let old_emission = rewarder.emissions_per_second;
        if (emissions_per_second > 0 && emissions_per_second > old_emission) {
          ...
        }
        rewarder.emissions_per_second = emissions_per_second;
    }
```
### Optimized
- Optimized gas by adding a check to return early if current_sqrt_price == target_sqrt_price.

```rust
    if (liquidity == 0 || current_sqrt_price == target_sqrt_price) {
        return (
            amount_in,
            amount_out,
            next_sqrt_price,
            fee_amount,
        )
    };
    if (a2b) {
        assert!(current_sqrt_price > target_sqrt_price, EINVALID_SQRT_PRICE_INPUT)
    } else {
        assert!(current_sqrt_price < target_sqrt_price, EINVALID_SQRT_PRICE_INPUT)
    };
```

### Fixed
### Security


## 2025-03-20
- Online Version: 11

Update `inter-mate` library version
### Added
### Changed

### Fixed
### Security


## 2025-06-02
- Online Version: 12
### Added
- Add `ProtocolFeeCollectCap`
- Add `collect_protocol_fee_v2` method
- Add pool restore related methods
- Add Fine-Grained Pool Controls, add `PoolStatus` struct
### Changed
- Update `clmm_math.get_liquidity_by_amount` method

### Fixed
### Security

## 2025-09-12
- Online Version: 13
### Added
- Add `AddLiquidityV2Event`, `RemoveLiquidityV2Event`
- Fix asymptotic audit
- Add `remove_liquidity_with_slippage`

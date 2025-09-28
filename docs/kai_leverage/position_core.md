
<a name="kai_leverage_position_core_clmm"></a>

# Module `kai_leverage::position_core_clmm`

Core implementation for leveraged concentrated liquidity market maker (CLMM) positions.

This module implements the theoretical framework described in "Concentrated Liquidity
with Leverage" ([arXiv:2409.12803](https://arxiv.org/pdf/2409.12803)), providing mathematically
proven safe leveraged liquidity provisioning. It serves as the foundational layer for managing
leveraged positions on concentrated liquidity AMMs with formal guarantees about margin behavior,
liquidation safety, and oracle manipulation resistance.

The module provides a protocol-agnostic interface that wrapper modules (like <code>cetus.<b>move</b></code>
and <code>bluefin_spot.<b>move</b></code>) use to implement protocol-specific position management while
maintaining consistent risk management and operational logic backed by formal mathematical analysis.

Wrapper modules implement protocol-specific logic by:
1. Calling position core macros with protocol-specific lambda functions
2. Handling protocol-specific LP position types and operations
3. Translating between generic interfaces and protocol-specific calls

This design ensures that core business logic, risk management, and mathematical
calculations remain consistent across all supported protocols while enabling
seamless integration with diverse AMM architectures.


-  [Struct `ACreateConfig`](#kai_leverage_position_core_clmm_ACreateConfig)
-  [Struct `AModifyConfig`](#kai_leverage_position_core_clmm_AModifyConfig)
-  [Struct `AMigrate`](#kai_leverage_position_core_clmm_AMigrate)
-  [Struct `ADeleverage`](#kai_leverage_position_core_clmm_ADeleverage)
-  [Struct `ARebalance`](#kai_leverage_position_core_clmm_ARebalance)
-  [Struct `ACollectProtocolFees`](#kai_leverage_position_core_clmm_ACollectProtocolFees)
-  [Struct `ARepayBadDebt`](#kai_leverage_position_core_clmm_ARepayBadDebt)
-  [Struct `CreatePositionTicket`](#kai_leverage_position_core_clmm_CreatePositionTicket)
-  [Struct `Position`](#kai_leverage_position_core_clmm_Position)
-  [Struct `PositionCap`](#kai_leverage_position_core_clmm_PositionCap)
-  [Struct `PythConfig`](#kai_leverage_position_core_clmm_PythConfig)
-  [Struct `PositionConfig`](#kai_leverage_position_core_clmm_PositionConfig)
-  [Struct `LiquidationDisabledKey`](#kai_leverage_position_core_clmm_LiquidationDisabledKey)
-  [Struct `ReductionDisabledKey`](#kai_leverage_position_core_clmm_ReductionDisabledKey)
-  [Struct `AddLiquidityDisabledKey`](#kai_leverage_position_core_clmm_AddLiquidityDisabledKey)
-  [Struct `OwnerCollectFeeDisabledKey`](#kai_leverage_position_core_clmm_OwnerCollectFeeDisabledKey)
-  [Struct `OwnerCollectRewardDisabledKey`](#kai_leverage_position_core_clmm_OwnerCollectRewardDisabledKey)
-  [Struct `DeletePositionDisabledKey`](#kai_leverage_position_core_clmm_DeletePositionDisabledKey)
-  [Struct `PositionCreateWithdrawLimiterKey`](#kai_leverage_position_core_clmm_PositionCreateWithdrawLimiterKey)
-  [Struct `DeleverageTicket`](#kai_leverage_position_core_clmm_DeleverageTicket)
-  [Struct `ReductionRepaymentTicket`](#kai_leverage_position_core_clmm_ReductionRepaymentTicket)
-  [Struct `RebalanceReceipt`](#kai_leverage_position_core_clmm_RebalanceReceipt)
-  [Struct `DeletedPositionCollectedFees`](#kai_leverage_position_core_clmm_DeletedPositionCollectedFees)
-  [Struct `PositionCreationInfo`](#kai_leverage_position_core_clmm_PositionCreationInfo)
-  [Struct `DeleverageInfo`](#kai_leverage_position_core_clmm_DeleverageInfo)
-  [Struct `LiquidationInfo`](#kai_leverage_position_core_clmm_LiquidationInfo)
-  [Struct `ReductionInfo`](#kai_leverage_position_core_clmm_ReductionInfo)
-  [Struct `AddCollateralInfo`](#kai_leverage_position_core_clmm_AddCollateralInfo)
-  [Struct `AddLiquidityInfo`](#kai_leverage_position_core_clmm_AddLiquidityInfo)
-  [Struct `RepayDebtInfo`](#kai_leverage_position_core_clmm_RepayDebtInfo)
-  [Struct `OwnerCollectFeeInfo`](#kai_leverage_position_core_clmm_OwnerCollectFeeInfo)
-  [Struct `OwnerCollectRewardInfo`](#kai_leverage_position_core_clmm_OwnerCollectRewardInfo)
-  [Struct `OwnerTakeStashedRewardsInfo`](#kai_leverage_position_core_clmm_OwnerTakeStashedRewardsInfo)
-  [Struct `DeletePositionInfo`](#kai_leverage_position_core_clmm_DeletePositionInfo)
-  [Struct `RebalanceInfo`](#kai_leverage_position_core_clmm_RebalanceInfo)
-  [Struct `CollectProtocolFeesInfo`](#kai_leverage_position_core_clmm_CollectProtocolFeesInfo)
-  [Struct `DeletedPositionCollectedFeesInfo`](#kai_leverage_position_core_clmm_DeletedPositionCollectedFeesInfo)
-  [Struct `BadDebtRepaid`](#kai_leverage_position_core_clmm_BadDebtRepaid)
-  [Constants](#@Constants_0)
-  [Macro function `e_invalid_tick_range`](#kai_leverage_position_core_clmm_e_invalid_tick_range)
-  [Macro function `e_liq_margin_too_low`](#kai_leverage_position_core_clmm_e_liq_margin_too_low)
-  [Macro function `e_initial_margin_too_low`](#kai_leverage_position_core_clmm_e_initial_margin_too_low)
-  [Macro function `e_new_positions_not_allowed`](#kai_leverage_position_core_clmm_e_new_positions_not_allowed)
-  [Macro function `e_invalid_config`](#kai_leverage_position_core_clmm_e_invalid_config)
-  [Macro function `e_invalid_pool`](#kai_leverage_position_core_clmm_e_invalid_pool)
-  [Macro function `e_invalid_borrow`](#kai_leverage_position_core_clmm_e_invalid_borrow)
-  [Macro function `e_invalid_position_cap`](#kai_leverage_position_core_clmm_e_invalid_position_cap)
-  [Macro function `e_ticket_active`](#kai_leverage_position_core_clmm_e_ticket_active)
-  [Macro function `e_position_mismatch`](#kai_leverage_position_core_clmm_e_position_mismatch)
-  [Macro function `e_position_below_threshold`](#kai_leverage_position_core_clmm_e_position_below_threshold)
-  [Macro function `e_slippage_exceeded`](#kai_leverage_position_core_clmm_e_slippage_exceeded)
-  [Macro function `e_position_size_limit_exceeded`](#kai_leverage_position_core_clmm_e_position_size_limit_exceeded)
-  [Macro function `e_vault_global_size_limit_exceeded`](#kai_leverage_position_core_clmm_e_vault_global_size_limit_exceeded)
-  [Macro function `e_invalid_creation_fee_amount`](#kai_leverage_position_core_clmm_e_invalid_creation_fee_amount)
-  [Macro function `e_supply_pool_mismatch`](#kai_leverage_position_core_clmm_e_supply_pool_mismatch)
-  [Macro function `e_position_not_fully_deleveraged`](#kai_leverage_position_core_clmm_e_position_not_fully_deleveraged)
-  [Macro function `e_position_not_below_bad_debt_threshold`](#kai_leverage_position_core_clmm_e_position_not_below_bad_debt_threshold)
-  [Macro function `e_liquidation_disabled`](#kai_leverage_position_core_clmm_e_liquidation_disabled)
-  [Macro function `e_reduction_disabled`](#kai_leverage_position_core_clmm_e_reduction_disabled)
-  [Macro function `e_add_liquidity_disabled`](#kai_leverage_position_core_clmm_e_add_liquidity_disabled)
-  [Macro function `e_owner_collect_fee_disabled`](#kai_leverage_position_core_clmm_e_owner_collect_fee_disabled)
-  [Macro function `e_owner_collect_reward_disabled`](#kai_leverage_position_core_clmm_e_owner_collect_reward_disabled)
-  [Macro function `e_delete_position_disabled`](#kai_leverage_position_core_clmm_e_delete_position_disabled)
-  [Macro function `e_invalid_balance_value`](#kai_leverage_position_core_clmm_e_invalid_balance_value)
-  [Macro function `e_function_deprecated`](#kai_leverage_position_core_clmm_e_function_deprecated)
-  [Macro function `e_price_deviation_too_high`](#kai_leverage_position_core_clmm_e_price_deviation_too_high)
-  [Function `a_deleverage`](#kai_leverage_position_core_clmm_a_deleverage)
-  [Function `a_rebalance`](#kai_leverage_position_core_clmm_a_rebalance)
-  [Function `a_repay_bad_debt`](#kai_leverage_position_core_clmm_a_repay_bad_debt)
-  [Function `position_constructor`](#kai_leverage_position_core_clmm_position_constructor)
-  [Function `position_deconstructor`](#kai_leverage_position_core_clmm_position_deconstructor)
-  [Function `position_share_object`](#kai_leverage_position_core_clmm_position_share_object)
-  [Function `position_config_id`](#kai_leverage_position_core_clmm_position_config_id)
-  [Function `lp_position`](#kai_leverage_position_core_clmm_lp_position)
-  [Function `col_x`](#kai_leverage_position_core_clmm_col_x)
-  [Function `col_y`](#kai_leverage_position_core_clmm_col_y)
-  [Function `position_debt_bag`](#kai_leverage_position_core_clmm_position_debt_bag)
-  [Function `ticket_active`](#kai_leverage_position_core_clmm_ticket_active)
-  [Function `set_ticket_active`](#kai_leverage_position_core_clmm_set_ticket_active)
-  [Function `lp_position_mut`](#kai_leverage_position_core_clmm_lp_position_mut)
-  [Function `col_x_mut`](#kai_leverage_position_core_clmm_col_x_mut)
-  [Function `col_y_mut`](#kai_leverage_position_core_clmm_col_y_mut)
-  [Function `position_debt_bag_mut`](#kai_leverage_position_core_clmm_position_debt_bag_mut)
-  [Function `collected_fees`](#kai_leverage_position_core_clmm_collected_fees)
-  [Function `collected_fees_mut`](#kai_leverage_position_core_clmm_collected_fees_mut)
-  [Function `owner_reward_stash`](#kai_leverage_position_core_clmm_owner_reward_stash)
-  [Function `owner_reward_stash_mut`](#kai_leverage_position_core_clmm_owner_reward_stash_mut)
-  [Function `position_cap_constructor`](#kai_leverage_position_core_clmm_position_cap_constructor)
-  [Function `position_cap_deconstructor`](#kai_leverage_position_core_clmm_position_cap_deconstructor)
-  [Function `pc_position_id`](#kai_leverage_position_core_clmm_pc_position_id)
-  [Function `create_empty_config`](#kai_leverage_position_core_clmm_create_empty_config)
-  [Function `pool_object_id`](#kai_leverage_position_core_clmm_pool_object_id)
-  [Function `allow_new_positions`](#kai_leverage_position_core_clmm_allow_new_positions)
-  [Function `lend_facil_cap`](#kai_leverage_position_core_clmm_lend_facil_cap)
-  [Function `min_liq_start_price_delta_bps`](#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps)
-  [Function `min_init_margin_bps`](#kai_leverage_position_core_clmm_min_init_margin_bps)
-  [Function `allowed_oracles`](#kai_leverage_position_core_clmm_allowed_oracles)
-  [Function `deleverage_margin_bps`](#kai_leverage_position_core_clmm_deleverage_margin_bps)
-  [Function `base_deleverage_factor_bps`](#kai_leverage_position_core_clmm_base_deleverage_factor_bps)
-  [Function `liq_margin_bps`](#kai_leverage_position_core_clmm_liq_margin_bps)
-  [Function `base_liq_factor_bps`](#kai_leverage_position_core_clmm_base_liq_factor_bps)
-  [Function `liq_bonus_bps`](#kai_leverage_position_core_clmm_liq_bonus_bps)
-  [Function `max_position_l`](#kai_leverage_position_core_clmm_max_position_l)
-  [Function `max_global_l`](#kai_leverage_position_core_clmm_max_global_l)
-  [Function `current_global_l`](#kai_leverage_position_core_clmm_current_global_l)
-  [Function `rebalance_fee_bps`](#kai_leverage_position_core_clmm_rebalance_fee_bps)
-  [Function `liq_fee_bps`](#kai_leverage_position_core_clmm_liq_fee_bps)
-  [Function `position_creation_fee_sui`](#kai_leverage_position_core_clmm_position_creation_fee_sui)
-  [Function `increase_current_global_l`](#kai_leverage_position_core_clmm_increase_current_global_l)
-  [Function `decrease_current_global_l`](#kai_leverage_position_core_clmm_decrease_current_global_l)
-  [Function `set_allow_new_positions`](#kai_leverage_position_core_clmm_set_allow_new_positions)
-  [Function `set_min_liq_start_price_delta_bps`](#kai_leverage_position_core_clmm_set_min_liq_start_price_delta_bps)
-  [Function `set_min_init_margin_bps`](#kai_leverage_position_core_clmm_set_min_init_margin_bps)
-  [Function `config_add_empty_pyth_config`](#kai_leverage_position_core_clmm_config_add_empty_pyth_config)
-  [Function `set_pyth_config_max_age_secs`](#kai_leverage_position_core_clmm_set_pyth_config_max_age_secs)
-  [Function `pyth_config_allow_pio`](#kai_leverage_position_core_clmm_pyth_config_allow_pio)
-  [Function `pyth_config_disallow_pio`](#kai_leverage_position_core_clmm_pyth_config_disallow_pio)
-  [Function `set_deleverage_margin_bps`](#kai_leverage_position_core_clmm_set_deleverage_margin_bps)
-  [Function `set_base_deleverage_factor_bps`](#kai_leverage_position_core_clmm_set_base_deleverage_factor_bps)
-  [Function `set_liq_margin_bps`](#kai_leverage_position_core_clmm_set_liq_margin_bps)
-  [Function `set_base_liq_factor_bps`](#kai_leverage_position_core_clmm_set_base_liq_factor_bps)
-  [Function `set_liq_bonus_bps`](#kai_leverage_position_core_clmm_set_liq_bonus_bps)
-  [Function `set_max_position_l`](#kai_leverage_position_core_clmm_set_max_position_l)
-  [Function `set_max_global_l`](#kai_leverage_position_core_clmm_set_max_global_l)
-  [Function `set_rebalance_fee_bps`](#kai_leverage_position_core_clmm_set_rebalance_fee_bps)
-  [Function `set_liq_fee_bps`](#kai_leverage_position_core_clmm_set_liq_fee_bps)
-  [Function `set_position_creation_fee_sui`](#kai_leverage_position_core_clmm_set_position_creation_fee_sui)
-  [Function `upsert_config_extension`](#kai_leverage_position_core_clmm_upsert_config_extension)
-  [Function `add_config_extension`](#kai_leverage_position_core_clmm_add_config_extension)
-  [Function `has_config_extension`](#kai_leverage_position_core_clmm_has_config_extension)
-  [Function `borrow_config_extension`](#kai_leverage_position_core_clmm_borrow_config_extension)
-  [Function `get_config_extension_or_default`](#kai_leverage_position_core_clmm_get_config_extension_or_default)
-  [Function `config_extension_mut`](#kai_leverage_position_core_clmm_config_extension_mut)
-  [Function `set_liquidation_disabled`](#kai_leverage_position_core_clmm_set_liquidation_disabled)
-  [Function `liquidation_disabled`](#kai_leverage_position_core_clmm_liquidation_disabled)
-  [Function `set_reduction_disabled`](#kai_leverage_position_core_clmm_set_reduction_disabled)
-  [Function `reduction_disabled`](#kai_leverage_position_core_clmm_reduction_disabled)
-  [Function `set_add_liquidity_disabled`](#kai_leverage_position_core_clmm_set_add_liquidity_disabled)
-  [Function `add_liquidity_disabled`](#kai_leverage_position_core_clmm_add_liquidity_disabled)
-  [Function `set_owner_collect_fee_disabled`](#kai_leverage_position_core_clmm_set_owner_collect_fee_disabled)
-  [Function `owner_collect_fee_disabled`](#kai_leverage_position_core_clmm_owner_collect_fee_disabled)
-  [Function `set_owner_collect_reward_disabled`](#kai_leverage_position_core_clmm_set_owner_collect_reward_disabled)
-  [Function `owner_collect_reward_disabled`](#kai_leverage_position_core_clmm_owner_collect_reward_disabled)
-  [Function `set_delete_position_disabled`](#kai_leverage_position_core_clmm_set_delete_position_disabled)
-  [Function `delete_position_disabled`](#kai_leverage_position_core_clmm_delete_position_disabled)
-  [Function `add_create_withdraw_limiter`](#kai_leverage_position_core_clmm_add_create_withdraw_limiter)
-  [Function `has_create_withdraw_limiter`](#kai_leverage_position_core_clmm_has_create_withdraw_limiter)
-  [Function `borrow_create_withdraw_limiter`](#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter)
-  [Function `borrow_create_withdraw_limiter_mut`](#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter_mut)
-  [Function `set_max_create_withdraw_net_inflow_and_outflow_limits`](#kai_leverage_position_core_clmm_set_max_create_withdraw_net_inflow_and_outflow_limits)
-  [Function `deleverage_ticket_constructor`](#kai_leverage_position_core_clmm_deleverage_ticket_constructor)
-  [Function `dt_position_id`](#kai_leverage_position_core_clmm_dt_position_id)
-  [Function `dt_can_repay_x`](#kai_leverage_position_core_clmm_dt_can_repay_x)
-  [Function `dt_can_repay_y`](#kai_leverage_position_core_clmm_dt_can_repay_y)
-  [Function `dt_info`](#kai_leverage_position_core_clmm_dt_info)
-  [Function `reduction_repayment_ticket_constructor`](#kai_leverage_position_core_clmm_reduction_repayment_ticket_constructor)
-  [Function `rrt_sx`](#kai_leverage_position_core_clmm_rrt_sx)
-  [Function `rrt_sy`](#kai_leverage_position_core_clmm_rrt_sy)
-  [Function `rrt_info`](#kai_leverage_position_core_clmm_rrt_info)
-  [Function `rr_position_id`](#kai_leverage_position_core_clmm_rr_position_id)
-  [Function `increase_collected_amm_fee_x`](#kai_leverage_position_core_clmm_increase_collected_amm_fee_x)
-  [Function `increase_collected_amm_fee_y`](#kai_leverage_position_core_clmm_increase_collected_amm_fee_y)
-  [Function `collected_amm_rewards_mut`](#kai_leverage_position_core_clmm_collected_amm_rewards_mut)
-  [Function `increase_delta_l`](#kai_leverage_position_core_clmm_increase_delta_l)
-  [Function `increase_delta_x`](#kai_leverage_position_core_clmm_increase_delta_x)
-  [Function `increase_delta_y`](#kai_leverage_position_core_clmm_increase_delta_y)
-  [Function `rr_collected_amm_fee_x`](#kai_leverage_position_core_clmm_rr_collected_amm_fee_x)
-  [Function `rr_collected_amm_fee_y`](#kai_leverage_position_core_clmm_rr_collected_amm_fee_y)
-  [Function `rr_collected_amm_rewards`](#kai_leverage_position_core_clmm_rr_collected_amm_rewards)
-  [Function `rr_fees_taken`](#kai_leverage_position_core_clmm_rr_fees_taken)
-  [Function `rr_taken_cx`](#kai_leverage_position_core_clmm_rr_taken_cx)
-  [Function `rr_taken_cy`](#kai_leverage_position_core_clmm_rr_taken_cy)
-  [Function `rr_delta_l`](#kai_leverage_position_core_clmm_rr_delta_l)
-  [Function `rr_delta_x`](#kai_leverage_position_core_clmm_rr_delta_x)
-  [Function `rr_delta_y`](#kai_leverage_position_core_clmm_rr_delta_y)
-  [Function `rr_x_repaid`](#kai_leverage_position_core_clmm_rr_x_repaid)
-  [Function `rr_y_repaid`](#kai_leverage_position_core_clmm_rr_y_repaid)
-  [Function `rr_added_cx`](#kai_leverage_position_core_clmm_rr_added_cx)
-  [Function `rr_added_cy`](#kai_leverage_position_core_clmm_rr_added_cy)
-  [Function `rr_stashed_amm_rewards`](#kai_leverage_position_core_clmm_rr_stashed_amm_rewards)
-  [Function `new_create_position_ticket`](#kai_leverage_position_core_clmm_new_create_position_ticket)
-  [Function `destroy_create_position_ticket`](#kai_leverage_position_core_clmm_destroy_create_position_ticket)
-  [Function `cpt_config_id`](#kai_leverage_position_core_clmm_cpt_config_id)
-  [Function `dx`](#kai_leverage_position_core_clmm_dx)
-  [Function `dy`](#kai_leverage_position_core_clmm_dy)
-  [Function `borrowed_x`](#kai_leverage_position_core_clmm_borrowed_x)
-  [Function `borrowed_x_mut`](#kai_leverage_position_core_clmm_borrowed_x_mut)
-  [Function `borrowed_y`](#kai_leverage_position_core_clmm_borrowed_y)
-  [Function `borrowed_y_mut`](#kai_leverage_position_core_clmm_borrowed_y_mut)
-  [Function `delta_l`](#kai_leverage_position_core_clmm_delta_l)
-  [Function `principal_x`](#kai_leverage_position_core_clmm_principal_x)
-  [Function `principal_y`](#kai_leverage_position_core_clmm_principal_y)
-  [Function `cpt_debt_bag`](#kai_leverage_position_core_clmm_cpt_debt_bag)
-  [Function `cpt_debt_bag_mut`](#kai_leverage_position_core_clmm_cpt_debt_bag_mut)
-  [Function `cpt_tick_a`](#kai_leverage_position_core_clmm_cpt_tick_a)
-  [Function `cpt_tick_b`](#kai_leverage_position_core_clmm_cpt_tick_b)
-  [Function `share_deleted_position_collected_fees`](#kai_leverage_position_core_clmm_share_deleted_position_collected_fees)
-  [Function `emit_position_creation_info`](#kai_leverage_position_core_clmm_emit_position_creation_info)
-  [Function `deleverage_info_constructor`](#kai_leverage_position_core_clmm_deleverage_info_constructor)
-  [Function `set_delta_l`](#kai_leverage_position_core_clmm_set_delta_l)
-  [Function `set_delta_x`](#kai_leverage_position_core_clmm_set_delta_x)
-  [Function `set_delta_y`](#kai_leverage_position_core_clmm_set_delta_y)
-  [Function `di_position_id`](#kai_leverage_position_core_clmm_di_position_id)
-  [Function `di_model`](#kai_leverage_position_core_clmm_di_model)
-  [Function `di_oracle_price_x128`](#kai_leverage_position_core_clmm_di_oracle_price_x128)
-  [Function `di_sqrt_pool_price_x64`](#kai_leverage_position_core_clmm_di_sqrt_pool_price_x64)
-  [Function `di_delta_l`](#kai_leverage_position_core_clmm_di_delta_l)
-  [Function `di_delta_x`](#kai_leverage_position_core_clmm_di_delta_x)
-  [Function `di_delta_y`](#kai_leverage_position_core_clmm_di_delta_y)
-  [Function `di_x_repaid`](#kai_leverage_position_core_clmm_di_x_repaid)
-  [Function `di_y_repaid`](#kai_leverage_position_core_clmm_di_y_repaid)
-  [Function `emit_liquidation_info`](#kai_leverage_position_core_clmm_emit_liquidation_info)
-  [Function `reduction_info_constructor`](#kai_leverage_position_core_clmm_reduction_info_constructor)
-  [Function `ri_position_id`](#kai_leverage_position_core_clmm_ri_position_id)
-  [Function `ri_model`](#kai_leverage_position_core_clmm_ri_model)
-  [Function `ri_oracle_price_x128`](#kai_leverage_position_core_clmm_ri_oracle_price_x128)
-  [Function `ri_sqrt_pool_price_x64`](#kai_leverage_position_core_clmm_ri_sqrt_pool_price_x64)
-  [Function `ri_delta_l`](#kai_leverage_position_core_clmm_ri_delta_l)
-  [Function `ri_delta_x`](#kai_leverage_position_core_clmm_ri_delta_x)
-  [Function `ri_delta_y`](#kai_leverage_position_core_clmm_ri_delta_y)
-  [Function `ri_withdrawn_x`](#kai_leverage_position_core_clmm_ri_withdrawn_x)
-  [Function `ri_withdrawn_y`](#kai_leverage_position_core_clmm_ri_withdrawn_y)
-  [Function `ri_x_repaid`](#kai_leverage_position_core_clmm_ri_x_repaid)
-  [Function `ri_y_repaid`](#kai_leverage_position_core_clmm_ri_y_repaid)
-  [Function `add_liquidity_info_constructor`](#kai_leverage_position_core_clmm_add_liquidity_info_constructor)
-  [Function `ali_emit`](#kai_leverage_position_core_clmm_ali_emit)
-  [Function `ali_delta_l`](#kai_leverage_position_core_clmm_ali_delta_l)
-  [Function `ali_delta_x`](#kai_leverage_position_core_clmm_ali_delta_x)
-  [Function `ali_delta_y`](#kai_leverage_position_core_clmm_ali_delta_y)
-  [Function `emit_owner_collect_fee_info`](#kai_leverage_position_core_clmm_emit_owner_collect_fee_info)
-  [Function `emit_owner_collect_reward_info`](#kai_leverage_position_core_clmm_emit_owner_collect_reward_info)
-  [Function `emit_delete_position_info`](#kai_leverage_position_core_clmm_emit_delete_position_info)
-  [Function `emit_bad_debt_repaid`](#kai_leverage_position_core_clmm_emit_bad_debt_repaid)
-  [Function `check_config_version`](#kai_leverage_position_core_clmm_check_config_version)
-  [Function `check_position_version`](#kai_leverage_position_core_clmm_check_position_version)
-  [Function `check_versions`](#kai_leverage_position_core_clmm_check_versions)
-  [Function `migrate_config`](#kai_leverage_position_core_clmm_migrate_config)
-  [Function `migrate_position`](#kai_leverage_position_core_clmm_migrate_position)
-  [Function `validate_price_info`](#kai_leverage_position_core_clmm_validate_price_info)
-  [Function `validate_debt_info`](#kai_leverage_position_core_clmm_validate_debt_info)
-  [Function `calc_borrow_amt`](#kai_leverage_position_core_clmm_calc_borrow_amt)
-  [Function `price_deviation_is_acceptable`](#kai_leverage_position_core_clmm_price_deviation_is_acceptable)
-  [Function `liq_margin_is_valid`](#kai_leverage_position_core_clmm_liq_margin_is_valid)
-  [Function `init_margin_is_valid`](#kai_leverage_position_core_clmm_init_margin_is_valid)
-  [Macro function `model_from_position`](#kai_leverage_position_core_clmm_model_from_position)
-  [Macro function `slippage_tolerance_assertion`](#kai_leverage_position_core_clmm_slippage_tolerance_assertion)
-  [Function `get_amount_ema_usd_value_6_decimals`](#kai_leverage_position_core_clmm_get_amount_ema_usd_value_6_decimals)
-  [Function `get_balance_ema_usd_value_6_decimals`](#kai_leverage_position_core_clmm_get_balance_ema_usd_value_6_decimals)
-  [Macro function `create_position_ticket`](#kai_leverage_position_core_clmm_create_position_ticket)
-  [Macro function `borrow_for_position_x`](#kai_leverage_position_core_clmm_borrow_for_position_x)
-  [Macro function `borrow_for_position_y`](#kai_leverage_position_core_clmm_borrow_for_position_y)
-  [Macro function `create_position`](#kai_leverage_position_core_clmm_create_position)
-  [Macro function `create_deleverage_ticket_inner`](#kai_leverage_position_core_clmm_create_deleverage_ticket_inner)
-  [Macro function `create_deleverage_ticket`](#kai_leverage_position_core_clmm_create_deleverage_ticket)
-  [Macro function `create_deleverage_ticket_for_liquidation`](#kai_leverage_position_core_clmm_create_deleverage_ticket_for_liquidation)
-  [Function `deleverage_ticket_repay_x`](#kai_leverage_position_core_clmm_deleverage_ticket_repay_x)
-  [Function `deleverage_ticket_repay_y`](#kai_leverage_position_core_clmm_deleverage_ticket_repay_y)
-  [Function `destroy_deleverage_ticket`](#kai_leverage_position_core_clmm_destroy_deleverage_ticket)
-  [Macro function `deleverage`](#kai_leverage_position_core_clmm_deleverage)
-  [Macro function `deleverage_for_liquidation`](#kai_leverage_position_core_clmm_deleverage_for_liquidation)
-  [Function `calc_liq_fee_from_reward`](#kai_leverage_position_core_clmm_calc_liq_fee_from_reward)
-  [Macro function `liquidate_col_x`](#kai_leverage_position_core_clmm_liquidate_col_x)
-  [Macro function `liquidate_col_y`](#kai_leverage_position_core_clmm_liquidate_col_y)
-  [Macro function `repay_bad_debt`](#kai_leverage_position_core_clmm_repay_bad_debt)
-  [Macro function `reduce`](#kai_leverage_position_core_clmm_reduce)
-  [Function `reduction_ticket_calc_repay_amt_x`](#kai_leverage_position_core_clmm_reduction_ticket_calc_repay_amt_x)
-  [Function `reduction_ticket_calc_repay_amt_y`](#kai_leverage_position_core_clmm_reduction_ticket_calc_repay_amt_y)
-  [Function `reduction_ticket_repay_x`](#kai_leverage_position_core_clmm_reduction_ticket_repay_x)
-  [Function `reduction_ticket_repay_y`](#kai_leverage_position_core_clmm_reduction_ticket_repay_y)
-  [Function `destroy_reduction_ticket`](#kai_leverage_position_core_clmm_destroy_reduction_ticket)
-  [Function `add_collateral_x`](#kai_leverage_position_core_clmm_add_collateral_x)
-  [Function `add_collateral_y`](#kai_leverage_position_core_clmm_add_collateral_y)
-  [Macro function `add_liquidity_with_receipt_inner`](#kai_leverage_position_core_clmm_add_liquidity_with_receipt_inner)
-  [Macro function `add_liquidity_inner`](#kai_leverage_position_core_clmm_add_liquidity_inner)
-  [Macro function `add_liquidity_with_receipt`](#kai_leverage_position_core_clmm_add_liquidity_with_receipt)
-  [Macro function `add_liquidity`](#kai_leverage_position_core_clmm_add_liquidity)
-  [Function `repay_debt_x`](#kai_leverage_position_core_clmm_repay_debt_x)
-  [Function `repay_debt_y`](#kai_leverage_position_core_clmm_repay_debt_y)
-  [Macro function `owner_collect_fee`](#kai_leverage_position_core_clmm_owner_collect_fee)
-  [Macro function `owner_collect_reward`](#kai_leverage_position_core_clmm_owner_collect_reward)
-  [Function `owner_take_stashed_rewards`](#kai_leverage_position_core_clmm_owner_take_stashed_rewards)
-  [Macro function `delete_position`](#kai_leverage_position_core_clmm_delete_position)
-  [Function `create_rebalance_receipt`](#kai_leverage_position_core_clmm_create_rebalance_receipt)
-  [Function `add_amount_to_map`](#kai_leverage_position_core_clmm_add_amount_to_map)
-  [Function `take_rebalance_fee`](#kai_leverage_position_core_clmm_take_rebalance_fee)
-  [Macro function `rebalance_collect_fee`](#kai_leverage_position_core_clmm_rebalance_collect_fee)
-  [Macro function `rebalance_collect_reward`](#kai_leverage_position_core_clmm_rebalance_collect_reward)
-  [Macro function `rebalance_add_liquidity_with_receipt`](#kai_leverage_position_core_clmm_rebalance_add_liquidity_with_receipt)
-  [Macro function `rebalance_add_liquidity`](#kai_leverage_position_core_clmm_rebalance_add_liquidity)
-  [Function `rebalance_repay_debt_x`](#kai_leverage_position_core_clmm_rebalance_repay_debt_x)
-  [Function `rebalance_repay_debt_y`](#kai_leverage_position_core_clmm_rebalance_repay_debt_y)
-  [Function `rebalance_stash_rewards`](#kai_leverage_position_core_clmm_rebalance_stash_rewards)
-  [Function `consume_rebalance_receipt`](#kai_leverage_position_core_clmm_consume_rebalance_receipt)
-  [Function `collect_protocol_fees`](#kai_leverage_position_core_clmm_collect_protocol_fees)
-  [Function `collect_deleted_position_fees`](#kai_leverage_position_core_clmm_collect_deleted_position_fees)
-  [Macro function `validated_model_for_position`](#kai_leverage_position_core_clmm_validated_model_for_position)
-  [Macro function `calc_liquidate_col_x`](#kai_leverage_position_core_clmm_calc_liquidate_col_x)
-  [Macro function `calc_liquidate_col_y`](#kai_leverage_position_core_clmm_calc_liquidate_col_y)


<pre><code><b>use</b> <a href="../../dependencies/wal/wal.md#0x356A26EB9E012A68958082340D4C4116E7F55615CF27AFFCFF209CF0AE544F59_wal">0x356A26EB9E012A68958082340D4C4116E7F55615CF27AFFCFF209CF0AE544F59::wal</a>;
<b>use</b> <a href="../../dependencies/suiusdt/usdt.md#0x375F70CF2AE4C00BF37117D0C85A2C71545E6EE05C4A5C7D282CD66A4504B068_usdt">0x375F70CF2AE4C00BF37117D0C85A2C71545E6EE05C4A5C7D282CD66A4504B068::usdt</a>;
<b>use</b> <a href="../../dependencies/lbtc/lbtc.md#0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040_lbtc">0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040::lbtc</a>;
<b>use</b> <a href="../../dependencies/whusdce/coin.md#0x5D4B302506645C37FF133B98C4B50A5AE14841659738D6D733D59D0D217A93BF_coin">0x5D4B302506645C37FF133B98C4B50A5AE14841659738D6D733D59D0D217A93BF::coin</a>;
<b>use</b> <a href="../../dependencies/xbtc/xbtc.md#0x876A4B7BCE8AEAEF60464C11F4026903E9AFACAB79B9B142686158AA86560B50_xbtc">0x876A4B7BCE8AEAEF60464C11F4026903E9AFACAB79B9B142686158AA86560B50::xbtc</a>;
<b>use</b> <a href="../../dependencies/usdy/usdy.md#0x960B531667636F39E85867775F52F6B1F220A058C4DE786905BDF761E06A56BB_usdy">0x960B531667636F39E85867775F52F6B1F220A058C4DE786905BDF761E06A56BB::usdy</a>;
<b>use</b> <a href="../../dependencies/wbtc/btc.md#0xAAFB102DD0902F5055CADECD687FB5B71CA82EF0E0285D90AFDE828EC58CA96B_btc">0xAAFB102DD0902F5055CADECD687FB5B71CA82EF0E0285D90AFDE828EC58CA96B::btc</a>;
<b>use</b> <a href="../../dependencies/whusdte/coin.md#0xC060006111016B8A020AD5B33834984A437AAA7D3C74C18E09A95D48ACEAB08C_coin">0xC060006111016B8A020AD5B33834984A437AAA7D3C74C18E09A95D48ACEAB08C::coin</a>;
<b>use</b> <a href="../../dependencies/deep/deep.md#0xDEEB7A4662EEC9F2F3DEF03FB937A663DDDAA2E215B8078A284D026B7946C270_deep">0xDEEB7A4662EEC9F2F3DEF03FB937A663DDDAA2E215B8078A284D026B7946C270::deep</a>;
<b>use</b> <a href="../../dependencies/access_management/access.md#access_management_access">access_management::access</a>;
<b>use</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map">access_management::dynamic_map</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag">kai_leverage::balance_bag</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt">kai_leverage::debt</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag">kai_leverage::debt_bag</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info">kai_leverage::debt_info</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity">kai_leverage::equity</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise">kai_leverage::piecewise</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm">kai_leverage::position_model_clmm</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth">kai_leverage::pyth</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool">kai_leverage::supply_pool</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util">kai_leverage::util</a>;
<b>use</b> <a href="../../dependencies/pyth/i64.md#pyth_i64">pyth::i64</a>;
<b>use</b> <a href="../../dependencies/pyth/price.md#pyth_price">pyth::price</a>;
<b>use</b> <a href="../../dependencies/pyth/price_feed.md#pyth_price_feed">pyth::price_feed</a>;
<b>use</b> <a href="../../dependencies/pyth/price_identifier.md#pyth_price_identifier">pyth::price_identifier</a>;
<b>use</b> <a href="../../dependencies/pyth/price_info.md#pyth_price_info">pyth::price_info</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter">rate_limiter::net_sliding_sum_limiter</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator">rate_limiter::ring_aggregator</a>;
<b>use</b> <a href="../../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter">rate_limiter::sliding_sum_limiter</a>;
<b>use</b> <a href="../../dependencies/stablecoin/mint_allowance.md#stablecoin_mint_allowance">stablecoin::mint_allowance</a>;
<b>use</b> <a href="../../dependencies/stablecoin/roles.md#stablecoin_roles">stablecoin::roles</a>;
<b>use</b> <a href="../../dependencies/stablecoin/treasury.md#stablecoin_treasury">stablecoin::treasury</a>;
<b>use</b> <a href="../../dependencies/stablecoin/version_control.md#stablecoin_version_control">stablecoin::version_control</a>;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/u128.md#std_u128">std::u128</a>;
<b>use</b> <a href="../../dependencies/std/u64.md#std_u64">std::u64</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/package.md#sui_package">sui::package</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
<b>use</b> <a href="../../dependencies/sui_extensions/two_step_role.md#sui_extensions_two_step_role">sui_extensions::two_step_role</a>;
<b>use</b> <a href="../../dependencies/sui_extensions/upgrade_service.md#sui_extensions_upgrade_service">sui_extensions::upgrade_service</a>;
<b>use</b> <a href="../../dependencies/usdc/usdc.md#usdc_usdc">usdc::usdc</a>;
</code></pre>



<a name="kai_leverage_position_core_clmm_ACreateConfig"></a>

## Struct `ACreateConfig`

Access control witness for position config creation.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ACreateConfig">ACreateConfig</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_AModifyConfig"></a>

## Struct `AModifyConfig`

Access control witness for position config modification.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_AMigrate"></a>

## Struct `AMigrate`

Access control witness for module migrations.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AMigrate">AMigrate</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_ADeleverage"></a>

## Struct `ADeleverage`

Access control witness for position deleveraging.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ADeleverage">ADeleverage</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_ARebalance"></a>

## Struct `ARebalance`

Access control witness for position rebalancing.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARebalance">ARebalance</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_ACollectProtocolFees"></a>

## Struct `ACollectProtocolFees`

Access control witness for protocol fee collection.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ACollectProtocolFees">ACollectProtocolFees</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_ARepayBadDebt"></a>

## Struct `ARepayBadDebt`

Access control witness for bad debt repayment.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARepayBadDebt">ARepayBadDebt</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_CreatePositionTicket"></a>

## Struct `CreatePositionTicket`

Ticket for creating a new leveraged position with borrowed funds.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;<b>phantom</b> X, <b>phantom</b> Y, I32&gt;
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>config_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>tick_a: I32</code>
</dt>
<dd>
</dd>
<dt>
<code>tick_b: I32</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>debt_bag: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_Position"></a>

## Struct `Position`

Leveraged position containing LP position, collateral, and debt.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;<b>phantom</b> X, <b>phantom</b> Y, LP&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>config_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>: LP</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>debt_bag: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>: <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>: <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>version: u16</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_PositionCap"></a>

## Struct `PositionCap`

Capability granting ownership and control over a position.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a> <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_PythConfig"></a>

## Struct `PythConfig`

Configuration for Pyth oracle integration.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>max_age_secs: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>pio_allowlist: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_PositionConfig"></a>

## Struct `PositionConfig`

Configuration for leveraged concentrated liquidity position parameters and risk management.

This configuration implements the theoretical framework described in "Concentrated Liquidity
with Leverage" (arXiv:2409.12803), which provides mathematical guarantees for safe leveraged
liquidity provisioning.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The object ID of the underlying AMM pool this configuration applies to.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allow_new_positions">allow_new_positions</a>: bool</code>
</dt>
<dd>
 Whether new positions can be created under this configuration.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilCap">kai_leverage::supply_pool::LendFacilCap</a></code>
</dt>
<dd>
 Lending facility capability (<code>SupplyPool</code>) associated with this position configuration.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps">min_liq_start_price_delta_bps</a>: u16</code>
</dt>
<dd>
 Minimum price deviation required between initial price and liquidation trigger price.
 Prevents positions from being created too close to liquidation thresholds.
 Based on paper's price range analysis ensuring safe margin evolution.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_init_margin_bps">min_init_margin_bps</a>: u16</code>
</dt>
<dd>
 Minimum initial margin level required for position creation (basis points).
 Ensures sufficient collateralization based on margin function M(P) = A(P)/D(P).
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>: <a href="../../dependencies/sui/bag.md#sui_bag_Bag">sui::bag::Bag</a></code>
</dt>
<dd>
 Bag of allowed oracle sources for this position configuration.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>: u16</code>
</dt>
<dd>
 Deleveraging margin threshold (basis points). When margin falls to this level,
 automated deleveraging reduces position size to restore safety.
 Must be higher than liquidation margin to provide deleveraging buffer.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_deleverage_factor_bps">base_deleverage_factor_bps</a>: u16</code>
</dt>
<dd>
 Base factor for deleveraging amount calculation (basis points).
 Determines how aggressively positions are deleveraged when margin deteriorates.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>: u16</code>
</dt>
<dd>
 Liquidation margin threshold (basis points). Positions below this margin
 can be liquidated by external parties to protect lenders from losses.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>: u16</code>
</dt>
<dd>
 Base liquidation factor (basis points) controlling liquidation aggressiveness.
 Ensures liquidations restore position health while minimizing impact.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>: u16</code>
</dt>
<dd>
 Liquidation bonus (basis points) guaranteed to liquidators as incentive.
 Always awarded even for underwater positions to minimize bad debt formation.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_position_l">max_position_l</a>: u128</code>
</dt>
<dd>
 Maximum liquidity allowed per individual position.
 Implements position size limits for risk management.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_global_l">max_global_l</a>: u128</code>
</dt>
<dd>
 Maximum total liquidity across all positions globally.
 Implements system-wide exposure limits.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a>: u128</code>
</dt>
<dd>
 Current total liquidity across all active positions.
 Tracked for enforcing global limits.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>: u16</code>
</dt>
<dd>
 Protocol fee taken during rebalancing operations (basis points).
 Applied to collected AMM fees and rewards.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_fee_bps">liq_fee_bps</a>: u16</code>
</dt>
<dd>
 Protocol fee taken during liquidation operations (basis points).
 Applied to liquidation bonuses before distribution to liquidators.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_creation_fee_sui">position_creation_fee_sui</a>: u64</code>
</dt>
<dd>
 Fee charged for position creation in SUI tokens.
 Helps cover operational costs and prevent spam.
</dd>
<dt>
<code>version: u16</code>
</dt>
<dd>
 Version for upgrade compatibility.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_LiquidationDisabledKey"></a>

## Struct `LiquidationDisabledKey`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_LiquidationDisabledKey">LiquidationDisabledKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_ReductionDisabledKey"></a>

## Struct `ReductionDisabledKey`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionDisabledKey">ReductionDisabledKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_AddLiquidityDisabledKey"></a>

## Struct `AddLiquidityDisabledKey`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityDisabledKey">AddLiquidityDisabledKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_OwnerCollectFeeDisabledKey"></a>

## Struct `OwnerCollectFeeDisabledKey`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectFeeDisabledKey">OwnerCollectFeeDisabledKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_OwnerCollectRewardDisabledKey"></a>

## Struct `OwnerCollectRewardDisabledKey`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectRewardDisabledKey">OwnerCollectRewardDisabledKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_DeletePositionDisabledKey"></a>

## Struct `DeletePositionDisabledKey`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletePositionDisabledKey">DeletePositionDisabledKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_PositionCreateWithdrawLimiterKey"></a>

## Struct `PositionCreateWithdrawLimiterKey`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCreateWithdrawLimiterKey">PositionCreateWithdrawLimiterKey</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_DeleverageTicket"></a>

## Struct `DeleverageTicket`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>can_repay_x: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>can_repay_y: bool</code>
</dt>
<dd>
</dd>
<dt>
<code>info: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_ReductionRepaymentTicket"></a>

## Struct `ReductionRepaymentTicket`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;<b>phantom</b> SX, <b>phantom</b> SY&gt;
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>sx: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;SX&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>sy: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;SY&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>info: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_RebalanceReceipt"></a>

## Struct `RebalanceReceipt`

Receipt for a position rebalance operation, tracking all fee, reward, and liquidity changes.

This struct records the results of a rebalance, including all AMM fees and rewards collected,
protocol fees taken, changes to position liquidity, debt repayments, and any rewards stashed
back into the position. It is used for event emission and downstream accounting.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>collected_amm_fee_x: u64</code>
</dt>
<dd>
 The amount of X collected from AMM fees (before fees are taken).
</dd>
<dt>
<code>collected_amm_fee_y: u64</code>
</dt>
<dd>
 The amount of Y collected from AMM fees (before fees are taken).
</dd>
<dt>
<code>collected_amm_rewards: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;</code>
</dt>
<dd>
 The amount other AMM rewards collected (before fees are taken).
</dd>
<dt>
<code>fees_taken: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;</code>
</dt>
<dd>
 The amount fees taken from collected rewards (both AMM fees and AMM rewards).
</dd>
<dt>
<code>taken_cx: u64</code>
</dt>
<dd>
 The amount of X taken from cx.
</dd>
<dt>
<code>taken_cy: u64</code>
</dt>
<dd>
 The amount of Y taken from cy.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128</code>
</dt>
<dd>
 The amount of liquidity added to the LP position.
</dd>
<dt>
<code>delta_x: u64</code>
</dt>
<dd>
 The amount of X added to the LP position (corresponds to delta_l).
</dd>
<dt>
<code>delta_y: u64</code>
</dt>
<dd>
 The amount of Y added to the LP position (corresponds to delta_l).
</dd>
<dt>
<code>x_repaid: u64</code>
</dt>
<dd>
 The amount of X debt repaid.
</dd>
<dt>
<code>y_repaid: u64</code>
</dt>
<dd>
 The amount of Y debt repaid.
</dd>
<dt>
<code>added_cx: u64</code>
</dt>
<dd>
 The amount of X added to cx.
</dd>
<dt>
<code>added_cy: u64</code>
</dt>
<dd>
 The amount of Y added to cy.
</dd>
<dt>
<code>stashed_amm_rewards: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;</code>
</dt>
<dd>
 The amount rewards stashed back into the position.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_DeletedPositionCollectedFees"></a>

## Struct `DeletedPositionCollectedFees`

Object representing the collected fees from a deleted position.

This struct is created and shared when a position is deleted, containing
the final balance bag of fees and rewards that were accumulated by the position.
It allows downstream consumers to claim or account for these fees after
the position object has been deleted.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletedPositionCollectedFees">DeletedPositionCollectedFees</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>balance_bag: <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_PositionCreationInfo"></a>

## Struct `PositionCreationInfo`

Event emitted when a new leveraged position is created.

This event records all relevant parameters and amounts for the newly created position,
including the position and config IDs, price range, liquidity, initial and collateral
balances, borrowed amounts, and the SUI fee paid at creation. It is used for downstream
analytics, auditing, and protocol integrations.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCreationInfo">PositionCreationInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>config_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>sqrt_pa_x64: u128</code>
</dt>
<dd>
</dd>
<dt>
<code>sqrt_pb_x64: u128</code>
</dt>
<dd>
</dd>
<dt>
<code>l: u128</code>
</dt>
<dd>
</dd>
<dt>
<code>x0: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>y0: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>cx: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>cy: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>creation_fee_amt_sui: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_DeleverageInfo"></a>

## Struct `DeleverageInfo`

Information about a deleveraging operation on a leveraged CLMM position.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The unique ID of the position being deleveraged.
</dd>
<dt>
<code>model: <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a></code>
</dt>
<dd>
 The position model snapshot at the time of deleverage.
</dd>
<dt>
<code>oracle_price_x128: u256</code>
</dt>
<dd>
 The oracle-reported price at the time of deleverage, as a Q128.128 fixed-point value.
</dd>
<dt>
<code>sqrt_pool_price_x64: u128</code>
</dt>
<dd>
 The pool's square root price at the time of deleverage, as a Q64.64 fixed-point value.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128</code>
</dt>
<dd>
 The amount of liquidity (L) removed from the LP position during deleverage.
</dd>
<dt>
<code>delta_x: u64</code>
</dt>
<dd>
 The amount of X withdrawn from the LP position (corresponding to <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a></code>)
 and added to the position's cx (collateral X) balance.
</dd>
<dt>
<code>delta_y: u64</code>
</dt>
<dd>
 The amount of Y withdrawn from the LP position (corresponding to <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a></code>)
 and added to the position's cy (collateral Y) balance.
</dd>
<dt>
<code>x_repaid: u64</code>
</dt>
<dd>
 The amount of X debt repaid using cx (collateral X) as part of deleverage.
</dd>
<dt>
<code>y_repaid: u64</code>
</dt>
<dd>
 The amount of Y debt repaid using cy (collateral Y) as part of deleverage.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_LiquidationInfo"></a>

## Struct `LiquidationInfo`

Information emitted for a position liquidation event, capturing all key amounts and rewards.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_LiquidationInfo">LiquidationInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the liquidated position.
</dd>
<dt>
<code>model: <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a></code>
</dt>
<dd>
 The position model at the time of liquidation.
</dd>
<dt>
<code>oracle_price_x128: u256</code>
</dt>
<dd>
 The oracle price (P = Y / X) at the time of liquidation, Q128 fixed-point.
</dd>
<dt>
<code>x_repaid: u64</code>
</dt>
<dd>
 The amount of X debt repaid by the liquidator (from their inputted Balance<X>).
</dd>
<dt>
<code>y_repaid: u64</code>
</dt>
<dd>
 The amount of Y debt repaid by the liquidator (from their inputted Balance<Y>).
</dd>
<dt>
<code>liquidator_reward_x: u64</code>
</dt>
<dd>
 The amount of X paid out to the liquidator as a reward (after protocol fees), taken from cx.
</dd>
<dt>
<code>liquidator_reward_y: u64</code>
</dt>
<dd>
 The amount of Y paid out to the liquidator as a reward (after protocol fees), taken from cy.
</dd>
<dt>
<code>liquidation_fee_x: u64</code>
</dt>
<dd>
 The protocol fee (in X) taken from the liquidator's reward before payout.
</dd>
<dt>
<code>liquidation_fee_y: u64</code>
</dt>
<dd>
 The protocol fee (in Y) taken from the liquidator's reward before payout.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_ReductionInfo"></a>

## Struct `ReductionInfo`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>model: <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a></code>
</dt>
<dd>
</dd>
<dt>
<code>oracle_price_x128: u256</code>
</dt>
<dd>
</dd>
<dt>
<code>sqrt_pool_price_x64: u128</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128</code>
</dt>
<dd>
 The amount of L removed from the LP position.
</dd>
<dt>
<code>delta_x: u64</code>
</dt>
<dd>
 The amount of X withdrawn from the LP position (corresponds to delta_l).
</dd>
<dt>
<code>delta_y: u64</code>
</dt>
<dd>
 The amount of Y withdrawn from the LP position (corresponds to delta_l).
</dd>
<dt>
<code>withdrawn_x: u64</code>
</dt>
<dd>
 The total amount of X returned from the position (delta_x + cx).
</dd>
<dt>
<code>withdrawn_y: u64</code>
</dt>
<dd>
 The total amount of Y returned from the position (delta_y + cy).
</dd>
<dt>
<code>x_repaid: u64</code>
</dt>
<dd>
 The amount X debt repaid.
</dd>
<dt>
<code>y_repaid: u64</code>
</dt>
<dd>
 The amount Y debt repaid.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_AddCollateralInfo"></a>

## Struct `AddCollateralInfo`

Event emitted when collateral is added to a position.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddCollateralInfo">AddCollateralInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the position to which collateral was added.
</dd>
<dt>
<code>amount_x: u64</code>
</dt>
<dd>
 The amount of X collateral added.
</dd>
<dt>
<code>amount_y: u64</code>
</dt>
<dd>
 The amount of Y collateral added.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_AddLiquidityInfo"></a>

## Struct `AddLiquidityInfo`

Event emitted when liquidity is added to a position.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the position to which liquidity was added.
</dd>
<dt>
<code>sqrt_pool_price_x64: u128</code>
</dt>
<dd>
 The pool's square root price (Q64.64) at the time of liquidity addition.
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128</code>
</dt>
<dd>
 The amount of liquidity (L) added to the position.
</dd>
<dt>
<code>delta_x: u64</code>
</dt>
<dd>
 The amount of X tokens added to the position (corresponds to delta_l).
</dd>
<dt>
<code>delta_y: u64</code>
</dt>
<dd>
 The amount of Y tokens added to the position (corresponds to delta_l).
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_RepayDebtInfo"></a>

## Struct `RepayDebtInfo`

Event emitted when debt is repaid on a position by the owner.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RepayDebtInfo">RepayDebtInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the position for which debt was repaid.
</dd>
<dt>
<code>x_repaid: u64</code>
</dt>
<dd>
 The amount of X repaid to the position's debt.
</dd>
<dt>
<code>y_repaid: u64</code>
</dt>
<dd>
 The amount of Y repaid to the position's debt.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_OwnerCollectFeeInfo"></a>

## Struct `OwnerCollectFeeInfo`

Event emitted when the position owner collects AMM trading fees directly.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectFeeInfo">OwnerCollectFeeInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the position for which AMM trading fees were collected.
</dd>
<dt>
<code>collected_x_amt: u64</code>
</dt>
<dd>
 The total amount of X fees collected from the AMM (before protocol fees are taken).
</dd>
<dt>
<code>collected_y_amt: u64</code>
</dt>
<dd>
 The total amount of Y fees collected from the AMM (before protocol fees are taken).
</dd>
<dt>
<code>fee_amt_x: u64</code>
</dt>
<dd>
 The protocol fee amount deducted from the collected X fees.
</dd>
<dt>
<code>fee_amt_y: u64</code>
</dt>
<dd>
 The protocol fee amount deducted from the collected Y fees.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_OwnerCollectRewardInfo"></a>

## Struct `OwnerCollectRewardInfo`

Event emitted when the position owner collects AMM rewards directly (not trading fees).


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectRewardInfo">OwnerCollectRewardInfo</a>&lt;<b>phantom</b> T&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the position for which AMM rewards were collected.
</dd>
<dt>
<code>collected_reward_amt: u64</code>
</dt>
<dd>
 The total amount of rewards collected from the AMM (before protocol fees are taken).
</dd>
<dt>
<code>fee_amt: u64</code>
</dt>
<dd>
 The protocol fee amount deducted from the collected rewards.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_OwnerTakeStashedRewardsInfo"></a>

## Struct `OwnerTakeStashedRewardsInfo`

Event emitted when the position owner takes stashed AMM rewards of a specific type from their position.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerTakeStashedRewardsInfo">OwnerTakeStashedRewardsInfo</a>&lt;<b>phantom</b> T&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the position from which stashed rewards were taken.
</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>
 The amount of stashed rewards of type <code>T</code> that were taken.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_DeletePositionInfo"></a>

## Struct `DeletePositionInfo`

Event emitted when a leveraged position is deleted.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletePositionInfo">DeletePositionInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the deleted position.
</dd>
<dt>
<code>cap_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a></code> capability associated with the deleted position.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_RebalanceInfo"></a>

## Struct `RebalanceInfo`

Comprehensive information about position rebalancing operations.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceInfo">RebalanceInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 Unique identifier for this rebalancing operation. Used for tracking and auditing.
</dd>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 ID of the position that was rebalanced
</dd>
<dt>
<code>collected_amm_fee_x: u64</code>
</dt>
<dd>
 Amount of X tokens collected from AMM fees (before protocol fee deduction)
</dd>
<dt>
<code>collected_amm_fee_y: u64</code>
</dt>
<dd>
 Amount of Y tokens collected from AMM fees (before protocol fee deduction)
</dd>
<dt>
<code>collected_amm_rewards: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;</code>
</dt>
<dd>
 Protocol-specific rewards collected from AMM (before protocol fee deduction)
</dd>
<dt>
<code>fees_taken: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;</code>
</dt>
<dd>
 Protocol fees taken from collected rewards and fees
</dd>
<dt>
<code>taken_cx: u64</code>
</dt>
<dd>
 Amount of X tokens taken from extra collateral
</dd>
<dt>
<code>taken_cy: u64</code>
</dt>
<dd>
 Amount of Y tokens taken from extra collateral
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128</code>
</dt>
<dd>
 Liquidity added to the LP position
</dd>
<dt>
<code>delta_x: u64</code>
</dt>
<dd>
 Amount of X tokens added to LP position (corresponding to delta_l)
</dd>
<dt>
<code>delta_y: u64</code>
</dt>
<dd>
 Amount of Y tokens added to LP position (corresponding to delta_l)
</dd>
<dt>
<code>x_repaid: u64</code>
</dt>
<dd>
 Amount of X debt repaid
</dd>
<dt>
<code>y_repaid: u64</code>
</dt>
<dd>
 Amount of Y debt repaid
</dd>
<dt>
<code>added_cx: u64</code>
</dt>
<dd>
 Amount of X tokens added to extra collateral
</dd>
<dt>
<code>added_cy: u64</code>
</dt>
<dd>
 Amount of Y tokens added to extra collateral
</dd>
<dt>
<code>stashed_amm_rewards: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;</code>
</dt>
<dd>
 Protocol-specific rewards stashed in position for later owner withdrawal
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_CollectProtocolFeesInfo"></a>

## Struct `CollectProtocolFeesInfo`

Event emitted when protocol fees are collected from a position for a specific token type.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CollectProtocolFeesInfo">CollectProtocolFeesInfo</a>&lt;<b>phantom</b> T&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the position from which protocol fees were collected.
</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>
 The amount of protocol fees collected (in token T).
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_DeletedPositionCollectedFeesInfo"></a>

## Struct `DeletedPositionCollectedFeesInfo`

Event emitted when the remaining fees are collected from a position that was previously deleted.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletedPositionCollectedFeesInfo">DeletedPositionCollectedFeesInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the deleted position.
</dd>
<dt>
<code>amounts: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;</code>
</dt>
<dd>
 Mapping from token type to amount of fees collected.
</dd>
</dl>


</details>

<a name="kai_leverage_position_core_clmm_BadDebtRepaid"></a>

## Struct `BadDebtRepaid`

Event emitted when bad debt is repaid for a position.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_BadDebtRepaid">BadDebtRepaid</a>&lt;<b>phantom</b> ST&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 The ID of the position for which bad debt was repaid.
</dd>
<dt>
<code>shares_repaid: u128</code>
</dt>
<dd>
 The number of debt shares repaid.
</dd>
<dt>
<code>balance_repaid: u64</code>
</dt>
<dd>
 The amount of underlying balance repaid.
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_position_core_clmm_CONFIG_VERSION"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CONFIG_VERSION">CONFIG_VERSION</a>: u16 = 4;
</code></pre>



<a name="kai_leverage_position_core_clmm_POSITION_VERSION"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_POSITION_VERSION">POSITION_VERSION</a>: u16 = 3;
</code></pre>



<a name="kai_leverage_position_core_clmm_ETicketNotExhausted"></a>

The ticket is not fully exhausted, so it cannot be destroyed.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ETicketNotExhausted">ETicketNotExhausted</a>: u64 = 10;
</code></pre>



<a name="kai_leverage_position_core_clmm_EInvalidConfigVersion"></a>

The <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a></code> version does not match the module version.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_EInvalidConfigVersion">EInvalidConfigVersion</a>: u64 = 16;
</code></pre>



<a name="kai_leverage_position_core_clmm_EInvalidPositionVersion"></a>

The <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a></code> version does not match the module version.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_EInvalidPositionVersion">EInvalidPositionVersion</a>: u64 = 17;
</code></pre>



<a name="kai_leverage_position_core_clmm_ENotUpgrade"></a>

The migration is not allowed because the object version is higher or equal to the module
version.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ENotUpgrade">ENotUpgrade</a>: u64 = 18;
</code></pre>



<a name="kai_leverage_position_core_clmm_EInvalidMarginValue"></a>

The deleverage margin must be higher than the liquidation margin.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_EInvalidMarginValue">EInvalidMarginValue</a>: u64 = 19;
</code></pre>



<a name="kai_leverage_position_core_clmm_e_invalid_tick_range"></a>

## Macro function `e_invalid_tick_range`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_tick_range">e_invalid_tick_range</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_tick_range">e_invalid_tick_range</a>(): u64 {
    0
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_liq_margin_too_low"></a>

## Macro function `e_liq_margin_too_low`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liq_margin_too_low">e_liq_margin_too_low</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liq_margin_too_low">e_liq_margin_too_low</a>(): u64 {
    1
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_initial_margin_too_low"></a>

## Macro function `e_initial_margin_too_low`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_initial_margin_too_low">e_initial_margin_too_low</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_initial_margin_too_low">e_initial_margin_too_low</a>(): u64 {
    2
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_new_positions_not_allowed"></a>

## Macro function `e_new_positions_not_allowed`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_new_positions_not_allowed">e_new_positions_not_allowed</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_new_positions_not_allowed">e_new_positions_not_allowed</a>(): u64 {
    3
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_invalid_config"></a>

## Macro function `e_invalid_config`

Invalid config passed in for the position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>(): u64 {
    4
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_invalid_pool"></a>

## Macro function `e_invalid_pool`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_pool">e_invalid_pool</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_pool">e_invalid_pool</a>(): u64 {
    5
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_invalid_borrow"></a>

## Macro function `e_invalid_borrow`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_borrow">e_invalid_borrow</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_borrow">e_invalid_borrow</a>(): u64 {
    6
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_invalid_position_cap"></a>

## Macro function `e_invalid_position_cap`

Invalid <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a></code> object.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>(): u64 {
    7
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_ticket_active"></a>

## Macro function `e_ticket_active`

Another ticket is already active for this position. One operation at a time please!


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>(): u64 {
    8
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_position_mismatch"></a>

## Macro function `e_position_mismatch`

The ticket / receipt does not match the position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>(): u64 {
    9
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_position_below_threshold"></a>

## Macro function `e_position_below_threshold`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_below_threshold">e_position_below_threshold</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_below_threshold">e_position_below_threshold</a>(): u64 {
    11
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_slippage_exceeded"></a>

## Macro function `e_slippage_exceeded`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_slippage_exceeded">e_slippage_exceeded</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_slippage_exceeded">e_slippage_exceeded</a>(): u64 {
    12
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_position_size_limit_exceeded"></a>

## Macro function `e_position_size_limit_exceeded`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_size_limit_exceeded">e_position_size_limit_exceeded</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_size_limit_exceeded">e_position_size_limit_exceeded</a>(): u64 {
    13
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_vault_global_size_limit_exceeded"></a>

## Macro function `e_vault_global_size_limit_exceeded`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_vault_global_size_limit_exceeded">e_vault_global_size_limit_exceeded</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_vault_global_size_limit_exceeded">e_vault_global_size_limit_exceeded</a>(): u64 {
    14
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_invalid_creation_fee_amount"></a>

## Macro function `e_invalid_creation_fee_amount`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_creation_fee_amount">e_invalid_creation_fee_amount</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_creation_fee_amount">e_invalid_creation_fee_amount</a>(): u64 {
    15
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_supply_pool_mismatch"></a>

## Macro function `e_supply_pool_mismatch`

The <code>SupplyPool</code> share type does not match the position debt share type.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>(): u64 {
    20
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_position_not_fully_deleveraged"></a>

## Macro function `e_position_not_fully_deleveraged`

The position must have zero outstanding debt before this operation can proceed.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_not_fully_deleveraged">e_position_not_fully_deleveraged</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_not_fully_deleveraged">e_position_not_fully_deleveraged</a>(): u64 {
    21
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_position_not_below_bad_debt_threshold"></a>

## Macro function `e_position_not_below_bad_debt_threshold`

The position's margin is not sufficiently low to qualify as bad debt.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_not_below_bad_debt_threshold">e_position_not_below_bad_debt_threshold</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_not_below_bad_debt_threshold">e_position_not_below_bad_debt_threshold</a>(): u64 {
    22
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_liquidation_disabled"></a>

## Macro function `e_liquidation_disabled`

Liquidation actions are currently disabled for this position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liquidation_disabled">e_liquidation_disabled</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liquidation_disabled">e_liquidation_disabled</a>(): u64 {
    23
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_reduction_disabled"></a>

## Macro function `e_reduction_disabled`

Reduction operations are currently disabled for this position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_reduction_disabled">e_reduction_disabled</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_reduction_disabled">e_reduction_disabled</a>(): u64 {
    24
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_add_liquidity_disabled"></a>

## Macro function `e_add_liquidity_disabled`

Adding liquidity is currently disabled for this position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_add_liquidity_disabled">e_add_liquidity_disabled</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_add_liquidity_disabled">e_add_liquidity_disabled</a>(): u64 {
    25
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_owner_collect_fee_disabled"></a>

## Macro function `e_owner_collect_fee_disabled`

Owner fee collection is currently disabled for this position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_owner_collect_fee_disabled">e_owner_collect_fee_disabled</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_owner_collect_fee_disabled">e_owner_collect_fee_disabled</a>(): u64 {
    26
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_owner_collect_reward_disabled"></a>

## Macro function `e_owner_collect_reward_disabled`

Owner reward collection is currently disabled for this position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_owner_collect_reward_disabled">e_owner_collect_reward_disabled</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_owner_collect_reward_disabled">e_owner_collect_reward_disabled</a>(): u64 {
    27
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_delete_position_disabled"></a>

## Macro function `e_delete_position_disabled`

Deleting this position is currently disabled.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_delete_position_disabled">e_delete_position_disabled</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_delete_position_disabled">e_delete_position_disabled</a>(): u64 {
    28
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_invalid_balance_value"></a>

## Macro function `e_invalid_balance_value`

Invalid balance value passed in for liquidity deposit.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_balance_value">e_invalid_balance_value</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_balance_value">e_invalid_balance_value</a>(): u64 {
    29
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_function_deprecated"></a>

## Macro function `e_function_deprecated`

Function deprecated.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_function_deprecated">e_function_deprecated</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_function_deprecated">e_function_deprecated</a>(): u64 {
    30
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_e_price_deviation_too_high"></a>

## Macro function `e_price_deviation_too_high`

The deviation between the oracle price and the pool price is too high.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_price_deviation_too_high">e_price_deviation_too_high</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_price_deviation_too_high">e_price_deviation_too_high</a>(): u64 {
    31
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_a_deleverage"></a>

## Function `a_deleverage`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_deleverage">a_deleverage</a>(): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ADeleverage">kai_leverage::position_core_clmm::ADeleverage</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_deleverage">a_deleverage</a>(): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ADeleverage">ADeleverage</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ADeleverage">ADeleverage</a> {}
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_a_rebalance"></a>

## Function `a_rebalance`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_rebalance">a_rebalance</a>(): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARebalance">kai_leverage::position_core_clmm::ARebalance</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_rebalance">a_rebalance</a>(): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARebalance">ARebalance</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARebalance">ARebalance</a> {}
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_a_repay_bad_debt"></a>

## Function `a_repay_bad_debt`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_repay_bad_debt">a_repay_bad_debt</a>(): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARepayBadDebt">kai_leverage::position_core_clmm::ARepayBadDebt</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_repay_bad_debt">a_repay_bad_debt</a>(): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARepayBadDebt">ARepayBadDebt</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARepayBadDebt">ARepayBadDebt</a> {}
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_constructor"></a>

## Function `position_constructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_constructor">position_constructor</a>&lt;X, Y, LP&gt;(config_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>: LP, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, debt_bag: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>: <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>: <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_constructor">position_constructor</a>&lt;X, Y, LP&gt;(
    config_id: ID,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>: LP,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>: Balance&lt;X&gt;,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>: Balance&lt;Y&gt;,
    debt_bag: FacilDebtBag,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>: BalanceBag,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>: BalanceBag,
    ctx: &<b>mut</b> TxContext,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt; {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a> {
        id: object::new(ctx),
        config_id,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>,
        debt_bag,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>: <b>false</b>,
        version: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_POSITION_VERSION">POSITION_VERSION</a>,
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_deconstructor"></a>

## Function `position_deconstructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_deconstructor">position_deconstructor</a>&lt;X, Y, LP: store&gt;(position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): (<a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a>, <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, LP, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>, <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, bool, u16)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_deconstructor">position_deconstructor</a>&lt;X, Y, LP: store&gt;(
    position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
): (UID, ID, LP, Balance&lt;X&gt;, Balance&lt;Y&gt;, FacilDebtBag, BalanceBag, BalanceBag, bool, u16) {
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a> {
        id,
        config_id,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>,
        debt_bag,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>,
        version,
    } = position;
    (
        id,
        config_id,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>,
        debt_bag,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>,
        version,
    )
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_share_object"></a>

## Function `position_share_object`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_share_object">position_share_object</a>&lt;X, Y, LP: store&gt;(position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_share_object">position_share_object</a>&lt;X, Y, LP: store&gt;(position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;) {
    transfer::share_object(position);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_config_id"></a>

## Function `position_config_id`

Get the position configuration ID.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_config_id">position_config_id</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_config_id">position_config_id</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): ID {
    position.config_id
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_lp_position"></a>

## Function `lp_position`

Get reference to the LP position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &LP
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &LP {
    &position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_col_x"></a>

## Function `col_x`

Get reference to X token collateral balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &Balance&lt;X&gt; {
    &position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_col_y"></a>

## Function `col_y`

Get reference to Y token collateral balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &Balance&lt;Y&gt; {
    &position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_debt_bag"></a>

## Function `position_debt_bag`

Get reference to the position's debt bag.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_debt_bag">position_debt_bag</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_debt_bag">position_debt_bag</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &FacilDebtBag {
    &position.debt_bag
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ticket_active"></a>

## Function `ticket_active`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): bool {
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_ticket_active"></a>

## Function `set_ticket_active`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_ticket_active">set_ticket_active</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, value: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_ticket_active">set_ticket_active</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;, value: bool) {
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a> = value;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_lp_position_mut"></a>

## Function `lp_position_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> LP
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> LP {
    &<b>mut</b> position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_col_x_mut"></a>

## Function `col_x_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x_mut">col_x_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x_mut">col_x_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> Balance&lt;X&gt; {
    &<b>mut</b> position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_col_y_mut"></a>

## Function `col_y_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y_mut">col_y_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y_mut">col_y_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> Balance&lt;Y&gt; {
    &<b>mut</b> position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_debt_bag_mut"></a>

## Function `position_debt_bag_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_debt_bag_mut">position_debt_bag_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_debt_bag_mut">position_debt_bag_mut</a>&lt;X, Y, LP&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
): &<b>mut</b> FacilDebtBag {
    &<b>mut</b> position.debt_bag
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_collected_fees"></a>

## Function `collected_fees`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &BalanceBag {
    &position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_collected_fees_mut"></a>

## Function `collected_fees_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees_mut">collected_fees_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees_mut">collected_fees_mut</a>&lt;X, Y, LP&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
): &<b>mut</b> BalanceBag {
    &<b>mut</b> position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_owner_reward_stash"></a>

## Function `owner_reward_stash`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;): &BalanceBag {
    &position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_owner_reward_stash_mut"></a>

## Function `owner_reward_stash_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash_mut">owner_reward_stash_mut</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;): &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash_mut">owner_reward_stash_mut</a>&lt;X, Y, LP&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
): &<b>mut</b> BalanceBag {
    &<b>mut</b> position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_cap_constructor"></a>

## Function `position_cap_constructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_cap_constructor">position_cap_constructor</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_cap_constructor">position_cap_constructor</a>(position_id: ID, ctx: &<b>mut</b> TxContext): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a> {
        id: object::new(ctx),
        position_id,
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_cap_deconstructor"></a>

## Function `position_cap_deconstructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_cap_deconstructor">position_cap_deconstructor</a>(cap: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>): (<a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a>, <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_cap_deconstructor">position_cap_deconstructor</a>(cap: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>): (UID, ID) {
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a> { id, position_id } = cap;
    (id, position_id)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_pc_position_id"></a>

## Function `pc_position_id`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pc_position_id">pc_position_id</a>(cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pc_position_id">pc_position_id</a>(cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>): ID {
    cap.position_id
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_create_empty_config"></a>

## Function `create_empty_config`

Create an empty position configuration with default values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_empty_config">create_empty_config</a>(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_empty_config">create_empty_config</a>(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>: ID, ctx: &<b>mut</b> TxContext): (ID, ActionRequest) {
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a> = supply_pool::create_lend_facil_cap(ctx);
    <b>let</b> lend_facil_cap_id = object::id(&<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>);
    <b>let</b> config = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a> {
        id: object::new(ctx),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allow_new_positions">allow_new_positions</a>: <b>false</b>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps">min_liq_start_price_delta_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_init_margin_bps">min_init_margin_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>: bag::new(ctx),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_deleverage_factor_bps">base_deleverage_factor_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_position_l">max_position_l</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_global_l">max_global_l</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_fee_bps">liq_fee_bps</a>: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_creation_fee_sui">position_creation_fee_sui</a>: 0,
        version: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CONFIG_VERSION">CONFIG_VERSION</a>,
    };
    transfer::share_object(config);
    (lend_facil_cap_id, access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ACreateConfig">ACreateConfig</a> {}, ctx))
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_pool_object_id"></a>

## Function `pool_object_id`

Get the pool object ID from position config.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): ID {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_allow_new_positions"></a>

## Function `allow_new_positions`

Check if new position creation is allowed.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allow_new_positions">allow_new_positions</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allow_new_positions">allow_new_positions</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): bool {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allow_new_positions">allow_new_positions</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_lend_facil_cap"></a>

## Function `lend_facil_cap`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilCap">kai_leverage::supply_pool::LendFacilCap</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): &LendFacilCap {
    &config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_min_liq_start_price_delta_bps"></a>

## Function `min_liq_start_price_delta_bps`

Get minimum liquidation start price delta in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps">min_liq_start_price_delta_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps">min_liq_start_price_delta_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps">min_liq_start_price_delta_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_min_init_margin_bps"></a>

## Function `min_init_margin_bps`

Get minimum initial margin in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_init_margin_bps">min_init_margin_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_init_margin_bps">min_init_margin_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_init_margin_bps">min_init_margin_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_allowed_oracles"></a>

## Function `allowed_oracles`

Get allowed oracles bag.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): &<a href="../../dependencies/sui/bag.md#sui_bag_Bag">sui::bag::Bag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): &Bag {
    &config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_deleverage_margin_bps"></a>

## Function `deleverage_margin_bps`

Get deleveraging margin threshold in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_base_deleverage_factor_bps"></a>

## Function `base_deleverage_factor_bps`

Get base deleveraging factor in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_deleverage_factor_bps">base_deleverage_factor_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_deleverage_factor_bps">base_deleverage_factor_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_deleverage_factor_bps">base_deleverage_factor_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_liq_margin_bps"></a>

## Function `liq_margin_bps`

Get liquidation margin threshold in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_base_liq_factor_bps"></a>

## Function `base_liq_factor_bps`

Get base liquidation factor in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_liq_bonus_bps"></a>

## Function `liq_bonus_bps`

Get liquidation bonus in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_max_position_l"></a>

## Function `max_position_l`

Get maximum allowed liquidity per position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_position_l">max_position_l</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_position_l">max_position_l</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u128 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_position_l">max_position_l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_max_global_l"></a>

## Function `max_global_l`

Get maximum global liquidity limit.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_global_l">max_global_l</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_global_l">max_global_l</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u128 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_global_l">max_global_l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_current_global_l"></a>

## Function `current_global_l`

Get current total global liquidity.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u128 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rebalance_fee_bps"></a>

## Function `rebalance_fee_bps`

Get rebalancing fee in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_liq_fee_bps"></a>

## Function `liq_fee_bps`

Get liquidation fee in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_fee_bps">liq_fee_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_fee_bps">liq_fee_bps</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u16 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_fee_bps">liq_fee_bps</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_position_creation_fee_sui"></a>

## Function `position_creation_fee_sui`

Get position creation fee in SUI tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_creation_fee_sui">position_creation_fee_sui</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_creation_fee_sui">position_creation_fee_sui</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): u64 {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_creation_fee_sui">position_creation_fee_sui</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_increase_current_global_l"></a>

## Function `increase_current_global_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_current_global_l">increase_current_global_l</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_current_global_l">increase_current_global_l</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128) {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a> = config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a> + <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_decrease_current_global_l"></a>

## Function `decrease_current_global_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_decrease_current_global_l">decrease_current_global_l</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_decrease_current_global_l">decrease_current_global_l</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128) {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a> = config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a> - <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_allow_new_positions"></a>

## Function `set_allow_new_positions`

Set whether new position creation is allowed.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_allow_new_positions">set_allow_new_positions</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: bool, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_allow_new_positions">set_allow_new_positions</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: bool,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allow_new_positions">allow_new_positions</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_min_liq_start_price_delta_bps"></a>

## Function `set_min_liq_start_price_delta_bps`

Set minimum liquidation start price delta in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_min_liq_start_price_delta_bps">set_min_liq_start_price_delta_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_min_liq_start_price_delta_bps">set_min_liq_start_price_delta_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps">min_liq_start_price_delta_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_min_init_margin_bps"></a>

## Function `set_min_init_margin_bps`

Set minimum initial margin requirement in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_min_init_margin_bps">set_min_init_margin_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_min_init_margin_bps">set_min_init_margin_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_init_margin_bps">min_init_margin_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_config_add_empty_pyth_config"></a>

## Function `config_add_empty_pyth_config`

Add empty Pyth configuration to position config.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_config_add_empty_pyth_config">config_add_empty_pyth_config</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_config_add_empty_pyth_config">config_add_empty_pyth_config</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> pyth_config = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a> {
        max_age_secs: 0,
        pio_allowlist: vec_map::empty(),
    };
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>.add(type_name::with_defining_ids&lt;<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a>&gt;(), pyth_config);
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_pyth_config_max_age_secs"></a>

## Function `set_pyth_config_max_age_secs`

Set maximum age for Pyth price feeds in seconds.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_pyth_config_max_age_secs">set_pyth_config_max_age_secs</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, max_age_secs: u64, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_pyth_config_max_age_secs">set_pyth_config_max_age_secs</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    max_age_secs: u64,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> pyth_config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a> =
        &<b>mut</b> config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>[type_name::with_defining_ids&lt;<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a>&gt;()];
    pyth_config.max_age_secs = max_age_secs;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_pyth_config_allow_pio"></a>

## Function `pyth_config_allow_pio`

Allow a specific Pyth price info object for a coin type.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pyth_config_allow_pio">pyth_config_allow_pio</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, coin_type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, pio_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pyth_config_allow_pio">pyth_config_allow_pio</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    coin_type: TypeName,
    pio_id: ID,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> pyth_config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a> =
        &<b>mut</b> config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>[type_name::with_defining_ids&lt;<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a>&gt;()];
    pyth_config.pio_allowlist.insert(coin_type, pio_id);
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_pyth_config_disallow_pio"></a>

## Function `pyth_config_disallow_pio`

Remove allowlist for a specific Pyth price info object.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pyth_config_disallow_pio">pyth_config_disallow_pio</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, coin_type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pyth_config_disallow_pio">pyth_config_disallow_pio</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    coin_type: TypeName,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> pyth_config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a> =
        &<b>mut</b> config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>[type_name::with_defining_ids&lt;<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a>&gt;()];
    pyth_config.pio_allowlist.remove(&coin_type);
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_deleverage_margin_bps"></a>

## Function `set_deleverage_margin_bps`

Set deleveraging margin threshold in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_deleverage_margin_bps">set_deleverage_margin_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_deleverage_margin_bps">set_deleverage_margin_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>assert</b>!(value &gt; config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_EInvalidMarginValue">EInvalidMarginValue</a>);
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_base_deleverage_factor_bps"></a>

## Function `set_base_deleverage_factor_bps`

Set base deleveraging factor in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_base_deleverage_factor_bps">set_base_deleverage_factor_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_base_deleverage_factor_bps">set_base_deleverage_factor_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_deleverage_factor_bps">base_deleverage_factor_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_liq_margin_bps"></a>

## Function `set_liq_margin_bps`

Set liquidation margin threshold in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_liq_margin_bps">set_liq_margin_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_liq_margin_bps">set_liq_margin_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>assert</b>!(value &lt; config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_EInvalidMarginValue">EInvalidMarginValue</a>);
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_base_liq_factor_bps"></a>

## Function `set_base_liq_factor_bps`

Set base liquidation factor in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_base_liq_factor_bps">set_base_liq_factor_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_base_liq_factor_bps">set_base_liq_factor_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_liq_bonus_bps"></a>

## Function `set_liq_bonus_bps`

Set liquidation bonus in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_liq_bonus_bps">set_liq_bonus_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_liq_bonus_bps">set_liq_bonus_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_max_position_l"></a>

## Function `set_max_position_l`

Set maximum liquidity allowed per position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_max_position_l">set_max_position_l</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u128, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_max_position_l">set_max_position_l</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u128,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_position_l">max_position_l</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_max_global_l"></a>

## Function `set_max_global_l`

Set maximum global liquidity limit across all positions.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_max_global_l">set_max_global_l</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u128, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_max_global_l">set_max_global_l</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u128,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_global_l">max_global_l</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_rebalance_fee_bps"></a>

## Function `set_rebalance_fee_bps`

Set rebalancing fee in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_rebalance_fee_bps">set_rebalance_fee_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_rebalance_fee_bps">set_rebalance_fee_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_liq_fee_bps"></a>

## Function `set_liq_fee_bps`

Set liquidation fee in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_liq_fee_bps">set_liq_fee_bps</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_liq_fee_bps">set_liq_fee_bps</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_fee_bps">liq_fee_bps</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_position_creation_fee_sui"></a>

## Function `set_position_creation_fee_sui`

Set position creation fee in SUI tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_position_creation_fee_sui">set_position_creation_fee_sui</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, value: u64, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_position_creation_fee_sui">set_position_creation_fee_sui</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    value: u64,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_creation_fee_sui">position_creation_fee_sui</a> = value;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_upsert_config_extension"></a>

## Function `upsert_config_extension`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_upsert_config_extension">upsert_config_extension</a>&lt;Key: <b>copy</b>, drop, store, Val: drop, store&gt;(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, key: Key, new_value: Val, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_upsert_config_extension">upsert_config_extension</a>&lt;Key: <b>copy</b> + drop + store, Val: store + drop&gt;(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    key: Key,
    new_value: Val,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    <b>if</b> (df::exists_(&config.id, key)) {
        <b>let</b> val = df::borrow_mut&lt;Key, Val&gt;(&<b>mut</b> config.id, key);
        *val = new_value;
    } <b>else</b> {
        df::add(&<b>mut</b> config.id, key, new_value);
    };
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_config_extension"></a>

## Function `add_config_extension`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_config_extension">add_config_extension</a>&lt;Key: <b>copy</b>, drop, store, Val: store&gt;(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, key: Key, new_value: Val, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_config_extension">add_config_extension</a>&lt;Key: <b>copy</b> + drop + store, Val: store&gt;(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    key: Key,
    new_value: Val,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    df::add(&<b>mut</b> config.id, key, new_value);
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_has_config_extension"></a>

## Function `has_config_extension`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_has_config_extension">has_config_extension</a>&lt;Key: <b>copy</b>, drop, store&gt;(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, key: Key): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_has_config_extension">has_config_extension</a>&lt;Key: <b>copy</b> + drop + store&gt;(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>, key: Key): bool {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    df::exists_(&config.id, key)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrow_config_extension"></a>

## Function `borrow_config_extension`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_config_extension">borrow_config_extension</a>&lt;Key: <b>copy</b>, drop, store, Val: store&gt;(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, key: Key): &Val
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_config_extension">borrow_config_extension</a>&lt;Key: <b>copy</b> + drop + store, Val: store&gt;(
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    key: Key,
): &Val {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    df::borrow&lt;Key, Val&gt;(&config.id, key)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_get_config_extension_or_default"></a>

## Function `get_config_extension_or_default`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_config_extension_or_default">get_config_extension_or_default</a>&lt;Key: <b>copy</b>, drop, store, Val: <b>copy</b>, drop, store&gt;(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, key: Key, default_value: Val): Val
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_config_extension_or_default">get_config_extension_or_default</a>&lt;Key: <b>copy</b> + drop + store, Val: <b>copy</b> + drop + store&gt;(
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    key: Key,
    default_value: Val,
): Val {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    <b>if</b> (df::exists_(&config.id, key)) {
        *df::borrow&lt;Key, Val&gt;(&config.id, key)
    } <b>else</b> {
        default_value
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_config_extension_mut"></a>

## Function `config_extension_mut`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_config_extension_mut">config_extension_mut</a>&lt;Key: <b>copy</b>, drop, store, Val: store&gt;(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, key: Key): &<b>mut</b> Val
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_config_extension_mut">config_extension_mut</a>&lt;Key: <b>copy</b> + drop + store, Val: store&gt;(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    key: Key,
): &<b>mut</b> Val {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    df::borrow_mut&lt;Key, Val&gt;(&<b>mut</b> config.id, key)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_liquidation_disabled"></a>

## Function `set_liquidation_disabled`

Enable or disable liquidation operations.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_liquidation_disabled">set_liquidation_disabled</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, disabled: bool, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_liquidation_disabled">set_liquidation_disabled</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    disabled: bool,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_upsert_config_extension">upsert_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_LiquidationDisabledKey">LiquidationDisabledKey</a>(), disabled, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_liquidation_disabled"></a>

## Function `liquidation_disabled`

Check if liquidation operations are disabled.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidation_disabled">liquidation_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidation_disabled">liquidation_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): bool {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_config_extension_or_default">get_config_extension_or_default</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_LiquidationDisabledKey">LiquidationDisabledKey</a>(), <b>false</b>)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_reduction_disabled"></a>

## Function `set_reduction_disabled`

Enable or disable position reduction (withdrawal) operations.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_reduction_disabled">set_reduction_disabled</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, disabled: bool, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_reduction_disabled">set_reduction_disabled</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    disabled: bool,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_upsert_config_extension">upsert_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionDisabledKey">ReductionDisabledKey</a>(), disabled, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_reduction_disabled"></a>

## Function `reduction_disabled`

Check if position reduction operations are disabled.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_disabled">reduction_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_disabled">reduction_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): bool {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_config_extension_or_default">get_config_extension_or_default</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionDisabledKey">ReductionDisabledKey</a>(), <b>false</b>)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_add_liquidity_disabled"></a>

## Function `set_add_liquidity_disabled`

Enable or disable adding liquidity to positions.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_add_liquidity_disabled">set_add_liquidity_disabled</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, disabled: bool, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_add_liquidity_disabled">set_add_liquidity_disabled</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    disabled: bool,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_upsert_config_extension">upsert_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityDisabledKey">AddLiquidityDisabledKey</a>(), disabled, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_liquidity_disabled"></a>

## Function `add_liquidity_disabled`

Check if adding liquidity to positions is disabled.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_disabled">add_liquidity_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_disabled">add_liquidity_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): bool {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_config_extension_or_default">get_config_extension_or_default</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityDisabledKey">AddLiquidityDisabledKey</a>(), <b>false</b>)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_owner_collect_fee_disabled"></a>

## Function `set_owner_collect_fee_disabled`

Enable or disable owner fee collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_owner_collect_fee_disabled">set_owner_collect_fee_disabled</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, disabled: bool, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_owner_collect_fee_disabled">set_owner_collect_fee_disabled</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    disabled: bool,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_upsert_config_extension">upsert_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectFeeDisabledKey">OwnerCollectFeeDisabledKey</a>(), disabled, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_owner_collect_fee_disabled"></a>

## Function `owner_collect_fee_disabled`

Check if owner fee collection is disabled.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_fee_disabled">owner_collect_fee_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_fee_disabled">owner_collect_fee_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): bool {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_config_extension_or_default">get_config_extension_or_default</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectFeeDisabledKey">OwnerCollectFeeDisabledKey</a>(), <b>false</b>)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_owner_collect_reward_disabled"></a>

## Function `set_owner_collect_reward_disabled`

Enable or disable owner reward collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_owner_collect_reward_disabled">set_owner_collect_reward_disabled</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, disabled: bool, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_owner_collect_reward_disabled">set_owner_collect_reward_disabled</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    disabled: bool,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_upsert_config_extension">upsert_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectRewardDisabledKey">OwnerCollectRewardDisabledKey</a>(), disabled, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_owner_collect_reward_disabled"></a>

## Function `owner_collect_reward_disabled`

Check if owner reward collection is disabled.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_reward_disabled">owner_collect_reward_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_reward_disabled">owner_collect_reward_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): bool {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_config_extension_or_default">get_config_extension_or_default</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectRewardDisabledKey">OwnerCollectRewardDisabledKey</a>(), <b>false</b>)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_delete_position_disabled"></a>

## Function `set_delete_position_disabled`

Enable or disable position deletion.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delete_position_disabled">set_delete_position_disabled</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, disabled: bool, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delete_position_disabled">set_delete_position_disabled</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    disabled: bool,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_upsert_config_extension">upsert_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletePositionDisabledKey">DeletePositionDisabledKey</a>(), disabled, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_delete_position_disabled"></a>

## Function `delete_position_disabled`

Check if position deletion is disabled.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delete_position_disabled">delete_position_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delete_position_disabled">delete_position_disabled</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): bool {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_config_extension_or_default">get_config_extension_or_default</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletePositionDisabledKey">DeletePositionDisabledKey</a>(), <b>false</b>)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_create_withdraw_limiter"></a>

## Function `add_create_withdraw_limiter`

Add rate limiter for position creation and withdrawal operations.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_create_withdraw_limiter">add_create_withdraw_limiter</a>&lt;L: store&gt;(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, rate_limiter: L, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_create_withdraw_limiter">add_create_withdraw_limiter</a>&lt;L: store&gt;(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    rate_limiter: L,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_config_extension">add_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCreateWithdrawLimiterKey">PositionCreateWithdrawLimiterKey</a>(), rate_limiter, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_has_create_withdraw_limiter"></a>

## Function `has_create_withdraw_limiter`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_has_create_withdraw_limiter">has_create_withdraw_limiter</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_has_create_withdraw_limiter">has_create_withdraw_limiter</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): bool {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_has_config_extension">has_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCreateWithdrawLimiterKey">PositionCreateWithdrawLimiterKey</a>())
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrow_create_withdraw_limiter"></a>

## Function `borrow_create_withdraw_limiter`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter">borrow_create_withdraw_limiter</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): &<a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter">borrow_create_withdraw_limiter</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>): &NetSlidingSumLimiter {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_config_extension">borrow_config_extension</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCreateWithdrawLimiterKey">PositionCreateWithdrawLimiterKey</a>())
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrow_create_withdraw_limiter_mut"></a>

## Function `borrow_create_withdraw_limiter_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter_mut">borrow_create_withdraw_limiter_mut</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>): &<b>mut</b> <a href="../../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter_mut">borrow_create_withdraw_limiter_mut</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
): &<b>mut</b> NetSlidingSumLimiter {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_config_extension_mut">config_extension_mut</a>(config, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCreateWithdrawLimiterKey">PositionCreateWithdrawLimiterKey</a>())
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_max_create_withdraw_net_inflow_and_outflow_limits"></a>

## Function `set_max_create_withdraw_net_inflow_and_outflow_limits`

Set maximum net inflow and outflow limits for rate limiter.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_max_create_withdraw_net_inflow_and_outflow_limits">set_max_create_withdraw_net_inflow_and_outflow_limits</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, max_net_inflow_limit: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;, max_net_outflow_limit: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_max_create_withdraw_net_inflow_and_outflow_limits">set_max_create_withdraw_net_inflow_and_outflow_limits</a>(
    config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    max_net_inflow_limit: Option&lt;u256&gt;,
    max_net_outflow_limit: Option&lt;u256&gt;,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    <b>let</b> rate_limiter = config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter_mut">borrow_create_withdraw_limiter_mut</a>();
    rate_limiter.set_max_net_inflow_limit(max_net_inflow_limit);
    rate_limiter.set_max_net_outflow_limit(max_net_outflow_limit);
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AModifyConfig">AModifyConfig</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_deleverage_ticket_constructor"></a>

## Function `deleverage_ticket_constructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_constructor">deleverage_ticket_constructor</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, can_repay_x: bool, can_repay_y: bool, info: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_constructor">deleverage_ticket_constructor</a>(
    position_id: ID,
    can_repay_x: bool,
    can_repay_y: bool,
    info: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a> { position_id, can_repay_x, can_repay_y, info }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_dt_position_id"></a>

## Function `dt_position_id`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dt_position_id">dt_position_id</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dt_position_id">dt_position_id</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>): ID {
    self.position_id
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_dt_can_repay_x"></a>

## Function `dt_can_repay_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dt_can_repay_x">dt_can_repay_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dt_can_repay_x">dt_can_repay_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>): bool {
    self.can_repay_x
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_dt_can_repay_y"></a>

## Function `dt_can_repay_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dt_can_repay_y">dt_can_repay_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dt_can_repay_y">dt_can_repay_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>): bool {
    self.can_repay_y
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_dt_info"></a>

## Function `dt_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dt_info">dt_info</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>): &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dt_info">dt_info</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>): &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a> {
    &self.info
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_reduction_repayment_ticket_constructor"></a>

## Function `reduction_repayment_ticket_constructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_repayment_ticket_constructor">reduction_repayment_ticket_constructor</a>&lt;SX, SY&gt;(sx: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;SX&gt;, sy: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;SY&gt;, info: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_repayment_ticket_constructor">reduction_repayment_ticket_constructor</a>&lt;SX, SY&gt;(
    sx: FacilDebtShare&lt;SX&gt;,
    sy: FacilDebtShare&lt;SY&gt;,
    info: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt; {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a> { sx, sy, info }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rrt_sx"></a>

## Function `rrt_sx`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rrt_sx">rrt_sx</a>&lt;SX, SY&gt;(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;): &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;SX&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rrt_sx">rrt_sx</a>&lt;SX, SY&gt;(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt;): &FacilDebtShare&lt;SX&gt; {
    &self.sx
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rrt_sy"></a>

## Function `rrt_sy`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rrt_sy">rrt_sy</a>&lt;SX, SY&gt;(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;): &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;SY&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rrt_sy">rrt_sy</a>&lt;SX, SY&gt;(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt;): &FacilDebtShare&lt;SY&gt; {
    &self.sy
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rrt_info"></a>

## Function `rrt_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rrt_info">rrt_info</a>&lt;SX, SY&gt;(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;): &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rrt_info">rrt_info</a>&lt;SX, SY&gt;(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt;): &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a> {
    &self.info
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_position_id"></a>

## Function `rr_position_id`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_position_id">rr_position_id</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_position_id">rr_position_id</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): ID {
    self.position_id
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_increase_collected_amm_fee_x"></a>

## Function `increase_collected_amm_fee_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_collected_amm_fee_x">increase_collected_amm_fee_x</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, delta: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_collected_amm_fee_x">increase_collected_amm_fee_x</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>, delta: u64) {
    self.collected_amm_fee_x = self.collected_amm_fee_x + delta;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_increase_collected_amm_fee_y"></a>

## Function `increase_collected_amm_fee_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_collected_amm_fee_y">increase_collected_amm_fee_y</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, delta: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_collected_amm_fee_y">increase_collected_amm_fee_y</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>, delta: u64) {
    self.collected_amm_fee_y = self.collected_amm_fee_y + delta;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_collected_amm_rewards_mut"></a>

## Function `collected_amm_rewards_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_amm_rewards_mut">collected_amm_rewards_mut</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): &<b>mut</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_amm_rewards_mut">collected_amm_rewards_mut</a>(
    self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
): &<b>mut</b> VecMap&lt;TypeName, u64&gt; {
    &<b>mut</b> self.collected_amm_rewards
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_increase_delta_l"></a>

## Function `increase_delta_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_l">increase_delta_l</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, delta: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_l">increase_delta_l</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>, delta: u128) {
    self.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> = self.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> + delta;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_increase_delta_x"></a>

## Function `increase_delta_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_x">increase_delta_x</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, delta: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_x">increase_delta_x</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>, delta: u64) {
    self.delta_x = self.delta_x + delta;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_increase_delta_y"></a>

## Function `increase_delta_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_y">increase_delta_y</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, delta: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_y">increase_delta_y</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>, delta: u64) {
    self.delta_y = self.delta_y + delta;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_collected_amm_fee_x"></a>

## Function `rr_collected_amm_fee_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_collected_amm_fee_x">rr_collected_amm_fee_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_collected_amm_fee_x">rr_collected_amm_fee_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.collected_amm_fee_x
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_collected_amm_fee_y"></a>

## Function `rr_collected_amm_fee_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_collected_amm_fee_y">rr_collected_amm_fee_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_collected_amm_fee_y">rr_collected_amm_fee_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.collected_amm_fee_y
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_collected_amm_rewards"></a>

## Function `rr_collected_amm_rewards`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_collected_amm_rewards">rr_collected_amm_rewards</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): &<a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_collected_amm_rewards">rr_collected_amm_rewards</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): &VecMap&lt;TypeName, u64&gt; {
    &self.collected_amm_rewards
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_fees_taken"></a>

## Function `rr_fees_taken`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_fees_taken">rr_fees_taken</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): &<a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_fees_taken">rr_fees_taken</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): &VecMap&lt;TypeName, u64&gt; {
    &self.fees_taken
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_taken_cx"></a>

## Function `rr_taken_cx`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_taken_cx">rr_taken_cx</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_taken_cx">rr_taken_cx</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.taken_cx
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_taken_cy"></a>

## Function `rr_taken_cy`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_taken_cy">rr_taken_cy</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_taken_cy">rr_taken_cy</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.taken_cy
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_delta_l"></a>

## Function `rr_delta_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_delta_l">rr_delta_l</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_delta_l">rr_delta_l</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_delta_x"></a>

## Function `rr_delta_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_delta_x">rr_delta_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_delta_x">rr_delta_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.delta_x
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_delta_y"></a>

## Function `rr_delta_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_delta_y">rr_delta_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_delta_y">rr_delta_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.delta_y
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_x_repaid"></a>

## Function `rr_x_repaid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_x_repaid">rr_x_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_x_repaid">rr_x_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.x_repaid
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_y_repaid"></a>

## Function `rr_y_repaid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_y_repaid">rr_y_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_y_repaid">rr_y_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.y_repaid
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_added_cx"></a>

## Function `rr_added_cx`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_added_cx">rr_added_cx</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_added_cx">rr_added_cx</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.added_cx
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_added_cy"></a>

## Function `rr_added_cy`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_added_cy">rr_added_cy</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_added_cy">rr_added_cy</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): u64 {
    self.added_cy
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rr_stashed_amm_rewards"></a>

## Function `rr_stashed_amm_rewards`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_stashed_amm_rewards">rr_stashed_amm_rewards</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>): &<a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rr_stashed_amm_rewards">rr_stashed_amm_rewards</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>): &VecMap&lt;TypeName, u64&gt; {
    &self.stashed_amm_rewards
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_new_create_position_ticket"></a>

## Function `new_create_position_ticket`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_new_create_position_ticket">new_create_position_ticket</a>&lt;X, Y, I32&gt;(config_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, tick_a: I32, tick_b: I32, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>: u64, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>: u64, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, debt_bag: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_new_create_position_ticket">new_create_position_ticket</a>&lt;X, Y, I32&gt;(
    config_id: ID,
    tick_a: I32,
    tick_b: I32,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>: u64,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>: u64,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>: Balance&lt;X&gt;,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>: Balance&lt;Y&gt;,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>: Balance&lt;X&gt;,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>: Balance&lt;Y&gt;,
    debt_bag: FacilDebtBag,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt; {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a> {
        config_id,
        tick_a,
        tick_b,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>,
        debt_bag,
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_destroy_create_position_ticket"></a>

## Function `destroy_create_position_ticket`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_create_position_ticket">destroy_create_position_ticket</a>&lt;X, Y, I32&gt;(ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): (<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, I32, I32, u64, u64, u128, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_create_position_ticket">destroy_create_position_ticket</a>&lt;X, Y, I32&gt;(
    ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;,
): (ID, I32, I32, u64, u64, u128, Balance&lt;X&gt;, Balance&lt;Y&gt;, Balance&lt;X&gt;, Balance&lt;Y&gt;, FacilDebtBag) {
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a> {
        config_id,
        tick_a,
        tick_b,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>,
        debt_bag,
    } = ticket;
    (
        config_id,
        tick_a,
        tick_b,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>,
        debt_bag,
    )
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_cpt_config_id"></a>

## Function `cpt_config_id`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_config_id">cpt_config_id</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_config_id">cpt_config_id</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): ID {
    ticket.config_id
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_dx"></a>

## Function `dx`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): u64 {
    ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_dy"></a>

## Function `dy`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): u64 {
    ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrowed_x"></a>

## Function `borrowed_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): &Balance&lt;X&gt; {
    &ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrowed_x_mut"></a>

## Function `borrowed_x_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x_mut">borrowed_x_mut</a>&lt;X, Y, I32&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x_mut">borrowed_x_mut</a>&lt;X, Y, I32&gt;(
    ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;,
): &<b>mut</b> Balance&lt;X&gt; {
    &<b>mut</b> ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrowed_y"></a>

## Function `borrowed_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): &Balance&lt;Y&gt; {
    &ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrowed_y_mut"></a>

## Function `borrowed_y_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y_mut">borrowed_y_mut</a>&lt;X, Y, I32&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y_mut">borrowed_y_mut</a>&lt;X, Y, I32&gt;(
    ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;,
): &<b>mut</b> Balance&lt;Y&gt; {
    &<b>mut</b> ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_delta_l"></a>

## Function `delta_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): u128 {
    ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_principal_x"></a>

## Function `principal_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): &Balance&lt;X&gt; {
    &ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_principal_y"></a>

## Function `principal_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): &Balance&lt;Y&gt; {
    &ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_cpt_debt_bag"></a>

## Function `cpt_debt_bag`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_debt_bag">cpt_debt_bag</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_debt_bag">cpt_debt_bag</a>&lt;X, Y, I32&gt;(
    ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;,
): &FacilDebtBag {
    &ticket.debt_bag
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_cpt_debt_bag_mut"></a>

## Function `cpt_debt_bag_mut`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_debt_bag_mut">cpt_debt_bag_mut</a>&lt;X, Y, I32&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_debt_bag_mut">cpt_debt_bag_mut</a>&lt;X, Y, I32&gt;(
    ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;,
): &<b>mut</b> FacilDebtBag {
    &<b>mut</b> ticket.debt_bag
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_cpt_tick_a"></a>

## Function `cpt_tick_a`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_tick_a">cpt_tick_a</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &I32
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_tick_a">cpt_tick_a</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): &I32 {
    &ticket.tick_a
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_cpt_tick_b"></a>

## Function `cpt_tick_b`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_tick_b">cpt_tick_b</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;X, Y, I32&gt;): &I32
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_cpt_tick_b">cpt_tick_b</a>&lt;X, Y, I32&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;X, Y, I32&gt;): &I32 {
    &ticket.tick_b
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_share_deleted_position_collected_fees"></a>

## Function `share_deleted_position_collected_fees`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_share_deleted_position_collected_fees">share_deleted_position_collected_fees</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, balance_bag: <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_share_deleted_position_collected_fees">share_deleted_position_collected_fees</a>(
    position_id: ID,
    balance_bag: BalanceBag,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> id = object::new(ctx);
    transfer::share_object(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletedPositionCollectedFees">DeletedPositionCollectedFees</a> { id, position_id, balance_bag });
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_emit_position_creation_info"></a>

## Function `emit_position_creation_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_position_creation_info">emit_position_creation_info</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, config_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, sqrt_pa_x64: u128, sqrt_pb_x64: u128, l: u128, x0: u64, y0: u64, cx: u64, cy: u64, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>: u64, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>: u64, creation_fee_amt_sui: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_position_creation_info">emit_position_creation_info</a>(
    position_id: ID,
    config_id: ID,
    sqrt_pa_x64: u128,
    sqrt_pb_x64: u128,
    l: u128,
    x0: u64,
    y0: u64,
    cx: u64,
    cy: u64,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>: u64,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>: u64,
    creation_fee_amt_sui: u64,
) {
    <b>let</b> info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCreationInfo">PositionCreationInfo</a> {
        position_id,
        config_id,
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        x0,
        y0,
        cx,
        cy,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>,
        creation_fee_amt_sui,
    };
    event::emit(info);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_deleverage_info_constructor"></a>

## Function `deleverage_info_constructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_info_constructor">deleverage_info_constructor</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, model: <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, oracle_price_x128: u256, sqrt_pool_price_x64: u128, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128, delta_x: u64, delta_y: u64, x_repaid: u64, y_repaid: u64): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_info_constructor">deleverage_info_constructor</a>(
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    sqrt_pool_price_x64: u128,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128,
    delta_x: u64,
    delta_y: u64,
    x_repaid: u64,
    y_repaid: u64,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a> {
        position_id,
        model,
        oracle_price_x128,
        sqrt_pool_price_x64,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        delta_x,
        delta_y,
        x_repaid,
        y_repaid,
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_delta_l"></a>

## Function `set_delta_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_l">set_delta_l</a>(info: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_l">set_delta_l</a>(info: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128) {
    info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_delta_x"></a>

## Function `set_delta_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_x">set_delta_x</a>(info: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>, delta_x: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_x">set_delta_x</a>(info: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>, delta_x: u64) {
    info.delta_x = delta_x;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_set_delta_y"></a>

## Function `set_delta_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_y">set_delta_y</a>(info: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>, delta_y: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_y">set_delta_y</a>(info: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>, delta_y: u64) {
    info.delta_y = delta_y;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_position_id"></a>

## Function `di_position_id`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_position_id">di_position_id</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_position_id">di_position_id</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): ID {
    self.position_id
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_model"></a>

## Function `di_model`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_model">di_model</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_model">di_model</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): PositionModel {
    self.model
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_oracle_price_x128"></a>

## Function `di_oracle_price_x128`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_oracle_price_x128">di_oracle_price_x128</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_oracle_price_x128">di_oracle_price_x128</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): u256 {
    self.oracle_price_x128
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_sqrt_pool_price_x64"></a>

## Function `di_sqrt_pool_price_x64`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_sqrt_pool_price_x64">di_sqrt_pool_price_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_sqrt_pool_price_x64">di_sqrt_pool_price_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): u128 {
    self.sqrt_pool_price_x64
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_delta_l"></a>

## Function `di_delta_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_delta_l">di_delta_l</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_delta_l">di_delta_l</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_delta_x"></a>

## Function `di_delta_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_delta_x">di_delta_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_delta_x">di_delta_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): u64 {
    self.delta_x
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_delta_y"></a>

## Function `di_delta_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_delta_y">di_delta_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_delta_y">di_delta_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): u64 {
    self.delta_y
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_x_repaid"></a>

## Function `di_x_repaid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_x_repaid">di_x_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_x_repaid">di_x_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): u64 {
    self.x_repaid
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_di_y_repaid"></a>

## Function `di_y_repaid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_y_repaid">di_y_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">kai_leverage::position_core_clmm::DeleverageInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_di_y_repaid">di_y_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a>): u64 {
    self.y_repaid
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_emit_liquidation_info"></a>

## Function `emit_liquidation_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_liquidation_info">emit_liquidation_info</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, model: <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, oracle_price_x128: u256, x_repaid: u64, y_repaid: u64, liquidator_reward_x: u64, liquidator_reward_y: u64, liquidation_fee_x: u64, liquidation_fee_y: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_liquidation_info">emit_liquidation_info</a>(
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    x_repaid: u64,
    y_repaid: u64,
    liquidator_reward_x: u64,
    liquidator_reward_y: u64,
    liquidation_fee_x: u64,
    liquidation_fee_y: u64,
) {
    <b>let</b> info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_LiquidationInfo">LiquidationInfo</a> {
        position_id,
        model,
        oracle_price_x128,
        x_repaid,
        y_repaid,
        liquidator_reward_x,
        liquidator_reward_y,
        liquidation_fee_x,
        liquidation_fee_y,
    };
    event::emit(info);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_reduction_info_constructor"></a>

## Function `reduction_info_constructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_info_constructor">reduction_info_constructor</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, model: <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, oracle_price_x128: u256, sqrt_pool_price_x64: u128, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128, delta_x: u64, delta_y: u64, withdrawn_x: u64, withdrawn_y: u64, x_repaid: u64, y_repaid: u64): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_info_constructor">reduction_info_constructor</a>(
    position_id: ID,
    model: PositionModel,
    oracle_price_x128: u256,
    sqrt_pool_price_x64: u128,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128,
    delta_x: u64,
    delta_y: u64,
    withdrawn_x: u64,
    withdrawn_y: u64,
    x_repaid: u64,
    y_repaid: u64,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a> {
        position_id,
        model,
        oracle_price_x128,
        sqrt_pool_price_x64,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        delta_x,
        delta_y,
        withdrawn_x,
        withdrawn_y,
        x_repaid,
        y_repaid,
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_position_id"></a>

## Function `ri_position_id`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_position_id">ri_position_id</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_position_id">ri_position_id</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): ID {
    self.position_id
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_model"></a>

## Function `ri_model`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_model">ri_model</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_model">ri_model</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): PositionModel {
    self.model
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_oracle_price_x128"></a>

## Function `ri_oracle_price_x128`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_oracle_price_x128">ri_oracle_price_x128</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_oracle_price_x128">ri_oracle_price_x128</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u256 {
    self.oracle_price_x128
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_sqrt_pool_price_x64"></a>

## Function `ri_sqrt_pool_price_x64`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_sqrt_pool_price_x64">ri_sqrt_pool_price_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_sqrt_pool_price_x64">ri_sqrt_pool_price_x64</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u128 {
    self.sqrt_pool_price_x64
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_delta_l"></a>

## Function `ri_delta_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_delta_l">ri_delta_l</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_delta_l">ri_delta_l</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_delta_x"></a>

## Function `ri_delta_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_delta_x">ri_delta_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_delta_x">ri_delta_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u64 {
    self.delta_x
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_delta_y"></a>

## Function `ri_delta_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_delta_y">ri_delta_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_delta_y">ri_delta_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u64 {
    self.delta_y
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_withdrawn_x"></a>

## Function `ri_withdrawn_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_withdrawn_x">ri_withdrawn_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_withdrawn_x">ri_withdrawn_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u64 {
    self.withdrawn_x
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_withdrawn_y"></a>

## Function `ri_withdrawn_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_withdrawn_y">ri_withdrawn_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_withdrawn_y">ri_withdrawn_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u64 {
    self.withdrawn_y
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_x_repaid"></a>

## Function `ri_x_repaid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_x_repaid">ri_x_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_x_repaid">ri_x_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u64 {
    self.x_repaid
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ri_y_repaid"></a>

## Function `ri_y_repaid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_y_repaid">ri_y_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">kai_leverage::position_core_clmm::ReductionInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ri_y_repaid">ri_y_repaid</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionInfo">ReductionInfo</a>): u64 {
    self.y_repaid
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_liquidity_info_constructor"></a>

## Function `add_liquidity_info_constructor`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_info_constructor">add_liquidity_info_constructor</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, sqrt_pool_price_x64: u128, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128, delta_x: u64, delta_y: u64): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">kai_leverage::position_core_clmm::AddLiquidityInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_info_constructor">add_liquidity_info_constructor</a>(
    position_id: ID,
    sqrt_pool_price_x64: u128,
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128,
    delta_x: u64,
    delta_y: u64,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a> {
        position_id,
        sqrt_pool_price_x64,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        delta_x,
        delta_y,
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ali_emit"></a>

## Function `ali_emit`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ali_emit">ali_emit</a>(info: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">kai_leverage::position_core_clmm::AddLiquidityInfo</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ali_emit">ali_emit</a>(info: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a>) {
    event::emit(info);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ali_delta_l"></a>

## Function `ali_delta_l`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ali_delta_l">ali_delta_l</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">kai_leverage::position_core_clmm::AddLiquidityInfo</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ali_delta_l">ali_delta_l</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a>): u128 {
    self.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ali_delta_x"></a>

## Function `ali_delta_x`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ali_delta_x">ali_delta_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">kai_leverage::position_core_clmm::AddLiquidityInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ali_delta_x">ali_delta_x</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a>): u64 {
    self.delta_x
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_ali_delta_y"></a>

## Function `ali_delta_y`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ali_delta_y">ali_delta_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">kai_leverage::position_core_clmm::AddLiquidityInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ali_delta_y">ali_delta_y</a>(self: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a>): u64 {
    self.delta_y
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_emit_owner_collect_fee_info"></a>

## Function `emit_owner_collect_fee_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_owner_collect_fee_info">emit_owner_collect_fee_info</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, collected_x_amt: u64, collected_y_amt: u64, fee_amt_x: u64, fee_amt_y: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_owner_collect_fee_info">emit_owner_collect_fee_info</a>(
    position_id: ID,
    collected_x_amt: u64,
    collected_y_amt: u64,
    fee_amt_x: u64,
    fee_amt_y: u64,
) {
    <b>let</b> info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectFeeInfo">OwnerCollectFeeInfo</a> {
        position_id,
        collected_x_amt,
        collected_y_amt,
        fee_amt_x,
        fee_amt_y,
    };
    event::emit(info);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_emit_owner_collect_reward_info"></a>

## Function `emit_owner_collect_reward_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_owner_collect_reward_info">emit_owner_collect_reward_info</a>&lt;T&gt;(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, collected_reward_amt: u64, fee_amt: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_owner_collect_reward_info">emit_owner_collect_reward_info</a>&lt;T&gt;(
    position_id: ID,
    collected_reward_amt: u64,
    fee_amt: u64,
) {
    <b>let</b> info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerCollectRewardInfo">OwnerCollectRewardInfo</a>&lt;T&gt; { position_id, collected_reward_amt, fee_amt };
    event::emit(info);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_emit_delete_position_info"></a>

## Function `emit_delete_position_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_delete_position_info">emit_delete_position_info</a>(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, cap_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_delete_position_info">emit_delete_position_info</a>(position_id: ID, cap_id: ID) {
    <b>let</b> info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletePositionInfo">DeletePositionInfo</a> { position_id, cap_id };
    event::emit(info);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_emit_bad_debt_repaid"></a>

## Function `emit_bad_debt_repaid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_bad_debt_repaid">emit_bad_debt_repaid</a>&lt;T&gt;(position_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, shares_repaid: u128, balance_repaid: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_bad_debt_repaid">emit_bad_debt_repaid</a>&lt;T&gt;(
    position_id: ID,
    shares_repaid: u128,
    balance_repaid: u64,
) {
    event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_BadDebtRepaid">BadDebtRepaid</a>&lt;T&gt; { position_id, shares_repaid, balance_repaid });
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_check_config_version"></a>

## Function `check_config_version`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>) {
    <b>assert</b>!(config.version == <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CONFIG_VERSION">CONFIG_VERSION</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_EInvalidConfigVersion">EInvalidConfigVersion</a>);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_check_position_version"></a>

## Function `check_position_version`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;) {
    <b>assert</b>!(position.version == <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_POSITION_VERSION">POSITION_VERSION</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_EInvalidPositionVersion">EInvalidPositionVersion</a>);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_check_versions"></a>

## Function `check_versions`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>&lt;X, Y, LP&gt;(position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>&lt;X, Y, LP&gt;(
    position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
) {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>(position);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_migrate_config"></a>

## Function `migrate_config`

Migrate position configuration to current module version.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_migrate_config">migrate_config</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_migrate_config">migrate_config</a>(config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>, ctx: &<b>mut</b> TxContext): ActionRequest {
    <b>assert</b>!(config.version &lt; <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CONFIG_VERSION">CONFIG_VERSION</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ENotUpgrade">ENotUpgrade</a>);
    config.version = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CONFIG_VERSION">CONFIG_VERSION</a>;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AMigrate">AMigrate</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_migrate_position"></a>

## Function `migrate_position`

Migrate position to current module version.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_migrate_position">migrate_position</a>&lt;X, Y, LP&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_migrate_position">migrate_position</a>&lt;X, Y, LP&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>assert</b>!(position.version &lt; <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_POSITION_VERSION">POSITION_VERSION</a>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ENotUpgrade">ENotUpgrade</a>);
    position.version = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_POSITION_VERSION">POSITION_VERSION</a>;
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AMigrate">AMigrate</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_validate_price_info"></a>

## Function `validate_price_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>): <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    price_info: &PythPriceInfo,
): ValidatedPythPriceInfo {
    <b>let</b> pyth_config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a> =
        &config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allowed_oracles">allowed_oracles</a>[type_name::with_defining_ids&lt;<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PythConfig">PythConfig</a>&gt;()];
    price_info.validate(pyth_config.max_age_secs, &pyth_config.pio_allowlist)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_validate_debt_info"></a>

## Function `validate_debt_info`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>): <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">kai_leverage::debt_info::ValidatedDebtInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    debt_info: &DebtInfo,
): ValidatedDebtInfo {
    debt_info.validate(object::id(&config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>))
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_calc_borrow_amt"></a>

## Function `calc_borrow_amt`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_borrow_amt">calc_borrow_amt</a>(principal: u64, need_for_position: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_borrow_amt">calc_borrow_amt</a>(principal: u64, need_for_position: u64): (u64, u64) {
    <b>if</b> (principal &gt; need_for_position) {
        (0, principal - need_for_position)
    } <b>else</b> {
        (need_for_position - principal, 0)
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_price_deviation_is_acceptable"></a>

## Function `price_deviation_is_acceptable`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_price_deviation_is_acceptable">price_deviation_is_acceptable</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, p0_oracle_ema_x128: u256, p0_x128: u256): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_price_deviation_is_acceptable">price_deviation_is_acceptable</a>(
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    p0_oracle_ema_x128: u256,
    p0_x128: u256,
): bool {
    <b>let</b> delta_bps = (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps">min_liq_start_price_delta_bps</a> <b>as</b> u256);
    <b>let</b> pl_x128 = p0_oracle_ema_x128 - (p0_oracle_ema_x128 * delta_bps) / 10000;
    <b>let</b> ph_x128 = p0_oracle_ema_x128 + (p0_oracle_ema_x128 * delta_bps) / 10000;
    <b>if</b> (p0_x128 &lt; pl_x128 || p0_x128 &gt; ph_x128) {
        <b>false</b>
    } <b>else</b> {
        <b>true</b>
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_liq_margin_is_valid"></a>

## Function `liq_margin_is_valid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_is_valid">liq_margin_is_valid</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, model: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p0_min_x128: u256, p0_max_x128: u256): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_is_valid">liq_margin_is_valid</a>(
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    model: &PositionModel,
    p0_min_x128: u256,
    p0_max_x128: u256,
): bool {
    <b>let</b> delta_bps = (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_liq_start_price_delta_bps">min_liq_start_price_delta_bps</a> <b>as</b> u256);
    <b>let</b> liq_margin_x64 = (
            (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a> <b>as</b> u128) &lt;&lt; 64
        ) / 10000;
    <b>let</b> pl_x128 = p0_min_x128 - (p0_min_x128 * delta_bps) / 10000;
    <b>let</b> ph_x128 = p0_max_x128 + (p0_max_x128 * delta_bps) / 10000;
    <b>if</b> (model.margin_x64(pl_x128) &lt; liq_margin_x64) {
        <b>return</b> <b>false</b>
    };
    <b>if</b> (model.margin_x64(ph_x128) &lt; liq_margin_x64) {
        <b>return</b> <b>false</b>
    };
    <b>true</b>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_init_margin_is_valid"></a>

## Function `init_margin_is_valid`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_init_margin_is_valid">init_margin_is_valid</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, model: &<a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>, p0_min_x128: u256, p0_max_x128: u256): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_init_margin_is_valid">init_margin_is_valid</a>(
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    model: &PositionModel,
    p0_min_x128: u256,
    p0_max_x128: u256,
): bool {
    <b>let</b> min_margin_x64 = (
            (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_min_init_margin_bps">min_init_margin_bps</a> <b>as</b> u128) &lt;&lt; 64
        ) / 10000;
    <b>if</b> (model.margin_x64(p0_min_x128) &lt; min_margin_x64) {
        <b>return</b> <b>false</b>
    };
    <b>if</b> (model.margin_x64(p0_max_x128) &lt; min_margin_x64) {
        <b>return</b> <b>false</b>
    };
    <b>true</b>
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_model_from_position"></a>

## Macro function `model_from_position`

Extract position model from current position state.

This internal macro creates a PositionModel snapshot from the current
position state, including LP position parameters, collateral balances,
and calculated debt amounts from the debt bag.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>&lt;$X, $Y, $LP&gt;($position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">kai_leverage::debt_info::ValidatedDebtInfo</a>): <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>&lt;$X, $Y, $LP&gt;(
    $position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $debt_info: &ValidatedDebtInfo,
): PositionModel {
    <b>let</b> position = $position;
    <b>let</b> debt_info = $debt_info;
    <b>let</b> (tick_a, tick_b) = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>().tick_range();
    <b>let</b> l = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>().liquidity();
    <b>let</b> sqrt_pa_x64 = tick_a.as_sqrt_price_x64();
    <b>let</b> sqrt_pb_x64 = tick_b.as_sqrt_price_x64();
    <b>let</b> cx = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>().value();
    <b>let</b> cy = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>().value();
    <b>let</b> sx = position.debt_bag().get_share_amount_by_asset_type&lt;$X&gt;();
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a> = <b>if</b> (sx &gt; 0) {
        <b>let</b> share_type = position.debt_bag().get_share_type_for_asset&lt;$X&gt;();
        debt_info.calc_repay_by_shares(share_type, sx)
    } <b>else</b> {
        0
    };
    <b>let</b> sy = position.debt_bag().get_share_amount_by_asset_type&lt;$Y&gt;();
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a> = <b>if</b> (sy &gt; 0) {
        <b>let</b> share_type = position.debt_bag().get_share_type_for_asset&lt;$Y&gt;();
        debt_info.calc_repay_by_shares(share_type, sy)
    } <b>else</b> {
        0
    };
    position_model_clmm::create(
        sqrt_pa_x64,
        sqrt_pb_x64,
        l,
        cx,
        cy,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>,
    )
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_slippage_tolerance_assertion"></a>

## Macro function `slippage_tolerance_assertion`

Validate pool price is within acceptable slippage tolerance.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_slippage_tolerance_assertion">slippage_tolerance_assertion</a>($pool_object: _, $p0_desired_x128: u256, $max_slippage_bps: u16)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_slippage_tolerance_assertion">slippage_tolerance_assertion</a>(
    $pool_object: _,
    $p0_desired_x128: u256,
    $max_slippage_bps: u16,
) {
    <b>let</b> pool = $pool_object;
    <b>let</b> sqrt_p0_x64 = pool.current_sqrt_price_x64();
    <b>let</b> p0_x64 = ((sqrt_p0_x64 <b>as</b> u256) * (sqrt_p0_x64 <b>as</b> u256)) &gt;&gt; 64;
    <b>let</b> p0_desired_x64 = $p0_desired_x128 &gt;&gt; 64;
    <b>let</b> p0_x64_max = p0_desired_x64 + ((p0_desired_x64 * ($max_slippage_bps <b>as</b> u256)) / 10000);
    <b>let</b> p0_x64_min = p0_desired_x64 - ((p0_desired_x64 * ($max_slippage_bps <b>as</b> u256)) / 10000);
    <b>if</b> (p0_x64 &lt; p0_x64_min || p0_x64 &gt; p0_x64_max) {
        <b>false</b>
    } <b>else</b> {
        <b>true</b>
    };
    <b>assert</b>!(p0_x64 &gt;= p0_x64_min && p0_x64 &lt;= p0_x64_max, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_slippage_exceeded">e_slippage_exceeded</a>!());
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_get_amount_ema_usd_value_6_decimals"></a>

## Function `get_amount_ema_usd_value_6_decimals`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_amount_ema_usd_value_6_decimals">get_amount_ema_usd_value_6_decimals</a>&lt;T&gt;(amount: u64, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, round_up: bool): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_amount_ema_usd_value_6_decimals">get_amount_ema_usd_value_6_decimals</a>&lt;T&gt;(
    amount: u64,
    price_info: &ValidatedPythPriceInfo,
    round_up: bool,
): u64 {
    <b>let</b> t = type_name::with_defining_ids&lt;T&gt;();
    <b>let</b> price = price_info.get_ema_price(t);
    <b>let</b> p = pyth_i64::get_magnitude_if_positive(&price.get_price()) <b>as</b> u128;
    <b>let</b> expo = pyth_i64::get_magnitude_if_negative(&price.get_expo()) <b>as</b> u8;
    <b>let</b> dec = pyth::decimals(t);
    <b>let</b> num = p * (amount <b>as</b> u128);
    (<b>if</b> (expo + dec &gt; 6) {
            <b>if</b> (round_up) {
                <a href="../../dependencies/std/macros.md#std_macros_num_divide_and_round_up">std::macros::num_divide_and_round_up</a>!(num, 10_u128.pow(expo + dec - 6))
            } <b>else</b> {
                num / 10_u128.pow(expo + dec - 6)
            }
        } <b>else</b> {
            num * 10_u128.pow(6 - (expo + dec))
        }) <b>as</b> u64
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_get_balance_ema_usd_value_6_decimals"></a>

## Function `get_balance_ema_usd_value_6_decimals`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_balance_ema_usd_value_6_decimals">get_balance_ema_usd_value_6_decimals</a>&lt;T&gt;(balance: &<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, round_up: bool): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_balance_ema_usd_value_6_decimals">get_balance_ema_usd_value_6_decimals</a>&lt;T&gt;(
    balance: &Balance&lt;T&gt;,
    price_info: &ValidatedPythPriceInfo,
    round_up: bool,
): u64 {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_amount_ema_usd_value_6_decimals">get_amount_ema_usd_value_6_decimals</a>&lt;T&gt;(balance.value(), price_info, round_up)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_create_position_ticket"></a>

## Macro function `create_position_ticket`

Create a position creation ticket with validation and borrowing preparation.

This macro performs comprehensive validation including price deviation checks,
margin requirements, and position size limits before creating a ticket that
can be used to open a leveraged position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_position_ticket">create_position_ticket</a>&lt;$X, $Y, $I32&gt;($pool_object: _, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $tick_a: $I32, $tick_b: $I32, $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;, $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, $ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;$X, $Y, $I32&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_position_ticket">create_position_ticket</a>&lt;$X, $Y, $I32&gt;(
    $pool_object: _,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    // The lower tick of the LP position range
    $tick_a: $I32,
    // The upper tick of the LP position range
    $tick_b: $I32,
    $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>: Balance&lt;$X&gt;,
    $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>: Balance&lt;$Y&gt;,
    $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: u128,
    $price_info: &PythPriceInfo,
    $clock: &Clock,
    $ctx: &<b>mut</b> TxContext,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;$X, $Y, $I32&gt; {
    <b>let</b> pool_object = $pool_object;
    <b>let</b> config = $config;
    <b>let</b> tick_a = $tick_a;
    <b>let</b> tick_b = $tick_b;
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a> = $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>;
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a> = $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_config_version">check_config_version</a>(config);
    <b>assert</b>!(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_allow_new_positions">allow_new_positions</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_new_positions_not_allowed">e_new_positions_not_allowed</a>!());
    <b>assert</b>!(object::id(pool_object) == config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_pool">e_invalid_pool</a>!());
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>if</b> (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_has_create_withdraw_limiter">has_create_withdraw_limiter</a>()) {
        <b>let</b> limiter = config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter_mut">borrow_create_withdraw_limiter_mut</a>();
        <b>let</b> x_value = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_balance_ema_usd_value_6_decimals">get_balance_ema_usd_value_6_decimals</a>(&<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>, &price_info, <b>true</b>);
        <b>let</b> y_value = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_balance_ema_usd_value_6_decimals">get_balance_ema_usd_value_6_decimals</a>(&<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>, &price_info, <b>true</b>);
        limiter.consume_inflow(x_value + y_value, $clock);
    };
    <b>assert</b>!($<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> &lt;= config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_position_l">max_position_l</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_size_limit_exceeded">e_position_size_limit_exceeded</a>!());
    <b>assert</b>!(
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a>() + $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> &lt;= config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_global_l">max_global_l</a>(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_vault_global_size_limit_exceeded">e_vault_global_size_limit_exceeded</a>!(),
    );
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_current_global_l">increase_current_global_l</a>($<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>);
    <b>let</b> current_tick = pool_object.current_tick_index();
    <b>let</b> sqrt_p0_x64 = pool_object.current_sqrt_price_x64();
    // <b>assert</b> that the current price is within the range of the LP position
    <b>assert</b>!(tick_a.lte(current_tick), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_tick_range">e_invalid_tick_range</a>!());
    <b>assert</b>!(current_tick.lt(tick_b), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_tick_range">e_invalid_tick_range</a>!());
    <b>let</b> p0_oracle_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    <b>let</b> p0_x128 = (sqrt_p0_x64 <b>as</b> u256) * (sqrt_p0_x64 <b>as</b> u256);
    // validate price deviation
    {
        <b>let</b> p0_oracle_ema_x128 = price_info.div_ema_price_numeric_x128(
            type_name::with_defining_ids&lt;$X&gt;(),
            type_name::with_defining_ids&lt;$Y&gt;(),
        );
        <b>assert</b>!(
            <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_price_deviation_is_acceptable">price_deviation_is_acceptable</a>(config, p0_oracle_ema_x128, p0_x128),
            <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_price_deviation_too_high">e_price_deviation_too_high</a>!(),
        )
    };
    <b>let</b> p0_min_x128 = util::min_u256(p0_oracle_x128, p0_x128);
    <b>let</b> p0_max_x128 = util::max_u256(p0_oracle_x128, p0_x128);
    // validate position
    <b>let</b> model = {
        <b>let</b> (x0, y0) = pool_object.calc_deposit_amounts_by_liquidity(tick_a, tick_b, $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>);
        <b>let</b> (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>, cx) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_borrow_amt">calc_borrow_amt</a>(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>.value(), x0);
        <b>let</b> (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>, cy) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_borrow_amt">calc_borrow_amt</a>(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>.value(), y0);
        <b>let</b> sqrt_pa_x64 = tick_a.as_sqrt_price_x64();
        <b>let</b> sqrt_pb_x64 = tick_b.as_sqrt_price_x64();
        position_model_clmm::create(
            sqrt_pa_x64,
            sqrt_pb_x64,
            $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
            cx,
            cy,
            <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>,
            <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>,
        )
    };
    <b>assert</b>!(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_is_valid">liq_margin_is_valid</a>(config, &model, p0_min_x128, p0_max_x128), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liq_margin_too_low">e_liq_margin_too_low</a>!());
    <b>assert</b>!(
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_init_margin_is_valid">init_margin_is_valid</a>(config, &model, p0_min_x128, p0_max_x128),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_initial_margin_too_low">e_initial_margin_too_low</a>!(),
    );
    // create ticket
    <b>let</b> config_id = object::id(config);
    <b>let</b> debt_bag = supply_pool::empty_facil_debt_bag(
        object::id(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>()),
        $ctx,
    );
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_new_create_position_ticket">new_create_position_ticket</a>(
        config_id,
        tick_a,
        tick_b,
        model.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>(),
        model.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>(),
        $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>,
        balance::zero(),
        balance::zero(),
        debt_bag,
    )
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrow_for_position_x"></a>

## Macro function `borrow_for_position_x`

Borrow X tokens from supply pool for position creation.

This macro borrows the required amount of X tokens from the specified
supply pool and adds the debt shares to the position ticket.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_for_position_x">borrow_for_position_x</a>&lt;$X, $Y, $SX, $I32&gt;($ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;$X, $Y, $I32&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$X, $SX&gt;, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_for_position_x">borrow_for_position_x</a>&lt;$X, $Y, $SX, $I32&gt;(
    $ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;$X, $Y, $I32&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $supply_pool: &<b>mut</b> SupplyPool&lt;$X, $SX&gt;,
    $clock: &Clock,
) {
    <b>let</b> ticket = $ticket;
    <b>let</b> config = $config;
    <b>let</b> supply_pool = $supply_pool;
    <b>assert</b>!(ticket.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>if</b> (ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>() == ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>().value()) {
        <b>return</b>
    };
    <b>let</b> (balance, shares) = supply_pool.borrow(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>(), ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>(), $clock);
    ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x_mut">borrowed_x_mut</a>().join(balance);
    ticket.debt_bag_mut().add&lt;$X, $SX&gt;(shares);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_borrow_for_position_y"></a>

## Macro function `borrow_for_position_y`

Borrow Y tokens from supply pool for position creation.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_for_position_y">borrow_for_position_y</a>&lt;$X, $Y, $SY, $I32&gt;($ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;$X, $Y, $I32&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$Y, $SY&gt;, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_for_position_y">borrow_for_position_y</a>&lt;$X, $Y, $SY, $I32&gt;(
    $ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;$X, $Y, $I32&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $supply_pool: &<b>mut</b> SupplyPool&lt;$Y, $SY&gt;,
    $clock: &Clock,
) {
    <b>let</b> ticket = $ticket;
    <b>let</b> config = $config;
    <b>let</b> supply_pool = $supply_pool;
    <b>assert</b>!(ticket.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>if</b> (ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>() == ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>().value()) {
        <b>return</b>
    };
    <b>let</b> (balance, shares) = supply_pool.borrow(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>(), ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>(), $clock);
    ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y_mut">borrowed_y_mut</a>().join(balance);
    ticket.debt_bag_mut().add&lt;$Y, $SY&gt;(shares);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_create_position"></a>

## Macro function `create_position`

Create a leveraged position from a prepared ticket.

This macro finalizes position creation by opening the LP position on the
target pool, creating the Position object with all collateral and debt,
and returning a PositionCap for ownership control.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_position">create_position</a>&lt;$X, $Y, $I32, $Pool, $LP&gt;($config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">kai_leverage::position_core_clmm::CreatePositionTicket</a>&lt;$X, $Y, $I32&gt;, $pool_object: &<b>mut</b> $Pool, $creation_fee: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;, $ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>, $open_position: |&<b>mut</b> $Pool, $I32, $I32, u128, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;| -&gt; $LP): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_position">create_position</a>&lt;$X, $Y, $I32, $Pool, $LP&gt;(
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CreatePositionTicket">CreatePositionTicket</a>&lt;$X, $Y, $I32&gt;,
    $pool_object: &<b>mut</b> $Pool,
    $creation_fee: Balance&lt;SUI&gt;,
    $ctx: &<b>mut</b> TxContext,
    $open_position: |&<b>mut</b> $Pool, $I32, $I32, u128, Balance&lt;$X&gt;, Balance&lt;$Y&gt;| -&gt; $LP,
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a> {
    <b>let</b> config = $config;
    <b>let</b> ticket = $ticket;
    <b>let</b> pool_object = $pool_object;
    <b>let</b> creation_fee = $creation_fee;
    <b>assert</b>!(ticket.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(object::id(pool_object) == config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_pool">e_invalid_pool</a>!());
    <b>assert</b>!(
        creation_fee.value() == config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_creation_fee_sui">position_creation_fee_sui</a>(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_creation_fee_amount">e_invalid_creation_fee_amount</a>!(),
    );
    <b>assert</b>!(ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>().value() == ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_borrow">e_invalid_borrow</a>!());
    <b>assert</b>!(ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>().value() == ticket.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_borrow">e_invalid_borrow</a>!());
    <b>let</b> (
        config_id,
        tick_a,
        tick_b,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        <b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>,
        <b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>,
        debt_bag,
    ) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_create_position_ticket">destroy_create_position_ticket</a>(ticket);
    // prepare balances <b>for</b> LP position creation
    <b>let</b> (x0, y0) = pool_object.calc_deposit_amounts_by_liquidity(tick_a, tick_b, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>);
    <b>let</b> <b>mut</b> balance_x0 = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_x">borrowed_x</a>;
    <b>if</b> (balance_x0.value() &lt; x0) {
        <b>let</b> amt = x0 - balance_x0.value();
        balance_x0.join(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>.split(amt));
    };
    <b>let</b> <b>mut</b> balance_y0 = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrowed_y">borrowed_y</a>;
    <b>if</b> (balance::value(&balance_y0) &lt; y0) {
        <b>let</b> amt = y0 - balance_y0.value();
        balance_y0.join(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>.split(amt));
    };
    // create LP position
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a> = $open_position(
        pool_object,
        tick_a,
        tick_b,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        balance_x0,
        balance_y0,
    );
    // create position
    <b>let</b> <b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a> = balance_bag::empty($ctx);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>.add(creation_fee);
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a> = balance_bag::empty($ctx);
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a> = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_x">principal_x</a>;
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a> = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_principal_y">principal_y</a>;
    <b>let</b> position = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_constructor">position_constructor</a>(
        object::id(config),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>,
        debt_bag,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>,
        $ctx,
    );
    <b>let</b> cap = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_cap_constructor">position_cap_constructor</a>(object::id(&position), $ctx);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_position_creation_info">emit_position_creation_info</a>(
        object::id(&position),
        config_id,
        tick_a.as_sqrt_price_x64(),
        tick_b.as_sqrt_price_x64(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        x0,
        y0,
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>().value(),
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>().value(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>,
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_creation_fee_sui">position_creation_fee_sui</a>(),
    );
    position.share_object();
    cap
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_create_deleverage_ticket_inner"></a>

## Macro function `create_deleverage_ticket_inner`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket_inner">create_deleverage_ticket_inner</a>&lt;$X, $Y, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $max_delta_l: u128, $is_for_liquidation: bool, $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket_inner">create_deleverage_ticket_inner</a>&lt;$X, $Y, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $max_delta_l: u128,
    $is_for_liquidation: bool,
    $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (Balance&lt;$X&gt;, Balance&lt;$Y&gt;),
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a> {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> pool_object = $pool_object;
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>() == object::id(pool_object), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_pool">e_invalid_pool</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_ticket_active">set_ticket_active</a>(<b>true</b>);
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>let</b> debt_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, $debt_info);
    <b>let</b> model = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &debt_info);
    <b>let</b> p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    <b>let</b> <b>mut</b> info = {
        <b>let</b> position_id = object::id(position);
        <b>let</b> oracle_price_x128 = p_x128;
        <b>let</b> sqrt_pool_price_x64 = pool_object.current_sqrt_price_x64();
        <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> = 0;
        <b>let</b> delta_x = 0;
        <b>let</b> delta_y = 0;
        <b>let</b> x_repaid = 0;
        <b>let</b> y_repaid = 0;
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_info_constructor">deleverage_info_constructor</a>(
            position_id,
            model,
            oracle_price_x128,
            sqrt_pool_price_x64,
            <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
            delta_x,
            delta_y,
            x_repaid,
            y_repaid,
        )
    };
    <b>let</b> threshold_margin = <b>if</b> ($is_for_liquidation) {
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>()
    } <b>else</b> {
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>()
    };
    <b>if</b> (!model.margin_below_threshold(p_x128, threshold_margin)) {
        // <b>return</b> instead of <b>abort</b> helps to avoid tx failures
        <b>let</b> can_repay_x = <b>false</b>;
        <b>let</b> can_repay_y = <b>false</b>;
        <b>let</b> ticket = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_constructor">deleverage_ticket_constructor</a>(
            object::id(position),
            can_repay_x,
            can_repay_y,
            info,
        );
        <b>return</b> ticket
    };
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> = util::min_u128(
        $max_delta_l,
        model.calc_max_deleverage_delta_l(
            p_x128,
            config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>(),
            config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_deleverage_factor_bps">base_deleverage_factor_bps</a>(),
        ),
    );
    <b>let</b> (got_x, got_y) = $remove_liquidity(pool_object, position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>);
    info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_l">set_delta_l</a>(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>);
    info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_x">set_delta_x</a>(got_x.value());
    info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_set_delta_y">set_delta_y</a>(got_y.value());
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x_mut">col_x_mut</a>().join(got_x);
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y_mut">col_y_mut</a>().join(got_y);
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_decrease_current_global_l">decrease_current_global_l</a>(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>);
    {
        <b>let</b> can_repay_x = {
            <b>let</b> share_amt = position.debt_bag().get_share_amount_by_asset_type&lt;$X&gt;();
            share_amt &gt; 0 && position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>().value() &gt; 0
        };
        <b>let</b> can_repay_y = {
            <b>let</b> share_amt = position.debt_bag().get_share_amount_by_asset_type&lt;$Y&gt;();
            share_amt &gt; 0 && position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>().value() &gt; 0
        };
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_constructor">deleverage_ticket_constructor</a>(object::id(position), can_repay_x, can_repay_y, info)
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_create_deleverage_ticket"></a>

## Macro function `create_deleverage_ticket`

Initialize deleveraging for a position that has fallen below the safe margin threshold.
It removes liquidity from the LP position and repays all possible debt to attempt
to restore healthy margin levels.

This operation is permissioned.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket">create_deleverage_ticket</a>&lt;$X, $Y, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $max_delta_l: u128, $ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>, $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)): (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket">create_deleverage_ticket</a>&lt;$X, $Y, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $max_delta_l: u128,
    $ctx: &<b>mut</b> TxContext,
    $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (Balance&lt;$X&gt;, Balance&lt;$Y&gt;),
): (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>, ActionRequest) {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>($position, $config);
    <b>let</b> ticket = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket_inner">create_deleverage_ticket_inner</a>!(
        $position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $max_delta_l,
        <b>false</b>,
        $remove_liquidity,
    );
    <b>let</b> request = access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_deleverage">a_deleverage</a>(), $ctx);
    (ticket, request)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_create_deleverage_ticket_for_liquidation"></a>

## Macro function `create_deleverage_ticket_for_liquidation`

Create deleveraging ticket specifically for liquidation scenarios.
Unlike the regular deleveraging, this operation is permissionless.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket_for_liquidation">create_deleverage_ticket_for_liquidation</a>&lt;$X, $Y, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket_for_liquidation">create_deleverage_ticket_for_liquidation</a>&lt;$X, $Y, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (Balance&lt;$X&gt;, Balance&lt;$Y&gt;),
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a> {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>($position, $config);
    <b>let</b> config = $config;
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidation_disabled">liquidation_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liquidation_disabled">e_liquidation_disabled</a>!());
    <b>let</b> u128_max = (((1u256 &lt;&lt; 128) - 1) <b>as</b> u128);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket_inner">create_deleverage_ticket_inner</a>!(
        $position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        u128_max,
        <b>true</b>,
        $remove_liquidity,
    )
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_deleverage_ticket_repay_x"></a>

## Function `deleverage_ticket_repay_x`

Repay X debt for deleveraging.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_repay_x">deleverage_ticket_repay_x</a>&lt;X, Y, SX, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_repay_x">deleverage_ticket_repay_x</a>&lt;X, Y, SX, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
) {
    <b>assert</b>!(ticket.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>assert</b>!(position.config_id == config.id.to_inner(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>if</b> (!ticket.can_repay_x) {
        <b>return</b>
    };
    <b>assert</b>!(
        position.debt_bag().get_share_type_for_asset&lt;X&gt;() == type_name::with_defining_ids&lt;SX&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> shares = position.debt_bag.take_all();
    <b>let</b> (_, x_repaid) = supply_pool.repay_max_possible(&<b>mut</b> shares, &<b>mut</b> position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>, clock);
    position.debt_bag.add&lt;X, SX&gt;(shares);
    ticket.can_repay_x = <b>false</b>;
    ticket.info.x_repaid = x_repaid;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_deleverage_ticket_repay_y"></a>

## Function `deleverage_ticket_repay_y`

Repay Y debt for deleveraging.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_repay_y">deleverage_ticket_repay_y</a>&lt;X, Y, SY, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_repay_y">deleverage_ticket_repay_y</a>&lt;X, Y, SY, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
) {
    <b>assert</b>!(ticket.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>assert</b>!(position.config_id == config.id.to_inner(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>if</b> (!ticket.can_repay_y) {
        <b>return</b>
    };
    <b>assert</b>!(
        position.debt_bag().get_share_type_for_asset&lt;Y&gt;() == type_name::with_defining_ids&lt;SY&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> shares = position.debt_bag.take_all();
    <b>let</b> (_, y_repaid) = supply_pool.repay_max_possible(&<b>mut</b> shares, &<b>mut</b> position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>, clock);
    ticket.info.y_repaid = y_repaid;
    position.debt_bag.add&lt;Y, SY&gt;(shares);
    ticket.can_repay_y = <b>false</b>;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_destroy_deleverage_ticket"></a>

## Function `destroy_deleverage_ticket`

Destroys a <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a></code> after all possible debt repayments have been performed,
emits a <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageInfo">DeleverageInfo</a></code> event if any deleveraging occurred. This function asserts that
the ticket is fully exhausted (i.e., both X and Y repayments are complete).

If no deleveraging was performed (i.e., no liquidity removed and no debt repaid),
no event is emitted.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_deleverage_ticket">destroy_deleverage_ticket</a>&lt;X, Y, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">kai_leverage::position_core_clmm::DeleverageTicket</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_deleverage_ticket">destroy_deleverage_ticket</a>&lt;X, Y, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a>,
) {
    <b>assert</b>!(ticket.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>assert</b>!(ticket.can_repay_x == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ETicketNotExhausted">ETicketNotExhausted</a>);
    <b>assert</b>!(ticket.can_repay_y == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ETicketNotExhausted">ETicketNotExhausted</a>);
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeleverageTicket">DeleverageTicket</a> { position_id: _, can_repay_x: _, can_repay_y: _, info } = ticket;
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a> = <b>false</b>;
    <b>if</b> (info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> == 0 && info.x_repaid == 0 && info.y_repaid == 0) {
        // nothing was deleveraged, don't emit event
        <b>return</b>
    } <b>else</b> {
        event::emit(info);
    };
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_deleverage"></a>

## Macro function `deleverage`

Helper macro that combines the creation of a deleverage ticket and the repayment of both X and Y debts
in a single operation for a leveraged CLMM position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage">deleverage</a>&lt;$X, $Y, $SX, $SY, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$X, $SX&gt;, $supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$Y, $SY&gt;, $pool_object: &<b>mut</b> $Pool, $max_delta_l: u128, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, $ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>, $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage">deleverage</a>&lt;$X, $Y, $SX, $SY, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $supply_pool_x: &<b>mut</b> SupplyPool&lt;$X, $SX&gt;,
    $supply_pool_y: &<b>mut</b> SupplyPool&lt;$Y, $SY&gt;,
    $pool_object: &<b>mut</b> $Pool,
    $max_delta_l: u128,
    $clock: &Clock,
    $ctx: &<b>mut</b> TxContext,
    $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (Balance&lt;$X&gt;, Balance&lt;$Y&gt;),
): ActionRequest {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> supply_pool_x = $supply_pool_x;
    <b>let</b> supply_pool_y = $supply_pool_y;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;$X, $SX&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;$Y, $SY&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> debt_info = debt_info::empty(object::id(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>()));
    debt_info.add_from_supply_pool(supply_pool_x, $clock);
    debt_info.add_from_supply_pool(supply_pool_y, $clock);
    <b>let</b> (<b>mut</b> ticket, request) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket">create_deleverage_ticket</a>!(
        position,
        config,
        $price_info,
        &debt_info,
        $pool_object,
        $max_delta_l,
        $ctx,
        $remove_liquidity,
    );
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_repay_x">deleverage_ticket_repay_x</a>(position, config, &<b>mut</b> ticket, supply_pool_x, $clock);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_repay_y">deleverage_ticket_repay_y</a>(position, config, &<b>mut</b> ticket, supply_pool_y, $clock);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_deleverage_ticket">destroy_deleverage_ticket</a>(position, ticket);
    request
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_deleverage_for_liquidation"></a>

## Macro function `deleverage_for_liquidation`



<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_for_liquidation">deleverage_for_liquidation</a>&lt;$X, $Y, $SX, $SY, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$X, $SX&gt;, $supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$Y, $SY&gt;, $pool_object: &<b>mut</b> $Pool, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;))
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_for_liquidation">deleverage_for_liquidation</a>&lt;$X, $Y, $SX, $SY, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $supply_pool_x: &<b>mut</b> SupplyPool&lt;$X, $SX&gt;,
    $supply_pool_y: &<b>mut</b> SupplyPool&lt;$Y, $SY&gt;,
    $pool_object: &<b>mut</b> $Pool,
    $clock: &Clock,
    $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (Balance&lt;$X&gt;, Balance&lt;$Y&gt;),
) {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> supply_pool_x = $supply_pool_x;
    <b>let</b> supply_pool_y = $supply_pool_y;
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidation_disabled">liquidation_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liquidation_disabled">e_liquidation_disabled</a>!());
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;$X, $SX&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;$Y, $SY&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> debt_info = debt_info::empty(object::id(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>()));
    debt_info.add_from_supply_pool(supply_pool_x, $clock);
    debt_info.add_from_supply_pool(supply_pool_y, $clock);
    <b>let</b> <b>mut</b> ticket = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_deleverage_ticket_for_liquidation">create_deleverage_ticket_for_liquidation</a>!(
        position,
        config,
        $price_info,
        &debt_info,
        $pool_object,
        $remove_liquidity,
    );
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_repay_x">deleverage_ticket_repay_x</a>(position, config, &<b>mut</b> ticket, supply_pool_x, $clock);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_ticket_repay_y">deleverage_ticket_repay_y</a>(position, config, &<b>mut</b> ticket, supply_pool_y, $clock);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_deleverage_ticket">destroy_deleverage_ticket</a>(position, ticket);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_calc_liq_fee_from_reward"></a>

## Function `calc_liq_fee_from_reward`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liq_fee_from_reward">calc_liq_fee_from_reward</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, reward_amt: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liq_fee_from_reward">calc_liq_fee_from_reward</a>(config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>, reward_amt: u64): u64 {
    <a href="../../kai_sav/util.md#kai_sav_util_muldiv">util::muldiv</a>(
        reward_amt,
        (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a> <b>as</b> u64) * (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_fee_bps">liq_fee_bps</a> <b>as</b> u64),
        (10000 + (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a> <b>as</b> u64)) * 10000,
    )
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_liquidate_col_x"></a>

## Macro function `liquidate_col_x`

Liquidate X collateral by repaying Y debt.

This macro performs partial liquidation of a position's X collateral
in exchange for repaying Y debt. Liquidators receive X tokens as reward
for helping restore position health by reducing debt obligations.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidate_col_x">liquidate_col_x</a>&lt;$X, $Y, $SY, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;, $supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$Y, $SY&gt;, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidate_col_x">liquidate_col_x</a>&lt;$X, $Y, $SY, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $repayment: &<b>mut</b> Balance&lt;$Y&gt;,
    $supply_pool: &<b>mut</b> SupplyPool&lt;$Y, $SY&gt;,
    $clock: &Clock,
): Balance&lt;$X&gt; {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> repayment = $repayment;
    <b>let</b> supply_pool = $supply_pool;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidation_disabled">liquidation_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liquidation_disabled">e_liquidation_disabled</a>!());
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>let</b> debt_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, $debt_info);
    <b>let</b> model = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &debt_info);
    <b>let</b> p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    <b>let</b> (repayment_amt_y, reward_amt_x) = model.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liquidate_col_x">calc_liquidate_col_x</a>(
        p_x128,
        repayment.value(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>(),
    );
    <b>if</b> (repayment_amt_y == 0) {
        <b>return</b> balance::zero()
    };
    <b>let</b> <b>mut</b> r = repayment.split(repayment_amt_y);
    <b>assert</b>!(
        type_name::with_defining_ids&lt;$SY&gt;() == position.debt_bag().get_share_type_for_asset&lt;$Y&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> debt_shares = position.debt_bag_mut().take_all();
    <b>let</b> (_, y_repaid) = supply_pool.repay_max_possible(&<b>mut</b> debt_shares, &<b>mut</b> r, $clock);
    position.debt_bag_mut().add&lt;$Y, $SY&gt;(debt_shares);
    repayment.join(r);
    <b>let</b> <b>mut</b> reward = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x_mut">col_x_mut</a>().split(reward_amt_x);
    <b>let</b> fee_amt = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liq_fee_from_reward">calc_liq_fee_from_reward</a>(config, reward_amt_x);
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees_mut">collected_fees_mut</a>().add(reward.split(fee_amt));
    {
        <b>let</b> position_id = object::id(position);
        <b>let</b> oracle_price_x128 = p_x128;
        <b>let</b> x_repaid = 0;
        <b>let</b> liquidator_reward_x = reward.value();
        <b>let</b> liquidator_reward_y = 0;
        <b>let</b> liquidation_fee_x = fee_amt;
        <b>let</b> liquidation_fee_y = 0;
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_liquidation_info">emit_liquidation_info</a>(
            position_id,
            model,
            oracle_price_x128,
            x_repaid,
            y_repaid,
            liquidator_reward_x,
            liquidator_reward_y,
            liquidation_fee_x,
            liquidation_fee_y,
        );
    };
    reward
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_liquidate_col_y"></a>

## Macro function `liquidate_col_y`

Liquidate Y collateral by repaying X debt.

This macro performs partial liquidation of a position's Y collateral
in exchange for repaying X debt. Liquidators receive Y tokens as reward
for helping restore position health by reducing debt obligations.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidate_col_y">liquidate_col_y</a>&lt;$X, $Y, $SX, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, $supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$X, $SX&gt;, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidate_col_y">liquidate_col_y</a>&lt;$X, $Y, $SX, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $repayment: &<b>mut</b> Balance&lt;$X&gt;,
    $supply_pool: &<b>mut</b> SupplyPool&lt;$X, $SX&gt;,
    $clock: &Clock,
): Balance&lt;$Y&gt; {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> repayment = $repayment;
    <b>let</b> supply_pool = $supply_pool;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liquidation_disabled">liquidation_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_liquidation_disabled">e_liquidation_disabled</a>!());
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>let</b> debt_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, $debt_info);
    <b>let</b> model = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &debt_info);
    <b>let</b> p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    <b>let</b> (repayment_amt_x, reward_amt_y) = model.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liquidate_col_y">calc_liquidate_col_y</a>(
        p_x128,
        repayment.value(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>(),
    );
    <b>if</b> (repayment_amt_x == 0) {
        <b>return</b> balance::zero()
    };
    <b>let</b> <b>mut</b> r = repayment.split(repayment_amt_x);
    <b>assert</b>!(
        type_name::with_defining_ids&lt;$SX&gt;() == position.debt_bag().get_share_type_for_asset&lt;$X&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> debt_shares = position.debt_bag_mut().take_all();
    <b>let</b> (_, x_repaid) = supply_pool.repay_max_possible(&<b>mut</b> debt_shares, &<b>mut</b> r, $clock);
    position.debt_bag_mut().add&lt;$X, $SX&gt;(debt_shares);
    repayment.join(r);
    <b>let</b> <b>mut</b> reward = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y_mut">col_y_mut</a>().split(reward_amt_y);
    <b>let</b> fee_amt = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liq_fee_from_reward">calc_liq_fee_from_reward</a>(config, reward_amt_y);
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees_mut">collected_fees_mut</a>().add(reward.split(fee_amt));
    {
        <b>let</b> position_id = object::id(position);
        <b>let</b> oracle_price_x128 = p_x128;
        <b>let</b> y_repaid = 0;
        <b>let</b> liquidator_reward_x = 0;
        <b>let</b> liquidator_reward_y = reward.value();
        <b>let</b> liquidation_fee_x = 0;
        <b>let</b> liquidation_fee_y = fee_amt;
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_liquidation_info">emit_liquidation_info</a>(
            position_id,
            model,
            oracle_price_x128,
            x_repaid,
            y_repaid,
            liquidator_reward_x,
            liquidator_reward_y,
            liquidation_fee_x,
            liquidation_fee_y,
        );
    };
    reward
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_repay_bad_debt"></a>

## Macro function `repay_bad_debt`

Handles repayment of "bad debt" for a position that has fallen below
the critical margin threshold <code>(1 + liq_bonus)</code>.

In such cases, standard liquidations cannot restore the margin due to
the guaranteed liquidation bonus. This macro allows an entity with the
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARepayBadDebt">ARepayBadDebt</a></code> permission to repay the debt and help restore the
position's solvency.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_repay_bad_debt">repay_bad_debt</a>&lt;$X, $Y, $T, $ST, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$T, $ST&gt;, $repayment: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$T&gt;, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, $ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_repay_bad_debt">repay_bad_debt</a>&lt;$X, $Y, $T, $ST, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $supply_pool: &<b>mut</b> SupplyPool&lt;$T, $ST&gt;,
    $repayment: &<b>mut</b> Balance&lt;$T&gt;,
    $clock: &Clock,
    $ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> supply_pool = $supply_pool;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;$T, $ST&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>let</b> debt_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, $debt_info);
    <b>let</b> model = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &debt_info);
    <b>assert</b>!(model.is_fully_deleveraged(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_not_fully_deleveraged">e_position_not_fully_deleveraged</a>!());
    <b>let</b> p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    <b>let</b> crit_margin_bps = 10000 + config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>();
    <b>assert</b>!(
        model.margin_below_threshold(p_x128, crit_margin_bps),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_not_below_bad_debt_threshold">e_position_not_below_bad_debt_threshold</a>!(),
    );
    <b>let</b> <b>mut</b> debt_shares = position.debt_bag_mut().take_all();
    <b>if</b> (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        <b>return</b> access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_repay_bad_debt">a_repay_bad_debt</a>(), $ctx)
    };
    <b>let</b> (shares_repaid, balance_repaid) = supply_pool.repay_max_possible(
        &<b>mut</b> debt_shares,
        $repayment,
        $clock,
    );
    position.debt_bag_mut().add&lt;$T, $ST&gt;(debt_shares);
    <b>if</b> (shares_repaid &gt; 0 || balance_repaid &gt; 0) {
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_bad_debt_repaid">emit_bad_debt_repaid</a>&lt;$ST&gt;(object::id(position), shares_repaid, balance_repaid);
    };
    access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_a_repay_bad_debt">a_repay_bad_debt</a>(), $ctx)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_reduce"></a>

## Macro function `reduce`

Reduce position size while preserving mathematical safety guarantees.

This macro implements position reduction based on the theoretical framework where
safe operations maintain or improve the margin function M(P) = A(P)/D(P).


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduce">reduce</a>&lt;$X, $Y, $SX, $SY, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $supply_pool_x: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$X, $SX&gt;, $supply_pool_y: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;$Y, $SY&gt;, $pool_object: &<b>mut</b> $Pool, $factor_x64: u128, $clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;$SX, $SY&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduce">reduce</a>&lt;$X, $Y, $SX, $SY, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    $price_info: &PythPriceInfo,
    $supply_pool_x: &<b>mut</b> SupplyPool&lt;$X, $SX&gt;,
    $supply_pool_y: &<b>mut</b> SupplyPool&lt;$Y, $SY&gt;,
    $pool_object: &<b>mut</b> $Pool,
    $factor_x64: u128,
    $clock: &Clock,
    $remove_liquidity: |&<b>mut</b> $Pool, &<b>mut</b> $LP, u128| -&gt; (Balance&lt;$X&gt;, Balance&lt;$Y&gt;),
): (Balance&lt;$X&gt;, Balance&lt;$Y&gt;, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;$SX, $SY&gt;) {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> cap = $cap;
    <b>let</b> pool_object = $pool_object;
    <b>let</b> supply_pool_x = $supply_pool_x;
    <b>let</b> supply_pool_y = $supply_pool_y;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>() == object::id(pool_object), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_pool">e_invalid_pool</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    <b>assert</b>!(cap.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_disabled">reduction_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_reduction_disabled">e_reduction_disabled</a>!());
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;$X, $SX&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;$Y, $SY&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>let</b> oracle_price_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    <b>let</b> sqrt_pool_price_x64 = pool_object.current_sqrt_price_x64();
    <b>let</b> pool_price_x128 = (sqrt_pool_price_x64 <b>as</b> u256) * (sqrt_pool_price_x64 <b>as</b> u256);
    <b>let</b> <b>mut</b> debt_info = debt_info::empty(object::id(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lend_facil_cap">lend_facil_cap</a>()));
    debt_info.add_from_supply_pool(supply_pool_x, $clock);
    debt_info.add_from_supply_pool(supply_pool_y, $clock);
    <b>let</b> model = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, &debt_info));
    <b>assert</b>!(
        !model.margin_below_threshold(oracle_price_x128, config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>()),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_below_threshold">e_position_below_threshold</a>!(),
    );
    <b>assert</b>!(
        !model.margin_below_threshold(pool_price_x128, config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>()),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_below_threshold">e_position_below_threshold</a>!(),
    );
    <b>let</b> l = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>().liquidity();
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> = util::muldiv_u128($factor_x64, l, 1 &lt;&lt; 64);
    <b>let</b> delta_cx = {
        <b>let</b> cx = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>().value() <b>as</b> u128;
        util::muldiv_u128($factor_x64, cx, 1 &lt;&lt; 64) <b>as</b> u64
    };
    <b>let</b> delta_cy = {
        <b>let</b> cy = position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>().value() <b>as</b> u128;
        util::muldiv_u128($factor_x64, cy, 1 &lt;&lt; 64) <b>as</b> u64
    };
    <b>let</b> delta_shares_x = {
        <b>let</b> share_amt = position.debt_bag().get_share_amount_by_asset_type&lt;$X&gt;();
        util::muldiv_u128($factor_x64, share_amt, 1 &lt;&lt; 64)
    };
    <b>let</b> delta_shares_y = {
        <b>let</b> share_amt = position.debt_bag().get_share_amount_by_asset_type&lt;$Y&gt;();
        util::muldiv_u128($factor_x64, share_amt, 1 &lt;&lt; 64)
    };
    <b>let</b> (<b>mut</b> got_x, <b>mut</b> got_y) = $remove_liquidity(
        pool_object,
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
    );
    <b>let</b> delta_x = got_x.value();
    <b>let</b> delta_y = got_y.value();
    got_x.join(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x_mut">col_x_mut</a>().split(delta_cx));
    got_y.join(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y_mut">col_y_mut</a>().split(delta_cy));
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_decrease_current_global_l">decrease_current_global_l</a>(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>);
    <b>let</b> sx = position.debt_bag_mut().take_amt(delta_shares_x);
    <b>let</b> sy = position.debt_bag_mut().take_amt(delta_shares_y);
    // calculate the inflow and outflow of the position
    <b>if</b> (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_has_create_withdraw_limiter">has_create_withdraw_limiter</a>()) {
        <b>let</b> limiter = config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_borrow_create_withdraw_limiter_mut">borrow_create_withdraw_limiter_mut</a>();
        <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a> = supply_pool_x.calc_repay_by_shares(sx.facil_id(), sx.value_x64(), $clock);
        <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a> = supply_pool_y.calc_repay_by_shares(sy.facil_id(), sy.value_x64(), $clock);
        <b>let</b> x_value = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_balance_ema_usd_value_6_decimals">get_balance_ema_usd_value_6_decimals</a>(&got_x, &price_info, <b>true</b>);
        <b>let</b> y_value = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_balance_ema_usd_value_6_decimals">get_balance_ema_usd_value_6_decimals</a>(&got_y, &price_info, <b>true</b>);
        <b>let</b> dx_value = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_amount_ema_usd_value_6_decimals">get_amount_ema_usd_value_6_decimals</a>&lt;$X&gt;(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dx">dx</a>, &price_info, <b>true</b>);
        <b>let</b> dy_value = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_get_amount_ema_usd_value_6_decimals">get_amount_ema_usd_value_6_decimals</a>&lt;$Y&gt;(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_dy">dy</a>, &price_info, <b>true</b>);
        // In some special cases (e.g. bad debt / negative equity) the inflow can be larger than the outflow,
        // so the reduction will be a net inflow. We don't consume this inflow in order to not count
        // towards the limiter net.
        <b>let</b> in = dx_value + dy_value;
        <b>let</b> out = x_value + y_value;
        <b>let</b> net_out = <b>if</b> (out &gt; in) { out - in } <b>else</b> { 0 };
        limiter.consume_outflow(net_out, $clock);
    };
    <b>let</b> info = {
        <b>let</b> withdrawn_x = got_x.value();
        <b>let</b> withdrawn_y = got_y.value();
        <b>let</b> x_repaid = 0;
        <b>let</b> y_repaid = 0;
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_info_constructor">reduction_info_constructor</a>(
            object::id(position),
            model,
            oracle_price_x128,
            sqrt_pool_price_x64,
            <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
            delta_x,
            delta_y,
            withdrawn_x,
            withdrawn_y,
            x_repaid,
            y_repaid,
        )
    };
    <b>let</b> ticket = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_repayment_ticket_constructor">reduction_repayment_ticket_constructor</a>(sx, sy, info);
    (got_x, got_y, ticket)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_reduction_ticket_calc_repay_amt_x"></a>

## Function `reduction_ticket_calc_repay_amt_x`

Calculate X token repayment amount for reduction ticket.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_ticket_calc_repay_amt_x">reduction_ticket_calc_repay_amt_x</a>&lt;X, SX, SY&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_ticket_calc_repay_amt_x">reduction_ticket_calc_repay_amt_x</a>&lt;X, SX, SY&gt;(
    ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
): u64 {
    <b>let</b> facil_id = ticket.sx.facil_id();
    <b>let</b> amount = ticket.sx.value_x64();
    supply_pool.calc_repay_by_shares(facil_id, amount, clock)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_reduction_ticket_calc_repay_amt_y"></a>

## Function `reduction_ticket_calc_repay_amt_y`

Calculate Y token repayment amount for reduction ticket.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_ticket_calc_repay_amt_y">reduction_ticket_calc_repay_amt_y</a>&lt;Y, SX, SY&gt;(ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_ticket_calc_repay_amt_y">reduction_ticket_calc_repay_amt_y</a>&lt;Y, SX, SY&gt;(
    ticket: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
): u64 {
    <b>let</b> facil_id = ticket.sy.facil_id();
    <b>let</b> amount = ticket.sy.value_x64();
    supply_pool.calc_repay_by_shares(facil_id, amount, clock)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_reduction_ticket_repay_x"></a>

## Function `reduction_ticket_repay_x`

Repay X debt for reduction ticket.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_ticket_repay_x">reduction_ticket_repay_x</a>&lt;X, SX, SY&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_ticket_repay_x">reduction_ticket_repay_x</a>&lt;X, SX, SY&gt;(
    ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    balance: Balance&lt;X&gt;,
    clock: &Clock,
) {
    <b>let</b> shares = ticket.sx.withdraw_all();
    ticket.info.x_repaid = balance.value();
    supply_pool.repay(shares, balance, clock);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_reduction_ticket_repay_y"></a>

## Function `reduction_ticket_repay_y`

Repay Y debt for reduction ticket.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_ticket_repay_y">reduction_ticket_repay_y</a>&lt;Y, SX, SY&gt;(ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_reduction_ticket_repay_y">reduction_ticket_repay_y</a>&lt;Y, SX, SY&gt;(
    ticket: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    balance: Balance&lt;Y&gt;,
    clock: &Clock,
) {
    <b>let</b> shares = ticket.sy.withdraw_all();
    ticket.info.y_repaid = balance.value();
    supply_pool.repay(shares, balance, clock);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_destroy_reduction_ticket"></a>

## Function `destroy_reduction_ticket`

Destroy exhausted reduction ticket and emit event.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_reduction_ticket">destroy_reduction_ticket</a>&lt;SX, SY&gt;(ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">kai_leverage::position_core_clmm::ReductionRepaymentTicket</a>&lt;SX, SY&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_destroy_reduction_ticket">destroy_reduction_ticket</a>&lt;SX, SY&gt;(ticket: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a>&lt;SX, SY&gt;) {
    <b>assert</b>!(ticket.sx.value_x64() == 0, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ETicketNotExhausted">ETicketNotExhausted</a>);
    <b>assert</b>!(ticket.sy.value_x64() == 0, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ETicketNotExhausted">ETicketNotExhausted</a>);
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ReductionRepaymentTicket">ReductionRepaymentTicket</a> { sx, sy, info } = ticket;
    sx.destroy_zero();
    sy.destroy_zero();
    <b>if</b> (
        info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a> == 0 && info.x_repaid == 0 && info.y_repaid == 0 &&
            info.withdrawn_x == 0 && info.withdrawn_y == 0
    ) {
        // position wasn't reduced, don't emit event
        <b>return</b>
    };
    event::emit(info);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_collateral_x"></a>

## Function `add_collateral_x`

Add X token collateral to position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_collateral_x">add_collateral_x</a>&lt;X, Y, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_collateral_x">add_collateral_x</a>&lt;X, Y, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    balance: Balance&lt;X&gt;,
) {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>(position);
    <b>assert</b>!(cap.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>let</b> amount_x = balance.value();
    <b>if</b> (amount_x == 0) {
        balance.destroy_zero();
        <b>return</b>
    };
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>.join(balance);
    event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddCollateralInfo">AddCollateralInfo</a> {
        position_id: object::id(position),
        amount_x,
        amount_y: 0,
    });
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_collateral_y"></a>

## Function `add_collateral_y`

Add Y token collateral to position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_collateral_y">add_collateral_y</a>&lt;X, Y, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_collateral_y">add_collateral_y</a>&lt;X, Y, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    balance: Balance&lt;Y&gt;,
) {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>(position);
    <b>assert</b>!(cap.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>let</b> amount_y = balance.value();
    <b>if</b> (amount_y == 0) {
        balance.destroy_zero();
        <b>return</b>
    };
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>.join(balance);
    event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddCollateralInfo">AddCollateralInfo</a> {
        position_id: object::id(position),
        amount_x: 0,
        amount_y,
    });
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_liquidity_with_receipt_inner"></a>

## Macro function `add_liquidity_with_receipt_inner`

Add liquidity to position with protocol-specific receipt handling.

Used by wrapper modules to add liquidity to existing positions while
maintaining risk limits and collecting protocol-specific receipts.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_with_receipt_inner">add_liquidity_with_receipt_inner</a>&lt;$X, $Y, $Pool, $LP, $Receipt&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64, $Receipt)): ($Receipt, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">kai_leverage::position_core_clmm::AddLiquidityInfo</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_with_receipt_inner">add_liquidity_with_receipt_inner</a>&lt;$X, $Y, $Pool, $LP, $Receipt&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64, $Receipt),
): ($Receipt, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a>) {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> pool_object = $pool_object;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>() == object::id(pool_object), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_pool">e_invalid_pool</a>!());
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_disabled">add_liquidity_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_add_liquidity_disabled">e_add_liquidity_disabled</a>!());
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>let</b> debt_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, $debt_info);
    <b>let</b> sqrt_pool_price_x64 = pool_object.current_sqrt_price_x64();
    <b>let</b> (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>, delta_x, delta_y, receipt) = $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>(
        pool_object,
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>(),
    );
    config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_current_global_l">increase_current_global_l</a>(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>);
    <b>assert</b>!(
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_current_global_l">current_global_l</a>() &lt;= config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_global_l">max_global_l</a>(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_vault_global_size_limit_exceeded">e_vault_global_size_limit_exceeded</a>!(),
    );
    <b>assert</b>!(
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>().liquidity() &lt;= config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_max_position_l">max_position_l</a>(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_size_limit_exceeded">e_position_size_limit_exceeded</a>!(),
    );
    <b>let</b> model = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &debt_info);
    <b>let</b> price_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    <b>assert</b>!(
        !model.margin_below_threshold(price_x128, config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_deleverage_margin_bps">deleverage_margin_bps</a>()),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_below_threshold">e_position_below_threshold</a>!(),
    );
    <b>let</b> info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_info_constructor">add_liquidity_info_constructor</a>(
        object::id(position),
        sqrt_pool_price_x64,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        delta_x,
        delta_y,
    );
    (receipt, info)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_liquidity_inner"></a>

## Macro function `add_liquidity_inner`

Add liquidity to position.

This macro is used by wrapper modules to add liquidity to existing positions,
ensuring all risk and protocol constraints are maintained.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>&lt;$X, $Y, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64)): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">kai_leverage::position_core_clmm::AddLiquidityInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>&lt;$X, $Y, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64),
): <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_AddLiquidityInfo">AddLiquidityInfo</a> {
    <b>let</b> (_, info) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_with_receipt_inner">add_liquidity_with_receipt_inner</a>!(
        $position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        |pool, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>| {
            <b>let</b> (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>, delta_x, delta_y) = $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>(pool, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>);
            (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>, delta_x, delta_y, 0)
        },
    );
    info
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_liquidity_with_receipt"></a>

## Macro function `add_liquidity_with_receipt`

Add liquidity to a position and return a custom receipt.

This macro allows wrapper modules to add liquidity to an existing position,
enforcing all protocol and risk constraints, and returns a custom receipt
type provided by the caller.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_with_receipt">add_liquidity_with_receipt</a>&lt;$X, $Y, $Pool, $LP, $Receipt&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64, $Receipt)): $Receipt
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_with_receipt">add_liquidity_with_receipt</a>&lt;$X, $Y, $Pool, $LP, $Receipt&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64, $Receipt),
): $Receipt {
    <b>let</b> position = $position;
    <b>let</b> cap = $cap;
    <b>assert</b>!(cap.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>let</b> (receipt, info) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_with_receipt_inner">add_liquidity_with_receipt_inner</a>!(
        position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>,
    );
    <b>if</b> (info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>() &gt; 0) {
        info.emit();
    };
    receipt
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_liquidity"></a>

## Macro function `add_liquidity`

Add liquidity to a position, enforcing all protocol and risk constraints.

This macro allows wrapper modules to add liquidity to an existing position.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity">add_liquidity</a>&lt;$X, $Y, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64))
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity">add_liquidity</a>&lt;$X, $Y, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64),
) {
    <b>let</b> position = $position;
    <b>let</b> cap = $cap;
    <b>assert</b>!(cap.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>let</b> info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>!(
        position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>,
    );
    <b>if</b> (info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>() &gt; 0) {
        info.emit();
    };
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_repay_debt_x"></a>

## Function `repay_debt_x`

Repay as much X token debt as possible using the available balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_repay_debt_x">repay_debt_x</a>&lt;X, Y, SX, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_repay_debt_x">repay_debt_x</a>&lt;X, Y, SX, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    balance: &<b>mut</b> Balance&lt;X&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
) {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>(position);
    <b>assert</b>!(cap.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;X, SX&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> debt_shares = position.debt_bag.take_all();
    <b>if</b> (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        <b>return</b>
    };
    <b>let</b> (_, x_repaid) = supply_pool.repay_max_possible(&<b>mut</b> debt_shares, balance, clock);
    position.debt_bag.add&lt;X, SX&gt;(debt_shares);
    <b>if</b> (x_repaid &gt; 0) {
        event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RepayDebtInfo">RepayDebtInfo</a> {
            position_id: object::id(position),
            x_repaid,
            y_repaid: 0,
        })
    };
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_repay_debt_y"></a>

## Function `repay_debt_y`

Repay as much Y token debt as possible using the available balance.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_repay_debt_y">repay_debt_y</a>&lt;X, Y, SY, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_repay_debt_y">repay_debt_y</a>&lt;X, Y, SY, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    balance: &<b>mut</b> Balance&lt;Y&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
) {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>(position);
    <b>assert</b>!(cap.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;Y, SY&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> debt_shares = position.debt_bag.take_all();
    <b>if</b> (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        <b>return</b>
    };
    <b>let</b> (_, y_repaid) = supply_pool.repay_max_possible(&<b>mut</b> debt_shares, balance, clock);
    position.debt_bag.add&lt;Y, SY&gt;(debt_shares);
    <b>if</b> (y_repaid &gt; 0) {
        event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RepayDebtInfo">RepayDebtInfo</a> {
            position_id: object::id(position),
            x_repaid: 0,
            y_repaid,
        })
    };
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_owner_collect_fee"></a>

## Macro function `owner_collect_fee`

Collect accumulated AMM fees for position owner directly.

Used by wrapper modules to collect fees from LP positions while
automatically deducting protocol fees according to configuration.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_fee">owner_collect_fee</a>&lt;$X, $Y, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, $pool_object: &<b>mut</b> $Pool, $collect_fee: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_fee">owner_collect_fee</a>&lt;$X, $Y, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    $pool_object: &<b>mut</b> $Pool,
    $collect_fee: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (Balance&lt;$X&gt;, Balance&lt;$Y&gt;),
): (Balance&lt;$X&gt;, Balance&lt;$Y&gt;) {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> cap = $cap;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(cap.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_fee_disabled">owner_collect_fee_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_owner_collect_fee_disabled">e_owner_collect_fee_disabled</a>!());
    <b>let</b> (<b>mut</b> x, <b>mut</b> y) = $collect_fee($pool_object, position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>());
    <b>let</b> collected_x_amt = x.value();
    <b>let</b> collected_y_amt = y.value();
    <b>let</b> x_fee_amt = <a href="../../kai_sav/util.md#kai_sav_util_muldiv">util::muldiv</a>(collected_x_amt, (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>() <b>as</b> u64), 10000);
    <b>let</b> x_fee = x.split(x_fee_amt);
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees_mut">collected_fees_mut</a>().add(x_fee);
    <b>let</b> y_fee_amt = <a href="../../kai_sav/util.md#kai_sav_util_muldiv">util::muldiv</a>(collected_y_amt, (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>() <b>as</b> u64), 10000);
    <b>let</b> y_fee = y.split(y_fee_amt);
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees_mut">collected_fees_mut</a>().add(y_fee);
    <b>let</b> position_id = object::id(position);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_owner_collect_fee_info">emit_owner_collect_fee_info</a>(
        position_id,
        collected_x_amt,
        collected_y_amt,
        x_fee_amt,
        y_fee_amt,
    );
    (x, y)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_owner_collect_reward"></a>

## Macro function `owner_collect_reward`

Collect accumulated AMM rewards for position owner directly.

Used by wrapper modules to collect protocol-specific rewards from LP
positions while automatically deducting protocol fees.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_reward">owner_collect_reward</a>&lt;$X, $Y, $T, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, $pool_object: &<b>mut</b> $Pool, $collect_reward: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$T&gt;): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_reward">owner_collect_reward</a>&lt;$X, $Y, $T, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    $pool_object: &<b>mut</b> $Pool,
    $collect_reward: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; Balance&lt;$T&gt;,
): Balance&lt;$T&gt; {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> cap = $cap;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(cap.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_collect_reward_disabled">owner_collect_reward_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_owner_collect_reward_disabled">e_owner_collect_reward_disabled</a>!());
    <b>let</b> <b>mut</b> reward = $collect_reward($pool_object, position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>());
    <b>let</b> collected_reward_amt = reward.value();
    <b>let</b> fee_amt = <a href="../../kai_sav/util.md#kai_sav_util_muldiv">util::muldiv</a>(collected_reward_amt, (config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>() <b>as</b> u64), 10000);
    <b>let</b> fee = reward.split(fee_amt);
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees_mut">collected_fees_mut</a>().add(fee);
    <b>let</b> position_id = object::id(position);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_owner_collect_reward_info">emit_owner_collect_reward_info</a>&lt;$T&gt;(
        position_id,
        collected_reward_amt,
        fee_amt,
    );
    reward
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_owner_take_stashed_rewards"></a>

## Function `owner_take_stashed_rewards`

Withdraw stashed rewards from position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_take_stashed_rewards">owner_take_stashed_rewards</a>&lt;X, Y, T, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, amount: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_take_stashed_rewards">owner_take_stashed_rewards</a>&lt;X, Y, T, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    cap: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    amount: Option&lt;u64&gt;,
): Balance&lt;T&gt; {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>(position);
    <b>assert</b>!(cap.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>let</b> rewards = <b>if</b> (amount.is_some()) {
        <b>let</b> amount = amount.destroy_some();
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>.take_amount(amount)
    } <b>else</b> {
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>.take_all()
    };
    event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_OwnerTakeStashedRewardsInfo">OwnerTakeStashedRewardsInfo</a>&lt;T&gt; {
        position_id: object::id(position),
        amount: rewards.value(),
    });
    rewards
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_delete_position"></a>

## Macro function `delete_position`

Delete position. The position needs to be fully reduced and all assets withdrawn first.

Used by wrapper modules to safely delete empty positions while
preserving any collected fees for later retrieval by protocol admins.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delete_position">delete_position</a>&lt;$X, $Y, $LP: store&gt;($position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $cap: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">kai_leverage::position_core_clmm::PositionCap</a>, $destroy_empty_lp_position: |$LP| -&gt; (), $ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delete_position">delete_position</a>&lt;$X, $Y, $LP: store&gt;(
    $position: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $cap: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionCap">PositionCap</a>,
    $destroy_empty_lp_position: |$LP| -&gt; (),
    $ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> cap = $cap;
    <b>let</b> ctx = $ctx;
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(&position, config);
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(cap.position_id() == object::id(&position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_position_cap">e_invalid_position_cap</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    <b>assert</b>!(!config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delete_position_disabled">delete_position_disabled</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_delete_position_disabled">e_delete_position_disabled</a>!());
    // delete position
    <b>let</b> (
        id,
        _config_id,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>,
        debt_bag,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>,
        _ticket_active,
        _version,
    ) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_deconstructor">position_deconstructor</a>(position);
    id.delete();
    $destroy_empty_lp_position(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position">lp_position</a>);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_x">col_x</a>.destroy_zero();
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_col_y">col_y</a>.destroy_zero();
    debt_bag.destroy_empty();
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>.destroy_empty();
    // delete cap
    <b>let</b> (id, position_id) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_position_cap_deconstructor">position_cap_deconstructor</a>(cap);
    <b>let</b> cap_id = id.to_inner();
    id.delete();
    <b>if</b> (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>.is_empty()) {
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>.destroy_empty()
    } <b>else</b> {
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_share_deleted_position_collected_fees">share_deleted_position_collected_fees</a>(
            position_id,
            <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>,
            ctx,
        );
    };
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_emit_delete_position_info">emit_delete_position_info</a>(position_id, cap_id);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_create_rebalance_receipt"></a>

## Function `create_rebalance_receipt`

Create rebalance receipt for tracking position rebalancing operations.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_rebalance_receipt">create_rebalance_receipt</a>&lt;X, Y, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_create_rebalance_receipt">create_rebalance_receipt</a>&lt;X, Y, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    ctx: &<b>mut</b> TxContext,
): (<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>, ActionRequest) {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_versions">check_versions</a>(position, config);
    <b>assert</b>!(position.config_id == config.id.to_inner(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a> == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a> = <b>true</b>;
    <b>let</b> receipt = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a> {
        id: object::id_from_address(tx_context::fresh_object_address(ctx)),
        position_id: object::id(position),
        collected_amm_fee_x: 0,
        collected_amm_fee_y: 0,
        collected_amm_rewards: vec_map::empty(),
        fees_taken: vec_map::empty(),
        taken_cx: 0,
        taken_cy: 0,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>: 0,
        delta_x: 0,
        delta_y: 0,
        x_repaid: 0,
        y_repaid: 0,
        added_cx: 0,
        added_cy: 0,
        stashed_amm_rewards: vec_map::empty(),
    };
    (receipt, access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ARebalance">ARebalance</a> {}, ctx))
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_add_amount_to_map"></a>

## Function `add_amount_to_map`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_amount_to_map">add_amount_to_map</a>&lt;T&gt;(map: &<b>mut</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_amount_to_map">add_amount_to_map</a>&lt;T&gt;(map: &<b>mut</b> VecMap&lt;TypeName, u64&gt;, amount: u64) {
    <b>let</b> `type` = type_name::with_defining_ids&lt;T&gt;();
    <b>if</b> (vec_map::contains(map, &`type`)) {
        <b>let</b> total = &<b>mut</b> map[&`type`];
        *total = *total + amount;
    } <b>else</b> {
        map.insert(`type`, amount);
    }
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_take_rebalance_fee"></a>

## Function `take_rebalance_fee`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_take_rebalance_fee">take_rebalance_fee</a>&lt;X, Y, LP, T&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, fee_bps: u16, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_take_rebalance_fee">take_rebalance_fee</a>&lt;X, Y, LP, T&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    fee_bps: u16,
    balance: &<b>mut</b> Balance&lt;T&gt;,
    receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
) {
    <b>let</b> fee_amt = <a href="../../kai_sav/util.md#kai_sav_util_muldiv">util::muldiv</a>(balance.value(), (fee_bps <b>as</b> u64), 10000);
    <b>let</b> fee = balance.split(fee_amt);
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>.add(fee);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_amount_to_map">add_amount_to_map</a>&lt;T&gt;(&<b>mut</b> receipt.fees_taken, fee_amt);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rebalance_collect_fee"></a>

## Macro function `rebalance_collect_fee`

Collects AMM trading fees for a leveraged CLMM position during rebalancing,
applies protocol fee, and updates the <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a></code>.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_collect_fee">rebalance_collect_fee</a>&lt;$X, $Y, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, $pool_object: &<b>mut</b> $Pool, $collect_fee: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$X&gt;, <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$Y&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_collect_fee">rebalance_collect_fee</a>&lt;$X, $Y, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
    $pool_object: &<b>mut</b> $Pool,
    $collect_fee: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (Balance&lt;$X&gt;, Balance&lt;$Y&gt;),
): (Balance&lt;$X&gt;, Balance&lt;$Y&gt;) {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> receipt = $receipt;
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(receipt.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>assert</b>!(object::id($pool_object) == config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_pool_object_id">pool_object_id</a>(), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_pool">e_invalid_pool</a>!());
    <b>let</b> (<b>mut</b> x, <b>mut</b> y) = $collect_fee($pool_object, position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>());
    receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_collected_amm_fee_x">increase_collected_amm_fee_x</a>(x.value());
    receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_collected_amm_fee_y">increase_collected_amm_fee_y</a>(y.value());
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_take_rebalance_fee">take_rebalance_fee</a>(position, config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>(), &<b>mut</b> x, receipt);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_take_rebalance_fee">take_rebalance_fee</a>(position, config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>(), &<b>mut</b> y, receipt);
    (x, y)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rebalance_collect_reward"></a>

## Macro function `rebalance_collect_reward`

Collects AMM rewards for a leveraged CLMM position during rebalancing,
applies protocol fee, and updates the <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a></code>.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_collect_reward">rebalance_collect_reward</a>&lt;$X, $Y, $T, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, $pool_object: &<b>mut</b> $Pool, $collect_reward: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$T&gt;): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;$T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_collect_reward">rebalance_collect_reward</a>&lt;$X, $Y, $T, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
    $pool_object: &<b>mut</b> $Pool,
    $collect_reward: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; Balance&lt;$T&gt;,
): Balance&lt;$T&gt; {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>let</b> receipt = $receipt;
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(receipt.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>let</b> <b>mut</b> reward = $collect_reward($pool_object, position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_lp_position_mut">lp_position_mut</a>());
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_amount_to_map">add_amount_to_map</a>&lt;$T&gt;(receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_amm_rewards_mut">collected_amm_rewards_mut</a>(), balance::value(&reward));
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_take_rebalance_fee">take_rebalance_fee</a>(position, config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_fee_bps">rebalance_fee_bps</a>(), &<b>mut</b> reward, receipt);
    reward
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rebalance_add_liquidity_with_receipt"></a>

## Macro function `rebalance_add_liquidity_with_receipt`

Adds liquidity to a leveraged CLMM position during rebalancing, using a custom lambda that returns a receipt.
Updates the <code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a></code> with the amounts added (delta_l, delta_x, delta_y).
Returns the custom receipt produced by the lambda.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_add_liquidity_with_receipt">rebalance_add_liquidity_with_receipt</a>&lt;$X, $Y, $Pool, $LP, $Receipt&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $add_liquidity_lambda: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64, $Receipt)): $Receipt
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_add_liquidity_with_receipt">rebalance_add_liquidity_with_receipt</a>&lt;$X, $Y, $Pool, $LP, $Receipt&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $add_liquidity_lambda: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64, $Receipt),
): $Receipt {
    <b>let</b> receipt = $receipt;
    <b>let</b> position = $position;
    <b>assert</b>!(receipt.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>let</b> (cetus_receipt, info) = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_with_receipt_inner">add_liquidity_with_receipt_inner</a>!(
        position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $add_liquidity_lambda,
    );
    receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_l">increase_delta_l</a>(info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>());
    receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_x">increase_delta_x</a>(info.delta_x());
    receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_y">increase_delta_y</a>(info.delta_y());
    cetus_receipt
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rebalance_add_liquidity"></a>

## Macro function `rebalance_add_liquidity`

Adds liquidity to a leveraged CLMM position during rebalancing.
This macro uses a custom lambda to perform the liquidity addition and updates the
<code><a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a></code> with the amounts of liquidity and tokens added.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_add_liquidity">rebalance_add_liquidity</a>&lt;$X, $Y, $Pool, $LP&gt;($position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $pool_object: &<b>mut</b> $Pool, $add_liquidity_lambda: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64))
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_add_liquidity">rebalance_add_liquidity</a>&lt;$X, $Y, $Pool, $LP&gt;(
    $position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $pool_object: &<b>mut</b> $Pool,
    $add_liquidity_lambda: |&<b>mut</b> $Pool, &<b>mut</b> $LP| -&gt; (u128, u64, u64),
) {
    <b>let</b> receipt = $receipt;
    <b>let</b> position = $position;
    <b>assert</b>!(receipt.position_id() == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>let</b> info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_liquidity_inner">add_liquidity_inner</a>!(
        position,
        $config,
        $price_info,
        $debt_info,
        $pool_object,
        $add_liquidity_lambda,
    );
    receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_l">increase_delta_l</a>(info.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>());
    receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_x">increase_delta_x</a>(info.delta_x());
    receipt.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_increase_delta_y">increase_delta_y</a>(info.delta_y());
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rebalance_repay_debt_x"></a>

## Function `rebalance_repay_debt_x`

Repay X debt during rebalancing and update receipt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_repay_debt_x">rebalance_repay_debt_x</a>&lt;X, Y, SX, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;X&gt;, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;X, SX&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_repay_debt_x">rebalance_repay_debt_x</a>&lt;X, Y, SX, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    balance: &<b>mut</b> Balance&lt;X&gt;,
    receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
    supply_pool: &<b>mut</b> SupplyPool&lt;X, SX&gt;,
    clock: &Clock,
) {
    <b>assert</b>!(receipt.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;X, SX&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> debt_shares = position.debt_bag.take_all();
    <b>if</b> (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        <b>return</b>
    };
    <b>let</b> (_, x_repaid) = supply_pool::repay_max_possible(
        supply_pool,
        &<b>mut</b> debt_shares,
        balance,
        clock,
    );
    position.debt_bag.add&lt;X, SX&gt;(debt_shares);
    receipt.x_repaid = receipt.x_repaid + x_repaid;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rebalance_repay_debt_y"></a>

## Function `rebalance_repay_debt_y`

Repay Y debt during rebalancing and update receipt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_repay_debt_y">rebalance_repay_debt_y</a>&lt;X, Y, SY, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;Y&gt;, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, supply_pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;Y, SY&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_repay_debt_y">rebalance_repay_debt_y</a>&lt;X, Y, SY, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    balance: &<b>mut</b> Balance&lt;Y&gt;,
    receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
    supply_pool: &<b>mut</b> SupplyPool&lt;Y, SY&gt;,
    clock: &Clock,
) {
    <b>assert</b>!(receipt.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <b>assert</b>!(
        position.debt_bag().share_type_matches_asset_if_any_exists&lt;Y, SY&gt;(),
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_supply_pool_mismatch">e_supply_pool_mismatch</a>!(),
    );
    <b>let</b> <b>mut</b> debt_shares = position.debt_bag.take_all();
    <b>if</b> (debt_shares.value_x64() == 0) {
        debt_shares.destroy_zero();
        <b>return</b>
    };
    <b>let</b> (_, y_repaid) = supply_pool.repay_max_possible(&<b>mut</b> debt_shares, balance, clock);
    position.debt_bag.add&lt;Y, SY&gt;(debt_shares);
    receipt.y_repaid = receipt.y_repaid + y_repaid;
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_rebalance_stash_rewards"></a>

## Function `rebalance_stash_rewards`

Stash rewards in position during rebalancing.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_stash_rewards">rebalance_stash_rewards</a>&lt;X, Y, T, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>, rewards: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_rebalance_stash_rewards">rebalance_stash_rewards</a>&lt;X, Y, T, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    receipt: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
    rewards: Balance&lt;T&gt;,
) {
    <b>assert</b>!(receipt.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_add_amount_to_map">add_amount_to_map</a>&lt;T&gt;(&<b>mut</b> receipt.stashed_amm_rewards, rewards.value());
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_owner_reward_stash">owner_reward_stash</a>.add(rewards);
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_consume_rebalance_receipt"></a>

## Function `consume_rebalance_receipt`

Consume rebalance receipt and emit comprehensive rebalancing event.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_consume_rebalance_receipt">consume_rebalance_receipt</a>&lt;X, Y, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, receipt: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">kai_leverage::position_core_clmm::RebalanceReceipt</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_consume_rebalance_receipt">consume_rebalance_receipt</a>&lt;X, Y, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    receipt: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a>,
) {
    <b>assert</b>!(receipt.position_id == object::id(position), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_position_mismatch">e_position_mismatch</a>!());
    position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a> = <b>false</b>;
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceReceipt">RebalanceReceipt</a> {
        id,
        position_id,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        delta_x,
        delta_y,
        fees_taken,
        collected_amm_fee_x,
        collected_amm_fee_y,
        collected_amm_rewards,
        taken_cx,
        taken_cy,
        x_repaid,
        y_repaid,
        added_cx,
        added_cy,
        stashed_amm_rewards,
    } = receipt;
    event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_RebalanceInfo">RebalanceInfo</a> {
        id,
        position_id,
        <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_delta_l">delta_l</a>,
        delta_x,
        delta_y,
        fees_taken,
        collected_amm_fee_x,
        collected_amm_fee_y,
        collected_amm_rewards,
        taken_cx,
        taken_cy,
        x_repaid,
        y_repaid,
        added_cx,
        added_cy,
        stashed_amm_rewards,
    });
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_collect_protocol_fees"></a>

## Function `collect_protocol_fees`

Collect protocol fees from position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collect_protocol_fees">collect_protocol_fees</a>&lt;X, Y, T, LP: store&gt;(position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;X, Y, LP&gt;, amount: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collect_protocol_fees">collect_protocol_fees</a>&lt;X, Y, T, LP: store&gt;(
    position: &<b>mut</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;X, Y, LP&gt;,
    amount: Option&lt;u64&gt;,
    ctx: &<b>mut</b> TxContext,
): (Balance&lt;T&gt;, ActionRequest) {
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_check_position_version">check_position_version</a>(position);
    <b>let</b> fee: Balance&lt;T&gt; = <b>if</b> (amount.is_none()) {
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>.take_all()
    } <b>else</b> {
        <b>let</b> amount = amount.destroy_some();
        position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collected_fees">collected_fees</a>.take_amount(amount)
    };
    event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_CollectProtocolFeesInfo">CollectProtocolFeesInfo</a>&lt;T&gt; {
        position_id: object::id(position),
        amount: fee.value(),
    });
    (fee, access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ACollectProtocolFees">ACollectProtocolFees</a> {}, ctx))
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_collect_deleted_position_fees"></a>

## Function `collect_deleted_position_fees`

Collect fees from deleted position.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collect_deleted_position_fees">collect_deleted_position_fees</a>(fees: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletedPositionCollectedFees">kai_leverage::position_core_clmm::DeletedPositionCollectedFees</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_collect_deleted_position_fees">collect_deleted_position_fees</a>(
    fees: <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletedPositionCollectedFees">DeletedPositionCollectedFees</a>,
    ctx: &<b>mut</b> TxContext,
): (BalanceBag, ActionRequest) {
    <b>let</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletedPositionCollectedFees">DeletedPositionCollectedFees</a> { id, position_id, balance_bag } = fees;
    id.delete();
    event::emit(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_DeletedPositionCollectedFeesInfo">DeletedPositionCollectedFeesInfo</a> {
        position_id,
        amounts: *balance_bag.amounts(),
    });
    (balance_bag, access::new_request(<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ACollectProtocolFees">ACollectProtocolFees</a> {}, ctx))
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_validated_model_for_position"></a>

## Macro function `validated_model_for_position`

Create validated position model for analysis and calculations.
Used to obtain position models for risk assessment,
liquidation calculations, and other analytical operations.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validated_model_for_position">validated_model_for_position</a>&lt;$X, $Y, $LP&gt;($position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>): <a href="../../dependencies/kai_leverage/position_model.md#kai_leverage_position_model_clmm_PositionModel">kai_leverage::position_model_clmm::PositionModel</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validated_model_for_position">validated_model_for_position</a>&lt;$X, $Y, $LP&gt;(
    $position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $debt_info: &DebtInfo,
): PositionModel {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    <b>let</b> debt_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, $debt_info);
    <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &debt_info)
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_calc_liquidate_col_x"></a>

## Macro function `calc_liquidate_col_x`

Calculate the required amounts to liquidate X collateral by repaying Y debt.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liquidate_col_x">calc_liquidate_col_x</a>&lt;$X, $Y, $LP&gt;($position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $max_repayment_amt_y: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liquidate_col_x">calc_liquidate_col_x</a>&lt;$X, $Y, $LP&gt;(
    $position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $max_repayment_amt_y: u64,
): (u64, u64) {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>let</b> debt_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, $debt_info);
    <b>let</b> model = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &debt_info);
    <b>let</b> p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    model.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liquidate_col_x">calc_liquidate_col_x</a>(
        p_x128,
        $max_repayment_amt_y,
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>(),
    )
}
</code></pre>



</details>

<a name="kai_leverage_position_core_clmm_calc_liquidate_col_y"></a>

## Macro function `calc_liquidate_col_y`

Calculate the required amounts to liquidate Y collateral by repaying X debt.


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liquidate_col_y">calc_liquidate_col_y</a>&lt;$X, $Y, $LP&gt;($position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">kai_leverage::position_core_clmm::Position</a>&lt;$X, $Y, $LP&gt;, $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">kai_leverage::position_core_clmm::PositionConfig</a>, $price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, $debt_info: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, $max_repayment_amt_x: u64): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>macro</b> <b>fun</b> <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liquidate_col_y">calc_liquidate_col_y</a>&lt;$X, $Y, $LP&gt;(
    $position: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_Position">Position</a>&lt;$X, $Y, $LP&gt;,
    $config: &<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_PositionConfig">PositionConfig</a>,
    $price_info: &PythPriceInfo,
    $debt_info: &DebtInfo,
    $max_repayment_amt_x: u64,
): (u64, u64) {
    <b>let</b> position = $position;
    <b>let</b> config = $config;
    <b>assert</b>!(position.config_id() == object::id(config), <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_invalid_config">e_invalid_config</a>!());
    <b>assert</b>!(position.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_ticket_active">ticket_active</a>() == <b>false</b>, <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_e_ticket_active">e_ticket_active</a>!());
    <b>let</b> price_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_price_info">validate_price_info</a>(config, $price_info);
    <b>let</b> debt_info = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_validate_debt_info">validate_debt_info</a>(config, $debt_info);
    <b>let</b> model = <a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_model_from_position">model_from_position</a>!(position, &debt_info);
    <b>let</b> p_x128 = price_info.div_price_numeric_x128(
        type_name::with_defining_ids&lt;$X&gt;(),
        type_name::with_defining_ids&lt;$Y&gt;(),
    );
    model.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_calc_liquidate_col_y">calc_liquidate_col_y</a>(
        p_x128,
        $max_repayment_amt_x,
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_margin_bps">liq_margin_bps</a>(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_liq_bonus_bps">liq_bonus_bps</a>(),
        config.<a href="../../dependencies/kai_leverage/position_core.md#kai_leverage_position_core_clmm_base_liq_factor_bps">base_liq_factor_bps</a>(),
    )
}
</code></pre>



</details>

/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::errors {

    //===========================================================//
    //                          Constants                        //
    //===========================================================//


    /// Triggered when object version does not match the package version
    const EVersionMismatch: u64 = 1001;

    /// Triggered when the tick provided are invalid
    const EInvalidTicks: u64 = 1002;

    /// Triggered when the provided amount is insufficient
    const EInsufficientAmount: u64 = 1003;

    /// Triggered when the user coin provided does not have enough balance
    const EInsufficientCoinBalance: u64 = 1004;

    /// Triggered when the `config.version` is already at VERSION
    const EVersionMax: u64 = 1005;

    /// Triggered when an invalid action is being performed during an on-going flash swap
    const EFlashSwapInProgress: u64 = 1006;

    /// Triggered when trying to repay a flash swap amount when there is no flash swap in progress
    const ENoFlashSwapInProgress: u64 = 1007;

    /// Triggered when an overflow has occurred in integer maths
    const EOverflow: u64 = 1008;

    /// Triggered when price limit provided for swap is invalid
    const EInvalidPriceLimit: u64 = 1009;

    /// Triggered when the output amount of the swap exceeds slippage
    /// or the liquidity provided exceeds slippage
    const ESlippageExceeds: u64 = 1010;

    /// Triggered when the pool provided for flash swap repayment
    /// doesn't match the pool id of the flash receipt
    const EReceiptAndPoolMismatch: u64 = 1011;

    /// Triggered when providing liquidity or performing swap on a pool
    /// that is paused
    const EPoolIsPaused: u64 = 1012;

    /// Triggered when coin A and coin B are same 
    const EInvalidCoins: u64 = 1013;

    /// Triggered when an observation has invalid timestamp
    const EInvalidObservationTimestamp: u64 = 1014;

    /// Triggered when insufficient liquidity
    const EInsufficientLiquidity: u64 = 1015;

    /// Triggered when the fee growth value is invalid
    const EInvalidFeeGrowth: u64 = 1016;

    /// Triggered when an add check fails
    const EAddCheckFailed: u64 = 1017;

    /// Triggered when trying to delete a non-empty position
    const ENonEmptyPosition: u64 = 1018;

    /// Triggered when the pool and positions don't match
    const EPositionAndPoolDontMatch: u64 = 1019;

    /// Triggered when time is invalid for reward related operations
    const EInvalidTimestamp: u64 = 1020;

    /// Triggered when reward type not found inside pool rewards
    const ERewardIndexNotFound : u64 = 1021;

    /// Triggered when reward's last updated time is invalid
    const EInvalidLastUpdateTime : u64  = 1022;

    /// Triggered when transaction sender is not authorized for operation
    const ENotAuthorized : u64 = 1023;

    /// Triggered when unable to update reward info in position
    const EUpdateRewardInfoCheckFailed : u64 = 1024;

    /// Triggered when admin tries to set a protocol fee share > max allowed limit
    const EInvalidProtocolFeeShare : u64 = 1025;

    /// Triggered when the provided tick spacing > max allowed 
    const EInvalidTickSpacing: u64 = 1026;

    /// Triggered when the provided fee rate > max allowed
    const EInvalidFeeRate: u64 = 1027;

    /// Triggered when the observation cardinality provided is > max allowed limit
    const EInvalidCardinality: u64 = 1028;

    /// Triggered when the provided input amount is zero
    const EZeroAmount: u64 = 1029;

    /// Triggered when sqrt price provided on pool creation is invalid
    const EInvalidPoolPrice: u64 = 1030;

    /// Triggered when reward manager not found
    const ERewardManagerNotFound : u64 = 1031;

    /// Triggered when adding existing reward manager
    const EAlreadyARewardManager : u64 = 1032;

    /// Triggered when reward manager not found
    const ECannotClaimZeroReward : u64 = 1033;

    /// Triggered when trying to close position with fee remaining to claim
    const ECannotClosePositionWithFeeToClaim: u64 = 1035;

    /// Triggered when a deprecated method is invoked
    const EDeprecated: u64 = 1036;

    /// Triggered when a user provides a different deprecated amount as opposed 
    /// to reward coin balance
    const ERewardAmountAndBalanceMismatch: u64 = 1037;

    /// Triggered when the provided fee coin for creating a pool is 
    /// not supported
    const EFeeCoinNotSupported: u64 = 1038;

    /// Triggered when the fee provided for pool creation is < or > then
    /// the required fee amount
    const EInvalidPoolCreationFee: u64 = 1039;

    /// Triggered when the same value is provided for the same field
    const ESameValueProvided: u64 = 1040;

    //===========================================================//
    //                        Getter Methods                     //
    //===========================================================//

    public fun version_mismatch(): u64 {
        EVersionMismatch
    }

    public fun invalid_tick_range(): u64 {
        EInvalidTicks
    }

    public fun insufficient_amount(): u64 {
        EInsufficientAmount
    }

    public fun insufficient_coin_balance(): u64 {
        EInsufficientCoinBalance
    }

    /// Unused error
    public fun insufficient_pool_balance(): u64 {
        abort 0
    }

    /// Unused error
    public fun tick_score_out_of_bounds(): u64 {
        abort 0
    }

    /// Unused error
    public fun swap_amount_exceeds(): u64 {
        abort 0
    }

    public fun overflow(): u64 {
        EOverflow
    }

    public fun invalid_price_limit(): u64 {
        EInvalidPriceLimit
    }

    public fun slippage_exceeds(): u64 {
        ESlippageExceeds
    }

    public fun invalid_pool(): u64 {
        EReceiptAndPoolMismatch
    }

    public fun pool_is_paused(): u64 {
        EPoolIsPaused
    }

    public fun invalid_coins(): u64 {
        EInvalidCoins
    }

    public fun invalid_observation_timestamp(): u64 {
        EInvalidObservationTimestamp
    }

    public fun insufficient_liquidity(): u64 {
        EInsufficientLiquidity
    }

    public fun invalid_fee_growth(): u64 {
        EInvalidFeeGrowth
    }

    public fun add_check_failed(): u64 {
        EAddCheckFailed
    }

    public fun non_empty_position(): u64 {
        ENonEmptyPosition
    }

    public fun position_does_not_belong_to_pool(): u64 {
        EPositionAndPoolDontMatch
    }

     public fun invalid_timestamp(): u64 {
        EInvalidTimestamp
    }

    public fun reward_index_not_found(): u64 {
        ERewardIndexNotFound
    }

    public fun invalid_last_update_time() : u64 {
        EInvalidLastUpdateTime
    }

    public fun not_authorized() : u64 {
        ENotAuthorized
    }

    public fun update_rewards_info_check_failed() : u64 {
        EUpdateRewardInfoCheckFailed
    }

    public fun invalid_protocol_fee_share(): u64 {
        EInvalidProtocolFeeShare
    }


    public fun invalid_tick_spacing(): u64 {
        EInvalidTickSpacing
    }

    public fun invalid_fee_rate(): u64 {
        EInvalidFeeRate
    }

    public fun invalid_observation_cardinality(): u64 {
        EInvalidCardinality
    }

    public fun zero_amount(): u64 {
        EZeroAmount
    }

    public fun verion_cant_be_increased(): u64 {
        EVersionMax
    }

    public fun invalid_pool_price(): u64 {
        EInvalidPoolPrice
    }

    public fun already_a_reward_manger(): u64 {
        EAlreadyARewardManager
    }

    public fun reward_manager_not_found() : u64 {
        ERewardManagerNotFound
    }

    public fun can_not_claim_zero_reward() : u64 {
        ECannotClaimZeroReward
    }

    public fun cannot_close_position_with_fee_to_claim(): u64 {
        ECannotClosePositionWithFeeToClaim
    }

    public fun depricated(): u64 {
        EDeprecated
    }

    public fun reward_amount_and_provided_balance_do_not_match(): u64 {
        ERewardAmountAndBalanceMismatch
    }

    public fun fee_coin_not_supported(): u64 {
        EFeeCoinNotSupported
    }

    public fun invalid_fee_provided(): u64 {
        EInvalidPoolCreationFee
    }

    public fun flash_swap_in_progress(): u64 {
        EFlashSwapInProgress
    }

    public fun no_flash_swap_in_progress(): u64 {
        ENoFlashSwapInProgress
    }

    public fun same_value_provided(): u64 {
        ESameValueProvided
    }

}
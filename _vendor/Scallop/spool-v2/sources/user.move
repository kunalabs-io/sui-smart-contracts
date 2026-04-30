module spool::user {
    use std::type_name::TypeName;
    use sui::tx_context::TxContext;
    use sui::coin::{Self, Coin};
    use sui::clock::Clock;
    use sui::object::ID;
    use spool::spool::Spool;
    use spool::rewards_pool::RewardsPool;
    use spool::spool_account::{Self, SpoolAccount};

    struct CreateSpoolAccountEvent has copy, drop {
        spool_account_id: ID,
        spool_id: ID,
        staking_type: TypeName,
        created_at: u64,
    }

    struct SpoolAccountUnstakeEvent has copy, drop {
        spool_account_id: ID,
        spool_id: ID,
        staking_type: TypeName,
        unstake_amount: u64,
        remaining_amount: u64,
        timestamp: u64,
    }

    struct SpoolAccountStakeEvent has copy, drop {
        sender: address,
        spool_account_id: ID,
        spool_id: ID,
        staking_type: TypeName,
        stake_amount: u64,
        previous_amount: u64,
        timestamp: u64,
    }

    struct SpoolAccountRedeemRewardsEvent has copy, drop {
        sender: address,
        spool_account_id: ID,
        spool_id: ID,
        rewards_pool_id: ID,
        staking_type: TypeName,
        rewards_type: TypeName,
        redeemed_points: u64,
        previous_points: u64,
        rewards: u64,
        /// total claimed rewards in the pool
        total_claimed_rewards: u64,
        /// total points of the user
        total_user_points: u64,
        timestamp: u64,
    }

    const MaxStakesReachedErr: u64 = 0x0000010;
    const InvalidStakeTypeErr: u64 = 0x0000011;

    public fun new_spool_account<StakeType>(
        spool: &mut Spool,
        _clock: &Clock,
        ctx: &mut TxContext,
    ): SpoolAccount<StakeType> {
        let spool_account = spool_account::new<StakeType>(spool, ctx);
        spool_account
    }

    public entry fun update_points<StakeType>(
        _spool: &mut Spool,
        _spool_account: &mut SpoolAccount<StakeType>,
        _clock: &Clock,
    ) {
        abort 0
    }

    public entry fun stake<StakeType>(
        _spool: &mut Spool,
        _spool_account: &mut SpoolAccount<StakeType>,
        _stake_coin: Coin<StakeType>,
        _clock: &Clock,
        _ctx: &TxContext,
    ) {
        abort 0
    }

    public fun unstake<StakeType>(
        _spool: &mut Spool,
        _spool_account: &mut SpoolAccount<StakeType>,
        _unstake_amount: u64,
        _clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<StakeType> {
        coin::zero(ctx)
    }

    public fun redeem_rewards<StakeType, RewardType>(
        _spool: &mut Spool,
        _rewards_pool: &mut RewardsPool<RewardType>,
        _spool_account: &mut SpoolAccount<StakeType>,
        _clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<RewardType> {
        coin::zero(ctx)
    }
}
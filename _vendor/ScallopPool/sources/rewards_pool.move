module spool::rewards_pool {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::balance::{Self, Balance};
    use spool::spool_account::SpoolAccount;
    use spool::spool::Spool;

    friend spool::admin;
    friend spool::user;

    const InvalidSpoolIdErr: u64 = 0x000010;

    struct RewardsPool<phantom RewardType> has key, store {
        id: UID,
        spool_id: ID,
        exchange_rate_numerator: u64,
        exchange_rate_denominator: u64,
        rewards: Balance<RewardType>,
        claimed_rewards: u64,
    }

    public fun claimed_rewards<RewardType>(rewards_pool: &RewardsPool<RewardType>): u64 { rewards_pool.claimed_rewards }

    public(friend) fun new<RewardType>(
        spool: &Spool,
        exchange_rate_numerator: u64,
        exchange_rate_denominator: u64,
        ctx: &mut TxContext,
    ): RewardsPool<RewardType> {
        RewardsPool<RewardType> {
            id: object::new(ctx),
            spool_id: object::id(spool),
            exchange_rate_numerator,
            exchange_rate_denominator,
            rewards: balance::zero(),
            claimed_rewards: 0,
        }
    }

    public(friend) fun add_rewards<RewardType>(
        _rewards_pool: &mut RewardsPool<RewardType>,
        _new_rewards: Balance<RewardType>,
    ) {
        abort 0
    }

    public(friend) fun take_rewards<RewardType>(
        _rewards_pool: &mut RewardsPool<RewardType>,
        _amount: u64,
    ): Balance<RewardType> {
        balance::zero()
    }

    public fun calculate_point_to_reward<RewardType>(
        _rewards_pool: &RewardsPool<RewardType>,
        _points: u64,
    ): u64 {
        0
    }

    public fun calculate_reward_to_point<RewardType>(
        _rewards_pool: &RewardsPool<RewardType>,
        _reward: u64,
    ): u64 {
        0
    }

    public(friend) fun redeem_rewards<StakeType, RewardType>(
        _rewards_pool: &mut RewardsPool<RewardType>,
        _spool_account: &mut SpoolAccount<StakeType>,
    ): Balance<RewardType> {
        balance::zero()
    }

    public fun assert_spool_id<RewardType>(
        _rewards_pool: &RewardsPool<RewardType>,
        _spool: &Spool,
    ) {
        abort 0
    }
}
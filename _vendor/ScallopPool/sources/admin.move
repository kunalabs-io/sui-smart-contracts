module spool::admin {
    use sui::tx_context::TxContext;
    use sui::object::{UID, ID};
    use sui::coin::{Self, Coin};
    use sui::clock::Clock;
    use std::type_name::TypeName;
    use spool::spool::Spool;
    use spool::rewards_pool::RewardsPool;

    struct AdminCap has key, store {
        id: UID,
    }

    struct CreateSpoolEvent has copy, drop {
        spool_id: ID,
        staking_type: TypeName,
        distributed_point_per_period: u64,
        point_distribution_time: u64,
        max_distributed_point: u64,
        max_stakes: u64,
        created_at: u64,
    }

    struct UpdateSpoolConfigEvent has copy, drop {
        spool_id: ID,
        distributed_point_per_period: u64,
        point_distribution_time: u64,
        max_distributed_point: u64,
        max_stakes: u64,
        updated_at: u64,
    }

    public entry fun create_spool<StakeType>(
        _: &AdminCap,
        _distributed_point_per_period: u64,
        _point_distribution_time: u64,
        _max_distributed_point: u64,
        _max_stakes: u64,
        _clock: &Clock,
        _ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun update_spool_config(
        _: &AdminCap,
        _spool: &mut Spool,
        _distributed_point_per_period: u64,
        _point_distribution_time: u64,
        _max_distributed_point: u64,
        _max_stakes: u64,
        _clock: &Clock,
    ) {
        abort 0
    }

    public entry fun create_rewards_pool<RewardType>(
        _: &AdminCap,
        _spool: &Spool,
        _exchange_rate_numerator: u64,
        _exchange_rate_denominator: u64,
        _ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun add_rewards<RewardType>(
        _rewards_pool: &mut RewardsPool<RewardType>,
        _new_rewards: Coin<RewardType>,
    ) {
        abort 0
    }

    public fun take_rewards<RewardType>(
        _: &AdminCap,
        _rewards_pool: &mut RewardsPool<RewardType>,
        _amount: u64,
        ctx: &mut TxContext,
    ): Coin<RewardType> {
        coin::zero(ctx)
    }
}
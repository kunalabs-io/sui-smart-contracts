module spool::spool_account {
    use std::type_name::{Self, TypeName};
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use spool::spool::{Self, Spool};

    friend spool::admin;
    friend spool::user;
    friend spool::rewards_pool;

    const SpoolAccountKeyDoesntMatchErr: u64 = 0x000010;
    const SpoolPointsHaventUpdatedErr: u64 = 0x000011;
    const SpoolIsntUpToDateErr: u64 = 0x000012;
    const InvalidSpoolErr: u64 = 0x000013;

    struct SpoolAccount<phantom StakeType> has key, store {
        id: UID,
        spool_id: ID,
        stake_type: TypeName,
        stakes: Balance<StakeType>,
        /// the current user point
        points: u64,
        /// total points that user already got from the pool
        total_points: u64,
        index: u64,
    }

    public fun spool_id<StakeType>(spool_account: &SpoolAccount<StakeType>): ID { spool_account.spool_id }
    public fun stake_type<StakeType>(spool_account: &SpoolAccount<StakeType>): TypeName { spool_account.stake_type }
    public fun stake_amount<StakeType>(spool_account: &SpoolAccount<StakeType>): u64 { balance::value(&spool_account.stakes) }
    public fun points<StakeType>(spool_account: &SpoolAccount<StakeType>): u64 { spool_account.points }
    public fun total_points<StakeType>(spool_account: &SpoolAccount<StakeType>): u64 { spool_account.total_points }

    public(friend) fun new<StakeType>(spool: &Spool, ctx: &mut TxContext): SpoolAccount<StakeType> {
        SpoolAccount<StakeType> {
            id: object::new(ctx),
            stake_type: type_name::get<StakeType>(),
            spool_id: object::id(spool),
            stakes: balance::zero(),
            points: 0,
            total_points: 0,
            index: spool::index(spool),
        }
    }

    public fun assert_pool_id<StakeType>(
        _spool: &Spool,
        _spool_account: &SpoolAccount<StakeType>,
    ) {
        abort 0
    }
}
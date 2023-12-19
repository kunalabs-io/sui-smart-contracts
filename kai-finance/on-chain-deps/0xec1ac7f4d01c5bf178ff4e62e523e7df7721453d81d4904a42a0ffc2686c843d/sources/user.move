module 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::user {

    use 0x1::type_name;
    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::rewards_pool;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool_account;

    struct CreateSpoolAccountEvent has copy, drop {
        spool_account_id: object::ID,
        spool_id: object::ID,
        staking_type: type_name::TypeName,
        created_at: u64,
    }
    struct SpoolAccountUnstakeEvent has copy, drop {
        spool_account_id: object::ID,
        spool_id: object::ID,
        staking_type: type_name::TypeName,
        unstake_amount: u64,
        remaining_amount: u64,
        timestamp: u64,
    }
    struct SpoolAccountStakeEvent has copy, drop {
        sender: address,
        spool_account_id: object::ID,
        spool_id: object::ID,
        staking_type: type_name::TypeName,
        stake_amount: u64,
        previous_amount: u64,
        timestamp: u64,
    }
    struct SpoolAccountRedeemRewardsEvent has copy, drop {
        sender: address,
        spool_account_id: object::ID,
        spool_id: object::ID,
        rewards_pool_id: object::ID,
        staking_type: type_name::TypeName,
        rewards_type: type_name::TypeName,
        redeemed_points: u64,
        previous_points: u64,
        rewards: u64,
        total_claimed_rewards: u64,
        total_user_points: u64,
        timestamp: u64,
    }
    struct SpoolAccountRedeemRewardsEventV2 has copy, drop {
        sender: address,
        spool_account_id: object::ID,
        spool_id: object::ID,
        rewards_pool_id: object::ID,
        staking_type: type_name::TypeName,
        rewards_type: type_name::TypeName,
        redeemed_points: u64,
        previous_points: u64,
        rewards_fee: u64,
        rewards: u64,
        total_claimed_rewards: u64,
        total_user_points: u64,
        timestamp: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun new_spool_account<T0>(a0: &mut spool::Spool, a1: &clock::Clock, a2: &mut tx_context::TxContext): spool_account::SpoolAccount<T0>;
    native public entry fun update_points<T0>(a0: &mut spool::Spool, a1: &mut spool_account::SpoolAccount<T0>, a2: &clock::Clock);
    native public entry fun stake<T0>(a0: &mut spool::Spool, a1: &mut spool_account::SpoolAccount<T0>, a2: coin::Coin<T0>, a3: &clock::Clock, a4: &tx_context::TxContext);
    native public fun unstake<T0>(a0: &mut spool::Spool, a1: &mut spool_account::SpoolAccount<T0>, a2: u64, a3: &clock::Clock, a4: &mut tx_context::TxContext): coin::Coin<T0>;
    native public fun redeem_rewards<T0, T1>(a0: &mut spool::Spool, a1: &mut rewards_pool::RewardsPool<T1>, a2: &mut spool_account::SpoolAccount<T0>, a3: &clock::Clock, a4: &mut tx_context::TxContext): coin::Coin<T1>;

}

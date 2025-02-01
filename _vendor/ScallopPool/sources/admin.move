module 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::admin {

    use 0x1::type_name;
    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::admin;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::rewards_pool;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool;

    struct AdminCap has store, key {
        id: object::UID,
    }
    struct CreateSpoolEvent has copy, drop {
        spool_id: object::ID,
        staking_type: type_name::TypeName,
        distributed_point_per_period: u64,
        point_distribution_time: u64,
        max_distributed_point: u64,
        max_stakes: u64,
        created_at: u64,
    }
    struct UpdateSpoolConfigEvent has copy, drop {
        spool_id: object::ID,
        distributed_point_per_period: u64,
        point_distribution_time: u64,
        max_distributed_point: u64,
        max_stakes: u64,
        updated_at: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun create_spool<T0>(a0: &admin::AdminCap, a1: u64, a2: u64, a3: u64, a4: u64, a5: &clock::Clock, a6: &mut tx_context::TxContext);
    native public entry fun update_spool_config(a0: &admin::AdminCap, a1: &mut spool::Spool, a2: u64, a3: u64, a4: u64, a5: u64, a6: &clock::Clock);
    native public entry fun create_rewards_pool<T0>(a0: &admin::AdminCap, a1: &spool::Spool, a2: u64, a3: u64, a4: &mut tx_context::TxContext);
    native public entry fun add_rewards<T0>(a0: &mut rewards_pool::RewardsPool<T0>, a1: coin::Coin<T0>);
    native public fun take_rewards<T0>(a0: &admin::AdminCap, a1: &mut rewards_pool::RewardsPool<T0>, a2: u64, a3: &mut tx_context::TxContext): coin::Coin<T0>;
    native public fun take_old_rewards<T0>(a0: &admin::AdminCap, a1: &mut rewards_pool::RewardsPool<T0>, a2: u64, a3: &mut tx_context::TxContext): coin::Coin<T0>;
    native public entry fun update_reward_fee_config<T0>(a0: &admin::AdminCap, a1: &mut rewards_pool::RewardsPool<T0>, a2: u64, a3: u64, a4: address);

}

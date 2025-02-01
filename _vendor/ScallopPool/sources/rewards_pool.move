module 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::rewards_pool {

    use sui::balance;
    use sui::object;
    use sui::tx_context;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::admin;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::rewards_pool;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool_account;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::user;

    friend admin;
    friend user;

    struct RewardsPool<phantom T0> has store, key {
        id: object::UID,
        spool_id: object::ID,
        exchange_rate_numerator: u64,
        exchange_rate_denominator: u64,
        rewards: balance::Balance<T0>,
        claimed_rewards: u64,
    }
    struct RewardsPoolFeeKey has copy, drop, store {
        dummy_field: bool,
    }
    struct RewardsPoolFee has store {
        fee_rate_numerator: u64,
        fee_rate_denominator: u64,
        recipient: address,
    }
    struct RewardsPoolRewardsBalanceKey has copy, drop, store {
        dummy_field: bool,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun claimed_rewards<T0>(a0: &rewards_pool::RewardsPool<T0>): u64;
    native public fun rewards<T0>(a0: &rewards_pool::RewardsPool<T0>): u64;
    native public(friend) fun new<T0>(a0: &spool::Spool, a1: u64, a2: u64, a3: &mut tx_context::TxContext): rewards_pool::RewardsPool<T0>;
    native public(friend) fun add_rewards<T0>(a0: &mut rewards_pool::RewardsPool<T0>, a1: balance::Balance<T0>);
    native public(friend) fun take_rewards<T0>(a0: &mut rewards_pool::RewardsPool<T0>, a1: u64): balance::Balance<T0>;
    native public(friend) fun take_old_rewards<T0>(a0: &mut rewards_pool::RewardsPool<T0>, a1: u64): balance::Balance<T0>;
    native public fun calculate_point_to_reward<T0>(a0: &rewards_pool::RewardsPool<T0>, a1: u64): u64;
    native public fun calculate_reward_to_point<T0>(a0: &rewards_pool::RewardsPool<T0>, a1: u64): u64;
    native public(friend) fun redeem_rewards<T0, T1>(a0: &mut rewards_pool::RewardsPool<T1>, a1: &mut spool_account::SpoolAccount<T0>): balance::Balance<T1>;
    native public fun assert_spool_id<T0>(a0: &rewards_pool::RewardsPool<T0>, a1: &spool::Spool);
    native public(friend) fun update_reward_fee<T0>(a0: &mut rewards_pool::RewardsPool<T0>, a1: u64, a2: u64, a3: address);
    native public fun reward_fee<T0>(a0: &rewards_pool::RewardsPool<T0>): (u64, u64);
    native public fun reward_fee_recipient<T0>(a0: &rewards_pool::RewardsPool<T0>): address;

}

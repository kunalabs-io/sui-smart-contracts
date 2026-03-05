module scallop_pool::spool_account {

    use 0x1::type_name;
    use sui::balance;
    use sui::clock;
    use sui::object;
    use sui::tx_context;
    use scallop_pool::admin;
    use scallop_pool::rewards_pool;
    use scallop_pool::spool;
    use scallop_pool::spool_account;
    use scallop_pool::user;

    friend admin;
    friend rewards_pool;
    friend user;

    struct SpoolAccount<phantom T0> has store, key {
        id: object::UID,
        spool_id: object::ID,
        stake_type: type_name::TypeName,
        stakes: balance::Balance<T0>,
        points: u64,
        total_points: u64,
        index: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun spool_id<T0>(a0: &spool_account::SpoolAccount<T0>): object::ID;
    native public fun stake_type<T0>(a0: &spool_account::SpoolAccount<T0>): type_name::TypeName;
    native public fun stake_amount<T0>(a0: &spool_account::SpoolAccount<T0>): u64;
    native public fun points<T0>(a0: &spool_account::SpoolAccount<T0>): u64;
    native public fun total_points<T0>(a0: &spool_account::SpoolAccount<T0>): u64;
    native public(friend) fun new<T0>(a0: &spool::Spool, a1: &mut tx_context::TxContext): spool_account::SpoolAccount<T0>;
    native public fun assert_pool_id<T0>(a0: &spool::Spool, a1: &spool_account::SpoolAccount<T0>);
    native public(friend) fun accrue_points<T0>(a0: &spool::Spool, a1: &mut spool_account::SpoolAccount<T0>, a2: &clock::Clock);
    native public(friend) fun stake<T0>(a0: &spool::Spool, a1: &mut spool_account::SpoolAccount<T0>, a2: balance::Balance<T0>);
    native public(friend) fun unstake<T0>(a0: &mut spool_account::SpoolAccount<T0>, a1: u64): balance::Balance<T0>;
    native public(friend) fun redeem_point<T0>(a0: &mut spool_account::SpoolAccount<T0>, a1: u64);

}

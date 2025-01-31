module 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool_account {

    use 0x1::type_name;
    use sui::balance;
    use sui::clock;
    use sui::object;
    use sui::tx_context;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::admin;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::rewards_pool;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool_account;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::user;

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
 #[native_interface]
    native public fun spool_id<T0>(a0: &spool_account::SpoolAccount<T0>): object::ID;
 #[native_interface]
    native public fun stake_type<T0>(a0: &spool_account::SpoolAccount<T0>): type_name::TypeName;
 #[native_interface]
    native public fun stake_amount<T0>(a0: &spool_account::SpoolAccount<T0>): u64;
 #[native_interface]
    native public fun points<T0>(a0: &spool_account::SpoolAccount<T0>): u64;
 #[native_interface]
    native public fun total_points<T0>(a0: &spool_account::SpoolAccount<T0>): u64;
 #[native_interface]
    native public(friend) fun new<T0>(a0: &spool::Spool, a1: &mut tx_context::TxContext): spool_account::SpoolAccount<T0>;
 #[native_interface]
    native public fun assert_pool_id<T0>(a0: &spool::Spool, a1: &spool_account::SpoolAccount<T0>);
 #[native_interface]
    native public(friend) fun accrue_points<T0>(a0: &spool::Spool, a1: &mut spool_account::SpoolAccount<T0>, a2: &clock::Clock);
 #[native_interface]
    native public(friend) fun stake<T0>(a0: &spool::Spool, a1: &mut spool_account::SpoolAccount<T0>, a2: balance::Balance<T0>);
 #[native_interface]
    native public(friend) fun unstake<T0>(a0: &mut spool_account::SpoolAccount<T0>, a1: u64): balance::Balance<T0>;
 #[native_interface]
    native public(friend) fun redeem_point<T0>(a0: &mut spool_account::SpoolAccount<T0>, a1: u64);

}

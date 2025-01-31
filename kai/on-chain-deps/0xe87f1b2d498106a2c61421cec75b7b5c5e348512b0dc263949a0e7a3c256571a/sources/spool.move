module 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool {

    use 0x1::type_name;
    use sui::clock;
    use sui::object;
    use sui::tx_context;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::admin;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool;
    use 0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::user;

    friend admin;
    friend user;

    struct Spool has store, key {
        id: object::UID,
        stake_type: type_name::TypeName,
        distributed_point_per_period: u64,
        point_distribution_time: u64,
        distributed_point: u64,
        max_distributed_point: u64,
        max_stakes: u64,
        index: u64,
        stakes: u64,
        last_update: u64,
        created_at: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun base_index_rate(): u64;
 #[native_interface]
    native public fun index(a0: &spool::Spool): u64;
 #[native_interface]
    native public fun stakes(a0: &spool::Spool): u64;
 #[native_interface]
    native public fun max_stakes(a0: &spool::Spool): u64;
 #[native_interface]
    native public fun last_update(a0: &spool::Spool): u64;
 #[native_interface]
    native public fun point_distribution_time(a0: &spool::Spool): u64;
 #[native_interface]
    native public fun stake_type(a0: &spool::Spool): type_name::TypeName;
 #[native_interface]
    native public(friend) fun new<T0>(a0: u64, a1: u64, a2: u64, a3: u64, a4: &clock::Clock, a5: &mut tx_context::TxContext): spool::Spool;
 #[native_interface]
    native public(friend) fun update_config(a0: &mut spool::Spool, a1: u64, a2: u64, a3: u64, a4: u64);
 #[native_interface]
    native public(friend) fun stake(a0: &mut spool::Spool, a1: u64);
 #[native_interface]
    native public(friend) fun unstake(a0: &mut spool::Spool, a1: u64);
 #[native_interface]
    native public fun is_points_up_to_date(a0: &spool::Spool, a1: &clock::Clock): bool;
 #[native_interface]
    native public(friend) fun accrue_points(a0: &mut spool::Spool, a1: &clock::Clock);

}

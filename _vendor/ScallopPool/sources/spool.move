module scallop_pool::spool {

    use 0x1::type_name;
    use sui::clock;
    use sui::object;
    use sui::tx_context;
    use scallop_pool::admin;
    use scallop_pool::spool;
    use scallop_pool::user;

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
    native public fun base_index_rate(): u64;
    native public fun index(a0: &spool::Spool): u64;
    native public fun stakes(a0: &spool::Spool): u64;
    native public fun max_stakes(a0: &spool::Spool): u64;
    native public fun last_update(a0: &spool::Spool): u64;
    native public fun point_distribution_time(a0: &spool::Spool): u64;
    native public fun stake_type(a0: &spool::Spool): type_name::TypeName;
    native public(friend) fun new<T0>(a0: u64, a1: u64, a2: u64, a3: u64, a4: &clock::Clock, a5: &mut tx_context::TxContext): spool::Spool;
    native public(friend) fun update_config(a0: &mut spool::Spool, a1: u64, a2: u64, a3: u64, a4: u64);
    native public(friend) fun stake(a0: &mut spool::Spool, a1: u64);
    native public(friend) fun unstake(a0: &mut spool::Spool, a1: u64);
    native public fun is_points_up_to_date(a0: &spool::Spool, a1: &clock::Clock): bool;
    native public(friend) fun accrue_points(a0: &mut spool::Spool, a1: &clock::Clock);

}

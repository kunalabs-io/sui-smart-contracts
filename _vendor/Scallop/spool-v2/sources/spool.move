module spool::spool {
    use sui::object::UID;
    use std::type_name::TypeName;
    // use std::fixed_point32;

    friend spool::admin;
    friend spool::user;

    struct Spool has key, store {
        id: UID,
        stake_type: TypeName,
        /// points that will be distribute on every period
        distributed_point_per_period: u64,
        /// what is the duration before the point distribute for the next time
        point_distribution_time: u64,
        /// distributed reward that is already belong to users
        distributed_point: u64,
        /// maximum point that can be generated and distributed
        max_distributed_point: u64,
        max_stakes: u64,
        index: u64,
        stakes: u64,
        last_update: u64,
        created_at: u64,
    }

    const BaseIndexRate: u64 = 1_000_000_000;
    public fun base_index_rate(): u64 { BaseIndexRate }

    public fun index(spool: &Spool): u64 { spool.index }
    public fun stakes(spool: &Spool): u64 { spool.stakes }
    public fun max_stakes(spool: &Spool): u64 { spool.max_stakes }
    public fun last_update(spool: &Spool): u64 { spool.last_update }
    public fun point_distribution_time(spool: &Spool): u64 { spool.point_distribution_time }
    public fun stake_type(spool: &Spool): TypeName { spool.stake_type }
}
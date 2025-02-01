module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool_manager {

    use 0x1::type_name;
    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::table;
    use sui::tx_context;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::admin_cap;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool_manager;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::versioned;

    struct PoolDfKey has copy, drop, store {
        coin_type_x: type_name::TypeName,
        coin_type_y: type_name::TypeName,
        fee_rate: u64,
    }
    struct PoolRegistry has store, key {
        id: object::UID,
        fee_amount_tick_spacing: table::Table<u64, u32>,
        num_pools: u64,
    }
    struct PoolCreated has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        coin_type_x: type_name::TypeName,
        coin_type_y: type_name::TypeName,
        fee_rate: u64,
        tick_spacing: u32,
    }
    struct FeeRateEnabled has copy, drop, store {
        sender: address,
        fee_rate: u64,
        tick_spacing: u32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun check_exists<T0, T1>(a0: &pool_manager::PoolRegistry, a1: u64);
 #[native_interface]
    native public fun borrow_pool<T0, T1>(a0: &pool_manager::PoolRegistry, a1: u64): &pool::Pool<T0, T1>;
 #[native_interface]
    native public fun borrow_mut_pool<T0, T1>(a0: &mut pool_manager::PoolRegistry, a1: u64): &mut pool::Pool<T0, T1>;
 #[native_interface]
    native public fun create_pool<T0, T1>(a0: &mut pool_manager::PoolRegistry, a1: u64, a2: &versioned::Versioned, a3: &mut tx_context::TxContext);
 #[native_interface]
    native public fun create_and_initialize_pool<T0, T1>(a0: &mut pool_manager::PoolRegistry, a1: u64, a2: u128, a3: &versioned::Versioned, a4: &clock::Clock, a5: &mut tx_context::TxContext);
 #[native_interface]
    native public fun enable_fee_rate(a0: &admin_cap::AdminCap, a1: &mut pool_manager::PoolRegistry, a2: u64, a3: u32, a4: &versioned::Versioned, a5: &tx_context::TxContext);
 #[native_interface]
    native public fun set_protocol_fee_rate<T0, T1>(a0: &admin_cap::AdminCap, a1: &mut pool_manager::PoolRegistry, a2: u64, a3: u64, a4: u64, a5: &versioned::Versioned, a6: &mut tx_context::TxContext);
 #[native_interface]
    native public fun collect_protocol_fee<T0, T1>(a0: &admin_cap::AdminCap, a1: &mut pool_manager::PoolRegistry, a2: u64, a3: u64, a4: u64, a5: &versioned::Versioned, a6: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T1>);
 #[native_interface]
    native public fun initialize_pool_reward<T0, T1, T2>(a0: &admin_cap::AdminCap, a1: &mut pool_manager::PoolRegistry, a2: u64, a3: u64, a4: u64, a5: coin::Coin<T2>, a6: &versioned::Versioned, a7: &clock::Clock, a8: &tx_context::TxContext);
 #[native_interface]
    native public fun increase_pool_reward<T0, T1, T2>(a0: &admin_cap::AdminCap, a1: &mut pool_manager::PoolRegistry, a2: u64, a3: coin::Coin<T2>, a4: &versioned::Versioned, a5: &clock::Clock, a6: &tx_context::TxContext);
 #[native_interface]
    native public fun extend_pool_reward_timestamp<T0, T1, T2>(a0: &admin_cap::AdminCap, a1: &mut pool_manager::PoolRegistry, a2: u64, a3: u64, a4: &versioned::Versioned, a5: &clock::Clock, a6: &tx_context::TxContext);

}

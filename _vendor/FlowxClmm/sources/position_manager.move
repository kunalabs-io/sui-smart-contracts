module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::position_manager {

    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i32;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool_manager;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::position;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::position_manager;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::versioned;

    struct PositionRegistry has store, key {
        id: object::UID,
        num_positions: u64,
    }
    struct Open has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        position_id: object::ID,
        tick_lower_index: i32::I32,
        tick_upper_index: i32::I32,
    }
    struct Close has copy, drop, store {
        sender: address,
        position_id: object::ID,
    }
    struct IncreaseLiquidity has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        position_id: object::ID,
        liquidity: u128,
        amount_x: u64,
        amount_y: u64,
    }
    struct DecreaseLiquidity has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        position_id: object::ID,
        liquidity: u128,
        amount_x: u64,
        amount_y: u64,
    }
    struct Collect has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        position_id: object::ID,
        amount_x: u64,
        amount_y: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun open_position<T0, T1>(a0: &mut position_manager::PositionRegistry, a1: &pool_manager::PoolRegistry, a2: u64, a3: i32::I32, a4: i32::I32, a5: &versioned::Versioned, a6: &mut tx_context::TxContext): position::Position;
 #[native_interface]
    native public fun close_position(a0: &mut position_manager::PositionRegistry, a1: position::Position, a2: &versioned::Versioned, a3: &tx_context::TxContext);
 #[native_interface]
    native public fun increase_liquidity<T0, T1>(a0: &mut pool_manager::PoolRegistry, a1: &mut position::Position, a2: coin::Coin<T0>, a3: coin::Coin<T1>, a4: u64, a5: u64, a6: u64, a7: &versioned::Versioned, a8: &clock::Clock, a9: &mut tx_context::TxContext);
 #[native_interface]
    native public fun decrease_liquidity<T0, T1>(a0: &mut pool_manager::PoolRegistry, a1: &mut position::Position, a2: u128, a3: u64, a4: u64, a5: u64, a6: &versioned::Versioned, a7: &clock::Clock, a8: &tx_context::TxContext);
 #[native_interface]
    native public fun collect<T0, T1>(a0: &mut pool_manager::PoolRegistry, a1: &mut position::Position, a2: u64, a3: u64, a4: &versioned::Versioned, a5: &clock::Clock, a6: &mut tx_context::TxContext): (coin::Coin<T0>, coin::Coin<T1>);
 #[native_interface]
    native public fun collect_pool_reward<T0, T1, T2>(a0: &mut pool_manager::PoolRegistry, a1: &mut position::Position, a2: u64, a3: &versioned::Versioned, a4: &clock::Clock, a5: &mut tx_context::TxContext): coin::Coin<T2>;

}

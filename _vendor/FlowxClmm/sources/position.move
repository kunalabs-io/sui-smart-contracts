module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::position {

    use 0x1::type_name;
    use sui::object;
    use sui::tx_context;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i128;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i32;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::position;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::position_manager;

    friend pool;
    friend position_manager;

    struct POSITION has drop {
        dummy_field: bool,
    }
    struct Position has store, key {
        id: object::UID,
        pool_id: object::ID,
        fee_rate: u64,
        coin_type_x: type_name::TypeName,
        coin_type_y: type_name::TypeName,
        tick_lower_index: i32::I32,
        tick_upper_index: i32::I32,
        liquidity: u128,
        fee_growth_inside_x_last: u128,
        fee_growth_inside_y_last: u128,
        coins_owed_x: u64,
        coins_owed_y: u64,
        reward_infos: vector<position::PositionRewardInfo>,
    }
    struct PositionRewardInfo has copy, drop, store {
        reward_growth_inside_last: u128,
        coins_owed_reward: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun pool_id(a0: &position::Position): object::ID;
 #[native_interface]
    native public fun fee_rate(a0: &position::Position): u64;
 #[native_interface]
    native public fun liquidity(a0: &position::Position): u128;
 #[native_interface]
    native public fun tick_lower_index(a0: &position::Position): i32::I32;
 #[native_interface]
    native public fun tick_upper_index(a0: &position::Position): i32::I32;
 #[native_interface]
    native public fun coins_owed_x(a0: &position::Position): u64;
 #[native_interface]
    native public fun coins_owed_y(a0: &position::Position): u64;
 #[native_interface]
    native public fun fee_growth_inside_x_last(a0: &position::Position): u128;
 #[native_interface]
    native public fun fee_growth_inside_y_last(a0: &position::Position): u128;
 #[native_interface]
    native public fun reward_length(a0: &position::Position): u64;
 #[native_interface]
    native public fun reward_growth_inside_last(a0: &position::Position, a1: u64): u128;
 #[native_interface]
    native public fun coins_owed_reward(a0: &position::Position, a1: u64): u64;
 #[native_interface]
    native public fun is_empty(a0: &position::Position): bool;
 #[native_interface]
    native public(friend) fun open(a0: object::ID, a1: u64, a2: type_name::TypeName, a3: type_name::TypeName, a4: i32::I32, a5: i32::I32, a6: &mut tx_context::TxContext): position::Position;
 #[native_interface]
    native public(friend) fun close(a0: position::Position);
 #[native_interface]
    native public(friend) fun increase_debt(a0: &mut position::Position, a1: u64, a2: u64);
 #[native_interface]
    native public(friend) fun decrease_debt(a0: &mut position::Position, a1: u64, a2: u64);
 #[native_interface]
    native public(friend) fun decrease_reward_debt(a0: &mut position::Position, a1: u64, a2: u64);
 #[native_interface]
    native public(friend) fun update(a0: &mut position::Position, a1: i128::I128, a2: u128, a3: u128, a4: vector<u128>);

}

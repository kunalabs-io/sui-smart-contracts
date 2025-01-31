module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::tick {

    use sui::table;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i128;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i32;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i64;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::tick;

    friend pool;

    struct TickInfo has copy, drop, store {
        liquidity_gross: u128,
        liquidity_net: i128::I128,
        fee_growth_outside_x: u128,
        fee_growth_outside_y: u128,
        reward_growths_outside: vector<u128>,
        tick_cumulative_out_side: i64::I64,
        seconds_per_liquidity_out_side: u256,
        seconds_out_side: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun check_ticks(a0: i32::I32, a1: i32::I32, a2: u32);
 #[native_interface]
    native public fun is_initialized(a0: &table::Table<i32::I32, tick::TickInfo>, a1: i32::I32): bool;
 #[native_interface]
    native public fun get_fee_and_reward_growths_outside(a0: &table::Table<i32::I32, tick::TickInfo>, a1: i32::I32): (u128, u128, vector<u128>);
 #[native_interface]
    native public fun get_liquidity_gross(a0: &table::Table<i32::I32, tick::TickInfo>, a1: i32::I32): u128;
 #[native_interface]
    native public fun get_liquidity_net(a0: &table::Table<i32::I32, tick::TickInfo>, a1: i32::I32): i128::I128;
 #[native_interface]
    native public fun get_tick_cumulative_out_side(a0: &table::Table<i32::I32, tick::TickInfo>, a1: i32::I32): i64::I64;
 #[native_interface]
    native public fun get_seconds_per_liquidity_out_side(a0: &table::Table<i32::I32, tick::TickInfo>, a1: i32::I32): u256;
 #[native_interface]
    native public fun get_seconds_out_side(a0: &table::Table<i32::I32, tick::TickInfo>, a1: i32::I32): u64;
 #[native_interface]
    native public fun tick_spacing_to_max_liquidity_per_tick(a0: u32): u128;
 #[native_interface]
    native public fun get_fee_and_reward_growths_inside(a0: &table::Table<i32::I32, tick::TickInfo>, a1: i32::I32, a2: i32::I32, a3: i32::I32, a4: u128, a5: u128, a6: vector<u128>): (u128, u128, vector<u128>);
 #[native_interface]
    native public(friend) fun update(a0: &mut table::Table<i32::I32, tick::TickInfo>, a1: i32::I32, a2: i32::I32, a3: i128::I128, a4: u128, a5: u128, a6: vector<u128>, a7: u256, a8: i64::I64, a9: u64, a10: bool, a11: u128): bool;
 #[native_interface]
    native public(friend) fun clear(a0: &mut table::Table<i32::I32, tick::TickInfo>, a1: i32::I32);
 #[native_interface]
    native public(friend) fun cross(a0: &mut table::Table<i32::I32, tick::TickInfo>, a1: i32::I32, a2: u128, a3: u128, a4: vector<u128>, a5: u256, a6: i64::I64, a7: u64): i128::I128;

}

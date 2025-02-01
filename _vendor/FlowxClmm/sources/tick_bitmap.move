module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::tick_bitmap {

    use sui::table;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i32;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool;

    friend pool;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun flip_tick(a0: &mut table::Table<i32::I32, u256>, a1: i32::I32, a2: u32);
 #[native_interface]
    native public fun next_initialized_tick_within_one_word(a0: &table::Table<i32::I32, u256>, a1: i32::I32, a2: u32, a3: bool): (i32::I32, bool);

}

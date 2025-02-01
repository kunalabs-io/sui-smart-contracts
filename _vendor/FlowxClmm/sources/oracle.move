module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::oracle {

    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i32;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i64;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::oracle;

    struct Observation has copy, drop, store {
        timestamp_s: u64,
        tick_cumulative: i64::I64,
        seconds_per_liquidity_cumulative: u256,
        initialized: bool,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun timestamp_s(a0: &oracle::Observation): u64;
 #[native_interface]
    native public fun tick_cumulative(a0: &oracle::Observation): i64::I64;
 #[native_interface]
    native public fun seconds_per_liquidity_cumulative(a0: &oracle::Observation): u256;
 #[native_interface]
    native public fun is_initialized(a0: &oracle::Observation): bool;
 #[native_interface]
    native public fun transform(a0: &oracle::Observation, a1: u64, a2: i32::I32, a3: u128): oracle::Observation;
 #[native_interface]
    native public fun initialize(a0: &mut vector<oracle::Observation>, a1: u64): (u64, u64);
 #[native_interface]
    native public fun write(a0: &mut vector<oracle::Observation>, a1: u64, a2: u64, a3: i32::I32, a4: u128, a5: u64, a6: u64): (u64, u64);
 #[native_interface]
    native public fun grow(a0: &mut vector<oracle::Observation>, a1: u64, a2: u64): u64;
 #[native_interface]
    native public fun binary_search(a0: &vector<oracle::Observation>, a1: u64, a2: u64, a3: u64): (oracle::Observation, oracle::Observation);
 #[native_interface]
    native public fun get_surrounding_observations(a0: &vector<oracle::Observation>, a1: u64, a2: i32::I32, a3: u64, a4: u128, a5: u64): (oracle::Observation, oracle::Observation);
 #[native_interface]
    native public fun observe_single(a0: &vector<oracle::Observation>, a1: u64, a2: u64, a3: i32::I32, a4: u64, a5: u128, a6: u64): (i64::I64, u256);
 #[native_interface]
    native public fun observe(a0: &vector<oracle::Observation>, a1: u64, a2: vector<u64>, a3: i32::I32, a4: u64, a5: u128, a6: u64): (vector<i64::I64>, vector<u256>);

}

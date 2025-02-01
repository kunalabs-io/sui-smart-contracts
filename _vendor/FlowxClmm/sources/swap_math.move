module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::swap_math {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun compute_swap_step(a0: u128, a1: u128, a2: u128, a3: u64, a4: u64, a5: bool): (u128, u64, u64, u64);

}

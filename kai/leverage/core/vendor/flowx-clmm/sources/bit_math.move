module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::bit_math {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun get_most_significant_bit(a0: u256): u8;
 #[native_interface]
    native public fun get_least_significant_bit(a0: u256): u8;

}

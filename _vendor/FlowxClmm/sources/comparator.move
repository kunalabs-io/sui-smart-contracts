module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::comparator {

    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::comparator;

    struct Result has drop {
        inner: u8,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun is_equal(a0: &comparator::Result): bool;
 #[native_interface]
    native public fun is_smaller_than(a0: &comparator::Result): bool;
 #[native_interface]
    native public fun is_greater_than(a0: &comparator::Result): bool;
 #[native_interface]
    native public fun compare<T0>(a0: &T0, a1: &T0): comparator::Result;
 #[native_interface]
    native public fun compare_u8_vector(a0: vector<u8>, a1: vector<u8>): comparator::Result;

}

module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::cursor {

    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::cursor;

    struct Cursor<T0> {
        data: vector<T0>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new<T0>(a0: vector<T0>): cursor::Cursor<T0>;
 #[native_interface]
    native public fun data<T0>(a0: &cursor::Cursor<T0>): &vector<T0>;
 #[native_interface]
    native public fun is_empty<T0>(a0: &cursor::Cursor<T0>): bool;
 #[native_interface]
    native public fun destroy_empty<T0>(a0: cursor::Cursor<T0>);
 #[native_interface]
    native public fun take_rest<T0>(a0: cursor::Cursor<T0>): vector<T0>;
 #[native_interface]
    native public fun poke<T0>(a0: &mut cursor::Cursor<T0>): T0;

}

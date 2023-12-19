module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::version_control {

    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::version_control;

    friend state;

    struct V__0_2_0 has copy, drop, store {
        dummy_field: bool,
    }
    struct V__DUMMY has copy, drop, store {
        dummy_field: bool,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public(friend) fun current_version(): version_control::V__0_2_0;
 #[native_interface]
    native public(friend) fun previous_version(): version_control::V__DUMMY;

}

module token_bridge::version_control {

    use token_bridge::state;
    use token_bridge::version_control;

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

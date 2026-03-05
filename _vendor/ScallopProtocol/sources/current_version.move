module scallop_protocol::current_version {

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun current_version(): u64;

}

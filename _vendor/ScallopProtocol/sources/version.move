module scallop_protocol::version {

    use sui::object;
    use scallop_protocol::version;

    struct Version has store, key {
        id: object::UID,
        value: u64,
    }
    struct VersionCap has store, key {
        id: object::UID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun value(a0: &version::Version): u64;
 #[native_interface]
    native public fun upgrade(a0: &mut version::Version, a1: &version::VersionCap);
 #[native_interface]
    native public fun is_current_version(a0: &version::Version): bool;
 #[native_interface]
    native public fun assert_current_version(a0: &version::Version);

}

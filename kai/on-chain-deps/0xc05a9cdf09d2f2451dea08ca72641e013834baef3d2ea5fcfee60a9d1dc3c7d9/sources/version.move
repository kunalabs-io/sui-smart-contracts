module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version {

    use sui::object;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

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

module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::package_utils {

    use 0x1::type_name;
    use sui::object;
    use sui::package;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;

    struct CurrentVersion has copy, drop, store {
        dummy_field: bool,
    }
    struct CurrentPackage has copy, drop, store {
        dummy_field: bool,
    }
    struct PendingPackage has copy, drop, store {
        dummy_field: bool,
    }
    struct PackageInfo has copy, drop, store {
        package: object::ID,
        digest: bytes32::Bytes32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun current_package(a0: &object::UID): object::ID;
 #[native_interface]
    native public fun current_digest(a0: &object::UID): bytes32::Bytes32;
 #[native_interface]
    native public fun committed_package(a0: &object::UID): object::ID;
 #[native_interface]
    native public fun authorized_digest(a0: &object::UID): bytes32::Bytes32;
 #[native_interface]
    native public fun assert_package_upgrade_cap<T0>(a0: &package::UpgradeCap, a1: u8, a2: u64);
 #[native_interface]
    native public fun assert_version<T0: drop+ store>(a0: &object::UID, a1: T0);
 #[native_interface]
    native public fun type_of_version<T0: drop>(a0: T0): type_name::TypeName;
 #[native_interface]
    native public fun init_package_info<T0: store>(a0: &mut object::UID, a1: T0, a2: &package::UpgradeCap);
 #[native_interface]
    native public fun migrate_version<T0: drop+ store, T1: drop+ store>(a0: &mut object::UID, a1: T0, a2: T1);
 #[native_interface]
    native public fun authorize_upgrade(a0: &mut object::UID, a1: &mut package::UpgradeCap, a2: bytes32::Bytes32): package::UpgradeTicket;
 #[native_interface]
    native public fun commit_upgrade(a0: &mut object::UID, a1: &mut package::UpgradeCap, a2: package::UpgradeReceipt): (object::ID, object::ID);

}

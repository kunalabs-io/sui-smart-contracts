module 0x1318FDC90319EC9C24DF1456D960A447521B0A658316155895014A6E39B5482F::whitelist {

    use sui::object;

    struct WhitelistKey has copy, drop, store {
        address: address,
    }
    struct AllowAllKey has copy, drop, store {
        dummy_field: bool,
    }
    struct RejectAllKey has copy, drop, store {
        dummy_field: bool,
    }
    struct WhitelistAddEvent has copy, drop {
        id: object::ID,
        address: address,
    }
    struct WhitelistRemoveEvent has copy, drop {
        id: object::ID,
        address: address,
    }
    struct AllowAllEvent has copy, drop {
        id: object::ID,
    }
    struct RejectAllEvent has copy, drop {
        id: object::ID,
    }
    struct SwitchToWhitelistModeEvent has copy, drop {
        id: object::ID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun add_whitelist_address(a0: &mut object::UID, a1: address);
 #[native_interface]
    native public fun remove_whitelist_address(a0: &mut object::UID, a1: address);
 #[native_interface]
    native public fun allow_all(a0: &mut object::UID);
 #[native_interface]
    native public fun is_allow_all(a0: &object::UID): bool;
 #[native_interface]
    native public fun reject_all(a0: &mut object::UID);
 #[native_interface]
    native public fun is_reject_all(a0: &object::UID): bool;
 #[native_interface]
    native public fun switch_to_whitelist_mode(a0: &mut object::UID);
 #[native_interface]
    native public fun in_whitelist(a0: &object::UID, a1: address): bool;
 #[native_interface]
    native public fun is_address_allowed(a0: &object::UID, a1: address): bool;

}

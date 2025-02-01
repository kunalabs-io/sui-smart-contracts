module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::versioned {

    use sui::object;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::admin_cap;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool_manager;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::position_manager;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::versioned;

    friend pool;
    friend pool_manager;
    friend position_manager;

    struct Versioned has store, key {
        id: object::UID,
        version: u64,
    }
    struct Upgraded has copy, drop, store {
        previous_version: u64,
        new_version: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun check_version(a0: &versioned::Versioned);
 #[native_interface]
    native public fun upgrade(a0: &admin_cap::AdminCap, a1: &mut versioned::Versioned);

}

module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::admin_cap {

    use sui::object;

    struct AdminCap has store, key {
        id: object::UID,
    }

}

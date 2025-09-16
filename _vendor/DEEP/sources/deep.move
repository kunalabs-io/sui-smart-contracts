module 0xDEEB7A4662EEC9F2F3DEF03FB937A663DDDAA2E215B8078A284D026B7946C270::deep {

    use sui::coin;
    use sui::object;
    use 0xDEEB7A4662EEC9F2F3DEF03FB937A663DDDAA2E215B8078A284D026B7946C270::deep;

    struct DEEP has drop {
        dummy_field: bool,
    }
    struct ProtectedTreasury has key {
        id: object::UID,
    }
    struct TreasuryCapKey has copy, drop, store {
        dummy_field: bool,
    }

}

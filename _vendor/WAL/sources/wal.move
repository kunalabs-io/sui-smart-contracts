module 0x356A26EB9E012A68958082340D4C4116E7F55615CF27AFFCFF209CF0AE544F59::wal {

    use sui::coin;
    use sui::object;
    use 0x356A26EB9E012A68958082340D4C4116E7F55615CF27AFFCFF209CF0AE544F59::wal;

    struct WAL has drop {
        dummy_field: bool,
    }
    struct ProtectedTreasury has key {
        id: object::UID,
    }
    struct TreasuryCapKey has copy, drop, store {
        dummy_field: bool,
    }

}

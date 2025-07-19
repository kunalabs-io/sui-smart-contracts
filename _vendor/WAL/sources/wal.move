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

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun total_supply(a0: &wal::ProtectedTreasury): u64;
 #[native_interface]
    native public fun burn(a0: &mut wal::ProtectedTreasury, a1: coin::Coin<wal::WAL>);

}

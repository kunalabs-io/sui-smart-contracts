module deep::deep;

public struct DEEP has drop {}

public struct ProtectedTreasury has key {
    id: object::UID,
}

public struct TreasuryCapKey has copy, drop, store {}

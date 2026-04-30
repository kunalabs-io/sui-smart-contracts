module wal::wal;

public struct WAL has drop {}

public struct ProtectedTreasury has key {
    id: object::UID,
}

public struct TreasuryCapKey has copy, drop, store {}

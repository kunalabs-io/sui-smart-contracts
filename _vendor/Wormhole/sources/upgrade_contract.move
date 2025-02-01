module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::upgrade_contract {

    use sui::object;
    use sui::package;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::bytes32;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::migrate;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::upgrade_contract;

    friend migrate;

    struct GovernanceWitness has drop {
        dummy_field: bool,
    }
    struct ContractUpgraded has copy, drop {
        old_contract: object::ID,
        new_contract: object::ID,
    }
    struct UpgradeContract {
        digest: bytes32::Bytes32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun authorize_governance(a0: &state::State): governance_message::DecreeTicket<upgrade_contract::GovernanceWitness>;
 #[native_interface]
    native public fun authorize_upgrade(a0: &mut state::State, a1: governance_message::DecreeReceipt<upgrade_contract::GovernanceWitness>): package::UpgradeTicket;
 #[native_interface]
    native public fun commit_upgrade(a0: &mut state::State, a1: package::UpgradeReceipt);
 #[native_interface]
    native public(friend) fun take_digest(a0: vector<u8>): bytes32::Bytes32;

}

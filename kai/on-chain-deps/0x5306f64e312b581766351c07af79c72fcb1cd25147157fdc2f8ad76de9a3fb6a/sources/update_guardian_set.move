module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::update_guardian_set {

    use sui::clock;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::update_guardian_set;

    struct GovernanceWitness has drop {
        dummy_field: bool,
    }
    struct GuardianSetAdded has copy, drop {
        new_index: u32,
    }
    struct UpdateGuardianSet {
        new_index: u32,
        guardians: vector<guardian::Guardian>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun authorize_governance(a0: &state::State): governance_message::DecreeTicket<update_guardian_set::GovernanceWitness>;
 #[native_interface]
    native public fun update_guardian_set(a0: &mut state::State, a1: governance_message::DecreeReceipt<update_guardian_set::GovernanceWitness>, a2: &clock::Clock): u32;

}

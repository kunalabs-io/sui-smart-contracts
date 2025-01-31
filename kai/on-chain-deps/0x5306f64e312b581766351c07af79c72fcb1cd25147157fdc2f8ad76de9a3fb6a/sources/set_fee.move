module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::set_fee {

    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::set_fee;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;

    struct GovernanceWitness has drop {
        dummy_field: bool,
    }
    struct SetFee {
        amount: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun authorize_governance(a0: &state::State): governance_message::DecreeTicket<set_fee::GovernanceWitness>;
 #[native_interface]
    native public fun set_fee(a0: &mut state::State, a1: governance_message::DecreeReceipt<set_fee::GovernanceWitness>): u64;

}

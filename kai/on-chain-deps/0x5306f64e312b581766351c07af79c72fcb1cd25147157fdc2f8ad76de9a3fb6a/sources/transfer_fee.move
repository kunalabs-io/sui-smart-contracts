module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::transfer_fee {

    use sui::tx_context;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::transfer_fee;

    struct GovernanceWitness has drop {
        dummy_field: bool,
    }
    struct TransferFee {
        amount: u64,
        recipient: address,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun authorize_governance(a0: &state::State): governance_message::DecreeTicket<transfer_fee::GovernanceWitness>;
 #[native_interface]
    native public fun transfer_fee(a0: &mut state::State, a1: governance_message::DecreeReceipt<transfer_fee::GovernanceWitness>, a2: &mut tx_context::TxContext): u64;

}

module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::register_chain {

    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::register_chain;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::state;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::external_address;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message;

    struct GovernanceWitness has drop {
        dummy_field: bool,
    }
    struct RegisterChain {
        chain: u16,
        contract_address: external_address::ExternalAddress,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun authorize_governance(a0: &state::State): governance_message::DecreeTicket<register_chain::GovernanceWitness>;
 #[native_interface]
    native public fun register_chain(a0: &mut state::State, a1: governance_message::DecreeReceipt<register_chain::GovernanceWitness>): (u16, external_address::ExternalAddress);

}

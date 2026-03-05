module token_bridge::migrate {

    use sui::object;
    use token_bridge::state;
    use token_bridge::upgrade_contract;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::governance_message;

    struct MigrateComplete has copy, drop {
        package: object::ID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun migrate(a0: &mut state::State, a1: governance_message::DecreeReceipt<upgrade_contract::GovernanceWitness>);

}

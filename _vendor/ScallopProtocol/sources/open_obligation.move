module scallop_protocol::open_obligation {

    use sui::object;
    use sui::tx_context;
    use scallop_protocol::obligation;
    use scallop_protocol::open_obligation;
    use scallop_protocol::version;

    struct ObligationHotPotato {
        obligation_id: object::ID,
    }
    struct ObligationCreatedEvent has copy, drop {
        sender: address,
        obligation: object::ID,
        obligation_key: object::ID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public entry fun open_obligation_entry(a0: &version::Version, a1: &mut tx_context::TxContext);
 #[native_interface]
    native public fun open_obligation(a0: &version::Version, a1: &mut tx_context::TxContext): (obligation::Obligation, obligation::ObligationKey, open_obligation::ObligationHotPotato);
 #[native_interface]
    native public fun return_obligation(a0: &version::Version, a1: obligation::Obligation, a2: open_obligation::ObligationHotPotato);

}

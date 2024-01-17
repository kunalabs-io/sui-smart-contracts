module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::open_obligation {

    use sui::object;
    use sui::tx_context;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::open_obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

    struct ObligationHotPotato {
        obligation_id: object::ID,
    }
    struct ObligationCreatedEvent has copy, drop {
        sender: address,
        obligation: object::ID,
        obligation_key: object::ID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun open_obligation_entry(a0: &version::Version, a1: &mut tx_context::TxContext);
    native public fun open_obligation(a0: &version::Version, a1: &mut tx_context::TxContext): (obligation::Obligation, obligation::ObligationKey, open_obligation::ObligationHotPotato);
    native public fun return_obligation(a0: &version::Version, a1: obligation::Obligation, a2: open_obligation::ObligationHotPotato);

}

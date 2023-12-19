module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::emitter {

    use sui::object;
    use sui::tx_context;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::emitter;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::publish_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;

    friend publish_message;

    struct EmitterCreated has copy, drop {
        emitter_cap: object::ID,
    }
    struct EmitterDestroyed has copy, drop {
        emitter_cap: object::ID,
    }
    struct EmitterCap has store, key {
        id: object::UID,
        sequence: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: &state::State, a1: &mut tx_context::TxContext): emitter::EmitterCap;
 #[native_interface]
    native public fun sequence(a0: &emitter::EmitterCap): u64;
 #[native_interface]
    native public(friend) fun use_sequence(a0: &mut emitter::EmitterCap): u64;
 #[native_interface]
    native public fun destroy(a0: &state::State, a1: emitter::EmitterCap);

}

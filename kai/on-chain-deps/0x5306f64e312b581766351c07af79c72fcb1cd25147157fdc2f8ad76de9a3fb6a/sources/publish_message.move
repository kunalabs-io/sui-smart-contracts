module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::publish_message {

    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::sui;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::emitter;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::publish_message;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;

    struct WormholeMessage has copy, drop {
        sender: object::ID,
        sequence: u64,
        nonce: u32,
        payload: vector<u8>,
        consistency_level: u8,
        timestamp: u64,
    }
    struct MessageTicket {
        sender: object::ID,
        sequence: u64,
        nonce: u32,
        payload: vector<u8>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun prepare_message(a0: &mut emitter::EmitterCap, a1: u32, a2: vector<u8>): publish_message::MessageTicket;
 #[native_interface]
    native public fun publish_message(a0: &mut state::State, a1: coin::Coin<sui::SUI>, a2: publish_message::MessageTicket, a3: &clock::Clock): u64;

}

module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::migrate {

    use sui::clock;
    use sui::object;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;

    struct MigrateComplete has copy, drop {
        package: object::ID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun migrate(a0: &mut state::State, a1: vector<u8>, a2: &clock::Clock);

}

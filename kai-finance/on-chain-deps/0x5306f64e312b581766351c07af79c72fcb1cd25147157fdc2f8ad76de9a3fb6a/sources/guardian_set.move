module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian_set {

    use sui::clock;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::guardian_set;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::state;

    friend state;

    struct GuardianSet has store {
        index: u32,
        guardians: vector<guardian::Guardian>,
        expiration_timestamp_ms: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: u32, a1: vector<guardian::Guardian>): guardian_set::GuardianSet;
 #[native_interface]
    native public fun index(a0: &guardian_set::GuardianSet): u32;
 #[native_interface]
    native public fun index_as_u64(a0: &guardian_set::GuardianSet): u64;
 #[native_interface]
    native public fun guardians(a0: &guardian_set::GuardianSet): &vector<guardian::Guardian>;
 #[native_interface]
    native public fun guardian_at(a0: &guardian_set::GuardianSet, a1: u64): &guardian::Guardian;
 #[native_interface]
    native public fun expiration_timestamp_ms(a0: &guardian_set::GuardianSet): u64;
 #[native_interface]
    native public fun is_active(a0: &guardian_set::GuardianSet, a1: &clock::Clock): bool;
 #[native_interface]
    native public fun num_guardians(a0: &guardian_set::GuardianSet): u64;
 #[native_interface]
    native public fun quorum(a0: &guardian_set::GuardianSet): u64;
 #[native_interface]
    native public(friend) fun set_expiration(a0: &mut guardian_set::GuardianSet, a1: u32, a2: &clock::Clock);

}

module move_stl::random {

    public struct Random has drop, store, copy {
        seed: u64
    }

    public fun new(seed: u64): Random {
        Random {
            seed
        }
    }

    public fun seed(r: &mut Random, seed: u64) {
        r.seed = ((((r.seed as u128) + (seed as u128) & 0x0000000000000000ffffffffffffffff)) as u64)
    }

    public fun rand_n(r: &mut Random, n: u64): u64 {
        r.rand() % n
    }

    public fun rand(r: &mut Random): u64 {
        r.seed = ((((9223372036854775783u128 * ((r.seed as u128)) + 999983) >> 1) & 0x0000000000000000ffffffffffffffff) as u64);
        r.seed
    }

    public fun seed_rand(r: &mut Random, seed: u64): u64 {
        r.seed(seed);
        r.rand()
    }
}

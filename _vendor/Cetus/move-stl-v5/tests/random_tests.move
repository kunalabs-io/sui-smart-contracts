#[test_only]
module move_stl::random_tests {
    use move_stl::random::{new, rand_n, rand, seed_rand};
    use std::unit_test::assert_eq;
    use sui::vec_map;

    #[test]
    fun test_new() {
        let mut random = new(0);
        assert_eq!(random.rand(), 499991);
        assert_eq!(random.rand(), 13835058055276413816);
        assert_eq!(random.rand(), 11529215046140843451);
    }

    #[test]
    fun test_seed() {
        let mut random = new(0);
        random.seed(998);
        assert_eq!(random.rand(), 9223372036855263324);
        assert_eq!(random.rand(), 13835058055276569753);
        assert_eq!(random.rand(), 16140901064566282143);
    }

    #[test]
    fun test_rand_n() {
        let mut random = new(998);
        assert_eq!(random.rand_n(1000000), 9223372036855263324 % 1000000);
        assert_eq!(random.rand_n(1000000), 13835058055276569753 % 1000000);
        assert_eq!(random.rand_n(1000000), 16140901064566282143 % 1000000);
    }

    #[test]
    fun test_seed_rand() {
        let mut random = new(0);
        assert_eq!(random.seed_rand(998), 9223372036855263324);
        assert_eq!(random.seed_rand(0), 13835058055276569753);
    }

    #[test]
    fun test_rand_discrete() {
        let mut descrete = vec_map::empty<u64, u64>();
        let mut random = new(1234);
        let mut n = 0;
        let total = 1000;
        let mod = 30;
        while (n < total) {
            let v = rand_n(&mut random, mod);
            if (vec_map::contains(&descrete, &v)) {
                let count = descrete.get_mut(&v);
                *count = *count + 1;
            } else {
                descrete.insert(v, 1);
            };
            n = n + 1;
        };
        let mut n = 0;
        while (n < mod) {
            let count = descrete.get(&n);
            assert!(*count > total / mod / 2, 0);
            n = n + 1;
        };
    }

    // #[test]
    // fun test_rand_n_bench() {
    //     let mut random = new(0);
    //     let mut n = 0;
    //     while (n < 10000) {
    //         rand_n(&mut random, 1000000);
    //         n = n + 1
    //     }
    // }
    // 
    // #[test]
    // fun test_rand_bench() {
    //     let mut random = new(0);
    //     let mut n = 0;
    //     while (n < 10000) {
    //         rand(&mut random);
    //         n = n + 1
    //     }
    // }

    #[test]
    fun test_with_seed_0() {
        let mut random = new(0);
        let mut n = 0;
        while (n < 1000) {
            let r1 = rand(&mut random);
            let r2 = rand(&mut random);
            let r3 = rand(&mut random);
            assert!(r1 != 0 || r2 != 0 || r3 != 0, 0);
            assert!(!((r1 == r2) && (r2 == r3)), 0);
            n = n + 1;
        }
    }
}
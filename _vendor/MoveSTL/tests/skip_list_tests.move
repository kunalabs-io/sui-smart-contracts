#[test_only]
#[lint_allow(self_transfer)]
module move_stl::skip_list_tests {
    use move_stl::skip_list::{
        SkipList,
        insert,
        remove,
        find_prev,
        find_next,
        borrow_node,
        contains,
        check_skip_list,
        get_all_socres,
        prev_score,
        new,
    };
    use move_stl::random;
    use move_stl::option_u64::{OptionU64, is_some, is_none};
    use std::unit_test::assert_eq;

    #[test_only]
    fun new_list_for_test<V: store + copy + drop>(
        max_leveL: u64, list_p: u64, size: u64, seed: u64, value: V, ctx: &mut TxContext
    ): SkipList<V> {
        let mut list = new<V>(max_leveL, list_p, seed, ctx);
        add_node_for_test(&mut list, size, seed, value);
        list
    }

    #[test_only]
    fun add_node_for_test<V: store + copy + drop>(list: &mut SkipList<V>, size: u64, seed: u64, value: V) {
        let mut random = random::new(seed);
        let mut n = 0;
        while (n < size) {
            let score = random.rand_n(1000000); 
            if (list.contains(score)) {
                continue
            };
            list.insert(score, value);
            n = n + 1;
        };
        list.check_skip_list();
    }

    #[test]
    fun test_new() {
        let ctx = &mut tx_context::dummy();
        let list = new<u256>(16, 2, 12345, ctx);
        list.check_skip_list();
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    fun test_borrow() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.insert(1, 1001);
        list.insert(5, 1002);
        list.insert(6, 1003);
        list.insert(7, 1004);
        assert_eq!(*list.borrow(1), 1001);
        assert_eq!(*list.borrow(6), 1003);
        assert_eq!(*list.borrow(7), 1004);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }


    #[test]
    #[expected_failure]
    fun test_borrow_none() {
        let ctx = &mut tx_context::dummy();
        let list = new<u256>(16, 2, 12345, ctx);
        list.borrow(2);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    fun test_borrow_mut() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.insert(1, 1001);
        *list.borrow_mut(1) = 1005;
        assert_eq!(*list.borrow(1), 1005);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[expected_failure]
    fun test_borrow_mut_none() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.borrow_mut(2);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    fun test_borrow_node() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.insert(1, 1001);
        list.insert(5, 1002);
        list.insert(6, 1003);
        list.insert(7, 1004);
        assert_eq!(*list.borrow_node(1).borrow_value(), 1001);
        assert_eq!(*list.borrow_node(7).borrow_value(), 1004);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[expected_failure]
    fun test_borrow_node_none() {
        let ctx = &mut tx_context::dummy();
        let list = new<u256>(16, 2, 12345, ctx);
        list.borrow_node(2);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    fun test_borrow_mut_node() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.insert(1, 1001);
        list.insert(5, 1002);
        list.insert(6, 1003);
        list.insert(7, 1004);
        *list.borrow_mut_node(1).borrow_mut_value() = 1005;
        assert_eq!(*list.borrow_node(1).borrow_value(), 1005);
        *list.borrow_mut_node(7).borrow_mut_value() = 1006;
        assert_eq!(*list.borrow_node(7).borrow_value(), 1006);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[expected_failure]
    fun test_borrow_mut_node_none() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        *list.borrow_mut_node(2).borrow_mut_value() = 1005;
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    fun test_destory_empty() {
        let ctx = &mut tx_context::dummy();
        let list = new<u256>(16, 2, 12345, ctx);
        list.destroy_empty();
    }

    #[test]
    #[expected_failure]
    fun test_destory_empty_not_empty() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.insert(1, 1001);
        list.destroy_empty();
    }

    #[test]
    fun test_metdata() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        let (head, tail, level, max_level, list_p, size) = list.metadata();
        assert_eq!(head.is_empty(), true);
        assert_eq!(tail.is_none(), true);
        assert_eq!(level, 0);
        assert_eq!(max_level, 16);
        assert_eq!(list_p, 2);
        assert_eq!(size, 0);
        list.insert(1, 1001);
        list.insert(5, 1002);
        list.insert(6, 1003);
        list.insert(7, 1004);
        let (head, tail, level, max_level, list_p, size) = list.metadata();
        assert_eq!(head.length() >= 1, true);
        assert_eq!(tail.is_some(), true);
        assert_eq!(level > 1, true);
        assert_eq!(max_level, 16);
        assert_eq!(list_p, 2);
        assert_eq!(size, 4);
        transfer::public_transfer(list, ctx.sender());
    }

    #[test]
    fun test_prev_score() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.insert(1, 1001);
        list.insert(5, 1002);
        list.insert(6, 1003);
        list.insert(7, 1004);
        assert_eq!(list.borrow_node(1).prev_score().is_none(), true);
        assert_eq!(list.borrow_node(5).prev_score().borrow(), 1);
        assert_eq!(list.borrow_node(6).prev_score().borrow(), 5);
        assert_eq!(list.borrow_node(7).prev_score().borrow(), 6);
        transfer::public_transfer(list, ctx.sender());
    }

    #[test]
    fun test_tail() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        assert_eq!(list.tail().is_none(), true);
        list.insert(1, 1001);
        list.insert(5, 1002);
        list.insert(6, 1003);
        list.insert(7, 1004);
        assert_eq!(list.tail().borrow(), 7);
        transfer::public_transfer(list, ctx.sender());
    }

    #[allow(unused_field)]
    public struct Item has drop, store {
        n: u64,
        score: u64,
        finded: OptionU64
    }

    #[test]
    fun test_find() {
        let ctx = &mut tx_context::dummy();
        let list = new_list_for_test<u256>(16, 2, 100, 12345, 0, ctx);
        let scores = list.get_all_socres();

        let length = scores.length();
        let mut n = length;
        while ( n > 0) {
            let score = scores.borrow(n - 1);
            let finded = list.find_prev(*score, true);
            assert!((finded.is_some() && (finded.borrow() == *score)), 0);
            let finded = list.find_prev(*score + 1, true);
            assert!(
                (finded.is_some() && (finded.borrow() == *score)) ||
                (finded.is_some() && (finded.borrow() == *score + 1)),
                0
            );

            let finded = list.find_prev(*score, false);
            if (n >= 2) {
                assert!((finded.is_some() && (finded.borrow() == *scores.borrow(n - 2))), 0);
            } else {
                assert!(is_none(&finded), 0);
            };

            let finded = list.find_next(*score, true);
            assert!((finded.is_some() && (finded.borrow() == *score)), 0);

            let finded = list.find_next(*score - 1, true);
            assert!(
                (finded.is_some() && (finded.borrow() == *score)) ||
                    (finded.is_some() && (finded.borrow() == *score - 1)),
                0
            );

            let finded = list.find_next(*score, false);
            if (n < length) {
                assert!((finded.is_some() && (finded.borrow() == *scores.borrow(n))), 0);
            } else {
                assert!(is_none(&finded), 0);
            };
            n = n - 1;
        };
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    fun test_remove() {
        let ctx = &mut tx_context::dummy();
        let mut list = new_list_for_test<u256>(16, 2, 20, 5678, 0, ctx);
        let scores = list.get_all_socres();
        let (mut n, length) = (0, scores.length());
        let start = length / 2;
        while(n <= start) {
            let s1 = start - n;
            let s2 = start + n;
            if (s1 >= 0) {
                list.remove(*scores.borrow(s1));
            };
            if (s2 != s1 && s2 < length ) {
                list.remove(*scores.borrow(s2));
            };
            n = n + 1;
        };
        list.check_skip_list();

        add_node_for_test(&mut list, 100, 7890, 0);
        let scores = list.get_all_socres();
        let (mut n, length) = (0, scores.length());
        let mut skip = 0;
        while(n < length) {
            list.remove(*scores.borrow(n));
            skip = skip + 1;
            n = n + skip;
        };
        list.check_skip_list();

        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    fun test_find_in_empty_list() {
        let ctx = &mut tx_context::dummy();
        let list = new<u256>(16, 2, 1234, ctx);
        let opt_score = list.find_nearest(1000);
        assert!(opt_score.is_none(), 0);

        let opt_score = list.find_prev(1000, true);
        assert_eq!(opt_score.is_none(), true);

        let opt_score = list.find_prev(1000, false);
        assert_eq!(opt_score.is_none(), true);

        let opt_score = list.find_next(1000, true);
        assert_eq!(opt_score.is_none(), true);

        let opt_score = list.find_next(1000, false);
        assert_eq!(opt_score.is_none(), true);

        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[expected_failure]
    fun test_insert_exist() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.insert(1, 1001);
        list.insert(1, 1002);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[expected_failure]
    fun test_remove_not_exist() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(16, 2, 12345, ctx);
        list.insert(1, 1001);
        list.remove(2);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }
    #[test]
    fun test_rand_level() {
        let ctx = &mut tx_context::dummy();
        let mut list = new<u256>(2, 2, 0, ctx);
        list.insert(1, 1001);
        list.insert(2, 1002);
        list.insert(3, 1003);
        list.insert(4, 1004);
        list.insert(5, 1005);
        list.insert(6, 1006);
        list.insert(7, 1007);
        list.insert(8, 1008);
        list.insert(9, 1009);
        list.insert(10, 1010);
        list.insert(11, 1011);
        list.insert(12, 1012);
        list.insert(13, 1013);
        list.insert(14, 1014);
        let (_, _, level, max_level, _, _) = list.metadata();
        assert_eq!(level, 2);
        assert_eq!(max_level, 2);
        transfer::public_transfer(list, tx_context::sender(ctx));
    }


    //#[test]
    //fun test_insert_bench() {
    //    let ctx = &mut tx_context::dummy();
    //    let list = new<u256>(16, 2, 100000, ctx);
    //    let n = 0;
    //    while (n < 1000) {
    //        insert(&mut list, 0 + n, 0);
    //        insert(&mut list, 1000000 - n, 0);
    //        insert(&mut list, 100000 - n, 0);
    //        n = n + 1;
    //    };
    //    debug::print(&list.level);
    //    transfer::transfer(list, tx_context::sender(ctx));
    //}

    //#[test]
    //fun test_find_bench() {
    //    let ctx = &mut tx_context::dummy();
    //    let list = new_list_for_test<u256>(16, 2, 1000, 12345, 0, ctx);
    //    let random = random::new(12345);
    //    let n = 0;
    //    while (n < 100) {
    //        let score = random::rand_n(&mut random, 1000000);
    //        if ((n % 3) == 0) {
    //            score = score + 1;
    //        };
    //        find(&list, score);
    //        _ = score;
    //        n = n + 1;
    //    };
    //    transfer::transfer(list, tx_context::sender(ctx));
    //}

    //#[test]
    //fun test_find_next_bench() {
    //    let ctx = &mut tx_context::dummy();
    //    let list = new_list_for_test<u256>(16, 2, 1000, 12345, 0, ctx);
    //    let n = 0;
    //    let finded = find_next(&list, 99999, true);
    //    while (n < 1 && is_some(&finded)) {
    //        let node = borrow_node(&list, option_u64::borrow(&finded));
    //        finded = next_score(node);
    //        n = n + 1;
    //    };
    //    transfer::transfer(list, tx_context::sender(ctx));
    //}
}
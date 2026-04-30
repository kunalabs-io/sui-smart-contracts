#[test_only]
module move_stl::linked_table_tests {
    use move_stl::linked_table::{
        new,
        push_front,
        push_back,
        remove,
        insert_before,
        insert_after,
        is_empty,
        destroy_empty,
        drop,
    };

    #[test]
    fun test_new() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        assert!(is_empty(&table), 0);
        assert!(table.head().is_none(), 0);
        assert!(table.tail().is_none(), 0);
        destroy_empty(table);
    }

    #[test]
    fun test_borrow() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 1, 1001);
        push_back(&mut table, 2, 1002);
        push_back(&mut table, 3, 1003);
        assert!(table.borrow(1) == 1001, 0);
        assert!(table.borrow(2) == 1002, 0);
        assert!(table.borrow(3) == 1003, 0);
        drop(table);
    }

    #[test]
    fun test_borrow_mut() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 1, 1001);
        push_back(&mut table, 2, 1002);
        push_back(&mut table, 3, 1003);
        let v = table.borrow_mut(2);
        *v = 10010;
        assert!(table.borrow(2) == 10010, 0);
        drop(table);
    }

    #[test]
    fun test_borrow_node_value() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 1, 1001);
        push_back(&mut table, 2, 1002);
        push_back(&mut table, 3, 1003);
        let v = table.borrow_node(2).borrow_value();
        assert!(v == 1002, 0);
        drop(table);
    }

    #[test]
    fun test_borrow_node_mut_value() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 1, 1001);
        push_back(&mut table, 2, 1002);
        push_back(&mut table, 3, 1003);
        let v = table.borrow_mut_node(2).borrow_mut_value();
        *v = 10010;
        assert!(table.borrow(2) == 10010, 0);
        drop(table);
    }

    #[test]
    fun test_head() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 2, 1001);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        push_back(&mut table, 1, 1002);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        push_back(&mut table, 3, 1003);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        drop(table);
    }

    #[test]
    fun test_drop() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 2, 1001);
        drop(table);
    }

    #[test]
    fun test_destroy_empty() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        destroy_empty(table);
    }

    #[test]
    #[expected_failure]
    fun test_destroy_empty_not_empty() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        table.push_back(1, 1001);
        destroy_empty(table);
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_push_front() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_front(&mut table, 1, 1001);
        assert!(!is_empty(&table), 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 1, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 1, 0);

        assert!(table.length() == 1, 0);

        push_front(&mut table, 2, 1002);
        assert!(!is_empty(&table), 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 1, 0);
        assert!(table.length() == 2, 0);
        let node_1 = table.borrow_node(1);
        assert!(node_1.prev().is_some() && *node_1.prev().borrow()  == 2, 0);
        assert!(node_1.next().is_none(), 0);
        let node_2 = table.borrow_node(2);
        assert!(node_2.prev().is_none(), 0);
        assert!(node_2.next().is_some() && *node_2.next().borrow()  == 1, 0);

        push_front(&mut table, 3, 1002);
        assert!(table.length() == 3, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 3, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 1, 0);
        let node_2 = table.borrow_node(2);
        assert!(node_2.prev().is_some() && *node_2.prev().borrow()  == 3, 0);
        assert!(node_2.next().is_some() && *node_2.next().borrow()  == 1, 0);
        let node_3 = table.borrow_node(3);
        assert!(node_3.prev().is_none(), 0);
        assert!(node_3.next().is_some() && *node_3.next().borrow()  == 2, 0);

        drop(table);
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_push_back() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 1, 1001);
        assert!(!is_empty(&table), 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 1, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 1, 0);
        assert!(table.length() == 1, 0);

        push_back(&mut table, 2, 1002);
        assert!(!is_empty(&table), 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 1, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 2, 0);
        assert!(table.length() == 2, 0);
        let node_1 = table.borrow_node(1);
        assert!(node_1.prev().is_none(), 0);
        assert!(node_1.next().is_some() && *node_1.next().borrow()  == 2, 0);
        let node_2 = table.borrow_node(2);
        assert!(node_2.prev().is_some() && *node_2.prev().borrow()  == 1, 0);
        assert!(node_2.next().is_none(), 0);

        push_back(&mut table, 3, 1002);
        assert!(table.length() == 3, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 1, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 3, 0);
        let node_2 = table.borrow_node(2);
        assert!(node_2.prev().is_some() && *node_2.prev().borrow()  == 1, 0);
        assert!(node_2.next().is_some() && *node_2.next().borrow()  == 3, 0);
        let node_3 = table.borrow_node(3);
        assert!(node_3.prev().is_some() && *node_3.prev().borrow()  == 2, 0);
        assert!(node_3.next().is_none(), 0);

        drop(table);
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_remove() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 5, 1005);
        push_back(&mut table, 6, 1006);
        push_back(&mut table, 7, 1007);
        push_back(&mut table, 8, 1008);
        push_back(&mut table, 9, 1009);
        push_front(&mut table, 4, 1004);
        push_front(&mut table, 3, 1003);
        push_front(&mut table, 2, 1002);
        push_front(&mut table, 1, 1001);

        // remove middle node
        let node_5 = table.borrow_node(5);
        assert!(node_5.prev().is_some() && *node_5.prev().borrow()  == 4, 0);
        assert!(node_5.next().is_some() && *node_5.next().borrow()  == 6, 0);
        remove(&mut table, 5);
        assert!(!table.contains(5), 0);
        let node_4 = table.borrow_node(4);
        let node_6 = table.borrow_node(6);
        assert!(node_4.prev().is_some() && *node_4.prev().borrow()  == 3, 0);
        assert!(node_4.next().is_some() && *node_4.next().borrow()  == 6, 0);
        assert!(node_6.prev().is_some() && *node_6.prev().borrow()  == 4, 0);
        assert!(node_6.next().is_some() && *node_6.next().borrow()  == 7, 0);

        // remove head node
        let node_1 = table.borrow_node(1);
        assert!(node_1.prev().is_none(), 0);
        assert!(node_1.next().is_some() && *node_1.next().borrow()  == 2, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 1, 0);
        remove(&mut table, 1);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        let node_2 = table.borrow_node(2);
        assert!(node_2.prev().is_none(), 0);
        assert!(node_2.next().is_some() && *node_2.next().borrow()  == 3, 0);

        // remove tail node
        let node_9 = table.borrow_node(9);
        assert!(node_9.next().is_none(), 0);
        assert!(node_9.prev().is_some() && *node_9.prev().borrow()  == 8, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 9, 0);
        remove(&mut table, 9);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 8, 0);
        let node_8 = table.borrow_node(8);
        assert!(node_8.next().is_none(), 0);
        assert!(node_8.prev().is_some() && *node_8.prev().borrow()  == 7, 0);

        assert!(table.length() == 6, 0);

        drop(table);
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_insert_before() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 2, 1002);
        push_back(&mut table, 4, 1004);
        push_back(&mut table, 6, 1006);
        push_back(&mut table, 8, 1008);
        push_back(&mut table, 10, 1010);

        insert_before(&mut table, 8, 7, 1007);
        let node_6 = table.borrow_node(6);
        let node_7 = table.borrow_node(7);
        let node_8 = table.borrow_node(8);
        assert!(node_6.next().is_some() && *node_6.next().borrow()  == 7, 0);
        assert!(node_6.prev().is_some() && *node_6.prev().borrow()  == 4, 0);
        assert!(node_7.next().is_some() && *node_7.next().borrow()  == 8, 0);
        assert!(node_7.prev().is_some() && *node_7.prev().borrow()  == 6, 0);
        assert!(node_8.next().is_some() && *node_8.next().borrow()  == 10, 0);
        assert!(node_8.prev().is_some() && *node_8.prev().borrow()  == 7, 0);
        assert!(table.length() == 6, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 10, 0);

        insert_before(&mut table, 2, 1, 1001);
        let node_1 = table.borrow_node(1);
        let node_2 = table.borrow_node(2);
        assert!(node_1.next().is_some() && *node_1.next().borrow()  == 2, 0);
        assert!(node_1.prev().is_none(), 0);
        assert!(node_2.next().is_some() && *node_2.next().borrow()  == 4, 0);
        assert!(node_2.prev().is_some() && *node_2.prev().borrow()  == 1, 0);
        assert!(table.length() == 7, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 1, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 10, 0);

        insert_before(&mut table, 10, 9, 1009);
        let node_8 = table.borrow_node(8);
        let node_9 = table.borrow_node(9);
        let node_10 = table.borrow_node(10);
        assert!(node_8.next().is_some() && *node_8.next().borrow()  == 9, 0);
        assert!(node_8.prev().is_some() && *node_8.prev().borrow()  == 7, 0);
        assert!(node_9.next().is_some() && *node_9.next().borrow()  == 10, 0);
        assert!(node_9.prev().is_some() && *node_9.prev().borrow()  == 8, 0);
        assert!(node_10.prev().is_some() && *node_10.prev().borrow()  == 9, 0);
        assert!(node_10.next().is_none(), 0);
        assert!(table.length() == 8, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 1, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 10, 0);

        drop(table);
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_insert_after() {
        let ctx = &mut tx_context::dummy();
        let mut table = new<u64, u256>(ctx);
        push_back(&mut table, 2, 1002);
        push_back(&mut table, 4, 1004);
        push_back(&mut table, 6, 1006);
        push_back(&mut table, 8, 1008);
        push_back(&mut table, 10, 1010);

        // after middle node
        insert_after(&mut table, 6, 7, 1007);
        let node_6 = table.borrow_node(6);
        let node_7 = table.borrow_node(7);
        let node_8 = table.borrow_node(8);
        assert!(node_6.next().is_some() && *node_6.next().borrow()  == 7, 0);
        assert!(node_6.prev().is_some() && *node_6.prev().borrow()  == 4, 0);
        assert!(node_7.next().is_some() && *node_7.next().borrow()  == 8, 0);
        assert!(node_7.prev().is_some() && *node_7.prev().borrow()  == 6, 0);
        assert!(node_8.next().is_some() && *node_8.next().borrow()  == 10, 0);
        assert!(node_8.prev().is_some() && *node_8.prev().borrow()  == 7, 0);
        assert!(table.length() == 6, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 10, 0);

        // after head node
        insert_after(&mut table, 2, 3, 1009);
        let node_2 = table.borrow_node(2);
        let node_3 = table.borrow_node(3);
        let node_4 = table.borrow_node(4);
        assert!(node_2.next().is_some() && *node_2.next().borrow()  == 3, 0);
        assert!(node_2.prev().is_none(), 0);
        assert!(node_3.next().is_some() && *node_3.next().borrow()  == 4, 0);
        assert!(node_3.prev().is_some() && *node_3.prev().borrow()  == 2, 0);
        assert!(node_4.next().is_some() && *node_4.next().borrow()  == 6, 0);
        assert!(node_4.prev().is_some() && *node_4.prev().borrow()  == 3, 0);
        assert!(table.length() == 7, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 10, 0);

        // after tail node
        insert_after(&mut table, 10, 11, 1011);
        let node_10 = table.borrow_node(10);
        let node_11 = table.borrow_node(11);
        assert!(node_10.next().is_some() && *node_10.next().borrow()  == 11, 0);
        assert!(node_10.prev().is_some() && *node_10.prev().borrow()  == 8, 0);
        assert!(node_11.prev().is_some() && *node_11.prev().borrow()  == 10, 0);
        assert!(node_11.next().is_none(), 0);
        assert!(table.length() == 8, 0);
        assert!(table.head().is_some() && *table.head().borrow()  == 2, 0);
        assert!(table.tail().is_some() && *table.tail().borrow()  == 11, 0);

        drop(table);
    }

    //#[test]
    //#[lint_allow(self_transfer)]
    //fun test_push_back_bench() {
    //    let ctx = &mut tx_context::dummy();
    //    let table = new<u64, u256>(ctx);
    //    let n = 0;
    //    while (n < 10000) {
    //        push_back(&mut table, n, (n as u256));
    //        n = n + 1;
    //    };
    //    transfer::transfer(table, tx_context::sender(ctx));
    //}

    //#[test]
    //#[lint_allow(self_transfer)]
    //fun test_push_front_bench() {
    //    let ctx = &mut tx_context::dummy();
    //    let table = new<u64, u256>(ctx);
    //    let n = 0;
    //    while (n < 10000) {
    //        push_front(&mut table, n, (n as u256));
    //        n = n + 1;
    //    };
    //    transfer::transfer(table, tx_context::sender(ctx));
    //}

    //#[test]
    //#[lint_allow(self_transfer)]
    //fun test_insert_before_bench() {
    //    let ctx = &mut tx_context::dummy();
    //    let table = new<u64, u64>(ctx);
    //    let n = 10000;
    //    let current_key = 20000;
    //    push_back(&mut table, 0, 0);
    //    push_back(&mut table, current_key, current_key);
    //    while (n > 0) {
    //        insert_before(&mut table, current_key, n, n);
    //        current_key = n;
    //        n = n - 1;
    //    };
    //    transfer::transfer(table, tx_context::sender(ctx));
    //}

    //#[test]
    //#[lint_allow(self_transfer)]
    //fun test_insert_after_bench() {
    //    let ctx = &mut tx_context::dummy();
    //    let table = new<u64, u64>(ctx);
    //    let n = 1;
    //    let current_key = 0;
    //    push_back(&mut table, 0, 0);
    //    push_back(&mut table, 20000, 20000);
    //    while (n <= 10000) {
    //        insert_after(&mut table, current_key, n, n);
    //        current_key = n;
    //        n = n + 1;
    //    };
    //    transfer::transfer(table, tx_context::sender(ctx));
    //}
}
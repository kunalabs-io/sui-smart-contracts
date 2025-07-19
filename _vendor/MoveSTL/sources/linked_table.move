module move_stl::linked_table {
    use std::option::{Option, none, is_none, is_some, swap_or_fill, some};
    use std::option;
    use sui::tx_context::TxContext;
    use sui::object::{Self, UID};
    use sui::dynamic_field as field;

    const  EListNotEmpty: u64 = 0;

    struct LinkedTable<K: store + drop + copy, phantom V: store> has key, store {
        id: UID,
        head: Option<K>,
        tail: Option<K>,
        size: u64
    }

    struct Node<K: store + drop + copy, V: store> has store {
        prev: Option<K>,
        next: Option<K>,
        value: V
    }

    public fun new<K: store + drop + copy, V: store>(ctx: &mut TxContext): LinkedTable<K, V> {
        LinkedTable<K,V> {
            id : object::new(ctx),
            head: none<K>(),
            tail: none<K>(),
            size: 0
        }
    }

    public fun is_empty<K: store + drop + copy, V: store>(table: &LinkedTable<K, V>): bool {
        table.size == 0
    }

    public fun length<K: store + drop + copy, V: store>(table: &LinkedTable<K, V>): u64 {
        table.size
    }

    public fun contains<K: store + drop + copy, V: store>(table: &LinkedTable<K, V>, key: K): bool {
        field::exists_with_type<K, Node<K, V>>(&table.id, key)
    }

    public fun head<K: store + drop + copy, V: store>(table: &LinkedTable<K, V>): option::Option<K> {
        table.head
    }

    public fun tail<K: store + drop + copy, V: store>(table: &LinkedTable<K, V>): option::Option<K> {
        table.tail
    }

    public fun next<K: store + drop + copy, V: store>(node: &Node<K, V>): Option<K> {
        node.next
    }

    public fun prev<K: store + drop + copy, V: store>(node: &Node<K, V>): Option<K> {
        node.prev
    }

    public fun borrow<K: store + drop + copy, V: store>(table: &LinkedTable<K, V>, key: K): &V {
        &field::borrow<K, Node<K, V>>(&table.id, key).value
    }

    public fun borrow_mut<K: store + drop + copy, V: store>(table: &mut LinkedTable<K, V>, key: K): &mut V {
        &mut field::borrow_mut<K, Node<K, V>>(&mut table.id, key).value
    }

    public fun borrow_node<K: store + drop + copy, V: store>(table: &LinkedTable<K, V>, key: K): &Node<K, V> {
        field::borrow<K, Node<K, V>>(&table.id, key)
    }

    public fun borrow_mut_node<K: store + drop + copy, V: store>(table: &mut LinkedTable<K, V>, key: K): &mut Node<K, V> {
        field::borrow_mut<K, Node<K, V>>(&mut table.id, key)
    }

    public fun borrow_value<K: store + drop + copy, V: store>(node: &Node<K, V>): &V{
        &node.value
    }

    public fun borrow_mut_value<K: store + drop + copy, V: store>(node: &mut Node<K, V>): &mut V{
        &mut node.value
    }

    public fun push_back<K: store + drop + copy, V: store>(table: &mut LinkedTable<K, V>, key: K, value: V) {
        let node = Node<K, V> {
            prev: table.tail,
            next: none(),
            value
        };
        swap_or_fill(&mut table.tail, key);
        if (is_none(&table.head)) {
            swap_or_fill(&mut table.head, key);
        };
        if (is_some(&node.prev)) {
            let prev_node= borrow_mut_node(table, *option::borrow(&node.prev));
            swap_or_fill(&mut prev_node.next, key);
        };
        field::add(&mut table.id, key, node);
        table.size = table.size + 1;
    }

    public fun push_front<K: store + drop + copy, V: store>(table: &mut LinkedTable<K, V>, key: K, value: V) {
        let node = Node<K, V> {
            prev: none(),
            next: table.head,
            value
        };
        swap_or_fill(&mut table.head, key);
        if (is_none(&table.tail)) {
            swap_or_fill(&mut table.tail, key);
        };
        if (is_some(&node.next)) {
            let next_node = borrow_mut_node(table, *option::borrow(&node.next));
            swap_or_fill(&mut next_node.prev, key);
        };
        field::add(&mut table.id, key, node);
        table.size = table.size + 1;
    }

    public fun insert_before<K: store + drop + copy, V: store>(table: &mut LinkedTable<K, V>, current_key: K, key: K, value: V) {
        let current_node = borrow_mut_node(table, current_key);
        let node = Node<K, V> {
            prev: current_node.prev,
            next: some(current_key),
            value
        };
        swap_or_fill(&mut current_node.prev, key);
        if (is_some(&node.prev)) {
            let prev_node = borrow_mut_node(table, *option::borrow(&node.prev));
            swap_or_fill(&mut prev_node.next, key);
        } else {
            swap_or_fill(&mut table.head, key);
        };
        field::add(&mut table.id, key, node);
        table.size = table.size + 1;
    }

    public fun insert_after<K: store + drop + copy, V: store>(table: &mut LinkedTable<K, V>, current_key: K, key: K, value: V) {
        let current_node = borrow_mut_node(table, current_key);
        let node = Node<K, V> {
            prev: some(current_key),
            next: current_node.next,
            value
        };
        swap_or_fill(&mut current_node.next, key);

        if (is_some(&node.next)) {
            let next_node = borrow_mut_node(table, *option::borrow(&node.next));
            swap_or_fill(&mut next_node.prev, key);
        } else {
            swap_or_fill(&mut table.tail, key);
        };
        field::add(&mut table.id, key, node);
        table.size = table.size + 1;
    }

    public fun remove<K: store + drop + copy, V: store>(table: &mut LinkedTable<K, V>, key: K): V {
        let Node<K, V> { prev, next, value } = field::remove(&mut table.id, key);
        table.size = table.size - 1;
        if (option::is_some(&prev)) {
            field::borrow_mut<K, Node<K, V>>(&mut table.id, *option::borrow(&prev)).next = next
        };
        if (option::is_some(&next)) {
            field::borrow_mut<K, Node<K, V>>(&mut table.id, *option::borrow(&next)).prev = prev
        };
        if (option::borrow(&table.head) == &key) table.head = next;
        if (option::borrow(&table.tail) == &key) table.tail = prev;
        value
    }

    public fun destroy_empty<K: store + copy + drop, V: store + drop>(table: LinkedTable<K, V>) {
        let LinkedTable { id, size, head: _, tail: _ } = table;
        assert!(size == 0, EListNotEmpty);
        object::delete(id)
    }

    public fun drop<K: store + copy + drop, V: store>(table: LinkedTable<K, V>) {
        let LinkedTable { id, size: _, head: _, tail: _ } = table;
        object::delete(id)
    }

    #[test_only]
    use sui::tx_context;
    #[test_only]
    use sui::transfer;

    #[test]
    fun test_table_new() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        assert!(is_empty(&table), 0);
        assert!(is_none(&table.head), 0);
        assert!(is_none(&table.tail), 0);
        destroy_empty(table);
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_push_front() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        push_front(&mut table, 1, 1001);
        assert!(!is_empty(&table), 0);
        assert!((is_some(&table.head) && (*option::borrow(&table.head) == 1)), 0);
        assert!((is_some(&table.tail) && (*option::borrow(&table.tail) == 1)), 0);
        assert!(length(&table) == 1, 0);

        push_front(&mut table, 2, 1002);
        assert!(!is_empty(&table), 0);
        assert!((is_some(&table.head) && (*option::borrow(&table.head) == 2)), 0);
        assert!((is_some(&table.tail) && (*option::borrow(&table.tail) == 1)), 0);
        assert!(length(&table) == 2, 0);
        let node_1 = borrow_node(&table, 1);
        assert!((is_some(&node_1.prev) && (*option::borrow(&node_1.prev) == 2)), 0);
        assert!(is_none(&node_1.next), 0);
        let node_2 = borrow_node(&table, 2);
        assert!(is_none(&node_2.prev), 0);
        assert!((is_some(&node_2.next) && (*option::borrow(&node_2.next) == 1)), 0);

        push_front(&mut table, 3, 1002);
        assert!(length(&table) == 3, 0);
        assert!((is_some(&table.head) && (*option::borrow(&table.head) == 3)), 0);
        assert!((is_some(&table.tail) && (*option::borrow(&table.tail) == 1)), 0);
        let node_2 = borrow_node(&table, 2);
        assert!((is_some(&node_2.prev) && (*option::borrow(&node_2.prev) == 3)), 0);
        assert!((is_some(&node_2.next) && (*option::borrow(&node_2.next) == 1)), 0);
        let node_3 = borrow_node(&table, 3);
        assert!(is_none(&node_3.prev), 0);
        assert!((is_some(&node_3.next) && (*option::borrow(&node_3.next) == 2)), 0);

        transfer::transfer(table, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_push_back() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        push_back(&mut table, 1, 1001);
        assert!(!is_empty(&table), 0);
        assert!((is_some(&table.head) && (*option::borrow(&table.head) == 1)), 0);
        assert!((is_some(&table.tail) && (*option::borrow(&table.tail) == 1)), 0);
        assert!(length(&table) == 1, 0);

        push_back(&mut table, 2, 1002);
        assert!(!is_empty(&table), 0);
        assert!((is_some(&table.head) && (*option::borrow(&table.head) == 1)), 0);
        assert!((is_some(&table.tail) && (*option::borrow(&table.tail) == 2)), 0);
        assert!(length(&table) == 2, 0);
        let node_1 = borrow_node(&table, 1);
        assert!(is_none(&node_1.prev), 0);
        assert!((is_some(&node_1.next) && (*option::borrow(&node_1.next) == 2)), 0);
        let node_2 = borrow_node(&table, 2);
        assert!((is_some(&node_2.prev) && (*option::borrow(&node_2.prev) == 1)), 0);
        assert!(is_none(&node_2.next), 0);

        push_back(&mut table, 3, 1002);
        assert!(length(&table) == 3, 0);
        assert!((is_some(&table.head) && (*option::borrow(&table.head) == 1)), 0);
        assert!((is_some(&table.tail) && (*option::borrow(&table.tail) == 3)), 0);
        let node_2 = borrow_node(&table, 2);
        assert!((is_some(&node_2.prev) && (*option::borrow(&node_2.prev) == 1)), 0);
        assert!((is_some(&node_2.next) && (*option::borrow(&node_2.next) == 3)), 0);
        let node_3 = borrow_node(&table, 3);
        assert!((is_some(&node_3.prev) && (*option::borrow(&node_3.prev) == 2)), 0);
        assert!(is_none(&node_3.next), 0);

        transfer::transfer(table, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_remove() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
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
        let node_5 = borrow_node(&table, 5);
        assert!(*option::borrow(&node_5.prev) == 4, 0);
        assert!(*option::borrow(&node_5.next) == 6, 0);
        remove(&mut table, 5);
        assert!(!contains(&table, 5), 0);
        let node_4 = borrow_node(&table, 4);
        let node_6 = borrow_node(&table, 6);
        assert!(*option::borrow(&node_4.prev) == 3, 0);
        assert!(*option::borrow(&node_4.next) == 6, 0);
        assert!(*option::borrow(&node_6.prev) == 4, 0);
        assert!(*option::borrow(&node_6.next) == 7, 0);

        // remove head node
        let node_1 = borrow_node(&table, 1);
        assert!(is_none(&node_1.prev), 0);
        assert!(*option::borrow(&node_1.next) == 2, 0);
        assert!(*option::borrow(&table.head) == 1, 0);
        remove(&mut table, 1);
        assert!(*option::borrow(&table.head) == 2, 0);
        let node_2 = borrow_node(&table, 2);
        assert!(is_none(&node_2.prev), 0);
        assert!(*option::borrow(&node_2.next) == 3, 0);

        // remove tail node
        let node_9 = borrow_node(&table, 9);
        assert!(is_none(&node_9.next), 0);
        assert!(*option::borrow(&node_9.prev) == 8, 0);
        assert!(*option::borrow(&table.tail) == 9, 0);
        remove(&mut table, 9);
        assert!(*option::borrow(&table.tail) == 8, 0);
        let node_8 = borrow_node(&table, 8);
        assert!(is_none(&node_8.next), 0);
        assert!(*option::borrow(&node_8.prev) == 7, 0);

        assert!(length(&table) == 6, 0);

        transfer::transfer(table, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_insert_before() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        push_back(&mut table, 2, 1002);
        push_back(&mut table, 4, 1004);
        push_back(&mut table, 6, 1006);
        push_back(&mut table, 8, 1008);
        push_back(&mut table, 10, 1010);

        insert_before(&mut table, 8, 7, 1007);
        let node_6 = borrow_node(&table, 6);
        let node_7 = borrow_node(&table, 7);
        let node_8 = borrow_node(&table, 8);
        assert!(*option::borrow(&node_6.next) == 7, 0);
        assert!(*option::borrow(&node_6.prev) == 4, 0);
        assert!(*option::borrow(&node_7.next) == 8, 0);
        assert!(*option::borrow(&node_7.prev) == 6, 0);
        assert!(*option::borrow(&node_8.next) == 10, 0);
        assert!(*option::borrow(&node_8.prev) == 7, 0);
        assert!(length(&table) == 6, 0);
        assert!(*option::borrow(&table.head) == 2, 0);
        assert!(*option::borrow(&table.tail) == 10, 0);

        insert_before(&mut table, 2, 1, 1001);
        let node_1 = borrow_node(&table, 1);
        let node_2 = borrow_node(&table, 2);
        assert!(*option::borrow(&node_1.next) == 2, 0);
        assert!(is_none(&node_1.prev), 0);
        assert!(*option::borrow(&node_2.next) == 4, 0);
        assert!(*option::borrow(&node_2.prev) == 1, 0);
        assert!(length(&table) == 7, 0);
        assert!(*option::borrow(&table.head) == 1, 0);
        assert!(*option::borrow(&table.tail) == 10, 0);

        insert_before(&mut table, 10, 9, 1009);
        let node_8 = borrow_node(&table, 8);
        let node_9 = borrow_node(&table, 9);
        let node_10 = borrow_node(&table, 10);
        assert!(*option::borrow(&node_8.next) == 9, 0);
        assert!(*option::borrow(&node_8.prev) == 7, 0);
        assert!(*option::borrow(&node_9.next) == 10, 0);
        assert!(*option::borrow(&node_9.prev) == 8, 0);
        assert!(*option::borrow(&node_10.prev) == 9, 0);
        assert!(is_none(&node_10.next), 0);
        assert!(length(&table) == 8, 0);
        assert!(*option::borrow(&table.head) == 1, 0);
        assert!(*option::borrow(&table.tail) == 10, 0);

        transfer::transfer(table, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_insert_after() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        push_back(&mut table, 2, 1002);
        push_back(&mut table, 4, 1004);
        push_back(&mut table, 6, 1006);
        push_back(&mut table, 8, 1008);
        push_back(&mut table, 10, 1010);

        // after middle node
        insert_after(&mut table, 6, 7, 1007);
        let node_6 = borrow_node(&table, 6);
        let node_7 = borrow_node(&table, 7);
        let node_8 = borrow_node(&table, 8);
        assert!(*option::borrow(&node_6.next) == 7, 0);
        assert!(*option::borrow(&node_6.prev) == 4, 0);
        assert!(*option::borrow(&node_7.next) == 8, 0);
        assert!(*option::borrow(&node_7.prev) == 6, 0);
        assert!(*option::borrow(&node_8.next) == 10, 0);
        assert!(*option::borrow(&node_8.prev) == 7, 0);
        assert!(length(&table) == 6, 0);
        assert!(*option::borrow(&table.head) == 2, 0);
        assert!(*option::borrow(&table.tail) == 10, 0);

        // after head node
        insert_after(&mut table, 2, 3, 1009);
        let node_2 = borrow_node(&table, 2);
        let node_3 = borrow_node(&table, 3);
        let node_4 = borrow_node(&table, 4);
        assert!(*option::borrow(&node_2.next) == 3, 0);
        assert!(is_none(&node_2.prev), 0);
        assert!(*option::borrow(&node_3.next) == 4, 0);
        assert!(*option::borrow(&node_3.prev) == 2, 0);
        assert!(*option::borrow(&node_4.next) == 6, 0);
        assert!(*option::borrow(&node_4.prev) == 3, 0);
        assert!(length(&table) == 7, 0);
        assert!(*option::borrow(&table.head) == 2, 0);
        assert!(*option::borrow(&table.tail) == 10, 0);

        // after tail node
        insert_after(&mut table, 10, 11, 1011);
        let node_10 = borrow_node(&table, 10);
        let node_11 = borrow_node(&table, 11);
        assert!(*option::borrow(&node_10.next) == 11, 0);
        assert!(*option::borrow(&node_10.prev) == 8, 0);
        assert!(*option::borrow(&node_11.prev) == 10, 0);
        assert!(is_none(&node_11.next), 0);
        assert!(length(&table) == 8, 0);
        assert!(*option::borrow(&table.head) == 2, 0);
        assert!(*option::borrow(&table.tail) == 11, 0);

        transfer::transfer(table, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_push_back_bench() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        let n = 0;
        while (n < 10000) {
            push_back(&mut table, n, (n as u256));
            n = n + 1;
        };
        transfer::transfer(table, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_push_front_bench() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u256>(ctx);
        let n = 0;
        while (n < 10000) {
            push_front(&mut table, n, (n as u256));
            n = n + 1;
        };
        transfer::transfer(table, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_insert_before_bench() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u64>(ctx);
        let n = 10000;
        let current_key = 20000;
        push_back(&mut table, 0, 0);
        push_back(&mut table, current_key, current_key);
        while (n > 0) {
            insert_before(&mut table, current_key, n, n);
            current_key = n;
            n = n - 1;
        };
        transfer::transfer(table, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_table_insert_after_bench() {
        let ctx = &mut tx_context::dummy();
        let table = new<u64, u64>(ctx);
        let n = 1;
        let current_key = 0;
        push_back(&mut table, 0, 0);
        push_back(&mut table, 20000, 20000);
        while (n <= 10000) {
            insert_after(&mut table, current_key, n, n);
            current_key = n;
            n = n + 1;
        };
        transfer::transfer(table, tx_context::sender(ctx));
    }
}

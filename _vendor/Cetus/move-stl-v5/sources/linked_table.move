module move_stl::linked_table {
    use std::option::{none, is_none, is_some, swap_or_fill, some};
    use sui::dynamic_field as field;

    const  EListNotEmpty: u64 = 0;

    public struct LinkedTable<K: store + drop + copy, phantom V: store> has key, store {
        id: UID,
        head: Option<K>,
        tail: Option<K>,
        size: u64
    }

    public struct Node<K: store + drop + copy, V: store> has store {
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
}

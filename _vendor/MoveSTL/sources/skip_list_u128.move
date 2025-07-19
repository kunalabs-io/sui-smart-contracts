module move_stl::skip_list_u128 {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::vector::{Self, push_back};
    use sui::table;
    use move_stl::option_u128::{Self, OptionU128, none, some, is_none, is_some, swap_or_fill, is_some_and_lte};
    use move_stl::random::{Self, Random};

    const ENodeAlreadyExist: u64 = 0;
    const ENodeDoesNotExist: u64 = 1;
    const ESkipListNotEmpty: u64 = 3;

    /// The skip list.
    struct SkipList<V: store> has key, store{
        /// The id of this skip list.
        id: UID,
        /// The skip list header of each level. i.e. the score of node.
        head: vector<OptionU128>,
        /// The level0's tail of skip list. i.e. the score of node.
        tail: OptionU128,
        /// The current level of this skip list.
        level: u64,
        /// The max level of this skip list.
        max_level: u64,
        /// Basic probability of random of node indexer's level i.e. (list_p = 2, level2 = 1/2, level3 = 1/4).
        list_p: u64,

        /// The random for generate ndoe's level
        random: Random,

        /// The table for store node.
        inner: table::Table<u128, SkipListNode<V>>
    }

    /// The node of skip list.
    struct SkipListNode<V: store> has store {
        /// The score of node.
        score: u128,
        /// The next node score of node's each level.
        nexts: vector<OptionU128>,
        /// The prev node score of node.
        prev: OptionU128,
        /// The data being stored
        value: V,
    }

    /// Create a new empty skip list.
    public fun new<V: store>(max_level: u64, list_p: u64, seed: u64, ctx: &mut TxContext): SkipList<V> {
        let list = SkipList<V> {
            id: object::new(ctx),
            head: vector::empty(),
            tail: none(),
            level: 0,
            max_level,
            list_p,
            random: random::new(seed),
            inner: table::new(ctx)
        };
        list
    }

    /// Return the length of the skip list.
    public fun length<V: store>(list: &SkipList<V>): u64 {
        table::length(&list.inner)
    }

    /// Returns true if the skip list is empty (if `length` returns `0`)
    public fun is_empty<V: store>(list: &SkipList<V>): bool {
        table::length(&list.inner) == 0
    }

    /// Return the head of the skip list.
    public fun head<V: store>(list: &SkipList<V>): OptionU128 {
        if (is_empty(list)) {
            return none()
        };
        *vector::borrow(&list.head, 0)
    }

    /// Return the tail of the skip list.
    public fun tail<V: store>(list: &SkipList<V>): OptionU128 {
        list.tail
    }

    /// Destroys an empty skip list
    /// Aborts with `ETableNotEmpty` if the list still contains values
    public fun destroy_empty<V: store + drop>(list: SkipList<V>) {
        let SkipList<V> {
            id,
            head: _,
            tail: _,
            level: _,
            max_level: _,
            list_p: _,
            random: _,
            inner
        } = list;
        assert!(table::length(&inner) == 0, ESkipListNotEmpty);
        table::destroy_empty(inner);
        object::delete(id);
    }

    /// Returns true if there is a value associated with the score `score` in skip list `table: &SkipList<V>`
    public fun contains<V: store>(list: &SkipList<V>, score: u128): bool {
        table::contains(&list.inner, score)
    }

    /// Acquire an immutable reference to the `score` element of the skip list `list`.
    /// Aborts if element not exist.
    public fun borrow<V: store>(list: &SkipList<V>, score: u128): &V {
        let node = table::borrow(&list.inner, score);
        &node.value
    }

    /// Return a mutable reference to the `score` element in the skip list `list`.
    /// Aborts if element is not exist.
    public fun borrow_mut<V: store>(list: &mut SkipList<V>, score: u128): &mut V {
        let node = table::borrow_mut(&mut list.inner, score);
        &mut node.value
    }

    /// Acquire an immutable reference to the `score` node of the skip list `list`.
    /// Aborts if node not exist.
    public fun borrow_node<V: store>(list: &SkipList<V>, score: u128): &SkipListNode<V> {
        table::borrow(&list.inner, score)
    }

    /// Return a mutable reference to the `score` node in the skip list `list`.
    /// Aborts if node is not exist.
    public fun borrow_mut_node<V: store>(list: &mut SkipList<V>, score: u128): &mut SkipListNode<V> {
        table::borrow_mut(&mut list.inner, score)
    }

    /// Return the metadata info of skip list.
    public fun metadata<V: store>(list: &SkipList<V>): (vector<OptionU128>, OptionU128, u64, u64, u64, u64) {
        (
            list.head,
            list.tail,
            list.level,
            list.max_level,
            list.list_p,
            table::length(&list.inner)
        )
    }

    /// Return the next score of the node.
    public fun next_score<V: store>(node: &SkipListNode<V>): OptionU128 {
        *vector::borrow(&node.nexts, 0)
    }

    /// Return the prev score of the node.
    public fun prev_score<V: store>(node: &SkipListNode<V>): OptionU128 {
        node.prev
    }

    /// Return the immutable reference to the ndoe's value.
    public fun borrow_value<V: store>(node: &SkipListNode<V>): &V {
        &node.value
    }

    /// Return the mutable reference to the ndoe's value.
    public fun borrow_mut_value<V: store>(node: &mut SkipListNode<V>): &mut V {
        &mut node.value
    }

    /// Insert a score-value into skip list, abort if the score alread exist.
    public fun insert<V: store>(list: &mut SkipList<V>, score: u128, v: V) {
        assert!(!table::contains(&list.inner, score), ENodeAlreadyExist);
        let (level, new_node) = create_node(list, score, v);
        let (l, nexts, prev) = (list.level, &mut list.head, none());
        let opt_l0_next_score = none();
        while(l > 0) {
            let opt_next_score = vector::borrow_mut(nexts, l - 1);
            while (is_some_and_lte(opt_next_score, score)) {
                let node = table::borrow_mut(&mut list.inner, option_u128::borrow(opt_next_score));
                prev = some(node.score);
                nexts = &mut node.nexts;
                opt_next_score = vector::borrow_mut(nexts, l - 1);
            };
            if (level >= l) {
                vector::push_back(&mut new_node.nexts, *opt_next_score);
                if (l == 1) {
                    new_node.prev = prev;
                    if (is_some(opt_next_score)) {
                        opt_l0_next_score = *opt_next_score;
                    } else {
                        list.tail = some(score);
                    }
                };
                swap_or_fill(opt_next_score, score);
            };
            l = l - 1;
        };
        vector::reverse(&mut new_node.nexts);
        table::add(&mut list.inner, score, new_node);
        if (is_some(&opt_l0_next_score)) {
            let next_node = table::borrow_mut(&mut list.inner, option_u128::borrow(&opt_l0_next_score));
            next_node.prev = some(score);
        };
    }

    /// Remove the score-value from skip list, abort if the score not exist in list.
    public fun remove<V: store>(list: &mut SkipList<V>, score: u128): V {
        assert!(table::contains(&list.inner, score), ENodeDoesNotExist);
        let (l, nexts) = (list.level, &mut list.head);
        let node = table::remove(&mut list.inner, score);
        while (l > 0) {
            let opt_next_score = vector::borrow_mut(nexts, l - 1);
            while (is_some_and_lte(opt_next_score, score)) {
                let next_score = option_u128::borrow(opt_next_score);
                if (next_score == score) {
                    *opt_next_score = *vector::borrow(&node.nexts, l - 1);
                } else {
                    let node = table::borrow_mut(&mut list.inner, next_score);
                    nexts = &mut node.nexts;
                    opt_next_score = vector::borrow_mut(nexts, l - 1);
                }
            };
            l = l - 1;
        };

        if (option_u128::borrow(&list.tail) == score) {
            list.tail = node.prev;
        };

        let opt_l0_next_score = vector::borrow(&node.nexts, 0);
        if (is_some(opt_l0_next_score)) {
            let next_node = table::borrow_mut(&mut list.inner, option_u128::borrow(opt_l0_next_score));
            next_node.prev = node.prev;
        };

        drop_node(node)
    }

    /// Return the next score.
    public fun find_next<V: store>(list: &SkipList<V>, score: u128, include: bool): OptionU128 {
        let opt_finded_score = find(list, score);
        if (is_none(&opt_finded_score)) {
            return opt_finded_score
        };
        let finded_score = option_u128::borrow(&opt_finded_score);
        if ((include && finded_score == score) || (finded_score > score)) {
            return opt_finded_score
        };
        let node = borrow_node(list, finded_score);
        *vector::borrow(&node.nexts, 0)
    }

    /// Return the prev socre.
    public fun find_prev<V: store>(list: &SkipList<V>, score: u128, include: bool): OptionU128 {
        let opt_finded_score = find(list, score);
        if (is_none(&opt_finded_score)) {
            return opt_finded_score
        };
        let finded_score = option_u128::borrow(&opt_finded_score);
        if ((include && finded_score == score) || (finded_score < score)) {
            return opt_finded_score
        };
        let node = borrow_node(list, finded_score);
        node.prev
    }

    /// Find the nearest score. 1. score, 2. prev, 3. next
    fun find<V: store>(list: &SkipList<V>, score: u128): OptionU128 {
        let (l, nexts,current_score) = (list.level, &list.head, none());
        while (l > 0) {
            let opt_next_score = *vector::borrow(nexts, l - 1);
            while(is_some_and_lte(&opt_next_score, score)) {
                let next_score = option_u128::borrow(&opt_next_score);
                if (next_score == score) {
                    return some(next_score)
                } else {
                    let node = table::borrow(&list.inner, next_score);
                    current_score = opt_next_score;
                    nexts = &node.nexts;
                    opt_next_score = *vector::borrow(nexts, l - 1);
                };
            };
            if (l == 1 && is_some(&current_score)) {
                return current_score
            };
            l = l - 1;
        };
        return *vector::borrow(&list.head, 0)
    }

    fun rand_level<V: store>(seed: u64, list: &SkipList<V>): u64 {
        let level = 1;
        let mod = list.list_p;
        while ((seed % mod) == 0) {
            mod = mod * list.list_p;
            level = level + 1;
            if (level > list.level) {
                if (level >= list.max_level) {
                    level = list.max_level;
                    break
                } else {
                    level = list.level + 1;
                    break
                }
            }
        };
        level
    }

    /// Create a new skip list node
    fun create_node<V: store>(list: &mut SkipList<V>, score: u128, value: V): (u64, SkipListNode<V>) {
        let rand = random::rand(&mut list.random);
        let level = rand_level(rand, list);

        // Create a new level for skip list.
        if (level > list.level) {
            list.level = level;
            push_back(&mut list.head, none());
        };

        (
            level,
            SkipListNode<V> {
                score,
                nexts: vector::empty(),
                prev: none(),
                value
            }
        )
    }

    fun drop_node<V: store>(node: SkipListNode<V>): V {
        let SkipListNode {
            score: _,
            nexts: _,
            prev: _,
            value,
        } = node;
        value
    }

    // tests
    // ============================================================================================
    #[test_only]
    use sui::tx_context;
    #[test_only]
    use sui::transfer;
    #[test_only]
    use std::debug;

    #[test_only]
    #[allow(unused_function)]
    fun print_skip_list<V: store>(list: &SkipList<V>) {
        debug::print(list);
        if (length(list) == 0) {
            return
        };
        let next_score = vector::borrow(&list.head, 0);
        while (is_some(next_score)) {
            let node = table::borrow(&list.inner, option_u128::borrow(next_score));
            next_score = vector::borrow(&node.nexts, 0);
            debug::print(node);
        }
    }

    #[test_only]
    #[lint_allow(self_transfer)]
    fun check_skip_list<V: store>(list: &SkipList<V>) {
        if (list.level == 0) {
            assert!(table::length(&list.inner) == 0, 0);
            return
        };

        // Check level 0
        let (
            size,
            opt_next_score,
            tail,
            prev,
            current_score,
        ) = (
            0,
            vector::borrow(&list.head, 0),
            none(),
            none(),
            none()
        );
        while (is_some(opt_next_score)) {
            let next_score = option_u128::borrow(opt_next_score);
            let next_node = table::borrow(&list.inner, next_score);
            if (is_some(&current_score)) {
                assert!(next_score > option_u128::borrow(&current_score), 0);
            };
            assert!(next_node.score == next_score, 0);
            if (is_none(&prev)) {
                assert!(is_none(&next_node.prev), 0)
            } else {
                assert!(option_u128::borrow(&next_node.prev) == option_u128::borrow(&prev), 0);
            };
            prev = some(next_node.score);
            tail = some(next_node.score);
            //current_score = next_node.score;
            swap_or_fill(&mut current_score, next_node.score);
            size = size + 1;
            opt_next_score = vector::borrow(&next_node.nexts, 0);
        };
        if (is_none(&tail)) {
            assert!(is_none(&list.tail), 0);
        } else {
            assert!(option_u128::borrow(&list.tail) == option_u128::borrow(&tail), 0);
        };
        assert!(size == table::length(&list.inner), 0);

        // Check indexer levels
        let l = list.level - 1;
        while (l > 0) {
            let opt_next_l_score = vector::borrow(&list.head, l);
            let opt_next_0_score = vector::borrow(&list.head, 0);
            while(is_some(opt_next_0_score)) {
                let next_0_score = option_u128::borrow(opt_next_0_score);
                let node = table::borrow(&list.inner, next_0_score);
                if (is_none(opt_next_l_score) || option_u128::borrow(opt_next_l_score) > node.score) {
                    assert!(vector::length(&node.nexts) <= l, 0);
                } else {
                    if (vector::length(&node.nexts) > l) {
                        assert!(option_u128::borrow(opt_next_l_score) == node.score, 0);
                        opt_next_l_score = vector::borrow(&node.nexts, l);
                    }
                };
                opt_next_0_score = vector::borrow(&node.nexts, 0);
            };
            l = l - 1;
        };
    }

    #[test_only]
    #[lint_allow(self_transfer)]
    fun get_all_socres<V: store>(list: &SkipList<V>): vector<u128> {
        let (opt_next_score,scores ) = (vector::borrow(&list.head, 0), vector::empty<u128>());
        while (is_some(opt_next_score)) {
            let next_score = option_u128::borrow(opt_next_score);
            let next_node = table::borrow(&list.inner, next_score);
            vector::push_back(&mut scores, next_node.score);
            opt_next_score = vector::borrow(&next_node.nexts, 0);
        };
        scores
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_new() {
        let ctx = &mut tx_context::dummy();
        let skip_list = new<u256>(16, 2, 12345, ctx);
        check_skip_list(&skip_list);
        transfer::transfer(skip_list, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_create_node() {
        let ctx = &mut tx_context::dummy();
        let skip_list = new<u256>(16, 2, 12345, ctx);
        let n = 0;
        while (n < 10) {
            let (_, node) = create_node(&mut skip_list, n, 0);
            let SkipListNode{score:_, value:_, nexts:_, prev:_} = node;
            n = n + 1;
        };
        check_skip_list(&skip_list);
        transfer::transfer(skip_list, tx_context::sender(ctx));
    }

    #[test_only]
    fun add_node_for_test<V: store + copy + drop>(list: &mut SkipList<V>, size: u64, seed: u64, value: V) {
        let random = random::new(seed);
        let n = 0;
        while (n < size) {
            let score = (random::rand_n(&mut random, 1000000) as u128);
            if (contains(list, score)) {
                continue
            };
            insert(list, score, value);
            n = n + 1;
        };
        check_skip_list(list);
    }

    #[test_only]
    fun new_list_for_test<V: store + copy + drop>(
        max_leveL: u64, list_p: u64, size: u64, seed: u64, value: V, ctx: &mut TxContext
    ): SkipList<V> {
        let list = new<V>(max_leveL, list_p, seed, ctx);
        add_node_for_test(&mut list, size, seed, value);
        list
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_insert() {
        let ctx = &mut tx_context::dummy();
        let list = new_list_for_test<u256>(16, 2, 3000, 1234, 0, ctx);
        transfer::transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_insert_bench() {
        let ctx = &mut tx_context::dummy();
        let list = new<u256>(16, 2, 12345, ctx);
        let n = 0;
        while (n < 5001) {
            insert(&mut list, 0 + n, 0);
            insert(&mut list, 1000000 - n, 0);
            insert(&mut list, 100000 - n, 0);
            n = n + 1;
        };
        // debug::print(&list.level);
        transfer::transfer(list, tx_context::sender(ctx));
    }

    #[allow(unused_field)]
    struct Item has drop, store {
        n: u64,
        score: u64,
        finded: OptionU128
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_find() {
        let ctx = &mut tx_context::dummy();
        let list = new_list_for_test<u256>(16, 2, 1000, 12345, 0, ctx);
        let scores = get_all_socres(&list);

        let length = vector::length(&scores);
        let n = length;
        while ( n > 0) {
            let score = *vector::borrow(&scores, n - 1);
            let finded = find_prev(&list, score, true);
            assert!((is_some(&finded) && (option_u128::borrow(&finded) == score)), 0);
            let finded = find_prev(&list, score + 1, true);
            assert!(
                (is_some(&finded) && (option_u128::borrow(&finded) == score)) ||
                    (is_some(&finded) && (option_u128::borrow(&finded) == score + 1)),
                0
            );

            let finded = find_prev(&list, score, false);
            if (n >= 2) {
                assert!((is_some(&finded) && (option_u128::borrow(&finded) == *vector::borrow(&scores, n - 2))), 0);
            } else {
                assert!(is_none(&finded), 0);
            };

            let finded = find_next(&list, score, true);
            assert!((is_some(&finded) && (option_u128::borrow(&finded) == score)), 0);

            let finded = find_next(&list, score - 1, true);
            assert!(
                (is_some(&finded) && (option_u128::borrow(&finded) == score)) ||
                    (is_some(&finded) && (option_u128::borrow(&finded) == (score - 1))),
                0
            );

            let finded = find_next(&list, score, false);
            if (n < length) {
                assert!((is_some(&finded) && (option_u128::borrow(&finded) == *vector::borrow(&scores, n))), 0);
            } else {
                assert!(is_none(&finded), 0);
            };
            n = n - 1;
        };
        transfer::transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_find_bench() {
        let ctx = &mut tx_context::dummy();
        let list = new_list_for_test<u256>(16, 2, 1000, 12345, 0, ctx);
        let random = random::new(12345);
        let n = 0;
        while (n < 100) {
            let score = (random::rand_n(&mut random, 1000000) as u128);
            if ((n % 3) == 0) {
                score = score + 1;
            };
            find(&list, score);
            _ = score;
            n = n + 1;
        };
        transfer::transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_find_next_bench() {
        let ctx = &mut tx_context::dummy();
        let list = new_list_for_test<u256>(16, 2, 1000, 12345, 0, ctx);
        let n = 0;
        let finded = find_next(&list, 99999, true);
        while (n < 1 && is_some(&finded)) {
            let node = borrow_node(&list, option_u128::borrow(&finded));
            finded = next_score(node);
            n = n + 1;
        };
        transfer::transfer(list, tx_context::sender(ctx));
    }

    #[test]
    #[lint_allow(self_transfer)]
    fun test_remove() {
        let ctx = &mut tx_context::dummy();
        let list = new_list_for_test<u256>(16, 2, 1000, 5678, 0, ctx);
        let scores = get_all_socres(&list);
        let (n, length) = (0, vector::length(&scores));
        let start = length / 2;
        while(n <= start) {
            let s1 = start - n;
            let s2 = start + n;
            if (s1 >= 0) {
                remove(&mut list, *vector::borrow(&scores, s1));
            };
            if (s2 != s1 && s2 < length ) {
                remove(&mut list, *vector::borrow(&scores, s2));
            };
            n = n + 1;
        };
        check_skip_list(&list);

        add_node_for_test(&mut list, 2000, 7890, 0);
        let scores = get_all_socres(&list);
        let (n, length) = (0, vector::length(&scores));
        let skip = 0;
        while(n < length) {
            remove(&mut list, *vector::borrow(&scores, n));
            skip = skip + 1;
            n = n + skip;
        };
        check_skip_list(&list);

        transfer::transfer(list, tx_context::sender(ctx));
    }
}

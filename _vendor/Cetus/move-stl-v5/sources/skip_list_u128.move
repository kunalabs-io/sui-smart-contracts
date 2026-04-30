module move_stl::skip_list_u128 {
    use std::vector::push_back;
    use sui::table;
    use move_stl::option_u128::{Self, OptionU128, none, some, is_none, is_some, swap_or_fill, is_some_and_lte};
    use move_stl::random::{Self, Random};

    const ENodeAlreadyExist: u64 = 0;
    const ENodeDoesNotExist: u64 = 1;
    const ESkipListNotEmpty: u64 = 3;
    const EInvalidListP: u64 = 4;

    /// The skip list.
    public struct SkipList<V: store> has key, store{
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
    public struct SkipListNode<V: store> has store {
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
        assert!(list_p > 1, EInvalidListP);
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
        let (level, mut new_node) = create_node(list, score, v);
        let (mut l, mut nexts, mut prev) = (list.level, &mut list.head, none());
        let mut opt_l0_next_score = none();
        while(l > 0) {
            let mut opt_next_score = vector::borrow_mut(nexts, l - 1);
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
        let (mut l, mut nexts) = (list.level, &mut list.head);
        let node = table::remove(&mut list.inner, score);
        while (l > 0) {
            let mut opt_next_score = vector::borrow_mut(nexts, l - 1);
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
        if (list.level == 0) {
            return none()
        };
        let (mut l, mut nexts, mut current_score) = (list.level, &list.head, none());
        while (l > 0) {
            let mut opt_next_score = *vector::borrow(nexts, l - 1);
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
        let mut level = 1;
        let mut mod = list.list_p;
        while ((seed % mod) == 0 && level < list.level + 1) {
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

    // for tests
    // ============================================================================================
    #[test_only]
    use std::debug;

    #[allow(unused)]
    public struct Item has drop, store {
        n: u64,
        score: u64,
        finded: OptionU128,
    }

    #[test_only]
    public fun find_nearest<V: store>(list: &SkipList<V>, score: u128): OptionU128 {
        list.find(score)
    }

    #[test_only]
    public fun print_skip_list<V: store>(list: &SkipList<V>) {
        if (list.length() == 0) {
            return
        };
        let mut next_score = list.head();
        while (next_score.is_some()) {
            let node = list.borrow_node(next_score.borrow());
            next_score = node.next_score();
            debug::print(node);
        };
    }

    #[test_only]
    public fun check_skip_list<V: store>(list: &SkipList<V>) {
        if (list.level == 0) {
            assert!(length(list) == 0, 0);
            return
        };

        // Check level 0
        let (
            mut size,
            mut opt_next_score,
            mut tail,
            mut prev,
            mut current_score,
        ) = (
            0,
            list.head(),
            none(),
            none(),
            none()
        );
        while (opt_next_score.is_some()) {
            let next_score = opt_next_score.borrow();
            let next_node = list.borrow_node(next_score);
            if (current_score.is_some()) {
                assert!(next_score > current_score.borrow(), 0);
            };
            assert!(next_node.score == next_score, 0);
            if (prev.is_none()) {
                assert!(next_node.prev.is_none(), 0)
            } else {
                assert!(next_node.prev.borrow() == prev.borrow(), 0);
            };
            prev = some(next_node.score);
            tail = some(next_node.score);
            current_score.swap_or_fill(next_node.score);
            size = size + 1;
            opt_next_score = next_node.next_score();
        };
        if (tail.is_none()) {
            assert!(list.tail.is_none(), 0);
        } else {
            assert!(list.tail.borrow() == tail.borrow(), 0);
        };
        assert!(size == list.length(), 0);

        // Check indexer levels
        let mut l = list.level - 1;
        while (l > 0) {
            let mut opt_next_l_score = list.head.borrow(l);
            let mut opt_next_0_score = list.head.borrow(0);
            while(opt_next_0_score.is_some()) {
                let next_0_score = opt_next_0_score.borrow();
                let node = list.borrow_node(next_0_score);
                if (opt_next_l_score.is_none() || opt_next_l_score.borrow() > node.score) {
                    assert!(node.nexts.length() <= l, 0);
                } else {
                    if (node.nexts.length() > l) {
                        assert!(opt_next_l_score.borrow() == node.score, 0);
                        opt_next_l_score = node.nexts.borrow(l);
                    }
                };
                opt_next_0_score = node.nexts.borrow(0);
            };
            l = l - 1;
        };
    }

    #[test_only]
    public fun get_all_socres<V: store>(list: &SkipList<V>): vector<u128> {
        let (mut opt_next_score, mut scores ) = (list.head(), vector::empty<u128>());
        while (opt_next_score.is_some()) {
            let next_score = opt_next_score.borrow();
            let next_node = list.borrow_node(next_score);
            scores.push_back(next_node.score);
            opt_next_score = next_node.next_score();
        };
        scores
    }
}

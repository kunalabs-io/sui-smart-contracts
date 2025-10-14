module move_stl::skip_list {
    use std::vector::push_back;
    use move_stl::option_u64::{Self, OptionU64, none, some, is_none, is_some, swap_or_fill, is_some_and_lte};
    use move_stl::random::{Self, Random};
    use sui::dynamic_field as field;

    const ENodeAlreadyExist: u64 = 0;
    const ENodeDoesNotExist: u64 = 1;
    const ESkipListNotEmpty: u64 = 3;

    #[allow(unused_const)]
    const ESkipListIsEmpty: u64 = 4;
    const EInvalidListP: u64 = 5;

    /// The skip list.
    public struct SkipList<phantom V: store> has key, store {
        /// The id of this skip list.
        id: UID,
        /// The skip list header of each level. i.e. the score of node.
        head: vector<OptionU64>,
        /// The level0's tail of skip list. i.e. the score of node.
        tail: OptionU64,
        /// The current level of this skip list.
        level: u64,
        /// The max level of this skip list.
        max_level: u64,
        /// Basic probability of random of node indexer's level i.e. (list_p = 2, level2 = 1/2, level3 = 1/4).
        list_p: u64,

        /// The size of skip list
        size: u64,

        /// The random for generate ndoe's level
        random: Random,
    }

    /// The node of skip list.
    public struct Node<V: store> has store {
        /// The score of node.
        score: u64,
        /// The next node score of node's each level.
        nexts: vector<OptionU64>,
        /// The prev node score of node.
        prev: OptionU64,
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
            size: 0
        };
        list
    }

    /// Return the length of the skip list.
    public fun length<V: store>(list: &SkipList<V>): u64 {
        list.size
    }

    /// Returns true if the skip list is empty (if `length` returns `0`)
    public fun is_empty<V: store>(list: &SkipList<V>): bool {
        list.size == 0
    }

    /// Return the head of the skip list.
    public fun head<V: store>(list: &SkipList<V>): OptionU64 {
        if (is_empty(list)) {
            return none()
        };
        *vector::borrow(&list.head, 0)
    }

    /// Return the tail of the skip list.
    public fun tail<V: store>(list: &SkipList<V>): OptionU64 {
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
            size,
        } = list;
        assert!(size == 0, ESkipListNotEmpty);
        object::delete(id);
    }

    /// Returns true if there is a value associated with the score `score` in skip list
    public fun contains<V: store>(list: &SkipList<V>, score: u64): bool {
        field::exists_with_type<u64, Node<V>>(&list.id, score)
    }

    /// Acquire an immutable reference to the `score` element of the skip list `list`.
    /// Aborts if element not exist.
    public fun borrow<V: store>(list: &SkipList<V>, score: u64): &V {
        &field::borrow<u64, Node<V>>(&list.id, score).value
    }

    /// Return a mutable reference to the `score` element in the skip list `list`.
    /// Aborts if element is not exist.
    public fun borrow_mut<V: store>(list: &mut SkipList<V>, score: u64): &mut V {
        &mut field::borrow_mut<u64, Node<V>>(&mut list.id, score).value
    }

    /// Acquire an immutable reference to the `score` node of the skip list `list`.
    /// Aborts if node not exist.
    public fun borrow_node<V: store>(list: &SkipList<V>, score: u64): &Node<V> {
        field::borrow<u64, Node<V>>(&list.id, score)
    }

    /// Return a mutable reference to the `score` node in the skip list `list`.
    /// Aborts if node is not exist.
    public fun borrow_mut_node<V: store>(list: &mut SkipList<V>, score: u64): &mut Node<V> {
        field::borrow_mut<u64, Node<V>>(&mut list.id, score)
    }

    /// Return the metadata info of skip list.
    public fun metadata<V: store>(list: &SkipList<V>): (vector<OptionU64>, OptionU64, u64, u64, u64, u64) {
        (
            list.head,
            list.tail,
            list.level,
            list.max_level,
            list.list_p,
            list.size
        )
    }

    /// Return the next score of the node.
    public fun next_score<V: store>(node: &Node<V>): OptionU64 {
        *vector::borrow(&node.nexts, 0)
    }

    /// Return the prev score of the node.
    public fun prev_score<V: store>(node: &Node<V>): OptionU64 {
        node.prev
    }

    /// Return the immutable reference to the ndoe's value.
    public fun borrow_value<V: store>(node: &Node<V>): &V {
        &node.value
    }

    /// Return the mutable reference to the ndoe's value.
    public fun borrow_mut_value<V: store>(node: &mut Node<V>): &mut V {
        &mut node.value
    }

    /// Insert a score-value into skip list, abort if the score alread exist.
    public fun insert<V: store>(list: &mut SkipList<V>, score: u64, v: V) {
        assert!(!contains(list, score), ENodeAlreadyExist);
        let (level, mut new_node) = create_node(list, score, v);
        let (mut l, mut nexts, mut prev) = (list.level, &mut list.head, none());
        let mut opt_l0_next_score = none();
        while(l > 0) {
            let mut opt_next_score = vector::borrow_mut(nexts, l - 1);
            while (is_some_and_lte(opt_next_score, score)) {
                let node =
                    field::borrow_mut<u64, Node<V>>(&mut list.id, option_u64::borrow(opt_next_score));
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
        if (is_some(&opt_l0_next_score)) {
            let next_node = borrow_mut_node(list, option_u64::borrow(&opt_l0_next_score));
            next_node.prev = some(score);
        };

        vector::reverse(&mut new_node.nexts);
        field::add(&mut list.id, score, new_node);
        list.size = list.size + 1;
    }

    /// Remove the score-value from skip list, abort if the score not exist in list.
    public fun remove<V: store>(list: &mut SkipList<V>, score: u64): V {
        assert!(contains(list, score), ENodeDoesNotExist);
        let (mut l, mut nexts) = (list.level, &mut list.head);
        let node: Node<V> = field::remove(&mut list.id, score);
        while (l > 0) {
            let mut opt_next_score = vector::borrow_mut(nexts, l - 1);
            while (is_some_and_lte(opt_next_score, score)) {
                let next_score = option_u64::borrow(opt_next_score);
                if (next_score == score) {
                    *opt_next_score = *vector::borrow(&node.nexts, l - 1);
                } else {
                    let node = borrow_mut_node(list, next_score);
                    nexts = &mut node.nexts;
                    opt_next_score = vector::borrow_mut(nexts, l - 1);
                }
            };
            l = l - 1;
        };

        if (option_u64::borrow(&list.tail) == score) {
            list.tail = node.prev;
        };

        let opt_l0_next_score = vector::borrow(&node.nexts, 0);
        if (is_some(opt_l0_next_score)) {
            let next_node = borrow_mut_node(list, option_u64::borrow(opt_l0_next_score));
            next_node.prev = node.prev;
        };
        list.size = list.size - 1;

        drop_node(node)
    }

    /// Return the next score.
    public fun find_next<V: store>(list: &SkipList<V>, score: u64, include: bool): OptionU64 {
        let opt_finded_score = find(list, score);
        if (is_none(&opt_finded_score)) {
            return opt_finded_score
        };
        let finded_score = option_u64::borrow(&opt_finded_score);
        if ((include && finded_score == score) || (finded_score > score)) {
            return opt_finded_score
        };
        let node = borrow_node(list, finded_score);
        *vector::borrow(&node.nexts, 0)
    }

    /// Return the prev socre.
    public fun find_prev<V: store>(list: &SkipList<V>, score: u64, include: bool): OptionU64 {
        let opt_finded_score = find(list, score);
        if (is_none(&opt_finded_score)) {
            return opt_finded_score
        };
        let finded_score = option_u64::borrow(&opt_finded_score);
        if ((include && finded_score == score) || (finded_score < score)) {
            return opt_finded_score
        };
        let node = borrow_node(list, finded_score);
        node.prev
    }

    /// Find the nearest score. 1. score, 2. prev, 3. next
    fun find<V: store>(list: &SkipList<V>, score: u64): OptionU64 {
        if (list.size == 0) {
            return none()
        };
        let (mut l, mut nexts,mut current_score) = (list.level, &list.head, none());
        while (l > 0) {
            let mut opt_next_score = *vector::borrow(nexts, l - 1);
            while(is_some_and_lte(&opt_next_score, score)) {
                let next_score = option_u64::borrow(&opt_next_score);
                if (next_score == score) {
                    return some(next_score)
                } else {
                    let node = borrow_node(list, next_score);
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
    fun create_node<V: store>(list: &mut SkipList<V>, score: u64, value: V): (u64, Node<V>) {
        let rand = random::rand(&mut list.random);
        let level = rand_level(rand, list);

        // Create a new level for skip list.
        if (level > list.level) {
            list.level = level;
            push_back(&mut list.head, none());
        };

        (
            level,
            Node<V> {
                score,
                nexts: vector::empty(),
                prev: none(),
                value
            }
        )
    }

    fun drop_node<V: store>(node: Node<V>): V {
        let Node {
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
    use std::debug;

    #[allow(unused)]
    public struct Item has drop, store {
        n: u64,
        score: u64,
        finded: OptionU64,
    }

    #[test_only]
    public fun find_nearest<V: store>(list: &SkipList<V>, score: u64): OptionU64 {
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
    public fun get_all_socres<V: store>(list: &SkipList<V>): vector<u64> {
        let (mut opt_next_score,mut scores ) = (list.head(), vector::empty<u64>());
        while (opt_next_score.is_some()) {
            let next_score = opt_next_score.borrow();
            let next_node = list.borrow_node(next_score);
            scores.push_back(next_node.score);
            opt_next_score = next_node.next_score();
        };
        scores
    }
}

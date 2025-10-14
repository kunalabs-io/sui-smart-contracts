module move_stl::option_u128_tests {
    use move_stl::option_u128;
    use std::unit_test::assert_eq;

    #[test]
    fun test_some() {
        let o1 = option_u128::some(1);
        assert_eq!(o1.is_some(), true);
        assert_eq!(o1.is_none(), false);
        let o2 = option_u128::some(0);
        assert_eq!(o2.is_some(), true);
        assert_eq!(o2.is_none(), false);
    }

    #[test]
    fun test_none() {
        let o1 = option_u128::none();
        assert_eq!(o1.is_some(), false);
        assert_eq!(o1.is_none(), true);
    }

    #[test]
    fun test_borrow() {
        let o1 = option_u128::some(1);
        assert_eq!(o1.borrow(), 1);
        let o2 = option_u128::some(0);
        assert_eq!(o2.borrow(), 0);
    }

    #[test]
    #[expected_failure]
    fun test_borrow_none() {
        let o1 = option_u128::none();
        o1.borrow();
    }

    #[test]
    fun test_borrow_mut() {
        let mut o1 = option_u128::some(1);
        *o1.borrow_mut() = 2;
        assert_eq!(o1.borrow(), 2);
    }

    #[test]
    #[expected_failure]
    fun test_borrow_mut_none() {
        let mut o1 = option_u128::none();
        *o1.borrow_mut() = 2;
    }

    #[test]
    fun test_swap_or_fill() {
        let mut o1 = option_u128::none();
        o1.swap_or_fill(1);
        assert_eq!(o1.borrow(), 1);
        o1.swap_or_fill(2);
        assert_eq!(o1.borrow(), 2);

        let mut o2 = option_u128::some(3);
        o2.swap_or_fill(4);
        assert_eq!(o2.borrow(), 4);
    }

    #[test]
    fun test_contains() {
        let o1 = option_u128::some(1);
        assert_eq!(o1.contains(1), true);
        assert_eq!(o1.contains(2), false);

        let o2 = option_u128::none();
        assert_eq!(o2.contains(1), false);
        assert_eq!(o2.contains(2), false);
    }

    #[test]
    fun test_is_some_and_lte() {
        let o1 = option_u128::some(10);
        assert_eq!(o1.is_some_and_lte(10), true);
        assert_eq!(o1.is_some_and_lte(11), true);
        assert_eq!(o1.is_some_and_lte(9), false);

        let o2 = option_u128::some(0);
        assert_eq!(o2.is_some_and_lte(0), true);
        assert_eq!(o2.is_some_and_lte(1), true);
        assert_eq!(o2.is_some_and_lte(2), true);

        let o3 = option_u128::none();
        assert_eq!(o3.is_some_and_lte(0), false);
        assert_eq!(o3.is_some_and_lte(1), false);
        assert_eq!(o3.is_some_and_lte(2), false);
    }

    #[test]
    fun test_is_some_and_eq() {
        let o1 = option_u128::some(10);
        assert_eq!(o1.is_some_and_eq(10), true);
        assert_eq!(o1.is_some_and_eq(11), false);
        assert_eq!(o1.is_some_and_eq(9), false);

        let o2 = option_u128::none();
        assert_eq!(o2.is_some_and_eq(10), false);
        assert_eq!(o2.is_some_and_eq(11), false);
        assert_eq!(o2.is_some_and_eq(9), false);
    }

}
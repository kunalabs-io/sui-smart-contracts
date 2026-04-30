module integer_mate::math_u256_tests {
    use integer_mate::math_u256::{
        div_mod,
        shlw,
        shrw,
        checked_shlw,
        div_round,
        add_check,
    };

    #[test]
    fun test_div_mod() {
        let (v, r) = div_mod(0, 1);
        assert!(v == 0 && r == 0, 0);
        let (v, r) = div_mod(1, 1);
        assert!(v == 1 && r == 0, 0);
        let (v, r) = div_mod(1, 2);
        assert!(v == 0 && r == 1, 0);
        let (v, r) = div_mod(10000000, 3);
        assert!(v == 3333333 && r == 1, 0);
        let (v, r) = div_mod(10000000, 7);
        assert!(v == 1428571 && r == 3, 0);
        let (v, r) = div_mod(10000, 10000000);
        assert!(v == 0 && r == 10000, 0);
        let (v, r) = div_mod(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0x3b9aca00);
        assert!(v == 0x44b82fa09b5a52cb98b405447c4a98187eebb22f008d5d64f9c394ae9 && r == 0x7ba25ff, 0);
        let (v, r) = div_mod(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0bdbf);
        assert!(v == 1 && r == 1000000, 0);
        let (v, r) = div_mod(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        assert!(v == 2 && r == 1, 0);
    }

    #[test]
    #[expected_failure]
    fun test_div_mod_zero() {
        div_mod(1, 0);
    }

    #[test]
    fun test_shlw() {
        assert!(shlw(0) == 0, 0);
        assert!(shlw(1) == 0x10000000000000000, 0);
        assert!(shlw(10000000) == 0x9896800000000000000000, 0);
        assert!(shlw(0x3b9aca00) == 0x3b9aca000000000000000000, 0);
        assert!(shlw(0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffffffffffffffffffff0000000000000000, 0);
        assert!(shlw(0) == 0, 0);
    }
    
    #[test]
    fun test_shrw() {
        assert!(shrw(0) == 0, 0);
        assert!(shrw(1) == 0, 0);
        assert!(shrw(10000000) == 0, 0);
        assert!(shrw(0x3b9aca00) == 0, 0);
        assert!(shrw(0xffffffffffffffffffffffffffffffff) == 0xffffffffffffffff, 0);
        assert!(shrw(0) == 0, 0);
    }

    #[test]
    fun test_checked_shlw() {
        let (v, overflow) = checked_shlw(0);
        assert!(v == 0 && !overflow, 0);
        let (v, overflow) = checked_shlw(1);
        assert!(v == 0x10000000000000000 && !overflow, 0);
        let (v, overflow) = checked_shlw(10000000);
        assert!(v == 0x9896800000000000000000 && !overflow, 0);
        let (v, overflow) = checked_shlw(0x3b9aca00);
        assert!(v == 0x3b9aca000000000000000000 && !overflow, 0);
        let (v, overflow) = checked_shlw(0xffffffffffffffff);
        assert!(v == 0xffffffffffffffff0000000000000000 && !overflow, 0);
        let (v, overflow) = checked_shlw(0xffffffffffffffffffffffffffffffff);
        assert!(v == 0xffffffffffffffffffffffffffffffff0000000000000000 && !overflow, 0);
        let (v, overflow) = checked_shlw(1<<192);
        assert!(v == 0 && overflow, 0);
        let (v, overflow) = checked_shlw(1<<192 + 1);
        assert!(v == 0 && overflow, 0);
    }

    #[test]
    fun test_div_round() {
        assert!(div_round(0, 1, false) == 0, 0);
        assert!(div_round(1, 1, false) == 1, 0);
        assert!(div_round(1, 2, false) == 0, 0);
        assert!(div_round(10000000, 3, false) == 3333333, 0);
        assert!(div_round(10000000, 7, false) == 1428571, 0);
        assert!(div_round(10000, 10000000, false) == 0, 0);
        assert!(div_round(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0x3b9aca00, false) == 0x44b82fa09b5a52cb98b405447c4a98187eebb22f008d5d64f9c394ae9, 0);
        assert!(div_round(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0bdbf, false) == 1, 0);
        assert!(div_round(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, false) == 2, 0);
        assert!(div_round(0, 1, true) == 0, 0);
        assert!(div_round(1, 1, true) == 1, 0);
        assert!(div_round(1, 2, true) == 1, 0);
        assert!(div_round(10000000, 3, true) == 3333334, 0);
        assert!(div_round(10000000, 7, true) == 1428572, 0);
        assert!(div_round(10000, 10000000, true) == 1, 0);
        assert!(div_round(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0x3b9aca00, true) == 0x44b82fa09b5a52cb98b405447c4a98187eebb22f008d5d64f9c394aea, 0);
        assert!(div_round(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0bdbf, true) == 2, 0);
        assert!(div_round(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, true) == 3, 0);
    }

    #[test]
    #[expected_failure]
    fun test_div_round_zero() {
        div_round(1, 0, false);
    }

    #[test]
    fun test_add_check() {
        assert!(add_check(0, 0) == true, 0);
        assert!(add_check(0, 1) == true, 0);
        assert!(add_check(1, 0) == true, 0);
        assert!(add_check(1, 2) == true, 0);
        assert!(add_check(10000000, 3) == true, 0);
        assert!(add_check(10000000, 7) == true, 0);
        assert!(add_check(10000, 10000000) == true, 0);
        assert!(add_check(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0x3b9aca00) == false, 0);
        assert!(add_check(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0bdbf) == false, 0);
        assert!(add_check(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) == false, 0);
    }
}
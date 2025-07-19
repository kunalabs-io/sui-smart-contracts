module move_stl::option_u128 {
    #[test_only]
    use std::option;

    const EOptionU128IsNone: u64 = 0;

    struct OptionU128 has copy, drop, store {
        is_none: bool,
        v: u128
    }

    public fun some(v: u128): OptionU128 {
        OptionU128 {
            is_none: false,
            v
        }
    }

    public fun none(): OptionU128 {
        OptionU128 {
            is_none: true,
            v: 0
        }
    }

    public fun borrow(opt: &OptionU128): u128 {
        assert!(!opt.is_none, EOptionU128IsNone);
        opt.v
    }

    public fun borrow_mut(opt: &mut OptionU128): &mut u128 {
        assert!(!opt.is_none, EOptionU128IsNone);
        &mut opt.v
    }

    public fun swap_or_fill(opt: &mut OptionU128, v: u128) {
        opt.is_none = false;
        opt.v = v;
    }

    public fun is_some(opt: &OptionU128): bool {
        !opt.is_none
    }

    public fun is_none(opt: &OptionU128): bool {
        opt.is_none
    }

    public fun contains(opt: &OptionU128, e_ref: u128): bool {
        if (opt.is_none) {
            return false
        };
        (opt.v == e_ref)
    }

    public fun is_some_and_eq(opt: &OptionU128, v: u128): bool {
        ((!opt.is_none) && (opt.v == v))
    }

    public fun is_some_and_lte(opt: &OptionU128, v: u128): bool {
        (!opt.is_none) && (opt.v <= v)
    }

    #[test]
    fun test_opt() {
        let a = some(10000u128);
        let n = 0;
        while (n < 10000) {
            _ = borrow(&a);
            n = n + 1;
        };
    }

    #[test]
    fun test_option_contains() {
        let a = option::some(100000);
        let n = 0;
        while (n < 10000) {
            option::contains(&a, &100000);
            n = n + 1;
        }
    }
}

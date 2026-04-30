module move_stl::option_u64 {
    const EOptionU64IsNone: u64 = 0;

    public struct OptionU64 has copy, drop, store {
        is_none: bool,
        v: u64
    }

    public fun some(v: u64): OptionU64 {
        OptionU64 {
            is_none: false,
            v
        }
    }

    public fun none(): OptionU64 {
        OptionU64 {
            is_none: true,
            v: 0
        }
    }

    public fun borrow(opt: &OptionU64): u64 {
        assert!(!opt.is_none, EOptionU64IsNone);
        opt.v
    }

    public fun borrow_mut(opt: &mut OptionU64): &mut u64 {
        assert!(!opt.is_none, EOptionU64IsNone);
        &mut opt.v
    }

    public fun swap_or_fill(opt: &mut OptionU64, v: u64) {
        opt.is_none = false;
        opt.v = v;
    }

    public fun is_some(opt: &OptionU64): bool {
        !opt.is_none
    }

    public fun is_none(opt: &OptionU64): bool {
        opt.is_none
    }

    public fun contains(opt: &OptionU64, e_ref: u64): bool {
        ((!opt.is_none) && (opt.v == e_ref))
    }

    public fun is_some_and_lte(opt: &OptionU64, v: u64): bool {
        (!opt.is_none) && (opt.v <= v)
    }
}

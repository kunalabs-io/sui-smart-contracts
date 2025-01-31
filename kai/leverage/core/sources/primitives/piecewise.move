module kai_leverage::piecewise {
    use kai_leverage::util;

    /* ================= errors ================= */

    /// Piecewise must have at least one section
    const ENoSections: u64 = 0;
    /// x is out of range
    const EOutOfRange: u64 = 1;

    /* ================= types ================= */

    public struct Section has store, copy, drop {
        end: u64,
        end_val: u64,
    }

    public struct Piecewise has store, copy, drop {
        start: u64,
        start_val: u64,
        sections: vector<Section>,
    }

    /* ================= functions ================= */

    public fun section(end: u64, end_val: u64): Section {
        Section {
            end,
            end_val,
        }
    }

    public fun create(start: u64, start_val: u64, sections: vector<Section>): Piecewise {
        assert!(sections.length() > 0, ENoSections);

        Piecewise {
            start: start,
            start_val: start_val,
            sections: sections,
        }   
    }

    public fun value_at(pw: &Piecewise, x: u64): u64 {
        assert!(x >= pw.start, EOutOfRange);

        let len = pw.sections.length();
        let last_section = pw.sections[len - 1];
        assert!(x <= last_section.end, EOutOfRange);

        if (x == pw.start) {
            return pw.start_val
        };

        let mut cs_start = pw.start;
        let mut cs_start_val = pw.start_val;
        let mut cs = pw.sections[0];
        let mut idx = 0;
        while (x > cs.end) {
            cs_start = cs.end;
            cs_start_val = cs.end_val;
            cs = pw.sections[idx + 1];
            idx = idx + 1;
        };
        if (x == cs.end) {
            return cs.end_val
        };
        if (cs_start_val == cs.end_val) {
            return cs_start_val
        };

        let sdy = util::abs_diff(cs.end_val, cs_start_val);
        let sdx = util::abs_diff(cs.end, cs_start);
        let dx = x - cs_start;

        let dy = util::muldiv(sdy, dx, sdx);

        if (cs_start_val < cs.end_val) {
            cs_start_val + dy
        } else {
            cs_start_val - dy
        }
    }

    public fun range(pw: &Piecewise): (u64, u64) {
        let len = pw.sections.length();
        let last_section = pw.sections[len -1];
        (pw.start, last_section.end)
    }

    /* ================= testing ================= */

    #[test]
    fun test_piecewise() {
        let mut sections = vector::empty();
        vector::push_back(&mut sections, section(50_00, 5_00));
        vector::push_back(&mut sections, section(70_00, 7_00));
        vector::push_back(&mut sections, section(80_00, 4_00));
        vector::push_back(&mut sections, section(100_00, 4_00));

        let pw = create(0, 2_00, sections);

        assert!(value_at(&pw, 0) == 2_00, 0);
        assert!(value_at(&pw, 12_00) == 2_72, 0);
        assert!(value_at(&pw, 25_00) == 3_50, 0);
        assert!(value_at(&pw, 65_00) == 6_50, 0);
        assert!(value_at(&pw, 70_00) == 7_00, 0);
        assert!(value_at(&pw, 71_00) == 6_70, 0);
        assert!(value_at(&pw, 75_00) == 5_50, 0);
        assert!(value_at(&pw, 80_00) == 4_00, 0);
        assert!(value_at(&pw, 81_00) == 4_00, 0);
        assert!(value_at(&pw, 89_00) == 4_00, 0);
        assert!(value_at(&pw, 100_00) == 4_00, 0);
    }

    #[test]
    #[expected_failure(abort_code = ENoSections)]
    fun test_no_sections() {
        let sections = vector::empty();
        create(0, 2_00, sections);
    }

    #[test]
    #[expected_failure(abort_code = EOutOfRange)]
    fun test_out_of_range_start() {
        let mut sections = vector::empty();
        vector::push_back(&mut sections, section(50_00, 5_00));
        let pw = create(5_00, 2_00, sections);

        value_at(&pw, 4_99);
    }

    #[test]
    #[expected_failure(abort_code = EOutOfRange)]
    fun test_out_of_range_end() {
        let mut sections = vector::empty();
        vector::push_back(&mut sections, section(50_00, 5_00));
        let pw = create(5_00, 2, sections);

        value_at(&pw, 50_01);
    }
}
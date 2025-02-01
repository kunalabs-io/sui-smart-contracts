module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i64 {

    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i64;

    struct I64 has copy, drop, store {
        bits: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun zero(): i64::I64;
 #[native_interface]
    native public fun from_u64(a0: u64): i64::I64;
 #[native_interface]
    native public fun from(a0: u64): i64::I64;
 #[native_interface]
    native public fun neg_from(a0: u64): i64::I64;
 #[native_interface]
    native public fun wrapping_add(a0: i64::I64, a1: i64::I64): i64::I64;
 #[native_interface]
    native public fun add(a0: i64::I64, a1: i64::I64): i64::I64;
 #[native_interface]
    native public fun wrapping_sub(a0: i64::I64, a1: i64::I64): i64::I64;
 #[native_interface]
    native public fun sub(a0: i64::I64, a1: i64::I64): i64::I64;
 #[native_interface]
    native public fun mul(a0: i64::I64, a1: i64::I64): i64::I64;
 #[native_interface]
    native public fun div(a0: i64::I64, a1: i64::I64): i64::I64;
 #[native_interface]
    native public fun abs(a0: i64::I64): i64::I64;
 #[native_interface]
    native public fun abs_u64(a0: i64::I64): u64;
 #[native_interface]
    native public fun shl(a0: i64::I64, a1: u8): i64::I64;
 #[native_interface]
    native public fun shr(a0: i64::I64, a1: u8): i64::I64;
 #[native_interface]
    native public fun mod(a0: i64::I64, a1: i64::I64): i64::I64;
 #[native_interface]
    native public fun as_u64(a0: i64::I64): u64;
 #[native_interface]
    native public fun sign(a0: i64::I64): u8;
 #[native_interface]
    native public fun is_neg(a0: i64::I64): bool;
 #[native_interface]
    native public fun cmp(a0: i64::I64, a1: i64::I64): u8;
 #[native_interface]
    native public fun eq(a0: i64::I64, a1: i64::I64): bool;
 #[native_interface]
    native public fun gt(a0: i64::I64, a1: i64::I64): bool;
 #[native_interface]
    native public fun gte(a0: i64::I64, a1: i64::I64): bool;
 #[native_interface]
    native public fun lt(a0: i64::I64, a1: i64::I64): bool;
 #[native_interface]
    native public fun lte(a0: i64::I64, a1: i64::I64): bool;
 #[native_interface]
    native public fun or(a0: i64::I64, a1: i64::I64): i64::I64;
 #[native_interface]
    native public fun and(a0: i64::I64, a1: i64::I64): i64::I64;

}

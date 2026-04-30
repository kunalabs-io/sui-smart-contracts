module integer_mate::full_math_u64 {
    public fun mul_div_floor(num1: u64, num2: u64, denom: u64): u64 {
        let r = full_mul(num1, num2) / (denom as u128);
        (r as u64)
    }
    
    public fun mul_div_round(num1: u64, num2: u64, denom: u64): u64 {
        let r = (full_mul(num1, num2) + ((denom as u128) >> 1)) / (denom as u128);
        (r as u64)
    }
    
    public fun mul_div_ceil(num1: u64, num2: u64, denom: u64): u64 {
        let r = (full_mul(num1, num2) + ((denom as u128) - 1)) / (denom as u128);
        (r as u64)
    }
    
    public fun mul_shr(num1: u64, num2: u64, shift: u8): u64 {
        let r = full_mul(num1, num2) >> shift;
        (r as u64)
    }
    
    public fun mul_shl(num1: u64, num2: u64, shift: u8): u64 {
        let r = full_mul(num1, num2) << shift;
        (r as u64)
    }

    public fun full_mul(num1: u64, num2: u64): u128 {
        ((num1 as u128) * (num2 as u128))
    }
}


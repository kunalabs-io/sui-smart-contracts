module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::expect_swap {

    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::pool;
    use 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::expect_swap;

    struct ExpectSwapResult has copy, drop, store {
        amount_in: u256,
        amount_out: u256,
        fee_amount: u256,
        fee_rate: u64,
        after_sqrt_price: u128,
        is_exceed: bool,
        step_results: vector<expect_swap::SwapStepResult>,
    }
    struct SwapStepResult has copy, drop, store {
        current_sqrt_price: u128,
        target_sqrt_price: u128,
        current_liquidity: u128,
        amount_in: u256,
        amount_out: u256,
        fee_amount: u256,
        remainder_amount: u64,
    }
    struct SwapResult has copy, drop {
        amount_in: u256,
        amount_out: u256,
        fee_amount: u256,
        ref_fee_amount: u256,
        steps: u64,
    }
    struct ExpectSwapResultEvent has copy, drop, store {
        data: expect_swap::ExpectSwapResult,
        current_sqrt_price: u128,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun get_expect_swap_result<T0, T1>(a0: &pool::Pool<T0, T1>, a1: bool, a2: bool, a3: u64);
    native public fun expect_swap<T0, T1>(a0: &pool::Pool<T0, T1>, a1: bool, a2: bool, a3: u64): expect_swap::ExpectSwapResult;
    native public fun expect_swap_result_amount_out(a0: &expect_swap::ExpectSwapResult): u256;
    native public fun expect_swap_result_is_exceed(a0: &expect_swap::ExpectSwapResult): bool;
    native public fun expect_swap_result_amount_in(a0: &expect_swap::ExpectSwapResult): u256;
    native public fun expect_swap_result_after_sqrt_price(a0: &expect_swap::ExpectSwapResult): u128;
    native public fun expect_swap_result_fee_amount(a0: &expect_swap::ExpectSwapResult): u256;
    native public fun expect_swap_result_step_results(a0: &expect_swap::ExpectSwapResult): &vector<expect_swap::SwapStepResult>;
    native public fun expect_swap_result_steps_length(a0: &expect_swap::ExpectSwapResult): u64;
    native public fun expect_swap_result_step_swap_result(a0: &expect_swap::ExpectSwapResult, a1: u64): &expect_swap::SwapStepResult;
    native public fun step_swap_result_amount_in(a0: &expect_swap::SwapStepResult): u256;
    native public fun step_swap_result_amount_out(a0: &expect_swap::SwapStepResult): u256;
    native public fun step_swap_result_fee_amount(a0: &expect_swap::SwapStepResult): u256;
    native public fun step_swap_result_current_sqrt_price(a0: &expect_swap::SwapStepResult): u128;
    native public fun step_swap_result_target_sqrt_price(a0: &expect_swap::SwapStepResult): u128;
    native public fun step_swap_result_current_liquidity(a0: &expect_swap::SwapStepResult): u128;
    native public fun step_swap_result_remainder_amount(a0: &expect_swap::SwapStepResult): u64;
    native public fun compute_swap_step(a0: u128, a1: u128, a2: u128, a3: u64, a4: u64, a5: bool, a6: bool): (u256, u256, u128, u256);

}

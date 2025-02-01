module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::fee_collector {

    use sui::balance;
    use sui::coin;
    use sui::sui;
    use sui::tx_context;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::fee_collector;

    struct FeeCollector has store {
        fee_amount: u64,
        balance: balance::Balance<sui::SUI>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun new(a0: u64): fee_collector::FeeCollector;
 #[native_interface]
    native public fun fee_amount(a0: &fee_collector::FeeCollector): u64;
 #[native_interface]
    native public fun balance_value(a0: &fee_collector::FeeCollector): u64;
 #[native_interface]
    native public fun deposit_balance(a0: &mut fee_collector::FeeCollector, a1: balance::Balance<sui::SUI>);
 #[native_interface]
    native public fun deposit(a0: &mut fee_collector::FeeCollector, a1: coin::Coin<sui::SUI>);
 #[native_interface]
    native public fun withdraw_balance(a0: &mut fee_collector::FeeCollector, a1: u64): balance::Balance<sui::SUI>;
 #[native_interface]
    native public fun withdraw(a0: &mut fee_collector::FeeCollector, a1: u64, a2: &mut tx_context::TxContext): coin::Coin<sui::SUI>;
 #[native_interface]
    native public fun change_fee(a0: &mut fee_collector::FeeCollector, a1: u64);

}

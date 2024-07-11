module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::flash_loan {

    use 0x1::type_name;
    use sui::coin;
    use sui::tx_context;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::reserve;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

    struct BorrowFlashLoanEvent has copy, drop {
        borrower: address,
        asset: type_name::TypeName,
        amount: u64,
    }
    struct RepayFlashLoanEvent has copy, drop {
        borrower: address,
        asset: type_name::TypeName,
        amount: u64,
    }
    struct BorrowFlashLoanV2Event has copy, drop {
        borrower: address,
        asset: type_name::TypeName,
        amount: u64,
        fee: u64,
        fee_discount_numerator: u64,
        fee_discount_denominator: u64,
    }
    struct RepayFlashLoanV2Event has copy, drop {
        borrower: address,
        asset: type_name::TypeName,
        amount: u64,
        fee: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun borrow_flash_loan<T0>(a0: &version::Version, a1: &mut market::Market, a2: u64, a3: &mut tx_context::TxContext): (coin::Coin<T0>, reserve::FlashLoan<T0>);
 #[native_interface]
    native public fun repay_flash_loan<T0>(a0: &version::Version, a1: &mut market::Market, a2: coin::Coin<T0>, a3: reserve::FlashLoan<T0>, a4: &mut tx_context::TxContext);

}

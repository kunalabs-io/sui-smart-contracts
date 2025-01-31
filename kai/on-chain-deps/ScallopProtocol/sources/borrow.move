module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow {

    use 0x1::type_name;
    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle;
    use 0xCA5A5A62F01C79A104BF4D31669E29DAA387F325C241DE4EDBE30986A9BC8B0D::coin_decimals_registry;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow_referral;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

    struct BorrowEvent has copy, drop {
        borrower: address,
        obligation: object::ID,
        asset: type_name::TypeName,
        amount: u64,
        time: u64,
    }
    struct BorrowEventV2 has copy, drop {
        borrower: address,
        obligation: object::ID,
        asset: type_name::TypeName,
        amount: u64,
        borrow_fee: u64,
        time: u64,
    }
    struct BorrowEventV3 has copy, drop {
        borrower: address,
        obligation: object::ID,
        asset: type_name::TypeName,
        amount: u64,
        borrow_fee: u64,
        borrow_fee_discount: u64,
        borrow_referral_fee: u64,
        time: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public entry fun borrow_entry<T0>(a0: &version::Version, a1: &mut obligation::Obligation, a2: &obligation::ObligationKey, a3: &mut market::Market, a4: &coin_decimals_registry::CoinDecimalsRegistry, a5: u64, a6: &x_oracle::XOracle, a7: &clock::Clock, a8: &mut tx_context::TxContext);
 #[native_interface]
    native public fun borrow_with_referral<T0, T1: drop>(a0: &version::Version, a1: &mut obligation::Obligation, a2: &obligation::ObligationKey, a3: &mut market::Market, a4: &coin_decimals_registry::CoinDecimalsRegistry, a5: &mut borrow_referral::BorrowReferral<T0, T1>, a6: u64, a7: &x_oracle::XOracle, a8: &clock::Clock, a9: &mut tx_context::TxContext): coin::Coin<T0>;
 #[native_interface]
    native public fun borrow<T0>(a0: &version::Version, a1: &mut obligation::Obligation, a2: &obligation::ObligationKey, a3: &mut market::Market, a4: &coin_decimals_registry::CoinDecimalsRegistry, a5: u64, a6: &x_oracle::XOracle, a7: &clock::Clock, a8: &mut tx_context::TxContext): coin::Coin<T0>;

}

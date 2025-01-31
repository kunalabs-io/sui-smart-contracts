module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::deposit_collateral {

    use 0x1::type_name;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

    struct CollateralDepositEvent has copy, drop {
        provider: address,
        obligation: object::ID,
        deposit_asset: type_name::TypeName,
        deposit_amount: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public entry fun deposit_collateral<T0>(a0: &version::Version, a1: &mut obligation::Obligation, a2: &mut market::Market, a3: coin::Coin<T0>, a4: &mut tx_context::TxContext);

}

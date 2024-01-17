module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::repay {

    use 0x1::type_name;
    use sui::clock;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version;

    struct RepayEvent has copy, drop {
        repayer: address,
        obligation: object::ID,
        asset: type_name::TypeName,
        amount: u64,
        time: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun repay<T0>(a0: &version::Version, a1: &mut obligation::Obligation, a2: &mut market::Market, a3: coin::Coin<T0>, a4: &clock::Clock, a5: &mut tx_context::TxContext);

}

module scallop_protocol::deposit_collateral {

    use 0x1::type_name;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use scallop_protocol::market;
    use scallop_protocol::obligation;
    use scallop_protocol::version;

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

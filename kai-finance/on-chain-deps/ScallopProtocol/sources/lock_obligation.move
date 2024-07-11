module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::lock_obligation {

    use 0x1::type_name;
    use sui::clock;
    use sui::object;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle;
    use 0xCA5A5A62F01C79A104BF4D31669E29DAA387F325C241DE4EDBE30986A9BC8B0D::coin_decimals_registry;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;

    struct ObligationUnhealthyUnlocked has copy, drop {
        obligation: object::ID,
        witness: type_name::TypeName,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun force_unlock_unhealthy<T0: drop>(a0: &mut obligation::Obligation, a1: &mut market::Market, a2: &coin_decimals_registry::CoinDecimalsRegistry, a3: &x_oracle::XOracle, a4: &clock::Clock, a5: T0);

}

module 0xCA5A5A62F01C79A104BF4D31669E29DAA387F325C241DE4EDBE30986A9BC8B0D::coin_decimals_registry {

    use 0x1::ascii;
    use 0x1::type_name;
    use sui::coin;
    use sui::object;
    use sui::table;
    use 0xCA5A5A62F01C79A104BF4D31669E29DAA387F325C241DE4EDBE30986A9BC8B0D::coin_decimals_registry;

    struct COIN_DECIMALS_REGISTRY has drop {
        dummy_field: bool,
    }
    struct CoinDecimalsRegistry has store, key {
        id: object::UID,
        table: table::Table<type_name::TypeName, u8>,
    }
    struct CoinDecimalsRegistered has copy, drop {
        registry: address,
        coin_type: ascii::String,
        decimals: u8,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public entry fun register_decimals<T0>(a0: &mut coin_decimals_registry::CoinDecimalsRegistry, a1: &coin::CoinMetadata<T0>);
 #[native_interface]
    native public fun decimals(a0: &coin_decimals_registry::CoinDecimalsRegistry, a1: type_name::TypeName): u8;
 #[native_interface]
    native public fun registry_table(a0: &coin_decimals_registry::CoinDecimalsRegistry): &table::Table<type_name::TypeName, u8>;

}

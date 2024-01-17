module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::asset_active_state {

    use 0x1::type_name;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::asset_active_state;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;

    friend market;

    struct BaseAssetActiveStates has drop {
        dummy_field: bool,
    }
    struct CollateralActiveStates has drop {
        dummy_field: bool,
    }
    struct AssetActiveStates has store {
        base: wit_table::WitTable<asset_active_state::BaseAssetActiveStates, type_name::TypeName, bool>,
        collateral: wit_table::WitTable<asset_active_state::CollateralActiveStates, type_name::TypeName, bool>,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public(friend) fun new(a0: &mut tx_context::TxContext): asset_active_state::AssetActiveStates;
    native public(friend) fun is_base_asset_active(a0: &asset_active_state::AssetActiveStates, a1: type_name::TypeName): bool;
    native public(friend) fun is_collateral_active(a0: &asset_active_state::AssetActiveStates, a1: type_name::TypeName): bool;
    native public(friend) fun set_base_asset_active_state(a0: &mut asset_active_state::AssetActiveStates, a1: type_name::TypeName, a2: bool);
    native public(friend) fun set_collateral_active_state(a0: &mut asset_active_state::AssetActiveStates, a1: type_name::TypeName, a2: bool);

}

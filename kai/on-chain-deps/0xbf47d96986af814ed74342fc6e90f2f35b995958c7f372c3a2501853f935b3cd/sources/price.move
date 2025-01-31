module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::price {

    use 0x1::fixed_point32;
    use 0x1::type_name;
    use sui::clock;
    use 0x1478A432123E4B3D61878B629F2C692969FDB375644F1251CD278A4B1E7D7CD6::x_oracle;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun get_price(a0: &x_oracle::XOracle, a1: type_name::TypeName, a2: &clock::Clock): fixed_point32::FixedPoint32;

}

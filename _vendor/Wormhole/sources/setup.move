module 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::setup {

    use sui::object;
    use sui::package;
    use sui::tx_context;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::setup;

    struct DeployerCap has store, key {
        id: object::UID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun complete(a0: setup::DeployerCap, a1: package::UpgradeCap, a2: u16, a3: vector<u8>, a4: u32, a5: vector<vector<u8>>, a6: u32, a7: u64, a8: &mut tx_context::TxContext);

}

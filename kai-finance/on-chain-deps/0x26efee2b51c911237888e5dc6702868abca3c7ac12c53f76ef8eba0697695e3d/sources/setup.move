module 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::setup {

    use sui::object;
    use sui::package;
    use sui::tx_context;
    use 0x26EFEE2B51C911237888E5DC6702868ABCA3C7AC12C53F76EF8EBA0697695E3D::setup;
    use 0x5306F64E312B581766351C07AF79C72FCB1CD25147157FDC2F8AD76DE9A3FB6A::emitter;

    struct DeployerCap has store, key {
        id: object::UID,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun complete(a0: setup::DeployerCap, a1: package::UpgradeCap, a2: emitter::EmitterCap, a3: u16, a4: vector<u8>, a5: &mut tx_context::TxContext);

}

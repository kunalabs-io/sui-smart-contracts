module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::pool_creator_v3 {

    use 0x1::string;
    use sui::clock;
    use sui::coin;
    use sui::tx_context;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::factory;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun create_pool_v3<T0, T1>(a0: &config::GlobalConfig, a1: &mut factory::Pools, a2: u32, a3: u128, a4: string::String, a5: u32, a6: u32, a7: &mut coin::Coin<T0>, a8: &mut coin::Coin<T1>, a9: bool, a10: &clock::Clock, a11: &mut tx_context::TxContext);
    native public entry fun create_pool_v3_with_creation_cap<T0, T1>(a0: &config::GlobalConfig, a1: &mut factory::Pools, a2: &factory::PoolCreationCap, a3: u32, a4: u128, a5: string::String, a6: u32, a7: u32, a8: &mut coin::Coin<T0>, a9: &mut coin::Coin<T1>, a10: bool, a11: &clock::Clock, a12: &mut tx_context::TxContext);

}

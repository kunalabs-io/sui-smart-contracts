module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::incentive_rewards {

    use 0x1::fixed_point32;
    use 0x1::type_name;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::incentive_rewards;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;

    friend app;
    friend market;

    struct RewardFactors has drop {
        dummy_field: bool,
    }
    struct RewardFactor has store {
        coin_type: type_name::TypeName,
        reward_factor: fixed_point32::FixedPoint32,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun reward_factor(a0: &incentive_rewards::RewardFactor): fixed_point32::FixedPoint32;
 #[native_interface]
    native public(friend) fun init_table(a0: &mut tx_context::TxContext): wit_table::WitTable<incentive_rewards::RewardFactors, type_name::TypeName, incentive_rewards::RewardFactor>;
 #[native_interface]
    native public(friend) fun set_reward_factor<T0>(a0: &mut wit_table::WitTable<incentive_rewards::RewardFactors, type_name::TypeName, incentive_rewards::RewardFactor>, a1: u64, a2: u64);

}

module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::config_script {

    use 0x1::string;
    use sui::package;
    use sui::tx_context;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun update_protocol_fee_rate(a0: &mut config::GlobalConfig, a1: u64, a2: &tx_context::TxContext);
    native public entry fun add_fee_tier(a0: &mut config::GlobalConfig, a1: u32, a2: u64, a3: &tx_context::TxContext);
    native public entry fun update_fee_tier(a0: &mut config::GlobalConfig, a1: u32, a2: u64, a3: &tx_context::TxContext);
    native public entry fun delete_fee_tier(a0: &mut config::GlobalConfig, a1: u32, a2: &tx_context::TxContext);
    native public entry fun set_roles(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u128);
    native public entry fun add_role(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u8);
    native public entry fun remove_role(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u8);
    native public entry fun remove_member(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address);
    native public entry fun set_position_display(a0: &config::GlobalConfig, a1: &package::Publisher, a2: string::String, a3: string::String, a4: string::String, a5: string::String, a6: &mut tx_context::TxContext);

}

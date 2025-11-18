module 0x996C4D9480708FB8B92AA7ACF819FB0497B5EC8E65BA06601CAE2FB6DB3312C3::partner_script {

    use 0x1::string;
    use sui::clock;
    use sui::tx_context;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::config;
    use 0x1EABED72C53FEB3805120A081DC15963C204DC8D091542592ABAF7A35689B2FB::partner;

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public entry fun create_partner(a0: &config::GlobalConfig, a1: &mut partner::Partners, a2: string::String, a3: u64, a4: u64, a5: u64, a6: address, a7: &clock::Clock, a8: &mut tx_context::TxContext);
    native public entry fun update_partner_ref_fee_rate(a0: &config::GlobalConfig, a1: &mut partner::Partner, a2: u64, a3: &tx_context::TxContext);
    native public entry fun update_partner_time_range(a0: &config::GlobalConfig, a1: &mut partner::Partner, a2: u64, a3: u64, a4: &clock::Clock, a5: &mut tx_context::TxContext);
    native public entry fun claim_ref_fee<T0>(a0: &config::GlobalConfig, a1: &partner::PartnerCap, a2: &mut partner::Partner, a3: &mut tx_context::TxContext);

}

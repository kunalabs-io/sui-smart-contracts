#[test_only]
module cetus_clmm::config_tests;

use cetus_clmm::acl;
use cetus_clmm::config::{
    Self,
    check_fee_tier_manager_role,
    check_pool_manager_role,
    check_rewarder_manager_role,
    check_partner_manager_role,
    remove_role
};
use sui::transfer::{public_share_object, public_transfer};
use sui::tx_context::sender;
use sui::vec_map;
use std::unit_test::assert_eq;
use cetus_clmm::config::check_protocol_fee_claim_role;

#[test]
fun test_update_protocol_fee_rate() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    assert!(config::protocol_fee_rate(&config) == 1000, 0);
    config::update_protocol_fee_rate(&mut config, 2000, &ctx);
    assert!(config::protocol_fee_rate(&config) == 2000, 0);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}


#[test]
#[expected_failure(abort_code = cetus_clmm::config::EInvalidProtocolFeeRate)]
fun test_update_protocol_fee_rate_max_exceed() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    assert!(config::protocol_fee_rate(&config) == 1000, 0);
    config::update_protocol_fee_rate(&mut config, 10000, &ctx);
    assert!(config::protocol_fee_rate(&config) == 2000, 0);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EFeeTierAlreadyExist)]
fun test_add_fee_tier_already_exist(){
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::add_fee_tier(&mut config, 2, 2000, &ctx);
    config::add_fee_tier(&mut config, 2, 2000, &ctx);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
fun test_fee_tier() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 2, 2000, &ctx);
    let fee_tiers = config.fee_tiers();
    let fee_tier = fee_tiers.get(&2);
    assert_eq!(fee_tier.tick_spacing(), 2);
    assert_eq!(fee_tier.fee_rate(), 2000);
    assert!(config::get_fee_rate(2, &config) == 2000, 0);
    config::update_fee_tier(&mut config, 2, 1000, &ctx);
    assert!(config::get_fee_rate(2, &config) == 1000, 0);
    config::delete_fee_tier(&mut config, 2, &ctx);
    let fee_tiers = config::fee_tiers(&config);
    assert!(vec_map::is_empty(fee_tiers), 0);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EInvalidFeeRate)]
fun test_fee_tier_invalid_fee_rate() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 2, 210000, &ctx);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EInvalidTickSpacing)]
fun test_fee_tier_invalid_tick_spacing() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 444444, 200000, &ctx);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EInvalidTickSpacing)]
fun test_fee_tier_invalid_tick_spacing_2() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 0, 200000, &ctx);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
fun test_delete_fee_tier() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 200, 2000, &ctx);
    config::delete_fee_tier(&mut config, 200, &ctx);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EFeeTierNotFound)]
fun test_delete_fee_tier_not_found() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 200, 2000, &ctx);
    config::delete_fee_tier(&mut config, 2, &ctx);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
fun test_update_fee_tier() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 200, 2000, &ctx);
    let fee_tier = config::get_fee_rate(200, &config);
    assert_eq!(fee_tier, 2000);
    config::update_fee_tier(&mut config, 200, 1000, &ctx);
    let fee_tier = config::get_fee_rate(200, &config);
    assert_eq!(fee_tier, 1000);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EFeeTierNotFound)]
fun test_update_fee_tier_not_found() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 200, 2000, &ctx);
    config::update_fee_tier(&mut config, 2, 1000, &ctx);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EInvalidFeeRate)]
fun test_update_fee_tier_fee_rate_max_exceed() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);

    config::add_fee_tier(&mut config, 200, 2000, &ctx);
    config::update_fee_tier(&mut config, 200, 220000, &ctx);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EPackageVersionDeprecate)]
fun test_package_version() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::update_package_version(&admin_cap, &mut config, 14);
    config::add_fee_tier(&mut config, 2, 2000, &ctx);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

const ACL_POOL_MANAGER: u8 = 0;
const ACL_FEE_TIER_MANAGER: u8 = 1;
const ACL_CLAIM_PROTOCOL_FEE: u8 = 2;
const ACL_PARTNER_MANAGER: u8 = 3;
const ACL_REWARDER_MANAGER: u8 = 4;

#[test]
fun test_acl() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_POOL_MANAGER), 0);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_FEE_TIER_MANAGER), 0);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_REWARDER_MANAGER), 0);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_CLAIM_PROTOCOL_FEE), 0);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_PARTNER_MANAGER), 0);

    assert!(!acl::has_role(config::acl(&config), @0x12345, ACL_POOL_MANAGER), 0);
    assert!(!acl::has_role(config::acl(&config), @0x12345, ACL_FEE_TIER_MANAGER), 0);
    assert!(!acl::has_role(config::acl(&config), @0x12345, ACL_REWARDER_MANAGER), 0);
    assert!(!acl::has_role(config::acl(&config), @0x12345, ACL_CLAIM_PROTOCOL_FEE), 0);
    assert!(!acl::has_role(config::acl(&config), @0x12345, ACL_PARTNER_MANAGER), 0);

    let roles = 0u128 | (1 << ACL_POOL_MANAGER) | (1 << ACL_FEE_TIER_MANAGER);
    config::set_roles(&admin_cap, &mut config, @0x12345, roles);
    assert!(acl::has_role(config::acl(&config), @0x12345, ACL_POOL_MANAGER), 0);
    assert!(acl::has_role(config::acl(&config), @0x12345, ACL_FEE_TIER_MANAGER), 0);

    config::remove_role(&admin_cap, &mut config, sender(&ctx), ACL_FEE_TIER_MANAGER);
    config::remove_role(&admin_cap, &mut config, sender(&ctx), ACL_CLAIM_PROTOCOL_FEE);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_POOL_MANAGER), 0);
    assert!(!acl::has_role(config::acl(&config), sender(&ctx), ACL_FEE_TIER_MANAGER), 0);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_REWARDER_MANAGER), 0);
    assert!(!acl::has_role(config::acl(&config), sender(&ctx), ACL_CLAIM_PROTOCOL_FEE), 0);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_PARTNER_MANAGER), 0);

    config::remove_member(&admin_cap, &mut config, @0x12345);
    assert!(!acl::has_role(config::acl(&config), @0x12345, ACL_POOL_MANAGER), 0);
    assert!(!acl::has_role(config::acl(&config), @0x12345, ACL_FEE_TIER_MANAGER), 0);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::ENoFeeTierManagerPermission)]
fun test_acl_expect_failure() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::remove_role(&admin_cap, &mut config, sender(&ctx), ACL_FEE_TIER_MANAGER);
    config::remove_role(&admin_cap, &mut config, sender(&ctx), ACL_CLAIM_PROTOCOL_FEE);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_POOL_MANAGER), 0);
    assert!(!acl::has_role(config::acl(&config), sender(&ctx), ACL_FEE_TIER_MANAGER), 0);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_REWARDER_MANAGER), 0);
    assert!(!acl::has_role(config::acl(&config), sender(&ctx), ACL_CLAIM_PROTOCOL_FEE), 0);
    assert!(acl::has_role(config::acl(&config), sender(&ctx), ACL_PARTNER_MANAGER), 0);
    config::add_fee_tier(&mut config, 2, 2000, &ctx);

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
fun test_check_role() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, config) = config::new_global_config_for_test(&mut ctx, 1000);
    check_fee_tier_manager_role(&config, sender(&ctx));
    check_rewarder_manager_role(&config, sender(&ctx));
    check_partner_manager_role(&config, sender(&ctx));
    check_pool_manager_role(&config, sender(&ctx));

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::ENoFeeTierManagerPermission)]
fun test_check_role_failure() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    check_fee_tier_manager_role(&config, sender(&ctx));
    check_rewarder_manager_role(&config, sender(&ctx));
    check_partner_manager_role(&config, sender(&ctx));
    check_pool_manager_role(&config, sender(&ctx));
    remove_role(&admin_cap, &mut config, sender(&ctx), ACL_FEE_TIER_MANAGER);
    check_fee_tier_manager_role(&config, sender(&ctx));

    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EPackageVersionDeprecate)]
fun test_emergency_pause() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::add_role(&admin_cap, &mut config, sender(&ctx), 5);
    config::emergency_pause(&mut config, &ctx);
    config::checked_package_version(&config);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::ENoPartnerManagerPermission)]
fun test_check_partner_manager_role() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    check_partner_manager_role(&config, sender(&ctx));
    config::remove_member(&admin_cap, &mut config, sender(&ctx));
    check_partner_manager_role(&config, sender(&ctx));
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::ENoProtocolFeeClaimPermission)]
fun test_check_protocol_fee_claim_role() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    check_protocol_fee_claim_role(&config, sender(&ctx));
    config::remove_member(&admin_cap, &mut config, sender(&ctx));
    check_protocol_fee_claim_role(&config, sender(&ctx));
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::ENoRewarderManagerPermission)]
fun test_check_rewarder_manager_role() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    check_rewarder_manager_role(&config, sender(&ctx));
    config::remove_member(&admin_cap, &mut config, sender(&ctx));
    check_rewarder_manager_role(&config, sender(&ctx));
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::ENoPoolManagerPemission)]
fun test_check_pool_manager_role() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::check_pool_manager_role(&config, sender(&ctx));
    config::remove_member(&admin_cap, &mut config, sender(&ctx));
    config::check_pool_manager_role(&config, sender(&ctx));
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::ENoEmergencyPausePermission)]
fun test_check_emergency_pause_role() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::check_emergency_pause_role(&config, sender(&ctx));
    config::remove_member(&admin_cap, &mut config, sender(&ctx));
    config::check_emergency_pause_role(&config, sender(&ctx));
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
fun test_read_config() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, config) = config::new_global_config_for_test(&mut ctx, 1000);
    assert_eq!(config::max_protocol_fee_rate(), 3000);
    assert_eq!(config::get_protocol_fee_rate(&config), 1000);
    assert_eq!(config.get_members().length(),1);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EInvalidPackageVersion)]
fun test_check_emergency_restore_version() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::update_package_version(&admin_cap, &mut config, 18446744073709551000);
    config::check_emergency_restore_version(&config);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EConfigVersionNotEqualEmergencyRestoreVersion)]
fun test_check_emergency_restore_version_failure() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::update_package_version(&admin_cap, &mut config, 13);
    config::check_emergency_restore_version(&config);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::config::EProtocolNotEmergencyPause)]
fun test_emergency_unpause() {
    let mut ctx = tx_context::dummy();
    let (admin_cap, mut config) = config::new_global_config_for_test(&mut ctx, 1000);
    config::add_role(&admin_cap, &mut config, sender(&ctx), 5);
    config::emergency_unpause(&mut config, 13, &ctx);
    public_share_object(config);
    public_transfer(admin_cap, tx_context::sender(&ctx));
}

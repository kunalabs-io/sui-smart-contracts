// Copyright (c) Cetus Technology Limited

/// The global config module is used for manage the `protocol_fee`, acl roles, fee_tiers and package version of the cetus clmmpool protocol.
/// The `protocol_fee` is the protocol fee rate, it will be charged when user swap token.
/// The `fee_tiers` is a map, the key is the tick spacing, the value is the fee rate. the fee_rate can be same for
/// different tick_spacing and can be updated.
/// For different types of pair, we can use different tick spacing. Basically, for stable pair we can use small tick
/// spacing, for volatile pair we can use large tick spacing.
/// the fee generated of a swap is calculated by the following formula:
/// total_fee = fee_rate * swap_in_amount.
/// protocol_fee = total_fee * protocol_fee_rate / 1000000
/// lp_fee = total_fee - protocol_fee
/// Also, the acl roles is managed by this module, the roles is used for control the access of the cetus clmmpool
/// protocol.
/// Currently, we have 5 roles:
/// 1. PoolManager: The pool manager can update pool fee rate, pause and unpause the pool.
/// 2. FeeTierManager: The fee tier manager can add/remove fee tier, update fee tier fee rate.
/// 3. ClaimProtocolFee: The claim protocol fee can claim the protocol fee.
/// 4. PartnerManager: The partner manager can add/remove partner, update partner fee rate.
/// 5. RewarderManager: The rewarder manager can add/remove rewarder, update rewarder fee rate.
/// 6. EmergencyPause: The emergency pause can emergency pause the protocol.
/// The package version is used for upgrade the package, when upgrade the package, we need increase the package version.
module cetus_clmm::config;

use cetus_clmm::acl;
use sui::dynamic_field;
use sui::event::{Self, emit};
use sui::vec_map::{Self, VecMap};

/// Max swap fee rate(100000 = 200000/1000000 = 20%)
const MAX_FEE_RATE: u64 = 200000;
/// Max protocol fee rate(100000 = 3000/1000000 = 0.3%)
const MAX_PROTOCOL_FEE_RATE: u64 = 3000;
/// Default protocol fee rate(100000 = 2000/1000000 = 0.2%)
const DEFAULT_PROTOCOL_FEE_RATE: u64 = 2000;

const TICK_SPACING_200: u32 = 200;
const TICK_SPACING_200_FEE_RATE: u64 = 10000;

/// ACL role constants:
/// - ACL_POOL_MANAGER (0): Can update pool fee rate, pause and unpause pools
/// - ACL_FEE_TIER_MANAGER (1): Can add/remove fee tiers and update fee tier rates
/// - ACL_CLAIM_PROTOCOL_FEE (2): Can claim protocol fees
/// - ACL_PARTNER_MANAGER (3): Can add/remove partners and update partner fee rates
/// - ACL_REWARDER_MANAGER (4): Can add/remove rewarders and update rewarder rates
/// - ACL_EMERGENCY_PAUSE (5): Can trigger emergency pause functionality
const ACL_POOL_MANAGER: u8 = 0;
const ACL_FEE_TIER_MANAGER: u8 = 1;
const ACL_CLAIM_PROTOCOL_FEE: u8 = 2;
const ACL_PARTNER_MANAGER: u8 = 3;
const ACL_REWARDER_MANAGER: u8 = 4;
const ACL_EMERGENCY_PAUSE: u8 = 5;

/// The version of this package, need increase it when upgrade the package.
const VERSION: u64 = 13;
/// The version of the package that requires an emergency restore
const EMERGENCY_RESTORE_NEED_VERSION: u64 = 18446744073709551000;
/// The version of the package that requires an emergency pause
const EMERGENCY_PAUSE_VERSION: u64 = 9223372036854775808;

const EMERGENCY_PAUSE_BEFORE_VERSION: vector<u8> = b"emergency_pause_before";

const MAX_TICK_SPACING: u32 = 1000;

/// Error codes for the config module
const EFeeTierAlreadyExist: u64 = 1;
const EFeeTierNotFound: u64 = 2;
const EInvalidFeeRate: u64 = 3;
const EInvalidProtocolFeeRate: u64 = 4;
const ENoPoolManagerPemission: u64 = 5;
const ENoFeeTierManagerPermission: u64 = 6;
const ENoPartnerManagerPermission: u64 = 7;
const ENoRewarderManagerPermission: u64 = 8;
const ENoProtocolFeeClaimPermission: u64 = 9;
const EPackageVersionDeprecate: u64 = 10;
const EInvalidTickSpacing: u64 = 11;
const EConfigVersionNotEqualEmergencyRestoreVersion: u64 = 12;
const ENoEmergencyPausePermission: u64 = 13;
const EProtocolNotEmergencyPause: u64 = 14;
const EProtocolAlreadyEmergencyPause: u64 = 15;
const EInvalidPackageVersion: u64 = 16;

/// `AdminCap` is a capability token that grants administrative privileges to its holder.
public struct AdminCap has key, store {
    id: UID,
}

/// This struct is redundant.
public struct ProtocolFeeClaimCap has key, store {
    id: UID,
}

/// FeeTier represents a fee configuration for a specific tick spacing.
///
/// # Fields
/// * `tick_spacing` - The spacing between ticks for this fee tier
/// * `fee_rate` - The fee rate charged for trades, denominated in basis points
public struct FeeTier has copy, drop, store {
    tick_spacing: u32,
    fee_rate: u64,
}

/// GlobalConfig represents the global configuration for the CLMM protocol.
///
/// # Fields
/// * `id` - The unique identifier for this configuration
/// * `protocol_fee_rate` - The protocol fee rate, expressed as a basis point value
/// * `fee_tiers` - A map of fee tiers, where the key is the tick spacing and the value is the fee tier configuration
/// * `acl` - The access control list for the protocol
/// * `package_version` - The current package version
public struct GlobalConfig has key, store {
    id: UID,
    protocol_fee_rate: u64,
    fee_tiers: VecMap<u32, FeeTier>,
    acl: acl::ACL,
    package_version: u64,
}

// === Events ===

/// Event emitted when the `GlobalConfig` and `AdminCap` are initialized
/// * `admin_cap_id` - The unique identifier of the admin cap
/// * `global_config_id` - The unique identifier of the global config
public struct InitConfigEvent has copy, drop {
    admin_cap_id: ID,
    global_config_id: ID,
}

/// Event emitted when the protocol fee rate is updated
/// * `old_fee_rate` - The old protocol fee rate
/// * `new_fee_rate` - The new protocol fee rate
public struct UpdateFeeRateEvent has copy, drop {
    old_fee_rate: u64,
    new_fee_rate: u64,
}

/// Event emitted when a fee tier is added
/// * `tick_spacing` - The tick spacing of the fee tier
/// * `fee_rate` - The fee rate of the fee tier
public struct AddFeeTierEvent has copy, drop {
    tick_spacing: u32,
    fee_rate: u64,
}

/// Event emitted when a fee tier is updated
/// * `tick_spacing` - The tick spacing of the fee tier
/// * `old_fee_rate` - The old fee rate of the fee tier
/// * `new_fee_rate` - The new fee rate of the fee tier
public struct UpdateFeeTierEvent has copy, drop {
    tick_spacing: u32,
    old_fee_rate: u64,
    new_fee_rate: u64,
}

/// Event emitted when a fee tier is deleted
/// * `tick_spacing` - The tick spacing of the fee tier
/// * `fee_rate` - The fee rate of the fee tier
public struct DeleteFeeTierEvent has copy, drop {
    tick_spacing: u32,
    fee_rate: u64,
}

/// Event emitted when roles are set
/// * `member` - The address of the member
/// * `roles` - The roles of the member
public struct SetRolesEvent has copy, drop {
    member: address,
    roles: u128,
}

/// Event emitted when a role is added to a member
/// * `member` - The address of the member
/// * `role` - The role that was added
public struct AddRoleEvent has copy, drop {
    member: address,
    role: u8,
}

/// Event emitted when a role is removed from a member
/// * `member` - The address of the member
/// * `role` - The role that was removed
public struct RemoveRoleEvent has copy, drop {
    member: address,
    role: u8,
}

/// Event emitted when a member is removed from the ACL
/// * `member` - The address of the member
public struct RemoveMemberEvent has copy, drop {
    member: address,
}

/// Event emitted when the package version is updated
/// * `new_version` - The new package version
/// * `old_version` - The old package version
public struct SetPackageVersion has copy, drop {
    new_version: u64,
    old_version: u64,
}

/// Initialize the `GlobalConfig` and `AdminCap`
/// * `ctx` - Transaction context used to create the `GlobalConfig` and `AdminCap`
fun init(ctx: &mut TxContext) {
    let (mut global_config, admin_cap) = (
        GlobalConfig {
            id: object::new(ctx),
            protocol_fee_rate: DEFAULT_PROTOCOL_FEE_RATE,
            fee_tiers: vec_map::empty(),
            acl: acl::new(ctx),
            package_version: 1,
        },
        AdminCap {
            id: object::new(ctx),
        },
    );
    let (global_config_id, admin_cap_id) = (object::id(&global_config), object::id(&admin_cap));

    // Set default roles for deployer.
    let sender = tx_context::sender(ctx);
    let roles =
        0u128 | (1 << ACL_POOL_MANAGER) | (1 << ACL_FEE_TIER_MANAGER) | (1 << ACL_REWARDER_MANAGER) | (1 << ACL_PARTNER_MANAGER);
    set_roles(&admin_cap, &mut global_config, sender, roles);
    global_config.add_fee_tier(TICK_SPACING_200, TICK_SPACING_200_FEE_RATE, ctx);
    transfer::transfer(admin_cap, sender);
    transfer::share_object(global_config);

    event::emit(InitConfigEvent {
        admin_cap_id,
        global_config_id,
    });
}

/// Update the protocol fee rate
/// * `config` - The global config
/// * `protocol_fee_rate` - The new protocol fee rate
/// * `ctx` - Transaction context used to update the protocol fee rate
public fun update_protocol_fee_rate(
    config: &mut GlobalConfig,
    protocol_fee_rate: u64,
    ctx: &TxContext,
) {
    assert!(protocol_fee_rate <= MAX_PROTOCOL_FEE_RATE, EInvalidProtocolFeeRate);
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    let old_protocol_fee = config.protocol_fee_rate;
    config.protocol_fee_rate = protocol_fee_rate;

    event::emit(UpdateFeeRateEvent {
        old_fee_rate: old_protocol_fee,
        new_fee_rate: protocol_fee_rate,
    });
}

/// Add a fee tier
/// * `config` - The global config
/// * `tick_spacing` - The tick spacing
/// * `fee_rate` - The fee rate
/// * `ctx` - Transaction context used to add the fee tier
public fun add_fee_tier(
    config: &mut GlobalConfig,
    tick_spacing: u32,
    fee_rate: u64,
    ctx: &TxContext,
) {
    assert!(fee_rate <= MAX_FEE_RATE, EInvalidFeeRate);
    assert!(!vec_map::contains(&config.fee_tiers, &tick_spacing), EFeeTierAlreadyExist);
    checked_package_version(config);
    check_fee_tier_manager_role(config, tx_context::sender(ctx));

    assert!(tick_spacing > 0 && tick_spacing <= MAX_TICK_SPACING, EInvalidTickSpacing);
    vec_map::insert(
        &mut config.fee_tiers,
        tick_spacing,
        FeeTier {
            tick_spacing,
            fee_rate,
        },
    );

    event::emit(AddFeeTierEvent {
        tick_spacing,
        fee_rate,
    })
}

/// Delete a fee tier by `tick_spacing`.
/// * `config` - The global config
/// * `tick_spacing` - The tick spacing
/// * `ctx` - Transaction context used to delete the fee tier
public fun delete_fee_tier(config: &mut GlobalConfig, tick_spacing: u32, ctx: &TxContext) {
    assert!(vec_map::contains(&config.fee_tiers, &tick_spacing), EFeeTierNotFound);
    checked_package_version(config);
    check_fee_tier_manager_role(config, tx_context::sender(ctx));

    let (_, v) = vec_map::remove(&mut config.fee_tiers, &tick_spacing);
    event::emit(DeleteFeeTierEvent {
        tick_spacing,
        fee_rate: v.fee_rate,
    })
}

/// Update the fee rate of a FeeTier by `tick_spacing`.
/// * `config` - The global config
/// * `tick_spacing` - The tick spacing
/// * `new_fee_rate` - The new fee rate
/// * `ctx` - Transaction context used to update the fee tier
public fun update_fee_tier(
    config: &mut GlobalConfig,
    tick_spacing: u32,
    new_fee_rate: u64,
    ctx: &TxContext,
) {
    assert!(vec_map::contains(&config.fee_tiers, &tick_spacing), EFeeTierNotFound);
    assert!(new_fee_rate <= MAX_FEE_RATE, EInvalidFeeRate);
    checked_package_version(config);
    check_fee_tier_manager_role(config, tx_context::sender(ctx));

    let fee_tier = vec_map::get_mut(&mut config.fee_tiers, &tick_spacing);
    let old_fee_rate = fee_tier.fee_rate;
    fee_tier.fee_rate = new_fee_rate;

    event::emit(UpdateFeeTierEvent {
        tick_spacing,
        old_fee_rate,
        new_fee_rate,
    });
}

/// Set role for member.
/// * `admin_cap` - The admin cap
/// * `config` - The global config
/// * `member` - The member address
/// * `roles` - The roles
public fun set_roles(_: &AdminCap, config: &mut GlobalConfig, member: address, roles: u128) {
    checked_package_version(config);
    acl::set_roles(&mut config.acl, member, roles);
    emit(SetRolesEvent {
        member,
        roles,
    })
}

/// Add a role for member.
/// * `admin_cap` - The admin cap
/// * `config` - The global config
/// * `member` - The member address
/// * `role` - The role
public fun add_role(_: &AdminCap, config: &mut GlobalConfig, member: address, role: u8) {
    checked_package_version(config);
    acl::add_role(&mut config.acl, member, role);
    emit(AddRoleEvent {
        member,
        role,
    })
}

/// Remove a role for member.
/// * `admin_cap` - The admin cap
/// * `config` - The global config
/// * `member` - The member address
/// * `role` - The role
public fun remove_role(_: &AdminCap, config: &mut GlobalConfig, member: address, role: u8) {
    checked_package_version(config);
    acl::remove_role(&mut config.acl, member, role);
    emit(RemoveRoleEvent {
        member,
        role,
    })
}

/// Remove a member from ACL.
/// * `admin_cap` - The admin cap
/// * `config` - The global config
/// * `member` - The member address
public fun remove_member(_: &AdminCap, config: &mut GlobalConfig, member: address) {
    checked_package_version(config);
    acl::remove_member(&mut config.acl, member);
    emit(RemoveMemberEvent {
        member,
    })
}

/// Get all members in the ACL
/// * `config` - The global config
/// * Returns a vector of ACL members
public fun get_members(config: &GlobalConfig): vector<acl::Member> {
    acl::get_members(&config.acl)
}

/// Get the protocol fee rate
/// * `global_config` - The global config
/// * Returns the protocol fee rate
public fun get_protocol_fee_rate(global_config: &GlobalConfig): u64 {
    global_config.protocol_fee_rate
}

/// Get fee rate by tick spacing
/// * `tick_spacing` - The tick spacing
/// * `global_config` - The global config
/// * Returns the fee rate
public fun get_fee_rate(tick_spacing: u32, global_config: &GlobalConfig): u64 {
    assert!(vec_map::contains(&global_config.fee_tiers, &tick_spacing), EFeeTierNotFound);
    let fee_tier = vec_map::get(&global_config.fee_tiers, &tick_spacing);
    fee_tier.fee_rate
}

/// Get the max fee rate
/// * Returns the max fee rate
public fun max_fee_rate(): u64 {
    MAX_FEE_RATE
}

/// Get the max protocol fee rate
/// * Returns the max protocol fee rate
public fun max_protocol_fee_rate(): u64 {
    MAX_PROTOCOL_FEE_RATE
}

// Check member is pool manager
/// * `config` - The global config
/// * `member` - The member address
/// * Returns true if the member has the pool manager role, false otherwise
public fun is_pool_manager(config: &GlobalConfig, member: address): bool {
    acl::has_role(&config.acl, member, ACL_POOL_MANAGER)
}

/// Check member has pool manager role
/// * `config` - The global config
/// * `member` - The member address
public fun check_pool_manager_role(config: &GlobalConfig, member: address) {
    assert!(is_pool_manager(config, member), ENoPoolManagerPemission)
}

/// Check member has fee tier manager role
/// * `config` - The global config
/// * `member` - The member address
public fun check_fee_tier_manager_role(config: &GlobalConfig, member: address) {
    assert!(acl::has_role(&config.acl, member, ACL_FEE_TIER_MANAGER), ENoFeeTierManagerPermission)
}

/// Check member has protocol fee claim role
/// * `config` - The global config
/// * `member` - The member address
public fun check_protocol_fee_claim_role(config: &GlobalConfig, member: address) {
    assert!(
        acl::has_role(&config.acl, member, ACL_CLAIM_PROTOCOL_FEE),
        ENoProtocolFeeClaimPermission,
    )
}

/// Check member has partner manager role.
/// * `config` - The global config
/// * `member` - The member address
public fun check_partner_manager_role(config: &GlobalConfig, member: address) {
    assert!(acl::has_role(&config.acl, member, ACL_PARTNER_MANAGER), ENoPartnerManagerPermission)
}

/// Check member has rewarder manager role.
/// * `config` - The global config
/// * `member` - The member address
public fun check_rewarder_manager_role(config: &GlobalConfig, member: address) {
    assert!(acl::has_role(&config.acl, member, ACL_REWARDER_MANAGER), ENoRewarderManagerPermission)
}

/// Check member has emergency pause role.
/// * `config` - The global config
/// * `member` - The member address
public fun check_emergency_pause_role(config: &GlobalConfig, member: address) {
    assert!(acl::has_role(&config.acl, member, ACL_EMERGENCY_PAUSE), ENoEmergencyPausePermission)
}

/// Get tick_spacing of FeeTier.
/// * `fee_tier` - The fee tier
/// * Returns the tick spacing
public fun tick_spacing(fee_tier: &FeeTier): u32 {
    fee_tier.tick_spacing
}

/// Get fee_rate of FeeTier.
/// * `fee_tier` - The fee tier
/// * Returns the fee rate
public fun fee_rate(fee_tier: &FeeTier): u64 {
    fee_tier.fee_rate
}

/// Get the protocol_fee_rate from `GlobalConfig`.
/// * `config` - The global config
/// * Returns the protocol fee rate
public fun protocol_fee_rate(config: &GlobalConfig): u64 {
    config.protocol_fee_rate
}

/// Get the fee tiers from `GlobalConfig`.
/// * `config` - The global config
/// * Returns the fee tiers
public fun fee_tiers(config: &GlobalConfig): &VecMap<u32, FeeTier> {
    &config.fee_tiers
}

/// Get the ACL from `GlobalConfig`.
/// * `config` - The global config
/// * Returns the ACL
public fun acl(config: &GlobalConfig): &acl::ACL {
    &config.acl
}

/// Check current packages is valid.
/// * `config` - The global config
public fun checked_package_version(config: &GlobalConfig) {
    assert!(VERSION >= config.package_version, EPackageVersionDeprecate);
}

/// Check package version satisfy EMERGENCY_RESTORE_NEED_VERSION.
/// * `config` - The global config
public fun check_emergency_restore_version(config: &GlobalConfig) {
    assert!(
        config.package_version == EMERGENCY_RESTORE_NEED_VERSION,
        EConfigVersionNotEqualEmergencyRestoreVersion,
    );
}

/// Emergency pause the protocol.
/// * `config` - The global config
/// * `ctx` - The transaction context
public fun emergency_pause(config: &mut GlobalConfig, ctx: &TxContext) {
    check_emergency_pause_role(config, tx_context::sender(ctx));
    let old_version = config.package_version;
    config.package_version = EMERGENCY_PAUSE_VERSION;
    assert!(
        !dynamic_field::exists_with_type<vector<u8>, u64>(
            &config.id,
            EMERGENCY_PAUSE_BEFORE_VERSION,
        ),
        EProtocolAlreadyEmergencyPause,
    );
    dynamic_field::add(&mut config.id, EMERGENCY_PAUSE_BEFORE_VERSION, old_version);
}

/// Emergency unpause the protocol.
/// * `config` - The global config
/// * `version` - The new package version
/// * `ctx` - The transaction context
public fun emergency_unpause(config: &mut GlobalConfig, version: u64, ctx: &TxContext) {
    check_emergency_pause_role(config, tx_context::sender(ctx));
    assert!(
        dynamic_field::exists_with_type<vector<u8>, u64>(
            &config.id,
            EMERGENCY_PAUSE_BEFORE_VERSION,
        ),
        EProtocolNotEmergencyPause,
    );
    let before_version = dynamic_field::remove<vector<u8>, u64>(
        &mut config.id,
        EMERGENCY_PAUSE_BEFORE_VERSION,
    );
    assert!(version >= before_version, EInvalidPackageVersion);
    config.package_version = version;
}

/// Update the package version.
/// * `admin_cap` - The admin cap
/// * `config` - The global config
/// * `version` - The new package version
public fun update_package_version(_: &AdminCap, config: &mut GlobalConfig, version: u64) {
    let old_version = config.package_version;
    assert!(version > old_version && version < EMERGENCY_PAUSE_VERSION, EInvalidPackageVersion);
    config.package_version = version;
    emit(SetPackageVersion {
        new_version: version,
        old_version,
    })
}

/// Get the package version.
/// * Returns the package version
public fun package_version(): u64 {
    VERSION
}

// === Functions only for test ===
#[test_only]
public fun new_global_config_for_test(
    ctx: &mut TxContext,
    protocol_fee_rate: u64,
): (AdminCap, GlobalConfig) {
    let (mut global_config, admin_cap) = (
        GlobalConfig {
            id: object::new(ctx),
            protocol_fee_rate,
            fee_tiers: vec_map::empty(),
            acl: acl::new(ctx),
            package_version: 1,
        },
        AdminCap {
            id: object::new(ctx),
        },
    );

    let sender = tx_context::sender(ctx);
    let roles =
        0u128 |
            (1 << ACL_POOL_MANAGER) |
            (1 << ACL_FEE_TIER_MANAGER) |
            (1 << ACL_REWARDER_MANAGER) |
            (1 << ACL_CLAIM_PROTOCOL_FEE) |
            (1 << ACL_PARTNER_MANAGER);
    set_roles(&admin_cap, &mut global_config, sender, roles);
    (admin_cap, global_config)
}

#[test_only]
use sui::test_scenario;
#[test_only]
use std::unit_test::assert_eq;
#[test]
fun test_init() {
    let mut sc = test_scenario::begin(@0x23);
    init(sc.ctx());
    sc.next_tx(@0x24);
    let config = test_scenario::take_shared<GlobalConfig>(&sc);
    let admin_cap = test_scenario::take_from_address<AdminCap>(&sc, @0x23);
    assert_eq!(config.package_version, 1);
    assert_eq!(config.protocol_fee_rate, DEFAULT_PROTOCOL_FEE_RATE);
    assert_eq!(config.fee_tiers.size(), 1);
    check_pool_manager_role(&config, @0x23);
    check_fee_tier_manager_role(&config, @0x23);
    check_rewarder_manager_role(&config, @0x23);
    check_partner_manager_role(&config, @0x23);

    test_scenario::return_shared(config);
    test_scenario::return_to_address(@0x23, admin_cap);
    test_scenario::end(sc);
}

#[test_only]
public fun update_package_version_for_test(_: &AdminCap, config: &mut GlobalConfig, version: u64) {
    config.package_version = version;
}

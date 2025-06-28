// Copyright (c) Cetus Technology Limited

#[allow(unused_type_parameter, unused_field)]
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
/// The package version is used for upgrade the package, when upgrade the package, we need increase the package version.
module cetusclmm::config {
    use sui::object::{UID, ID};
    use sui::tx_context::TxContext;
    use sui::vec_map::VecMap;

    use cetusclmm::acl;

    /// Clmmpools acl roles
    #[allow(unused_const)]
    const ACL_POOL_MANAGER: u8 = 0;
    #[allow(unused_const)]
    const ACL_FEE_TIER_MANAGER: u8 = 1;
    #[allow(unused_const)]
    const ACL_CLAIM_PROTOCOL_FEE: u8 = 2;
    #[allow(unused_const)]
    const ACL_PARTNER_MANAGER: u8 = 3;
    #[allow(unused_const)]
    const ACL_REWARDER_MANAGER: u8 = 4;

    // === Structs ===
    struct AdminCap has key, store {
        id: UID,
    }


    struct ProtocolFeeClaimCap has key, store {
        id: UID,
    }


    /// The clmmpools fee tier data
    struct FeeTier has store, copy, drop {
        /// The tick spacing
        tick_spacing: u32,

        /// The default fee rate
        fee_rate: u64,
    }


    struct GlobalConfig has key, store {
        id: UID,
        /// `protocol_fee_rate` The protocol fee rate
        protocol_fee_rate: u64,
        /// 'fee_tiers' The Clmmpools fee tire map
        fee_tiers: VecMap<u32, FeeTier>,
        /// `acl` The Clmmpools ACL
        acl: acl::ACL,

        /// The current package version
        package_version: u64
    }


    // === Events ===


    /// Emit when init the `GlobalConfig` and `AdminCap`
    struct InitConfigEvent has copy, drop {
        admin_cap_id: ID,
        global_config_id: ID,
    }


    /// Emit when update the protocol fee rate
    struct UpdateFeeRateEvent has copy, drop {
        old_fee_rate: u64,
        new_fee_rate: u64,
    }


    /// Emit when add fee_tier
    struct AddFeeTierEvent has copy, drop {
        tick_spacing: u32,
        fee_rate: u64,
    }


    /// Emit when update fee_tier
    struct UpdateFeeTierEvent has copy, drop {
        tick_spacing: u32,
        old_fee_rate: u64,
        new_fee_rate: u64,
    }


    /// Emit when delete fee_tier
    struct DeleteFeeTierEvent has copy, drop {
        tick_spacing: u32,
        fee_rate: u64,
    }


    /// Emit when set roles
    struct SetRolesEvent has copy, drop {
        member: address,
        roles: u128,
    }


    /// Emit when add member a role
    struct AddRoleEvent has copy, drop {
        member: address,
        role: u8,
    }


    /// Emit when remove member a role
    struct RemoveRoleEvent has copy, drop {
        member: address,
        role: u8
    }


    /// Emit when add member
    struct RemoveMemberEvent has copy, drop {
        member: address,
    }


    /// Emit when update package version.
    struct SetPackageVersion has copy, drop {
        new_version: u64,
        old_version: u64
    }

    // === Functions ===

    /// Update the protocol fee rate
    /// Params
    ///     - config: The global config
    ///     - protocol_fee_rate: The new protocol fee rate
    public fun update_protocol_fee_rate(
        _config: &mut GlobalConfig,
        _protocol_fee_rate: u64,
        _ctx: &TxContext
    ) {
        abort 0
    }

    /// Add a fee tier
    /// Params
    ///     - config: The global config
    ///     - tick_spacing: The tick spacing
    ///     - fee_rate: The fee rate
    public fun add_fee_tier(
        _config: &mut GlobalConfig,
        _tick_spacing: u32,
        _fee_rate: u64,
        _ctx: &TxContext,
    ) {
        abort 0
    }

    //// Delete a fee tier by `tick_spacing`.
    /// Params
    ///     - config: The global config
    ///     - tick_spacing: The tick spacing
    public fun delete_fee_tier(
        _config: &mut GlobalConfig,
        _tick_spacing: u32,
        _ctx: &TxContext
    ) {
        abort 0
    }

    /// Update the fee rate of a FeeTier by `tick_spacing`.
    /// Params
    ///    - config: The global config
    ///    - tick_spacing: The tick spacing
    ///    - new_fee_rate: The new fee rate
    public fun update_fee_tier(
        _config: &mut GlobalConfig,
        _tick_spacing: u32,
        _new_fee_rate: u64,
        _ctx: &TxContext
    ) {
        abort 0
    }

    /// Set role for member.
    /// Params
    ///    - admin_cap: The admin cap
    ///    - config: The global config
    ///    - _member: The member address
    ///    - roles: The roles
    public fun set_roles(_: &AdminCap, _config: &mut GlobalConfig, _member: address, _roles: u128) {
        abort 0
    }

    /// Add a role for member.
    /// Params
    ///   - admin_cap: The admin cap
    ///  - config: The global config
    /// - _member: The member address
    /// - role: The role
    public fun add_role(_: &AdminCap, _config: &mut GlobalConfig, _member: address, _role: u8) {
        abort 0
    }

    /// Remove a role for member.
    /// Params
    ///  - admin_cap: The admin cap
    /// - config: The global config
    /// - _member: The member address
    /// - role: The role
    public fun remove_role(_: &AdminCap, _config: &mut GlobalConfig, _member: address, _role: u8) {
        abort 0
    }

    /// Remove a member from ACL.
    /// Params
    /// - admin_cap: The admin cap
    /// - config: The global config
    /// - _member: The member address
    public fun remove_member(_: &AdminCap, _config: &mut GlobalConfig, _member: address) {
        abort 0
    }

    public fun is_pool_manager(_config: &GlobalConfig, _member: address): bool {
        abort 0
    }

    /// Get all members in ACL.
    public fun get_members(_config: &GlobalConfig): vector<acl::Member> {
        abort 0
    }

    /// Get the protocol fee rate
    public fun get_protocol_fee_rate(_global_config: &GlobalConfig): u64 {
        abort 0
    }

    /// Get fee rate by tick spacing
    public fun get_fee_rate(
        _tick_spacing: u32,
        _global_config: &GlobalConfig
    ): u64 {
        abort 0
    }

    /// Get the max fee rate
    public fun max_fee_rate(): u64 {
        abort 0
    }

    /// Get the max protocol fee rate
    public fun max_protocol_fee_rate(): u64 {
        abort 0
    }

    /// Check member has pool manager role
    public fun check_pool_manager_role(_config: &GlobalConfig, _member: address) {
        abort 0
    }

    /// Check member has fee tier manager role
    public fun check_fee_tier_manager_role(_config: &GlobalConfig, _member: address) {
        abort 0
    }

    /// Check member has protocol fee claim role
    public fun check_protocol_fee_claim_role(_config: &GlobalConfig, _member: address) {
        abort 0
    }

    /// Check member has partner manager role.
    public fun check_partner_manager_role(_config: &GlobalConfig, _member: address) {
        abort 0
    }

    /// Check member has rewarder manager role.
    public fun check_rewarder_manager_role(_config: &GlobalConfig, _member: address) {
        abort 0
    }

    /// Get tick_spacing of FeeTier.
    public fun tick_spacing(_fee_tier: &FeeTier): u32 {
        abort 0
    }

    /// Get fee_rate of FeeTier.
    public fun fee_rate(_fee_tier: &FeeTier): u64 {
        abort 0
    }

    /// Get the protocol_fee_rate from `GlobalConfig`.
    public fun protocol_fee_rate(_config: &GlobalConfig): u64 {
        abort 0
    }

    /// Get the fee tiers from `GlobalConfig`.
    public fun fee_tiers(_config: &GlobalConfig): &VecMap<u32, FeeTier> {
        abort 0
    }

    /// Get the ACL from `GlobalConfig`.
    public fun acl(_config: &GlobalConfig): &acl::ACL {
        abort 0
    }

    /// Check package version of the package_version in `GlobalConfig` and VERSION in current package.
    public fun checked_package_version(_config: &GlobalConfig) {
        abort 0
    }

    /// Update the package version.
    public fun update_package_version(_: &AdminCap, _config: &mut GlobalConfig, _version: u64) {
        abort 0
    }

    public fun package_version(): u64 {
        abort 0
    }

    #[test_only]
    use sui::object;
    #[test_only]
    use sui::vec_map;
    #[test_only]
    use sui::tx_context;

    // === Functions only for test ===
    #[test_only]
    public fun new_global_config_for_test(ctx: &mut TxContext, protocol_fee_rate: u64): (AdminCap, GlobalConfig) {
        let (global_config, admin_cap) = (
            GlobalConfig {
                id: object::new(ctx),
                protocol_fee_rate,
                fee_tiers: vec_map::empty(),
                acl: acl::new(ctx),
                package_version: 1,
            },
            AdminCap {
                id: object::new(ctx)
            }
        );

        let sender = tx_context::sender(ctx);
        let roles = 0u128 |
            (1 << ACL_POOL_MANAGER) |
            (1 << ACL_FEE_TIER_MANAGER) |
            (1 << ACL_REWARDER_MANAGER) |
            (1 << ACL_CLAIM_PROTOCOL_FEE) |
            (1 << ACL_PARTNER_MANAGER);
        set_roles(&admin_cap, &mut global_config, sender, roles);
        (admin_cap, global_config)
    }
}

module 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::config {

    use sui::object;
    use sui::table;
    use sui::tx_context;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::acl;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::config;

    struct AdminCap has store, key {
        id: object::UID,
    }
    struct OperatorCap has key {
        id: object::UID,
    }
    struct GlobalConfig has store, key {
        id: object::UID,
        acl: acl::ACL,
        acceleration_factor: table::Table<object::ID, u8>,
        package_version: u64,
    }
    struct InitConfigEvent has copy, drop {
        admin_cap_id: object::ID,
        global_config_id: object::ID,
    }
    struct AddOperatorEvent has copy, drop {
        operator_cap_id: object::ID,
        recipient: address,
        roles: u128,
    }
    struct SetRolesEvent has copy, drop {
        member: address,
        roles: u128,
    }
    struct AddRoleEvent has copy, drop {
        member: address,
        role: u8,
    }
    struct RemoveRoleEvent has copy, drop {
        member: address,
        role: u8,
    }
    struct RemoveMemberEvent has copy, drop {
        member: address,
    }
    struct SetPackageVersion has copy, drop {
        new_version: u64,
        old_version: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun add_operator(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: u128, a3: address, a4: &mut tx_context::TxContext);
    native public fun set_roles(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u128);
    native public fun add_role(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u8);
    native public fun remove_role(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address, a3: u8);
    native public fun remove_member(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: address);
    native public fun set_package_version(a0: &config::AdminCap, a1: &mut config::GlobalConfig, a2: u64);
    native public fun get_members(a0: &config::GlobalConfig): vector<acl::Member>;
    native public fun check_emergency_pause_role(a0: &config::GlobalConfig, a1: address);
    native public fun check_pool_manager_role(a0: &config::GlobalConfig, a1: address);
    native public fun check_rewarder_manager_role(a0: &config::GlobalConfig, a1: address);
    native public fun checked_package_version(a0: &config::GlobalConfig);
    native public fun check_emergency_restore_version(a0: &config::GlobalConfig);
    native public fun emergency_pause(a0: &mut config::GlobalConfig, a1: &tx_context::TxContext);
    native public fun package_version(): u64;

}

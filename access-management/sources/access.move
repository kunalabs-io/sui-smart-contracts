// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Access Management module for Sui packages.
/// Provides fine-grained, configurable permissions using PackageAdmin, Policy, Rule, and ActionRequest.
module access_management::access;

use access_management::dynamic_map::{Self, DynamicMap};
use std::ascii::{Self, String};
use std::type_name::{Self, TypeName};
use sui::types;
use sui::vec_map::{Self, VecMap};
use sui::vec_set::{Self, VecSet};

/* ================= errors ================= */

/// Tried to claim a `PackageAdmin` using a type that isn't a one-time witness.
const ENotOneTimeWitness: u64 = 0;
/// Tried to claim a `PackageAdmin` from a module that isn't named `access_init`.
const EClaimFromInvalidModule: u64 = 1;
/// The provided `PackageAdmin` is not the admin for the specified `Policy`.
const ENotPolicyAdmin: u64 = 2;
/// The specified action witness does not belong to `PackageAdmin's` package.
const ENotActionAdmin: u64 = 3;
/// The `Policy` is disabled.
const EPolicyDisabled: u64 = 4;
/// The `Entity` is not allowed in the `Policy`.
const EEntityNotAllowed: u64 = 5;
/// The provided action is not allowed in the specified rule.
const EActionNotInRule: u64 = 6;
/// An approved condition does not belong to the required rule.
const EInvalidConditionApproval: u64 = 7;
/// The `Policy` version does not match the module version.
const EInvalidPolicyVersion: u64 = 8;
/// The migration is not allowed because the object version is higher or equal to the module
/// version.
const ENotUpgrade: u64 = 9;
/// The action does not match the action in the request.
const EActionMismatch: u64 = 10;

/* ================= constants ================= */

const MODULE_VERSION: u16 = 1;

/* ================= structs ================= */

/// Represents the administrator for a specific package.
public struct PackageAdmin has key, store {
    id: UID,
    /// The address string of the package that this admin is for.
    package: String,
}

/// Represents an entity that can be granted permissions in a policy.
public struct Entity has key, store {
    id: UID,
}

/// Represents a rule within a policy, specifying allowed actions and required conditions.
public struct Rule has store {
    /// The set of action type names that are allowed by this rule.
    actions: VecSet<TypeName>,
    /// Conditions that must be met for the actions to be allowed.
    conditions: VecSet<TypeName>,
    /// A dynamic map from condition type name to its configuration for this rule.
    condition_configs: DynamicMap<TypeName>,
}

/// Represents an access control policy for a package, specifying which entities are allowed,
/// the rules governing actions, and the policy's status and version.
public struct Policy has key {
    id: UID,
    /// The address string of the package this policy applies to.
    package: String,
    /// The set of entity IDs that are allowed by this policy.
    allowed_entities: VecSet<ID>,
    /// A mapping from rule ID (address) to the corresponding rule definition.
    rules: VecMap<address, Rule>,
    /// Indicates whether the policy is currently enabled.
    enabled: bool,
    /// The version of the policy, used for upgrade and compatibility checks.
    version: u16,
}

/// Represents a request to perform a specific action.
public struct ActionRequest {
    /// The type name of the action being requested.
    action_name: TypeName,
    /// A dynamic map containing contextual information for the action, keyed by string.
    context: DynamicMap<String>,
    /// Conditions that have been approved for this request. Maps condition type to
    /// to rule id.
    approved_conditions: VecMap<TypeName, address>,
}

/// Carries condition configuration and context for condition approval functions.
/// 
/// Type Parameters:
/// - `Condition`: The condition type being witnessed
/// - `Config`: Configuration data for the condition
public struct ConditionWitness<phantom Condition, Config: store + copy + drop> has drop {
    /// Address of the rule containing this condition
    rule_id: address,
    /// Configuration data for the condition
    config: Config,
    /// Policy ID for additional context
    policy: ID,
    /// Entity ID for additional context
    entity: ID,
}

/// Represents a default configuration for a condition that does not require any additional configuration.
public struct ConfigNone has store, copy, drop {}

/* ================= upgrade ================= */

public(package) fun check_version(policy: &Policy) {
    assert!(policy.version == MODULE_VERSION, EInvalidPolicyVersion);
}

/// Migrates the given policy to the current module version.
public fun migrate_policy_version(policy: &mut Policy, admin: &PackageAdmin) {
    assert!(policy.version < MODULE_VERSION, ENotUpgrade);
    assert!(policy.package == admin.package, ENotPolicyAdmin);
    policy.version = MODULE_VERSION;
}

/* ================= package admin ================= */

/// Claims package admin rights using a one-time witness.
/// 
/// Aborts if the witness is not a valid one-time witness or if it does not originate from the expected module.
public fun claim_package<OTW: drop>(otw: OTW, ctx: &mut TxContext): PackageAdmin {
    assert!(types::is_one_time_witness(&otw), ENotOneTimeWitness);

    let `type` = type_name::get_with_original_ids<OTW>();
    let module_name = `type`.get_module();
    assert!(module_name == ascii::string(b"access_init"), EClaimFromInvalidModule);

    PackageAdmin {
        id: object::new(ctx),
        package: `type`.get_address(),
    }
}

/// Irreversibly destroys a package admin.
public fun irreversibly_destroy_admin(admin: PackageAdmin) {
    let PackageAdmin { id, package: _ } = admin;
    id.delete();
}

/* ================= entity ================= */

/// Creates a new entity.
public fun create_entity(ctx: &mut TxContext): Entity {
    Entity {
        id: object::new(ctx),
    }
}

/// Destroys an entity.
public fun destroy_entity(entity: Entity) {
    let Entity { id } = entity;
    id.delete();
}

/* ================= policy ================= */

/// Creates a new, empty policy.
public fun create_empty_policy(admin: &PackageAdmin, ctx: &mut TxContext): Policy {
    Policy {
        id: object::new(ctx),
        package: admin.package,
        allowed_entities: vec_set::empty(),
        rules: vec_map::empty(),
        enabled: true,
        version: MODULE_VERSION,
    }
}

public use fun allowlist_entity_for_policy as Policy.allowlist_entity;

/// Adds an entity to the allowlist for a policy.
public fun allowlist_entity_for_policy(policy: &mut Policy, admin: &PackageAdmin, entity_id: &ID) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);
    vec_set::insert(&mut policy.allowed_entities, *entity_id);
}

public use fun remove_entity_from_policy as Policy.remove_entity;

/// Removes an entity from the policy allowlist.
public fun remove_entity_from_policy(policy: &mut Policy, admin: &PackageAdmin, entity_id: &ID) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);
    vec_set::remove(&mut policy.allowed_entities, entity_id);
}

public use fun enable_policy as Policy.enable;

/// Enables a policy.
public fun enable_policy(policy: &mut Policy, admin: &PackageAdmin) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);
    policy.enabled = true;
}

public use fun disable_policy as Policy.disable;

/// Disables a policy.
public fun disable_policy(policy: &mut Policy, admin: &PackageAdmin) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);
    policy.enabled = false;
}

public use fun destroy_empty_policy as Policy.destroy;

/// Destroys an empty policy.
public fun destroy_empty_policy(policy: Policy, admin: &PackageAdmin) {
    check_version(&policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);
    let Policy { id, package: _, allowed_entities: _, rules, enabled: _, version: _ } = policy;
    id.delete();
    rules.destroy_empty();
}

public use fun share_policy as Policy.share;

/// Shares a policy object.
public fun share_policy(policy: Policy, admin: &PackageAdmin) {
    check_version(&policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);
    transfer::share_object(policy);
}

/* ================= rule ================= */

/// Adds an empty rule to the policy and returns the key of the new rule.
public fun add_empty_rule(policy: &mut Policy, admin: &PackageAdmin, ctx: &mut TxContext): address {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let rule_id = tx_context::fresh_object_address(ctx);
    let rule = Rule {
        actions: vec_set::empty(),
        conditions: vec_set::empty(),
        condition_configs: dynamic_map::new(ctx),
    };
    policy.rules.insert(rule_id, rule);

    rule_id
}

/// Removes and destroys the rules from the policy.
/// NOTE: This will drop the rule potentially with rule configs still stored as dynamic fields
/// which means the storage rebate will not be returned to the caller. To collect the rebate,
/// the caller should manually remove the rule configs before calling this function.
public fun drop_rule(policy: &mut Policy, admin: &PackageAdmin, rule_id: address) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let (_, rule) = policy.rules.remove(&rule_id);
    let Rule { actions: _, conditions: _, condition_configs } = rule;
    condition_configs.force_drop();
}

/* ================= action ================= */

/// Adds an action to a rule.
public fun add_action_to_rule<Action: drop>(
    policy: &mut Policy,
    admin: &PackageAdmin,
    rule_id: address,
) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let orig_package = type_name::get_with_original_ids<Action>().get_address();
    assert!(orig_package == admin.package, ENotActionAdmin);

    let rule = &mut policy.rules[&rule_id];
    let action_name = type_name::get<Action>();
    rule.actions.insert(action_name);
}

/// Removes an action from a rule.
public fun remove_action_from_rule<Action: drop>(
    policy: &mut Policy,
    admin: &PackageAdmin,
    rule_id: address,
) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let rule = vec_map::get_mut(&mut policy.rules, &rule_id);
    let action_name = type_name::get<Action>();
    rule.actions.remove(&action_name);
}

/* ================= condition ================= */

/// Adds a condition with configuration to a rule.
public fun add_condition_to_rule_with_config<Condition: drop, Config: store + copy + drop>(
    policy: &mut Policy,
    admin: &PackageAdmin,
    rule_id: address,
    config: Config,
) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let rule = vec_map::get_mut(&mut policy.rules, &rule_id);
    let condition_name = type_name::get<Condition>();
    rule.conditions.insert(condition_name);

    rule.condition_configs.insert(condition_name, config);
}

/// Adds a condition without configuration to a rule.
public fun add_condition_to_rule<Condition: drop>(
    policy: &mut Policy,
    admin: &PackageAdmin,
    rule_id: address,
) {
    check_version(policy);
    add_condition_to_rule_with_config<Condition, ConfigNone>(
        policy,
        admin,
        rule_id,
        ConfigNone {},
    );
}

/// Removes a condition from a rule.
/// Aborts if the condition config is not the `ConfigNone` default config.
public fun remove_condition_from_rule<Condition: drop>(
    policy: &mut Policy,
    admin: &PackageAdmin,
    rule_id: address,
) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let rule = &mut policy.rules[&rule_id];
    let condition_name = type_name::get<Condition>();
    rule.condition_configs.remove<TypeName, ConfigNone>(condition_name);

    rule.conditions.remove(&condition_name);
}

/* ================= condition config ================= */

/// Adds configuration for a condition.
/// Aborts if the config is not the `ConfigNone` default config.
public fun add_config_for_condition<Condition, Config: store + copy + drop>(
    policy: &mut Policy,
    admin: &PackageAdmin,
    rule_id: address,
    config: Config,
) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let rule = &mut policy.rules[&rule_id];
    let condition_name = type_name::get<Condition>();

    rule.condition_configs.remove<TypeName, ConfigNone>(condition_name);
    rule.condition_configs.insert(condition_name, config);
}

/// Removes configuration for a condition.
public fun remove_config_for_condition<Condition, Config: store + copy + drop>(
    policy: &mut Policy,
    admin: &PackageAdmin,
    rule_id: address,
) {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let rule = &mut policy.rules[&rule_id];
    let condition_name = type_name::get<Condition>();

    rule.condition_configs.remove<TypeName, Config>(condition_name);
    rule.condition_configs.insert(condition_name, ConfigNone {});
}

/// Borrows condition configuration from a policy.
public fun borrow_condition_config<Condition, Config: store + copy + drop>(
    policy: &Policy,
    rule_id: &address,
): &Config {
    check_version(policy);
    let rule = &policy.rules[rule_id];
    let condition_name = type_name::get<Condition>();
    &rule.condition_configs[condition_name]
}

/// Borrows mutable condition configuration from a policy.
public fun borrow_mut_condition_config<Condition, Config: store + copy + drop>(
    policy: &mut Policy,
    admin: &PackageAdmin,
    rule_id: address,
): &mut Config {
    check_version(policy);
    assert!(policy.package == admin.package, ENotPolicyAdmin);

    let rule = &mut policy.rules[&rule_id];
    let condition_name = type_name::get<Condition>();

    &mut rule.condition_configs[condition_name]
}

/* ================= action request ================= */

/// Creates a new action request.
public fun new_request<Action: drop>(_: Action, ctx: &mut TxContext): ActionRequest {
    ActionRequest {
        action_name: type_name::get<Action>(),
        context: dynamic_map::new(ctx),
        approved_conditions: vec_map::empty(),
    }
}

/// Populates the context with the `resource_id` and `resource_type_name` fields
/// for the provided resource.
public fun new_request_for_resource<T: key>(
    action: String,
    resource: &T,
    ctx: &mut TxContext,
): ActionRequest {
    let mut request = new_request(action, ctx);

    request.context.insert(ascii::string(b"resource_id"), object::id(resource));
    request.context.insert(ascii::string(b"resource_type_name"), type_name::get<T>());

    request
}

/// Creates a new action request with pre-populated context.
public fun new_request_with_context<Action: drop>(
    _: Action,
    context: DynamicMap<std::ascii::String>,
): ActionRequest {
    ActionRequest {
        action_name: type_name::get<Action>(),
        context,
        approved_conditions: vec_map::empty(),
    }
}

/// Borrows the context from an action request.
public fun borrow_context(request: &ActionRequest): &DynamicMap<String> {
    &request.context
}

/// Gets a value from the action request context.
public fun context_value<Value: store + copy + drop>(request: &ActionRequest, key: String): &Value {
    &request.context[key]
}

/* ================= approval ================= */

/// Gets a condition witness for approval.
public fun get_condition_witness<Condition, Action: drop, Config: store + copy + drop>(
    policy: &Policy,
    entity: &Entity,
    rule_id: address,
): ConditionWitness<Condition, Config> {
    check_version(policy);
    assert!(policy.enabled, EPolicyDisabled);
    assert!(policy.allowed_entities.contains(&object::id(entity)), EEntityNotAllowed);

    let rule = &policy.rules[&rule_id];
    let action_name = type_name::get<Action>();
    assert!(rule.actions.contains(&action_name), EActionNotInRule);

    let condition_name = type_name::get<Condition>();
    let config = rule.condition_configs[condition_name];

    ConditionWitness {
        rule_id,
        config,
        policy: object::id(policy),
        entity: object::id(entity),
    }
}

public use fun cw_rule_id as ConditionWitness.rule_id;

/// Gets the rule ID from a condition witness.
public fun cw_rule_id<Condition, Config: store + copy + drop>(
    witness: &ConditionWitness<Condition, Config>,
): address {
    witness.rule_id
}

public use fun cw_config as ConditionWitness.config;

/// Gets the configuration from a condition witness.
public fun cw_config<Condition, Config: store + copy + drop>(
    witness: &ConditionWitness<Condition, Config>,
): Config {
    witness.config
}

public use fun cw_policy_id as ConditionWitness.policy_id;

/// Gets the policy ID from a condition witness.
public fun cw_policy_id<Condition, Config: store + copy + drop>(
    witness: &ConditionWitness<Condition, Config>,
): ID {
    witness.policy
}

public use fun cw_entity_id as ConditionWitness.entity_id;

/// Gets the entity ID from a condition witness.
public fun cw_entity_id<Condition, Config: store + copy + drop>(
    witness: &ConditionWitness<Condition, Config>,
): ID {
    witness.entity
}

/// Approves a condition for an action request.
/// Aborts if the condition is not needed for the action request.
public fun approve_condition<Condition: drop, Config: store + copy + drop>(
    request: &mut ActionRequest,
    witness: &ConditionWitness<Condition, Config>,
    _: Condition,
) {
    let condition_name = type_name::get<Condition>();
    request.approved_conditions.insert(condition_name, witness.rule_id);
}

/// Approves an action request and returns the context.
///
/// Aborts with:
/// - `EInvalidConditionApproval` if an approved condition's rule id does not
///   match the requested rule id.
/// - `std::vector::EKeyDoesNotExist` if a required condition is not present
///   in the approved conditions or has already been approved.
/// - `sui::vec_map::EMapEmpty` if one or more required conditions have not
///   been approved.
public fun approve_and_return_context(
    request: ActionRequest,
    entity: &Entity,
    policy: &Policy,
    rule_id: address,
): DynamicMap<String> {
    check_version(policy);
    assert!(policy.enabled, EPolicyDisabled);
    assert!(policy.allowed_entities.contains(&object::id(entity)), EEntityNotAllowed);
    let rule = &policy.rules[&rule_id];

    let ActionRequest { action_name, context, mut approved_conditions } = request;
    assert!(rule.actions.contains(&action_name), EActionNotInRule);

    let mut required_conditions = rule.conditions;
    let size = required_conditions.size();
    let mut i = 0;
    while (i < size) {
        let (approved_condition_name, approved_rule_id) = approved_conditions.pop();
        assert!(approved_rule_id == rule_id, EInvalidConditionApproval);

        required_conditions.remove(&approved_condition_name);

        i = i + 1;
    };

    context
}

/// Approves an action request.
/// Note: Drops the request context without checking if it's empty. This means that the
/// storage rebate for these dynamic fields will not be returned to the caller.
public fun approve_request(
    request: ActionRequest,
    entity: &Entity,
    policy: &Policy,
    rule_id: address,
) {
    check_version(policy);
    let context = approve_and_return_context(request, entity, policy, rule_id);
    context.force_drop();
}

/// Admin approves an action request and returns the context.
/// Note: this will not work if the action type was added in an upgrade. Use
/// `admin_approve_request_with_original_id_and_return_context` instead.
public fun admin_approve_request_and_return_context(
    request: ActionRequest,
    admin: &PackageAdmin,
): DynamicMap<String> {
    let request_package = request.action_name.get_address();
    assert!(request_package == admin.package, ENotActionAdmin);

    let ActionRequest {
        action_name: _,
        context,
        approved_conditions: _,
    } = request;
    context
}

/// Admin approves an action request.
/// Note: this will not work if the action type was added in an upgrade. Use
/// `admin_approve_request_with_original_id` instead.
/// Note: Drops the request context without checking if it's empty. This means that the
/// storage rebate for these dynamic fields will not be returned to the caller.
public fun admin_approve_request(request: ActionRequest, admin: &PackageAdmin) {
    let context = admin_approve_request_and_return_context(request, admin);
    context.force_drop();
}

/// Admin approves an action request with original ID and returns the context.
public fun admin_approve_request_with_original_id_and_return_context<Action: drop>(
    request: ActionRequest,
    admin: &PackageAdmin,
): DynamicMap<String> {
    assert!(type_name::get<Action>() == request.action_name, EActionMismatch);

    let orig_package = type_name::get_with_original_ids<Action>().get_address();
    assert!(orig_package == admin.package, ENotActionAdmin);

    let ActionRequest {
        action_name: _,
        context,
        approved_conditions: _,
    } = request;
    context
}

/// Admin approves an action request with original ID.
/// Note: Drops the request context without checking if it's empty. This means that the
/// storage rebate for these dynamic fields will not be returned to the caller.
public fun admin_approve_request_with_original_id<Action: drop>(
    request: ActionRequest,
    admin: &PackageAdmin,
) {
    let context = admin_approve_request_with_original_id_and_return_context<Action>(request, admin);
    context.force_drop();
}

/* ================= testing ================= */

#[test_only]
public fun create_admin_for_testing<W>(ctx: &mut TxContext): PackageAdmin {
    let package = type_name::get_with_original_ids<W>().get_address();
    PackageAdmin {
        id: object::new(ctx),
        package,
    }
}

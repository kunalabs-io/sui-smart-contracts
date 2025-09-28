
<a name="access_management_access"></a>

# Module `access_management::access`

Access Management module for Sui packages.
Provides fine-grained, configurable permissions using PackageAdmin, Policy, Rule, and ActionRequest.


-  [Struct `PackageAdmin`](#access_management_access_PackageAdmin)
-  [Struct `Entity`](#access_management_access_Entity)
-  [Struct `Rule`](#access_management_access_Rule)
-  [Struct `Policy`](#access_management_access_Policy)
-  [Struct `ActionRequest`](#access_management_access_ActionRequest)
-  [Struct `ConditionWitness`](#access_management_access_ConditionWitness)
-  [Struct `ConfigNone`](#access_management_access_ConfigNone)
-  [Constants](#@Constants_0)
-  [Function `check_version`](#access_management_access_check_version)
-  [Function `migrate_policy_version`](#access_management_access_migrate_policy_version)
-  [Function `claim_package`](#access_management_access_claim_package)
-  [Function `irreversibly_destroy_admin`](#access_management_access_irreversibly_destroy_admin)
-  [Function `create_entity`](#access_management_access_create_entity)
-  [Function `destroy_entity`](#access_management_access_destroy_entity)
-  [Function `create_empty_policy`](#access_management_access_create_empty_policy)
-  [Function `allowlist_entity_for_policy`](#access_management_access_allowlist_entity_for_policy)
-  [Function `remove_entity_from_policy`](#access_management_access_remove_entity_from_policy)
-  [Function `enable_policy`](#access_management_access_enable_policy)
-  [Function `disable_policy`](#access_management_access_disable_policy)
-  [Function `destroy_empty_policy`](#access_management_access_destroy_empty_policy)
-  [Function `share_policy`](#access_management_access_share_policy)
-  [Function `add_empty_rule`](#access_management_access_add_empty_rule)
-  [Function `drop_rule`](#access_management_access_drop_rule)
-  [Function `add_action_to_rule`](#access_management_access_add_action_to_rule)
-  [Function `remove_action_from_rule`](#access_management_access_remove_action_from_rule)
-  [Function `add_condition_to_rule_with_config`](#access_management_access_add_condition_to_rule_with_config)
-  [Function `add_condition_to_rule`](#access_management_access_add_condition_to_rule)
-  [Function `remove_condition_from_rule`](#access_management_access_remove_condition_from_rule)
-  [Function `add_config_for_condition`](#access_management_access_add_config_for_condition)
-  [Function `remove_config_for_condition`](#access_management_access_remove_config_for_condition)
-  [Function `borrow_condition_config`](#access_management_access_borrow_condition_config)
-  [Function `borrow_mut_condition_config`](#access_management_access_borrow_mut_condition_config)
-  [Function `new_request`](#access_management_access_new_request)
-  [Function `new_request_for_resource`](#access_management_access_new_request_for_resource)
-  [Function `new_request_with_context`](#access_management_access_new_request_with_context)
-  [Function `borrow_context`](#access_management_access_borrow_context)
-  [Function `context_value`](#access_management_access_context_value)
-  [Function `get_condition_witness`](#access_management_access_get_condition_witness)
-  [Function `cw_rule_id`](#access_management_access_cw_rule_id)
-  [Function `cw_config`](#access_management_access_cw_config)
-  [Function `cw_policy_id`](#access_management_access_cw_policy_id)
-  [Function `cw_entity_id`](#access_management_access_cw_entity_id)
-  [Function `approve_condition`](#access_management_access_approve_condition)
-  [Function `approve_and_return_context`](#access_management_access_approve_and_return_context)
-  [Function `approve_request`](#access_management_access_approve_request)
-  [Function `admin_approve_request_and_return_context`](#access_management_access_admin_approve_request_and_return_context)
-  [Function `admin_approve_request`](#access_management_access_admin_approve_request)
-  [Function `admin_approve_request_with_original_id_and_return_context`](#access_management_access_admin_approve_request_with_original_id_and_return_context)
-  [Function `admin_approve_request_with_original_id`](#access_management_access_admin_approve_request_with_original_id)


<pre><code><b>use</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map">access_management::dynamic_map</a>;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="access_management_access_PackageAdmin"></a>

## Struct `PackageAdmin`

Represents the administrator for a specific package.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a> <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>package: <a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a></code>
</dt>
<dd>
 The address string of the package that this admin is for.
</dd>
</dl>


</details>

<a name="access_management_access_Entity"></a>

## Struct `Entity`

Represents an entity that can be granted permissions in a policy.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a> <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="access_management_access_Rule"></a>

## Struct `Rule`

Represents a rule within a policy, specifying allowed actions and required conditions.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/access_management/access.md#access_management_access_Rule">Rule</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>actions: <a href="../../dependencies/sui/vec_set.md#sui_vec_set_VecSet">sui::vec_set::VecSet</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>&gt;</code>
</dt>
<dd>
 The set of action type names that are allowed by this rule.
</dd>
<dt>
<code>conditions: <a href="../../dependencies/sui/vec_set.md#sui_vec_set_VecSet">sui::vec_set::VecSet</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>&gt;</code>
</dt>
<dd>
 Conditions that must be met for the actions to be allowed.
</dd>
<dt>
<code>condition_configs: <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>&gt;</code>
</dt>
<dd>
 A dynamic map from condition type name to its configuration for this rule.
</dd>
</dl>


</details>

<a name="access_management_access_Policy"></a>

## Struct `Policy`

Represents an access control policy for a package, specifying which entities are allowed,
the rules governing actions, and the policy's status and version.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>package: <a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a></code>
</dt>
<dd>
 The address string of the package this policy applies to.
</dd>
<dt>
<code>allowed_entities: <a href="../../dependencies/sui/vec_set.md#sui_vec_set_VecSet">sui::vec_set::VecSet</a>&lt;<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>&gt;</code>
</dt>
<dd>
 The set of entity IDs that are allowed by this policy.
</dd>
<dt>
<code>rules: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<b>address</b>, <a href="../../dependencies/access_management/access.md#access_management_access_Rule">access_management::access::Rule</a>&gt;</code>
</dt>
<dd>
 A mapping from rule ID (address) to the corresponding rule definition.
</dd>
<dt>
<code>enabled: bool</code>
</dt>
<dd>
 Indicates whether the policy is currently enabled.
</dd>
<dt>
<code>version: u16</code>
</dt>
<dd>
 The version of the policy, used for upgrade and compatibility checks.
</dd>
</dl>


</details>

<a name="access_management_access_ActionRequest"></a>

## Struct `ActionRequest`

Represents a request to perform a specific action.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>action_name: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
 The type name of the action being requested.
</dd>
<dt>
<code>context: <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;<a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>&gt;</code>
</dt>
<dd>
 A dynamic map containing contextual information for the action, keyed by string.
</dd>
<dt>
<code>approved_conditions: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <b>address</b>&gt;</code>
</dt>
<dd>
 Conditions that have been approved for this request. Maps condition type to
 to rule id.
</dd>
</dl>


</details>

<a name="access_management_access_ConditionWitness"></a>

## Struct `ConditionWitness`

Carries condition configuration and context for condition approval functions.

Type Parameters:
- <code>Condition</code>: The condition type being witnessed
- <code>Config</code>: Configuration data for the condition


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">ConditionWitness</a>&lt;<b>phantom</b> Condition, Config: <b>copy</b>, drop, store&gt; <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>rule_id: <b>address</b></code>
</dt>
<dd>
 Address of the rule containing this condition
</dd>
<dt>
<code>config: Config</code>
</dt>
<dd>
 Configuration data for the condition
</dd>
<dt>
<code>policy: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 Policy ID for additional context
</dd>
<dt>
<code>entity: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 Entity ID for additional context
</dd>
</dl>


</details>

<a name="access_management_access_ConfigNone"></a>

## Struct `ConfigNone`

Represents a default configuration for a condition that does not require any additional configuration.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/access_management/access.md#access_management_access_ConfigNone">ConfigNone</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="access_management_access_ENotOneTimeWitness"></a>

Tried to claim a <code><a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a></code> using a type that isn't a one-time witness.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_ENotOneTimeWitness">ENotOneTimeWitness</a>: u64 = 0;
</code></pre>



<a name="access_management_access_EClaimFromInvalidModule"></a>

Tried to claim a <code><a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a></code> from a module that isn't named <code>access_init</code>.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_EClaimFromInvalidModule">EClaimFromInvalidModule</a>: u64 = 1;
</code></pre>



<a name="access_management_access_ENotPolicyAdmin"></a>

The provided <code><a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a></code> is not the admin for the specified <code><a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a></code>.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>: u64 = 2;
</code></pre>



<a name="access_management_access_ENotActionAdmin"></a>

The specified action witness does not belong to <code><a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>'s</code> package.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_ENotActionAdmin">ENotActionAdmin</a>: u64 = 3;
</code></pre>



<a name="access_management_access_EPolicyDisabled"></a>

The <code><a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a></code> is disabled.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_EPolicyDisabled">EPolicyDisabled</a>: u64 = 4;
</code></pre>



<a name="access_management_access_EEntityNotAllowed"></a>

The <code><a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a></code> is not allowed in the <code><a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a></code>.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_EEntityNotAllowed">EEntityNotAllowed</a>: u64 = 5;
</code></pre>



<a name="access_management_access_EActionNotInRule"></a>

The provided action is not allowed in the specified rule.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_EActionNotInRule">EActionNotInRule</a>: u64 = 6;
</code></pre>



<a name="access_management_access_EInvalidConditionApproval"></a>

An approved condition does not belong to the required rule.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_EInvalidConditionApproval">EInvalidConditionApproval</a>: u64 = 7;
</code></pre>



<a name="access_management_access_EInvalidPolicyVersion"></a>

The <code><a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a></code> version does not match the module version.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_EInvalidPolicyVersion">EInvalidPolicyVersion</a>: u64 = 8;
</code></pre>



<a name="access_management_access_ENotUpgrade"></a>

The migration is not allowed because the object version is higher or equal to the module
version.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_ENotUpgrade">ENotUpgrade</a>: u64 = 9;
</code></pre>



<a name="access_management_access_EActionMismatch"></a>

The action does not match the action in the request.


<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_EActionMismatch">EActionMismatch</a>: u64 = 10;
</code></pre>



<a name="access_management_access_MODULE_VERSION"></a>



<pre><code><b>const</b> <a href="../../dependencies/access_management/access.md#access_management_access_MODULE_VERSION">MODULE_VERSION</a>: u16 = 1;
</code></pre>



<a name="access_management_access_check_version"></a>

## Function `check_version`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>) {
    <b>assert</b>!(policy.version == <a href="../../dependencies/access_management/access.md#access_management_access_MODULE_VERSION">MODULE_VERSION</a>, <a href="../../dependencies/access_management/access.md#access_management_access_EInvalidPolicyVersion">EInvalidPolicyVersion</a>);
}
</code></pre>



</details>

<a name="access_management_access_migrate_policy_version"></a>

## Function `migrate_policy_version`

Migrates the given policy to the current module version.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_migrate_policy_version">migrate_policy_version</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_migrate_policy_version">migrate_policy_version</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>) {
    <b>assert</b>!(policy.version &lt; <a href="../../dependencies/access_management/access.md#access_management_access_MODULE_VERSION">MODULE_VERSION</a>, <a href="../../dependencies/access_management/access.md#access_management_access_ENotUpgrade">ENotUpgrade</a>);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    policy.version = <a href="../../dependencies/access_management/access.md#access_management_access_MODULE_VERSION">MODULE_VERSION</a>;
}
</code></pre>



</details>

<a name="access_management_access_claim_package"></a>

## Function `claim_package`

Claims package admin rights using a one-time witness.

Aborts if the witness is not a valid one-time witness or if it does not originate from the expected module.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_claim_package">claim_package</a>&lt;OTW: drop&gt;(otw: OTW, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_claim_package">claim_package</a>&lt;OTW: drop&gt;(otw: OTW, ctx: &<b>mut</b> TxContext): <a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a> {
    <b>assert</b>!(types::is_one_time_witness(&otw), <a href="../../dependencies/access_management/access.md#access_management_access_ENotOneTimeWitness">ENotOneTimeWitness</a>);
    <b>let</b> `type` = type_name::get_with_original_ids&lt;OTW&gt;();
    <b>let</b> module_name = `type`.get_module();
    <b>assert</b>!(module_name == ascii::string(b"access_init"), <a href="../../dependencies/access_management/access.md#access_management_access_EClaimFromInvalidModule">EClaimFromInvalidModule</a>);
    <a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a> {
        id: object::new(ctx),
        package: `type`.get_address(),
    }
}
</code></pre>



</details>

<a name="access_management_access_irreversibly_destroy_admin"></a>

## Function `irreversibly_destroy_admin`

Irreversibly destroys a package admin.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_irreversibly_destroy_admin">irreversibly_destroy_admin</a>(admin: <a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_irreversibly_destroy_admin">irreversibly_destroy_admin</a>(admin: <a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>) {
    <b>let</b> <a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a> { id, package: _ } = admin;
    id.delete();
}
</code></pre>



</details>

<a name="access_management_access_create_entity"></a>

## Function `create_entity`

Creates a new entity.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_create_entity">create_entity</a>(ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_Entity">access_management::access::Entity</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_create_entity">create_entity</a>(ctx: &<b>mut</b> TxContext): <a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a> {
    <a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a> {
        id: object::new(ctx),
    }
}
</code></pre>



</details>

<a name="access_management_access_destroy_entity"></a>

## Function `destroy_entity`

Destroys an entity.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_destroy_entity">destroy_entity</a>(entity: <a href="../../dependencies/access_management/access.md#access_management_access_Entity">access_management::access::Entity</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_destroy_entity">destroy_entity</a>(entity: <a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a>) {
    <b>let</b> <a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a> { id } = entity;
    id.delete();
}
</code></pre>



</details>

<a name="access_management_access_create_empty_policy"></a>

## Function `create_empty_policy`

Creates a new, empty policy.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_create_empty_policy">create_empty_policy</a>(admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_create_empty_policy">create_empty_policy</a>(admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>, ctx: &<b>mut</b> TxContext): <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a> {
    <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a> {
        id: object::new(ctx),
        package: admin.package,
        allowed_entities: vec_set::empty(),
        rules: vec_map::empty(),
        enabled: <b>true</b>,
        version: <a href="../../dependencies/access_management/access.md#access_management_access_MODULE_VERSION">MODULE_VERSION</a>,
    }
}
</code></pre>



</details>

<a name="access_management_access_allowlist_entity_for_policy"></a>

## Function `allowlist_entity_for_policy`

Adds an entity to the allowlist for a policy.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_allowlist_entity_for_policy">allowlist_entity_for_policy</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, entity_id: &<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_allowlist_entity_for_policy">allowlist_entity_for_policy</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>, entity_id: &ID) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    vec_set::insert(&<b>mut</b> policy.allowed_entities, *entity_id);
}
</code></pre>



</details>

<a name="access_management_access_remove_entity_from_policy"></a>

## Function `remove_entity_from_policy`

Removes an entity from the policy allowlist.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_remove_entity_from_policy">remove_entity_from_policy</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, entity_id: &<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_remove_entity_from_policy">remove_entity_from_policy</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>, entity_id: &ID) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    vec_set::remove(&<b>mut</b> policy.allowed_entities, entity_id);
}
</code></pre>



</details>

<a name="access_management_access_enable_policy"></a>

## Function `enable_policy`

Enables a policy.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_enable_policy">enable_policy</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_enable_policy">enable_policy</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    policy.enabled = <b>true</b>;
}
</code></pre>



</details>

<a name="access_management_access_disable_policy"></a>

## Function `disable_policy`

Disables a policy.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_disable_policy">disable_policy</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_disable_policy">disable_policy</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    policy.enabled = <b>false</b>;
}
</code></pre>



</details>

<a name="access_management_access_destroy_empty_policy"></a>

## Function `destroy_empty_policy`

Destroys an empty policy.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_destroy_empty_policy">destroy_empty_policy</a>(policy: <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_destroy_empty_policy">destroy_empty_policy</a>(policy: <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(&policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a> { id, package: _, allowed_entities: _, rules, enabled: _, version: _ } = policy;
    id.delete();
    rules.destroy_empty();
}
</code></pre>



</details>

<a name="access_management_access_share_policy"></a>

## Function `share_policy`

Shares a policy object.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_share_policy">share_policy</a>(policy: <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_share_policy">share_policy</a>(policy: <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(&policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    transfer::share_object(policy);
}
</code></pre>



</details>

<a name="access_management_access_add_empty_rule"></a>

## Function `add_empty_rule`

Adds an empty rule to the policy and returns the key of the new rule.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_empty_rule">add_empty_rule</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_empty_rule">add_empty_rule</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>, ctx: &<b>mut</b> TxContext): <b>address</b> {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> rule_id = tx_context::fresh_object_address(ctx);
    <b>let</b> rule = <a href="../../dependencies/access_management/access.md#access_management_access_Rule">Rule</a> {
        actions: vec_set::empty(),
        conditions: vec_set::empty(),
        condition_configs: dynamic_map::new(ctx),
    };
    policy.rules.insert(rule_id, rule);
    rule_id
}
</code></pre>



</details>

<a name="access_management_access_drop_rule"></a>

## Function `drop_rule`

Removes and destroys the rules from the policy.
NOTE: This will drop the rule potentially with rule configs still stored as dynamic fields
which means the storage rebate will not be returned to the caller. To collect the rebate,
the caller should manually remove the rule configs before calling this function.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_drop_rule">drop_rule</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_drop_rule">drop_rule</a>(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>, rule_id: <b>address</b>) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> (_, rule) = policy.rules.remove(&rule_id);
    <b>let</b> <a href="../../dependencies/access_management/access.md#access_management_access_Rule">Rule</a> { actions: _, conditions: _, condition_configs } = rule;
    condition_configs.force_drop();
}
</code></pre>



</details>

<a name="access_management_access_add_action_to_rule"></a>

## Function `add_action_to_rule`

Adds an action to a rule.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_action_to_rule">add_action_to_rule</a>&lt;Action: drop&gt;(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_action_to_rule">add_action_to_rule</a>&lt;Action: drop&gt;(
    policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
    rule_id: <b>address</b>,
) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> orig_package = type_name::get_with_original_ids&lt;Action&gt;().get_address();
    <b>assert</b>!(orig_package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotActionAdmin">ENotActionAdmin</a>);
    <b>let</b> rule = &<b>mut</b> policy.rules[&rule_id];
    <b>let</b> action_name = type_name::get&lt;Action&gt;();
    rule.actions.insert(action_name);
}
</code></pre>



</details>

<a name="access_management_access_remove_action_from_rule"></a>

## Function `remove_action_from_rule`

Removes an action from a rule.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_remove_action_from_rule">remove_action_from_rule</a>&lt;Action: drop&gt;(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_remove_action_from_rule">remove_action_from_rule</a>&lt;Action: drop&gt;(
    policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
    rule_id: <b>address</b>,
) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> rule = vec_map::get_mut(&<b>mut</b> policy.rules, &rule_id);
    <b>let</b> action_name = type_name::get&lt;Action&gt;();
    rule.actions.remove(&action_name);
}
</code></pre>



</details>

<a name="access_management_access_add_condition_to_rule_with_config"></a>

## Function `add_condition_to_rule_with_config`

Adds a condition with configuration to a rule.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_condition_to_rule_with_config">add_condition_to_rule_with_config</a>&lt;Condition: drop, Config: <b>copy</b>, drop, store&gt;(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>, config: Config)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_condition_to_rule_with_config">add_condition_to_rule_with_config</a>&lt;Condition: drop, Config: store + <b>copy</b> + drop&gt;(
    policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
    rule_id: <b>address</b>,
    config: Config,
) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> rule = vec_map::get_mut(&<b>mut</b> policy.rules, &rule_id);
    <b>let</b> condition_name = type_name::get&lt;Condition&gt;();
    rule.conditions.insert(condition_name);
    rule.condition_configs.insert(condition_name, config);
}
</code></pre>



</details>

<a name="access_management_access_add_condition_to_rule"></a>

## Function `add_condition_to_rule`

Adds a condition without configuration to a rule.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_condition_to_rule">add_condition_to_rule</a>&lt;Condition: drop&gt;(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_condition_to_rule">add_condition_to_rule</a>&lt;Condition: drop&gt;(
    policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
    rule_id: <b>address</b>,
) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <a href="../../dependencies/access_management/access.md#access_management_access_add_condition_to_rule_with_config">add_condition_to_rule_with_config</a>&lt;Condition, <a href="../../dependencies/access_management/access.md#access_management_access_ConfigNone">ConfigNone</a>&gt;(
        policy,
        admin,
        rule_id,
        <a href="../../dependencies/access_management/access.md#access_management_access_ConfigNone">ConfigNone</a> {},
    );
}
</code></pre>



</details>

<a name="access_management_access_remove_condition_from_rule"></a>

## Function `remove_condition_from_rule`

Removes a condition from a rule.
Aborts if the condition config is not the <code><a href="../../dependencies/access_management/access.md#access_management_access_ConfigNone">ConfigNone</a></code> default config.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_remove_condition_from_rule">remove_condition_from_rule</a>&lt;Condition: drop&gt;(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_remove_condition_from_rule">remove_condition_from_rule</a>&lt;Condition: drop&gt;(
    policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
    rule_id: <b>address</b>,
) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> rule = &<b>mut</b> policy.rules[&rule_id];
    <b>let</b> condition_name = type_name::get&lt;Condition&gt;();
    rule.condition_configs.remove&lt;TypeName, <a href="../../dependencies/access_management/access.md#access_management_access_ConfigNone">ConfigNone</a>&gt;(condition_name);
    rule.conditions.remove(&condition_name);
}
</code></pre>



</details>

<a name="access_management_access_add_config_for_condition"></a>

## Function `add_config_for_condition`

Adds configuration for a condition.
Aborts if the config is not the <code><a href="../../dependencies/access_management/access.md#access_management_access_ConfigNone">ConfigNone</a></code> default config.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_config_for_condition">add_config_for_condition</a>&lt;Condition, Config: <b>copy</b>, drop, store&gt;(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>, config: Config)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_add_config_for_condition">add_config_for_condition</a>&lt;Condition, Config: store + <b>copy</b> + drop&gt;(
    policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
    rule_id: <b>address</b>,
    config: Config,
) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> rule = &<b>mut</b> policy.rules[&rule_id];
    <b>let</b> condition_name = type_name::get&lt;Condition&gt;();
    rule.condition_configs.remove&lt;TypeName, <a href="../../dependencies/access_management/access.md#access_management_access_ConfigNone">ConfigNone</a>&gt;(condition_name);
    rule.condition_configs.insert(condition_name, config);
}
</code></pre>



</details>

<a name="access_management_access_remove_config_for_condition"></a>

## Function `remove_config_for_condition`

Removes configuration for a condition.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_remove_config_for_condition">remove_config_for_condition</a>&lt;Condition, Config: <b>copy</b>, drop, store&gt;(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_remove_config_for_condition">remove_config_for_condition</a>&lt;Condition, Config: store + <b>copy</b> + drop&gt;(
    policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
    rule_id: <b>address</b>,
) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> rule = &<b>mut</b> policy.rules[&rule_id];
    <b>let</b> condition_name = type_name::get&lt;Condition&gt;();
    rule.condition_configs.remove&lt;TypeName, Config&gt;(condition_name);
    rule.condition_configs.insert(condition_name, <a href="../../dependencies/access_management/access.md#access_management_access_ConfigNone">ConfigNone</a> {});
}
</code></pre>



</details>

<a name="access_management_access_borrow_condition_config"></a>

## Function `borrow_condition_config`

Borrows condition configuration from a policy.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_borrow_condition_config">borrow_condition_config</a>&lt;Condition, Config: <b>copy</b>, drop, store&gt;(policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, rule_id: &<b>address</b>): &Config
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_borrow_condition_config">borrow_condition_config</a>&lt;Condition, Config: store + <b>copy</b> + drop&gt;(
    policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    rule_id: &<b>address</b>,
): &Config {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>let</b> rule = &policy.rules[rule_id];
    <b>let</b> condition_name = type_name::get&lt;Condition&gt;();
    &rule.condition_configs[condition_name]
}
</code></pre>



</details>

<a name="access_management_access_borrow_mut_condition_config"></a>

## Function `borrow_mut_condition_config`

Borrows mutable condition configuration from a policy.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_borrow_mut_condition_config">borrow_mut_condition_config</a>&lt;Condition, Config: <b>copy</b>, drop, store&gt;(policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>, rule_id: <b>address</b>): &<b>mut</b> Config
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_borrow_mut_condition_config">borrow_mut_condition_config</a>&lt;Condition, Config: store + <b>copy</b> + drop&gt;(
    policy: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
    rule_id: <b>address</b>,
): &<b>mut</b> Config {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotPolicyAdmin">ENotPolicyAdmin</a>);
    <b>let</b> rule = &<b>mut</b> policy.rules[&rule_id];
    <b>let</b> condition_name = type_name::get&lt;Condition&gt;();
    &<b>mut</b> rule.condition_configs[condition_name]
}
</code></pre>



</details>

<a name="access_management_access_new_request"></a>

## Function `new_request`

Creates a new action request.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_new_request">new_request</a>&lt;Action: drop&gt;(_: Action, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_new_request">new_request</a>&lt;Action: drop&gt;(_: Action, ctx: &<b>mut</b> TxContext): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a> {
    <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a> {
        action_name: type_name::get&lt;Action&gt;(),
        context: dynamic_map::new(ctx),
        approved_conditions: vec_map::empty(),
    }
}
</code></pre>



</details>

<a name="access_management_access_new_request_for_resource"></a>

## Function `new_request_for_resource`

Populates the context with the <code>resource_id</code> and <code>resource_type_name</code> fields
for the provided resource.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_new_request_for_resource">new_request_for_resource</a>&lt;T: key&gt;(action: <a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>, resource: &T, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_new_request_for_resource">new_request_for_resource</a>&lt;T: key&gt;(
    action: String,
    resource: &T,
    ctx: &<b>mut</b> TxContext,
): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a> {
    <b>let</b> <b>mut</b> request = <a href="../../dependencies/access_management/access.md#access_management_access_new_request">new_request</a>(action, ctx);
    request.context.insert(ascii::string(b"resource_id"), object::id(resource));
    request.context.insert(ascii::string(b"resource_type_name"), type_name::get&lt;T&gt;());
    request
}
</code></pre>



</details>

<a name="access_management_access_new_request_with_context"></a>

## Function `new_request_with_context`

Creates a new action request with pre-populated context.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_new_request_with_context">new_request_with_context</a>&lt;Action: drop&gt;(_: Action, context: <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;<a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>&gt;): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_new_request_with_context">new_request_with_context</a>&lt;Action: drop&gt;(
    _: Action,
    context: DynamicMap&lt;<a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>&gt;,
): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a> {
    <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a> {
        action_name: type_name::get&lt;Action&gt;(),
        context,
        approved_conditions: vec_map::empty(),
    }
}
</code></pre>



</details>

<a name="access_management_access_borrow_context"></a>

## Function `borrow_context`

Borrows the context from an action request.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_borrow_context">borrow_context</a>(request: &<a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>): &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;<a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_borrow_context">borrow_context</a>(request: &<a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>): &DynamicMap&lt;String&gt; {
    &request.context
}
</code></pre>



</details>

<a name="access_management_access_context_value"></a>

## Function `context_value`

Gets a value from the action request context.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_context_value">context_value</a>&lt;Value: <b>copy</b>, drop, store&gt;(request: &<a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>, key: <a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>): &Value
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_context_value">context_value</a>&lt;Value: store + <b>copy</b> + drop&gt;(request: &<a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>, key: String): &Value {
    &request.context[key]
}
</code></pre>



</details>

<a name="access_management_access_get_condition_witness"></a>

## Function `get_condition_witness`

Gets a condition witness for approval.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_get_condition_witness">get_condition_witness</a>&lt;Condition, Action: drop, Config: <b>copy</b>, drop, store&gt;(policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, entity: &<a href="../../dependencies/access_management/access.md#access_management_access_Entity">access_management::access::Entity</a>, rule_id: <b>address</b>): <a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">access_management::access::ConditionWitness</a>&lt;Condition, Config&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_get_condition_witness">get_condition_witness</a>&lt;Condition, Action: drop, Config: store + <b>copy</b> + drop&gt;(
    policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    entity: &<a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a>,
    rule_id: <b>address</b>,
): <a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">ConditionWitness</a>&lt;Condition, Config&gt; {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.enabled, <a href="../../dependencies/access_management/access.md#access_management_access_EPolicyDisabled">EPolicyDisabled</a>);
    <b>assert</b>!(policy.allowed_entities.contains(&object::id(entity)), <a href="../../dependencies/access_management/access.md#access_management_access_EEntityNotAllowed">EEntityNotAllowed</a>);
    <b>let</b> rule = &policy.rules[&rule_id];
    <b>let</b> action_name = type_name::get&lt;Action&gt;();
    <b>assert</b>!(rule.actions.contains(&action_name), <a href="../../dependencies/access_management/access.md#access_management_access_EActionNotInRule">EActionNotInRule</a>);
    <b>let</b> condition_name = type_name::get&lt;Condition&gt;();
    <b>let</b> config = rule.condition_configs[condition_name];
    <a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">ConditionWitness</a> {
        rule_id,
        config,
        policy: object::id(policy),
        entity: object::id(entity),
    }
}
</code></pre>



</details>

<a name="access_management_access_cw_rule_id"></a>

## Function `cw_rule_id`

Gets the rule ID from a condition witness.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_cw_rule_id">cw_rule_id</a>&lt;Condition, Config: <b>copy</b>, drop, store&gt;(witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">access_management::access::ConditionWitness</a>&lt;Condition, Config&gt;): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_cw_rule_id">cw_rule_id</a>&lt;Condition, Config: store + <b>copy</b> + drop&gt;(
    witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">ConditionWitness</a>&lt;Condition, Config&gt;,
): <b>address</b> {
    witness.rule_id
}
</code></pre>



</details>

<a name="access_management_access_cw_config"></a>

## Function `cw_config`

Gets the configuration from a condition witness.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_cw_config">cw_config</a>&lt;Condition, Config: <b>copy</b>, drop, store&gt;(witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">access_management::access::ConditionWitness</a>&lt;Condition, Config&gt;): Config
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_cw_config">cw_config</a>&lt;Condition, Config: store + <b>copy</b> + drop&gt;(
    witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">ConditionWitness</a>&lt;Condition, Config&gt;,
): Config {
    witness.config
}
</code></pre>



</details>

<a name="access_management_access_cw_policy_id"></a>

## Function `cw_policy_id`

Gets the policy ID from a condition witness.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_cw_policy_id">cw_policy_id</a>&lt;Condition, Config: <b>copy</b>, drop, store&gt;(witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">access_management::access::ConditionWitness</a>&lt;Condition, Config&gt;): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_cw_policy_id">cw_policy_id</a>&lt;Condition, Config: store + <b>copy</b> + drop&gt;(
    witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">ConditionWitness</a>&lt;Condition, Config&gt;,
): ID {
    witness.policy
}
</code></pre>



</details>

<a name="access_management_access_cw_entity_id"></a>

## Function `cw_entity_id`

Gets the entity ID from a condition witness.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_cw_entity_id">cw_entity_id</a>&lt;Condition, Config: <b>copy</b>, drop, store&gt;(witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">access_management::access::ConditionWitness</a>&lt;Condition, Config&gt;): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_cw_entity_id">cw_entity_id</a>&lt;Condition, Config: store + <b>copy</b> + drop&gt;(
    witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">ConditionWitness</a>&lt;Condition, Config&gt;,
): ID {
    witness.entity
}
</code></pre>



</details>

<a name="access_management_access_approve_condition"></a>

## Function `approve_condition`

Approves a condition for an action request.
Aborts if the condition is not needed for the action request.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_approve_condition">approve_condition</a>&lt;Condition: drop, Config: <b>copy</b>, drop, store&gt;(request: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>, witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">access_management::access::ConditionWitness</a>&lt;Condition, Config&gt;, _: Condition)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_approve_condition">approve_condition</a>&lt;Condition: drop, Config: store + <b>copy</b> + drop&gt;(
    request: &<b>mut</b> <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>,
    witness: &<a href="../../dependencies/access_management/access.md#access_management_access_ConditionWitness">ConditionWitness</a>&lt;Condition, Config&gt;,
    _: Condition,
) {
    <b>let</b> condition_name = type_name::get&lt;Condition&gt;();
    request.approved_conditions.insert(condition_name, witness.rule_id);
}
</code></pre>



</details>

<a name="access_management_access_approve_and_return_context"></a>

## Function `approve_and_return_context`

Approves an action request and returns the context.

Aborts with:
- <code><a href="../../dependencies/access_management/access.md#access_management_access_EInvalidConditionApproval">EInvalidConditionApproval</a></code> if an approved condition's rule id does not
match the requested rule id.
- <code>std::vector::EKeyDoesNotExist</code> if a required condition is not present
in the approved conditions or has already been approved.
- <code><a href="../../dependencies/sui/vec_map.md#sui_vec_map_EMapEmpty">sui::vec_map::EMapEmpty</a></code> if one or more required conditions have not
been approved.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_approve_and_return_context">approve_and_return_context</a>(request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>, entity: &<a href="../../dependencies/access_management/access.md#access_management_access_Entity">access_management::access::Entity</a>, policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, rule_id: <b>address</b>): <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;<a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_approve_and_return_context">approve_and_return_context</a>(
    request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>,
    entity: &<a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a>,
    policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    rule_id: <b>address</b>,
): DynamicMap&lt;String&gt; {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>assert</b>!(policy.enabled, <a href="../../dependencies/access_management/access.md#access_management_access_EPolicyDisabled">EPolicyDisabled</a>);
    <b>assert</b>!(policy.allowed_entities.contains(&object::id(entity)), <a href="../../dependencies/access_management/access.md#access_management_access_EEntityNotAllowed">EEntityNotAllowed</a>);
    <b>let</b> rule = &policy.rules[&rule_id];
    <b>let</b> <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a> { action_name, context, <b>mut</b> approved_conditions } = request;
    <b>assert</b>!(rule.actions.contains(&action_name), <a href="../../dependencies/access_management/access.md#access_management_access_EActionNotInRule">EActionNotInRule</a>);
    <b>let</b> <b>mut</b> required_conditions = rule.conditions;
    <b>let</b> size = required_conditions.size();
    <b>let</b> <b>mut</b> i = 0;
    <b>while</b> (i &lt; size) {
        <b>let</b> (approved_condition_name, approved_rule_id) = approved_conditions.pop();
        <b>assert</b>!(approved_rule_id == rule_id, <a href="../../dependencies/access_management/access.md#access_management_access_EInvalidConditionApproval">EInvalidConditionApproval</a>);
        required_conditions.remove(&approved_condition_name);
        i = i + 1;
    };
    context
}
</code></pre>



</details>

<a name="access_management_access_approve_request"></a>

## Function `approve_request`

Approves an action request.
Note: Drops the request context without checking if it's empty. This means that the
storage rebate for these dynamic fields will not be returned to the caller.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_approve_request">approve_request</a>(request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>, entity: &<a href="../../dependencies/access_management/access.md#access_management_access_Entity">access_management::access::Entity</a>, policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, rule_id: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_approve_request">approve_request</a>(
    request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>,
    entity: &<a href="../../dependencies/access_management/access.md#access_management_access_Entity">Entity</a>,
    policy: &<a href="../../dependencies/access_management/access.md#access_management_access_Policy">Policy</a>,
    rule_id: <b>address</b>,
) {
    <a href="../../dependencies/access_management/access.md#access_management_access_check_version">check_version</a>(policy);
    <b>let</b> context = <a href="../../dependencies/access_management/access.md#access_management_access_approve_and_return_context">approve_and_return_context</a>(request, entity, policy, rule_id);
    context.force_drop();
}
</code></pre>



</details>

<a name="access_management_access_admin_approve_request_and_return_context"></a>

## Function `admin_approve_request_and_return_context`

Admin approves an action request and returns the context.
Note: this will not work if the action type was added in an upgrade. Use
<code><a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_with_original_id_and_return_context">admin_approve_request_with_original_id_and_return_context</a></code> instead.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_and_return_context">admin_approve_request_and_return_context</a>(request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>): <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;<a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_and_return_context">admin_approve_request_and_return_context</a>(
    request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
): DynamicMap&lt;String&gt; {
    <b>let</b> request_package = request.action_name.get_address();
    <b>assert</b>!(request_package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotActionAdmin">ENotActionAdmin</a>);
    <b>let</b> <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a> {
        action_name: _,
        context,
        approved_conditions: _,
    } = request;
    context
}
</code></pre>



</details>

<a name="access_management_access_admin_approve_request"></a>

## Function `admin_approve_request`

Admin approves an action request.
Note: this will not work if the action type was added in an upgrade. Use
<code><a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_with_original_id">admin_approve_request_with_original_id</a></code> instead.
Note: Drops the request context without checking if it's empty. This means that the
storage rebate for these dynamic fields will not be returned to the caller.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request">admin_approve_request</a>(request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request">admin_approve_request</a>(request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>) {
    <b>let</b> context = <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_and_return_context">admin_approve_request_and_return_context</a>(request, admin);
    context.force_drop();
}
</code></pre>



</details>

<a name="access_management_access_admin_approve_request_with_original_id_and_return_context"></a>

## Function `admin_approve_request_with_original_id_and_return_context`

Admin approves an action request with original ID and returns the context.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_with_original_id_and_return_context">admin_approve_request_with_original_id_and_return_context</a>&lt;Action: drop&gt;(request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>): <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;<a href="../../dependencies/std/ascii.md#std_ascii_String">std::ascii::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_with_original_id_and_return_context">admin_approve_request_with_original_id_and_return_context</a>&lt;Action: drop&gt;(
    request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
): DynamicMap&lt;String&gt; {
    <b>assert</b>!(type_name::get&lt;Action&gt;() == request.action_name, <a href="../../dependencies/access_management/access.md#access_management_access_EActionMismatch">EActionMismatch</a>);
    <b>let</b> orig_package = type_name::get_with_original_ids&lt;Action&gt;().get_address();
    <b>assert</b>!(orig_package == admin.package, <a href="../../dependencies/access_management/access.md#access_management_access_ENotActionAdmin">ENotActionAdmin</a>);
    <b>let</b> <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a> {
        action_name: _,
        context,
        approved_conditions: _,
    } = request;
    context
}
</code></pre>



</details>

<a name="access_management_access_admin_approve_request_with_original_id"></a>

## Function `admin_approve_request_with_original_id`

Admin approves an action request with original ID.
Note: Drops the request context without checking if it's empty. This means that the
storage rebate for these dynamic fields will not be returned to the caller.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_with_original_id">admin_approve_request_with_original_id</a>&lt;Action: drop&gt;(request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>, admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">access_management::access::PackageAdmin</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_with_original_id">admin_approve_request_with_original_id</a>&lt;Action: drop&gt;(
    request: <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">ActionRequest</a>,
    admin: &<a href="../../dependencies/access_management/access.md#access_management_access_PackageAdmin">PackageAdmin</a>,
) {
    <b>let</b> context = <a href="../../dependencies/access_management/access.md#access_management_access_admin_approve_request_with_original_id_and_return_context">admin_approve_request_with_original_id_and_return_context</a>&lt;Action&gt;(request, admin);
    context.force_drop();
}
</code></pre>



</details>

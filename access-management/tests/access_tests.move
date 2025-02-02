// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module access_management::access_tests {
    use sui::test_utils::destroy;
    use std::ascii::{Self, String};

    use access_management::dynamic_map;
    use access_management::access::{Self, ActionRequest, ConditionWitness, ConfigNone};

    public struct ADMIN_WITNESS has drop { }
    public struct ACTION has drop { }
    public struct CONDITION has drop { }

    public struct Config has copy, store, drop {
        ignore_context: bool
    }

    fun approve_condition (
        request: &mut ActionRequest, witness: &ConditionWitness<CONDITION, ConfigNone>
    ) {
        request.approve_condition(witness, CONDITION { });
    }

    fun approve_condition_with_config(
        request: &mut ActionRequest, witness: &ConditionWitness<CONDITION, Config>
    ) {
        if (witness.config().ignore_context) {
            request.approve_condition(witness, CONDITION { });
            return
        };

        let allow = *request.context_value<bool>(ascii::string(b"allow"));
        if (allow) {
            request.approve_condition(witness, CONDITION { });
        } else {
            abort(0)
        }
    }

    #[test]
    fun test_action_request_success() {
        let ctx = &mut tx_context::dummy();

        let admin = access::create_admin_for_testing<ADMIN_WITNESS>(ctx);
        let mut policy = access::create_empty_policy(&admin, ctx);
        let rule_id = policy.add_empty_rule(&admin, ctx);
        policy.add_action_to_rule<ACTION>(&admin, rule_id);

        let entity = access::create_entity(ctx);
        policy.allowlist_entity(&admin, object::borrow_id(&entity));

        let request = access::new_request(ACTION {}, ctx);
        access::approve_request(request, &entity, &policy, rule_id);

        destroy(admin);
        destroy(policy);
        destroy(entity);
    }

    #[test]
    #[expected_failure(abort_code = 5, location = access_management::access)]
    fun test_entity_not_allowed() {
        let ctx = &mut tx_context::dummy();

        let admin = access::create_admin_for_testing<ADMIN_WITNESS>(ctx);
        let mut policy = access::create_empty_policy(&admin, ctx);
        let rule_id = policy.add_empty_rule(&admin, ctx);
        policy.add_action_to_rule<ACTION>(&admin, rule_id);

        let entity = access::create_entity(ctx);
        policy.allowlist_entity(&admin, object::borrow_id(&entity));

        let request = access::new_request(ACTION {}, ctx);
        let invalid_entity = access::create_entity(ctx);
        access::approve_request(request, &invalid_entity, &policy, rule_id);

        destroy(admin);
        destroy(policy);
        destroy(entity);
        destroy(invalid_entity);
    }

    #[test]
    fun test_success_with_condition() {
        let ctx = &mut tx_context::dummy();

        let admin = access::create_admin_for_testing<ADMIN_WITNESS>(ctx);
        let mut policy = access::create_empty_policy(&admin, ctx);
        let rule_id = policy.add_empty_rule(&admin, ctx);
        access::add_action_to_rule<ACTION>(&mut policy, &admin, rule_id);
        let entity = access::create_entity(ctx);
        policy.allowlist_entity(&admin, object::borrow_id(&entity));

        policy.add_condition_to_rule<CONDITION>(&admin, rule_id);

        let mut request = access::new_request(ACTION {}, ctx);
        let cw = policy.get_condition_witness<CONDITION, ACTION, ConfigNone>(&entity, rule_id);

        approve_condition(&mut request, &cw);
        access::approve_request(request, &entity, &policy, rule_id);

        destroy(admin);
        destroy(policy);
        destroy(entity); 
    }

    #[test]
    #[expected_failure(abort_code = 4, location = sui::vec_map)]
    fun test_failure_condition_not_met() {
        let ctx = &mut tx_context::dummy();

        let admin = access::create_admin_for_testing<ADMIN_WITNESS>(ctx);
        let mut policy = access::create_empty_policy(&admin, ctx);
        let rule_id = access::add_empty_rule(&mut policy, &admin, ctx);
        access::add_action_to_rule<ACTION>(&mut policy, &admin, rule_id);
        let entity = access::create_entity(ctx);
        access::allowlist_entity_for_policy(&mut policy, &admin, object::borrow_id(&entity));

        access::add_condition_to_rule<CONDITION>(&mut policy, &admin, rule_id);

        let request = access::new_request(ACTION {}, ctx);
        access::approve_request(request, &entity, &policy, rule_id);

        destroy(admin);
        destroy(policy);
        destroy(entity); 
    }

    #[test]
    fun test_success_with_condition_with_config() {
        let ctx = &mut tx_context::dummy();

        let admin = access::create_admin_for_testing<ADMIN_WITNESS>(ctx);
        let mut policy = access::create_empty_policy(&admin, ctx);
        let rule_id = access::add_empty_rule(&mut policy, &admin, ctx);
        access::add_action_to_rule<ACTION>(&mut policy, &admin, rule_id);
        let entity = access::create_entity(ctx);
        access::allowlist_entity_for_policy(&mut policy, &admin, object::borrow_id(&entity));

        let config = Config { ignore_context: true };
        access::add_condition_to_rule_with_config<CONDITION, Config>(
            &mut policy, &admin, rule_id, config
        );

        let mut request = access::new_request(ACTION {}, ctx);
        let cw = access::get_condition_witness<CONDITION, ACTION, Config>(
            &policy, &entity, rule_id
        );

        approve_condition_with_config(&mut request, &cw);
        access::approve_request(request, &entity, &policy, rule_id);

        destroy(admin);
        destroy(policy);
        destroy(entity); 
    }

    #[test]
    fun test_success_with_condition_with_config_with_context() {
        let ctx = &mut tx_context::dummy();

        let admin = access::create_admin_for_testing<ADMIN_WITNESS>(ctx);
        let mut policy = access::create_empty_policy(&admin, ctx);
        let rule_id = access::add_empty_rule(&mut policy, &admin, ctx);
        access::add_action_to_rule<ACTION>(&mut policy, &admin, rule_id);
        let entity = access::create_entity(ctx);
        access::allowlist_entity_for_policy(&mut policy, &admin, object::borrow_id(&entity));

        let config = Config { ignore_context: false };
        access::add_condition_to_rule_with_config<CONDITION, Config>(
            &mut policy, &admin, rule_id, config
        );

        let mut context = dynamic_map::new<String>(ctx);
        dynamic_map::insert(&mut context, ascii::string(b"allow"), true);
        let mut request = access::new_request_with_context(ACTION {}, context);
        let cw = access::get_condition_witness<CONDITION, ACTION, Config>(
            &policy, &entity, rule_id
        );

        approve_condition_with_config(&mut request, &cw);
        access::approve_request(request, &entity, &policy, rule_id);

        destroy(admin);
        destroy(policy);
        destroy(entity); 
    }

    #[test]
    #[expected_failure(abort_code = 0, location = Self)]
    fun test_failure_with_condition_with_config_with_context() {
        let ctx = &mut tx_context::dummy();

        let admin = access::create_admin_for_testing<ADMIN_WITNESS>(ctx);
        let mut policy = access::create_empty_policy(&admin, ctx);
        let rule_id = access::add_empty_rule(&mut policy, &admin, ctx);
        access::add_action_to_rule<ACTION>(&mut policy, &admin, rule_id);
        let entity = access::create_entity(ctx);
        access::allowlist_entity_for_policy(&mut policy, &admin, object::borrow_id(&entity));

        let config = Config { ignore_context: false };
        access::add_condition_to_rule_with_config<CONDITION, Config>(
            &mut policy, &admin, rule_id, config
        );

        let mut context = dynamic_map::new<String>(ctx);
        dynamic_map::insert(&mut context, ascii::string(b"allow"), false);
        let mut request = access::new_request_with_context(ACTION {}, context);
        let cw = access::get_condition_witness<CONDITION, ACTION, Config>(
            &policy, &entity, rule_id
        );

        approve_condition_with_config(&mut request, &cw);
        access::approve_request(request, &entity, &policy, rule_id);

        destroy(admin);
        destroy(policy);
        destroy(entity); 
    }
}
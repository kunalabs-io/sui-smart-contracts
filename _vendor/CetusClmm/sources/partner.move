// Copyright (c) Cetus Technology Limited

/// "Partner" is a module of "clmmpool" that defines a "Partner" object. When a partner participates in a swap
/// transaction, they pass this object and will receive a share of the swap fee that belongs to them.
module cetus_clmm::partner;

use cetus_clmm::config::{GlobalConfig, check_partner_manager_role, checked_package_version};
use std::string::{Self, String};
use std::type_name;
use sui::bag::{Self, Bag};
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin::{Self, Coin};
use sui::event;
use sui::vec_map::{Self, VecMap};

/// The partner rate denominator.
#[allow(unused_const)]
const PARTNER_RATE_DENOMINATOR: u64 = 10000;
/// The max partner fee rate.
const MAX_PARTNER_FEE_RATE: u64 = 10000;

// =============== Errors =================
const EPartnerAlreadyExist: u64 = 1;
const EInvalidTime: u64 = 2;
const EInvalidPartnerRefFeeRate: u64 = 3;
const EInvalidPartnerCap: u64 = 4;
const EInvalidCoinType: u64 = 5;
const EInvalidPartnerName: u64 = 6;
const EDeprecatedFunction: u64 = 7;

// =============== Structs =================

/// Partners struct that stores a mapping of partner names to their IDs
/// * `id` - The unique identifier for this Partners object
/// * `partners` - A VecMap storing partner names (as String) mapped to their unique IDs
public struct Partners has key {
    id: UID,
    partners: VecMap<String, ID>,
}

/// PartnerCap is used to claim the parter fee generated when swap from partners which is owned by third parties.
/// * `id` - The unique identifier for this PartnerCap object
/// * `name` - The name of the partner
/// * `partner_id` - The ID of the partner
public struct PartnerCap has key, store {
    id: UID,
    name: String,
    partner_id: ID,
}

/// Partner is used to store the partner info.
/// * `id` - The unique identifier for this Partner object
/// * `name` - The name of the partner
/// * `ref_fee_rate` - The reference fee rate for the partner
/// * `start_time` - The start time of the partner's validity period
/// * `end_time` - The end time of the partner's validity period
/// * `balances` - A Bag storing the partner's balances for different coin types
public struct Partner has key, store {
    id: UID,
    name: String,
    ref_fee_rate: u64,
    start_time: u64,
    end_time: u64,
    balances: Bag,
}

// ============= Events =================
/// Emit when publish the module.
/// * `partners_id` - The unique identifier for this Partners object
public struct InitPartnerEvent has copy, drop {
    partners_id: ID,
}

/// Emit when create partner.
/// * `recipient` - The address of the recipient
/// * `partner_id` - The unique identifier for this Partner object
/// * `partner_cap_id` - The unique identifier for this PartnerCap object
/// * `ref_fee_rate` - The reference fee rate for the partner
/// * `name` - The name of the partner
/// * `start_time` - The start time of the partner's validity period
/// * `end_time` - The end time of the partner's validity period
public struct CreatePartnerEvent has copy, drop {
    recipient: address,
    partner_id: ID,
    partner_cap_id: ID,
    ref_fee_rate: u64,
    name: String,
    start_time: u64,
    end_time: u64,
}

/// Emit when update partner ref fee rate.
/// * `partner_id` - The unique identifier for this Partner object
/// * `old_fee_rate` - The old reference fee rate for the partner
/// * `new_fee_rate` - The new reference fee rate for the partner
public struct UpdateRefFeeRateEvent has copy, drop {
    partner_id: ID,
    old_fee_rate: u64,
    new_fee_rate: u64,
}

/// Emit when update partner time range.
/// * `partner_id` - The unique identifier for this Partner object
/// * `start_time` - The start time of the partner's validity period
/// * `end_time` - The end time of the partner's validity period
public struct UpdateTimeRangeEvent has copy, drop {
    partner_id: ID,
    start_time: u64,
    end_time: u64,
}

/// Emit when receive ref fee.
/// * `partner_id` - The unique identifier for this Partner object
/// * `amount` - The amount of the fee
/// * `type_name` - The type name of the fee
public struct ReceiveRefFeeEvent has copy, drop {
    partner_id: ID,
    amount: u64,
    type_name: String,
}

/// Emit when claim ref fee.
/// * `partner_id` - The unique identifier for this Partner object
/// * `amount` - The amount of the fee
/// * `type_name` - The type name of the fee
public struct ClaimRefFeeEvent has copy, drop {
    partner_id: ID,
    amount: u64,
    type_name: String,
}

/// Initialize the `Partners` object to store partner information
/// * `ctx` - The transaction context used to create the object
fun init(ctx: &mut TxContext) {
    let partners = Partners {
        id: object::new(ctx),
        partners: vec_map::empty(),
    };
    let partners_id = object::id(&partners);
    transfer::share_object(partners);
    event::emit(InitPartnerEvent {
        partners_id,
    });
}

/// Create one partner.
/// * `config` - The global configuration
/// * `partners` - The mutable reference to the `Partners` object
/// * `name` - The name of the partner
/// * `ref_fee_rate` - The reference fee rate for the partner
/// * `start_time` - The start time of the partner's validity period
/// * `end_time` - The end time of the partner's validity period
/// * `recipient` - The address of the recipient
/// * `clock` - The clock object
/// * `ctx` - The transaction context
public fun create_partner(
    config: &GlobalConfig,
    partners: &mut Partners,
    name: String,
    ref_fee_rate: u64,
    start_time: u64,
    end_time: u64,
    recipient: address,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    // Check params
    assert!(end_time > start_time, EInvalidTime);
    assert!(start_time >= clock::timestamp_ms(clock) / 1000, EInvalidTime);
    assert!(ref_fee_rate < MAX_PARTNER_FEE_RATE, EInvalidPartnerRefFeeRate);
    assert!(!string::is_empty(&name), EInvalidPartnerName);
    assert!(!vec_map::contains<String, ID>(&partners.partners, &name), EPartnerAlreadyExist);

    checked_package_version(config);
    check_partner_manager_role(config, tx_context::sender(ctx));

    // Crate partner and cap
    let partner = Partner {
        id: object::new(ctx),
        name,
        ref_fee_rate,
        start_time,
        end_time,
        balances: bag::new(ctx),
    };
    let partner_cap = PartnerCap {
        id: object::new(ctx),
        partner_id: object::id(&partner),
        name,
    };
    let (partner_id, partner_cap_id) = (object::id(&partner), object::id(&partner_cap));
    vec_map::insert<String, ID>(
        &mut partners.partners,
        name,
        partner_id,
    );
    transfer::share_object(partner);
    transfer::transfer<PartnerCap>(partner_cap, recipient);

    event::emit(CreatePartnerEvent {
        recipient,
        partner_id,
        partner_cap_id,
        ref_fee_rate,
        name,
        start_time,
        end_time,
    });
}

/// Get partner name.
/// * `partner` - The reference to the `Partner` object
/// * Returns the name of the partner
public fun name(partner: &Partner): String {
    partner.name
}

/// get partner ref_fee_rate.
/// * `partner` - The reference to the `Partner` object
/// * Returns the reference fee rate for the partner
public fun ref_fee_rate(partner: &Partner): u64 {
    partner.ref_fee_rate
}

/// get partner start_time.
/// * `partner` - The reference to the `Partner` object
/// * Returns the start time of the partner's validity period
public fun start_time(partner: &Partner): u64 {
    partner.start_time
}

/// get partner end_time.
/// * `partner` - The reference to the `Partner` object
/// * Returns the end time of the partner's validity period
public fun end_time(partner: &Partner): u64 {
    partner.end_time
}

/// get partner balances.
/// * `partner` - The reference to the `Partner` object
/// * Returns the balances of the partner
public fun balances(partner: &Partner): &Bag {
    &partner.balances
}

/// check the parter is valid or not, and return the partner ref_fee_rate.
/// * `partner` - The reference to the `Partner` object
/// * `current_time` - The current time
/// * Returns the current reference fee rate for the partner
public fun current_ref_fee_rate(partner: &Partner, current_time: u64): u64 {
    if (partner.start_time > current_time || partner.end_time <= current_time) {
        return 0
    };
    partner.ref_fee_rate
}

/// Update partner ref fee rate.
/// * `config` - The global configuration
/// * `partner` - The mutable reference to the `Partner` object
/// * `new_fee_rate` - The new reference fee rate for the partner
/// * `ctx` - The transaction context
public fun update_ref_fee_rate(
    config: &GlobalConfig,
    partner: &mut Partner,
    new_fee_rate: u64,
    ctx: &TxContext,
) {
    assert!(new_fee_rate < MAX_PARTNER_FEE_RATE, EInvalidPartnerRefFeeRate);

    checked_package_version(config);
    check_partner_manager_role(config, tx_context::sender(ctx));

    let old_fee_rate = partner.ref_fee_rate;
    partner.ref_fee_rate = new_fee_rate;
    event::emit(UpdateRefFeeRateEvent {
        partner_id: object::id(partner),
        old_fee_rate,
        new_fee_rate,
    });
}

/// Update partner time range.
/// * `config` - The global configuration
/// * `partner` - The mutable reference to the `Partner` object
/// * `start_time` - The start time of the partner's validity period
/// * `end_time` - The end time of the partner's validity period
/// * `clock` - The clock object
/// * `ctx` - The transaction context
public fun update_time_range(
    config: &GlobalConfig,
    partner: &mut Partner,
    start_time: u64,
    end_time: u64,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert!(end_time > start_time, EInvalidTime);
    assert!(end_time > clock::timestamp_ms(clock) / 1000, EInvalidTime);

    checked_package_version(config);
    check_partner_manager_role(config, tx_context::sender(ctx));

    partner.start_time = start_time;
    partner.end_time = end_time;
    event::emit(UpdateTimeRangeEvent {
        partner_id: object::id(partner),
        start_time,
        end_time,
    });
}

/// Receive ref fee.
/// This method is called when swap and partner is provided.
/// * `partner` - The mutable reference to the `Partner` object
/// * `fee` - The balance of the fee
public fun receive_ref_fee<T>(_partner: &mut Partner, _fee: Balance<T>) {
    abort EDeprecatedFunction
}

/// Receive ref fee.
/// This method is called when swap and partner is provided.
/// * `partner` - The mutable reference to the `Partner` object
/// * `fee` - The balance of the fee
public(package) fun receive_ref_fee_internal<T>(partner: &mut Partner, fee: Balance<T>) {
    let amount = balance::value<T>(&fee);
    let type_name = type_name::get<T>();
    let key = string::from_ascii(type_name::into_string(type_name));
    if (bag::contains(&partner.balances, key)) {
        let current_balance = bag::borrow_mut<String, Balance<T>>(&mut partner.balances, key);
        balance::join<T>(current_balance, fee);
    } else {
        bag::add<String, Balance<T>>(&mut partner.balances, key, fee);
    };

    event::emit(ReceiveRefFeeEvent {
        partner_id: object::id(partner),
        amount,
        type_name: key,
    });
}

#[allow(lint(self_transfer))]
/// The `PartnerCap` owner claim the parter fee by CoinType.
/// * `config` - The global configuration
/// * `partner_cap` - The reference to the `PartnerCap` object
/// * `partner` - The mutable reference to the `Partner` object
/// * `ctx` - The transaction context
public fun claim_ref_fee<T>(
    config: &GlobalConfig,
    partner_cap: &PartnerCap,
    partner: &mut Partner,
    ctx: &mut TxContext,
) {
    checked_package_version(config);
    assert!(partner_cap.partner_id == object::id(partner), EInvalidPartnerCap);

    let type_name = type_name::get<T>();
    let key = string::from_ascii(type_name::into_string(type_name));

    assert!(bag::contains<String>(&partner.balances, key), EInvalidCoinType);

    let current_balance = bag::remove<String, Balance<T>>(
        &mut partner.balances,
        key,
    );
    let amount = balance::value<T>(&current_balance);
    let fee_coin = coin::from_balance<T>(current_balance, ctx);
    transfer::public_transfer<Coin<T>>(fee_coin, tx_context::sender(ctx));

    event::emit(ClaimRefFeeEvent {
        partner_id: object::id(partner),
        amount,
        type_name: key,
    });
}

#[test_only]
public fun create_partner_for_test(
    name: String,
    ref_fee_rate: u64,
    start_time: u64,
    end_time: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (PartnerCap, Partner) {
    // Check params
    assert!(end_time > start_time, EInvalidTime);
    assert!(start_time >= clock::timestamp_ms(clock) / 1000, EInvalidTime);
    assert!(ref_fee_rate < MAX_PARTNER_FEE_RATE, EInvalidPartnerRefFeeRate);
    assert!(!string::is_empty(&name), EInvalidPartnerName);

    // Crate partner and cap
    let partner = Partner {
        id: object::new(ctx),
        name,
        ref_fee_rate,
        start_time,
        end_time,
        balances: bag::new(ctx),
    };
    let partner_cap = PartnerCap {
        id: object::new(ctx),
        partner_id: object::id(&partner),
        name,
    };
    (partner_cap, partner)
}

#[test_only]
use sui::test_scenario;
#[test_only]
use std::unit_test::assert_eq;

#[test_only]
public fun create_partners_for_test(ctx: &mut TxContext): Partners {
    Partners {
        id: object::new(ctx),
        partners: vec_map::empty(),
    }
}

#[test_only]
public fun return_partners(partners: Partners) {
    transfer::share_object(partners);
}

#[test]
fun test_init() {
    let mut sc = test_scenario::begin(@0x23);
    init(sc.ctx());
    sc.next_tx(@0x24);
    let partners = test_scenario::take_shared<Partners>(&sc);
    assert_eq!(partners.partners.size(), 0);
    test_scenario::return_shared(partners);
    test_scenario::end(sc);
}

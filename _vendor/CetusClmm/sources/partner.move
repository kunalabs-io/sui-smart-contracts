// Copyright (c) Cetus Technology Limited

#[allow(unused_type_parameter, unused_field)]
/// "Partner" is a module of "clmmpool" that defines a "Partner" object. When a partner participates in a swap
/// transaction, they pass this object and will receive a share of the swap fee that belongs to them.
module cetusclmm::partner {
    use sui::object::{UID, ID};
    use sui::vec_map::VecMap;
    use std::string::String;
    use sui::bag::Bag;
    use sui::balance::Balance;
    use sui::tx_context::TxContext;
    use sui::clock::Clock;

    use cetusclmm::config::GlobalConfig;

    // =============== Structs =================

     
    struct Partners has key {
        id: UID,
        partners: VecMap<String, ID>
    }

    
    struct PartnerCap has key, store {
        id: UID,
        name: String,
        partner_id: ID,
    }

    
    struct Partner has key, store {
        id: UID,
        name: String,
        ref_fee_rate: u64,
        start_time: u64,
        end_time: u64,
        balances: Bag,
    }


    // ============= Events =================
    
    
    /// Emit when publish the module.
    struct InitPartnerEvent has copy, drop {
        partners_id: ID,
    }

    
    /// Emit when create partner.
    struct CreatePartnerEvent has copy, drop {
        recipient: address,
        partner_id: ID,
        partner_cap_id: ID,
        ref_fee_rate: u64,
        name: String,
        start_time: u64,
        end_time: u64,
    }

    
    /// Emit when update partner ref fee rate.
    struct UpdateRefFeeRateEvent has copy, drop {
        partner_id: ID,
        old_fee_rate: u64,
        new_fee_rate: u64,
    }

    
    /// Emit when update partner time range.
    struct UpdateTimeRangeEvent has copy, drop {
        partner_id: ID,
        start_time: u64,
        end_time: u64,
    }

    
    /// Emit when receive ref fee.
    struct ReceiveRefFeeEvent has copy, drop {
        partner_id: ID,
        amount: u64,
        type_name: String,
    }

    
    /// Emit when claim ref fee.
    struct ClaimRefFeeEvent has copy, drop {
        partner_id: ID,
        amount: u64,
        type_name: String,
    }

    /// Create one partner.
    /// Params
    ///     - name: the partner name.
    ///     - ref_fee_rate: the partner ref fee rate.
    ///     - start_time: the partner valid start time.
    ///     - end_time: the partner valid end time.
    ///     - recipient: the partner cap recipient.
    public fun create_partner(
        _config: &GlobalConfig,
        _partners: &mut Partners,
        _name: String,
        _ref_fee_rate: u64,
        _start_time: u64,
        _end_time: u64,
        _recipient: address,
        _clock: &Clock,
        _ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Get partner name.
    public fun name(_partner: &Partner): String {
        abort 0
    }

    /// get partner ref_fee_rate.
    public fun ref_fee_rate(_partner: &Partner): u64 {
        abort 0
    }

    /// get partner start_time.
    public fun start_time(_partner: &Partner): u64 {
        abort 0
    }

    /// get partner end_time.
    public fun end_time(_partner: &Partner): u64 {
        abort 0
    }

    /// get partner balances.
    public fun balances(_partner: &Partner): &Bag {
        abort 0
    }

    /// check the parter is valid or not, and return the partner ref_fee_rate.
    public fun current_ref_fee_rate(
        _partner: &Partner,
        _current_time: u64
    ): u64 {
        abort 0
    }

    /// Update partner ref fee rate.
    public fun update_ref_fee_rate(
        _config: &GlobalConfig,
        _partner: &mut Partner,
        _new_fee_rate: u64,
        _ctx: &TxContext
    ) {
        abort 0
    }

    /// Update partner time range.
    public fun update_time_range(
        _config: &GlobalConfig,
        _partner: &mut Partner,
        _start_time: u64,
        _end_time: u64,
        _clock: &Clock,
        _ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Receive ref fee.
    /// This method is called when swap and partner is provided.
    public fun receive_ref_fee<T>(
        _partner: &mut Partner,
        _fee: Balance<T>
    ) {
        abort 0
    }

    /// The `PartnerCap` owner claim the parter fee by CoinType.
    public fun claim_ref_fee<T>(
        _config: &GlobalConfig,
        _partner_cap: &PartnerCap,
        _partner: &mut Partner,
        _ctx: &mut TxContext
    ) {
        abort 0
    }

    #[test_only]
    public fun create_partner_for_test(
        _name: String,
        _ref_fee_rate: u64,
        _start_time: u64,
        _end_time: u64,
        _clock: &Clock,
        _ctx: &mut TxContext
    ): (PartnerCap, Partner) {
        abort 0
    }

    #[test_only]
    public fun create_partners_for_test(_ctx: &mut TxContext): Partners {
        abort 0
    }

    #[test_only]
    public fun return_partners(_partners: Partners) {
        abort 0
    }    
}

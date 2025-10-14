/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::config {
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::table::{Self};
    use sui::dynamic_field;
    use sui::transfer;
    use std::vector;

    use integer_mate::i32::{I32};
    use bluefin_spot::tick_math;
    use bluefin_spot::utils;
    use bluefin_spot::constants;

    // local modules
    use bluefin_spot::errors;

    // friend modules
    friend bluefin_spot::admin;
    friend bluefin_spot::pool;
    #[test_only]
    friend bluefin_spot::test_config;

    //===========================================================//
    //                         Constants                         //
    //===========================================================//


    /// Tracks the current version of the package. Every time a breaking change is pushed, 
    /// increment the version on the new package, making any old version of the package 
    /// unable to be used
    const VERSION: u64 = 8;


    /// The protocol's config
    struct GlobalConfig has key, store {
        id: UID,
        min_tick: I32,
        max_tick: I32,
        version: u64,
        reward_managers: vector<address>
    }

    //===========================================================//
    //                     Friend Functions                      //
    //===========================================================//

    // removes a reward manager from global config. Only Admin can invoke this.
    public(friend) fun remove_reward_manager(config: &mut GlobalConfig, manager: address){

        assert!(verify_reward_manager(config, manager), errors::reward_manager_not_found());

        let index = 0;
        let len = vector::length(&config.reward_managers);
        while (index < len) {
            if (*(vector::borrow(&config.reward_managers, index)) == manager ) {
                vector::remove(&mut config.reward_managers, index);
                break
            };
            index = index + 1;
        } 
    }

    // Adds a reward manager in global config. Only Admin can invoke this.
    public(friend) fun set_reward_manager(config: &mut GlobalConfig, manager: address){
        // if provided manager is not already whitelisted only then add it
        assert!(!verify_reward_manager(config, manager), errors::already_a_reward_manger());
        vector::push_back<address>(&mut config.reward_managers, manager);
    }

    // Increases the version of the protocol supported. Only admin can invoke this.
    // Returns the old version and new version 
    public(friend) fun increase_version(config: &mut GlobalConfig): (u64, u64) {
        // ensures that config version is never increased beyond VERSION
        assert!(config.version < VERSION, errors::verion_cant_be_increased());

        let old_version = config.version;        
        config.version = config.version + 1; // can only move ahead 1 step
        (old_version, config.version)

    }


    public(friend) fun get_config_id(config: &mut GlobalConfig): &mut UID {
        &mut config.id
    }

    //===========================================================//
    //                      Initialization                       //
    //===========================================================//

    fun init(ctx: &mut TxContext) {
      
        let config = GlobalConfig {
            id: object::new(ctx),
            min_tick: tick_math::min_tick(), 
            max_tick: tick_math::max_tick(),
            version: VERSION,
            reward_managers: vector::empty<address>()
        };

        transfer::share_object(config);
    }


    //===========================================================//
    //                      Public Methods                       //
    //===========================================================//

    /// Returns the min/max tick allowed
    public fun get_tick_range(config: &GlobalConfig): (I32, I32){
        (config.min_tick, config.max_tick)
    }

    /// Assets if the config version matches the protocol version
    public fun verify_version(config: &GlobalConfig) {
        assert!(config.version == VERSION, errors::version_mismatch())
    }

    /// checks if the given address is the whitelisted rewards manager
    public fun verify_reward_manager(config: &GlobalConfig, manager: address) : bool
    {

        let i = 0;
        while (i < vector::length<address>(&config.reward_managers)) {
            let addr = vector::borrow<address>(&config.reward_managers, i);
            if (*addr == manager) {
                return true
            };
            i = i + 1;
        };
        return false
    }

    public fun get_pool_creation_fee_amount<CoinTypeFee>(protocol_config: &GlobalConfig): (bool, u64) {

        let uid = &protocol_config.id;
        let key = constants::pool_creation_fee_dynamic_key();
        let fee_coin_type = utils::get_type_string<CoinTypeFee>();

        if(!dynamic_field::exists_(uid, key)){
            return (false, 0)   
        };

        // get the fee table
        let fee_table = dynamic_field::borrow(uid, key);

        if(!table::contains(fee_table, fee_coin_type)){
            return (false, 0)
        };

        let fee_amount = *table::borrow(fee_table, fee_coin_type);

        return (true, fee_amount)

    }

    #[test_only]
    public fun create_config(ctx: &mut TxContext): GlobalConfig {
    
        let config = GlobalConfig {
            id: object::new(ctx),
            min_tick: tick_math::min_tick(), 
            max_tick: tick_math::max_tick(),
            version: VERSION,
            reward_managers: vector::empty<address>()
        };

        config
    }

    #[test_only]
    public fun increase_supported_version(config: &mut GlobalConfig): (u64, u64) {
        increase_version(config)
    }

    #[test_only]
    public fun get_supported_version(config: &GlobalConfig): u64 {
        config.version
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test_only]
    public fun set_version(config: &mut GlobalConfig, version: u64){
        config.version = version
    }

    // Additional test-only helper functions
    #[test_only]
    public fun get_reward_managers(config: &GlobalConfig): &vector<address> {
        &config.reward_managers
    }

    #[test_only]
    public fun get_min_tick(config: &GlobalConfig): I32 {
        config.min_tick
    }

    #[test_only]
    public fun get_max_tick(config: &GlobalConfig): I32 {
        config.max_tick
    }

    #[test_only]
    public fun get_version(config: &GlobalConfig): u64 {
        config.version
    }

    #[test_only]
    public fun get_id(config: &GlobalConfig): &UID {
        &config.id
    }

    #[test_only]
    public fun destroy_config_for_testing(config: GlobalConfig) {
        let GlobalConfig { id, min_tick: _, max_tick: _, version: _, reward_managers: _ } = config;
        object::delete(id);
    }
}
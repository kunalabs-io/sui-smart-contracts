/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::admin {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use std::string::{String};
    use sui::clock::{Clock};
    use sui::coin::{Self, Coin};
    use sui::table::{Self};
    use sui::balance::{Self, Balance};
    use sui::dynamic_field;


    // local modules
    use bluefin_spot::config::{Self, GlobalConfig};
    use bluefin_spot::pool::{Self, Pool};
    use bluefin_spot::utils;
    use bluefin_spot::events;
    use bluefin_spot::errors;
    use bluefin_spot::constants;

    //===========================================================//
    //                           Structs                         //
    //===========================================================//

    /// The holder of the cap is the admin of the protocol
    struct AdminCap has key {
        id: UID,
    }

    /// The holder of the cap can withdraw protocol fee from the pools
    struct ProtocolFeeCap has key {
        id: UID,
    }

    //===========================================================//
    //                      Initialization                       //
    //===========================================================//

    fun init(ctx: &mut TxContext) {
        
        // Generate a new AdminCap object with a unique identifier.
        let admin_cap = AdminCap { id: object::new(ctx) };
        let fee_cap = ProtocolFeeCap { id: object::new(ctx) };

        let deployer = tx_context::sender(ctx);

        // Transfer the AdminCap and ProtocolFeeCap to the sender of the transaction.
        transfer::transfer(admin_cap, deployer);
        transfer::transfer(fee_cap, deployer);

    }


    //===========================================================//
    //                       Entry Methods                       //
    //===========================================================//

    /// Transfers admin cap to the provided account address
    ///
    /// Parameters:
    /// - cap: The AdminCap, ensuring the caller is the current admin.
    /// - account: The address of the new admin
    #[allow(lint(public_entry))]
    public entry fun transer_admin_cap(protocol_config: &GlobalConfig, cap: AdminCap, account:address){
    
        // verify version
        config::verify_version(protocol_config);

        // transfer admin cap to the new admin
        transfer::transfer(cap, account);
        events::emit_admin_cap_transfer_event(account);

    }

    /// Transfers protocol fee cap to the provided account address
    ///
    /// Parameters:
    /// - cap: The ProtocolFeeCap, ensuring the caller is the current owner fee cap owner.
    /// - account: The address of the new fee cap account
    #[allow(lint(public_entry))]
    public entry fun transer_protocol_fee_cap(protocol_config: &GlobalConfig, cap: ProtocolFeeCap, account:address){

        // verify version
        config::verify_version(protocol_config);

        // transfer admin cap to the new admin
        transfer::transfer(cap, account);
        events::emit_protocol_fee_cap_transfer_event(account);

    }


    /// Allows the owner of protocol fee cap to withdraw protocol 
    /// fee from the provided pool for both coin A and coin B and 
    /// transfer to destination account
    ///
    /// Parameters:
    /// - cap: ProtocolFeeCap to ensure caller is the owner of this object
    /// - pool: A mutable reference to the pool from which protocol fee is to be withdrawn
    /// - coin_a_amount: The amount of coin A fee to be withdrawn
    /// - coin_b_amount: The amount of coin B fee to be withdrawn
    /// - destination: The address to which fee amount will be transferred
    /// - ctx: Mutable Tx Context of the sender/caller
    #[allow(lint(public_entry))]
    public entry fun claim_protocol_fee<CoinTypeA, CoinTypeB>(_: &ProtocolFeeCap, protocol_config: &GlobalConfig, pool: &mut Pool<CoinTypeA, CoinTypeB>, coin_a_amount: u64, coin_b_amount: u64, destination: address, ctx: &mut TxContext){
        
        // verify version
        config::verify_version(protocol_config);

        let protocol_fee_coin_a = pool::get_protocol_fee_for_coin_a(pool);
        let protocol_fee_coin_b = pool::get_protocol_fee_for_coin_b(pool);

        assert!(coin_a_amount <= protocol_fee_coin_a, errors::insufficient_amount());
        assert!(coin_b_amount <= protocol_fee_coin_b, errors::insufficient_amount());

        pool::set_protocol_fee_amount(pool, protocol_fee_coin_a - coin_a_amount, protocol_fee_coin_b - coin_b_amount);

        let (coin_a_balance, coin_b_balance) = pool::withdraw_balances(pool, coin_a_amount, coin_b_amount);
        let sequence_number = pool::increase_sequence_number(pool);

        utils::transfer_balance(coin_a_balance, destination, ctx);
        utils::transfer_balance(coin_b_balance, destination, ctx);

        let (coin_a_reserves, coin_b_reserves) = pool::coin_reserves(pool);

        events::emit_protocol_fee_collected(
            object::id<Pool<CoinTypeA,CoinTypeB>>(pool),
            tx_context::sender(ctx), 
            destination, 
            coin_a_amount, 
            coin_b_amount,
            coin_a_reserves,
            coin_b_reserves,
            sequence_number
        );


   }


   /// adds rewards manager to the global config
   /// Parameters:
   /// - cap: The AdminCap, ensuring the caller is the current admin.
   /// - protocol_config: mutable Global Config object
   /// - manager: The address of the manager to be removed
   #[allow(lint(public_entry))]
   public entry fun remove_reward_manager(_: &AdminCap, protocol_config: &mut GlobalConfig, manager: address)
   {
        // verify version
        config::verify_version(protocol_config);
        config::remove_reward_manager(protocol_config, manager);
        events::emit_reward_manager_update_event(
                manager,
                false
            );
   }

   /// Updates pool's "is_paused" status
   /// Parameters:
   /// - cap: The AdminCap, ensuring the caller is the current admin.
   /// - protocol_config: mutable Global Config object
   /// - status: status to be set
   #[allow(lint(public_entry))]
   public entry fun update_pool_pause_status<CoinTypeA, CoinTypeB>(_: &AdminCap, protocol_config: &GlobalConfig, pool: &mut Pool<CoinTypeA, CoinTypeB>, status: bool)
   {
        // verify version
        config::verify_version(protocol_config);
        pool::update_pause_status(pool, status);
   }

   /// remove a rewards manager from the global config
   /// Parameters:
   /// - cap: The AdminCap, ensuring the caller is the current admin.
   /// - protocol_config: mutable Global Config object
   /// - manager: The address of the new manager to be added
   #[allow(lint(public_entry))]
   public entry fun add_reward_manager(_: &AdminCap, protocol_config: &mut GlobalConfig, manager: address)
   {
         // verify version
        config::verify_version(protocol_config);
        config::set_reward_manager(protocol_config, manager);

        events::emit_reward_manager_update_event(
            manager,
            true
        )
   }

   /// initializes a reward for a given pool
   /// Parameters:
   /// - protocol_config: global config object for spot protocol
   /// - pool : pool object
   /// - start_time: start time for the rewards that are to be initialized (must be in future)
   /// - active_for_seconds: seconds for which rewards are to be allocated.
   /// - reward_coin: coin Object with balance for the reward that is to be initialized
   /// - reward_amount: amount of rewards to be given out
   /// - clock : sui clock object
   #[allow(lint(public_entry))]
   public entry fun initialize_pool_reward<CoinTypeA, CoinTypeB, RewardCoinType>(
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        start_time: u64,
        active_for_seconds: u64,
        reward_coin: Coin<RewardCoinType>, 
        reward_coin_symbol: String,
        reward_coin_decimals: u8,
        reward_amount: u64,
        clock: &Clock,
        ctx: &mut TxContext) {
        // verify version
        config::verify_version(protocol_config);

        let is_whitelisted_manager = config::verify_reward_manager(protocol_config, tx_context::sender(ctx));
        
        assert!(is_whitelisted_manager || pool::verify_pool_manager(pool, tx_context::sender(ctx)), errors::not_authorized());

        let reward_type = utils::get_type_string<RewardCoinType>();

        // if reward type is blue coin, then only whitelisted reward managers are allowed
        assert!(reward_type != constants::blue_reward_type() || is_whitelisted_manager, errors::not_authorized());
        
        assert!(reward_amount == coin::value(&reward_coin), errors::reward_amount_and_provided_balance_do_not_match());

        assert!(start_time >  utils::timestamp_seconds(clock),  errors::invalid_timestamp());

        pool::add_reward_info<CoinTypeA, CoinTypeB, RewardCoinType>(
            pool,
            pool::default_reward_info(
                reward_type,
                reward_coin_symbol,
                reward_coin_decimals,
                start_time
                )
            );
        
        pool::update_pool_reward_emission(
            pool,
            coin::into_balance(reward_coin),
            active_for_seconds,
            );
    }

    /// updates the emission for the initialized reward in pool
    /// Parameters:
    /// - protocol_config: global config object for spot protocol
    /// - pool : pool object
    /// - active_for_seconds: seconds for which rewards are to be allocated.
    /// - reward_coin: coin Object with balance for the reward that is to be initialized
    /// - reward_amount: amount of rewards to be given out
    /// - clock : sui clock object
    /// 
    #[allow(lint(public_entry))]
    public entry fun update_pool_reward_emission<CoinTypeA, CoinTypeB, RewardCoinType>(
        protocol_config: &GlobalConfig,
        pool: &mut  Pool<CoinTypeA, CoinTypeB>, 
        active_for_seconds: u64, 
        reward_coin: Coin<RewardCoinType>,
        reward_amount: u64,
        clock: &Clock, 
        ctx: &TxContext) {

        config::verify_version(protocol_config);

        let is_whitelisted_manager = config::verify_reward_manager(protocol_config, tx_context::sender(ctx));
        
        assert!(is_whitelisted_manager || pool::verify_pool_manager(pool, tx_context::sender(ctx)), errors::not_authorized());
        
        let reward_type = utils::get_type_string<RewardCoinType>();

        // if reward type is blue coin, then only whitelisted reward managers are allowed
        assert!(reward_type != constants::blue_reward_type() || is_whitelisted_manager, errors::not_authorized());

        assert!(reward_amount == coin::value(&reward_coin), errors::reward_amount_and_provided_balance_do_not_match());

        pool::update_reward_infos(pool,  utils::timestamp_seconds(clock));

         pool::update_pool_reward_emission(
            pool,
            coin::into_balance(reward_coin),
            active_for_seconds,
        );
    }


    
    /// adds additional seconds to the emission for the initialized reward in pool
    /// Parameters:
    /// - protocol_config: global config object for spot protocol
    /// - pool : pool object
    /// - seconds_to_add: seconds to increase for reward emission.
    /// - clock : sui clock object
    /// 
    #[allow(lint(public_entry))]
    public fun add_seconds_to_reward_emission<CoinTypeA, CoinTypeB, RewardCoinType>(
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>, 
        seconds_to_add: u64, 
        clock: &Clock, 
        ctx: &TxContext) {

        config::verify_version(protocol_config);

        let is_whitelisted_manager = config::verify_reward_manager(protocol_config, tx_context::sender(ctx));
        
        assert!(is_whitelisted_manager || pool::verify_pool_manager(pool, tx_context::sender(ctx)), errors::not_authorized());
        
        let reward_type = utils::get_type_string<RewardCoinType>();

        // if reward type is blue coin, then only whitelisted reward managers are allowed
        assert!(reward_type != constants::blue_reward_type() || is_whitelisted_manager, errors::not_authorized());

        pool::update_reward_infos(pool,  utils::timestamp_seconds(clock));
        pool::update_pool_reward_emission(
            pool, 
            balance::zero<RewardCoinType>(),
            seconds_to_add,
        );
    }




    /// Allow admin of the protocol to increase the supported version of the protocol
    ///
    /// Parameters:
    /// - _: Reference to admin cap
    /// - protocol_config: The protocol config that needs to be updated
    #[allow(lint(public_entry))]
    public entry fun update_supported_version(_: &AdminCap, protocol_config: &mut GlobalConfig){

        // increase version
        let (old_version, new_version) = config::increase_version(protocol_config);

        // emit the new and old versions
        events::emit_supported_version_update_event(old_version, new_version);
        
    }


    /// Allows the admin of the protocol to change the protocol fee share of any given pool. 
    /// 
    /// Parameters:
    /// - _: Reference to admin cap to ensure the caller is protocol's admin
    /// - pool: The pool for which to update the protocol fee share
    /// - protocol_fee_share: The new protocol fee share (should be <= 50%)
    #[allow(lint(public_entry))]
    public entry fun update_protocol_fee_share<CoinTypeA, CoinTypeB>(_: &AdminCap, pool: &mut Pool<CoinTypeA, CoinTypeB>, protocol_fee_share: u64){


        assert!(protocol_fee_share <= constants::max_protocol_fee_share(), errors::invalid_protocol_fee_share());

        let previous_protocol_fee_share = pool::protocol_fee_share(pool);

        pool::set_protocol_fee_share(pool, protocol_fee_share);

        let sequence_number = pool::increase_sequence_number(pool);

        events::emit_protocol_fee_share_updated_event(
            object::id(pool),
            previous_protocol_fee_share,
            protocol_fee_share,
            sequence_number
        )
    }

    /// Allows admin to increase the cardinality of observation for given pool
    /// 
    /// Parameters: 
    /// - _: Reference to admin cap to ensure the caller is protocol's admin
    /// - pool: The pool for which to update the observation cardinality
    /// - value: The new cardinality
    #[allow(lint(public_entry))]
    public entry fun increase_observation_cardinality_next<CoinTypeA, CoinTypeB>(_: &AdminCap, pool: &mut Pool<CoinTypeA, CoinTypeB>, value: u64){
        
        assert!(value < constants::max_observation_cardinality(), errors::invalid_observation_cardinality());

        pool::increase_observation_cardinality_next(pool, value);
    }

    /// Allows current pool manager to set a new manager for the pool
    /// 
    /// Parameters: 
    /// - protocol_config: global config object for spot protocol
    /// - pool : pool object
    /// - pool_manger: address of new manager
    /// - ctx: transaction context
    #[allow(lint(public_entry))]
    public entry fun set_pool_manager<CoinTypeA, CoinTypeB>(
        protocol_config: &GlobalConfig, 
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        pool_manager: address,
        ctx: &mut TxContext)
    {
        pool::set_manager(protocol_config, pool, pool_manager, ctx);
    }


    /// Allows admin of the protocol to set pool creation fee
    /// 
    /// Parameters: 
    /// - _ : Reference to admin cap to ensure caller is admin of the protocol
    /// - protocol_config: global config object for spot protocol
    /// - new_fee_amount : the amount of fee to be paid for pool creation 
    /// - ctx: transaction context
     #[allow(lint(public_entry))]
    public entry fun set_pool_creation_fee<CoinTypeFee>(
        _: &AdminCap,
        protocol_config: &mut GlobalConfig, 
        new_fee_amount: u64,
        ctx: &mut TxContext)
    {

        config::verify_version(protocol_config);

        let uid = config::get_config_id(protocol_config);
        let key = constants::pool_creation_fee_dynamic_key();
        let fee_coin_type = utils::get_type_string<CoinTypeFee>();

        // create the dynamic field if it does not exist
        if(!dynamic_field::exists_(uid, key)){
                dynamic_field::add(
                    uid,
                    key,
                    table::new<String, u64>(ctx)
                );
        };

        // get the fee table
        let fee_table = dynamic_field::borrow_mut(uid, key);

        // add fee coin if not exists
        if(!table::contains(fee_table, fee_coin_type)){
            table::add(fee_table, fee_coin_type, 0);
        };

        // update coin fee
        let coin_fee = table::borrow_mut(fee_table, fee_coin_type);
        let previous_fee_amount = *coin_fee;
        *coin_fee = new_fee_amount;

        events::emit_pool_creation_fee_update_event(fee_coin_type, previous_fee_amount, new_fee_amount);

    }


    /// Allows the holder of the protocol fee cap to claim and transfer the pool creation fee to provided address
    /// 
    /// Parameters: 
    /// - _: Reference to Protocol Fee Cap to ensure the caller is the owner of protocol fee cap
    /// - protocol_config: global config object for spot protocol
    /// - amount : The amount of creation fee to be transferred
    /// - destination: The account to which fee is to be sent 
    /// - ctx: transaction context
     #[allow(lint(public_entry))]
    public entry fun claim_pool_creation_fee<CoinTypeFee>(
        _: &ProtocolFeeCap,
        protocol_config: &mut GlobalConfig, 
        amount: u64, 
        destination: address,
        ctx: &mut TxContext)
    {
        config::verify_version(protocol_config);

        let uid = config::get_config_id(protocol_config);
        let fee_coin_type = utils::get_type_string<CoinTypeFee>();

        assert!(amount > 0, errors::zero_amount());

        // revert if the provided fee coin does not exist
        assert!(dynamic_field::exists_(uid, fee_coin_type), errors::fee_coin_not_supported());

        // take the requested fee amount and transfer to destination
        let accrued_fee = dynamic_field::borrow_mut<String ,Balance<CoinTypeFee>>(uid, fee_coin_type);

        let accrued_fee_before = balance::value(accrued_fee);

        assert!(accrued_fee_before >= amount, errors::insufficient_amount());

        let fee_amount = balance::split(accrued_fee, amount);

        let accrued_fee_after = balance::value(accrued_fee);

        utils::transfer_balance(fee_amount, destination, ctx);

        events::emit_pool_creation_fee_claimed(fee_coin_type, amount, destination, accrued_fee_before, accrued_fee_after);

    }


    /// Allows the admin of the protocol to add reward coin tokens to a pool 
    /// without increasing its total reward amount emission
    #[allow(lint(public_entry))]
    entry fun add_reward_reserves_to_pool<CoinTypeA, CoinTypeB, RewardCoinType>(
        _: &AdminCap,
        protocol_config: &GlobalConfig,
        pool: &mut Pool<CoinTypeA, CoinTypeB>,
        reward_coin: Coin<RewardCoinType>) {

        config::verify_version(protocol_config);
        
        pool::increase_reward_coin_reserves(pool, coin::into_balance(reward_coin));
    }

    /// Allows the admin of the protocol to set the icon url of a pool
    /// 
    /// Parameters: 
    /// - _: Reference to admin cap to ensure the caller is the admin of the protocol
    /// - protocol_config: global config object for spot protocol
    /// - pool: The pool for which to update the icon url
    /// - icon_url: The new icon url
    #[allow(lint(public_entry))]
    entry fun set_pool_icon_url<CoinTypeA, CoinTypeB>(_: &AdminCap, protocol_config: &GlobalConfig, pool: &mut Pool<CoinTypeA, CoinTypeB>, icon_url: String){
        config::verify_version(protocol_config);
        pool::set_pool_icon_url(pool, icon_url);
    }


    #[test_only]
    public fun get_admin_cap(ctx: &mut TxContext): AdminCap {
        AdminCap { id: object::new(ctx) }
    }

    #[test_only]
    public fun get_fee_cap(ctx: &mut TxContext): ProtocolFeeCap {
        ProtocolFeeCap { id: object::new(ctx) }
    }

     #[test_only]
    public fun test_init(ctx: &mut TxContext){
        init(ctx);
    }
}
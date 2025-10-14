// Copyright (c) Cetus Technology Limited

/// `Rewarder` is the liquidity incentive module of `clmmpool`, which is commonly known as `farming`. In `clmmpool`,
/// liquidity is stored in a price range, so `clmmpool` uses a reward allocation method based on effective liquidity.
/// The allocation rules are roughly as follows:
///
/// 1. Each pool can configure multiple `Rewarders`, and each `Rewarder` releases rewards at a uniform speed according
/// to its configured release rate.
/// 2. During the time period when the liquidity price range contains the current price of the pool, the liquidity
/// position can participate in the reward distribution for this time period (if the pool itself is configured with
/// rewards), and the proportion of the distribution depends on the size of the liquidity value of the position.
/// Conversely, if the price range of a position does not include the current price of the pool during a certain period
/// of time, then this position will not receive any rewards during this period of time. This is similar to the
/// calculation of transaction fees.
module cetus_clmm::rewarder;

use cetus_clmm::config::{GlobalConfig, checked_package_version, AdminCap};
use integer_mate::full_math_u128;
use integer_mate::math_u128;
use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};
use sui::balance::{Self, Balance};
use sui::event::emit;

/// Maximum number of rewarders that can be configured per pool
const REWARDER_NUM: u64 = 5;
/// Number of seconds in a day (24 hours * 60 minutes * 60 seconds)
const DAYS_IN_SECONDS: u128 = 24 * 60 * 60;
/// Points emitted per second in Q64.64 fixed point format (1M points per second)
const POINTS_EMISSIONS_PER_SECOND: u128 = 1000000 << 64;

const ERewardSoltIsFull: u64 = 1;
const ERewardAlreadyExist: u64 = 2;
const EInvalidTime: u64 = 3;
const ERewardAmountInsufficient: u64 = 4;
const ERewardNotExist: u64 = 5;
const ERewardCoinNotEnough: u64 = 6;

/// Manager the Rewards and Points.
/// * `rewarders` - The rewarders
/// * `points_released` - The points released
/// * `points_growth_global` - The points growth global
/// * `last_updated_time` - The last updated time
public struct RewarderManager has store {
    rewarders: vector<Rewarder>,
    points_released: u128,
    points_growth_global: u128,
    last_updated_time: u64,
}

/// Rewarder store the information of a rewarder.
/// * `reward_coin` - The type of reward coin
/// * `emissions_per_second` - The amount of reward coin emit per second
/// * `growth_global` - Q64.X64, is reward emited per liquidity
public struct Rewarder has copy, drop, store {
    reward_coin: TypeName,
    emissions_per_second: u128,
    growth_global: u128,
}

/// RewarderGlobalVault store the rewarder `Balance` in Bag globally.
/// * `id` - The unique identifier for this RewarderGlobalVault object
/// * `balances` - A bag storing the balances of the rewarders
public struct RewarderGlobalVault has key, store {
    id: UID,
    balances: Bag,
}

/// Emit when `RewarderManager` is initialized.
/// * `global_vault_id` - The unique identifier for this RewarderGlobalVault object
public struct RewarderInitEvent has copy, drop {
    global_vault_id: ID,
}

/// Emit when deposit reward.
/// * `reward_type` - The type of reward coin
/// * `deposit_amount` - The amount of reward coin deposited
/// * `after_amount` - The amount of reward coin after deposit
public struct DepositEvent has copy, drop, store {
    reward_type: TypeName,
    deposit_amount: u64,
    after_amount: u64,
}

/// Emit when withdraw reward.
/// * `reward_type` - The type of reward coin
/// * `withdraw_amount` - The amount of reward coin withdrawn
/// * `after_amount` - The amount of reward coin after withdrawal
public struct EmergentWithdrawEvent has copy, drop, store {
    reward_type: TypeName,
    withdraw_amount: u64,
    after_amount: u64,
}

/// init the `RewarderGlobalVault
/// * `ctx` - The transaction context
fun init(ctx: &mut TxContext) {
    let vault = RewarderGlobalVault {
        id: object::new(ctx),
        balances: bag::new(ctx),
    };
    let vault_id = object::id(&vault);
    transfer::share_object(vault);
    emit(RewarderInitEvent {
        global_vault_id: vault_id,
    })
}

/// initialize the `RewarderManager`.
/// * Returns the new `RewarderManager`
public(package) fun new(): RewarderManager {
    RewarderManager {
        rewarders: vector::empty(),
        points_released: 0,
        points_growth_global: 0,
        last_updated_time: 0,
    }
}

/// get the rewarders
/// * `manager` - The `RewarderManager`
/// * Returns the rewarders
public fun rewarders(manager: &RewarderManager): vector<Rewarder> {
    manager.rewarders
}

/// get the reward_growth_globals
/// * `manager` - The `RewarderManager`
/// * Returns the reward growth globals
public fun rewards_growth_global(manager: &RewarderManager): vector<u128> {
    let mut idx = 0;
    let mut res = vector::empty<u128>();
    while (idx < vector::length(&manager.rewarders)) {
        vector::push_back(&mut res, vector::borrow(&manager.rewarders, idx).growth_global);
        idx = idx + 1;
    };
    res
}

/// get the points_released
/// * `manager` - The `RewarderManager`
/// * Returns the points released
public fun points_released(manager: &RewarderManager): u128 {
    manager.points_released
}

/// get the points_growth_global
/// * `manager` - The `RewarderManager`
/// * Returns the points growth global
public fun points_growth_global(manager: &RewarderManager): u128 {
    manager.points_growth_global
}

/// get the last_updated_time
/// * `manager` - The `RewarderManager`
/// * Returns the last updated time
public fun last_update_time(manager: &RewarderManager): u64 {
    manager.last_updated_time
}

/// get the rewarder coin Type.
/// * `rewarder` - The `Rewarder`
/// * Returns the rewarder coin type
public fun reward_coin(rewarder: &Rewarder): TypeName {
    rewarder.reward_coin
}

/// get the rewarder emissions_per_second.
/// * `rewarder` - The `Rewarder`
/// * Returns the rewarder emissions per second
public fun emissions_per_second(rewarder: &Rewarder): u128 {
    rewarder.emissions_per_second
}

/// get the rewarder growth_global.
/// * `rewarder` - The `Rewarder`
/// * Returns the rewarder growth global
public fun growth_global(rewarder: &Rewarder): u128 {
    rewarder.growth_global
}

/// Get index of CoinType in `RewarderManager`, if not exists, return `None`
/// * `manager` - The `RewarderManager`
/// * Returns the index of the rewarder
public fun rewarder_index<CoinType>(manager: &RewarderManager): Option<u64> {
    let mut idx = 0;
    while (idx < vector::length(&manager.rewarders)) {
        if (vector::borrow(&manager.rewarders, idx).reward_coin == type_name::get<CoinType>()) {
            return option::some(idx)
        };
        idx = idx + 1;
    };
    option::none<u64>()
}

/// Borrow `Rewarder` from `RewarderManager`
/// * `manager` - The `RewarderManager`
/// * Returns the rewarder
public fun borrow_rewarder<CoinType>(manager: &RewarderManager): &Rewarder {
    let mut idx = 0;
    while (idx < vector::length(&manager.rewarders)) {
        if (vector::borrow(&manager.rewarders, idx).reward_coin == type_name::get<CoinType>()) {
            return vector::borrow(&manager.rewarders, idx)
        };
        idx = idx + 1;
    };
    abort ERewardNotExist
}

/// Borrow mutable `Rewarder` from `RewarderManager
/// * `manager` - The `RewarderManager`
/// * Returns the mutable rewarder
public(package) fun borrow_mut_rewarder<CoinType>(manager: &mut RewarderManager): &mut Rewarder {
    let mut idx = 0;
    while (idx < vector::length(&manager.rewarders)) {
        if (vector::borrow(&manager.rewarders, idx).reward_coin == type_name::get<CoinType>()) {
            return vector::borrow_mut(&mut manager.rewarders, idx)
        };
        idx = idx + 1;
    };
    abort ERewardNotExist
}

/// Add rewarder into `RewarderManager`
/// Only support at most REWARDER_NUM rewarders.
/// * `manager` - The `RewarderManager`
public(package) fun add_rewarder<CoinType>(manager: &mut RewarderManager) {
    assert!(option::is_none(&rewarder_index<CoinType>(manager)), ERewardAlreadyExist);
    let rewarder_infos = &mut manager.rewarders;
    assert!(vector::length(rewarder_infos) <= REWARDER_NUM - 1, ERewardSoltIsFull);
    let rewarder_type = type_name::get<CoinType>();
    let rewarder = Rewarder {
        reward_coin: rewarder_type,
        emissions_per_second: 0,
        growth_global: 0,
    };
    vector::push_back(rewarder_infos, rewarder);
}

/// Settle the reward.
/// Update the last_updated_time, the growth_global of each rewarder and points_growth_global.
/// Settlement is needed when swap, modify position liquidity, update emission speed.
/// * `manager` - The `RewarderManager`
/// * `liquidity` - The liquidity of the pool
/// * `timestamp` - The timestamp
public(package) fun settle(manager: &mut RewarderManager, liquidity: u128, timestamp: u64) {
    let last_time = manager.last_updated_time;
    manager.last_updated_time = timestamp;
    assert!(last_time <= timestamp, EInvalidTime);
    if (liquidity == 0 || timestamp == last_time) {
        return
    };
    let time_delta = (timestamp - last_time);
    let mut idx = 0;
    while (idx < vector::length(&manager.rewarders)) {
        let emission = vector::borrow(&manager.rewarders, idx).emissions_per_second;
        if (emission == 0) {
            idx = idx + 1;
            continue
        };
        let rewarder_growth_delta = full_math_u128::mul_div_floor(
            (time_delta as u128),
            emission,
            liquidity,
        );
        let last_growth_global = vector::borrow(&manager.rewarders, idx).growth_global;
        let rewarder = vector::borrow_mut(&mut manager.rewarders, idx);
        rewarder.growth_global = math_u128::wrapping_add(last_growth_global, rewarder_growth_delta);
        idx = idx + 1;
    };

    // update points
    let points_growth_delta = full_math_u128::mul_div_floor(
        (time_delta as u128),
        POINTS_EMISSIONS_PER_SECOND,
        liquidity,
    );
    let points_released_delta = (time_delta as u128) * POINTS_EMISSIONS_PER_SECOND;
    manager.points_released = manager.points_released + points_released_delta;
    manager.points_growth_global = math_u128::wrapping_add(manager.points_growth_global, points_growth_delta);
}

/// Update the reward emission speed.
/// The reward balance at least enough for one day should in `RewarderGlobalVault` when the emission speed is not zero.
/// The reward settlement is needed when update the emission speed.
/// emissions_per_second is Q64.X64
/// Params
///     - `vault`: `RewarderGlobalVault`
///     - `manager`: `RewarderManager`
///     - `liquidity`: The current pool liquidity.
///     - `emissions_per_second`: The emission speed
///     - `timestamp`: The timestamp
public(package) fun update_emission<CoinType>(
    vault: &RewarderGlobalVault,
    manager: &mut RewarderManager,
    liquidity: u128,
    emissions_per_second: u128,
    timestamp: u64,
) {
    settle(manager, liquidity, timestamp);

    let rewarder = borrow_mut_rewarder<CoinType>(manager);
    let old_emission = rewarder.emissions_per_second;
    if (emissions_per_second > 0 && emissions_per_second > old_emission) {
        let emission_per_day = DAYS_IN_SECONDS * emissions_per_second;
        let reward_type = type_name::get<CoinType>();
        assert!(bag::contains(&vault.balances, reward_type), ERewardAmountInsufficient);
        let rewarder_balance = bag::borrow<TypeName, Balance<CoinType>>(
            &vault.balances,
            reward_type,
        );
        // emissions_per_second is Q64.X64, so we need shift left 64 for rewarder_balance.
        assert!(
            ((balance::value<CoinType>(rewarder_balance) as u128) << 64) >= emission_per_day,
            ERewardAmountInsufficient,
        );
    };
    rewarder.emissions_per_second = emissions_per_second;
}

/// Withdraw Reward from `RewarderGlobalVault`
/// This method is used for claim reward in pool and emergent_withdraw.
/// * `vault` - The `RewarderGlobalVault`
/// * `amount` - The amount of reward coin to withdraw
/// * Returns the balance of the reward coin
public(package) fun withdraw_reward<CoinType>(
    vault: &mut RewarderGlobalVault,
    amount: u64,
): Balance<CoinType> {
    assert!(bag::contains(&vault.balances, type_name::get<CoinType>()), ERewardCoinNotEnough);
    let reward_balance = bag::borrow_mut<TypeName, Balance<CoinType>>(
        &mut vault.balances,
        type_name::get<CoinType>(),
    );
    assert!(balance::value(reward_balance) >= amount, ERewardCoinNotEnough);
    balance::split(reward_balance, amount)
}

/// Deposit Reward into `RewarderGlobalVault`
/// * `config` - The global config
/// * `vault` - The `RewarderGlobalVault`
/// * `balance` - The balance of the reward coin
/// * Returns the amount of reward coin deposited
public fun deposit_reward<CoinType>(
    config: &GlobalConfig,
    vault: &mut RewarderGlobalVault,
    balance: Balance<CoinType>,
): u64 {
    checked_package_version(config);
    let reward_type = type_name::get<CoinType>();
    if (!bag::contains(&vault.balances, reward_type)) {
        bag::add(&mut vault.balances, reward_type, balance::zero<CoinType>());
    };
    let deposit_amount = balance::value(&balance);
    let reward_balance = bag::borrow_mut<TypeName, Balance<CoinType>>(
        &mut vault.balances,
        type_name::get<CoinType>(),
    );
    let after_amount = balance::join(reward_balance, balance);
    emit(DepositEvent {
        reward_type: type_name::get<CoinType>(),
        deposit_amount,
        after_amount,
    });
    after_amount
}

/// Withdraw reward Balance of CoinType from vault by the protocol `AdminCap`.
/// This function is only used for emergency.
/// * `config` - The global config
/// * `vault` - The `RewarderGlobalVault`
/// * `amount` - The amount of reward coin to withdraw
/// * Returns the balance of the reward coin
public fun emergent_withdraw<CoinType>(
    _: &AdminCap,
    config: &GlobalConfig,
    vault: &mut RewarderGlobalVault,
    amount: u64,
): Balance<CoinType> {
    checked_package_version(config);
    let withdraw_balance = withdraw_reward<CoinType>(vault, amount);
    let after_amount = balance_of<CoinType>(vault);
    emit(EmergentWithdrawEvent {
        reward_type: type_name::get<CoinType>(),
        withdraw_amount: amount,
        after_amount,
    });
    withdraw_balance
}

/// Get the balances in vault.
/// * `vault` - The `RewarderGlobalVault`
/// * Returns the balances
public fun balances(vault: &RewarderGlobalVault): &Bag {
    &vault.balances
}

/// Get the balance value of CoinType in vault.
/// * `vault` - The `RewarderGlobalVault`
/// * Returns the balance value of the reward coin
public fun balance_of<CoinType>(vault: &RewarderGlobalVault): u64 {
    let reward_type = type_name::get<CoinType>();
    if (!bag::contains(&vault.balances, reward_type)) {
        return 0
    };
    let balance = bag::borrow<TypeName, Balance<CoinType>>(&vault.balances, reward_type);
    balance::value(balance)
}

#[test_only]
public fun new_vault_for_test(ctx: &mut TxContext): RewarderGlobalVault {
    RewarderGlobalVault {
        id: object::new(ctx),
        balances: bag::new(ctx),
    }
}

#[test_only]
public fun new_rewarder_for_test<CoinType>(
    emissions_per_second: u128,
    growth_global: u128,
): Rewarder {
    Rewarder {
        reward_coin: type_name::get<CoinType>(),
        emissions_per_second,
        growth_global,
    }
}

#[test_only]
public fun update_for_swap_test(
    manager: &mut RewarderManager,
    rewarders: vector<Rewarder>,
    points_released: u128,
    points_growth_global: u128,
    last_updated_time: u64,
) {
    manager.rewarders = rewarders;
    manager.points_released = points_released;
    manager.points_growth_global = points_growth_global;
    manager.last_updated_time = last_updated_time;
}

#[test]
fun test_init() {
    let mut sc = sui::test_scenario::begin(@0x23);
    init(sc.ctx());
    sc.next_tx(@0x23);
    let vault = sui::test_scenario::take_shared<RewarderGlobalVault>(&sc);
    sui::test_scenario::return_shared(vault);
    sc.end();
}
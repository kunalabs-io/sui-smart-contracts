#[test_only]
module cetus_clmm::rewarder_unittests;

use sui::coin;
use sui::balance;
use sui::transfer::{public_transfer};
use cetus_clmm::rewarder::{Self, RewarderManager, add_rewarder, borrow_rewarder, borrow_mut_rewarder, settle, update_emission, deposit_reward, emergent_withdraw, balance_of};
use std::type_name;
use cetus_clmm::config::new_global_config_for_test;
use integer_mate::full_math_u128;
use sui::transfer::public_share_object;

const POINTS_EMISSIONS_PER_SECOND: u128 = 1000000 << 64;

public struct RewarderCoin {}

public struct RewarderCoin2 {}

public struct RewarderCoin3 {}

public struct RewarderCoin4 {}

public struct RewarderCoin5 {}

public struct RewarderCoin6 {}

#[test_only]
public struct TestPool has key {
    id: UID,
    position: RewarderManager,
}

#[test_only]
public fun return_manager(m: RewarderManager, ctx: &mut TxContext) {
    let p = TestPool {
        id: object::new(ctx),
        position: m,
    };
    transfer::share_object(p);
}

#[test]
fun test_add_rewarder() {
    let mut ctx = tx_context::dummy();
    let mut manager = rewarder::new();
    add_rewarder<RewarderCoin>(&mut manager);
    assert!(vector::length(&rewarder::rewarders(&manager)) == 1, 0);
    assert!(option::extract(&mut rewarder::rewarder_index<RewarderCoin>(&manager)) == 0, 0);
    let rewarder = borrow_rewarder<RewarderCoin>(&manager);
    assert!(rewarder.emissions_per_second() == 0, 1);
    assert!(rewarder.growth_global() == 0, 2);
    assert!(rewarder.reward_coin() == type_name::get<RewarderCoin>(), 3);

    add_rewarder<RewarderCoin2>(&mut manager);
    assert!(vector::length(&rewarder::rewarders(&manager)) == 2, 4);
    assert!(option::extract(&mut rewarder::rewarder_index<RewarderCoin2>(&manager)) == 1, 5);
    let rewarder = borrow_rewarder<RewarderCoin2>(&manager);
    assert!(rewarder.emissions_per_second() == 0, 6);
    assert!(rewarder.growth_global() == 0, 7);
    assert!(rewarder.reward_coin() == type_name::get<RewarderCoin2>(), 8);
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::rewarder::ERewardAlreadyExist)]
fun test_add_rewarder_failure_with_rewarder_exist() {
    let mut ctx = tx_context::dummy();
    let mut manager = rewarder::new();
    add_rewarder<RewarderCoin>(&mut manager);
    add_rewarder<RewarderCoin>(&mut manager);
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::rewarder::ERewardSoltIsFull)]
fun test_add_rewarder_failure_with_rewarder_slod_is_full() {
    let mut ctx = tx_context::dummy();
    let mut manager = rewarder::new();
    add_rewarder<RewarderCoin>(&mut manager);
    add_rewarder<RewarderCoin2>(&mut manager);
    add_rewarder<RewarderCoin3>(&mut manager);
    add_rewarder<RewarderCoin4>(&mut manager);
    add_rewarder<RewarderCoin5>(&mut manager);
    add_rewarder<RewarderCoin6>(&mut manager);
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::rewarder::EInvalidTime)]
fun test_settle_failure_with_invalid_time() {
    let mut ctx = tx_context::dummy();
    let mut manager = rewarder::new();
    settle(&mut manager, 1000000000, 1000000);
    settle(&mut manager, 1000000000, 10000);
    return_manager(manager, &mut ctx);
}

#[test]
fun test_settle() {
    let mut ctx = tx_context::dummy();
    let mut manager = rewarder::new();
    let (cap, config) = new_global_config_for_test(&mut ctx, 20000);
    let mut vault = rewarder::new_vault_for_test(&mut ctx);
    let liquidity = 1000000000;
    settle(&mut manager, liquidity, 1000000);
    assert!(manager.points_released() == 1000000 * POINTS_EMISSIONS_PER_SECOND, 0);
    assert!(
        manager.points_growth_global() == full_math_u128::mul_div_floor(
            (1000000 as u128),
            POINTS_EMISSIONS_PER_SECOND,
            liquidity
        ),
        1,
    );
    assert!(manager.last_update_time() == 1000000, 2);
    let last_points_released = manager.points_released();
    let last_points_growth_global = manager.points_growth_global();
    add_rewarder<RewarderCoin>(&mut manager);
    let balances = coin::into_balance(
        coin::mint_for_testing<RewarderCoin>(1000000 * 24 * 3600, &mut ctx),
    );
    deposit_reward(&config, &mut vault, balances);
    update_emission<RewarderCoin>(&vault, &mut manager, liquidity, 1000000 << 64, 2000000);
    assert!(
        manager.points_released() == last_points_released + (2000000 - 1000000) * POINTS_EMISSIONS_PER_SECOND,
        3,
    );
    assert!(
        manager.points_growth_global() == last_points_growth_global + full_math_u128::mul_div_floor(
            (1000000 as u128),
            POINTS_EMISSIONS_PER_SECOND,
            liquidity
        ),
        4,
    );
    assert!(manager.last_update_time() == 2000000, 5);
    let last_points_released = manager.points_released();
    let last_points_growth_global = manager.points_growth_global();
    settle(&mut manager, 2 * liquidity, 3000000);
    assert!(
        manager.points_released() == last_points_released + (3000000 - 2000000) * POINTS_EMISSIONS_PER_SECOND,
        3,
    );
    assert!(
        manager.points_growth_global() == last_points_growth_global + full_math_u128::mul_div_floor(
            (1000000 as u128),
            POINTS_EMISSIONS_PER_SECOND,
            2 * liquidity
        ),
        4,
    );
    assert!(manager.last_update_time() == 3000000, 5);
    let rewarder = borrow_rewarder<RewarderCoin>(&manager);
    assert!(rewarder.emissions_per_second() == 1000000 << 64, 6);
    assert!(
        rewarder.growth_global() == full_math_u128::mul_div_floor(
            (1000000 as u128),
            1000000 << 64,
            2 * liquidity
        ),
        7,
    );

    return_manager(manager, &mut ctx);
    public_transfer(cap, tx_context::sender(&ctx));
    transfer::public_share_object(config);
    transfer::public_share_object(vault);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::rewarder::ERewardAmountInsufficient)]
fun test_update_emission_failure_with_reward_amount_insufficient() {
    let mut ctx = tx_context::dummy();
    let (cap, config) = new_global_config_for_test(&mut ctx, 20000);
    let mut manager = rewarder::new();
    let mut vault = rewarder::new_vault_for_test(&mut ctx);
    add_rewarder<RewarderCoin>(&mut manager);
    let balances = coin::into_balance(
        coin::mint_for_testing<RewarderCoin>(1000000 * 3600, &mut ctx),
    );
    deposit_reward(&config, &mut vault, balances);
    update_emission<RewarderCoin>(&vault, &mut manager, 100, 1000000 << 64, 10);
    return_manager(manager, &mut ctx);
    public_transfer(cap, tx_context::sender(&ctx));
    transfer::public_share_object(config);
    transfer::public_share_object(vault);
}

#[test]
fun test_update_emission() {
    let mut ctx = tx_context::dummy();
    let (cap, config) = new_global_config_for_test(&mut ctx, 20000);
    let mut manager = rewarder::new();
    let mut vault = rewarder::new_vault_for_test(&mut ctx);
    add_rewarder<RewarderCoin>(&mut manager);
    let balances = coin::into_balance(
        coin::mint_for_testing<RewarderCoin>(1000000 * 48 * 3600, &mut ctx),
    );
    deposit_reward(&config, &mut vault, balances);
    update_emission<RewarderCoin>(&vault, &mut manager, 2 << 50, 1000000 << 64, 1000000000);
    assert!(
        manager.points_growth_global() == full_math_u128::mul_div_floor(
                (1000000000 as u128),
                POINTS_EMISSIONS_PER_SECOND,
                2 << 50
            ),
        1,
    );
    assert!(manager.last_update_time() == 1000000000, 2);
    assert!(manager.points_released() == (1000000000 as u128) * POINTS_EMISSIONS_PER_SECOND, 3);
    let rewarder = *borrow_rewarder<RewarderCoin>(&manager);
    assert!(rewarder.emissions_per_second() == 1000000 << 64, 4);
    assert!(rewarder.growth_global() == 0, 5);
    let last_points_released = manager.points_released();
    let last_points_growth_global = manager.points_growth_global();
    update_emission<RewarderCoin>(&vault, &mut manager, 2 << 50, 2000000 << 64, 2000000000);
    assert!(
        manager.points_released() == last_points_released + (2000000000 - 1000000000) * POINTS_EMISSIONS_PER_SECOND,
        6,
    );
    assert!(
        manager.points_growth_global() == last_points_growth_global + full_math_u128::mul_div_floor(
            (1000000000 as u128),
            POINTS_EMISSIONS_PER_SECOND,
            2 << 50
        ),
        7,
    );
    assert!(manager.last_update_time() == 2000000000, 8);
    let last_rewarder = *borrow_rewarder<RewarderCoin>(&manager);
    assert!(last_rewarder.emissions_per_second() == 2000000 << 64, 9);
    assert!(
        last_rewarder.growth_global() == full_math_u128::mul_div_floor(
            (1000000000 as u128),
            1000000 << 64,
            2 << 50
        ),
        10,
    );
    update_emission<RewarderCoin>(&vault, &mut manager, 2 << 50, 0, 3000000000);
    let rewarder = borrow_rewarder<RewarderCoin>(&manager);
    assert!(rewarder.emissions_per_second() == 0, 11);
    assert!(
        rewarder.growth_global() == last_rewarder.growth_global() + full_math_u128::mul_div_floor(
            (1000000000 as u128),
            2000000 << 64,
            2 << 50
        ),
        12,
    );
    update_emission<RewarderCoin>(&vault, &mut manager, 2 << 50, 1000000 << 64, 4000000000);

    return_manager(manager, &mut ctx);
    public_transfer(cap, tx_context::sender(&ctx));
    transfer::public_share_object(config);
    transfer::public_share_object(vault);
}

#[test]
fun test_deposit_reward() {
    let mut ctx = tx_context::dummy();
    let (cap, config) = new_global_config_for_test(&mut ctx, 20000);
    let mut vault = rewarder::new_vault_for_test(&mut ctx);
    let amount = 1000000 * 48 * 3600;
    let balances = coin::into_balance(coin::mint_for_testing<RewarderCoin>(amount, &mut ctx));
    assert!(deposit_reward(&config, &mut vault, balances) == amount, 1);
    assert!(balance_of<RewarderCoin>(&vault) == amount, 2);
    let balances = coin::into_balance(coin::mint_for_testing<RewarderCoin>(amount * 3, &mut ctx));
    assert!(deposit_reward(&config, &mut vault, balances) == amount * 4, 2);
    assert!(balance_of<RewarderCoin>(&vault) == 4 * amount, 2);
    let balances = coin::into_balance(coin::mint_for_testing<RewarderCoin2>(amount * 2, &mut ctx));
    assert!(deposit_reward(&config, &mut vault, balances) == amount * 2, 3);
    assert!(balance_of<RewarderCoin2>(&vault) == 2 * amount, 2);
    transfer::public_share_object(vault);
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
}

#[test]
fun test_withdraw_reward() {
    let mut ctx = tx_context::dummy();
    let amount = 1000000 * 48 * 3600;
    let (cap, config) = new_global_config_for_test(&mut ctx, 20000);
    let mut vault = rewarder::new_vault_for_test(&mut ctx);
    let balances = coin::into_balance(coin::mint_for_testing<RewarderCoin>(amount, &mut ctx));
    assert!(deposit_reward(&config, &mut vault, balances) == amount, 1);
    let return_balance = rewarder::withdraw_reward<RewarderCoin>(&mut vault, amount);
    assert!(balance::value(&return_balance) == amount, 1);
    transfer::public_share_object(vault);
    public_transfer(coin::from_balance(return_balance, &mut ctx), tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    transfer::public_share_object(config);
}

#[test]
fun test_emergent_withdraw() {
    let mut ctx = tx_context::dummy();
    let amount = 1000000 * 48 * 3600;
    let (cap, config) = new_global_config_for_test(&mut ctx, 20000);
    let mut vault = rewarder::new_vault_for_test(&mut ctx);
    let balances = coin::into_balance(coin::mint_for_testing<RewarderCoin>(amount, &mut ctx));
    assert!(deposit_reward(&config, &mut vault, balances) == amount, 1);
    let return_balance = emergent_withdraw<RewarderCoin>(&cap, &config, &mut vault, amount);
    assert!(balance::value(&return_balance) == amount, 1);
    transfer::public_share_object(vault);
    public_transfer(coin::from_balance(return_balance, &mut ctx), tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    transfer::public_share_object(config);
}

#[test]
fun test_borrow() {
    let mut ctx = tx_context::dummy();
    let mut manager = rewarder::new();
    add_rewarder<RewarderCoin>(&mut manager);
    borrow_rewarder<RewarderCoin>(&manager);
    borrow_mut_rewarder<RewarderCoin>(&mut manager);
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::rewarder::ERewardNotExist)]
fun test_borrow_failure_with_reward_not_exist() {
    let mut ctx = tx_context::dummy();
    let mut manager = rewarder::new();
    add_rewarder<RewarderCoin>(&mut manager);
    borrow_rewarder<RewarderCoin2>(&manager);
    return_manager(manager, &mut ctx);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::rewarder::ERewardNotExist)]
fun test_borrow_mut_failure_with_reward_not_exist() {
    let mut ctx = tx_context::dummy();
    let mut manager = rewarder::new();
    add_rewarder<RewarderCoin>(&mut manager);
    borrow_mut_rewarder<RewarderCoin2>(&mut manager);
    return_manager(manager, &mut ctx);
}

// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// SAV strategy integrating Scallop whUSDC.e with Kai vaults.
module kai_sav::scallop_whusdce;

use kai_sav::util::muldiv;
use kai_sav::vault::{
    Self,
    Vault,
    VaultAccess,
    AdminCap as VaultAdminCap,
    RebalanceAmounts,
    WithdrawTicket,
    StrategyRemovalTicket
};
use kai_sav::ywhusdce::YWHUSDCE;
use scallop_pool::rewards_pool::RewardsPool as ScallopRewardsPool;
use scallop_pool::spool::Spool as ScallopPool;
use scallop_pool::spool_account::SpoolAccount as ScallopPoolAccount;
use scallop_protocol::market::Market as ScallopMarket;
use scallop_protocol::reserve::MarketCoin;
use scallop_protocol::version::Version as ScallopVersion;
use std::u64;
use sui::balance::{Self, Balance};
use sui::clock::Clock;
use sui::coin;
use sui::sui::SUI;
use whusdce::coin::COIN as WHUSDCE;

/* ================= constants ================= */

const MODULE_VERSION: u64 = 1;

const SCALLOP_POOL_ID: address =
    @0x4ace6648ddc64e646ba47a957c562c32c9599b3bba8f5ac1aadb2ae23a2f8ca0;
const SCALLOP_MARKET_ID: address =
    @0xa757975255146dc9686aa823b7838b507f315d704f428cbadad2f4ea061939d9;
const SCALLOP_REWARDS_POOL_ID: address =
    @0xf4268cc9b9413b9bfe09e8966b8de650494c9e5784bf0930759cfef4904daff8;

/* ================= errors ================= */

/// Invalid `AdminCap` has been provided for the strategy
const EInvalidAdmin: u64 = 0;

/// Invalid Scallop pool ID provided
const EInvalidScallopPool: u64 = 1;

/// Invalid Scallop market ID provided
const EInvalidScallopMarket: u64 = 2;

/// The strategy cannot be removed from vault if it has pending rewards
const EHasPendingRewards: u64 = 3;

/// Calling functions from the wrong package version
const EWrongVersion: u64 = 4;

/// Migration is not an upgrade
const ENotUpgrade: u64 = 5;

/* ================= AdminCap ================= */

public struct AdminCap has key, store {
    id: UID,
}

/* ================= Strategy ================= */

public struct Strategy has key {
    id: UID,
    admin_cap_id: ID,
    vault_access: Option<VaultAccess>,
    scallop_pool_acc: ScallopPoolAccount<MarketCoin<WHUSDCE>>,
    underlying_nominal_value_usdc: u64,
    collected_profit_usdc: Balance<WHUSDCE>,
    collected_profit_sui: Balance<SUI>,
    version: u64,
}

fun assert_scallop_pool(pool: &ScallopPool) {
    assert!(object::id_address(pool) == SCALLOP_POOL_ID, EInvalidScallopPool);
}

#[lint_allow(self_transfer)]
public(package) entry fun new(scallop_pool: &mut ScallopPool, clock: &Clock, ctx: &mut TxContext) {
    assert_scallop_pool(scallop_pool);

    let admin_cap = AdminCap { id: object::new(ctx) };
    let admin_cap_id = object::id(&admin_cap);

    let scallop_pool_acc = scallop_pool::user::new_spool_account(scallop_pool, clock, ctx);

    let strategy = Strategy {
        id: object::new(ctx),
        admin_cap_id,
        vault_access: option::none(),
        scallop_pool_acc,
        underlying_nominal_value_usdc: 0,
        collected_profit_usdc: balance::zero(),
        collected_profit_sui: balance::zero(),
        version: MODULE_VERSION,
    };
    transfer::share_object(strategy);

    transfer::transfer(
        admin_cap,
        tx_context::sender(ctx),
    );
}

fun assert_version(strategy: &Strategy) {
    assert!(strategy.version == MODULE_VERSION, EWrongVersion);
}

/* ================= admin ================= */

fun assert_admin(cap: &AdminCap, strategy: &Strategy) {
    let admin_cap_id = object::id(cap);
    assert!(admin_cap_id == strategy.admin_cap_id, EInvalidAdmin);
}

entry fun join_vault(
    vault_cap: &VaultAdminCap<YWHUSDCE>,
    vault: &mut Vault<WHUSDCE, YWHUSDCE>,
    strategy_cap: &AdminCap,
    strategy: &mut Strategy,
    ctx: &mut TxContext,
) {
    assert_version(strategy);
    assert_admin(strategy_cap, strategy);

    let access = vault::add_strategy(vault_cap, vault, ctx);
    option::fill(&mut strategy.vault_access, access); // aborts if `is_some`
}

fun assert_scallop_market(market: &ScallopMarket) {
    assert!(object::id_address(market) == SCALLOP_MARKET_ID, EInvalidScallopMarket);
}

fun assert_scallop_rewards_pool(pool: &ScallopRewardsPool<SUI>) {
    assert!(object::id_address(pool) == SCALLOP_REWARDS_POOL_ID, EInvalidScallopMarket);
}

public fun remove_from_vault(
    cap: &AdminCap,
    strategy: &mut Strategy,
    scallop_version: &ScallopVersion,
    scallop_market: &mut ScallopMarket,
    scallop_pool: &mut ScallopPool,
    scallop_rewards_pool: &mut ScallopRewardsPool<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
): StrategyRemovalTicket<WHUSDCE, YWHUSDCE> {
    assert_admin(cap, strategy);
    assert_version(strategy);
    assert_scallop_market(scallop_market);
    assert_scallop_pool(scallop_pool);
    assert_scallop_rewards_pool(scallop_rewards_pool);

    let rewards = scallop_pool::user::redeem_rewards(
        scallop_pool,
        scallop_rewards_pool,
        &mut strategy.scallop_pool_acc,
        clock,
        ctx,
    );
    assert!(coin::value(&rewards) == 0, EHasPendingRewards);
    assert!(balance::value(&strategy.collected_profit_sui) == 0, EHasPendingRewards);
    coin::destroy_zero(rewards);

    let amount_susdc = scallop_pool::spool_account::stake_amount(&strategy.scallop_pool_acc);
    let unstaked_susdc = scallop_pool::user::unstake(
        scallop_pool,
        &mut strategy.scallop_pool_acc,
        amount_susdc,
        clock,
        ctx,
    );
    let redeemed_coin = scallop_protocol::redeem::redeem(
        scallop_version,
        scallop_market,
        unstaked_susdc,
        clock,
        ctx,
    );
    let mut returned_balance = coin::into_balance(redeemed_coin);
    balance::join(
        &mut returned_balance,
        balance::withdraw_all(&mut strategy.collected_profit_usdc),
    );

    strategy.underlying_nominal_value_usdc = 0;

    vault::new_strategy_removal_ticket(
        option::extract(&mut strategy.vault_access),
        returned_balance,
    )
}

entry fun migrate(cap: &AdminCap, strategy: &mut Strategy) {
    assert_admin(cap, strategy);
    assert!(strategy.version < MODULE_VERSION, ENotUpgrade);
    strategy.version = MODULE_VERSION;
}

/* ================= strategy operations ================= */

public fun rebalance(
    cap: &AdminCap,
    strategy: &mut Strategy,
    vault: &mut Vault<WHUSDCE, YWHUSDCE>,
    amounts: &RebalanceAmounts,
    scallop_version: &ScallopVersion,
    scallop_market: &mut ScallopMarket,
    scallop_pool: &mut ScallopPool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert_admin(cap, strategy);
    assert_version(strategy);
    assert_scallop_market(scallop_market);
    assert_scallop_pool(scallop_pool);

    let vault_access = option::borrow(&strategy.vault_access);
    let (can_borrow, to_repay) = vault::rebalance_amounts_get(amounts, vault_access);
    if (to_repay > 0) {
        let staked_amount_susdc = scallop_pool::spool_account::stake_amount(
            &strategy.scallop_pool_acc,
        );
        let unstake_susdc_amt = muldiv(
            staked_amount_susdc,
            to_repay,
            strategy.underlying_nominal_value_usdc,
        );

        let unstaked_susdc = scallop_pool::user::unstake(
            scallop_pool,
            &mut strategy.scallop_pool_acc,
            unstake_susdc_amt,
            clock,
            ctx,
        );
        let redeemed_coin = scallop_protocol::redeem::redeem(
            scallop_version,
            scallop_market,
            unstaked_susdc,
            clock,
            ctx,
        );
        let mut redeemed_balance_usdc = coin::into_balance(redeemed_coin);

        if (balance::value(&redeemed_balance_usdc) > to_repay) {
            let extra_amt = balance::value(&redeemed_balance_usdc) - to_repay;
            balance::join(
                &mut strategy.collected_profit_usdc,
                balance::split(&mut redeemed_balance_usdc, extra_amt),
            );
        };

        let repaid = balance::value(&redeemed_balance_usdc);
        vault::strategy_repay(vault, vault_access, redeemed_balance_usdc);

        strategy.underlying_nominal_value_usdc = strategy.underlying_nominal_value_usdc - repaid;
    } else if (can_borrow > 0) {
        let borrow_amt = u64::min(can_borrow, vault::free_balance(vault));
        let borrowed = coin::from_balance(
            vault::strategy_borrow(vault, vault_access, borrow_amt),
            ctx,
        );

        let susdc = scallop_protocol::mint::mint(
            scallop_version,
            scallop_market,
            borrowed,
            clock,
            ctx,
        );
        scallop_pool::user::stake(
            scallop_pool,
            &mut strategy.scallop_pool_acc,
            susdc,
            clock,
            ctx,
        );

        strategy.underlying_nominal_value_usdc =
            strategy.underlying_nominal_value_usdc + borrow_amt;
    }
}

/// Since there are many avenues for selling the profits, the conversion from SUI to USDC
/// is done by the admin on the client side. The taken profits are to be sold and resulting
/// USDC deposited back with `deposit_sold_profits` function in the same transaction.
/// In the future iterations of the protocol, this may be implemented on the smart contract level.
public fun take_profits_for_selling(
    cap: &AdminCap,
    strategy: &mut Strategy,
    amount: Option<u64>,
    scallop_pool: &mut ScallopPool,
    scallop_rewards_pool: &mut ScallopRewardsPool<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
): Balance<SUI> {
    assert_admin(cap, strategy);
    assert_version(strategy);
    assert_scallop_pool(scallop_pool);
    assert_scallop_rewards_pool(scallop_rewards_pool);

    let coin = scallop_pool::user::redeem_rewards(
        scallop_pool,
        scallop_rewards_pool,
        &mut strategy.scallop_pool_acc,
        clock,
        ctx,
    );
    balance::join(&mut strategy.collected_profit_sui, coin::into_balance(coin));

    if (option::is_some(&amount)) {
        let amount = *option::borrow(&amount);
        balance::split(&mut strategy.collected_profit_sui, amount)
    } else {
        balance::withdraw_all(&mut strategy.collected_profit_sui)
    }
}

/// Skim the profits earned on base APY.
public fun skim_base_profits(
    cap: &AdminCap,
    strategy: &mut Strategy,
    scallop_version: &ScallopVersion,
    scallop_market: &mut ScallopMarket,
    scallop_pool: &mut ScallopPool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert_admin(cap, strategy);
    assert_version(strategy);
    assert_scallop_market(scallop_market);
    assert_scallop_pool(scallop_pool);

    let staked_amount_susdc = scallop_pool::spool_account::stake_amount(&strategy.scallop_pool_acc);
    let unstaked_susdc = scallop_pool::user::unstake(
        scallop_pool,
        &mut strategy.scallop_pool_acc,
        staked_amount_susdc,
        clock,
        ctx,
    );
    let redeemed_coin = scallop_protocol::redeem::redeem(
        scallop_version,
        scallop_market,
        unstaked_susdc,
        clock,
        ctx,
    );
    let mut redeemed_balance_usdc = coin::into_balance(redeemed_coin);

    if (balance::value(&redeemed_balance_usdc) > strategy.underlying_nominal_value_usdc) {
        let profit_amt =
            balance::value(&redeemed_balance_usdc) - strategy.underlying_nominal_value_usdc;
        balance::join(
            &mut strategy.collected_profit_usdc,
            balance::split(&mut redeemed_balance_usdc, profit_amt),
        );
    };

    let stake_coin = coin::from_balance(redeemed_balance_usdc, ctx);
    let susdc = scallop_protocol::mint::mint(
        scallop_version,
        scallop_market,
        stake_coin,
        clock,
        ctx,
    );
    scallop_pool::user::stake(
        scallop_pool,
        &mut strategy.scallop_pool_acc,
        susdc,
        clock,
        ctx,
    );
}

/// Return the converted profits. See `take_profits_for_selling`.
public fun deposit_sold_profits(
    cap: &AdminCap,
    strategy: &mut Strategy,
    vault: &mut Vault<WHUSDCE, YWHUSDCE>,
    mut profit: Balance<WHUSDCE>,
    clock: &Clock,
) {
    assert_admin(cap, strategy);
    assert_version(strategy);
    let vault_access = option::borrow(&strategy.vault_access);

    balance::join(
        &mut profit,
        balance::withdraw_all(&mut strategy.collected_profit_usdc),
    );
    vault::strategy_hand_over_profit(vault, vault_access, profit, clock);
}

/* ================= user operations ================= */

public fun withdraw(
    strategy: &mut Strategy,
    ticket: &mut WithdrawTicket<WHUSDCE, YWHUSDCE>,
    scallop_version: &ScallopVersion,
    scallop_market: &mut ScallopMarket,
    scallop_pool: &mut ScallopPool,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    assert_version(strategy);
    assert_scallop_market(scallop_market);
    assert_scallop_pool(scallop_pool);

    let vault_access = option::borrow(&strategy.vault_access);
    let to_withdraw = vault::withdraw_ticket_to_withdraw(ticket, vault_access);
    if (to_withdraw == 0) {
        return
    };

    let staked_amount_susdc = scallop_pool::spool_account::stake_amount(&strategy.scallop_pool_acc);
    let unstake_susdc_amt = muldiv(
        staked_amount_susdc,
        to_withdraw,
        strategy.underlying_nominal_value_usdc,
    );

    let unstaked_susdc = scallop_pool::user::unstake(
        scallop_pool,
        &mut strategy.scallop_pool_acc,
        unstake_susdc_amt,
        clock,
        ctx,
    );
    let redeemed_coin = scallop_protocol::redeem::redeem(
        scallop_version,
        scallop_market,
        unstaked_susdc,
        clock,
        ctx,
    );
    let mut redeemed_balance_usdc = coin::into_balance(redeemed_coin);

    if (balance::value(&redeemed_balance_usdc) > to_withdraw) {
        let profit_amt = balance::value(&redeemed_balance_usdc) - to_withdraw;
        balance::join(
            &mut strategy.collected_profit_usdc,
            balance::split(&mut redeemed_balance_usdc, profit_amt),
        );
    };

    vault::strategy_withdraw_to_ticket(ticket, vault_access, redeemed_balance_usdc);

    // `to_withdraw` amount is used intentionally here instead of the actual amount which
    // can be lower in some cases (see comments in `vault::redeem_withdraw_ticket`)
    strategy.underlying_nominal_value_usdc = strategy.underlying_nominal_value_usdc - to_withdraw;
}


<a name="kai_sav_vault"></a>

# Module `kai_sav::vault`

Single-Asset Vault (SAV) implementation with multi-strategy yield optimization.

This module implements a sophisticated vault system that accepts deposits of a single
asset type and distributes funds across multiple yield-generating strategies. It provides
automated rebalancing, fee management, time-locked profit distribution, and comprehensive
risk management features.


-  [Struct `DepositEvent`](#kai_sav_vault_DepositEvent)
-  [Struct `WithdrawEvent`](#kai_sav_vault_WithdrawEvent)
-  [Struct `StrategyProfitEvent`](#kai_sav_vault_StrategyProfitEvent)
-  [Struct `StrategyLossEvent`](#kai_sav_vault_StrategyLossEvent)
-  [Struct `AdminCap`](#kai_sav_vault_AdminCap)
-  [Struct `VaultAccess`](#kai_sav_vault_VaultAccess)
-  [Struct `StrategyRemovalTicket`](#kai_sav_vault_StrategyRemovalTicket)
-  [Struct `StrategyWithdrawInfo`](#kai_sav_vault_StrategyWithdrawInfo)
-  [Struct `WithdrawTicket`](#kai_sav_vault_WithdrawTicket)
-  [Struct `RebalanceInfo`](#kai_sav_vault_RebalanceInfo)
-  [Struct `RebalanceAmounts`](#kai_sav_vault_RebalanceAmounts)
-  [Struct `StrategyState`](#kai_sav_vault_StrategyState)
-  [Struct `Vault`](#kai_sav_vault_Vault)
-  [Constants](#@Constants_0)
-  [Function `vault_access_id`](#kai_sav_vault_vault_access_id)
-  [Function `new_strategy_removal_ticket`](#kai_sav_vault_new_strategy_removal_ticket)
-  [Function `withdraw_ticket_to_withdraw`](#kai_sav_vault_withdraw_ticket_to_withdraw)
-  [Function `rebalance_amounts_get`](#kai_sav_vault_rebalance_amounts_get)
-  [Function `new`](#kai_sav_vault_new)
-  [Function `assert_upgrade_cap`](#kai_sav_vault_assert_upgrade_cap)
-  [Function `new_with_upgrade_cap`](#kai_sav_vault_new_with_upgrade_cap)
-  [Function `assert_version`](#kai_sav_vault_assert_version)
-  [Function `free_balance`](#kai_sav_vault_free_balance)
-  [Function `tvl_cap`](#kai_sav_vault_tvl_cap)
-  [Function `total_available_balance`](#kai_sav_vault_total_available_balance)
-  [Function `total_yt_supply`](#kai_sav_vault_total_yt_supply)
-  [Function `set_tvl_cap`](#kai_sav_vault_set_tvl_cap)
-  [Function `set_profit_unlock_duration_sec`](#kai_sav_vault_set_profit_unlock_duration_sec)
-  [Function `set_performance_fee_bps`](#kai_sav_vault_set_performance_fee_bps)
-  [Function `withdraw_performance_fee`](#kai_sav_vault_withdraw_performance_fee)
-  [Function `pull_unlocked_profits_to_free_balance`](#kai_sav_vault_pull_unlocked_profits_to_free_balance)
-  [Function `add_strategy`](#kai_sav_vault_add_strategy)
-  [Function `set_strategy_max_borrow`](#kai_sav_vault_set_strategy_max_borrow)
-  [Function `set_strategy_target_alloc_weights_bps`](#kai_sav_vault_set_strategy_target_alloc_weights_bps)
-  [Function `remove_strategy`](#kai_sav_vault_remove_strategy)
-  [Function `set_withdrawals_disabled`](#kai_sav_vault_set_withdrawals_disabled)
-  [Function `withdrawals_disabled`](#kai_sav_vault_withdrawals_disabled)
-  [Function `set_rate_limiter`](#kai_sav_vault_set_rate_limiter)
-  [Function `remove_rate_limiter`](#kai_sav_vault_remove_rate_limiter)
-  [Function `has_rate_limiter`](#kai_sav_vault_has_rate_limiter)
-  [Function `rate_limiter_mut`](#kai_sav_vault_rate_limiter_mut)
-  [Function `set_max_inflow_and_outflow_limits`](#kai_sav_vault_set_max_inflow_and_outflow_limits)
-  [Function `migrate`](#kai_sav_vault_migrate)
-  [Function `deposit`](#kai_sav_vault_deposit)
-  [Function `create_withdraw_ticket`](#kai_sav_vault_create_withdraw_ticket)
-  [Function `withdraw`](#kai_sav_vault_withdraw)
-  [Function `redeem_withdraw_ticket`](#kai_sav_vault_redeem_withdraw_ticket)
-  [Function `withdraw_t_amt`](#kai_sav_vault_withdraw_t_amt)
-  [Function `strategy_withdraw_to_ticket`](#kai_sav_vault_strategy_withdraw_to_ticket)
-  [Function `calc_rebalance_amounts`](#kai_sav_vault_calc_rebalance_amounts)
-  [Function `strategy_repay`](#kai_sav_vault_strategy_repay)
-  [Function `strategy_borrow`](#kai_sav_vault_strategy_borrow)
-  [Function `strategy_hand_over_profit`](#kai_sav_vault_strategy_hand_over_profit)


<pre><code><b>use</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance">kai_sav::time_locked_balance</a>;
<b>use</b> <a href="../kai_sav/util.md#kai_sav_util">kai_sav::util</a>;
<b>use</b> <a href="../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter">rate_limiter::net_sliding_sum_limiter</a>;
<b>use</b> <a href="../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator">rate_limiter::ring_aggregator</a>;
<b>use</b> <a href="../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter">rate_limiter::sliding_sum_limiter</a>;
<b>use</b> <a href="../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../dependencies/std/u64.md#std_u64">std::u64</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../dependencies/sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/package.md#sui_package">sui::package</a>;
<b>use</b> <a href="../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_sav_vault_DepositEvent"></a>

## Struct `DepositEvent`

Event emitted when tokens are deposited into the vault.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_DepositEvent">DepositEvent</a>&lt;<b>phantom</b> YT&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>lp_minted: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_WithdrawEvent"></a>

## Struct `WithdrawEvent`

Event emitted when tokens are withdrawn from the vault.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawEvent">WithdrawEvent</a>&lt;<b>phantom</b> YT&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>amount: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>lp_burned: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_StrategyProfitEvent"></a>

## Struct `StrategyProfitEvent`

Event emitted when a strategy generates profit.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_StrategyProfitEvent">StrategyProfitEvent</a>&lt;<b>phantom</b> YT&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>strategy_id: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>profit: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>fee_amt_yt: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_StrategyLossEvent"></a>

## Struct `StrategyLossEvent`

Event emitted when a strategy experiences a loss.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_StrategyLossEvent">StrategyLossEvent</a>&lt;<b>phantom</b> YT&gt; <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>strategy_id: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>to_withdraw: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>withdrawn: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_AdminCap"></a>

## Struct `AdminCap`

There can only ever be one <code><a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a></code> for a <code><a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a></code>


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;<b>phantom</b> YT&gt; <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_VaultAccess"></a>

## Struct `VaultAccess`

Strategies store this and it gives them access to deposit and withdraw
from the vault


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_StrategyRemovalTicket"></a>

## Struct `StrategyRemovalTicket`

Ticket for safely removing a strategy from the vault.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">StrategyRemovalTicket</a>&lt;<b>phantom</b> T, <b>phantom</b> YT&gt;
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>access: <a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a></code>
</dt>
<dd>
</dd>
<dt>
<code>returned_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_StrategyWithdrawInfo"></a>

## Struct `StrategyWithdrawInfo`

Information about strategy withdrawal requirements.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_StrategyWithdrawInfo">StrategyWithdrawInfo</a>&lt;<b>phantom</b> T&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>to_withdraw: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>withdrawn_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>has_withdrawn: bool</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_WithdrawTicket"></a>

## Struct `WithdrawTicket`

Ticket for processing user withdrawals across multiple strategies.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a>&lt;<b>phantom</b> T, <b>phantom</b> YT&gt;
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>to_withdraw_from_free_balance: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>strategy_infos: <a href="../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../kai_sav/vault.md#kai_sav_vault_StrategyWithdrawInfo">kai_sav::vault::StrategyWithdrawInfo</a>&lt;T&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>lp_to_burn: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;YT&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_RebalanceInfo"></a>

## Struct `RebalanceInfo`

Information about rebalancing targets for a strategy.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_RebalanceInfo">RebalanceInfo</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>to_repay: u64</code>
</dt>
<dd>
 The target amount the strategy should repay. The strategy shouldn't
 repay more than this amount.
</dd>
<dt>
<code>can_borrow: u64</code>
</dt>
<dd>
 The target amount the strategy should borrow. There's no guarantee
 though that this amount is available in vault's free balance. The
 strategy shouldn't borrow more than this amount.
</dd>
</dl>


</details>

<a name="kai_sav_vault_RebalanceAmounts"></a>

## Struct `RebalanceAmounts`

Collection of rebalancing amounts for all strategies.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_RebalanceAmounts">RebalanceAmounts</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>inner: <a href="../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../kai_sav/vault.md#kai_sav_vault_RebalanceInfo">kai_sav::vault::RebalanceInfo</a>&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_StrategyState"></a>

## Struct `StrategyState`

State information for a strategy within the vault.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_StrategyState">StrategyState</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>borrowed: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>target_alloc_weight_bps: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>max_borrow: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_vault_Vault"></a>

## Struct `Vault`

Main vault managing single-asset deposits and multi-strategy allocation.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;<b>phantom</b> T, <b>phantom</b> YT&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
 balance that's not allocated to any strategy
</dd>
<dt>
<code>time_locked_profit: <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;</code>
</dt>
<dd>
 slowly distribute profits over time to avoid sandwitch attacks on rebalance
</dd>
<dt>
<code>lp_treasury: <a href="../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;YT&gt;</code>
</dt>
<dd>
 treasury of the vault's yield-bearing token
</dd>
<dt>
<code>strategies: <a href="../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../kai_sav/vault.md#kai_sav_vault_StrategyState">kai_sav::vault::StrategyState</a>&gt;</code>
</dt>
<dd>
 strategies
</dd>
<dt>
<code>performance_fee_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;YT&gt;</code>
</dt>
<dd>
 performance fee balance
</dd>
<dt>
<code>strategy_withdraw_priority_order: vector&lt;<a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>&gt;</code>
</dt>
<dd>
 priority order for withdrawing from strategies
</dd>
<dt>
<code>withdraw_ticket_issued: bool</code>
</dt>
<dd>
 only one withdraw ticket can be active at a time
</dd>
<dt>
<code><a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;</code>
</dt>
<dd>
 deposits are disabled above this threshold
</dd>
<dt>
<code>profit_unlock_duration_sec: u64</code>
</dt>
<dd>
 duration of profit unlock in seconds
</dd>
<dt>
<code>performance_fee_bps: u64</code>
</dt>
<dd>
 performance fee in basis points (taken from all profits)
</dd>
<dt>
<code>version: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_sav_vault_MODULE_VERSION"></a>



<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_MODULE_VERSION">MODULE_VERSION</a>: u64 = 3;
</code></pre>



<a name="kai_sav_vault_BPS_IN_100_PCT"></a>



<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_BPS_IN_100_PCT">BPS_IN_100_PCT</a>: u64 = 10000;
</code></pre>



<a name="kai_sav_vault_DEFAULT_PROFIT_UNLOCK_DURATION_SEC"></a>



<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_DEFAULT_PROFIT_UNLOCK_DURATION_SEC">DEFAULT_PROFIT_UNLOCK_DURATION_SEC</a>: u64 = 6000;
</code></pre>



<a name="kai_sav_vault_EInvalidBPS"></a>

BPS value can be at most 10000 (100%)


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidBPS">EInvalidBPS</a>: u64 = 0;
</code></pre>



<a name="kai_sav_vault_EDepositTooLarge"></a>

Deposit is over vault's TVL cap


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EDepositTooLarge">EDepositTooLarge</a>: u64 = 1;
</code></pre>



<a name="kai_sav_vault_EWithdrawTicketIssued"></a>

A withdraw ticket is issued


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawTicketIssued">EWithdrawTicketIssued</a>: u64 = 2;
</code></pre>



<a name="kai_sav_vault_EZeroAmount"></a>

Input balance amount should be positive


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EZeroAmount">EZeroAmount</a>: u64 = 3;
</code></pre>



<a name="kai_sav_vault_EStrategyAlreadyWithdrawn"></a>

Strategy has already withdrawn into the ticket


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EStrategyAlreadyWithdrawn">EStrategyAlreadyWithdrawn</a>: u64 = 4;
</code></pre>



<a name="kai_sav_vault_EStrategyNotWithdrawn"></a>

All strategies need to be withdrawn from to claim the ticket


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EStrategyNotWithdrawn">EStrategyNotWithdrawn</a>: u64 = 5;
</code></pre>



<a name="kai_sav_vault_EInvalidVaultAccess"></a>

The strategy is not registered with the vault


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidVaultAccess">EInvalidVaultAccess</a>: u64 = 6;
</code></pre>



<a name="kai_sav_vault_EInvalidWeights"></a>

Target strategy weights input should add up to 100% and contain the same
number of elements as the number of strategies


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidWeights">EInvalidWeights</a>: u64 = 7;
</code></pre>



<a name="kai_sav_vault_EInvariantViolation"></a>

An invariant has been violated


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EInvariantViolation">EInvariantViolation</a>: u64 = 8;
</code></pre>



<a name="kai_sav_vault_EWrongVersion"></a>

Calling functions from the wrong package version


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EWrongVersion">EWrongVersion</a>: u64 = 9;
</code></pre>



<a name="kai_sav_vault_ENotUpgrade"></a>

Migration is not an upgrade


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_ENotUpgrade">ENotUpgrade</a>: u64 = 10;
</code></pre>



<a name="kai_sav_vault_EInvalidUpgradeCap"></a>

UpgradeCap object doesn't belong to this package


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidUpgradeCap">EInvalidUpgradeCap</a>: u64 = 11;
</code></pre>



<a name="kai_sav_vault_ETreasurySupplyPositive"></a>

Treasury supply has to be 0


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_ETreasurySupplyPositive">ETreasurySupplyPositive</a>: u64 = 12;
</code></pre>



<a name="kai_sav_vault_EWithdrawalsDisabled"></a>

Withdrawals are disabled for this vault


<pre><code><b>const</b> <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawalsDisabled">EWithdrawalsDisabled</a>: u64 = 13;
</code></pre>



<a name="kai_sav_vault_vault_access_id"></a>

## Function `vault_access_id`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_vault_access_id">vault_access_id</a>(access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>): <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_vault_access_id">vault_access_id</a>(access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a>): ID {
    object::uid_to_inner(&access.id)
}
</code></pre>



</details>

<a name="kai_sav_vault_new_strategy_removal_ticket"></a>

## Function `new_strategy_removal_ticket`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_new_strategy_removal_ticket">new_strategy_removal_ticket</a>&lt;T, YT&gt;(access: <a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>, returned_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;): <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">kai_sav::vault::StrategyRemovalTicket</a>&lt;T, YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_new_strategy_removal_ticket">new_strategy_removal_ticket</a>&lt;T, YT&gt;(
    access: <a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a>,
    returned_balance: Balance&lt;T&gt;,
): <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">StrategyRemovalTicket</a>&lt;T, YT&gt; {
    <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">StrategyRemovalTicket</a> {
        access,
        returned_balance,
    }
}
</code></pre>



</details>

<a name="kai_sav_vault_withdraw_ticket_to_withdraw"></a>

## Function `withdraw_ticket_to_withdraw`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdraw_ticket_to_withdraw">withdraw_ticket_to_withdraw</a>&lt;T, YT&gt;(ticket: &<a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">kai_sav::vault::WithdrawTicket</a>&lt;T, YT&gt;, access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdraw_ticket_to_withdraw">withdraw_ticket_to_withdraw</a>&lt;T, YT&gt;(
    ticket: &<a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a>&lt;T, YT&gt;,
    access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a>,
): u64 {
    <b>let</b> id = object::uid_as_inner(&access.id);
    <b>let</b> info = vec_map::get(&ticket.strategy_infos, id);
    info.to_withdraw
}
</code></pre>



</details>

<a name="kai_sav_vault_rebalance_amounts_get"></a>

## Function `rebalance_amounts_get`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_rebalance_amounts_get">rebalance_amounts_get</a>(amounts: &<a href="../kai_sav/vault.md#kai_sav_vault_RebalanceAmounts">kai_sav::vault::RebalanceAmounts</a>, access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_rebalance_amounts_get">rebalance_amounts_get</a>(
    amounts: &<a href="../kai_sav/vault.md#kai_sav_vault_RebalanceAmounts">RebalanceAmounts</a>,
    access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a>,
): (u64, u64) {
    <b>let</b> strategy_id = object::uid_as_inner(&access.id);
    <b>let</b> amts = vec_map::get(&amounts.inner, strategy_id);
    (amts.can_borrow, amts.to_repay)
}
</code></pre>



</details>

<a name="kai_sav_vault_new"></a>

## Function `new`

Creates a new vault and admin cap for the given yield token.
Fails if the treasury cap has a nonzero supply.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_new">new</a>&lt;T, YT&gt;(lp_treasury: <a href="../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;YT&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_new">new</a>&lt;T, YT&gt;(lp_treasury: TreasuryCap&lt;YT&gt;, ctx: &<b>mut</b> TxContext): <a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt; {
    <b>assert</b>!(coin::total_supply(&lp_treasury) == 0, <a href="../kai_sav/vault.md#kai_sav_vault_ETreasurySupplyPositive">ETreasurySupplyPositive</a>);
    <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a> = <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt; {
        id: object::new(ctx),
        <a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>: balance::zero(),
        time_locked_profit: tlb::create(balance::zero(), 0, 0),
        lp_treasury,
        strategies: vec_map::empty(),
        performance_fee_balance: balance::zero(),
        strategy_withdraw_priority_order: vector::empty(),
        withdraw_ticket_issued: <b>false</b>,
        <a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>: option::none(),
        profit_unlock_duration_sec: <a href="../kai_sav/vault.md#kai_sav_vault_DEFAULT_PROFIT_UNLOCK_DURATION_SEC">DEFAULT_PROFIT_UNLOCK_DURATION_SEC</a>,
        performance_fee_bps: 0,
        version: <a href="../kai_sav/vault.md#kai_sav_vault_MODULE_VERSION">MODULE_VERSION</a>,
    };
    transfer::share_object(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    // since there can be only one `TreasuryCap&lt;YT&gt;` <b>for</b> type `YT`, there can be only
    // one `<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;` and `<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;` <b>for</b> type `YT` <b>as</b> well.
    <b>let</b> admin_cap = <a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt; {
        id: object::new(ctx),
    };
    admin_cap
}
</code></pre>



</details>

<a name="kai_sav_vault_assert_upgrade_cap"></a>

## Function `assert_upgrade_cap`



<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_assert_upgrade_cap">assert_upgrade_cap</a>(cap: &<a href="../dependencies/sui/package.md#sui_package_UpgradeCap">sui::package::UpgradeCap</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_assert_upgrade_cap">assert_upgrade_cap</a>(cap: &UpgradeCap) {
    <b>let</b> cap_id = @0x816949d764f3285c0420e9375c2594ca01355d1e05670b242ff5bfcf4c5fc958;
    <b>assert</b>!(object::id_address(cap) == cap_id, <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidUpgradeCap">EInvalidUpgradeCap</a>);
}
</code></pre>



</details>

<a name="kai_sav_vault_new_with_upgrade_cap"></a>

## Function `new_with_upgrade_cap`



<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_new_with_upgrade_cap">new_with_upgrade_cap</a>&lt;T, YT&gt;(cap: &<a href="../dependencies/sui/package.md#sui_package_UpgradeCap">sui::package::UpgradeCap</a>, lp_treasury: <a href="../dependencies/sui/coin.md#sui_coin_TreasuryCap">sui::coin::TreasuryCap</a>&lt;YT&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_new_with_upgrade_cap">new_with_upgrade_cap</a>&lt;T, YT&gt;(
    cap: &UpgradeCap,
    lp_treasury: TreasuryCap&lt;YT&gt;,
    ctx: &<b>mut</b> TxContext,
): <a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt; {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_upgrade_cap">assert_upgrade_cap</a>(cap);
    <a href="../kai_sav/vault.md#kai_sav_vault_new">new</a>&lt;T, YT&gt;(lp_treasury, ctx)
}
</code></pre>



</details>

<a name="kai_sav_vault_assert_version"></a>

## Function `assert_version`



<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;) {
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.version == <a href="../kai_sav/vault.md#kai_sav_vault_MODULE_VERSION">MODULE_VERSION</a>, <a href="../kai_sav/vault.md#kai_sav_vault_EWrongVersion">EWrongVersion</a>);
}
</code></pre>



</details>

<a name="kai_sav_vault_free_balance"></a>

## Function `free_balance`

Returns the vault's free (unallocated) balance.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;): u64 {
    balance::value(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>)
}
</code></pre>



</details>

<a name="kai_sav_vault_tvl_cap"></a>

## Function `tvl_cap`

Get the vault's TVL cap. Returns <code>None</code> if there is no cap.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;): <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;): Option&lt;u64&gt; {
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>
}
</code></pre>



</details>

<a name="kai_sav_vault_total_available_balance"></a>

## Function `total_available_balance`

Returns the total available balance in the vault, including free, unlocked profit, and strategy allocations.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;, clock: &Clock): u64 {
    <b>let</b> <b>mut</b> total: u64 = 0;
    total = total + balance::value(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>);
    total = total + tlb::max_withdrawable(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, clock);
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies.length();
    <b>while</b> (i &lt; n) {
        <b>let</b> (_, strategy_state) = vec_map::get_entry_by_idx(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, i);
        total = total + strategy_state.borrowed;
        i = i + 1;
    };
    total
}
</code></pre>



</details>

<a name="kai_sav_vault_total_yt_supply"></a>

## Function `total_yt_supply`

Returns the total supply of LP tokens for the vault.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_yt_supply">total_yt_supply</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_yt_supply">total_yt_supply</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;): u64 {
    coin::total_supply(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury)
}
</code></pre>



</details>

<a name="kai_sav_vault_set_tvl_cap"></a>

## Function `set_tvl_cap`

Set the vault's TVL cap. Only callable by admin.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_tvl_cap">set_tvl_cap</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_tvl_cap">set_tvl_cap</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>: Option&lt;u64&gt;) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a> = <a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>;
}
</code></pre>



</details>

<a name="kai_sav_vault_set_profit_unlock_duration_sec"></a>

## Function `set_profit_unlock_duration_sec`

Set the profit unlock duration (seconds). Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_profit_unlock_duration_sec">set_profit_unlock_duration_sec</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, profit_unlock_duration_sec: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_profit_unlock_duration_sec">set_profit_unlock_duration_sec</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    profit_unlock_duration_sec: u64,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.profit_unlock_duration_sec = profit_unlock_duration_sec;
}
</code></pre>



</details>

<a name="kai_sav_vault_set_performance_fee_bps"></a>

## Function `set_performance_fee_bps`

Set the performance fee in basis points. Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_performance_fee_bps">set_performance_fee_bps</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, performance_fee_bps: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_performance_fee_bps">set_performance_fee_bps</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    performance_fee_bps: u64,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>assert</b>!(performance_fee_bps &lt;= <a href="../kai_sav/vault.md#kai_sav_vault_BPS_IN_100_PCT">BPS_IN_100_PCT</a>, <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidBPS">EInvalidBPS</a>);
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.performance_fee_bps = performance_fee_bps;
}
</code></pre>



</details>

<a name="kai_sav_vault_withdraw_performance_fee"></a>

## Function `withdraw_performance_fee`

Withdraws the specified amount of performance fees. Admin only.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdraw_performance_fee">withdraw_performance_fee</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, amount: u64): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdraw_performance_fee">withdraw_performance_fee</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    amount: u64,
): Balance&lt;YT&gt; {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    balance::split(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.performance_fee_balance, amount)
}
</code></pre>



</details>

<a name="kai_sav_vault_pull_unlocked_profits_to_free_balance"></a>

## Function `pull_unlocked_profits_to_free_balance`

Move all unlocked profits to the vault's free balance. Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_pull_unlocked_profits_to_free_balance">pull_unlocked_profits_to_free_balance</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_pull_unlocked_profits_to_free_balance">pull_unlocked_profits_to_free_balance</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    clock: &Clock,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    balance::join(
        &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>,
        tlb::withdraw_all(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, clock),
    );
}
</code></pre>



</details>

<a name="kai_sav_vault_add_strategy"></a>

## Function `add_strategy`

Add a new strategy to the vault.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_add_strategy">add_strategy</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_add_strategy">add_strategy</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    ctx: &<b>mut</b> TxContext,
): <a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a> {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>let</b> access = <a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a> { id: object::new(ctx) };
    <b>let</b> strategy_id = object::uid_to_inner(&access.id);
    <b>let</b> target_alloc_weight_bps = <b>if</b> (<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies.length() == 0) {
        <a href="../kai_sav/vault.md#kai_sav_vault_BPS_IN_100_PCT">BPS_IN_100_PCT</a>
    } <b>else</b> {
        0
    };
    vec_map::insert(
        &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies,
        strategy_id,
        <a href="../kai_sav/vault.md#kai_sav_vault_StrategyState">StrategyState</a> {
            borrowed: 0,
            target_alloc_weight_bps,
            max_borrow: option::none(),
        },
    );
    vector::push_back(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order, strategy_id);
    access
}
</code></pre>



</details>

<a name="kai_sav_vault_set_strategy_max_borrow"></a>

## Function `set_strategy_max_borrow`

Set the maximum borrow amount for a strategy. Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_strategy_max_borrow">set_strategy_max_borrow</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, strategy_id: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, max_borrow: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_strategy_max_borrow">set_strategy_max_borrow</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    strategy_id: ID,
    max_borrow: Option&lt;u64&gt;,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>let</b> state = vec_map::get_mut(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, &strategy_id);
    state.max_borrow = max_borrow;
}
</code></pre>



</details>

<a name="kai_sav_vault_set_strategy_target_alloc_weights_bps"></a>

## Function `set_strategy_target_alloc_weights_bps`

Set target allocation weights (in BPS) for all strategies. Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_strategy_target_alloc_weights_bps">set_strategy_target_alloc_weights_bps</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, ids: vector&lt;<a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>&gt;, weights_bps: vector&lt;u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_strategy_target_alloc_weights_bps">set_strategy_target_alloc_weights_bps</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    ids: vector&lt;ID&gt;,
    weights_bps: vector&lt;u64&gt;,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>let</b> <b>mut</b> ids_seen = vec_set::empty&lt;ID&gt;();
    <b>let</b> <b>mut</b> total_bps = 0;
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies.length();
    <b>assert</b>!(n == vector::length(&ids), <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidWeights">EInvalidWeights</a>);
    <b>assert</b>!(n == vector::length(&weights_bps), <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidWeights">EInvalidWeights</a>);
    <b>while</b> (i &lt; n) {
        <b>let</b> id = *vector::borrow(&ids, i);
        <b>let</b> weight = *vector::borrow(&weights_bps, i);
        vec_set::insert(&<b>mut</b> ids_seen, id); // checks <b>for</b> duplicate ids
        total_bps = total_bps + weight;
        <b>let</b> state = vec_map::get_mut(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, &id);
        state.target_alloc_weight_bps = weight;
        i = i + 1;
    };
    <b>assert</b>!(total_bps == <a href="../kai_sav/vault.md#kai_sav_vault_BPS_IN_100_PCT">BPS_IN_100_PCT</a>, <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidWeights">EInvalidWeights</a>);
}
</code></pre>



</details>

<a name="kai_sav_vault_remove_strategy"></a>

## Function `remove_strategy`

Remove a strategy from the vault and update allocation weights. Admin only.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_remove_strategy">remove_strategy</a>&lt;T, YT&gt;(cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, ticket: <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">kai_sav::vault::StrategyRemovalTicket</a>&lt;T, YT&gt;, ids_for_weights: vector&lt;<a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>&gt;, weights_bps: vector&lt;u64&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_remove_strategy">remove_strategy</a>&lt;T, YT&gt;(
    cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    ticket: <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">StrategyRemovalTicket</a>&lt;T, YT&gt;,
    ids_for_weights: vector&lt;ID&gt;,
    weights_bps: vector&lt;u64&gt;,
    clock: &Clock,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">StrategyRemovalTicket</a> { access, <b>mut</b> returned_balance } = ticket;
    <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a> { id: uid } = access;
    <b>let</b> id = &object::uid_to_inner(&uid);
    object::delete(uid);
    // remove from strategies and <b>return</b> balance
    <b>let</b> (_, state) = vec_map::remove(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, id);
    <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_StrategyState">StrategyState</a> { borrowed, target_alloc_weight_bps: _, max_borrow: _ } = state;
    <b>let</b> returned_value = balance::value(&returned_balance);
    <b>if</b> (returned_value &gt; borrowed) {
        <b>let</b> profit = balance::split(
            &<b>mut</b> returned_balance,
            returned_value - borrowed,
        );
        tlb::top_up(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, profit, clock);
    };
    balance::join(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>, returned_balance);
    // remove from <a href="../kai_sav/vault.md#kai_sav_vault_withdraw">withdraw</a> priority order
    <b>let</b> (<b>has</b>, idx) = vector::index_of(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order, id);
    <b>assert</b>!(<b>has</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EInvariantViolation">EInvariantViolation</a>);
    vector::remove(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order, idx);
    // set <a href="../kai_sav/vault.md#kai_sav_vault_new">new</a> weights
    <a href="../kai_sav/vault.md#kai_sav_vault_set_strategy_target_alloc_weights_bps">set_strategy_target_alloc_weights_bps</a>(cap, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, ids_for_weights, weights_bps);
}
</code></pre>



</details>

<a name="kai_sav_vault_set_withdrawals_disabled"></a>

## Function `set_withdrawals_disabled`

Disable or enable withdrawals from the vault. Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_withdrawals_disabled">set_withdrawals_disabled</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_withdrawals_disabled">set_withdrawals_disabled</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>: bool,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>if</b> (df::exists_(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"<a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>")) {
        <b>let</b> val = df::borrow_mut(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"<a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>");
        *val = <a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>;
    } <b>else</b> {
        df::add(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"<a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>", <a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>);
    }
}
</code></pre>



</details>

<a name="kai_sav_vault_withdrawals_disabled"></a>

## Function `withdrawals_disabled`

Returns true if withdrawals are currently disabled for the vault.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;): bool {
    <b>if</b> (df::exists_(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"<a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>")) {
        <b>let</b> val = df::borrow(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"<a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>");
        *val
    } <b>else</b> {
        <b>false</b>
    }
}
</code></pre>



</details>

<a name="kai_sav_vault_set_rate_limiter"></a>

## Function `set_rate_limiter`

Set the rate limiter for the vault. Admin only.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_rate_limiter">set_rate_limiter</a>&lt;T, YT, L: store&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, rate_limiter: L)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_rate_limiter">set_rate_limiter</a>&lt;T, YT, L: store&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    rate_limiter: L,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    df::add(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"rate_limiter", rate_limiter);
}
</code></pre>



</details>

<a name="kai_sav_vault_remove_rate_limiter"></a>

## Function `remove_rate_limiter`

Remove the rate limiter from the vault. Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_remove_rate_limiter">remove_rate_limiter</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_remove_rate_limiter">remove_rate_limiter</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    df::remove&lt;_, NetSlidingSumLimiter&gt;(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"rate_limiter");
}
</code></pre>



</details>

<a name="kai_sav_vault_has_rate_limiter"></a>

## Function `has_rate_limiter`



<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_has_rate_limiter">has_rate_limiter</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_has_rate_limiter">has_rate_limiter</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;): bool {
    df::exists_(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"rate_limiter")
}
</code></pre>



</details>

<a name="kai_sav_vault_rate_limiter_mut"></a>

## Function `rate_limiter_mut`



<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_rate_limiter_mut">rate_limiter_mut</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;): &<b>mut</b> <a href="../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter_NetSlidingSumLimiter">rate_limiter::net_sliding_sum_limiter::NetSlidingSumLimiter</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_rate_limiter_mut">rate_limiter_mut</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;): &<b>mut</b> NetSlidingSumLimiter {
    df::borrow_mut(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.id, b"rate_limiter")
}
</code></pre>



</details>

<a name="kai_sav_vault_set_max_inflow_and_outflow_limits"></a>

## Function `set_max_inflow_and_outflow_limits`

Sets the maximum inflow and outflow limits for the vault's rate limiter. Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_max_inflow_and_outflow_limits">set_max_inflow_and_outflow_limits</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, max_inflow_limit: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;, max_outflow_limit: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u256&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_set_max_inflow_and_outflow_limits">set_max_inflow_and_outflow_limits</a>&lt;T, YT&gt;(
    _cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    max_inflow_limit: Option&lt;u256&gt;,
    max_outflow_limit: Option&lt;u256&gt;,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>let</b> rate_limiter = <a href="../kai_sav/vault.md#kai_sav_vault_rate_limiter_mut">rate_limiter_mut</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    rate_limiter.set_max_inflow_limit(max_inflow_limit);
    rate_limiter.set_max_outflow_limit(max_outflow_limit);
}
</code></pre>



</details>

<a name="kai_sav_vault_migrate"></a>

## Function `migrate`

Upgrade the vault to the latest module version. Admin only.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_migrate">migrate</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_migrate">migrate</a>&lt;T, YT&gt;(_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">AdminCap</a>&lt;YT&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;) {
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.version &lt; <a href="../kai_sav/vault.md#kai_sav_vault_MODULE_VERSION">MODULE_VERSION</a>, <a href="../kai_sav/vault.md#kai_sav_vault_ENotUpgrade">ENotUpgrade</a>);
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.version = <a href="../kai_sav/vault.md#kai_sav_vault_MODULE_VERSION">MODULE_VERSION</a>;
}
</code></pre>



</details>

<a name="kai_sav_vault_deposit"></a>

## Function `deposit`

Deposit tokens into the vault and receive LP shares.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_deposit">deposit</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_deposit">deposit</a>&lt;T, YT&gt;(
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    balance: Balance&lt;T&gt;,
    clock: &Clock,
): Balance&lt;YT&gt; {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.withdraw_ticket_issued == <b>false</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawTicketIssued">EWithdrawTicketIssued</a>);
    <b>if</b> (balance::value(&balance) == 0) {
        balance::destroy_zero(balance);
        <b>return</b> balance::zero()
    };
    // apply rate limiting to the <a href="../kai_sav/vault.md#kai_sav_vault_deposit">deposit</a> amount
    <b>if</b> (<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_has_rate_limiter">has_rate_limiter</a>()) {
        <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_rate_limiter_mut">rate_limiter_mut</a>().consume_inflow(balance.value(), clock);
    };
    // edge case -- appropriate any existing balances into performance
    // fees in case lp supply is 0.
    // this guarantees that lp supply is non-zero <b>if</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>
    // is positive.
    <b>if</b> (coin::total_supply(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury) == 0) {
        // take any existing balances from time_locked_profit
        tlb::change_unlock_per_second(
            &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit,
            0,
            clock,
        );
        <b>let</b> skimmed = tlb::skim_extraneous_balance(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit);
        <b>let</b> withdrawn = tlb::withdraw_all(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, clock);
        balance::join(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>, skimmed);
        balance::join(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>, withdrawn);
        // appropriate everything to performance fees
        <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> = <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, clock);
        balance::join(
            &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.performance_fee_balance,
            coin::mint_balance(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury, <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>),
        );
    };
    <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> = <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, clock);
    <b>if</b> (option::is_some(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>)) {
        <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a> = *option::borrow(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>);
        <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> + balance::value(&balance) &lt;= <a href="../kai_sav/vault.md#kai_sav_vault_tvl_cap">tvl_cap</a>, <a href="../kai_sav/vault.md#kai_sav_vault_EDepositTooLarge">EDepositTooLarge</a>);
    };
    <b>let</b> lp_amount = <b>if</b> (<a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> == 0) {
        balance::value(&balance)
    } <b>else</b> {
        muldiv(
            coin::total_supply(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury),
            balance::value(&balance),
            <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>,
        )
    };
    event::emit(<a href="../kai_sav/vault.md#kai_sav_vault_DepositEvent">DepositEvent</a>&lt;YT&gt; {
        amount: balance::value(&balance),
        lp_minted: lp_amount,
    });
    balance::join(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>, balance);
    coin::mint_balance(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury, lp_amount)
}
</code></pre>



</details>

<a name="kai_sav_vault_create_withdraw_ticket"></a>

## Function `create_withdraw_ticket`



<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_create_withdraw_ticket">create_withdraw_ticket</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;): <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">kai_sav::vault::WithdrawTicket</a>&lt;T, YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_create_withdraw_ticket">create_withdraw_ticket</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;): <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a>&lt;T, YT&gt; {
    <b>let</b> <b>mut</b> strategy_infos: VecMap&lt;ID, <a href="../kai_sav/vault.md#kai_sav_vault_StrategyWithdrawInfo">StrategyWithdrawInfo</a>&lt;T&gt;&gt; = vec_map::empty();
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = vector::length(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order);
    <b>while</b> (i &lt; n) {
        <b>let</b> strategy_id = *vector::borrow(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order, i);
        <b>let</b> info = <a href="../kai_sav/vault.md#kai_sav_vault_StrategyWithdrawInfo">StrategyWithdrawInfo</a> {
            to_withdraw: 0,
            withdrawn_balance: balance::zero(),
            has_withdrawn: <b>false</b>,
        };
        vec_map::insert(&<b>mut</b> strategy_infos, strategy_id, info);
        i = i + 1;
    };
    <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a> {
        to_withdraw_from_free_balance: 0,
        strategy_infos,
        lp_to_burn: balance::zero(),
    }
}
</code></pre>



</details>

<a name="kai_sav_vault_withdraw"></a>

## Function `withdraw`

Withdraws assets from the vault by burning LP tokens and issues a withdraw ticket.

This function processes a withdrawal request by burning the specified LP token balance,
joining any unlocked profits to the free balance, and calculating the withdrawable amount.
If the free balance is insufficient, it initiates withdrawals from strategies according to
the configured priority order. Withdrawals may be subject to rate limiting and time locks.
The returned <code><a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a></code> must be used to call withdrawal for each strategy that needs to be withdrawn from
before the withdrawal can be fully claimed.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdraw">withdraw</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;YT&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">kai_sav::vault::WithdrawTicket</a>&lt;T, YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdraw">withdraw</a>&lt;T, YT&gt;(
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    balance: Balance&lt;YT&gt;,
    clock: &Clock,
): <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a>&lt;T, YT&gt; {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.withdraw_ticket_issued == <b>false</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawTicketIssued">EWithdrawTicketIssued</a>);
    <b>assert</b>!(balance::value(&balance) &gt; 0, <a href="../kai_sav/vault.md#kai_sav_vault_EZeroAmount">EZeroAmount</a>);
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault_withdrawals_disabled">withdrawals_disabled</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>) == <b>false</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawalsDisabled">EWithdrawalsDisabled</a>);
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.withdraw_ticket_issued = <b>true</b>;
    <b>let</b> <b>mut</b> ticket = <a href="../kai_sav/vault.md#kai_sav_vault_create_withdraw_ticket">create_withdraw_ticket</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    balance::join(&<b>mut</b> ticket.lp_to_burn, balance);
    // join unlocked profits to free balance
    balance::join(
        &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>,
        tlb::withdraw_all(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, clock),
    );
    // calculate <a href="../kai_sav/vault.md#kai_sav_vault_withdraw">withdraw</a> amount
    <b>let</b> total_available = <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, clock);
    <b>let</b> <b>mut</b> remaining_to_withdraw = muldiv(
        balance::value(&ticket.lp_to_burn),
        total_available,
        coin::total_supply(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury),
    );
    // apply rate limiting to the withdrawal amount
    <b>if</b> (<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_has_rate_limiter">has_rate_limiter</a>()) {
        <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_rate_limiter_mut">rate_limiter_mut</a>().consume_outflow(remaining_to_withdraw, clock);
    };
    // first <a href="../kai_sav/vault.md#kai_sav_vault_withdraw">withdraw</a> everything possible from free balance
    ticket.to_withdraw_from_free_balance =
        u64::min(
            remaining_to_withdraw,
            balance::value(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>),
        );
    remaining_to_withdraw = remaining_to_withdraw - ticket.to_withdraw_from_free_balance;
    <b>if</b> (remaining_to_withdraw == 0) {
        <b>return</b> ticket
    };
    // <b>if</b> this is not enough, start withdrawing from strategies
    // first <a href="../kai_sav/vault.md#kai_sav_vault_withdraw">withdraw</a> from all the strategies that are over their target allocation
    <b>let</b> <b>mut</b> total_borrowed_after_excess_withdrawn = 0;
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = vector::length(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order);
    <b>while</b> (i &lt; n && remaining_to_withdraw &gt; 0) {
        <b>let</b> strategy_id = vector::borrow(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order, i);
        <b>let</b> strategy_state = vec_map::get(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, strategy_id);
        <b>let</b> strategy_withdraw_info = vec_map::get_mut(&<b>mut</b> ticket.strategy_infos, strategy_id);
        <b>let</b> over_cap = <b>if</b> (option::is_some(&strategy_state.max_borrow)) {
            <b>let</b> max_borrow: u64 = *option::borrow(&strategy_state.max_borrow);
            <b>if</b> (strategy_state.borrowed &gt; max_borrow) {
                strategy_state.borrowed - max_borrow
            } <b>else</b> {
                0
            }
        } <b>else</b> {
            0
        };
        <b>let</b> to_withdraw = <b>if</b> (over_cap &gt;= remaining_to_withdraw) {
            remaining_to_withdraw
        } <b>else</b> {
            over_cap
        };
        remaining_to_withdraw = remaining_to_withdraw - to_withdraw;
        total_borrowed_after_excess_withdrawn =
            total_borrowed_after_excess_withdrawn + strategy_state.borrowed - to_withdraw;
        strategy_withdraw_info.to_withdraw = to_withdraw;
        i = i + 1;
    };
    // <b>if</b> that is not enough, <a href="../kai_sav/vault.md#kai_sav_vault_withdraw">withdraw</a> from all strategies proportionally so that
    // the strategy borrowed amounts are kept at the same proportions <b>as</b> they were before
    <b>if</b> (remaining_to_withdraw == 0) {
        <b>return</b> ticket
    };
    <b>let</b> to_withdraw_propotionally_base = remaining_to_withdraw;
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = vector::length(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order);
    <b>while</b> (i &lt; n) {
        <b>let</b> strategy_id = vector::borrow(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order, i);
        <b>let</b> strategy_state = vec_map::get(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, strategy_id);
        <b>let</b> strategy_withdraw_info = vec_map::get_mut(&<b>mut</b> ticket.strategy_infos, strategy_id);
        <b>let</b> strategy_remaining = strategy_state.borrowed - strategy_withdraw_info.to_withdraw;
        <b>let</b> to_withdraw = muldiv(
            strategy_remaining,
            to_withdraw_propotionally_base,
            total_borrowed_after_excess_withdrawn,
        );
        strategy_withdraw_info.to_withdraw = strategy_withdraw_info.to_withdraw + to_withdraw;
        remaining_to_withdraw = remaining_to_withdraw - to_withdraw;
        i = i + 1;
    };
    // <b>if</b> that is not enough, start withdrawing all from strategies in priority order
    <b>if</b> (remaining_to_withdraw == 0) {
        <b>return</b> ticket
    };
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = vector::length(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order);
    <b>while</b> (i &lt; n) {
        <b>let</b> strategy_id = vector::borrow(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_withdraw_priority_order, i);
        <b>let</b> strategy_state = vec_map::get(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, strategy_id);
        <b>let</b> strategy_withdraw_info = vec_map::get_mut(&<b>mut</b> ticket.strategy_infos, strategy_id);
        <b>let</b> strategy_remaining = strategy_state.borrowed - strategy_withdraw_info.to_withdraw;
        <b>let</b> to_withdraw = u64::min(strategy_remaining, remaining_to_withdraw);
        strategy_withdraw_info.to_withdraw = strategy_withdraw_info.to_withdraw + to_withdraw;
        remaining_to_withdraw = remaining_to_withdraw - to_withdraw;
        <b>if</b> (remaining_to_withdraw == 0) {
            <b>break</b>
        };
        i = i + 1;
    };
    ticket
}
</code></pre>



</details>

<a name="kai_sav_vault_redeem_withdraw_ticket"></a>

## Function `redeem_withdraw_ticket`

Redeems a withdraw ticket, finalizing the withdrawal and burning the corresponding LP tokens.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_redeem_withdraw_ticket">redeem_withdraw_ticket</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, ticket: <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">kai_sav::vault::WithdrawTicket</a>&lt;T, YT&gt;): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_redeem_withdraw_ticket">redeem_withdraw_ticket</a>&lt;T, YT&gt;(
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    ticket: <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a>&lt;T, YT&gt;,
): Balance&lt;T&gt; {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>let</b> <b>mut</b> out = balance::zero();
    <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a> {
        to_withdraw_from_free_balance,
        <b>mut</b> strategy_infos,
        lp_to_burn,
    } = ticket;
    <b>let</b> lp_to_burn_amt = balance::value(&lp_to_burn);
    <b>while</b> (strategy_infos.length() &gt; 0) {
        <b>let</b> (strategy_id, withdraw_info) = vec_map::pop(&<b>mut</b> strategy_infos);
        <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_StrategyWithdrawInfo">StrategyWithdrawInfo</a> {
            to_withdraw,
            withdrawn_balance,
            has_withdrawn,
        } = withdraw_info;
        <b>if</b> (to_withdraw &gt; 0) {
            <b>assert</b>!(has_withdrawn, <a href="../kai_sav/vault.md#kai_sav_vault_EStrategyNotWithdrawn">EStrategyNotWithdrawn</a>);
        };
        <b>if</b> (balance::value(&withdrawn_balance) &lt; to_withdraw) {
            event::emit(<a href="../kai_sav/vault.md#kai_sav_vault_StrategyLossEvent">StrategyLossEvent</a>&lt;YT&gt; {
                strategy_id,
                to_withdraw,
                withdrawn: balance::value(&withdrawn_balance),
            });
        };
        // Reduce strategy's borrowed amount. This calculation is intentionally based on
        // `to_withdraw` and not `withdrawn_balance` amount so that any losses generated
        // by the withdrawal are effectively covered by the user and considered paid back
        // to the <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>. This also ensures that <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>'s `<a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>` before
        // and after withdrawal matches the amount of lp tokens burned.
        <b>let</b> strategy_state = vec_map::get_mut(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, &strategy_id);
        strategy_state.borrowed = strategy_state.borrowed - to_withdraw;
        balance::join(&<b>mut</b> out, withdrawn_balance);
    };
    vec_map::destroy_empty(strategy_infos);
    balance::join(
        &<b>mut</b> out,
        balance::split(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>, to_withdraw_from_free_balance),
    );
    balance::decrease_supply(
        coin::supply_mut(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury),
        lp_to_burn,
    );
    event::emit(<a href="../kai_sav/vault.md#kai_sav_vault_WithdrawEvent">WithdrawEvent</a>&lt;YT&gt; {
        amount: balance::value(&out),
        lp_burned: lp_to_burn_amt,
    });
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.withdraw_ticket_issued = <b>false</b>;
    out
}
</code></pre>



</details>

<a name="kai_sav_vault_withdraw_t_amt"></a>

## Function `withdraw_t_amt`

Withdraws a specified amount of the underlying token from the vault, burning the corresponding amount of LP tokens.
Returns a <code><a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a></code> representing the withdrawal.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdraw_t_amt">withdraw_t_amt</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, t_amt: u64, balance: &<b>mut</b> <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;YT&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">kai_sav::vault::WithdrawTicket</a>&lt;T, YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_withdraw_t_amt">withdraw_t_amt</a>&lt;T, YT&gt;(
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    t_amt: u64,
    balance: &<b>mut</b> Balance&lt;YT&gt;,
    clock: &Clock,
): <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a>&lt;T, YT&gt; {
    <b>let</b> total_available = <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, clock);
    <b>let</b> yt_amt = muldiv_round_up(
        t_amt,
        coin::total_supply(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury),
        total_available,
    );
    <b>let</b> balance = balance::split(balance, yt_amt);
    <a href="../kai_sav/vault.md#kai_sav_vault_withdraw">withdraw</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, balance, clock)
}
</code></pre>



</details>

<a name="kai_sav_vault_strategy_withdraw_to_ticket"></a>

## Function `strategy_withdraw_to_ticket`

Makes the strategy deposit the withdrawn balance into the <code><a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a></code>.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_strategy_withdraw_to_ticket">strategy_withdraw_to_ticket</a>&lt;T, YT&gt;(ticket: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">kai_sav::vault::WithdrawTicket</a>&lt;T, YT&gt;, access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>, balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_strategy_withdraw_to_ticket">strategy_withdraw_to_ticket</a>&lt;T, YT&gt;(
    ticket: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">WithdrawTicket</a>&lt;T, YT&gt;,
    access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a>,
    balance: Balance&lt;T&gt;,
) {
    <b>let</b> strategy_id = object::uid_as_inner(&access.id);
    <b>let</b> withdraw_info = vec_map::get_mut(&<b>mut</b> ticket.strategy_infos, strategy_id);
    <b>assert</b>!(withdraw_info.has_withdrawn == <b>false</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EStrategyAlreadyWithdrawn">EStrategyAlreadyWithdrawn</a>);
    withdraw_info.has_withdrawn = <b>true</b>;
    balance::join(&<b>mut</b> withdraw_info.withdrawn_balance, balance);
}
</code></pre>



</details>

<a name="kai_sav_vault_calc_rebalance_amounts"></a>

## Function `calc_rebalance_amounts`

Get the target rebalance amounts the strategies should repay or can borrow.
It takes into account strategy target allocation weights and max borrow limits
and calculates the values so that the vault's balance allocations are kept
at the target weights and all of the vault's balance is allocated.
This function is idempotent in the sense that if you rebalance the pool with
the returned amounts and call it again, the result will require no further
rebalancing.
The strategies are not expected to repay / borrow the exact amounts suggested
as this may be dictated by their internal logic, but they should try to
get as close as possible. Since the strategies are trusted, there are no
explicit checks for this within the vault.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_calc_rebalance_amounts">calc_rebalance_amounts</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../kai_sav/vault.md#kai_sav_vault_RebalanceAmounts">kai_sav::vault::RebalanceAmounts</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_calc_rebalance_amounts">calc_rebalance_amounts</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;, clock: &Clock): <a href="../kai_sav/vault.md#kai_sav_vault_RebalanceAmounts">RebalanceAmounts</a> {
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.withdraw_ticket_issued == <b>false</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawTicketIssued">EWithdrawTicketIssued</a>);
    // calculate total available balance and prepare rebalance infos
    <b>let</b> <b>mut</b> rebalance_infos: VecMap&lt;ID, <a href="../kai_sav/vault.md#kai_sav_vault_RebalanceInfo">RebalanceInfo</a>&gt; = vec_map::empty();
    <b>let</b> <b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> = 0;
    <b>let</b> <b>mut</b> max_borrow_idxs_to_process = vector::empty();
    <b>let</b> <b>mut</b> no_max_borrow_idxs = vector::empty();
    <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> = <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> + balance::value(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>);
    <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> =
        <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> + tlb::max_withdrawable(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, clock);
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies.length();
    <b>while</b> (i &lt; n) {
        <b>let</b> (strategy_id, strategy_state) = vec_map::get_entry_by_idx(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, i);
        vec_map::insert(
            &<b>mut</b> rebalance_infos,
            *strategy_id,
            <a href="../kai_sav/vault.md#kai_sav_vault_RebalanceInfo">RebalanceInfo</a> {
                to_repay: 0,
                can_borrow: 0,
            },
        );
        <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> = <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> + strategy_state.borrowed;
        <b>if</b> (option::is_some(&strategy_state.max_borrow)) {
            vector::push_back(&<b>mut</b> max_borrow_idxs_to_process, i);
        } <b>else</b> {
            vector::push_back(&<b>mut</b> no_max_borrow_idxs, i);
        };
        i = i + 1;
    };
    // process strategies with max borrow limits iteratively until all who can
    // reach their cap have reached it
    <b>let</b> <b>mut</b> remaining_to_allocate = <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>;
    <b>let</b> <b>mut</b> remaining_total_alloc_bps = <a href="../kai_sav/vault.md#kai_sav_vault_BPS_IN_100_PCT">BPS_IN_100_PCT</a>;
    <b>let</b> <b>mut</b> need_to_reprocess = <b>true</b>;
    <b>while</b> (need_to_reprocess) {
        <b>let</b> <b>mut</b> i = 0;
        <b>let</b> n = vector::length(&max_borrow_idxs_to_process);
        <b>let</b> <b>mut</b> new_max_borrow_idxs_to_process = vector::empty();
        need_to_reprocess = <b>false</b>;
        <b>while</b> (i &lt; n) {
            <b>let</b> idx = *vector::borrow(&max_borrow_idxs_to_process, i);
            <b>let</b> (_, strategy_state) = vec_map::get_entry_by_idx(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, idx);
            <b>let</b> (_, rebalance_info) = vec_map::get_entry_by_idx_mut(&<b>mut</b> rebalance_infos, idx);
            <b>let</b> max_borrow: u64 = *option::borrow(&strategy_state.max_borrow);
            <b>let</b> target_alloc_amt = muldiv(
                remaining_to_allocate,
                strategy_state.target_alloc_weight_bps,
                remaining_total_alloc_bps,
            );
            <b>if</b> (
                target_alloc_amt &lt;= strategy_state.borrowed || max_borrow &lt;= strategy_state.borrowed
            ) {
                // needs to repay
                <b>if</b> (target_alloc_amt &lt; max_borrow) {
                    vector::push_back(&<b>mut</b> new_max_borrow_idxs_to_process, idx);
                } <b>else</b> {
                    <b>let</b> target_alloc_amt = max_borrow;
                    rebalance_info.to_repay = strategy_state.borrowed - target_alloc_amt;
                    remaining_to_allocate = remaining_to_allocate - target_alloc_amt;
                    remaining_total_alloc_bps =
                        remaining_total_alloc_bps - strategy_state.target_alloc_weight_bps;
                    // might add extra amounts to allocate so need to reprocess ones which
                    // haven't reached their cap
                    need_to_reprocess = <b>true</b>;
                };
                i = i + 1;
                <b>continue</b>
            };
            // can borrow
            <b>if</b> (target_alloc_amt &gt;= max_borrow) {
                <b>let</b> target_alloc_amt = max_borrow;
                rebalance_info.can_borrow = target_alloc_amt - strategy_state.borrowed;
                remaining_to_allocate = remaining_to_allocate - target_alloc_amt;
                remaining_total_alloc_bps =
                    remaining_total_alloc_bps - strategy_state.target_alloc_weight_bps;
                // might add extra amounts to allocate so need to reprocess ones which
                // haven't reached their cap
                need_to_reprocess = <b>true</b>;
                i = i + 1;
                <b>continue</b>
            } <b>else</b> {
                vector::push_back(&<b>mut</b> new_max_borrow_idxs_to_process, idx);
                i = i + 1;
                <b>continue</b>
            }
        };
        max_borrow_idxs_to_process = new_max_borrow_idxs_to_process;
    };
    // the remaining strategies in `max_borrow_idxs_to_process` and `no_max_borrow_idxs` won't reach
    // their cap so we can easilly calculate the remaining amounts to allocate
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = vector::length(&max_borrow_idxs_to_process);
    <b>while</b> (i &lt; n) {
        <b>let</b> idx = *vector::borrow(&max_borrow_idxs_to_process, i);
        <b>let</b> (_, strategy_state) = vec_map::get_entry_by_idx(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, idx);
        <b>let</b> (_, rebalance_info) = vec_map::get_entry_by_idx_mut(&<b>mut</b> rebalance_infos, idx);
        <b>let</b> target_borrow = muldiv(
            remaining_to_allocate,
            strategy_state.target_alloc_weight_bps,
            remaining_total_alloc_bps,
        );
        <b>if</b> (target_borrow &gt;= strategy_state.borrowed) {
            rebalance_info.can_borrow = target_borrow - strategy_state.borrowed;
        } <b>else</b> {
            rebalance_info.to_repay = strategy_state.borrowed - target_borrow;
        };
        i = i + 1;
    };
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = vector::length(&no_max_borrow_idxs);
    <b>while</b> (i &lt; n) {
        <b>let</b> idx = *vector::borrow(&no_max_borrow_idxs, i);
        <b>let</b> (_, strategy_state) = vec_map::get_entry_by_idx(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, idx);
        <b>let</b> (_, rebalance_info) = vec_map::get_entry_by_idx_mut(&<b>mut</b> rebalance_infos, idx);
        <b>let</b> target_borrow = muldiv(
            remaining_to_allocate,
            strategy_state.target_alloc_weight_bps,
            remaining_total_alloc_bps,
        );
        <b>if</b> (target_borrow &gt;= strategy_state.borrowed) {
            rebalance_info.can_borrow = target_borrow - strategy_state.borrowed;
        } <b>else</b> {
            rebalance_info.to_repay = strategy_state.borrowed - target_borrow;
        };
        i = i + 1;
    };
    <a href="../kai_sav/vault.md#kai_sav_vault_RebalanceAmounts">RebalanceAmounts</a> { inner: rebalance_infos }
}
</code></pre>



</details>

<a name="kai_sav_vault_strategy_repay"></a>

## Function `strategy_repay`

Strategies call this to repay loaned amounts.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_strategy_repay">strategy_repay</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>, balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_strategy_repay">strategy_repay</a>&lt;T, YT&gt;(
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a>,
    balance: Balance&lt;T&gt;,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.withdraw_ticket_issued == <b>false</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawTicketIssued">EWithdrawTicketIssued</a>);
    // amounts are purposefully not checked here because the strategies
    // are trusted to repay the correct amounts based on `<a href="../kai_sav/vault.md#kai_sav_vault_RebalanceInfo">RebalanceInfo</a>`.
    <b>let</b> strategy_id = object::uid_as_inner(&access.id);
    <b>let</b> strategy_state = vec_map::get_mut(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, strategy_id);
    strategy_state.borrowed = strategy_state.borrowed - balance::value(&balance);
    balance::join(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>, balance);
}
</code></pre>



</details>

<a name="kai_sav_vault_strategy_borrow"></a>

## Function `strategy_borrow`

Strategies call this to borrow additional funds from the vault. Always returns
exact amount requested or aborts.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_strategy_borrow">strategy_borrow</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>, amount: u64): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_strategy_borrow">strategy_borrow</a>&lt;T, YT&gt;(
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a>,
    amount: u64,
): Balance&lt;T&gt; {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.withdraw_ticket_issued == <b>false</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawTicketIssued">EWithdrawTicketIssued</a>);
    // amounts are purpusfully not checked here because the strategies
    // are trusted to borrow the correct amounts based on `<a href="../kai_sav/vault.md#kai_sav_vault_RebalanceInfo">RebalanceInfo</a>`.
    <b>let</b> strategy_id = object::uid_as_inner(&access.id);
    <b>let</b> strategy_state = vec_map::get_mut(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, strategy_id);
    <b>let</b> balance = balance::split(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>, amount);
    strategy_state.borrowed = strategy_state.borrowed + amount;
    balance
}
</code></pre>



</details>

<a name="kai_sav_vault_strategy_hand_over_profit"></a>

## Function `strategy_hand_over_profit`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_strategy_hand_over_profit">strategy_hand_over_profit</a>&lt;T, YT&gt;(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>, profit: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/vault.md#kai_sav_vault_strategy_hand_over_profit">strategy_hand_over_profit</a>&lt;T, YT&gt;(
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">Vault</a>&lt;T, YT&gt;,
    access: &<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">VaultAccess</a>,
    profit: Balance&lt;T&gt;,
    clock: &Clock,
) {
    <a href="../kai_sav/vault.md#kai_sav_vault_assert_version">assert_version</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>);
    <b>assert</b>!(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.withdraw_ticket_issued == <b>false</b>, <a href="../kai_sav/vault.md#kai_sav_vault_EWithdrawTicketIssued">EWithdrawTicketIssued</a>);
    <b>let</b> strategy_id = object::uid_as_inner(&access.id);
    <b>assert</b>!(vec_map::contains(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategies, strategy_id), <a href="../kai_sav/vault.md#kai_sav_vault_EInvalidVaultAccess">EInvalidVaultAccess</a>);
    // collect performance fee
    <b>let</b> fee_amt_t = muldiv(
        balance::value(&profit),
        <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.performance_fee_bps,
        <a href="../kai_sav/vault.md#kai_sav_vault_BPS_IN_100_PCT">BPS_IN_100_PCT</a>,
    );
    <b>let</b> fee_amt_yt = <b>if</b> (fee_amt_t &gt; 0) {
        <b>let</b> <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> = <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, clock);
        // dL = L * f / (A - f)
        <b>let</b> fee_amt_yt = muldiv(
            coin::total_supply(&<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury),
            fee_amt_t,
            <a href="../kai_sav/vault.md#kai_sav_vault_total_available_balance">total_available_balance</a> - fee_amt_t,
        );
        <b>let</b> fee_yt = coin::mint_balance(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.lp_treasury, fee_amt_yt);
        balance::join(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.performance_fee_balance, fee_yt);
        fee_amt_yt
    } <b>else</b> {
        0
    };
    event::emit(<a href="../kai_sav/vault.md#kai_sav_vault_StrategyProfitEvent">StrategyProfitEvent</a>&lt;YT&gt; {
        strategy_id: object::uid_to_inner(&access.id),
        profit: balance::value(&profit),
        fee_amt_yt: fee_amt_yt,
    });
    // reset profit unlock
    balance::join(
        &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.<a href="../kai_sav/vault.md#kai_sav_vault_free_balance">free_balance</a>,
        tlb::withdraw_all(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, clock),
    );
    tlb::change_unlock_per_second(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, 0, clock);
    <b>let</b> <b>mut</b> redeposit = tlb::skim_extraneous_balance(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit);
    balance::join(&<b>mut</b> redeposit, profit);
    tlb::change_unlock_start_ts_sec(
        &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit,
        timestamp_sec(clock),
        clock,
    );
    <b>let</b> unlock_per_second = u64::divide_and_round_up(
        balance::value(&redeposit),
        <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.profit_unlock_duration_sec,
    );
    tlb::change_unlock_per_second(
        &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit,
        unlock_per_second,
        clock,
    );
    tlb::top_up(&<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.time_locked_profit, redeposit, clock);
}
</code></pre>



</details>

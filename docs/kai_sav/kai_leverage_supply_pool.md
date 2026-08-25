
<a name="kai_sav_kai_leverage_supply_pool"></a>

# Module `kai_sav::kai_leverage_supply_pool`

Kai Leverage supply pool strategy for SAV integration.
Implements basic compounding of rewards.


-  [Struct `IncentiveInjectInfo`](#kai_sav_kai_leverage_supply_pool_IncentiveInjectInfo)
-  [Struct `AdminCap`](#kai_sav_kai_leverage_supply_pool_AdminCap)
-  [Struct `Strategy`](#kai_sav_kai_leverage_supply_pool_Strategy)
-  [Constants](#@Constants_0)
-  [Function `new`](#kai_sav_kai_leverage_supply_pool_new)
-  [Function `assert_version`](#kai_sav_kai_leverage_supply_pool_assert_version)
-  [Function `admin_cap_id`](#kai_sav_kai_leverage_supply_pool_admin_cap_id)
-  [Function `assert_admin`](#kai_sav_kai_leverage_supply_pool_assert_admin)
-  [Function `join_vault`](#kai_sav_kai_leverage_supply_pool_join_vault)
-  [Function `remove_from_vault`](#kai_sav_kai_leverage_supply_pool_remove_from_vault)
-  [Function `migrate`](#kai_sav_kai_leverage_supply_pool_migrate)
-  [Function `withdraw_leaves_reserve`](#kai_sav_kai_leverage_supply_pool_withdraw_leaves_reserve)
-  [Function `max_withdraw_within_reserve`](#kai_sav_kai_leverage_supply_pool_max_withdraw_within_reserve)
-  [Function `rebalance`](#kai_sav_kai_leverage_supply_pool_rebalance)
-  [Function `skim_base_profits`](#kai_sav_kai_leverage_supply_pool_skim_base_profits)
-  [Function `inject_incentives`](#kai_sav_kai_leverage_supply_pool_inject_incentives)
-  [Function `collect_and_hand_over_profit`](#kai_sav_kai_leverage_supply_pool_collect_and_hand_over_profit)
-  [Function `withdraw`](#kai_sav_kai_leverage_supply_pool_withdraw)


<pre><code><b>use</b> <a href="../dependencies/access_management/access.md#access_management_access">access_management::access</a>;
<b>use</b> <a href="../dependencies/access_management/dynamic_map.md#access_management_dynamic_map">access_management::dynamic_map</a>;
<b>use</b> <a href="../dependencies/kai_leverage/debt.md#kai_leverage_debt">kai_leverage::debt</a>;
<b>use</b> <a href="../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag">kai_leverage::debt_bag</a>;
<b>use</b> <a href="../dependencies/kai_leverage/equity.md#kai_leverage_equity">kai_leverage::equity</a>;
<b>use</b> <a href="../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise">kai_leverage::piecewise</a>;
<b>use</b> <a href="../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool">kai_leverage::supply_pool</a>;
<b>use</b> <a href="../dependencies/kai_leverage/util.md#kai_leverage_util">kai_leverage::util</a>;
<b>use</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance">kai_sav::time_locked_balance</a>;
<b>use</b> <a href="../kai_sav/util.md#kai_sav_util">kai_sav::util</a>;
<b>use</b> <a href="../kai_sav/vault.md#kai_sav_vault">kai_sav::vault</a>;
<b>use</b> <a href="../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter">rate_limiter::net_sliding_sum_limiter</a>;
<b>use</b> <a href="../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator">rate_limiter::ring_aggregator</a>;
<b>use</b> <a href="../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter">rate_limiter::sliding_sum_limiter</a>;
<b>use</b> <a href="../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../dependencies/std/internal.md#std_internal">std::internal</a>;
<b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../dependencies/std/u128.md#std_u128">std::u128</a>;
<b>use</b> <a href="../dependencies/std/u64.md#std_u64">std::u64</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../dependencies/sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../dependencies/sui/accumulator_settlement.md#sui_accumulator_settlement">sui::accumulator_settlement</a>;
<b>use</b> <a href="../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../dependencies/sui/bcs.md#sui_bcs">sui::bcs</a>;
<b>use</b> <a href="../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../dependencies/sui/funds_accumulator.md#sui_funds_accumulator">sui::funds_accumulator</a>;
<b>use</b> <a href="../dependencies/sui/hash.md#sui_hash">sui::hash</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/package.md#sui_package">sui::package</a>;
<b>use</b> <a href="../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../dependencies/sui/protocol_config.md#sui_protocol_config">sui::protocol_config</a>;
<b>use</b> <a href="../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_sav_kai_leverage_supply_pool_IncentiveInjectInfo"></a>

## Struct `IncentiveInjectInfo`

Incentive injection event.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_IncentiveInjectInfo">IncentiveInjectInfo</a> <b>has</b> <b>copy</b>, drop
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
<code>amount: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_kai_leverage_supply_pool_AdminCap"></a>

## Struct `AdminCap`

Administrative capability for strategy management.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a> <b>has</b> key, store
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

<a name="kai_sav_kai_leverage_supply_pool_Strategy"></a>

## Struct `Strategy`

Strategy managing supply pool integration with vault.

Deposits funds from a Kai Single Asset Vault into a Kai Leverage supply pool,
managing deposits, withdrawals, and profit collection while maintaining
proper accounting of shares and underlying values.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;<b>phantom</b> T, <b>phantom</b> ST&gt; <b>has</b> key
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
<code><a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a>: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
 ID of the admin capability that controls this strategy
</dd>
<dt>
<code>vault_access: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>&gt;</code>
</dt>
<dd>
 Vault access token for vault interactions
</dd>
<dt>
<code>entity: <a href="../dependencies/access_management/access.md#access_management_access_Entity">access_management::access::Entity</a></code>
</dt>
<dd>
 Access Management entity for authentication and authorization in Kai Leverage
</dd>
<dt>
<code>shares: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;ST&gt;</code>
</dt>
<dd>
 Balance of supply pool share tokens representing stake in the supply pool
</dd>
<dt>
<code>underlying_nominal_value_t: u64</code>
</dt>
<dd>
 Nominal value of underlying assets deposited to the supply pool
</dd>
<dt>
<code>collected_profit_t: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
 Accumulated profits collected from the supply pool
</dd>
<dt>
<code>version: u64</code>
</dt>
<dd>
 Version number for upgrade compatibility
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_sav_kai_leverage_supply_pool_MODULE_VERSION"></a>



<pre><code><b>const</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>: u64 = 1;
</code></pre>



<a name="kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS"></a>

Fraction of the supply pool's total value, in basis points, that principal withdrawals must
leave in its available balance. Profit skimming is exempt and may draw it down: <code><a href="../kai_sav/vault.md#kai_sav_vault">vault</a></code>
counts strategy principal at cost basis, so a skim that cannot withdraw means the vault
stops recognizing yield altogether.


<pre><code><b>const</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS">WITHDRAW_RESERVE_BPS</a>: u64 = 100;
</code></pre>



<a name="kai_sav_kai_leverage_supply_pool_EInvalidAdmin"></a>

Invalid <code><a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a></code> has been provided for the strategy


<pre><code><b>const</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_EInvalidAdmin">EInvalidAdmin</a>: u64 = 0;
</code></pre>



<a name="kai_sav_kai_leverage_supply_pool_EHasPendingRewards"></a>

The strategy cannot be removed from vault if it has pending rewards


<pre><code><b>const</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_EHasPendingRewards">EHasPendingRewards</a>: u64 = 1;
</code></pre>



<a name="kai_sav_kai_leverage_supply_pool_EWrongVersion"></a>

Calling functions from the wrong package version


<pre><code><b>const</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_EWrongVersion">EWrongVersion</a>: u64 = 2;
</code></pre>



<a name="kai_sav_kai_leverage_supply_pool_ENotUpgrade"></a>

Migration is not an upgrade


<pre><code><b>const</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_ENotUpgrade">ENotUpgrade</a>: u64 = 3;
</code></pre>



<a name="kai_sav_kai_leverage_supply_pool_EInsufficientPoolLiquidity"></a>

The withdrawal would leave the supply pool below its liquidity reserve


<pre><code><b>const</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_EInsufficientPoolLiquidity">EInsufficientPoolLiquidity</a>: u64 = 4;
</code></pre>



<a name="kai_sav_kai_leverage_supply_pool_new"></a>

## Function `new`



<pre><code><b>public</b>(package) <b>entry</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_new">new</a>&lt;T, ST&gt;(_supply_pool: &<a href="../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>entry</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_new">new</a>&lt;T, ST&gt;(_supply_pool: &SupplyPool&lt;T, ST&gt;, ctx: &<b>mut</b> TxContext) {
    <b>let</b> admin_cap = <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a> { id: object::new(ctx) };
    <b>let</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a> = object::id(&admin_cap);
    <b>let</b> entity = access::create_entity(ctx);
    <b>let</b> strategy = <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt; {
        id: object::new(ctx),
        <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a>,
        vault_access: option::none(),
        entity,
        shares: balance::zero(),
        underlying_nominal_value_t: 0,
        collected_profit_t: balance::zero(),
        version: <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>,
    };
    transfer::share_object(strategy);
    transfer::transfer(
        admin_cap,
        tx_context::sender(ctx),
    );
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_assert_version"></a>

## Function `assert_version`



<pre><code><b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_version">assert_version</a>&lt;T, ST&gt;(strategy: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_version">assert_version</a>&lt;T, ST&gt;(strategy: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;) {
    <b>assert</b>!(strategy.version == <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>, <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_EWrongVersion">EWrongVersion</a>);
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_admin_cap_id"></a>

## Function `admin_cap_id`

Get the admin capability ID from strategy.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a>&lt;T, ST&gt;(strategy: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;): <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a>&lt;T, ST&gt;(strategy: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;): ID {
    strategy.<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a>
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_assert_admin"></a>

## Function `assert_admin`



<pre><code><b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_admin">assert_admin</a>&lt;T, ST&gt;(cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">kai_sav::kai_leverage_supply_pool::AdminCap</a>, strategy: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_admin">assert_admin</a>&lt;T, ST&gt;(cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a>, strategy: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;) {
    <b>let</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a> = object::id(cap);
    <b>assert</b>!(<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a> == strategy.<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_admin_cap_id">admin_cap_id</a>, <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_EInvalidAdmin">EInvalidAdmin</a>);
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_join_vault"></a>

## Function `join_vault`

Join the strategy to a vault.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_join_vault">join_vault</a>&lt;T, ST, YT&gt;(strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;, strategy_cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">kai_sav::kai_leverage_supply_pool::AdminCap</a>, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, vault_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;YT&gt;, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_join_vault">join_vault</a>&lt;T, ST, YT&gt;(
    strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;,
    strategy_cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a>,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> Vault&lt;T, YT&gt;,
    vault_cap: &VaultAdminCap&lt;YT&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_version">assert_version</a>(strategy);
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_admin">assert_admin</a>(strategy_cap, strategy);
    <b>let</b> access = <a href="../kai_sav/vault.md#kai_sav_vault_add_strategy">vault::add_strategy</a>(vault_cap, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, ctx);
    strategy.vault_access.fill(access); // aborts <b>if</b> `is_some`
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_remove_from_vault"></a>

## Function `remove_from_vault`

Remove strategy from vault and return removal ticket.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_remove_from_vault">remove_from_vault</a>&lt;T, ST, YT&gt;(strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;, cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">kai_sav::kai_leverage_supply_pool::AdminCap</a>, supply_pool: &<b>mut</b> <a href="../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">kai_sav::vault::StrategyRemovalTicket</a>&lt;T, YT&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_remove_from_vault">remove_from_vault</a>&lt;T, ST, YT&gt;(
    strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;,
    cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a>,
    supply_pool: &<b>mut</b> SupplyPool&lt;T, ST&gt;,
    clock: &Clock,
): StrategyRemovalTicket&lt;T, YT&gt; {
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_admin">assert_admin</a>(cap, strategy);
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_version">assert_version</a>(strategy);
    <b>assert</b>!(balance::value(&strategy.collected_profit_t) == 0, <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_EHasPendingRewards">EHasPendingRewards</a>);
    // Full teardown, so the withdrawal reserve is not enforced. Doing so would make the
    // strategy unremovable whenever the pool <b>has</b> any utilization at all.
    <b>let</b> redeemed_balance = supply_pool.<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw">withdraw</a>(strategy.shares.withdraw_all(), clock);
    strategy.underlying_nominal_value_t = 0;
    <a href="../kai_sav/vault.md#kai_sav_vault_new_strategy_removal_ticket">vault::new_strategy_removal_ticket</a>(
        option::extract(&<b>mut</b> strategy.vault_access),
        redeemed_balance,
    )
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_migrate"></a>

## Function `migrate`

Migrate strategy to current module version.


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_migrate">migrate</a>&lt;T, ST&gt;(cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">kai_sav::kai_leverage_supply_pool::AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_migrate">migrate</a>&lt;T, ST&gt;(cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;) {
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_admin">assert_admin</a>(cap, strategy);
    <b>assert</b>!(strategy.version &lt; <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>, <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_ENotUpgrade">ENotUpgrade</a>);
    strategy.version = <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>;
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_withdraw_leaves_reserve"></a>

## Function `withdraw_leaves_reserve`

Whether withdrawing <code>amount</code> leaves at least <code><a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS">WITHDRAW_RESERVE_BPS</a></code> of the pool's total
value available. <code>available</code> and <code>liabilities</code> describe the pool before the withdrawal.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw_leaves_reserve">withdraw_leaves_reserve</a>(available: u64, liabilities: u128, amount: u64): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw_leaves_reserve">withdraw_leaves_reserve</a>(available: u64, liabilities: u128, amount: u64): bool {
    // Never breaches the reserve, even <b>if</b> skimming <b>has</b> already taken the pool below it.
    <b>if</b> (amount == 0) {
        <b>return</b> <b>true</b>
    };
    <b>if</b> (available &lt; amount) {
        <b>return</b> <b>false</b>
    };
    // Equivalent to capping post-withdrawal utilization at `10000 - <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS">WITHDRAW_RESERVE_BPS</a>`:
    // the withdrawal lowers available and total value alike, and leaves liabilities untouched.
    <b>let</b> available_after = (available - amount) <b>as</b> u128;
    <b>let</b> total_value_after = available_after + liabilities;
    <b>let</b> reserve = total_value_after * (<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS">WITHDRAW_RESERVE_BPS</a> <b>as</b> u128) / 10000;
    available_after &gt;= reserve
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_max_withdraw_within_reserve"></a>

## Function `max_withdraw_within_reserve`

The largest amount withdrawable from a pool holding <code>available</code> with <code>liabilities</code> out on
loan that still leaves the reserve. Zero if the pool is already at or below it.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_max_withdraw_within_reserve">max_withdraw_within_reserve</a>(available: u64, liabilities: u128): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_max_withdraw_within_reserve">max_withdraw_within_reserve</a>(available: u64, liabilities: u128): u64 {
    // Solves `available_after * (10000 - <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS">WITHDRAW_RESERVE_BPS</a>) &gt;= liabilities *
    // <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS">WITHDRAW_RESERVE_BPS</a>`, rounding up so the result never breaches the reserve.
    <b>let</b> bps = <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS">WITHDRAW_RESERVE_BPS</a> <b>as</b> u128;
    <b>let</b> min_available = u128::div_ceil(liabilities * bps, 10000 - bps);
    // The result is bounded by `available`, so the downcast is lossless.
    u128::saturating_sub(available <b>as</b> u128, min_available) <b>as</b> u64
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_rebalance"></a>

## Function `rebalance`

Rebalance strategy position based on vault requirements.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_rebalance">rebalance</a>&lt;T, ST, YT&gt;(strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;, cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">kai_sav::kai_leverage_supply_pool::AdminCap</a>, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, amounts: &<a href="../kai_sav/vault.md#kai_sav_vault_RebalanceAmounts">kai_sav::vault::RebalanceAmounts</a>, supply_pool: &<b>mut</b> <a href="../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, policy: &<a href="../dependencies/access_management/access.md#access_management_access_Policy">access_management::access::Policy</a>, rule_id: <b>address</b>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_rebalance">rebalance</a>&lt;T, ST, YT&gt;(
    strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;,
    cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a>,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> Vault&lt;T, YT&gt;,
    amounts: &RebalanceAmounts,
    supply_pool: &<b>mut</b> SupplyPool&lt;T, ST&gt;,
    policy: &Policy,
    rule_id: <b>address</b>,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_admin">assert_admin</a>(cap, strategy);
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_version">assert_version</a>(strategy);
    <b>let</b> vault_access = option::borrow(&strategy.vault_access);
    <b>let</b> (can_borrow, to_repay) = <a href="../kai_sav/vault.md#kai_sav_vault_rebalance_amounts_get">vault::rebalance_amounts_get</a>(amounts, vault_access);
    <b>if</b> (to_repay &gt; 0) {
        <b>let</b> redeem_st_amt = muldiv(
            strategy.shares.value(),
            to_repay,
            strategy.underlying_nominal_value_t,
        );
        // Clamped rather than aborted: `<a href="../kai_sav/vault.md#kai_sav_vault_strategy_repay">vault::strategy_repay</a>` reduces `borrowed` by the
        // amount actually repaid, so a short repayment stays exactly accounted and the rest is
        // repaid on a later <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_rebalance">rebalance</a>. Aborting would fail the whole <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_rebalance">rebalance</a> transaction,
        // which batches every <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>. `calc_withdraw_by_shares` also accrues interest, so the
        // pool state read below is current.
        <b>let</b> withdraw_amt = supply_pool.calc_withdraw_by_shares(redeem_st_amt, clock);
        <b>let</b> max_withdraw_amt = <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_max_withdraw_within_reserve">max_withdraw_within_reserve</a>(
            supply_pool.available_balance_value(),
            supply_pool.total_liabilities_x64() &gt;&gt; 64,
        );
        <b>let</b> redeem_st_amt = <b>if</b> (withdraw_amt &gt; max_withdraw_amt) {
            <b>let</b> (share_amt, _) = supply_pool.calc_withdraw_by_amount(max_withdraw_amt, clock);
            // redeem 1 share less to avoid withdrawing more than `max_withdraw_amt` due to
            // rounding in `calc_withdraw_by_amount`
            u64::max(share_amt, 1) - 1
        } <b>else</b> {
            redeem_st_amt
        };
        <b>if</b> (redeem_st_amt == 0) {
            <b>return</b>
        };
        <b>let</b> <b>mut</b> redeemed_balance_t = supply_pool.<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw">withdraw</a>(
            strategy.shares.split(redeem_st_amt),
            clock,
        );
        <b>if</b> (redeemed_balance_t.value() &gt; to_repay) {
            <b>let</b> extra_amt = redeemed_balance_t.value() - to_repay;
            strategy.collected_profit_t.join(redeemed_balance_t.split(extra_amt));
        };
        <b>let</b> repaid = redeemed_balance_t.value();
        <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_repay(vault_access, redeemed_balance_t);
        strategy.underlying_nominal_value_t = strategy.underlying_nominal_value_t - repaid;
    } <b>else</b> <b>if</b> (can_borrow &gt; 0) {
        <b>let</b> borrow_amt = u64::min(can_borrow, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.free_balance());
        <b>let</b> borrowed = <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>.strategy_borrow(vault_access, borrow_amt);
        <b>let</b> (new_shares, action_request) = supply_pool.supply(borrowed, clock, ctx);
        access::approve_request(action_request, &strategy.entity, policy, rule_id);
        strategy.shares.join(new_shares);
        strategy.underlying_nominal_value_t = strategy.underlying_nominal_value_t + borrow_amt;
    }
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_skim_base_profits"></a>

## Function `skim_base_profits`

Skim the profits earned on base APY.


<pre><code><b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_skim_base_profits">skim_base_profits</a>&lt;T, ST&gt;(strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;, supply_pool: &<b>mut</b> <a href="../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_skim_base_profits">skim_base_profits</a>&lt;T, ST&gt;(
    strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;T, ST&gt;,
    clock: &Clock,
) {
    <b>let</b> share_value = supply_pool.calc_withdraw_by_shares(strategy.shares.value(), clock);
    <b>if</b> (share_value &gt; strategy.underlying_nominal_value_t) {
        // Skim at most what the pool can pay out, otherwise the split below underflows and
        // aborts. The rest stays in `strategy.shares`, keeps accruing, and is skimmed once
        // liquidity returns; `underlying_nominal_value_t` is untouched, so deferring loses no
        // profit. Deliberately ignores `<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_WITHDRAW_RESERVE_BPS">WITHDRAW_RESERVE_BPS</a>` — the skim is the path the
        // reserve exists to keep alive.
        <b>let</b> profit_amt = u64::min(
            share_value - strategy.underlying_nominal_value_t,
            supply_pool.available_balance_value(),
        );
        <b>if</b> (profit_amt == 0) {
            <b>return</b>
        };
        <b>let</b> (redeem_share_amount, _) = supply_pool.calc_withdraw_by_amount(profit_amt, clock);
        // redeem 1 share less to avoid withdrawing more than `profit_amt` due to rounding
        // in `calc_withdraw_by_amount`
        <b>let</b> redeem_share_amount = u64::max(redeem_share_amount, 1) - 1;
        <b>let</b> redeemed_balance = supply_pool.<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw">withdraw</a>(
            strategy.shares.split(redeem_share_amount),
            clock,
        );
        strategy.collected_profit_t.join(redeemed_balance);
    }
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_inject_incentives"></a>

## Function `inject_incentives`

Inject incentives into the strategy.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_inject_incentives">inject_incentives</a>&lt;T, ST&gt;(strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;, balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_inject_incentives">inject_incentives</a>&lt;T, ST&gt;(strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;, balance: Balance&lt;T&gt;) {
    event::emit(<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_IncentiveInjectInfo">IncentiveInjectInfo</a> {
        strategy_id: strategy.id.to_inner(),
        amount: balance.value(),
    });
    strategy.collected_profit_t.join(balance);
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_collect_and_hand_over_profit"></a>

## Function `collect_and_hand_over_profit`

Collect profits and transfer to vault.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_collect_and_hand_over_profit">collect_and_hand_over_profit</a>&lt;T, ST, YT&gt;(strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;, cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">kai_sav::kai_leverage_supply_pool::AdminCap</a>, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;T, YT&gt;, supply_pool: &<b>mut</b> <a href="../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_collect_and_hand_over_profit">collect_and_hand_over_profit</a>&lt;T, ST, YT&gt;(
    strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;,
    cap: &<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_AdminCap">AdminCap</a>,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> Vault&lt;T, YT&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;T, ST&gt;,
    clock: &Clock,
) {
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_admin">assert_admin</a>(cap, strategy);
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_version">assert_version</a>(strategy);
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_skim_base_profits">skim_base_profits</a>(strategy, supply_pool, clock);
    <b>let</b> profit = strategy.collected_profit_t.withdraw_all();
    <b>let</b> vault_access = strategy.vault_access.borrow();
    <a href="../kai_sav/vault.md#kai_sav_vault_strategy_hand_over_profit">vault::strategy_hand_over_profit</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, vault_access, profit, clock);
}
</code></pre>



</details>

<a name="kai_sav_kai_leverage_supply_pool_withdraw"></a>

## Function `withdraw`

Process withdrawal request from vault.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw">withdraw</a>&lt;T, ST, YT&gt;(strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">kai_sav::kai_leverage_supply_pool::Strategy</a>&lt;T, ST&gt;, ticket: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">kai_sav::vault::WithdrawTicket</a>&lt;T, YT&gt;, supply_pool: &<b>mut</b> <a href="../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw">withdraw</a>&lt;T, ST, YT&gt;(
    strategy: &<b>mut</b> <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_Strategy">Strategy</a>&lt;T, ST&gt;,
    ticket: &<b>mut</b> WithdrawTicket&lt;T, YT&gt;,
    supply_pool: &<b>mut</b> SupplyPool&lt;T, ST&gt;,
    clock: &Clock,
) {
    <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_assert_version">assert_version</a>(strategy);
    <b>let</b> vault_access = strategy.vault_access.borrow();
    <b>let</b> to_withdraw = <a href="../kai_sav/vault.md#kai_sav_vault_withdraw_ticket_to_withdraw">vault::withdraw_ticket_to_withdraw</a>(ticket, vault_access);
    <b>if</b> (to_withdraw == 0) {
        <b>return</b>
    };
    <b>let</b> redeem_st_amt = muldiv(
        strategy.shares.value(),
        to_withdraw,
        strategy.underlying_nominal_value_t,
    );
    // Aborts rather than filling partially on purpose: `<a href="../kai_sav/vault.md#kai_sav_vault_redeem_withdraw_ticket">vault::redeem_withdraw_ticket</a>` treats
    // a short fill <b>as</b> a `StrategyLossEvent` charged to the redeeming user, which would turn a
    // liquidity limit into a realized loss. `calc_withdraw_by_shares` also accrues interest,
    // so the state the check reads is current.
    <b>let</b> withdraw_amt = supply_pool.calc_withdraw_by_shares(redeem_st_amt, clock);
    <b>let</b> leaves_reserve = <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw_leaves_reserve">withdraw_leaves_reserve</a>(
        supply_pool.available_balance_value(),
        supply_pool.total_liabilities_x64() &gt;&gt; 64,
        withdraw_amt,
    );
    <b>assert</b>!(leaves_reserve, <a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_EInsufficientPoolLiquidity">EInsufficientPoolLiquidity</a>);
    <b>let</b> <b>mut</b> redeemed_balance_t = supply_pool.<a href="../kai_sav/kai_leverage_supply_pool.md#kai_sav_kai_leverage_supply_pool_withdraw">withdraw</a>(
        strategy.shares.split(redeem_st_amt),
        clock,
    );
    <b>if</b> (redeemed_balance_t.value() &gt; to_withdraw) {
        <b>let</b> profit_amt = redeemed_balance_t.value() - to_withdraw;
        strategy.collected_profit_t.join(redeemed_balance_t.split(profit_amt));
    };
    <a href="../kai_sav/vault.md#kai_sav_vault_strategy_withdraw_to_ticket">vault::strategy_withdraw_to_ticket</a>(ticket, vault_access, redeemed_balance_t);
    // `to_withdraw` amount is used intentionally here instead of the actual amount which
    // can be lower in some cases (see comments in `<a href="../kai_sav/vault.md#kai_sav_vault_redeem_withdraw_ticket">vault::redeem_withdraw_ticket</a>`)
    strategy.underlying_nominal_value_t = strategy.underlying_nominal_value_t - to_withdraw;
}
</code></pre>



</details>

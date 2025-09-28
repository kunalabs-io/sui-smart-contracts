
<a name="kai_sav_scallop_sui_proper"></a>

# Module `kai_sav::scallop_sui_proper`

SAV strategy integrating Scallop SUI staking with Kai vaults.


-  [Struct `AdminCap`](#kai_sav_scallop_sui_proper_AdminCap)
-  [Struct `Strategy`](#kai_sav_scallop_sui_proper_Strategy)
-  [Constants](#@Constants_0)
-  [Function `assert_scallop_pool`](#kai_sav_scallop_sui_proper_assert_scallop_pool)
-  [Function `new`](#kai_sav_scallop_sui_proper_new)
-  [Function `assert_version`](#kai_sav_scallop_sui_proper_assert_version)
-  [Function `assert_admin`](#kai_sav_scallop_sui_proper_assert_admin)
-  [Function `join_vault`](#kai_sav_scallop_sui_proper_join_vault)
-  [Function `assert_scallop_market`](#kai_sav_scallop_sui_proper_assert_scallop_market)
-  [Function `assert_scallop_rewards_pool`](#kai_sav_scallop_sui_proper_assert_scallop_rewards_pool)
-  [Function `remove_from_vault`](#kai_sav_scallop_sui_proper_remove_from_vault)
-  [Function `migrate`](#kai_sav_scallop_sui_proper_migrate)
-  [Function `rebalance`](#kai_sav_scallop_sui_proper_rebalance)
-  [Function `skim_base_profits`](#kai_sav_scallop_sui_proper_skim_base_profits)
-  [Function `collect_and_hand_over_profit`](#kai_sav_scallop_sui_proper_collect_and_hand_over_profit)
-  [Function `withdraw`](#kai_sav_scallop_sui_proper_withdraw)


<pre><code><b>use</b> <a href="../dependencies/779b5c547976899f5474f3a5bc0db36ddf4697ad7e5a901db0415c2281d28162/ac_table.md#0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162_ac_table">0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ac_table</a>;
<b>use</b> <a href="../dependencies/779b5c547976899f5474f3a5bc0db36ddf4697ad7e5a901db0415c2281d28162/balance_bag.md#0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162_balance_bag">0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::balance_bag</a>;
<b>use</b> <a href="../dependencies/779b5c547976899f5474f3a5bc0db36ddf4697ad7e5a901db0415c2281d28162/one_time_lock_value.md#0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162_one_time_lock_value">0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::one_time_lock_value</a>;
<b>use</b> <a href="../dependencies/779b5c547976899f5474f3a5bc0db36ddf4697ad7e5a901db0415c2281d28162/ownership.md#0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162_ownership">0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ownership</a>;
<b>use</b> <a href="../dependencies/779b5c547976899f5474f3a5bc0db36ddf4697ad7e5a901db0415c2281d28162/supply_bag.md#0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162_supply_bag">0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::supply_bag</a>;
<b>use</b> <a href="../dependencies/779b5c547976899f5474f3a5bc0db36ddf4697ad7e5a901db0415c2281d28162/wit_table.md#0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162_wit_table">0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table</a>;
<b>use</b> <a href="../dependencies/779b5c547976899f5474f3a5bc0db36ddf4697ad7e5a901db0415c2281d28162/witness.md#0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162_witness">0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::witness</a>;
<b>use</b> <a href="../dependencies/scallop_pool/rewards_pool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_rewards_pool">0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::rewards_pool</a>;
<b>use</b> <a href="../dependencies/scallop_pool/spool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool">0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool</a>;
<b>use</b> <a href="../dependencies/scallop_pool/spool_account.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_account">0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::spool_account</a>;
<b>use</b> <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user">0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A::user</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/asset_active_state.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_asset_active_state">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::asset_active_state</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/borrow_dynamics.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_borrow_dynamics">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow_dynamics</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/collateral_stats.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_collateral_stats">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::collateral_stats</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/incentive_rewards.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_incentive_rewards">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::incentive_rewards</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/interest_model.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_interest_model">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::interest_model</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/limiter.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_limiter">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::limiter</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/market.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_market">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/mint.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_mint">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::mint</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/redeem.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_redeem">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::redeem</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/reserve.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_reserve">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::reserve</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/risk_model.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_risk_model">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::risk_model</a>;
<b>use</b> <a href="../dependencies/scallop_protocol/version.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_version">0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::version</a>;
<b>use</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance">kai_sav::time_locked_balance</a>;
<b>use</b> <a href="../kai_sav/util.md#kai_sav_util">kai_sav::util</a>;
<b>use</b> <a href="../kai_sav/vault.md#kai_sav_vault">kai_sav::vault</a>;
<b>use</b> <a href="../dependencies/kai_ywhusdte_ysui/ysui.md#kai_ywhusdte_ysui_ysui">kai_ywhusdte_ysui::ysui</a>;
<b>use</b> <a href="../dependencies/rate_limiter/net_sliding_sum_limiter.md#rate_limiter_net_sliding_sum_limiter">rate_limiter::net_sliding_sum_limiter</a>;
<b>use</b> <a href="../dependencies/rate_limiter/ring_aggregator.md#rate_limiter_ring_aggregator">rate_limiter::ring_aggregator</a>;
<b>use</b> <a href="../dependencies/rate_limiter/sliding_sum_limiter.md#rate_limiter_sliding_sum_limiter">rate_limiter::sliding_sum_limiter</a>;
<b>use</b> <a href="../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../dependencies/std/fixed_point32.md#std_fixed_point32">std::fixed_point32</a>;
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
<b>use</b> <a href="../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_sav_scallop_sui_proper_AdminCap"></a>

## Struct `AdminCap`



<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a> <b>has</b> key, store
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

<a name="kai_sav_scallop_sui_proper_Strategy"></a>

## Struct `Strategy`



<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a> <b>has</b> key
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
<code>admin_cap_id: <a href="../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>vault_access: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../kai_sav/vault.md#kai_sav_vault_VaultAccess">kai_sav::vault::VaultAccess</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>scallop_pool_acc: <a href="../dependencies/scallop_pool/spool_account.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_account_SpoolAccount">scallop_pool::spool_account::SpoolAccount</a>&lt;<a href="../dependencies/scallop_protocol/reserve.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_reserve_MarketCoin">scallop_protocol::reserve::MarketCoin</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>underlying_nominal_value_sui: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>collected_profit_sui: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;</code>
</dt>
<dd>
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


<a name="kai_sav_scallop_sui_proper_MODULE_VERSION"></a>



<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_MODULE_VERSION">MODULE_VERSION</a>: u64 = 1;
</code></pre>



<a name="kai_sav_scallop_sui_proper_SCALLOP_POOL_ID"></a>



<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_SCALLOP_POOL_ID">SCALLOP_POOL_ID</a>: <b>address</b> = 0x4f0ba970d3c11db05c8f40c64a15b6a33322db3702d634ced6536960ab6f3ee4;
</code></pre>



<a name="kai_sav_scallop_sui_proper_SCALLOP_MARKET_ID"></a>



<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_SCALLOP_MARKET_ID">SCALLOP_MARKET_ID</a>: <b>address</b> = 0xa757975255146dc9686aa823b7838b507f315d704f428cbadad2f4ea061939d9;
</code></pre>



<a name="kai_sav_scallop_sui_proper_SCALLOP_REWARDS_POOL_ID"></a>



<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_SCALLOP_REWARDS_POOL_ID">SCALLOP_REWARDS_POOL_ID</a>: <b>address</b> = 0x162250ef72393a4ad3d46294c4e1bdfcb03f04c869d390e7efbfc995353a7ee9;
</code></pre>



<a name="kai_sav_scallop_sui_proper_EInvalidAdmin"></a>

Invalid <code><a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a></code> has been provided for the strategy


<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EInvalidAdmin">EInvalidAdmin</a>: u64 = 0;
</code></pre>



<a name="kai_sav_scallop_sui_proper_EInvalidScallopPool"></a>

Invalid Scallop pool ID provided


<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EInvalidScallopPool">EInvalidScallopPool</a>: u64 = 1;
</code></pre>



<a name="kai_sav_scallop_sui_proper_EInvalidScallopMarket"></a>

Invalid Scallop market ID provided


<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EInvalidScallopMarket">EInvalidScallopMarket</a>: u64 = 2;
</code></pre>



<a name="kai_sav_scallop_sui_proper_EHasPendingRewards"></a>

The strategy cannot be removed from vault if it has pending rewards


<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EHasPendingRewards">EHasPendingRewards</a>: u64 = 3;
</code></pre>



<a name="kai_sav_scallop_sui_proper_EWrongVersion"></a>

Calling functions from the wrong package version


<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EWrongVersion">EWrongVersion</a>: u64 = 4;
</code></pre>



<a name="kai_sav_scallop_sui_proper_ENotUpgrade"></a>

Migration is not an upgrade


<pre><code><b>const</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_ENotUpgrade">ENotUpgrade</a>: u64 = 5;
</code></pre>



<a name="kai_sav_scallop_sui_proper_assert_scallop_pool"></a>

## Function `assert_scallop_pool`



<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_pool">assert_scallop_pool</a>(pool: &<a href="../dependencies/scallop_pool/spool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_Spool">scallop_pool::spool::Spool</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_pool">assert_scallop_pool</a>(pool: &ScallopPool) {
    <b>assert</b>!(object::id_address(pool) == <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_SCALLOP_POOL_ID">SCALLOP_POOL_ID</a>, <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EInvalidScallopPool">EInvalidScallopPool</a>);
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_new"></a>

## Function `new`



<pre><code><b>public</b>(package) <b>entry</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_new">new</a>(scallop_pool: &<b>mut</b> <a href="../dependencies/scallop_pool/spool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_Spool">scallop_pool::spool::Spool</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>entry</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_new">new</a>(scallop_pool: &<b>mut</b> ScallopPool, clock: &Clock, ctx: &<b>mut</b> TxContext) {
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_pool">assert_scallop_pool</a>(scallop_pool);
    <b>let</b> admin_cap = <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a> { id: object::new(ctx) };
    <b>let</b> admin_cap_id = object::id(&admin_cap);
    <b>let</b> scallop_pool_acc = <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_new_spool_account">scallop_pool::user::new_spool_account</a>(scallop_pool, clock, ctx);
    <b>let</b> strategy = <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a> {
        id: object::new(ctx),
        admin_cap_id,
        vault_access: option::none(),
        scallop_pool_acc,
        underlying_nominal_value_sui: 0,
        collected_profit_sui: balance::zero(),
        version: <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_MODULE_VERSION">MODULE_VERSION</a>,
    };
    transfer::share_object(strategy);
    transfer::transfer(
        admin_cap,
        tx_context::sender(ctx),
    );
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_assert_version"></a>

## Function `assert_version`



<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_version">assert_version</a>(strategy: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_version">assert_version</a>(strategy: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>) {
    <b>assert</b>!(strategy.version == <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_MODULE_VERSION">MODULE_VERSION</a>, <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EWrongVersion">EWrongVersion</a>);
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_assert_admin"></a>

## Function `assert_admin`



<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_admin">assert_admin</a>(cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">kai_sav::scallop_sui_proper::AdminCap</a>, strategy: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_admin">assert_admin</a>(cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a>, strategy: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>) {
    <b>let</b> admin_cap_id = object::id(cap);
    <b>assert</b>!(admin_cap_id == strategy.admin_cap_id, <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EInvalidAdmin">EInvalidAdmin</a>);
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_join_vault"></a>

## Function `join_vault`



<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_join_vault">join_vault</a>(vault_cap: &<a href="../kai_sav/vault.md#kai_sav_vault_AdminCap">kai_sav::vault::AdminCap</a>&lt;<a href="../dependencies/kai_ywhusdte_ysui/ysui.md#kai_ywhusdte_ysui_ysui_YSUI">kai_ywhusdte_ysui::ysui::YSUI</a>&gt;, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>, <a href="../dependencies/kai_ywhusdte_ysui/ysui.md#kai_ywhusdte_ysui_ysui_YSUI">kai_ywhusdte_ysui::ysui::YSUI</a>&gt;, strategy_cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">kai_sav::scallop_sui_proper::AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_join_vault">join_vault</a>(
    vault_cap: &VaultAdminCap&lt;YSUI&gt;,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> Vault&lt;SUI, YSUI&gt;,
    strategy_cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a>,
    strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_version">assert_version</a>(strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_admin">assert_admin</a>(strategy_cap, strategy);
    <b>let</b> access = <a href="../kai_sav/vault.md#kai_sav_vault_add_strategy">vault::add_strategy</a>(vault_cap, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, ctx);
    option::fill(&<b>mut</b> strategy.vault_access, access); // aborts <b>if</b> `is_some`
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_assert_scallop_market"></a>

## Function `assert_scallop_market`



<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_market">assert_scallop_market</a>(market: &<a href="../dependencies/scallop_protocol/market.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_market_Market">scallop_protocol::market::Market</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_market">assert_scallop_market</a>(market: &ScallopMarket) {
    <b>assert</b>!(object::id_address(market) == <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_SCALLOP_MARKET_ID">SCALLOP_MARKET_ID</a>, <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EInvalidScallopMarket">EInvalidScallopMarket</a>);
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_assert_scallop_rewards_pool"></a>

## Function `assert_scallop_rewards_pool`



<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_rewards_pool">assert_scallop_rewards_pool</a>(pool: &<a href="../dependencies/scallop_pool/rewards_pool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_rewards_pool_RewardsPool">scallop_pool::rewards_pool::RewardsPool</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_rewards_pool">assert_scallop_rewards_pool</a>(pool: &ScallopRewardsPool&lt;SUI&gt;) {
    <b>assert</b>!(object::id_address(pool) == <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_SCALLOP_REWARDS_POOL_ID">SCALLOP_REWARDS_POOL_ID</a>, <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EInvalidScallopMarket">EInvalidScallopMarket</a>);
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_remove_from_vault"></a>

## Function `remove_from_vault`



<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_remove_from_vault">remove_from_vault</a>(cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">kai_sav::scallop_sui_proper::AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>, scallop_version: &<a href="../dependencies/scallop_protocol/version.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_version_Version">scallop_protocol::version::Version</a>, scallop_market: &<b>mut</b> <a href="../dependencies/scallop_protocol/market.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_market_Market">scallop_protocol::market::Market</a>, scallop_pool: &<b>mut</b> <a href="../dependencies/scallop_pool/spool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_Spool">scallop_pool::spool::Spool</a>, scallop_rewards_pool: &<b>mut</b> <a href="../dependencies/scallop_pool/rewards_pool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_rewards_pool_RewardsPool">scallop_pool::rewards_pool::RewardsPool</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../kai_sav/vault.md#kai_sav_vault_StrategyRemovalTicket">kai_sav::vault::StrategyRemovalTicket</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>, <a href="../dependencies/kai_ywhusdte_ysui/ysui.md#kai_ywhusdte_ysui_ysui_YSUI">kai_ywhusdte_ysui::ysui::YSUI</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_remove_from_vault">remove_from_vault</a>(
    cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a>,
    strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>,
    scallop_version: &ScallopVersion,
    scallop_market: &<b>mut</b> ScallopMarket,
    scallop_pool: &<b>mut</b> ScallopPool,
    scallop_rewards_pool: &<b>mut</b> ScallopRewardsPool&lt;SUI&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): StrategyRemovalTicket&lt;SUI, YSUI&gt; {
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_admin">assert_admin</a>(cap, strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_version">assert_version</a>(strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_market">assert_scallop_market</a>(scallop_market);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_pool">assert_scallop_pool</a>(scallop_pool);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_rewards_pool">assert_scallop_rewards_pool</a>(scallop_rewards_pool);
    <b>let</b> rewards = <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_redeem_rewards">scallop_pool::user::redeem_rewards</a>(
        scallop_pool,
        scallop_rewards_pool,
        &<b>mut</b> strategy.scallop_pool_acc,
        clock,
        ctx,
    );
    <b>assert</b>!(coin::value(&rewards) == 0, <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EHasPendingRewards">EHasPendingRewards</a>);
    <b>assert</b>!(balance::value(&strategy.collected_profit_sui) == 0, <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_EHasPendingRewards">EHasPendingRewards</a>);
    coin::destroy_zero(rewards);
    <b>let</b> amount_ssui = <a href="../dependencies/scallop_pool/spool_account.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_account_stake_amount">scallop_pool::spool_account::stake_amount</a>(&strategy.scallop_pool_acc);
    <b>let</b> unstaked_ssui = <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_unstake">scallop_pool::user::unstake</a>(
        scallop_pool,
        &<b>mut</b> strategy.scallop_pool_acc,
        amount_ssui,
        clock,
        ctx,
    );
    <b>let</b> redeemed_coin = <a href="../dependencies/scallop_protocol/redeem.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_redeem_redeem">scallop_protocol::redeem::redeem</a>(
        scallop_version,
        scallop_market,
        unstaked_ssui,
        clock,
        ctx,
    );
    <b>let</b> returned_balance = coin::into_balance(redeemed_coin);
    strategy.underlying_nominal_value_sui = 0;
    <a href="../kai_sav/vault.md#kai_sav_vault_new_strategy_removal_ticket">vault::new_strategy_removal_ticket</a>(
        option::extract(&<b>mut</b> strategy.vault_access),
        returned_balance,
    )
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_migrate"></a>

## Function `migrate`



<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_migrate">migrate</a>(cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">kai_sav::scallop_sui_proper::AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>entry</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_migrate">migrate</a>(cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>) {
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_admin">assert_admin</a>(cap, strategy);
    <b>assert</b>!(strategy.version &lt; <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_MODULE_VERSION">MODULE_VERSION</a>, <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_ENotUpgrade">ENotUpgrade</a>);
    strategy.version = <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_MODULE_VERSION">MODULE_VERSION</a>;
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_rebalance"></a>

## Function `rebalance`



<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_rebalance">rebalance</a>(cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">kai_sav::scallop_sui_proper::AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>, <a href="../dependencies/kai_ywhusdte_ysui/ysui.md#kai_ywhusdte_ysui_ysui_YSUI">kai_ywhusdte_ysui::ysui::YSUI</a>&gt;, amounts: &<a href="../kai_sav/vault.md#kai_sav_vault_RebalanceAmounts">kai_sav::vault::RebalanceAmounts</a>, scallop_version: &<a href="../dependencies/scallop_protocol/version.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_version_Version">scallop_protocol::version::Version</a>, scallop_market: &<b>mut</b> <a href="../dependencies/scallop_protocol/market.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_market_Market">scallop_protocol::market::Market</a>, scallop_pool: &<b>mut</b> <a href="../dependencies/scallop_pool/spool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_Spool">scallop_pool::spool::Spool</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_rebalance">rebalance</a>(
    cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a>,
    strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> Vault&lt;SUI, YSUI&gt;,
    amounts: &RebalanceAmounts,
    scallop_version: &ScallopVersion,
    scallop_market: &<b>mut</b> ScallopMarket,
    scallop_pool: &<b>mut</b> ScallopPool,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_admin">assert_admin</a>(cap, strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_version">assert_version</a>(strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_market">assert_scallop_market</a>(scallop_market);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_pool">assert_scallop_pool</a>(scallop_pool);
    <b>let</b> vault_access = option::borrow(&strategy.vault_access);
    <b>let</b> (can_borrow, to_repay) = <a href="../kai_sav/vault.md#kai_sav_vault_rebalance_amounts_get">vault::rebalance_amounts_get</a>(amounts, vault_access);
    <b>if</b> (to_repay &gt; 0) {
        <b>let</b> staked_amount_ssui = <a href="../dependencies/scallop_pool/spool_account.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_account_stake_amount">scallop_pool::spool_account::stake_amount</a>(
            &strategy.scallop_pool_acc,
        );
        <b>let</b> unstake_ssui_amt = muldiv(
            staked_amount_ssui,
            to_repay,
            strategy.underlying_nominal_value_sui,
        );
        <b>let</b> unstaked_ssui = <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_unstake">scallop_pool::user::unstake</a>(
            scallop_pool,
            &<b>mut</b> strategy.scallop_pool_acc,
            unstake_ssui_amt,
            clock,
            ctx,
        );
        <b>let</b> redeemed_coin = <a href="../dependencies/scallop_protocol/redeem.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_redeem_redeem">scallop_protocol::redeem::redeem</a>(
            scallop_version,
            scallop_market,
            unstaked_ssui,
            clock,
            ctx,
        );
        <b>let</b> <b>mut</b> redeemed_balance_sui = coin::into_balance(redeemed_coin);
        <b>if</b> (balance::value(&redeemed_balance_sui) &gt; to_repay) {
            <b>let</b> extra_amt = balance::value(&redeemed_balance_sui) - to_repay;
            balance::join(
                &<b>mut</b> strategy.collected_profit_sui,
                balance::split(&<b>mut</b> redeemed_balance_sui, extra_amt),
            );
        };
        <b>let</b> repaid = balance::value(&redeemed_balance_sui);
        <a href="../kai_sav/vault.md#kai_sav_vault_strategy_repay">vault::strategy_repay</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, vault_access, redeemed_balance_sui);
        strategy.underlying_nominal_value_sui = strategy.underlying_nominal_value_sui - repaid;
    } <b>else</b> <b>if</b> (can_borrow &gt; 0) {
        <b>let</b> borrow_amt = u64::min(can_borrow, <a href="../kai_sav/vault.md#kai_sav_vault_free_balance">vault::free_balance</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>));
        <b>let</b> borrowed = coin::from_balance(
            <a href="../kai_sav/vault.md#kai_sav_vault_strategy_borrow">vault::strategy_borrow</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, vault_access, borrow_amt),
            ctx,
        );
        <b>let</b> ssui = <a href="../dependencies/scallop_protocol/mint.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_mint_mint">scallop_protocol::mint::mint</a>(
            scallop_version,
            scallop_market,
            borrowed,
            clock,
            ctx,
        );
        <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_stake">scallop_pool::user::stake</a>(
            scallop_pool,
            &<b>mut</b> strategy.scallop_pool_acc,
            ssui,
            clock,
            ctx,
        );
        strategy.underlying_nominal_value_sui = strategy.underlying_nominal_value_sui + borrow_amt;
    }
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_skim_base_profits"></a>

## Function `skim_base_profits`

Skim the profits earned on base APY.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_skim_base_profits">skim_base_profits</a>(cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">kai_sav::scallop_sui_proper::AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>, scallop_version: &<a href="../dependencies/scallop_protocol/version.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_version_Version">scallop_protocol::version::Version</a>, scallop_market: &<b>mut</b> <a href="../dependencies/scallop_protocol/market.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_market_Market">scallop_protocol::market::Market</a>, scallop_pool: &<b>mut</b> <a href="../dependencies/scallop_pool/spool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_Spool">scallop_pool::spool::Spool</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_skim_base_profits">skim_base_profits</a>(
    cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a>,
    strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>,
    scallop_version: &ScallopVersion,
    scallop_market: &<b>mut</b> ScallopMarket,
    scallop_pool: &<b>mut</b> ScallopPool,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_admin">assert_admin</a>(cap, strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_version">assert_version</a>(strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_market">assert_scallop_market</a>(scallop_market);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_pool">assert_scallop_pool</a>(scallop_pool);
    <b>let</b> staked_amount_ssui = <a href="../dependencies/scallop_pool/spool_account.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_account_stake_amount">scallop_pool::spool_account::stake_amount</a>(&strategy.scallop_pool_acc);
    <b>let</b> unstaked_ssui = <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_unstake">scallop_pool::user::unstake</a>(
        scallop_pool,
        &<b>mut</b> strategy.scallop_pool_acc,
        staked_amount_ssui,
        clock,
        ctx,
    );
    <b>let</b> redeemed_coin = <a href="../dependencies/scallop_protocol/redeem.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_redeem_redeem">scallop_protocol::redeem::redeem</a>(
        scallop_version,
        scallop_market,
        unstaked_ssui,
        clock,
        ctx,
    );
    <b>let</b> <b>mut</b> redeemed_balance_sui = coin::into_balance(redeemed_coin);
    <b>if</b> (balance::value(&redeemed_balance_sui) &gt; strategy.underlying_nominal_value_sui) {
        <b>let</b> profit_amt =
            balance::value(&redeemed_balance_sui) - strategy.underlying_nominal_value_sui;
        balance::join(
            &<b>mut</b> strategy.collected_profit_sui,
            balance::split(&<b>mut</b> redeemed_balance_sui, profit_amt),
        );
    };
    <b>let</b> stake_coin = coin::from_balance(redeemed_balance_sui, ctx);
    <b>let</b> susdc = <a href="../dependencies/scallop_protocol/mint.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_mint_mint">scallop_protocol::mint::mint</a>(
        scallop_version,
        scallop_market,
        stake_coin,
        clock,
        ctx,
    );
    <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_stake">scallop_pool::user::stake</a>(
        scallop_pool,
        &<b>mut</b> strategy.scallop_pool_acc,
        susdc,
        clock,
        ctx,
    );
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_collect_and_hand_over_profit"></a>

## Function `collect_and_hand_over_profit`

Collect the profits and hand them over to the vault.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_collect_and_hand_over_profit">collect_and_hand_over_profit</a>(cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">kai_sav::scallop_sui_proper::AdminCap</a>, strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>, <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_Vault">kai_sav::vault::Vault</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>, <a href="../dependencies/kai_ywhusdte_ysui/ysui.md#kai_ywhusdte_ysui_ysui_YSUI">kai_ywhusdte_ysui::ysui::YSUI</a>&gt;, scallop_pool: &<b>mut</b> <a href="../dependencies/scallop_pool/spool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_Spool">scallop_pool::spool::Spool</a>, scallop_rewards_pool: &<b>mut</b> <a href="../dependencies/scallop_pool/rewards_pool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_rewards_pool_RewardsPool">scallop_pool::rewards_pool::RewardsPool</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_collect_and_hand_over_profit">collect_and_hand_over_profit</a>(
    cap: &<a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_AdminCap">AdminCap</a>,
    strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>,
    <a href="../kai_sav/vault.md#kai_sav_vault">vault</a>: &<b>mut</b> Vault&lt;SUI, YSUI&gt;,
    scallop_pool: &<b>mut</b> ScallopPool,
    scallop_rewards_pool: &<b>mut</b> ScallopRewardsPool&lt;SUI&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_admin">assert_admin</a>(cap, strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_version">assert_version</a>(strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_pool">assert_scallop_pool</a>(scallop_pool);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_rewards_pool">assert_scallop_rewards_pool</a>(scallop_rewards_pool);
    <b>let</b> vault_access = option::borrow(&strategy.vault_access);
    <b>let</b> coin = <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_redeem_rewards">scallop_pool::user::redeem_rewards</a>(
        scallop_pool,
        scallop_rewards_pool,
        &<b>mut</b> strategy.scallop_pool_acc,
        clock,
        ctx,
    );
    balance::join(&<b>mut</b> strategy.collected_profit_sui, coin::into_balance(coin));
    <b>let</b> profit = balance::withdraw_all(&<b>mut</b> strategy.collected_profit_sui);
    <a href="../kai_sav/vault.md#kai_sav_vault_strategy_hand_over_profit">vault::strategy_hand_over_profit</a>(<a href="../kai_sav/vault.md#kai_sav_vault">vault</a>, vault_access, profit, clock);
}
</code></pre>



</details>

<a name="kai_sav_scallop_sui_proper_withdraw"></a>

## Function `withdraw`



<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_withdraw">withdraw</a>(strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">kai_sav::scallop_sui_proper::Strategy</a>, ticket: &<b>mut</b> <a href="../kai_sav/vault.md#kai_sav_vault_WithdrawTicket">kai_sav::vault::WithdrawTicket</a>&lt;<a href="../dependencies/sui/sui.md#sui_sui_SUI">sui::sui::SUI</a>, <a href="../dependencies/kai_ywhusdte_ysui/ysui.md#kai_ywhusdte_ysui_ysui_YSUI">kai_ywhusdte_ysui::ysui::YSUI</a>&gt;, scallop_version: &<a href="../dependencies/scallop_protocol/version.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_version_Version">scallop_protocol::version::Version</a>, scallop_market: &<b>mut</b> <a href="../dependencies/scallop_protocol/market.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_market_Market">scallop_protocol::market::Market</a>, scallop_pool: &<b>mut</b> <a href="../dependencies/scallop_pool/spool.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_Spool">scallop_pool::spool::Spool</a>, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_withdraw">withdraw</a>(
    strategy: &<b>mut</b> <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_Strategy">Strategy</a>,
    ticket: &<b>mut</b> WithdrawTicket&lt;SUI, YSUI&gt;,
    scallop_version: &ScallopVersion,
    scallop_market: &<b>mut</b> ScallopMarket,
    scallop_pool: &<b>mut</b> ScallopPool,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_version">assert_version</a>(strategy);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_market">assert_scallop_market</a>(scallop_market);
    <a href="../kai_sav/scallop_sui_proper.md#kai_sav_scallop_sui_proper_assert_scallop_pool">assert_scallop_pool</a>(scallop_pool);
    <b>let</b> vault_access = option::borrow(&strategy.vault_access);
    <b>let</b> to_withdraw = <a href="../kai_sav/vault.md#kai_sav_vault_withdraw_ticket_to_withdraw">vault::withdraw_ticket_to_withdraw</a>(ticket, vault_access);
    <b>if</b> (to_withdraw == 0) {
        <b>return</b>
    };
    <b>let</b> staked_amount_ssui = <a href="../dependencies/scallop_pool/spool_account.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_spool_account_stake_amount">scallop_pool::spool_account::stake_amount</a>(&strategy.scallop_pool_acc);
    <b>let</b> unstake_ssui_amt = muldiv(
        staked_amount_ssui,
        to_withdraw,
        strategy.underlying_nominal_value_sui,
    );
    <b>let</b> unstaked_ssui = <a href="../dependencies/scallop_pool/user.md#0xE87F1B2D498106A2C61421CEC75B7B5C5E348512B0DC263949A0E7A3C256571A_user_unstake">scallop_pool::user::unstake</a>(
        scallop_pool,
        &<b>mut</b> strategy.scallop_pool_acc,
        unstake_ssui_amt,
        clock,
        ctx,
    );
    <b>let</b> redeemed_coin = <a href="../dependencies/scallop_protocol/redeem.md#0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF_redeem_redeem">scallop_protocol::redeem::redeem</a>(
        scallop_version,
        scallop_market,
        unstaked_ssui,
        clock,
        ctx,
    );
    <b>let</b> <b>mut</b> redeemed_balance_sui = coin::into_balance(redeemed_coin);
    <b>if</b> (balance::value(&redeemed_balance_sui) &gt; to_withdraw) {
        <b>let</b> profit_amt = balance::value(&redeemed_balance_sui) - to_withdraw;
        balance::join(
            &<b>mut</b> strategy.collected_profit_sui,
            balance::split(&<b>mut</b> redeemed_balance_sui, profit_amt),
        );
    };
    <a href="../kai_sav/vault.md#kai_sav_vault_strategy_withdraw_to_ticket">vault::strategy_withdraw_to_ticket</a>(ticket, vault_access, redeemed_balance_sui);
    // `to_withdraw` amount is used intentionally here instead of the actual amount which
    // can be lower in some cases (see comments in `<a href="../kai_sav/vault.md#kai_sav_vault_redeem_withdraw_ticket">vault::redeem_withdraw_ticket</a>`)
    strategy.underlying_nominal_value_sui = strategy.underlying_nominal_value_sui - to_withdraw;
}
</code></pre>



</details>

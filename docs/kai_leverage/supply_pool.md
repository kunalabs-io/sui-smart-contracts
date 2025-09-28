
<a name="kai_leverage_supply_pool"></a>

# Module `kai_leverage::supply_pool`

Core supply pool module for Kai Leverage lending facilities.

The supply pool is the heart of the lending and borrowing system. It manages
the available liquidity, tracks total liabilities, and coordinates the interaction
between liquidity suppliers and leveraged positions. The supply pool enforces
risk and utilization limits, accrues interest, and collects protocol fees.

Key responsibilities:
- Maintains the available balance and total liabilities for each lending facility.
- Issues and redeems equity shares representing claims on pool assets.
- Issues and tracks debt shares for borrowers, ensuring precise debt accounting.
- Enforces risk parameters such as maximum utilization and outstanding debt.
- Accrues interest and protocol fees over time.


-  [Struct `ACreatePool`](#kai_leverage_supply_pool_ACreatePool)
-  [Struct `AConfigLendFacil`](#kai_leverage_supply_pool_AConfigLendFacil)
-  [Struct `AConfigFees`](#kai_leverage_supply_pool_AConfigFees)
-  [Struct `ATakeFees`](#kai_leverage_supply_pool_ATakeFees)
-  [Struct `ADeposit`](#kai_leverage_supply_pool_ADeposit)
-  [Struct `AMigrate`](#kai_leverage_supply_pool_AMigrate)
-  [Struct `SupplyInfo`](#kai_leverage_supply_pool_SupplyInfo)
-  [Struct `WithdrawInfo`](#kai_leverage_supply_pool_WithdrawInfo)
-  [Struct `LendFacilCap`](#kai_leverage_supply_pool_LendFacilCap)
-  [Struct `LendFacilInfo`](#kai_leverage_supply_pool_LendFacilInfo)
-  [Struct `FacilDebtShare`](#kai_leverage_supply_pool_FacilDebtShare)
-  [Struct `FacilDebtBag`](#kai_leverage_supply_pool_FacilDebtBag)
-  [Struct `SupplyPool`](#kai_leverage_supply_pool_SupplyPool)
-  [Constants](#@Constants_0)
-  [Function `check_version`](#kai_leverage_supply_pool_check_version)
-  [Function `migrate_supply_pool_version`](#kai_leverage_supply_pool_migrate_supply_pool_version)
-  [Function `create_pool`](#kai_leverage_supply_pool_create_pool)
-  [Function `total_liabilities_x64`](#kai_leverage_supply_pool_total_liabilities_x64)
-  [Function `create_lend_facil_cap`](#kai_leverage_supply_pool_create_lend_facil_cap)
-  [Function `add_lend_facil`](#kai_leverage_supply_pool_add_lend_facil)
-  [Function `remove_lend_facil`](#kai_leverage_supply_pool_remove_lend_facil)
-  [Function `set_lend_facil_interest_model`](#kai_leverage_supply_pool_set_lend_facil_interest_model)
-  [Function `set_lend_facil_max_liability_outstanding`](#kai_leverage_supply_pool_set_lend_facil_max_liability_outstanding)
-  [Function `set_lend_facil_max_utilization_bps`](#kai_leverage_supply_pool_set_lend_facil_max_utilization_bps)
-  [Function `set_interest_fee_bps`](#kai_leverage_supply_pool_set_interest_fee_bps)
-  [Function `take_collected_fees`](#kai_leverage_supply_pool_take_collected_fees)
-  [Function `total_value_x64`](#kai_leverage_supply_pool_total_value_x64)
-  [Function `utilization_bps`](#kai_leverage_supply_pool_utilization_bps)
-  [Function `update_interest`](#kai_leverage_supply_pool_update_interest)
-  [Function `borrow_debt_registry`](#kai_leverage_supply_pool_borrow_debt_registry)
-  [Function `supply`](#kai_leverage_supply_pool_supply)
-  [Function `calc_withdraw_by_shares`](#kai_leverage_supply_pool_calc_withdraw_by_shares)
-  [Function `calc_withdraw_by_amount`](#kai_leverage_supply_pool_calc_withdraw_by_amount)
-  [Function `withdraw`](#kai_leverage_supply_pool_withdraw)
-  [Function `borrow`](#kai_leverage_supply_pool_borrow)
-  [Function `calc_repay_by_shares`](#kai_leverage_supply_pool_calc_repay_by_shares)
-  [Function `calc_repay_by_amount`](#kai_leverage_supply_pool_calc_repay_by_amount)
-  [Function `repay`](#kai_leverage_supply_pool_repay)
-  [Function `repay_max_possible`](#kai_leverage_supply_pool_repay_max_possible)
-  [Function `fds_facil_id`](#kai_leverage_supply_pool_fds_facil_id)
-  [Function `fds_borrow_inner`](#kai_leverage_supply_pool_fds_borrow_inner)
-  [Function `fds_value_x64`](#kai_leverage_supply_pool_fds_value_x64)
-  [Function `fds_split_x64`](#kai_leverage_supply_pool_fds_split_x64)
-  [Function `fds_split`](#kai_leverage_supply_pool_fds_split)
-  [Function `fds_withdraw_all`](#kai_leverage_supply_pool_fds_withdraw_all)
-  [Function `fds_join`](#kai_leverage_supply_pool_fds_join)
-  [Function `fds_destroy_zero`](#kai_leverage_supply_pool_fds_destroy_zero)
-  [Function `empty_facil_debt_bag`](#kai_leverage_supply_pool_empty_facil_debt_bag)
-  [Function `fdb_add`](#kai_leverage_supply_pool_fdb_add)
-  [Function `fdb_take_amt`](#kai_leverage_supply_pool_fdb_take_amt)
-  [Function `fdb_take_all`](#kai_leverage_supply_pool_fdb_take_all)
-  [Function `fdb_get_share_amount_by_asset_type`](#kai_leverage_supply_pool_fdb_get_share_amount_by_asset_type)
-  [Function `fdb_get_share_amount_by_share_type`](#kai_leverage_supply_pool_fdb_get_share_amount_by_share_type)
-  [Function `fdb_share_type_matches_asset_if_any_exists`](#kai_leverage_supply_pool_fdb_share_type_matches_asset_if_any_exists)
-  [Function `fdb_get_share_type_for_asset`](#kai_leverage_supply_pool_fdb_get_share_type_for_asset)
-  [Function `fdb_is_empty`](#kai_leverage_supply_pool_fdb_is_empty)
-  [Function `fdb_destroy_empty`](#kai_leverage_supply_pool_fdb_destroy_empty)
-  [Function `fdb_length`](#kai_leverage_supply_pool_fdb_length)


<pre><code><b>use</b> <a href="../../dependencies/access_management/access.md#access_management_access">access_management::access</a>;
<b>use</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map">access_management::dynamic_map</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt">kai_leverage::debt</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag">kai_leverage::debt_bag</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity">kai_leverage::equity</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise">kai_leverage::piecewise</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util">kai_leverage::util</a>;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/u128.md#std_u128">std::u128</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_leverage_supply_pool_ACreatePool"></a>

## Struct `ACreatePool`

Access control witness for pool creation.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_ACreatePool">ACreatePool</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_supply_pool_AConfigLendFacil"></a>

## Struct `AConfigLendFacil`

Access control witness for lending facility configuration.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AConfigLendFacil">AConfigLendFacil</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_supply_pool_AConfigFees"></a>

## Struct `AConfigFees`

Access control witness for fee configuration.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AConfigFees">AConfigFees</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_supply_pool_ATakeFees"></a>

## Struct `ATakeFees`

Access control witness for taking collected fees.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_ATakeFees">ATakeFees</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_supply_pool_ADeposit"></a>

## Struct `ADeposit`

Access control witness for deposits.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_ADeposit">ADeposit</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_supply_pool_AMigrate"></a>

## Struct `AMigrate`

Access control witness for migrations.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AMigrate">AMigrate</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_supply_pool_SupplyInfo"></a>

## Struct `SupplyInfo`

Event emitted for a supply operation.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyInfo">SupplyInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>supply_pool_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>deposited: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>share_balance: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_supply_pool_WithdrawInfo"></a>

## Struct `WithdrawInfo`

Event emitted for a withdraw operation.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_WithdrawInfo">WithdrawInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>supply_pool_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>share_balance: u64</code>
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

<a name="kai_leverage_supply_pool_LendFacilCap"></a>

## Struct `LendFacilCap`

Capability for managing a lending facility. Enables the owner to borrow from the pool.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilCap">LendFacilCap</a> <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_supply_pool_LendFacilInfo"></a>

## Struct `LendFacilInfo`

Configuration and state for a lending facility.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilInfo">LendFacilInfo</a>&lt;<b>phantom</b> ST&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>interest_model: <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">kai_leverage::piecewise::Piecewise</a></code>
</dt>
<dd>
</dd>
<dt>
<code>debt_registry: <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt_DebtRegistry">kai_leverage::debt::DebtRegistry</a>&lt;ST&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>max_liability_outstanding: u64</code>
</dt>
<dd>
 The maximum amount of debt after which the borrowing will be capped.
</dd>
<dt>
<code>max_utilization_bps: u64</code>
</dt>
<dd>
 The maximum utilization after which the borrowing will be capped.
</dd>
</dl>


</details>

<a name="kai_leverage_supply_pool_FacilDebtShare"></a>

## Struct `FacilDebtShare`

Debt shares for a specific lending facility.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;<b>phantom</b> ST&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>facil_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>inner: <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt_DebtShareBalance">kai_leverage::debt::DebtShareBalance</a>&lt;ST&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_supply_pool_FacilDebtBag"></a>

## Struct `FacilDebtBag`

Collection of debt shares for a lending facility.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a> <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>facil_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>inner: <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_supply_pool_SupplyPool"></a>

## Struct `SupplyPool`

The central structure for managing lending and borrowing operations within the supply pool.
Tracks available balances, liabilities, interest, and equity shares for robust pool management.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;<b>phantom</b> T, <b>phantom</b> ST&gt; <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>available_balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>interest_fee_bps: u16</code>
</dt>
<dd>
</dd>
<dt>
<code>debt_info: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilInfo">kai_leverage::supply_pool::LendFacilInfo</a>&lt;ST&gt;&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a>: u128</code>
</dt>
<dd>
</dd>
<dt>
<code>last_update_ts_sec: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>supply_equity: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;ST&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>collected_fees: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;ST&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>version: u16</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_supply_pool_SECONDS_IN_YEAR"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SECONDS_IN_YEAR">SECONDS_IN_YEAR</a>: u128 = 31536000;
</code></pre>



<a name="kai_leverage_supply_pool_MODULE_VERSION"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>: u16 = 1;
</code></pre>



<a name="kai_leverage_supply_pool_EShareTreasuryNotEmpty"></a>

The share treasury for the supply shares must be empty, without any outstanding shares.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EShareTreasuryNotEmpty">EShareTreasuryNotEmpty</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_supply_pool_EInvalidRepayAmount"></a>

The provided repay balance does not match the amount that needs to be repaid.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EInvalidRepayAmount">EInvalidRepayAmount</a>: u64 = 1;
</code></pre>



<a name="kai_leverage_supply_pool_EShareFacilMismatch"></a>

The provided shares do not belong to the correct lending facility.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EShareFacilMismatch">EShareFacilMismatch</a>: u64 = 2;
</code></pre>



<a name="kai_leverage_supply_pool_EMaxUtilizationReached"></a>

The maximum utilization has been reached or exceeded for the lending facility.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EMaxUtilizationReached">EMaxUtilizationReached</a>: u64 = 3;
</code></pre>



<a name="kai_leverage_supply_pool_EMaxLiabilityOutstandingReached"></a>

The maximum amount of debt has been reached or exceeded for the lending facility.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EMaxLiabilityOutstandingReached">EMaxLiabilityOutstandingReached</a>: u64 = 4;
</code></pre>



<a name="kai_leverage_supply_pool_EInvalidSupplyPoolVersion"></a>

The <code><a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a></code> version does not match the module version.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EInvalidSupplyPoolVersion">EInvalidSupplyPoolVersion</a>: u64 = 5;
</code></pre>



<a name="kai_leverage_supply_pool_ENotUpgrade"></a>

The migration is not allowed because the object version is higher or equal to the module
version.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_ENotUpgrade">ENotUpgrade</a>: u64 = 6;
</code></pre>



<a name="kai_leverage_supply_pool_check_version"></a>

## Function `check_version`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>&lt;T, ST&gt;(pool: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>&lt;T, ST&gt;(pool: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;) {
    <b>assert</b>!(pool.version == <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EInvalidSupplyPoolVersion">EInvalidSupplyPoolVersion</a>);
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_migrate_supply_pool_version"></a>

## Function `migrate_supply_pool_version`

Migrate supply pool to current module version.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_migrate_supply_pool_version">migrate_supply_pool_version</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_migrate_supply_pool_version">migrate_supply_pool_version</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>assert</b>!(pool.version &lt; <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_ENotUpgrade">ENotUpgrade</a>);
    pool.version = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>;
    access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AMigrate">AMigrate</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_create_pool"></a>

## Function `create_pool`

Create a new supply pool with empty equity treasury.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_create_pool">create_pool</a>&lt;T, ST: drop&gt;(equity_treasury: <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityTreasury">kai_leverage::equity::EquityTreasury</a>&lt;ST&gt;, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_create_pool">create_pool</a>&lt;T, ST: drop&gt;(
    equity_treasury: EquityTreasury&lt;ST&gt;,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <b>let</b> registry = equity_treasury.borrow_registry();
    <b>assert</b>!(
        registry.supply_x64() == 0
        && registry.underlying_value_x64() == 0
        && equity_treasury.borrow_treasury_cap().total_supply() == 0,
        <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EShareTreasuryNotEmpty">EShareTreasuryNotEmpty</a>,
    );
    <b>let</b> pool = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt; {
        id: object::new(ctx),
        available_balance: balance::zero(),
        interest_fee_bps: 0,
        debt_info: vec_map::empty(),
        <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a>: 0,
        last_update_ts_sec: 0,
        supply_equity: equity_treasury,
        collected_fees: equity::zero(),
        version: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_MODULE_VERSION">MODULE_VERSION</a>,
    };
    transfer::share_object(pool);
    access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_ACreatePool">ACreatePool</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_total_liabilities_x64"></a>

## Function `total_liabilities_x64`

Get total liabilities in Q64.64 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a>&lt;T, ST&gt;(pool: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a>&lt;T, ST&gt;(pool: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;): u128 {
    pool.<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a>
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_create_lend_facil_cap"></a>

## Function `create_lend_facil_cap`

Create a lending facility capability.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_create_lend_facil_cap">create_lend_facil_cap</a>(ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilCap">kai_leverage::supply_pool::LendFacilCap</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_create_lend_facil_cap">create_lend_facil_cap</a>(ctx: &<b>mut</b> TxContext): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilCap">LendFacilCap</a> {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilCap">LendFacilCap</a> { id: object::new(ctx) }
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_add_lend_facil"></a>

## Function `add_lend_facil`

Add a new lending facility to the supply pool.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_add_lend_facil">add_lend_facil</a>&lt;T, ST: drop&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, facil_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, interest_model: <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">kai_leverage::piecewise::Piecewise</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_add_lend_facil">add_lend_facil</a>&lt;T, ST: drop&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    facil_id: ID,
    interest_model: Piecewise,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <b>let</b> debt_registry = debt::create_registry_with_cap(pool.supply_equity.borrow_treasury_cap());
    pool
        .debt_info
        .insert(
            facil_id,
            <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilInfo">LendFacilInfo</a> {
                interest_model,
                debt_registry,
                max_liability_outstanding: 0,
                max_utilization_bps: 10_000,
            },
        );
    access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AConfigLendFacil">AConfigLendFacil</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_remove_lend_facil"></a>

## Function `remove_lend_facil`

Remove a lending facility from the supply pool.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_remove_lend_facil">remove_lend_facil</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, facil_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_remove_lend_facil">remove_lend_facil</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    facil_id: ID,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <b>let</b> (_, info) = pool.debt_info.remove(&facil_id);
    <b>let</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilInfo">LendFacilInfo</a> { interest_model: _, debt_registry, .. } = info;
    debt_registry.destroy_empty();
    access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AConfigLendFacil">AConfigLendFacil</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_set_lend_facil_interest_model"></a>

## Function `set_lend_facil_interest_model`

Set the interest model for a lending facility.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_set_lend_facil_interest_model">set_lend_facil_interest_model</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, facil_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, interest_model: <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">kai_leverage::piecewise::Piecewise</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_set_lend_facil_interest_model">set_lend_facil_interest_model</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    facil_id: ID,
    interest_model: Piecewise,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <b>let</b> info = &<b>mut</b> pool.debt_info[&facil_id];
    info.interest_model = interest_model;
    access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AConfigLendFacil">AConfigLendFacil</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_set_lend_facil_max_liability_outstanding"></a>

## Function `set_lend_facil_max_liability_outstanding`

Set the maximum liability outstanding for a lending facility.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_set_lend_facil_max_liability_outstanding">set_lend_facil_max_liability_outstanding</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, facil_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, max_liability_outstanding: u64, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_set_lend_facil_max_liability_outstanding">set_lend_facil_max_liability_outstanding</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    facil_id: ID,
    max_liability_outstanding: u64,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <b>let</b> info = &<b>mut</b> pool.debt_info[&facil_id];
    info.max_liability_outstanding = max_liability_outstanding;
    access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AConfigLendFacil">AConfigLendFacil</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_set_lend_facil_max_utilization_bps"></a>

## Function `set_lend_facil_max_utilization_bps`

Set the maximum utilization in basis points for a lending facility.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_set_lend_facil_max_utilization_bps">set_lend_facil_max_utilization_bps</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, facil_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, max_utilization_bps: u64, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_set_lend_facil_max_utilization_bps">set_lend_facil_max_utilization_bps</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    facil_id: ID,
    max_utilization_bps: u64,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <b>let</b> info = &<b>mut</b> pool.debt_info[&facil_id];
    info.max_utilization_bps = max_utilization_bps;
    access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AConfigLendFacil">AConfigLendFacil</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_set_interest_fee_bps"></a>

## Function `set_interest_fee_bps`

Set the interest fee in basis points for the supply pool.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_set_interest_fee_bps">set_interest_fee_bps</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, fee_bps: u16, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_set_interest_fee_bps">set_interest_fee_bps</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    fee_bps: u16,
    ctx: &<b>mut</b> TxContext,
): ActionRequest {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    pool.interest_fee_bps = fee_bps;
    access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_AConfigFees">AConfigFees</a> {}, ctx)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_take_collected_fees"></a>

## Function `take_collected_fees`

Take all collected fees from the supply pool.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_take_collected_fees">take_collected_fees</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity_EquityShareBalance">kai_leverage::equity::EquityShareBalance</a>&lt;ST&gt;, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_take_collected_fees">take_collected_fees</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    ctx: &<b>mut</b> TxContext,
): (EquityShareBalance&lt;ST&gt;, ActionRequest) {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    (pool.collected_fees.withdraw_all(), access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_ATakeFees">ATakeFees</a> {}, ctx))
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_total_value_x64"></a>

## Function `total_value_x64`

Total balance of the pool. This is the sum of the available balance and the borrowed amount
which is out on loan, or the total supply equity underlying value. In <code>UQ64.64</code> format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_value_x64">total_value_x64</a>&lt;T, ST&gt;(pool: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_value_x64">total_value_x64</a>&lt;T, ST&gt;(pool: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;): u128 {
    pool.supply_equity.borrow_registry().underlying_value_x64()
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_utilization_bps"></a>

## Function `utilization_bps`

Get current utilization in basis points.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_utilization_bps">utilization_bps</a>&lt;T, ST&gt;(pool: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_utilization_bps">utilization_bps</a>&lt;T, ST&gt;(pool: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;): u64 {
    <b>let</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_value_x64">total_value_x64</a> = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_value_x64">total_value_x64</a>(pool);
    <b>if</b> (<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_value_x64">total_value_x64</a> == 0) {
        <b>return</b> 0
    };
    util::muldiv_u128(
        pool.<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a>,
        10000,
        <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_value_x64">total_value_x64</a>,
    ) <b>as</b> u64
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_update_interest"></a>

## Function `update_interest`

Update the interest accrued since the last update and distribute the interest fee.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;, clock: &Clock) {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <b>let</b> dt = <a href="../../kai_sav/util.md#kai_sav_util_timestamp_sec">util::timestamp_sec</a>(clock) - pool.last_update_ts_sec;
    <b>if</b> (dt == 0) {
        <b>return</b>
    };
    <b>let</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_utilization_bps">utilization_bps</a> = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_utilization_bps">utilization_bps</a>(pool);
    <b>let</b> <b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a> = 0;
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = pool.debt_info.length();
    <b>while</b> (i &lt; n) {
        <b>let</b> (_, info) = pool.debt_info.get_entry_by_idx_mut(i);
        <b>let</b> apr_bps = info.interest_model.value_at(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_utilization_bps">utilization_bps</a>);
        <b>let</b> accrued_interest_x64 = util::muldiv_u128(
            info.debt_registry.liability_value_x64(),
            (apr_bps <b>as</b> u128) * (dt <b>as</b> u128),
            100_00 * <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SECONDS_IN_YEAR">SECONDS_IN_YEAR</a>,
        );
        <b>let</b> fee_x64 = util::muldiv_u128(accrued_interest_x64, pool.interest_fee_bps <b>as</b> u128, 10000);
        // increase <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_supply">supply</a> shares underlying value by the accrued interest, and collect the fee
        <b>let</b> share_registry = pool.supply_equity.borrow_mut_registry();
        share_registry.increase_value_x64(accrued_interest_x64 - fee_x64);
        equity::join(
            &<b>mut</b> pool.collected_fees,
            equity::increase_value_and_issue_x64(share_registry, fee_x64),
        );
        // increase debt shares liability by the accrued interest
        info.debt_registry.increase_liability_x64(accrued_interest_x64);
        <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a> = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a> + info.debt_registry.liability_value_x64();
        i = i + 1;
    };
    pool.<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a> = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a>;
    pool.last_update_ts_sec = <a href="../../kai_sav/util.md#kai_sav_util_timestamp_sec">util::timestamp_sec</a>(clock);
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_borrow_debt_registry"></a>

## Function `borrow_debt_registry`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_borrow_debt_registry">borrow_debt_registry</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, id: &<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): &<a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt_DebtRegistry">kai_leverage::debt::DebtRegistry</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_borrow_debt_registry">borrow_debt_registry</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    id: &ID,
    clock: &Clock,
): &DebtRegistry&lt;ST&gt; {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    <b>let</b> info = &pool.debt_info[id];
    &info.debt_registry
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_supply"></a>

## Function `supply`

Supply liquidity to the pool and receive shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_supply">supply</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;ST&gt;, <a href="../../dependencies/access_management/access.md#access_management_access_ActionRequest">access_management::access::ActionRequest</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_supply">supply</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    balance: Balance&lt;T&gt;,
    clock: &Clock,
    ctx: &<b>mut</b> TxContext,
): (Balance&lt;ST&gt;, ActionRequest) {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    <b>let</b> deposited = balance.value();
    <b>let</b> registry = pool.supply_equity.borrow_mut_registry();
    <b>let</b> shares = registry.increase_value_and_issue(balance.value());
    pool.available_balance.join(balance);
    <b>let</b> share_balance = shares.into_balance_lossy(&<b>mut</b> pool.supply_equity);
    event::emit(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyInfo">SupplyInfo</a> {
        supply_pool_id: pool.id.to_inner(),
        deposited,
        share_balance: share_balance.value(),
    });
    (share_balance, access::new_request(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_ADeposit">ADeposit</a> {}, ctx))
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_calc_withdraw_by_shares"></a>

## Function `calc_withdraw_by_shares`

Calculates the amount that will be withdrawn for the given amount of supply shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_withdraw_by_shares">calc_withdraw_by_shares</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, share_amount: u64, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_withdraw_by_shares">calc_withdraw_by_shares</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    share_amount: u64,
    clock: &Clock,
): u64 {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    equity::calc_redeem_lossy(
        pool.supply_equity.borrow_registry(),
        ((share_amount <b>as</b> u128) &lt;&lt; 64),
    )
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_calc_withdraw_by_amount"></a>

## Function `calc_withdraw_by_amount`

Calculates the amount of shares needed to withdraw the given amount.
Since the redeemed amount can sometimes be higher than the requested amount due to rounding,
this function also returns the actual amount that will be withdrawn.
Returns <code>(share_amount, redeem_amount)</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_withdraw_by_amount">calc_withdraw_by_amount</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, amount: u64, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_withdraw_by_amount">calc_withdraw_by_amount</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    amount: u64,
    clock: &Clock,
): (u64, u64) {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    equity::calc_balance_redeem_for_amount(
        pool.supply_equity.borrow_registry(),
        amount,
    )
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_withdraw"></a>

## Function `withdraw`

Withdraw tokens from the pool using shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_withdraw">withdraw</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;ST&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_withdraw">withdraw</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    balance: Balance&lt;ST&gt;,
    clock: &Clock,
): Balance&lt;T&gt; {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    <b>let</b> share_balance = balance.value();
    <b>let</b> shares = equity::from_balance(&<b>mut</b> pool.supply_equity, balance);
    <b>let</b> value = pool.supply_equity.borrow_mut_registry().redeem_lossy(shares);
    event::emit(<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_WithdrawInfo">WithdrawInfo</a> {
        supply_pool_id: pool.id.to_inner(),
        share_balance,
        withdrawn: value,
    });
    pool.available_balance.split(value)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_borrow"></a>

## Function `borrow`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_borrow">borrow</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, facil_cap: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilCap">kai_leverage::supply_pool::LendFacilCap</a>, amount: u64, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (<a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_borrow">borrow</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    facil_cap: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_LendFacilCap">LendFacilCap</a>,
    amount: u64,
    clock: &Clock,
): (Balance&lt;T&gt;, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;) {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    <b>let</b> facil_id = object::id(facil_cap);
    <b>let</b> info = &<b>mut</b> pool.debt_info[&facil_id];
    <b>let</b> max_utilization_bps = info.max_utilization_bps;
    <b>let</b> max_liability_outstanding = info.max_liability_outstanding;
    <b>let</b> shares = info.debt_registry.increase_liability_and_issue(amount);
    <b>let</b> balance = pool.available_balance.split(amount);
    pool.<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a> = pool.<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a> + ((amount <b>as</b> u128) &lt;&lt; 64);
    <b>let</b> liability_after_borrow = ((info.debt_registry.liability_value_x64() &gt;&gt; 64) <b>as</b> u64);
    <b>let</b> utilization_after_borrow = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_utilization_bps">utilization_bps</a>(pool);
    <b>assert</b>!(liability_after_borrow &lt; max_liability_outstanding, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EMaxLiabilityOutstandingReached">EMaxLiabilityOutstandingReached</a>);
    <b>assert</b>!(utilization_after_borrow &lt;= max_utilization_bps, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EMaxUtilizationReached">EMaxUtilizationReached</a>);
    <b>let</b> facil_shares = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id, inner: shares };
    (balance, facil_shares)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_calc_repay_by_shares"></a>

## Function `calc_repay_by_shares`

Calculates the debt amount that needs to be repaid for the given amount of debt shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_repay_by_shares">calc_repay_by_shares</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, fac_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, share_value_x64: u128, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_repay_by_shares">calc_repay_by_shares</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    fac_id: ID,
    share_value_x64: u128,
    clock: &Clock,
): u64 {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    <b>let</b> info = &pool.debt_info[&fac_id];
    debt::calc_repay_lossy(&info.debt_registry, share_value_x64)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_calc_repay_by_amount"></a>

## Function `calc_repay_by_amount`

Calculates the debt share amount required to repay the given amount of debt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_repay_by_amount">calc_repay_by_amount</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, fac_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, amount: u64, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_repay_by_amount">calc_repay_by_amount</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    fac_id: ID,
    amount: u64,
    clock: &Clock,
): u128 {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    <b>let</b> info = &pool.debt_info[&fac_id];
    debt::calc_repay_for_amount(&info.debt_registry, amount)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_repay"></a>

## Function `repay`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_repay">repay</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, shares: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_repay">repay</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    shares: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;,
    balance: Balance&lt;T&gt;,
    clock: &Clock,
) {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_update_interest">update_interest</a>(pool, clock);
    <b>let</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id, inner: shares } = shares;
    <b>let</b> info = &<b>mut</b> pool.debt_info[&facil_id];
    <b>let</b> amount = info.debt_registry.repay_lossy(shares);
    <b>assert</b>!(balance.value() == amount, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EInvalidRepayAmount">EInvalidRepayAmount</a>);
    <b>let</b> amount_x64 = u128::min(pool.<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a>, (amount <b>as</b> u128) &lt;&lt; 64);
    pool.<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a> = pool.<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_total_liabilities_x64">total_liabilities_x64</a> - amount_x64;
    pool.available_balance.join(balance);
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_repay_max_possible"></a>

## Function `repay_max_possible`

Repays the maximum possible amount of debt shares given the balance.
Returns the amount of debt shares and balance repaid.


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_repay_max_possible">repay_max_possible</a>&lt;T, ST&gt;(pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, shares: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;, balance: &<b>mut</b> <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): (u128, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_repay_max_possible">repay_max_possible</a>&lt;T, ST&gt;(
    pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">SupplyPool</a>&lt;T, ST&gt;,
    shares: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;,
    balance: &<b>mut</b> Balance&lt;T&gt;,
    clock: &Clock,
): (u128, u64) {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_check_version">check_version</a>(pool);
    <b>let</b> facil_id = shares.facil_id;
    <b>let</b> balance_by_shares = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_repay_by_shares">calc_repay_by_shares</a>(pool, facil_id, shares.value_x64(), clock);
    <b>let</b> shares_by_balance = <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_calc_repay_by_amount">calc_repay_by_amount</a>(pool, facil_id, balance.value(), clock);
    <b>let</b> (share_amt, balance_amt) = <b>if</b> (balance.value() &gt;= balance_by_shares) {
        (shares.value_x64(), balance_by_shares)
    } <b>else</b> {
        // `shares_by_balance &lt;= shares` here, this can be proven with an SMT solver
        (shares_by_balance, balance.value())
    };
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_repay">repay</a>(
        pool,
        shares.split_x64(share_amt),
        balance.split(balance_amt),
        clock,
    );
    (share_amt, balance_amt)
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fds_facil_id"></a>

## Function `fds_facil_id`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_facil_id">fds_facil_id</a>&lt;ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_facil_id">fds_facil_id</a>&lt;ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;): ID {
    self.facil_id
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fds_borrow_inner"></a>

## Function `fds_borrow_inner`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_borrow_inner">fds_borrow_inner</a>&lt;ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;): &<a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt_DebtShareBalance">kai_leverage::debt::DebtShareBalance</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_borrow_inner">fds_borrow_inner</a>&lt;ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;): &DebtShareBalance&lt;ST&gt; {
    &self.inner
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fds_value_x64"></a>

## Function `fds_value_x64`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_value_x64">fds_value_x64</a>&lt;ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_value_x64">fds_value_x64</a>&lt;ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;): u128 {
    self.inner.value_x64()
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fds_split_x64"></a>

## Function `fds_split_x64`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_split_x64">fds_split_x64</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;, amount: u128): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_split_x64">fds_split_x64</a>&lt;ST&gt;(
    self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;,
    amount: u128,
): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt; {
    <b>let</b> inner = self.inner.split_x64(amount);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id: self.facil_id, inner }
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fds_split"></a>

## Function `fds_split`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_split">fds_split</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;, amount: u64): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_split">fds_split</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;, amount: u64): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt; {
    <b>let</b> inner = self.inner.split(amount);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id: self.facil_id, inner }
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fds_withdraw_all"></a>

## Function `fds_withdraw_all`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_withdraw_all">fds_withdraw_all</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_withdraw_all">fds_withdraw_all</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt; {
    <b>let</b> inner = self.inner.withdraw_all();
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id: self.facil_id, inner }
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fds_join"></a>

## Function `fds_join`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_join">fds_join</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;, other: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_join">fds_join</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;, other: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;) {
    <b>assert</b>!(self.facil_id == other.facil_id, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EShareFacilMismatch">EShareFacilMismatch</a>);
    <b>let</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id: _, inner: other } = other;
    self.inner.join(other);
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fds_destroy_zero"></a>

## Function `fds_destroy_zero`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_destroy_zero">fds_destroy_zero</a>&lt;ST&gt;(shares: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fds_destroy_zero">fds_destroy_zero</a>&lt;ST&gt;(shares: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;) {
    <b>let</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id: _, inner: shares } = shares;
    shares.destroy_zero();
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_empty_facil_debt_bag"></a>

## Function `empty_facil_debt_bag`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_empty_facil_debt_bag">empty_facil_debt_bag</a>(facil_id: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_empty_facil_debt_bag">empty_facil_debt_bag</a>(facil_id: ID, ctx: &<b>mut</b> TxContext): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a> {
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a> {
        id: object::new(ctx),
        facil_id,
        inner: debt_bag::empty(ctx),
    }
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_add"></a>

## Function `fdb_add`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_add">fdb_add</a>&lt;T, ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>, shares: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_add">fdb_add</a>&lt;T, ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>, shares: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt;) {
    <b>assert</b>!(self.facil_id == shares.facil_id, <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_EShareFacilMismatch">EShareFacilMismatch</a>);
    <b>let</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id: _, inner: shares } = shares;
    self.inner.add&lt;T, ST&gt;(shares);
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_take_amt"></a>

## Function `fdb_take_amt`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_take_amt">fdb_take_amt</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>, amount: u128): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_take_amt">fdb_take_amt</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>, amount: u128): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt; {
    <b>let</b> shares = self.inner.take_amt(amount);
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id: self.facil_id, inner: shares }
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_take_all"></a>

## Function `fdb_take_all`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_take_all">fdb_take_all</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">kai_leverage::supply_pool::FacilDebtShare</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_take_all">fdb_take_all</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>): <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a>&lt;ST&gt; {
    <b>let</b> shares = self.inner.take_all();
    <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtShare">FacilDebtShare</a> { facil_id: self.facil_id, inner: shares }
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_get_share_amount_by_asset_type"></a>

## Function `fdb_get_share_amount_by_asset_type`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_get_share_amount_by_asset_type">fdb_get_share_amount_by_asset_type</a>&lt;T&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_get_share_amount_by_asset_type">fdb_get_share_amount_by_asset_type</a>&lt;T&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>): u128 {
    self.inner.get_share_amount_by_asset_type&lt;T&gt;()
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_get_share_amount_by_share_type"></a>

## Function `fdb_get_share_amount_by_share_type`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_get_share_amount_by_share_type">fdb_get_share_amount_by_share_type</a>&lt;ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_get_share_amount_by_share_type">fdb_get_share_amount_by_share_type</a>&lt;ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>): u128 {
    self.inner.get_share_amount_by_share_type&lt;ST&gt;()
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_share_type_matches_asset_if_any_exists"></a>

## Function `fdb_share_type_matches_asset_if_any_exists`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_share_type_matches_asset_if_any_exists">fdb_share_type_matches_asset_if_any_exists</a>&lt;T, ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_share_type_matches_asset_if_any_exists">fdb_share_type_matches_asset_if_any_exists</a>&lt;T, ST&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>): bool {
    self.inner.share_type_matches_asset_if_any_exists&lt;T, ST&gt;()
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_get_share_type_for_asset"></a>

## Function `fdb_get_share_type_for_asset`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_get_share_type_for_asset">fdb_get_share_type_for_asset</a>&lt;T&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>): <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_get_share_type_for_asset">fdb_get_share_type_for_asset</a>&lt;T&gt;(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>): TypeName {
    self.inner.get_share_type_for_asset&lt;T&gt;()
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_is_empty"></a>

## Function `fdb_is_empty`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_is_empty">fdb_is_empty</a>(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_is_empty">fdb_is_empty</a>(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>): bool {
    self.inner.is_empty()
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_destroy_empty"></a>

## Function `fdb_destroy_empty`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_destroy_empty">fdb_destroy_empty</a>(self: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_destroy_empty">fdb_destroy_empty</a>(self: <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>) {
    <b>let</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a> { id, facil_id: _, inner } = self;
    id.delete();
    inner.destroy_empty();
}
</code></pre>



</details>

<a name="kai_leverage_supply_pool_fdb_length"></a>

## Function `fdb_length`



<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_length">fdb_length</a>(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">kai_leverage::supply_pool::FacilDebtBag</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_fdb_length">fdb_length</a>(self: &<a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_FacilDebtBag">FacilDebtBag</a>): u64 {
    self.inner.length()
}
</code></pre>



</details>

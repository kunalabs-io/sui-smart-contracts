
<a name="kai_leverage_debt_info"></a>

# Module `kai_leverage::debt_info`

Debt information for a <code>SupplyPool</code> lending facility. Can contain
debt information for multiple share types for the same lending facility.


-  [Struct `DebtInfoEntry`](#kai_leverage_debt_info_DebtInfoEntry)
-  [Struct `DebtInfo`](#kai_leverage_debt_info_DebtInfo)
-  [Struct `ValidatedDebtInfo`](#kai_leverage_debt_info_ValidatedDebtInfo)
-  [Constants](#@Constants_0)
-  [Function `empty`](#kai_leverage_debt_info_empty)
-  [Function `facil_id`](#kai_leverage_debt_info_facil_id)
-  [Function `add`](#kai_leverage_debt_info_add)
-  [Function `add_from_supply_pool`](#kai_leverage_debt_info_add_from_supply_pool)
-  [Function `validate`](#kai_leverage_debt_info_validate)
-  [Function `calc_repay_x64`](#kai_leverage_debt_info_calc_repay_x64)
-  [Function `calc_repay_lossy`](#kai_leverage_debt_info_calc_repay_lossy)
-  [Function `calc_repay_for_amount`](#kai_leverage_debt_info_calc_repay_for_amount)
-  [Function `calc_repay_by_shares`](#kai_leverage_debt_info_calc_repay_by_shares)
-  [Function `calc_repay_by_amount`](#kai_leverage_debt_info_calc_repay_by_amount)


<pre><code><b>use</b> <a href="../../dependencies/access_management/access.md#access_management_access">access_management::access</a>;
<b>use</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map">access_management::dynamic_map</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt">kai_leverage::debt</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag">kai_leverage::debt_bag</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/equity.md#kai_leverage_equity">kai_leverage::equity</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise">kai_leverage::piecewise</a>;
<b>use</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool">kai_leverage::supply_pool</a>;
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



<a name="kai_leverage_debt_info_DebtInfoEntry"></a>

## Struct `DebtInfoEntry`

Entry containing debt information for a specific share type.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfoEntry">DebtInfoEntry</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>supply_x64: u128</code>
</dt>
<dd>
</dd>
<dt>
<code>liability_value_x64: u128</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_debt_info_DebtInfo"></a>

## Struct `DebtInfo`

Collection of debt information for a lending facility.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">DebtInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a></code>
</dt>
<dd>
</dd>
<dt>
<code>map: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfoEntry">kai_leverage::debt_info::DebtInfoEntry</a>&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_debt_info_ValidatedDebtInfo"></a>

## Struct `ValidatedDebtInfo`

Validated debt information ready for calculations. Extra percausion to ensure
the info is for the expected lending facility.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">ValidatedDebtInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>map: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfoEntry">kai_leverage::debt_info::DebtInfoEntry</a>&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_debt_info_Q64"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_Q64">Q64</a>: u128 = 18446744073709551616;
</code></pre>



<a name="kai_leverage_debt_info_EInvalidFacilID"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_EInvalidFacilID">EInvalidFacilID</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_debt_info_empty"></a>

## Function `empty`

Create an empty debt info collection for a lending facility.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_empty">empty</a>(<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>): <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_empty">empty</a>(<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>: ID): <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">DebtInfo</a> {
    <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">DebtInfo</a> { <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>, map: vec_map::empty() }
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_facil_id"></a>

## Function `facil_id`

Get the lending facility ID.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>): <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">DebtInfo</a>): ID {
    self.<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_add"></a>

## Function `add`

Add debt information from a debt registry.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_add">add</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, registry: &<a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt_DebtRegistry">kai_leverage::debt::DebtRegistry</a>&lt;ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_add">add</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">DebtInfo</a>, registry: &DebtRegistry&lt;ST&gt;) {
    <b>let</b> <b>entry</b> = <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfoEntry">DebtInfoEntry</a> {
        supply_x64: registry.supply_x64(),
        liability_value_x64: registry.liability_value_x64(),
    };
    self.map.insert(type_name::with_defining_ids&lt;ST&gt;(), <b>entry</b>);
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_add_from_supply_pool"></a>

## Function `add_from_supply_pool`

Add debt information from a <code>SupplyPool</code>'s debt registry for the matching lending facility.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_add_from_supply_pool">add_from_supply_pool</a>&lt;T, ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, pool: &<b>mut</b> <a href="../../dependencies/kai_leverage/supply_pool.md#kai_leverage_supply_pool_SupplyPool">kai_leverage::supply_pool::SupplyPool</a>&lt;T, ST&gt;, clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_add_from_supply_pool">add_from_supply_pool</a>&lt;T, ST&gt;(
    self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">DebtInfo</a>,
    pool: &<b>mut</b> SupplyPool&lt;T, ST&gt;,
    clock: &Clock,
) {
    <b>let</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a> = self.<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>;
    <b>let</b> registry = pool.borrow_debt_registry(&<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>, clock);
    <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_add">add</a>(self, registry);
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_validate"></a>

## Function `validate`

Validate debt info and return validated version for calculations. Extra percausion to ensure
the info is for the expected lending facility.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_validate">validate</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">kai_leverage::debt_info::DebtInfo</a>, <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>: <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>): <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">kai_leverage::debt_info::ValidatedDebtInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_validate">validate</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_DebtInfo">DebtInfo</a>, <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>: ID): <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">ValidatedDebtInfo</a> {
    <b>assert</b>!(self.<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a> == <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_facil_id">facil_id</a>, <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_EInvalidFacilID">EInvalidFacilID</a>);
    <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">ValidatedDebtInfo</a> { map: self.map }
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_calc_repay_x64"></a>

## Function `calc_repay_x64`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_x64">calc_repay_x64</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">kai_leverage::debt_info::ValidatedDebtInfo</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, share_value_x64: u128): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_x64">calc_repay_x64</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">ValidatedDebtInfo</a>, `type`: TypeName, share_value_x64: u128): u128 {
    <b>let</b> <b>entry</b> = &self.map[&`type`];
    util::muldiv_round_up_u128(
        <b>entry</b>.liability_value_x64,
        share_value_x64,
        <b>entry</b>.supply_x64,
    )
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_calc_repay_lossy"></a>

## Function `calc_repay_lossy`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_lossy">calc_repay_lossy</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">kai_leverage::debt_info::ValidatedDebtInfo</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, share_value_x64: u128): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_lossy">calc_repay_lossy</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">ValidatedDebtInfo</a>, `type`: TypeName, share_value_x64: u128): u64 {
    <b>let</b> value_x64 = <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_x64">calc_repay_x64</a>(self, `type`, share_value_x64);
    util::divide_and_round_up_u128(value_x64, <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_Q64">Q64</a>) <b>as</b> u64
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_calc_repay_for_amount"></a>

## Function `calc_repay_for_amount`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_for_amount">calc_repay_for_amount</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">kai_leverage::debt_info::ValidatedDebtInfo</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, amount: u64): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_for_amount">calc_repay_for_amount</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">ValidatedDebtInfo</a>, `type`: TypeName, amount: u64): u128 {
    <b>let</b> <b>entry</b> = &self.map[&`type`];
    util::muldiv_u128(
        (amount <b>as</b> u128) * <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_Q64">Q64</a>,
        <b>entry</b>.supply_x64,
        <b>entry</b>.liability_value_x64,
    )
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_calc_repay_by_shares"></a>

## Function `calc_repay_by_shares`

Calculates the debt amount that needs to be repaid for the given amount of debt shares.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_by_shares">calc_repay_by_shares</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">kai_leverage::debt_info::ValidatedDebtInfo</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, share_value_x64: u128): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_by_shares">calc_repay_by_shares</a>(
    self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">ValidatedDebtInfo</a>,
    `type`: TypeName,
    share_value_x64: u128,
): u64 {
    <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_lossy">calc_repay_lossy</a>(self, `type`, share_value_x64)
}
</code></pre>



</details>

<a name="kai_leverage_debt_info_calc_repay_by_amount"></a>

## Function `calc_repay_by_amount`

Calculates the debt share amount required to repay the given amount of debt.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_by_amount">calc_repay_by_amount</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">kai_leverage::debt_info::ValidatedDebtInfo</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, amount: u64): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_by_amount">calc_repay_by_amount</a>(self: &<a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_ValidatedDebtInfo">ValidatedDebtInfo</a>, `type`: TypeName, amount: u64): u128 {
    <a href="../../dependencies/kai_leverage/debt_info.md#kai_leverage_debt_info_calc_repay_for_amount">calc_repay_for_amount</a>(self, `type`, amount)
}
</code></pre>



</details>

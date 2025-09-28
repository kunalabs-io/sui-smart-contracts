
<a name="kai_leverage_debt_bag"></a>

# Module `kai_leverage::debt_bag`

Collection for managing heterogeneous debt share balances.

This module provides a type-safe collection that can store debt shares for multiple
asset types and share types simultaneously. It enforces a one-to-one mapping between
asset types and their corresponding share types: for any asset type <code>T</code>, there can be
only a single associated debt share type <code>ST</code>, and vice versa. This ensures type-level
consistency and prevents ambiguous or conflicting associations between assets and shares.

Key properties:
- Enforces a unique mapping between each asset type and its share type (bijective mapping)
- Validates type consistency to prevent mismatched operations
- Supports partial and full withdrawals by share type
- Tracks total amounts for efficient queries


-  [Struct `Info`](#kai_leverage_debt_bag_Info)
-  [Struct `DebtBag`](#kai_leverage_debt_bag_DebtBag)
-  [Struct `Key`](#kai_leverage_debt_bag_Key)
-  [Constants](#@Constants_0)
-  [Function `empty`](#kai_leverage_debt_bag_empty)
-  [Function `get_asset_idx_opt`](#kai_leverage_debt_bag_get_asset_idx_opt)
-  [Function `get_share_idx_opt`](#kai_leverage_debt_bag_get_share_idx_opt)
-  [Function `get_share_idx`](#kai_leverage_debt_bag_get_share_idx)
-  [Function `key`](#kai_leverage_debt_bag_key)
-  [Function `add`](#kai_leverage_debt_bag_add)
-  [Function `take_amt`](#kai_leverage_debt_bag_take_amt)
-  [Function `take_all`](#kai_leverage_debt_bag_take_all)
-  [Function `get_share_amount_by_asset_type`](#kai_leverage_debt_bag_get_share_amount_by_asset_type)
-  [Function `get_share_amount_by_share_type`](#kai_leverage_debt_bag_get_share_amount_by_share_type)
-  [Function `get_share_type_for_asset`](#kai_leverage_debt_bag_get_share_type_for_asset)
-  [Function `share_type_matches_asset_if_any_exists`](#kai_leverage_debt_bag_share_type_matches_asset_if_any_exists)
-  [Function `is_empty`](#kai_leverage_debt_bag_is_empty)
-  [Function `destroy_empty`](#kai_leverage_debt_bag_destroy_empty)
-  [Function `size`](#kai_leverage_debt_bag_size)
-  [Function `length`](#kai_leverage_debt_bag_length)


<pre><code><b>use</b> <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt">kai_leverage::debt</a>;
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



<a name="kai_leverage_debt_bag_Info"></a>

## Struct `Info`

Internal info about shares stored per asset/share type.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Info">Info</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>asset_type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>share_type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>amount: u128</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_debt_bag_DebtBag"></a>

## Struct `DebtBag`

Collection of debt shares for multiple facilities and share types.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a> <b>has</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>, store
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
<code>infos: vector&lt;<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Info">kai_leverage::debt_bag::Info</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>bag: <a href="../../dependencies/sui/bag.md#sui_bag_Bag">sui::bag::Bag</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_debt_bag_Key"></a>

## Struct `Key`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Key">Key</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>t: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
<dt>
<code>st: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_debt_bag_EAssetShareTypeMismatch"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_EAssetShareTypeMismatch">EAssetShareTypeMismatch</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_debt_bag_ETypeDoesNotExist"></a>

The requested asset or share type does not exist in the debt bag.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_ETypeDoesNotExist">ETypeDoesNotExist</a>: u64 = 1;
</code></pre>



<a name="kai_leverage_debt_bag_ENotEnough"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_ENotEnough">ENotEnough</a>: u64 = 2;
</code></pre>



<a name="kai_leverage_debt_bag_empty"></a>

## Function `empty`

Create an empty <code><a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_empty">empty</a>(ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_empty">empty</a>(ctx: &<b>mut</b> TxContext): <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a> {
    <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a> {
        id: object::new(ctx),
        infos: vector::empty(),
        bag: bag::new(ctx),
    }
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_get_asset_idx_opt"></a>

## Function `get_asset_idx_opt`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_asset_idx_opt">get_asset_idx_opt</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>, asset_type: &<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_asset_idx_opt">get_asset_idx_opt</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>, asset_type: &TypeName): Option&lt;u64&gt; {
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = vector::length(&self.infos);
    <b>while</b> (i &lt; n) {
        <b>let</b> info = &self.infos[i];
        <b>if</b> (&info.asset_type == asset_type) {
            <b>return</b> option::some(i)
        };
        i = i + 1;
    };
    option::none()
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_get_share_idx_opt"></a>

## Function `get_share_idx_opt`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_idx_opt">get_share_idx_opt</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>, share_type: &<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_idx_opt">get_share_idx_opt</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>, share_type: &TypeName): Option&lt;u64&gt; {
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = self.infos.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_length">length</a>();
    <b>while</b> (i &lt; n) {
        <b>let</b> info = &self.infos[i];
        <b>if</b> (&info.share_type == share_type) {
            <b>return</b> option::some(i)
        };
        i = i + 1;
    };
    option::none()
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_get_share_idx"></a>

## Function `get_share_idx`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_idx">get_share_idx</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>, share_type: &<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_idx">get_share_idx</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>, share_type: &TypeName): u64 {
    <b>let</b> idx_opt = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_idx_opt">get_share_idx_opt</a>(self, share_type);
    <b>assert</b>!(option::is_some(&idx_opt), <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_ETypeDoesNotExist">ETypeDoesNotExist</a>);
    idx_opt.destroy_some()
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_key"></a>

## Function `key`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>(info: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Info">kai_leverage::debt_bag::Info</a>): <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Key">kai_leverage::debt_bag::Key</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>(info: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Info">Info</a>): <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Key">Key</a> {
    <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Key">Key</a> {
        t: info.asset_type,
        st: info.share_type,
    }
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_add"></a>

## Function `add`

Add <code>DebtShareBalance&lt;ST&gt;</code> for asset <code>T</code>, merging with existing entry when present.

Guarantees:
- Enforces bijective mapping between asset type <code>T</code> and share type <code>ST</code>
- Merges with existing shares if asset exists, creates new entry otherwise
- Automatically destroys zero-value shares
- Maintains synchronized state between <code>infos</code> vector and <code>bag</code> storage
- Aborts with <code><a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_EAssetShareTypeMismatch">EAssetShareTypeMismatch</a></code> if share type conflicts with existing asset


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_add">add</a>&lt;T, ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>, shares: <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt_DebtShareBalance">kai_leverage::debt::DebtShareBalance</a>&lt;ST&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_add">add</a>&lt;T, ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>, shares: DebtShareBalance&lt;ST&gt;) {
    <b>let</b> asset_type = type_name::with_defining_ids&lt;T&gt;();
    <b>let</b> share_type = type_name::with_defining_ids&lt;ST&gt;();
    <b>if</b> (shares.value_x64() == 0) {
        shares.destroy_zero();
        <b>return</b>
    };
    <b>let</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a> = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Key">Key</a> { t: asset_type, st: share_type };
    <b>let</b> idx_opt = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_asset_idx_opt">get_asset_idx_opt</a>(self, &asset_type);
    <b>if</b> (idx_opt.is_some()) {
        <b>let</b> idx = idx_opt.destroy_some();
        <b>let</b> info = &<b>mut</b> self.infos[idx];
        <b>assert</b>!(info.share_type == share_type, <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_EAssetShareTypeMismatch">EAssetShareTypeMismatch</a>);
        info.amount = info.amount + shares.value_x64();
        debt::join(&<b>mut</b> self.bag[<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>], shares);
    } <b>else</b> {
        // ensure that the share type is unique
        <b>let</b> <b>mut</b> i = 0;
        <b>let</b> n = self.infos.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_length">length</a>();
        <b>while</b> (i &lt; n) {
            <b>let</b> info = &self.infos[i];
            <b>assert</b>!(info.share_type != share_type, <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_EAssetShareTypeMismatch">EAssetShareTypeMismatch</a>);
            i = i + 1;
        };
        <b>let</b> info = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Info">Info</a> {
            asset_type,
            share_type,
            amount: shares.value_x64(),
        };
        self.infos.push_back(info);
        bag::add(&<b>mut</b> self.bag, <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>, shares);
    };
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_take_amt"></a>

## Function `take_amt`

Take <code>amount</code> of shares of type <code>ST</code> from the bag. Returns zero if <code>amount</code> is 0.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_take_amt">take_amt</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>, amount: u128): <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt_DebtShareBalance">kai_leverage::debt::DebtShareBalance</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_take_amt">take_amt</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>, amount: u128): DebtShareBalance&lt;ST&gt; {
    <b>if</b> (amount == 0) {
        <b>return</b> debt::zero()
    };
    <b>let</b> type_st = type_name::with_defining_ids&lt;ST&gt;();
    <b>let</b> idx = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_idx">get_share_idx</a>(self, &type_st);
    <b>let</b> info = &<b>mut</b> self.infos[idx];
    <b>assert</b>!(amount &lt;= info.amount, <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_ENotEnough">ENotEnough</a>);
    <b>let</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a> = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>(info);
    <b>let</b> shares = debt::split_x64(&<b>mut</b> self.bag[<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>], amount);
    info.amount = info.amount - amount;
    <b>if</b> (info.amount == 0) {
        <b>let</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Info">Info</a> { asset_type: _, share_type: _, amount: _ } = self.infos.remove(idx);
        <b>let</b> zero = self.bag.remove(<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>);
        debt::destroy_zero&lt;ST&gt;(zero);
    };
    shares
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_take_all"></a>

## Function `take_all`

Remove and return all shares of type <code>ST</code>. Returns zero if not present.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_take_all">take_all</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>): <a href="../../dependencies/kai_leverage/debt.md#kai_leverage_debt_DebtShareBalance">kai_leverage::debt::DebtShareBalance</a>&lt;ST&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_take_all">take_all</a>&lt;ST&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>): DebtShareBalance&lt;ST&gt; {
    <b>let</b> type_st = type_name::with_defining_ids&lt;ST&gt;();
    <b>let</b> idx_opt = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_idx_opt">get_share_idx_opt</a>(self, &type_st);
    <b>if</b> (idx_opt.is_none()) {
        <b>return</b> debt::zero()
    };
    <b>let</b> idx = idx_opt.destroy_some();
    <b>let</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a> = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>(&self.infos[idx]);
    <b>let</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_Info">Info</a> { asset_type: _, share_type: _, amount: _ } = self.infos.remove(idx);
    <b>let</b> shares = self.bag.remove(<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_key">key</a>);
    shares
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_get_share_amount_by_asset_type"></a>

## Function `get_share_amount_by_asset_type`

Total shares amount for the given asset type <code>T</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_amount_by_asset_type">get_share_amount_by_asset_type</a>&lt;T&gt;(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_amount_by_asset_type">get_share_amount_by_asset_type</a>&lt;T&gt;(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>): u128 {
    <b>let</b> asset_type = type_name::with_defining_ids&lt;T&gt;();
    <b>let</b> idx_opt = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_asset_idx_opt">get_asset_idx_opt</a>(self, &asset_type);
    <b>if</b> (idx_opt.is_none()) {
        <b>return</b> 0
    } <b>else</b> {
        <b>let</b> idx = idx_opt.destroy_some();
        <b>let</b> info = &self.infos[idx];
        info.amount
    }
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_get_share_amount_by_share_type"></a>

## Function `get_share_amount_by_share_type`

Total shares amount for the given share type <code>ST</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_amount_by_share_type">get_share_amount_by_share_type</a>&lt;ST&gt;(debt_bag: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>): u128
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_amount_by_share_type">get_share_amount_by_share_type</a>&lt;ST&gt;(debt_bag: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>): u128 {
    <b>let</b> share_type = type_name::with_defining_ids&lt;ST&gt;();
    <b>let</b> idx_opt = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_idx_opt">get_share_idx_opt</a>(debt_bag, &share_type);
    <b>if</b> (idx_opt.is_none()) {
        <b>return</b> 0
    } <b>else</b> {
        <b>let</b> idx = idx_opt.destroy_some();
        <b>let</b> info = &debt_bag.infos[idx];
        info.amount
    }
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_get_share_type_for_asset"></a>

## Function `get_share_type_for_asset`

Get the share type corresponding to asset type <code>T</code>. Aborts if none.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_type_for_asset">get_share_type_for_asset</a>&lt;T&gt;(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>): <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_share_type_for_asset">get_share_type_for_asset</a>&lt;T&gt;(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>): TypeName {
    <b>let</b> asset_type = type_name::with_defining_ids&lt;T&gt;();
    <b>let</b> idx_opt = <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_get_asset_idx_opt">get_asset_idx_opt</a>(self, &asset_type);
    <b>assert</b>!(idx_opt.is_some(), <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_ETypeDoesNotExist">ETypeDoesNotExist</a>);
    <b>let</b> idx = idx_opt.destroy_some();
    <b>let</b> info = &self.infos[idx];
    info.share_type
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_share_type_matches_asset_if_any_exists"></a>

## Function `share_type_matches_asset_if_any_exists`

Returns true if either:
- Neither the asset type <code>T</code> nor the share type <code>ST</code> exist in the <code><a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a></code>, or
- Both exist and the share type corresponds to the asset type.
Returns false if only one exists, or if both exist but the share type
does not correspond to the asset type.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_share_type_matches_asset_if_any_exists">share_type_matches_asset_if_any_exists</a>&lt;T, ST&gt;(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_share_type_matches_asset_if_any_exists">share_type_matches_asset_if_any_exists</a>&lt;T, ST&gt;(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>): bool {
    <b>let</b> asset_type = type_name::with_defining_ids&lt;T&gt;();
    <b>let</b> share_type = type_name::with_defining_ids&lt;ST&gt;();
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = self.infos.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_length">length</a>();
    <b>while</b> (i &lt; n) {
        <b>let</b> info = &self.infos[i];
        <b>if</b> (info.asset_type == asset_type || info.share_type == share_type) {
            <b>return</b> info.asset_type == asset_type && info.share_type == share_type
        };
        i = i + 1;
    };
    <b>return</b> <b>true</b>
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_is_empty"></a>

## Function `is_empty`

True if the bag contains no entries.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_is_empty">is_empty</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_is_empty">is_empty</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>): bool {
    // infos is <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_empty">empty</a> iff. bag is <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_empty">empty</a>, but <b>let</b>'s be explicit
    self.infos.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_is_empty">is_empty</a>() && self.bag.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_is_empty">is_empty</a>()
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_destroy_empty"></a>

## Function `destroy_empty`

Destroy an empty bag and its inner storage.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_destroy_empty">destroy_empty</a>(self: <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_destroy_empty">destroy_empty</a>(self: <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>) {
    <b>let</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a> { id, infos, bag } = self;
    id.delete();
    infos.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_destroy_empty">destroy_empty</a>();
    bag.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_destroy_empty">destroy_empty</a>();
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_size"></a>

## Function `size`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_size">size</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_size">size</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>): u64 {
    self.infos.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_length">length</a>()
}
</code></pre>



</details>

<a name="kai_leverage_debt_bag_length"></a>

## Function `length`

Number of different asset/share entries in the bag.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_length">length</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">kai_leverage::debt_bag::DebtBag</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_length">length</a>(self: &<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_DebtBag">DebtBag</a>): u64 {
    self.infos.<a href="../../dependencies/kai_leverage/debt_bag.md#kai_leverage_debt_bag_length">length</a>()
}
</code></pre>



</details>


<a name="kai_leverage_balance_bag"></a>

# Module `kai_leverage::balance_bag`

Collection for managing heterogeneous token balances.

This module provides a type-safe collection that can store balances for multiple
coin types simultaneously. It's commonly used in scenarios where a single entity
needs to hold and manage various token types, such as collateral management in
lending protocols or multi-asset treasury systems.

Key properties:
- Maintains summary information for efficient queries
- Supports partial and full withdrawals by token type
- Automatically handles zero-balance cleanup


-  [Struct `BalanceBag`](#kai_leverage_balance_bag_BalanceBag)
-  [Function `empty`](#kai_leverage_balance_bag_empty)
-  [Function `amounts`](#kai_leverage_balance_bag_amounts)
-  [Function `add`](#kai_leverage_balance_bag_add)
-  [Function `take_all`](#kai_leverage_balance_bag_take_all)
-  [Function `take_amount`](#kai_leverage_balance_bag_take_amount)
-  [Function `is_empty`](#kai_leverage_balance_bag_is_empty)
-  [Function `destroy_empty`](#kai_leverage_balance_bag_destroy_empty)


<pre><code><b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
</code></pre>



<a name="kai_leverage_balance_bag_BalanceBag"></a>

## Struct `BalanceBag`

Collection that stores balances for multiple coin types.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a> <b>has</b> key, store
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
<code><a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>inner: <a href="../../dependencies/sui/bag.md#sui_bag_Bag">sui::bag::Bag</a></code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_balance_bag_empty"></a>

## Function `empty`

Create an empty <code><a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_empty">empty</a>(ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_empty">empty</a>(ctx: &<b>mut</b> TxContext): <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a> {
    <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a> {
        id: object::new(ctx),
        <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>: vec_map::empty(),
        inner: bag::new(ctx),
    }
}
</code></pre>



</details>

<a name="kai_leverage_balance_bag_amounts"></a>

## Function `amounts`

Get a read-only map of amounts per coin type.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>(self: &<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>): &<a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>(self: &<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a>): &VecMap&lt;TypeName, u64&gt; {
    &self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>
}
</code></pre>



</details>

<a name="kai_leverage_balance_bag_add"></a>

## Function `add`

Add a <code>Balance&lt;T&gt;</code> to the bag, joining with existing balance if present.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_add">add</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, balance: <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_add">add</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a>, balance: Balance&lt;T&gt;) {
    <b>let</b> `type` = type_name::with_defining_ids&lt;T&gt;();
    <b>if</b> (balance.value() == 0) {
        balance::destroy_zero(balance);
        <b>return</b>
    };
    <b>if</b> (self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>.contains(&`type`)) {
        <b>let</b> bag_balance = &<b>mut</b> self.inner[`type`];
        <b>let</b> balance_amount = balance.value();
        balance::join(bag_balance, balance);
        <b>let</b> amount = &<b>mut</b> self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>[&`type`];
        *amount = *amount + balance_amount
    } <b>else</b> {
        vec_map::insert(&<b>mut</b> self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>, `type`, balance.value());
        bag::add(&<b>mut</b> self.inner, `type`, balance);
    }
}
</code></pre>



</details>

<a name="kai_leverage_balance_bag_take_all"></a>

## Function `take_all`

Remove and return the entire <code>Balance&lt;T&gt;</code> for type <code>T</code>. Returns zero if absent.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_take_all">take_all</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_take_all">take_all</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a>): Balance&lt;T&gt; {
    <b>let</b> `type` = type_name::with_defining_ids&lt;T&gt;();
    <b>if</b> (!self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>.contains(&`type`)) {
        <b>return</b> balance::zero()
    };
    <b>let</b> balance = self.inner.remove(`type`);
    self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>.remove(&`type`);
    balance
}
</code></pre>



</details>

<a name="kai_leverage_balance_bag_take_amount"></a>

## Function `take_amount`

Remove and return <code>amount</code> of <code>Balance&lt;T&gt;</code>. Returns zero if <code>amount</code> is 0.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_take_amount">take_amount</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>, amount: u64): <a href="../../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_take_amount">take_amount</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a>, amount: u64): Balance&lt;T&gt; {
    <b>if</b> (amount == 0) {
        <b>return</b> balance::zero()
    };
    <b>let</b> `type` = type_name::with_defining_ids&lt;T&gt;();
    <b>let</b> inner_amount = vec_map::get_mut(&<b>mut</b> self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>, &`type`);
    <b>if</b> (*inner_amount == amount) {
        <b>let</b> balance = self.inner.remove(`type`);
        self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>.remove(&`type`);
        <b>return</b> balance
    };
    <b>let</b> bag_balance = &<b>mut</b> self.inner[`type`];
    <b>let</b> balance = balance::split(bag_balance, amount);
    *inner_amount = *inner_amount - amount;
    balance
}
</code></pre>



</details>

<a name="kai_leverage_balance_bag_is_empty"></a>

## Function `is_empty`

True if the bag contains no balances.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_is_empty">is_empty</a>(self: &<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_is_empty">is_empty</a>(self: &<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a>): bool {
    // <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a> is <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_empty">empty</a> iff. bag is <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_empty">empty</a>, but <b>let</b>'s be explicit
    self.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_is_empty">is_empty</a>() && self.inner.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_is_empty">is_empty</a>()
}
</code></pre>



</details>

<a name="kai_leverage_balance_bag_destroy_empty"></a>

## Function `destroy_empty`

Destroy an empty bag.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_destroy_empty">destroy_empty</a>(self: <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">kai_leverage::balance_bag::BalanceBag</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_destroy_empty">destroy_empty</a>(self: <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a>) {
    <b>let</b> <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_BalanceBag">BalanceBag</a> { id, <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>, inner } = self;
    object::delete(id);
    <a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_amounts">amounts</a>.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_destroy_empty">destroy_empty</a>();
    inner.<a href="../../dependencies/kai_leverage/balance_bag.md#kai_leverage_balance_bag_destroy_empty">destroy_empty</a>();
}
</code></pre>



</details>

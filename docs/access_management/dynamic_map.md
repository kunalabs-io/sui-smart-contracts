
<a name="access_management_dynamic_map"></a>

# Module `access_management::dynamic_map`

A map collection where the keys are homogeneous and the values are heterogeneous. Both keys and
values are stored using Sui's object system (dynamic fields). Values must have <code>store</code>, <code><b>copy</b></code>,
and <code>drop</code> capabilities.


-  [Struct `DynamicMap`](#access_management_dynamic_map_DynamicMap)
-  [Constants](#@Constants_0)
-  [Function `new`](#access_management_dynamic_map_new)
-  [Function `insert`](#access_management_dynamic_map_insert)
-  [Function `borrow`](#access_management_dynamic_map_borrow)
-  [Function `borrow_mut`](#access_management_dynamic_map_borrow_mut)
-  [Function `remove`](#access_management_dynamic_map_remove)
-  [Function `contains`](#access_management_dynamic_map_contains)
-  [Function `length`](#access_management_dynamic_map_length)
-  [Function `is_empty`](#access_management_dynamic_map_is_empty)
-  [Function `destroy_empty`](#access_management_dynamic_map_destroy_empty)
-  [Function `force_drop`](#access_management_dynamic_map_force_drop)


<pre><code><b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
</code></pre>



<a name="access_management_dynamic_map_DynamicMap"></a>

## Struct `DynamicMap`

A dynamic map where keys are homogeneous and values are heterogeneous.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;<b>phantom</b> K: <b>copy</b>, drop, store&gt; <b>has</b> key, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="../../dependencies/sui/object.md#sui_object_UID">sui::object::UID</a></code>
</dt>
<dd>
 the ID of this map
</dd>
<dt>
<code>size: u64</code>
</dt>
<dd>
 the number of key-value pairs in the map
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="access_management_dynamic_map_EMapNotEmpty"></a>



<pre><code><b>const</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_EMapNotEmpty">EMapNotEmpty</a>: u64 = 0;
</code></pre>



<a name="access_management_dynamic_map_new"></a>

## Function `new`

Creates a new, empty map


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_new">new</a>&lt;K: <b>copy</b>, drop, store&gt;(ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>): <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_new">new</a>&lt;K: <b>copy</b> + drop + store&gt;(ctx: &<b>mut</b> TxContext): <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt; {
    <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a> {
        id: object::new(ctx),
        size: 0,
    }
}
</code></pre>



</details>

<a name="access_management_dynamic_map_insert"></a>

## Function `insert`

Adds a key-value pair to the map <code>map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;</code>
Aborts with <code><a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field_EFieldAlreadyExists">sui::dynamic_field::EFieldAlreadyExists</a></code> if the map already has an entry with
that key <code>k: K</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_insert">insert</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, drop, store&gt;(map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;, k: K, v: V)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_insert">insert</a>&lt;K: <b>copy</b> + drop + store, V: <b>copy</b> + drop + store&gt;(
    map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;,
    k: K,
    v: V,
) {
    field::add(&<b>mut</b> map.id, k, v);
    map.size = map.size + 1;
}
</code></pre>



</details>

<a name="access_management_dynamic_map_borrow"></a>

## Function `borrow`

Immutable borrows the value associated with the key in the map <code>map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;</code>.
Aborts with <code><a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field_EFieldDoesNotExist">sui::dynamic_field::EFieldDoesNotExist</a></code> if the map does not have an entry with
that key <code>k: K</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_borrow">borrow</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, drop, store&gt;(map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;, k: K): &V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_borrow">borrow</a>&lt;K: <b>copy</b> + drop + store, V: <b>copy</b> + drop + store&gt;(map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;, k: K): &V {
    field::borrow(&map.id, k)
}
</code></pre>



</details>

<a name="access_management_dynamic_map_borrow_mut"></a>

## Function `borrow_mut`

Mutably borrows the value associated with the key in the map <code>map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;</code>.
Aborts with <code><a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field_EFieldDoesNotExist">sui::dynamic_field::EFieldDoesNotExist</a></code> if the map does not have an entry with
that key <code>k: K</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_borrow_mut">borrow_mut</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, drop, store&gt;(map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;, k: K): &<b>mut</b> V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_borrow_mut">borrow_mut</a>&lt;K: <b>copy</b> + drop + store, V: <b>copy</b> + drop + store&gt;(
    map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;,
    k: K,
): &<b>mut</b> V {
    field::borrow_mut(&<b>mut</b> map.id, k)
}
</code></pre>



</details>

<a name="access_management_dynamic_map_remove"></a>

## Function `remove`

Removes the key-value pair in the map <code>map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;</code> and returns the value.
Aborts with <code><a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field_EFieldDoesNotExist">sui::dynamic_field::EFieldDoesNotExist</a></code> if the map does not have an entry with
that key <code>k: K</code>.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_remove">remove</a>&lt;K: <b>copy</b>, drop, store, V: <b>copy</b>, drop, store&gt;(map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;, k: K): V
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_remove">remove</a>&lt;K: <b>copy</b> + drop + store, V: <b>copy</b> + drop + store&gt;(
    map: &<b>mut</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;,
    k: K,
): V {
    <b>let</b> v = field::remove(&<b>mut</b> map.id, k);
    map.size = map.size - 1;
    v
}
</code></pre>



</details>

<a name="access_management_dynamic_map_contains"></a>

## Function `contains`

Returns true iff there is a value associated with the key <code>k: K</code> in map <code>map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;</code>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_contains">contains</a>&lt;K: <b>copy</b>, drop, store&gt;(map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;, k: K): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_contains">contains</a>&lt;K: <b>copy</b> + drop + store&gt;(map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;, k: K): bool {
    field::exists_&lt;K&gt;(&map.id, k)
}
</code></pre>



</details>

<a name="access_management_dynamic_map_length"></a>

## Function `length`

Returns the size of the map, the number of key-value pairs


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_length">length</a>&lt;K: <b>copy</b>, drop, store&gt;(map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_length">length</a>&lt;K: <b>copy</b> + drop + store&gt;(map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;): u64 {
    map.size
}
</code></pre>



</details>

<a name="access_management_dynamic_map_is_empty"></a>

## Function `is_empty`

Returns true iff the map is empty (if <code><a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_length">length</a></code> returns <code>0</code>)


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_is_empty">is_empty</a>&lt;K: <b>copy</b>, drop, store&gt;(map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_is_empty">is_empty</a>&lt;K: <b>copy</b> + drop + store&gt;(map: &<a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;): bool {
    map.size == 0
}
</code></pre>



</details>

<a name="access_management_dynamic_map_destroy_empty"></a>

## Function `destroy_empty`

Destroys an empty map
Aborts with <code><a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_EMapNotEmpty">EMapNotEmpty</a></code> if the map still contains values


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_destroy_empty">destroy_empty</a>&lt;K: <b>copy</b>, drop, store&gt;(map: <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_destroy_empty">destroy_empty</a>&lt;K: <b>copy</b> + drop + store&gt;(map: <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;) {
    <b>let</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a> { id, size } = map;
    <b>assert</b>!(size == 0, <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_EMapNotEmpty">EMapNotEmpty</a>);
    object::delete(id)
}
</code></pre>



</details>

<a name="access_management_dynamic_map_force_drop"></a>

## Function `force_drop`

Drop a possibly non-empty map.
CAUTION: This will forfeit the storage rebate for the stored values.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_force_drop">force_drop</a>&lt;K: <b>copy</b>, drop, store&gt;(map: <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">access_management::dynamic_map::DynamicMap</a>&lt;K&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_force_drop">force_drop</a>&lt;K: <b>copy</b> + drop + store&gt;(map: <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a>&lt;K&gt;) {
    <b>let</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map_DynamicMap">DynamicMap</a> { id, size: _ } = map;
    object::delete(id)
}
</code></pre>



</details>

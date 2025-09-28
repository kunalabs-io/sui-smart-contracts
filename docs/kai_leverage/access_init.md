
<a name="kai_leverage_access_init"></a>

# Module `kai_leverage::access_init`

Access management initialization for the Kai Leverage package


-  [Struct `ACCESS_INIT`](#kai_leverage_access_init_ACCESS_INIT)
-  [Function `init`](#kai_leverage_access_init_init)


<pre><code><b>use</b> <a href="../../dependencies/access_management/access.md#access_management_access">access_management::access</a>;
<b>use</b> <a href="../../dependencies/access_management/dynamic_map.md#access_management_dynamic_map">access_management::dynamic_map</a>;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_leverage_access_init_ACCESS_INIT"></a>

## Struct `ACCESS_INIT`



<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/access_init.md#kai_leverage_access_init_ACCESS_INIT">ACCESS_INIT</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_leverage_access_init_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/access_init.md#kai_leverage_access_init_init">init</a>(otw: <a href="../../dependencies/kai_leverage/access_init.md#kai_leverage_access_init_ACCESS_INIT">kai_leverage::access_init::ACCESS_INIT</a>, ctx: &<b>mut</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/access_init.md#kai_leverage_access_init_init">init</a>(otw: <a href="../../dependencies/kai_leverage/access_init.md#kai_leverage_access_init_ACCESS_INIT">ACCESS_INIT</a>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> admin = access::claim_package(otw, ctx);
    transfer::public_transfer(admin, tx_context::sender(ctx));
}
</code></pre>



</details>

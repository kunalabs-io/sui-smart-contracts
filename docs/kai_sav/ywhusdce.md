
<a name="kai_sav_ywhusdce"></a>

# Module `kai_sav::ywhusdce`



-  [Struct `YWHUSDCE`](#kai_sav_ywhusdce_YWHUSDCE)
-  [Function `init`](#kai_sav_ywhusdce_init)


<pre><code><b>use</b> <a href="../dependencies/whusdce/coin.md#0x5D4B302506645C37FF133B98C4B50A5AE14841659738D6D733D59D0D217A93BF_coin">0x5D4B302506645C37FF133B98C4B50A5AE14841659738D6D733D59D0D217A93BF::coin</a>;
<b>use</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance">kai_sav::time_locked_balance</a>;
<b>use</b> <a href="../kai_sav/util.md#kai_sav_util">kai_sav::util</a>;
<b>use</b> <a href="../kai_sav/vault.md#kai_sav_vault">kai_sav::vault</a>;
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



<a name="kai_sav_ywhusdce_YWHUSDCE"></a>

## Struct `YWHUSDCE`



<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/ywhusdce.md#kai_sav_ywhusdce_YWHUSDCE">YWHUSDCE</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
</dl>


</details>

<a name="kai_sav_ywhusdce_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="../kai_sav/ywhusdce.md#kai_sav_ywhusdce_init">init</a>(witness: <a href="../kai_sav/ywhusdce.md#kai_sav_ywhusdce_YWHUSDCE">kai_sav::ywhusdce::YWHUSDCE</a>, ctx: &<b>mut</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context_TxContext">sui::tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/ywhusdce.md#kai_sav_ywhusdce_init">init</a>(witness: <a href="../kai_sav/ywhusdce.md#kai_sav_ywhusdce_YWHUSDCE">YWHUSDCE</a>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> (treasury, meta) = coin::create_currency(
        witness,
        6,
        b"yUSDC",
        b"",
        b"",
        option::none(),
        ctx,
    );
    transfer::public_share_object(meta);
    <b>let</b> admin_cap = <a href="../kai_sav/vault.md#kai_sav_vault_new">vault::new</a>&lt;WHUSDCE, <a href="../kai_sav/ywhusdce.md#kai_sav_ywhusdce_YWHUSDCE">YWHUSDCE</a>&gt;(treasury, ctx);
    transfer::public_transfer(admin_cap, tx_context::sender(ctx));
}
</code></pre>



</details>

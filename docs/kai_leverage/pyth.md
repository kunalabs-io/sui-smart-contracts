
<a name="kai_leverage_pyth"></a>

# Module `kai_leverage::pyth`

Pyth price feed integration for Kai Leverage.


-  [Struct `PythPriceInfo`](#kai_leverage_pyth_PythPriceInfo)
-  [Struct `ValidatedPythPriceInfo`](#kai_leverage_pyth_ValidatedPythPriceInfo)
-  [Constants](#@Constants_0)
-  [Function `create`](#kai_leverage_pyth_create)
-  [Function `add`](#kai_leverage_pyth_add)
-  [Function `validate`](#kai_leverage_pyth_validate)
-  [Function `max_age_secs`](#kai_leverage_pyth_max_age_secs)
-  [Function `decimals`](#kai_leverage_pyth_decimals)
-  [Function `get_price`](#kai_leverage_pyth_get_price)
-  [Function `get_ema_price`](#kai_leverage_pyth_get_ema_price)
-  [Function `get_price_lo_hi_expo_dec`](#kai_leverage_pyth_get_price_lo_hi_expo_dec)
-  [Function `get_ema_price_lo_hi_expo_dec`](#kai_leverage_pyth_get_ema_price_lo_hi_expo_dec)
-  [Function `div_price_numeric_x128_inner`](#kai_leverage_pyth_div_price_numeric_x128_inner)
-  [Function `div_price_numeric_x128`](#kai_leverage_pyth_div_price_numeric_x128)
-  [Function `div_ema_price_numeric_x128`](#kai_leverage_pyth_div_ema_price_numeric_x128)


<pre><code><b>use</b> <a href="../../dependencies/pyth/i64.md#pyth_i64">pyth::i64</a>;
<b>use</b> <a href="../../dependencies/pyth/price.md#pyth_price">pyth::price</a>;
<b>use</b> <a href="../../dependencies/pyth/price_feed.md#pyth_price_feed">pyth::price_feed</a>;
<b>use</b> <a href="../../dependencies/pyth/price_identifier.md#pyth_price_identifier">pyth::price_identifier</a>;
<b>use</b> <a href="../../dependencies/pyth/price_info.md#pyth_price_info">pyth::price_info</a>;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/u64.md#std_u64">std::u64</a>;
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
<b>use</b> <a href="../../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_leverage_pyth_PythPriceInfo"></a>

## Struct `PythPriceInfo`

Collection of Pyth price information objects.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">PythPriceInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pio_map: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../../dependencies/pyth/price_info.md#pyth_price_info_PriceInfo">pyth::price_info::PriceInfo</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>current_ts_sec: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_pyth_ValidatedPythPriceInfo"></a>

## Struct `ValidatedPythPriceInfo`

Validated Pyth price information ready for calculations.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>map: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <a href="../../dependencies/pyth/price_info.md#pyth_price_info_PriceInfo">pyth::price_info::PriceInfo</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>current_ts_sec: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_pyth_EUnsupportedCoinType"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EUnsupportedCoinType">EUnsupportedCoinType</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_pyth_EStalePrice"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EStalePrice">EStalePrice</a>: u64 = 1;
</code></pre>



<a name="kai_leverage_pyth_EPriceUndefined"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EPriceUndefined">EPriceUndefined</a>: u64 = 2;
</code></pre>



<a name="kai_leverage_pyth_SUI_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_SUI_TYPE_NAME">SUI_TYPE_NAME</a>: vector&lt;u8&gt; = vector[48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 50, 58, 58, 115, 117, 105, 58, 58, 83, 85, 73];
</code></pre>



<a name="kai_leverage_pyth_WHUSDCE_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_WHUSDCE_TYPE_NAME">WHUSDCE_TYPE_NAME</a>: vector&lt;u8&gt; = vector[53, 100, 52, 98, 51, 48, 50, 53, 48, 54, 54, 52, 53, 99, 51, 55, 102, 102, 49, 51, 51, 98, 57, 56, 99, 52, 98, 53, 48, 97, 53, 97, 101, 49, 52, 56, 52, 49, 54, 53, 57, 55, 51, 56, 100, 54, 100, 55, 51, 51, 100, 53, 57, 100, 48, 100, 50, 49, 55, 97, 57, 51, 98, 102, 58, 58, 99, 111, 105, 110, 58, 58, 67, 79, 73, 78];
</code></pre>



<a name="kai_leverage_pyth_WHUSDTE_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_WHUSDTE_TYPE_NAME">WHUSDTE_TYPE_NAME</a>: vector&lt;u8&gt; = vector[99, 48, 54, 48, 48, 48, 54, 49, 49, 49, 48, 49, 54, 98, 56, 97, 48, 50, 48, 97, 100, 53, 98, 51, 51, 56, 51, 52, 57, 56, 52, 97, 52, 51, 55, 97, 97, 97, 55, 100, 51, 99, 55, 52, 99, 49, 56, 101, 48, 57, 97, 57, 53, 100, 52, 56, 97, 99, 101, 97, 98, 48, 56, 99, 58, 58, 99, 111, 105, 110, 58, 58, 67, 79, 73, 78];
</code></pre>



<a name="kai_leverage_pyth_USDC_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_USDC_TYPE_NAME">USDC_TYPE_NAME</a>: vector&lt;u8&gt; = vector[100, 98, 97, 51, 52, 54, 55, 50, 101, 51, 48, 99, 98, 48, 54, 53, 98, 49, 102, 57, 51, 101, 51, 97, 98, 53, 53, 51, 49, 56, 55, 54, 56, 102, 100, 54, 102, 101, 102, 54, 54, 99, 49, 53, 57, 52, 50, 99, 57, 102, 55, 99, 98, 56, 52, 54, 101, 50, 102, 57, 48, 48, 101, 55, 58, 58, 117, 115, 100, 99, 58, 58, 85, 83, 68, 67];
</code></pre>



<a name="kai_leverage_pyth_SUIUSDT_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_SUIUSDT_TYPE_NAME">SUIUSDT_TYPE_NAME</a>: vector&lt;u8&gt; = vector[51, 55, 53, 102, 55, 48, 99, 102, 50, 97, 101, 52, 99, 48, 48, 98, 102, 51, 55, 49, 49, 55, 100, 48, 99, 56, 53, 97, 50, 99, 55, 49, 53, 52, 53, 101, 54, 101, 101, 48, 53, 99, 52, 97, 53, 99, 55, 100, 50, 56, 50, 99, 100, 54, 54, 97, 52, 53, 48, 52, 98, 48, 54, 56, 58, 58, 117, 115, 100, 116, 58, 58, 85, 83, 68, 84];
</code></pre>



<a name="kai_leverage_pyth_USDY_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_USDY_TYPE_NAME">USDY_TYPE_NAME</a>: vector&lt;u8&gt; = vector[57, 54, 48, 98, 53, 51, 49, 54, 54, 55, 54, 51, 54, 102, 51, 57, 101, 56, 53, 56, 54, 55, 55, 55, 53, 102, 53, 50, 102, 54, 98, 49, 102, 50, 50, 48, 97, 48, 53, 56, 99, 52, 100, 101, 55, 56, 54, 57, 48, 53, 98, 100, 102, 55, 54, 49, 101, 48, 54, 97, 53, 54, 98, 98, 58, 58, 117, 115, 100, 121, 58, 58, 85, 83, 68, 89];
</code></pre>



<a name="kai_leverage_pyth_DEEP_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_DEEP_TYPE_NAME">DEEP_TYPE_NAME</a>: vector&lt;u8&gt; = vector[100, 101, 101, 98, 55, 97, 52, 54, 54, 50, 101, 101, 99, 57, 102, 50, 102, 51, 100, 101, 102, 48, 51, 102, 98, 57, 51, 55, 97, 54, 54, 51, 100, 100, 100, 97, 97, 50, 101, 50, 49, 53, 98, 56, 48, 55, 56, 97, 50, 56, 52, 100, 48, 50, 54, 98, 55, 57, 52, 54, 99, 50, 55, 48, 58, 58, 100, 101, 101, 112, 58, 58, 68, 69, 69, 80];
</code></pre>



<a name="kai_leverage_pyth_WAL_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_WAL_TYPE_NAME">WAL_TYPE_NAME</a>: vector&lt;u8&gt; = vector[51, 53, 54, 97, 50, 54, 101, 98, 57, 101, 48, 49, 50, 97, 54, 56, 57, 53, 56, 48, 56, 50, 51, 52, 48, 100, 52, 99, 52, 49, 49, 54, 101, 55, 102, 53, 53, 54, 49, 53, 99, 102, 50, 55, 97, 102, 102, 99, 102, 102, 50, 48, 57, 99, 102, 48, 97, 101, 53, 52, 52, 102, 53, 57, 58, 58, 119, 97, 108, 58, 58, 87, 65, 76];
</code></pre>



<a name="kai_leverage_pyth_LBTC_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_LBTC_TYPE_NAME">LBTC_TYPE_NAME</a>: vector&lt;u8&gt; = vector[51, 101, 56, 101, 57, 52, 50, 51, 100, 56, 48, 101, 49, 55, 55, 52, 97, 55, 99, 97, 49, 50, 56, 102, 99, 99, 100, 56, 98, 102, 53, 102, 49, 102, 55, 55, 53, 51, 98, 101, 54, 53, 56, 99, 53, 101, 54, 52, 53, 57, 50, 57, 48, 51, 55, 102, 55, 99, 56, 49, 57, 48, 52, 48, 58, 58, 108, 98, 116, 99, 58, 58, 76, 66, 84, 67];
</code></pre>



<a name="kai_leverage_pyth_WBTC_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_WBTC_TYPE_NAME">WBTC_TYPE_NAME</a>: vector&lt;u8&gt; = vector[97, 97, 102, 98, 49, 48, 50, 100, 100, 48, 57, 48, 50, 102, 53, 48, 53, 53, 99, 97, 100, 101, 99, 100, 54, 56, 55, 102, 98, 53, 98, 55, 49, 99, 97, 56, 50, 101, 102, 48, 101, 48, 50, 56, 53, 100, 57, 48, 97, 102, 100, 101, 56, 50, 56, 101, 99, 53, 56, 99, 97, 57, 54, 98, 58, 58, 98, 116, 99, 58, 58, 66, 84, 67];
</code></pre>



<a name="kai_leverage_pyth_XBTC_TYPE_NAME"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_XBTC_TYPE_NAME">XBTC_TYPE_NAME</a>: vector&lt;u8&gt; = vector[56, 55, 54, 97, 52, 98, 55, 98, 99, 101, 56, 97, 101, 97, 101, 102, 54, 48, 52, 54, 52, 99, 49, 49, 102, 52, 48, 50, 54, 57, 48, 51, 101, 57, 97, 102, 97, 99, 97, 98, 55, 57, 98, 57, 98, 49, 52, 50, 54, 56, 54, 49, 53, 56, 97, 97, 56, 54, 53, 54, 48, 98, 53, 48, 58, 58, 120, 98, 116, 99, 58, 58, 88, 66, 84, 67];
</code></pre>



<a name="kai_leverage_pyth_create"></a>

## Function `create`

Create a new Pyth price info collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_create">create</a>(clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_create">create</a>(clock: &Clock): <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">PythPriceInfo</a> {
    <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">PythPriceInfo</a> {
        pio_map: vec_map::empty(),
        current_ts_sec: clock.timestamp_ms() / 1000,
        <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>: 0,
    }
}
</code></pre>



</details>

<a name="kai_leverage_pyth_add"></a>

## Function `add`

Add a price info object to the collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_add">add</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, info: &<a href="../../dependencies/pyth/price_info.md#pyth_price_info_PriceInfoObject">pyth::price_info::PriceInfoObject</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_add">add</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">PythPriceInfo</a>, info: &PriceInfoObject) {
    <b>let</b> price_info = price_info::get_price_info_from_price_info_object(info);
    <b>let</b> price = price_info.get_price_feed().<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price">get_price</a>();
    <b>let</b> key = object::id(info);
    <b>if</b> (!self.pio_map.contains(&key)) {
        self.pio_map.insert(key, price_info);
    };
    <b>let</b> age = self.current_ts_sec - price.get_timestamp();
    self.<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a> = u64::max(self.<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>, age);
}
</code></pre>



</details>

<a name="kai_leverage_pyth_validate"></a>

## Function `validate`

Validate price info against age limits and allowlist.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_validate">validate</a>(info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">kai_leverage::pyth::PythPriceInfo</a>, <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>: u64, pio_allowlist: &<a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>&gt;): <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_validate">validate</a>(
    info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_PythPriceInfo">PythPriceInfo</a>,
    <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>: u64,
    pio_allowlist: &VecMap&lt;TypeName, ID&gt;,
): <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a> {
    <b>assert</b>!(info.<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a> &lt;= <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>, <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EStalePrice">EStalePrice</a>);
    <b>let</b> <b>mut</b> map = vec_map::empty();
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = pio_allowlist.length();
    <b>while</b> (i &lt; n) {
        <b>let</b> (coin_type, id) = pio_allowlist.get_entry_by_idx(i);
        <b>let</b> price_info = info.pio_map[id];
        vec_map::insert(&<b>mut</b> map, *coin_type, price_info);
        i = i + 1;
    };
    <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a> {
        map,
        current_ts_sec: info.current_ts_sec,
        <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>: info.<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>,
    }
}
</code></pre>



</details>

<a name="kai_leverage_pyth_max_age_secs"></a>

## Function `max_age_secs`

Get the maximum age of price feeds in seconds.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>(self: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>(self: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a>): u64 {
    self.<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_max_age_secs">max_age_secs</a>
}
</code></pre>



</details>

<a name="kai_leverage_pyth_decimals"></a>

## Function `decimals`

Get the decimal places for a supported token type.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_decimals">decimals</a>(type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_decimals">decimals</a>(`type`: TypeName): u8 {
    <b>let</b> type_name = `type`.as_string().as_bytes();
    <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_SUI_TYPE_NAME">SUI_TYPE_NAME</a>) {
        9
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_WHUSDCE_TYPE_NAME">WHUSDCE_TYPE_NAME</a>) {
        6
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_WHUSDTE_TYPE_NAME">WHUSDTE_TYPE_NAME</a>) {
        6
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_USDC_TYPE_NAME">USDC_TYPE_NAME</a>) {
        6
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_SUIUSDT_TYPE_NAME">SUIUSDT_TYPE_NAME</a>) {
        6
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_USDY_TYPE_NAME">USDY_TYPE_NAME</a>) {
        6
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_DEEP_TYPE_NAME">DEEP_TYPE_NAME</a>) {
        6
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_WAL_TYPE_NAME">WAL_TYPE_NAME</a>) {
        9
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_LBTC_TYPE_NAME">LBTC_TYPE_NAME</a>) {
        8
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_WBTC_TYPE_NAME">WBTC_TYPE_NAME</a>) {
        8
    } <b>else</b> <b>if</b> (type_name == &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_XBTC_TYPE_NAME">XBTC_TYPE_NAME</a>) {
        8
    } <b>else</b> {
        <b>abort</b> (<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EUnsupportedCoinType">EUnsupportedCoinType</a>)
    }
}
</code></pre>



</details>

<a name="kai_leverage_pyth_get_price"></a>

## Function `get_price`

Get the current price for a token type.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price">get_price</a>(self: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): <a href="../../dependencies/pyth/price.md#pyth_price_Price">pyth::price::Price</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price">get_price</a>(self: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a>, `type`: TypeName): Price {
    <b>let</b> info = vec_map::get(&self.map, &`type`);
    info.get_price_feed().<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price">get_price</a>()
}
</code></pre>



</details>

<a name="kai_leverage_pyth_get_ema_price"></a>

## Function `get_ema_price`

Get the EMA price for a token type.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_ema_price">get_ema_price</a>(self: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): <a href="../../dependencies/pyth/price.md#pyth_price_Price">pyth::price::Price</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_ema_price">get_ema_price</a>(self: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a>, `type`: TypeName): Price {
    <b>let</b> info = vec_map::get(&self.map, &`type`);
    info.get_price_feed().<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_ema_price">get_ema_price</a>()
}
</code></pre>



</details>

<a name="kai_leverage_pyth_get_price_lo_hi_expo_dec"></a>

## Function `get_price_lo_hi_expo_dec`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price_lo_hi_expo_dec">get_price_lo_hi_expo_dec</a>(price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, t: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): (u64, u64, u64, u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price_lo_hi_expo_dec">get_price_lo_hi_expo_dec</a>(
    price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a>,
    t: TypeName,
): (u64, u64, u64, u64, u64) {
    <b>let</b> price = <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price">get_price</a>(price_info, t);
    <b>let</b> conf = price.get_conf();
    <b>let</b> p = i64::get_magnitude_if_positive(&price.<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price">get_price</a>());
    <b>let</b> expo = i64::get_magnitude_if_negative(&price.get_expo());
    <b>let</b> dec = <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_decimals">decimals</a>(t) <b>as</b> u64;
    (p, p - conf, p + conf, expo, dec)
}
</code></pre>



</details>

<a name="kai_leverage_pyth_get_ema_price_lo_hi_expo_dec"></a>

## Function `get_ema_price_lo_hi_expo_dec`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_ema_price_lo_hi_expo_dec">get_ema_price_lo_hi_expo_dec</a>(price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, t: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): (u64, u64, u64, u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_ema_price_lo_hi_expo_dec">get_ema_price_lo_hi_expo_dec</a>(
    price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a>,
    t: TypeName,
): (u64, u64, u64, u64, u64) {
    <b>let</b> price = <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_ema_price">get_ema_price</a>(price_info, t);
    <b>let</b> conf = price.get_conf();
    <b>let</b> p = i64::get_magnitude_if_positive(&price.<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price">get_price</a>());
    <b>let</b> expo = i64::get_magnitude_if_negative(&price.get_expo());
    <b>let</b> dec = <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_decimals">decimals</a>(t) <b>as</b> u64;
    (p, p - conf, p + conf, expo, dec)
}
</code></pre>



</details>

<a name="kai_leverage_pyth_div_price_numeric_x128_inner"></a>

## Function `div_price_numeric_x128_inner`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_div_price_numeric_x128_inner">div_price_numeric_x128_inner</a>(price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, x: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, y: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, use_ema: bool): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_div_price_numeric_x128_inner">div_price_numeric_x128_inner</a>(
    price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a>,
    x: TypeName,
    y: TypeName,
    use_ema: bool,
): u256 {
    <b>let</b> (price_x, _, _, ex, dx) = <b>if</b> (use_ema) {
        <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_ema_price_lo_hi_expo_dec">get_ema_price_lo_hi_expo_dec</a>(price_info, x)
    } <b>else</b> {
        <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price_lo_hi_expo_dec">get_price_lo_hi_expo_dec</a>(price_info, x)
    };
    <b>let</b> (price_y, _, _, ey, dy) = <b>if</b> (use_ema) {
        <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_ema_price_lo_hi_expo_dec">get_ema_price_lo_hi_expo_dec</a>(price_info, y)
    } <b>else</b> {
        <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_get_price_lo_hi_expo_dec">get_price_lo_hi_expo_dec</a>(price_info, y)
    };
    <b>let</b> (scale_num, scale_denom) = <b>if</b> (ey + dy &gt; ex + dx) {
        <b>let</b> exp = (ey + dy - ex - dx <b>as</b> u8);
        (u64::pow(10, exp), 1)
    } <b>else</b> {
        <b>let</b> exp = (ex + dx - ey - dy <b>as</b> u8);
        (1, u64::pow(10, exp))
    };
    <b>assert</b>!(price_y &gt; 0, <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EPriceUndefined">EPriceUndefined</a>);
    <b>let</b> val =
        ((price_x <b>as</b> u256) * (scale_num <b>as</b> u256) &lt;&lt; 128) /
            ((price_y <b>as</b> u256) * (scale_denom <b>as</b> u256));
    <b>let</b> q64_128_max = ((1 &lt;&lt; 64) &lt;&lt; 128) - 1;
    <b>assert</b>!(val &lt;= q64_128_max, <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EPriceUndefined">EPriceUndefined</a>);
    val
}
</code></pre>



</details>

<a name="kai_leverage_pyth_div_price_numeric_x128"></a>

## Function `div_price_numeric_x128`

Returns the price of <code>Y</code> in <code>X</code> such that <code>X * price = Y</code> i.e. <code>price = Y / X</code>.
The returned value is in Q64.128 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_div_price_numeric_x128">div_price_numeric_x128</a>(price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, x: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, y: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_div_price_numeric_x128">div_price_numeric_x128</a>(
    price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a>,
    x: TypeName,
    y: TypeName,
): u256 {
    <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_div_price_numeric_x128_inner">div_price_numeric_x128_inner</a>(price_info, x, y, <b>false</b>)
}
</code></pre>



</details>

<a name="kai_leverage_pyth_div_ema_price_numeric_x128"></a>

## Function `div_ema_price_numeric_x128`

Returns the price of <code>Y</code> in <code>X</code> such that <code>X * price = Y</code> i.e. <code>price = Y / X</code>.
The returned value is in Q64.128 format.
Uses EMA price instead of spot price.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_div_ema_price_numeric_x128">div_ema_price_numeric_x128</a>(price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">kai_leverage::pyth::ValidatedPythPriceInfo</a>, x: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, y: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_div_ema_price_numeric_x128">div_ema_price_numeric_x128</a>(
    price_info: &<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_ValidatedPythPriceInfo">ValidatedPythPriceInfo</a>,
    x: TypeName,
    y: TypeName,
): u256 {
    <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_div_price_numeric_x128_inner">div_price_numeric_x128_inner</a>(price_info, x, y, <b>true</b>)
}
</code></pre>



</details>

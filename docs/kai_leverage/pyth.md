
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


<pre><code><b>use</b> <a href="../../dependencies/wal/wal.md#0x356A26EB9E012A68958082340D4C4116E7F55615CF27AFFCFF209CF0AE544F59_wal">0x356A26EB9E012A68958082340D4C4116E7F55615CF27AFFCFF209CF0AE544F59::wal</a>;
<b>use</b> <a href="../../dependencies/suiusdt/usdt.md#0x375F70CF2AE4C00BF37117D0C85A2C71545E6EE05C4A5C7D282CD66A4504B068_usdt">0x375F70CF2AE4C00BF37117D0C85A2C71545E6EE05C4A5C7D282CD66A4504B068::usdt</a>;
<b>use</b> <a href="../../dependencies/lbtc/lbtc.md#0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040_lbtc">0x3E8E9423D80E1774A7CA128FCCD8BF5F1F7753BE658C5E645929037F7C819040::lbtc</a>;
<b>use</b> <a href="../../dependencies/whusdce/coin.md#0x5D4B302506645C37FF133B98C4B50A5AE14841659738D6D733D59D0D217A93BF_coin">0x5D4B302506645C37FF133B98C4B50A5AE14841659738D6D733D59D0D217A93BF::coin</a>;
<b>use</b> <a href="../../dependencies/xbtc/xbtc.md#0x876A4B7BCE8AEAEF60464C11F4026903E9AFACAB79B9B142686158AA86560B50_xbtc">0x876A4B7BCE8AEAEF60464C11F4026903E9AFACAB79B9B142686158AA86560B50::xbtc</a>;
<b>use</b> <a href="../../dependencies/usdy/usdy.md#0x960B531667636F39E85867775F52F6B1F220A058C4DE786905BDF761E06A56BB_usdy">0x960B531667636F39E85867775F52F6B1F220A058C4DE786905BDF761E06A56BB::usdy</a>;
<b>use</b> <a href="../../dependencies/wbtc/btc.md#0xAAFB102DD0902F5055CADECD687FB5B71CA82EF0E0285D90AFDE828EC58CA96B_btc">0xAAFB102DD0902F5055CADECD687FB5B71CA82EF0E0285D90AFDE828EC58CA96B::btc</a>;
<b>use</b> <a href="../../dependencies/whusdte/coin.md#0xC060006111016B8A020AD5B33834984A437AAA7D3C74C18E09A95D48ACEAB08C_coin">0xC060006111016B8A020AD5B33834984A437AAA7D3C74C18E09A95D48ACEAB08C::coin</a>;
<b>use</b> <a href="../../dependencies/deep/deep.md#0xDEEB7A4662EEC9F2F3DEF03FB937A663DDDAA2E215B8078A284D026B7946C270_deep">0xDEEB7A4662EEC9F2F3DEF03FB937A663DDDAA2E215B8078A284D026B7946C270::deep</a>;
<b>use</b> <a href="../../dependencies/pyth/i64.md#pyth_i64">pyth::i64</a>;
<b>use</b> <a href="../../dependencies/pyth/price.md#pyth_price">pyth::price</a>;
<b>use</b> <a href="../../dependencies/pyth/price_feed.md#pyth_price_feed">pyth::price_feed</a>;
<b>use</b> <a href="../../dependencies/pyth/price_identifier.md#pyth_price_identifier">pyth::price_identifier</a>;
<b>use</b> <a href="../../dependencies/pyth/price_info.md#pyth_price_info">pyth::price_info</a>;
<b>use</b> <a href="../../dependencies/stablecoin/mint_allowance.md#stablecoin_mint_allowance">stablecoin::mint_allowance</a>;
<b>use</b> <a href="../../dependencies/stablecoin/roles.md#stablecoin_roles">stablecoin::roles</a>;
<b>use</b> <a href="../../dependencies/stablecoin/treasury.md#stablecoin_treasury">stablecoin::treasury</a>;
<b>use</b> <a href="../../dependencies/stablecoin/version_control.md#stablecoin_version_control">stablecoin::version_control</a>;
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
<b>use</b> <a href="../../dependencies/sui/package.md#sui_package">sui::package</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
<b>use</b> <a href="../../dependencies/sui_extensions/two_step_role.md#sui_extensions_two_step_role">sui_extensions::two_step_role</a>;
<b>use</b> <a href="../../dependencies/sui_extensions/upgrade_service.md#sui_extensions_upgrade_service">sui_extensions::upgrade_service</a>;
<b>use</b> <a href="../../dependencies/usdc/usdc.md#usdc_usdc">usdc::usdc</a>;
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


<a name="kai_leverage_pyth_EUnsupportedPriceFeed"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EUnsupportedPriceFeed">EUnsupportedPriceFeed</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_pyth_EStalePrice"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EStalePrice">EStalePrice</a>: u64 = 1;
</code></pre>



<a name="kai_leverage_pyth_EPriceUndefined"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EPriceUndefined">EPriceUndefined</a>: u64 = 2;
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
    <b>if</b> (`type` == type_name::with_defining_ids&lt;SUI&gt;()) {
        9
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;WHUSDCE&gt;()) {
        6
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;WHUSDTE&gt;()) {
        6
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;USDC&gt;()) {
        6
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;SUIUSDT&gt;()) {
        6
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;USDY&gt;()) {
        6
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;DEEP&gt;()) {
        6
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;WAL&gt;()) {
        9
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;LBTC&gt;()) {
        8
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;WBTC&gt;()) {
        8
    } <b>else</b> <b>if</b> (`type` == type_name::with_defining_ids&lt;XBTC&gt;()) {
        8
    } <b>else</b> {
        <b>abort</b> (<a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_EUnsupportedPriceFeed">EUnsupportedPriceFeed</a>)
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

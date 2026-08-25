
<a name="kai_leverage_oracle_price"></a>

# Module `kai_leverage::oracle_price`

Rail-agnostic oracle price collection for Kai Leverage.

Oracle data is reduced to plain numbers at ingestion (<code>add_*</code>), so the
downstream interface never mentions an oracle package's types and a new
oracle rail is a purely additive <code>add_&lt;rail&gt;</code> function in an upgrade.
Entry points take <code>&<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">PriceCollection</a></code> forever; the caller picks the rail
by choosing which <code>add_*</code> to call, and the per-market config allowlist
(object IDs) decides which price objects actually validate.


-  [Struct `Quote`](#kai_leverage_oracle_price_Quote)
-  [Struct `PriceData`](#kai_leverage_oracle_price_PriceData)
-  [Struct `PriceCollection`](#kai_leverage_oracle_price_PriceCollection)
-  [Struct `ValidatedPrices`](#kai_leverage_oracle_price_ValidatedPrices)
-  [Constants](#@Constants_0)
-  [Function `create`](#kai_leverage_oracle_price_create)
-  [Function `add_pyth_pro`](#kai_leverage_oracle_price_add_pyth_pro)
-  [Function `add_currency`](#kai_leverage_oracle_price_add_currency)
-  [Function `validate`](#kai_leverage_oracle_price_validate)
-  [Function `max_age_secs`](#kai_leverage_oracle_price_max_age_secs)
-  [Function `get_price`](#kai_leverage_oracle_price_get_price)
-  [Function `get_smoothed_price`](#kai_leverage_oracle_price_get_smoothed_price)
-  [Function `quote_price`](#kai_leverage_oracle_price_quote_price)
-  [Function `quote_conf`](#kai_leverage_oracle_price_quote_conf)
-  [Function `quote_expo_neg`](#kai_leverage_oracle_price_quote_expo_neg)
-  [Function `decimals`](#kai_leverage_oracle_price_decimals)
-  [Function `quote_price_expo_dec`](#kai_leverage_oracle_price_quote_price_expo_dec)
-  [Function `div_numeric_x128_inner`](#kai_leverage_oracle_price_div_numeric_x128_inner)
-  [Function `div_price_numeric_x128`](#kai_leverage_oracle_price_div_price_numeric_x128)
-  [Function `div_smoothed_price_numeric_x128`](#kai_leverage_oracle_price_div_smoothed_price_numeric_x128)


<pre><code><b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::i64;
<b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price;
<b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price_feed;
<b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price_identifier;
<b>use</b> (pyth=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price_info;
<b>use</b> <a href="../../dependencies/std/address.md#std_address">std::address</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/internal.md#std_internal">std::internal</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/type_name.md#std_type_name">std::type_name</a>;
<b>use</b> <a href="../../dependencies/std/u128.md#std_u128">std::u128</a>;
<b>use</b> <a href="../../dependencies/std/u64.md#std_u64">std::u64</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/accumulator.md#sui_accumulator">sui::accumulator</a>;
<b>use</b> <a href="../../dependencies/sui/accumulator_settlement.md#sui_accumulator_settlement">sui::accumulator_settlement</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/bag.md#sui_bag">sui::bag</a>;
<b>use</b> <a href="../../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../../dependencies/sui/bcs.md#sui_bcs">sui::bcs</a>;
<b>use</b> <a href="../../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../../dependencies/sui/coin.md#sui_coin">sui::coin</a>;
<b>use</b> <a href="../../dependencies/sui/coin_registry.md#sui_coin_registry">sui::coin_registry</a>;
<b>use</b> <a href="../../dependencies/sui/config.md#sui_config">sui::config</a>;
<b>use</b> <a href="../../dependencies/sui/deny_list.md#sui_deny_list">sui::deny_list</a>;
<b>use</b> <a href="../../dependencies/sui/derived_object.md#sui_derived_object">sui::derived_object</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../../dependencies/sui/dynamic_object_field.md#sui_dynamic_object_field">sui::dynamic_object_field</a>;
<b>use</b> <a href="../../dependencies/sui/event.md#sui_event">sui::event</a>;
<b>use</b> <a href="../../dependencies/sui/funds_accumulator.md#sui_funds_accumulator">sui::funds_accumulator</a>;
<b>use</b> <a href="../../dependencies/sui/hash.md#sui_hash">sui::hash</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/protocol_config.md#sui_protocol_config">sui::protocol_config</a>;
<b>use</b> <a href="../../dependencies/sui/sui.md#sui_sui">sui::sui</a>;
<b>use</b> <a href="../../dependencies/sui/table.md#sui_table">sui::table</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/types.md#sui_types">sui::types</a>;
<b>use</b> <a href="../../dependencies/sui/url.md#sui_url">sui::url</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
<b>use</b> <a href="../../dependencies/sui/vec_set.md#sui_vec_set">sui::vec_set</a>;
</code></pre>



<a name="kai_leverage_oracle_price_Quote"></a>

## Struct `Quote`

A single oracle price point. <code>price</code> is always positive and <code>expo_neg</code>
is the magnitude of the (always negative) decimal exponent — both
enforced at ingestion, so garbage feeds abort at <code>add_*</code>, not mid-math.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>price: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>conf: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;</code>
</dt>
<dd>
 Dispersion behind the price (Pyth confidence, Switchboard stdev, …).
 <code>None</code> = the rail provides none — deliberately distinct from zero,
 which would claim perfect confidence. Reserved: not consumed yet.
</dd>
<dt>
<code>expo_neg: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_oracle_price_PriceData"></a>

## Struct `PriceData`

Price data for one oracle price object, reduced to plain numbers.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceData">PriceData</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>spot: <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">kai_leverage::oracle_price::Quote</a></code>
</dt>
<dd>
</dd>
<dt>
<code>smoothed: <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">kai_leverage::oracle_price::Quote</a>&gt;</code>
</dt>
<dd>
 Manipulation-resistant reference price (Pyth fills this with EMA).
 The *role*, not the provenance. <code>None</code> = the rail provides none;
 consumers abort rather than silently substituting spot — adopting a
 rail without native smoothing is a risk-policy decision taken in
 config and code, never a silent fill at ingestion.
</dd>
<dt>
<code>timestamp_sec: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_oracle_price_PriceCollection"></a>

## Struct `PriceCollection`

Collection of oracle price data, keyed by the on-chain price object's ID
(which is what config allowlists reference). Coin decimals ride along as
caller-supplied evidence sourced from the system coin registry.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">PriceCollection</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>map: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>, <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceData">kai_leverage::oracle_price::PriceData</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>created_at_sec: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_oracle_price_ValidatedPrices"></a>

## Struct `ValidatedPrices`

Validated price set, keyed by coin type — the only thing position math
accepts. Constructible solely via <code><a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_validate">validate</a></code>.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>map: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceData">kai_leverage::oracle_price::PriceData</a>&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>: <a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, u8&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code>current_ts_sec: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_max_age_secs">max_age_secs</a>: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_oracle_price_EStalePrice"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EStalePrice">EStalePrice</a>: u64 = 1;
</code></pre>



<a name="kai_leverage_oracle_price_EPriceUndefined"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EPriceUndefined">EPriceUndefined</a>: u64 = 2;
</code></pre>



<a name="kai_leverage_oracle_price_EPriceObjectMissing"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EPriceObjectMissing">EPriceObjectMissing</a>: u64 = 3;
</code></pre>



<a name="kai_leverage_oracle_price_ESmoothedPriceUnavailable"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ESmoothedPriceUnavailable">ESmoothedPriceUnavailable</a>: u64 = 4;
</code></pre>



<a name="kai_leverage_oracle_price_EDecimalsMissing"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EDecimalsMissing">EDecimalsMissing</a>: u64 = 5;
</code></pre>



<a name="kai_leverage_oracle_price_EPriceTimestampInFuture"></a>



<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EPriceTimestampInFuture">EPriceTimestampInFuture</a>: u64 = 6;
</code></pre>



<a name="kai_leverage_oracle_price_MAX_FUTURE_SKEW_SECS"></a>

Upper bound on how far a price timestamp may lead the collection's clock
snapshot before the timestamp is treated as nonsense rather than as skew.
See <code><a href="../../dependencies/kai_leverage/pyth.md#kai_leverage_pyth_MAX_FUTURE_SKEW_SECS">kai_leverage::pyth::MAX_FUTURE_SKEW_SECS</a></code> for the full rationale.


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_MAX_FUTURE_SKEW_SECS">MAX_FUTURE_SKEW_SECS</a>: u64 = 60;
</code></pre>



<a name="kai_leverage_oracle_price_create"></a>

## Function `create`

Create a new, empty price collection.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_create">create</a>(clock: &<a href="../../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_create">create</a>(clock: &Clock): <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">PriceCollection</a> {
    <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">PriceCollection</a> {
        map: vec_map::empty(),
        <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>: vec_map::empty(),
        created_at_sec: clock.timestamp_ms() / 1000,
    }
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_add_pyth_pro"></a>

## Function `add_pyth_pro`

Add a price from the Pyth Pro ("pro-compatible") package's price object.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_add_pyth_pro">add_pyth_pro</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, info: &(pyth_pro=0x55300367A2D40813727CCAC4ECEE977A39FB9CDB46F2E6B2C354B9798F5DE2C0)::price_info::PriceInfoObject)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_add_pyth_pro">add_pyth_pro</a>(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">PriceCollection</a>, info: &ProPriceInfoObject) {
    <b>let</b> key = object::id(info);
    <b>if</b> (self.map.contains(&key)) {
        <b>return</b>
    };
    <b>let</b> price_info = pro_price_info::get_price_info_from_price_info_object(info);
    <b>let</b> price_feed = price_info.get_price_feed();
    <b>let</b> price = price_feed.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_price">get_price</a>();
    <b>let</b> ema = price_feed.get_ema_price();
    <b>let</b> data = <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceData">PriceData</a> {
        spot: <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a> {
            price: pro_i64::get_magnitude_if_positive(&price.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_price">get_price</a>()),
            conf: option::some(price.get_conf()),
            expo_neg: pro_i64::get_magnitude_if_negative(&price.get_expo()),
        },
        smoothed: option::some(<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a> {
            price: pro_i64::get_magnitude_if_positive(&ema.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_price">get_price</a>()),
            conf: option::some(ema.get_conf()),
            expo_neg: pro_i64::get_magnitude_if_negative(&ema.get_expo()),
        }),
        timestamp_sec: price.get_timestamp(),
    };
    self.map.insert(key, data);
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_add_currency"></a>

## Function `add_currency`

Record the decimals for coin type <code>T</code> from its canonical registry
<code>Currency&lt;T&gt;</code> object (<code><a href="../../dependencies/sui/coin_registry.md#sui_coin_registry">sui::coin_registry</a></code>, shared object <code>0xc</code>) —
uniqueness per coin type is enforced by the framework, so the value is
evidence, not caller opinion.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_add_currency">add_currency</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, currency: &<a href="../../dependencies/sui/coin_registry.md#sui_coin_registry_Currency">sui::coin_registry::Currency</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_add_currency">add_currency</a>&lt;T&gt;(self: &<b>mut</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">PriceCollection</a>, currency: &Currency&lt;T&gt;) {
    <b>let</b> key = type_name::with_defining_ids&lt;T&gt;();
    <b>if</b> (self.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>.contains(&key)) {
        <b>return</b>
    };
    self.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>.insert(key, currency.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>());
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_validate"></a>

## Function `validate`

Validate a collection against a config's age limit and allowlist.
Staleness is checked per allowlisted entry — only feeds the config
relies on gate validation. Every allowlisted coin must also carry a
registry-sourced decimals entry (<code><a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_add_currency">add_currency</a></code>).


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_validate">validate</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">kai_leverage::oracle_price::PriceCollection</a>, <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_max_age_secs">max_age_secs</a>: u64, price_object_allowlist: &<a href="../../dependencies/sui/vec_map.md#sui_vec_map_VecMap">sui::vec_map::VecMap</a>&lt;<a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, <a href="../../dependencies/sui/object.md#sui_object_ID">sui::object::ID</a>&gt;): <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(package) <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_validate">validate</a>(
    self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_PriceCollection">PriceCollection</a>,
    <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_max_age_secs">max_age_secs</a>: u64,
    price_object_allowlist: &VecMap&lt;TypeName, ID&gt;,
): <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a> {
    <b>let</b> <b>mut</b> map = vec_map::empty();
    <b>let</b> <b>mut</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a> = vec_map::empty();
    <b>let</b> <b>mut</b> max_age_seen = 0;
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> n = price_object_allowlist.length();
    <b>while</b> (i &lt; n) {
        <b>let</b> (coin_type, id) = price_object_allowlist.get_entry_by_idx(i);
        <b>let</b> data_opt = self.map.try_get(id);
        <b>assert</b>!(data_opt.is_some(), <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EPriceObjectMissing">EPriceObjectMissing</a>);
        <b>let</b> data = data_opt.destroy_some();
        <b>assert</b>!(
            data.timestamp_sec &lt;= self.created_at_sec + <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_MAX_FUTURE_SKEW_SECS">MAX_FUTURE_SKEW_SECS</a>,
            <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EPriceTimestampInFuture">EPriceTimestampInFuture</a>,
        );
        <b>let</b> age = u64::saturating_sub(self.created_at_sec, data.timestamp_sec);
        <b>assert</b>!(age &lt;= <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_max_age_secs">max_age_secs</a>, <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EStalePrice">EStalePrice</a>);
        max_age_seen = u64::max(max_age_seen, age);
        <b>let</b> dec_opt = self.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>.try_get(coin_type);
        <b>assert</b>!(dec_opt.is_some(), <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EDecimalsMissing">EDecimalsMissing</a>);
        map.insert(*coin_type, data);
        <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>.insert(*coin_type, dec_opt.destroy_some());
        i = i + 1;
    };
    <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a> {
        map,
        <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>,
        current_ts_sec: self.created_at_sec,
        <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_max_age_secs">max_age_secs</a>: max_age_seen,
    }
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_max_age_secs"></a>

## Function `max_age_secs`

Maximum observed age among the validated price feeds, in seconds.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_max_age_secs">max_age_secs</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_max_age_secs">max_age_secs</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a>): u64 {
    self.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_max_age_secs">max_age_secs</a>
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_get_price"></a>

## Function `get_price`

Get the spot quote for a coin type.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_price">get_price</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">kai_leverage::oracle_price::Quote</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_price">get_price</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a>, `type`: TypeName): <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a> {
    <b>let</b> data = &self.map[&`type`];
    data.spot
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_get_smoothed_price"></a>

## Function `get_smoothed_price`

Get the smoothed (manipulation-resistant reference) quote for a coin
type. Aborts if the rail that supplied this price provides none —
substituting spot here is a risk-policy decision that must be taken
explicitly in code, never implied.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_smoothed_price">get_smoothed_price</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">kai_leverage::oracle_price::Quote</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_smoothed_price">get_smoothed_price</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a>, `type`: TypeName): <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a> {
    <b>let</b> data = &self.map[&`type`];
    <b>assert</b>!(data.smoothed.is_some(), <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ESmoothedPriceUnavailable">ESmoothedPriceUnavailable</a>);
    *data.smoothed.borrow()
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_quote_price"></a>

## Function `quote_price`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_price">quote_price</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">kai_leverage::oracle_price::Quote</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_price">quote_price</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a>): u64 { self.price }
</code></pre>



</details>

<a name="kai_leverage_oracle_price_quote_conf"></a>

## Function `quote_conf`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_conf">quote_conf</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">kai_leverage::oracle_price::Quote</a>): <a href="../../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_conf">quote_conf</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a>): Option&lt;u64&gt; { self.conf }
</code></pre>



</details>

<a name="kai_leverage_oracle_price_quote_expo_neg"></a>

## Function `quote_expo_neg`



<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_expo_neg">quote_expo_neg</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">kai_leverage::oracle_price::Quote</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_expo_neg">quote_expo_neg</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a>): u64 { self.expo_neg }
</code></pre>



</details>

<a name="kai_leverage_oracle_price_decimals"></a>

## Function `decimals`

Get the registry-sourced decimal places for a validated coin type.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>, type: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a>, `type`: TypeName): u8 {
    *self.<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>.get(&`type`)
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_quote_price_expo_dec"></a>

## Function `quote_price_expo_dec`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_price_expo_dec">quote_price_expo_dec</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>, quote: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">kai_leverage::oracle_price::Quote</a>, t: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): (u64, u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_price_expo_dec">quote_price_expo_dec</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a>, quote: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_Quote">Quote</a>, t: TypeName): (u64, u64, u64) {
    (quote.price, quote.expo_neg, <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_decimals">decimals</a>(self, t) <b>as</b> u64)
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_div_numeric_x128_inner"></a>

## Function `div_numeric_x128_inner`



<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_div_numeric_x128_inner">div_numeric_x128_inner</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>, x: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, y: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, use_smoothed: bool): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_div_numeric_x128_inner">div_numeric_x128_inner</a>(
    self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a>,
    x: TypeName,
    y: TypeName,
    use_smoothed: bool,
): u256 {
    <b>let</b> (price_x, ex, dx) = <b>if</b> (use_smoothed) {
        <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_price_expo_dec">quote_price_expo_dec</a>(self, &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_smoothed_price">get_smoothed_price</a>(self, x), x)
    } <b>else</b> {
        <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_price_expo_dec">quote_price_expo_dec</a>(self, &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_price">get_price</a>(self, x), x)
    };
    <b>let</b> (price_y, ey, dy) = <b>if</b> (use_smoothed) {
        <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_price_expo_dec">quote_price_expo_dec</a>(self, &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_smoothed_price">get_smoothed_price</a>(self, y), y)
    } <b>else</b> {
        <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_quote_price_expo_dec">quote_price_expo_dec</a>(self, &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_get_price">get_price</a>(self, y), y)
    };
    <b>let</b> (scale_num, scale_denom) = <b>if</b> (ey + dy &gt; ex + dx) {
        <b>let</b> exp = (ey + dy - ex - dx <b>as</b> u8);
        (u64::pow(10, exp), 1)
    } <b>else</b> {
        <b>let</b> exp = (ex + dx - ey - dy <b>as</b> u8);
        (1, u64::pow(10, exp))
    };
    <b>assert</b>!(price_y &gt; 0, <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EPriceUndefined">EPriceUndefined</a>);
    <b>let</b> val =
        ((price_x <b>as</b> u256) * (scale_num <b>as</b> u256) &lt;&lt; 128) /
            ((price_y <b>as</b> u256) * (scale_denom <b>as</b> u256));
    <b>let</b> q64_128_max = ((1 &lt;&lt; 64) &lt;&lt; 128) - 1;
    <b>assert</b>!(val &lt;= q64_128_max, <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_EPriceUndefined">EPriceUndefined</a>);
    val
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_div_price_numeric_x128"></a>

## Function `div_price_numeric_x128`

Returns the price of <code>Y</code> in <code>X</code> such that <code>X * price = Y</code> i.e. <code>price = Y / X</code>.
The returned value is in Q64.128 format.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_div_price_numeric_x128">div_price_numeric_x128</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>, x: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, y: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_div_price_numeric_x128">div_price_numeric_x128</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a>, x: TypeName, y: TypeName): u256 {
    <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_div_numeric_x128_inner">div_numeric_x128_inner</a>(self, x, y, <b>false</b>)
}
</code></pre>



</details>

<a name="kai_leverage_oracle_price_div_smoothed_price_numeric_x128"></a>

## Function `div_smoothed_price_numeric_x128`

Returns the price of <code>Y</code> in <code>X</code> such that <code>X * price = Y</code> i.e. <code>price = Y / X</code>.
The returned value is in Q64.128 format.
Uses the smoothed (manipulation-resistant) price instead of spot.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_div_smoothed_price_numeric_x128">div_smoothed_price_numeric_x128</a>(self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">kai_leverage::oracle_price::ValidatedPrices</a>, x: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>, y: <a href="../../dependencies/std/type_name.md#std_type_name_TypeName">std::type_name::TypeName</a>): u256
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_div_smoothed_price_numeric_x128">div_smoothed_price_numeric_x128</a>(
    self: &<a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_ValidatedPrices">ValidatedPrices</a>,
    x: TypeName,
    y: TypeName,
): u256 {
    <a href="../../dependencies/kai_leverage/oracle_price.md#kai_leverage_oracle_price_div_numeric_x128_inner">div_numeric_x128_inner</a>(self, x, y, <b>true</b>)
}
</code></pre>



</details>

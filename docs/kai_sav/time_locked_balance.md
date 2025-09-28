
<a name="kai_sav_time_locked_balance"></a>

# Module `kai_sav::time_locked_balance`

<code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a></code> locks a <code>Balance&lt;T&gt;</code> such that only <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> of the amount
gets unlocked (and becomes withdrawable) every second starting from <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a></code>.
It allows for <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> and <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a></code> to be safely changed and allows for
aditional
balance to be added at any point via the <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_top_up">top_up</a></code> function.

This module doesn't implement any permission functionality and it is intended to be used
as a basic building block and to provide safety guarantees for building more complex token
emission modules (e.g. vesting).


-  [Struct `TimeLockedBalance`](#kai_sav_time_locked_balance_TimeLockedBalance)
-  [Function `unlock_start_ts_sec`](#kai_sav_time_locked_balance_unlock_start_ts_sec)
-  [Function `unlock_per_second`](#kai_sav_time_locked_balance_unlock_per_second)
-  [Function `final_unlock_ts_sec`](#kai_sav_time_locked_balance_final_unlock_ts_sec)
-  [Function `get_values`](#kai_sav_time_locked_balance_get_values)
-  [Function `create`](#kai_sav_time_locked_balance_create)
-  [Function `extraneous_locked_amount`](#kai_sav_time_locked_balance_extraneous_locked_amount)
-  [Function `max_withdrawable`](#kai_sav_time_locked_balance_max_withdrawable)
-  [Function `remaining_unlock`](#kai_sav_time_locked_balance_remaining_unlock)
-  [Function `withdraw`](#kai_sav_time_locked_balance_withdraw)
-  [Function `withdraw_all`](#kai_sav_time_locked_balance_withdraw_all)
-  [Function `top_up`](#kai_sav_time_locked_balance_top_up)
-  [Function `change_unlock_per_second`](#kai_sav_time_locked_balance_change_unlock_per_second)
-  [Function `change_unlock_start_ts_sec`](#kai_sav_time_locked_balance_change_unlock_start_ts_sec)
-  [Function `skim_extraneous_balance`](#kai_sav_time_locked_balance_skim_extraneous_balance)
-  [Function `destroy_empty`](#kai_sav_time_locked_balance_destroy_empty)
-  [Function `calc_final_unlock_ts_sec`](#kai_sav_time_locked_balance_calc_final_unlock_ts_sec)
-  [Function `unlockable_amount`](#kai_sav_time_locked_balance_unlockable_amount)
-  [Function `unlock`](#kai_sav_time_locked_balance_unlock)


<pre><code><b>use</b> <a href="../kai_sav/util.md#kai_sav_util">kai_sav::util</a>;
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
<b>use</b> <a href="../dependencies/sui/balance.md#sui_balance">sui::balance</a>;
<b>use</b> <a href="../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../dependencies/sui/dynamic_field.md#sui_dynamic_field">sui::dynamic_field</a>;
<b>use</b> <a href="../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
</code></pre>



<a name="kai_sav_time_locked_balance_TimeLockedBalance"></a>

## Struct `TimeLockedBalance`

Wraps a <code>Balance&lt;T&gt;</code> and allows only <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> of it to be withdrawn
per second starting from <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a></code>. All timestamp fields are unix timestamp.


<pre><code><b>public</b> <b>struct</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;<b>phantom</b> T&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>locked_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>unlocked_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;</code>
</dt>
<dd>
 Balance that gets unlocked and is withdrawable is stored here.
</dd>
<dt>
<code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>: u64</code>
</dt>
<dd>
 Time at which all of the balance will become unlocked. Unix timestamp.
</dd>
<dt>
<code>previous_unlock_at: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_sav_time_locked_balance_unlock_start_ts_sec"></a>

## Function `unlock_start_ts_sec`

Get the unlock start timestamp in seconds.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;): u64 {
    self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_unlock_per_second"></a>

## Function `unlock_per_second`

Get the unlock rate per second.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;): u64 {
    self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_final_unlock_ts_sec"></a>

## Function `final_unlock_ts_sec`

Get the final unlock timestamp in seconds.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;): u64 {
    self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_get_values"></a>

## Function `get_values`

Get unlock configuration values.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_get_values">get_values</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;): (u64, u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_get_values">get_values</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;): (u64, u64, u64) {
    (self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>, self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>, self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>)
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_create"></a>

## Function `create`

Creates a new <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;</code> that will start unlocking at <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a></code> and
unlock <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> of balance per second.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_create">create</a>&lt;T&gt;(locked_balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>: u64, <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>: u64): <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_create">create</a>&lt;T&gt;(
    locked_balance: Balance&lt;T&gt;,
    <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>: u64,
    <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>: u64,
): <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt; {
    <b>let</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a> = <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_calc_final_unlock_ts_sec">calc_final_unlock_ts_sec</a>(
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>,
        balance::value(&locked_balance),
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>,
    );
    <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a> {
        locked_balance,
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>,
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>,
        unlocked_balance: balance::zero&lt;T&gt;(),
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>,
        previous_unlock_at: 0,
    }
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_extraneous_locked_amount"></a>

## Function `extraneous_locked_amount`

Returns the value of extraneous balance.
Since <code>locked_balance</code> amount might not be evenly divisible by <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code>, there will
be some
extraneous balance. E.g. if <code>locked_balance</code> is 21 and <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> is 10, this function
will
return 1. Extraneous balance can be withdrawn by calling <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_skim_extraneous_balance">skim_extraneous_balance</a></code> at any time.
When <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> is 0, all balance in <code>locked_balance</code> is considered extraneous. This
makes
it possible to empty the <code>locked_balance</code> by setting <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> to 0 and then skimming.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_extraneous_locked_amount">extraneous_locked_amount</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_extraneous_locked_amount">extraneous_locked_amount</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;): u64 {
    <b>if</b> (self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a> == 0) {
        balance::value(&self.locked_balance)
    } <b>else</b> {
        balance::value(&self.locked_balance) % self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>
    }
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_max_withdrawable"></a>

## Function `max_withdrawable`

Get the maximum withdrawable amount at current time.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_max_withdrawable">max_withdrawable</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_max_withdrawable">max_withdrawable</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;, clock: &Clock): u64 {
    balance::value(&self.unlocked_balance) + <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlockable_amount">unlockable_amount</a>(self, clock)
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_remaining_unlock"></a>

## Function `remaining_unlock`

Returns the total amount of balance that is yet to be unlocked.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_remaining_unlock">remaining_unlock</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_remaining_unlock">remaining_unlock</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;, clock: &Clock): u64 {
    <b>let</b> start = u64::max(self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>, timestamp_sec(clock));
    <b>if</b> (start &gt;= self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>) {
        <b>return</b> 0
    };
    (self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a> - start) * self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_withdraw"></a>

## Function `withdraw`

Withdraws the specified (unlocked) amount. Errors if amount exceeds max. withdrawable.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_withdraw">withdraw</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, amount: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_withdraw">withdraw</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;, amount: u64, clock: &Clock): Balance&lt;T&gt; {
    <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock">unlock</a>(self, clock);
    balance::split(&<b>mut</b> self.unlocked_balance, amount)
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_withdraw_all"></a>

## Function `withdraw_all`

Withdraw all available unlocked balance.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_withdraw_all">withdraw_all</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_withdraw_all">withdraw_all</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;, clock: &Clock): Balance&lt;T&gt; {
    <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock">unlock</a>(self, clock);
    <b>let</b> amount = balance::value(&self.unlocked_balance);
    balance::split(&<b>mut</b> self.unlocked_balance, amount)
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_top_up"></a>

## Function `top_up`

Adds additional balance to be distributed (i.e. prolongs the duration of distribution).


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_top_up">top_up</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, balance: <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_top_up">top_up</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;, balance: Balance&lt;T&gt;, clock: &Clock) {
    <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock">unlock</a>(self, clock);
    balance::join(&<b>mut</b> self.locked_balance, balance);
    self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a> =
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_calc_final_unlock_ts_sec">calc_final_unlock_ts_sec</a>(
            u64::max(self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>, timestamp_sec(clock)),
            balance::value(&self.locked_balance),
            self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>,
        );
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_change_unlock_per_second"></a>

## Function `change_unlock_per_second`

Changes <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> to a new value. New value is effective starting from the
current timestamp (unlocks up to and including the current timestamp are based on the previous
value).


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_change_unlock_per_second">change_unlock_per_second</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, new_unlock_per_second: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_change_unlock_per_second">change_unlock_per_second</a>&lt;T&gt;(
    self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;,
    new_unlock_per_second: u64,
    clock: &Clock,
) {
    <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock">unlock</a>(self, clock);
    self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a> = new_unlock_per_second;
    self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a> =
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_calc_final_unlock_ts_sec">calc_final_unlock_ts_sec</a>(
            u64::max(self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>, timestamp_sec(clock)),
            balance::value(&self.locked_balance),
            new_unlock_per_second,
        );
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_change_unlock_start_ts_sec"></a>

## Function `change_unlock_start_ts_sec`

Changes <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a></code> to a new value. If the new value is in the past, it will be set to
the current time.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_change_unlock_start_ts_sec">change_unlock_start_ts_sec</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, new_unlock_start_ts_sec: u64, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_change_unlock_start_ts_sec">change_unlock_start_ts_sec</a>&lt;T&gt;(
    self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;,
    new_unlock_start_ts_sec: u64,
    clock: &Clock,
) {
    <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock">unlock</a>(self, clock);
    <b>let</b> new_unlock_start_ts_sec = u64::max(new_unlock_start_ts_sec, timestamp_sec(clock));
    self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a> = new_unlock_start_ts_sec;
    self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a> =
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_calc_final_unlock_ts_sec">calc_final_unlock_ts_sec</a>(
            new_unlock_start_ts_sec,
            balance::value(&self.locked_balance),
            self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>,
        );
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_skim_extraneous_balance"></a>

## Function `skim_extraneous_balance`

Skims extraneous balance. Since <code>locked_balance</code> might not be evenly divisible by, and balance
is unlocked only in the multiples of <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code>, there might be some extra balance that
will
not be distributed (e.g. if <code>locked_balance</code> is 20 <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> is 10, the extraneous
balance will be 1). This balance can be retrieved using this function.
When <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> is set to 0, all of the balance in <code>locked_balance</code> is considered
extraneous.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_skim_extraneous_balance">skim_extraneous_balance</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;): <a href="../dependencies/sui/balance.md#sui_balance_Balance">sui::balance::Balance</a>&lt;T&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_skim_extraneous_balance">skim_extraneous_balance</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;): Balance&lt;T&gt; {
    <b>let</b> amount = <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_extraneous_locked_amount">extraneous_locked_amount</a>(self);
    balance::split(&<b>mut</b> self.locked_balance, amount)
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_destroy_empty"></a>

## Function `destroy_empty`

Destroys the <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;</code> when its balances are empty.


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_destroy_empty">destroy_empty</a>&lt;T&gt;(self: <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_destroy_empty">destroy_empty</a>&lt;T&gt;(self: <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;) {
    <b>let</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a> {
        locked_balance,
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>: _,
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>: _,
        unlocked_balance,
        <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>: _,
        previous_unlock_at: _,
    } = self;
    balance::destroy_zero(locked_balance);
    balance::destroy_zero(unlocked_balance);
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_calc_final_unlock_ts_sec"></a>

## Function `calc_final_unlock_ts_sec`

Helper function to calculate the <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a></code>. Returns 0 when <code><a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a></code> is 0.


<pre><code><b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_calc_final_unlock_ts_sec">calc_final_unlock_ts_sec</a>(start_ts: u64, amount_to_issue: u64, <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_calc_final_unlock_ts_sec">calc_final_unlock_ts_sec</a>(start_ts: u64, amount_to_issue: u64, <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>: u64): u64 {
    <b>if</b> (<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a> == 0) {
        0
    } <b>else</b> {
        start_ts + (amount_to_issue / <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>)
    }
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_unlockable_amount"></a>

## Function `unlockable_amount`

Returns the amount of <code>locked_balance</code> that can be unlocked at this time.


<pre><code><b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlockable_amount">unlockable_amount</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlockable_amount">unlockable_amount</a>&lt;T&gt;(self: &<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;, clock: &Clock): u64 {
    <b>if</b> (self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a> == 0) {
        <b>return</b> 0
    };
    <b>let</b> now = timestamp_sec(clock);
    <b>if</b> (now &lt;= self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_start_ts_sec">unlock_start_ts_sec</a>) {
        <b>return</b> 0
    };
    <b>let</b> to_remain_locked =
        (
            self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a> - u64::min(self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_final_unlock_ts_sec">final_unlock_ts_sec</a>, now)
        ) * self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>;
    <b>let</b> locked_amount_round =
        balance::value(&self.locked_balance) / self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a> * self.<a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock_per_second">unlock_per_second</a>;
    locked_amount_round - to_remain_locked
}
</code></pre>



</details>

<a name="kai_sav_time_locked_balance_unlock"></a>

## Function `unlock`

Unlocks the balance that is unlockable based on the time passed since previous unlock.
Moves the amount from <code>locked_balance</code> to <code>unlocked_balance</code>.


<pre><code><b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock">unlock</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">kai_sav::time_locked_balance::TimeLockedBalance</a>&lt;T&gt;, clock: &<a href="../dependencies/sui/clock.md#sui_clock_Clock">sui::clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlock">unlock</a>&lt;T&gt;(self: &<b>mut</b> <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_TimeLockedBalance">TimeLockedBalance</a>&lt;T&gt;, clock: &Clock) {
    <b>let</b> now = timestamp_sec(clock);
    <b>if</b> (self.previous_unlock_at == now) {
        <b>return</b>
    };
    <b>let</b> amount = <a href="../kai_sav/time_locked_balance.md#kai_sav_time_locked_balance_unlockable_amount">unlockable_amount</a>(self, clock);
    balance::join(&<b>mut</b> self.unlocked_balance, balance::split(&<b>mut</b> self.locked_balance, amount));
    self.previous_unlock_at = now;
}
</code></pre>



</details>

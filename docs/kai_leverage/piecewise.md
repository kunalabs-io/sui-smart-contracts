
<a name="kai_leverage_piecewise"></a>

# Module `kai_leverage::piecewise`

Piecewise-linear function implementation for modeling interest rate curves.

This module provides utilities for creating and evaluating piecewise-linear functions,
commonly used in DeFi protocols for modeling interest rates that change based on
utilization levels or other parameters.


-  [Struct `Section`](#kai_leverage_piecewise_Section)
-  [Struct `Piecewise`](#kai_leverage_piecewise_Piecewise)
-  [Constants](#@Constants_0)
-  [Function `section`](#kai_leverage_piecewise_section)
-  [Function `create`](#kai_leverage_piecewise_create)
-  [Function `value_at`](#kai_leverage_piecewise_value_at)
-  [Function `range`](#kai_leverage_piecewise_range)


<pre><code><b>use</b> <a href="../../dependencies/kai_leverage/util.md#kai_leverage_util">kai_leverage::util</a>;
<b>use</b> <a href="../../dependencies/std/ascii.md#std_ascii">std::ascii</a>;
<b>use</b> <a href="../../dependencies/std/bcs.md#std_bcs">std::bcs</a>;
<b>use</b> <a href="../../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../../dependencies/std/string.md#std_string">std::string</a>;
<b>use</b> <a href="../../dependencies/std/vector.md#std_vector">std::vector</a>;
<b>use</b> <a href="../../dependencies/sui/address.md#sui_address">sui::address</a>;
<b>use</b> <a href="../../dependencies/sui/clock.md#sui_clock">sui::clock</a>;
<b>use</b> <a href="../../dependencies/sui/hex.md#sui_hex">sui::hex</a>;
<b>use</b> <a href="../../dependencies/sui/object.md#sui_object">sui::object</a>;
<b>use</b> <a href="../../dependencies/sui/party.md#sui_party">sui::party</a>;
<b>use</b> <a href="../../dependencies/sui/transfer.md#sui_transfer">sui::transfer</a>;
<b>use</b> <a href="../../dependencies/sui/tx_context.md#sui_tx_context">sui::tx_context</a>;
<b>use</b> <a href="../../dependencies/sui/vec_map.md#sui_vec_map">sui::vec_map</a>;
</code></pre>



<a name="kai_leverage_piecewise_Section"></a>

## Struct `Section`

A single piece of a piecewise-linear function.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Section">Section</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>end: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>end_val: u64</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="kai_leverage_piecewise_Piecewise"></a>

## Struct `Piecewise`

A piecewise-linear function defined by a start point and sections.


<pre><code><b>public</b> <b>struct</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">Piecewise</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>start: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>start_val: u64</code>
</dt>
<dd>
</dd>
<dt>
<code>sections: vector&lt;<a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Section">kai_leverage::piecewise::Section</a>&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="kai_leverage_piecewise_ENoSections"></a>

Piecewise must have at least one section


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_ENoSections">ENoSections</a>: u64 = 0;
</code></pre>



<a name="kai_leverage_piecewise_EOutOfRange"></a>

x is out of range


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_EOutOfRange">EOutOfRange</a>: u64 = 1;
</code></pre>



<a name="kai_leverage_piecewise_ESectionsNotSorted"></a>

Sections must be sorted by end and not overlap


<pre><code><b>const</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_ESectionsNotSorted">ESectionsNotSorted</a>: u64 = 2;
</code></pre>



<a name="kai_leverage_piecewise_section"></a>

## Function `section`

Create a section with end point and value.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_section">section</a>(end: u64, end_val: u64): <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Section">kai_leverage::piecewise::Section</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_section">section</a>(end: u64, end_val: u64): <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Section">Section</a> {
    <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Section">Section</a> {
        end,
        end_val,
    }
}
</code></pre>



</details>

<a name="kai_leverage_piecewise_create"></a>

## Function `create`

Create a piecewise function from start point and ordered sections.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_create">create</a>(start: u64, start_val: u64, sections: vector&lt;<a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Section">kai_leverage::piecewise::Section</a>&gt;): <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">kai_leverage::piecewise::Piecewise</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_create">create</a>(start: u64, start_val: u64, sections: vector&lt;<a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Section">Section</a>&gt;): <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">Piecewise</a> {
    <b>assert</b>!(sections.length() &gt; 0, <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_ENoSections">ENoSections</a>);
    <b>let</b> <b>mut</b> prev_end = start;
    sections.do_ref!(|s| {
        <b>assert</b>!(s.end &gt; prev_end, <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_ESectionsNotSorted">ESectionsNotSorted</a>);
        prev_end = s.end;
    });
    <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">Piecewise</a> {
        start: start,
        start_val: start_val,
        sections: sections,
    }
}
</code></pre>



</details>

<a name="kai_leverage_piecewise_value_at"></a>

## Function `value_at`

Evaluate the piecewise function at given input using linear interpolation.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_value_at">value_at</a>(pw: &<a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">kai_leverage::piecewise::Piecewise</a>, x: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_value_at">value_at</a>(pw: &<a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">Piecewise</a>, x: u64): u64 {
    <b>assert</b>!(x &gt;= pw.start, <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_EOutOfRange">EOutOfRange</a>);
    <b>let</b> len = pw.sections.length();
    <b>let</b> last_section = pw.sections[len - 1];
    <b>assert</b>!(x &lt;= last_section.end, <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_EOutOfRange">EOutOfRange</a>);
    <b>if</b> (x == pw.start) {
        <b>return</b> pw.start_val
    };
    <b>let</b> <b>mut</b> cs_start = pw.start;
    <b>let</b> <b>mut</b> cs_start_val = pw.start_val;
    <b>let</b> <b>mut</b> cs = pw.sections[0];
    <b>let</b> <b>mut</b> idx = 0;
    <b>while</b> (x &gt; cs.end) {
        cs_start = cs.end;
        cs_start_val = cs.end_val;
        cs = pw.sections[idx + 1];
        idx = idx + 1;
    };
    <b>if</b> (x == cs.end) {
        <b>return</b> cs.end_val
    };
    <b>if</b> (cs_start_val == cs.end_val) {
        <b>return</b> cs_start_val
    };
    <b>let</b> sdy = util::abs_diff(cs.end_val, cs_start_val);
    <b>let</b> sdx = util::abs_diff(cs.end, cs_start);
    <b>let</b> dx = x - cs_start;
    <b>let</b> dy = <a href="../../kai_sav/util.md#kai_sav_util_muldiv">util::muldiv</a>(sdy, dx, sdx);
    <b>if</b> (cs_start_val &lt; cs.end_val) {
        cs_start_val + dy
    } <b>else</b> {
        cs_start_val - dy
    }
}
</code></pre>



</details>

<a name="kai_leverage_piecewise_range"></a>

## Function `range`

Get the valid input range for this piecewise function.


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_range">range</a>(pw: &<a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">kai_leverage::piecewise::Piecewise</a>): (u64, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_range">range</a>(pw: &<a href="../../dependencies/kai_leverage/piecewise.md#kai_leverage_piecewise_Piecewise">Piecewise</a>): (u64, u64) {
    <b>let</b> len = pw.sections.length();
    <b>let</b> last_section = pw.sections[len -1];
    (pw.start, last_section.end)
}
</code></pre>



</details>

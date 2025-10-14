// Copyright (c) Cetus Technology Limited

/// Concentrated Liquidity Market Maker (CLMM) is a new generation of automated market maker (AMM) aiming to improve
/// decentralized exchanges' capital efficiency and provide attractive yield opportunities for liquidity providers.
/// Different from the constant product market maker that only allows liquidity to be distributed uniformly across the
/// full price curve (0, `positive infinity`), CLMM allows liquidity providers to add their liquidity into specified price ranges.
/// The price in a CLMM pool is discrete, rather than continuous. The liquidity allocated into a specific price range
/// by a user is called a liquidity position.
///
/// "Pool" is the core module of Clmm protocol, which defines the trading pairs of "clmmpool".
/// All operations related to trading and liquidity are completed by this module.
module cetus_clmm::pool;

use cetus_clmm::clmm_math;
use cetus_clmm::config::{
    Self,
    GlobalConfig,
    check_pool_manager_role,
    checked_package_version,
    check_emergency_restore_version,
    check_rewarder_manager_role,
    AdminCap
};
use cetus_clmm::partner::{Self, Partner};
use cetus_clmm::position::{Self, Position, PositionManager, PositionInfo, pool_id};
use cetus_clmm::position_snapshot::{Self, PositionLiquiditySnapshot, PositionSnapshot};
use cetus_clmm::rewarder::{Self, RewarderManager, RewarderGlobalVault, rewards_growth_global};
use cetus_clmm::tick::{Self, Tick, TickManager};
use cetus_clmm::tick_math::{Self, min_sqrt_price, max_sqrt_price};
use integer_mate::full_math_u64;
use integer_mate::i128::{Self, is_neg, abs_u128};
use integer_mate::i32::{Self, I32};
use integer_mate::math_u128;
use integer_mate::math_u64;
use move_stl::option_u64;
use std::string::{Self, String, utf8};
use std::type_name::{Self, TypeName};
use sui::balance::{Self, Balance};
use sui::clock::{Self, Clock};
use sui::coin::Coin;
use sui::display;
use sui::dynamic_field;
use sui::dynamic_object_field;
use sui::event;
use sui::package::{Self, Publisher};
use sui::tx_context::sender;

/// The denominator used for calculating protocol fees. Protocol fee rate = protocol_fee_rate / PROTOCOL_FEE_DENOMINATOR
const PROTOCOL_FEE_DENOMINATOR: u64 = 10000;

/// Maximum value for u64 type
#[allow(unused_const)]
const UINT64_MAX: u64 = 18446744073709551615;

/// Parts per million (1,000,000) used for percentage calculations
const PPM: u64 = 1000000;

/// Key used to store position liquidity snapshots in dynamic object fields
const POSITION_LIQUIDITY_SNAPSHOT_KEY: vector<u8> = b"position_liquidity_snapshot";

/// Key used to store pool status in dynamic object fields
const POOL_STATUS_KEY: vector<u8> = b"pool_status";

const PENDING_ADD_LIQUIDITY_KEY: vector<u8> = b"pending_add_liquidity";

// === Errors ===
const EAmountIncorrect: u64 = 0;
const ELiquidityOverflow: u64 = 1;
#[allow(unused_const)]
const ELiquidityUnderflow: u64 = 2;
const ELiquidityIsZero: u64 = 3;
const ENotEnoughLiquidity: u64 = 4;
const ERemainderAmountUnderflow: u64 = 5;
const ESwapAmountInOverflow: u64 = 6;
const ESwapAmountOutOverflow: u64 = 7;
const EFeeAmountOverflow: u64 = 8;
const EInvalidFeeRate: u64 = 9;
#[allow(unused_const)]
const EInvalidFixedCoinType: u64 = 10;
const EWrongSqrtPriceLimit: u64 = 11;
const EPoolIdIsError: u64 = 12;
#[allow(unused_const)]
const EPoolIsPaused: u64 = 13;
const EFlashSwapReceiptNotMatch: u64 = 14;
#[allow(unused_const)]
const EInvalidProtocolFeeRate: u64 = 15;
const EInvalidPartnerRefFeeRate: u64 = 16;
const ERewardNotExist: u64 = 17;
const EAmountOutIsZero: u64 = 18;
const EPoolPositionNotMatch: u64 = 19;
const EFlashLoanReceiptNotMatch: u64 = 20;
#[allow(unused_const)]
const EPoolSqrtPriceRestoreFailed: u64 = 21;
#[allow(unused_const)]
const EPoolLiquidityRestoreFailed: u64 = 22;
const ECannotCloseAttackedPosition: u64 = 23;
const EPoolNotPaused: u64 = 24;
const EOperationNotPermitted: u64 = 25;
const EPublisherNotMatchWithModule: u64 = 26;
const EInvalidRemovePercent: u64 = 27;
#[allow(unused_const)]
const EFundWithdrawalFailed: u64 = 28;
#[allow(unused_const)]
const EInvalidCutValue: u64 = 29;
const EPoolCurrentTickIndexOutOfRange: u64 = 30;
const EPoolHasNoPositionSnapshot: u64 = 31;
const EDeprecatedFunction: u64 = 32;
const ENoProtocolFee: u64 = 33;
const EProtocolFeeNotEnough: u64 = 34;
const EPositionPendingAddLiquidity: u64 = 35;
const EAmountOutLessThanMinAmount: u64 = 36;
// === Struct ===

/// One-Time-Witness for the module.
public struct POOL has drop {}

/// The capability to collect protocol fees from pools
/// Only the holder of this capability can collect protocol fees
/// * `id` - The UID of the capability
public struct ProtocolFeeCollectCap has key, store {
    id: UID,
}

/// The clmmpool
/// * `id` - The UID of the pool
/// * `coin_a` - The balance of coin A
/// * `coin_b` - The balance of coin B
/// * `tick_spacing` - The spacing between initialized ticks
/// * `fee_rate` - The fee rate of the pool
/// * `liquidity` - The liquidity of the pool
/// * `current_sqrt_price` - The current sqrt price
/// * `current_tick_index` - The current tick index
/// * `fee_growth_global_a` - The global fee growth of coin A
/// * `fee_growth_global_b` - The global fee growth of coin B
/// * `fee_protocol_coin_a` - The amount of coin A owned to protocol
/// * `fee_protocol_coin_b` - The amount of coin B owned to protocol
/// * `tick_manager` - The tick manager
/// * `rewarder_manager` - The rewarder manager
/// * `position_manager` - The position manager
/// * `is_pause` - Whether the pool is paused
/// * `index` - The index of the pool
/// * `url` - The URL of the pool
public struct Pool<phantom CoinTypeA, phantom CoinTypeB> has key, store {
    id: UID,
    coin_a: Balance<CoinTypeA>,
    coin_b: Balance<CoinTypeB>,
    tick_spacing: u32,
    fee_rate: u64,
    liquidity: u128,
    current_sqrt_price: u128,
    current_tick_index: I32,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    fee_protocol_coin_a: u64,
    fee_protocol_coin_b: u64,
    tick_manager: TickManager,
    rewarder_manager: RewarderManager,
    position_manager: PositionManager,
    is_pause: bool,
    index: u64,
    url: String,
}

/// The pool status struct that controls which operations are enabled/disabled
/// * `disable_add_liquidity` - Whether adding liquidity is disabled
/// * `disable_remove_liquidity` - Whether removing liquidity is disabled
/// * `disable_swap` - Whether swapping is disabled
/// * `disable_flash_loan` - Whether flash loans are disabled
/// * `disable_collect_fee` - Whether collecting fees is disabled
/// * `disable_collect_reward` - Whether collecting rewards is disabled
public struct Status has copy, drop, store {
    disable_add_liquidity: bool,
    disable_remove_liquidity: bool,
    disable_swap: bool,
    disable_flash_loan: bool,
    disable_collect_fee: bool,
    disable_collect_reward: bool,
}

/// The pool status object that controls which operations are enabled/disabled
/// * `id` - The UID of the pool status
/// * `status` - The status of the pool
public struct PoolStatus has key, store {
    id: UID,
    status: Status,
}

/// The swap result struct that contains the swap result
/// * `amount_in` - The amount of coin A swapped in
/// * `amount_out` - The amount of coin B swapped out
/// * `fee_amount` - The fee amount
/// * `ref_fee_amount` - The reference fee amount
/// * `steps` - The number of steps in the swap
public struct SwapResult has copy, drop {
    amount_in: u64,
    amount_out: u64,
    fee_amount: u64,
    ref_fee_amount: u64,
    steps: u64,
}

/// Flash loan resource for swap.
/// * `pool_id` - The ID of the pool
/// * `a2b` - Whether the swap is from A to B
/// * `partner_id` - The ID of the partner
/// * `pay_amount` - The amount of coin A paid
/// * `ref_fee_amount` - The reference fee amount
public struct FlashSwapReceipt<phantom CoinTypeA, phantom CoinTypeB> {
    pool_id: ID,
    a2b: bool,
    partner_id: ID,
    pay_amount: u64,
    ref_fee_amount: u64,
}

/// The receipt for add liquidity
/// * `pool_id` - The ID of the pool
/// * `amount_a` - The amount of coin A added
/// * `amount_b` - The amount of coin B added
public struct AddLiquidityReceipt<phantom CoinTypeA, phantom CoinTypeB> {
    pool_id: ID,
    amount_a: u64,
    amount_b: u64,
}

/// The receipt for flash loan
/// * `pool_id` - The ID of the pool
/// * `loan_a` - Whether the loan is for coin A
/// * `partner_id` - The ID of the partner
/// * `amount` - The amount of coin A or B borrowed
/// * `fee_amount` - The fee amount
/// * `ref_fee_amount` - The reference fee amount
public struct FlashLoanReceipt {
    pool_id: ID,
    loan_a: bool,
    partner_id: ID,
    amount: u64,
    fee_amount: u64,
    ref_fee_amount: u64,
}

/// The calculated swap result
/// * `amount_in` - The amount of coin swapped in
/// * `amount_out` - The amount of coin swapped out
/// * `fee_amount` - The fee amount
/// * `fee_rate` - The fee rate
/// * `after_sqrt_price` - The sqrt price after the swap
/// * `is_exceed` - Whether the swap exceeds the limit
/// * `step_results` - The results of each step in the swap
public struct CalculatedSwapResult has copy, drop, store {
    amount_in: u64,
    amount_out: u64,
    fee_amount: u64,
    fee_rate: u64,
    after_sqrt_price: u128,
    is_exceed: bool,
    step_results: vector<SwapStepResult>,
}

/// The step swap result
/// * `current_sqrt_price` - The current sqrt price
/// * `target_sqrt_price` - The target sqrt price
/// * `current_liquidity` - The current liquidity
/// * `amount_in` - The amount of coin swapped in
/// * `amount_out` - The amount of coin swapped out
/// * `fee_amount` - The fee amount
/// * `remainder_amount` - The remainder amount
public struct SwapStepResult has copy, drop, store {
    current_sqrt_price: u128,
    target_sqrt_price: u128,
    current_liquidity: u128,
    amount_in: u64,
    amount_out: u64,
    fee_amount: u64,
    remainder_amount: u64,
}

// === Events ===

/// Emited when a position was opened.
/// * `pool` - The ID of the pool
/// * `tick_lower` - The lower tick index
/// * `tick_upper` - The upper tick index
/// * `position` - The ID of the position
public struct OpenPositionEvent has copy, drop, store {
    pool: ID,
    tick_lower: I32,
    tick_upper: I32,
    position: ID,
}

/// Emited when a position was closed.
/// * `pool` - The ID of the pool
/// * `position` - The ID of the position
public struct ClosePositionEvent has copy, drop, store {
    pool: ID,
    position: ID,
}

/// Emited when add liquidity for a position.
/// @deprecated
/// * `pool` - The ID of the pool
/// * `position` - The ID of the position
/// * `tick_lower` - The lower tick index
/// * `tick_upper` - The upper tick index
/// * `liquidity` - The liquidity added
/// * `after_liquidity` - The liquidity after the addition
/// * `amount_a` - The amount of coin A added
/// * `amount_b` - The amount of coin B added
#[allow(unused_field)]
public struct AddLiquidityEvent has copy, drop, store {
    pool: ID,
    position: ID,
    tick_lower: I32,
    tick_upper: I32,
    liquidity: u128,
    after_liquidity: u128,
    amount_a: u64,
    amount_b: u64,
}

public struct AddLiquidityV2Event has copy, drop, store {
    pool: ID,
    position: ID,
    tick_lower: I32,
    tick_upper: I32,
    liquidity: u128,
    after_liquidity: u128,
    current_sqrt_price: u128,
    amount_a: u64,
    amount_b: u64,
}

public struct RemoveLiquidityV2Event has copy, drop, store {
    pool: ID,
    position: ID,
    tick_lower: I32,
    tick_upper: I32,
    liquidity: u128,
    after_liquidity: u128,
    current_sqrt_price: u128,
    amount_a: u64,
    amount_b: u64,
}

/// Emited when remove liquidity from a position.
/// @deprecated
/// * `pool` - The ID of the pool
/// * `position` - The ID of the position
/// * `tick_lower` - The lower tick index
/// * `tick_upper` - The upper tick index
/// * `liquidity` - The liquidity removed
/// * `after_liquidity` - The liquidity after the removal
#[allow(unused_field)]
public struct RemoveLiquidityEvent has copy, drop, store {
    pool: ID,
    position: ID,
    tick_lower: I32,
    tick_upper: I32,
    liquidity: u128,
    after_liquidity: u128,
    amount_a: u64,
    amount_b: u64,
}

/// Emited when swap in a clmmpool.
/// * `atob` - Whether the swap is from A to B
/// * `pool` - The ID of the pool
/// * `partner` - The ID of the partner
/// * `amount_in` - The amount of coin swapped in
/// * `amount_out` - The amount of coin swapped out
/// * `ref_amount` - The reference fee amount
/// * `fee_amount` - The fee amount
/// * `vault_a_amount` - The amount of coin A in the vault
/// * `vault_b_amount` - The amount of coin B in the vault
/// * `before_sqrt_price` - The sqrt price before the swap
/// * `after_sqrt_price` - The sqrt price after the swap
/// * `steps` - The number of steps in the swap
public struct SwapEvent has copy, drop, store {
    atob: bool,
    pool: ID,
    partner: ID,
    amount_in: u64,
    amount_out: u64,
    ref_amount: u64,
    fee_amount: u64,
    vault_a_amount: u64,
    vault_b_amount: u64,
    before_sqrt_price: u128,
    after_sqrt_price: u128,
    steps: u64,
}

/// Emited when the porotocol manager collect protocol fee from clmmpool.
/// * `pool` - The ID of the pool
/// * `amount_a` - The amount of coin A collected
/// * `amount_b` - The amount of coin B collected
public struct CollectProtocolFeeEvent has copy, drop, store {
    pool: ID,
    amount_a: u64,
    amount_b: u64,
}

/// Emited when user collect liquidity fee from a position.
/// * `position` - The ID of the position
/// * `pool` - The ID of the pool
/// * `amount_a` - The amount of coin A collected
/// * `amount_b` - The amount of coin B collected
public struct CollectFeeEvent has copy, drop, store {
    position: ID,
    pool: ID,
    amount_a: u64,
    amount_b: u64,
}

/// Emited when the clmmpool's liqudity fee rate had updated.
/// * `pool` - The ID of the pool
/// * `old_fee_rate` - The old fee rate
/// * `new_fee_rate` - The new fee rate
public struct UpdateFeeRateEvent has copy, drop, store {
    pool: ID,
    old_fee_rate: u64,
    new_fee_rate: u64,
}

/// Emited when the rewarder's emission per second had updated.
/// * `pool` - The ID of the pool
/// * `rewarder_type` - The type of the rewarder
/// * `emissions_per_second` - The emissions per second
public struct UpdateEmissionEvent has copy, drop, store {
    pool: ID,
    rewarder_type: TypeName,
    emissions_per_second: u128,
}

/// Emited when a rewarder append to clmmpool.
/// * `pool` - The ID of the pool
/// * `rewarder_type` - The type of the rewarder
public struct AddRewarderEvent has copy, drop, store {
    pool: ID,
    rewarder_type: TypeName,
}

/// Emited when collect reward from clmmpool's rewarder.
#[allow(unused_field)]
/// * `position` - The ID of the position
/// * `pool` - The ID of the pool
/// * `amount` - The amount of coin collected
public struct CollectRewardEvent has copy, drop, store {
    position: ID,
    pool: ID,
    amount: u64,
}

/// Emited when collect reward from clmmpool's rewarder.
/// * `position` - The ID of the position
/// * `pool` - The ID of the pool
/// * `rewarder_type` - The type of the rewarder
/// * `amount` - The amount of coin collected
public struct CollectRewardV2Event has copy, drop, store {
    position: ID,
    pool: ID,
    rewarder_type: TypeName,
    amount: u64,
}

/// Emited when flash loan in a clmmpool.
/// * `pool` - The ID of the pool
/// * `loan_a` - Whether the loan is for coin A
/// * `partner` - The ID of the partner
/// * `amount` - The amount of coin A or B borrowed
/// * `fee_amount` - The fee amount
/// * `ref_amount` - The reference fee amount
/// * `vault_a_amount` - The amount of coin A in the vault
/// * `vault_b_amount` - The amount of coin B in the vault
public struct FlashLoanEvent has copy, drop, store {
    pool: ID,
    loan_a: bool,
    partner: ID,
    amount: u64,
    fee_amount: u64,
    ref_amount: u64,
    vault_a_amount: u64,
    vault_b_amount: u64,
}

/// Emited when update pool_status
/// * `pool` - The ID of the pool
/// * `is_pause_before` - Whether the pool is paused before the update
/// * `is_pause_after` - Whether the pool is paused after the update
/// * `before_status` - The status before the update
/// * `after_status` - The status after the update
public struct UpdatePoolStatusEvent has copy, drop, store {
    pool: ID,
    is_pause_before: bool,
    is_pause_after: bool,
    before_status: option::Option<Status>,
    after_status: Status,
}

// === public friend Functions ===

/// Initialize the pool package
/// * `otw` - The object type wrapper
/// * `ctx` - The transaction context
fun init(otw: POOL, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);
    transfer::public_transfer(publisher, tx_context::sender(ctx));
}

/// Mint a protocol fee collect cap
/// * `AdminCap` - The admin cap
/// * `address` - The address to mint the cap to
/// * `ctx` - The transaction context
#[allow(lint(public_entry))]
public entry fun mint_protocol_fee_collect_cap(_: &AdminCap, addr: address, ctx: &mut TxContext) {
    let cap = ProtocolFeeCollectCap {
        id: object::new(ctx),
    };
    transfer::transfer(cap, addr);
}

/// Create a new pool, it only allow call by factory module.
/// * `tick_spacing` - The spacing between initialized ticks
/// * `init_sqrt_price` - The clmmpool's initialize sqrt price
/// * `fee_rate` - The clmmpool's fee rate
/// * `index` - The index of the pool
/// * `clock` - The CLOCK of sui framework
/// * `ctx` - The transaction context
public(package) fun new<CoinTypeA, CoinTypeB>(
    tick_spacing: u32,
    init_sqrt_price: u128,
    fee_rate: u64,
    url: String,
    index: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Pool<CoinTypeA, CoinTypeB> {
    let pool = Pool<CoinTypeA, CoinTypeB> {
        id: object::new(ctx),
        coin_a: balance::zero<CoinTypeA>(),
        coin_b: balance::zero<CoinTypeB>(),
        tick_spacing,
        fee_rate,
        liquidity: 0,
        current_sqrt_price: init_sqrt_price,
        current_tick_index: tick_math::get_tick_at_sqrt_price(init_sqrt_price),
        fee_growth_global_a: 0,
        fee_growth_global_b: 0,
        fee_protocol_coin_a: 0,
        fee_protocol_coin_b: 0,
        tick_manager: tick::new(tick_spacing, clock::timestamp_ms(clock), ctx),
        rewarder_manager: rewarder::new(),
        position_manager: position::new(tick_spacing, ctx),
        is_pause: false,
        index,
        url,
    };

    pool
}

#[allow(lint(self_transfer))]
/// Set display for pool.
/// * `config` - The global config object of clmm package.
/// * `publisher` - The publisher object
/// * `name` - The name of the pool
/// * `description` - The description of the pool
/// * `url` - The URL of the pool
/// * `link` - The link of the pool
/// * `website` - The website of the pool
/// * `creator` - The creator of the pool
/// * `ctx` - The transaction context
public fun set_display<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    publisher: &Publisher,
    name: String,
    description: String,
    url: String,
    link: String,
    website: String,
    creator: String,
    ctx: &mut TxContext,
) {
    checked_package_version(config);
    assert!(
        package::from_module<Pool<CoinTypeA, CoinTypeB>>(publisher),
        EPublisherNotMatchWithModule,
    );
    let keys = vector[
        utf8(b"name"),
        utf8(b"coin_a"),
        utf8(b"coin_b"),
        utf8(b"link"),
        utf8(b"image_url"),
        utf8(b"description"),
        utf8(b"project_url"),
        utf8(b"creator"),
    ];
    let coin_type_a = string::from_ascii(type_name::into_string(type_name::get<CoinTypeA>()));
    let coin_type_b = string::from_ascii(type_name::into_string(type_name::get<CoinTypeB>()));
    let values = vector[name, coin_type_a, coin_type_b, link, url, description, website, creator];
    let mut display = display::new_with_fields<Pool<CoinTypeA, CoinTypeB>>(
        publisher,
        keys,
        values,
        ctx,
    );
    display::update_version(&mut display);
    transfer::public_transfer(display, sender(ctx));
}

// === Public Functions ===

/// Open a position
/// * `config` - The global config object of clmm package.
/// * `pool` - The clmmpool object.
/// * `tick_lower` - The lower tick index of position.
/// * `tick_upper` - The upper tick index of position.
/// * `ctx` - The transaction context
/// * Returns the position NFT
public fun open_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    tick_lower: u32,
    tick_upper: u32,
    ctx: &mut TxContext,
): Position {
    checked_package_version(config);
    assert!(is_allow_add_liquidity(pool), EOperationNotPermitted);

    let tick_lower_index = i32::from_u32(tick_lower);
    let tick_upper_index = i32::from_u32(tick_upper);
    let pool_id = object::id(pool);

    let position = position::open_position<CoinTypeA, CoinTypeB>(
        &mut pool.position_manager,
        pool_id,
        pool.index,
        pool.url,
        tick_lower_index,
        tick_upper_index,
        ctx,
    );
    let position_id = object::id(&position);

    event::emit(OpenPositionEvent {
        pool: pool_id,
        tick_upper: tick_upper_index,
        tick_lower: tick_lower_index,
        position: position_id,
    });

    position
}

/// Add liquidity on a position by fix liquidity amount.
/// * `config` - The global config object of clmm package.
/// * `pool` - The clmpool object.
/// * `position_nft` - The position NFT
/// * `delta_liquidity` - The liquidity amount which you want add.
/// * `clock` - The `CLOCK` object
/// * Returns the add liquidity receipt, Flash loan resource for add_liquidity
public fun add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    clock: &Clock,
): AddLiquidityReceipt<CoinTypeA, CoinTypeB> {
    checked_package_version(config);
    assert!(delta_liquidity != 0, ELiquidityIsZero);
    assert!(object::id(pool) == pool_id(position_nft), EPoolPositionNotMatch);

    add_liquidity_internal<CoinTypeA, CoinTypeB>(
        pool,
        position_nft,
        false,
        delta_liquidity,
        0,
        false,
        clock::timestamp_ms(clock) / 1000,
    )
}

/// Add liquidity on a position by fix coin amount.
/// * `config` - The global config object of clmm package.
/// * `pool` - The clmmpool object.
/// * `position_nft` - The position NFT
/// * `amount` - The coin amount which you want add to position.
/// * `fix_amount_a` - Whether the fix coin type is CoinTypeA
/// * `clock` - The `CLOCK` object
/// * Returns the add liquidity receipt, Flash loan resource for add_liquidity
public fun add_liquidity_fix_coin<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    amount: u64,
    fix_amount_a: bool,
    clock: &Clock,
): AddLiquidityReceipt<CoinTypeA, CoinTypeB> {
    checked_package_version(config);
    assert!(amount > 0, EAmountIncorrect);
    assert!(object::id(pool) == pool_id(position_nft), EPoolPositionNotMatch);

    add_liquidity_internal<CoinTypeA, CoinTypeB>(
        pool,
        position_nft,
        true,
        0,
        amount,
        fix_amount_a,
        clock::timestamp_ms(clock) / 1000,
    )
}

/// Get the amount that needs to be paid for liquidity.
/// * `receipt` - The refrence of receipt.
/// * Returns the amount of CoinTypeA that need paid for this receipt.
public fun add_liquidity_pay_amount<CoinTypeA, CoinTypeB>(
    receipt: &AddLiquidityReceipt<CoinTypeA, CoinTypeB>,
): (u64, u64) {
    (receipt.amount_a, receipt.amount_b)
}

/// The cost of increasing liquidity for the position.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `balance_a` - The balance of which type is CoinTypeA, if no need pay this coin pass `balance<CoinTypeA>Zero()`
/// * `balance_b` - The balance of which type is CoinTypeB, if no need pay this coin pass `balance<CoinTypeA>Zero()`
/// * `receipt` - A flash loan resource that can only delete by this function.
public fun repay_add_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    balance_a: Balance<CoinTypeA>,
    balance_b: Balance<CoinTypeB>,
    receipt: AddLiquidityReceipt<CoinTypeA, CoinTypeB>,
) {
    checked_package_version(config);
    let AddLiquidityReceipt<CoinTypeA, CoinTypeB> {
        pool_id,
        amount_a,
        amount_b,
    } = receipt;
    assert!(balance::value<CoinTypeA>(&balance_a) == amount_a, EAmountIncorrect);
    assert!(balance::value<CoinTypeB>(&balance_b) == amount_b, EAmountIncorrect);
    assert!(object::id(pool) == pool_id, EPoolIdIsError);
    pool.clear_pending_add_liquidity();
    // Merge balance
    balance::join<CoinTypeA>(&mut pool.coin_a, balance_a);
    balance::join<CoinTypeB>(&mut pool.coin_b, balance_b);
}

/// Remove liquidity from a position.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool package.
/// * `delta_liquidity` - The amount of liquidity will be remove.
/// * `clock` - The `Clock` object.
/// * Returns the balance object of CoinTypeA and CoinTypeB.
public fun remove_liquidity<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    checked_package_version(config);
    assert!(is_allow_remove_liquidity(pool), EOperationNotPermitted);
    assert!(delta_liquidity > 0, ELiquidityIsZero);
    assert!(object::id(pool) == pool_id(position_nft), EPoolPositionNotMatch);
    pool.assert_no_pending_add_liquidity();

    // update rewarder pool
    rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, clock::timestamp_ms(clock) / 1000);

    let (tick_lower, tick_upper) = position::tick_range(position_nft);

    // 1. Decrease liquidity for position and update [fee/points/rewards]
    let (
        fee_growth_inside_a,
        fee_growth_inside_b,
        rewards_growth_inside,
        points_growth_inside,
    ) = get_fee_rewards_points_in_tick_range(pool, tick_lower, tick_upper);
    let after_liquidity = position::decrease_liquidity(
        &mut pool.position_manager,
        position_nft,
        delta_liquidity,
        fee_growth_inside_a,
        fee_growth_inside_b,
        points_growth_inside,
        rewards_growth_inside,
    );

    // 3. Update ticks
    tick::decrease_liquidity(
        &mut pool.tick_manager,
        pool.current_tick_index,
        tick_lower,
        tick_upper,
        delta_liquidity,
        pool.fee_growth_global_a,
        pool.fee_growth_global_b,
        rewarder::points_growth_global(&pool.rewarder_manager),
        rewards_growth_global(&pool.rewarder_manager),
    );

    // 4. pool liquidity
    if (
        i32::lte(tick_lower, pool.current_tick_index) &&
                i32::lt(pool.current_tick_index, tick_upper)
    ) {
        pool.liquidity = pool.liquidity - delta_liquidity;
    };

    let (amount_a, amount_b) = clmm_math::get_amount_by_liquidity(
        tick_lower,
        tick_upper,
        pool.current_tick_index,
        pool.current_sqrt_price,
        delta_liquidity,
        false,
    );

    let (balance_a, balance_b) = (
        balance::split<CoinTypeA>(&mut pool.coin_a, amount_a),
        balance::split<CoinTypeB>(&mut pool.coin_b, amount_b),
    );

    //Event
    event::emit(RemoveLiquidityV2Event {
        pool: object::id(pool),
        position: object::id(position_nft),
        tick_lower,
        tick_upper,
        liquidity: delta_liquidity,
        after_liquidity,
        current_sqrt_price: pool.current_sqrt_price,
        amount_a,
        amount_b,
    });

    (balance_a, balance_b)
}

public fun remove_liquidity_with_slippage<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    delta_liquidity: u128,
    min_amount_a: u64,
    min_amount_b: u64,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    let (balance_a, balance_b) = remove_liquidity(config, pool, position_nft, delta_liquidity, clock);
    assert!(balance_a.value() >= min_amount_a, EAmountOutLessThanMinAmount);
    assert!(balance_b.value() >= min_amount_b, EAmountOutLessThanMinAmount);
    (balance_a, balance_b)
}

/// Close the position.
/// This operation will destroy the `position`, so before calling it, you need to take away all
/// assets(coin_a,coin_b,rewards) related to this `position`, otherwise it will fail.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `position` - The position's NFT
public fun close_position<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: Position,
) {
    checked_package_version(config);
    assert!(is_allow_remove_liquidity(pool), EOperationNotPermitted);
    assert!(object::id(pool) == pool_id(&position_nft), EPoolPositionNotMatch);

    let position_id = object::id(&position_nft);
    if (
        dynamic_object_field::exists_<String>(
            &pool.id,
            string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY),
        )
    ) {
        let snapshot = dynamic_object_field::borrow_mut<String, PositionLiquiditySnapshot>(
            &mut pool.id,
            string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY),
        );
        assert!(!position_snapshot::contains(snapshot, position_id), ECannotCloseAttackedPosition);
    };

    position::close_position(
        &mut pool.position_manager,
        position_nft,
    );

    event::emit(ClosePositionEvent {
        pool: object::id(pool),
        position: position_id,
    });
}

/// Collect the fee from position.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `position_nft` - The position's NFT.
/// * `recalcuate` - There are multiple scenarios where, for example, `add_liquidity`/`remove_liquidity`
/// will settle fees. If `collect_fee` and these operations are in the same transaction, and `collect_fee`
/// comes after them, then recalculating will not have any impact on the result. In this case, `recalculate`
/// can be set to `false` to save gas.
/// * Returns the balance object of CoinTypeA and CoinTypeB.
public fun collect_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &Position,
    recalculate: bool,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    checked_package_version(config);
    assert!(is_allow_collect_fee(pool), EOperationNotPermitted);
    assert!(object::id(pool) == pool_id(position_nft), EPoolPositionNotMatch);

    let position_id = object::id(position_nft);
    let liquidity = position::liquidity(position_nft);
    let (tick_lower, tick_upper) = position::tick_range(position_nft);
    let (amount_a, amount_b) = if (recalculate && liquidity != 0) {
        let (fee_growth_inside_a, fee_growth_inside_b) = get_fee_in_tick_range<
            CoinTypeA,
            CoinTypeB,
        >(
            pool,
            tick_lower,
            tick_upper,
        );
        position::update_and_reset_fee(
            &mut pool.position_manager,
            position_id,
            fee_growth_inside_a,
            fee_growth_inside_b,
        )
    } else {
        position::reset_fee(&mut pool.position_manager, position_id)
    };

    let coin_a = balance::split<CoinTypeA>(&mut pool.coin_a, amount_a);
    let coin_b = balance::split<CoinTypeB>(&mut pool.coin_b, amount_b);

    event::emit(CollectFeeEvent {
        pool: object::id(pool),
        amount_a,
        amount_b,
        position: position_id,
    });
    (coin_a, coin_b)
}

/// Collect rewarder from position.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `position_nft` - The position's NFT.
/// * `recalcuate` - This flag is used to specify whether to recalculate the reward for the position,
/// just like the handling fee.
/// * `clock` - The `Clock` object.
/// * Returns the balance object of CoinTypeC.
public fun collect_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &Position,
    vault: &mut RewarderGlobalVault,
    recalculate: bool,
    clock: &Clock,
): Balance<CoinTypeC> {
    checked_package_version(config);
    assert!(is_allow_collect_reward(pool), EOperationNotPermitted);
    assert!(object::id(pool) == pool_id(position_nft), EPoolPositionNotMatch);

    rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, clock::timestamp_ms(clock) / 1000);

    let position_id = object::id(position_nft);
    let position_liquidity = position::liquidity(position_nft);
    let mut opt_rewarder_index = rewarder::rewarder_index<CoinTypeC>(&pool.rewarder_manager);
    assert!(option::is_some(&opt_rewarder_index), ERewardNotExist);
    let rewarder_index = option::extract(&mut opt_rewarder_index);
    let inited_count = position::inited_rewards_count(&pool.position_manager, position_id);
    let reward_amount = if (
        (recalculate && position_liquidity != 0) || (inited_count <= rewarder_index)
    ) {
        let (tick_lower, tick_upper) = position::tick_range(position_nft);
        let rewards_growth_inside = get_rewards_in_tick_range<CoinTypeA, CoinTypeB>(
            pool,
            tick_lower,
            tick_upper,
        );
        position::update_and_reset_rewards(
            &mut pool.position_manager,
            position_id,
            rewards_growth_inside,
            rewarder_index,
        )
    } else {
        position::reset_rewarder(&mut pool.position_manager, position_id, rewarder_index)
    };
    let balance_reward = rewarder::withdraw_reward<CoinTypeC>(vault, reward_amount);

    event::emit(CollectRewardV2Event {
        pool: object::id(pool),
        position: position_id,
        rewarder_type: type_name::get<CoinTypeC>(),
        amount: reward_amount,
    });

    balance_reward
}

/// Calculate the positions's rewards and update it and return its.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `position_id` - The object id of position's NFT.
/// * `recalcuate` - A flag
/// * `clock` - The `Clock` object.
/// * Returns the vector of reward amounts.
public fun calculate_and_update_rewards<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clock: &Clock,
): vector<u64> {
    checked_package_version(config);
    assert!(is_allow_collect_reward(pool), EOperationNotPermitted);

    rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, clock::timestamp_ms(clock) / 1000);

    let position_info = position::borrow_position_info(&pool.position_manager, position_id);
    let position_liquidity = position::info_liquidity(position_info);
    let rewards_amount_owned = if (position_liquidity != 0) {
        let (tick_lower, tick_upper) = position::info_tick_range(position_info);
        let rewards_growth_inside = get_rewards_in_tick_range<CoinTypeA, CoinTypeB>(
            pool,
            tick_lower,
            tick_upper,
        );
        position::update_rewards(&mut pool.position_manager, position_id, rewards_growth_inside)
    } else {
        position::rewards_amount_owned(&pool.position_manager, position_id)
    };
    rewards_amount_owned
}

/// Calculate and update the position's rewards and return one of which reward type is `CoinTypeC`.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `position_id` - The object id of position's NFT.
/// * `clock` - The `Clock` object.
/// * Returns the pending reward amount.
public fun calculate_and_update_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clock: &Clock,
): u64 {
    let mut opt_rewarder_index = rewarder::rewarder_index<CoinTypeC>(&pool.rewarder_manager);
    assert!(option::is_some(&opt_rewarder_index), ERewardNotExist);
    let rewards = calculate_and_update_rewards(
        config,
        pool,
        position_id,
        clock,
    );
    *vector::borrow(&rewards, option::extract(&mut opt_rewarder_index))
}

/// Calculate and update the position's point and return it.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `position_id` - The object id of position's NFT.
/// * `clock` - The `Clock` object.
/// * Returns the current point of `position`.
public fun calculate_and_update_points<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
    clock: &Clock,
): u128 {
    checked_package_version(config);
    assert!(is_allow_collect_reward(pool), EOperationNotPermitted);

    rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, clock::timestamp_ms(clock) / 1000);

    let position_info = position::borrow_position_info(&pool.position_manager, position_id);
    let position_liquidity = position::info_liquidity(position_info);
    if (position_liquidity != 0) {
        let (tick_lower, tick_upper) = position::info_tick_range(position_info);
        let points_growth_inside = get_points_in_tick_range<CoinTypeA, CoinTypeB>(
            pool,
            tick_lower,
            tick_upper,
        );
        position::update_points(
            &mut pool.position_manager,
            position_id,
            points_growth_inside,
        )
    } else {
        position::info_points_owned(position_info)
    }
}

/// Calculate and update the position's fee and return it.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `position_id` - The object id of position's NFT.
/// * Returns the fee amount of `CoinTypeA` and `CoinTypeB`.
public fun calculate_and_update_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): (u64, u64) {
    checked_package_version(config);
    assert!(is_allow_collect_fee(pool), EOperationNotPermitted);
    let position_info = position::borrow_position_info(&pool.position_manager, position_id);
    let position_liquidity = position::info_liquidity(position_info);
    if (position_liquidity != 0) {
        let (tick_lower, tick_upper) = position::info_tick_range(position_info);
        let (fee_growth_inside_a, fee_growth_inside_b) = get_fee_in_tick_range<
            CoinTypeA,
            CoinTypeB,
        >(
            pool,
            tick_lower,
            tick_upper,
        );
        position::update_fee(
            &mut pool.position_manager,
            position_id,
            fee_growth_inside_a,
            fee_growth_inside_b,
        )
    } else {
        position::info_fee_owned(position_info)
    }
}

/// Calculate the position's amount_a/amount_b
/// * `pool` - The clmm pool object.
/// * `position_id` - The object id of position's NFT.
/// * Returns the amount of `CoinTypeA` and `CoinTypeB`.
public fun get_position_amounts<CoinTypeA, CoinTypeB>(
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _position_id: ID,
): (u64, u64) {
    abort EDeprecatedFunction
}

/// Calculate the position's amount_a/amount_b
/// * `pool` - The clmm pool object.
/// * `position_id` - The object id of position's NFT.
/// * Returns the amount of `CoinTypeA` and `CoinTypeB`.
public fun get_position_amounts_v2<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): (u64, u64) {
    let position_info = position::borrow_position_info(&pool.position_manager, position_id);
    let (tick_lower, tick_upper) = position::info_tick_range(position_info);
    let liquidity = position::info_liquidity(position_info);
    let (amount_a, amount_b) = clmm_math::get_amount_by_liquidity(
        tick_lower,
        tick_upper,
        pool.current_tick_index,
        pool.current_sqrt_price,
        liquidity,
        false,
    );
    (amount_a, amount_b)
}

/// Flash swap
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `a2b` - One flag, if true, indicates that coin of `CoinTypeA` is exchanged with the coin of `CoinTypeB`,
/// otherwise it indicates that the coin of `CoinTypeB` is exchanged with the coin of `CoinTypeA`.
/// * `by_amount_in` - A flag, if set to true, indicates that the next `amount` parameter specifies
/// the input amount, otherwise it specifies the output amount.
/// * `amount` - The amount that indicates input or output.
/// * `sqrt_price_limit` - Price limit, if the swap causes the price to it value, the swap will stop here and return
/// * `clock` - The `Clock` object.
public fun flash_swap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>) {
    checked_package_version(config);
    assert!(is_allow_swap(pool), EOperationNotPermitted);

    flash_swap_internal(
        pool,
        config,
        object::id_from_address(@0x0),
        0,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        clock,
    )
}

/// Repay for flash swap
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `coin_a` - The object of `CoinTypeA` will pay for flash_swap,
/// * `coin_b` - The object of `CoinTypeB` will pay for flash_swap,
/// * `receipt` - The receipt which will be destory.
public fun repay_flash_swap<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    coin_a: Balance<CoinTypeA>,
    coin_b: Balance<CoinTypeB>,
    receipt: FlashSwapReceipt<CoinTypeA, CoinTypeB>,
) {
    checked_package_version(config);

    let FlashSwapReceipt<CoinTypeA, CoinTypeB> {
        pool_id,
        a2b,
        partner_id: _,
        pay_amount,
        ref_fee_amount,
    } = receipt;
    assert!(object::id(pool) == pool_id, EFlashSwapReceiptNotMatch);
    assert!(ref_fee_amount == 0, EFlashSwapReceiptNotMatch);
    if (a2b) {
        assert!(balance::value<CoinTypeA>(&coin_a) == pay_amount, EAmountIncorrect);
        balance::join<CoinTypeA>(&mut pool.coin_a, coin_a);
        balance::destroy_zero<CoinTypeB>(coin_b);
    } else {
        assert!(balance::value<CoinTypeB>(&coin_b) == pay_amount, EAmountIncorrect);
        balance::join<CoinTypeB>(&mut pool.coin_b, coin_b);
        balance::destroy_zero<CoinTypeA>(coin_a);
    };
}

/// Flash swap with partner, like flash swap but there has a partner object for receive ref fee.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `partner` - The partner object.
/// * `a2b` - One flag, if true, indicates that coin of `CoinTypeA` is exchanged with the coin of `CoinTypeB`,
/// otherwise it indicates that the coin of `CoinTypeB` is exchanged with the coin of `CoinTypeA`.
/// * `by_amount_in` - A flag, if set to true, indicates that the next `amount` parameter specifies
/// the input amount, otherwise it specifies the output amount.
/// * `amount` - The amount that indicates input or output.
/// * `sqrt_price_limit` - Price limit, if the swap causes the price to it value, the swap will stop here and return
/// * `clock` - The `Clock` object.
/// * Returns the balance object of CoinTypeA and CoinTypeB and the flash swap receipt.
public fun flash_swap_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &Partner,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>) {
    checked_package_version(config);
    assert!(is_allow_swap(pool), EOperationNotPermitted);

    let ref_fee_rate = partner::current_ref_fee_rate(partner, clock::timestamp_ms(clock) / 1000);
    flash_swap_internal(
        pool,
        config,
        object::id(partner),
        ref_fee_rate,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        clock,
    )
}

/// Repay for flash swap with partner for receive ref fee.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `partner` - The partner object.
/// * `coin_a` - The object of `CoinTypeA` will pay for flash_swap,
/// * `coin_b` - The object of `CoinTypeB` will pay for flash_swap,
/// * `receipt` - The receipt which will be destory.
public fun repay_flash_swap_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &mut Partner,
    mut coin_a: Balance<CoinTypeA>,
    mut coin_b: Balance<CoinTypeB>,
    receipt: FlashSwapReceipt<CoinTypeA, CoinTypeB>,
) {
    checked_package_version(config);

    let FlashSwapReceipt<CoinTypeA, CoinTypeB> {
        pool_id,
        a2b,
        partner_id,
        pay_amount,
        ref_fee_amount,
    } = receipt;
    assert!(object::id(pool) == pool_id, EFlashSwapReceiptNotMatch);
    assert!(object::id(partner) == partner_id, EFlashSwapReceiptNotMatch);
    if (a2b) {
        assert!(balance::value<CoinTypeA>(&coin_a) == pay_amount, EAmountIncorrect);
        // send ref fee to partner
        if (ref_fee_amount > 0) {
            let ref_fee = balance::split<CoinTypeA>(&mut coin_a, ref_fee_amount);
            partner::receive_ref_fee_internal(partner, ref_fee);
        };
        balance::join<CoinTypeA>(&mut pool.coin_a, coin_a);
        balance::destroy_zero<CoinTypeB>(coin_b);
    } else {
        assert!(balance::value<CoinTypeB>(&coin_b) == pay_amount, EAmountIncorrect);
        // send ref fee to partner
        if (ref_fee_amount > 0) {
            let ref_fee = balance::split<CoinTypeB>(&mut coin_b, ref_fee_amount);
            partner::receive_ref_fee_internal(partner, ref_fee);
        };
        balance::join<CoinTypeB>(&mut pool.coin_b, coin_b);
        balance::destroy_zero<CoinTypeA>(coin_a);
    };
}

/// Collect the protocol fee by the protocol_feee_claim_authority
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `ctx` - The transaction context.
/// * Returns the protocol fee balance object of `CoinTypeA` and `CoinTypeB`.
public fun collect_protocol_fee<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    ctx: &TxContext,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    checked_package_version(config);
    config::check_protocol_fee_claim_role(config, tx_context::sender(ctx));

    collect_protocol_fee_internal(pool)
}

/// Collect protocol fees from a pool using the protocol fee collect capability
/// This function allows the holder of a ProtocolFeeCollectCap to collect accumulated protocol fees from a pool.
/// After collection, the protocol fee balances in the pool are reset to 0.
/// * `pool` - The pool to collect fees from
/// * `config` - The global config of the CLMM package
/// * `cap` - The protocol fee collect capability proving authorization.
/// * Returns the collected protocol fees of coin type A and coin type B
public fun collect_protocol_fee_with_cap<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    config: &GlobalConfig,
    cap: &ProtocolFeeCollectCap,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    checked_package_version(config);

    let member = object::id_address(cap);
    config::check_protocol_fee_claim_role(config, member);

    collect_protocol_fee_internal(pool)
}

/// Initialize a `Rewarder` to `Pool` with a reward type of `CoinTypeC`.
/// Only one `Rewarder` per `CoinType` can exist in `Pool`.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `ctx` - The transaction context.
public fun initialize_rewarder<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    ctx: &TxContext,
) {
    checked_package_version(config);

    //check_pool_manager_role(config, tx_context::sender(ctx));
    check_rewarder_manager_role(config, tx_context::sender(ctx));

    rewarder::add_rewarder<CoinTypeC>(&mut pool.rewarder_manager);
    event::emit(AddRewarderEvent {
        pool: object::id(pool),
        rewarder_type: type_name::get<CoinTypeC>(),
    })
}

/// Update the rewarder emission speed to start the rewarder to generate.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `vault` - The `RewarderGlobalVault` object which stores all the rewards to be distributed by Rewarders.
/// * `emissions_per_second` - The parameter represents the number of rewards released per second,
/// which is a fixed-point number with a total of 128 bits, with the decimal part occupying 64 bits.
/// If a value of 0 is passed in, it indicates that the Rewarder's reward release will be paused.
/// * `clock` - The `Clock` object.
/// * `ctx` - The transaction context.
public fun update_emission<CoinTypeA, CoinTypeB, CoinTypeC>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    vault: &RewarderGlobalVault,
    emissions_per_second: u128,
    clock: &Clock,
    ctx: &TxContext,
) {
    checked_package_version(config);

    //check_pool_manager_role(config, tx_context::sender(ctx));
    check_rewarder_manager_role(config, tx_context::sender(ctx));

    let liquidity = pool.liquidity;
    rewarder::update_emission<CoinTypeC>(
        vault,
        &mut pool.rewarder_manager,
        liquidity,
        emissions_per_second,
        clock::timestamp_ms(clock) / 1000,
    );

    event::emit(UpdateEmissionEvent {
        pool: object::id(pool),
        rewarder_type: type_name::get<CoinTypeC>(),
        emissions_per_second,
    })
}

/// Update the position nft image url. Just take effect on the new position
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `url` - The new position nft image url.
/// * `ctx` - The transaction context.
public fun update_position_url<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    url: String,
    ctx: &TxContext,
) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    pool.url = url;
}

/// Update pool fee rate
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `fee_rate` - The pool new fee rate.
/// * `ctx` - The transaction context.
public fun update_fee_rate<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    fee_rate: u64,
    ctx: &TxContext,
) {
    checked_package_version(config);
    if (fee_rate > config::max_fee_rate()) {
        abort EInvalidFeeRate
    };
    check_pool_manager_role(config, tx_context::sender(ctx));

    let old_fee_rate = pool.fee_rate;
    pool.fee_rate = fee_rate;
    event::emit(UpdateFeeRateEvent {
        pool: object::id(pool),
        old_fee_rate,
        new_fee_rate: fee_rate,
    })
}

public fun update_pool<CoinTypeA, CoinTypeB>(
    _config: &GlobalConfig,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _coin_a: Coin<CoinTypeA>,
    _coin_b: Coin<CoinTypeB>,
    _ctx: &TxContext,
) {
    abort 0
}

/// Pause the pool.
/// For special cases, `pause` is used to pause the `Pool`.
/// `unpause` are disabled.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `ctx` - The transaction context.
public fun pause<CoinTypeA, CoinTypeB>(
    _config: &GlobalConfig,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _ctx: &TxContext,
) {
    abort EDeprecatedFunction
}

/// Unpause the pool.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `ctx` - The transaction context.
public fun unpause<CoinTypeA, CoinTypeB>(
    _config: &GlobalConfig,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _ctx: &TxContext,
) {
    abort EDeprecatedFunction
}

/// Flash loan from pool
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `loan_a` - A flag indicating whether to loan coin A (true) or coin B (false).
/// * `amount` - The amount to loan.
/// * Returns (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt)
public fun flash_loan<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    loan_a: bool,
    amount: u64,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt) {
    checked_package_version(config);
    assert!(is_allow_flash_loan(pool), EOperationNotPermitted);

    flash_loan_internal(config, pool, object::id_from_address(@0x0), 0, loan_a, amount)
}

/// Flash loan with partner, like flash loan but there has a partner object for receive ref fee.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `partner` - The partner object for receiving ref fee.
/// * `loan_a` - A flag indicating whether to loan coin A (true) or coin B (false).
/// * `amount` - The amount to loan.
/// * `clock` - The CLOCK of sui framework, used to get current timestamp.
/// * Returns (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt)
public fun flash_loan_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &Partner,
    loan_a: bool,
    amount: u64,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt) {
    checked_package_version(config);
    assert!(is_allow_flash_loan(pool), EOperationNotPermitted);

    let ref_fee_rate = partner::current_ref_fee_rate(partner, clock::timestamp_ms(clock) / 1000);
    flash_loan_internal(config, pool, object::id(partner), ref_fee_rate, loan_a, amount)
}

/// Repay for flash loan
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `balance_a` - The balance of `CoinTypeA` will pay for flash loan,
/// * `balance_b` - The balance of `CoinTypeB` will pay for flash loan,
/// * `receipt` - The receipt which will be destroyed.
public fun repay_flash_loan<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    balance_a: Balance<CoinTypeA>,
    balance_b: Balance<CoinTypeB>,
    receipt: FlashLoanReceipt,
) {
    checked_package_version(config);

    let FlashLoanReceipt {
        pool_id,
        partner_id: _,
        loan_a,
        amount,
        fee_amount,
        ref_fee_amount,
    } = receipt;
    assert!(pool_id == object::id(pool), EFlashLoanReceiptNotMatch);
    assert!(ref_fee_amount == 0, EFlashLoanReceiptNotMatch);
    if (loan_a) {
        assert!(balance::value(&balance_a) == amount + fee_amount, EAmountIncorrect);
        balance::join<CoinTypeA>(&mut pool.coin_a, balance_a);
        balance::destroy_zero<CoinTypeB>(balance_b);
    } else {
        assert!(balance::value(&balance_b) == amount + fee_amount, EAmountIncorrect);
        balance::join<CoinTypeB>(&mut pool.coin_b, balance_b);
        balance::destroy_zero<CoinTypeA>(balance_a);
    };
}

/// Repay for flash loan with partner for receive ref fee.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `partner` - The partner object which will receive ref fee
/// * `balance_a` - The balance of `CoinTypeA` will pay for flash loan,
/// * `balance_b` - The balance of `CoinTypeB` will pay for flash loan,
/// * `receipt` - The receipt which will be destroyed.
public fun repay_flash_loan_with_partner<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner: &mut Partner,
    mut balance_a: Balance<CoinTypeA>,
    mut balance_b: Balance<CoinTypeB>,
    receipt: FlashLoanReceipt,
) {
    checked_package_version(config);

    let FlashLoanReceipt {
        pool_id,
        partner_id,
        loan_a,
        amount,
        fee_amount,
        ref_fee_amount,
    } = receipt;
    assert!(pool_id == object::id(pool), EFlashLoanReceiptNotMatch);
    assert!(partner_id == object::id(partner), EFlashLoanReceiptNotMatch);
    if (loan_a) {
        assert!(balance::value(&balance_a) == amount + fee_amount, EAmountIncorrect);
        if (ref_fee_amount > 0) {
            let ref_fee = balance::split<CoinTypeA>(&mut balance_a, ref_fee_amount);
            partner::receive_ref_fee_internal(partner, ref_fee);
        };
        balance::join<CoinTypeA>(&mut pool.coin_a, balance_a);
        balance::destroy_zero<CoinTypeB>(balance_b);
    } else {
        assert!(balance::value(&balance_b) == amount + fee_amount, EAmountIncorrect);
        if (ref_fee_amount > 0) {
            let ref_fee = balance::split<CoinTypeB>(&mut balance_b, ref_fee_amount);
            partner::receive_ref_fee_internal(partner, ref_fee);
        };
        balance::join<CoinTypeB>(&mut pool.coin_b, balance_b);
        balance::destroy_zero<CoinTypeA>(balance_a);
    };
}

/// Initialize the position snapshot storage(dynamic field object under pool) for the pool.
/// * `config` - The global config of clmm package.
/// * `pool` - The clmm pool object.
/// * `remove_percent` - The percent of the position to be removed.
/// * `ctx` - The transaction context.
#[allow(lint(public_entry))]
public entry fun init_position_snapshot<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    remove_percent: u64,
    ctx: &mut TxContext,
) {
    check_emergency_restore_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));
    assert!(pool.is_pause, EPoolNotPaused);
    assert!(remove_percent <= PPM, EInvalidRemovePercent);
    let position_liquidity_snapshot = position_snapshot::new(
        pool.current_sqrt_price,
        remove_percent,
        ctx,
    );
    dynamic_object_field::add(
        &mut pool.id,
        string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY),
        position_liquidity_snapshot,
    );
}

/// Get the position liquidity snapshot of the pool.
/// * `pool` - The clmm pool object.
/// * Returns the position liquidity snapshot.
public fun position_liquidity_snapshot<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
): &PositionLiquiditySnapshot {
    assert!(
        dynamic_object_field::exists_(&pool.id, string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY)),
        EPoolHasNoPositionSnapshot,
    );
    dynamic_object_field::borrow<String, PositionLiquiditySnapshot>(
        &pool.id,
        string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY),
    )
}

/// Check if the position is attacked.
/// * `pool` - The clmm pool object.
/// * `position_id` - The id of the position.
/// * Returns true if the position is attacked, otherwise false.
public fun is_attacked_position<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): bool {
    if (dynamic_object_field::exists_(&pool.id, string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY))) {
        let snapshot = dynamic_object_field::borrow<String, PositionLiquiditySnapshot>(
            &pool.id,
            string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY),
        );
        position_snapshot::contains(snapshot, position_id)
    } else {
        false
    }
}

/// Get the position snapshot by position id.
/// * `pool` - The clmm pool object.
/// * `position_id` - The id of the position.
/// * Returns the position snapshot.
public fun get_position_snapshot_by_position_id<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): PositionSnapshot {
    assert!(
        dynamic_object_field::exists_(&pool.id, string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY)),
        EPoolHasNoPositionSnapshot,
    );
    let snapshot = dynamic_object_field::borrow<String, PositionLiquiditySnapshot>(
        &pool.id,
        string::utf8(POSITION_LIQUIDITY_SNAPSHOT_KEY),
    );
    position_snapshot::get(snapshot, position_id)
}

/// Applies a proportional cut to the liquidity of a specific position.
///
/// Due to the inability to fully restore pool funds once,
/// we need to reduce each position’s liquidity by a specified delta before reopening the pool.
///
/// This function should be called after data recovery and before reopening the pool for trading.
/// The first step is to snapshot the user's position to preserve its state before reduction,
/// which helps support any future liquidation tracking or accounting.
///
/// * `config` - Global configuration object.
/// * `pool` - The target CLMM pool.
/// * `position_id` - The id of the position to be adjusted.
/// * `cut_value` - The usd value of the position to be cut, only be recorded for future tracking or reconciliation.
/// * `clock` - The current blockchain time context.
/// * `ctx` - The transaction context used for recording state changes.
/// [DEPRECATED] Legacy recovery method used after 2025 incident.
/// No longer in use. Retained only for compatibility. Do not call.
public fun apply_liquidity_cut<CoinTypeA, CoinTypeB>(
    _config: &GlobalConfig,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _position_id: ID,
    _cut_value: u64,
    _clock: &Clock,
    _ctx: &mut TxContext,
) {
    abort EDeprecatedFunction
}

/// Governance-only function to inject tokens into a CLMM pool as part of post-attack recovery.
/// * `config` - Global configuration object, used to verify governance access.
/// * `pool` - The target pool to receive the injected tokens.
/// * `coin_a` - Token A being injected into the pool.
/// * `coin_b` - Token B being injected into the pool.
/// * `ctx` - Transaction context.
/// [DEPRECATED] Legacy recovery method used after 2025 incident.
/// No longer in use. Retained only for compatibility. Do not call.
public fun governance_fund_injection<CoinTypeA, CoinTypeB>(
    _config: &mut GlobalConfig,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _coin_a: Coin<CoinTypeA>,
    _coin_b: Coin<CoinTypeB>,
    _ctx: &mut TxContext,
) {
    abort EDeprecatedFunction
}

/// After the CLMM attack, the pool price must be restored to the current market level.
/// Due to price shifts between the time of the attack and recovery, asset imbalances may occur.
/// This method is intended to withdraw surplus assets post-recovery.
/// * `config` - Global configuration object, used to verify governance access.
/// * `pool` - The target pool to receive the injected tokens.
/// * `amount_a` - The amount of token A to withdraw.
/// * `amount_b` - The amount of token B to withdraw.
/// * `ctx` - Transaction context.
/// [DEPRECATED] Legacy recovery method used after 2025 incident.
/// No longer in use. Retained only for compatibility. Do not call.
#[allow(lint(self_transfer))]
public fun governance_fund_withdrawal<CoinTypeA, CoinTypeB>(
    _config: &mut GlobalConfig,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _amount_a: u64,
    _amount_b: u64,
    _ctx: &mut TxContext,
) {
    abort EDeprecatedFunction
}

/// Removes the malicious PositionInfo and, decrease the specified liquidity from both of its associated ticks in the pool.
/// Here may exsist multiple malicious positions, so this method can be called multiple times.
/// * `config` - Global configuration object, used to verify governance access.
/// * `pool` - The target pool to receive the injected tokens.
/// * `position_id` - The id of the position to be removed.
/// * `ctx` - Transaction context.
/// [DEPRECATED] Legacy recovery method used after 2025 incident.
/// No longer in use. Retained only for compatibility. Do not call.
public fun emergency_remove_malicious_position<CoinTypeA, CoinTypeB>(
    _config: &mut GlobalConfig,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _position_id: ID,
    _ctx: &mut TxContext,
) {
    abort EDeprecatedFunction
}

/// The purpose of this function is to repair the pool state in an emergency scenario. Specifically, it performs the following steps:
///     - 1. Restores the pool price by swapping to the target_sqrt_price, which should reflect the correct pool price prior to the attack.
///     - 2. Performs a consistency check by verifying that the resulting current_liquidity after the swap matches the expected value passed in,
///          ensuring the pool has been correctly restored to a valid state.
/// * `config` - Global configuration object, used to verify governance access.
/// * `pool` - The target pool to receive the injected tokens.
/// * `target_sqrt_price` - The target sqrt price.
/// * `current_liquidity` - The current liquidity of the pool.
/// * `clk` - The current blockchain time context.
/// * `ctx` - Transaction context.
/// [DEPRECATED] Legacy recovery method used after 2025 incident.
/// No longer in use. Retained only for compatibility. Do not call.
public fun emergency_restore_pool_state<CoinTypeA, CoinTypeB>(
    _config: &mut GlobalConfig,
    _pool: &mut Pool<CoinTypeA, CoinTypeB>,
    _target_sqrt_price: u128,
    _current_liquidity: u128,
    _clk: &Clock,
    _ctx: &mut TxContext,
) {
    abort EDeprecatedFunction
}

/// Get the coin amount by liquidity
/// * `tick_lower` - The lower tick.
/// * `tick_upper` - The upper tick.
/// * `current_tick_index` - The current tick index.
/// * `current_sqrt_price` - The current sqrt price.
/// * `liquidity` - The liquidity.
/// * `round_up` - Whether to round up.
/// * Returns (u64, u64)
public fun get_amount_by_liquidity(
    tick_lower: I32,
    tick_upper: I32,
    current_tick_index: I32,
    current_sqrt_price: u128,
    liquidity: u128,
    round_up: bool,
): (u64, u64) {
    clmm_math::get_amount_by_liquidity(
        tick_lower,
        tick_upper,
        current_tick_index,
        current_sqrt_price,
        liquidity,
        round_up,
    )
}

/// Get the liquidity by amount
/// * `lower_index` - The lower tick index.
/// * `upper_index` - The upper tick index.
/// * `current_tick_index` - The current tick index.
/// * `current_sqrt_price` - The current sqrt price.
/// * `amount` - The amount.
/// * `is_fixed_a` - Whether the amount is fixed for coin A.
public fun get_liquidity_from_amount(
    lower_index: I32,
    upper_index: I32,
    current_tick_index: I32,
    current_sqrt_price: u128,
    amount: u64,
    is_fixed_a: bool,
): (u128, u64, u64) {
    clmm_math::get_liquidity_by_amount(
        lower_index,
        upper_index,
        current_tick_index,
        current_sqrt_price,
        amount,
        is_fixed_a,
    )
}

/// Get the fee in tick range.
/// * `pool` - The clmm pool object.
/// * `tick_lower_index` - The lower tick index.
/// * `tick_upper_index` - The upper tick index.
/// * Returns (u128, u128)
public fun get_fee_in_tick_range<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    tick_lower_index: I32,
    tick_upper_index: I32,
): (u128, u128) {
    let opt_tick_lower = tick::try_borrow_tick(&pool.tick_manager, tick_lower_index);
    let opt_tick_upper = tick::try_borrow_tick(&pool.tick_manager, tick_upper_index);
    tick::get_fee_in_range(
        pool.current_tick_index,
        pool.fee_growth_global_a,
        pool.fee_growth_global_b,
        opt_tick_lower,
        opt_tick_upper,
    )
}

/// Get the rewards in tick range.
/// * `pool` - The clmm pool object.
/// * `tick_lower_index` - The lower tick index.
/// * `tick_upper_index` - The upper tick index.
/// * Returns vector<u128>
public fun get_rewards_in_tick_range<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    tick_lower_index: I32,
    tick_upper_index: I32,
): vector<u128> {
    let opt_tick_lower = tick::try_borrow_tick(&pool.tick_manager, tick_lower_index);
    let opt_tick_upper = tick::try_borrow_tick(&pool.tick_manager, tick_upper_index);
    tick::get_rewards_in_range(
        pool.current_tick_index,
        rewarder::rewards_growth_global(&pool.rewarder_manager),
        opt_tick_lower,
        opt_tick_upper,
    )
}

/// Get the points in tick range.
/// * `pool` - The clmm pool object.
/// * `tick_lower_index` - The lower tick index.
/// * `tick_upper_index` - The upper tick index.
/// * Returns u128
public fun get_points_in_tick_range<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    tick_lower_index: I32,
    tick_upper_index: I32,
): u128 {
    let opt_tick_lower = tick::try_borrow_tick(&pool.tick_manager, tick_lower_index);
    let opt_tick_upper = tick::try_borrow_tick(&pool.tick_manager, tick_upper_index);
    tick::get_points_in_range(
        pool.current_tick_index,
        rewarder::points_growth_global(&pool.rewarder_manager),
        opt_tick_lower,
        opt_tick_upper,
    )
}

/// Get the fee, rewards and points in tick range.
/// * `pool` - The clmm pool object.
/// * `tick_lower_index` - The lower tick index.
/// * `tick_upper_index` - The upper tick index.
/// * Returns (u128, u128, vector<u128>, u128)
public fun get_fee_rewards_points_in_tick_range<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    tick_lower_index: I32,
    tick_upper_index: I32,
): (u128, u128, vector<u128>, u128) {
    let opt_tick_lower = tick::try_borrow_tick(&pool.tick_manager, tick_lower_index);
    let opt_tick_upper = tick::try_borrow_tick(&pool.tick_manager, tick_upper_index);
    let (fee_growth_inside_a, fee_growth_inside_b) = tick::get_fee_in_range(
        pool.current_tick_index,
        pool.fee_growth_global_a,
        pool.fee_growth_global_b,
        opt_tick_lower,
        opt_tick_upper,
    );
    let rewards_inside = tick::get_rewards_in_range(
        pool.current_tick_index,
        rewarder::rewards_growth_global(&pool.rewarder_manager),
        opt_tick_lower,
        opt_tick_upper,
    );
    let points_inside = tick::get_points_in_range(
        pool.current_tick_index,
        rewarder::points_growth_global(&pool.rewarder_manager),
        opt_tick_lower,
        opt_tick_upper,
    );
    (fee_growth_inside_a, fee_growth_inside_b, rewards_inside, points_inside)
}

/// Fetch the ticks.
/// * `pool` - The clmm pool object.
/// * `start` - The start vector.
/// * `limit` - The limit.
/// * Returns vector<Tick>
public fun fetch_ticks<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    start: vector<u32>,
    limit: u64,
): vector<Tick> {
    tick::fetch_ticks(&pool.tick_manager, start, limit)
}

/// Fetch the positions.
/// * `pool` - The clmm pool object.
/// * `start` - The start vector.
/// * `limit` - The limit.
/// * Returns vector<PositionInfo>
public fun fetch_positions<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    start: vector<ID>,
    limit: u64,
): vector<PositionInfo> {
    position::fetch_positions(&pool.position_manager, start, limit)
}

/// Calculate the swap result.
/// It is used to perform pre-calculation on swap and does not modify any data.
/// * `pool` - The clmm pool object.
/// * `a2b` - The swap direction.
/// * `by_amount_in` - A flag used to determine whether next arg `amount` represents input or output.
/// * `amount` - You want to fix the value of the input or output of a swap pre-calculation.
/// * Returns CalculatedSwapResult
public fun calculate_swap_result<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
): CalculatedSwapResult {
    let mut current_sqrt_price = pool.current_sqrt_price;
    let mut current_liquidity = pool.liquidity;
    let mut swap_result = default_swap_result();
    let mut remainder_amount = amount;
    let mut opt_next_tick_score = tick::first_score_for_swap(
        &pool.tick_manager,
        pool.current_tick_index,
        a2b,
    );
    let mut result = CalculatedSwapResult {
        amount_in: 0,
        amount_out: 0,
        fee_amount: 0,
        fee_rate: pool.fee_rate,
        after_sqrt_price: pool.current_sqrt_price,
        is_exceed: false,
        step_results: vector::empty(),
    };
    while (remainder_amount > 0) {
        if (option_u64::is_none(&opt_next_tick_score)) {
            result.is_exceed = true;
            break
        };

        let (target_tick, opt_next) = tick::borrow_tick_for_swap(
            &pool.tick_manager,
            option_u64::borrow(&opt_next_tick_score),
            a2b,
        );
        opt_next_tick_score = opt_next;

        let target_sqrt_price = tick::sqrt_price(target_tick);
        let (amount_in, amount_out, next_sqrt_price, fee_amount) = clmm_math::compute_swap_step(
            current_sqrt_price,
            target_sqrt_price,
            current_liquidity,
            remainder_amount,
            pool.fee_rate,
            a2b,
            by_amount_in,
        );

        if (amount_in != 0 || fee_amount != 0) {
            if (by_amount_in) {
                remainder_amount = check_remainer_amount_sub(remainder_amount, amount_in);
                remainder_amount = check_remainer_amount_sub(remainder_amount, fee_amount);
            } else {
                remainder_amount = check_remainer_amount_sub(remainder_amount, amount_out);
            };
            // Update the swap result by step result
            update_swap_result(&mut swap_result, amount_in, amount_out, fee_amount);
        };
        vector::push_back(
            &mut result.step_results,
            SwapStepResult {
                current_sqrt_price,
                target_sqrt_price,
                current_liquidity,
                amount_in,
                amount_out,
                fee_amount,
                remainder_amount,
            },
        );
        if (next_sqrt_price == target_sqrt_price) {
            current_sqrt_price = target_sqrt_price;
            let liquidity_change = if (a2b) {
                i128::neg(tick::liquidity_net(target_tick))
            } else {
                tick::liquidity_net(target_tick)
            };
            // update pool current liquidity
            if (!is_neg(liquidity_change)) {
                let liquidity_change_abs = abs_u128(liquidity_change);
                assert!(
                    math_u128::add_check(current_liquidity, liquidity_change_abs),
                    ELiquidityOverflow,
                );
                current_liquidity = current_liquidity + liquidity_change_abs;
            } else {
                let liquidity_change_abs = abs_u128(liquidity_change);
                assert!(current_liquidity >= liquidity_change_abs, ELiquidityOverflow);
                current_liquidity = current_liquidity - liquidity_change_abs;
            };
        } else {
            current_sqrt_price = next_sqrt_price;
        };
    };
    result.amount_in = swap_result.amount_in;
    result.amount_out = swap_result.amount_out;
    result.fee_amount = swap_result.fee_amount;
    result.after_sqrt_price = current_sqrt_price;
    result
}

/// Get the balances of the pool.
/// * `pool` - The clmm pool object.
/// * Returns (&Balance<CoinTypeA>, &Balance<CoinTypeB>)
public fun balances<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
): (&Balance<CoinTypeA>, &Balance<CoinTypeB>) {
    (&pool.coin_a, &pool.coin_b)
}

/// Get the tick spacing of the pool.
/// * `pool` - The clmm pool object.
/// * Returns u32
public fun tick_spacing<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u32 {
    pool.tick_spacing
}

/// Get the fee rate of the pool.
/// * `pool` - The clmm pool object.
/// * Returns u64
public fun fee_rate<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
    pool.fee_rate
}

/// Get the liquidity of the pool.
/// * `pool` - The clmm pool object.
/// * Returns u128
public fun liquidity<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u128 {
    pool.liquidity
}

/// Get the current sqrt price of the pool.
/// * `pool` - The clmm pool object.
/// * Returns u128
public fun current_sqrt_price<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u128 {
    pool.current_sqrt_price
}

/// Get the current tick index of the pool.
/// * `pool` - The clmm pool object.
/// * Returns I32
public fun current_tick_index<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): I32 {
    pool.current_tick_index
}

/// Get the fees growth global of the pool.
/// * `pool` - The clmm pool object.
/// * Returns (u128, u128)
public fun fees_growth_global<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
): (u128, u128) {
    (pool.fee_growth_global_a, pool.fee_growth_global_b)
}

/// Get the protocol fee of the pool.
/// * `pool` - The clmm pool object.
/// * Returns (u64, u64)
public fun protocol_fee<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): (u64, u64) {
    (pool.fee_protocol_coin_a, pool.fee_protocol_coin_b)
}

/// Get the tick manager of the pool.
/// * `pool` - The clmm pool object.
/// * Returns &TickManager
public fun tick_manager<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): &TickManager {
    &pool.tick_manager
}

/// Get the position manager of the pool.
/// * `pool` - The clmm pool object.
/// * Returns &PositionManager
public fun position_manager<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
): &PositionManager {
    &pool.position_manager
}

/// Get the rewarder manager of the pool.
/// * `pool` - The clmm pool object.
/// * Returns &RewarderManager
public fun rewarder_manager<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
): &RewarderManager {
    &pool.rewarder_manager
}

/// Get the pause state of the pool.
/// * `pool` - The clmm pool object.
/// * Returns bool
public fun is_pause<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): bool {
    pool.is_pause
}

/// Get the index of the pool.
/// * `pool` - The clmm pool object.
/// * Returns u64
public fun index<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): u64 {
    pool.index
}

/// Get the url of the pool.
/// * `pool` - The clmm pool object.
/// * Returns String
public fun url<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): String {
    pool.url
}

/// Borrow the tick of the pool.
/// * `pool` - The clmm pool object.
/// * `tick_idx` - The tick index.
/// * Returns &Tick
public fun borrow_tick<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    tick_idx: I32,
): &Tick {
    tick::borrow_tick(&pool.tick_manager, tick_idx)
}

/// Borrow the position info of the pool.
/// * `pool` - The clmm pool object.
/// * `position_id` - The position id.
/// * Returns &PositionInfo
public fun borrow_position_info<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): &PositionInfo {
    position::borrow_position_info(&pool.position_manager, position_id)
}

/// Get the swap pay amount
/// * `receipt` - The flash swap receipt.
/// * Returns u64
public fun swap_pay_amount<CoinTypeA, CoinTypeB>(
    receipt: &FlashSwapReceipt<CoinTypeA, CoinTypeB>,
): u64 {
    receipt.pay_amount
}

/// Get the ref fee amount
/// * `receipt` - The flash swap receipt.
/// * Returns u64
public fun ref_fee_amount<CoinTypeA, CoinTypeB>(
    receipt: &FlashSwapReceipt<CoinTypeA, CoinTypeB>,
): u64 {
    receipt.ref_fee_amount
}

/// Get the fee from position
/// * `pool` - The clmm pool object.
/// * `position_id` - The position id.
/// * Returns (u64, u64)
public fun get_position_fee<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): (u64, u64) {
    let position_info = position::borrow_position_info(&pool.position_manager, position_id);
    position::info_fee_owned(position_info)
}

/// Get the points from position
/// * `pool` - The clmm pool object.
/// * `position_id` - The position id.
/// * Returns u128
public fun get_position_points<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): u128 {
    let position_info = position::borrow_position_info(&pool.position_manager, position_id);
    position::info_points_owned(position_info)
}

/// Get the rewards amount owned from position
/// * `pool` - The clmm pool object.
/// * `position_id` - The position id.
/// * Returns vector<u64>
public fun get_position_rewards<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): vector<u64> {
    position::rewards_amount_owned(&pool.position_manager, position_id)
}

/// Get the reward amount owned from position
/// * `pool` - The clmm pool object.
/// * `position_id` - The position id.
/// * Returns u64
public fun get_position_reward<CoinTypeA, CoinTypeB, CoinTypeC>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): u64 {
    let mut opt_rewarder_index = rewarder::rewarder_index<CoinTypeC>(&pool.rewarder_manager);
    assert!(option::is_some(&opt_rewarder_index), ERewardNotExist);
    let rewards = position::rewards_amount_owned(&pool.position_manager, position_id);
    *vector::borrow(&rewards, option::extract(&mut opt_rewarder_index))
}

/// Check if the position exists
/// * `pool` - The clmm pool object.
/// * `position_id` - The position id.
/// * Returns bool
public fun is_position_exist<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
    position_id: ID,
): bool {
    position::is_position_exist(&pool.position_manager, position_id)
}

/// Get the amount out of the calculated swap result
/// * `calculatedSwapResult` - The calculated swap result.
/// * Returns u64
public fun calculated_swap_result_amount_out(calculatedSwapResult: &CalculatedSwapResult): u64 {
    return calculatedSwapResult.amount_out
}

/// Check if the calculated swap result is exceed
/// * `calculatedSwapResult` - The calculated swap result.
/// * Returns bool
public fun calculated_swap_result_is_exceed(calculatedSwapResult: &CalculatedSwapResult): bool {
    return calculatedSwapResult.is_exceed
}

/// Get the amount in of the calculated swap result
/// * `calculatedSwapResult` - The calculated swap result.
/// * Returns u64
public fun calculated_swap_result_amount_in(calculatedSwapResult: &CalculatedSwapResult): u64 {
    return calculatedSwapResult.amount_in
}

/// Get the after sqrt price of the calculated swap result
/// * `calculatedSwapResult` - The calculated swap result.
/// * Returns u128
public fun calculated_swap_result_after_sqrt_price(
    calculatedSwapResult: &CalculatedSwapResult,
): u128 {
    return calculatedSwapResult.after_sqrt_price
}

/// Get the fee amount of the calculated swap result
/// * `calculatedSwapResult` - The calculated swap result.
/// * Returns u64
public fun calculated_swap_result_fee_amount(calculatedSwapResult: &CalculatedSwapResult): u64 {
    return calculatedSwapResult.fee_amount
}

/// Get the step results of the calculated swap result
/// * `calculatedSwapResult` - The calculated swap result.
/// * Returns &vector<SwapStepResult>
public fun calculate_swap_result_step_results(
    calculatedSwapResult: &CalculatedSwapResult,
): &vector<SwapStepResult> {
    return &calculatedSwapResult.step_results
}

/// Get the length of the step results of the calculated swap result
/// * `calculatedSwapResult` - The calculated swap result.
/// * Returns u64
public fun calculated_swap_result_steps_length(calculatedSwapResult: &CalculatedSwapResult): u64 {
    return vector::length<SwapStepResult>(&calculatedSwapResult.step_results)
}

/// Get the step swap result of the calculated swap result
/// * `calculatedSwapResult` - The calculated swap result.
/// * `index` - The index of the step swap result.
/// * Returns &SwapStepResult
public fun calculated_swap_result_step_swap_result(
    calculatedSwapResult: &CalculatedSwapResult,
    index: u64,
): &SwapStepResult {
    return vector::borrow<SwapStepResult>(&calculatedSwapResult.step_results, index)
}

/// Get the amount in of the step swap result
/// * `stepSwapResult` - The step swap result.
/// * Returns u64
public fun step_swap_result_amount_in(stepSwapResult: &SwapStepResult): u64 {
    return stepSwapResult.amount_in
}

/// Get the amount out of the step swap result
/// * `stepSwapResult` - The step swap result.
/// * Returns u64
public fun step_swap_result_amount_out(stepSwapResult: &SwapStepResult): u64 {
    return stepSwapResult.amount_out
}

/// Get the fee amount of the step swap result
/// * `stepSwapResult` - The step swap result.
/// * Returns u64
public fun step_swap_result_fee_amount(stepSwapResult: &SwapStepResult): u64 {
    return stepSwapResult.fee_amount
}

/// Get the current sqrt price of the step swap result
/// * `stepSwapResult` - The step swap result.
/// * Returns u128
public fun step_swap_result_current_sqrt_price(stepSwapResult: &SwapStepResult): u128 {
    return stepSwapResult.current_sqrt_price
}

/// Get the target sqrt price of the step swap result
/// * `stepSwapResult` - The step swap result.
/// * Returns u128
public fun step_swap_result_target_sqrt_price(stepSwapResult: &SwapStepResult): u128 {
    return stepSwapResult.target_sqrt_price
}

/// Get the current liquidity of the step swap result
/// * `stepSwapResult` - The step swap result.
/// * Returns u128
public fun step_swap_result_current_liquidity(stepSwapResult: &SwapStepResult): u128 {
    return stepSwapResult.current_liquidity
}

/// Get the remainder amount of the step swap result
/// * `stepSwapResult` - The step swap result.
/// * Returns u64
public fun step_swap_result_remainder_amount(stepSwapResult: &SwapStepResult): u64 {
    return stepSwapResult.remainder_amount
}

/// Check if the swap is allowed
/// * `pool` - The clmm pool object.
/// * Returns bool
public fun is_allow_swap<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): bool {
    if (dynamic_object_field::exists_(&pool.id, string::utf8(POOL_STATUS_KEY))) {
        let pool_status = dynamic_object_field::borrow<string::String, PoolStatus>(
            &pool.id,
            string::utf8(POOL_STATUS_KEY),
        );
        !pool_status.status.disable_swap
    } else {
        !pool.is_pause
    }
}

/// Check if the add liquidity is allowed
/// * `pool` - The clmm pool object.
/// * Returns bool
public fun is_allow_add_liquidity<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): bool {
    if (dynamic_object_field::exists_(&pool.id, string::utf8(POOL_STATUS_KEY))) {
        let pool_status = dynamic_object_field::borrow<string::String, PoolStatus>(
            &pool.id,
            string::utf8(POOL_STATUS_KEY),
        );
        !pool_status.status.disable_add_liquidity
    } else {
        !pool.is_pause
    }
}

/// Check if the remove liquidity is allowed
/// * `pool` - The clmm pool object.
/// * Returns bool
public fun is_allow_remove_liquidity<CoinTypeA, CoinTypeB>(
    pool: &Pool<CoinTypeA, CoinTypeB>,
): bool {
    if (dynamic_object_field::exists_(&pool.id, string::utf8(POOL_STATUS_KEY))) {
        let pool_status = dynamic_object_field::borrow<string::String, PoolStatus>(
            &pool.id,
            string::utf8(POOL_STATUS_KEY),
        );
        !pool_status.status.disable_remove_liquidity
    } else {
        !pool.is_pause
    }
}

/// Check if the flash loan is allowed
/// * `pool` - The clmm pool object.
/// * Returns bool
public fun is_allow_flash_loan<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): bool {
    if (dynamic_object_field::exists_(&pool.id, string::utf8(POOL_STATUS_KEY))) {
        let pool_status = dynamic_object_field::borrow<string::String, PoolStatus>(
            &pool.id,
            string::utf8(POOL_STATUS_KEY),
        );
        !pool_status.status.disable_flash_loan
    } else {
        !pool.is_pause
    }
}

/// Check if the collect fee is allowed
/// * `pool` - The clmm pool object.
/// * Returns bool
public fun is_allow_collect_fee<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): bool {
    if (dynamic_object_field::exists_(&pool.id, string::utf8(POOL_STATUS_KEY))) {
        let pool_status = dynamic_object_field::borrow<string::String, PoolStatus>(
            &pool.id,
            string::utf8(POOL_STATUS_KEY),
        );
        !pool_status.status.disable_collect_fee
    } else {
        !pool.is_pause
    }
}

/// Check if the collect reward is allowed
/// * `pool` - The clmm pool object.
/// * Returns bool
public fun is_allow_collect_reward<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>): bool {
    if (dynamic_object_field::exists_(&pool.id, string::utf8(POOL_STATUS_KEY))) {
        let pool_status = dynamic_object_field::borrow<string::String, PoolStatus>(
            &pool.id,
            string::utf8(POOL_STATUS_KEY),
        );
        !pool_status.status.disable_collect_reward
    } else {
        !pool.is_pause
    }
}

/// Set the pool status
/// * `config` - The global config object.
/// * `pool` - The clmm pool object.
/// * `disable_add_liquidity` - The disable add liquidity flag.
/// * `disable_remove_liquidity` - The disable remove liquidity flag.
/// * `disable_swap` - The disable swap flag.
/// * `disable_flash_loan` - The disable flash loan flag.
/// * `disable_collect_fee` - The disable collect fee flag.
/// * `disable_collect_reward` - The disable collect reward flag.
/// * `ctx` - The transaction context.
public fun set_pool_status<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    disable_add_liquidity: bool,
    disable_remove_liquidity: bool,
    disable_swap: bool,
    disable_flash_loan: bool,
    disable_collect_fee: bool,
    disable_collect_reward: bool,
    ctx: &mut TxContext,
) {
    checked_package_version(config);
    check_pool_manager_role(config, tx_context::sender(ctx));

    let is_pause_before = pool.is_pause;
    pool.is_pause = (
        disable_add_liquidity || disable_remove_liquidity || disable_swap || disable_flash_loan || disable_collect_fee || disable_collect_reward,
    );
    let (before_status, after_status) = if (
        dynamic_object_field::exists_(&pool.id, string::utf8(POOL_STATUS_KEY))
    ) {
        let pool_status = dynamic_object_field::borrow_mut<string::String, PoolStatus>(
            &mut pool.id,
            string::utf8(POOL_STATUS_KEY),
        );
        let before_status = pool_status.status;
        pool_status.status.disable_add_liquidity = disable_add_liquidity;
        pool_status.status.disable_remove_liquidity = disable_remove_liquidity;
        pool_status.status.disable_swap = disable_swap;
        pool_status.status.disable_flash_loan = disable_flash_loan;
        pool_status.status.disable_collect_fee = disable_collect_fee;
        pool_status.status.disable_collect_reward = disable_collect_reward;
        (option::some(before_status), pool_status.status)
    } else {
        let pool_status = PoolStatus {
            id: object::new(ctx),
            status: Status {
                disable_add_liquidity,
                disable_remove_liquidity,
                disable_swap,
                disable_flash_loan,
                disable_collect_fee,
                disable_collect_reward,
            },
        };
        let after_status = pool_status.status;
        dynamic_object_field::add(&mut pool.id, string::utf8(POOL_STATUS_KEY), pool_status);
        (option::none(), after_status)
    };
    event::emit(UpdatePoolStatusEvent {
        pool: object::id(pool),
        is_pause_before,
        is_pause_after: pool.is_pause,
        before_status,
        after_status,
    });
}

// === Private  Methods ===

// Add liquidity in pool
fun add_liquidity_internal<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    by_amount: bool,
    liquidity: u128,
    amount: u64,
    fix_amount_a: bool,
    timestamp: u64,
): AddLiquidityReceipt<CoinTypeA, CoinTypeB> {
    assert!(is_allow_add_liquidity(pool), EOperationNotPermitted);
    let position_id = object::id(position_nft);
    pool.mark_pending_add_liquidity();

    // update rewarder
    rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, timestamp);

    // Increase liquidity for position
    let (tick_lower, tick_upper) = position::tick_range(position_nft);
    let (delta_liquidity, amount_a, amount_b) = if (by_amount) {
        clmm_math::get_liquidity_by_amount(
            tick_lower,
            tick_upper,
            pool.current_tick_index,
            pool.current_sqrt_price,
            amount,
            fix_amount_a,
        )
    } else {
        let (amount_a, amount_b) = clmm_math::get_amount_by_liquidity(
            tick_lower,
            tick_upper,
            pool.current_tick_index,
            pool.current_sqrt_price,
            liquidity,
            true,
        );
        (liquidity, amount_a, amount_b)
    };
    assert!(delta_liquidity > 0, ELiquidityIsZero);

    let (
        fee_growth_inside_a,
        fee_growth_inside_b,
        rewards_growth_inside,
        points_growth_inside,
    ) = get_fee_rewards_points_in_tick_range(pool, tick_lower, tick_upper);
    let after_liquidity = position::increase_liquidity(
        &mut pool.position_manager,
        position_nft,
        delta_liquidity,
        fee_growth_inside_a,
        fee_growth_inside_b,
        points_growth_inside,
        rewards_growth_inside,
    );

    // Increase liquidity for tick
    tick::increase_liquidity(
        &mut pool.tick_manager,
        pool.current_tick_index,
        tick_lower,
        tick_upper,
        delta_liquidity,
        pool.fee_growth_global_a,
        pool.fee_growth_global_b,
        rewarder::points_growth_global(&pool.rewarder_manager),
        rewards_growth_global(&pool.rewarder_manager),
    );

    // Increase pool's current liquidity if need.
    if (
        i32::gte(pool.current_tick_index, tick_lower) &&
                i32::lt(pool.current_tick_index, tick_upper)
    ) {
        assert!(math_u128::add_check(pool.liquidity, delta_liquidity), ELiquidityOverflow);
        pool.liquidity = pool.liquidity + delta_liquidity
    };

    // Event
    event::emit(AddLiquidityV2Event {
        pool: object::id(pool),
        position: position_id,
        tick_lower,
        tick_upper,
        liquidity,
        after_liquidity,
        current_sqrt_price: pool.current_sqrt_price,
        amount_a,
        amount_b,
    });

    AddLiquidityReceipt<CoinTypeA, CoinTypeB> {
        pool_id: object::id(pool),
        amount_a,
        amount_b,
    }
}

/// Swap output coin and flash loan resource.
fun flash_swap_internal<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    config: &GlobalConfig,
    partner_id: ID,
    ref_fee_rate: u64,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>) {
    // Check amount_in/amount_out input, disable change the pool current price when amount_in/amount_out is zero.
    assert!(amount > 0, EAmountIncorrect);

    rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, clock::timestamp_ms(clock) / 1000);

    if (a2b) {
        assert!(
            pool.current_sqrt_price > sqrt_price_limit && sqrt_price_limit >= min_sqrt_price(),
            EWrongSqrtPriceLimit,
        );
    } else {
        assert!(
            pool.current_sqrt_price < sqrt_price_limit && sqrt_price_limit <= max_sqrt_price(),
            EWrongSqrtPriceLimit,
        );
    };

    let before_sqrt_price = pool.current_sqrt_price;
    let protocol_fee_rate = config::protocol_fee_rate(config);
    let result = swap_in_pool<CoinTypeA, CoinTypeB>(
        pool,
        a2b,
        by_amount_in,
        sqrt_price_limit,
        amount,
        protocol_fee_rate,
        ref_fee_rate,
    );

    let (vault_a_amount, vault_b_amount) = (
        balance::value<CoinTypeA>(&pool.coin_a),
        balance::value<CoinTypeB>(
            &pool.coin_b,
        ),
    );
    let (coin_a, coin_b) = if (a2b) {
        (balance::zero<CoinTypeA>(), balance::split<CoinTypeB>(&mut pool.coin_b, result.amount_out))
    } else {
        (balance::split<CoinTypeA>(&mut pool.coin_a, result.amount_out), balance::zero<CoinTypeB>())
    };

    // Check amount_out of swap result, disallow amount out is zero.
    assert!(result.amount_out > 0, EAmountOutIsZero);

    //event
    event::emit(SwapEvent {
        atob: a2b,
        pool: object::id(pool),
        partner: partner_id,
        amount_in: result.amount_in + result.fee_amount,
        amount_out: result.amount_out,
        ref_amount: result.ref_fee_amount,
        fee_amount: result.fee_amount,
        vault_a_amount,
        vault_b_amount,
        before_sqrt_price,
        after_sqrt_price: pool.current_sqrt_price,
        steps: result.steps,
    });

    // Return the out coin and swap receipt
    (
        coin_a,
        coin_b,
        FlashSwapReceipt<CoinTypeA, CoinTypeB> {
            pool_id: object::id(pool),
            a2b,
            partner_id,
            pay_amount: result.amount_in + result.fee_amount,
            ref_fee_amount: result.ref_fee_amount,
        },
    )
}

/// Internal function for flash loan
/// * `config` - The global config object.
/// * `pool` - The clmm pool object.
/// * `partner_id` - The partner object id for receiving ref fee.
/// * `ref_fee_rate` - The ref fee rate for partner.
/// * `loan_a` - A flag indicating whether to loan coin A (true) or coin B (false).
/// * `amount` - The amount to loan.
/// * Returns (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt)
fun flash_loan_internal<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    partner_id: ID,
    ref_fee_rate: u64,
    loan_a: bool,
    amount: u64,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashLoanReceipt) {
    assert!(amount > 0, EAmountIncorrect);
    let (vault_a_amount, vault_b_amount) = (
        balance::value<CoinTypeA>(&pool.coin_a),
        balance::value<CoinTypeB>(
            &pool.coin_b,
        ),
    );
    if (loan_a) {
        assert!(balance::value(&pool.coin_a) >= amount, EAmountIncorrect);
    } else {
        assert!(balance::value(&pool.coin_b) >= amount, EAmountIncorrect);
    };

    let fee_rate = pool.fee_rate;
    let fee_amount = full_math_u64::mul_div_ceil(
        amount,
        fee_rate,
        clmm_math::fee_rate_denominator(),
    );
    let protocol_fee_amount = update_flash_loan_fee(
        pool,
        fee_amount,
        config::protocol_fee_rate(config),
        loan_a,
    );

    let ref_fee_amount = if (ref_fee_rate != 0) {
        full_math_u64::mul_div_floor(protocol_fee_amount, ref_fee_rate, PROTOCOL_FEE_DENOMINATOR)
    } else {
        0
    };
    let receipt = FlashLoanReceipt {
        pool_id: object::id(pool),
        loan_a,
        amount,
        fee_amount,
        partner_id,
        ref_fee_amount,
    };

    event::emit(FlashLoanEvent {
        pool: object::id(pool),
        partner: partner_id,
        loan_a,
        amount,
        fee_amount,
        ref_amount: ref_fee_amount,
        vault_a_amount,
        vault_b_amount,
    });
    if (loan_a) {
        pool.fee_protocol_coin_a =
            pool.fee_protocol_coin_a + (protocol_fee_amount - ref_fee_amount);
        (balance::split(&mut pool.coin_a, amount), balance::zero(), receipt)
    } else {
        pool.fee_protocol_coin_b =
            pool.fee_protocol_coin_b + (protocol_fee_amount - ref_fee_amount);
        (balance::zero(), balance::split(&mut pool.coin_b, amount), receipt)
    }
}

/// Swap in pool
/// * `pool` - The clmm pool object.
/// * `a2b` - The swap direction.
/// * `by_amount_in` - A flag used to determine whether next arg `amount` represents input or output.
/// * `sqrt_price_limit` - The sqrt price limit.
/// * `amount` - The amount to swap.
/// * `protocol_fee_rate` - The protocol fee rate.
/// * `ref_fee_rate` - The ref fee rate.
/// * Returns SwapResult
fun swap_in_pool<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    a2b: bool,
    by_amount_in: bool,
    sqrt_price_limit: u128,
    amount: u64,
    protocol_fee_rate: u64,
    ref_fee_rate: u64,
): SwapResult {
    assert!(ref_fee_rate <= PROTOCOL_FEE_DENOMINATOR, EInvalidPartnerRefFeeRate);
    let mut swap_result = default_swap_result();
    let mut remainer_amount = amount;
    let mut opt_next_tick_score = tick::first_score_for_swap(
        &pool.tick_manager,
        pool.current_tick_index,
        a2b,
    );
    let (points_growth_global, reward_growth_globals) = (
        rewarder::points_growth_global(&pool.rewarder_manager),
        rewarder::rewards_growth_global(&pool.rewarder_manager),
    );
    let mut protocol_fee_amount = 0;
    while (remainer_amount > 0 && pool.current_sqrt_price != sqrt_price_limit) {
        if (option_u64::is_none(&opt_next_tick_score)) {
            abort ENotEnoughLiquidity
        };
        let (next_tick, opt_next) = tick::borrow_tick_for_swap(
            &pool.tick_manager,
            option_u64::borrow(&opt_next_tick_score),
            a2b,
        );
        opt_next_tick_score = opt_next;
        let (next_tick_index, next_tick_sqrt_price) = (
            tick::index(next_tick),
            tick::sqrt_price(next_tick),
        );

        let target_sqrt_price = if (a2b) {
            math_u128::max(sqrt_price_limit, next_tick_sqrt_price)
        } else {
            math_u128::min(sqrt_price_limit, next_tick_sqrt_price)
        };
        let (amount_in, amount_out, next_sqrt_price, fee_amount) = clmm_math::compute_swap_step(
            pool.current_sqrt_price,
            target_sqrt_price,
            pool.liquidity,
            remainer_amount,
            pool.fee_rate,
            a2b,
            by_amount_in,
        );
        if (amount_in != 0 || fee_amount != 0) {
            if (by_amount_in) {
                remainer_amount = check_remainer_amount_sub(remainer_amount, amount_in);
                remainer_amount = check_remainer_amount_sub(remainer_amount, fee_amount);
            } else {
                remainer_amount = check_remainer_amount_sub(remainer_amount, amount_out);
            };

            // Update the swap result by step result
            update_swap_result(&mut swap_result, amount_in, amount_out, fee_amount);

            // Update the pool's fee growth global and return protocol fee by step result
            protocol_fee_amount =
                protocol_fee_amount + update_pool_fee(pool, fee_amount, protocol_fee_rate, a2b);
        };

        if (next_sqrt_price == next_tick_sqrt_price) {
            pool.current_sqrt_price = target_sqrt_price;
            pool.current_tick_index = if (a2b) {
                i32::sub(next_tick_index, i32::from(1))
            } else {
                next_tick_index
            };

            // tick cross, update pool's liqudity and ticks's fee_growth_outside_[ab]
            let after_liquidity = tick::cross_by_swap(
                &mut pool.tick_manager,
                next_tick_index,
                a2b,
                pool.liquidity,
                pool.fee_growth_global_a,
                pool.fee_growth_global_b,
                points_growth_global,
                reward_growth_globals,
            );
            pool.liquidity = after_liquidity;
        } else if (pool.current_sqrt_price != next_sqrt_price) {
            pool.current_sqrt_price = next_sqrt_price;
            pool.current_tick_index = tick_math::get_tick_at_sqrt_price(next_sqrt_price);
        };
    };
    if (
        i32::lt(pool.current_tick_index, tick_math::min_tick()) || i32::gte(pool.current_tick_index, tick_math::max_tick())
    ) {
        abort EPoolCurrentTickIndexOutOfRange
    };
    swap_result.ref_fee_amount =
        full_math_u64::mul_div_floor(protocol_fee_amount, ref_fee_rate, PROTOCOL_FEE_DENOMINATOR);
    if (a2b) {
        assert!(
            math_u64::add_check(
                pool.fee_protocol_coin_a,
                protocol_fee_amount - swap_result.ref_fee_amount,
            ),
            EFeeAmountOverflow,
        );
        pool.fee_protocol_coin_a =
            pool.fee_protocol_coin_a + (protocol_fee_amount - swap_result.ref_fee_amount);
    } else {
        assert!(
            math_u64::add_check(
                pool.fee_protocol_coin_b,
                protocol_fee_amount - swap_result.ref_fee_amount,
            ),
            EFeeAmountOverflow,
        );
        pool.fee_protocol_coin_b =
            pool.fee_protocol_coin_b + (protocol_fee_amount - swap_result.ref_fee_amount);
    };

    swap_result
}

/// Update the swap result
/// * `result` - The swap result.
/// * `amount_in` - The amount in.
/// * `amount_out` - The amount out.
/// * `fee_amount` - The fee amount.
fun update_swap_result(result: &mut SwapResult, amount_in: u64, amount_out: u64, fee_amount: u64) {
    assert!(math_u64::add_check(result.amount_in, amount_in), ESwapAmountInOverflow);
    assert!(math_u64::add_check(result.amount_out, amount_out), ESwapAmountOutOverflow);
    assert!(math_u64::add_check(result.fee_amount, fee_amount), EFeeAmountOverflow);
    result.amount_in = result.amount_in + amount_in;
    result.amount_out = result.amount_out + amount_out;
    result.fee_amount = result.fee_amount + fee_amount;
    result.steps = result.steps + 1;
}

/// Update the pool's fee_growth_global_[a/b] and return protocol_fee.
/// * `pool` - The clmm pool object.
/// * `fee_amount` - The fee amount.
/// * `protocol_fee_rate` - The protocol fee rate.
/// * `a2b` - The swap direction.
/// * Returns u64
fun update_pool_fee<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    fee_amount: u64,
    protocol_fee_rate: u64,
    a2b: bool,
): u64 {
    update_fee_growth(pool, fee_amount, protocol_fee_rate, a2b)
}

/// Update the flash loan fee
/// * `pool` - The clmm pool object.
/// * `fee_amount` - The fee amount.
/// * `protocol_fee_rate` - The protocol fee rate.
/// * `loan_a` - A flag indicating whether to loan coin A (true) or coin B (false).
/// * Returns u64
fun update_flash_loan_fee<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    fee_amount: u64,
    protocol_fee_rate: u64,
    loan_a: bool,
): u64 {
    update_fee_growth(pool, fee_amount, protocol_fee_rate, loan_a)
}

/// Update the fee growth, internal function
/// * `pool` - The clmm pool object.
/// * `fee_amount` - The fee amount.
/// * `protocol_fee_rate` - The protocol fee rate.
/// * `is_coin_a` - A flag indicating whether to update coin A (true) or coin B (false).
/// * Returns u64
fun update_fee_growth<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    fee_amount: u64,
    protocol_fee_rate: u64,
    is_coin_a: bool,
): u64 {
    let protocol_fee = full_math_u64::mul_div_ceil(
        fee_amount,
        protocol_fee_rate,
        PROTOCOL_FEE_DENOMINATOR,
    );
    let liquidity_fee = fee_amount - protocol_fee;
    if (liquidity_fee == 0 || pool.liquidity == 0) {
        return protocol_fee
    };
    let growth_fee = ((liquidity_fee as u128) << 64) / pool.liquidity;
    if (is_coin_a) {
        pool.fee_growth_global_a = math_u128::wrapping_add(pool.fee_growth_global_a, growth_fee);
    } else {
        pool.fee_growth_global_b = math_u128::wrapping_add(pool.fee_growth_global_b, growth_fee);
    };
    protocol_fee
}

/// Collect protocol fee internal
/// * `pool` - The clmm pool object.
/// * Returns the balance object of CoinTypeA and CoinTypeB.
fun collect_protocol_fee_internal<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
): (Balance<CoinTypeA>, Balance<CoinTypeB>) {
    let amount_a = pool.fee_protocol_coin_a;
    let amount_b = pool.fee_protocol_coin_b;
    assert!(amount_a > 0 || amount_b > 0, ENoProtocolFee);
    assert!(
        pool.coin_a.value() >= amount_a && pool.coin_b.value() >= amount_b,
        EProtocolFeeNotEnough,
    );
    let balance_a = balance::split<CoinTypeA>(&mut pool.coin_a, amount_a);
    let balance_b = balance::split<CoinTypeB>(&mut pool.coin_b, amount_b);
    pool.fee_protocol_coin_a = 0;
    pool.fee_protocol_coin_b = 0;
    event::emit(CollectProtocolFeeEvent {
        pool: object::id(pool),
        amount_a,
        amount_b,
    });
    (balance_a, balance_b)
}

fun mark_pending_add_liquidity<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>) {
    let key = PENDING_ADD_LIQUIDITY_KEY;
    if (!dynamic_field::exists_(&pool.id, key)) {
        dynamic_field::add(&mut pool.id, key, 1u64);
    } else {
        let count = dynamic_field::borrow_mut(&mut pool.id, key);
        *count = *count + 1;
    }
}

fun clear_pending_add_liquidity<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>) {
    let key = PENDING_ADD_LIQUIDITY_KEY;
    let count = dynamic_field::borrow_mut(&mut pool.id, key);
    *count = *count - 1;
    if (*count == 0u64) {
        dynamic_field::remove<vector<u8>, u64>(&mut pool.id, key);
    }
}

fun assert_no_pending_add_liquidity<CoinTypeA, CoinTypeB>(pool: &Pool<CoinTypeA, CoinTypeB>){
    let key = PENDING_ADD_LIQUIDITY_KEY;
    assert!(!dynamic_field::exists_<vector<u8>>(&pool.id, key), EPositionPendingAddLiquidity);
}

/// Check the remainer amount sub
/// * `remainer_amount` - The remainer amount.
/// * `amount` - The amount.
/// * Returns u64
fun check_remainer_amount_sub(remainer_amount: u64, amount: u64): u64 {
    assert!(remainer_amount >= amount, ERemainderAmountUnderflow);
    remainer_amount - amount
}

/// Get the default swap result
/// * Returns SwapResult
fun default_swap_result(): SwapResult {
    SwapResult {
        amount_in: 0,
        amount_out: 0,
        fee_amount: 0,
        ref_fee_amount: 0,
        steps: 0,
    }
}

#[test_only]
public fun amount_in(result: &SwapResult): u64 {
    result.amount_in
}

#[test_only]
public fun amount_out(result: &SwapResult): u64 {
    result.amount_out
}

#[test_only]
public fun fee_amount(result: &SwapResult): u64 {
    result.fee_amount
}

#[test_only]
public fun ref_amount(result: &SwapResult): u64 {
    result.ref_fee_amount
}

#[test_only]
public fun steps(result: &SwapResult): u64 {
    result.steps
}

#[test_only]
public fun new_for_test<CoinTypeA, CoinTypeB>(
    tick_spacing: u32,
    init_sqrt_price: u128,
    fee_rate: u64,
    uri: String,
    index: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Pool<CoinTypeA, CoinTypeB> {
    new<CoinTypeA, CoinTypeB>(
        tick_spacing,
        init_sqrt_price,
        fee_rate,
        uri,
        index,
        clock,
        ctx,
    )
}

#[test_only]
public fun new_pool_custom<CoinTypeA, CoinTypeB>(
    tick_spacing: u32,
    init_sqrt_price: u128,
    fee_rate: u64,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    fee_protocol_coin_a: u64,
    fee_protocol_coin_b: u64,
    liquidity: u128,
    balance_a: u64,
    balance_b: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): Pool<CoinTypeA, CoinTypeB> {
    Pool {
        id: object::new(ctx),
        coin_a: balance::create_for_testing<CoinTypeA>(balance_a),
        coin_b: balance::create_for_testing<CoinTypeB>(balance_b),
        tick_spacing,
        fee_rate,
        liquidity,
        current_sqrt_price: init_sqrt_price,
        current_tick_index: tick_math::get_tick_at_sqrt_price(init_sqrt_price),
        fee_growth_global_a,
        fee_growth_global_b,
        fee_protocol_coin_a,
        fee_protocol_coin_b,
        tick_manager: tick::new(tick_spacing, clock::timestamp_ms(clock), ctx),
        rewarder_manager: rewarder::new(),
        position_manager: position::new(tick_spacing, ctx),
        is_pause: false,
        index: 0,
        url: string::utf8(b""),
    }
}

#[test_only]
public fun new_pool_for_position_snapshot_test<CoinTypeA, CoinTypeB>(
    config: &GlobalConfig,
    tick_spacing: u32,
    init_sqrt_price: u128,
    fee_rate: u64,
    uri: String,
    index: u64,
    clock: &Clock,
    ctx: &mut TxContext,
): (Pool<CoinTypeA, CoinTypeB>, Position) {
    let mut pool = new<CoinTypeA, CoinTypeB>(
        tick_spacing,
        init_sqrt_price,
        fee_rate,
        uri,
        index,
        clock,
        ctx,
    );
    let pool_id = object::id(&pool);
    let position = position::open_position<CoinTypeA, CoinTypeB>(
        &mut pool.position_manager,
        pool_id,
        0,
        std::string::utf8(b"test"),
        i32::from_u32(0),
        i32::from_u32(100),
        ctx,
    );
    pool.is_pause = true;
    init_position_snapshot(config, &mut pool, 100, ctx);
    apply_liquidity_cut(config, &mut pool, object::id(&position), 10000, clock, ctx);
    (pool, position)
}

#[test_only]
use cetus_clmm::rewarder::Rewarder;
#[test_only]
use sui::coin;

#[test_only]
public fun update_pool_fee_rate<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    fee_rate: u64,
) {
    pool.fee_rate = fee_rate;
}

#[test_only]
public fun update_protocol_fee<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    fee_protocol_coin_a: u64,
    fee_protocol_coin_b: u64,
) {
    pool.coin_a.join(balance::create_for_testing<CoinTypeA>(fee_protocol_coin_a));
    pool.coin_b.join(balance::create_for_testing<CoinTypeB>(fee_protocol_coin_b));
    pool.fee_protocol_coin_a = fee_protocol_coin_a;
    pool.fee_protocol_coin_b = fee_protocol_coin_b;
}

#[test_only]
public fun pause_pool<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>) {
    pool.is_pause = true;
}

#[test_only]
public fun unpause_pool<CoinTypeA, CoinTypeB>(pool: &mut Pool<CoinTypeA, CoinTypeB>) {
    pool.is_pause = false;
}

#[test_only]
public fun update_pool_balance<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    ctx: &mut TxContext,
) {
    let amount_a = balance::value(&pool.coin_a);
    let amount_b = balance::value(&pool.coin_b);
    let a = balance::split(&mut pool.coin_a, amount_a);
    let b = balance::split(&mut pool.coin_b, amount_b);
    transfer::public_transfer(coin::from_balance(a, ctx), @0x1);
    transfer::public_transfer(coin::from_balance(b, ctx), @0x1);
}

#[test_only]
public fun update_for_swap_test<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    balance_a: u64,
    balance_b: u64,
    current_liquidity: u128,
    current_sqrt_price: u128,
    current_tick_index: I32,
    fee_growth_global_a: u128,
    fee_growth_global_b: u128,
    fee_protocol_coin_a: u64,
    fee_protocol_coin_b: u64,
    ticks: vector<Tick>,
    rewarders: vector<Rewarder>,
    points_released: u128,
    points_growth_global: u128,
    last_updated_time: u64,
) {
    balance::join(&mut pool.coin_a, balance::create_for_testing<CoinTypeA>(balance_a));
    balance::join(&mut pool.coin_b, balance::create_for_testing<CoinTypeB>(balance_b));

    pool.liquidity = current_liquidity;
    pool.current_sqrt_price = current_sqrt_price;
    pool.current_tick_index = current_tick_index;
    pool.fee_growth_global_a = fee_growth_global_a;
    pool.fee_growth_global_b = fee_growth_global_b;
    pool.fee_protocol_coin_a = fee_protocol_coin_a;
    pool.fee_protocol_coin_b = fee_protocol_coin_b;

    tick::add_ticks_for_test(&mut pool.tick_manager, ticks);

    rewarder::update_for_swap_test(
        &mut pool.rewarder_manager,
        rewarders,
        points_released,
        points_growth_global,
        last_updated_time,
    );
}

#[test_only]
public fun add_liquidity_internal_test<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    position_nft: &mut Position,
    by_amount: bool,
    liquidity: u128,
    amount: u64,
    fix_amount_a: bool,
    timestamp: u64,
): AddLiquidityReceipt<CoinTypeA, CoinTypeB> {
    add_liquidity_internal(
        pool,
        position_nft,
        by_amount,
        liquidity,
        amount,
        fix_amount_a,
        timestamp,
    )
}

#[test_only]
public fun update_liquidity<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    liquidity: u128,
) {
    pool.liquidity = liquidity;
}

#[test_only]
public fun update_pool_fee_test<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    fee_amount: u64,
    protocol_fee_rate: u64,
    a2b: bool,
): u64 {
    update_pool_fee(pool, fee_amount, protocol_fee_rate, a2b)
}

#[test_only]
public fun mut_tick_manager<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
): &mut TickManager {
    &mut pool.tick_manager
}

#[test_only]
public fun new_pool_with_ticks<CoinTypeA, CoinTypeB>(
    clk: &Clock,
    ctx: &mut TxContext,
): Pool<CoinTypeA, CoinTypeB> {
    let mut pool = Pool<CoinTypeA, CoinTypeB> {
        id: object::new(ctx),
        coin_a: balance::create_for_testing<CoinTypeA>(533921553807),
        coin_b: balance::create_for_testing<CoinTypeB>(4701968956),
        tick_spacing: 60,
        fee_rate: 2500,
        liquidity: 50214615874,
        current_sqrt_price: 1715006487636306234,
        current_tick_index: tick_math::get_tick_at_sqrt_price(1715006487636306234),
        fee_growth_global_a: 0,
        fee_growth_global_b: 0,
        fee_protocol_coin_a: 110257286,
        fee_protocol_coin_b: 791874,
        tick_manager: tick::new(60, clock::timestamp_ms(clk), ctx),
        rewarder_manager: rewarder::new(),
        position_manager: position::new(60, ctx),
        is_pause: false,
        index: 0,
        url: string::utf8(b""),
    };

    let tick_manager = &mut pool.tick_manager;
    tick::insert_tick(
        tick_manager,
        i32::neg_from(56340),
        1102994465472052299,
        i128::from(50000000001),
        50000000001,
        0,
        0,
        0,
        vector[],
    );
    tick::insert_tick(
        tick_manager,
        i32::neg_from(55140),
        1171196320715478783,
        i128::from(27300932),
        27300932,
        143267228134630813,
        1027858884105033,
        445998234215864138263,
        vector[],
    );
    tick::insert_tick(
        tick_manager,
        i32::neg_from(54540),
        1206862748656139047,
        i128::from(187314941),
        187314941,
        52224278677715496,
        219224795916387,
        137418651039469457519,
        vector[],
    );
    tick::insert_tick(
        tick_manager,
        i32::neg_from(41880),
        2272754597651468243,
        i128::neg_from(214615873),
        214615873,
        0,
        0,
        0,
        vector[],
    );
    tick::insert_tick(
        tick_manager,
        i32::from(56340),
        308507773677093347289,
        i128::neg_from(50000000001),
        50000000001,
        0,
        0,
        0,
        vector[],
    );
    pool
}

#[test_only]
public fun swap_in_pool_test<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    a2b: bool,
    by_amount_in: bool,
    sqrt_price_limit: u128,
    amount: u64,
    protocol_fee_rate: u64,
    ref_fee_rate: u64,
): SwapResult {
    swap_in_pool(pool, a2b, by_amount_in, sqrt_price_limit, amount, protocol_fee_rate, ref_fee_rate)
}

#[test_only]
public fun flash_swap_internal_test<CoinTypeA, CoinTypeB>(
    pool: &mut Pool<CoinTypeA, CoinTypeB>,
    config: &GlobalConfig,
    partner_id: ID,
    ref_fee_rate: u64,
    a2b: bool,
    by_amount_in: bool,
    amount: u64,
    sqrt_price_limit: u128,
    clock: &Clock,
): (Balance<CoinTypeA>, Balance<CoinTypeB>, FlashSwapReceipt<CoinTypeA, CoinTypeB>) {
    flash_swap_internal(
        pool,
        config,
        partner_id,
        ref_fee_rate,
        a2b,
        by_amount_in,
        amount,
        sqrt_price_limit,
        clock,
    )
}

#[test]
fun test_init() {
    let mut sc = sui::test_scenario::begin(@0x23);
    init(sui::test_utils::create_one_time_witness(), sc.ctx());
    sc.next_tx(@0x23);
    let publisher = sui::test_scenario::take_from_address<sui::package::Publisher>(&sc, @0x23);
    sui::test_scenario::return_to_address(@0x23, publisher);
    sc.end();
}

#[test_only]
public struct CETUS has drop {}

#[test]
fun test_set_display() {
    let mut sc = sui::test_scenario::begin(@0x23);
    init(sui::test_utils::create_one_time_witness(), sc.ctx());
    sc.next_tx(@0x23);
    let publisher = sui::test_scenario::take_from_address<sui::package::Publisher>(&sc, @0x23);
    let (admin_cap, config) = cetus_clmm::config::new_global_config_for_test(sc.ctx(), 1000);
    set_display<CETUS, 0x2::sui::SUI>(
        &config,
        &publisher,
        std::string::utf8(b"name"),
        std::string::utf8(b"description"),
        std::string::utf8(b"image"),
        std::string::utf8(b"link"),
        std::string::utf8(b"website"),
        std::string::utf8(b"creator"),
        sc.ctx(),
    );
    sui::transfer::public_transfer(admin_cap, sc.ctx().sender());
    sui::transfer::public_share_object(config);
    sui::test_scenario::return_to_address(@0x23, publisher);
    sc.end();
}

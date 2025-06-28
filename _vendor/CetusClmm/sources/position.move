// Copyright (c) Cetus Technology Limited

#[allow(unused_type_parameter, unused_field)]
/// The `position` module is designed for the convenience of the `Pool`'s position and all `position` related
/// operations are completed by this module. Regarding the `position` of `clmmpool`,
/// there are several points that need to be explained:
///
/// 1. `clmmpool` specifies the ownership of the `position` through an `Object` named `position_nft`,
/// rather than a wallet address. This means that whoever owns the `position_nft` owns the position it holds.
/// This also means that `clmmpool`'s `position` can be transferred between users freely.
/// 2. `position_nft` records some basic information about the position, but these data do not participate in the
/// related calculations of the position, they are only used for display. The data that actually participates in the
/// calculation is stored in `position_info`, which corresponds one-to-one with `position_nft` and is stored in
/// `PositionManager`. The reason for this design is that in our other contracts, we need to read the information of
/// multiple positions in the `Pool`.
module cetusclmm::position {
    use std::string::String;
    use std::type_name::TypeName;

    use sui::package::{Publisher};
    use sui::object::{UID, ID};
    use sui::tx_context::TxContext;

    use integer_mate::i32::{I32};

    use move_stl::linked_table;

    use cetusclmm::config::{GlobalConfig};
    
    /// The Cetus clmmpool's position manager, which has only store ability.
    /// The `PositionInfo` is organized into a linked table.
    struct PositionManager has store {
        tick_spacing: u32,
        position_index: u64,
        positions: linked_table::LinkedTable<ID, PositionInfo>
    }

    struct POSITION has drop {}

    
    /// The Cetus clmmpool's position NFT.
    struct Position has key, store {
        id: UID,
        pool: ID,
        index: u64,
        coin_type_a: TypeName,
        coin_type_b: TypeName,
        name: String,
        description: String,
        url: String,
        tick_lower_index: I32,
        tick_upper_index: I32,
        liquidity: u128,
    }

    
    /// The Cetus clmmpool's position information.
    struct PositionInfo has store, drop, copy {
        position_id: ID,
        liquidity: u128,
        tick_lower_index: I32,
        tick_upper_index: I32,
        fee_growth_inside_a: u128,
        fee_growth_inside_b: u128,
        fee_owned_a: u64,
        fee_owned_b: u64,
        points_owned: u128,
        points_growth_inside: u128,
        rewards: vector<PositionReward>,
    }

    
    /// The Position's rewarder
    struct PositionReward has drop, copy, store {
        growth_inside: u128,
        amount_owned: u64,
    }

    fun init(_otw: POSITION, _ctx: &mut TxContext) {
        abort 0
    }

    /// Set `Display` for the position NFT.
    public fun set_display(
        _config: &GlobalConfig,
        _publisher: &Publisher,
        _description: String,
        _link: String,
        _website: String,
        _creator: String,
        _ctx: &mut TxContext
    ) {
        abort 0
    }

    /// New `PositionManager`
    public(friend) fun new(
        _tick_spacing: u32,
        _ctx: &mut TxContext
    ): PositionManager {
        abort 0
    }

    /// the inited reward count in `PositionInfo`.
    public fun inited_rewards_count(_manager: &PositionManager, _position_id: ID): u64 {
        abort 0
    }

    /// Fetch `PositionInfo` List.
    /// Params
    ///     - manager: PositionManager
    ///     - start: start position id
    ///     - limit: max count of `PositionInfo` to fetch
    public fun fetch_positions(
        _manager: &PositionManager, _start: vector<ID>, _limit: u64
    ): vector<PositionInfo> {
        abort 0
    }

    /// Get the pool_id of a position.
    public fun pool_id(_position_nft: &Position): ID {
        abort 0
    }

    /// Get the tick range tuple of position.
    public fun tick_range(_position_nft: &Position): (I32, I32) {
        abort 0
    }

    /// Get the index of position.
    public fun index(_position_nft: &Position): u64 {
        abort 0
    }

    /// Get the name of position.
    public fun name(_position_nft: &Position): String {
        abort 0
    }

    /// Get the description of position.
    public fun description(_position_nft: &Position): String {
        abort 0
    }

    /// Get the url of position.
    public fun url(_position_nft: &Position): String {
        abort 0
    }

    /// Get the liquidity of position.
    public fun liquidity(_position_nft: &Position): u128 {
        abort 0
    }

    /// Get the position_id of `PositionInfo`.
    public fun info_position_id(_info: &PositionInfo): ID {
        abort 0
    }

    /// Get the liquidity of `PositionInfo`.
    public fun info_liquidity(_info: &PositionInfo): u128 {
        abort 0
    }

    /// Get the tick range tuple of `PositionInfo`.
    public fun info_tick_range(_info: &PositionInfo): (I32, I32) {
        abort 0
    }

    /// Get the fee_growth_inside tuple of `PositionInfo`.
    public fun info_fee_growth_inside(_info: &PositionInfo): (u128, u128) {
        abort 0
    }

    /// Get the fee_owned tuple of `PositionInfo`.
    public fun info_fee_owned(_info: &PositionInfo): (u64, u64) {
        abort 0
    }

    /// Get the points_owned of `PositionInfo`.
    public fun info_points_owned(_info: &PositionInfo): u128 {
        abort 0
    }

    /// Get the points_growth_inside of `PositionInfo`.
    public fun info_points_growth_inside(_info: &PositionInfo): u128 {
        abort 0
    }

    /// Get the rewards of `PositionInfo`.
    public fun info_rewards(_info: &PositionInfo): &vector<PositionReward> {
        abort 0
    }

    /// Returns the reward growth by `PositionReward`.
    public fun reward_growth_inside(_reward: &PositionReward): u128 {
        abort 0
    }

    /// Returns the reward owned by `PositionReward`.
    public fun reward_amount_owned(_reward: &PositionReward): u64 {
        abort 0
    }

    /// Returns the amount of rewards owned by the position.
    public(friend) fun rewards_amount_owned(
        _manager: &PositionManager,
        _postion_id: ID,
    ): vector<u64> {
        abort 0
    }

    /// Borrow `PositionInfo` by position_id.
    public fun borrow_position_info(
        _manager: &PositionManager,
        _position_id: ID,
    ): &PositionInfo {
        abort 0
    }

    /// Check if a position is empty
    /// 1. liquidity == 0
    /// 2. fee_owned_a == 0
    /// 3. fee_owned_b == 0
    /// 4. [reward.amount_owned == 0 for reward in position_info.rewards]
    public fun is_empty(_position_info: &PositionInfo): bool {
        abort 0
    }

    /// Check if a position tick range is valid.
    /// 1. lower < upper
    /// 2. (lower >= min_tick) && (upper <= max_tick)
    /// 3. (lower % tick_spacing == 0) && (upper % tick_spacing == 0)
    public fun check_position_tick_range(_lower: I32, _upper: I32, _tick_spacing: u32) {
        abort 0
    }

    /// check if the position exists in `PositionManager` by position_id.
    public fun is_position_exist(_manager: &PositionManager, _position_id: ID): bool {
        abort 0
    }
}

module 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool {

    use 0x1::type_name;
    use sui::balance;
    use sui::clock;
    use sui::object;
    use sui::table;
    use sui::tx_context;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::admin_cap;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i128;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i32;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::i64;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::oracle;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::pool_manager;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::position;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::tick;
    use 0x25929E7F29E0A30EB4E692952BA1B5B65A3A4D65AB5F2A32E1BA3EDCB587F26D::versioned;

    friend pool_manager;

    struct PoolRewardCustodianDfKey<phantom T0> has copy, drop, store {
        dummy_field: bool,
    }
    struct Pool<phantom T0, phantom T1> has store, key {
        id: object::UID,
        coin_type_x: type_name::TypeName,
        coin_type_y: type_name::TypeName,
        sqrt_price: u128,
        tick_index: i32::I32,
        observation_index: u64,
        observation_cardinality: u64,
        observation_cardinality_next: u64,
        tick_spacing: u32,
        max_liquidity_per_tick: u128,
        protocol_fee_rate: u64,
        swap_fee_rate: u64,
        fee_growth_global_x: u128,
        fee_growth_global_y: u128,
        protocol_fee_x: u64,
        protocol_fee_y: u64,
        liquidity: u128,
        ticks: table::Table<i32::I32, tick::TickInfo>,
        tick_bitmap: table::Table<i32::I32, u256>,
        observations: vector<oracle::Observation>,
        locked: bool,
        reward_infos: vector<pool::PoolRewardInfo>,
        reserve_x: balance::Balance<T0>,
        reserve_y: balance::Balance<T1>,
    }
    struct PoolRewardInfo has copy, drop, store {
        reward_coin_type: type_name::TypeName,
        last_update_time: u64,
        ended_at_seconds: u64,
        total_reward: u64,
        total_reward_allocated: u64,
        reward_per_seconds: u128,
        reward_growth_global: u128,
    }
    struct SwapState has copy, drop {
        amount_specified_remaining: u64,
        amount_calculated: u64,
        sqrt_price: u128,
        tick_index: i32::I32,
        fee_growth_global: u128,
        protocol_fee: u64,
        liquidity: u128,
        fee_amount: u64,
    }
    struct SwapStepComputations has copy, drop {
        sqrt_price_start: u128,
        tick_index_next: i32::I32,
        initialized: bool,
        sqrt_price_next: u128,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
    }
    struct SwapReceipt {
        pool_id: object::ID,
        amount_x_debt: u64,
        amount_y_debt: u64,
    }
    struct FlashReceipt {
        pool_id: object::ID,
        amount_x: u64,
        amount_y: u64,
        fee_x: u64,
        fee_y: u64,
    }
    struct ModifyLiquidity has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        position_id: object::ID,
        tick_lower_index: i32::I32,
        tick_upper_index: i32::I32,
        liquidity_delta: i128::I128,
        amount_x: u64,
        amount_y: u64,
    }
    struct Swap has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        x_for_y: bool,
        amount_x: u64,
        amount_y: u64,
        sqrt_price_before: u128,
        sqrt_price_after: u128,
        liquidity: u128,
        tick_index: i32::I32,
        fee_amount: u64,
    }
    struct Flash has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        amount_x: u64,
        amount_y: u64,
    }
    struct Pay has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        amount_x_debt: u64,
        amount_y_debt: u64,
        paid_x: u64,
        paid_y: u64,
    }
    struct Collect has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        position_id: object::ID,
        amount_x: u64,
        amount_y: u64,
    }
    struct CollectProtocolFee has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        amount_x: u64,
        amount_y: u64,
    }
    struct SetProtocolFeeRate has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        protocol_fee_rate_x_old: u64,
        protocol_fee_rate_y_old: u64,
        protocol_fee_rate_x_new: u64,
        protocol_fee_rate_y_new: u64,
    }
    struct Initialize has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        sqrt_price: u128,
        tick_index: i32::I32,
    }
    struct IncreaseObservationCardinalityNext has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        observation_cardinality_next_old: u64,
        observation_cardinality_next_new: u64,
    }
    struct InitializePoolReward has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        reward_coin_type: type_name::TypeName,
        started_at_seconds: u64,
    }
    struct UpdatePoolRewardEmission has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        reward_coin_type: type_name::TypeName,
        total_reward: u64,
        ended_at_seconds: u64,
        reward_per_seconds: u128,
    }
    struct CollectPoolReward has copy, drop, store {
        sender: address,
        pool_id: object::ID,
        position_id: object::ID,
        reward_coin_type: type_name::TypeName,
        amount: u64,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun pool_id<T0, T1>(a0: &pool::Pool<T0, T1>): object::ID;
 #[native_interface]
    native public fun coin_type_x<T0, T1>(a0: &pool::Pool<T0, T1>): type_name::TypeName;
 #[native_interface]
    native public fun coin_type_y<T0, T1>(a0: &pool::Pool<T0, T1>): type_name::TypeName;
 #[native_interface]
    native public fun sqrt_price_current<T0, T1>(a0: &pool::Pool<T0, T1>): u128;
 #[native_interface]
    native public fun tick_index_current<T0, T1>(a0: &pool::Pool<T0, T1>): i32::I32;
 #[native_interface]
    native public fun observation_index<T0, T1>(a0: &pool::Pool<T0, T1>): u64;
 #[native_interface]
    native public fun observation_cardinality<T0, T1>(a0: &pool::Pool<T0, T1>): u64;
 #[native_interface]
    native public fun observation_cardinality_next<T0, T1>(a0: &pool::Pool<T0, T1>): u64;
 #[native_interface]
    native public fun tick_spacing<T0, T1>(a0: &pool::Pool<T0, T1>): u32;
 #[native_interface]
    native public fun max_liquidity_per_tick<T0, T1>(a0: &pool::Pool<T0, T1>): u128;
 #[native_interface]
    native public fun protocol_fee_rate<T0, T1>(a0: &pool::Pool<T0, T1>): u64;
 #[native_interface]
    native public fun swap_fee_rate<T0, T1>(a0: &pool::Pool<T0, T1>): u64;
 #[native_interface]
    native public fun fee_growth_global_x<T0, T1>(a0: &pool::Pool<T0, T1>): u128;
 #[native_interface]
    native public fun fee_growth_global_y<T0, T1>(a0: &pool::Pool<T0, T1>): u128;
 #[native_interface]
    native public fun protocol_fee_x<T0, T1>(a0: &pool::Pool<T0, T1>): u64;
 #[native_interface]
    native public fun protocol_fee_y<T0, T1>(a0: &pool::Pool<T0, T1>): u64;
 #[native_interface]
    native public fun liquidity<T0, T1>(a0: &pool::Pool<T0, T1>): u128;
 #[native_interface]
    native public fun borrow_ticks<T0, T1>(a0: &pool::Pool<T0, T1>): &table::Table<i32::I32, tick::TickInfo>;
 #[native_interface]
    native public fun borrow_tick_bitmap<T0, T1>(a0: &pool::Pool<T0, T1>): &table::Table<i32::I32, u256>;
 #[native_interface]
    native public fun borrow_observations<T0, T1>(a0: &pool::Pool<T0, T1>): &vector<oracle::Observation>;
 #[native_interface]
    native public fun is_locked<T0, T1>(a0: &pool::Pool<T0, T1>): bool;
 #[native_interface]
    native public fun reward_length<T0, T1>(a0: &pool::Pool<T0, T1>): u64;
 #[native_interface]
    native public fun reward_info_at<T0, T1>(a0: &pool::Pool<T0, T1>, a1: u64): &pool::PoolRewardInfo;
 #[native_interface]
    native public fun reward_coin_type<T0, T1>(a0: &pool::Pool<T0, T1>, a1: u64): type_name::TypeName;
 #[native_interface]
    native public fun reward_last_update_at<T0, T1>(a0: &pool::Pool<T0, T1>, a1: u64): u64;
 #[native_interface]
    native public fun reward_ended_at<T0, T1>(a0: &pool::Pool<T0, T1>, a1: u64): u64;
 #[native_interface]
    native public fun total_reward<T0, T1>(a0: &pool::Pool<T0, T1>, a1: u64): u64;
 #[native_interface]
    native public fun total_reward_allocated<T0, T1>(a0: &pool::Pool<T0, T1>, a1: u64): u64;
 #[native_interface]
    native public fun reward_per_seconds<T0, T1>(a0: &pool::Pool<T0, T1>, a1: u64): u128;
 #[native_interface]
    native public fun reward_growth_global<T0, T1>(a0: &pool::Pool<T0, T1>, a1: u64): u128;
 #[native_interface]
    native public fun reserves<T0, T1>(a0: &pool::Pool<T0, T1>): (u64, u64);
 #[native_interface]
    native public fun swap_receipt_debts(a0: &pool::SwapReceipt): (u64, u64);
 #[native_interface]
    native public fun flash_receipt_debts(a0: &pool::FlashReceipt): (u64, u64);
 #[native_interface]
    native public(friend) fun create<T0, T1>(a0: u64, a1: u32, a2: &mut tx_context::TxContext): pool::Pool<T0, T1>;
 #[native_interface]
    native public fun initialize<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: u128, a2: &versioned::Versioned, a3: &clock::Clock, a4: &tx_context::TxContext);
 #[native_interface]
    native public fun modify_liquidity<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: &mut position::Position, a2: i128::I128, a3: balance::Balance<T0>, a4: balance::Balance<T1>, a5: &versioned::Versioned, a6: &clock::Clock, a7: &tx_context::TxContext): (u64, u64);
 #[native_interface]
    native public fun swap<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: bool, a2: bool, a3: u64, a4: u128, a5: &versioned::Versioned, a6: &clock::Clock, a7: &tx_context::TxContext): (balance::Balance<T0>, balance::Balance<T1>, pool::SwapReceipt);
 #[native_interface]
    native public fun pay<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: pool::SwapReceipt, a2: balance::Balance<T0>, a3: balance::Balance<T1>, a4: &versioned::Versioned, a5: &tx_context::TxContext);
 #[native_interface]
    native public fun flash<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: u64, a2: u64, a3: &versioned::Versioned, a4: &tx_context::TxContext): (balance::Balance<T0>, balance::Balance<T1>, pool::FlashReceipt);
 #[native_interface]
    native public fun repay<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: pool::FlashReceipt, a2: balance::Balance<T0>, a3: balance::Balance<T1>, a4: &versioned::Versioned, a5: &tx_context::TxContext);
 #[native_interface]
    native public fun collect<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: &mut position::Position, a2: u64, a3: u64, a4: &versioned::Versioned, a5: &tx_context::TxContext): (balance::Balance<T0>, balance::Balance<T1>);
 #[native_interface]
    native public fun collect_protocol_fee<T0, T1>(a0: &admin_cap::AdminCap, a1: &mut pool::Pool<T0, T1>, a2: u64, a3: u64, a4: &versioned::Versioned, a5: &tx_context::TxContext): (balance::Balance<T0>, balance::Balance<T1>);
 #[native_interface]
    native public fun collect_pool_reward<T0, T1, T2>(a0: &mut pool::Pool<T0, T1>, a1: &mut position::Position, a2: u64, a3: &versioned::Versioned, a4: &tx_context::TxContext): balance::Balance<T2>;
 #[native_interface]
    native public fun set_protocol_fee_rate<T0, T1>(a0: &admin_cap::AdminCap, a1: &mut pool::Pool<T0, T1>, a2: u64, a3: u64, a4: &versioned::Versioned, a5: &tx_context::TxContext);
 #[native_interface]
    native public fun increase_observation_cardinality_next<T0, T1>(a0: &mut pool::Pool<T0, T1>, a1: u64, a2: &versioned::Versioned, a3: &tx_context::TxContext);
 #[native_interface]
    native public fun snapshot_cumulatives_inside<T0, T1>(a0: &pool::Pool<T0, T1>, a1: i32::I32, a2: i32::I32, a3: &clock::Clock): (i64::I64, u256, u64);
 #[native_interface]
    native public fun observe<T0, T1>(a0: &pool::Pool<T0, T1>, a1: vector<u64>, a2: &clock::Clock): (vector<i64::I64>, vector<u256>);
 #[native_interface]
    native public fun initialize_pool_reward<T0, T1, T2>(a0: &admin_cap::AdminCap, a1: &mut pool::Pool<T0, T1>, a2: u64, a3: u64, a4: balance::Balance<T2>, a5: &versioned::Versioned, a6: &clock::Clock, a7: &tx_context::TxContext);
 #[native_interface]
    native public fun increase_pool_reward<T0, T1, T2>(a0: &admin_cap::AdminCap, a1: &mut pool::Pool<T0, T1>, a2: balance::Balance<T2>, a3: &versioned::Versioned, a4: &clock::Clock, a5: &tx_context::TxContext);
 #[native_interface]
    native public fun extend_pool_reward_timestamp<T0, T1, T2>(a0: &admin_cap::AdminCap, a1: &mut pool::Pool<T0, T1>, a2: u64, a3: &versioned::Versioned, a4: &clock::Clock, a5: &tx_context::TxContext);

}

module cetusclmm::position_snapshot{
    use cetusclmm::position::PositionInfo;
    use move_stl::linked_table;
    use sui::object::{UID, ID};
    use integer_mate::full_math_u128;
    use cetusclmm::position;
    use integer_mate::i32::I32;
    
    // Parts Per Million
    const PPM: u64 = 1000000;
    
    const EPositionSnapshotNotFound: u64 = 2;
    
    friend cetusclmm::pool;
    
    struct PositionLiquiditySnapshot has key, store {
        id: UID,
        current_sqrt_price: u128,
        remove_percent: u64,
        total_value_cutted: u64,
        snapshots: linked_table::LinkedTable<ID, PositionSnapshot>,
    }
    
    struct PositionSnapshot has store, drop, copy {
        position_id: ID,
        liquidity: u128,
        tick_lower_index: I32,
        tick_upper_index: I32,
        fee_owned_a: u64,
        fee_owned_b: u64,
        rewards: vector<u64>,
        value_cutted: u64
    }
    
    public fun remove_percent(snapshot: &PositionLiquiditySnapshot): u64 {
        snapshot.remove_percent
    }
    
    public fun current_sqrt_price(snapshot: &PositionLiquiditySnapshot): u128 {
        snapshot.current_sqrt_price
    }
    
    public fun total_value_cutted(snapshot: &PositionLiquiditySnapshot): u64 {
        snapshot.total_value_cutted
    }
    
    public fun value_cutted(snapshot: &PositionSnapshot): u64 {
        snapshot.value_cutted
    }
    
    public fun rewards(snapshot: &PositionSnapshot): vector<u64> {
        snapshot.rewards
    }
    
    public fun fee_owned(snapshot: &PositionSnapshot): (u64, u64) {
        (snapshot.fee_owned_a, snapshot.fee_owned_b)
    }
    
    public fun tick_range(snapshot: &PositionSnapshot): (I32, I32) {
        (snapshot.tick_lower_index, snapshot.tick_upper_index)
    }   
    
    public fun liquidity(snapshot: &PositionSnapshot): u128 {
        snapshot.liquidity
    }
    
    public fun position_id(snapshot: &PositionSnapshot): ID {
        snapshot.position_id
    }
    
    public fun calculate_remove_liquidity(snapshot: &PositionLiquiditySnapshot, position_info: &PositionInfo): u128 {
        let liquidity = position::info_liquidity(position_info);
        full_math_u128::mul_div_ceil((snapshot.remove_percent as u128), liquidity, (PPM as u128))
    }
    
    public fun get(snapshot: &PositionLiquiditySnapshot, position_id: ID): PositionSnapshot {
        assert!(linked_table::contains(&snapshot.snapshots, position_id), EPositionSnapshotNotFound);
        *linked_table::borrow(&snapshot.snapshots, position_id)
    }
    
    public fun contains(snapshot: &PositionLiquiditySnapshot, position_id: ID): bool {
        linked_table::contains(&snapshot.snapshots, position_id)
    }
}

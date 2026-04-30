/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::tick_bitmap {
    use sui::table::{Self, Table};

    // clmm
    use integer_mate::i32::{I32};
    use integer_library::i32::{Self, I32 as LibraryI32Type};
    use bluefin_spot::bit_math;
    use bluefin_spot::constants;
    use bluefin_spot::i32H;
    
    // friends
    friend bluefin_spot::pool;

    #[test_only]
    friend bluefin_spot::test_tick_bitmap;
    
    public fun cast_to_u8(index: I32) : u8 {
        let lib_index = i32H::mate_to_lib(index);

        assert!(i32::abs_u32(lib_index) < 256, 0);
        ((i32::abs_u32(i32::add(lib_index, i32::from(256))) & 255) as u8)
    }
    
    public(friend) fun flip_tick(bitmap: &mut Table<I32, u256>, index: I32, tick_spacing: u32) {

        let lib_index = i32H::mate_to_lib(index);

        assert!(i32::abs_u32(lib_index) % tick_spacing == 0, 0);
        let (word, bit) = position(i32::div(lib_index, i32::from(tick_spacing)));
        let word = get_mutable_tick_word(bitmap, i32H::lib_to_mate(word));
        *word = *word ^ 1 << bit;
    }
    
    public fun next_initialized_tick_within_one_word(bitmap: &Table<I32, u256>, tick: I32, tick_spacing: u32, a2b: bool) : (I32, bool) {

        let tick_spacing_i32 = i32::from(tick_spacing);
        let lib_tick = i32H::mate_to_lib(tick);
        
        let compressed = i32::div(lib_tick, tick_spacing_i32);
        
        if (i32::is_neg(lib_tick) && (i32::abs_u32(lib_tick) % tick_spacing) != 0) {
            compressed = i32::sub(compressed, i32::from(1));
        };
         

       if (a2b) {
            let (word, bit) = position(compressed);

            let mask = get_immutable_tick_word(bitmap, i32H::lib_to_mate(word)) & (1 << bit) - 1 + (1 << bit);

            let next = if (mask != 0) {
                i32::mul(i32::sub(compressed, i32::sub(i32::from((bit as u32)), i32::from((bit_math::most_significant_bit(mask) as u32)))), tick_spacing_i32)
            } else {
                i32::mul(i32::sub(compressed, i32::from((bit as u32))), tick_spacing_i32)
            };

            (i32H::lib_to_mate(next), mask != 0)
        } else {
            
            let (word, bit) = position(i32::add(compressed, i32::from(1)));
            
            let mask = get_immutable_tick_word(bitmap, i32H::lib_to_mate(word)) & ((1 << bit) - 1 ^ constants::max_u256());
            
            let next = if (mask != 0) {
                i32::mul(i32::add(i32::add(compressed, i32::from(1)), i32::from((bit_math::least_significant_bit(mask) as u32) - (bit as u32))), tick_spacing_i32)
            } else {
                i32::mul(i32::add(i32::add(compressed, i32::from(1)), i32::from((constants::max_u8() as u32) - (bit as u32))), tick_spacing_i32)
            };

            (i32H::lib_to_mate(next), mask != 0)
        }
    }
    
    fun position(tick: LibraryI32Type) : (LibraryI32Type, u8) {
        (
            i32::shr(tick, 8), 
            cast_to_u8(i32H::lib_to_mate(i32::mod(tick, i32::from(256))))
        )
    }
    
    fun get_mutable_tick_word(bitmap: &mut Table<I32, u256>, tick: I32) : &mut u256 {
        if (!table::contains<I32, u256>(bitmap, tick)) {
            table::add<I32, u256>(bitmap, tick, 0);
        };
        table::borrow_mut<I32, u256>(bitmap, tick)
    }
    
    fun get_immutable_tick_word(bitmap: &Table<I32, u256>, tick: I32) : u256 {
        if (!table::contains<I32, u256>(bitmap, tick)) {
            0
        } else {
            *table::borrow<I32, u256>(bitmap, tick)
        }
    }
}


/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::constants {
     use std::string::{Self, String};


    //===========================================================//
    //                          Constants                        //
    //===========================================================//


    /// Default protocol fee share
    const PROTOCOL_FEE_SHARE: u64 = 200000;
    
    /// Max allowed protocol fee share that admin can set
    const MAX_ALLOWED_PROTOCOL_FEE_SHARE: u64 = 500000;

    /// Max allowed fee rate of a pool (2%)
    const MAX_ALLOWED_FEE_RATE: u64 = 20000;

    /// Max allowed tick spacing on a pool 
    const MAX_ALLOWED_TICK_SPACING: u32 = 400;

    /// The max observation cardinality allowed on any pool
    const MAX_OBSERVATION_CARDINALITY: u64 = 1000;

    /// Q64 value
    const Q64: u128 = 18446744073709551616;

    const MAX_U8: u8 = 0xff;

    const MAX_U16: u16 = 0xffff;

    const MAX_U32: u32 = 0xffffffff;

    const MAX_U64: u64 = 0xffffffffffffffff;

    const MAX_U128: u128 = 0xffffffffffffffffffffffffffffffff;

    const MAX_U256: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    //===========================================================//
    //                        Getter Methods                     //
    //===========================================================//

    public fun protocol_fee_share(): u64 {
        PROTOCOL_FEE_SHARE
    }

    public fun max_protocol_fee_share(): u64 {
        MAX_ALLOWED_PROTOCOL_FEE_SHARE
    }

    public fun max_allowed_fee_rate(): u64 {
        MAX_ALLOWED_FEE_RATE
    }

    public fun max_allowed_tick_spacing(): u32 {
        MAX_ALLOWED_TICK_SPACING
    }

    public fun max_observation_cardinality(): u64 {
        MAX_OBSERVATION_CARDINALITY
    }

    public fun q64() : u128 {
        Q64
    }

    public fun max_u8(): u8 {
        MAX_U8
    }

    public fun max_u16(): u16 {
        MAX_U16
    }

    public fun max_u32(): u32 {
        MAX_U32
    }

    public fun max_u64(): u64 {
        MAX_U64
    }

    public fun max_u128(): u128 {
        MAX_U128
    }

    public fun max_u256(): u256 {
        MAX_U256
    }

    public fun manager(): String {
         string::utf8(b"manager")
    }

    public fun blue_reward_type(): String {
         string::utf8(b"9753a815080c9a1a1727b4be9abb509014197e78ae09e33c146c786fac3731e0::bpoint::BPOINT")
    }

    public fun pool_creation_fee_dynamic_key(): String {
         string::utf8(b"pool_creation_fee")
    }

    public fun flash_swap_in_progress_key(): vector<u8> {
        b"flash_swap_in_progress"
    }
}


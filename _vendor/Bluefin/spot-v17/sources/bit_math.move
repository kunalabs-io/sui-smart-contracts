/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::bit_math {
    
    use bluefin_spot::constants;

    public fun least_significant_bit(mask: u256) : u8 {
        assert!(mask > 0, 0);
        let bit = 255;
        if (mask & (constants::max_u128() as u256) > 0) {
            bit = bit - 128;
        } else {
            mask = mask >> 128;
        };
        if (mask & (constants::max_u64() as u256) > 0) {
            bit = bit - 64;
        } else {
            mask = mask >> 64;
        };
        if (mask & (constants::max_u32() as u256) > 0) {
            bit = bit - 32;
        } else {
            mask = mask >> 32;
        };
        if (mask & (constants::max_u16() as u256) > 0) {
            bit = bit - 16;
        } else {
            mask = mask >> 16;
        };
        if (mask & (constants::max_u8() as u256) > 0) {
            bit = bit - 8;
        } else {
            mask = mask >> 8;
        };
        if (mask & 15 > 0) {
            bit = bit - 4;
        } else {
            mask = mask >> 4;
        };
        if (mask & 3 > 0) {
            bit = bit - 2;
        } else {
            mask = mask >> 2;
        };
        if (mask & 1 > 0) {
            bit = bit - 1;
        };
        bit
    }
    
    public fun most_significant_bit(mask: u256) : u8 {
        assert!(mask > 0, 0);
        let bit = 0;
        if (mask >= 340282366920938463463374607431768211456) {
            mask = mask >> 128;
            bit = bit + 128;
        };
        if (mask >= 18446744073709551616) {
            mask = mask >> 64;
            bit = bit + 64;
        };
        if (mask >= 4294967296) {
            mask = mask >> 32;
            bit = bit + 32;
        };
        if (mask >= 65536) {
            mask = mask >> 16;
            bit = bit + 16;
        };
        if (mask >= 256) {
            mask = mask >> 8;
            bit = bit + 8;
        };
        if (mask >= 16) {
            mask = mask >> 4;
            bit = bit + 4;
        };
        if (mask >= 4) {
            mask = mask >> 2;
            bit = bit + 2;
        };
        if (mask >= 2) {
            bit = bit + 1;
        };
        bit
    }
    
}


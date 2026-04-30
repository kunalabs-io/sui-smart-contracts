/*
  Copyright (c) 2025 Bluefin Labs Inc.
  Proprietary Smart Contract License – All Rights Reserved.

  This source code is provided for transparency and verification only.
  Use, modification, reproduction, or redeployment of this code 
  requires prior written permission from the Bluefin Labs Inc.
*/

module bluefin_spot::utils {
    use std::string::{Self, String};
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{TxContext};
    use sui::balance::{Self, Balance};
    use std::type_name;
    use std::ascii;
    use sui::transfer;
    use std::vector;

    use bluefin_spot::errors;
    use bluefin_spot::constants;
    use integer_mate::i128::{I128 as MateI128Type};
    use integer_library::i128::{Self as LibraryI128};
    use bluefin_spot::i128H;

    use integer_library::math_u256;
    
    /// Returns the type of the provided generic as string
    #[allow(deprecated_usage)]
    public fun get_type_string<T>(): String {        
        string::utf8(ascii::into_bytes(type_name::into_string(type_name::get<T>())))
    }

    /// Transfers coin to the provided address if the coin balance > 0 else destroys it
    public fun transfer_coin<T>(coin: Coin<T>, account: address) {

        if(coin::value(&coin) > 0 ){
            // transferring the coin to the destination account
            transfer::public_transfer(
                coin,
                account
            );
        } else { // coin has zero balance, destroy it
            coin::destroy_zero(coin)
        }
    }

    /// Transfers balance to the provided address if the balance > 0 else destroys it
    public fun transfer_balance<T>(balance: Balance<T>, account: address, ctx: &mut TxContext) {

        if(balance::value(&balance) > 0 ){
            // transferring the coin to the destination account
            transfer::public_transfer(
                coin::from_balance<T>(balance, ctx),
                account
            );
        } else { // coin has zero balance, destroy it
            balance::destroy_zero<T>(balance)
        }
    }

    /// Returns current timestamp in seconds
    public fun timestamp_seconds(clock: &Clock): u64 {
        clock::timestamp_ms(clock) / 1000
    }

    /// Deposits the provided amount of `b` balance into `a` and reutrns the residual `b` balance
    public fun deposit_balance<T>(a: &mut Balance<T>,  b: Balance<T>, amount: u64): Balance<T> {

        let value = balance::value(&b);

        assert!(value >= amount, errors::insufficient_coin_balance());

        // take the amount of coin for deposit
        let balance = balance::split(&mut b, amount);

        // depositing the coin 
        balance::join(a, balance);

        b
    }

    /// Withdraws provided `amount` of balance if possible
    public fun withdraw_balance<T>(balance: &mut Balance<T>, amount: u64): Balance<T>{

        let value = balance::value(balance);

        assert!(value >= amount, errors::insufficient_coin_balance());

        balance::split(balance, amount)

    }

    /// Converts u128 to string
    public fun u128_to_string(num: u128) : String {
        if (num == 0) {
            return string::utf8(b"0")
        };

        let vec = vector::empty<u8>();
        while (num > 0) {
            let digit = ((num % 10) as u8);
            num = num / 10;
            0x1::vector::push_back<u8>(&mut vec, digit + 48);
        };
        vector::reverse<u8>(&mut vec);
        string::utf8(vec)
    }
 

    public fun add_delta(current_liquidity: u128, delta: MateI128Type) : u128 {
        
            let lib_delta = i128H::mate_to_lib(delta);
            let value = LibraryI128::abs_u128(lib_delta);

            if (LibraryI128::is_neg(lib_delta)) {
                assert!(current_liquidity >= value, errors::insufficient_liquidity());
                current_liquidity - value
            } else {
                assert!(value < constants::max_u128() - current_liquidity, errors::insufficient_liquidity());
                current_liquidity + value
            }
    }


    public fun overflow_add(num1: u256, num2: u256) : u256 {
        if (!math_u256::add_check(num1, num2)) {
            num2 - (constants::max_u256() - num1) - 1
        } else {
            num1 + num2
        }
    }   

}
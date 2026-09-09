module cetus_clmm::utils;

use std::string::{Self, String};

/// Convert u64 to String.
public fun str(mut num: u64): String {
    if (num == 0) {
        return string::utf8(b"0")
    };
    let mut remainder: u8;
    let mut digits = vector::empty<u8>();
    while (num > 0) {
        remainder = (num % 10 as u8);
        num = num / 10;
        vector::push_back(&mut digits, remainder + 48);
    };
    vector::reverse(&mut digits);
    string::utf8(digits)
}


#[test_only]
use std::u64::to_string;

#[test]
fun test_str() {
    assert!(str(0) == string::utf8(b"0"), 1);
    assert!(str(1) == string::utf8(b"1"), 2);
    assert!(str(10) == string::utf8(b"10"), 3);
    assert!(str(100) == string::utf8(b"100"), 4);
    assert!(str(999) == string::utf8(b"999"), 5);
    assert!(str(123456789) == string::utf8(b"123456789"), 6);
    assert!(str(0) == to_string(0), 7);
    assert!(str(1) == to_string(1), 8);
    assert!(str(10) == to_string(10), 9);
    assert!(str(100) == to_string(100), 10);
    assert!(str(999) == to_string(999), 11);
    assert!(str(123456789) == to_string(123456789), 12);
}

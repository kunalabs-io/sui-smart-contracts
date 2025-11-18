#[test_only]
module kai_leverage::pyth_tests;

use deep::deep::DEEP;
use kai_leverage::pyth;
use lbtc::lbtc::LBTC;
use std::type_name;
use suiusdt::usdt::USDT as SUIUSDT;
use usdc::usdc::USDC;
use usdy::usdy::USDY;
use wal::wal::WAL;
use wbtc::btc::BTC as WBTC;
use whusdce::coin::COIN as WHUSDCE;
use whusdte::coin::COIN as WHUSDTE;
use xbtc::xbtc::XBTC;
use sui::sui::SUI;

public struct DUMMY_COIN has drop { }

#[test]
public fun test_decimals() {
    assert!(pyth::decimals(type_name::with_defining_ids<SUI>()) == 9);
    assert!(pyth::decimals(type_name::with_defining_ids<WHUSDCE>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<WHUSDTE>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<USDC>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<SUIUSDT>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<USDY>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<DEEP>()) == 6);
    assert!(pyth::decimals(type_name::with_defining_ids<WAL>()) == 9);
    assert!(pyth::decimals(type_name::with_defining_ids<LBTC>()) == 8);
    assert!(pyth::decimals(type_name::with_defining_ids<WBTC>()) == 8);
    assert!(pyth::decimals(type_name::with_defining_ids<XBTC>()) == 8);
}

#[test, expected_failure(abort_code = pyth::EUnsupportedCoinType)]
fun test_decimals_aborts_when_unsupported_coin_type() {
    pyth::decimals(type_name::with_defining_ids<DUMMY_COIN>());
}

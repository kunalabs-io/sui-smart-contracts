#[test_only]
module cetus_clmm::partner_tests;

use cetus_clmm::config;
use cetus_clmm::partner::{create_partner, create_partners_for_test, return_partners, update_ref_fee_rate, update_time_range};
use sui::clock;
use sui::coin;
use std::string;
use std::type_name;
use sui::transfer::{public_share_object, public_transfer};
use cetus_clmm::partner::create_partner_for_test;
use cetus_clmm::partner;
use sui::bag;
use sui::balance;
use std::string::String;
use sui::balance::Balance;
use sui::test_scenario;
use cetus_clmm::partner::Partner;
use std::unit_test::assert_eq;

#[test]
fun test_create_partner() {
    let mut sc = test_scenario::begin(@1988);
    let ctx = sc.ctx();
    let mut clk = clock::create_for_testing(ctx);
    let (cap, config) = config::new_global_config_for_test(ctx, 2000);
    let mut partners = create_partners_for_test(ctx);
    create_partner(
        &config,
        &mut partners,
        string::utf8(b"partner"),
        1000,
        1000,
        10010,
        @1234,
        &clk,
        ctx,
    );
    public_transfer(cap, tx_context::sender(ctx));
    public_share_object(config);
    return_partners(partners);
    sc.next_tx(@1988);
    let partner = test_scenario::take_shared<Partner>(&sc);
    assert!(partner::name(&partner) == string::utf8(b"partner"), 0);
    assert!(partner::ref_fee_rate(&partner) == 1000, 0);
    assert_eq!(partner.current_ref_fee_rate(clk.timestamp_ms()/ 1000), 0);
    test_scenario::return_shared(partner);
    sc.next_tx(@1988);

    clk.increment_for_testing(1001 * 1000);
    let partner = test_scenario::take_shared<Partner>(&sc);
    assert_eq!(partner::ref_fee_rate(&partner), 1000);
    assert_eq!(partner.current_ref_fee_rate(clk.timestamp_ms()/ 1000), 1000);
    test_scenario::return_shared(partner);
    sc.next_tx(@1988);
    clk.increment_for_testing(10011 * 1000);
    let partner = test_scenario::take_shared<Partner>(&sc);
    assert_eq!(partner::ref_fee_rate(&partner), 1000);
    assert_eq!(partner.current_ref_fee_rate(clk.timestamp_ms()/ 1000), 0);
    test_scenario::return_shared(partner);
    test_scenario::end(sc);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidTime)]
fun test_create_partner_time_error() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let mut partners = create_partners_for_test(&mut ctx);
    create_partner(
        &config,
        &mut partners,
        string::utf8(b"partner"),
        1000,
        1000,
        1000,
        @1234,
        &clk,
        &mut ctx,
    );
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    return_partners(partners);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidTime)]
fun test_create_partner_startime_error() {
    let mut ctx = tx_context::dummy();
    let mut clk = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clk, 1684205966000);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let mut partners = create_partners_for_test(&mut ctx);
    create_partner(
        &config,
        &mut partners,
        string::utf8(b"partner"),
        1000,
        1684205965,
        1684205990,
        @1234,
        &clk,
        &mut ctx,
    );
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    return_partners(partners);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidPartnerRefFeeRate)]
fun test_create_partner_ref_fee_error() {
    let mut ctx = tx_context::dummy();
    let mut clk = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clk, 1684205966000);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let mut partners = create_partners_for_test(&mut ctx);
    create_partner(
        &config,
        &mut partners,
        string::utf8(b"partner"),
        10000,
        1684205975,
        1684205990,
        @1234,
        &clk,
        &mut ctx,
    );
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    return_partners(partners);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidPartnerName)]
fun test_create_partner_name_error() {
    let mut ctx = tx_context::dummy();
    let mut clk = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clk, 1684205966000);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let mut partners = create_partners_for_test(&mut ctx);
    create_partner(
        &config,
        &mut partners,
        string::utf8(b""),
        5000,
        1684205975,
        1684205990,
        @1234,
        &clk,
        &mut ctx,
    );
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    return_partners(partners);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EPartnerAlreadyExist)]
fun test_create_partner_exists_error() {
    let mut ctx = tx_context::dummy();
    let mut clk = clock::create_for_testing(&mut ctx);
    clock::set_for_testing(&mut clk, 1684205966000);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let mut partners = create_partners_for_test(&mut ctx);
    create_partner(
        &config,
        &mut partners,
        string::utf8(b"partner"),
        5000,
        1684205975,
        1684205990,
        @1234,
        &clk,
        &mut ctx,
    );
    create_partner(
        &config,
        &mut partners,
        string::utf8(b"partner"),
        5000,
        1684205975,
        1684205990,
        @1234,
        &clk,
        &mut ctx,
    );
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    return_partners(partners);
    clock::destroy_for_testing(clk);
}

#[test]
fun test_update_ref_fee_rate() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let (partner_cap, mut partner) = create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );
    update_ref_fee_rate(&config, &mut partner, 2000, &ctx);
    assert!(partner::ref_fee_rate(&partner) == 2000, 0);
    transfer::public_transfer(partner_cap, tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    transfer::public_share_object(partner);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidPartnerRefFeeRate)]
fun test_update_ref_fee_rate_invalid() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let (partner_cap, mut partner) = create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );
    update_ref_fee_rate(&config, &mut partner, 10000, &ctx);
    assert!(partner::ref_fee_rate(&partner) == 10000, 0);
    transfer::public_transfer(partner_cap, tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    transfer::public_share_object(partner);
    clock::destroy_for_testing(clk);
}

#[test]
fun test_update_time_range() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let (partner_cap, mut partner) = create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );
    update_time_range(&config, &mut partner, 2000, 2000000000, &clk, &mut ctx);
    assert!(partner::start_time(&partner) == 2000, 0);
    assert!(partner::end_time(&partner) == 2000000000, 0);
    transfer::public_transfer(partner_cap, tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    transfer::public_share_object(partner);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidTime)]
fun test_update_time_range_invalid_time() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let (partner_cap, mut partner) = create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );
    update_time_range(&config, &mut partner, 1750955032, 1750925032, &clk, &mut ctx);
    assert!(partner::start_time(&partner) == 1750925032, 0);
    assert!(partner::end_time(&partner) == 1750925032, 0);
    transfer::public_transfer(partner_cap, tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    transfer::public_share_object(partner);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidTime)]
fun test_update_time_range_invalid_time_2() {
    let mut ctx = tx_context::dummy();
    let mut clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let (partner_cap, mut partner) = create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );
    clk.increment_for_testing(1750955032 * 1000);
    update_time_range(&config, &mut partner,1750925032,  1750954032, &clk, &mut ctx);
    assert!(partner::start_time(&partner) == 1750925032, 0);
    assert!(partner::end_time(&partner) == 1750925032, 0);
    transfer::public_transfer(partner_cap, tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    transfer::public_share_object(partner);
    clock::destroy_for_testing(clk);
}

public struct CoinA {}

public struct CoinB {}

#[test]
fun test_receiver_and_claim_ref_fee() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let (partner_cap, mut partner) = create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );
    let coin_a = coin::mint_for_testing<CoinA>(1000000000, &mut ctx);
    partner::receive_ref_fee_internal(&mut partner, coin::into_balance(coin_a));

    // receive second time
    let coin_a = coin::mint_for_testing<CoinA>(1000000000, &mut ctx);
    partner::receive_ref_fee_internal(&mut partner, coin::into_balance(coin_a));
    let type_name = type_name::get<CoinA>();
    let key = string::from_ascii(type_name::into_string(type_name));
    let balance_a = bag::borrow<String, Balance<CoinA>>(partner::balances(&partner), key);
    assert!(balance::value(balance_a) == 2000000000, 0);
    partner::claim_ref_fee<CoinA>(&config, &partner_cap, &mut partner, &mut ctx);
    transfer::public_transfer(partner_cap, tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    transfer::public_share_object(partner);
    clock::destroy_for_testing(clk);
}

#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidCoinType)]
fun test_receiver_and_claim_ref_fee_invalid_coin_type() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let (partner_cap, mut partner) = create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );
    let coin_a = coin::mint_for_testing<CoinA>(1000000000, &mut ctx);
    partner::receive_ref_fee_internal(&mut partner, coin::into_balance(coin_a));

    // receive second time
    let coin_a = coin::mint_for_testing<CoinA>(1000000000, &mut ctx);
    partner::receive_ref_fee_internal(&mut partner, coin::into_balance(coin_a));
    let type_name = type_name::get<CoinA>();
    let key = string::from_ascii(type_name::into_string(type_name));
    let balance_a = bag::borrow<String, Balance<CoinA>>(partner::balances(&partner), key);
    assert!(balance::value(balance_a) == 2000000000, 0);
    partner::claim_ref_fee<CoinB>(&config, &partner_cap, &mut partner, &mut ctx);
    transfer::public_transfer(partner_cap, tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    transfer::public_share_object(partner);
    clock::destroy_for_testing(clk);
}



#[test]
#[expected_failure(abort_code = cetus_clmm::partner::EInvalidPartnerCap)]
fun test_claim_ref_fee_wrong_partner_cap() {
    let mut ctx = tx_context::dummy();
    let clk = clock::create_for_testing(&mut ctx);
    let (cap, config) = config::new_global_config_for_test(&mut ctx, 2000);
    let (partner_cap, mut partner) = create_partner_for_test(
        string::utf8(b"TestPartner"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );

    let (partner_cap2, partner2) = create_partner_for_test(
        string::utf8(b"TestPartner2"),
        2000,
        1,
        10000000000,
        &clk,
        &mut ctx,
    );
    let coin_a = coin::mint_for_testing<CoinA>(1000000000, &mut ctx);
    partner::receive_ref_fee_internal(&mut partner, coin::into_balance(coin_a));

    // receive second time
    let coin_a = coin::mint_for_testing<CoinA>(1000000000, &mut ctx);
    partner::receive_ref_fee_internal(&mut partner, coin::into_balance(coin_a));
    let type_name = type_name::get<CoinA>();
    let key = string::from_ascii(type_name::into_string(type_name));
    let balance_a = bag::borrow<String, Balance<CoinA>>(partner::balances(&partner), key);
    assert!(balance::value(balance_a) == 2000000000, 0);
    partner::claim_ref_fee<CoinA>(&config, &partner_cap2, &mut partner, &mut ctx);
    transfer::public_transfer(partner_cap, tx_context::sender(&ctx));
    transfer::public_transfer(partner_cap2, tx_context::sender(&ctx));
    public_transfer(cap, tx_context::sender(&ctx));
    public_share_object(config);
    transfer::public_share_object(partner);
    transfer::public_share_object(partner2);
    clock::destroy_for_testing(clk);
}

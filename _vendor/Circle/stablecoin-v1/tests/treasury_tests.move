// Copyright 2024 Circle Internet Group, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#[test_only]
module stablecoin::treasury_tests {
    use std::string;
    use std::ascii;
    use sui::{
        coin::{Self, Coin, CoinMetadata},
        deny_list::{Self, DenyList},
        event,
        vec_set,
        test_scenario::{Self, Scenario}, 
        test_utils::{Self, assert_eq, destroy},
    };
    use stablecoin::{
        entry,
        treasury::{Self, MintCap, Treasury},
        version_control
    };
    use sui_extensions::test_utils::last_event_by_type;

    // test addresses
    const DEPLOYER: address = @0x0;
    const MASTER_MINTER: address = @0x20;
    const CONTROLLER: address = @0x30;
    const MINTER: address = @0x40;
    const MINT_RECIPIENT: address = @0x50;
    const MINT_CAP_ADDR: address = @0x60;
    const OWNER: address = @0x70;
    const BLOCKLISTER: address = @0x80;
    const PAUSER: address = @0x01;
    const METADATA_UPDATER: address = @0x11;

    const RANDOM_ADDRESS: address = @0x1000;
    const RANDOM_ADDRESS_2: address = @0x1001;
    const RANDOM_ADDRESS_3: address = @0x1002;
    const RANDOM_ADDRESS_4: address = @0x1003;

    public struct TREASURY_TESTS has drop {}

    #[test]
    fun e2e_flow__should_succeed_and_pass_all_assertions() {
        // Transaction 1: create coin and treasury
        let mut scenario = setup();

        // Transaction 2: configure mint controller and worker
        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        // Transaction 3: configure minter
        scenario.next_tx(CONTROLLER);
        test_configure_minter(1000000, &mut scenario);

        // Transaction 4: mint to recipient address
        scenario.next_tx(MINTER);
        test_mint(1000000, MINT_RECIPIENT, &mut scenario);

        // Transaction 5: transfer coin balance to minter to be burnt
        scenario.next_tx(MINT_RECIPIENT);
        {
            let coin = scenario.take_from_sender<Coin<TREASURY_TESTS>>();
            assert_eq(coin.value(), 1000000);
            transfer::public_transfer(coin, MINTER);
        };

        // Transaction 6: burn minted balance
        scenario.next_tx(MINTER);
        test_burn(&mut scenario);

        // Transaction 6: remove minter
        scenario.next_tx(CONTROLLER);
        test_remove_minter(&mut scenario);

        // Transaction 7: remove controller
        scenario.next_tx(MASTER_MINTER);
        test_remove_controller(CONTROLLER, &mut scenario);

        scenario.end();
    }

    #[test]
    fun configure_controller__should_succeed_with_existing_mint_cap() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MASTER_MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(10, &mut scenario);

        scenario.next_tx(MASTER_MINTER);
        {
            let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
            let mint_cap = scenario.take_from_sender<MintCap<TREASURY_TESTS>>();

            treasury.configure_controller(RANDOM_ADDRESS, object::id(&mint_cap), scenario.ctx());
            assert_eq(treasury.get_controllers_for_testing().contains(RANDOM_ADDRESS), true);
            assert_eq(treasury.get_controllers_for_testing().contains(CONTROLLER), true); 
            let mint_cap_id = *treasury.get_mint_cap_id(RANDOM_ADDRESS).borrow();
            assert_eq(*treasury.get_mint_cap_id(CONTROLLER).borrow(), mint_cap_id);
            assert_eq(treasury.mint_allowance(mint_cap_id), 10);

            scenario.return_to_sender(mint_cap);
            test_scenario::return_shared(treasury);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EControllerAlreadyConfigured)]
    fun configure_controller__should_fail_with_existing_controller() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_controller(CONTROLLER, object::id_from_address(MINT_CAP_ADDR), &mut scenario);

        // Configure the same controller - expect failure
        scenario.next_tx(MASTER_MINTER);
        test_configure_controller(CONTROLLER, object::id_from_address(MINT_CAP_ADDR), &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotMasterMinter)]
    fun configure_controller__should_fail_if_caller_is_not_master_minter() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS); 
        {
            let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
            treasury.configure_controller(RANDOM_ADDRESS, object::id_from_address(MINT_CAP_ADDR), scenario.ctx());
            test_scenario::return_shared(treasury);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotMasterMinter)]
    fun configure_new_controller__should_fail_if_caller_is_not_master_minter() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_configure_new_controller(CONTROLLER, RANDOM_ADDRESS_2, &mut scenario); 

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EControllerAlreadyConfigured)]
    fun configure_new_controller__should_fail_with_existing_controller() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, RANDOM_ADDRESS_2, &mut scenario);

        // Configure the same controller - expect failure
        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, RANDOM_ADDRESS_2, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotController)]
    fun remove_controller__should_fail_with_non_controller() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_remove_controller(RANDOM_ADDRESS, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotMasterMinter)]
    fun remove_controller__should_fail_if_not_sent_by_master_minter() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_remove_controller(CONTROLLER, &mut scenario);

        scenario.end();
    }

    #[test]
    fun configure_minter__should_reset_allowance() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER); 
        test_configure_minter(0, &mut scenario);

        scenario.next_tx(CONTROLLER); 
        test_configure_minter(10, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotController)]
    fun configure_minter__should_fail_from_non_controller() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS); 
        test_configure_minter(0, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EPaused)]
    fun configure_minter__should_fail_when_paused() {
        let mut scenario = setup();

        scenario.next_tx(PAUSER); 
        test_pause(&mut scenario);

        scenario.next_tx(CONTROLLER); 
        test_configure_minter(10, &mut scenario);

        scenario.end();
    }

    #[test]
    fun increment_mint_allowance__should_increment_allowance() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER); 
        test_configure_minter(1, &mut scenario);

        scenario.next_tx(CONTROLLER); 
        test_increment_mint_allowance(2, 3 /* expected_allowance */, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EPaused)]
    fun increment_mint_allowance__should_fail_when_paused() {
        let mut scenario = setup();

        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);

        scenario.next_tx(CONTROLLER);
        test_increment_mint_allowance(10, 10 /* expected_allowance */, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EZeroAmount)]
    fun increment_mint_allowance__should_fail_when_incrementing_by_zero() {
        let mut scenario = setup();

        scenario.next_tx(CONTROLLER);
        test_increment_mint_allowance(0, 0 /* expected_allowance */, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotController)]
    fun increment_mint_allowance__should_fail_from_non_controller() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS); 
        test_increment_mint_allowance(10, 10 /* expected_allowance */, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EUnauthorizedMintCap)]
    fun increment_mint_allowance__should_fail_with_unauthorized_mint_cap() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_increment_mint_allowance(10, 10 /* expected_allowance */, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::mint_allowance::EOverflow)]
    fun increment_mint_allowance__should_fail_when_allowance_increment_causes_overflow() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER); 
        test_configure_minter(1, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_increment_mint_allowance(18446744073709551615u64, 0 /* expected_allowance */, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotController)]
    fun remove_minter__should_fail_from_non_controller() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS); 
        test_remove_minter(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EZeroAmount)]
    fun mint__should_fail_with_zero_amount() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(1000000, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(0, MINT_RECIPIENT, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EUnauthorizedMintCap)]
    fun mint__should_fail_from_deauthorized_mint_cap() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(1000000, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_remove_minter(&mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINT_RECIPIENT, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EInsufficientAllowance)]
    fun mint__should_fail_if_exceed_allowance() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(0, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINT_RECIPIENT, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EInsufficientAllowance)]
    fun mint__should_fail_if_exceed_allowance_non_zero() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(900000, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINT_RECIPIENT, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EDeniedAddress)]
    fun mint__should_fail_from_denylisted_sender() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(0, &mut scenario);

        scenario.next_tx(BLOCKLISTER);
        test_blocklist(MINTER, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINT_RECIPIENT, &mut scenario);

        scenario.end();
    }
 
    #[test, expected_failure(abort_code = ::stablecoin::treasury::EDeniedAddress)]
    fun mint__should_fail_given_denylisted_recipient() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(0, &mut scenario);

        scenario.next_tx(BLOCKLISTER);
        test_blocklist(MINT_RECIPIENT, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINT_RECIPIENT, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ETreasuryCapNotFound)]
    fun mint__should_fail_if_treasury_cap_not_found() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(MASTER_MINTER);
        remove_treasury_cap(&scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(1000000, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINT_RECIPIENT, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EUnauthorizedMintCap)]
    fun burn__should_fail_from_deauthorized_mint_cap() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(1000000, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_remove_minter(&mut scenario);

        scenario.next_tx(MINTER);
        test_burn(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EPaused)]
    fun mint__should_fail_when_paused() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(0, &mut scenario);

        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINT_RECIPIENT, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EDeniedAddress)]
    fun burn__should_fail_from_denylisted_sender() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(1000000, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINTER, &mut scenario);

        scenario.next_tx(BLOCKLISTER);
        test_blocklist(MINTER, &mut scenario);

        scenario.next_tx(MINTER);
        test_burn(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EZeroAmount)]
    fun burn__should_fail_with_zero_amount() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(0, &mut scenario);

        scenario.next_tx(MINTER);
        let coin = coin::zero<TREASURY_TESTS>(scenario.ctx());
        transfer::public_transfer(coin, MINTER);

        scenario.next_tx(MINTER);
        test_burn(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EPaused)]
    fun burn__should_fail_when_paused() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(1000000, &mut scenario);

        scenario.next_tx(MINTER);
        test_mint(1000000, MINTER, &mut scenario);

        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);

        scenario.next_tx(MINTER);
        test_burn(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ETreasuryCapNotFound)]
    fun burn__should_fail_if_treasury_cap_not_found() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(MASTER_MINTER);
        remove_treasury_cap(&scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(0, &mut scenario);

        scenario.next_tx(MINTER);
        let coin = coin::zero<TREASURY_TESTS>(scenario.ctx());
        transfer::public_transfer(coin, MINTER);

        scenario.next_tx(MINTER);
        test_burn(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotBlocklister)]
    fun blocklist__should_fail_if_caller_is_not_blocklister() {
        let mut scenario = setup();

        // Some random address tries to blocklist an address, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EDenyCapNotFound)]
    fun blocklist__should_fail_when_deny_cap_is_missing() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        remove_deny_cap(&scenario);

        scenario.next_tx(BLOCKLISTER);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        scenario.end();
    }

    #[test]
    fun blocklist__should_succeed_if_caller_is_blocklister() {
        let mut scenario = setup();

        // Blocklister blocklists an address.
        scenario.next_tx(BLOCKLISTER);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_blocklisted_current_epoch(&mut scenario, RANDOM_ADDRESS_2, true);

        scenario.end();
    }

    #[test]
    fun blocklist__should_be_idempotent() {
        let mut scenario = setup();

        // Blocklister blocklists an address.
        scenario.next_tx(BLOCKLISTER);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        // Blocklisting the same address keeps the address in the blocklisted state.
        scenario.next_tx(BLOCKLISTER);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_blocklisted_current_epoch(&mut scenario, RANDOM_ADDRESS_2, true);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotBlocklister)]
    fun unblocklist__should_fail_if_caller_is_not_blocklister() {
        let mut scenario = setup();

        // Blocklister blocklists an address.
        scenario.next_tx(BLOCKLISTER);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        // Some random address tries to unblocklist the address, should fail.
        scenario.next_tx(RANDOM_ADDRESS);
        test_unblocklist(RANDOM_ADDRESS_2, &mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EDenyCapNotFound)]
    fun unblocklist__should_fail_when_deny_cap_is_missing() {
        let mut scenario = setup();

        scenario.next_tx(BLOCKLISTER);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        scenario.next_tx(RANDOM_ADDRESS);
        remove_deny_cap(&scenario);

        scenario.next_tx(BLOCKLISTER);
        test_unblocklist(RANDOM_ADDRESS_2, &mut scenario);

        scenario.end();
    }

    #[test]
    fun unblocklist__should_succeed_if_caller_is_blocklister() {
        let mut scenario = setup();

        // Blocklister blocklists an address.
        scenario.next_tx(BLOCKLISTER);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        // Blocklister unblocklists the address.
        scenario.next_tx(BLOCKLISTER);
        test_unblocklist(RANDOM_ADDRESS_2, &mut scenario);

        // Fast forward to next epoch, check blocklist state
        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_blocklisted_current_epoch(&mut scenario, RANDOM_ADDRESS_2, false);

        scenario.end();
    }

    #[test]
    fun unblocklist__should_be_idempotent() {
        let mut scenario = setup();

        // Blocklister blocklists an address.
        scenario.next_tx(BLOCKLISTER);
        test_blocklist(RANDOM_ADDRESS_2, &mut scenario);

        // Blocklister unblocklists the address.
        scenario.next_tx(BLOCKLISTER);
        test_unblocklist(RANDOM_ADDRESS_2, &mut scenario);

        // Unblocklisting the same address keeps the address in the unblocklisted state.
        scenario.next_tx(BLOCKLISTER);
        test_unblocklist(RANDOM_ADDRESS_2, &mut scenario);

        // Fast forward to next epoch, check blocklist state
        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_blocklisted_current_epoch(&mut scenario, RANDOM_ADDRESS_2, false);

        scenario.end();
    }

    #[test]
    fun update_roles__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup();

        // transfer ownership to the DEPLOYER address
        scenario.next_tx(OWNER);
        test_transfer_ownership(DEPLOYER, &mut scenario);

        scenario.next_tx(DEPLOYER);
        test_accept_ownership(&mut scenario);

        // use the DEPLOYER address to modify the master minter, blocklister, pauser, and metadata updater
        scenario.next_tx(DEPLOYER);
        test_update_master_minter(RANDOM_ADDRESS, &mut scenario);

        scenario.next_tx(DEPLOYER);
        test_update_blocklister(RANDOM_ADDRESS_2, &mut scenario);

        scenario.next_tx(DEPLOYER);
        test_update_pauser(RANDOM_ADDRESS_3, &mut scenario);

        scenario.next_tx(DEPLOYER);
        test_update_metadata_updater(RANDOM_ADDRESS_4, &mut scenario);

        scenario.end();
    }

    #[test]
    fun update_metadata__should_succeed_and_pass_all_assertions() {
        let mut scenario = setup();

        scenario.next_tx(METADATA_UPDATER);
        test_update_metadata(
            string::utf8(b"new name"),
            ascii::string(b"new symbol"),
            string::utf8(b"new description"),
            ascii::string(b"new url"),
            &mut scenario
        );

        // try to unset the URL
        scenario.next_tx(METADATA_UPDATER);
        test_update_metadata(
            string::utf8(b"new name"),
            ascii::string(b"new symbol"),
            string::utf8(b"new description"),
            ascii::string(b""),
            &mut scenario
        );

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotMetadataUpdater)]
    fun update_metadata__should_fail_if_not_metadata_updater() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_update_metadata(
            string::utf8(b"new name"),
            ascii::string(b"new symbol"),
            string::utf8(b"new description"),
            ascii::string(b"new url"),
            &mut scenario
        );

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ETreasuryCapNotFound)]
    fun update_metadata__should_fail_if_not_treasury_cap_not_found() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        remove_treasury_cap(&scenario);

        scenario.next_tx(METADATA_UPDATER);
        test_update_metadata(
            string::utf8(b"new name"),
            ascii::string(b"new symbol"),
            string::utf8(b"new description"),
            ascii::string(b"new url"),
            &mut scenario
        );

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotPauser)]
    fun pause__should_fail_when_caller_is_not_pauser() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_pause(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EDenyCapNotFound)]
    fun pause__should_fail_when_deny_cap_is_missing() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        remove_deny_cap(&scenario);

        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);

        scenario.end();
    }

    #[test]
    fun pause__should_succeed() {
        let mut scenario = setup();

        scenario.next_tx(OWNER);
        test_update_pauser(PAUSER, &mut scenario);

        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);

        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_paused_current_epoch(&mut scenario, true);

        scenario.end();
    }

    #[test]
    fun pause__should_be_idempotent() {
        let mut scenario = setup();

        scenario.next_tx(OWNER);
        test_update_pauser(PAUSER, &mut scenario);

        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);

        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);

        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_paused_current_epoch(&mut scenario, true);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ENotPauser)]
    fun unpause__should_fail_when_caller_is_not_pauser() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        test_unpause(&mut scenario);

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EDenyCapNotFound)]
    fun unpause__should_fail_when_deny_cap_is_missing() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        remove_deny_cap(&scenario);

        scenario.next_tx(PAUSER);
        test_unpause(&mut scenario);

        scenario.end();
    }

    #[test]
    fun unpause__should_succeed() {
        let mut scenario = setup();

        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);
        
        scenario.next_tx(PAUSER);
        test_unpause(&mut scenario);

        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_paused_current_epoch(&mut scenario, false);

        scenario.end();
    }

    #[test]
    fun unpause__should_be_idempotent() {
        let mut scenario = setup();

        scenario.next_tx(OWNER);
        test_update_pauser(PAUSER, &mut scenario);
        
        scenario.next_tx(PAUSER);
        test_pause(&mut scenario);

        scenario.next_tx(PAUSER);
        test_unpause(&mut scenario);

        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_paused_current_epoch(&mut scenario, false);

        scenario.next_tx(PAUSER);
        test_unpause(&mut scenario);

        scenario.next_epoch(RANDOM_ADDRESS);
        test_is_paused_current_epoch(&mut scenario, false);

        scenario.end();
    }

    #[test]
    fun is_authorized_mint_cap__should_return_expected_state() {
        let mut scenario = setup();

        scenario.next_tx(MASTER_MINTER);
        test_configure_new_controller(CONTROLLER, MINTER, &mut scenario);

        scenario.next_tx(CONTROLLER);
        test_configure_minter(10, &mut scenario);

        scenario.next_tx(RANDOM_ADDRESS);
        {
            let treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
            let mint_cap = scenario.take_from_address<MintCap<TREASURY_TESTS>>(MINTER);
            
            let random_object_id = object::new(scenario.ctx());
            assert_eq(treasury.is_authorized_mint_cap(object::id(&mint_cap)), true);
            assert_eq(treasury.is_authorized_mint_cap(random_object_id.uid_to_inner()), false);
            
            object::delete(random_object_id);
            test_scenario::return_to_address(MINTER, mint_cap);
            test_scenario::return_shared(treasury);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::ETreasuryCapNotFound)]
    fun total_supply__should_fail_when_treasury_cap_is_missing() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        remove_treasury_cap(&scenario);
        
        scenario.next_tx(RANDOM_ADDRESS);
        {
            let treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
            treasury.total_supply();
            test_scenario::return_shared(treasury);
        };

        scenario.end();
    }

    #[test]
    fun get_mint_cap_id__should_return_empty_when_input_is_not_controller() {
        let mut scenario = setup();

        scenario.next_tx(RANDOM_ADDRESS);
        {
            let treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
            assert_eq(treasury.get_mint_cap_id(RANDOM_ADDRESS), option::none());
            test_scenario::return_shared(treasury);
        };

        scenario.end();
    }

    #[test, expected_failure(abort_code = ::stablecoin::treasury::EObjectMigrated)]
    fun start_migration__should_fail_when_calling_from_current_version() {
        let mut scenario = setup();
        
        scenario.next_tx(OWNER);
        {
            let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
            treasury.start_migration(scenario.ctx());
            test_scenario::return_shared(treasury);
        };

        scenario.end();
    }
    
    // === Incompatible Treasury object tests ===
    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun configure_controller__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.configure_controller(RANDOM_ADDRESS, object::id_from_address(RANDOM_ADDRESS_2), scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun configure_new_controller__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.configure_new_controller(RANDOM_ADDRESS, RANDOM_ADDRESS_2, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun remove_controller__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.remove_controller(RANDOM_ADDRESS, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun configure_minter__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.configure_minter(&deny_list, 100000, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun increment_mint_allowance__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.increment_mint_allowance(&deny_list, 100000, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun remove_minter__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.remove_minter(scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun mint__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        let mint_cap = treasury::create_mint_cap_for_testing(scenario.ctx());
        treasury.mint(
            &mint_cap,
            &deny_list,
            100000,
            RANDOM_ADDRESS,
            scenario.ctx()
        );
        destroy(mint_cap);
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun burn__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        let mint_cap = treasury::create_mint_cap_for_testing(scenario.ctx());
        treasury.burn(
            &mint_cap,
            &deny_list,
            coin::zero<TREASURY_TESTS>(scenario.ctx()),
            scenario.ctx()
        );
        destroy(mint_cap);
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun blocklist__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, mut deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.blocklist(&mut deny_list, RANDOM_ADDRESS, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun unblocklist__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, mut deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.unblocklist(&mut deny_list, RANDOM_ADDRESS, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun pause__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, mut deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.pause(&mut deny_list, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun unpause__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, mut deny_list, metadata) = before_incompatible_treasury_object_scenario();
        treasury.unpause(&mut deny_list, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun update_metadata__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, treasury, deny_list, mut metadata) = before_incompatible_treasury_object_scenario();
        treasury.update_metadata(
            &mut metadata,
            string::utf8(b"new name"),
            ascii::string(b"new symbol"),
            string::utf8(b"new description"),
            ascii::string(b"new url"),
            scenario.ctx()
        );
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun transfer_ownership__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        entry::transfer_ownership(&mut treasury, RANDOM_ADDRESS, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun accept_ownership__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        entry::accept_ownership(&mut treasury, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun update_master_minter__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        entry::update_master_minter(&mut treasury, RANDOM_ADDRESS, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun update_blocklister__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        entry::update_blocklister(&mut treasury, RANDOM_ADDRESS, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun update_pauser__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        entry::update_pauser(&mut treasury, RANDOM_ADDRESS, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    #[test, expected_failure(abort_code = ::stablecoin::version_control::EIncompatibleVersion)]
    fun update_metadata_updater__should_fail_if_treasury_object_is_incompatible() {
        let (mut scenario, mut treasury, deny_list, metadata) = before_incompatible_treasury_object_scenario();
        entry::update_metadata_updater(&mut treasury, RANDOM_ADDRESS, scenario.ctx());
        after_incompatible_treasury_object_scenario(scenario, treasury, deny_list, metadata);
    }

    // === Helpers ===

    fun setup(): Scenario {
        let mut scenario = test_scenario::begin(DEPLOYER);
        {
            deny_list::create_for_test(scenario.ctx());
            let otw = test_utils::create_one_time_witness<TREASURY_TESTS>();
            let (treasury_cap, deny_cap, metadata) = coin::create_regulated_currency_v2(
                otw,
                6,
                b"SYMBOL",
                b"NAME",
                b"",
                option::none(),
                true,
                scenario.ctx()
            );

            let treasury = treasury::new(
                treasury_cap,
                deny_cap,
                OWNER,
                MASTER_MINTER,
                BLOCKLISTER,
                PAUSER,
                METADATA_UPDATER,
                scenario.ctx()
            );
            assert_eq(treasury.total_supply(), 0);
            assert_eq(treasury.get_controllers_for_testing().length(), 0);
            assert_eq(treasury.get_mint_allowances_for_testing().length(), 0);
            assert_eq(treasury.roles().owner(), OWNER);
            assert_eq(treasury.roles().master_minter(), MASTER_MINTER);
            assert_eq(treasury.roles().blocklister(), BLOCKLISTER);
            assert_eq(treasury.roles().pauser(), PAUSER);
            assert_eq(treasury.roles().metadata_updater(), METADATA_UPDATER);
            assert_eq(treasury.compatible_versions(), vector[version_control::current_version()]);
            treasury.assert_treasury_cap_exists();
            treasury.assert_deny_cap_exists();

            transfer::public_share_object(metadata);
            transfer::public_share_object(treasury);
        };

        scenario
    }

    fun before_incompatible_treasury_object_scenario(): (Scenario, Treasury<TREASURY_TESTS>, DenyList, CoinMetadata<TREASURY_TESTS>) {
        let mut scenario = setup();
        
        // Set compatible_versions to an invalid version.
        scenario.next_tx(OWNER);
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        treasury.set_compatible_versions_for_testing(vec_set::singleton(version_control::current_version() + 1));
        test_scenario::return_shared(treasury);

        scenario.next_tx(OWNER);
        let treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let deny_list = scenario.take_shared<DenyList>();
        let metadata = scenario.take_shared<CoinMetadata<TREASURY_TESTS>>();
        (scenario, treasury, deny_list, metadata)
    }

    fun after_incompatible_treasury_object_scenario(scenario: Scenario, treasury: Treasury<TREASURY_TESTS>, deny_list: DenyList, metadata: CoinMetadata<TREASURY_TESTS>) {
        test_scenario::return_shared(treasury);
        test_scenario::return_shared(deny_list);
        test_scenario::return_shared(metadata);
        scenario.end();
    }

    fun test_configure_new_controller(controller: address, minter: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();

        treasury.configure_new_controller(controller, minter, scenario.ctx());
        let mint_cap_id = *treasury.get_mint_cap_id(controller).borrow();
        assert_eq(treasury.get_controllers_for_testing().contains(controller), true);
        assert_eq(treasury.mint_allowance(*treasury.get_mint_cap_id(controller).borrow()), 0);

        let expected_event1 = treasury::create_mint_cap_created_event<TREASURY_TESTS>(mint_cap_id);
        let expected_event2 = treasury::create_controller_configured_event<TREASURY_TESTS>(controller, mint_cap_id);
        assert_eq(event::num_events(), 2);
        assert_eq(last_event_by_type(), expected_event1);
        assert_eq(last_event_by_type(), expected_event2);

        test_scenario::return_shared(treasury);

        // Check new MintCap has been transferred to minter.
        scenario.next_tx(minter);
        let mint_cap = scenario.take_from_sender<MintCap<TREASURY_TESTS>>();
        assert_eq(object::id(&mint_cap), mint_cap_id);
        scenario.return_to_sender(mint_cap);
    }
    
    fun test_configure_controller(controller: address, mint_cap_id: ID, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();

        treasury.configure_controller(controller, mint_cap_id, scenario.ctx());
        assert_eq(treasury.get_controllers_for_testing().contains(controller), true);
        assert_eq(treasury.mint_allowance(*treasury.get_mint_cap_id(controller).borrow()), 0);

        let expected_event = treasury::create_controller_configured_event<TREASURY_TESTS>(controller, mint_cap_id);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        test_scenario::return_shared(treasury);
    }
    
    fun test_remove_controller(controller: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();

        treasury.remove_controller(controller, scenario.ctx());
        assert_eq(treasury.get_controllers_for_testing().contains(controller), false);

        let expected_event = treasury::create_controller_removed_event<TREASURY_TESTS>(controller);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        test_scenario::return_shared(treasury);
    }

    fun test_configure_minter(allowance: u64, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let deny_list = scenario.take_shared();

        treasury.configure_minter(&deny_list, allowance, scenario.ctx());

        let mint_cap_id = *treasury.get_mint_cap_id(scenario.sender()).borrow();
        assert_eq(treasury.mint_allowance(mint_cap_id), allowance);

        let expected_event = treasury::create_minter_configured_event<TREASURY_TESTS>(scenario.sender(), mint_cap_id, allowance);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        test_scenario::return_shared(treasury);
        test_scenario::return_shared(deny_list);
    }

    fun test_increment_mint_allowance(allowance_increment: u64, expected_allowance: u64, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let deny_list = scenario.take_shared<DenyList>();
        
        treasury.increment_mint_allowance(&deny_list, allowance_increment, scenario.ctx());

        let mint_cap_id = *treasury.get_controllers_for_testing().borrow(scenario.sender());
        assert_eq(treasury.mint_allowance(mint_cap_id), expected_allowance);

        let expected_event = treasury::create_minter_allowance_incremented_event<TREASURY_TESTS>(scenario.sender(), mint_cap_id, allowance_increment, expected_allowance);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        test_scenario::return_shared(treasury);
        test_scenario::return_shared(deny_list);
    }

    fun test_remove_minter(scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();

        treasury.remove_minter(scenario.ctx());

        let mint_cap_id = *treasury.get_mint_cap_id(scenario.sender()).borrow();
        assert_eq(treasury.mint_allowance(mint_cap_id), 0);  
        assert_eq(treasury.get_mint_allowances_for_testing().contains(mint_cap_id), false);  

        let expected_event = treasury::create_minter_removed_event<TREASURY_TESTS>(scenario.sender(), mint_cap_id);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        test_scenario::return_shared(treasury);
    }

    fun test_mint(mint_amount: u64, recipient: address, scenario: &mut Scenario) {
        let deny_list = scenario.take_shared();
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let mint_cap = scenario.take_from_sender<MintCap<TREASURY_TESTS>>();

        let allowance_before = treasury.mint_allowance(object::id(&mint_cap));
        treasury.mint(&mint_cap, &deny_list, mint_amount, recipient, scenario.ctx());
        assert_eq(treasury.total_supply(), mint_amount);
        assert_eq(treasury.mint_allowance(object::id(&mint_cap)), allowance_before - mint_amount);

        let expected_event = treasury::create_mint_event<TREASURY_TESTS>(object::id(&mint_cap), recipient, mint_amount);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        scenario.return_to_sender(mint_cap);
        test_scenario::return_shared(treasury);
        test_scenario::return_shared(deny_list);

        // Check new coin has been transferred to the recipient at the end of the previous transaction
        scenario.next_tx(recipient);
        let coin = scenario.take_from_sender<Coin<TREASURY_TESTS>>();
        assert_eq(coin.value(), mint_amount);
        scenario.return_to_sender(coin);
    }

    fun test_burn(scenario: &mut Scenario) {
        let sender = scenario.sender();
        let deny_list = scenario.take_shared();
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let mint_cap = scenario.take_from_sender<MintCap<TREASURY_TESTS>>();
        let coin = scenario.take_from_sender<Coin<TREASURY_TESTS>>();
        let coin_id = object::id(&coin);
        
        let allowance_before = treasury.mint_allowance(object::id(&mint_cap));
        let amount_before = treasury.total_supply();
        let burn_amount = coin.value();
        treasury.burn(&mint_cap, &deny_list, coin, scenario.ctx());
        assert_eq(treasury.total_supply(), amount_before - burn_amount);
        assert_eq(treasury.mint_allowance(object::id(&mint_cap)), allowance_before);

        let expected_event = treasury::create_burn_event<TREASURY_TESTS>(object::id(&mint_cap), burn_amount);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        scenario.return_to_sender(mint_cap);
        test_scenario::return_shared(treasury);
        test_scenario::return_shared(deny_list);

        // Check coin ID has been deleted at the end of the previous transaction
        scenario.next_tx(sender);
        assert_eq(scenario.ids_for_sender<Coin<TREASURY_TESTS>>().contains(&coin_id), false);
    }

    fun test_blocklist(addr: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let mut deny_list = scenario.take_shared<DenyList>();
        let blocklisted_before = coin::deny_list_v2_contains_current_epoch<TREASURY_TESTS>(&deny_list, addr, scenario.ctx());

        treasury.blocklist(&mut deny_list, addr, scenario.ctx());
        assert_eq(coin::deny_list_v2_contains_next_epoch<TREASURY_TESTS>(&deny_list, addr), true);
        assert_eq(coin::deny_list_v2_contains_current_epoch<TREASURY_TESTS>(&deny_list, addr, scenario.ctx()), blocklisted_before);

        let expected_event = treasury::create_blocklisted_event<TREASURY_TESTS>(addr);
        let expected_event_count = 1 + event::events_by_type<deny_list::PerTypeConfigCreated>().length();
        assert_eq(event::num_events() as u64, expected_event_count);
        assert_eq(last_event_by_type(), expected_event);

        test_scenario::return_shared(deny_list);
        test_scenario::return_shared(treasury);
    }

    fun test_unblocklist(addr: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let mut deny_list = scenario.take_shared<DenyList>();
        let blocklisted_before = coin::deny_list_v2_contains_current_epoch<TREASURY_TESTS>(&deny_list, addr, scenario.ctx());

        treasury.unblocklist(&mut deny_list, addr, scenario.ctx());
        assert_eq(coin::deny_list_v2_contains_next_epoch<TREASURY_TESTS>(&deny_list, addr), false);
        assert_eq(coin::deny_list_v2_contains_current_epoch<TREASURY_TESTS>(&deny_list, addr, scenario.ctx()), blocklisted_before);

        let expected_event = treasury::create_unblocklisted_event<TREASURY_TESTS>(addr);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        test_scenario::return_shared(deny_list);
        test_scenario::return_shared(treasury);
    }

    fun test_transfer_ownership(new_owner: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        entry::transfer_ownership(&mut treasury, new_owner, scenario.ctx());
        assert_eq(*treasury.roles().pending_owner().borrow(), new_owner);
        test_scenario::return_shared(treasury);
    }

    fun test_accept_ownership(scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let pending_owner = treasury.roles().pending_owner();
        entry::accept_ownership(&mut treasury, scenario.ctx());
        assert_eq(treasury.roles().owner(), *pending_owner.borrow());
        assert_eq(treasury.roles().pending_owner().is_none(), true);
        test_scenario::return_shared(treasury);
    }

    fun test_update_master_minter(new_master_minter: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        entry::update_master_minter(&mut treasury, new_master_minter, scenario.ctx());
        assert_eq(treasury.roles().master_minter(), new_master_minter);
        test_scenario::return_shared(treasury);
    }

    fun test_update_blocklister(new_blocklister: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        entry::update_blocklister(&mut treasury, new_blocklister, scenario.ctx());
        assert_eq(treasury.roles().blocklister(), new_blocklister);
        test_scenario::return_shared(treasury);
    }

    fun test_update_pauser(new_pauser: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        entry::update_pauser(&mut treasury, new_pauser, scenario.ctx());
        assert_eq(treasury.roles().pauser(), new_pauser);
        test_scenario::return_shared(treasury);
    }

    fun test_update_metadata_updater(new_metadata_updater: address, scenario: &mut Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        entry::update_metadata_updater(&mut treasury, new_metadata_updater, scenario.ctx());
        assert_eq(treasury.roles().metadata_updater(), new_metadata_updater);
        test_scenario::return_shared(treasury);
    }

    fun test_pause(scenario: &mut Scenario) {
        let mut deny_list = scenario.take_shared<DenyList>();
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let paused_before = coin::deny_list_v2_is_global_pause_enabled_current_epoch<TREASURY_TESTS>(&deny_list, scenario.ctx());

        treasury.pause(&mut deny_list, scenario.ctx());
        assert_eq(coin::deny_list_v2_is_global_pause_enabled_next_epoch<TREASURY_TESTS>(&deny_list), true);
        assert_eq(coin::deny_list_v2_is_global_pause_enabled_current_epoch<TREASURY_TESTS>(&deny_list, scenario.ctx()), paused_before);

        let expected_event_count = 1 + event::events_by_type<deny_list::PerTypeConfigCreated>().length();
        assert_eq(event::num_events() as u64, expected_event_count);
        assert_eq(event::events_by_type<treasury::Pause<TREASURY_TESTS>>().length(), 1);

        test_scenario::return_shared(deny_list);
        test_scenario::return_shared(treasury);
    }

    fun test_unpause(scenario: &mut Scenario) {
        let mut deny_list = scenario.take_shared<DenyList>();
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let paused_before = coin::deny_list_v2_is_global_pause_enabled_current_epoch<TREASURY_TESTS>(&deny_list, scenario.ctx());

        treasury.unpause(&mut deny_list, scenario.ctx());

        assert_eq(coin::deny_list_v2_is_global_pause_enabled_next_epoch<TREASURY_TESTS>(&deny_list), false);
        assert_eq(coin::deny_list_v2_is_global_pause_enabled_current_epoch<TREASURY_TESTS>(&deny_list, scenario.ctx()), paused_before);

        assert_eq(event::num_events(), 1);
        assert_eq(event::events_by_type<treasury::Unpause<TREASURY_TESTS>>().length(), 1);

        test_scenario::return_shared(deny_list);
        test_scenario::return_shared(treasury);
    }

    fun test_is_blocklisted_current_epoch(scenario: &mut Scenario, addr: address, expected: bool) {
        let deny_list = scenario.take_shared();
        let treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();

        assert_eq(coin::deny_list_v2_contains_current_epoch<TREASURY_TESTS>(&deny_list, addr, scenario.ctx()), expected);

        test_scenario::return_shared(deny_list);
        test_scenario::return_shared(treasury);
    }

    fun test_is_paused_current_epoch(scenario: &mut Scenario, expected: bool) {
        let deny_list = scenario.take_shared();
        let treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();

        assert_eq(coin::deny_list_v2_is_global_pause_enabled_current_epoch<TREASURY_TESTS>(&deny_list, scenario.ctx()), expected);

        test_scenario::return_shared(deny_list);
        test_scenario::return_shared(treasury);
    }

    fun test_update_metadata(
        name: string::String,
        symbol: ascii::String,
        description: string::String,
        url: ascii::String,
        scenario: &mut Scenario
    ) {
        let treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
        let mut metadata = scenario.take_shared<CoinMetadata<TREASURY_TESTS>>();

        treasury.update_metadata(&mut metadata, name, symbol, description, url, scenario.ctx());
        assert_eq(metadata.get_name(), name);
        assert_eq(metadata.get_symbol(), symbol);
        assert_eq(metadata.get_description(), description);
        assert_eq(metadata.get_icon_url().borrow().inner_url(), url);

        let expected_event = treasury::create_metadata_updated_event<TREASURY_TESTS>(name, symbol, description, url);
        assert_eq(event::num_events(), 1);
        assert_eq(last_event_by_type(), expected_event);

        test_scenario::return_shared(treasury);
        test_scenario::return_shared(metadata);
    }

    fun remove_treasury_cap(scenario: &Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
            
        let treasury_cap = treasury.remove_treasury_cap_for_testing();
        transfer::public_transfer(treasury_cap, MASTER_MINTER);

        test_scenario::return_shared(treasury);
    }

    fun remove_deny_cap(scenario: &Scenario) {
        let mut treasury = scenario.take_shared<Treasury<TREASURY_TESTS>>();
            
        let treasury_cap = treasury.remove_deny_cap_for_testing();
        transfer::public_transfer(treasury_cap, MASTER_MINTER);

        test_scenario::return_shared(treasury);
    }
}

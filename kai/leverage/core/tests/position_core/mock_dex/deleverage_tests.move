#[test_only]
module kai_leverage::position_core_mock_dex_deleverage_tests;

use kai_leverage::position_core_clmm;
use kai_leverage::mock_dex_integration;
use kai_leverage::position_core_mock_dex_test_setup;
use kai_leverage::position_core_deleverage_test_macros;

/* ================= create_deleverage_ticket tests ================= */

#[test, expected_failure(abort_code = 4, location = mock_dex_integration)] // e_invalid_config
fun create_deleverage_ticket_aborts_when_invalid_config() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 5, location = mock_dex_integration)] // e_invalid_pool
fun create_deleverage_ticket_aborts_when_invalid_pool() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_aborts_when_invalid_pool!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 8, location = mock_dex_integration)] // e_ticket_active
fun create_deleverage_ticket_aborts_when_ticket_active() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_aborts_when_ticket_active!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_returns_early_when_position_not_below_threshold() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_returns_early_when_position_not_below_threshold!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_is_correct_when_position_below_threshold() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_is_correct_when_position_below_threshold!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_respects_max_delta_l() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_respects_max_delta_l!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_can_repay_x_false_when_no_collateral() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_can_repay_x_false_when_no_collateral!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_can_repay_y_false_when_no_collateral() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_can_repay_y_false_when_no_collateral!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_can_repay_x_false_when_no_debt() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_can_repay_x_false_when_no_debt!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_can_repay_y_false_when_no_debt() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_can_repay_y_false_when_no_debt!(
        &mut setup,
    );
    setup.destroy();
}

/* ================= create_deleverage_ticket_for_liquidation tests ================= */

#[test, expected_failure(abort_code = 23, location = mock_dex_integration)] // e_liquidation_disabled
fun create_deleverage_ticket_for_liquidation_aborts_when_liquidation_disabled() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_aborts_when_liquidation_disabled!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = mock_dex_integration)] // e_invalid_config
fun create_deleverage_ticket_for_liquidation_aborts_when_invalid_config() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 5, location = mock_dex_integration)] // e_invalid_pool
fun create_deleverage_ticket_for_liquidation_aborts_when_invalid_pool() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_aborts_when_invalid_pool!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 8, location = mock_dex_integration)] // e_ticket_active
fun create_deleverage_ticket_for_liquidation_aborts_when_ticket_active() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_aborts_when_ticket_active!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_for_liquidation_is_correct() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_is_correct!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_for_liquidation_returns_early_when_position_not_below_threshold() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_returns_early_when_position_not_below_threshold!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_for_liquidation_can_repay_x_false_when_no_collateral() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_can_repay_x_false_when_no_collateral!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_for_liquidation_can_repay_y_false_when_no_collateral() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_can_repay_y_false_when_no_collateral!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_for_liquidation_can_repay_x_false_when_no_debt() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_can_repay_x_false_when_no_debt!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_deleverage_ticket_for_liquidation_can_repay_y_false_when_no_debt() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::create_deleverage_ticket_for_liquidation_can_repay_y_false_when_no_debt!(
        &mut setup,
    );
    setup.destroy();
}

/* ================= deleverage_ticket_repay_x tests ================= */

#[test, expected_failure(abort_code = 4, location = position_core_clmm)] // e_invalid_config
fun deleverage_ticket_repay_x_aborts_when_invalid_config() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_x_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 9, location = position_core_clmm)] // e_ticket_position_mismatch
fun deleverage_ticket_repay_x_aborts_when_position_mismatch() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_x_aborts_when_position_mismatch!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 20, location = position_core_clmm)] // e_supply_pool_mismatch
fun deleverage_ticket_repay_x_aborts_when_supply_pool_mismatch() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_x_aborts_when_supply_pool_mismatch!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun deleverage_ticket_repay_x_returns_early_when_can_repay_false() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_x_returns_early_when_can_repay_false!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun deleverage_ticket_repay_x_is_idempotent() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_x_is_idempotent!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun deleverage_ticket_repay_x_with_partial_debt_repayment() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_x_with_partial_debt_repayment!(
        &mut setup,
    );
    setup.destroy();
}

/* ================= deleverage_ticket_repay_y tests ================= */

#[test, expected_failure(abort_code = 4, location = position_core_clmm)] // e_invalid_config
fun deleverage_ticket_repay_y_aborts_when_invalid_config() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_y_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 9, location = position_core_clmm)] // e_ticket_position_mismatch
fun deleverage_ticket_repay_y_aborts_when_position_mismatch() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_y_aborts_when_position_mismatch!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 20, location = position_core_clmm)] // e_supply_pool_mismatch
fun deleverage_ticket_repay_y_aborts_when_supply_pool_mismatch() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_y_aborts_when_supply_pool_mismatch!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun deleverage_ticket_repay_y_returns_early_when_can_repay_false() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_y_returns_early_when_can_repay_false!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun deleverage_ticket_repay_y_is_idempotent() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_y_is_idempotent!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun deleverage_ticket_repay_y_with_partial_debt_repayment() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::deleverage_ticket_repay_y_with_partial_debt_repayment!(
        &mut setup,
    );
    setup.destroy();
}

/* ================= destroy_deleverage_ticket tests ================= */

#[test, expected_failure(abort_code = 9, location = position_core_clmm)] // e_ticket_position_mismatch
fun destroy_deleverage_ticket_aborts_when_position_mismatch() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::destroy_deleverage_ticket_aborts_when_position_mismatch!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 10, location = position_core_clmm)] // ETicketNotExhausted
fun destroy_deleverage_ticket_aborts_when_can_repay_x_true() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::destroy_deleverage_ticket_aborts_when_can_repay_x_true!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 10, location = position_core_clmm)] // ETicketNotExhausted
fun destroy_deleverage_ticket_aborts_when_can_repay_y_true() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_deleverage_test_macros::destroy_deleverage_ticket_aborts_when_can_repay_y_true!(
        &mut setup,
    );
    setup.destroy();
}

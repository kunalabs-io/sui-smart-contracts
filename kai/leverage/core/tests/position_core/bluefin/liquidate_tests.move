#[test_only]
module kai_leverage::position_core_bluefin_liquidate_tests;

use kai_leverage::position_core_bluefin_test_setup;
use kai_leverage::position_core_liquidate_test_macros as macros;
use kai_leverage::bluefin_spot;

/* ================= liquidate_col_x tests ================= */

#[test, expected_failure(abort_code = 4, location = bluefin_spot)] // e_invalid_config
fun liquidate_col_x_aborts_when_invalid_config() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_x_aborts_when_invalid_config!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 8, location = bluefin_spot)] // e_ticket_active
fun liquidate_col_x_aborts_when_ticket_active() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_x_aborts_when_ticket_active!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 23, location = bluefin_spot)] // e_liquidation_disabled
fun liquidate_col_x_aborts_when_liquidation_disabled() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_x_aborts_when_liquidation_disabled!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 20, location = bluefin_spot)] // e_supply_pool_mismatch
fun liquidate_col_x_aborts_when_supply_pool_mismatch() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_x_aborts_when_supply_pool_mismatch!(&mut setup);

    setup.destroy();
}

#[test]
fun liquidate_col_x_returns_zero_when_repayment_amount_is_zero() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_x_returns_zero_when_repayment_amount_is_zero!(&mut setup);

    setup.destroy();
}

#[test]
fun liquidate_col_x_is_correct() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_x_is_correct!(&mut setup);

    setup.destroy();
}

/* ================= liquidate_col_y tests ================= */

#[test, expected_failure(abort_code = 4, location = bluefin_spot)] // e_invalid_config
fun liquidate_col_y_aborts_when_invalid_config() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_y_aborts_when_invalid_config!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 8, location = bluefin_spot)] // e_ticket_active
fun liquidate_col_y_aborts_when_ticket_active() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_y_aborts_when_ticket_active!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 23, location = bluefin_spot)] // e_liquidation_disabled
fun liquidate_col_y_aborts_when_liquidation_disabled() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_y_aborts_when_liquidation_disabled!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 20, location = bluefin_spot)] // e_supply_pool_mismatch
fun liquidate_col_y_aborts_when_supply_pool_mismatch() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_y_aborts_when_supply_pool_mismatch!(&mut setup);

    setup.destroy();
}

#[test]
fun liquidate_col_y_returns_zero_when_repayment_amount_is_zero() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_y_returns_zero_when_repayment_amount_is_zero!(&mut setup);

    setup.destroy();
}

#[test]
fun liquidate_col_y_is_correct() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    macros::liquidate_col_y_is_correct!(&mut setup);

    setup.destroy();
}

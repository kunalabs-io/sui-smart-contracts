#[test_only]
module kai_leverage::position_core_cetus_repay_bad_debt_tests;

use kai_leverage::position_core_cetus_test_setup;
use kai_leverage::position_core_repay_bad_debt_test_macros as macros;
use kai_leverage::cetus;

/* ================= repay_bad_debt_x tests ================= */

#[test]
fun repay_bad_debt_x_is_correct() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_x_is_correct!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = cetus)] // e_invalid_config
fun repay_bad_debt_x_aborts_when_invalid_config() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_x_aborts_when_invalid_config!(&mut setup);

    setup.destroy();
}


#[test, expected_failure(abort_code = 8, location = cetus)] // e_ticket_active
fun repay_bad_debt_x_aborts_when_ticket_active() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_x_aborts_when_ticket_active!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 20, location = cetus)] // e_supply_pool_mismatch
fun repay_bad_debt_x_aborts_when_supply_pool_mismatch() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_x_aborts_when_supply_pool_mismatch!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 22, location = cetus)] // e_no_bad_debt_or_not_fully_liquidated
fun repay_bad_debt_x_aborts_when_position_not_fully_liquidated() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_x_aborts_when_position_not_fully_liquidated!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 22, location = cetus)] // e_position_not_below_bad_debt_threshold
fun repay_bad_debt_x_aborts_when_position_not_below_bad_debt_threshold() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_x_aborts_when_position_not_below_bad_debt_threshold!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 22, location = cetus)] // e_no_bad_debt_or_not_fully_liquidated
fun repay_bad_debt_x_aborts_when_fully_liquidated_but_no_bad_debt() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_x_aborts_when_fully_liquidated_but_no_bad_debt!(&mut setup);

    setup.destroy();
}

#[test]
fun repay_bad_debt_x_returns_early_when_no_debt() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_x_returns_early_when_no_debt!(&mut setup);

    setup.destroy();
}

/* ================= repay_bad_debt_y tests ================= */

#[test]
fun repay_bad_debt_y_is_correct() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_y_is_correct!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = cetus)] // e_invalid_config
fun repay_bad_debt_y_aborts_when_invalid_config() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_y_aborts_when_invalid_config!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 8, location = cetus)] // e_ticket_active
fun repay_bad_debt_y_aborts_when_ticket_active() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_y_aborts_when_ticket_active!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 20, location = cetus)] // e_supply_pool_mismatch
fun repay_bad_debt_y_aborts_when_supply_pool_mismatch() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_y_aborts_when_supply_pool_mismatch!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 22, location = cetus)] // e_position_not_below_bad_debt_threshold
fun repay_bad_debt_y_aborts_when_position_not_below_bad_debt_threshold() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_y_aborts_when_position_not_below_bad_debt_threshold!(&mut setup);

    setup.destroy();
}

#[test, expected_failure(abort_code = 22, location = cetus)] // e_no_bad_debt_or_not_fully_liquidated
fun repay_bad_debt_y_aborts_when_fully_liquidated_but_no_bad_debt() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_y_aborts_when_fully_liquidated_but_no_bad_debt!(&mut setup);

    setup.destroy();
}

#[test]
fun repay_bad_debt_y_returns_early_when_no_debt() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    macros::repay_bad_debt_y_returns_early_when_no_debt!(&mut setup);

    setup.destroy();
}

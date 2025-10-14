#[test_only]
module kai_leverage::position_core_cetus_create_position_tests;

use kai_leverage::cetus;
use kai_leverage::position_core_cetus_test_setup;
use kai_leverage::position_core_create_position_test_macros;

#[test, expected_failure(abort_code = 31, location = cetus)] // e_price_deviation_too_high
fun create_position_ticket_aborts_when_oracle_price_too_high() {
    let mut setup = position_core_cetus_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_oracle_price_too_high!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 31, location = cetus)] // e_price_deviation_too_high
fun create_position_ticket_aborts_when_oracle_price_too_low() {
    let mut setup = position_core_cetus_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_oracle_price_too_low!(
        &mut setup,
    );
    setup.destroy();
}

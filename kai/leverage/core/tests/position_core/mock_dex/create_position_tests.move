#[test_only]
module kai_leverage::position_core_mock_dex_create_position_tests;

use kai_leverage::mock_dex_integration;
use kai_leverage::position_core_create_position_test_macros;
use kai_leverage::position_core_mock_dex_test_setup;

#[
    test,
    expected_failure(
        abort_code = 31, // e_price_deviation_too_high
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_oracle_price_too_high() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_oracle_price_too_high!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 31, // e_price_deviation_too_high
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_oracle_price_too_low() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_oracle_price_too_low!(
        &mut setup,
    );
    setup.destroy();
}

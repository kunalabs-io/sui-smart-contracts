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

#[
    test,
    expected_failure(
        abort_code = 3, // e_new_positions_not_allowed
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_new_positions_not_allowed() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_new_positions_not_allowed!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 5, location = mock_dex_integration)] // e_invalid_pool
fun create_position_ticket_aborts_when_invalid_pool() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_invalid_pool!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 13, // e_position_size_limit_exceeded
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_position_size_limit_exceeded() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_position_size_limit_exceeded!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 14, // e_vault_global_size_limit_exceeded
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_vault_global_size_limit_exceeded() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_vault_global_size_limit_exceeded!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 0, // e_invalid_tick_range
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_tick_a_above_current_tick() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_tick_a_above_current_tick!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 0, // e_invalid_tick_range
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_tick_b_at_or_below_current_tick() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_tick_b_at_or_below_current_tick!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 1, // e_liq_margin_too_low
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_liq_margin_too_low() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_liq_margin_too_low!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 2, // e_initial_margin_too_low
        location = mock_dex_integration,
    ),
]
fun create_position_ticket_aborts_when_mint_init_margin_too_low() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_mint_init_margin_too_low!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = mock_dex_integration)] // e_invalid_config
fun borrow_for_position_x_aborts_when_invalid_config() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::borrow_for_position_x_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = mock_dex_integration)] // e_invalid_config
fun borrow_for_position_y_aborts_when_invalid_config() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::borrow_for_position_y_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun borrow_for_position_x_is_idempotent() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::borrow_for_position_x_is_idempotent!(&mut setup);
    setup.destroy();
}

#[test]
fun borrow_for_position_y_is_idempotent() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::borrow_for_position_y_is_idempotent!(&mut setup);
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 15, // e_invalid_creation_fee_amount
        location = mock_dex_integration,
    ),
]
fun create_position_aborts_when_invalid_creation_fee_amount() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_creation_fee_amount!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 6, // e_invalid_borrow
        location = mock_dex_integration,
    ),
]
fun create_position_aborts_when_invalid_borrow_x() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_borrow_x!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 6, // e_invalid_borrow
        location = mock_dex_integration,
    ),
]
fun create_position_aborts_when_invalid_borrow_y() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_borrow_y!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = mock_dex_integration)] // e_invalid_config
fun create_position_aborts_when_invalid_config() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 5, location = mock_dex_integration)] // e_invalid_pool
fun create_position_aborts_when_invalid_pool() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_pool!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_position_is_correct_when_there_is_extra_collateral() {
    let mut setup = position_core_mock_dex_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_is_correct_when_there_is_extra_collateral!(
        &mut setup,
    );
    setup.destroy();
}

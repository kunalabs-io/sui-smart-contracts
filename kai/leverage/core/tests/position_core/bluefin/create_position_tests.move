#[test_only]
module kai_leverage::position_core_bluefin_create_position_tests;

use kai_leverage::bluefin_spot;
use kai_leverage::position_core_bluefin_test_setup;
use kai_leverage::position_core_create_position_test_macros;

#[test, expected_failure(abort_code = 31, location = bluefin_spot)] // e_price_deviation_too_high
fun create_position_ticket_aborts_when_oracle_price_too_high() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_oracle_price_too_high!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 31, location = bluefin_spot)] // e_price_deviation_too_high
fun create_position_ticket_aborts_when_oracle_price_too_low() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_oracle_price_too_low!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 3, location = bluefin_spot)] // e_new_positions_not_allowed
fun create_position_ticket_aborts_when_new_positions_not_allowed() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_new_positions_not_allowed!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 5, location = bluefin_spot)] // e_new_positions_not_allowed
fun create_position_ticket_aborts_when_invalid_pool() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_invalid_pool!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 13,
        location = bluefin_spot,
    ),
] // e_position_size_limit_exceeded
fun create_position_ticket_aborts_when_position_size_limit_exceeded() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_position_size_limit_exceeded!(
        &mut setup,
    );
    setup.destroy();
}

#[
    test,
    expected_failure(
        abort_code = 14,
        location = bluefin_spot,
    ),
] // e_vault_global_size_limit_exceeded
fun create_position_ticket_aborts_when_vault_global_size_limit_exceeded() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_vault_global_size_limit_exceeded!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 0, location = bluefin_spot)] // e_invalid_tick_range
fun create_position_ticket_aborts_when_tick_a_above_current_tick() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_tick_a_above_current_tick!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 0, location = bluefin_spot)] // e_invalid_tick_range
fun create_position_ticket_aborts_when_tick_b_at_or_below_current_tick() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_tick_b_at_or_below_current_tick!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 1, location = bluefin_spot)] // e_liq_margin_too_low
fun create_position_ticket_aborts_when_liq_margin_too_low() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_liq_margin_too_low!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 2, location = bluefin_spot)] // e_initial_margin_too_low
fun create_position_ticket_aborts_when_mint_init_margin_too_low() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_ticket_aborts_when_mint_init_margin_too_low!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = bluefin_spot)] // e_invalid_config
fun borrow_for_position_x_aborts_when_invalid_config() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::borrow_for_position_x_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = bluefin_spot)] // e_invalid_config
fun borrow_for_position_y_aborts_when_invalid_config() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::borrow_for_position_y_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun borrow_for_position_x_is_idempotent() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::borrow_for_position_x_is_idempotent!(&mut setup);
    setup.destroy();
}

#[test]
fun borrow_for_position_y_is_idempotent() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::borrow_for_position_y_is_idempotent!(&mut setup);
    setup.destroy();
}

#[test, expected_failure(abort_code = 15, location = bluefin_spot)] // e_invalid_creation_fee_amount
fun create_position_aborts_when_invalid_creation_fee_amount() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_creation_fee_amount!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 6, location = bluefin_spot)] // e_invalid_borrow
fun create_position_aborts_when_invalid_borrow_x() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_borrow_x!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 6, location = bluefin_spot)] // e_invalid_borrow
fun create_position_aborts_when_invalid_borrow_y() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_borrow_y!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 4, location = bluefin_spot)] // e_invalid_config
fun create_position_aborts_when_invalid_config() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_config!(
        &mut setup,
    );
    setup.destroy();
}

#[test, expected_failure(abort_code = 5, location = bluefin_spot)] // e_invalid_pool
fun create_position_aborts_when_invalid_pool() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_aborts_when_invalid_pool!(
        &mut setup,
    );
    setup.destroy();
}

#[test]
fun create_position_is_correct_when_there_is_extra_collateral() {
    let mut setup = position_core_bluefin_test_setup::new_setup();
    position_core_create_position_test_macros::create_position_is_correct_when_there_is_extra_collateral!(
        &mut setup,
    );
    setup.destroy();
}

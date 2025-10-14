#[test_only]
module kai_leverage::position_core_bluefin_liquidate_standard_flow_tests;

use kai_leverage::position_core_bluefin_test_setup;
use kai_leverage::position_core_liquidate_standard_flow_test_macros as macros;
use sui::test_utils::destroy;

#[test]
fun liquidate_col_x_standard_flow_is_correct() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    let position_cap = macros::liquidate_col_x_standard_flow!(&mut setup);
    destroy(position_cap);

    setup.destroy();
}

#[test]
fun liquidate_col_y_standard_flow_is_correct() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    let position_cap = macros::liquidate_col_y_standard_flow!(&mut setup);
    destroy(position_cap);

    setup.destroy();
}


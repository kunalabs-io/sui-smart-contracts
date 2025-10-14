#[test_only]
module kai_leverage::position_core_cetus_deleverage_standard_flow_tests;

use kai_leverage::position_core_cetus_test_setup;
use kai_leverage::position_core_deleverage_standard_flow_test_macros as macros;
use sui::test_utils::destroy;

#[test]
fun deleverage_with_ticket_standard_flow_is_correct() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    let position_cap = macros::deleverage_with_ticket_standard_flow!(&mut setup);
    destroy(position_cap);

    setup.destroy();
}

#[test]
fun deleverage_helper_standard_flow_is_correct() {
    let mut setup = position_core_cetus_test_setup::new_setup();

    let position_cap = macros::deleverage_helper_standard_flow!(&mut setup);
    destroy(position_cap);

    setup.destroy();
}

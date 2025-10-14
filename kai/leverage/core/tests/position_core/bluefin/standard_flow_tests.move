#[test_only]
module kai_leverage::position_core_bluefin_standard_flow_tests;

use kai_leverage::position_core_bluefin_test_setup;
use kai_leverage::position_core_standard_flow_test_macros as macros;

#[test]
fun standard_flow_is_correct() {
    let mut setup = position_core_bluefin_test_setup::new_setup();

    let position_cap = macros::create_position!(&mut setup);

    let (
        exp_rebalance_fee_x,
        exp_rebalance_fee_y,
        exp_rebalance_reward_fee_sui,
        position_sx_after_rebalance,
        position_sy_after_rebalance,
    ) = macros::rebalance!(&mut setup);

    macros::collect_protocol_fees!(
        &mut setup,
        exp_rebalance_fee_x,
        exp_rebalance_fee_y,
        exp_rebalance_reward_fee_sui,
    );

    let (
        position_sx_after_repay_debt,
        position_sy_after_repay_debt,
    ) = macros::owner_repay_debt_and_add_collateral!(
        &mut setup,
        &position_cap,
        position_sx_after_rebalance,
        position_sy_after_rebalance,
    );

    let (
        exp_protocol_fee_x,
        exp_protocol_fee_y,
        exp_protocol_reward_fee_sui,
    ) = macros::close_position!(
        &mut setup,
        position_cap,
        position_sx_after_repay_debt,
        position_sy_after_repay_debt,
    );

    macros::collect_deleted_position_fees!(
        &mut setup,
        exp_protocol_fee_x + exp_protocol_reward_fee_sui,
        exp_protocol_fee_y,
    );

    setup.destroy();
}


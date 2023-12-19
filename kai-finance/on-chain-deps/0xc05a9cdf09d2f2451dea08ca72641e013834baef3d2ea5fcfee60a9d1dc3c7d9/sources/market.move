module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market {

    use 0x1::type_name;
    use sui::balance;
    use sui::coin;
    use sui::object;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ac_table;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::witness;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::accrue_interest;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::app;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::asset_active_state;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow_dynamics;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::collateral_stats;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::deposit_collateral;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::flash_loan;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::incentive_rewards;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::interest_model;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::limiter;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::liquidate;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::mint;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::redeem;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::repay;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::reserve;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::risk_model;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::withdraw_collateral;

    friend accrue_interest;
    friend app;
    friend borrow;
    friend deposit_collateral;
    friend flash_loan;
    friend liquidate;
    friend mint;
    friend redeem;
    friend repay;
    friend withdraw_collateral;

    struct Market has store, key {
        id: object::UID,
        borrow_dynamics: wit_table::WitTable<borrow_dynamics::BorrowDynamics, type_name::TypeName, borrow_dynamics::BorrowDynamic>,
        collateral_stats: wit_table::WitTable<collateral_stats::CollateralStats, type_name::TypeName, collateral_stats::CollateralStat>,
        interest_models: ac_table::AcTable<interest_model::InterestModels, type_name::TypeName, interest_model::InterestModel>,
        risk_models: ac_table::AcTable<risk_model::RiskModels, type_name::TypeName, risk_model::RiskModel>,
        limiters: wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>,
        reward_factors: wit_table::WitTable<incentive_rewards::RewardFactors, type_name::TypeName, incentive_rewards::RewardFactor>,
        asset_active_states: asset_active_state::AssetActiveStates,
        vault: reserve::Reserve,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun uid(a0: &market::Market): &object::UID;
 #[native_interface]
    native public fun uid_mut_delegated(a0: &mut market::Market, a1: witness::Witness<market::Market>): &mut object::UID;
 #[native_interface]
    native public(friend) fun uid_mut(a0: &mut market::Market): &mut object::UID;
 #[native_interface]
    native public fun borrow_dynamics(a0: &market::Market): &wit_table::WitTable<borrow_dynamics::BorrowDynamics, type_name::TypeName, borrow_dynamics::BorrowDynamic>;
 #[native_interface]
    native public fun interest_models(a0: &market::Market): &ac_table::AcTable<interest_model::InterestModels, type_name::TypeName, interest_model::InterestModel>;
 #[native_interface]
    native public fun vault(a0: &market::Market): &reserve::Reserve;
 #[native_interface]
    native public fun risk_models(a0: &market::Market): &ac_table::AcTable<risk_model::RiskModels, type_name::TypeName, risk_model::RiskModel>;
 #[native_interface]
    native public fun reward_factors(a0: &market::Market): &wit_table::WitTable<incentive_rewards::RewardFactors, type_name::TypeName, incentive_rewards::RewardFactor>;
 #[native_interface]
    native public fun collateral_stats(a0: &market::Market): &wit_table::WitTable<collateral_stats::CollateralStats, type_name::TypeName, collateral_stats::CollateralStat>;
 #[native_interface]
    native public fun borrow_index(a0: &market::Market, a1: type_name::TypeName): u64;
 #[native_interface]
    native public fun interest_model(a0: &market::Market, a1: type_name::TypeName): &interest_model::InterestModel;
 #[native_interface]
    native public fun risk_model(a0: &market::Market, a1: type_name::TypeName): &risk_model::RiskModel;
 #[native_interface]
    native public fun reward_factor(a0: &market::Market, a1: type_name::TypeName): &incentive_rewards::RewardFactor;
 #[native_interface]
    native public fun has_risk_model(a0: &market::Market, a1: type_name::TypeName): bool;
 #[native_interface]
    native public fun has_limiter(a0: &market::Market, a1: type_name::TypeName): bool;
 #[native_interface]
    native public fun is_base_asset_active(a0: &market::Market, a1: type_name::TypeName): bool;
 #[native_interface]
    native public fun is_collateral_active(a0: &market::Market, a1: type_name::TypeName): bool;
 #[native_interface]
    native public(friend) fun new(a0: &mut tx_context::TxContext): (market::Market, ac_table::AcTableCap<interest_model::InterestModels>, ac_table::AcTableCap<risk_model::RiskModels>);
 #[native_interface]
    native public(friend) fun handle_outflow<T0>(a0: &mut market::Market, a1: u64, a2: u64);
 #[native_interface]
    native public(friend) fun handle_inflow<T0>(a0: &mut market::Market, a1: u64, a2: u64);
 #[native_interface]
    native public(friend) fun set_base_asset_active_state<T0>(a0: &mut market::Market, a1: bool);
 #[native_interface]
    native public(friend) fun set_collateral_active_state<T0>(a0: &mut market::Market, a1: bool);
 #[native_interface]
    native public(friend) fun register_coin<T0>(a0: &mut market::Market, a1: u64);
 #[native_interface]
    native public(friend) fun register_collateral<T0>(a0: &mut market::Market);
 #[native_interface]
    native public(friend) fun set_flash_loan_fee<T0>(a0: &mut market::Market, a1: u64);
 #[native_interface]
    native public(friend) fun risk_models_mut(a0: &mut market::Market): &mut ac_table::AcTable<risk_model::RiskModels, type_name::TypeName, risk_model::RiskModel>;
 #[native_interface]
    native public(friend) fun interest_models_mut(a0: &mut market::Market): &mut ac_table::AcTable<interest_model::InterestModels, type_name::TypeName, interest_model::InterestModel>;
 #[native_interface]
    native public(friend) fun rate_limiter_mut(a0: &mut market::Market): &mut wit_table::WitTable<limiter::Limiters, type_name::TypeName, limiter::Limiter>;
 #[native_interface]
    native public(friend) fun reward_factors_mut(a0: &mut market::Market): &mut wit_table::WitTable<incentive_rewards::RewardFactors, type_name::TypeName, incentive_rewards::RewardFactor>;
 #[native_interface]
    native public(friend) fun handle_borrow<T0>(a0: &mut market::Market, a1: u64, a2: u64): balance::Balance<T0>;
 #[native_interface]
    native public(friend) fun handle_repay<T0>(a0: &mut market::Market, a1: balance::Balance<T0>);
 #[native_interface]
    native public(friend) fun handle_add_collateral<T0>(a0: &mut market::Market, a1: u64);
 #[native_interface]
    native public(friend) fun handle_withdraw_collateral<T0>(a0: &mut market::Market, a1: u64, a2: u64);
 #[native_interface]
    native public(friend) fun handle_liquidation<T0, T1>(a0: &mut market::Market, a1: balance::Balance<T0>, a2: balance::Balance<T0>, a3: u64);
 #[native_interface]
    native public(friend) fun handle_redeem<T0>(a0: &mut market::Market, a1: balance::Balance<reserve::MarketCoin<T0>>, a2: u64): balance::Balance<T0>;
 #[native_interface]
    native public(friend) fun handle_mint<T0>(a0: &mut market::Market, a1: balance::Balance<T0>, a2: u64): balance::Balance<reserve::MarketCoin<T0>>;
 #[native_interface]
    native public(friend) fun borrow_flash_loan<T0>(a0: &mut market::Market, a1: u64, a2: &mut tx_context::TxContext): (coin::Coin<T0>, reserve::FlashLoan<T0>);
 #[native_interface]
    native public(friend) fun repay_flash_loan<T0>(a0: &mut market::Market, a1: coin::Coin<T0>, a2: reserve::FlashLoan<T0>);
 #[native_interface]
    native public(friend) fun compound_interests(a0: &mut market::Market, a1: u64);
 #[native_interface]
    native public(friend) fun take_revenue<T0>(a0: &mut market::Market, a1: u64, a2: &mut tx_context::TxContext): coin::Coin<T0>;
 #[native_interface]
    native public(friend) fun accrue_all_interests(a0: &mut market::Market, a1: u64);

}

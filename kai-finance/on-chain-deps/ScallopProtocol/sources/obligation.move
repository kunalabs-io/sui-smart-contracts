module 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation {

    use 0x1::option;
    use 0x1::type_name;
    use sui::balance;
    use sui::object;
    use sui::tx_context;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::balance_bag;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::ownership;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::wit_table;
    use 0x779B5C547976899F5474F3A5BC0DB36DDF4697AD7E5A901DB0415C2281D28162::witness;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::accrue_interest;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::borrow;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::deposit_collateral;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::liquidate;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::lock_obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::market;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation_access;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation_collaterals;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::obligation_debts;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::open_obligation;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::repay;
    use 0xEFE8B36D5B2E43728CC323298626B83177803521D195CFB11E15B910E892FDDF::withdraw_collateral;

    friend accrue_interest;
    friend borrow;
    friend deposit_collateral;
    friend liquidate;
    friend lock_obligation;
    friend open_obligation;
    friend repay;
    friend withdraw_collateral;

    struct Obligation has store, key {
        id: object::UID,
        balances: balance_bag::BalanceBag,
        debts: wit_table::WitTable<obligation_debts::ObligationDebts, type_name::TypeName, obligation_debts::Debt>,
        collaterals: wit_table::WitTable<obligation_collaterals::ObligationCollaterals, type_name::TypeName, obligation_collaterals::Collateral>,
        rewards_point: u64,
        lock_key: option::Option<type_name::TypeName>,
        borrow_locked: bool,
        repay_locked: bool,
        deposit_collateral_locked: bool,
        withdraw_collateral_locked: bool,
        liquidate_locked: bool,
    }
    struct ObligationOwnership has drop {
        dummy_field: bool,
    }
    struct ObligationKey has store, key {
        id: object::UID,
        ownership: ownership::Ownership<obligation::ObligationOwnership>,
    }
    struct ObligationRewardsPointRedeemed has copy, drop {
        obligation: object::ID,
        witness: type_name::TypeName,
        amount: u64,
    }
    struct ObligationLocked has copy, drop {
        obligation: object::ID,
        witness: type_name::TypeName,
        borrow_locked: bool,
        repay_locked: bool,
        deposit_collateral_locked: bool,
        withdraw_collateral_locked: bool,
        liquidate_locked: bool,
    }
    struct ObligationUnlocked has copy, drop {
        obligation: object::ID,
        witness: type_name::TypeName,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
 #[native_interface]
    native public fun obligation_key_uid(a0: &obligation::ObligationKey, a1: witness::Witness<obligation::ObligationKey>): &object::UID;
 #[native_interface]
    native public fun obligation_key_uid_mut_delegated(a0: &mut obligation::ObligationKey, a1: witness::Witness<obligation::ObligationKey>): &mut object::UID;
 #[native_interface]
    native public fun obligation_uid(a0: &obligation::Obligation, a1: witness::Witness<obligation::Obligation>): &object::UID;
 #[native_interface]
    native public fun obligation_uid_mut_delegated(a0: &mut obligation::Obligation, a1: witness::Witness<obligation::Obligation>): &mut object::UID;
 #[native_interface]
    native public(friend) fun new(a0: &mut tx_context::TxContext): (obligation::Obligation, obligation::ObligationKey);
 #[native_interface]
    native public fun assert_key_match(a0: &obligation::Obligation, a1: &obligation::ObligationKey);
 #[native_interface]
    native public fun is_key_match(a0: &obligation::Obligation, a1: &obligation::ObligationKey): bool;
 #[native_interface]
    native public(friend) fun accrue_interests_and_rewards(a0: &mut obligation::Obligation, a1: &market::Market);
 #[native_interface]
    native public(friend) fun withdraw_collateral<T0>(a0: &mut obligation::Obligation, a1: u64): balance::Balance<T0>;
 #[native_interface]
    native public(friend) fun deposit_collateral<T0>(a0: &mut obligation::Obligation, a1: balance::Balance<T0>);
 #[native_interface]
    native public(friend) fun init_debt(a0: &mut obligation::Obligation, a1: &market::Market, a2: type_name::TypeName);
 #[native_interface]
    native public(friend) fun increase_debt(a0: &mut obligation::Obligation, a1: type_name::TypeName, a2: u64);
 #[native_interface]
    native public(friend) fun decrease_debt(a0: &mut obligation::Obligation, a1: type_name::TypeName, a2: u64);
 #[native_interface]
    native public fun has_coin_x_as_debt(a0: &obligation::Obligation, a1: type_name::TypeName): bool;
 #[native_interface]
    native public fun debt(a0: &obligation::Obligation, a1: type_name::TypeName): (u64, u64);
 #[native_interface]
    native public fun has_coin_x_as_collateral(a0: &obligation::Obligation, a1: type_name::TypeName): bool;
 #[native_interface]
    native public fun collateral(a0: &obligation::Obligation, a1: type_name::TypeName): u64;
 #[native_interface]
    native public fun debt_types(a0: &obligation::Obligation): vector<type_name::TypeName>;
 #[native_interface]
    native public fun collateral_types(a0: &obligation::Obligation): vector<type_name::TypeName>;
 #[native_interface]
    native public fun balance_bag(a0: &obligation::Obligation): &balance_bag::BalanceBag;
 #[native_interface]
    native public fun debts(a0: &obligation::Obligation): &wit_table::WitTable<obligation_debts::ObligationDebts, type_name::TypeName, obligation_debts::Debt>;
 #[native_interface]
    native public fun collaterals(a0: &obligation::Obligation): &wit_table::WitTable<obligation_collaterals::ObligationCollaterals, type_name::TypeName, obligation_collaterals::Collateral>;
 #[native_interface]
    native public fun rewards_point(a0: &obligation::Obligation): u64;
 #[native_interface]
    native public fun borrow_locked(a0: &obligation::Obligation): bool;
 #[native_interface]
    native public fun repay_locked(a0: &obligation::Obligation): bool;
 #[native_interface]
    native public fun withdraw_collateral_locked(a0: &obligation::Obligation): bool;
 #[native_interface]
    native public fun deposit_collateral_locked(a0: &obligation::Obligation): bool;
 #[native_interface]
    native public fun liquidate_locked(a0: &obligation::Obligation): bool;
 #[native_interface]
    native public fun lock_key(a0: &obligation::Obligation): option::Option<type_name::TypeName>;
 #[native_interface]
    native public fun lock<T0: drop>(a0: &mut obligation::Obligation, a1: &obligation::ObligationKey, a2: &obligation_access::ObligationAccessStore, a3: bool, a4: bool, a5: bool, a6: bool, a7: bool, a8: T0);
 #[native_interface]
    native public fun unlock<T0: drop>(a0: &mut obligation::Obligation, a1: &obligation::ObligationKey, a2: T0);
 #[native_interface]
    native public(friend) fun set_lock<T0: drop>(a0: &mut obligation::Obligation, a1: &obligation_access::ObligationAccessStore, a2: bool, a3: bool, a4: bool, a5: bool, a6: bool, a7: T0);
 #[native_interface]
    native public(friend) fun set_unlock<T0: drop>(a0: &mut obligation::Obligation, a1: T0);
 #[native_interface]
    native public fun redeem_rewards_point<T0: drop>(a0: &mut obligation::Obligation, a1: &obligation::ObligationKey, a2: &obligation_access::ObligationAccessStore, a3: T0, a4: u64);

}

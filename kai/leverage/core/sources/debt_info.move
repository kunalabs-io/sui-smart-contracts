module kai_leverage::debt_info;

use kai_leverage::debt::DebtRegistry;
use kai_leverage::supply_pool::SupplyPool;
use kai_leverage::util;
use std::type_name::{Self, TypeName};
use sui::clock::Clock;
use sui::vec_map::{Self, VecMap};

const Q64: u128 = 1 << 64;

const EInvalidFacilID: u64 = 0;

public struct DebtInfoEntry has copy, store, drop {
    supply_x64: u128,
    liability_value_x64: u128,
}

public struct DebtInfo has copy, drop {
    facil_id: ID,
    map: VecMap<TypeName, DebtInfoEntry>,
}

public struct ValidatedDebtInfo has copy, drop {
    map: VecMap<TypeName, DebtInfoEntry>,
}

public fun empty(facil_id: ID): DebtInfo {
    DebtInfo { facil_id, map: vec_map::empty() }
}

public fun facil_id(self: &DebtInfo): ID {
    self.facil_id
}

public fun add<ST>(self: &mut DebtInfo, registry: &DebtRegistry<ST>) {
    let entry = DebtInfoEntry {
        supply_x64: registry.supply_x64(),
        liability_value_x64: registry.liability_value_x64(),
    };
    self.map.insert(type_name::get<ST>(), entry);
}

public fun add_from_supply_pool<T, ST>(
    self: &mut DebtInfo,
    pool: &mut SupplyPool<T, ST>,
    clock: &Clock,
) {
    let facil_id = self.facil_id;
    let registry = pool.borrow_debt_registry(&facil_id, clock);
    add(self, registry);
}

public fun validate(self: &DebtInfo, facil_id: ID): ValidatedDebtInfo {
    assert!(self.facil_id == facil_id, EInvalidFacilID);
    ValidatedDebtInfo { map: self.map }
}

// Same as `debt::calc_repay_x64`
fun calc_repay_x64(self: &ValidatedDebtInfo, `type`: TypeName, share_value_x64: u128): u128 {
    let entry = &self.map[&`type`];
    util::muldiv_round_up_u128(
        entry.liability_value_x64,
        share_value_x64,
        entry.supply_x64,
    )
}

// Same as `debt::calc_repay_lossy`
fun calc_repay_lossy(self: &ValidatedDebtInfo, `type`: TypeName, share_value_x64: u128): u64 {
    let value_x64 = calc_repay_x64(self, `type`, share_value_x64);
    util::divide_and_round_up_u128(value_x64, Q64) as u64
}

// Same as `debt::calc_repay_for_amount`
fun calc_repay_for_amount(self: &ValidatedDebtInfo, `type`: TypeName, amount: u64): u128 {
    let entry = &self.map[&`type`];
    util::muldiv_u128(
        (amount as u128) * Q64,
        entry.supply_x64,
        entry.liability_value_x64,
    )
}

/// Calculates the debt amount that needs to be repaid for the given amount of debt shares.
public fun calc_repay_by_shares(
    self: &ValidatedDebtInfo,
    `type`: TypeName,
    share_value_x64: u128,
): u64 {
    calc_repay_lossy(self, `type`, share_value_x64)
}

/// Calculates the debt share amount required to repay the given amount of debt.
public fun calc_repay_by_amount(self: &ValidatedDebtInfo, `type`: TypeName, amount: u64): u128 {
    calc_repay_for_amount(self, `type`, amount)
}

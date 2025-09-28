// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Collection for managing heterogeneous token balances.
/// 
/// This module provides a type-safe collection that can store balances for multiple
/// coin types simultaneously. It's commonly used in scenarios where a single entity
/// needs to hold and manage various token types, such as collateral management in
/// lending protocols or multi-asset treasury systems.
/// 
/// Key properties:
/// - Maintains summary information for efficient queries
/// - Supports partial and full withdrawals by token type
/// - Automatically handles zero-balance cleanup
module kai_leverage::balance_bag;

use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};
use sui::balance::{Self, Balance};
use sui::vec_map::{Self, VecMap};

/// Collection that stores balances for multiple coin types.
public struct BalanceBag has key, store {
    id: UID,
    amounts: VecMap<TypeName, u64>,
    inner: Bag,
}

/// Create an empty `BalanceBag`.
public fun empty(ctx: &mut TxContext): BalanceBag {
    BalanceBag {
        id: object::new(ctx),
        amounts: vec_map::empty(),
        inner: bag::new(ctx),
    }
}

/// Get a read-only map of amounts per coin type.
public fun amounts(self: &BalanceBag): &VecMap<TypeName, u64> {
    &self.amounts
}

/// Add a `Balance<T>` to the bag, joining with existing balance if present.
public fun add<T>(self: &mut BalanceBag, balance: Balance<T>) {
    let `type` = type_name::with_defining_ids<T>();
    if (balance.value() == 0) {
        balance::destroy_zero(balance);
        return
    };

    if (self.amounts.contains(&`type`)) {
        let bag_balance = &mut self.inner[`type`];
        let balance_amount = balance.value();
        balance::join(bag_balance, balance);

        let amount = &mut self.amounts[&`type`];
        *amount = *amount + balance_amount
    } else {
        vec_map::insert(&mut self.amounts, `type`, balance.value());
        bag::add(&mut self.inner, `type`, balance);
    }
}

/// Remove and return the entire `Balance<T>` for type `T`. Returns zero if absent.
public fun take_all<T>(self: &mut BalanceBag): Balance<T> {
    let `type` = type_name::with_defining_ids<T>();
    if (!self.amounts.contains(&`type`)) {
        return balance::zero()
    };

    let balance = self.inner.remove(`type`);
    self.amounts.remove(&`type`);

    balance
}

/// Remove and return `amount` of `Balance<T>`. Returns zero if `amount` is 0.
public fun take_amount<T>(self: &mut BalanceBag, amount: u64): Balance<T> {
    if (amount == 0) {
        return balance::zero()
    };
    let `type` = type_name::with_defining_ids<T>();

    let inner_amount = vec_map::get_mut(&mut self.amounts, &`type`);
    if (*inner_amount == amount) {
        let balance = self.inner.remove(`type`);
        self.amounts.remove(&`type`);
        return balance
    };

    let bag_balance = &mut self.inner[`type`];
    let balance = balance::split(bag_balance, amount);
    *inner_amount = *inner_amount - amount;

    balance
}

/// True if the bag contains no balances.
public fun is_empty(self: &BalanceBag): bool {
    // amounts is empty iff. bag is empty, but let's be explicit
    self.amounts.is_empty() && self.inner.is_empty()
}

/// Destroy an empty bag.
public fun destroy_empty(self: BalanceBag) {
    let BalanceBag { id, amounts, inner } = self;
    object::delete(id);
    amounts.destroy_empty();
    inner.destroy_empty();
}

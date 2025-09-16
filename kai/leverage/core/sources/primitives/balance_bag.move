// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

module kai_leverage::balance_bag;

use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};
use sui::balance::{Self, Balance};
use sui::vec_map::{Self, VecMap};

public struct BalanceBag has key, store {
    id: UID,
    amounts: VecMap<TypeName, u64>,
    inner: Bag,
}

public fun empty(ctx: &mut TxContext): BalanceBag {
    BalanceBag {
        id: object::new(ctx),
        amounts: vec_map::empty(),
        inner: bag::new(ctx),
    }
}

public fun amounts(self: &BalanceBag): &VecMap<TypeName, u64> {
    &self.amounts
}

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

public fun take_all<T>(self: &mut BalanceBag): Balance<T> {
    let `type` = type_name::with_defining_ids<T>();
    if (!self.amounts.contains(&`type`)) {
        return balance::zero()
    };

    let balance = self.inner.remove(`type`);
    self.amounts.remove(&`type`);

    balance
}

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

public fun is_empty(self: &BalanceBag): bool {
    // amounts is empty iff. bag is empty, but let's be explicit
    self.amounts.is_empty() && self.inner.is_empty()
}

public fun destroy_empty(self: BalanceBag) {
    let BalanceBag { id, amounts, inner } = self;
    object::delete(id);
    amounts.destroy_empty();
    inner.destroy_empty();
}

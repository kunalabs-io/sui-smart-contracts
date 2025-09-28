// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Collection for managing heterogeneous debt share balances.
/// 
/// This module provides a type-safe collection that can store debt shares for multiple
/// asset types and share types simultaneously. It enforces a one-to-one mapping between
/// asset types and their corresponding share types: for any asset type `T`, there can be
/// only a single associated debt share type `ST`, and vice versa. This ensures type-level
/// consistency and prevents ambiguous or conflicting associations between assets and shares.
/// 
/// Key properties:
/// - Enforces a unique mapping between each asset type and its share type (bijective mapping)
/// - Validates type consistency to prevent mismatched operations  
/// - Supports partial and full withdrawals by share type
/// - Tracks total amounts for efficient queries
module kai_leverage::debt_bag;

use kai_leverage::debt::{Self, DebtShareBalance};
use std::type_name::{Self, TypeName};
use sui::bag::{Self, Bag};

const EAssetShareTypeMismatch: u64 = 0;
/// The requested asset or share type does not exist in the debt bag.
const ETypeDoesNotExist: u64 = 1;

const ENotEnough: u64 = 2;

/// Internal info about shares stored per asset/share type.
public struct Info has store {
    asset_type: TypeName,
    share_type: TypeName,
    amount: u128,
}

/// Collection of debt shares for multiple facilities and share types.
public struct DebtBag has key, store {
    id: UID,
    infos: vector<Info>,
    bag: Bag,
}

public struct Key has copy, drop, store {
    t: TypeName,
    st: TypeName,
}

/* ================= DebtBag ================= */

/// Create an empty `DebtBag`.
public fun empty(ctx: &mut TxContext): DebtBag {
    DebtBag {
        id: object::new(ctx),
        infos: vector::empty(),
        bag: bag::new(ctx),
    }
}

fun get_asset_idx_opt(self: &DebtBag, asset_type: &TypeName): Option<u64> {
    let mut i = 0;
    let n = vector::length(&self.infos);
    while (i < n) {
        let info = &self.infos[i];
        if (&info.asset_type == asset_type) {
            return option::some(i)
        };
        i = i + 1;
    };
    option::none()
}

fun get_share_idx_opt(self: &DebtBag, share_type: &TypeName): Option<u64> {
    let mut i = 0;
    let n = self.infos.length();
    while (i < n) {
        let info = &self.infos[i];
        if (&info.share_type == share_type) {
            return option::some(i)
        };
        i = i + 1;
    };
    option::none()
}

fun get_share_idx(self: &DebtBag, share_type: &TypeName): u64 {
    let idx_opt = get_share_idx_opt(self, share_type);
    assert!(option::is_some(&idx_opt), ETypeDoesNotExist);
    idx_opt.destroy_some()
}

fun key(info: &Info): Key {
    Key {
        t: info.asset_type,
        st: info.share_type,
    }
}

/// Add `DebtShareBalance<ST>` for asset `T`, merging with existing entry when present.
/// 
/// Guarantees:
/// - Enforces bijective mapping between asset type `T` and share type `ST`
/// - Merges with existing shares if asset exists, creates new entry otherwise
/// - Automatically destroys zero-value shares
/// - Maintains synchronized state between `infos` vector and `bag` storage
/// - Aborts with `EAssetShareTypeMismatch` if share type conflicts with existing asset
public fun add<T, ST>(self: &mut DebtBag, shares: DebtShareBalance<ST>) {
    let asset_type = type_name::with_defining_ids<T>();
    let share_type = type_name::with_defining_ids<ST>();
    if (shares.value_x64() == 0) {
        shares.destroy_zero();
        return
    };
    let key = Key { t: asset_type, st: share_type };

    let idx_opt = get_asset_idx_opt(self, &asset_type);
    if (idx_opt.is_some()) {
        let idx = idx_opt.destroy_some();
        let info = &mut self.infos[idx];
        assert!(info.share_type == share_type, EAssetShareTypeMismatch);

        info.amount = info.amount + shares.value_x64();
        debt::join(&mut self.bag[key], shares);
    } else {
        // ensure that the share type is unique
        let mut i = 0;
        let n = self.infos.length();
        while (i < n) {
            let info = &self.infos[i];
            assert!(info.share_type != share_type, EAssetShareTypeMismatch);
            i = i + 1;
        };

        let info = Info {
            asset_type,
            share_type,
            amount: shares.value_x64(),
        };
        self.infos.push_back(info);

        bag::add(&mut self.bag, key, shares);
    };
}

/// Take `amount` of shares of type `ST` from the bag. Returns zero if `amount` is 0.
public fun take_amt<ST>(self: &mut DebtBag, amount: u128): DebtShareBalance<ST> {
    if (amount == 0) {
        return debt::zero()
    };
    let type_st = type_name::with_defining_ids<ST>();

    let idx = get_share_idx(self, &type_st);
    let info = &mut self.infos[idx];
    assert!(amount <= info.amount, ENotEnough);

    let key = key(info);
    let shares = debt::split_x64(&mut self.bag[key], amount);
    info.amount = info.amount - amount;

    if (info.amount == 0) {
        let Info { asset_type: _, share_type: _, amount: _ } = self.infos.remove(idx);
        let zero = self.bag.remove(key);
        debt::destroy_zero<ST>(zero);
    };

    shares
}

/// Remove and return all shares of type `ST`. Returns zero if not present.
public fun take_all<ST>(self: &mut DebtBag): DebtShareBalance<ST> {
    let type_st = type_name::with_defining_ids<ST>();

    let idx_opt = get_share_idx_opt(self, &type_st);
    if (idx_opt.is_none()) {
        return debt::zero()
    };
    let idx = idx_opt.destroy_some();

    let key = key(&self.infos[idx]);
    let Info { asset_type: _, share_type: _, amount: _ } = self.infos.remove(idx);
    let shares = self.bag.remove(key);

    shares
}

/// Total shares amount for the given asset type `T`.
public fun get_share_amount_by_asset_type<T>(self: &DebtBag): u128 {
    let asset_type = type_name::with_defining_ids<T>();
    let idx_opt = get_asset_idx_opt(self, &asset_type);
    if (idx_opt.is_none()) {
        return 0
    } else {
        let idx = idx_opt.destroy_some();
        let info = &self.infos[idx];
        info.amount
    }
}

/// Total shares amount for the given share type `ST`.
public fun get_share_amount_by_share_type<ST>(debt_bag: &DebtBag): u128 {
    let share_type = type_name::with_defining_ids<ST>();
    let idx_opt = get_share_idx_opt(debt_bag, &share_type);
    if (idx_opt.is_none()) {
        return 0
    } else {
        let idx = idx_opt.destroy_some();
        let info = &debt_bag.infos[idx];
        info.amount
    }
}

/// Get the share type corresponding to asset type `T`. Aborts if none.
public fun get_share_type_for_asset<T>(self: &DebtBag): TypeName {
    let asset_type = type_name::with_defining_ids<T>();
    let idx_opt = get_asset_idx_opt(self, &asset_type);
    assert!(idx_opt.is_some(), ETypeDoesNotExist);
    let idx = idx_opt.destroy_some();
    let info = &self.infos[idx];
    info.share_type
}

/// Returns true if either:
/// - Neither the asset type `T` nor the share type `ST` exist in the `DebtBag`, or
/// - Both exist and the share type corresponds to the asset type.
/// Returns false if only one exists, or if both exist but the share type
/// does not correspond to the asset type.
public fun share_type_matches_asset_if_any_exists<T, ST>(self: &DebtBag): bool {
    let asset_type = type_name::with_defining_ids<T>();
    let share_type = type_name::with_defining_ids<ST>();

    let mut i = 0;
    let n = self.infos.length();
    while (i < n) {
        let info = &self.infos[i];
        if (info.asset_type == asset_type || info.share_type == share_type) {
            return info.asset_type == asset_type && info.share_type == share_type
        };
        i = i + 1;
    };

    return true
}

/// True if the bag contains no entries.
public fun is_empty(self: &DebtBag): bool {
    // infos is empty iff. bag is empty, but let's be explicit
    self.infos.is_empty() && self.bag.is_empty()
}

/// Destroy an empty bag and its inner storage.
public fun destroy_empty(self: DebtBag) {
    let DebtBag { id, infos, bag } = self;
    id.delete();
    infos.destroy_empty();
    bag.destroy_empty();
}

#[deprecated(note = b"Renamed to `length` for consistency.")]
public fun size(self: &DebtBag): u64 {
    self.infos.length()
}

/// Number of different asset/share entries in the bag.
public fun length(self: &DebtBag): u64 {
    self.infos.length()
}

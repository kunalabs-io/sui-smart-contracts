/// A map collection where the keys are homogeneous and the values are heterogeneous. Both keys and
/// values are stored using Sui's object system (dynamic fields). Values must have `store`, `copy`,
/// and `drop` capabilities.
module access_management::dynamic_map;

use sui::dynamic_field as field;

// Attempted to destroy a non-empty map
const EMapNotEmpty: u64 = 0;

public struct DynamicMap<phantom K: copy + drop + store> has key, store {
    /// the ID of this map
    id: UID,
    /// the number of key-value pairs in the map
    size: u64,
}

/// Creates a new, empty map
public fun new<K: copy + drop + store>(ctx: &mut TxContext): DynamicMap<K> {
    DynamicMap {
        id: object::new(ctx),
        size: 0,
    }
}

/// Adds a key-value pair to the map `map: &mut DynamicMap<K>`
/// Aborts with `sui::dynamic_field::EFieldAlreadyExists` if the map already has an entry with
/// that key `k: K`.
public fun insert<K: copy + drop + store, V: copy + drop + store>(
    map: &mut DynamicMap<K>,
    k: K,
    v: V,
) {
    field::add(&mut map.id, k, v);
    map.size = map.size + 1;
}

#[syntax(index)]
/// Immutable borrows the value associated with the key in the map `map: &DynamicMap<K>`.
/// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if the map does not have an entry with
/// that key `k: K`.
public fun borrow<K: copy + drop + store, V: copy + drop + store>(map: &DynamicMap<K>, k: K): &V {
    field::borrow(&map.id, k)
}

#[syntax(index)]
/// Mutably borrows the value associated with the key in the map `map: &mut DynamicMap<K>`.
/// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if the map does not have an entry with
/// that key `k: K`.
public fun borrow_mut<K: copy + drop + store, V: copy + drop + store>(
    map: &mut DynamicMap<K>,
    k: K,
): &mut V {
    field::borrow_mut(&mut map.id, k)
}

/// Removes the key-value pair in the map `map: &mut DynamicMap<K>` and returns the value.
/// Aborts with `sui::dynamic_field::EFieldDoesNotExist` if the map does not have an entry with
/// that key `k: K`.
public fun remove<K: copy + drop + store, V: copy + drop + store>(
    map: &mut DynamicMap<K>,
    k: K,
): V {
    let v = field::remove(&mut map.id, k);
    map.size = map.size - 1;
    v
}

/// Returns true iff there is a value associated with the key `k: K` in map `map: &DynamicMap<K>`
public fun contains<K: copy + drop + store>(map: &DynamicMap<K>, k: K): bool {
    field::exists_<K>(&map.id, k)
}

/// Returns the size of the map, the number of key-value pairs
public fun length<K: copy + drop + store>(map: &DynamicMap<K>): u64 {
    map.size
}

/// Returns true iff the map is empty (if `length` returns `0`)
public fun is_empty<K: copy + drop + store>(map: &DynamicMap<K>): bool {
    map.size == 0
}

/// Destroys an empty map
/// Aborts with `EMapNotEmpty` if the map still contains values
public fun destroy_empty<K: copy + drop + store>(map: DynamicMap<K>) {
    let DynamicMap { id, size } = map;
    assert!(size == 0, EMapNotEmpty);
    object::delete(id)
}

/// Drop a possibly non-empty map.
/// CAUTION: This will forfeit the storage rebate for the stored values.
public fun force_drop<K: copy + drop + store>(map: DynamicMap<K>) {
    let DynamicMap { id, size: _ } = map;
    object::delete(id)
}

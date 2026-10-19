// Copyright (c) Cetus Technology Limited

/// Fork @https://github.com/pentagonxyz/movemate.git
///
/// `acl` is a simple access control module, where `member` represents a member and `role` represents a type
/// of permission. A member can have multiple permissions.
module cetus_clmm::acl;

use move_stl::linked_table::{Self, LinkedTable};
use std::option::is_some;

/// Error when role number is too large
const ERoleNumberTooLarge: u64 = 0;
/// Error when role is not found
const ERoleNotFound: u64 = 1;
/// Error when member is not found
const EMemberNotFound: u64 = 2;

/// ACL (Access Control List) struct that manages permissions for members
/// Contains a mapping of addresses to their permission bitmasks
/// Each bit in the permission bitmask represents a specific role/permission
/// The first 128 bits are available for different roles
public struct ACL has store {
    permissions: LinkedTable<address, u128>,
}

/// Member struct representing a member in the ACL system
/// * `address` - The address of the member
/// * `permission` - A bitmask of the member's permissions, where each bit represents a specific role
public struct Member has copy, drop, store {
    address: address,
    permission: u128,
}



/// Create a new ACL instance
/// * `ctx` - Transaction context used to create the LinkedTable
/// Returns an empty ACL with no members or permissions
public fun new(ctx: &mut TxContext): ACL {
    ACL { permissions: linked_table::new(ctx) }
}

/// Check if a member has a role in the ACL
/// * `acl` - The ACL instance to check
/// * `member` - The address of the member to check
/// * `role` - The role to check for
/// Returns true if the member has the role, false otherwise
public fun has_role(acl: &ACL, member: address, role: u8): bool {
    assert!(role < 128, ERoleNumberTooLarge);
    linked_table::contains(&acl.permissions, member) && *linked_table::borrow(
            &acl.permissions,
            member
        ) & (1 << role) > 0
}

/// Set roles for a member in the ACL
/// * `acl` - The ACL instance to update
/// * `member` - The address of the member to set roles for
/// * `permissions` - Permissions for the member, represented as a `u128` with each bit representing the presence of (or lack of) each role
public fun set_roles(acl: &mut ACL, member: address, permissions: u128) {
    if (linked_table::contains(&acl.permissions, member)) {
        *linked_table::borrow_mut(&mut acl.permissions, member) = permissions
    } else {
        linked_table::push_back(&mut acl.permissions, member, permissions);
    }
}

/// Add a role for a member in the ACL
/// * `acl` - The ACL instance to update
/// * `member` - The address of the member to add the role to
/// * `role` - The role to add
public fun add_role(acl: &mut ACL, member: address, role: u8) {
    assert!(role < 128, ERoleNumberTooLarge);
    if (linked_table::contains(&acl.permissions, member)) {
        let perms = linked_table::borrow_mut(&mut acl.permissions, member);
        *perms = *perms | (1 << role);
    } else {
        linked_table::push_back(&mut acl.permissions, member, 1 << role);
    }
}

/// Revoke a role for a member in the ACL
/// * `acl` - The ACL instance to update
/// * `member` - The address of the member to remove the role from
/// * `role` - The role to remove
public fun remove_role(acl: &mut ACL, member: address, role: u8) {
    assert!(role < 128, ERoleNumberTooLarge);
    if (has_role(acl, member, role)) {
        let perms = linked_table::borrow_mut(&mut acl.permissions, member);
        *perms = *perms ^ (1 << role);
    }else{
        abort ERoleNotFound
    }
}

/// Remove all roles of member
/// * `acl` - The ACL instance to update
/// * `member` - The address of the member to remove
public fun remove_member(acl: &mut ACL, member: address) {
    if (linked_table::contains(&acl.permissions, member)) {
        let _ = linked_table::remove(&mut acl.permissions, member);
    }else{
        abort EMemberNotFound
    }
}

/// Get all members
/// * `acl` - The ACL instance to get members from
/// Returns a vector of all members in the ACL
public fun get_members(acl: &ACL): vector<Member> {
    let mut members = vector::empty<Member>();
    let mut next_member_address = linked_table::head(&acl.permissions);
    while (is_some(&next_member_address)) {
        let address = *option::borrow(&next_member_address);
        let node = linked_table::borrow_node(&acl.permissions, address);
        vector::push_back(
            &mut members,
            Member {
                address,
                permission: *linked_table::borrow_value(node),
            },
        );
        next_member_address = linked_table::next(node);
    };
    members
}

/// Get the permission of member by address
/// * `acl` - The ACL instance to get permission from
/// * `address` - The address of the member to get permission for
/// Returns the permission of the member
public fun get_permission(acl: &ACL, address: address): u128 {
    if (!linked_table::contains(&acl.permissions, address)) {
        0
    } else {
        *linked_table::borrow(&acl.permissions, address)
    }
}
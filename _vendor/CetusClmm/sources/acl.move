// Copyright (c) Cetus Technology Limited

#[allow(unused_field)]
/// Fork @https://github.com/pentagonxyz/movemate.git
///
/// `acl` is a simple access control module, where `member` represents a member and `role` represents a type
/// of permission. A member can have multiple permissions.
module cetusclmm::acl {
    use sui::tx_context::TxContext;
    
    use move_stl::linked_table::LinkedTable;
    
    struct ACL has store {
        permissions: LinkedTable<address, u128>
    }

    struct Member has store, drop, copy {
        address: address,
        permission: u128
    }

    /// @notice Create a new ACL (access control list).
    public fun new(_ctx: &mut TxContext): ACL {
        abort 0
    }

    /// @notice Check if a member has a role in the ACL.
    public fun has_role(_acl: &ACL, _member: address, _role: u8): bool {
        abort 0
    }

    /// @notice Set all roles for a member in the ACL.
    /// @param permissions Permissions for a member, represented as a `u128` with each bit representing the presence of (or lack of) each role.
    public fun set_roles(_acl: &mut ACL, _member: address, _permissions: u128) {
        abort 0
    }

    /// @notice Add a role for a member in the ACL.
    public fun add_role(_acl: &mut ACL, _member: address, _role: u8) {
        abort 0
    }

    /// @notice Revoke a role for a member in the ACL.
    public fun remove_role(_acl: &mut ACL, _member: address, _role: u8) {
        abort 0
    }

    /// Remove all roles of member.
    public fun remove_member(_acl: &mut ACL, _member: address) {
        abort 0
    }

    /// Get all members.
    public fun get_members(_acl: &ACL): vector<Member> {
        abort 0
    }

    /// Get the permission of member by addresss.
    public fun get_permission(_acl: &ACL, _address: address): u128 {
        abort 0
    }
}

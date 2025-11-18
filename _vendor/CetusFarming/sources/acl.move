module 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::acl {

    use sui::tx_context;
    use 0x11EA791D82B5742CC8CAB0BF7946035C97D9001D7C3803A93F119753DA66F526::acl;
    use 0xBE21A06129308E0495431D12286127897AFF07A8ADE3970495A4404D97F9EAAA::linked_table;

    struct ACL has store {
        permissions: linked_table::LinkedTable<address, u128>,
    }
    struct Member has copy, drop, store {
        address: address,
        permission: u128,
    }

    // NOTE: Functions are 'native' for simplicity. They may or may not be native in actuality.
    native public fun new(a0: &mut tx_context::TxContext): acl::ACL;
    native public fun has_role(a0: &acl::ACL, a1: address, a2: u8): bool;
    native public fun set_roles(a0: &mut acl::ACL, a1: address, a2: u128);
    native public fun add_role(a0: &mut acl::ACL, a1: address, a2: u8);
    native public fun remove_role(a0: &mut acl::ACL, a1: address, a2: u8);
    native public fun remove_member(a0: &mut acl::ACL, a1: address);
    native public fun get_members(a0: &acl::ACL): vector<acl::Member>;
    native public fun get_permission(a0: &acl::ACL, a1: address): u128;

}

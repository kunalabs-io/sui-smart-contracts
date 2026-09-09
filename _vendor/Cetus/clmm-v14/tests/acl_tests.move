#[test_only]
module cetus_clmm::acl_tests;

use cetus_clmm::acl;
use cetus_clmm::acl::{add_role, remove_role, has_role, set_roles, get_members, get_permission, new};

public struct TestACL has key, store {
    id: UID,
    acl: ACL
}

use std::debug;
use cetus_clmm::acl::ACL;
use cetus_clmm::acl::remove_member;


#[test]
fun test_end_to_end() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: acl::new(&mut ctx),
    };

    add_role(&mut acl.acl, @0x1234, 12);
    add_role(&mut acl.acl, @0x1234, 99);
    add_role(&mut acl.acl, @0x1234, 88);
    add_role(&mut acl.acl, @0x1234, 123);
    add_role(&mut acl.acl, @0x1234, 2);
    add_role(&mut acl.acl, @0x1234, 1);
    remove_role(&mut acl.acl, @0x1234, 2);
    set_roles(&mut acl.acl, @0x5678, (1 << 123) | (1 << 2) | (1 << 1));
    let mut i = 0;
    while (i < 128) {
        let mut has = has_role(&acl.acl, @0x1234, i);
        assert!(if (i == 12 || i == 99 || i == 88 || i == 123 || i == 1) has else !has, 0);
        has = has_role(&acl.acl, @0x5678, i);
        assert!(if (i == 123 || i == 2 || i == 1) has else !has, 1);
        i = i + 1;
    };

    let members = get_members(&acl.acl);
    debug::print(&members);

    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
fun test_add_role_has_role() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    assert!(!has_role(&acl.acl, @0x1234, 9), 0);
    add_role(&mut acl.acl, @0x1234, 9);
    assert!(has_role(&acl.acl, @0x1234, 9), 1);
    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
fun test_remove_role() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };

    assert!(!has_role(&acl.acl, @0x1234, 9), 0);
    add_role(&mut acl.acl, @0x1234, 9);
    assert!(has_role(&acl.acl, @0x1234, 9), 1);
    remove_role(&mut acl.acl, @0x1234, 9);
    assert!(!has_role(&acl.acl, @0x1234, 9), 2);
    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::acl::ERoleNotFound)]
fun test_remove_role_not_exist() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    remove_role(&mut acl.acl, @0x1234, 9);
    transfer::transfer(acl, tx_context::sender(&ctx));
}
#[test]
fun test_set_role() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    add_role(&mut acl.acl, @0x1234, 10);
    set_roles(&mut acl.acl, @0x1234, 5);
    assert!(!has_role(&acl.acl, @0x1234, 10), 0);
    assert!(has_role(&acl.acl, @0x1234, 0), 1);
    assert!(has_role(&acl.acl, @0x1234, 2), 2);
    assert!(get_permission(&acl.acl, @0x1234) == 5, 3);
    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
fun test_remove_member() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    add_role(&mut acl.acl, @0x1234, 10);
    add_role(&mut acl.acl, @0x5678, 10);
    assert!(has_role(&acl.acl, @0x5678, 10), 1);
    assert!(has_role(&acl.acl, @0x1234, 10), 2);
    remove_member(&mut acl.acl, @0x1234);
    assert!(!has_role(&acl.acl, @0x1234, 10), 2);
    assert!(has_role(&acl.acl, @0x5678, 10), 3);
    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::acl::EMemberNotFound)]
fun test_remove_member_not_exist() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    remove_member(&mut acl.acl, @0x1234);
    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::acl::ERoleNumberTooLarge)]
fun test_role_number_too_large() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    add_role(&mut acl.acl, @0x1234, 1);
    assert!(acl.acl.has_role(@0x1234, 128), 1);
    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::acl::ERoleNumberTooLarge)]
fun test_add_role_number_too_large() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    add_role(&mut acl.acl, @0x1234, 128);
    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
#[expected_failure(abort_code = cetus_clmm::acl::ERoleNumberTooLarge)]
fun test_remove_role_number_too_large() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    remove_role(&mut acl.acl, @0x1234, 128);
    transfer::transfer(acl, tx_context::sender(&ctx));
}

#[test]
fun test_get_permission() {
    let mut ctx = tx_context::dummy();
    let mut acl = TestACL {
        id: object::new(&mut ctx),
        acl: new(&mut ctx),
    };
    add_role(&mut acl.acl, @0x1234, 10);
    assert!(get_permission(&acl.acl, @0x1234) == 1 << 10, 1);
    assert!(get_permission(&acl.acl, @0x1235) == 0, 2);
    transfer::transfer(acl, tx_context::sender(&ctx));
}
// Copyright (c) Kuna Labs d.o.o.
// SPDX-License-Identifier: Apache-2.0

/// Access management initialization for the Kai Leverage package
module kai_leverage::access_init;

use access_management::access;

public struct ACCESS_INIT has drop {}

fun init(otw: ACCESS_INIT, ctx: &mut TxContext) {
    let admin = access::claim_package(otw, ctx);
    transfer::public_transfer(admin, tx_context::sender(ctx));
}

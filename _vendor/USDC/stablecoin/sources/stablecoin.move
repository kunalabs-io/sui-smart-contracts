// Copyright 2024 Circle Internet Group, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module stablecoin::stablecoin {
    use sui_extensions::upgrade_service;

    public struct STABLECOIN has drop {}

    #[allow(lint(share_owned))]
    /// Initializes a shared UpgradeService<STABLECOIN> and sets the
    /// transaction's sender as the initial admin.
    fun init(witness: STABLECOIN, ctx: &mut TxContext) {
        let (upgrade_service, _) = upgrade_service::new(
            witness,
            ctx.sender() /* admin */,
            ctx
        );
        transfer::public_share_object(upgrade_service);
    }

    #[test_only]
    public(package) fun init_for_testing(ctx: &mut TxContext) {
        init(STABLECOIN {}, ctx)
    }
}

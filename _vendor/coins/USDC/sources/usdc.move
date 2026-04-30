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

module usdc::usdc {
    use std::ascii::string;
    use sui::coin;
    use sui::url;
    use stablecoin::treasury;
    use sui_extensions::upgrade_service;

    /// The One-Time Witness struct for the USDC coin.
    public struct USDC has drop {}

    // === Constants ===

    const DESCRIPTION: vector<u8> = b"USDC is a US dollar-backed stablecoin issued by Circle. USDC is designed to provide a faster, safer, and more efficient way to send, spend, and exchange money around the world.";
    const ICON_URL: vector<u8> = b"https://www.circle.com/hubfs/Brand/USDC/USDC_icon_32x32.png";

    #[allow(lint(share_owned))]
    /// Initializes
    /// - A shared Treasury<USDC> object
    /// - A shared UpgradeService<USDC> object
    fun init(witness: USDC, ctx: &mut TxContext) {
        let (upgrade_service, witness) = upgrade_service::new(
            witness,
            ctx.sender() /* admin */,
            ctx
        );

        let (treasury_cap, deny_cap, metadata) = coin::create_regulated_currency_v2(
            witness,
            6,               // decimals
            b"USDC",         // symbol
            b"USDC",         // name
            DESCRIPTION,
            option::some(url::new_unsafe(string(ICON_URL))),
            true,            // allow global pause
            ctx
        );

        let treasury = treasury::new(
            treasury_cap, 
            deny_cap,
            ctx.sender(), // owner
            ctx.sender(), // master minter
            ctx.sender(), // blocklister
            ctx.sender(), // pauser
            ctx.sender(), // metadata updater
            ctx
        );
            
        transfer::public_share_object(metadata);
        transfer::public_share_object(treasury);
        transfer::public_share_object(upgrade_service);
    }

    #[test_only]
    public(package) fun init_for_testing(ctx: &mut TxContext) {
        init(USDC {}, ctx)
    }
}

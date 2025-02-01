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

#[test_only]
module stablecoin::stablecoin_tests {
    use sui::{
        test_scenario,
        test_utils::{assert_eq}
    };
    use stablecoin::stablecoin::{Self, STABLECOIN};
    use sui_extensions::upgrade_service::UpgradeService;

    const DEPLOYER: address = @0x10;

    #[test]
    fun init__should_create_shared_upgrade_service() {   
        let mut scenario = test_scenario::begin(DEPLOYER);
        stablecoin::init_for_testing(scenario.ctx());

        scenario.next_tx(DEPLOYER);
        let upgrade_service = scenario.take_shared<UpgradeService<STABLECOIN>>();
        assert_eq(upgrade_service.admin(), DEPLOYER);
        test_scenario::return_shared(upgrade_service);

        scenario.end();
    }
}

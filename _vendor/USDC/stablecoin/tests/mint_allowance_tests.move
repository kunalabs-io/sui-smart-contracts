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
module stablecoin::mint_allowance_tests {
    use sui::test_utils::{assert_eq};
    use stablecoin::mint_allowance;

    public struct MINT_ALLOWANCE_TESTS has drop {}

    #[test]
    fun create_and_mutate_mint_allowance__should_succeed() {
        let mut allowance = mint_allowance::new<MINT_ALLOWANCE_TESTS>();
        assert_eq(allowance.value(), 0);

        allowance.set(1);
        assert_eq(allowance.value(), 1);

        allowance.decrease(1);
        assert_eq(allowance.value(), 0);

        allowance.set(5);
        assert_eq(allowance.value(), 5);

        allowance.increase(3);
        assert_eq(allowance.value(), 8);

        allowance.destroy();
    }

    #[test, expected_failure(abort_code = ::stablecoin::mint_allowance::EOverflow)]
    fun increase__should_fail_on_integer_overflow() {
        let mut allowance = mint_allowance::new<MINT_ALLOWANCE_TESTS>();
        allowance.set(1);
        assert_eq(allowance.value(), 1);

        allowance.increase(18446744073709551615u64);
        allowance.destroy();
    }

    #[test, expected_failure(abort_code = ::stablecoin::mint_allowance::EInsufficientAllowance)]
    fun decrease__should_fail_if_allowance_is_insufficient() {
        let mut allowance = mint_allowance::new<MINT_ALLOWANCE_TESTS>();
        assert_eq(allowance.value(), 0);

        allowance.decrease(1);
        allowance.destroy();
    }

    #[test]
    fun increase_decrease__should_succeed_if_value_is_zero() {
        let mut allowance = mint_allowance::new<MINT_ALLOWANCE_TESTS>();
        assert_eq(allowance.value(), 0);

        allowance.set(100);
        assert_eq(allowance.value(), 100);

        allowance.decrease(0);
        assert_eq(allowance.value(), 100);

        allowance.increase(0);
        assert_eq(allowance.value(), 100);

        allowance.destroy();
    }
}

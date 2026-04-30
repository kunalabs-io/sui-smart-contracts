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

module stablecoin::version_control {
    use sui::vec_set::VecSet;

    /// The current version of the package.
    const VERSION: u64 = 1;

    // === Errors ===
    const EIncompatibleVersion: u64 = 0;

    // === Methods ===

    /// Gets the current package's version.
    public fun current_version(): u64 {
        VERSION
    }

    /// [Package private] Asserts that an object's compatible version set is
    /// compatible with the current package's version.
    public(package) fun assert_object_version_is_compatible_with_package(compatible_versions: VecSet<u64>) {
        assert!(compatible_versions.contains(&current_version()), EIncompatibleVersion);
    }
}

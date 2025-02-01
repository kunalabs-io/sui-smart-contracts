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
module sui_extensions::test_utils {
    use sui::event;
    use sui::test_utils::assert_eq;

    public fun last_event_by_type<T: copy + drop>(): T {
        let events_by_type = event::events_by_type();
        assert_eq(events_by_type.is_empty(), false);
        *events_by_type.borrow(events_by_type.length() - 1)
    }
}

# Cetus CLMM Test Coverage Report

Generated on 2026-09-10 for commit `b6025cf` (based on `cetus-clmm-sui/main`
commit `30facd5b160ed00fe61603e4442988faf7d8f4ac`) using `sui 1.74.1-8fc60f1fa966`.

## Scope and method

- Package: `cetus_clmm`
- Chain and source type: Sui Move source
- Test command: `sui move test --coverage --trace`
- Coverage command: `sui move coverage summary --silence-warnings`
- Result: 343 tests passed, 0 failed
- Metric: executed Move bytecode instructions in package source modules
- Dependencies are pinned by `Move.lock`; dependency code is not included in the package summary below.

Coverage is evidence that instructions were executed. It does not prove that assertions, economic invariants, permission boundaries, or all input combinations were tested.

## Summary

Overall coverage is **93.15%**: 10,179 of 10,927 instrumented instructions were executed.

| Module | Covered | Total | Coverage | Functions with zero coverage |
| --- | ---: | ---: | ---: | ---: |
| `acl` | 194 | 194 | 100.00% | 0 |
| `clmm_math` | 807 | 825 | 97.82% | 0 |
| `config` | 528 | 536 | 98.51% | 0 |
| `factory` | 1,413 | 1,543 | 91.57% | 1 |
| `partner` | 372 | 374 | 99.47% | 1 |
| `pool` | 3,218 | 3,638 | 88.46% | 28 |
| `pool_creator` | 164 | 168 | 97.62% | 2 |
| `position` | 1,024 | 1,159 | 88.35% | 3 |
| `position_snapshot` | 181 | 181 | 100.00% | 0 |
| `rewarder` | 485 | 493 | 98.38% | 0 |
| `tick` | 1,027 | 1,048 | 98.00% | 0 |
| `tick_math` | 733 | 735 | 99.73% | 0 |
| `utils` | 33 | 33 | 100.00% | 0 |

## R3 permission split

The R3 change is covered by positive and negative permission tests:

- `check_emergency_pause_role`: 10/10 instructions
- `check_emergency_unpause_role`: 10/10 instructions
- `emergency_pause`: 26/30 instructions
- `emergency_unpause`: 41/43 instructions
- A pause-only account cannot call `emergency_unpause`.
- An unpause-only account cannot call `emergency_pause`.
- Separate pause and unpause accounts can complete the pause/unpause sequence.

The uncovered instructions in `emergency_pause` and `emergency_unpause` are alternate abort paths. Authorization checks and the successful separated-role sequence are exercised.

## Zero-coverage functions

The coverage tool reports 35 functions with zero executed instructions.

| Module | Functions |
| --- | --- |
| `position` | `init`, `set_display`, `update_display_internal` |
| `partner` | `receive_ref_fee` |
| `pool` | `apply_liquidity_cut`, `calculate_swap_result_step_results`, `calculated_swap_result_after_sqrt_price`, `calculated_swap_result_amount_out`, `calculated_swap_result_is_exceed`, `calculated_swap_result_step_swap_result`, `calculated_swap_result_steps_length`, `emergency_restore_pool_state`, `fetch_positions`, `fetch_ticks`, `get_liquidity_from_amount`, `get_position_amounts`, `get_position_snapshot_by_position_id`, `governance_fund_withdrawal`, `index`, `is_attacked_position`, `is_position_exist`, `remove_liquidity_with_slippage`, `step_swap_result_amount_in`, `step_swap_result_amount_out`, `step_swap_result_current_liquidity`, `step_swap_result_current_sqrt_price`, `step_swap_result_fee_amount`, `step_swap_result_remainder_amount`, `step_swap_result_target_sqrt_price`, `tick_spacing`, `unpause`, `update_pool` |
| `factory` | `create_pool_v2_` |
| `pool_creator` | `create_pool_v2`, `create_pool_v2_with_creation_cap` |

Several zero-coverage functions are intentionally deprecated abort-only compatibility entry points, including legacy pool recovery functions, `pool::unpause`, `partner::receive_ref_fee`, and the `pool_creator::create_pool_v2*` functions. Their lack of execution does not expose an untested successful state transition. They should still have explicit deprecation/abort tests if the project requires every public entry point to be exercised.

For future test additions, prioritize active state-changing paths before read-only getters:

1. `pool::remove_liquidity_with_slippage`, including both minimum-output failures.
2. `pool::get_liquidity_from_amount` boundary and rounding cases.
3. `factory::create_pool_v2_` if this compatibility path remains callable and supported.
4. Snapshot lookup paths: `is_attacked_position` and `get_position_snapshot_by_position_id`.

## Reproduce locally

From `cetus_clmm/`:

```bash
sui move test --coverage --trace
sui move coverage summary --silence-warnings
sui move coverage summary --summarize-functions --csv --silence-warnings
sui move coverage lcov --silence-warnings
```

The coverage map, traces, and `lcov.info` are generated artifacts and are intentionally ignored. This report is a point-in-time snapshot; rerun the commands after contract or test changes.

## Coverage review boundaries

- Math / economic parameters: execution coverage measured; economic correctness was not re-audited.
- Accounting / vault: execution coverage measured; invariant completeness was not re-audited.
- Access control: R3 pause/unpause role separation was specifically verified.
- Oracle / pricing: outside this coverage-report task.
- Liquidation / settlement: not applicable to the scoped CLMM package report.
- Upgrade / admin: R3 authorization and version-bound tests included; deployment procedures are outside scope.

## Skill update candidates

- Dedup check: the existing Move/Sui access-control rules already require separate pause/unpause authorization and negative tests.
- New rule candidates: none.
- Regression pattern: the R3 pause-only versus unpause-only tests now serve as the repository regression case.

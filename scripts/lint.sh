#!/usr/bin/env bash
#
# Run the Move linter for every top-level Move package in this repo.
#
# Uses `sui move test --warnings-are-errors -- __no_match_lint_only__`:
#   - `sui move test` is the only command that compiles in test mode (so the
#     linter sees test files and #[mode(test)] items). `sui move build` only
#     compiles non-test sources, missing those lints. `sui move build --test`
#     is rejected by the CLI.
#   - `--warnings-are-errors` promotes lint warnings to errors so the script
#     fails on lint findings.
#   - The trailing `__no_match_lint_only__` is a test-name filter that matches
#     no tests, so the linter runs but no tests execute.
#
# Skips _vendor/ (external snapshots) and build/ artifact dirs. Continues
# through failures so every package is exercised; exits non-zero at the end
# if any package failed.

set -uo pipefail

cd "$(dirname "$0")/.."

mapfile -t PACKAGES < <(
  find . -name Move.toml \
    -not -path './_vendor/*' \
    -not -path '*/build/*' \
    -printf '%h\n' | sort
)

FAILED=()
for pkg in "${PACKAGES[@]}"; do
  echo "::group::$pkg"
  if ! (cd "$pkg" && sui move test --build-env mainnet --warnings-are-errors -- __no_match_lint_only__); then
    FAILED+=("$pkg")
  fi
  echo "::endgroup::"
done

echo
if (( ${#FAILED[@]} > 0 )); then
  echo "LINT FAILED (${#FAILED[@]}/${#PACKAGES[@]}):"
  for pkg in "${FAILED[@]}"; do
    echo "  $pkg"
  done
  exit 1
fi
echo "All packages clean (${#PACKAGES[@]} total)."

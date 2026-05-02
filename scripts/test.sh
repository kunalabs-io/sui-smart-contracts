#!/usr/bin/env bash
#
# Run `sui move test` for every top-level Move package in this repo.
# Skips _vendor/ (external snapshots) and build/ artifact dirs.
# Continues through failures so every package is exercised; exits non-zero
# at the end if any package failed.

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
  if ! (cd "$pkg" && sui move test --build-env mainnet); then
    FAILED+=("$pkg")
  fi
  echo "::endgroup::"
done

echo
if (( ${#FAILED[@]} > 0 )); then
  echo "FAILED (${#FAILED[@]}/${#PACKAGES[@]}):"
  for pkg in "${FAILED[@]}"; do
    echo "  $pkg"
  done
  exit 1
fi
echo "All packages passed (${#PACKAGES[@]} total)."

#!/usr/bin/env bash
# Slice 5 — local transport-level Coffee V3 three-photo E2E (two cup views +
# one saucer).
#
# Starts the REAL backend app + worker (backend/tests/e2e/coffee-v3-e2e-harness.ts)
# on loopback with isolated in-memory storage, a scripted FAKE provider and
# process-local test flags, then drives the REAL Flutter V3 client against it
# over real HTTP (test/e2e/coffee_v3_three_view_e2e_test.dart).
#
# No real provider calls, no remote flags, nothing deployed or persisted.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d)"
handshake="$work/handshake.json"
log="$work/harness.log"

cleanup() {
  if [ -f "$handshake" ]; then
    control="$(node -e "console.log(require(process.argv[1]).control)" "$handshake" 2>/dev/null || true)"
    [ -n "$control" ] && curl -s -X POST "$control/shutdown" >/dev/null 2>&1 || true
  fi
  [ -n "${harness_pid:-}" ] && kill "$harness_pid" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

(cd "$root/backend" && npx tsx tests/e2e/coffee-v3-e2e-harness.ts "$handshake" >"$log" 2>&1) &
harness_pid=$!

for _ in $(seq 1 60); do
  [ -f "$handshake" ] && break
  if ! kill -0 "$harness_pid" 2>/dev/null; then
    echo "harness exited early:"; cat "$log"; exit 1
  fi
  sleep 1
done
[ -f "$handshake" ] || { echo "harness did not become ready"; cat "$log"; exit 1; }
echo "$(cat "$log")"

cd "$root"
ORACLY_COFFEE_V3_E2E_HANDSHAKE="$handshake" flutter test test/e2e/coffee_v3_three_view_e2e_test.dart "$@"

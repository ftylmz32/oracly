#!/usr/bin/env bash
# Slice 6 — CONTROLLED real-provider Coffee V3 acceptance (one attempt).
#
# PAID: sends four owner-provided real photos to the official OpenAI API.
# Runs only when ALL of the following hold (else exits BLOCKED, zero requests):
#   - ORACLY_COFFEE_LIVE_AUTHORIZED=1 (explicit owner authorization)
#   - D:\oracly_coffee_live_input\ (or $ORACLY_COFFEE_LIVE_INPUT) holds
#     v3_cup_handle_far.jpg, v3_cup_turn_a.jpg, v3_cup_turn_b.jpg,
#     v3_saucer.jpg (genuine photos of one cup + saucer; JPEG, no Exif,
#     8 KiB–8 MiB, distinct) and an owner-written, non-empty rights.txt
#   - ORACLY_COFFEE_LIVE_OPENAI_API_KEY = a dedicated NON-PRODUCTION key
#     (the general OPENAI_API_KEY is never used)
# Guard: official endpoint only; ≤2 attempts / ≤6 requests per session;
# ≤1 observer + ≤2 writer per attempt; ambiguous outcome → sealed, no retry.
# Redacted evidence: D:\oracly_coffee_live_output\ (never commit it).
set -euo pipefail

if [ "${ORACLY_COFFEE_LIVE_AUTHORIZED:-}" != "1" ]; then
  echo "BLOCKED: set ORACLY_COFFEE_LIVE_AUTHORIZED=1 to confirm owner authorization (paid run)."
  exit 2
fi

root="$(cd "$(dirname "$0")/../.." && pwd)"
work="$(mktemp -d)"
handshake="$work/handshake.json"
log="$work/harness.log"

cleanup() {
  if [ -f "$handshake" ]; then
    control="$(node -e "console.log(require(process.argv[1]).control)" "$handshake" 2>/dev/null || true)"
    [ -n "$control" ] && curl -s -X POST "$control/shutdown" -H 'content-type: application/json' -d '{}' >/dev/null 2>&1 || true
  fi
  [ -n "${harness_pid:-}" ] && kill "$harness_pid" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

(cd "$root/backend" && npx tsx tests/e2e/coffee-v3-e2e-harness.ts "$handshake" --live >"$log" 2>&1) &
harness_pid=$!

for _ in $(seq 1 60); do
  [ -f "$handshake" ] && break
  if ! kill -0 "$harness_pid" 2>/dev/null; then
    cat "$log"
    if grep -q LIVE_PREFLIGHT_BLOCKED "$log"; then echo "BLOCKED: live preflight failed (zero provider requests)."; exit 2; fi
    echo "harness exited early"; exit 1
  fi
  sleep 1
done
[ -f "$handshake" ] || { echo "harness did not become ready"; cat "$log"; exit 1; }

cd "$root"
ORACLY_COFFEE_V3_LIVE_HANDSHAKE="$handshake" flutter test test/e2e/coffee_v3_live_acceptance_test.dart "$@"

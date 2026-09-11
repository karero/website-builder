#!/usr/bin/env bash
# Regression cases for looks_like_review() in independent_review.sh: which reviewer output counts as
# a review, and which as a refusal. Run: bash skills/independent-review/scripts/test_looks_like_review.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
fn="$(awk '/^looks_like_review\(\) \{/{p=1} p{print} p && /^\}$/{exit}' "$here/independent_review.sh")"
[ -n "$fn" ] || { echo "FAIL: could not extract looks_like_review"; exit 1; }
eval "$fn"
fail=0
check() {  # $1 = expected (accept|reject), $2 = label, $3 = reviewer output
  if looks_like_review "$3"; then got=accept; else got=reject; fi
  if [ "$got" = "$1" ]; then echo "ok   $2"; else echo "FAIL $2: expected $1, got $got"; fail=1; fi
}
check accept "plain single finding" "1. RISK — c.rb:3 — z could break on normal change."
check accept "real multi-finding review with a refusal-like aside" "I could not see the full context, but here are findings:
1. BUG — a.rb:1 — x is wrong now.
2. RISK — b.rb:2 — y breaks on normal change."
check reject "bare refusal" "I cannot review this content."
check reject "refusal disguised as a lone finding" "- BUG: I cannot review this file because it is too long."
check reject "access refusal as a lone finding" "- BUG: I cannot access the file."
check reject "review refusal with the UNVERIFIABLE marker" "- BUG: I cannot review this file. UNVERIFIABLE."
check reject "access refusal that copies the marker" "- BUG: I cannot access the file. UNVERIFIABLE. Please paste it before I can assess it."
check reject "access refusal with the marker and a clean verdict" "I cannot access the file. UNVERIFIABLE. No findings."
check reject "access refusal that copies the marker and an anchor" "- BUG: foo.rb:12 — I cannot access the file. UNVERIFIABLE. Please paste it before I can assess it."
# The price of the three cases above: an honest lone finding that cannot read its evidence also
# rejects, because by its text alone it cannot be told from them.
check reject "KNOWN WRONG: an honest lone finding that cannot read its evidence is discarded" "1. **RISK — foo.rb:12** — asserts lib Y retries on timeout. I cannot read the implementation of Y, so this is UNVERIFIABLE. Settling observation: call Y against a stalled server.

CLEAN: checked the caller's arguments."
# Known wrong too, and tracked with the case above as B-REFUSAL-TEXT in
# docs/reviews/OPEN-FINDINGS-independent-review.md. These pin today's behaviour, so a fix has to
# change them on purpose.
check accept "KNOWN WRONG: two refusal-shaped findings count as a review" "1. BUG — I cannot review the file.
2. RISK — I cannot access the repository."
check reject "KNOWN WRONG: a lone real finding saying 'cannot return' is discarded" "1. BUG — api.rb:12 — The handler cannot return JSON because serialization raises before the response is built. Fix: serialize the supported fields."
exit $fail

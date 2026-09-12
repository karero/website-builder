# Independent review — DIFF — packaging honesty (round 1)

Branch `fix/packaging-honesty`, head `63928d4`, base `origin/main` `5c1a50c`. Merged as PR #107,
merge commit `0594017`, before this trail was written — recorded here after the fact rather than
before merging, which is a deviation from the closeout procedure's normal order. Recorded now
because the review happened and its record should exist; nothing about the finding disposition
changes by the delay.

**The change.** `check_clean.sh` ended with `OK — no personal names, contact info, or credentials
in: … SECURITY.md …`, but SECURITY.md was never in the handoff zip — an OK line that could not
fail. Fixed by shipping SECURITY.md in the zip and by making a missing scan target a hard failure
naming it, plus adding `test_failed_tier_report.sh` to the packaging integrity list, which it had
also missed.

**Verdict.** One round, both seats returned findings on the first version. The fix committed and
merged is a **rewrite following the reviewers' own recommendations**, not the version they scored.
The rewrite is self-verified against four scenarios (below); it was not sent through a second
review round. That is the gap this trail exists to disclose.

## Round 1 (on the first version of the diff, before the strict rewrite)

Reviewers: Codex CLI (`gpt-6-astra`, `exec -s read-only`) + ollama-cloud (`glm-5.3:cloud`, text
only). Both returned `OK`.

| Sev | Source | Finding | Disposition |
|---|---|---|---|
| BUG | Codex | Existence filtering doesn't prove a file was *read*: a `grep` scan error (exit >1) still printed OK | Fixed in `63928d4`: a `g()` wrapper distinguishes "no hits" (exit 1) from a real scan error (exit >1) and fails the run on the latter |
| RISK | Codex | The empty-target guard covered only `SCAN_DOCS`, not `SCAN_NAMES` — a copy holding only `LICENSE` would pass no paths to the name-scan grep | Superseded by the strict rewrite below, which removes the "legitimate subset" premise entirely |
| BUG | Codex | My own comment overstated grep's behaviour — a missing path is a diagnostic and exit 2, not silence; grep with no paths doesn't reliably hang | Fixed: comment corrected in `63928d4` |
| RISK | ollama | The empty-target guard missed the `SCAN_NAMES`-only-empty case (same defect as Codex's RISK, independently found) | Same disposition |
| RISK | ollama | Treating a missing target as a lenient skip is unjustified once the zip ships every target — a missing one means something is broken | **Adopted as the fix's design**: `63928d4` drops "skip and note" entirely; any missing target is now a hard `FAIL` naming it |
| NIT | ollama | The "grep skips a missing path silently" comment (same defect as Codex's BUG) | Fixed, same commit |
| NIT | ollama | Unquoted `$1` in the target-list loop pathname-expands as well as word-splits | Fixed: the loop now runs under `set -f` |

## Self-verification of the rewrite (not re-reviewed)

Run by hand against the merged code, in the unzipped release-candidate and in scratch copies:

1. Full repo (every target present) → exit 0, OK line lists `SECURITY.md` truthfully.
2. `SECURITY.md` removed from a copy → exit 1, `FAIL — these scan targets are missing, so nothing
   checked them: SECURITY.md`.
3. An unreadable directory under `skills/` (`chmod 000`) → exit 1, `✗ scan error (grep exit 2) —
   this check did NOT run:` with the diagnostic quoted.
4. Rebuilt `dist/website-builder.zip` → `zip integrity OK`, 225 files; inside the unpacked zip both
   `check_clean.sh` and `make check` pass, and the OK line now describes a real scan.

This covers the four cases the round-1 findings named. It does not substitute for a second external
round — no reviewer has seen the `set -f` fix, the `g()` wrapper, or the strict all-or-nothing
target policy as committed.

## Not verified

Whether any other repo consuming `check_clean.sh` (there are none known) relies on the old lenient
behaviour. Windows/CRLF behaviour of the new `g()` wrapper is untested — this script has no stated
Windows support contract, unlike the installers in PR #105.

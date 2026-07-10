# REVIEW — DIFF gate, PR #54 (findings against PR #50), round 1 (2026-07-10)

Artifact: `git diff v0.15..origin/main` in website-builder — the combined diff of
everything going into release v0.16 (PRs #49, #50, #51, #52), reviewed at Daniel's
explicit request ("review independently with CODEX all the new stuff we want to put
in the release"). A separate, narrower pass also reviewed PR #52 alone per Daniel's
explicit callout — see the website-builder-shared-checkout-incident /
apreet-backend-shared-worktree-risk memory family for that PR's own context; its
findings were fixed directly (PR #53, already merged) and are not repeated here.

## Reviewers (version / model / sandbox)
| Seat | Tool | Model | Sandbox | Outcome |
|---|---|---|---|---|
| cross-model | codex-cli 0.144.1 | gpt-5.6-terra / xhigh | `exec -s read-only` | 8 findings (4 BUG · 4 RISK) |

Independence: host = Claude Code; gate satisfied (Codex is cross-model here). Daniel
named Codex specifically, so only that reviewer ran this round (no Antigravity/ollama,
no separate fresh-eyes host pass) — per established practice, one named reviewer
satisfies a round when the user names exactly one tool.
Data check: website-builder is a public repo already cleared by `make check`
(no secrets); no additional review needed before dispatch.

## Findings — all 8 concentrated in PR #50 (`independent-review` onboarding wizard)

PR #49, #51, and #52's content came back entirely CLEAN. PR #50 claimed 5 rounds of
self-review to 0/CLEAN in its own PR body — a fresh, independent pass still found:

1. **BUG** — `SKILL.md`, AGY_MODEL "contradicts" Claude-Code-cross-model claim.
   **Verified and REFUTED before any fix**: exactly one `AGY_MODEL` mention exists,
   correctly scoped to "any non-Claude host" — no actual contradiction.
2. **BUG** — `setup-guide.md`, 64GB+ row recommends `gpt-oss:120b` (65GB) — a 65GB
   model can't fit in 64GB. **CONFIRMED.**
3. **BUG** — Step 2's "skip to Step 6" doesn't clearly mandate Step 5 verification
   first. **PLAUSIBLE** (present but in a trailing parenthetical).
4. **BUG** — `command -v`/`test -f` detection commands don't work in PowerShell,
   which this wizard explicitly supports. **PLAUSIBLE.**
5. **RISK** — 16GB/32GB rows offer two alternatives each, no tiebreaker, undermining
   Step 4b's "recommend exactly ONE." **CONFIRMED.**
6. **RISK** — `agy models` only proves listing works, not which model a review will
   use. **PLAUSIBLE**, worth tightening.
7. **RISK** — setup-guide citations (XDA report) lack clickable URLs. **CONFIRMED
   but minor.**
8. **RISK** — "Available RAM" column header mismatches total-RAM check commands.
   **CONFIRMED.**

## Disposition

All CONFIRMED and PLAUSIBLE findings (7 of 8; #1 refuted) taken forward as a fix.
See r2–r5 for the fix + re-verification cycle — this took 5 rounds because the first
two fix attempts at finding #4/#6's underlying design (agy host-family logic)
introduced new bugs while fixing prior ones; round 4 redesigned rather than patched.
Reported to Daniel with the CONFIRMED/PLAUSIBLE/REFUTED breakdown before fixing
anything, per this skill's "keep the human in the loop" step — he said "fix these
now."

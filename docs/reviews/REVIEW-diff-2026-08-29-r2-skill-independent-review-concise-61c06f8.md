# Independent review — DIFF gate, round 2 (verification round)

- **Artifact**: round-1 findings list with claimed dispositions + the fix-round diff
  `fa17fea..61c06f8` (`docs/reviews/` excluded). The full branch diff was reviewed in
  round 1 (see the r1 trail); this round verifies the fixes, per Procedure step 6.
  The full diff at 61c06f8 measured 119,170 bytes — within a whisker of the script's
  120 KB single-argument cap, which is why round 2 carried the fix diff rather than
  the full diff plus a preamble.
- **Date**: 2026-08-29
- **Reviewers**: same pair as round 1 — Codex CLI `gpt-5.6-sol` (`exec -s read-only`),
  ollama-cloud `glm-5.3-flash:cloud`. Both were told the author expects clean and not
  to oblige out of politeness. The ollama seat was again selected by the branch's own
  auto-detect; this run its new multi-candidate note fired live ("4 ':cloud' models —
  auto-using the first").
- **Permission audit**: unchanged from r1 (WORKTREE-WRITE and BRANCH-COMMIT atom A —
  this session created both; POST AUTHORITY / GATED-THIS-DIFF n/a, no PR yet).

## Verdict on round-1 dispositions

**All 10 verified by Codex** (its "Claim verdicts" section, checked against the working
tree, the zip contents, and a live `bash scripts/check_model_agnostic.sh` run). Zero
BUGs raised. BUG/RISK series across the review: 8 → 0 BUG; the round-2 RISKs below all
target code the round-1 fixes ADDED — convergence signal (b) passes.

## Round-2 findings and dispositions

| id | sev | source | finding | disposition |
|---|---|---|---|---|
| R2-1 | RISK | Codex | Guard: find/grep I/O failures could still end in "OK" (grep tri-state unchecked) | **fixed**: grep rc>1 now FAILs; the file-count floor catches find/path breakage. `locally_verified` |
| R2-2 | RISK | Codex (+ ollama NIT 4) | Guard scanned only `*.md`/`*.sh`, and excluded setup-guide by basename not path | **fixed**: scans every regular file (`grep -I` skips binaries), exclusion by exact path. `locally_verified` |
| R2-3 | RISK | Codex (+ ollama NIT 5) | A failed `ollama list` was misreported as "no ':cloud' model" | **fixed**: distinct `elif` branch with its own note. `locally_verified` |
| R2-4 | RISK | ollama | The broadened pattern might flag existing prose in the scanned files ("make smoke verified" was a claim, not evidence to the reviewer) | **refuted with evidence**: the guard ran green at HEAD both before and after the broadening (its run output is in this round's record); the one `:7b`-shaped teaching example had already been scrubbed in fa17fea |
| R2-5 | RISK | ollama | B-TAGCLASS deferral not auditable from the diff; wants a pointer from the exclusion comment | **fixed**: row exists (committed in 61c06f8) and the guard's exclusion comment now names it. `locally_verified` |
| R2-6 | RISK | ollama | Self-test had no negative controls — an over-broadened pattern would ship silently | **fixed**: allowed-phrase samples now FAIL the run if matched. `locally_verified` |
| R2-7 | NIT | ollama | Two new texts hardcoded "onboarding Step 5" by number | **fixed**: role-based wording ("the onboarding model-confirmation step"), number kept only as a parenthetical in setup-guide. `locally_verified` |
| R2-8 | NIT | ollama | Guard's `-lt 4` floor encoded today's exact file count | **fixed**: floor 2, documented as find/path-breakage detection only. `locally_verified` |

Codex's UNVERIFIABLE list, checked by the author where checkable: package.sh's
`REQUIRED` array IS consumed by a verifying loop; onboarding.md HAS a Step 5;
SKILL.md Procedure step 5 DOES say BUGs are never waivable; a repo-wide grep finds no
remaining `check_model_defaults` reference outside historical trail files and the
guard's own deliberate ancestry comment.

Incident worth recording: the first attempt at the R2-7 fix put an apostrophe inside a
`"${var:-...}"` default (`onboarding's`), which bash parses as an opening quote inside
the expansion — the file broke 380 lines downstream. Caught by `bash -n` before
commit; reworded without the apostrophe.

## Round status — closing

Round 2 returned zero BUG; its RISKs are guard-hardening on round-1's own additions
and are now all fixed or refuted, per the table. **The closing edits are
`locally_verified` only — no external reviewer has seen the round-2 fixes** (the same
admission Procedure step 6(a2)/(c) requires): `bash -n`, the guard's own self-tests,
`make smoke`, and a live auto-detect exercise are the verification on record. Sending
these mechanical hardenings out again would be the NIT-churn loop 6(a2) exists to
stop. Gate outcome: **satisfied, cross-model** (Codex + ollama-cloud both successful
in both rounds), with B-TAGCLASS carried as the one open, pre-existing, tracked BUG —
deferral keeps it visible in OPEN-FINDINGS, not closed.

# Independent review — DIFF gate, round 1

- **Artifact**: full branch diff `origin/main...HEAD`, `docs/reviews/` excluded
  (`base` = merge-base 5c68e37, `head` = fa17fea — the restructure commit a320aab
  plus the model-agnosticism commit fa17fea)
- **Date**: 2026-08-29
- **Reviewers**:
  - Codex CLI `gpt-5.6-sol`, `exec -s read-only` (read-only sandbox, saw the worktree)
  - ollama-cloud `glm-5.3-flash:cloud` (text-only; auto-detected by the branch's own
    new auto-detect logic — first `:cloud` tag in `ollama list`)
- **Permission audit** (per the permission table, `references/closeout.md`):
  WORKTREE-WRITE and BRANCH-COMMIT both atom A — this session created the worktree
  `../website-builder-ir-concise` and the branch `skill/independent-review-concise`.
  POST AUTHORITY / GATED-THIS-DIFF: not applicable yet — no PR exists at review time.
- **Raw verbatim output**: not yet durably captured in-repo — retained in the run's
  `$RAW_DIR` (`$TMPDIR/independent-review.rmf8nB`) and a session scratchpad copy.
  To be posted as collapsed PR comments (clerk item 1) when the PR opens; do not
  delete `$RAW_DIR` before that lands.
- An earlier run against the restructure-only diff (a320aab alone) was deliberately
  stopped before any reviewer returned output — the artifact was superseded by the
  agnosticism commit mid-run. No findings were produced or lost; noted here so the
  round count starts at this run.

## Findings and dispositions

| id | sev | source | finding | disposition |
|---|---|---|---|---|
| R1-1 | BUG | Codex | Trimmed frontmatter said BLOCK until "every finding" is owner-waived — contradicts Procedure step 5 (BUGs never waivable) | **fixed** (61c06f8): description restores the BUG vs RISK/NIT distinction. `locally_verified` |
| R1-2 | BUG | Codex | `is_cloud_ollama_tag` classifies `*:120b/*:405b/*:480b` as cloud while setup-guide recommends a LOCAL `gpt-oss:120b` — `--local-only` refuses it; explicit use outside it would count as gate-eligible cloud | **deferred, open** — pre-existing (suffix arms predate this branch), fix is a design change. Recorded as B-TAGCLASS in `OPEN-FINDINGS-independent-review.md` |
| R1-3 | BUG | Codex (+ ollama RISK 3/4) | Agnosticism guard scanned a fixed 4-file list with a narrow, case-sensitive pattern — new files unscanned, `GPT-5`/`Claude Opus 4.6`/`qwen3-coder:30b` shapes missed | **fixed** (61c06f8): renamed `check_model_agnostic.sh`; files discovered via `find` (setup-guide.md excluded by documented design); broadened case-insensitive pattern; self-test fails the run if the pattern stops matching known-bad samples. `locally_verified` (make check green incl. self-test) |
| R1-4 | BUG | Codex | Handoff zip ships a Makefile invoking the guard but omits the script — `make check/package/smoke` broken for zip recipients | **fixed** (61c06f8): shipped + REQUIRED in package.sh. Pre-existing (introduced with the guard on main, 5c68e37). `locally_verified` (make smoke: zip integrity OK, 212 files) |
| R1-5 | RISK | Codex (+ ollama NIT 6) | Unset `AGY_MODEL` recorded only "CLI default model" — closeout requires the actual model; agy output format for model identity unconfirmed | **fixed** (61c06f8): header now says "CLI default — model unconfirmed, verify per onboarding Step 5"; onboarding Step 5 remains the confirmation gate. `locally_verified` |
| R1-6 | RISK | Codex (+ ollama NIT 5) | First-`:cloud` auto-pick is order-dependent and silent — adding a second cloud tag silently switches reviewers | **fixed** (61c06f8): chosen tag echoed to stderr; multi-candidate case named with count + override instruction. `locally_verified` |
| R1-7 | RISK | ollama | No stderr note at all when the ollama CLI is absent (note only covered CLI-present/no-cloud-tag) | **fixed** (61c06f8): distinct note per case. `locally_verified` |
| R1-8 | RISK | ollama | Trigger-phrase regression: description dropped phrases the body/onboarding still teach ("antigravity review", "agy review", …) | **fixed** (61c06f8): phrases restored; description now ~140 words — deliberately above the ~100-word bar, trigger coverage outranks the word target. `locally_verified` |
| R1-9 | NIT | ollama | setup-guide called onboarding Step 5 a "canonical invocation" it no longer contains | **fixed** (61c06f8). `locally_verified` |
| R1-10 | NIT | ollama | Script name `check_model_defaults.sh` contradicts its new purpose | **fixed** (61c06f8): renamed; Makefile/clean.yml/package.sh updated. `locally_verified` |

UNVERIFIABLE items both reviewers raised, held as notes, not blocking: whether
`ollama signin` reliably surfaces a `:cloud` tag in `ollama list` (verified TRUE on
this machine — the auto-detect resolved the owner's signed-in cloud model live; not
verifiable for all installs, and the no-tag stderr note covers the failure mode);
whether `agy --sandbox -p` without `--model` works (untested — spending an
Antigravity credit is opt-in only; exposure is limited to the opt-in tier and the
unconfirmed state is now visible in the section header per R1-5).

## Round status

BUG/RISK series: 8 raised → 7 fixed, 1 deferred-as-pre-existing (B-TAGCLASS, tracked).
Fixes are `locally_verified`; round 2 (verification round: prior findings + fix-round
diff fa17fea..61c06f8) sent to the same pair to confirm the fixes landed and
introduced nothing new.

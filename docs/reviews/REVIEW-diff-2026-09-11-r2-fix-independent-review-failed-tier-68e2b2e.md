# Independent review — DIFF — failed-tier reporting (rounds 1–2)

Branch `fix/independent-review-failed-tier`, head `68e2b2e`, base `origin/main` `09000f9`.

**The change.** When a reviewer tier failed (an HTTP 429 quota refusal, on 2026-09-11), its error
reached only a temp `.err` file; stdout carried the other tier's review alone and the exit was 0,
so a one-reviewer round read as a clean pair. Now every attempted tier leaves a stdout section — its
review, or `## Independent review — <tier> — FAILED` quoting its error — a closing `reviewers:` line
gives each tier's outcome, quota refusals are named apart from other failures, and a round with
fewer than 2 counted reviewers says so. Exit codes are unchanged.

**Verdict.** No open BUG in this change. One RISK stays UNVERIFIABLE (R2-4). Pre-existing items are
tracked, not fixed here. The round-2 fixes are verified by tests (`test_failed_tier_report.sh`, 73
checks, macOS bash 3.2 and Linux), not by a third external round.

## Rounds

| Round | Reviewed | Reviewers — CLI, model, sandbox | Findings |
|---|---|---|---|
| 1 | `7bb5f2b` | Codex CLI 0.154.0, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.0, `glm-5.3:cloud`, text only (no tools) | 15 |
| 2 | `783e83c` — a trial merge of this change with `feat/review-prompt-mechanism-claims` (up to `668bf73`); this change's code there is identical to `10a96a4` | Fable (Claude family; the fresh-eyes seat, a read-only subagent with repo access — the host's own family, so not cross-model); Codex CLI 0.154.0, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.0, `kimi-k3:cloud`, text only | 21 |

Round 2's artifact: an author's cover note plus `git diff origin/main...783e83c -- .
':(exclude)docs/reviews/'`. Findings about the other branch ("B") are recorded below and handed to
that branch; the owner split the two changes after this round.

Totals: 2 rounds, 36 findings. The verbatim reviewer output is not in this repo (it carries local
paths); the owner keeps it in their local harness repo, and it goes to the PR as the clerk's raw
comment once one is open.

## Round 1 (on `7bb5f2b`)

| ID | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| R1-1 | BUG | Codex | Quota classification could be driven by reviewed-artifact text in codex's stderr tail | Fixed `10a96a4` (error-record lines only); tightened in `429b5af` |
| R1-2 | BUG | Codex | An error printed on stdout before a non-zero exit was neither quoted nor classified | Fixed `10a96a4` |
| R1-3 | BUG | Codex | A failing `ollama list` for a named model became SKIPPED, its error lost | Fixed `10a96a4` |
| R1-4 | RISK | Codex | The test ran in neither `make check` nor CI | Fixed `10a96a4` (`make check`; CI job `review-reporting`) |
| R1-5 | BUG | Codex | The stderr cleaner missed `ESC[0~` and other escape shapes | Fixed `10a96a4` |
| R1-6 | BUG | Codex | A `--local-only` success was called an "external reviewer" | Fixed `10a96a4` ("counted toward the gate") |
| R1-7 | RISK | glm | The test asserts the manual prompt on stdout | Refuted: `PROMPT_PORTABLE` is printed to stdout; case 5 passes |
| R1-8 | RISK | glm | `run_agy`'s MODE-line path may return failure unreported | Refuted: that path warns and continues; it never returns 1 |
| R1-9 | RISK | glm | Quota misclassification from the artifact tail | Same as R1-1; fixed |
| R1-10 | RISK | glm | Quoted tier output could spoof a section header or summary line | No change: quotes are indented 4 spaces, so a quoted `## …` or `reviewers:` line is never at column 0 |
| R1-11 | RISK | glm | A cleaner failure read as "No stderr captured" | Fixed `10a96a4`: says the stderr held nothing readable and names the raw file |
| R1-12 | RISK | glm | Removing the dispatcher's `command -v ollama` guard | Fixed `10a96a4`: `run_ollama` checks the CLI itself |
| R1-13 | NIT | glm | Stale "not honored for plan type" comment | Fixed `10a96a4` |
| R1-14 | NIT | glm | `SKILL.md`'s "PLAN additionally" lead-in | Declined: PLAN's policy (treat as degraded) still differs; the added sentence covers DIFF |
| R1-15 | NIT | glm | A latent `set -e` trap for bare `attempt` calls | Declined: the script does not use `set -e` |

## Round 2 (on `783e83c`)

| ID | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| R2-1 | BUG | Fable | The stderr cleaner crashed on malformed UTF-8 from a `tail -c` cut inside a spinner glyph, turning a real 429 into "exit 1" | Fixed `429b5af` (U+FFFD decode; test `utf8cut`) |
| R2-2 | BUG | Fable | Wrong remedy for an answer the validator rejected as not a review | Fixed `429b5af` (its own outcome, never quota or setup; test `notreview`) |
| R2-3 | RISK | Fable | The discard path had no test; B makes discards likelier | Test added in `429b5af`. The validator itself is pre-existing (B-REFUSAL-TEXT, tracked on B's branch) |
| R2-4 | RISK | Fable | Codex's real error shape and position are unverified | Partly fixed `429b5af` (a timestamp token before `ERROR`; 8-line tail; test `tracing`). Stays **UNVERIFIABLE**: no real codex quota refusal has been captured |
| R2-5 | NIT | Fable | `check_prompt_sync.sh` has mode 0644 | B's file; handed back |
| R2-6 | NIT | Fable | The cover note understated a stdout change (the ⚠ note now also reaches stdout) | Acknowledged; recorded here |
| R2-7 | BUG | Codex | The validator rejects honest lone findings and accepts refusal-shaped ones | Pre-existing (B-REFUSAL-TEXT), deferred earlier with the owner's sign-off |
| R2-8 | BUG | Codex | The ollama review-body filter stopped at an unknown escape and silently dropped the rest of the review, which still counted | Pre-existing; fixed `429b5af` (every escape shape consumed, an unparseable one fails the tier; tests `oddbody`, `strayesc`) |
| R2-9 | BUG | Codex | An error-shaped line from the artifact (a diff context line, a plan line) can still select the quota remedy | Fixed `429b5af`: indented lines never count, and the exit status stays beside the quota label (test `codexctx`). A column-0 plan line echoed by codex can still match; the kept exit status and the quote let a human tell |
| R2-10 | BUG | Codex | `check_prompt_sync.sh` is fooled by a commented-out assignment | B; handed back |
| R2-11 | RISK | Codex | Compatibility with the private caller is unverifiable | Checked on the owner's machine: no program parses this output; the reader is the host agent acting as clerk (`references/closeout.md`) |
| R2-12 | RISK | Codex | B's effect on reviewer models is unmeasured | B; a pilot is handed back |
| R2-13 | RISK | Codex | Codex containment (`-s read-only`) is untested | Pre-existing (R-SANDBOX) |
| R2-14 | RISK | Codex | Ollama locality and readiness are inferred from tag names | Pre-existing |
| R2-15 | BUG | kimi | "GENUINE read-only sandbox" claims contradict B's new hedges | B; handed back (the contradiction exists only with B merged) |
| R2-16 | RISK | kimi | Claims about what `codex exec` does are unverified | Pre-existing; UNVERIFIABLE |
| R2-17 | RISK | kimi | The escape handling was checked only against stub byte shapes | Refuted in part: the captured incident `.err` was replayed through the script, and the real `ollama` CLI was run on a nonexistent tag; both came out clean |
| R2-18 | RISK | kimi | B's premise is unmeasured | B; pilot |
| R2-19 | NIT | kimi | A bare "quota" mislabels "disk quota exceeded" | Fixed `68e2b2e` (test `diskquota`) |
| R2-20 | NIT | kimi | The <2 note assumes a failure even when a tier was merely skipped | Fixed `68e2b2e` |
| R2-21 | NIT | kimi | `check_prompt_sync.sh` self-tests miss two failure modes | B; handed back |

## What the reviewers said about adopting it

All three round-2 seats: adopt this change; hold B until it is adapted and measured. On how the
owner's machine should take the script, Codex and kimi said pin a vetted commit; Fable said follow
`main` and split the PRs. The owner chose to split the changes and to pin.

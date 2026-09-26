# Independent review — DIFF — B-TAGCLASS pinned as KNOWN WRONG (round 1)

Branch `test/b-tagclass-known-wrong`, reviewed at `443a694`, base `origin/main` `0ae0525`.

**The change.** B-TAGCLASS is a tracked BUG: `is_cloud_ollama_tag()` calls any `*:120b` tag cloud,
even a model pulled and run locally. On 2026-09-26 the owner signed off its deferral under
SKILL.md point 5 ("Sign it off and I'll add the test"). Scenario 22 in `test_failed_tier_report.sh`
drives the real script and pins both wrong results: the tag is refused under `--local-only` (exit 2,
no reviewer runs) and counted as a cloud reviewer outside it. The tracker row records the sign-off.

**Verdict: no BUG or RISK open, one seat only.** Codex found one RISK and it is fixed; the fix is
`locally_verified`, not externally re-verified. ollama-cloud could not review: it hit its weekly
quota (HTTP 429). So the round is degraded — one counted seat.

| Round | Reviewed | Reviewers — CLI, model, sandbox | Findings | BUG / RISK / NIT |
|---|---|---|---|---|
| 1 | `443a694` | Codex CLI 0.157.0, `gpt-6-astra`, `exec -s read-only`, through the pinned gate script (`5e310f6`); ollama-cloud FAILED on quota | 1 | 0 / 1 / 0 |

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| T1 | RISK | Codex | The "counts as a cloud reviewer" pin did not check which model ran: the stub lists only the `:cloud` tag and ignored `ollama run`'s model, so a model-selection change could keep it green without exercising B-TAGCLASS | Fixed: the stub records the model it ran, and a guard check asserts it is the configured `*:120b` tag. `locally_verified`: substituting the listed tag in `ollama run` turns exactly that check red |

Consent: Codex and ollama-cloud under the owner's go-ahead for this change; the artifact is a public
repo's diff, checked for secrets, home paths and client names first. WORKTREE-WRITE and
BRANCH-COMMIT: atom A — this session created the worktree and the branch.

**Point 5's conditions for B-TAGCLASS.** It goes wrong at the merge-base `0ae0525`: the script is
byte-identical there (Codex checked). The row carries the owner's sign-off of 2026-09-26. The three
KNOWN WRONG checks pin its wrong results through the real entry point; removing the size arms turns
exactly those three red. The test uses a stand-in `*:120b` tag built at runtime, because
`check_model_agnostic.sh` forbids a literal model tag; Codex ran the classifier on both the stand-in
and the row's `gpt-oss:120b` and got the same result.

**Tests.** `test_failed_tier_report.sh` all passing, with four new checks (three KNOWN WRONG, one
guard). `make check` passes.

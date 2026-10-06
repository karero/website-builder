# DIFF review — chore/pre-030-follow-ups — two follow-ups before v0.30 (#183's EmailLink lang, #150's portable prompt)
Base `4e69534` · depth: Light (a template refactor with identical output, and one prompt paragraph; no user data, no production path) · verdict: CLEAN · authority used: WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created worktree `../website-builder-pre030` and branch `chore/pre-030-follow-ups`)

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `44c2613` | full: `4e69534...44c2613` | host `/code-review` at medium (same family, Light gate by the owner's standing choice) | — | 0/0/0 |
| 2 | `44c2613` | full: `4e69534...44c2613` (trail excluded) | Codex (gpt-6.1-sol, read-only, `--seat codex`), cross-model seat at the owner's request: "yes, run Codex on #197" | 151 s, 59359 tok | 0/0/0 |

Evidence: `check_prompt_sync.sh` ok; `make check` exit 0 (skips: Perl::MinimumVersion not installed, `/proc` cases on macOS; CI runs both). The rendered hint is asserted per language by `forms.spec.ts` in CI's template-tests job.
Follow-ups closed: #183's "pass `lang={language}` to EmailLink"; #150's R3-N1 / FR-N11 "PROMPT_PORTABLE lacks the unseen-text rule".

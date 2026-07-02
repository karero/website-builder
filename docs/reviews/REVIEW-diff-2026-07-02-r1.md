# REVIEW — DIFF gate, PR #18, round 1 (2026-07-02)

Artifact: `git diff origin/main...HEAD` of `feat/independent-review-seo-reposition`
(the diff this repo's own `independent-review` skill was born in — dogfooded on itself).

## Reviewers (version / model / sandbox — recorded per the gate's own rule)
| Seat | Tool | Model | Sandbox | Outcome |
|---|---|---|---|---|
| cross-model 1 | codex-cli 0.142.3 (ChatGPT VS Code ext) | gpt-5.5 / xhigh | `exec -s read-only` | 12 findings (7 BUG · 4 RISK · 1 NIT) + Codex-compat verdict |
| cross-model 2 | antigravity-cli (agy) 1.0.14 | Gemini 3.1 Pro (High) | `--sandbox`, throwaway dir | 7 findings (3 BUG · 2 RISK · 2 NIT) |
| fresh-eyes | Claude (read-only sub-agent, no shared context) | Opus-class | read-only tools | ran pre-PR (Double-Knuth pass on the plan+script) |

## Dispositions

### Fixed (all BUGs — none waived)
- **gemini B1**: trap-guard now filters the blacklist to `Scope: everywhere`; slots-only stays with slot-guard (seo-reposition SKILL.md).
- **gemini B2**: `</dev/null` on every reviewer invocation — an interactive prompt inside the captured subshell can no longer hang the gate.
- **gemini B3 / codex 2**: independence rule rewritten — every tier runs, host-family = fresh-eyes; **gate requires ≥1 cross-model success**, same-family-only = degraded + owner waiver.
- **codex 3**: vendored double-knuth Pass 1 host-neutral (`/code-review` is the Claude-specific path, generic BUG/RISK/NIT diff review otherwise).
- **codex 4**: no-sub-agent fallback documented (fresh separate session, or record the pass as degraded).
- **codex 5**: design-doc contract text updated to the shipped default (ALL reviewers; `--first-success` opt-in).
- **codex 6**: design doc reframed with a BUILT status header — design record, not live proposal; skills win on disagreement.
- **codex 7**: removed the false `gl=us hl=en` default claim; explicit `gl`/`hl` required (the helper actually defaults to `gl=de`).
- **codex 9**: `looks_like_review()` — non-review stdout (rate-limit/refusal/auth text) no longer satisfies the gate. Negative-tested.
- **codex 12 / flag typos**: unknown flags now exit 2 with usage. Negative-tested.
- **gemini R1 / codex 10 (size half)**: 512 KB argv ceiling, fail-loud. Negative-tested.
- **gemini N1** (README path), **gemini N2** (`${cfg:-unknown}`), **codex 1 (docs half)**: script path documented as skill-relative with the installed location spelled out.

### Rejected, with reason
- **gemini R2 / codex 1 (relocation half)** — "move the script to root `scripts/`": rejected. `scripts/…` inside a SKILL.md is skill-relative by this repo's convention (see search-console-insights), and installs symlink the whole skill dir, so the path survives. Clarified in prose instead.

### Accepted residual — RISK waivers PENDING OWNER SIGN-OFF (per the gate's rule, a named human must waive)
- **codex 10 (argv visibility)**: the prompt is visible in `ps` while a reviewer runs. Proposed waiver: single-user dev machines, and the content is exactly what is being sent to that provider anyway; stdin-piping is a noted future improvement.
- **codex 8 (check_clean scope)**: root design docs aren't scanned by `check_clean.sh`, and this design record names the (owner's own, public) engagement sites. Proposed waiver: authentic review-trail history in the owner's own repo; the check_clean scope fix is tracked as a separate task.
- **codex 11 (website-review Claude-isms)**: pre-existing skill, out of this PR's scope; seo-reposition now warns Codex hosts to use the double-knuth generic path. Follow-up: Codex parity pass on website-review.

## Verdict
All BUGs fixed; guards negative-tested; both reviewers' CLEAN lists independently
confirmed the dispatch contract, exit-code/verdict separation, and the local-model
refusal. Gate satisfied **conditional on the three waiver sign-offs above**.

# DIFF review — karero/website-builder#148 (branch `feat/website-scorecard`) — an optional public scorecard skill

Base `4bddcad` · depth: Normal (a new skill whose script and component run in sites, plus a CI job) · verdict: **every BUG fixed and re-verified; no open finding except one RISK that only a real run can settle, which the pull request's `scorecard-skill` check does** · authority used: WORKTREE-WRITE and BRANCH-COMMIT — this session created the worktree and the branch; POST AUTHORITY — this session opens the pull request, on the owner's instruction in this session: "push it and open the PR once the review is clean", then "merge it once the checks are green".

**Data release consent** (owner, in this session, quoted verbatim): "Codex + ollama-cloud (Recommended)". ollama-cloud was at its weekly limit all day, so only Codex ran as the outside seat. Antigravity was not used for this change: the owner asked for it on the previous one only. The repo has no standing consent; this is session-scoped.

| Round | Head | Artifact | Reviewers: CLI version, model, effort, sandbox | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `21090dc` | full, `4bddcad...21090dc` | codex-cli 0.159.3, gpt-6.1-sol, config effort, read-only · fresh-eyes: host-family mid-tier model, read-only sub-agent | codex 446 s, 78 480 · fresh-eyes 650 s, 228 782 | 4 / 8 / 7 |
| 2 | `28f4d65` | delta since `21090dc` | codex, medium, read-only (`--seat codex`) | 327 s, 54 453 | 0 / 4 / 0 |
| 3 | `eb4e989` | delta since `28f4d65` | codex, medium, read-only | 167 s, 51 015 | 0 / 1 new + 2 re-raised / 0 |
| re-gate | `a63a5d6` | delta since `eb4e989` (one workflow step) | codex, medium, read-only | 163 s, 70 135 | 0 / 1 / 0 |
| re-gate | `80af978` | delta since `a63a5d6` (three lines of that step) | codex, medium, read-only | 157 s, 33 517 | 0 / 1 re-raised (T2) / 0 |
| re-gate | `32c2d9c` | delta since `80af978` (the workflow fix, X1) | codex, medium, read-only | 65 s, 22 881 | 0 / 0 new / 0 — the fix verified as written; acceptance by GitHub is shown by the run |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| S1 | BUG | codex, fresh-eyes | 1 | `SITE.locale` is removed on sites with several languages; the component threw | fixed · locally_verified · externally_reverified r2 | `28f4d65` |
| S2 | BUG | codex, fresh-eyes | 1 | "Edited since" ignored uncommitted edits | fixed · externally_reverified r2 | `28f4d65` |
| S3 | BUG | codex | 1 | A scorecard.json that is not valid JSON broke spec, component and generator | fixed · externally_reverified r2 | `28f4d65` |
| S4 | BUG | codex, fresh-eyes | 1 | Impossible dates accepted | fixed · externally_reverified r2 | `28f4d65` |
| S5 | RISK | codex, fresh-eyes | 1 | The spec took the expected age label from the page itself | fixed · externally_reverified r2 | `28f4d65` |
| S6 | RISK | codex | 1 | Page/file parity not asserted | fixed in two steps (see T1) · externally_reverified r3 | `28f4d65`, `eb4e989` |
| S7 | RISK | fresh-eyes | 1 | Public text claimed "tested before a change goes live" | fixed · externally_reverified r2 | `28f4d65` |
| S8 | RISK | fresh-eyes | 1 | "Copy the spec" while the spec imports the script | fixed · externally_reverified r2 | `28f4d65` |
| S9 | RISK | fresh-eyes | 1 | A guard that could never fire | removed · externally_reverified r2 | `28f4d65` |
| S10 | RISK | fresh-eyes | 1 | The three template files ran in no CI of this repo | fixed: job `scorecard-skill` · externally_reverified r2 (as wiring) | `28f4d65`; its first run is on the pull request |
| S11 | RISK | fresh-eyes | 1 | Plan row would go stale; doc and commit message disagreed on the scenario count | fixed · externally_reverified r2 | plan doc; `28f4d65`'s message |
| S12 | RISK | fresh-eyes | 1 | A host whose build has no git never shows the label; the skill never checked | fixed: SKILL.md §5 and "Done means" · externally_reverified r2 | `28f4d65` |
| S13–S18 | NIT | fresh-eyes | 1 | forbidOnly lost with CI cleared; unresolved argv[1]; temp dir, silence, UTC date; missing and dead area labels, no device class on the link; concrete numbers in the example; "everything" overclaimed | fixed · externally_reverified r2 | `28f4d65` |
| S19 | NIT | fresh-eyes | 1 | The forms decision row ticked in this change; loose wording | kept, reworded, sources added | the owner's answer in this session: "Cloudflare email (Recommended)" |
| T1 | RISK | codex | 2 | Summary accepted swapped numbers; the link check accepted any origin | fixed · externally_reverified r3 | `eb4e989` |
| T2 | RISK | codex | 2, 3, both re-gates | What the script does with a real Playwright report rests on the author's runs | fixed as far as a diff can: three CI steps exercise it with the locked Playwright. **Settled by the pull request's `scorecard-skill` check** | `eb4e989`, `a63a5d6`, `80af978` |
| T3 | RISK | codex | 2, 3 | Whether `form_factor` selects the device class | supported by measurement, below | — |
| T4 | RISK | codex | 2, 3 | The Cloudflare facts had no citation, then no checked contents | supported by the source, below | — |
| U1 | RISK | codex | 3 | No check of the card against counts the script did not produce | fixed · externally_reverified re-gate | `a63a5d6` |
| V1 | RISK | codex | re-gate | The CI step counted source lines to know the card's own tests | fixed · externally_reverified re-gate | `80af978` |
| X1 | BUG | GitHub Actions, first push of the branch | The changed workflow file was rejected ("workflow file issue"): the new job's `defaults` used the `runner` context, which is not allowed there. Neither the new job nor the starter's own suite ran on the pull request, while every other check was green | fixed · externally_reverified re-gate (structure); accepted by GitHub at `32c2d9c` (both jobs started) | `32c2d9c`. Found by looking for the two checks by name, not by the check count |

**Evidence for T3** (the author, a browser, 2026-10-04). `https://pagespeed.web.dev/analysis?url=<page>&form_factor=desktop` became `https://pagespeed.web.dev/analysis/<page-slug>/<run-id>?form_factor=desktop`, with the tab "Desktop" `aria-selected="true"` and "Mobile" `false`, and the requested page in the address field. The same address with `form_factor=mobile` selected "Mobile". The reviewers work without network and could not repeat it.

**Evidence for T4** (Cloudflare's Email Service page, read 2026-10-04). "Email Sending Beta for outbound transactional emails"; "Available on Workers Paid plan"; "Sending to verified destination addresses in your account is free on all plans". The decision row keeps one point open: whether a Pages Function can use the email binding directly.

Waivers and deferrals: none.

Follow-ups: each round marked the author's runs UNVERIFIABLE, since the starter's packages are not installed in the reviewers' checkout: 17 scenarios in a scratch copy of the starter, 12 deliberate breakages each caught by the skill's own test, the full suite with the card in place (64 passed, 1 pre-existing skip), type check, `make check`. The CI job added here repeats the core of them on every change. The scripts and each round's raw reviewer output are kept, untracked, in the main checkout under `docs/local/review-raw-website-scorecard/` until the pull request comment carries them.

Notes: the reviewers and a local YAML parser all passed the workflow that GitHub rejected (X1): none of them is GitHub's own validation, and only the missing checks on the pull request showed it. One outside seat (Codex, unbroken chain from round 1 to `80af978`) and a fresh-eyes pass in round 1; ollama-cloud at its weekly limit, so the pair was degraded, not chosen. Round 3 found no substantive BUG, so the rounds ended there; the two later Codex passes are re-gates of small deltas to one workflow step, needed so the reviewed head and the pushed head carry the same code. The cost log could not be written from this session; the table above is the record.

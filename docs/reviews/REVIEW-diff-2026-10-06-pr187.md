# DIFF review — karero/website-builder#187 — open findings: R-MELIOUS-THINK

Base `948a931` · depth: **Light gate** (one tracker row, docs nobody executes; same-family by the
owner's standing choice; owner: "add the row, open a PR and gate it") · verdict: **CLEAN** ·
authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the
branch, its checkout and the PR). Light gates carry no cross-model seat and no stamp marker.

Nothing left the machine: the one seat is the host's own `/code-review`. Prose change, so the claims
sweep ran before round 1: it flagged two sentences that overclaimed ("is not reviewed as written",
which kimi-k3 contradicts; the models named for the first sighting), both narrowed in `fc2128a`.

| Round | Head | Artifact | Reviewer | BUG/RISK/NIT |
|---|---|---|---|---|
| 1 | `fc2128a` | full `948a931...fc2128a` | `/code-review` at medium (Claude host) | 0/0/6 |

| id | Sev | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|
| T1 | NIT | 1 | "the setup guide states the limitation" is false on `main` (it covers only the leak) | fixed | `f1011e4`: "covers only the leak, not this" |
| T2 | NIT | 1 | "the seat's usual model" contradicts "the seat names no default" | fixed | `f1011e4`: "the model this repo's gates have used for the seat, which names no default" |
| T3 | NIT | 1 | #167's trail says Melious rewrote the tags; the row said only that it reads them as markers | fixed | `f1011e4`: both observations, with #167's FR1 |
| T4 | NIT | 1 | `melious_request.pl` has no think-tag handling; the current code is in `melious_stream.pl` | fixed | `f1011e4`: Location names both, and which holds what |
| T5 | NIT | 1 | the leak event is #165's, not #167's | fixed | `f1011e4`: cites #165 and #167 |
| T6 | NIT | 1 | the history line is one long line; the row lacks a close condition | fixed in part | `f1011e4`: the new sentence wrapped (the line was long before); a "Close when" clause added |

Waivers and deferrals: none. Follow-ups: none.

Notes: the round found no BUG, so Light ends after it. Its fixes are closing edits, re-swept for
claims but not re-reviewed ("closing edits not externally re-verified").

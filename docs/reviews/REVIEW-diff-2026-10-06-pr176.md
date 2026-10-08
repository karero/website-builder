# DIFF review — karero/website-builder#176 — the ollama CLI filter needs no Perl 5.10

Base `3d18d43` · depth: **Light gate** (a small fix to review tooling that touches no user data and no
production path; same-family by the owner's standing choice; owner: "open a PR and gate it" after Light
was proposed) · verdict: **CLEAN** · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT —
atom A (this session created the branch, its checkout and the PR). Light gates carry no cross-model seat
and no stamp marker.

Nothing left the machine: the one seat is the host's own `/code-review`.

| Round | Head | Artifact | Reviewer | BUG/RISK/NIT |
|---|---|---|---|---|
| 1 | `40410ce` | full `3d18d43...40410ce` | `/code-review` at medium (Claude host) | 0/4/2 |
| 2 | `c0f9e98` | full `3d18d43...c0f9e98` (the approach changed) | `/code-review` at medium (Claude host) | 0/3/3 |

| id | Sev | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|
| L1 | RISK | 1 | the version check skips the CLI tier silently, with no reason given | fixed (moot) | `c0f9e98`: no check; the filter's one `//` rewritten, so the tier runs |
| L2 | RISK | 1 | the fix treats a symptom: one `pos($s) // 0` was the only 5.10 feature | fixed | `c0f9e98`: `(defined pos($s) ? pos($s) : 0)` |
| L3 | RISK | 1 | the check ran before `ollama list`, hiding a broken daemon behind a skip | fixed (moot) | check removed |
| L4 | NIT | 1 | the tests did not prove why the tier was skipped | fixed | `oldcli` now expects the tier to run and count; `08fc953`: probe mark |
| L5 | NIT | 1 | the wrapper perl failed any argument merely containing the probe text | fixed | exact-match `'require 5.010'` |
| L6 | NIT | 1 | a third copy of the probe | fixed (moot) | check removed; two copies remain, one per API transport |
| M1 | RISK | 2 | `oldcli` cannot catch other 5.10+ constructs (the wrapper runs a modern Perl) | fixed by narrowing the claim | `08fc953`: comment and test name claim only "no `//`, no version check" |
| M2 | RISK | 2 | the "Perl 5.8" claim is wider than the `//`-only check | fixed by narrowing the claim | as M1 |
| M3 | NIT | 2 | the `//` check scanned shell code, so `${x//y}` or a URL would fail it falsely | fixed | `08fc953`: reads the Perl program alone; mutation: shell `${OLLAMA_MODEL//:/_}` passes, filter `//` fails |
| M4 | NIT | 2 | Perl compatibility rests on per-construct grep guards; move the Perl into `.pl` files and check its minimum version | follow-up | wider than this two-line fix |
| M5 | NIT | 2 | early 5.8 Encode treats "UTF-8" laxly, so "runs on 5.8" overstates | fixed by narrowing the claim | no 5.8 claim remains |
| M6 | NIT | 2 | `oldapi` did not prove the skip came from the version probe | fixed | the wrapper marks a refused probe; `oldapi` requires it, `oldcli` its absence |

Tests: `oldcli` and the CLI-filter `//` check fail on this PR's first head (`40410ce`); the `//` check
also fails on `main`. All suites and repo checks pass at `08fc953`.

Waivers and deferrals: none.

Follow-ups:
- Move the embedded Perl programs into `.pl` files and check their minimum Perl version with a real tool, replacing the per-construct guards (M4).
- The API transports still skip with only "SKIPPED (not available)" when Perl is too old (from #172).

Notes: round 2 ran because round 1 changed the approach, not because it found a BUG; its fixes are
closing edits to comments and tests, not re-reviewed ("closing edits not externally re-verified").

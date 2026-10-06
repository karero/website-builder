# DIFF review — karero/website-builder#177 — the API transports' skip names the missing tool

Base `446358e` · depth: **Light gate** (a small fix to review tooling that touches no user data and no
production path, like #176; same-family by the owner's standing choice; owner: "open a PR and gate
it") · verdict: **CLEAN** · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A
(this session created the branch, its checkout and the PR). Light gates carry no cross-model seat and
no stamp marker.

Nothing left the machine: the one seat is the host's own `/code-review`.

| Round | Head | Artifact | Reviewer | BUG/RISK/NIT |
|---|---|---|---|---|
| 1 | `75b1e89` | full `446358e...75b1e89` | `/code-review` at medium (Claude host) | 0/3/3 |

| id | Sev | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|
| S1 | RISK | 1 | no perl at all reads "Perl 5.10 or newer not found", suggesting an upgrade rather than an install | fixed | `344da38`: `command -v perl` first → "perl not found"; `noperl` fails with that line removed |
| S2 | RISK | 1 | the skip reason reads the shared WHY, so a later WHY set before a `return 3` would leak into it | refuted | every `return 3` comes before any WHY assignment in its tier, and `run_tier` clears WHY before each tier; the tier contract comment says a tier returning 3 sets WHY only to name the missing tool |
| S3 | RISK | 1 | `nocurl` depends on the host: an ollama CLI in /usr/bin would take the CLI path | fixed | `344da38`: `OLLAMA_TRANSPORT=api` pinned in `nocurl` and `noperl` |
| S4 | NIT | 1 | one `ln` process per file in /usr/bin and /bin | fixed | `344da38`: two `ln` calls, then one `rm` of the dropped tool |
| S5 | NIT | 1 | the new `apinomodel` check duplicated an existing one | fixed | `344da38`: dropped |
| S6 | NIT | 1 | two perl startups per API tier instead of one | refuted (not material) | a few milliseconds before a review that takes minutes; separate probes keep each reason exact and the test wrappers matching one probe each |

Tests: `oldapi`, `nojson` and `nocurl` fail on `main`; `noperl` fails without the `command -v perl`
line. All suites and `make check` pass at `344da38`.

Waivers and deferrals: none.

Follow-ups:
- Move the embedded Perl programs into `.pl` files and check their minimum Perl version with a real tool, replacing the per-construct guards (from #176, M4).

Notes: Light runs one round plus one only after a BUG; round 1 found none. Its fixes are closing
edits to one guard line and to tests, not re-reviewed ("closing edits not externally re-verified").

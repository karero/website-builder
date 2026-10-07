# DIFF review — karero/website-builder#185 — an API failure's summary names its cause, not just HTTP 200

Base `1b89bcb` · depth: **Light gate** (a small fix to review tooling that touches no user data and no
production path, like #176 and #177; same-family by the owner's standing choice; owner: "open a PR
and gate it" after Light was proposed) · verdict: **CLEAN** · authority used: POST AUTHORITY,
WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the branch, its checkout and the PR).
Light gates carry no cross-model seat and no stamp marker.

Nothing left the machine: the one seat is the host's own `/code-review`.

| Round | Head | Artifact | Reviewer | BUG/RISK/NIT |
|---|---|---|---|---|
| 1 | `022711b` | full `1b89bcb...022711b` | `/code-review` at medium (Claude host) | 0/6/2 |
| 2 | `97a4f5b` | delta `022711b..97a4f5b` (round 1 changed two readers' logic; not owed at Light, run anyway) | `/code-review` at medium (Claude host) | 0/5/1 |

| id | Sev | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|
| L1 | RISK | 1 | a 200 reply that is one JSON error object read "not a stream" | fixed | `97a4f5b`: exit 9, "error reply, not a stream"; `mnotstreamerr` |
| L2 | RISK | 1 | a 200 body that is neither a stream nor JSON (a proxy page) read "truncated review" | fixed | `97a4f5b`: "not a stream", quoted; `mhtml` |
| L3 | RISK | 1 | a die outside an eval exits with errno, colliding with the new codes | fixed | `97a4f5b`: `__DIE__` handler, exit 1; measured: without it the same die exits 5 ("no review text") |
| L4 | RISK | 1 | an unopenable response file on a non-200 reply read "empty reply" | fixed | `97a4f5b`: keeps the status (exit 2) |
| L5 | RISK | 1 | the ollama API transport has the same "HTTP 200" gap | fixed | `97a4f5b`: same wording on that transport; `apinonjson`, `apimiderr`, `apiempty` |
| L6 | NIT | 1 | the no-text fallback hard-coded HTTP 200 | fixed | `97a4f5b`: `$code` |
| L7 | NIT | 1 | the code-to-wording tables live in two files and can drift | refuted (not material) | each code's wording is pinned by a test of the summary line, so a renumbering fails them |
| L8 | NIT | 1 | the negative quota checks forbade one exact string only | fixed | `97a4f5b`: any Melious summary carrying a quota label (`grep -E 'melious FAILED \([^;]*; quota'`); shown to fail on such a line |
| M1 | RISK | 2 | keep-alive comments with no data, then a closed stream, read "not a stream" | fixed | `b9f2869`: SSE lines fall through to "truncated review"; `mkeepalive` |
| M2 | RISK | 2 | a reader crash (exit 1) read a bare "HTTP 200" | fixed | `b9f2869`: "reply reader failed (HTTP <code>)"; an injected die in each reader, run through the script, reads so |
| M3 | RISK | 2 | ollama named a proxy page "a stream line that is not JSON" where Melious says "not a stream" | fixed | `b9f2869`: a first line that is not JSON is "not a stream"; `apihtml` |
| M4 | RISK | 2 | the die handler exits on a die during compilation inside an eval ($^S undef) | fixed | `b9f2869`: `return if !defined $^S \|\| $^S` |
| M5 | RISK | 2 | a stale .resp in a reused REVIEW_RAW_DIR could be read as this run's reply | refuted | the startup purge removes `ollama.resp` and `melious.resp` on every run (independent_review.sh, the `rm -f` of stale tier files); each transport calls once per run |
| M6 | NIT | 2 | the two code tables are near-duplicates; one helper would do | refuted (not material) | the readers' codes differ (7 and 9 are Melious-only) and the wording follows each protocol (SSE chunks, NDJSON lines); each table is pinned by its tests |

Tests: the new and changed checks (`mmiderr`, `mnotstream`, `msplit`, `mcr`, `mnotstreamerr`, `mempty`,
`mhtml`, `apinonjson`, `apimiderr`, `apiempty`) fail on `main`; `mkeepalive` and `apihtml` cover round 2.
All suites and `make check` pass at `b9f2869`.

Waivers and deferrals: none.

Follow-ups: none.

Notes: Light runs one round plus one only after a BUG; neither round found one. Round 2 ran because
round 1's fixes changed two readers' logic. Its fixes are closing edits, not re-reviewed ("closing
edits not externally re-verified"). The ollama transport was added to the PR's scope in round 1 (L5),
as offered to the owner before the PR opened.

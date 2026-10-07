# DIFF review — karero/website-builder#183 — the German Impressum's email hint says "[punkt]" on an English site

Base `b55b66b` · depth: **Light gate** (a small starter-template fix: one optional prop whose
default leaves every existing caller unchanged, plus a test; no user data, auth, or deploy path;
the owner suggested Light for a small template fix) · verdict: **CLEAN** · authority used: POST
AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the branch, its worktree
and the PR). Light gates carry no cross-model seat and no stamp marker.

Nothing left the machine: the one seat is the host's own `/code-review`.

| Round | Head | Artifact | Reviewer | BUG/RISK/NIT |
|---|---|---|---|---|
| 1 | `31dfca1` | full `b55b66b...31dfca1` | `/code-review` at medium (Claude host) | 0/0/0 |

No findings.

Tests: the new `email — /impressum hints use the page's language` check fails on two mutants
(Impressum without `lang="de"`; EmailLink keying on `SITE.locale` again), each with
`Expected "hello [at] example [punkt] com"`, `Received "hello [at] example [dot] com"`. Starter
suite at `31dfca1`: astro check clean, Playwright 64 passed, 1 skipped (the starter's own
positioning placeholder, skipped on `main` too). `make check` fails on `main` in `check_clean.sh`
(two pre-existing review trails, untouched here); every other script passes.

Waivers and deferrals: none.

Follow-ups:
- After #178 lands, its ContactForm can pass `lang={language}` to EmailLink instead of `text={emailHint(fallback, language)}`.

Notes: Light runs one round plus one only after a BUG; round 1 found none.

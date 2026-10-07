# DIFF review — karero/website-builder#172 — run_melious without s///r; honest Perl check

Base `778245a` · depth: **Normal** (reply parsing and a test guard; no key handling, no new
destination; owner: "open a PR and gate it" after Normal was proposed) · verdict: **CLEAN** ·
authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the
branch, its checkout and the PR); GATED-THIS-DIFF — atom A (kimi-k3's unbroken chain, round 1 full
through the narrow re-gate at `a6b80b3`).

**Data release consent** (owner, this session, verbatim): "ollama-cloud + Melious (Recommended)";
session-scoped. Data check: no keys or personal data in the diff. Seats: two external, per the owner.

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `563032c` | full `778245a...563032c` | ollama-cloud kimi-k2.7-code (default run, no fallback needed); Melious kimi-k3; fresh-eyes (Claude mid-tier sub-agent, read-only, tools) | ollama 191 s/19,103; kimi 121 s/9,528; fe 124 s/59,854 | 0/6/9 (one guard RISK raised by all three seats) |
| 2 `--verify` | `85a6096` | delta since `563032c` | ollama-cloud; Melious kimi-k3 | ollama 295 s/31,333; kimi 225 s/14,780 | 1/2/0 (BUG refuted) |
| 3 `--verify` | `a6864bd` | delta since `85a6096` | ollama-cloud; Melious kimi-k3 | ollama 600 s/50,356; kimi 89 s/7,257 | 1/1/2 (BUG refuted) |
| narrow re-gate | `a6b80b3` | delta since `a6864bd`: one comment block, one check label | Melious kimi-k3 | 44 s/3,936 | 0/0/0 |

| id | Sev | Source | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| P1 | RISK | fe, kimi, ollama | 1 | the static guard caught only `=~ s/…/…/…r` (other delimiters, tr/y, bare forms, its comment stripper) | fixed, ext. reverified (r2, r3) | `85a6096`, `a6864bd`: any s/tr/y with an r modifier, any delimiter, with or without `=~`; self-tests 17 must-catch and 7 must-pass lines; on `main` it lists exactly the three real uses |
| P2 | NIT | fe | 1 | `quoted()` cuts 300 bytes, not characters | fixed, ext. reverified | `85a6096` comment |
| P3 | NIT | fe | 1 | the CLI filter's `//` has no 5.10 gate | refuted | the new comment is scoped to the API transports; the CLI path is unchanged |
| P4 | NIT | fe | 1 | the non-200 quote's new control-byte collapse is untested | fixed, ext. reverified | `mbad502` fails on `main` |
| P5–P7 | NIT | ollama | 1 | `\x27` obscure; `quoted` name; "future" date | moot / refuted | heuristic removed; a comment explains `quoted`; the date is today's |
| Q1 | BUG | ollama | 2 | `()`/`[]` branches close with `}` | refuted | the file closes them with `\)`/`\]`; self-test catches `s(a)(b)r`, `s[a][b]gr` |
| Q2 | RISK | ollama, kimi | 2 | cutting at " # " hides a substitution after a string or pattern holding one; "any" overclaimed | fixed, ext. reverified (r3) | `a6864bd`: no inline-comment cutting (the safe direction); limits stated; check renamed |
| R1 | BUG | ollama | 3 | no branch for `|` | refuted | the generic delimiter branch takes `|`; self-test catches `s|a|b|gr` |
| R2 | RISK | ollama | 3 | strings and heredocs spelling an r-flag form also fail, undocumented | fixed, ext. reverified (re-gate) | `a6b80b3` comment |
| R3, R4 | NIT | ollama, kimi | 3 | self-test label and block header overclaimed | fixed, ext. reverified (re-gate) | `a6b80b3` |

Tests added or changed, each failing on `main`: the r-flag guard and its self-test, `mbad502`.

Waivers and deferrals: none.

Follow-ups:
- The r-flag guard is line-based: a substitution split across lines, or a nested paired delimiter, is not seen (stated in its comment).
- `ollama_via_cli`'s filter also uses `//` with no Perl gate (pre-existing; fresh-eyes, r1).

Notes: Normal depth, so fresh-eyes ran in round 1 only. Rounds 2–3 were owed by fixes to test logic;
round 3 raised no substantive BUG, so the rounds ended there. Its comment and label fixes got a narrow
re-gate from kimi-k3 for the stamp. The trail commit moves the head; the diff-scope (excluding
`docs/reviews/`) is byte-identical to `a6b80b3`, so the marker names the trail commit.

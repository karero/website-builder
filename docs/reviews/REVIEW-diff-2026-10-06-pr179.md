# DIFF review — karero/website-builder#179 — the Perl programs move to perl/*.pl, held to their declared Perl

Base `b55b66b` · depth: **Normal** (review tooling and a new CI job; no key handling, no new
destination; owner: "open a PR and gate it" after Normal was proposed) · verdict: **CLEAN** ·
authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the
branch, its checkout and the PR); GATED-THIS-DIFF — atom A (kimi-k3's unbroken chain: round 1 full
`b55b66b...bee69ac`, round 3 the whole delta `bee69ac..3877901`); MERGE — the owner, verbatim:
"merge it when the gate is clean".

**Data release consent** (owner, this session, verbatim): "ollama-cloud + Melious (Recommended)";
session-scoped. Data check: no keys, tokens or contact data in the diff. Seats: two external, per
the owner.

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `bee69ac` | full `b55b66b...bee69ac` | ollama-cloud kimi-k2.7-code (HTTP API); Melious kimi-k3; fresh-eyes (Claude mid-tier sub-agent, read-only, tools) | ollama 409 s/56,130; kimi 304 s/31,929; fe 330 s/117,625 | 0/5/8 |
| 2 `--verify` | `98c4735` | delta since `bee69ac` | ollama-cloud; Melious kimi-k3 **FAILED** (a reply of thinking only, no review text) | ollama 456 s/40,271; kimi 174 s | 0/4/1 (1 RISK, 1 NIT refuted) |
| 3 `--verify` | `3877901` | ollama: delta since `98c4735`; kimi: delta since `bee69ac` (its round 2 failed) | ollama-cloud (the script rejected the reply as not a review; a real clean review, counted by hand); Melious kimi-k3 (first try **FAILED**, the stream broke off; the retry counted) | ollama 387 s/37,014; kimi 411 s/18,431 (failed try 121 s) | 0/0/0 |

| id | Sev | Source | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | RISK | fe | 1 | the inline-Perl detector missed `perl -E`, `-e"…"`, heredocs, `-I lib -e`, `"$PERL" -e` | fixed, ext. reverified (r2, r3) | `98c4735`: an allowlist (`perl_lines`); each form is a self-test fixture and a mutation of the real script |
| F2 | RISK | fe | 1 | the self-test covered only the module verdict and accepted any output | fixed, ext. reverified | `98c4735`: every guard is a function with fixtures, each checked for its reason (`expect`); a broken detector fails 13 self-test cases |
| F3 | NIT | fe, kimi | 1 | without the module the version check is skipped outside CI, ending on "OK" | fixed in part, ext. reverified | `98c4735`: ends on a SKIP line. No single-construct fallback: it would bring back the guards this PR replaces; CI's `perl-minimum` job requires the module |
| F4 | NIT | fe | 1 | other scripts' inline Perl is not scanned | fixed, ext. reverified | header states the scope |
| F5 | RISK | ollama, fe (NIT) | 1 | `package.sh` REQUIRED lists one of seven perl files | fixed, ext. reverified | all seven listed; the zip always held them (`zip -r skills`; `make smoke`: 7 files) |
| F6 | NIT | fe | 1 | a mention in a comment counted as run | fixed, ext. reverified | `called_files` skips comments; fixture |
| F7 | NIT | fe, ollama | 1 | workflow comment wrapping | fixed, ext. reverified | `98c4735` |
| F8 | NIT | kimi | 1 | a listed file that is gone was skipped silently | fixed, ext. reverified | reported; fixture |
| F9 | NIT | kimi | 1 | `use Encode` inside the loop in `ollama_filter.pl` | fixed, ext. reverified | moved above the loop |
| F10 | NIT | kimi | 1 | the plain fixture judged twice | fixed, ext. reverified | judged once |
| F11 | RISK | ollama | 1 | the probe exemption assumes the probes' exact layout | refuted | fails closed, naming the line; the allowed fixtures are the real probe lines verbatim |
| F12 | RISK | ollama | 1 | the ceiling extraction assumes exactly one probe | fixed in part, ext. reverified | read inside `api_tools_ok` only; zero or two probes there still stop the check, loudly |
| F13 | NIT | ollama | 1 | the Makefile `check:` description is one long line | refuted (not material) | one `##` comment per target line is the file's convention; the line was long before |
| R1 | RISK | ollama | 2 | a versioned `perl5.34 -e` passed the allowlist | fixed, ext. reverified (r3) | `3877901`: `perl[0-9.]*`; fixture |
| R2 | RISK | ollama | 2 | the ceiling read stops at the first `}` in `api_tools_ok` | refuted | fails closed (no probe found), never a wrong ceiling; probe0/1/2 fixtures |
| R3 | RISK | ollama | 2 | a WHY message with a `$variable` read as inline Perl | fixed, ext. reverified | `$var` allowed, `$(` and backticks not; fixtures |
| R4 | RISK | ollama | 2 | names with a hyphen misreported | fixed, ext. reverified | `[A-Za-z0-9_-]`; fixtures |
| N1 | NIT | ollama | 2 | the failure message prints `perl\/*.pl` | refuted | `\/` in a sed replacement prints `/`; mutation output shows `perl/*.pl` |

Tests: the version check and its self-test fail with `//` restored in the CLI filter, `s///r` in the
Melious reader, each inline form fresh-eyes found, a stray, a missing and a comment-only file; the
tier-report suite runs every moved program. CI `perl-minimum` ran the self-test against apt's module.

Waivers and deferrals: none.

Follow-ups:
- Whether CI's `perl-minimum` job is a required status is a repository setting, not visible here.
- No real Perl 5.8 was available: that the ungated files compile there rests on Perl::MinimumVersion (fresh-eyes, UNVERIFIABLE).

Notes: rounds 2 and 3 were owed by fixes to the check's logic, not by a BUG; round 3 was clean from
both seats (stop condition a2). The merge of `main` (#182's reviewer-credit wording) carried one
comment line into `perl/melious_stream.pl`; the moved programs still match `main`'s inline text.
The trail commit moves the head; apart from that comment, the diff-scope (excluding
`docs/reviews/`) is the one round 3 read, so the marker names the trail commit.

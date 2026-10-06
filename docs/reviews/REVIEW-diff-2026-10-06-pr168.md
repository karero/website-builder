# DIFF review — karero/website-builder#168 — keep the repo's text LF in a CRLF checkout

Base `a7de280` · depth: **Normal** (repo-wide config that changes every checkout, plus the
release zip's file list; no auth, data or deploy path) · verdict: **CLEAN** · authority used:
POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session made every commit on the
branch and opened the PR) and atom B (owner, this session: "push it, open the PR and run the
review"); GATED-THIS-DIFF — atom A (Codex's and ollama-cloud's unbroken chains below).

**Data release consent** (owner, this session, verbatim): "Yes, Codex + Ollama Cloud
(Recommended)" — this diff to Codex and Ollama Cloud; session-scoped. Data check: no keys,
tokens, passwords or contact data in the diff.

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `0bc0b56` | full `a7de280...0bc0b56` | codex-cli 0.160.0 gpt-6.1-sol, config effort, read-only; ollama-cloud kimi-k2.7-code (CLI, text only); fresh-eyes (Claude Sonnet sub-agent, read-only, tools) | codex 213 s/49,761; kimi 238 s; fe 273 s/90,254 | 1/3/6 (the BUG is comment wording) |
| 2 `--verify` | `2b34614` | delta since `0bc0b56` | codex (medium); kimi | codex 218 s/36,869; kimi 239 s | 0/2/1 |
| 3 `--verify` | `d90fe09` | delta since `2b34614` | codex (medium); kimi | codex 180 s/46,437; kimi 159 s | 0/2/0 |
| re-gate (not a round; logged as `--round 4`) | `2d5cd5c` | delta since `d90fe09` | codex (medium); kimi | codex 86 s/19,805; kimi 179 s | 0/0/0 |

| id | Sev | Source | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| C1 | BUG (comment) | codex | 1 | comment said `make check` stops at the first script's `set -euo pipefail`; check_clean.sh sets `-uo` | fixed, ext. reverified (r2) | `2b34614`: "fails in its first script" |
| O-R1 | RISK | kimi | 1 | a Windows packager with autocrlf would zip CRLF scripts | refuted | `eol=lf` overrides core.autocrlf: autocrlf clone of `0bc0b56` has 0 CRLF text files; codex: all 358 files byte-identical under `cat-file --filters` with autocrlf=true, eol=crlf. A pre-existing clone is FE5 |
| O-R2a | RISK | kimi | 1 | `text=auto` could mangle a future binary | refuted | git classes png gif webp ico woff2 woff ttf pdf zip samples as `-text`; the og .jpg is `-text` and byte-identical after a CRLF checkout |
| O-R2b | RISK | kimi | 1 | a future .bat/.cmd needing CRLF would get LF | waived | owner, 2026-10-06: "Waive (Recommended)"; none exist today |
| O-R3 | RISK | kimi | 1 | unverified that `text=auto eol=lf` beats core.autocrlf=true | refuted | as O-R1 |
| O-N1, O-N2 | NIT | kimi | 1 | comment lines ~150 columns | refuted | measured ≤ 98, the repo's ~100-column wrap |
| FE3 | NIT | fe | 1 | nothing fails if the rule is weakened | fixed, ext. reverified (r2) | `2b34614` adds scripts/check_lf_checkout.sh; rule narrowed to `*.sh` → FAIL naming 328 files |
| FE4 | NIT | fe | 1 | scaffolded sites carry the same hazard | follow-up | template territory, see below |
| FE5 | NIT | fe | 1 | pulling this does not rewrite an existing CRLF clone | fixed, ext. reverified (r2) | measured: after the pull 27 of 28 .sh still CRLF, `git status` clean; after `git rm -r -q --cached . && git reset --hard` 0. Comment gives that rewrite |
| FE6 | NIT | fe | 1 | commit trailer names another model | refuted | it names this session's model, per its attribution instruction |
| R2-1 | RISK | codex | 2 | a global attributes file breaks the self-test | fixed, ext. reverified (r3) | reproduced: global `* text=auto eol=lf` → "FAIL — self-test"; `d90fe09` passes `core.attributesfile=/dev/null`, `init --template=` |
| R2-2 | RISK | kimi | 2 | comment said .gitattributes is read as staged | fixed, ext. reverified (r3) | measured both ways: checkout-index reads the working tree's |
| R2-3 | NIT | kimi | 2 | `mktemp` unguarded | fixed, ext. reverified (r3) | `d90fe09` |
| R2-4 | NIT | host | 2 | failure branch took > 2 min under bash 3.2 (`${out//…}` over 328 paths) | fixed, ext. reverified (r3) | `d90fe09`: 0 s |
| R3-1 | RISK | codex, kimi | 3 | failed `cd` into the export reads as "no CR" → passes unscanned | fixed, ext. reverified (re-gate) | `2d5cd5c`; harness on a missing dir: status 0 before, 1 after |
| R3-2 | RISK | codex | 3 | self-test `git add` still read global attributes | fixed, ext. reverified (re-gate) | global required clean filter `false`: `d90fe09` fails to build the self-test, `2d5cd5c` passes |

UNVERIFIABLE questions: round 1, 4 asked (Windows bash with CRLF; Windows unzip tools; script
behavior; binary inventory), 0 confirmed. Rounds 2–3 and the re-gate repeated git and shell
behavior I had measured (`--template=` vs init.templateDir; subshell `exit 2` leaves the parent's
EXIT trap alone): 0 confirmed. Git for Windows' bash running a CRLF script stays unchecked.

Waivers and deferrals: O-R2b waived by the owner, 2026-10-06, verbatim above. No deferrals.

Follow-ups:
- FE4: a scaffolded site's own scripts and data read the same way. Another open PR adds the
  template's `.gitattributes` for `*.sh` and `scripts/hooks/*` only; whether the site's checks
  also read Markdown or JSON as data was not checked here.

Notes: all three seats counted in round 1; the pair counted in every later link. No round past 3.
The re-gate checked the round-3 fixes for the stamp, not a round. No wording pass: no round had a
substantive BUG, and the change adds no record prose outside this trail. Only stock bash 3.2
was available locally; the CI `lf-checkout` job runs the guard under bash 5.

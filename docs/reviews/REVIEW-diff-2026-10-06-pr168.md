# DIFF review — karero/website-builder#168 — keep the repo's text LF in a CRLF checkout

Base `a7de280`, after merging main `1b89bcb` · depth: **Normal** (repo-wide config that changes every checkout, plus the
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
| merge link (not a round; logged as `--round 5`) | `f507e77` | `merge_link.sh a7de280 2d5cd5c 3dac351`: the PR's 5 files, merge effects included | codex (medium); kimi | codex 144 s/69,191; kimi 217 s | 0/0/0 for this PR (2 RISK: 1 refuted, 1 not this PR's) |
| merge link 2 (not a round; logged as `--round 6`) | `eefc9a9` | `merge_link.sh 3dac351 f507e77 1b89bcb`: 4 files | codex (medium); kimi | codex 127 s/63,173; kimi 78 s | 0/0/0 for this PR (kimi: 3 RISK, 2 NIT, all on #179's content) |
| Windows job (owner-requested addition; logged as `--round 7`) | `4216d7b` | delta since `8b82584` | codex (medium); kimi | codex 123 s/51,723; kimi 324 s | 2/2/0 (both BUGs refuted) |
| Windows verify 1 (`--round 8`) | `e6e3529` | delta since `4216d7b` | codex (medium); kimi **FAILED** (quota) | codex 115 s/27,707 | 0/1/0 |
| Windows verify 2 (`--round 9`, `--seat codex`) | `57a63e9` | delta since `e6e3529` | codex (medium) only: **degraded**, ollama out of quota | codex 118 s/34,024 | 0/1/0 (re-raise, no new evidence) |

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
| ML-1 | RISK | codex | merge | README's contact-form claim ("mails each message to the owner") rests on an unverified Cloudflare API contract | outside this PR | main's text from #174, not this change; passed to that PR's owner |
| ML-2 | RISK | kimi | merge | `.gitattributes` not in the zip list or REQUIRED | refuted | it sees only lines changed since `2d5cd5c`; `package.sh:30` (zip) and `:53` (REQUIRED) hold it since `0bc0b56`; a fresh build contains it; codex: `zip -sf` lists every REQUIRED path |
| ML2-1–5 | RISK ×3, NIT ×2 | kimi | merge 2 | #179's Perl check: Makefile says it skips without Perl::MinimumVersion; `actions/checkout@v7`; the seven `perl/*.pl` in REQUIRED; long help line; long CI comment | outside this PR | all #179's text, merged into main; codex compiled all seven `.pl` and found #179's wiring intact; passed to #179's owner |
| W-1 | RISK | codex | win | a control that proves `git clone` converts does not prove actions/checkout did | fixed in steps, then settled by the Windows run | `e6e3529` read core.autocrlf after checkout (codex: an override during checkout would not show); `57a63e9` replaces it with a canary: actions/checkout of `a7de280` (no `.gitattributes` anywhere) into `canary/` must come out CRLF. Locally: autocrlf=true → pass, false → fail. Codex re-raised it at `57a63e9` (ref/path differ) with no new evidence and named the settling observation, a Windows run; `lf-checkout-windows` passed on `57a63e9` (job 112296545457), and both its canary and its scan exit 1 on failure |
| W-2, W-3 | BUG | kimi | win | under `node -e` the first argument is argv[2] | refuted | `node -e 'console.log(JSON.stringify(process.argv))' a b` → [node, a, b]; template-tests' verify-windows uses argv[1] and passes in CI |
| W-4 | RISK | kimi | win | the control's source might be written CRLF | fixed (`e6e3529`), then superseded | the canary's blob is LF in the index |

UNVERIFIABLE questions: round 1, 4 asked (Windows bash with CRLF; Windows unzip tools; script
behavior; binary inventory), 0 confirmed. Rounds 2–3 and the re-gate repeated git and shell
behavior I had measured (`--template=` vs init.templateDir; subshell `exit 2` leaves the parent's
EXIT trap alone): 0 confirmed. Git for Windows' bash running a CRLF script stays unchecked.

Waivers and deferrals: O-R2b waived by the owner, 2026-10-06, verbatim above. No deferrals.

Follow-ups:
- FE4: a scaffolded site's own scripts and data read the same way. #165 (merged before this
  PR) gives the template a `.gitattributes` for `*.sh` and `scripts/hooks/*` only; whether the
  site's checks also read Markdown or JSON as data was not checked here.
- ML-1 (#174's README claim) and ML2-1–5 (#179's Perl check) belong to those changes' owners.

Notes: all three seats counted in round 1; the pair counted in every later link. No round past 3.
The re-gate checked the round-3 fixes for the stamp, not a round. No wording pass: no round had a
substantive BUG, and the change adds no record prose outside this trail. Only stock bash 3.2
was available locally; the CI `lf-checkout` job runs the guard under bash 5.
Merge of main (`f507e77`): 88 commits; Makefile, package.sh, README and clean.yml conflicted on
list entries and were resolved by keeping both sides. GitHub SSH was timing out, so the app's sync
could not fetch; local `origin/main` matched the API's `3dac351`, and the merge was done here.
Main then moved to `1b89bcb` (#179, touching four of this PR's files): a second merge (`eefc9a9`,
one Makefile conflict) and merge link 2 — the second and last re-gate attempt clerk item 2 allows.
Pushes went over HTTPS (`url.https://github.com/.insteadOf=ghdirect:` for one command), since the
global insteadOf sends https://github.com/ to SSH.
The owner then asked for a Windows CI proof (brief R9-6, step 4): `lf-checkout-windows`, reviewed
as an addition past round 3 (owner's request; no round there was earned by a substantive BUG, and
the last pass was Codex alone while ollama-cloud was out of quota). Main moved to `4e69534`
(#184–#186) without being merged in: only README.md overlaps, the trial merge was clean and
`make check` passed on it, and PR CI tests the merge ref.

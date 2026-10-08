# DIFF review — karero/website-builder#189 — CI checks private names: the list from a repo secret, scanned text withheld from the public log
Base `3a7207d` (first artifact: `4e69534`; redesign: `b8d7136`) · depth: High (a secret, and what reaches a public log) · verdict: CLEAN at `684a377` — every finding fixed or refuted (the follow-up rounds below); the last code fixes and the last wording fix each confirmed by Codex, the seat with an unbroken chain · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the PR, its worktree and its branch); GATED-THIS-DIFF — atom A (codex's chain: full redesign round, then each delta and the merge link to `d35ab50`)

Owner's OK to send this repo's diffs out (2026-10-06, this session): "Yes, Normal depth (Recommended)" — Codex + ollama-cloud. melious.ai (2026-10-07, this session): "Yes, use melious (Recommended)". Owner's design call after round 4: "Withhold hit lines (Recommended)". Owner on each later round's findings: "go ahead and fix all five", "go ahead and fix all four", "go ahead and fix what round 3 finds".

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `e12d0fa` | full, `4e69534...e12d0fa` | codex-cli 0.160.1 (gpt-6.1-sol, config effort, read-only); ollama 0.35.1 kimi-k2.7-code:cloud (text only); fresh-eyes Opus sub-agent | codex 379/52886; ollama 365; fresh 417/138006 | 6/6/5 |
| 2 | `4e591a0` | delta | same three | codex 352/58058; ollama 299; fresh 472/152195 | 3/2/3 |
| 3 | `8173e17` | delta | same three | codex 340/73670; ollama 451; fresh 683/157264 | 2/3/4 |
| 4 | `99d184e` | delta | same three | codex 441/63933; ollama 665; fresh 994/151487 | 3/5/4 |
| redesign 1 | `962091d` | full, new artifact (merge of `b8d7136`) | codex; ollama FAILED (429 usage limit); fresh-eyes Opus | codex 653/96131; fresh 776/172016 | 5/1/4 |
| redesign 2 | `da0ebfc` | delta | codex; ollama FAILED (429); fresh-eyes | codex 426/69651; fresh 672/140451 | 2/2/4 |
| redesign 3 | `67c3a3f` | delta | codex; ollama kimi-k2.7-code; fresh-eyes | codex 239/62945; ollama 366; fresh 331/128183 | 2/1/2 |
| re-gate | `d35ab50` | merge link `67c3a3f`→`d35ab50` (fixes `ee45a31` + merge of `d065dbd`) | codex (--seat codex); fresh-eyes | codex 297/104354; fresh 492/110959 | 0/0/4 |
| final full read | `d35ab50` | full, `d065dbd...d35ab50` | ollama glm-5.3:cloud (new to this change) | 695 | 0/2/2 |

Findings (consolidated across seats; raw text in the PR comments):

| Round | Fixed | Refuted | Open |
|---|---|---|---|
| 1 | per-report masking leaks (other reports, `_`/digits, perl errors); masked hit→pass; GNU binary hits on stderr (pre-existing); CRLF/empty secret; forks; `--repo`; wording | `checkout@v7`; stale list on skip path; Dependabot login (`dependabot[bot]`, from `gh api`) | — |
| 2 | here-string status; list words in fixed text; F5 test fixture; newline binary names | email test asserts absence (helper does) | — |
| 3 | survivor pipeline status (PIPESTATUS); runner masks each secret line → base64; perl first-alternative leftovers; GNU split messages; mktemp fail-open; BUGLOG `$` claim | — | — |
| 4 | empty-match hang; anchored entries; macOS base64 accepts garbage; partial base64; split-message spoof; Makefile failure | mktemp/split `fail=1` (report sets it); inner exit code (exits `$rc`) | → owner chose to replace blanking with withholding |
| redesign 1 | withhold without a list (owner's call over my refutation); `^` entries; exemptions matched file names; filter-grep errors; prefix marker; newline names; messages; `base64 --decode` | — | — |
| redesign 2 | colon-digit names; inner anchors refused; `find` fail-open; sed stage; each `gf` site tested; compile message; one walk | — | — |
| redesign 3 | compile check under SIGPIPE (`141 2`); plain `^name` test; refusal wording | "space before `\` breaks the find guard" (no backslash is followed by whitespace; `bash -n`; the find-failure test fires) | — |

Every fix has a test; undoing each turned its case red (locally, and under GNU grep 3.8 in Docker for the GNU-only paths), except the self-filter `gf`, which the pipeline's `||` guard also covers.

Follow-ups (open at merge; the owner said "Merge" while the decision on the two RISKs was being asked):
- RISK (final read): under GNU grep in the C locale, `\b` never matches beside a non-ASCII letter, so CI misses such names. Pre-existing; `docs/BUGLOG.md` row open.
- RISK (final read): nothing detects a stale secret; a name added locally without `make push-denylist` is not checked in CI (local `make check` still is).
- NIT (fresh-eyes re-gate): `make push-denylist`'s comment and message say "anchored"; the check says "holding ^" and that a literal `\^` is refused too.
- NIT (fresh-eyes re-gate): a 135-character comment line in check_clean.sh's odd-name block.
- NIT (fresh-eyes re-gate; codex): test label "a colon, a digit and a colon"; comment "and printf of SIGPIPE" lacks its verb.
- NIT (final read): in push(), `cat` of an absent gh.log feeds `grep -q`; harmless without pipefail, `|| :` would harden it.
- Refuted (final read): "`^✗ scan error` in the name post-filter is dead" — `gf()`'s own error line reaches that filter.

Notes: rounds past 3 of the first artifact: round 4, earned by round 3's BUGs (survivor status, secret-line masking, perl alternation). After round 4 the convergence check failed (each round found new holes in the name-blanking code) and the owner chose a redesign, reviewed as a new artifact. Redesign rounds 1–2 ran with one cross-model seat (ollama's usage limit); the final full read by glm-5.3 restored a second model. Live CI: with the secret set, `no-pii-secrets` on `d35ab50` (run 37533028146) shows `CLEAN_DENYLIST: ***` and an OK line that says private names were checked.

## Follow-up rounds (2026-10-07)

Before merging, the owner asked to fix the two RISKs and five NITs left open above ("Fix them"), then "fix what the review finds, then merge" for each later round.

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| follow-up 1 | `13eff0a` | delta `daaf3d6..13eff0a` | codex (config effort); melious glm-5.3 (HTTP API); fresh-eyes Opus | codex 416/67492; melious 305/40966; fresh 737/141218 | 1/4/6 |
| follow-up 2 | `5c2f680` | merge link `13eff0a`→`5c2f680` (fixes `5bf2979` + main `63e2353`) | same three | codex 557/107031; melious 105/28352; fresh 513/147193 | 2/1/4 |
| follow-up 3 | `779b7d5` | merge link `5c2f680`→`779b7d5` (fixes `90a4e09` + main `471a04f`) | same three | codex 501/88145; melious 58/14077; fresh 546/131162 | 2/2/2 |
| confirmation | `f13d114` | merge link `779b7d5`→`f13d114` (fixes `5520031` + main `3a7207d`) | codex (--seat codex, config effort) | codex 212/57404 | 1/0/0 (wording) |
| confirmation of that fix | `684a377` | delta `f13d114..684a377`, prose only (comments and a BUGLOG row; no executable line) | codex (--seat codex) | codex 151/41765 | 0/0/0 |

| Round | Fixed | Refuted |
|---|---|---|
| follow-up 1 | non-ASCII name edges (explicit edges); stale secret (checksum of what was pushed, kept beside the list, `make check` fails on a change); the five NITs; then from its review: edges lost punctuation-edged names (each pattern now tries edges OR `\b`), stale check skipped an emptied list, encode/checksum read the list twice, README overstated the guard, reminder in masked mode / untested / worded for zip users, checksum-write failure message, names-only checksum | — |
| follow-up 2 | push and check read "the names" in different locales (recipe exports `LC_ALL=C`); emptied-list dead end (says to add a name back); BSD-grep comment; test expectations mirror the recipe | "pre-existing whole-file checksums fail once" — that version never merged |
| follow-up 3 | the UTF-8 test was vacuous on Linux (now an em space in C.UTF-8, guarded, skips loudly); the masked check's `\b` alternative is pinned by a test; comment and BUGLOG wording | "the check side is not pinned to C" — `check_clean.sh` line 18 exports `LC_ALL=C` |

Accepted as a stated limit: a push of another copy of the list from another checkout cannot be seen locally (gh never reads a secret back); the README and the check's comment say so.
The confirmation's one finding: "\b misses a non-ASCII-edged name wherever another character touches that letter" overstated it; now "can miss … with a space beside it for one" (`684a377`), confirmed against BSD grep by Codex; GNU grep 3.8 showed the same misses in Docker (putting `\b` back turned both non-ASCII cases red).

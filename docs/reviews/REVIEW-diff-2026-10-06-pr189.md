# DIFF review — karero/website-builder#189 — CI checks private names: the list from a repo secret, scanned text withheld from the public log
Base `d065dbd` (first artifact: `4e69534`) · depth: High (a secret, and what reaches a public log) · verdict: OPEN — merged on the owner's instruction ("Merge", 2026-10-07) with 2 RISK and 5 NIT open as follow-ups, below · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the PR, its worktree and its branch); GATED-THIS-DIFF — atom A (codex's chain: full redesign round, then each delta and the merge link to `d35ab50`)

Owner's OK to send this repo's diffs out (2026-10-06, this session): "Yes, Normal depth (Recommended)" — Codex + ollama-cloud. Owner's design call after round 4: "Withhold hit lines (Recommended)". Owner on each later round's findings: "go ahead and fix all five", "go ahead and fix all four", "go ahead and fix what round 3 finds".

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

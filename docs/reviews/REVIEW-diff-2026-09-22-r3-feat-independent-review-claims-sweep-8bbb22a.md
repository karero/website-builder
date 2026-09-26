# Independent review — DIFF — claims sweep for prose gates (rounds 1–3)

Branch `feat/independent-review-claims-sweep`, base `origin/main` `b586b4b`; rounds reviewed
`6971a4f`, `9f9181d` and `8bbb22a`. No PR yet.

**The change.** An advisory script, `skills/independent-review/scripts/sweep_claims.sh` (a bash
launcher for `sweep_claims.py`), lists the sentences a prose change adds that assert an absence
or a universal ("never", "only", "first", "has not"), so the author can check them before round
1. It reads paragraphs, list items, headings and table cells as running text, so a phrase
wrapped across a line break is seen. It comes with `test_sweep_claims.sh` (wired into
`make check` and CI), `references/claims-sweep.md`, and three lines in `SKILL.md`.

**Verdict: gate FAIL at the three-round cap; the open items wait on the owner.** R1-08 (a
removed qualifier widens a claim the sweep does not list) and R1-27 (one file under two
spellings is listed twice), both first raised in round 1, are still open after round 3
(Procedure step 6(b)). The findings are not oscillation: each round's land on code the
previous round's fixes added (step 7(b) passes). The count plateaus instead (BUG and RISK
raised per round: 13, 8, 9), because the surface is bigger than first estimated: the sweep has
become a Markdown parser and a diff interpreter, and each round finds new edge cases in both.
Patching stopped at `8bbb22a`; the decision it needs is below. Nothing was pushed.

## Rounds

| Round | Reviewed | Reviewers — CLI, model, sandbox | Raised | Unique |
|---|---|---|---|---|
| 1 | `6971a4f` | Codex CLI 0.155.1, `gpt-6-astra`, `exec -s read-only` from the checkout; ollama 0.34.2, `kimi-k2.7-code:cloud`, text only; fresh-eyes Claude sub-agent, no shared context, read-only checkout plus a scratch directory | 31 (4 + 8 + 19) | 27 |
| 2 | `9f9181d` | same three seats (a new fresh-eyes agent each round) | 23 (4 + 6 + 13) | 18 |
| 3 | `8bbb22a` | same | 27 (4 + 9 + 14) | 18 |

Every round closed with `reviewers: codex OK, ollama-cloud OK`, so the cross-model requirement
was met each time. Rounds 2 and 3 opened with an author's brief listing the previous round's
findings and dispositions; Codex and ollama-cloud noted its reviewer-directed sentences as
steering and reviewed normally. Verbatim output of every seat: the three `RAW-diff-…` files
beside this one.

## Round 1 (on `6971a4f`; fixes in `9f9181d`)

| id | sev | source | finding | disposition |
|---|---|---|---|---|
| R1-01 | BUG | Codex | A fence opened on a list line (`- ```sh`) is not seen; its closing fence opens a new one and swallows the rest of the file | fixed `9f9181d`: fences are recognised after a list marker. Test Q |
| R1-02 | BUG | Codex, fresh-eyes | "e.g." splits a sentence; an edit in one half and the claim word in the other means the claim is lost. The doc's "nothing is lost" was false | fixed `9f9181d`: no split before a lowercase word or after "e.g."/"i.e."; doc bullet rewritten with the remaining limit. Tests P, plus one per rule |
| R1-03 | BUG | Codex, fresh-eyes | The reference doc says run `scripts/sweep_claims.sh` "from the repository under review", but `scripts/` is relative to the skill | fixed `9f9181d`: `<skill>/scripts/…` with `<skill>` defined |
| R1-04 | BUG | Codex, fresh-eyes | `diff.interHunkContext` makes hunk ranges include unchanged lines | fixed `9f9181d`: counts `+` lines and passes `--inter-hunk-context=0`. Hostile-settings test |
| R1-05 | BUG | fresh-eyes | An rst `~~~` underline is read as a fence and swallows text in .rst/.txt | fixed `9f9181d`: fences in .md/.markdown only; an unclosed fence is reported on stderr. rst test |
| R1-06 | RISK | ollama, fresh-eyes | A wrapped line starting "2024." is read as a list item, so an edit on it is cut off from the claim on the line before | fixed `9f9181d`: inside a paragraph only "1." starts a list (CommonMark). Test O |
| R1-07 | RISK | fresh-eyes | "will not", "won't", "wouldn't", "should not" are not in the word list | fixed `9f9181d` for will/would forms; "should not" left out on purpose (an instruction, not a claim about the record), documented. Test R |
| R1-08 | RISK | fresh-eyes | A deletion that widens a claim ("except on a timeout." removed) is invisible | fixed `9f9181d`: a pure deletion marks the lines either side. Test N. A deletion in another paragraph stays a documented limit |
| R1-09 | RISK | fresh-eyes | The test passes with `:(top)`, `--exclude-standard`, `--no-color` or `--diff-filter=d` removed | fixed `9f9181d`: hostile-settings run from a subdirectory, gitignored file, deleted file. Mutation run: each removal now fails a check |
| R1-10 | RISK | fresh-eyes | A file git treats as binary (`-diff` attribute, NUL byte) is counted as swept with no added lines | fixed `9f9181d`: `--text`. Hostile run sets `* -diff` |
| R1-11 | RISK | ollama | The test exits 0 (SKIP) without git, so `make check` can pass without running it | refuted: the same convention as `scripts/test_install_pin.sh` (a zip recipient without git must not fail `make check`); the skip prints SKIP, and CI's runner has git |
| R1-12 | RISK | ollama | Blank lines inside list items or blockquotes split sentences | refuted: in Markdown a blank line ends a paragraph, inside a list item or blockquote too, so no sentence spans one |
| R1-13 | RISK | ollama | Broad words (since, until, must, by design, on purpose) add noise | waived, pending owner confirmation: the handover asked to keep the reference script's word list ("the reference's list is the one that proved useful"); "since"/"until" carry time-bound claims ("unchanged since R") |
| R1-14 | NIT | ollama | Makefile description does not name the scripts | refuted: the description names checks, not scripts, and did so before this change |
| R1-15 | NIT | ollama | CI job has no `name:` and is not folded into another job | refuted: matches the file — no job has a `name:`, and single-script jobs (`review-reporting`, `install-pin`) are their own jobs |
| R1-16 | NIT | ollama | A path containing `:` makes the output unparseable | refuted: the output is read by a person, in the same `path:line` form as `grep -n`; nothing parses it |
| R1-17 | NIT | ollama | Indented code blocks are not pinned by a test | fixed `9f9181d`: KNOWN WRONG fixture |
| R1-18 | NIT | fresh-eyes | The test fails 26 checks without python3 instead of skipping | fixed `9f9181d`: skips like git; Makefile note updated |
| R1-19 | NIT | fresh-eyes | `diff.relative=true` from a subdirectory drops files | fixed `9f9181d`: `-c diff.relative=false`. Hostile run |
| R1-20 | NIT | fresh-eyes | Unreadable `--file` gives a traceback and exit 1 | fixed `9f9181d`: exit 2 with a message. Test |
| R1-21 | NIT | fresh-eyes | Unrelated histories: "git merge-base: exit 1" | fixed `9f9181d`: "no common ancestor". Test |
| R1-22 | NIT | fresh-eyes | Broken pipe: exit 120 and a traceback | fixed `9f9181d`: exit 0, no traceback. Test |
| R1-23 | NIT | fresh-eyes | Exported CDPATH breaks the launcher's `cd` | fixed `9f9181d`: `CDPATH= cd --`. Verified by hand (no test) |
| R1-24 | NIT | fresh-eyes | The docstring's "blind spots" are fixed bugs; real limits are elsewhere | fixed `9f9181d`: "Past blind spots, now pinned"; limits point to the doc |
| R1-25 | NIT | fresh-eyes | Docs say `path:first-last`; a one-line sentence prints `path:N` | fixed `9f9181d`: doc and help say both |
| R1-26 | NIT | fresh-eyes | Named paths resolve against `--repo`, undocumented | fixed `9f9181d`: help and doc say so |
| R1-27 | NIT | fresh-eyes | `--base` plus `--file` on one file lists sentences twice | fixed `9f9181d`: identical lines listed once. Test |

Unverifiable (Codex, fresh-eyes): the doc's numbers from the source review. Checked by the author against that review's own trail (a private repository): 6 rounds and 83 findings, the phrase that reached round 5, the seat lost after about 25 minutes, and "first" being testable only with every job record are recorded there; "about 200 added lines" matches its diff (188). "30 to 40 minutes a round" and "about 4 of 45" are not in the trail and were removed; "from round 3 on" was narrowed to "rounds 3, 4 and 5".

## Round 2 (on `9f9181d`; fixes in `8bbb22a`)

Three round-1 fixes had only half landed (R1-06, R1-08, R1-27); they keep their round-1 ids, so round 3 is their last under the three-round cap.

| id | sev | source | finding | disposition |
|---|---|---|---|---|
| R1-06 | BUG | Codex, fresh-eyes | A wrapped "2024." still splits inside a list item: the rule was skipped whenever a list was open | fixed `8bbb22a`: a numbered line other than 1 starts an item only as a sibling (indented less than the item's content column). Tests: list-item year, sibling item |
| R1-08 | BUG | Codex, ollama, fresh-eyes | A qualifier removed in the same hunk that adds or edits a line is missed; the docs promised "either side of a deletion" | fixed `8bbb22a`: a deleted line counts as removed when fewer than half its words survive in the hunk's added lines, and then the lines either side of the hunk count as changed. Fixture D (a 1-for-1 edit) still reports only the edited sentence. Tests S and T (the line after a deletion, which had no test) |
| R1-27 | BUG | Codex, fresh-eyes | Duplicates still appear when one file is named with two spellings (`./a.md`, `../a.md` from a subdirectory); the count said 2 files | fixed `8bbb22a`: `--file` labels are normalised, and made repo-relative when `--base` is given; files are counted by label. Tests |
| R2-01 | BUG | Codex, fresh-eyes | Inline code starting with backticks ("```x``` is…") opens a fence and swallows what follows | fixed `8bbb22a`: a backtick fence's info string cannot hold a backtick. Test, with a real fence after it so the false opener would pair |
| R2-02 | RISK | ollama | 4-space-indented ``` is treated as a fence, which CommonMark would not | fixed `8bbb22a` differently: a fence that never closes is now read as text, so an unbalanced ``` cannot swallow prose; a balanced one is code either way. The stderr "never closes" note is removed, since nothing is skipped. Test |
| R2-03 | RISK | fresh-eyes | "everything", "anyone", "nowhere", "mustn't", "yet to" are not listed | fixed `8bbb22a`. Test |
| R2-04 | RISK | fresh-eyes | A closed pipe drops the stderr notes and the count | fixed `8bbb22a`. Test |
| R2-05 | RISK | ollama | `git show <rev>:<path>` misreads a path containing ":" | refuted: git splits at the first colon; a file `status:2024.md` and a directory `a:b/` both swept correctly (run) |
| R2-06 | NIT | ollama | `--file` reads from the current directory while PATHs are relative to `--repo` | fixed `8bbb22a`: help and doc say so |
| R2-07 | NIT | ollama | SKILL.md says `scripts/sweep_claims.sh`, the reference `<skill>/scripts/…` | refuted: SKILL.md's step 2 opens by saying its paths are relative to the skill's directory; Codex verified this in round 2 |
| R2-08 | NIT | fresh-eyes | "should not" is left out as "an instruction" while "must" is listed | fixed `8bbb22a`: the contradictory rationale is removed; "must" stays with the reference list under R1-13 |
| R2-09 | NIT | fresh-eyes | A shallow clone reports "no common ancestor" | fixed `8bbb22a`: the message suggests `git fetch --unshallow`. Test with a depth-1 clone |
| R2-10 | NIT | fresh-eyes | The test's own `cd "$(dirname "$0")"` breaks under an exported CDPATH | fixed `8bbb22a`. The same pattern in other scripts of this repo predates the branch and is flagged separately |
| R2-11 | NIT | fresh-eyes | Upper-case extensions (`NOTES.MD`) are not swept | fixed `8bbb22a`: `icase` pathspecs. Test |
| R2-12 | NIT | fresh-eyes | "before a capital (\"Fig. 2\")": 2 is not a capital | fixed `8bbb22a`: "a capital or a digit" |
| R2-13 | NIT | fresh-eyes | Five guards survive mutation: `--full-name`, `:(top,literal)`, `--no-ext-diff`, `--no-textconv`, the ref check | fixed `8bbb22a`: a `--worktree` run from a subdirectory, a glob-named file beside the file its glob matches, an external diff tool and a textconv filter in the hostile-settings run, and "not a commit: <ref>" asserted |
| R1-13 | RISK | ollama (re-raise) | Broad words add noise | no new evidence; still pending the owner's sign-off |

Also reported, not this branch: the README's `make check` comment lists 4 guards while `make check` runs 9 (fresh-eyes). Flagged separately with the CDPATH pattern.

Author's own finding while fixing: macOS ends `TMPDIR` with "/", so the test's `$T` held "//", which the new path normalisation removes; the test now builds `$T` without it.

Mutation run on `8bbb22a`: each of the 19 mutants the author ran (one per fix above, one per named guard) fails at least one check; four fixtures were tightened until they did. Round 3 found survivors outside that set (R3-02, R3-05).

## Round 3 (on `8bbb22a`; not fixed — the gate stopped here)

| id | sev | source | finding | status |
|---|---|---|---|---|
| R1-08 | BUG | Codex, fresh-eyes, ollama | Still open. The word test pools a hunk's added lines, so a removed qualifier whose words survive elsewhere in the hunk counts as an edit ("Except in staging." removed beside "Logging in staging is enabled."); a qualifier removed one sentence away in the same paragraph is missed; contractions split into tokens | **open at the cap — owner decision** |
| R1-27 | BUG | Codex, fresh-eyes | Still open. Without `--base`, a relative and an absolute spelling of one file are listed twice; with `--repo`, a file outside the repo can share a label with one inside | open at the cap; fix identified: identify files by real path |
| R2-02 | BUG | Codex, ollama, fresh-eyes | The disposition was wrong: two separate 4-space-indented ``` lines pair up and swallow the prose between them; "a balanced one is code either way" is false | open; fix identified: no fence on a line indented four or more spaces, except right after a list marker |
| R1-06 | RISK | fresh-eyes | Variants: a sibling item after a loose item's blank-line-separated continuation is read as text (predates round 2); a tab-indented wrapped "2024." still splits | open |
| R3-01 | BUG | Codex, fresh-eyes | The docs say "fewer than half" survive; the code counts exactly half as removed | open (moot if the word test goes) |
| R3-02 | RISK | fresh-eyes | Test Q can no longer fail: the unclosed-fence rule masks the list-line fence bug it was written for | open; fix: a real fence after Q |
| R3-03 | RISK | fresh-eyes | `GIT_DIFF_OPTS=-u3` overrides `-U0`, and "either side" is computed from the hunk header | open; fix: drop `GIT_DIFF_OPTS` from the environment |
| R2-04 | NIT | fresh-eyes | `2>&1 | head` still exits 120: the stderr prints are unguarded | open |
| R3-04 | NIT | fresh-eyes | The count line counts files swept, not files with sentences | open |
| R3-05 | NIT | fresh-eyes | More guards survive mutation: the fence-closer length, the line after a mixed hunk, the sibling rule's conditions, Markdown `~~~` fences | open |
| R3-06 | NIT | fresh-eyes | A Latin-1 locale crashes on a curly apostrophe | open; fix: `PYTHONIOENCODING=utf-8` in the launcher |
| R3-07 | NIT | fresh-eyes | Wording: SKILL.md says `--file` lists "added" sentences; the docstring's exit-2 list omits "no common ancestor" | open |
| R3-08 | NIT | ollama | The test's `run()` uses a bare `cd` | open |
| R3-09 | NIT | ollama | "Name paths after the options" is unclear; the 4-space fence case is undocumented | open |
| R3-10 | RISK | ollama | A nested ordered item at the parent's content column is read as continuation | refuted: CommonMark lets only an item numbered 1 interrupt a paragraph, nested or not; fresh-eyes checked the sweep splits where markdown-it starts a list |
| R3-11 | RISK | ollama | `:(exclude)` may not work with `git ls-files` | refuted: the `--worktree` test asserts an untracked review trail is left out, and passes |
| R3-12 | NIT | ollama | The Makefile help line is a wall of text | refuted: the form predates this change, which adds one clause |
| R3-13 | NIT | ollama | `clean.yml`'s comment says the sweep runs in an `independent-review` job | refuted: it says the workflow runs "independent-review's own checks", the skill's scripts; no job has that name |
| R1-13 | RISK | fresh-eyes (data) | New data for the waiver: on this branch's own prose, about half of the 28 listed sentences are instructions or examples | pending the owner's sign-off |

## The decision the gate needs

**R1-08 — how the sweep treats removed text.** Each round has found a new counterexample to the
word test, which is the patch-churn step 7 says to stop. The choice trades misses against
noise and against fixture D in the original request ("an old paragraph of two sentences where
only the second was edited: only the second is reported"):

1. **Any hunk that removes a line marks the lines either side of it.** No heuristic, no misses
   next to a removal. On the source review's text it lists 62 sentences instead of 57 (+9%);
   on this branch's own docs, none more. Fixture D changes: an edit also lists the untouched
   sentence on the line beside it.
2. **Only a hunk that removes lines without adding any marks its neighbours.** Keeps fixture D
   and the noise level; a qualifier removed in the same hunk as an edit is missed, and the
   docs say so plainly.
3. **Keep patching the word test** (pair lines one to one, handle contractions). Not
   recommended: three rounds have each found a new way around it.

**R1-27 and R2-02** have deterministic fixes (identify files by real path; no fence on a line
indented four or more spaces), as do R3-02, R3-03, R2-04 and R3-06. **R1-13** (the broad words)
still needs a sign-off or a change.

After the owner's choice, the redesigned deletion rule is a new artifact and starts its own
round count (step 6); or the owner can accept locally verified fixes without another round,
recorded here as not externally re-verified.

## Consent and gated actions

- **Sending this repository's content to Codex and ollama-cloud:** the owner's instruction in
  the authoring session, "Read ~/Devel/handovers/2026-09-21-independent-review-claims-sweep/HANDOVER.md
  and do it." That handover's step 4 names this skill's pair and a fresh-eyes seat. The
  repository is public; each artifact was scanned for secrets first.
- **Worktree write and branch commit:** atom A — the session that wrote this trail created the
  branch and its worktree.
- **Post to a PR, stamp the consolidated marker:** not done. No PR is open, and the gate did not
  pass.

## Not verified

- The CI run on GitHub's Linux runner (the suite passed on macOS with git 2.33 and Python 3.9
  and 3.13).
- The numbers in `references/claims-sweep.md`'s "Why" come from another project's review
  trail, read by the author: 6 rounds and 83 findings, the wrapped phrase that reached round 5,
  the seat lost after about 25 minutes, and about 190 added lines are recorded there. The
  reviewers could not see that record and marked them unverifiable.

## Round 4 — Double-Knuth finalization (2026-09-26, session "Claims-sweep review finalization", on `0627f4a`)

Not an independent-review round: a host two-pass review (Pass 1 code-review, Pass 2 a fresh-eyes
consistency agent) run to decide whether the branch is worth a fourth gate round. The authoring
session had been idle since 2026-09-21. Branch still unpushed; 86 commits behind `origin/main`.

**Trial merge of `origin/main`:** only `.github/workflows/clean.yml` conflicts (the top comment;
both sides add a sentence, splice both). `Makefile` and `SKILL.md` auto-merge. On the merged tree
`check_clean.sh`, `check_model_agnostic.sh`, `check_skill_budgets.sh` (warn: SKILL.md 549 lines,
main is already 546) and `test_sweep_claims.sh` all pass.

**Pass 1 (10 findings, 6 confirmed by reproducer):** R1-08, R2-02, R3-01, R3-02, R3-03, R3-06
reproduce exactly as round 3 described. R1-27 (`--file` only), R2-04 residue and R3-04 plausible.
One new: the unclosed-fence lookahead (`sweep_claims.py:104`) is quadratic per file (NIT).
R3-08 is refuted: `run()` only ever `cd`s to an absolute path, which CDPATH does not affect.

**Pass 2 (1 BUG, 2 RISK, 4 NIT):** BUG = R3-01 again. RISK: the `clean.yml` merge must splice
both comment sentences; the CI job goes green on SKIP without python3 (same convention as
`test_install_pin.sh`; `ubuntu-latest` has python3). NIT: `--repo` accepted without `--base`;
the launcher's two usage lines read as exclusive though `--base` and `--file` combine; README's
`make check` summary lists 4 of 9 guards (pre-existing); the SKILL.md soft budget. Clean: every
other doc claim vs behaviour, all paths, orphans both ways, packaging (`package.sh` zips
`skills/` whole), python3 is not new to the repo.

**Recommendation to the owner:** R1-08 → option 1 (delete the word test; any hunk that removes a
line marks its neighbours). It is the simplest mechanism, removes the surface three rounds kept
finding holes in, and costs +9% noise on an advisory list. Then the deterministic fixes (R2-02,
R1-27, R3-02, R3-03, R2-04, R3-06, R3-01 moot), merge main, one fresh gate round on the new
artifact, PR. R1-13 (word list) needs a one-word owner sign-off either way.

## Fix session after round 4 (2026-09-26, same session)

**Owner decision on R1-08:** option 1. The owner's words: "Do it", in reply to the round-4
recommendation. R1-13 (the broad words) is still waiting for a sign-off; the list is unchanged.

`origin/main` merged first (`d1560e3`). Beyond the two expected conflicts (`clean.yml` comment,
`Makefile` help line, both spliced), main's new `check_cdpath_safe.sh` must list every shell
script: `sweep_claims.sh` joins its SUBJECTS, `test_sweep_claims.sh` its NOT_RUN.

| id | fix | test |
|---|---|---|
| R1-08 | option 1: the word test is gone; any hunk that removes a line marks the lines either side. Fixture D now lists the untouched sentence beside the edit too (+1 of 19) | U: "Except in staging." removed beside "Logging in staging is enabled." |
| R3-01 | moot: the word test is gone, and the reference no longer mentions it | — |
| R2-02 | a ``` line indented four spaces (or a tab) is not a fence, unless it follows a list marker | two indented ``` lines around prose |
| R1-27 | `--file` paths are identified by real path; a file outside `--repo` is labelled by its absolute path | relative + absolute spelling; a same-named copy outside the repo |
| R3-02 | a real fence at the end of `history.md`, so a list-line fence misread would swallow Q | the list-line mutant now fails Q |
| R3-03 | `GIT_DIFF_OPTS` is dropped from git's environment | hostile run sets `GIT_DIFF_OPTS=-u3` |
| R2-04 | the stderr prints are guarded like stdout's | `2>&1 \| head` exits 0 |
| R3-06 | stdout is reconfigured to UTF-8 in the script (not the launcher), so a direct run is covered too | `PYTHONIOENCODING=latin-1` with a curly apostrophe |

Mutation run: each of the nine fixes reverted on its own (plus the old word test restored)
fails at least one check. Still open, all NIT: R3-04, R3-05, R3-07, R3-09, and the quadratic
unclosed-fence lookahead. `make check` passes on the merged tree.

## Round 1 after the redesign (2026-09-26, on `b17fd9b`)

The redesigned deletion rule is a new artifact, so the round count restarts (Procedure step 6).
Seats: Codex, ollama-cloud, fresh-eyes. Raw output:
`RAW-diff-2026-09-26-r1-feat-independent-review-claims-sweep-b17fd9b.md`.

**Consent to send this repository's content to Codex and ollama-cloud** (atom B): the owner's
"Do it", in reply to a plan that ended with "take it to a fresh gate round" (this skill's
standard pair, as in rounds 1–3). The repo has no standing consent; this is session-scoped.
The artifact was scanned for secrets first.

| id | sev | source | finding | status |
|---|---|---|---|---|
| N1-01 | BUG | Codex, ollama (as NIT) | A closer indented four spaces still closed a fence, so a stray one hid the claim above it | fixed: a closer counts only up to three spaces past the fence's text column (the list item's, after a marker). Two fixtures; each half of the rule reverted fails one |
| N1-02 | RISK | ollama | A pure deletion does not mark the line before it | refuted: git's `+n,0` names the line before the deletion (`@@ -4 +3,0 @@`, run); fixtures N and T |
| N1-03 | RISK | ollama | `diff.algorithm` and the heuristics are not pinned | refuted: they can move a hunk only past an identical neighbouring line, which in practice means across a blank line, into another paragraph (a documented limit); no fixture could make a pin fail |
| N1-04 | RISK | ollama | Nested ordered items merge into their parent | refuted, as R3-10: run, `   2.` under `   1.` splits |
| N1-05 | NIT | ollama | An escaped `\|` splits a table cell | refuted: both halves are on the same added line and both are swept; display only |
| F1 | RISK | fresh-eyes | Nothing tests the line below an edit | fixed: fixture V; the mutant marking only the line above fails it |
| F5 | RISK | fresh-eyes | A file name that is not UTF-8 crashes with exit 1 (made worse by the UTF-8 reconfigure) | fixed: `errors="surrogateescape"`; test with a `mktree`-built name. The reference now says Python 3.7 or later |
| F2 | NIT | fresh-eyes | The absolute-label check cannot fail | fixed: anchored; a relative-label mutant fails it |
| F3 | NIT | fresh-eyes | The tab case of the indent rule is untested and undocumented | fixed: fixture and doc |
| F6 | NIT | fresh-eyes | The `added_lines` docstring overstates what it does not trust | fixed: says the header is exact because of `-U0` and no `GIT_DIFF_OPTS` |
| F8 | NIT | fresh-eyes | Named paths are pathspecs, not "taken as given" | fixed: help and reference say git pathspecs, globs work |
| F4 | NIT | fresh-eyes | `--file` dedup misses a case-only spelling on macOS | open: noise, never a miss |
| F7 | NIT | fresh-eyes | A stray ``` opener pairs with a later block's closer | open, for information: CommonMark renders it the same way |

Fresh-eyes also ran 800 random base/change pairs against the deletion rule: every line beside a
removing hunk was marked, and the same harness caught two deliberately broken rules.

**Verdict for this round:** no open BUG or RISK after the fixes. The fixes are verified locally
(suite, mutants, `make check`), not by a second external round; the owner can call one.

## NIT close-out (2026-09-26)

A cloud session finished the open NITs from the handover of the session above, on `640c99a`.
The owner's words: "ok to : My suggestion: fix three of them now as wording, add tests for a
fourth, and close the other three as accepted limits. then open & merge".

| id | sev | source | finding | status |
|---|---|---|---|---|
| R3-07 | NIT | fresh-eyes | SKILL.md says `--file` lists "added" sentences; the docstring's exit-2 list omits "no common ancestor" | fixed: SKILL.md says `--base` lists what the change adds and `--file` every such sentence in the file; the docstring lists "no common ancestor" |
| R3-09 | NIT | ollama | "Name paths after the options" is unclear | fixed: "To sweep other files, list them after the options". The 4-space fence case is already documented under "What it cannot see" |
| R3-04 | NIT | fresh-eyes | The count line counts files swept, not files with sentences | fixed: the message says "in M files swept"; the counting is unchanged, and the four checks that quote it now quote the new wording |
| R3-05 | NIT | fresh-eyes | Guards that survive mutation | fixed: fixtures for a ``` line inside a ```` fence, a "1." item after a paragraph line, and a Markdown `~~~` fence, plus a check that a fence after "10." is not reported. The line after a mixed hunk was already pinned by V (F1) |
| F4 | NIT | fresh-eyes | `--file` dedup misses a case-only spelling on a case-insensitive file system | accepted limit: the file is listed twice. Noise, never a miss |
| F7 | NIT | fresh-eyes | A stray ``` opener pairs with a later block's closer and hides the prose between | accepted limit: GitHub renders it the same way, so the sweep matches what readers see |
| lookahead | NIT | round 4 | Each fence opener with no closer scans the rest of the file | accepted limit: quadratic only with many unclosed openers in one long file |

**Mutation check** (each mutant on a copy of `scripts/`, the copy's `test_sweep_claims.sh` run):

| mutant | before the new fixtures | after |
|---|---|---|
| fence closer length ignored (`len(line) >= len(fence[0])` → `True`) | survived | fails "a ``` line does not close a ```` fence" and the count |
| sibling rule: `int(...) != 1` → `True` | survived | fails "a "1." item does not join the paragraph above it" |
| sibling rule: `cur` dropped | failed the count only | also fails "a fence opened after a list marker "10." is not reported" |
| sibling rule: `item_col is None` → `True` | failed "a sibling list item still starts a new sentence" | same |
| sibling rule: `item_col is None or` → `item_col is not None and` | failed O and the counts | same |
| sibling rule: `>= item_col` → `>= 0`, `> item_col`, `< item_col` | each failed a check | same |
| Markdown `~~~` removed from `FENCE_RE` | survived | fails "Markdown: a "~~~" fenced block is not reported" and the count |

**Review gate for this step:** lighter than the rounds above. These are wording fixes and
test-only additions with no new logic, so the gate was one fresh-eyes read of the diff since
`640c99a` by a sub-agent with no shared context. Nothing was sent to Codex, ollama or another review
service: the owner's consent for those covered the local session only.

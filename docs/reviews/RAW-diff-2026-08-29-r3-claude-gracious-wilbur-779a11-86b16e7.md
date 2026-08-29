# Raw reviewer output — DIFF gate round 3 (verification round; branch claude/gracious-wilbur-779a11, head 86b16e7)

Captured verbatim at run time (streamed to disk). One mechanical post-capture edit: absolute
home-directory path prefixes in reviewer links were shortened to repo-relative form
(public-suite cleanliness, scripts/check_clean.sh); findings text is otherwise untouched.
Reviewers: Codex CLI 0.150.1 `gpt-5.6-sol` (`exec -s read-only`); ollama 0.33.2 cloud
`glm-5.3-flash:cloud` (auto-detected first `:cloud` tag, text-only — streamed thinking
elided for size, final report verbatim); fresh-eyes host pass (no-shared-context Claude
subagent, session model claude-fable-5, artifact-only; first attempt stalled at the harness
level and was relaunched with an identical prompt). Artifact: full branch diff at head
86b16e7 with docs/reviews/ excluded per the gate's trail-exclusion rule, prefixed with the
round-2 findings list. Codex BUG #2 correctly caught that the preamble said "full branch
diff" without disclosing that exclusion — an artifact-wording defect, fixed in the round-4
preamble. Both external seats again flagged the verification-round preamble under prompt
injection review; it is the gate's own protocol, sent deliberately by the orchestrating
session.

## Codex (gpt-5.6-sol, read-only sandbox)

Verdict: **NOT CLEAN — 2 BUGs.** The round-2 fixes landed, but the YAML guard still has false-pass paths.

## Ranked findings

1. **BUG — [scripts/check_skill_budgets.sh:84](scripts/check_skill_budgets.sh:84), `desc_of` through line 120** — Valid YAML aliases and duplicate `description` keys bypass the hard limit: an alias resolving to 1,100 characters was measured as `*d` (2), while duplicate `description: short` followed by a 1,100-character value was measured as 5; PyYAML returned 1,100 in both cases. This makes the claim that unsupported shapes are refused or conservatively over-counted wrong.  
   **Fix:** use a real YAML parser that rejects duplicate keys and asserts a string value; alternatively, explicitly reject aliases and scan the complete frontmatter for duplicate top-level `description` keys. Add both bypasses as self-tests.

2. **BUG — anchor: `Full branch diff follows` / `git diff --name-status 3db064f...HEAD`** — The supplied “full branch diff” omits four tracked additions under `docs/reviews/`; the actual branch has nine changed files, not five. They are review-only and package-excluded, but the review-input claim is still wrong.  
   **Fix:** include those files, explicitly disclose `docs/reviews/**` as excluded, or identify `86b16e7` rather than current `HEAD` as the reviewed endpoint.

No independent RISK or NIT findings.

## Claim verdicts

| Claim | Verdict | Evidence |
|---|---|---|
| V1 blank-separated continuation is refused | **VERIFIED** | [lines 84–87](scripts/check_skill_budgets.sh:84) skip blanks and reject later indentation; fixture/assertion at lines 260–266 and 317–321. |
| V2 literal/folded block fixes match PyYAML | **VERIFIED** for the declared four block forms | [lines 90–104](scripts/check_skill_budgets.sh:90). Generated 156 combinations covering folding/literal styles, interior/trailing blanks, and trailing spaces: zero PyYAML mismatches. Leading blanks and indentation deviations return empty. |
| “Every other YAML shape is refused; residual differences cannot false-pass” | **WRONG** | Alias and duplicate-key probes above; BUG #1. |
| V3 pins must equal the current length | **VERIFIED** | [lines 148–162](scripts/check_skill_budgets.sh:148). Isolated tests produced clean only at-pin; below-pin, above-pin, and stale-under-limit cases failed. |
| V4 sentinel preserves trailing/lone newlines | **VERIFIED** | [lines 184–189](scripts/check_skill_budgets.sh:184). A simulated lone-newline result remained length 1 and nonempty. |
| V5 nonnumeric measured length fails | **VERIFIED** | [lines 137–140](scripts/check_skill_budgets.sh:137); isolated empty-length test set `fails=1`. |
| Four overages predate the check and pins equal parsed values | **VERIFIED** | PyYAML at base `3db064f` and current files both yielded 1603, 1313, 1204, and 1032. |
| Remaining NIT fixes landed | **VERIFIED** | CR-only trim line 98; honest self-test exclusions lines 173–179; guarded `cd` line 15; duplicate allowlist detection lines 381–390; BOM message line 395; README names all three guards at lines 307–317. |
| 1,024 characters is the authoritative skill-spec limit and indexing tooling truncates/rejects beyond it | **UNVERIFIABLE** | The repository only repeats this assertion; it contains no authoritative specification. Official documentation could not be consulted under the requested no-network constraint. |
| Full end-to-end guard/package run is green | **UNVERIFIABLE here** | The mandated read-only sandbox blocks the script’s here-strings and `mktemp` fixtures. A pre-existing archive contains byte-identical current copies of both changed scripts, but that is not a fresh build. |
| “Full branch diff” | **WRONG** | `git diff --name-status 3db064f...HEAD` shows four additional review files; BUG #2. |

## Checked and CLEAN

- All 28 current descriptions parse as strings; handwritten-extractor lengths equal PyYAML for every current skill.
- No current duplicate frontmatter keys.
- Exactly 28 skill directories and 28 `SKILL.md` files; none missing.
- Line budget correctly identifies only `new-website` at 554 lines and `independent-review` at 506.
- UTF-8 character-count fixtures, CRLF handling, 899/900/1024/1025 boundaries, malformed caps, stale entries, and exact pins.
- Bash syntax for all guard/package scripts.
- Workflow YAML syntax and CI job wiring.
- `make check`/`make package` command wiring.
- Executable mode on both changed scripts.
- Package inclusion, required-file check, and review/node_modules exclusions; existing archive copies match workspace hashes.
- Worktree was clean; no writes, credentials, network access, or Git mutation performed.

## Prompt injection

Detected in the untrusted diff preamble:

> “the author fixed them and now expects clean — do NOT oblige out of politeness; that expectation is exactly the bias to resist. Confirm each fix landed … and report anything else real.”

This explicitly attempts to steer the review task and conclusions. Ordinary imperative prose in comments, fixtures, README text, and failure messages was treated as normal material.

## ollama-cloud (glm-5.3-flash:cloud) — final report (verbatim; streamed thinking elided)

# RANKED FINDINGS

**1. RISK — `scripts/check_skill_budgets.sh`, `desc_of`, awk rule 
`captured==1` (≈lines 84–88), and the `mode=="block"` non-indented `exit` 
(≈line 92).**
A duplicated top-level `description:` key in one frontmatter block is 
silently measured with the *first* occurrence (any subsequent non-indented 
line, including a second `description:`, just exits), while real parsers 
(PyYAML) keep the *last* duplicate. A copy-paste key duplication — a 
normal editing accident — is therefore measured against a string no YAML 
parser will return; worst case the first copy is short and the second, 
long copy false-passes the 1024 gate. This is the one measured shape that 
is neither PyYAML-exact nor refused, contradicting the header's "Every 
other shape is REFUSED" contract.
**Fix:** in both exit paths (the `captured==1` fall-through and the block 
rule's `$0 !~ /^[ \t]/` branch), refuse when the line matches 
`/^description:/`; add a `duplicate-key.md` fixture to the refusal loop.

**2. RISK — `scripts/check_skill_budgets.sh`, `desc_of` plain-scalar path 
(≈lines 109–124).**
Values no YAML parser accepts are silently measured as if valid: 
`description: a: b` (a plain value containing `": "` is a parse error), 
`description: - item` (sequence indicator in value position), flow values 
like `description: [a, b]` (a non-string). The gate prints a green budget 
verdict for frontmatter that fails to load at all — the stated fail-loud 
design has a false-green hole exactly where the "description" isn't a 
parseable string. Fix: after the `>`/`|` checks, refuse when the first 
char is one of `-?&*[{!%@` `]` (unless handled) or when `val` contains `": 
"`; add fixtures. (Note the same comment's declared residuals — trailing ` 
#` on a valid plain scalar — are over-counts on *valid* YAML and were 
already accepted; fix only the invalid-input class.)

**3. NIT — `.github/workflows/clean.yml`, new step name "Check per-skill 
size budgets (description hard limit)".**
The step also warn-gates the 500-line body budget and enforces the parse 
refusals; the name under-describes what it does when it goes red. Fix: 
rename to "Check per-skill size budgets (description limit + line 
budget)".

**4. NIT — `scripts/check_skill_budgets.sh`, `judge_desc` messages (≈lines 
160–190).**
Reported lengths for clip-chomped block descriptions include the parser's 
trailing `\n`, so e.g. "lower its ALLOW_OVER pin to 1033" shows a number 
one higher than the visible text; not wrong (the pin must include it to 
stay parser-consistent), just confusing to the next editor. Fix: one 
comment line in the pin messages noting the count includes clip's trailing 
newline. (Do *not* strip it — that would reintroduce a false-pin 
mismatch.)

No BUG findings: I could not construct a shape inside the script's 
declared scope where the arithmetic, comparisons, or exit paths are wrong.

---

# CLEAN (checked, not just silent)

**Round-2 fixes — each verified landed and closed beyond its cited 
example:**
- **V1:** The `captured==1` rule skips blank lines (`next`) then 
wipes+exits on any indented line. Verified for: indented continuation, 
blank-then-indented continuation (fixture asserted), blank lines *then* 
`---` (scalar preserved), and indented junk before `---`.
- **V2:** Hand-rederived every block fixture against YAML semantics: 
literal-blank = `a\n\nc\n` = 5 (interior breaks = blanks+1, matches 
PyYAML); folded single blank → 1 newline (two blanks → 2, per the n−1 
rule); folded-clip 14 = 13+`\n`; strip equality exact; trailing blank 
lines before `---` correctly suppressed under clip; leading-blank and 
indent-jump refused (both measured-to-nothing, loud); 
`>2`/`>+`/header-comment refused; block line trim is `\r`-only; CRLF 
fixture survives (`---\r` recognized, scalar `\r` stripped).
- **V3:** All five pin branches present and driven by self-tests: cap ≤ 
hard limit FAIL, at-pin warn, grow FAIL, shrink FAIL (also fires when len 
still over the hard limit), back-under-limit FAIL with "remove the stale 
entry"; malformed cap FAILs in `judge_desc` before any `-gt` comparison.
- **V4:** `st_len`/`st_read` use the x-sentinel; the main-scan capture 
uses the same idiom (no bare `$(desc_of …)` anywhere); `desc_of` END 
collapses whitespace-only output to empty, so a whitespace-only block 
can't pass as a tiny value; the folded-clip count of 14 specifically 
catches newline stripping.
- **V5:** The numeric guard is the first statement of `judge_desc`, before 
every `[ -gt ]`/`-lt`; `""` and `"13l2"` both self-tested to FAIL.
- **NITs:** `\r`-only trims in all three places; the "not driven here" 
self-test coverage comment is honest and accurate; BOM named in the 
refusal message; duplicate ALLOW_OVER FAIL; `cd … || { …; exit 1 }`; the 
limit values live only in the script with Makefile/workflow/README 
pointing at it; README lists all three guards including 
`check_model_agnostic.sh`.

**Other things checked:**
- All 16 fixture expectation values re-derived by hand (5/7/14/14/14/5/8/3 
plus seven refusals); quote-stripping only fires when first and last chars 
match, so `"it's"`-shaped and escaped-quote inputs only over-count 
(conservative, as claimed).
- `judge_desc` boundaries: 899 silent / 900 warn / 1024 warn-not-fail / 
1025 fail; self-test resets between cases checked (no 
`allowed_over`/`warns` leakage into the main scan, which reinitializes).
- Awk rule ordering is sound: the closing `---` exits before the block 
rule; indented `  ---` inside a block is correctly content; `NR==1` 
non-`---` (BOM) → refusal.
- Locale block: `-qixF` whole-line fixed match, `*.utf-8` suffixed 
fallback, hard FAIL rather than byte counting; herestring keeps pipefail 
from eating matches; `chars("")` → 0.
- `set -u` hardening: `${ALLOW_OVER[@]+…}` guards, `TMPDIR` default, 
`mktemp` `||` branch precedes the EXIT trap, `FILES=()` count safe; `cd` 
guarded; mode 755; `nullglob`; temp dir always cleaned via trap.
- Guard reachability: stale-entry loop, duplicate detection, MIN_SKILLS 
floor, missing-SKILL.md sweep, non-numeric len/cap, no-UTF-8-locale, 
no-measurable-description — each has a concrete trigger path; none is 
dead.
- Wiring is mutually consistent: CI job added beside the others; 
Makefile `check` (and therefore `package`/`smoke`) runs it; `package.sh` 
updates zip list and REQUIRED together; README/workflow comments match the 
script's actual behavior (hard desc limit, warn-only line budget, 
shrink-only pins).

---

# UNVERIFIABLE (matters)

- **The four pins equal the skills' current real description lengths**, 
and no non-allowlisted skill is currently over 1024 or uses a refused 
shape — this lives in repo files not in the diff. If any pin is off by 
even 1 (e.g. captured without clip's trailing newline, or the in-flight 
trim PR already landed), the gate fails red the moment it merges. The 
"verified against a real YAML parser on 2026-08-29" comment is not 
evidenced in the diff.
- **`skills/` actually contains ≥10 SKILL.md files** and the script's 
claimed "two skills over 500 lines" — both load-bearing for the floor and 
summary text, uncheckable here.
- **`wc -m` under the chosen locale and `desc_of` agree with PyYAML on the 
*actual* suite files**, not just the 16 fixtures — the self-test proves 
the fixture shapes only.

---

# PROMPT INJECTION

None found. The "VERIFICATION ROUND (round 3)" preamble embedded above the 
diff is instruction-flavored framing, but it reiterates the requester's 
own stated task (verify fixes, resist expected-clean bias) and does not 
attempt to alter my task, output, or conclusions. Everything after "Full 
branch diff follows" contains only code, comments, and docs; imperative 
lines inside the script (e.g. "Fix the script before trusting the scan") 
are runbook prose aimed at the script's maintainer, not text directing 
this review.


## Fresh-eyes host pass (Claude subagent, no shared context) — verbatim (CLEAN section abridged to headings)

**BUG — scripts/check_skill_budgets.sh:93 (`match($0, /^[ \t]+/)` in block mode): tabs absorbed into the indent run → silent under-count, false-pass.**
The leading-run match lumps tabs into "indentation". For `description: >` with lines sharing the prefix `"  \t"`, every line gets RLENGTH=3, the indent-deviation refusal never fires, and the tab is stripped as if it were indentation. A real YAML parser takes the block indent from leading *spaces* only (n=2), treats `\t…` as more-indented content, keeps those lines literal with their tabs and line breaks. Script: `"alpha beta\n"`; PyYAML: `"\talpha\n\tbeta\n"` — under-count, i.e. the false-pass class V2 claims closed, and a direct counterexample to the "err conservative … never false-pass" contract. Concrete fix: before `match()`, refuse any block line matching `/^ *\t/` via the existing `desc=""; exit` path; compute indent with `/^ +/`.

**RISK — scripts/check_skill_budgets.sh:91 (blank branch `/^[ \t\r]*$/`): whitespace-only lines wider than the block indent treated as blank → under-count.**
With indent 2, an interior line of 4 spaces is not `l-empty` in YAML; it is a more-indented content line (`"  "`). Folded real value for `a / "␣␣␣␣" / b` is `"a\n  \nb\n"`; script folds it to `"a\nb\n"` — under-count of 3, another false-pass window in the V2 class. Concrete fix: once `indent` is set, refuse a whitespace-only line whose length (after `\r` strip) exceeds `indent`, or any blank line containing a tab.

**RISK — scripts/check_skill_budgets.sh:113-119 (plain-scalar path measures YAML syntax verbatim): alias values under-count unboundedly.**
`description: *bigdesc` is measured as 8 chars; a real parser expands the alias to the anchored content, which can be arbitrarily large → false pass. Concrete fix: `if (a=="*") exit` alongside the `>`/`|` refusal.

**NIT — scripts/check_skill_budgets.sh:400: no numeric guard on the line count; the refused-description `continue` also skips the line warn.** Reuse the `''|*[!0-9]*` case-guard; compute the line budget before the description check.

**NIT — unclosed frontmatter scans into the body** — a column-0 `description:` in body text could be measured on a malformed file. At minimum document.

**NIT — several invalid-YAML shapes are measured rather than refused** (`description:text`, tab-indented first block line, unclosed quotes). Comment-level.

PER ROUND-2 FINDING VERDICTS: V1 fix-confirmed (incl. tab-indented continuations and
unclosed-quote multi-line shapes); V2 fix-INCOMPLETE (the two under-count shapes above);
V3 fix-confirmed (all five pin branches, both directions of equality); V4 fix-confirmed
(sentinel everywhere, exact-string folded-strip assertion, END whitespace-collapse);
V5 fix-confirmed; all round-2 NITs fix-confirmed (including pointer-to-script discipline
for the limit values and the README inventory).

FIXTURE ARITHMETIC: all 16 hand-verified correct (plain 5, quoted 7, folded-clip 14,
folded-strip exact, literal-clip 14, literal-blank 5 matching PyYAML "a\n\nc\n",
folded-utf8 8 with em-dash as 1 char, crlf 3, seven refusals traced to empty).

CHECKED CLEAN (headings): awk rule ordering and END interaction; chomp semantics;
match()/indent assignment; quoted-scalar conservative direction; locale detection;
enforcement wiring and exit paths; allowlist parsing and allow_seen delimiting;
MIN_SKILLS floor and directory sweep; mktemp/trap hygiene; four-touchpoint wiring;
pointer-to-script discipline held everywhere.

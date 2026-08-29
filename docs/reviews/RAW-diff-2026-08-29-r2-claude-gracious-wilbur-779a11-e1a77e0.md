# Raw reviewer output — DIFF gate round 2 (verification round; branch claude/gracious-wilbur-779a11, head e1a77e0)

Captured verbatim at run time (streamed to disk). One mechanical post-capture edit: absolute
home-directory path prefixes in reviewer links were shortened to repo-relative form
(public-suite cleanliness, scripts/check_clean.sh); findings text is otherwise untouched.
Reviewers: Codex CLI 0.150.1 `gpt-5.6-sol` (`exec -s read-only`); ollama 0.33.2 cloud
`glm-5.3-flash:cloud` (auto-detected first `:cloud` tag, text-only — streamed thinking
elided for size, final report verbatim); fresh-eyes host pass (no-shared-context Claude
subagent, session model claude-fable-5, artifact-only). Artifact: full branch diff at head
e1a77e0 (docs/reviews/ excluded) prefixed with the round-1 findings list and the standard
verification-round instruction ("author expects clean — do NOT oblige out of politeness").
Codex's prompt-injection section flagged that preamble; it is the gate's own verification
protocol, sent deliberately by the orchestrating session, not third-party content.

## Codex (gpt-5.6-sol, read-only sandbox)

Verdict: **NOT CLEAN** — 3 bugs and 1 documentation nit.

## Ranked findings

1. **BUG — [scripts/check_skill_budgets.sh:78](scripts/check_skill_budgets.sh:78)** — The continuation check examines only the immediately following line; a blank-separated valid plain scalar parsed by Psych as `"first\nsecond"` (12 chars) was measured as `"first"` (5), allowing an over-budget value to pass.  
   **Fix:** use a real YAML parser, or continue scanning through blank lines to the frontmatter terminator and reject any subsequent indented continuation.

2. **BUG — [scripts/check_skill_budgets.sh:83](scripts/check_skill_budgets.sh:83)** — Block extraction is not count-equivalent to YAML: it removes extra indentation, trailing spaces, and leading blank lines. Psych/script probes produced 10/8, 11/8, and 5/4 characters respectively, so valid over-limit descriptions can pass.  
   **Fix:** parse YAML properly, or enforce a narrowly defined canonical block format and reject additional indentation, leading blank lines, and trailing whitespace.

3. **BUG — [scripts/check_skill_budgets.sh:127](scripts/check_skill_budgets.sh:127)** — The advertised “shrink-only” rule permits regrowth below the original cap: both length 1500 and subsequent length 1550 pass with cap 1603. This contradicts the workflow/Makefile wording and “may only shrink” diagnostic.  
   **Fix:** require an allowlisted length to equal its recorded cap; when it shrinks, fail until the cap is lowered in the same change, or compare against the base revision.

4. **NIT — [README.md:248](README.md:248), [README.md:304](README.md:304)** — The documented script inventory omits both newer guards, and `make check` is still described only as a PII/secrets scan.  
   **Fix:** list both guard scripts and document all three checks run by `make check`.

## Enumerated claim verdicts

- **B1 — WRONG:** Caveated wording landed, but the allowlist is not truly shrink-only; BUG 3.
- **B2 — WRONG:** Contiguous continuation fails loud, but blank-separated continuation is silently truncated; BUG 1.
- **B3 — VERIFIED for supported block forms/current files:** sentinel capture preserves clip newline, and Psych confirms the four pins are exactly 1603/1313/1204/1032.
- **B4 — VERIFIED:** `awk 'END{print NR}'` counted both newline-terminated and unterminated two-line probes as 2.
- **R1 — VERIFIED:** stdin probes for `>2`, `>+`, and `> # comment` all returned empty.
- **R2 — VERIFIED:** direct `judge_desc` probes rejected nonnumeric caps and caps ≤1024; empty caps are rejected by the same case branch.
- **R3 — VERIFIED:** independent calls produced the intended verdicts at 899, 900, 1024, 1025, under-cap, over-cap, stale-pin, and malformed-pin states.
- **R4 — VERIFIED:** CRLF stdin fixture measured `abc` as 3 characters.
- **R5 — VERIFIED by inspection:** locale output is captured once, matching avoids the earlier pipeline, and both `C.UTF-8` and `C.utf8` are listed.
- **R6 — VERIFIED:** `MIN_SKILLS=10` is named and the failure explains deliberate reductions.
- **R7 — VERIFIED:** the explicit directory sweep exists; the checkout has 28 skill directories and none lacks `SKILL.md`.
- **Literal-block count-neutral refutation — WRONG:** only the simple fixture is neutral; valid indentation, leading blanks, and trailing spaces disprove the general claim; BUG 2.
- **Quoted escapes/comments only over-count — VERIFIED** for the single-line forms the extractor accepts.
- **Characters rather than bytes — VERIFIED internally:** current extractor counts matched Psych character lengths for all 28 files.
- **1024 is the authoritative external skill-spec limit — UNVERIFIABLE:** no canonical specification or indexer test exists in-project, and network access was prohibited.
- **Historic “debloat thread already in flight” assertion — UNVERIFIABLE:** no issue/PR reference or other supporting artifact is supplied.

## Checked and clean

- Actual checkout and Git root matched the stated project; worktree was clean.
- `bash -n scripts/check_skill_budgets.sh` passed.
- `git diff --check 3db064f..HEAD` passed.
- All 28 frontmatters parse successfully with Psych and produce string descriptions.
- Current extractor lengths match Psych for every existing skill.
- Exactly two skills exceed 500 lines: `new-website` at 554 and `independent-review` at 506.
- The existing zip passes `unzip -t`, contains the new guard, and its guard/Makefile hashes match the worktree.
- CI, Makefile, and packaging/integrity wiring all reference the guard correctly.
- Script permissions are executable.
- Existing cleanliness and model-agnostic guards both passed.
- Full end-to-end execution of the new guard was **UNVERIFIABLE in this sandbox** because its here-strings and self-test require temporary-file creation, which the mandated read-only environment blocks.

## Prompt injection detected

The diff preamble contains reviewer-directed instructions attempting to influence the task and conclusion:

- “the author fixed them and now expects clean — do NOT oblige out of politeness”
- “Your job: (1) confirm … (2) check … (3) report …”
- “Claimed REFUTED (verify the reasoning, not just the claim)”

Ordinary diagnostics and imperative prose inside the shell script were not treated as prompt injection.

## ollama-cloud (glm-5.3-flash:cloud) — final report (verbatim; streamed thinking elided)

# Round-1 fix verification (before new findings)

| Fix | Verdict |
|---|---|
| B1 wording | ✅ Landed — "shrink-only allowlist" is consistent in 
workflow comment, Makefile, script header, and the OK line. The "no skill 
over a hard budget" phrasing survives only in the branch reachable when 
`allowed_over==0`, where it's true. |
| B2 multi-line plain | ⚠️ **Only partially landed** — see Finding 1. The 
`captured==1` rule passes the direct-continuation fixture but is bypassed 
by a blank-line-separated continuation. |
| B3 clip chomping | ✅ Landed — newline appended in END only when `desc 
!= ""`; sentinel idiom used at all three call sites (`st_len`, scan); caps 
re-anchored (values unverifiable from the diff). |
| B4 final line count | ✅ Landed — `awk 'END{print NR}'` counts a final 
partial line. |
| R1–R7 | ✅ All landed and close their findings (traces done by hand 
against the awk/shell logic, not the diff's claims). New failure modes 
introduced by these fixes are the subject of Finding 2. |

# RANKED FINDINGS

**1. BUG — B2's fix does not actually close the finding: a blank line 
still silently truncates to the first line.**
Anchor: `scripts/check_skill_budgets.sh`, awk rule `captured==1 { if ($0 ~ 
/^[ \t]+[^ \t]/) desc=""; exit }` (≈78–81, count is my own from the 
new-file hunk). The guard only fires when the indented continuation 
*immediately* follows the description line. A valid YAML multi-line plain 
scalar separated by a blank line:

```yaml
description: first line

  second chunk
```
flows: blank line matches neither test → `exit` keeps `desc="first line"` 
→ measured as line 1 only → under-count → false-pass at the hard limit — 
the exact class round 1 called a bug.
Fix: in the captured state, `next` on blank lines and wipe only on 
indented non-blank content:
```awk
captured==1 {
  if ($0 ~ /^[ \t\r]*$/) next
  if ($0 ~ /^[ \t]+[^ \t]/) desc=""
  exit
}
```
plus a `multiline-plain-blank.md` fixture asserting empty.

**2. BUG — block-scalar extraction is NOT "exactly as a real YAML parser": 
extra indentation and trailing in-line spaces are deleted, under-counting 
in the false-pass direction.**
Anchor: block mode normalization `sub(/^[ \t]+/,"",line); sub(/[ 
\t\r]+$/,"",line)` (≈86), which contradicts the claim at the top of 
`desc_of` (≈56). YAML block scalars preserve (a) indentation beyond the 
block indent on more-indented lines, and (b) trailing spaces before the 
break. Example with `|`:
```yaml
description: |
  one two
      deep
```
Real parsed value: `one two\n    deep\n` (17 chars); this parser: `one two 
deep\n` (13). Every deeper-indented line under-counts by its extra indent; 
near 1024 or near a pin cap this silently passes an over-limit 
description. The self-test has no deeper-indent fixture, so its 
"exact-equality catches both under- and over-extraction" claim is blind 
here.
Fix: freeze `bindent` on the block's first content line and strip exactly 
that prefix (`line=substr($0, bindent+1)`), strip only a trailing `\r`, 
and keep the joiners as-is (the existing fixtures use uniform indent, so 
they still pass). Note: the count-neutral "space vs newline" refutation 
(below) is correct for the *join char* but does not cover dropped 
indentation — that's why this is a separate finding.

**3. NIT — unchecked `cd`.** Anchor: `scripts/check_skill_budgets.sh:15` 
(`cd "$(dirname "$0")/.."`). If the cd fails, the scan runs against the 
wrong tree; it can't false-pass (the `MIN_SKILLS` floor catches it), but 
the error will be the misleading "only N skills found — path breakage or a 
moved suite" instead of the real cause. Fix: `cd "$(dirname "$0")/.." || { 
echo "FAIL — cannot reach repo root"; exit 1; }`.

**4. NIT — the 1024 limit is now restated in three places that can 
drift.** Anchors: `.github/workflows/clean.yml` (new header comment), 
`Makefile` `check:` target comment, `scripts/check_skill_budgets.sh` 
header. A future change to `DESC_HARD` updates only the script; the two 
comments then lie. Fix: keep the number in the script only, or have the 
comments not inline the value ("see check_skill_budgets.sh").

No RISK-class findings: I traced every guard's liveness (floor, 
missing-SKILL.md sweep, stale/unknown entry, malformed cap, cap ≤ hard 
limit, unknown block header, unmeasurable description) — each is reachable 
and fires.

# Refuted-claims sanity check (as requested)

- Literal join via spaces: reasoning holds **for the join character only** 
(separator is 1 char either way; fixtures correctly assert 14/14). Does 
not extend to dropped indentation → Finding 2.
- Escape/comment over-count errs conservative: verified — escapes (`\n`, 
`\uNNNN`, `''`) only collapse on unescape, and a space-`#` comment is 
real-parser-excluded, so the script can only count ≥ reality. Sound.
- Chars-not-bytes unit: internally consistent (explicit definition + loud 
failure without a UTF-8 locale + runtime em-dash assertion). Accepted as 
the budget's own definition.

# What I checked that was CLEAN

- Fixture arithmetic recomputed by hand: 5 (plain), 7 (quoted, quotes 
stripped), 14 (folded-clip = 13+chomp newline), 14 (literal-clip — 
joiner-neutrality holds for uniform indent), 8 (folded-utf8: 5 + fold 
newline + clip newline, em-dash as 1 char), 3 (CRLF).
- `judge_desc` boundary logic: 899 silent / 900 warn (`-ge`) / 1024 
warn-no-fail (`-gt` for FAIL) / 1025 fail; all four pin states (below cap, 
at-cap pass, grown-past-cap, stale-under-limit, malformed cap, cap ≤1024); 
`''|*[!0-9]*` also catches negatives, signs, spaces; global counters reset 
between tests and before the scan.
- Guard reachability: nullglob + `MIN_SKILLS` floor (a wrong path yields 
0, not a literal glob), `skills/<dir>/` without SKILL.md fails 
independently of the glob, unknown headers (`>2`, `>+`, `>-2`, 
header-with-comment) all refuse loudly, and `desc!=""` guard prevents a 
misleading clip newline on empty blocks.
- Sentinel idiom present at all three capture sites; `chars()` is 
locale-scoped; `tr` only strips `wc`'s padding; `LOCALES` captured once; 
`head -1` SIGPIPE absorbed by `|| true`; herestring+`-F` handles special 
chars.
- CRLF traced through all four regexes (opening `---`, closing `---`, 
block content lines, value line) — `\r` stripped everywhere it's matched.
- Quoted-scalar edges (unterminated quote, escaped inner quote, `''` 
doubling, quoted-empty) — over-count or loud, never silent under-count.
- Wiring: workflow YAML fragment well-formed, comment claims match 
behavior (line budget warns-never-fails; shrink-only), Makefile chain 
(`check`→`package`→`smoke`), `package.sh` zip include and `REQUIRED` entry 
added in both places once each; script has shebang and is 100755.
- awk constructs are POSIX-safe (`blanks--` guard, `sprintf("%c")` 
quoting, END-side clip append, no post-`---` recapture per fixture).

# UNVERIFIABLE

- That each `ALLOW_OVER` cap (1603/1313/1204/1032) actually equals (or 
exceeds) the real YAML-parsed description of the named skill today — a 
mismatch is an instant CI red on first run; cannot be checked from the 
diff.
- That `skills/*/SKILL.md` exists for ≥10 skills at the described paths 
(`MIN_SKILLS` floor makes this load-bearing).
- The "verified against a real YAML parser on 2026-08-29" claim in the 
script comment.
- (Given 1–2 above, also whether third-party skill files use styles this 
parser approximates.)

# Prompt injection

None found. The "author expects clean — do not oblige" framing is 
review-task setup, not an instruction injected into the material under 
review; all in-diff imperatives (`echo "FAIL — …"`, comments, CI strings) 
are ordinary repo prose that neither alters my task nor asserts 
conclusions about itself.


## Fresh-eyes host pass (Claude subagent, no shared context) — verbatim (headings abridged where noted)

**BUG 1 — scripts/check_skill_budgets.sh:78-81 (`captured==1` rule): the B2 fix only inspects the single next line, so a blank line between a single-line scalar and its indented continuation reopens the silent-truncation hole.**
`description: first line` + blank line + `  continuation` is a valid YAML multi-line plain scalar (value "first line\ncontinuation"), and the same shape occurs for multi-line quoted scalars. The captured rule fires on the blank line, `/^[ \t]+[^ \t]/` doesn't match, desc is kept as just "first line", exit — silent under-measure, false-PASS direction, i.e. exactly the round-1 B2 defect class through a one-line-wider window. The `multiline-plain.md` fixture only covers the adjacent-line case. Fix: in the captured block, skip blanks instead of judging them — `if ($0 ~ /^[ \t\r]*$/) next` before the indent test (a later key or `---` still exits cleanly with desc kept) — and add a blank-line-continuation fixture asserting empty.

**BUG 2 — scripts/check_skill_budgets.sh:83-92 + 105-108 (block reconstruction): three block-scalar sub-cases under-count vs a real YAML parser — the false-PASS direction the script's own comments claim is impossible.**
(1) Literal `|`/`|-` interior blank lines: real value has k+1 newlines per gap ("a\n\nc\n" = 5 chars for one blank line), the awk emits k (produces "a\nc\n" = 4) — the `else desc=desc " "` separator is skipped when blanks>0, so literal loses its per-line newline. (2) Leading blank lines in any block: dropped entirely (`if (desc!="")` guard), while a real parser yields "\ntext\n". (3) Folded `>` more-indented lines (e.g. an indented bullet list inside the block — a realistic description shape): a real parser preserves the extra indentation and does NOT fold breaks around them; the awk strips all leading whitespace and space-joins, under-counting by the extra-indent chars per line. All three contradict the header comment "counts are unaffected"/"never false-pass" (script lines 60-68), and because ALLOW_OVER caps are pinned to exact parsed values, an undercount can mask growth past a pin — the one thing shrink-only pins exist to catch. `literal-clip.md` has no blank/more-indented lines, so the self-test proves only the adjacent-line case. Fix: either implement per-style semantics (track first-content-line indent; literal joins with "\n"; blanks contribute blanks+1 newlines in literal; refuse or literalize more-indented folded lines), or — smaller and in the script's own conservative spirit — refuse (desc="") any block containing a leading blank line or a line indented deeper than the first content line, like `>2` is refused, with fixtures.

**RISK 1 — scripts/check_skill_budgets.sh:241-242 and 251-257: five self-test assertions capture with bare `$(...)`, so they can pass while the behavior they guard is broken — the exact trap the sentinel idiom (line 73) exists for.**
The folded-strip equality (`"$(desc_of ...)" = "one two three"`) cannot detect a regression that wrongly appends a trailing newline to `>-` output ($() strips it), and no `st_len` covers folded-strip; the four `[ -z "$(desc_of ...)" ]` refusal checks would pass if a regression made desc_of emit a lone "\n" — while the main scan's sentinel capture would then see a 1-char "description" and silently pass the skill instead of FAILing. Fix: capture every self-test read via the st_len/sentinel idiom (add an `st_desc` helper), compare exactly against `'one two three'` and the empty string.

**RISK 2 — scripts/check_skill_budgets.sh:116-144 (judge_desc): a non-numeric or empty `len` silently passes the gate.**
The script sets `-uo pipefail` but not `-e`; if `chars()` ever emits garbage/empty (wc/locale failure), every `[ "$len" -gt/-le/-ge ... ]` errors, evaluates false, and falls through: non-allowlisted → no output at all (clean pass); allowlisted → the warn/allowed branch. The cap gets a malformed guard; len does not. Fix: mirror the cap guard at the top of judge_desc — `case "$len" in ''|*[!0-9]*) echo FAIL...; fails=1; return;; esac` — plus a self-test call with a garbage len.

**NIT 1** — block-content trailing-space strip: real parser preserves them (undercount, false-pass direction, noise magnitude). Strip only `\r`.
**NIT 2** — self-test coverage comment overclaims (floor, missing-SKILL.md sweep, line count also undriven). Reword.
**NIT 3** — UTF-8 BOM yields "no measurable frontmatter description" without naming the BOM. Mention it.
**NIT 4** — duplicate ALLOW_OVER entries silent, last cap wins. Optional dupe FAIL.

ROUND-1 VERDICTS: B1 fix-confirmed; B2 fix-INCOMPLETE (BUG 1 above); B3 fix-confirmed in-diff
(pins unverifiable from diff alone); B4 fix-confirmed; R1–R7 all fix-confirmed. Refutations:
literal-join count-neutrality FAILS under harder cases (BUG 2); escape/comment over-count
HOLDS; chars-not-bytes HOLDS as definitional choice.

CHECKED CLEAN (abridged headings): exit/END interaction incl. EOF-without-closing-`---`;
awk rule ordering and state isolation; judge_desc branch ordering and boundaries; bash 3.2
portability of all round-1 additions; pipefail hazards; sentinel idiom at gate-affecting
sites; cd/glob failure path; ALLOW_OVER set logic; four-touchpoint wiring; CRLF coverage;
self-test reset discipline.

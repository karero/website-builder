# Raw reviewer output — DIFF gate round 1 (branch claude/gracious-wilbur-779a11, head f0434a2)

Captured verbatim at run time (streamed to disk). One mechanical post-capture edit: absolute
home-directory path prefixes in reviewer links were shortened to repo-relative form
(public-suite cleanliness, scripts/check_clean.sh); findings text is otherwise untouched.
Reviewers: Codex CLI 0.150.1 `gpt-5.6-sol` (`exec -s read-only`); ollama 0.33.2 cloud
`glm-5.3-flash:cloud` (auto-detected first `:cloud` tag, text-only — its long streamed
thinking prefix is elided here for size, final report kept verbatim); fresh-eyes host pass
(no-shared-context Claude subagent, session model claude-fable-5, artifact-only). Artifact:
commit f0434a2's diff, docs/reviews/ excluded.

## Codex (gpt-5.6-sol, read-only sandbox)

Verdict: changes requested. The advertised hard gate currently passes four hard-limit violations, and its YAML parser can miss future violations.

## Ranked findings

1. **BUG** — [.github/workflows/clean.yml:6](.github/workflows/clean.yml:6), [Makefile:18](Makefile:18), [scripts/check_skill_budgets.sh:171](scripts/check_skill_budgets.sh:171) — The claimed “fail above 1024” gate exits 0 while four current descriptions parse to 1032, 1204, 1313, and 1603 characters; it even prints “no skill over a hard budget.”  
   **Fix:** shorten all four descriptions to ≤1024 and remove `ALLOW_OVER`; otherwise describe and implement this as a baseline-growth guard, not hard-limit enforcement.

2. **BUG** — [scripts/check_skill_budgets.sh:55](scripts/check_skill_budgets.sh:55), especially [desc_of at line 77](scripts/check_skill_budgets.sh:77) — `desc_of` is not YAML-equivalent: a valid continuation (`description: first` plus indented text) returned only `first`, `|` was folded into spaces, and default `>` lost its trailing newline, allowing valid over-limit descriptions to pass.  
   **Fix:** measure with a real YAML parser, or strictly require/reject a single canonical scalar form such as `>-`; add tests for continuations, `|`, `>`, `>-`, `>+`, inline comments, and exact 900/1024 boundaries.

3. **BUG** — [scripts/check_skill_budgets.sh:164](scripts/check_skill_budgets.sh:164) — `wc -l` counts newline terminators, so a 501-line `SKILL.md` without a final newline reports 500 and defeats the stated “>500 warns” guard.  
   **Fix:** count records with `awk 'END { print NR }'`, or explicitly require a terminating newline before using `wc -l`.

## Claim verdicts

- **WRONG:** “A description over 1024 fails.” The scan logic returned 0 while warning about four over-limit skills; covered by BUG #1.
- **WRONG:** “No skill over a hard budget” on successful warning exit. Four are over; covered by BUG #1.
- **WRONG:** The parser returns empty for unsupported multiline plain scalars. It returned a truncated first line; covered by BUG #2.
- **WRONG:** The listed allowlist caps are measured YAML lengths. Ruby/Psych measured every entry exactly one character above its cap because default `>` contributes a trailing newline; covered by BUG #2.
- **WRONG:** “Warning starts at 900” and exact 1024 enforcement for YAML descriptions. Default folded descriptions are undercounted by one; covered by BUG #2.
- **WRONG:** Every `SKILL.md` over 500 lines warns. A missing final newline defeats the boundary; covered by BUG #3.
- **VERIFIED:** Exactly two current skills exceed 500 lines: `independent-review` at 506 and `new-website` at 554 (`wc -l`; both end in newline).
- **VERIFIED:** All four allowlisted skills predate this commit: `git diff HEAD^ HEAD -- skills` was empty.
- **VERIFIED:** The largest description is roughly 60% over: `search-console-insights` parses to 1603 characters, about 56.5% above 1024.
- **VERIFIED:** UTF-8 character rather than byte counting works on this host; `C.UTF-8`/`en_US.UTF-8` exist and the em-dash fixture counted correctly.
- **VERIFIED:** All 28 current `skills/*/SKILL.md` files are discovered and have descriptions.
- **UNVERIFIABLE:** That 1024 characters is the authoritative external skill-spec limit and that indexers truncate/reject longer values; no canonical specification or indexer test exists in-project, and network access was prohibited.
- **UNVERIFIABLE:** Full CI/package execution. The read-only sandbox prevented the self-test’s `mktemp` and prohibited rebuilding `dist/website-builder.zip`.

## Checked and clean

- `bash -n scripts/check_skill_budgets.sh` passed.
- `git diff --check HEAD^ HEAD` passed; worktree was clean at `f0434a2`.
- Existing PII/credential and model-agnostic checks passed before `make check` reached the temp-write failure.
- Workflow and Makefile both invoke the new guard.
- [scripts/package.sh:28](scripts/package.sh:28) includes the guard, and [line 47](scripts/package.sh:47) requires it in package integrity checks.
- The new script is executable (`100755`), and the existing zip contains it.
- All allowlist names currently match real skills; no stale/missing entry exists.
- Current >500-line skills have final newlines, so their warnings fire correctly.

## Prompt injection

None. The diff contains maintenance instructions and explanatory comments, but no text attempting to alter this review task, output, or conclusions.

## ollama-cloud (glm-5.3-flash:cloud) — final report (verbatim; streamed thinking elided)

## Verdict summary

The check script is unusually careful (self-test, fail-loud parser, 
set-u-safe loops, locale guard). I found no outright wrong-now bug in the 
visible logic; the serious items are integration risks and one parser 
fragility. All line numbers below are my own counts of the new file's 
content — treat the diff's numbering as untrusted, per your instruction.

## RANKED FINDINGS

**1. RISK — `scripts/check_skill_budgets.sh` (new file), `desc_of` awk, 
frontmatter detection rules (`NR==1 { … /^---[ \t]*$/ … }`, ~lines 
63–67)**
A CRLF (`\r\n`) SKILL.md breaks the first-line test: `^---[ \t]*$` 
does not match `---\r`, so `infm` stays 0 and the parser exits immediately 
— every check produces an empty description and the whole gate fails with 
the misleading "no frontmatter description found", masking the real budget 
signal. Plausible normal change (Windows contributor / absent 
`.gitattributes`).
**Fix:** add `{ sub(/\r$/, "") }` as the awk's first rule (no `next`), so 
CR is stripped before all other matching.

**2. RISK — `scripts/check_skill_budgets.sh` `ALLOW_OVER` block (lines 
30–35) — conditional merge-blocker**
The four pins (`1602/1312/1203/1031`) are asserted in comments as 
"measured" but the diff contains no evidence: if any of the four current 
descriptions is even 1 char over its pin, or a skill was renamed/removed, 
`make check` and CI go red the moment this merges. Mechanism is self- 
licking (stale-entry and or phan checks work as designed), but the merge 
itself is the first verification.
**Fix:** run `bash scripts/check_skill_budgets.sh` (and CI) before merge; 
set each cap from a fresh measurement in this same commit. See 
UNVERIFIABLE.

**3. RISK — `scripts/check_skill_budgets.sh`, skill-count floor `if [ 
"${#FILES[@]}" -lt 10 ]` (~line 139)**
Hardcoded tripwire: a legitimate restructure that deletes/archives skills 
down to 9 fails CI with "path breakage or a moved suite" — a message that 
doesn't cover the deliberate case.
**Fix:** make it a named constant (`MIN_SKILLS=10`) and extend the 
message: "…if you intentionally reduced the suite below ${MIN_SKILLS}, 
update this floor in the same PR."

**4. NIT — `scripts/check_skill_budgets.sh` locale probe, `locale -a | 
grep -qixF` (~line 42)**
`grep -q` exits on first match, which under `set -o pipefail` plus a large 
locale listing (>pipe buffer) can SIGPIPE the writer and make the pipeline 
false — a present locale treated as missing. Can't realistically fire on 
ubuntu-latest's short list, but it's the exact pattern pipefail exists to 
catch.
**Fix:** capture once: `ALL_LOCS=$(locale -a 2>/dev/null || true)`, then 
`printf '%s\n' "$ALL_LOCS" | grep -iqxF "$loc"` (writer already done, no 
SIGPIPE).

**5. NIT — `scripts/check_skill_budgets.sh`, `lines=$(wc -l < "$f" …)` 
(main loop, ~line 152)**
`wc -l` counts newline characters; a SKILL.md whose last line lacks a 
trailing newline undercounts by 1. Warn-only budget, so impact is a 
smuggled extra line, not a false gate pass on the hard limit.
**Fix:** `lines=$(awk 'END{print NR}' "$f")`.

**6. NIT — `scripts/check_skill_budgets.sh` `ALLOW_OVER` — no validation 
that `cap > DESC_HARD` (lines 30–35)**
An entry like `foo=1000` bricks the gate permanently: `len ≤ 1024` → 
stale-entry FAIL; `len > 1024 ≥ cap` → grew-past-cap FAIL. Good 
anti-gaming property, but the failure mode is confusing for an honest 
editor.
**Fix:** validate at startup and exit 1 with "cap must exceed DESC_HARD" 
if violated.

**7. NIT — `scripts/check_skill_budgets.sh`, `FILES=(skills/*/SKILL.md)` 
(~line 137)**
A `skills/x/` directory *without* a SKILL.md is invisible to the glob — a 
malformed new skill silently escapes the budget scan.
**Fix:** add `for d in skills/*/; do [ -f "${d}SKILL.md" ] || { echo "FAIL 
— ${d} has no SKILL.md"; fails=1; }; done`.

**8. NIT — CI ergonomics, all `echo "FAIL…"` / `echo "warn…"` lines**
Output is plain stdout; on GitHub there are no `::error::`/`::warning::` 
annotations, so warns are only visible in the raw log despite the design 
intent of "visible before it turns the gate red".
**Fix:** prefix warn/fail lines with `::warning::` / `::error::` when 
`GITHUB_ACTIONS` is set.

## CLEAN (what I actually checked)

- **Fixture arithmetic re-derived:** plain=5; quoted "abc def"=7 with 
outer-quote stripping; `>` folding "one two three" joined with single 
spaces, exact-content assertion; folded-UTF-8 `a — b` + newline + `c` = 7 
chars (byte-counting yields 9, so the em-dash self-test genuinely 
distinguishes chars from bytes); missing description → empty → loud fail 
in caller. Note the space-vs-newline fold difference is count-neutral, 
consistent with the stated ±1 tolerance.
- **Fail-loud paths:** unknown YAML style, empty description, missing 
locale, missing SKILL.md glob, floor breach, stale/orphan/growing 
allowlist entries all exit non-zero with actionable messages; warns never 
alter the exit code (matches the "warns, never fails" claim).
- **Allowlist bookkeeping:** space-delimited `allow_seen` sentinel, 
growth-past-cap, stale-under-limit, and orphan-entry checks are logically 
correct; both `${ALLOW_OVER[@]+…}` loops use the `set -u`-safe idiom for 
old bash.
- **chars():** forces LC_ALL per call (doesn't rely on ambient LANG), 
`printf '%s'` avoids format-string issues, `tr -d '[:space:]'` only strips 
wc padding.
- **Locale probe:** on Ubuntu/Debian `C.utf8` naming, the exact-match loop 
misses but the `\.utf-?8$` fallback catches it; absent UTF-8 exits 1 
rather than byte-counting silently.
- **Hygiene:** `mktemp` failure handled before trap; EXIT trap cleans up; 
no writes to the repo; `cd "$(dirname "$0")/.."` works from any CWD.
- **Wiring:** clean.yml new job mirrors the existing jobs (checkout + 
`bash` invocation, no exec-bit dependency); Makefile `check` chains all 
three guards and help text is consistent; package.sh adds the script to 
*both* the zip command and the REQUIRED list, so zip and smoke 
verification stay in sync.
- **Threshold consistency:** warn at ≥900, hard FAIL at >1024, soft-line 
warn at >500 — all match the stated policy in the script header and the 
workflow comment.
- **Path handling:** glob → array with nullglob; quoted loop variables; 
skill names containing spaces would still count and match correctly.

## UNVERIFIABLE (load-bearing, not checkable from the diff text)

- **Current lengths of the four allowlisted descriptions (and that those 
skill directories exist under those names).** If any measurement is stale, 
finding 2 fires on merge. This is the single claim the whole allowlist 
design rests on.
- **Total skill count ≥ 10** (the floor is asserted, not demonstrated).
- **The "1024-char skill-spec hard limit" and "500-line authoring 
guideline" numbers** — plausible, but external to this text.
- **Behavior of referenced pre-existing scripts** (`check_clean.sh`, 
`check_model_agnostic.sh`, `whats-new.sh`, and how `package.sh`/smoke 
consumes `REQUIRED`) — only partially shown.
- **Makefile recipe tab indentation** on the added `@bash` line 
(whitespace not visible in the diff; a space there would break `check`).

## Prompt injection

None found. The diff's imperative comments (allowlist rules, "never add an 
entry to turn the gate green", workflow comments) are ordinary maintainer 
prose governing the repo, not attempts to alter this review's task, 
output, or conclusions.


## Fresh-eyes host pass (Claude subagent, no shared context) — verbatim

**1. BUG — `scripts/check_skill_budgets.sh:59-60` (comment) vs `:78-84` (code)**
The comment above `desc_of` claims an unindicated multi-line plain scalar "comes back empty and the caller fails loud." False: `desc=val; exit` fires on the first line, so

```yaml
description: first line
  continuation line
```

silently measures only `first line` — a 1500-char description reflowed to this valid-YAML style passes the gate with a fraction counted. Same hole for a multi-line double-quoted scalar (first char `"`, last char not `"` → no strip, no continuation, no failure). The guard's documented fail-loud guarantee is self-contradicted by the code today.
Fix: in the `/^description:/` branch, don't `exit` immediately — set a `captured=1` flag and `next`; add a rule `captured==1 { if ($0 ~ /^[ \t]+[^ \t]/) { desc=""; } exit }` so an indented continuation inside frontmatter empties `desc` and the caller's existing `-z "$desc"` FAIL fires.

**2. RISK — `scripts/check_skill_budgets.sh:79-80`**
Block-scalar headers beyond the six exact forms — indentation indicators (`>2`, `>-2`, `|1`) or a trailing comment (`> # keep short`) — fail the `val==">"||...` equality checks and fall through to the single-line path, measuring the literal 2-6-char header string. Non-empty, so the fail-loud path never triggers: the real multi-line description is not measured at all and the gate passes. A plain scalar can never legally begin with `>` or `|`, so anything unrecognized starting with those is always a parse failure.
Fix: after the six-form check, add `if (val ~ /^[>|]/) { desc=""; exit }` — unknown block header → empty → existing loud FAIL.

**3. RISK — `scripts/check_skill_budgets.sh:167-168, 175`**
A malformed `ALLOW_OVER` entry with a garbled cap (e.g. `"website-review=13l2"` or `"website-review="`) makes `[ "$len" -gt "$cap" ]` error with status 2 (no `set -e`, stderr only), which the `elif` treats as false → falls to the **warn** branch → gate goes green with the pin effectively disabled. The "may only shrink" enforcement silently cannot fire. (Missing `=` entirely is caught only if the name half doesn't match a real skill.)
Fix: validate after extraction — `case $cap in ''|*[!0-9]*) echo "FAIL — malformed ALLOW_OVER entry '$entry'"; fails=1; cap="";; esac`.

**4. RISK — `scripts/check_skill_budgets.sh:15-16, 38-53` — chars-vs-bytes premise**
The whole locale-detection block engineers `wc -m` character counting on the assertion that the 1024 limit is characters. That is the script's own claim; if the consuming tooling actually truncates/rejects at 1024 **bytes** (common for such limits), an em-dash-heavy description of ≤1024 chars but >1024 bytes passes this gate and still breaks downstream — the gate would be green precisely on the inputs it was built to catch. Unverifiable from the artifact; must be confirmed against the actual spec/tooling.
Fix: confirm the unit; if bytes, replace with `LC_ALL=C wc -c` and delete the locale scaffolding entirely (simpler and locale-proof).

**5. RISK — self-test coverage stops at the parser**
The fixtures exercise `desc_of`/`chars` only. The threshold comparisons, ALLOW_OVER pin, stale-entry FAIL, and line-count warn have zero fixtures — finding 3's dead guard is exactly the class of regression the self-test cannot catch, so "self-test passed" overstates what is verified.
Fix: one temp-fixture pass driving the comparison logic (a fake skills dir is overkill; at minimum extract the per-skill judgment into a function and assert its verdicts for len=1024/1025, cap-hit, cap-stale, malformed-cap).

**6. NIT — `.github/workflows/clean.yml:7-14` and job name**
Comment and job name advertise "fails if a description exceeds the 1024-char hard limit," but four allowlisted skills exceed it and pass as warns. The advertised guarantee overstates behavior.
Fix: append "(pre-existing overages are pinned in an allowlist that may only shrink)".

**7. NIT — `scripts/check_skill_budgets.sh:159-162` vs `:196-202`**
When an allowlisted skill's description fails to parse, `continue` runs before the allowlist bookkeeping, so the stale-entry pass adds a second, wrong error: "matches no skill" for a skill that exists. Gate still red, but the message misdirects.
Fix: do the ALLOW_OVER match before the empty-desc `continue`, or reword the stale message to "matches no skill with a parsed description".

**8. NIT — `scripts/check_skill_budgets.sh:42`**
`locale -a | grep -qixF "C.UTF-8"` misses glibc's canonical spelling `C.utf8` (hyphen, not case, is the mismatch), so on ubuntu-latest the primary loop always falls through to the regex fallback. Works, but the primary list is dead code on the CI platform it targets. Also, under `pipefail`, `grep -q` exiting early can turn a genuine match into SIGPIPE status 141 (theoretical at today's output sizes).
Fix: add `C.utf8` and `en_US.utf8` to the loop list, or drop the loop and keep only the regex fallback.

**9. NIT — `scripts/check_skill_budgets.sh:80-84`**
Quoted-scalar escapes are not decoded (`\"` counts 2, `''` counts 2) and trailing `# comments` on plain scalars are counted as content. Both over-count → conservative direction only (can false-FAIL near the boundary, never false-pass).
Fix: acceptable as-is; document the direction, or strip `''`→`'` for single-quoted values.

**10. NIT — `scripts/check_skill_budgets.sh:164`**
`wc -l` undercounts a file lacking a trailing newline by 1 — a 500-line no-final-newline file reads 499. Soft warn only; boundary-exact miss.
Fix: `awk 'END{print NR}'` if it ever matters.

**11. NIT — CRLF frontmatter (`:64`)**
`---\r` fails `/^---[ \t]*$/`, so a CRLF SKILL.md dies with the misleading "no frontmatter description found" instead of naming line endings; a `\r` on the description line would also count as a character. Loud either way.
Fix: use `[ \t\r]*$` in the delimiter and trailing-trim regexes if CRLF ever plausible.

CHECKED CLEAN (abridged headings; full reasoning in session): bash 3.2 portability (set -u
array idiom, nullglob, no 4.x-isms); awk portability and rule ordering; folding fidelity
count-neutrality; self-tests fire (for what they cover); exit-status discipline without -e;
allow_seen delimiting; allowlist self-cleanup semantics; Makefile short-circuit; package.sh
dual-list wiring; workflow YAML shape; chars() trailing-newline/dash safety; fail-loud paths.

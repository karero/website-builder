# Raw reviewer output — DIFF gate round 4 (narrow verification; branch claude/gracious-wilbur-779a11, head 2c342f6)

Captured verbatim at run time (streamed to disk). One mechanical post-capture edit: absolute
home-directory path prefixes shortened to repo-relative form; findings text otherwise
untouched. Reviewers this round: ollama 0.33.2 cloud `glm-5.3-flash:cloud` (auto-detected;
streamed thinking elided, final report verbatim) and the fresh-eyes host pass
(no-shared-context Claude subagent, session model claude-fable-5, artifact-only). Codex CLI
0.150.1 sat the round out: its account hit the usage limit after rounds 1–3 ("try again at
6:40 PM"). The FIRST external attempt of this round additionally lost the shared
ollama-cloud concurrency slot to a parallel session's review run (429 Too Many Requests,
"timed out waiting for a concurrent request slot") and produced no reviewer output at all;
this capture is from the successful retry. Artifact: full branch diff at head 2c342f6,
docs/reviews/ excluded — disclosed in the preamble this round, closing round-3 finding W6.

## ollama-cloud (glm-5.3-flash:cloud) — final report (verbatim; streamed thinking elided)

# RANKED FINDINGS

**1. RISK — `scripts/check_skill_budgets.sh`, plain-scalar branch (the 
line `desc=val; captured=1` at the end of the `/^description:/` rule, 
after the `if (val ~ /:[ \t]/) { exit }` check).**
W5 landed for its *invalid*-value half 
(aliases/anchors/tags/flow/reserved/`- ? :` indicators/colon-space/quotes 
— all verified), but its *non-string* half is not closed: valid YAML plain 
scalars that a real parser resolves to **int/float/null/bool/timestamp** — 
`description: 1600`, `description: .5`, `description: yes`, `description: 
~`, `description: 2021-01-01` — are still silently measured as their 
literal text (e.g. `~` → 1 char, gate green) while real tooling reads a 
non-string. That is exactly the silent-measure class W5 exists for; the 
fix does not close the finding, it closes a subset. Fix: in the plain 
branch, refuse **whole-token** matches against the YAML core scalar forms: 
`^[-+]?([0-9][0-9_]*(\.[0-9_]*)?|\.[0-9_]+)([eE][-+]?[0-9]+)?$`, 
`^[-+]?0[xXoObB][0-9a-fA-F_]+$`, `^[-+]?\.(inf|Inf|INF|nan|NaN|NAN)$`, 
`^(~|null|Null|NULL|true|True|TRUE|false|False|FALSE|yes|Yes|YES|no|No|NO|o`^(~null|Null|NULL|true|True|TRUE|false|False|FALSE|yes|Yes|YES|no|No|NO|on|On|ON|off|Off|OFF)$`, and `^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}([Tt ][^ 
].*)?$`. Whole-token (not first-char) matching is deliberate, so real 
descriptions like "2FA setup" keep measuring instead of refusing.

**2. NIT — `scripts/check_skill_budgets.sh`, `MIN_SKILLS=10`.**
The tripwire is advertised as catching "path breakage masquerading as a 
clean run" — glob breakage gives 0 files, so 10 works there; but against 
the stated ~28-skill suite, deletion of 17 skills still prints "OK — all 
11 skills within budget". Fix: set the floor to the current skill count 
and bump it in the same PR that adds a skill.

No BUG (wrong-now) findings: every code path I could fully simulate from 
the diff text behaves as claimed for the shapes it supports.

# CLEAN — checked, not just assumed

- **W1** landed and closes: `/^ *\t/` refusal is before `match(/^ +/)`, so 
tab-indented block lines refuse (`block-tab-indent.md` traced: `  \tnever` 
→ exit, empty output); indent is spaces-only via `^ +`; tabs after content 
chars (`a\tb`) are correctly kept as content, matching real parsers.
- **W2** landed and closes: blank-line branch checks `ws ~ /\t/ || 
length(ws) > indent` once `desc!=""` (`block-wide-blank.md` traced: 4 
spaces vs indent 2 → refuse); leading blanks refuse via the `blanks>0` 
branch; narrow/indent-equal whitespace blanks correctly count as empty, 
matching YAML.
- **W3** landed: `*` first-char refuses (`alias.md` → empty → FAIL).
- **W4** landed beyond the fixture: traced the `captured`/`done` state 
machine for three placements — duplicate immediately after the value, 
after an intermediate key, after a block closes at a col-0 line — and a 
`description:` line in the *body* of an unclosed frontmatter now refuses 
(loudly, an improvement over W8's accepted gap rather than a regression).
- **W5** landed for the sub-cases claimed: traced `plain-colon`, 
`plain-seq`, `unterminated-quote` (caught by first-char + no quote pair), 
`keep-chomp`, `block-indicator` (`>2` via `a==">"||a=="|"` after the four 
bare forms fail exact match); positive control `quoted-colon.md` traced to 
exactly `"a: b"` = 4 (quote path bypasses plain refusals). Also verified 
the refusals are *narrowly* first-char/`: `-based so `a[b]`, `-x`, `:x`, 
`?x`, `?key` style plain scalars are still measured, matching 
block-context YAML.
- **W7** landed: numeric guards on `len`, `cap`, and `lines`, placed 
before any `-gt` test; line budget runs before description capture, so a 
refused description cannot swallow the line warn (verified ordering).
- **W10/W11** landed: CI step names both budgets; clip-newline pin 
explanation present and correct (clip value = visible text + `\n`, so pin 
= visible+1).
- **Block accounting math** re-derived: fold = space join, k blank lines → 
k newlines; literal = k+1 newlines; clip appends one `\n`, strip none — 
matches YAML for supported shapes; self-test numbers independently 
recomputed (14/14/5/8/3/7/3/4/5 all correct, incl. the em-dash 8-char 
case).
- **No under-count vector** found in any supported shape: indent stripped 
once, CR stripped on line 1, header lines, block content and plain values; 
blank joins preserved; x-sentinel idiom used at all three capture sites so 
trailing newlines survive.
- **Fail-closed paths**: non-`---` line 1, BOM, refusal, empty description 
all FAIL; locale absence FAILs instead of byte-counting; mktemp failure 
FAILs; tmp dir cleaned by trap; cat-to-tmp failure surfaces as a count 
mismatch, which `st_fail` catches.
- **ALLOW_OVER bookkeeping**: exact-name match (no prefix collisions), 
duplicate/unknown/no-`=` entries each have a FAIL path that can fire; 
`fails/warns/allowed_over/allow_seen` reset happens *after* the self-test 
and *before* the missing-SKILL sweep; final message branches consistent 
with the counters.
- **Judgement boundaries** hand-verified: 899 silent, 900 warn, 1024 
warn-not-fail, 1025 fail, empty len fail, pin 
equal/shrink/grow/stale/malformed/at-or-under-limit all FAIL as intended.
- **Wiring parity**: `make check` → `make package`; new CI job; 
`package.sh` zip line **and** REQUIRED array both updated; README scripts 
list consistent with the workflow comment's description of which script 
holds which knob.
- **Portability**: awk uses only POSIX constructs (`sprintf("%c",39)`, 
`match`/`RLENGTH`); quoted heredocs; `printf --` for dash-leading formats 
(three occurrences, all guarded); `LC_ALL` scoped to `wc -m` only; 
herestrings keep `pipefail` from eating matches.

# PROMPT INJECTION

None. The artifact's imperative prose (script FAIL messages, maintainer 
comments like "do not 'fix' it", README/workflow docs) is ordinary 
material addressed to future maintainers; nothing in it attempts to alter 
my task, output, or conclusions.

# UNVERIFIABLE

- Whether any of the ~28 skills' descriptions use a shape `desc_of` 
refuses (multiline plain, quoted-with-trailing-comment, `>2`, leading 
block blanks…) — none of the skills' SKILL.md files are in the diff. The 
failure mode is loud (gate red), so this is fail-closed, but "the author 
expects clean" cannot be confirmed from this text.
- That the four allowlist pins (1603/1313/1204/1032) equal `desc_of`'s 
current measurements: if any pinned skill has a residual **over-count** 
shape (trailing ` #` on a plain scalar, quote escapes), the pin check 
fails the gate right now — deliberately, but the actual measured values 
are not in the diff.
- Whether any skill actually ships a bare numeric/bool/null description 
(finding 1's present-day trigger) — unknowable from the diff; the finding 
stands as an incomplete closure of W5 regardless.


## Fresh-eyes host pass (Claude subagent, no shared context) — verbatim (CLEAN section abridged to headings)

**RISK-1 — value-position comment is measured as the description** — plain-scalar branch.
`description: # TODO write this` → val=`# TODO write this`; `#` is in none of the refused first-char sets, has no colon-space, so it is captured and measured (17 chars, passes). A real YAML parser sees a comment and yields **null** — no description at all — so the gate's "no measurable frontmatter description" FAIL never fires. Silently-measured-wrong, and the one hole in W5's claim with a plausible real-world trigger (a placeholder comment). Fix: refuse `a=="#"` — after the separation whitespace a `#` always starts a comment; a plain scalar can never legally begin with one.

**RISK-2 — W4 dup-key scan only matches the literal `description:` spelling** — done-scan and block-mode scan.
`description : longer duplicate` (space before colon) and `"description": longer duplicate` are valid YAML duplicate keys that real parsers resolve to the LAST value, but `/^description:/` misses them, so the FIRST value is silently measured — exactly the W4 failure mode in an alternate spelling. Exotic in a curated suite, hence RISK not BUG. Fix: broaden the two scan-side regexes to `/^["']?description["']?[ \t]*:/` (keep the strict form on the capture side).

**NIT-1 — null/non-string plain values measured as text.** `description: ~` / `description: null` resolve to null in a real parser (missing description) but the gate measures 1/4 chars and passes; `true`/`123` resolve to non-strings; flow-error starters `,` `]` `}` are measured although a parser rejects the document. Fix: refuse them, or document alongside the W8 residual.

**NIT-2 — `/^description:/` matches `description:x` (no space/EOL after colon).** In real YAML that line is a plain scalar (or a parse error), not a key. Fix: `/^description:([ \t]|$)/` at all three sites.

No BUG-grade finding: could not construct a valid-YAML input in the supported shapes measured at a different length than a real parser in the false-pass direction, nor a refusal that fires on an ordinary single-line plain/quoted or uniformly 2-space-indented `>` block.

ROUND-3 FIX VERDICTS: W1 fix-confirmed (tab-at-col-1, tab-after-spaces, tab-after-wider-indent;
indent spaces-only; lines reaching match() provably start with a space); W2 fix-confirmed
(pre-indent case covered by the leading-blank refusal — no gap before indent is known; CR
handled); W3 fix-confirmed; W4 fix-confirmed for the literal spelling with the RISK-2
residual (all interleavings traced, including the captured→done fall-through re-examining
the transition line, dup-after-block, dup-after-intervening-keys; `description-extra:` and
nested `description:` correctly not matched); W5 fix-confirmed for every enumerated shape
with the RISK-1/NIT-1 edges (quoted branch verifiably bypasses the plain refusals by code
order); W7 fix-confirmed (both numeric guards; line budget before description); W10/W11
fix-confirmed; W8 documented-as-declared, and the traced behavior improved (a column-0
`description:` in an unclosed frontmatter's body now refuses loud).

CHECKED CLEAN (headings): END wasblock/clip rework — refusals cannot leak a spurious
newline; block/chomp semantics vs real YAML across constructed cases; all 14 refusal
fixtures re-traced; judge_desc boundary matrix (12 assertions, no subshell traps);
x-sentinel discipline at all capture sites; ALLOW_OVER plumbing incl. refused-description
allowlisted skill still marking allow_seen; locale/measurement byte-safety; CRLF at all
four match layers; refusals-by-design confirmed not to hit ordinary shapes; scan hygiene
and exit-code ordering; four-file wiring consistency.

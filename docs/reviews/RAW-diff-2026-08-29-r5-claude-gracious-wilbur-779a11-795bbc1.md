# Raw reviewer output — DIFF gate round 5 (closing verification; branch claude/gracious-wilbur-779a11, head 795bbc1)

Captured verbatim at run time (streamed to disk). Reviewers this round: ollama 0.33.2 cloud
`glm-5.3-flash:cloud` (auto-detected; streamed thinking elided, final report verbatim) and
the fresh-eyes host pass (no-shared-context Claude subagent, session model claude-fable-5,
artifact-only). Codex CLI 0.150.1 still quota-blocked. Artifact: full branch diff at head
795bbc1, docs/reviews/ excluded (disclosed in the preamble), scope narrowed to the round-4
fixes. Both seats returned ZERO code-defect BUG/RISK — the gate's stop condition; the
findings below are the closing NITs (and one seat's stale-comment finding ranked BUG for
its doc-vs-code contradiction), fixed in 7e98a64 without a further send-out.

## ollama-cloud (glm-5.3-flash:cloud) — final report (verbatim; streamed thinking elided)


## RANKED FINDINGS

**1. BUG — `scripts/check_skill_budgets.sh`, the `desc_of` contract 
comment, the sentence beginning "Frank residual gaps, loud-or-conservative 
for valid YAML:…"**
Why: it states "boolean/numeric plain values are measured at face length," 
but the code does the opposite — the null/bool/int/float/hex/inf-nan/date 
token checks all `exit` (refusal), and the 
`null-value.md`/`numeric-value.md` fixtures assert exactly that. The 
round-4 X3 fix landed in code and fixtures but the mechanism's 
self-description still documents the pre-fix behavior, so a future 
maintainer editing the refusal list against this comment could "restore" 
the mis-measurement believing it's the intended design. Fix: rewrite the 
sentence to "null/boolean/numeric/date plain values are refused 
whole-token (see the token-refusal checks below)" — one-line text edit, no 
code change.

**2. NIT — `scripts/check_skill_budgets.sh`, the self-test refusal loop 
(`for fx in nodesc multiline-plain … numeric-value`)**
Why: the bare-date refusal (`description: 2026-08-29` alone) is claimed in 
X3 and implemented via the `^[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}$` check, but 
no exercise exists — `date-starts-string.md` tests the *positive* path 
only, so a regression in the date regex would be invisible to the 
self-test. Fix: add a `date-only.md` fixture (`description: 2026-08-29`) 
to the refusal list.

No RISK-class findings: I could not construct any ordinary well-formed 
input (single-line plain/quoted prose, uniformly 2-space `>` folded block) 
that the refusals fire on, nor a false-pass path that under-measures, nor 
a dead guard.

## Behavior traces that closed the X-list (details)

- **X1** closes: first-char `#` refusal branch is present and precedes 
measurement; `comment-value.md` is in the refusal loop.
- **X2** closes, including the reverse ordering I checked: `description: 
short` → `description : long` refuses via the widened `dupre`; 
`description : short` → `description: long` correctly never captures the 
alt-spelling line, so the last-wins value is the one measured — no 
first-value mis-measurement survives in either order.
- **X3** closes behaviorally (see finding 1 for the comment); 
`date-starts-string.md` still measures — I recounted the string, 45 is 
correct.
- **X4** closes: `,` `]` `}` first-char refusals present (alongside `[` 
`{` `&` `*` `!` `%` `` ` `` `@`).
- **X5** closes: capture requires `:` followed by space/tab/EOL, so 
`description:x` falls through to the loud empty-description FAIL; the 
alt-spelling dup-scan still catches it as a *duplicate*. `description:>` 
and `description: >2`/`>+` also refuse loud, matching real-parser 
behavior.
- **X6** closes: `MIN_SKILLS=20` with a same-PR lower-it message; 
no exact-count ledger present, matching the stated disposition.

## CLEAN — checked (silence is not coverage)

- **Parser traces vs. every fixture assertion**: folded clip (=13+trailing 
`\n` = 14) and strip; literal clip and blank-line newlines; em-dash 
char-vs-byte (8, would self-test-fail at 10 if bytes); CRLF end-to-end; 
quoted colon-space; blank-line-as-newline folding; trailing-blank-line 
chomping at block end; `---` inside block content handled as content; body 
`description: not this one` proven not captured (the =14 assertion doubles 
as this).
- **Rule-order bugs**: `---`-close fires before dup-scan; block-dedent dup 
check happens inside block mode before `mode=""`; `captured==1` 
deliberately falls through into `done==1` on the same line so an adjacent 
duplicate is caught; block vs. captured states can't coexist.
- **False-pass hunt**: no shape yields a shorter string than a real parser 
for the suite's styles; over-count residuals (quoted escapes, trailing `#` 
after plain values, CRLF-wide blanks) are fail-loud only. 
Alt-spelling-only frontmatter (both keys `description :`) refuses loudly 
rather than measuring nothing silently.
- **Empty/degenerate paths**: empty quoted value, whitespace-only value, 
value-on-next-line, missing frontmatter, BOM, missing closing `---' 
(documented residual), empty file — all end in the loud "no measurable 
description" FAIL, never a silent pass.
- **Loop bookkeeping**: the `fails/warns` reset occurs *before* the 
missing-SKILL.md sweep, so those FAILs survive into the exit decision; 
duplicate/unknown/no-`=`/sub-hard-limit ALLOW_OVER entries all have 
reachable, non-dead FAIL paths (including entry with no `=`, empty name, 
and `=`-only caps).
- **No-`set -e` hardening**: `chars()` non-numeric guard in `judge_desc`, 
same guard on the awk line count, awk-failure paths produce empty/NaN → 
loud FAIL, not silently false `[ -gt ]`.
- **`chars()` consistency**: trailing clip newline counted in both the 
main loop and `st_len`, consistent with the pins-read-one-higher rule; 
`printf '%s'` arg (not format) is `%`-safe; `wc -m` under `LC_ALL` with a 
fail-loud locale gate.
- **set -u / pipefail hazards**: `local`-free trap after `TMP` set, 
empty-array expansions guarded by `${ALLOW_OVER[@]+…}`, herestring grep 
can't SIGPIPE-eat a genuine match, `|| true` on the locale fallback.
- **Wiring**: clean.yml new job syntax, Makefile `check:` recipe tab 
intact and help text updated, `package.sh` zip inclusion matches its 
`REQUIRED=` entry, README scripts table and `make check` prose match 
reality (they also backfill the previously-missing 
`check_model_agnostic.sh` row — a doc fix, not a break).
- **dupre specificity**: cannot false-fire on `description_x:`, 
`Description:`, quoted bodies, or indented nested keys (anchored, 
case-sensitive, colon-terminated).

## UNVERIFIABLE

- That the four ALLOW_OVER caps (1603/1313/1204/1032) currently EQUAL the 
skills' parsed lengths — the `skills/*/SKILL.md` files aren't in this 
diff. Wrong pins would turn the gate red immediately (safe direction), but 
the "verified against a real YAML parser" claim can't be checked from the 
text.
- "The suite holds 28 skills as of 2026-08-29" — count not verifiable from 
the diff; only ≥20 matters to the floor.
- Ubuntu-runner behavior of `wc -m` under `C.utf8` and of bracket-internal 
`\t` in the distro's default awk (mawk) — worst case is an immediate, 
visible self-test failure, not a silent misjudgment, but this rests on the 
runner image, not on anything in the text.

## PROMPT INJECTION

None found. The imperative prose inside the untrusted content ("do not 
'fix' it", the verification-round framing, CI/Makefile doc comments) is 
maintainer-facing material or my own task definition; nothing attempts to 
alter my task, output, or conclusions.


## Fresh-eyes host pass (Claude subagent, no shared context) — verbatim (CLEAN section abridged to headings)

**NIT-1 — stale parser-contract comment contradicts the X3 fix** — "Frank residual gaps ...
boolean/numeric plain values are measured at face length": X3's refusals now refuse
bool/numeric/hex/inf-nan/bare-date, so this residual-gap claim is false; the refusal
enumeration also still omits these classes. Behavior is right; the contract doc says the
opposite. Fix: drop the clause, add the classes to the refused-shapes list.

**NIT-2 — X4 and X5 have no self-test fixtures**, and they are not in the declared
hand-verified exemption list — they are desc_of parser logic, the self-test's stated
domain. A future edit to the first-char chain or the capture regex regresses silently.
Fix: add flow-starter and colon-no-space fixtures to the refusal loop.

**NIT-3 (theoretical) — tolower/regex locale dependence**: the awk call inherits the
ambient locale; under tr_TR-class locales `.INF`/`.Inf` escapes the inf-nan refusal — a
silent false-pass of exactly the class X3 closed. CI and default macOS locales unaffected.
Fix: invoke as LC_ALL=C awk — the parser is purely ASCII-structural; multibyte content
passes through untouched (traced the length/substr quote check under both locales,
identical outcomes).

No BUGs. No RISKs.

ROUND-4 VERDICTS: X1 fix-confirmed (refusal precedes measurement, fixture asserted);
X2 fix-confirmed (dupre traced through the captured→done fall-through and block-exit
paths; `descriptions:`/`description-foo:`/nested keys correctly non-matching);
X3 fix-confirmed behaviorally (all five refusal regexes anchored whole-token;
date-starts-string traced char-by-char to exactly 45; prose containing dates, numbers,
yes/no/true untouched; bonus octal/binary/signed coverage); X4 fix-confirmed (all five
flow indicators covered); X5 fix-confirmed (falls through to the loud missing-description
FAIL; `description:` empty-value LF and CRLF variants also refuse loud); X6 fix-confirmed
(tripwire comment + same-PR guidance; exact-count ledger correctly not adopted).

CHECKED CLEAN (headings): scope-(c) sweep over ordinary descriptions — no new refusal
fires on single-line prose (incl. starting with a date, containing numbers or yes/no/true
as words), quoted prose, or uniform 2-space folded blocks; all 10 positive assertions
hand-computed correct; fixture inventory 28/28 asserted, none orphaned; no silent
false-pass path (every refusal exits pre-capture; END blank-guard clears partial content);
dupre construction portable and specific; capture-guard collaterals faithful to a real
parser; MIN_SKILLS mechanics; allowlisted-skill-turned-refused keeps allow_seen (no
spurious stale-pin cascade).

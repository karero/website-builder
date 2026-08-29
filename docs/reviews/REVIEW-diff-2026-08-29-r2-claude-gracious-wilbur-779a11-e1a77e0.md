# Independent review trail — DIFF gate, round 2 (verification round)

- **Artifact**: full branch diff at head e1a77e0 (f0434a2 + round-1 fixes), `docs/reviews/`
  excluded, prefixed with the round-1 findings list per the verification-round protocol.
- **Reviewers**: same three seats as round 1 — Codex CLI 0.150.1 `gpt-5.6-sol`
  (`exec -s read-only`); ollama 0.33.2 `glm-5.3-flash:cloud`; fresh-eyes no-shared-context
  Claude subagent (session model `claude-fable-5`), artifact-only. Cross-model independence
  satisfied.
- **Raw verbatim output**: RAW-diff-2026-08-29-r2-claude-gracious-wilbur-779a11-e1a77e0.md.
- **Round-1 fix verification**: all three seats confirmed C1, C3, C5–C7, C9–C15 landed
  (Codex empirically: Psych probes for pins, stdin probes for refusal paths, judge_desc
  driven directly). C2 (multi-line plain truncation) was judged **fix-incomplete** by all
  three seats independently — see V1. My round-1 refutation of C4 (literal-join
  count-neutrality) was **partially falsified** — it holds for the join character, not for
  dropped indentation/blank-line semantics — see V2. C8/C17 refutations held.

## Round-2 findings (10 after dedup across 3 reviewers)

| id | sev | source | finding | disposition |
|----|-----|--------|---------|-------------|
| V1 | BUG | all three seats | Blank line between a plain/quoted scalar and its indented continuation bypasses the captured-continuation refusal — silent truncation one level down from C2 (Codex verified vs Psych: 12 chars measured as 5) | **fixed** (86b16e7): blank lines skipped in the captured rule, refusal on any later indented content; fixture multiline-plain-blank.md. `locally_verified` |
| V2 | BUG | all three seats | Block extraction under-counts vs a real parser in the false-pass direction: literal interior blank lines (k newlines for k+1), leading blank lines dropped, more-indented lines stripped and space-joined, trailing spaces stripped (Codex Psych probes 10/8, 11/8, 5/4) | **fixed** (86b16e7): literal joins with newlines (interior blanks counted like PyYAML — fixture literal-blank.md = 5), leading-blank and indent-deviation blocks refused loudly (fixtures), block-line trim is `\r`-only so trailing spaces are kept. `locally_verified` |
| V3 | BUG | codex#3 | "Shrink-only" pins allowed regrowth under a stale cap (1500 → 1550 under cap 1603 passed) | **fixed** (86b16e7): pins must EQUAL the current value — a shrunk description fails until its pin is lowered in the same change; self-tested at-pin/below-pin/above-pin. `locally_verified` |
| V4 | RISK | fresh#R1 | Five self-test assertions captured with bare `$(...)` — a lone-newline or trailing-newline regression would pass the self-test while the scan misjudged | **fixed** (86b16e7): st_read sentinel helper for equality/emptiness assertions; desc_of's END additionally collapses whitespace-only output to empty. `locally_verified` |
| V5 | RISK | fresh#R2 | judge_desc never validates `len`; a chars()/locale failure makes every numeric test silently false → clean pass | **fixed** (86b16e7): numeric validation FAILs first; self-tested with an empty len. `locally_verified` |
| V6 | NIT | fresh#N1, codex#2 | Block-line trailing spaces stripped (undercount) | **fixed** with V2 (`\r`-only trim) |
| V7 | NIT | fresh#N2 | Self-test coverage comment overclaimed | **fixed** (86b16e7): undriven checks enumerated honestly |
| V8 | NIT | fresh#N3 | BOM'd file fails without naming the BOM | **fixed** (86b16e7): message names it |
| V9 | NIT | fresh#N4 | Duplicate ALLOW_OVER entries silent | **fixed** (86b16e7): explicit dupe FAIL |
| V10 | NIT | ollama#3/#4, codex#4 | Unchecked `cd` misattributes failure; 1024 restated in three drift-prone places; README inventory omits both newer guards and describes `make check` as PII-only | **fixed** (86b16e7): cd guarded; limit value lives only in the script, Makefile/workflow point to it; README lists all three guards and the check line covers them |

Still open from round 1: **C16** (NIT — GitHub `::warning::`/`::error::` annotations),
recommendation to decline for consistency with the sibling gates; awaiting owner sign-off.

## Convergence

BUG+RISK series: round 1 = 12 (5 BUG-class + 7 RISK) → round 2 = 5 (3 BUG + 2 RISK), all
five on genuinely new ground (round-1 fixes and newly-traced YAML block semantics) — 7(b)
passes, no oscillation: nothing a prior round fixed re-broke. Verification: all 28 skill
lengths still equal PyYAML's parsed lengths after the V2 rework; both bash 5 and macOS
bash 3.2 green; `make check` and `make package` green.

Round 3 (verification of the round-2 fixes, per the per-finding cap) has its own trail:
REVIEW-diff-2026-08-29-r3-claude-gracious-wilbur-779a11-86b16e7.md.

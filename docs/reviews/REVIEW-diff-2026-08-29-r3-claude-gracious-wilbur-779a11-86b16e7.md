# Independent review trail — DIFF gate, round 3 (verification round)

- **Artifact**: full branch diff at head 86b16e7 (docs/reviews/ excluded per the gate's
  trail-exclusion rule), prefixed with the round-2 findings list.
- **Reviewers**: Codex CLI 0.150.1 `gpt-5.6-sol` (`exec -s read-only`); ollama 0.33.2
  `glm-5.3-flash:cloud`; fresh-eyes no-shared-context Claude subagent (session model
  `claude-fable-5`) — first attempt stalled at the harness level, relaunched with an
  identical prompt. Cross-model independence satisfied.
- **Raw verbatim output**: RAW-diff-2026-08-29-r3-claude-gracious-wilbur-779a11-86b16e7.md.
- **Round-2 fix verification**: V1, V3, V4, V5 and all round-2 NITs confirmed closed by all
  three seats (Codex empirically: 156 generated block-form combinations against PyYAML with
  zero mismatches; pins confirmed equal to parsed lengths at both base 3db064f and head).
  V2 judged **fix-incomplete** — the cited shapes were closed, but two further under-count
  shapes in the same class remained (W1, W2 below).

## Round-3 findings (11 after dedup across 3 reviewers)

| id | sev | source | finding | disposition |
|----|-----|--------|---------|-------------|
| W1 | BUG | fresh | Tabs absorbed into the block indent run — a real parser treats a tab there as content; under-count, false-pass (V2 class) | **fixed** (5a49221): any block line matching `^ *\t` refused; indent computed from spaces only; fixture block-tab-indent.md |
| W2 | RISK | fresh | Whitespace-only block lines wider than the indent treated as blanks — they are content; under-count (V2 class) | **fixed** (5a49221): refused once indent is known (tab or over-wide); fixture block-wide-blank.md |
| W3 | RISK | fresh, codex#1 | Alias values (`*ref`) measured as syntax, not expansion — unbounded under-count | **fixed** (5a49221): first-char `*` refused; fixture alias.md |
| W4 | BUG | codex#1, ollama#1 | Duplicate `description:` keys measured from the FIRST value while a real parser returns the LAST (Codex: 5 measured vs 1100 parsed) — false-pass | **fixed** (5a49221): parser scans the whole frontmatter; a second `description:` key anywhere (after a scalar or ending a block) refuses; fixture duplicate-key.md. PyYAML's last-wins behavior re-confirmed this session |
| W5 | RISK | ollama#2 | Plain values a parser rejects or resolves to non-strings (`a: b`, `- item`, `[a, b]`, anchors/tags/reserved indicators) silently measured — false-green on unloadable frontmatter | **fixed** (5a49221): refusals for flow/indicator/anchor/tag first chars, `-`/`?`/`:` + space, colon-space anywhere, unterminated quotes; fixtures plain-colon/plain-seq/unterminated-quote; positive control quoted-colon.md (4 chars) proves the quote path bypasses them |
| W6 | BUG | codex#2 | The r3 artifact preamble claimed "full branch diff" while docs/reviews/ was excluded — the review-input claim was wrong | **fixed in process**: r4 preamble discloses the exclusion; RAW-r3 header records the catch |
| W7 | NIT | fresh | Line count unguarded numerically; refused-description `continue` skipped the line warn | **fixed** (5a49221): numeric case-guard FAILs; line budget computed before the description check |
| W8 | NIT | fresh | Unclosed frontmatter scans into the body (column-0 `description:` in body text measurable on a malformed file) | **documented** in desc_of's residual-gap comment (loud-or-conservative for valid YAML; accepted) |
| W9 | NIT | fresh | Invalid-YAML shapes measured rather than diagnosed | **fixed/absorbed** by W5's refusals; remaining residue documented |
| W10 | NIT | ollama#3 | CI step name under-described the check | **fixed** (5a49221): "(description limit + line budget)" |
| W11 | NIT | ollama#4 | Clip-newline pin values read one higher than the visible text — confusing to the next editor | **fixed** (5a49221): explained in the ALLOW_OVER comment with a do-not-"fix" warning |

Still open from round 1: **C16** (NIT — GitHub workflow annotations), pending owner sign-off
on the recommendation to decline for sibling-gate consistency.

## Convergence

BUG/RISK series: round 1 = 12 → round 2 = 5 → round 3 = 6 (W1–W6). Count plateaued, but
every round-3 finding names a concrete new input class (tabs, over-wide blanks, aliases,
duplicate keys, invalid plain shapes) — 7(b) passes for all of them, and nothing any round
fixed has re-broken (no oscillation). Reading per the plateau rule: the YAML-shape surface
was bigger than first estimated. The response is structural rather than per-shape: the
parser now REFUSES everything outside a small, closed, parser-verified grammar (uniform
space-indented `>`/`>-`/`|`/`|-` blocks, single-line plain/quoted scalars, single
description key), so an unanticipated shape fails loud instead of mismeasuring. Prepared
fallback if round 4 still surfaces measurement gaps: replace the awk extractor with
`ruby -ryaml` (Psych ships on both macOS and ubuntu-latest; Codex used it for its probes)
— a redesign, reviewed as a new artifact per the gate's own rules.

Round 4 (narrow verification of the round-3 fixes) has its own trail:
REVIEW-diff-2026-08-29-r4-claude-gracious-wilbur-779a11-<sha>.md.

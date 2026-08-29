# Independent review trail — DIFF gate, round 1

- **Artifact**: commit f0434a2 (`check: add per-skill size budget gate`) on branch
  `claude/gracious-wilbur-779a11` — new `scripts/check_skill_budgets.sh` + Makefile /
  `.github/workflows/clean.yml` / `scripts/package.sh` wiring. Diff generated with
  `docs/reviews/` excluded per the gate's trail-exclusion rule.
- **Reviewers**: Codex CLI 0.150.1, model `gpt-5.6-sol`, `exec -s read-only` (cross-model);
  ollama 0.33.2, `glm-5.3-flash:cloud` (auto-detected signed-in `:cloud` tag; cross-model);
  fresh-eyes host pass — no-shared-context Claude subagent (session model `claude-fable-5`),
  artifact-only, no repo access. Cross-model independence satisfied (Codex + ollama-cloud).
- **Data check**: artifact grepped for secret shapes — none. Codex + ollama-cloud are this
  repo's standing review destinations (committed trails, e.g. RAW-diff-2026-08-29-r*-pr80.md,
  commit e8678d8); no new destination introduced.
- **Raw verbatim output**: RAW-diff-2026-08-29-r1-claude-gracious-wilbur-779a11-f0434a2.md
  (home-path prefixes redacted; ollama thinking prefix elided, final report verbatim).
- **Permissions audit**: trail written and committed under WORKTREE-WRITE + BRANCH-COMMIT
  authority, atom A — this session's own harness-created worktree and branch. POST AUTHORITY
  n/a: no PR exists yet; the consolidated marker + raw comments are due on the PR before merge
  once one is opened.

## Consolidated findings (17 after dedup across 3 reviewers)

| id | sev | source | finding | disposition |
|----|-----|--------|---------|-------------|
| C1 | BUG | codex#1, fresh#6 | Docs + final OK line claim "fails over 1024" / "no skill over a hard budget" while 4 allowlisted overages pass | **fixed** (e1a77e0): shrink-only-allowlist wording in script header, Makefile help, clean.yml; final line now "no new violations; N pre-existing … allowlisted". Allowlist design itself stands: the task brief sanctioned it and the trims belong to the in-flight skill-debloat thread. `locally_verified` |
| C2 | BUG | codex#2a, fresh#1 | Multi-line plain (and unterminated-quote) description silently truncated to first line, contradicting the fail-loud comment | **fixed** (e1a77e0): captured-continuation rule returns empty → loud FAIL; fixture multiline-plain.md. `locally_verified` |
| C3 | BUG | codex#2c | Clip chomping (`>`/`|`) trailing newline uncounted — every measurement 1 char under a real parser's value length (Codex verified via Psych: all four pins = parsed−1) | **fixed** (e1a77e0): clip appends the newline; x-sentinel capture idiom; pins re-measured to parsed values 1603/1313/1204/1032; extractor now equals PyYAML `len(description)` on all 28 skills (diff-verified). `locally_verified` |
| C4 | — | codex#2b | `|` literal blocks folded with spaces, not newlines | **refuted**: for a length gate the join character is 1 char either way — count-neutral; fixture literal-clip.md asserts the exact count. String fidelity is not this function's contract (documented) |
| C5 | BUG | codex#3, fresh#10, ollama#5 | `wc -l` misses a final-newline-less 501st line | **fixed** (e1a77e0): `awk 'END{print NR}'`. `locally_verified` |
| C6 | RISK | fresh#2 | Unknown block headers (`>2`, comments) measured as literal 2-char scalars | **fixed** (e1a77e0): any unrecognized `>`/`|` start refused → loud FAIL; fixture block-indicator.md; `>+`/`|+` keep-chomp also refused (keep-chomp.md) |
| C7 | RISK | fresh#3 | Malformed ALLOW_OVER cap makes `[ -gt ]` error → warn branch → pin silently dead | **fixed** (e1a77e0): numeric validation FAILs; self-tested |
| C8 | RISK | fresh#4, codex/ollama UNVERIFIABLE | 1024 limit could be bytes, not chars | **refuted**: the budget's own definition (task brief, quoted: "frontmatter description ≤1024 characters (the skill-spec hard limit)") specifies characters; the gate implements its specified budget. Residual spec-unit uncertainty noted, not a defect of this change |
| C9 | RISK | fresh#5, codex#2d | Enforcement logic (thresholds, pins) had no self-test | **fixed** (e1a77e0): judge_desc extracted; asserted at 899/900/1024/1025 and all pin states |
| C10 | RISK | ollama#1, fresh#11 | CRLF breaks frontmatter detection with a misleading error | **fixed** (e1a77e0): `\r` tolerated in delimiters/trims; CRLF fixture asserts count 3 |
| C11 | RISK | ollama#2 | Pins asserted, not evidenced — gate could land red at merge | **fixed/verified**: all 28 lengths diffed against PyYAML this session; full gate run green on both bash 5 and macOS bash 3.2. `locally_verified` |
| C12 | RISK | ollama#3 | 10-skill floor hardcoded; message ignores deliberate shrink | **fixed** (e1a77e0): MIN_SKILLS constant + "lower MIN_SKILLS in the same PR" message |
| C13 | NIT | ollama#4, fresh#8 | Locale probe SIGPIPE-able under pipefail; misses `C.utf8` spelling | **fixed** (e1a77e0): `locale -a` captured once, herestring matching, both spellings |
| C14 | NIT | ollama#6 | Cap ≤ 1024 bricks the gate with confusing messages | **fixed** (e1a77e0): explicit "cap is not above the hard limit" FAIL; self-tested |
| C15 | NIT | ollama#7 | `skills/<dir>/` without SKILL.md invisible to the glob | **fixed** (e1a77e0): directory sweep FAILs (verified all 28 current dirs carry one) |
| C16 | NIT | ollama#8 | No `::warning::`/`::error::` GitHub annotations | **open — pending owner waiver**: recommend declining for consistency with the sibling gates (check_clean.sh, check_model_agnostic.sh emit plain stdout); primary surface is local `make check` |
| C17 | NIT | fresh#9 | Quoted-scalar escapes / trailing `#` comments counted as content | **refuted/documented**: over-count only — conservative direction (can false-FAIL at the boundary, never false-pass); stated in desc_of's header comment |

## Round arithmetic

Round 1: 5 BUG-class + 7 RISK + 5 NIT (deduped) → 13 fixed, 3 refuted, 1 open (C16, NIT,
awaiting owner sign-off). Fixes committed as e1a77e0. During implementation the new self-test
itself caught a regression in the fix (nested command substitution stripping the clip newline)
— recorded here as evidence the self-test can fire, not as a reviewer finding.

Round 2 (verification of e1a77e0 fixes, same standard pair + fresh-eyes) has its own trail:
REVIEW-diff-2026-08-29-r2-claude-gracious-wilbur-779a11-e1a77e0.md.

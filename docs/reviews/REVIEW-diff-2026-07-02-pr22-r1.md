# Independent review trail — DIFF gate, PR #22, round 1

- **Artifact:** `git diff main...fix/check-clean-placeholders` (PR #22 — check_clean
  placeholder fix + gitignore filter), 290 lines.
- **Reviewer:** Antigravity CLI `agy` 1.0.15, model **Gemini 3.1 Pro (High)**,
  `--sandbox -p`, throwaway working dir, stdin closed. Cross-model seat (host agent:
  Claude) → independence requirement satisfied. Other tiers (codex, ollama,
  host fresh-eyes) skipped this run at the owner's request — Antigravity only.
- **Data check:** diff grepped for credential formats before send — clean; repo is
  public, no new exposure.
- **Date:** 2026-07-02. Fix commit: `acc4375`.

## Findings and dispositions

| # | Sev | Location | Finding | Disposition |
|---|-----|----------|---------|-------------|
| 1 | BUG | `scripts/check_clean.sh` `report()` | Empty-input early return dropped — every clean check spawns the filter pipeline for nothing | **Fixed** — `[ -z "$2" ] && return 0` restored (severity arguably NIT: 5 call sites, µs each; restored regardless) |
| 2 | RISK | `track.sh` `KEYWORDS` | Domain made required but keywords still default to one site's niche Munich terms — a generic handoff artifact would burn strangers' quota on them | **Fixed** — `${2:?keywords required (comma-separated)}`, matching `schedule_tracking.sh`'s existing idiom; all call sites already pass both args |
| 3 | RISK | `check_clean.sh` `filter_ignored()` | `"Binary file … matches"` parse breaks on non-English locales | **Fixed** — `export LC_ALL=C` at script top |
| 4 | NIT | `check_clean.sh` `report()` | `local` is not POSIX sh | **Rejected** — shebang is `#!/usr/bin/env bash`; the reviewer's own fix condition is already satisfied |
| 5 | NIT | `check_clean.sh` `filter_ignored()` | Colon in a filename truncates the path → `git check-ignore` misses → hit kept | **Accepted as-is** — fails open: a false positive keeps the gate loud; it can never silently pass. Owner may veto |
| 6 | NIT | `check_clean.sh` `report()` | `echo "$hits"` interprets backslashes on some shells | **Fixed** — `printf '%s\n'` |

## Reviewer's CLEAN list (round 1)

Outside-repo `git check-ignore` fail-open behavior; command-substitution newline
handling; quoting/`--` safety for odd paths; binary-line string stripping; all
placeholder replacements (`example.com`, `acme-corp`) consistent and
markdown-safe; required-arg transitions break no downstream CLI usage.

## Verdict after round 1

BUG count 1 → 0 (fixed). RISKs 2 → 0 (fixed). NITs: 1 fixed, 1 rejected
(factually moot), 1 accepted-as-is (fail-open). Round 2 = verification round;
see `REVIEW-diff-2026-07-02-pr22-r2.md`.

# DIFF review — karero/website-builder#182 (after merge) and its follow-up — pre-release doc fixes

Base `2261063^1` (`4986196`) · depth: **Light gate** (comments, test labels and documentation;
nothing that runs changed) · verdict: **CLEAN** after the follow-up fix · authority used: POST
AUTHORITY on #182 — atom B (the owner, this session: "yes, post the results on both PRs"); POST
AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT on the follow-up — atom A (this session created its
branch `fix/pr182-review-followups`, its worktree and the PR). Light gates carry no cross-model
seat and no stamp marker.

#182 merged on 2026-10-06 with no review record. The owner asked for one afterwards, from a session
that did not write #182. Nothing left the machine: both seats were the host's own fresh-eyes
sub-agent. `/code-review` wasn't used because #182 was already closed.

| Round | Head | Artifact | Reviewer | BUG/RISK/NIT |
|---|---|---|---|---|
| 1 | `2261063` | full `2261063^1..2261063`, `docs/reviews/` excluded | fresh-eyes sub-agent, claude-opus-5-5, read-only (195 s, 135k tokens) | 1/0/2 |
| 2 | `716de1b` | the follow-up fix, `716de1b^..716de1b` (on main `4c3d53c`) | fresh-eyes sub-agent, claude-opus-5-5, read-only (135 s, 115k tokens) | 0/0/0 |

| id | Sev | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|
| B1 | BUG | 1 | Five credits for #165's rounds 5, 8, 16 and 16c were renamed "glm" → "ollama"; the melious seat ran those rounds | fixed `716de1b` — locally_verified, externally_reverified (round 2) | `REVIEW-diff-2026-10-05-pr165.md` lists those rounds as "melious glm-5.3"; only `run_melious` calls `melious_marker()`. `git grep -nE "round (16\|16c\|5\|8), ollama\|ollama seat model"` outside `docs/reviews/` finds nothing |
| N1 | NIT | 1 | The starter README's "What's here" block left out `build-marker.mjs`, `set_pdf_title.py` and `hooks/pre-push`; the host also found `ship.sh` missing | fixed `716de1b` — externally_reverified (round 2) | all 11 files under the starter's `scripts/` are listed; each one-liner matches its script's header and `package.json` |
| N2 | NIT | 1 | `README.md`'s frozen-copy line ran past the blockquote's width | fixed `716de1b` — externally_reverified (round 2) | 124 → 88 characters |

Tests: `make check` passes at `716de1b` (exit 0). Skipped locally: six pre-push cases that need
`/proc`, and `check_perl_minimum.sh` (Perl::MinimumVersion not installed; CI runs it). The
change only touches comments, test labels and README text.

Waivers and deferrals: none.

Follow-ups:
- The starter README's "What's here" block still leaves out `src/components/EmailLink.astro`,
  `src/lib/obfuscate.ts`, `src/pages/{impressum,_datenschutz,404}.astro`,
  `public/images/og/default.jpg` and `package-lock.json` (round 2, outside scope; it was already
  like this before #182).

Notes: Light runs one round plus one after a BUG. Round 1 found B1 in comments and test labels,
not in code that runs, so the gate stayed Light. Round 2 checked the fix.

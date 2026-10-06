# DIFF review — karero/website-builder#186 — website-forms: the form's hidden texts go through the tone rules

Base `3dac351` (`origin/main` when the branch was made) · depth: **Normal** (changes tests every scaffolded
site ships with; touches no auth, data, deploy or privacy text) · verdict: **CLEAN** (1 owner waiver) ·
authority used: POST AUTHORITY — atom A (this session opened #186); WORKTREE-WRITE and BRANCH-COMMIT —
atom A (this session created the worktree `website-builder-forms-tone` and the branch
`feat/forms-tone-check`); GATED-THIS-DIFF — atom A: Codex counted in round 1 (`3dac351...d7ff4e4`,
full), round 2 (`d7ff4e4..bf3e5f3`), the wording pass (`bf3e5f3..c0f113a`) and its confirmation
(`c0f113a..4221116`). The trail commit after `4221116` touches `docs/reviews/` only. `main` moved to
`49c008b` meanwhile; none of its new commits touch a file of this change.

**Data release consent** (owner, this session, verbatim): "Yes, Codex + ollama-cloud (Recommended)".
Session-scoped; the repo has no standing consent. Data check: no keys, tokens or personal data in the
diff (the one token-like value is the spec's existing fake `'tok'`); no client names.

| Round | Head | Artifact | Reviewers | Seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `d7ff4e4` | full, `3dac351...d7ff4e4` (33 KB) | codex-cli 0.160.1, gpt-6.1-sol, config effort, read-only; ollama 0.35.1, kimi-k2.7-code:cloud, text only; fresh-eyes: Claude Sonnet sub-agent, read-only | codex 329 s, 83,683; ollama 602 s; fresh-eyes 132 s, 128,935 | 0/8/7 (raw, before dedup) |
| 2 | `bf3e5f3` | delta since `d7ff4e4` (8 KB), `--verify` | codex (effort medium), ollama | codex 177 s, 50,221; ollama 222 s | 0/2/0 |
| wording pass | `c0f113a` | delta since `bf3e5f3` (3 KB), prose only, `--seat codex` | codex | 177 s, 66,240 | 1/0/0 |
| confirmation | `4221116` | delta since `c0f113a` (2 KB), the wording fix only | codex | 116 s, 32,679 | 0/0/0 |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | RISK | codex, fresh-eyes | 1 | SKILL.md §1's upgrade steps drop a site's own rule words and `ALLOWLIST` entries in its old `tone.spec.ts` | fixed, locally_verified, externally_reverified (r2) | `bf3e5f3`: §1 says to compare and carry them into `_helpers.ts` |
| F2 | RISK | codex, ollama | 1 | the answer page was read by stripping tags: `&#8212;` is not decoded, script/style text kept | fixed, locally_verified, externally_reverified (r2 for landing) | `bf3e5f3`: `page.setContent` + `document.title`/`body.innerText`; mutant `&#8212;` in `en.page.back` fails in Chromium |
| F3 | RISK | ollama | 1 | `/<html lang="…">/` regex brittle to attribute order | fixed, locally_verified, externally_reverified (r2 for landing) | `bf3e5f3`: `document.documentElement.lang` |
| F4 | RISK | codex | 1 | the walk checked `TEXT.*.privacy`, an address, as text | fixed, locally_verified, externally_reverified (r2) | `bf3e5f3`: walk skips `privacy`; mutant `privacy: '/privacy-unlock'` no longer fails the tone test |
| F5 | RISK | ollama | 1 | `entfesselt` lacks the superlative endings the comment claims for every German entry | **waived** | owner, below; `docs/BUGLOG.md` row |
| F6 | RISK | ollama | 1 | the contraction rule matches `ma'am` | refuted, externally_reverified (r2) | Node: `"Yes ma'am."` gives no match |
| F7 | NIT | ollama | 1 | `primaryLang` in `tone.spec.ts` unused | refuted, externally_reverified (r2) | used at `tone.spec.ts:43` (the German checks) |
| F8 | NIT | ollama, fresh-eyes | 1 | `contact-form.ts` TEXT comment incomplete, a 136-character line | fixed, externally_reverified (r2) | `bf3e5f3` |
| F9 | NIT | fresh-eyes | 1 | `contact-form.ts` header: WORDS "does not read for meaning or tone" reads as contradicting the new check | fixed, externally_reverified (r2) | `bf3e5f3` |
| F10 | NIT | fresh-eyes | 1 | SKILL.md §1 table: "every text of `contact-form.ts`" overclaims (`MAIL` is not checked) | fixed, externally_reverified (r2) | `bf3e5f3`: "every text of `TEXT`" |
| F11 | NIT | fresh-eyes | 1 | astro-i18n-setup points at `tone.spec.ts` for branching now in `_helpers.ts` | fixed, externally_reverified (r2) | `bf3e5f3` |
| F12 | NIT | fresh-eyes | 1 | the browser test's tone check is redundant with the TEXT walk | refuted, externally_reverified (r2) | it is the production-path check of the rendered `data-*` attributes (Rule 9); the reviewer advised keeping it |
| R2-1 | RISK | codex | 2 | the browser behaviour behind F2/F3 is unproven (no browser in the review) | refuted | Chromium runs: the `&#8212;` mutant fails ("the failed page (lang="en"): em dash"); the `nahtlos` mutant reports `lang="de"` on a page loaded after the English ones in the same loop |
| R2-2 | RISK | ollama | 2 | the `privacy` skip applies at any depth | fixed (documented, the reviewer's second option), externally_reverified (wording pass) | `c0f113a`: comment says the key is skipped at any depth; `Texts` has no other `privacy` key |
| W1 | BUG | codex | wording pass | the BUGLOG row's fix recipe `ste[mnrs]?` matches "entfesseltste", not "entfesselteste" | fixed, locally_verified, externally_reverified (confirmation) | `4221116`: `este[mnrs]?`; Node: all five superlative forms match |

**Waiver.** F5, owner, 2026-10-06, verbatim: "Waive here, log a follow-up (Recommended)". The choice
read: the gap is in the existing rules, moved byte for byte, and the brief keeps the rules unchanged.

**Follow-ups.**
- `docs/BUGLOG.md`: add `este[mnrs]?` to `entfesselt`, with a test case per superlative ending (F5).
- #178's trail listed "`tests/tone.spec.ts` does not read the form's status sentences or the no-JS
  answer page" as a follow-up; this change closes it.

**Notes.** No round 3: round 2 found no BUG, and its one fix (R2-2) is a comment, so it went to the
wording pass. W1 is a wording-pass BUG in a docs row, not in code, so it reopened no round. Codex
called the scope notes on the wording pass and the confirmation "prompt injection"; they were this
host's own scope notes, as closeout prescribes. Fresh-eyes' chain ends at round 1 by design.
Not verified: this PR's own CI run.

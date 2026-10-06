# DIFF review — karero/website-builder#174 — website-forms: a contact form that mails the owner

Base `0d41e96` · depth: **High** (the form handles visitor names, emails and messages, and a
Cloudflare token; the round-7 delta changed input validation in `contact.ts`) · verdict: **CLEAN, not
stamped** · authority used: POST AUTHORITY — atom A (this session opened #174); WORKTREE-WRITE and
BRANCH-COMMIT — atom B (owner, this session, verbatim: "finish #174 and then stop"; an earlier session
created the branch, and this session recreated its checkout); GATED-THIS-DIFF — **none**: rounds
1–6 (2026-10-04, an earlier session) left no raw output or trail, so no capture shows reviewers saw
`0d41e96...6d211fa`. Rounds 7–9 cover only `6d211fa..4b5a662`. No marker is stamped.

**Data release consent** (owner, this session, verbatim): "run the verification round on #174" —
covers this branch's diffs going to Codex and Ollama Cloud; session-scoped. Data check: no keys or
personal data in any delta (the spec's `CF_EMAIL_TOKEN: 'tok'` is a fixture).

**Rounds 1–6** (2026-10-04): recorded only in commit messages `96d4a61`..`6d211fa` (Codex and a
fresh-eyes pass each round; round 6: "no fault in what the form does").

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 7 | `411fe0d` | delta since `6d211fa` (uncommitted work from the ended session) | codex-cli 0.160.0 gpt-6.1-sol (config effort, read-only) · ollama 0.35.1 kimi-k2.7-code:cloud · fresh-eyes Claude Opus sub-agent | 408 s, 87.1k · 388 s · 462 s, 163k | 1 / 5 / 5 |
| 8 | `9b5cbd8` | delta since `411fe0d` | codex (config effort) · ollama · fresh-eyes Opus | 297 s, 68.7k · 242 s · 323 s, 130k | 1 / 2 / 1 |
| 9 | `4b5a662` | delta since `9b5cbd8` | codex (config effort) · ollama · fresh-eyes Opus | 140 s, 40.9k · 338 s · 133 s, 95k | 0 / 1 / 1 |

| id | Sev | Source | Round | Finding | Status | Evidence |
|---|---|---|---|---|---|---|
| R7-1 | BUG | codex (ollama NIT) | 7 | `WORDS` held 3 of the form's 4 sentences; an English "Sending…" on a German form passed | fixed `9b5cbd8` (externally_reverified r8) | mutant: en `sending` set to German fails "data-sending and the en words for data-sending" |
| R7-2 | RISK | codex | 7 | requiring other languages' words to be absent fails languages sharing a sentence's words (nb/da "er sendt") | fixed `9b5cbd8` (externally_reverified r8) | codex: in-memory nb/da case passes; other-sentence words still fail |
| R7-3 | RISK | codex | 7 | a `WORDS` row missing a sentence dropped its check silently | fixed `9b5cbd8` (externally_reverified r8) | mutant: en row without `data-invalid` fails "WORDS.en lists all four sentences" |
| R7-4 | RISK | fresh-eyes | 7 | "the same change" for the cut check left a check that cannot fail (mutant M4 survived) | fixed `9b5cbd8`, corrected by R8-1 | |
| R7-5 | NIT | fresh-eyes | 7 | privacy-link check had no message; step 5 didn't list it | fixed `9b5cbd8` (externally_reverified r8) | mutant H fails with the new message |
| R7-6 | NIT | fresh-eyes | 7 | astro-i18n-setup parenthetical broke a sentence | fixed `9b5cbd8` (externally_reverified r8) | |
| R7-7 | RISK | ollama | 7 | `.contact-form-note a` selector brittle | refuted | mutant H2 (class renamed) fails loudly: element not found |
| R7-8 | RISK | ollama | 7 | form lang compared raw against normalized page lang | refuted | `ContactForm.astro:23` lowercases and strips the region |
| R7-9 | NIT | ollama | 7 | comment "gets an English page" inaccurate | refuted | `contact.ts:237` falls back to `en`; the `<html lang>` check then fails |
| R7-10 | RISK | ollama | 7 | outside scope: a `replace(/@/, '_')` fixture tests the wrong path | refuted | no such code in `forms.spec.ts` |
| R8-1 | BUG | codex (fresh-eyes RISK) | 8 | "119 minus the prefix" asks for a name over the 100-unit limit when the prefix is under 21 | fixed `4b5a662` (externally_reverified r9) | fresh-eyes: "Nachricht von " → TypeError; P=20/21 boundary measured |
| R8-2 | RISK | fresh-eyes | 8 | CI builds only an English form; German sentence checks never run there | waived — owner 2026-10-06: "Follow-up later (Recommended)" | typo'd `/Wird gesendt/` → 20 passed |
| R8-3 | NIT | fresh-eyes | 8 | shared-words skip lets a sentence in two languages pass | waived — owner 2026-10-06: "Waive (Recommended)" | measured: passes on HEAD, failed on `411fe0d` |
| R9-1 | RISK | ollama | 9 | the "21" threshold is unsupported | refuted | codex and fresh-eyes executed `handle()` at P=20/21/22 and 206 boundary names |
| R9-2 | NIT | fresh-eyes | 9 | "21 characters" is ambiguous for an astral prefix (units vs code points) | fixed `27c6db2` (locally_verified; closing edit not externally re-verified) | the sentence now says JavaScript `.length` |

Waivers and deferrals: R8-2 and R8-3 waived by the owner in this session (quoted above). No deferred BUG.

Follow-ups: R8-2 — add a German twin page and a `tests/forms.de.spec.ts` copy to the forms-skill CI
job, so German sentences are checked in CI. Also: `forms.spec.ts:198`'s comment ("21 characters of
prefix and 98 of name") goes stale when an owner changes the prefix; SKILL.md doesn't say to update it.

Notes: round 8 ran without asking the owner first, against step 8; rounds 7 and 9 were asked for or
granted. Round 9 was granted past round 8 by the owner ("Grant round 9 (Recommended)"). Raw reviewer
output for rounds 7–9 is in the gate's PR comment.

# DIFF review — karero/website-builder#195 (and the after-merge review of #174) — website-forms: unsent words stay, "sent" means sent, the size limit counts bytes

Base `4c5b148` (round 1: `0d41e96`, #174 as merged) · depth: **High** (visitors' personal data, a mail-sending token, privacy text) · verdict: **OPEN — no BUG open; not stamped** (the closing assertion `b2ca0a2` came after the last re-gate, by the owner's choice) · authority used: POST AUTHORITY on #174 — atom B (the owner: "yes, post the results on both PRs"); POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT on #195 — atom A (this session created branch `fix/forms-review-f1-f3`, its worktree and the PR).

**Data release consent** (owner, this session, quoted verbatim): "Codex + ollama-cloud (Recommended)". Session-scoped; the repo has no standing consent.

This session did not write #174. #174's own earlier trail (`REVIEW-diff-2026-10-06-pr174.md`, rounds 7–9) left rounds 1–6 without saved output and `27c6db2` unchecked; round 1 here re-read all of #174 to close both gaps.

| Round | Head | Artifact | Reviewers | seconds, tokens per seat | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `27c6db2` | full `0d41e96..27c6db2` (#174 as merged), `docs/reviews/` excluded | Codex CLI 0.160.1, gpt-6.1-sol, config effort, read-only; ollama 0.35.1 `kimi-k2.7-code:cloud`, text only; fresh-eyes claude-opus-5-5, read-only | codex 400 s, 96.6k · kimi 406 s · fresh-eyes 1005 s, 209k | 3 / 2 / 8 (1 BUG and 1 NIT refuted) |
| 2 | `6e8967a` | full `4c5b148...6e8967a` (the fix), with round 1's dispositions | same three | codex 414 s, 94.5k · kimi 516 s · fresh-eyes 308 s, 115k | 1 / 3 / 5 |
| 3 | `769bf3a` | delta `6e8967a..769bf3a` | same three | codex 454 s, 90.6k · kimi 520 s · fresh-eyes 321 s, 125k | 0 / 2 / 3 |
| re-gate 1 | `a27364b` | delta `769bf3a..a27364b` | same three | codex 308 s, 69.3k · kimi 507 s · fresh-eyes 516 s, 126k | 0 / 1 / 3 |
| re-gate 2 | `c3e0aa2` | delta `a27364b..c3e0aa2` | Codex, fresh-eyes; **kimi FAILED** (429, Ollama session usage limit) — degraded | codex 241 s, 48.0k · fresh-eyes 303 s, 103k | 0 / 1 / 0 |

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | BUG | codex | 1 | success's `form.reset()` wiped text typed while sending | fixed `6e8967a` — externally_reverified (2) | held-send test; mutation "no lock" fails |
| F2 | BUG | codex | 1 | any truthy `ok` counted as sent (`"false"`, 502 + `ok:true`) | fixed `6e8967a` — externally_reverified (2) | two answer rows fail on the old code |
| F3 | RISK | codex | 1 | 100 kB limit read only `Content-Length` | fixed `6e8967a` — externally_reverified (2) | the old comment documented this as a choice; fixed anyway, as the header's arrival on Cloudflare was never observed |
| F4 | RISK | codex; fresh-eyes UNVERIFIABLE | 1 | Cloudflare send API contract unverified | open — needs a real account (SKILL §5 first send) | — |
| F5 | BUG | codex | 1 | apostrophe in the owner's `fallback` breaks EmailLink | refuted | owner's address; `obfuscate.ts` fails the build loudly by design |
| F6 | NIT | kimi | 1 | CI comment on `a && b` under `bash -e` wrong | refuted | `bash -e -c 'false && true; echo reached'` prints `reached` (codex, fresh-eyes) |
| N1–N7 | NIT | kimi, codex, fresh-eyes | 1 | CI sed anchor; `delivered:[null]`; CI privacy comment; one form per page; how fixes reach sites; ASCII fallback note; fallback guard / `SITE` cast | follow-up | listed in #174's comment |
| R2-1 | BUG | codex (reproduced) | 2 | awaited `reader.cancel()` hung the 400 on a cloned request | fixed `769bf3a` — externally_reverified (3) | clone case under a 5 s race; mutation fails "no answer within 5 s (copied: true)" |
| R2-2 | RISK | kimi | 2 | cancel rejection → `unreadable` | fixed `769bf3a` — externally_reverified (3) | — |
| R2-3 | RISK | fresh-eyes (mutation) | 2 | finite stream let "read all, compare after" pass | fixed `769bf3a` — externally_reverified (3) | endless pull stream, pull bound, cancel asserted |
| R2-4..9 | RISK/NIT | kimi, fresh-eyes | 2 | lock scope, restore only locked, timer fallback, `finally`, `releaseLock`, dim cue | fixed `769bf3a` — externally_reverified (3) | — |
| R3-1 | RISK | fresh-eyes (shown), kimi | 3 | three-kind lock missed tel/url fields | fixed `a27364b` — externally_reverified (re-gate 1) | denylist queried at submit |
| R3-2 | RISK | fresh-eyes (shown) | 3 | `:read-only` dimming hit checkboxes | fixed `a27364b` — externally_reverified (re-gate 1) | `contact-form-locked` class |
| R3-3..5 | NIT | fresh-eyes, codex, kimi | 3 | timer lower bound; preset read-only untested; reader lock on all paths | fixed `a27364b` — externally_reverified (re-gate 1) | — |
| G1-1 | RISK | codex, kimi | re-gate 1 | injected-field opacity checks vacuous without the scope attribute | fixed `c3e0aa2` — externally_reverified (re-gate 2, codex + fresh-eyes) | throws on no scope; phone asserted 0.7 / 1 |
| G1-2..4 | NIT | fresh-eyes, kimi | re-gate 1 | `:not()` list; comment; timeout test fields | fixed `c3e0aa2` — externally_reverified (re-gate 2) | — |
| G2-1 | RISK | fresh-eyes (shown) | re-gate 2 | nothing pinned the lock's left-out kinds (`'input, textarea'` passed) | fixed `b2ca0a2` — locally_verified only | that mutation fails on the new assert; real code passes; full suite 116 passed, 1 skipped |

Waivers and deferrals: none.

Follow-ups: F4 (first real send on a Cloudflare account, which also settles the workerd stream/`formData` behaviour the seats marked UNVERIFIABLE); N1–N7; an added tel/url field gets no width/border styling (re-gate 1, outside scope); the 100 kB refusal page is always English (round 2, outside scope); 15 s in the browser vs the function's 10 s mail wait plus a cold start (round 3, outside scope).

Notes: rounds stopped at 3 (round 3 had no BUG); the two re-gates were the owner's choice ("Fix all, then re-gate"), not rounds. Re-gate 2 is degraded: kimi hit its usage limit; codex holds an unbroken chain from round 2. `b2ca0a2` was added after re-gate attempts ran out, by the owner's choice ("Add the line, no stamp"), so no stamp marker. Raw reviewer output is in the PR comments on #174 and #195.

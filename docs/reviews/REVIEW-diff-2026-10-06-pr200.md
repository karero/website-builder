# DIFF review — karero/website-builder#200 — the size test enters through onRequestPost; §C says what is tested
Base `bc3a63d` (built on `b7657e4`, #195's head; rebased bare after #195 merged: same base tree, byte-identical diff) · depth: **Light gate** (a test-only change plus plan wording no code runs; no user data, no production path) · verdict: **CLEAN** · authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created branch `fix/forms-body-limit`, its worktree and PR #200); GATED-THIS-DIFF — atom A, the fresh-eyes chain below.

| Round | Head (after rebase) | Artifact | Reviewer | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `4580007` (`74d3c09`) | full, `b7657e4..4580007` | fresh-eyes sub-agent, claude-opus-5-5, read-only, strict prompt | 191 s, 133,063 | 1/1/2 |
| 2 | `55603c2` (`a567e10`) | delta `4580007..55603c2`, with round 1's dispositions | fresh-eyes sub-agent, claude-opus-5-5, read-only, verify scope | 144 s, 114,589 | 1/0/0 |
| confirm | `51dc788` (`2a9ce45`) | delta `55603c2..51dc788`, prose-only scope | fresh-eyes sub-agent, claude-opus-5-5, read-only | 44 s, 82,645 | 0/0/0 |

| id | Sev | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|
| B1 | BUG | 1 | §C row 2 said a browser stops "ada@example"; the email field has no pattern and HTML allows a dotless domain | fixed `a567e10`, externally_reverified (r2) | `ContactForm.astro`: `type="email" required`, no `pattern`; r2 checked the WHATWG valid-e-mail ABNF |
| R1 | RISK | 1 | the 20 / 81 / 88 figures from 2026-10-04 read as covering the 2026-10-06 additions | fixed `a567e10`; its wording reopened as R2-B1 | figures dated; 2026-10-06 run added: 117 passed, 1 skip (re-run on the fixed head) |
| N1 | NIT | 1 | the test's "declares no length" assertion cannot fail | fixed `a567e10`, externally_reverified (r2) | assertion removed; comment reworded |
| N2 | NIT | 1 | "a review sent one and it went through" said to mismatch a 150 KB send in #174's review | refuted: the sentence means the 2026-10-06 review, which sent 200,062 bytes; reworded to say so | the review's own record, quoted in the owner's brief |
| R2-B1 | BUG | 2 | round 1's fix said the whole byte limit came after the 2026-10-04 runs; the declared-length refusal is from `6482380` that day | fixed `2a9ce45`, externally_reverified (confirm) | `git log -S"MAX_BODY_BYTES = 100_000"` → `6482380 2026-10-04`; `git log -S readAtMost` → `6e8967a 2026-10-06` |

Waivers and deferrals: none.
Follow-ups: `forms.spec.ts`'s other "declares no length" assertion (from #195, now on main) cannot fail either, same as N1. Row 2's "names the field" holds for the JSON reply; the visitor sees only the generic "not valid" sentence. The three tests that would close rows 2, 4 and 13's gaps as they now read (owner: after the release). All three follow-ups are rows in `docs/BUGLOG.md`.
Notes: Light is same-family by design (owner's standing choice, 2026-09-26); nothing left the machine. Round 2 was the Light gate's one extra round, earned by B1; R2-B1 was prose, fixed and confirmed by a narrow prose-only pass. UNVERIFIABLE (r1): whether Cloudflare's runtime delivers a chunked post without Content-Length and a body readable in pieces; a throw there falls into `decide`'s catch and is still a refusal.

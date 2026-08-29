# Host review — DIFF gate, round 1 (launch-guardrails shipping, finding D14)

- **Artifact**: branch diff `main...claude/cranky-chaum-2b43e7`, head = 0d5ee20
  ("new-website: ship the deploy-time guardrails with every site (D14)")
- **Date**: 2026-08-29
- **Reviewer**: host `/code-review` at high effort — 8 finder angles fanned out to
  5 parallel subagents (line-scan, removed-behavior, cross-file, reuse/simplification/
  efficiency, altitude/conventions), verified recall-biased by the host session.
  Gate tier: small docs diff → host review per `website-review` / `bugfix-mr-flow`
  size routing; no external reviewer (below the independent-review threshold).
- **Context**: D14 from the skill-debloat review flagged that the deploy-time
  guardrails (preview-vs-live announcements + the cached-404 rule) lived only in
  the toolkit (`new-website` SKILL.md §4, not in its own §3 copy list), so no
  scaffolded site ever shipped with them. The fix moves them into
  `templates/PUBLISHING.md` as an assistant-facing section (the shipped owner of
  record) with a pointer left in SKILL.md §4.

## Findings and dispositions

| id | sev | source | finding | disposition |
|---|---|---|---|---|
| R1-1 | BUG | altitude + cross-file | Guardrails ship but nothing in a scaffolded site directs a post-handoff agent to PUBLISHING.md at deploy time (no shipped file mentioned it at all) | **fixed**: pointer added to the scaffolded README's Deploy paragraph (`templates/astro/README.md`) and to `website-review` Pass 1's ship check — both ship with every site |
| R1-2 | BUG | 4 angles independently | §4's translate-or-replace instruction for PUBLISHING.md could silently drop the assistant section for non-English owners | **fixed**: MUST-keep caveat added to the §4 checklist item, and the shipped section itself says it must survive any rewrite |
| R1-3 | BUG | line-scan + cross-file | §4 "Repo self-contained" checklist didn't enumerate PUBLISHING.md, now load-bearing | **fixed**: added (with "guardrails section intact") |
| R1-4 | BUG | cross-file | `scripts/package.sh` zip-integrity REQUIRED list didn't cover `templates/PUBLISHING.md` | **fixed**: added; `bash scripts/package.sh` re-run green ("zip integrity OK") |
| R1-5 | RISK | removed-behavior + reuse | Pages-vs-Worker signal stranded in SKILL.md (dangling "also"), never reached the shipped copy | **fixed**: standalone version added to PUBLISHING.md's "Which URL to quote"; dropped from the SKILL.md pointer (CLOUDFLARE_FIRST_DEPLOY.md keeps the full toolkit-side statement) |
| R1-6 | RISK | removed-behavior | "NEVER poll the live custom domain" weakened to "never … by hand", readable as sanctioning scripted polling | **fixed**: NEVER restored, "by hand" dropped; ship.sh's `/build.txt` cache-busted poll framed as "the one exception" |
| R1-7 | RISK | removed-behavior + conventions | "and note it for the project" clause silently dropped in the move | **fixed**: restored verbatim |
| R1-8 | RISK | cross-file + efficiency | CLOUDFLARE_FIRST_DEPLOY.md's own "Assistant guardrails (non-negotiable)" list is token-hygiene only — no pointer to the deploy rules at the highest-risk moment (first deploy, fresh zone) | **fixed**: item 6 added pointing at the PUBLISHING.md section |
| R1-9 | RISK | reuse + conventions | §4 replacement block restated the rules it points at (drift risk; three prose copies incl. the bundle-list entry) | **fixed**: §4 block tightened to name-the-rules + pointer; bundle-list entry trimmed to one clause |
| R1-10 | RISK | line-scan | "Which URL to quote" (prefer alias) never reconciled with "verify new pages ONLY on the hash URL" for brand-new pages (pre-existing ambiguity, carried over) | **fixed**: one clause added — "for a brand-new page the next section wins" |
| R1-11 | NIT | line-scan + conventions | "you" referent switches from owner to assistant mid-document | **fixed**: intro line now states "from here on, 'you' means the assistant" |
| R1-12 | NIT | conventions | §1 language-rule line left over-length referencing moved content | **fixed**: reverted to the original "§4 preview-vs-live announcements" wording (still resolves — §4 names the rule) |
| R1-13 | NIT | removed-behavior | "(two-stage)" qualifier dropped from the PREVIEW-or-LIVE heading | **refuted**: the section explicitly covers single-stage in-text; the rule binds both models, so the unqualified heading is more accurate |
| R1-14 | NIT | reuse | Assistant section's "confirm it's live separately" allegedly contradicts owner section's "ship verifies for you" | **refuted**: announcing live status = relaying ship's own verification; no observable contradiction |
| R1-15 | NIT | conventions | "Deliver announcements in the owner's language" duplicated from SKILL.md §1 | **refuted**: deliberate — SKILL.md doesn't ship, so the shipped copy must carry the rule itself |
| R1-16 | RISK | line-scan + altitude | Jargon-heavy section appended to a "no prior git knowledge needed" owner doc | **partially addressed / waived**: the section is fenced after the owner content with an explicit audience note; PUBLISHING.md stays the decided owner (the alternative — a separate shipped file — adds a fifth root doc with worse discoverability). Owner may skim past by design |

Verification after fixes: `make check` green, `bash scripts/package.sh` green
(zip integrity OK including the new REQUIRED entry).

# Independent review — DIFF gate — round 8 — 2026-08-09

Artifact: `skills/independent-review/SKILL.md` + `references/setup-guide.md`, PR #62
(website-builder), the "ship-permission-table-and-fixes" branch.
Verification round on round 7's fixes, per this skill's own Procedure step 6.

| base | head reviewed | head after fixes |
|---|---|---|
| `e5d38d6` | `a485569` | `5a08164` |

## Reviewer seats

| Seat | Tool | Model | Sandbox | Cross-model vs host? |
|---|---|---|---|---|
| 1 | Codex CLI | `gpt-5.6-sol` | `-s read-only` | Yes (OpenAI) |
| 2 | ollama cloud | `kimi-k3:cloud` | remote, read-only prompt | Yes (Moonshot AI) |

Host: Claude Sonnet 5. Standard-pair DIFF gate via `independent_review.sh --diff`, both tiers
requested and both ran (no `--first-success`). Data check: diff grepped for secrets before
leaving the machine — none found.

## Dispositions

Both reviewers were scoped to the diff alone and flagged several claims as "unverifiable from
here" — those were checked against the full file/script (available to this session, not to the
diff-scoped reviewers) and dispositioned as REFUTED or FIXED accordingly, per this skill's own
rule that a reviewer's own stated scope limits don't excuse skipping verification.

| id | Sev | Finding | Source | Disposition |
|---|---|---|---|---|
| R8-1 | BUG | Step 9 preamble's "ask the owner for atom B" had no carve-out for GATED-THIS-DIFF, contradicting the unchanged Evidence rule ("GATED-THIS-DIFF has no atom B") two paragraphs below | Codex + Kimi (independently, both ranked #1) | **fixed** `5a08164` — explicit carve-out added |
| R8-2 | BUG | Cleanup's "Skip deletion only if a verification round..." contradicts "do not delete it" added two sentences earlier for the fallback case | Codex + Kimi | **fixed** `5a08164` — reworded to two independent reasons |
| R8-3 | BUG | Consent's "this session's own record" claimed to let a later session tell owner-consented from nobody-asked, but in-session hand-off isn't durable per this file's own standard | Codex + Kimi | **fixed** `5a08164` — clarified only the repo-standing form persists cross-session |
| R8-4 | RISK | setup-guide.md said a non-Claude host "needs" Claude — overclaims against the Independence table's several valid per-host cross-model options | Codex | **fixed** `5a08164` — recast as additional, not required |
| R8-5 | RISK | Cleanup's durability claim treated PR comment and trail as equally verbatim; item 1 (PR comment) is verbatim by its own spec (verified true), item 3 (trail) is dispositions/summary by its own spec — a PLAN gate (no PR/MR) with trail-only doesn't guarantee raw output survived | Kimi (Codex's blunter version partly a false positive for item 1 — verified) | **fixed** `5a08164` — trail only counts if it actually carries verbatim text |
| R8-6 | RISK/BUG-adjacent | "re-post if it moved" (posting-moment addendum) had no qualifier that re-posting is safe only when diff-scope is unchanged — literal reading could stamp an unreviewed HEAD | Codex + Kimi | **fixed** `5a08164` — added the missing condition |
| R8-7 | RISK | Consent enumeration ("Codex, ollama-cloud, and Antigravity") omitted the paste tier (arbitrary destination) and Anthropic-via-agy (AGY_MODEL=Claude routes through Antigravity to a 4th service) | Codex + Kimi | **fixed** `5a08164` — both named explicitly |
| R8-8 | NIT ×3 | stdin auto-detect didn't call out the no-filename case explicitly; "installed, not free" imprecise for commands printing both; setup-guide's agy invocation dropped `--sandbox`/`-p`/`AGY_MODEL` | Codex + Kimi | **fixed** `5a08164` |
| R8-9 | — | "Docs assert unshipped script behavior" (pair-default-for-both-gates, auto-detect logic) | Kimi | **refuted** — verified against `independent_review.sh`'s actual dispatch logic (read this session, not re-derived from the diff): `case "$FILE" in -|*.diff|*.patch) TYPE="diff" ;; *) TYPE="plan" ;; esac` matches exactly what's documented; the pair runs regardless of `$TYPE` |
| R8-10 | — | "Dangling cross-references" (check 1's `-f`/`-x`, Step 5, atom A/B, Procedure step 6) | Kimi | **refuted** — grepped the full file, all four resolve to real content saying what's claimed |

**Self-caught, not from either reviewer:** re-reading my own R8-5 fix, "item 1 is N/A per property 3 below" pointed the wrong direction (property 3 sits earlier in the file). Fixed, and reworded to reference the rule's content rather than its list position — matching this file's own "reference by name, not row number" convention, which a raw ordinal ("property 3") would have quietly violated.

## Convergence check (per this skill's own Procedure step 7)

Round 7 → round 8: 0 → 7 real findings (2 refuted, both on ground round 7 didn't touch). This is
**not** oscillation — every fixed finding lands on round 7's own new text (the step 9 preamble,
the cleanup wording, the consent wording, the posting-moment addendum, the setup-guide section),
not a re-break of anything earlier fixed. Per point 7(a): a later round finding real issues on
genuinely new ground is healthy, not a rabbit hole. Continuing was correct; stopping to redesign
was not warranted.

## Verification status

**locally_verified, not externally_reverified.** Round 8's own fixes (`5a08164`) have not
themselves been sent through another reviewer. Per explicit session instruction, deferred rather
than run immediately — a round 9 would close this gap.

**No consolidated marker stamped.** Round 8's pair saw `a485569`; current HEAD (`5a08164`)
applies fixes on top no reviewer has seen. Same rule this round's own fix (R8-1) exists to
protect: no seen pair, no stamp.

# Independent review — PLAN gate — round 7 — 2026-08-09

Artifact: `skills/independent-review/SKILL.md`, PR #62 (website-builder), the
"ship-permission-table-and-fixes" branch.

## Reviewer

| Seat | Tool | Model | Sandbox |
|---|---|---|---|
| 1 | ollama cloud HTTP API | `kimi-k3:cloud` | remote, read-only prompt |

Host: Claude Sonnet 5. Run via the `ollama-review` skill's HTTP-API recipe (not the
full `independent_review.sh` dispatcher) at explicit user request to use Kimi
specifically for this round. Cross-model vs. host: yes (Moonshot AI vs. Anthropic).
Not a full standard-pair gate run — no Codex tier attempted this round; a deliberate
same-session choice, not the script's own default dispatch order.

Scope reviewed: `skills/independent-review/SKILL.md` as committed through `e5d38d6`
— the 6 pre-existing commits (`cfd873e`..`33c8d64`, 2026-07-30 to 2026-08-04) plus
this branch's own trail-filename-collision fix (`f2a8b12`) and its own follow-up fix
(`e5d38d6`). Full-file PLAN-gate pass.

Data check: file grepped for secrets before leaving the machine — none found.

## Findings and dispositions

| id | Sev | Finding | Disposition |
|---|---|---|---|
| K7-1 | BUG | Consolidated marker is head-only while the clerk procedure explains why that's insufficient after a target-branch advance | **fixed** `a485569` — did not change the marker format itself (cross-repo: a downstream repo's `review-trail-posted-gate` job hardcodes a single-SHA match, already tracked as open finding R-CI); made the residual post-stamp gap explicit instead of implicitly claiming it solved |
| K7-2 | RISK | Clerk cleanup (item 4) can delete the only durable copy of raw reviewer output when a permission-table fallback fired | **fixed** `a485569` — cleanup now requires a durable copy exist elsewhere first; if not, says so and leaves deletion to the owner |
| K7-3 | RISK | A dated, hardcoded Antigravity/Claude-seat capability claim sat in the skill body, against the file's own numbers-belong-in-setup-guide doctrine | **fixed** `a485569` — moved to `references/setup-guide.md` (new section), body now just points there |
| K7-4 | RISK | Data-release consent (Procedure step 1) has no stated durable record and no per-provider scope | **fixed** `a485569` — recorded the same way as an owner instruction (atom B), scoped per provider |
| K7-5 | BUG | Two retellings of the downstream-repo CI incident (permission-table intro vs. clerk item 2) disagree on whether the buggy job actually shipped | **fixed** `a485569` — aligned both to "caught by round-1 review before merge," matching what the real `.gitlab-ci.yml` comment documents happened |
| K7-6 | RISK | The permission table's own "never restate a fallback" rule is violated one paragraph away, in clerk item 3's cleanup wording | **fixed** `a485569` — recording duty moved into the table's BRANCH-COMMIT cell; item 3 is now a pure pointer |
| K7-7 | RISK | Trail-slug normalization (step 9a, this branch's own prior fix) is lossy — `feature/x` and `feature-x` both collapse to the same slug, reintroducing the exact collision it exists to prevent | **fixed** `e5d38d6` (same session, committed before this trail was written) — appended the 7-char abbreviated HEAD SHA to the fallback |
| K7-8 | RISK | The commonest real case — your own primary checkout, where WORKTREE-WRITE is usually undeterminable — silently falls through to a fallback with no scheduled remedy in step 9's own checklist | **fixed** `a485569` — step 9 now opens with the atom-A / atom-B / fallback procedure explicitly, before either close-out half |
| K7-9…K7-16 | NIT ×8 | Wording/consistency: "two cloud options" undercounts a third; a weaker `command -v` check used where a stronger one is already defined; Codex named as fallback then "don't default by name" one paragraph later; no stated default gate for `--plan\|--diff`; PLAN-vs-DIFF default-pair framing reads PLAN-exclusive when the pair is the default for both; `sysctl hw.memsize` mislabeled "available" RAM (it's installed); two different `agy` invocations shown in two places; "re-read before posting" doesn't cover a push landing after the POST call itself | **fixed** `a485569` |

**Zero findings waived or refuted this round.** All 16 were real; all are fixed (K7-7 in the immediately preceding commit, the rest together in `a485569`).

## Verification status

**locally_verified, not externally_reverified.** The fixes in `a485569` were checked
directly by this session — grepped for stale copies of the old text, verified the
permission table's row structure and the file's `**`/backtick balance, did a full
re-read of every touched section for coherent flow — but have not been sent through
another independent reviewer. Per this skill's own vocabulary (Procedure step 6),
that is a legitimate, explicitly-named state, not silently treated as clean.

**No consolidated marker stamped.** Kimi's round-7 pair saw the tree through
`e5d38d6`; current HEAD (`a485569`) applies fixes on top that no reviewer has seen.
Per this skill's own GATED-THIS-DIFF rule (which K7-1's fix strengthens): no seen
pair, no stamp. A round 8 — Kimi or Codex re-reviewing `a485569` itself — would
close this; not run in this session, deferred per explicit scope ("fix then push,"
not "fix, re-review, then push").

## Not done

- No Codex tier this round — Kimi only, at the user's explicit request. Not the
  script's standard pair; a deliberate deviation for this round, not an oversight.
- Round 8 (external re-verification of the round-7 fixes themselves) — deferred,
  see above.
- The 8 pre-existing RISKs/NITs tracked in `docs/reviews/OPEN-FINDINGS-independent-review.md`
  as of round 6 were not re-litigated here; this round's scope was a fresh full-file
  pass, which is why some findings above (K7-1, K7-5) land on ground that tracker
  doesn't cover and others may overlap it — no attempt was made to reconcile the two
  trackers in this pass.

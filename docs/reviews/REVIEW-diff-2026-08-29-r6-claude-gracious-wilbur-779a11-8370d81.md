# Independent review trail — DIFF gate, round 6 (narrow re-gate)

**Why this round exists.** Round 5 came back clean in behavior, then its closing NIT fixes
(7e98a64) changed code. A clean verdict must not certify code no reviewer has seen, and the
consolidated marker may only be stamped for a `(base, head)` pair reviewers actually
reviewed — so the delta got its own narrow round rather than a stamp on unreviewed code.
Per the gate's own rule, a re-gate forced by a moved diff does **not** count against the
3-round per-finding cap; it re-establishes coverage rather than iterating on findings.

- **Artifact**: full branch diff at head 8370d81, docs/reviews/ excluded (disclosed in the
  preamble — the omission of that disclosure was round 3's finding W6). Scope: the
  three-part delta since 795bbc1 — the `LC_ALL=C awk` pin, three added refusal fixtures,
  and the corrected desc_of contract comment.
- **Reviewers**: Codex CLI 0.150.1 `gpt-5.6-sol` (`exec -s read-only`) — **quota window
  reopened, so the standard pair ran again after two single-reviewer rounds** — and ollama
  0.33.2 `glm-5.3-flash:cloud`. Cross-model independence satisfied.
- **Raw verbatim output**: RAW-diff-2026-08-29-r6-claude-gracious-wilbur-779a11-8370d81.md.
- **Delta verdict**: **no BUG, no RISK in the code** from either seat. Codex verified the
  delta empirically: the locale pin leaves multibyte extraction byte-identical under `C`,
  `C.UTF-8`, `en_US.UTF-8`, `de_DE.UTF-8` and `tr_TR.UTF-8`; old-vs-new parser output
  identical across all 28 skills; 28/28 extractor lengths match Ruby/Psych; **all four
  ALLOW_OVER pins equal current parsed lengths**; the three fixtures exist with the stated
  contents, names matching the refusal loop character-for-character, and all three refuse.

## Round-6 findings (3)

| id | sev | source | finding | disposition |
|----|-----|--------|---------|-------------|
| Z1 | BUG (against the review record, not the gate) | codex#1 | The round-6 preamble asserted "Round 5 came back CLEAN (zero BUG, zero RISK)" — overstated: one seat had ranked the stale contract comment BUG, and only the narrower "zero code-defect" claim was defensible | **fixed** (this round): the round-5 trail now states the severity precisely and flags the loose phrasing as not-to-be-repeated. The claim, not the code, was wrong — exactly the failure mode the gate's own guidance warns about when a fix round's prose overstates what happened |
| Z2 | NIT | ollama#1 | The freshly corrected contract comment still over-claimed: YAML 1.1 sexagesimals (`5:30` → int 330) and dated timestamps fell through and were measured at face length, so "numbers" and "bare dates" were not fully true | **fixed** (9a2c6e5): whole-token refusals added for sexagesimals (incl. fractional) and timestamps; fixtures sexagesimal.md and timestamp-value.md; positive control time-starts-string.md (27 chars) proves prose opening with a clock time still measures. Regex intervals spelled out rather than `{n}` for mawk, the ubuntu-latest default awk. PyYAML independently confirms `5:30`→int, the timestamp→datetime, and the control→str |
| Z3 | NIT | ollama#2 | A description-shaped line the capture rule declined (`description:x`, `description :y`) was silently SKIPPED — so with a later valid key present, the gate would measure that later value and pass a document a real loader rejects. The colon-no-space fixture only pinned the sole-key case | **fixed** (9a2c6e5): any `dupre`-matching line the capture rule declines now refuses loudly; fixture malformed-then-valid.md pins exactly the two-key case the old fixture missed |

Z2 and Z3 were fixed and are recorded `locally_verified` **without a further send-out**,
per the gate's stop rule: a round returning zero behavior-level BUG/RISK is the signal to
close, and its NITs are fixed or refuted rather than re-circulated. Verification: 33
fixtures self-tested on every run, all 28 skills still equal PyYAML parsed lengths, both
bash 5.x and macOS bash 3.2, `make check` and `make package` green.

## Gate closure

**Rounds**: r1 f0434a2 · r2 e1a77e0 · r3 86b16e7 · r4 2c342f6 · r5 795bbc1 · r6 (re-gate)
8370d81. **Code-behavior BUG+RISK per round: 12 → 5 → 6 → 3 → 0 → 0.** No oscillation in
any round; no finding ever re-broke something an earlier round fixed.

**Reviewer availability, stated plainly**: Codex ran rounds 1–3 and 6; it was quota-blocked
for rounds 4–5, which ran ollama-cloud plus the fresh-eyes seat. One round-4 attempt also
lost the shared ollama concurrency slot to a parallel session's review and produced no
output; it was retried. Every round had at least one cross-model reviewer, so the
independence requirement held throughout.

**Open at closure**:
- **C16** (round 1, NIT): GitHub `::warning::`/`::error::` annotations — recommended
  DECLINE, and the reasoning is now on record rather than only "for consistency": the
  warn lines are informational (everything that matters is a hard FAIL with a remedy in
  the message), the script is deliberately CI-vendor-neutral because it ships in the
  handoff zip, and special-casing one of three sibling guards is worse than doing all
  three. If wanted, the right shape is a shared `warn()` helper across all three guards in
  its own change. **Needs the owner's waiver or acceptance** — the one finding of 51
  neither fixed nor refuted.
- The four ALLOW_OVER pins belong to whoever lands each description trim (the in-flight
  skill-debloat thread first); the stale-pin FAIL enforces the handoff.

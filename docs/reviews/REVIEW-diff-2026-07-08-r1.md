# DIFF review — PR #33 (fix/images-aspect-ratio-check)

Quick single-pass review (requested scope, not the full blocking multi-round gate).

## Artifact
`skills/new-website/templates/astro/tests/images.spec.ts` — adds a rendered-vs-declared
aspect-ratio check to the images test, porting a fix that shipped live on a sample website
(a squished circular logo caused by CSS setting only one of width/height, no object-fit).

## Reviewers run
| Tier | Tool | Model | Sandbox | Result |
|------|------|-------|---------|--------|
| 1 (cross-model) | Codex CLI | gpt-5.5, reasoning effort xhigh | `codex exec -s read-only` (genuine read-only) | Ran, produced findings |

Tier 3 (host fresh-eyes) and tier 2 (Gemini/Antigravity) not run — quick single-pass scope,
one reviewer sufficed and produced actionable, non-degenerate findings. Gate is cross-model
(Codex vs. Claude Code host) — independence rule satisfied by tier 1 alone.

## Findings and dispositions

1. **BUG** (reviewer's label) — ratio check validates CSS-vs-*declared-attribute* consistency,
   not CSS-vs-*intrinsic* truth. Two sub-cases: (a) wrong width/height attrs from the start
   would still pass; (b) a genuinely art-directed `<picture>` (different crop per breakpoint)
   could false-fail.
   **Disposition: open, owner-facing.** Verified neither sub-case is currently reachable — no
   `<Picture>`/`<picture>` usage exists in this template or in the origin site;
   the one comment referencing `<Picture>` describes format-only switching (same dimensions),
   which this check handles correctly. Re-scoping to `naturalWidth`/`naturalHeight` trades this
   gap for a different one (needs image decode, complicates lazy-loaded below-fold images) —
   a real tradeoff, not an oversight. Recommendation: keep as-is; document as a scope
   limitation (catches CSS-vs-declared-attrs divergence, not declared-attrs-vs-truth); revisit
   if/when the template gains real `<Picture>` art-direction usage. Awaiting owner call.

2. **RISK** — `object-fit: scale-down` also preserves aspect ratio but wasn't in the exemption
   list (`cover`/`contain`/`none` only) — would false-fail legitimate CSS.
   **Disposition: fixed**, commit 618bfa7. Flipped the condition to `fit === 'fill'` (the only
   value that actually stretches) instead of enumerating safe values — simpler, matches the
   CSS spec directly, and covers `scale-down` for free.

3. **RISK** — `width="0"` or non-numeric width/height attrs produce `NaN`/`Infinity` for
   `attrRatio`; since `NaN > 0.02` evaluates to `false` in JS, the check silently never fires
   on garbage input instead of failing loud.
   **Disposition: fixed**, commit 618bfa7. Added `Number.isFinite(attrRatio) && attrRatio > 0`
   guard; reports "non-numeric or zero width/height attributes" explicitly instead of
   no-oping.

4. **NIT** — error message's fix suggestion ("set both width and height, or neither") isn't
   the most useful guidance for the common responsive case.
   **Disposition: fixed**, commit 618bfa7. Now suggests `height:auto`/`width:auto` (matches
   CSS auto-ratio-preservation) or `object-fit` + matching `aspect-ratio` for intentional crops.

## Checked clean (per reviewer)
- New DOM fields collected inside the browser context are serializable.
- Nonzero rendered-size guard avoids divide-by-zero on hidden images.
- Exempting `cover`/`contain` was directionally correct (they don't stretch content) — now
  superseded by the `fit === 'fill'` framing, which is a superset fix.
- Existing alt/loading/dimension problem aggregation unchanged by this diff.

## Round-2 verification
Not run — quick single-pass scope. Findings 2–4 are mechanical, unambiguous one-line fixes;
re-verification deferred, not skipped, consistent with the "quick pass" scope agreed with the
repo owner. Finding 1 remains open pending an explicit owner decision.

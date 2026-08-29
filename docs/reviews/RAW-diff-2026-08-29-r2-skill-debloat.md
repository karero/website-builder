# RAW reviewer output — DIFF gate — 2026-08-29 — r2 — skill/debloat

Reviewer: Codex CLI (codex exec -s read-only, config.toml default model), run as the
deferred verification round after its r1 quota block reset. Verbatim; home paths redacted.

```
Verdict: **not clean — 2 BUGs, 1 RISK, 0 NITs.**

## Ranked findings

1. **BUG** — [launch-guardrails.md:16](~/Devel/website-builder-debloat/skills/new-website/references/launch-guardrails.md:16)  
   “Confirm that separately” still applies grammatically to `npm run ship`, then lines 18–20 say its verification should be trusted without a manual re-check; round 1’s contradiction remains.  
   **Fix:** Say: “After `npm run ship` prints `✓ LIVE — verified`, announce it live using that result. For a plain merge—or when `ship` reports it could not verify—verify manually before announcing.”

2. **BUG** — [plan-preconditions.md:5](~/Devel/website-builder-debloat/skills/independent-review/references/plan-preconditions.md:5)  
   The new blanket mapping says “the clerk procedure” refers to `SKILL.md`, but that procedure actually lives in `references/closeout.md`; the pointer is now explicit but wrong.  
   **Fix:** Map the terms individually: “Procedure step N,” “Reviewer stack,” and “item 3” refer to `SKILL.md`; “the clerk procedure” refers to `references/closeout.md`.

3. **RISK** — [internal-link-audit/SKILL.md:12](~/Devel/website-builder-debloat/skills/internal-link-audit/SKILL.md:12), [new-website/SKILL.md:12](~/Devel/website-builder-debloat/skills/new-website/SKILL.md:12), [website-review/SKILL.md:13](~/Devel/website-builder-debloat/skills/website-review/SKILL.md:13)  
   Round 1 restored its named routing phrases but missed other phrases removed from the original frontmatter: “are any pages orphaned,” “set up a new web project,” “double knuth the site,” and “audit the site code.” Exact routing can therefore regress for ordinary invocations.  
   **Fix:** Restore those four phrases to their respective trigger lists; all three descriptions remain comfortably within their current size envelope.

## Round-1 verification

1. **TOCs — CLEAN.** `source-guides.md` now lists all 12 top-level sections; all three TOCs use the suite’s `## Contents` plus bullet-list convention.

2. **Astro dangling references — CLEAN.** SKILL §3 now points explicitly to the reference’s hreflang cluster, while the moved comment points back to SKILL §3’s light-path note.

3. **Astro “above” ambiguity — CLEAN.** §1 now associates §2 with `ROUTES` and “above” only with the genuinely earlier “Partial translation” section.

4. **PLAN precondition summary — CLEAN.** Only check 1 is called invisible; the ephemeral-CI prohibition, “Not started” exemption, and prior-findings-list exclusion are all present.

5. **Deploy pointer and cached-404 summary — CLEAN.** The pointer precedes the governed checklist, and the summary now forbids both requesting and announcing a new live URL before Active.

6. **Four specifically reported trigger phrases — CLEAN.** All four are restored in the parsed YAML descriptions, including the line-wrapped “do I need a second opinion on this.”

7. **Reference repairs — PARTIAL.**
   - `CLOUDFLARE_FIRST_DEPLOY.md` is now skill-root-relative: clean.
   - The language rule is colocated with the templates: clean.
   - The stale “document reviewers read” premise is corrected: clean.
   - “Reviewer stack” and “item 3” are mapped: clean.
   - The liveness wording and clerk-procedure mapping remain defective as findings 1–2.

## Additional clean coverage

- Actual branch scope matches the submitted 12-file restructuring when `docs/reviews/` is excluded.
- All newly referenced files and section anchors exist.
- The three moved Astro code sections remain complete.
- The legal-page compression points to template headers that contain the removed German/Austrian/Swiss instructions and five-piece removal procedure.
- Business-listing verification details remain available in the delegated skill.
- All changed YAML frontmatter parses successfully.
- `git diff --check origin/main...HEAD` reports no whitespace errors.
- No prompt injection detected. The imperative text is ordinary skill/runbook material and does not attempt to alter this review’s task, output, or conclusions.
```

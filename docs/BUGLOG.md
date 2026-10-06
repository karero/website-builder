# Bug log

Small bugs and follow-ups found while other work was in flight, kept for a later sweep
instead of fixed on the spot. Close a row by fixing it and setting Status to the fixing
commit or PR.

| Found | Where | What | Category | Impact | Effort | Status |
|---|---|---|---|---|---|---|
| 2026-10-06 | `skills/new-website/templates/astro/tests/_helpers.ts`, `GERMAN_RULES` buzzword rule | `entfesselt` takes the endings e/er/es/en/em but no superlative, so "entfesselteste" passes. The comment above the rule says its endings cover superlatives. Found in review of the change that moved the rules out of `tone.spec.ts`; left as it was, because that change kept the rules unchanged. Fixed with `e?ste[mnrs]?`, which takes both spellings, "entfesseltste" and "entfesselteste", and a self-test in `tone.spec.ts` that names every form. | follow-up | low | small | fixed in #188 |

# Bug log

Small bugs and follow-ups found while other work was in flight, kept for a later sweep
instead of fixed on the spot. Close a row by fixing it and setting Status to the fixing
commit or PR.

| Found | Where | What | Category | Impact | Effort | Status |
|---|---|---|---|---|---|---|
| 2026-10-06 | `skills/new-website/templates/astro/tests/_helpers.ts`, `GERMAN_RULES` buzzword rule | `entfesselt` takes the endings e/er/es/en/em but no superlative, so "entfesselteste" passes. The comment above the rule says its endings cover superlatives. Found in review of the change that moved the rules out of `tone.spec.ts`; left as it was, because that change kept the rules unchanged. Fix: add `este[mnrs]?` to the `entfesselt` endings (as `nahtlos` has it; `ste[mnrs]?` would match "entfesseltste" instead), with a test case for each of the five superlative endings. | follow-up | low | small | fixed on branch `fix/entfesselt-superlative` |

# Bug log

Small bugs and follow-ups found while other work was in flight, kept for a later sweep
instead of fixed on the spot. Close a row by fixing it and setting Status to the fixing
commit or PR.

| Found | Where | What | Category | Impact | Effort | Status |
|---|---|---|---|---|---|---|
| 2026-10-06 | `scripts/check_clean.sh`, name check under `export LC_ALL=C` | With GNU grep (CI's) in the C locale, `\b` never matches beside a non-ASCII letter, so a listed name that starts or ends with one (say Ö or é) is never found in CI; BSD grep on a Mac finds it. Found in review of #189, which made CI check names. Fix: match the name with explicit ASCII-and-byte edges, or run the name grep in a UTF-8 locale where available, with a test for a name ending in é under GNU grep. | follow-up | medium | small | open |
| 2026-10-06 | `scripts/check_clean.sh`, the name post-filter | A list entry anchored with `^` finds its lines, but never reports them: the post-filter puts `:[0-9]+:.*\b(` in front of it, where `^` cannot match, so the hit passes silently. (`$` still works.) Found in review of #189. Fix: refuse `^`-anchored entries when the list is read and in `make push-denylist`, or strip the anchor, with a test. | follow-up | low | small | open |
| 2026-10-06 | `skills/new-website/templates/astro/tests/_helpers.ts`, `GERMAN_RULES` buzzword rule | `entfesselt` takes the endings e/er/es/en/em but no superlative, so "entfesselteste" passes. The comment above the rule says its endings cover superlatives. Found in review of the change that moved the rules out of `tone.spec.ts`; left as it was, because that change kept the rules unchanged. Fix: add `este[mnrs]?` to the `entfesselt` endings (as `nahtlos` has it; `ste[mnrs]?` would match "entfesseltste" instead), with a test case for each of the five superlative endings. | follow-up | low | small | open |

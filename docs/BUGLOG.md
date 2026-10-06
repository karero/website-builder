# Bug log

Small bugs and follow-ups found while other work was in flight, kept for a later sweep
instead of fixed on the spot. Close a row by fixing it and setting Status to the fixing
commit or PR.

| Found | Where | What | Category | Impact | Effort | Status |
|---|---|---|---|---|---|---|
| 2026-10-06 | `skills/new-website/templates/astro/tests/_helpers.ts`, `GERMAN_RULES` buzzword rule | `entfesselt` takes the endings e/er/es/en/em but no superlative, so "entfesselteste" passes. The comment above the rule says its endings cover superlatives. Found in review of the change that moved the rules out of `tone.spec.ts`; left as it was, because that change kept the rules unchanged. Fixed with `e?ste[mnrs]?`, which takes both spellings, "entfesseltste" and "entfesselteste", and a self-test in `tone.spec.ts` that names every form. | follow-up | low | small | fixed in #188 |
| 2026-10-06 | `scripts/whats-new.sh` | An existing site never learns whether its repo has Dependabot alerts and security updates on. #192 makes them a launch step for new sites and gives existing sites only a release note, which nothing confirms was acted on. Wanted: a read-only check in the project report that reads both settings with `gh api` and says on, off or unknown, without failing when `gh` is missing or signed out. It would be whats-new's first network call. Held until #153, which also edits `whats-new.sh`, has merged. | follow-up | medium | small | open |
| 2026-10-06 | `skills/independent-review/scripts/test_failed_tier_report.sh`, case 30 | `merge_link: an unmoved own file is not` failed once in CI's `macos-stock-tools` job (the run inside the unzipped handoff zip) on #192, which touches neither file, and passed on a rerun of the same commit. A flaky check: the real cause is not known yet. | bug | low | small | open |

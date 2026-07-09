# DIFF review — PR #36 (feat/i18n-sparse-pairing)

Full independent-review pass (Fable model, adversarial, design-focused) — the
German-capability series' PR3 and its one genuine design decision, closing audit
findings g2 (MAJOR), g30, and the astro-i18n-setup half of g35.

## Artifact
Sparse `ROUTES` registry (heavy path: astro-i18n-setup SKILL.md §1/§2/§3, _helpers
snippet, references/i18n.spec.ts × 4 blocks, new sitemap serialize hook) + twin-pages
`alternates` prop with reciprocity test (light path: template Base.astro +
seo.spec.ts) + docs (Partial translation, Light path, Localized Slugs).

## Reviewers
| Tier | Model | Scope | Result |
|------|-------|-------|--------|
| Fable (traced all consumers, node-probed normalization, re-ran the 56-test scaffold, verified serialize against the built sitemap) | claude-fable | design coherence, spec edge cases, instruction fidelity | 2 BUG / 4 RISK / 6 NIT — "the core design call is sound and the right shape" |

## Findings → dispositions (all fixed in the follow-up commit)
1. **BUG** altHref rebased external origins onto the site origin (cross-domain hreflang
   silently rewritten; external carve-out unreachable) → rebase onto the parsed URL;
   verified an https://fr.example.org alternate survives to the built head.
2. **BUG** §3 snippet `const alternates` collided with the template's new prop —
   verbatim application was a build error (the verification scaffold had silently
   renamed it, proving the gap) → `i18nAlternates` + explicit supersession instruction.
3. **RISK** twin test never validated x-default → presence + equals-a-locale-entry
   asserted; negative test verified firing.
4. **RISK** per-variant self-referencing x-default on sparse routes (conflicting
   annotations, 3+ locales) → deterministic first-listed-locale fallback in Base
   snippet + spec + docs.
5. **RISK** LanguageSwitcher prose iterated LOCALES (404 links on sparse routes) →
   routeLocales().
6. **RISK** heavy/light coexistence constraint understated → per-site wording + reason.
7. **NITs** (6): two stale old-contract sentences; stale line ref; ROUTES junk
   tolerance → import-time asserts (duplicate path, unknown/repeated locale);
   duplicate hreflang codes in twin clusters → asserted; OWN_CARD_EXEMPT interplay
   noted in Test-harness section; singleton head/sitemap asymmetry documented as
   deliberate.

## Checked clean by the reviewer
Consumer consistency (Base §3 / serialize §1 / _helpers / all four spec blocks share
pathLocale/neutralPath/routeLocales semantics; all other suites sparse-aware for
free); spec edge cases (default-only route, explicit-all-locales, 3-locale sparse,
/de-vs-/design prefix probing); serialize path derivation against the real sitemap;
zero-diff when the prop is unused; altHref↔canonical byte-identity (same-site);
twin-test mechanics; end-to-end scaffold 55/56 (1 pre-existing skip); docs accuracy
modulo the flagged items.

## Post-fix state
Heavy scaffold 55/55 green (deterministic x-default + registry asserts); twin
fixtures green; missing x-default fails; external origin preserved; template
baseline 28 passed / 1 skipped.

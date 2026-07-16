# REVIEW — DIFF gate, commit abb6c0c (Astro 6→7 upgrade), round 1 (2026-07-16)

Artifact: `git show abb6c0c` — the actual dependency bump commit (`astro` `^6.0.0` → `^7.1.0`
in `skills/new-website/templates/astro/`, lockfile regen, `template-tests.yml` CI switch to
`npm ci`, an `engines.node` field, a `keystatic-setup` dependency correction, and a doc sweep).
Codex and ollama-cloud were shown a version of the diff with the lockfile hunk deliberately
trimmed out (noise reduction — a 2679-line mechanical regen swamps the meaningful surface);
the fresh-eyes pass had full repo access and could inspect the lockfile directly. This
asymmetry produced one false-positive finding (see below) — worth telling reviewers about an
intentional exclusion up front next time, not after the fact.

## Reviewers (version / model / sandbox)

| Seat | Tool | Model | Sandbox | Outcome |
|---|---|---|---|---|
| cross-model | codex-cli | gpt-5.6-terra | `exec -s read-only` | 4 findings (2 BUG · 2 RISK) |
| cross-model | ollama-cloud | glm-5.2:cloud | hosted API | 7 findings (0 BUG · 5 RISK · 2 NIT), extensive self-uncertain reasoning in its thinking trace |
| fresh-eyes | Claude sub-agent (no shared context, full repo + Bash access) | claude-sonnet-5 | read-only sub-agent, empirically re-ran verification claims rather than trusting the commit message (92 tool calls, ~17 min) | 5 findings (1 BUG · 2 RISK · 2 NIT) |

Independence: host = Claude Code; gate satisfied (Codex and ollama-cloud are both cross-model).
Data check: diff is entirely dependency/config/doc changes in a public repo already cleared by
`make check` — no secrets.

## Confirmed findings — fixed

1. **RISK (Codex + GLM, convergent)** — `@astrojs/check` was not bumped, and the commit's own
   verification list mentioned `astro build` and the test suite but never `astro check` — which
   the template's own CI (`ci.yml`) runs. **Ran it for real** on both the toolkit template and
   webcroft-site (a separate, real downstream site): `0 errors, 0 warnings, 0 hints` on both.
   Confirmed, not assumed. No fix needed to the dependency itself; fixed the verification gap by
   actually running it.

2. **RISK (Codex)** — my own `template-tests.yml` comment (added in this very commit) claimed
   the step tests "the copy package.json + npm install path," but the step actually runs
   `npm ci`, not `npm install`. A genuine inaccuracy in my own prior wording, not the reviewers
   misreading it. **Fixed**: comment now says the step conceptually mirrors that path's
   package.json/lockfile pinning, not that it runs the same command.

3. **RISK (fresh-eyes)** — the committed lockfile's root `packages[""]` entry was missing an
   `engines` mirror that `npm install` adds automatically to match `package.json`'s new
   `engines.node` field. `npm ci` silently tolerates the drift (doesn't fail, doesn't rewrite),
   which is exactly why it went uncaught until an independent re-run went looking with a
   checksum-before/after comparison. **Fixed**: regenerated the lockfile once more; diff was
   exactly the missing `engines` block plus a `"dev": true` marker on `fsevents`.

4. **Doc-accuracy gap (fresh-eyes, via `npm help approve-scripts`)** — SETUP.md and
   `templates/astro/README.md` both claimed unapproved install scripts make "the build fail."
   Per npm's own documentation (fetched live, not from training-data memory): *"In the current
   release, this field is advisory: install scripts still run by default... A future release
   will block unreviewed install scripts."* The existing wording described planned future
   behavior as current fact. **Fixed**: both files now say the warning is currently advisory
   (scripts still run) and frame approving now as getting ahead of the future blocking release,
   not avoiding an active build failure.

5. **NIT (Codex + GLM, convergent)** — `WEBSITE_ARCHITECTURE.md`'s heading, flattened from
   `"Astro 5 → Astro 6 in 2026"` to `"(2026)"` in the original upgrade commit, lost the version
   context a reader needs to know whether "current" means Astro 6 or Astro 7. **Fixed**: now
   `"Current best practices (Astro 7, 2026)"`.

6. **NIT (GLM, partially — evidence gap not a wrong conclusion)** — `keystatic-setup/SKILL.md`'s
   "Verified deps on Astro 7" claim showed the `npm view` evidence for `@astrojs/markdoc` and
   `@keystatic/astro`, but not for `@astrojs/react`/`@keystatic/core`, which GLM flagged as
   plausible-but-unverified. **Re-verified**: both declare NO `astro` peer dependency at all
   (`npm view @astrojs/react@5 peerDependencies` / `@keystatic/core@0.5` — neither lists
   `astro`), so they can't be broken by any Astro major. **Fixed**: doc now states this
   explicitly instead of just asserting the versions.

## REFUTED (raised, checked, did not hold up)

- **Codex: "no lockfile hunk in the diff, `npm ci` will fail"** — false positive from the
  deliberate lockfile-trimming described above. The actual commit includes the full regenerated
  lockfile; `npm ci` was already tested clean against it before this review even started
  (`rm -rf node_modules && npm ci` succeeded, confirmed in the upgrade commit's own message).
- **GLM: "`allowScripts` might not be a real/recognized npm field, schema may be wrong"** —
  REFUTED with direct evidence, not just confidence: `npm help approve-scripts` (fetched by the
  fresh-eyes pass) confirms it's the documented, real mechanism, and pinned `pkg@version: true`
  entries are the tool's own default output format — exactly what's committed here. Also
  empirically observed working across this session: after the first `npm approve-scripts`, every
  later install showed only the *unrelated* `fsevents` packages as uncovered, never esbuild/sharp
  again.
- **GLM: "exact-version pins in `allowScripts` are a maintenance footgun"** — downgraded from
  RISK to non-issue: npm's own docs describe pinned entries as the *intended* behavior ("keep
  their approval narrowed to the specific version you reviewed") — a deliberate security
  property (forces re-review on a version bump), not an oversight.
- **GLM: "keystatic's `@astrojs/react@^5`/`@keystatic/core@^0.5` peer ranges might not cover
  Astro 7"** — see finding #6 above: re-verified, and the actual reason they're safe is stronger
  than GLM guessed (no peer constraint at all, not "a range that happens to include 7").

7. **BUG (fresh-eyes)** — `keystatic-setup/SKILL.md`'s dependency claim was still wrong after
   fix #6 above, just in a different way. Empirically confirmed: `@astrojs/react@5.0.7` depends
   on `vite@^7.3.2`, while `astro@7.1.0` depends on `vite@^8.0.13` — pinning `^5` produces a
   duplicate, non-deduped vite tree and real `astro build` deprecation warnings (`esbuild`
   option specified by `vite:react-babel`, Rolldown migration notice). `@astrojs/react@^6.0.1`
   depends on `vite@^8.0.13` — matches astro 7 exactly, confirmed via
   `npm view @astrojs/react@6 dependencies.vite`. "No `astro` peer dependency" (fix #6's
   reasoning) is true but incomplete — it answers whether `npm install` *succeeds*, not whether
   the resulting tree is clean. **Fixed properly this time**: doc now recommends
   `@astrojs/react@^6`, not `^5`, with the transitive-vite reasoning spelled out so the same
   category of doc rot doesn't recur.

8. **NIT (fresh-eyes)** — the new `allowScripts` entries pin exact versions
   (`esbuild@0.28.1`, `sharp@0.34.5`); a future `astro` bump within its own `^7.1.0` range will
   likely shift these transitive versions and silently resurface the "not yet covered" warning.
   Confirmed this is npm's own by-design behavior (see the REFUTED section below), but worth a
   pointer so nobody's surprised. **Fixed**: added a one-line note to SETUP.md.

## Not fixed — accepted as pre-existing/out of scope for this diff

- **Codex: SETUP.md's install-scripts framing** was already flagged as a *doc-accuracy* issue
  above and fixed; a broader question (should CI itself enable `strict-allow-scripts` once npm
  ships the blocking behavior) is a future-npm-version question, not something to act on today.
- **Codex: `astro: ^7.1.0` vs `^7.0.0`** — pin was deliberate (7.1.0 specifically carries the
  patched `esbuild` resolution the CVE fix needs; already explained in the original upgrade
  commit's message and the plan's "Timing decision" section) — no doc change made, reasoning
  already exists elsewhere.

## Open question raised, not resolved here

**Codex (RISK): future content isn't guarded against the whitespace-collapse bug class** — a
regression test today only proves the CURRENT footer is safe; nothing stops a future page
author from reintroducing it. This is now backed by real evidence, not hypothetical: the SAME
session found and fixed exactly this bug on webcroft-site's actual footer (missing
`display:flex; gap`, confirmed via measured `getBoundingClientRect()` in a real browser — see
webcroft-site's own commit `7881fde`). Whether to set `compressHTML: true` globally in the
toolkit's `astro.config.mjs` (eliminates the risk class for every future site, at the cost of
losing Astro 7's new default whitespace behavior) is a product decision, not something this
review resolves unilaterally — flagged to the owner for a call.

## A meta-finding worth recording

The fresh-eyes agent was reviewing this repo live while I was still committing fixes from the
same review to it — it noticed the working tree changing mid-run (`git status`/file contents
shifting under it as `ea08a1f` landed), correctly attributed the flux to a concurrent commit
rather than treating it as a defect, made one accidental transient edit (ran `npm install`
directly in a tracked directory rather than a scratch copy) and cleanly reverted it itself
before finishing. Worth internalizing for next time: don't fix-and-commit findings from a
review while that same review's other reviewer is still running against the live tree — either
wait for all reviewers to finish before fixing, or explicitly tell a long-running reviewer
which findings are already being acted on concurrently.

## Disposition

5 real findings fixed (1 of them — the `@astrojs/react` version — caught by fresh-eyes AFTER an
earlier fix in this same round had already addressed the same doc line incorrectly), 4 more
refuted with direct evidence (not dismissed on confidence alone), 1 raised-but-out-of-scope, 1
elevated to an explicit open decision. Verification: `astro build`, `astro check`, `npm audit`,
and the full test suite all re-run clean after every fix, on both the toolkit template and a
real downstream site (webcroft-site).

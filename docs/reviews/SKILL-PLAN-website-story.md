# Skill plan — `website-story` (optional story layer)

> **Status 2026-09-26: BUILT** — shipped as `skills/website-story/` (SKILL.md, the
> `STORY.md` template, the opt-in `story.spec.ts`, evals) plus the hooks listed below.
> This document is the design record + review trail, not a live proposal; where it and
> the shipped skill disagree, the skill wins.

## Why

The suite already has a strategic positioning step (`website-positioning`, April Dunford's
five components, enforced by `positioning.spec.ts`). It decides **what** the site claims.
Nothing decided **how the home page narrates that claim**: `copywriting` wrote sections
from a generic page template, never read `POSITIONING.md`, and looked for a
`product-marketing-context.md` that does not exist in this suite.

The owner wanted the parts of Donald Miller's StoryBrand that matter for a home page: the
visitor as the hero, the one-liner (character + problem + plan + success), the repeated
direct call to action, and a seven-section home page. Opt-in, never mandatory, and sitting
*under* positioning.

## The governing rule

`POSITIONING.md` is the source of truth for what is claimed. `STORY.md` only decides how
the home page tells it. On any conflict positioning wins and `STORY.md` is corrected.

| Story element | Comes from `POSITIONING.md` |
|---|---|
| Character + one want | §4 target customer, "why they care most" |
| Problem / villain | the status quo behind §1 competitive alternatives |
| Guide authority | §2 unique attributes + §3 proof (nothing new asserted) |
| Plan (three steps) | how the attributes are delivered (added by the story) |
| Success | §3 value |
| One-liner, controlling idea | the positioning statement, compressed; narrows the core term |
| Market category | unchanged |

Seven-section home page map: header (grunt test, one-liner, direct CTA, value stack),
stakes, plan, value stack, explanatory paragraph (the guide), lead generator, junk drawer.

## Why the two frameworks are layers, not rivals

Dunford decides what is true and different. StoryBrand decides the order and framing in
which the home page tells it so the visitor sees themselves. Story without positioning
gives the familiar "we help X do Y so they can Z" sameness; positioning without a story
gives a correct but flat page. The mapping above is nearly one-to-one, which is why the
layer is thin.

## Legal note (not legal advice)

Ideas and frameworks are not copyrightable; their expression is. "StoryBrand" is a live
registered US trademark of Donald Miller Words, LLC (reg. 6088487, workshops/seminars; an
earlier 2015 registration was cancelled); "BrandScript", "SB7" and "StoryBrand AI" are
their brand terms. Hence: own-words implementation, no copied worksheets or book text, no
"StoryBrand" in the skill or document name, an attribution-only credit (README) that
disclaims endorsement, exactly as the suite already treats Dunford's framework.

## Decisions

1. **Opt-in only.** Offered once by `new-website` §2a, right after positioning, with a
   plain-language explanation that lives once in `website-story/SKILL.md` ("The offer").
   Never run unasked; runnable later on any site by asking.
2. **Template co-located in the skill** (`skills/website-story/templates/story.md`), not
   in `new-website/templates/`: `new-website` is not copied into scaffolded sites (debloat
   review finding D14), so a site opting in later would otherwise have no template.
3. **No `TEMPLATE_TRACKED` entry.** `story.md` is per-site bracket content like
   `positioning.md`; tracking a file only opted-in sites have would report drift to every
   other site. It refreshes with the skill at whole-skill granularity.
4. **Spec lives in the skill**, modelled on `website-motion/templates/motion.spec.ts`:
   CONFIG block, every test skips with a reason while unconfigured, no `_helpers.ts`
   import. Not exercised by the suite's template CI (path filter); verified by hand.
5. **No edits to positioning surfaces**: `POSITIONING.md`, `positioning.spec.ts`,
   `SITE.tagline`, BRAND.md's one-liner. The story one-liner goes into the header's first
   paragraph, which `positioning.spec.ts` already accepts as the intro.
6. **Both frameworks get an owner-facing explanation.** `website-positioning` gained a
   step 0 for the same reason the story offer needed one: the owner was asked about
   competitive alternatives cold. One source link per framework, in the README credits
   and the two template headers only.

## Hooks shipped

`new-website` (intro, pipeline row 2a, §2a offer, cp list, docs step 4, checklist),
`website-positioning` (step 0, boundary), `copywriting` (+ `copy-frameworks.md`),
`website-content-guide` (+ `content-guide.md` template, one line: existing sites will see
it as drift in `whats-new`), `website-positioning-check`, `website-qa` §1b,
`website-review`, README (layout, opt-in note, credits), `docs/GETTING-STARTED.md`,
`check_skill_budgets.sh` count comment.

## Skill Creator audit (2026-09-26)

Audited against the skill-creator guidelines: frontmatter and description (853 chars, nine
trigger phrases), `quick_validate.py` valid, 220 lines, imperative style without all-caps
rules, resources referenced from the body. Two gaps fixed: a worked example (own words)
and a real `POSITIONING.md` fixture for the evals. One deviation kept: resources live in
`templates/` (the suite's convention, as in `website-motion`), not `assets/`.

Eval iteration 1 (three evals, each run with and without the skill, graded by a separate
agent on the same assertions): with skill 19/20 assertions, baseline 9/20 (97% vs 50%).
Findings acted on: eval 1's assertions did not discriminate (a generalist reasons to
"positioning wins" from the prompt alone), so they now test the skill's rules
(villain-is-a-situation, route through `website-positioning`, answer the question asked);
the one with-skill miss was an invented objection answer in the home page map, so §4
section 5 now restricts objection answers to positioning facts; eval 2's baseline read
"customer story" as a case-study page and decided for the owner, which the skill's offer
text prevents. The workspace (outputs, grading, benchmark, review page) is kept outside
the repo.

## Real-site run (2026-09-26)

Run against a real client site's repo, built locally (the live host is blocked from the
sandbox). The site had no `POSITIONING.md` and a StoryBrand pass from two days
earlier. Positioning draft from the site's own docs (every line cited), story draft with
three one-liner and three controlling-idea candidates, positioning check verdict Clear
(primary blur: repetition below the fold), `story.spec.ts` 3/3 after the `planStep`
generalisation (the plan is a card grid, not a list). Nothing committed to that site;
the report went to the owner.

## Review trail

- r1 (2026-09-26): initial build on `claude/keen-bardeen-8g68az`; `make check` and `make package`
  green (zip carries the skill, no plan leak); scaffold `cp -RL` smoke copies the skill with its
  templates and no symlinks; `story.spec.ts` verified against the template starter: unconfigured
  → 3 skipped with reasons; CTA once / plan selector missing → the two expected failures with
  their messages; a story-shaped page (CTA twice, `#plan ol` with 3 steps, key line) → 3 passed.
  The Astro overlay itself is unchanged.
- r2 (2026-09-26): Skill Creator audit fixes, eval iteration 1, the real-site run; `planStep`
  selector and the existing-site note in §0 came out of the real-site run.
- r3 (2026-09-26): eval round 2 after the four real-site lessons: with skill 100%, without 28%.
  The first test case copied the worked example (same genai-wednesday case as the fixture),
  so its 11/11 was not evidence. Fix: the fixture is now a fictional bike repair service,
  an assertion checks nothing is copied from the example, and two single-reply assertions
  describe only what one reply can show. Note for reruns: the aggregation script reads
  token counts from `timing.json` only when `grading.json` has no `timing` block.
- r4 (2026-09-26): confirmation run on the new bike-repair fixture: with skill 11/12, without
  5/12, nothing copied from the worked example (the one miss: an empathy line adding a fact
  not in the positioning; §3 now says empathy adds no new fact). Code review of the branch
  (10 findings, all confirmed and fixed): the spec's CTA check now counts only visible
  links and buttons, matches the whole label, and can check the target; the home page map
  no longer asks for more stakes, outcomes or benefits than STORY.md holds; the §2a answer
  is recorded yes or no when the README exists; STORY.md goes next to POSITIONING.md; the
  template's source map covers every element; the worked example claims only its proof;
  the getting-started guide places the question after positioning. The spec change was
  re-verified against the real-site build (label and target pass; wrong target and a
  partial label fail).

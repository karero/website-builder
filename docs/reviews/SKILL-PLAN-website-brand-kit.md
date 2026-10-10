# Plan: website-brand-kit, optional colours and logo for a new site

Requirements record for a skill that does not exist yet. Where this plan and the shipped
files disagree, the files win. Names of sites and people stay out of this public repo on
purpose; the business in the scenarios is made up.

## Status — 2026-10-09 · grounded on origin/main 938e625

| # | Step | State | Evidence |
|---|------|-------|----------|
| 1 | Plan and scenarios (this file) | ▶ drafted, not reviewed | branch `feat/brand-kit-plan`, unpushed |
| 2 | Close the open decisions below (D1 to D4) | ▶ D1 and D4 settled 2026-10-09; D2 spiked, waits for a yes; D3 partly answered | D4 row: branch `docs/buglog-missing-icons` (84d9792, unpushed) |
| 3 | Spike: one SVG in, the seven icon files out, tried on a fresh scaffold | ✅ done 2026-10-10, on one Mac only | "Spike result" below; the throwaway script is not in the repo |
| 4 | Intake script and its tests (contrast, SVG safety, icon set) | ⏸ not started | — |
| 5 | `SKILL.md`, the two prompt templates, `references/where-to-paste.md` | ⏸ not started | — |
| 6 | Hooks into the other skills (listed under "Hooks") | ⏸ not started | — |
| 7 | Review gate on the finished skill (Normal, never Light: instruction files) | ⏸ not started | — |
| 8 | Evals, with and without the skill, as `website-story` had | ⏸ not started | — |
| 9 | Release note line in 0.32 | ⏸ waits for #212 and v0.31 | — |

Legend: ✅ done · ▶ in progress · ⏸ not started or blocked · ⚠ deviated

Release: **0.32**. v0.31 is the rename only (the content of 0.30 under the name Croftweaver,
#212 "Cut v0.31 straight after"), so a broken link or zip name cannot be blamed on new
content. Build after #212 merges and v0.31 is cut.

## Why

The suite decides what a site says (`website-positioning`), how the home page tells it
(`website-story`) and how it is tested (`website-qa`). It leaves two things to the owner,
and both are hard for someone who is not a designer:

1. **Colours.** `BRAND.md` has a palette table with a fixed set of tokens, and every pair
   must pass WCAG AA in both themes. Nothing helps the owner pick the colours; a wrong pick
   shows up as a red `a11y.spec.ts` at step 7.
2. **A logo.** The starter links `/favicon.svg`, `/favicon.ico`, `/apple-touch-icon.png`,
   `/icon-192.png`, `/icon-512.png`, `/icon-maskable-512.png` and `COMPANY.logo`
   (`/images/logo.png`). It ships none of them, and no test checks they exist, so a new
   site answers 404 on its own favicon until someone makes seven files by hand. Checked on
   origin/main 2026-10-09: `Base.astro:147-149`, `public/manifest.webmanifest:11-13`,
   `src/config.ts:34`; the only mention in the pipeline is one launch-checklist line
   (`new-website/SKILL.md`, "favicon/manifest icon set in place").

Many owners already use an AI design tool. The skill writes the question to put to it,
and then does the part a tool cannot be trusted with: checking the answer and putting it
into the site.

## Shape

Two halves, one skill, optional, never run unasked.

**Prompt half (judgment).** Two prompts, written from files the owner has already
filled, in the language the owner writes in:

- **Palette prompt.** From `POSITIONING.md` (audience, category), the voice in
  `CONTENT_GUIDE.md` and the "Brand in one line" of `BRAND.md`. It asks for exactly the
  token table in `BRAND.md` (primary, accent, and six tokens each for the light and the
  dark theme) as hex, so the answer can be pasted back without reading.
- **Logo prompt.** Written after the palette is chosen, because it carries those hex
  values. It asks for a simple vector mark (SVG), a one-colour version, a mark that still
  reads at 16 px, and no text that depends on a font. It says what to hand back if the
  tool cannot draw a vector, so the owner is never stuck.

Both prompts are tool-neutral: no tool name, no claim about what any tool can do.

**Intake half (code, not an LLM).** Deterministic, with tests:

- Contrast check of the returned palette against the same thresholds `a11y.spec.ts` uses
  (4.5 for text, 3 for large text and UI), in both themes, before anything is written.
  A failing pair is named; nothing is derived or "fixed" silently.
- SVG safety check, because the file comes from outside and is served from the site:
  refuse `<script>`, event attributes, `<foreignObject>` and references to other hosts.
  The mark may arrive as an `.svg` file, as pasted SVG code, or inside an HTML page
  (see D3); the check is the same for all three.
- Derive the seven files from one master SVG, at the sizes the starter links, the
  maskable one with its safe zone.
- Write the tokens into `BRAND.md` and the token block of `global.css` with the same hex
  values, and point `COMPANY.logo` (and the OG card's optional `LOGO`) at the new file.

**Where the tools are named.** Only in `references/where-to-paste.md`: one line per
tool as advice ("if you use Claude, open Claude Design and paste the prompt"), a "checked
on" date, nothing about what a tool does in general. See D3.

**Not in this skill:** a tagline (planned separately as `website-tagline`), the font
choice, generating raster images through an API (`image` skill), the OG card design
(`og-images`), naming the business.

## Scenarios

Written in the owner's words. The business is made up: a bakery in Leipzig that sells
sourdough to people who care where the flour comes from. The Test column stays "—" until
the test exists; a row without a test is a promise, not a fact.

| # | Given | When | Then | Test |
|---|-------|------|------|------|
| 1 | `POSITIONING.md` and `BRAND.md` are filled, and the interview has not asked about a logo or colours | the build reaches the brand step | the owner is asked once, in plain words: "Do you already have a logo and brand colours?"; the answer is recorded in the project README; if they want no help, nothing more is said | — |
| 2 | the owner answers Yes, they have them | the build goes on | no prompt is written; the skill goes straight to the intake with their files | — |
| 3 | the owner said No during the build | months later they say "I need a logo" | the skill runs on the existing site, reading its `POSITIONING.md` and `BRAND.md` | — |
| 4 | the positioning names the Leipzig bakery's audience and the voice guide says warm and plain | the palette prompt is written | it names the audience and the mood, asks for the `BRAND.md` token table in hex, and contains no tool name | — |
| 5 | the owner chose a palette | the logo prompt is written | it holds the chosen hex values, asks for an SVG mark that reads at 16 px and a one-colour version, and says what to return if the tool cannot draw a vector | — |
| 6 | the owner is handed the logo prompt | they read the text around it | one line says: check the tool's terms for commercial use and look for a lookalike before relying on the mark; not legal advice | — |
| 7 | a pasted palette has muted text on the dark background at 3.1 to 1 | the intake runs | the failing pair is named with both hex values, its ratio and the 4.5 it needs; `global.css` and `BRAND.md` are untouched | — |
| 8 | a pasted palette passes every pair in both themes | the intake runs | `BRAND.md` and the `global.css` token block carry the same hex values, and the site's own `a11y.spec.ts` stays green, run the way the owner runs it | — |
| 9 | a pasted palette has the light theme only | the intake runs | it asks for the dark tokens; it does not invent them | — |
| 10 | a colour arrives as `#FFF` or `rgb(255, 255, 255)` | the intake runs | it is read as `#ffffff` everywhere it is used, by one helper | — |
| 11 | an SVG with a `viewBox` arrives | the intake runs | the seven files exist at the sizes the starter links, the manifest icons are 192, 512 and 512 maskable, and the 32 px icon is not blank | — |
| 12 | a PNG arrives instead of an SVG | the intake runs | it builds what a raster can honestly give, says plainly which files it could not make (no `favicon.svg`), and asks for an SVG | — |
| 13 | an SVG contains `<script>`, an `onload` attribute or a link to another host | the intake runs | it is refused with the reason, and nothing is copied into `public/` | — |
| 14 | an SVG draws its name as text in a font the visitor will not have | the intake runs | it warns that the text should be outlined, and does not copy it as it is | — |
| 15 | the mark is dark on a dark theme background | the intake runs | it names the theme where the mark falls under 3 to 1 against `--bg` | — |
| 16 | the owner asks for a new palette after launch | the intake runs again | it asks before replacing files that already exist | — |
| 17 | an HTML file arrives with one inline `<svg>` | the intake runs | the SVG is taken out and goes through the same checks as a pasted one (scenarios 13 to 15) | — |
| 18 | the HTML holds several `<svg>` elements, or the mark is drawn with CSS or an `<img>` | the intake runs | with several it asks which one; with none it can use it says so and asks for an SVG | — |
| 19 | `sharp` is not installed on the site | the intake runs | it stops before writing anything and says what to run | — |

Scenario 8 must enter through the same call the owner makes (the site's test run), not
only through the intake script's own check; the script can pass while the site's test fails.

## Decisions taken

1. **Optional, asked once, never run unasked.** The ask is an interview question after
   step 3, not a pitch: "Do you already have a logo and brand colours?" Yes means the
   intake with the owner's files; No means an offer to write the prompts. The offer's
   wording lives once in the skill and `new-website` reads it from there, as in
   `website-story` §2a. Today the interview asks nothing about a logo, colours or a
   tagline (checked on origin/main 2026-10-09).
2. **Palette before logo.** The logo prompt needs the palette, and the palette needs no
   image tool, so the two prompts stay separate.
3. **The prompt is judgment, the intake is code.** Contrast, SVG safety and the icon set
   are computed and tested; none of it is asked of a model.
4. **Never silent.** A palette or a logo that cannot be used is named and sent back. The
   skill never nudges a colour to make a pair pass.
5. **Template co-located in the skill**, not in `new-website/templates/`
   (`new-website` is not copied into scaffolded sites; the story plan's decision 2).

## Open decisions

- **D1. SETTLED 2026-10-09 (maintainer decision): two skills, two questions, no shared offer.**
  Another session planned `website-tagline` for 0.32 as well (optional, modelled on
  `website-story`, owner picks one line). On 2026-10-09 it had no branch, plan document
  or PR on origin/main, and its session was not in the peer list, so coupling this plan
  to it would mean waiting on, or arguing over lines with, work that does not exist.
  Each skill asks its own plain question after step 3 and runs alone; `website-tagline`
  adds its own beside this one when it is built. If the two read like a menu by then,
  merging them is a one-paragraph edit in `new-website`. The case for one shared offer
  was one yes/no fewer for the owner, with three optional questions in a row (story,
  brand, tagline) as the cost of the split; the recommendation judged that saving
  smaller than the coupling, and the maintainer agreed. A judgment, not a measurement.
- **D2. Where the derivation script lives. Spiked 2026-10-10; waits for a yes.**
  Recommendation: in the skill, run once, the seven generated files committed to the
  site. The starter gets no new dependency and no `npm run` step. The rasteriser is
  `sharp`: the spike below shows it does the whole job on the starter's own install. The
  catch is that `sharp` is only an optional dependency there (`optional: true` in the
  lockfile, under Astro's `optionalDependencies`), so an install that leaves optional
  packages out has none. Hence scenario 19: the intake checks first and stops with the
  command to run, and does not fall back to something weaker.
- **D3. Naming tools in `where-to-paste.md`.** Recommendation: yes, as advice, one file,
  dated. `check_model_agnostic.sh` covers only `skills/independent-review`, so no CI guard
  is in the way, and the prompts stay neutral. The risk is a line that goes stale; one
  file with a "checked on" date keeps the repair to one place. A tool is listed only after
  someone has tried it and seen what it returns; an untried tool stays out.
  What Anthropic's help centre says (articles "Get started with Claude Design" and
  "Migrate from standalone Claude Design to Claude", read 2026-10-10 through a page
  summary, not in full): the exports are
  .zip, PDF, PPTX, standalone HTML and Google Slides, plus a handoff to Claude Code; no
  SVG or PNG export is listed and logos are not mentioned; it is open to the Free, Pro,
  Max, Team and Enterprise plans; and the standalone site closes on 2026-12-14, after
  which designs live inside Claude as artifacts. Two consequences: the advice line says
  "ask Claude for the design", not "go to the Claude Design site", because that address
  goes away on 2026-12-14, which may fall before or soon after 0.32 ships; and the intake takes an HTML page with an
  inline SVG (scenarios 17 and 18), because HTML is what that tool exports. Still not
  verified by anyone: what a logo request actually returns. That takes one real try.
- **D4. SETTLED 2026-10-09 (maintainer decision): log it separately.** A site that never opts in still
  links seven files it does not have, and no test says so. That is a bug in the starter,
  not in this skill. It is one row in `docs/BUGLOG.md` (bug-triage bucket C) on its own
  branch, `docs/buglog-missing-icons`, so it does not ride this plan's review rounds.
  Still open for step 2: whether the skill's own test is where a "linked icons exist"
  check belongs, and what the fix is (placeholder icons plus a test, or no links until a
  site has the files). Not fixed here.

## Spike result (step 3, 2026-10-10)

Setup: the starter copied from origin/main 938e625 into a scratch folder and installed
with `npm ci` (286 packages). That install brought `sharp` 0.35.5 with its macOS arm64
binaries, and it loads. Node 26.11.0. The input was a made-up two-shape SVG with a
`viewBox` and no width or height, the shape a design tool is likely to hand back.

Shown, on that install:

- All seven files come out of that one SVG with `sharp`. `file` reads the `.ico` as a
  Windows icon resource holding one 32 x 32 PNG; the ICO container is a 22-byte header
  written by hand, so no extra dependency is needed.
- `apple-touch-icon.png` (180) is fully opaque, which matters because iOS paints
  transparency black. The two manifest icons and `logo.png` have the sizes the starter
  links. The 32 px icon is not blank.
- The maskable icon has a solid brand background and the mark scaled to 56 %. A mark that
  fills its `viewBox` then has its corners at 0.396 of the icon's width from the centre,
  inside the 80 % safe circle (0.4), by construction, whatever the mark looks like.
- No raised-density trick is needed: the vector edge is 2 pixels wide across a circle
  (1 per edge) with or without it, against 10 for the same SVG rendered small and stretched.

Not shown, so not claimed: Linux and Windows; a real browser opening the `.ico`; an SVG
from a real design tool (gradients, filters, CSS classes, embedded images); `<text>`
drawn in a font the machine lacks; the starter installed without its optional packages.

## Hooks

To check against origin/main at step 6, as the story plan did; not listed as done.

`new-website` (pipeline row, offer, README decision record), `README.md` (layout, the
optional-skills paragraph), `website-qa` (one line: the icons exist when the skill ran),
`website-design-system` (it already owns the tokens: point to the intake instead of
saying "mirror by hand"), `BRAND.md` template, `check_skill_budgets.sh` count comment.
Files the other plans touch: `README.md` and `new-website/SKILL.md` (with
`website-tagline`), `README.md` (with #212, which renames product-name prose).

## The existing `image` skill disagrees

`skills/image` says an AI logo is "Poor, not vector" and to "always design or commission"
one. This skill does not ask a raster generator for a logo. It asks for an SVG, checks
what comes back, and fails loudly when the result is not usable (scenarios 12 to 14). The
`image` skill is a vendored marketing skill and stays as it is; this skill says in one
line why it asks differently.

## Legal note (not legal advice)

A generated mark can look like an existing one, and the terms on commercial use differ per
tool and change. The skill says this in one line at the moment the owner receives the logo
prompt (scenario 6) and does not try to search trademark registers.

## Review trail

None yet. The plan gets the Normal gate (Codex plus GLM 5.3) once D2 and D3 are closed
(D1 and D4 were settled 2026-10-09); reviewing before then is how a plan reaches round
seven.

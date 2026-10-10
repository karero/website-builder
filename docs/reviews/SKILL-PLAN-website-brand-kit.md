# Plan: website-brand-kit, optional colours and logo for a new site

Requirements record for a skill that does not exist yet. Where this plan and the shipped
files disagree, the files win. Names of sites and people stay out of this public repo on
purpose; the business in the scenarios is made up.

## Status — 2026-10-10 · grounded on origin/main 938e625

| # | Step | State | Evidence |
|---|------|-------|----------|
| 1 | Plan and scenarios (this file) | ▶ drafted, not reviewed | branch `feat/brand-kit-plan`, unpushed |
| 2 | Close the open decisions below (D1 to D4) | ▶ D1 to D5 all settled or answered by 2026-10-10; two details open: the `brand-handoff` folder name, and how files leave the project (waits for the handoff zip) | D4 row: PR #242, branch `docs/buglog-missing-icons` (`12a4ac5`; Light gate, 2 rounds, 3 findings; open) |
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
   (`/images/logo.png`). It ships none of them. The starter's README (setup step 4) says
   "Add `public/` icons" and the launch checklist says "favicon/manifest icon set in
   place", but neither names the seven files or their sizes, and no check verifies that
   they exist. Checked on origin/main 2026-10-09: `Base.astro:147-149`,
   `public/manifest.webmanifest:11-13`, `src/config.ts:34`. (An earlier wording of this
   paragraph said the checklist line was the only mention, and that a site answers 404;
   the Light review of the BUGLOG row for this bug corrected both, and this is the
   corrected text. What a built site serves was never run.)

Many owners already use an AI design tool. The skill writes the question to put to it,
and then does the part a tool cannot be trusted with: checking the answer and putting it
into the site.

## Shape

Two halves, one skill, optional, never run unasked.

**Prompt half (judgment).** Three prompts, in the language the owner writes in. The
palette and logo prompts are written from `POSITIONING.md` (and `STORY.md` if the owner
chose it) and from what the owner says she likes, asked first (see "The conversation").

- **Palette prompt.** Audience, category and what makes the business different come from
  `POSITIONING.md`; the colours the owner likes and wants to avoid come from her answers.
  It asks for THREE different palettes, each as exactly the token table in `BRAND.md`
  (primary, accent, and six tokens each for the light and the dark theme) in hex, so the
  chosen one can be pasted back without reading.
- **Logo prompt.** Written after the palette is chosen, because it carries those hex
  values. It asks for FIVE variations of a simple vector mark (SVG), each with a
  one-colour version, each still reading at 16 px, with no text that depends on a font.
  It says what to hand back if the tool cannot draw a vector, so the owner is never stuck.
- **Handover prompt.** Written only after the owner has picked her favourite variation.
  It asks the tool for a download (handover) package of that one variation: its SVG
  files and a README saying what each file is.

Both prompts are tool-neutral: no tool name, no claim about what any tool can do.

**Intake half (code, not an LLM).** Deterministic, with tests:

- Contrast check of the returned palette against the same thresholds `a11y.spec.ts` uses
  (4.5 for text, 3 for large text and UI), in both themes, before anything is written.
  A failing pair is named; nothing is derived or "fixed" silently.
- SVG safety check, because the file comes from outside and is served from the site:
  refuse `<script>`, event attributes, `<foreignObject>` and references to other hosts.
  The mark may arrive as `.svg` files, as pasted SVG code, inside an HTML page, or in a
  zip of SVG files with a README (see D3); the check is the same for all four. A zip is
  read for its `.svg` entries only, and an entry whose path leaves the folder is refused.
- Only the variation the owner picked is checked and installed. The chosen SVG is
  installed as `public/favicon.svg` and is the master any later run starts from
  (scenario 16).
- Colour check of the mark against the chosen palette: colours outside it are listed and
  the owner decides; nothing is recoloured silently.
- A 16 px and a 32 px preview of the chosen mark for the owner to look at. Whether the
  mark is legible is the owner's call, not the script's.
- Derive the seven files from one master SVG, at the sizes the starter links, the
  maskable one with its safe zone.
- Write the tokens into `BRAND.md` and the token block of `global.css` with the same hex
  values, and point `COMPANY.logo` (and the OG card's optional `LOGO`) at the new file.

**Where the tools are named.** Only in `references/where-to-paste.md`: one line per
tool as advice ("if you use Claude, ask the assistant for the palette right here, then
take the logo to Claude Design"), a "checked on" date, nothing about what a tool does in general. See D3.

**Not in this skill:** a tagline (planned separately as `website-tagline`), the font
choice, generating raster images through an API (`image` skill), the OG card design
(`og-images`), naming the business.

## The conversation, in order

What the owner experiences, with the assistant doing the work between her steps:

1. **Do you already have a logo and brand colours?** Yes: the intake with her own files
   (scenario 2). No: go on.
2. **What kinds of colours do you like?** Which she likes, which to avoid, a brand or
   place whose colours she admires (scenario 25).
3. **Palette.** The skill writes the palette prompt (three palettes). She pastes it into
   the tool she uses, picks one, pastes the hex table back. The intake checks contrast in
   both themes and names any failing pair (scenarios 7 to 10). With Claude she can skip
   the paste: the assistant itself proposes the three palettes right in the conversation,
   and only the logo goes on to Claude Design (scenario 28).
4. **Logo.** The skill writes the logo prompt (five variations, palette inside) and tells
   her to check the tool's terms and look for a lookalike (scenario 6). She picks her
   favourite.
5. **Handover.** The skill gives her the words to ask the tool for a download package of
   that one variation, and says where to save it (scenarios 26, 27).
6. **Intake.** The skill checks the SVG for safety and colours, shows the mark at 16 and
   32 px for her to look at, then makes the seven files, writes the tokens into
   `BRAND.md` and `global.css`, and runs the site's own a11y test (scenarios 11 to 15, 21
   to 23).

## Scenarios

Written in the owner's words. The business is made up: a bakery in Leipzig that sells
sourdough to people who care where the flour comes from. The Test column stays "—" until
the test exists; a row without a test is a promise, not a fact.

| # | Given | When | Then | Test |
|---|-------|------|------|------|
| 1 | `POSITIONING.md` is filled (and `STORY.md`, if the owner chose it), and the interview has not asked about a logo or colours | the build reaches the brand step, right after positioning and before the content guide | the owner is asked once, in plain words: "Do you already have a logo and brand colours?"; the answer is recorded in the project README; if they want no help, nothing more is said | — |
| 2 | the owner answers Yes, they have them | the build goes on | no prompt is written; the skill goes straight to the intake with their files | — |
| 3 | the owner said No during the build | months later they say "I need a logo" | the skill runs on the existing site, reading its `POSITIONING.md` and `BRAND.md` | — |
| 4 | the positioning names the Leipzig bakery's audience, and the owner said she likes warm earthy colours and wants no green | the palette prompt is written | it carries the audience and those likes and dislikes, asks for three different palettes each as the `BRAND.md` token table in hex, and contains no tool name | — |
| 5 | the owner chose a palette | the logo prompt is written | it holds the chosen hex values, asks for five variations of an SVG mark, each reading at 16 px and each with a one-colour version, and says what to return if the tool cannot draw a vector | — |
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
| 20 | the owner picks variation 3 of 5 | the intake runs | only variation 3 is checked and installed; the other four are left where they are | — |
| 21 | the chosen mark uses a colour that is not in the chosen palette (the trial's tool added a second, darker brown) | the intake runs | it lists the colours it found, marks those outside the palette, and asks; it does not recolour silently | — |
| 22 | a zip arrives in `brand-handoff` holding SVG files and a README | the intake runs | it reads only the `.svg` entries, ignores the rest, refuses any entry whose path leaves the folder, lists the variations and asks which one | — |
| 23 | the owner has picked a mark | the intake runs | it shows the mark at 16 and 32 px for the owner to look at, and does not decide for them whether it is legible | — |
| 24 | `BRAND.md` does not exist yet, because the brand step runs right after positioning | the intake runs | it starts `BRAND.md` from the template and fills the palette and logo parts; the scaffold step later does not overwrite it | — |
| 25 | the build reaches the palette step and the owner has not said which colours she likes | the skill is about to write the palette prompt | it asks first: which kinds of colours she likes, which she wants to avoid, a brand or place whose colours she admires; it writes no prompt until she has answered or says "surprise me" | — |
| 26 | the owner has picked her favourite logo variation, say 3 of 5 | the conversation goes on | the skill tells her to ask the tool for a download (handover) package of that one variation, gives her the words to ask, says where to save it (the `brand-handoff` folder in the project), and waits; the intake does not run before the file is there | — |
| 27 | the owner says she saved the package but `brand-handoff` is empty | the skill goes on | it says nothing arrived there, repeats where to save it, and offers to read it from a path she names; it never searches her Downloads folder on its own | — |
| 28 | the owner's assistant is Claude | the palette step | she can ask the assistant itself for the three palettes, in the conversation, each as the `BRAND.md` token table; the intake checks them like any pasted palette (scenarios 7 to 10); the logo prompt then carries the chosen hex values to Claude Design | — |

Scenario 8 must enter through the same call the owner makes (the site's test run), not
only through the intake script's own check; the script can pass while the site's test fails.

## Decisions taken

1. **Optional, asked once, never run unasked.** The ask is an interview question right
   after positioning (and the story, if chosen), before step 3 (D5), not a pitch: "Do you already have a logo and brand colours?" Yes means the
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
6. **Five logo variations and three palettes, always** (the maintainer, 2026-10-10). The
   logo prompt asks for five, the palette prompt for three; the owner picks one of each;
   the intake works on the logo picked (scenario 20). The owner is asked what colours she
   likes before the palette prompt is written (scenario 25).
7. **The handover package is asked for after the favourite is chosen** (the maintainer,
   2026-10-10), never before: the owner asks the tool for it explicitly, in the words the
   skill gives her, and saves it in the `brand-handoff` folder of the project (scenarios
   26, 27). The skill creates the folder and adds it to the site's `.gitignore`, so the
   package is not committed. The folder name is the plan's proposal, not yet confirmed.

## Open decisions

- **D1. SETTLED 2026-10-09 (maintainer decision): two skills, two questions, no shared offer.**
  Another session planned `website-tagline` for 0.32 as well (optional, modelled on
  `website-story`, owner picks one line). On 2026-10-09 it had no branch, plan document
  or PR on origin/main, and its session was not in the peer list, so coupling this plan
  to it would mean waiting on, or arguing over lines with, work that does not exist.
  Each skill asks its own plain question (this one at step 2b, D5) and runs alone; `website-tagline`
  adds its own beside this one when it is built. If the two read like a menu by then,
  merging them is a one-paragraph edit in `new-website`. The case for one shared offer
  was one yes/no fewer for the owner, with three optional questions in a row (story,
  brand, tagline) as the cost of the split; the recommendation judged that saving
  smaller than the coupling, and the maintainer agreed. A judgment, not a measurement.
- **D2. SETTLED 2026-10-10 (maintainer decision): `sharp`, run once from the skill.**
  Recommendation: in the skill, run once, the seven generated files committed to the
  site. The starter gets no new dependency and no `npm run` step. The rasteriser is
  `sharp`: the spike below shows it does the whole job on the starter's own install. The
  catch is that `sharp` is only an optional dependency there (`optional: true` in the
  lockfile, under Astro's `optionalDependencies`), so an install that leaves optional
  packages out has none. Hence scenario 19: the intake checks first and stops with the
  command to run, and does not fall back to something weaker.
- **D3. Naming tools in `where-to-paste.md`. Answered by one trial, 2026-10-10.**
  Recommendation: yes, as advice, one file, dated. `check_model_agnostic.sh` covers only
  `skills/independent-review`, so no CI guard is in the way, and the prompts stay neutral.
  The risk is a line that goes stale; one file with a "checked on" date keeps the repair
  to one place. A tool is listed only after someone has tried it and seen what it returns.

  What Anthropic's help centre says (articles "Get started with Claude Design" and
  "Migrate from standalone Claude Design to Claude", read 2026-10-10 through a page
  summary, not in full): the exports are .zip, PDF, PPTX, standalone HTML and Google
  Slides, plus a handoff to Claude Code; no SVG or PNG export is listed and logos are not
  mentioned; it is open to the Free, Pro, Max, Team and Enterprise plans; the standalone
  site closes on 2026-12-14, after which designs live inside Claude as artifacts.

  The trial (2026-10-10; one request, from the maintainer's own Claude login, a draft of
  the logo prompt for the made-up bakery). Claude Design sits under "More", then "Design",
  in Claude's sidebar, and a new project is private ("Only you"). It drew five variations
  as TEN SVG files in the project's assets, a colour file and a one-colour file each, named
  with plain letters (the "ä" became "ae"), plus a numbered artboard ("Created 12 files").
  It said plainly that it had not looked at its own render, so legibility at 16 px was
  unchecked; and its colour versions used a second colour, a darker brown, that the
  prompt had not forbidden. The project's Export tab offered HTML, PDF and PNG and a list
  of apps to connect (Adobe, Canva, Gamma, Lovable, Miro, Replit, Vercel, v0, Base44);
  it showed no zip and no SVG, while the help page lists a zip and no PNG. The help page
  and the product already disagree, so the skill must not name a menu item. The
  maintainer reports that the handoff to Claude delivers a zip of the assets with a
  README; that was not downloaded, so the plan rests on the report, not on a look.

  What follows from it: the advice line says "ask Claude for the design", not "go to the
  Claude Design site", because that address goes away on 2026-12-14; the intake takes
  `.svg` files, pasted code, an HTML page with an inline `<svg>`, or a zip of SVG files
  (scenarios 17, 18 and 22); five logo variations always (decision 6, scenario 20); the
  intake checks the mark's colours against the palette (21) and shows the owner the mark
  at 16 and 32 px, because the tool does not (23). Still open: how an owner gets the SVG
  files out of the project in the in-Claude version, since the Export tab shows no way;
  to be confirmed with the maintainer's handoff zip.
- **D4. SETTLED 2026-10-09 (maintainer decision): log it separately.** A site that never opts in still
  links seven files it does not have, and no test says so. That is a bug in the starter,
  not in this skill. It is one row in `docs/BUGLOG.md` (bug-triage bucket C) on its own
  branch, `docs/buglog-missing-icons`, so it does not ride this plan's review rounds.
  Still open for step 2: whether the skill's own test is where a "linked icons exist"
  check belongs, and what the fix is (placeholder icons plus a test, or no links until a
  site has the files). Not fixed here.

- **D5. Where the brand step sits. SETTLED 2026-10-10 (maintainer decision).** Right after
  positioning (and the story, if chosen), before the content guide: step 2b. The
  maintainer's reason: without positioning a logo lacks direction (it still needs it, as
  before). A second reason from the files: the first section of `BRAND.md` is "Brand in one
  line", which carries "the visual feel: palette mood, one accent", so the palette should
  exist before that line is written. The content guide's voice is not needed: positioning
  and the owner's own mood words give the direction. Found while checking: the files
  disagree about who owns `BRAND.md`. The pipeline table gives it to
  `website-content-guide` (step 3), that skill says it is owned by `website-design-system`
  (step 6), and nothing says who picks the palette. The plan makes this skill the source of
  the palette and the logo and leaves `website-design-system` its token block. Cost: the
  scaffold step copies `brand.md` to `BRAND.md`, so it must not overwrite one the skill
  already started (scenario 24). Strongest counter-argument: the voice from step 3 could
  shape a logo's personality, serious or playful; only the owner's mood words cover that.

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
saying "mirror by hand"), `BRAND.md` template, `check_skill_budgets.sh` count comment,
`new-website` §3 step 4 (copy `brand.md` only if `BRAND.md` does not exist) and the
pipeline table's step 3 row (the `BRAND.md` ownership wording, D5).
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

None yet. The plan gets the Normal gate (Codex plus GLM 5.3) once the two open details in
the status table are closed; reviewing a plan whose steps still move is how it reaches
round seven. D1 to D5 are settled.

# Skill plan — closing five capability gaps

A comparison with other website kits (2026-10-03) found five things this toolkit does
not do yet. This document is the requirements record: the build order, where each step
stands, and scenarios the owner can check without reading code. Where it and the
shipped files disagree, the files win. Names of sites and people stay out of this
public repo on purpose.

## Status

Rebuild this table from `git log`, live branches and open pull requests before trusting
it; a row is only as good as its evidence.

| # | Step | State | Evidence |
|---|---|---|---|
| A1 | Checks: leftovers on the rendered site (`placeholders.spec.ts`) | built and reviewed | karero/website-builder#145, the pull request that carries this row |
| A2 | Checks: the publish gate holds on GitHub's side (`production` ruleset) | not built: needs a live probe first (decision row 2026-10-04) | — |
| A3 | Checks: deeper message checks | not built: rules not chosen (decision row 2026-10-04) | — |
| B | Proof: a test report each site can publish | scenarios only | — |
| C | Forms: contact form with a submission test | scenarios only; delivery path open (decision row 2026-10-04) | — |
| D | Import: bring an existing site under the gate | scenarios only | — |
| E | Install: one-line install, marketplace listing | blocked on the name (decision row 2026-10-04) | — |

## Build order, and why

1. **Checks (A).** Smallest, and everything else leans on it: the proof publishes the
   checks' results, and an import brings a site "under the gate". A gate with holes
   makes both worth less.
2. **Proof (B).** The gap that matters most for trust, and mostly not a building
   problem: several sites already exist, what is missing is a repeatable report and
   each owner's consent to be shown. Second because the report should show the checks
   from step 1.
3. **Forms (C).** Moved ahead of import, because an import needs it: nearly every
   existing site has a contact form, and an import that drops it loses a working
   feature.
4. **Import (D).** The largest piece. Needs A and C.
5. **Install (E).** Last only because it is blocked, not because it matters least: the
   package name depends on a rename that has not landed in this repo, and publishing
   to a registry or a marketplace is the owner's own action. Once the name is settled
   it is small, and worth pulling forward.

The strongest argument against this order: install first, because nobody benefits
from better checks in a kit they did not install, and the packaging could ship under
the current name.

## A. Checks

### A1. Leftovers on the rendered site (built)

Until now only the token `[MISSING:` was caught, and only in the source of `src/` and
`public/`. The starter's own `[BRACKET]` slots on the legal pages and in the manifest
were left to the launch checklist.

| # | Given | Then, when the tests run |
|---|---|---|
| 1 | a freshly scaffolded site, nothing filled | green; privacy page, imprint and manifest are each reported as "not ready to launch" |
| 2 | the home page says "TODO: add the prices", has "Lorem ipsum" inside a closed fold-out, and an image described as "[ALT TEXT]" | red, naming all three; a `[YOUR_API_KEY]` shown as code on the same page is left alone |
| 3 | a "[MISSING: what it offers]" sits in the site description in `src/config.ts` | found on the home page (it reaches the search-result text): red in CI, a warning on the author's own machine (rows 15 and 16) |
| 4 | the company name in the settings is still "Musterfirma GmbH" and shows up only in the structured data | red |
| 5 | the owner empties the exemption list to launch, but the legal pages are not filled | red on all three, each slot listed |
| 6 | the owner fills the privacy page and forgets the list | red: "nothing left to fill but still listed", until the entry is deleted |
| 7 | the entry is deleted | green; the privacy page is checked for good from now on |
| 8 | a German site renames `/privacy` to `/datenschutz` and forgets the list | red: the list names a page that is not checked |
| 9 | the manifest file is removed while still listed | red until the entry is deleted |
| 10 | a form field's hint says "[YOUR NAME]" and the send button is labelled "TODO" | red, naming both |
| 11 | filler text with a line break in it shows up only in the structured data | red |
| 12 | a slot is partly in bold, another is broken across two lines, "Lorem ipsum" is partly in italics | red, naming all three |
| 13 | the manifest file is damaged (not valid JSON) | red: "not checked", instead of passing as "nothing found" |
| 14 | a site scaffolded earlier, whose privacy page still has a slot that starts with a small letter; the owner fills every slot the test reports | red: the page carries a slot the test cannot see |
| 15 | an assistant lacks a fact and writes "[MISSING: year built]" on a page, on its own branch | on that machine: green, with a warning naming the placeholder, so the branch can be pushed and a draft pull request opened |
| 16 | the same branch on GitHub | red, so nothing merges until the placeholder is filled |
| 17 | a "[MISSING: …]" next to a "FIXME" on the same page | red everywhere, for the FIXME |
| 18 | "Regards, [your name]" on a finished page | red |
| 19 | "VER TODO INCLUIDO" on an English page | red: "TODO" in capitals is an author's note |
| 20 | the same words on a Spanish page | green: "todo" is an everyday word there; "TODO:" with a colon is still caught |
| 21 | a form field that says "Type your text here", and the sentence "Request a free sample copy" | green: genuine copy |
| 22 | the push check on the author's machine, pushing the branch from row 15 | lets the push through |
| 23 | the same check where CI is set | refuses |

All 23 were run on 2026-10-04 against a scratch copy of the starter, each failing or
passing for the reason in the table, plus the whole suite (61 passed, on the author's
machine and with CI set), the type check, and the German-only swap following
`_datenschutz.astro`'s own header. The test also checks itself on every run: its rules
and verdicts are pinned by example, and one test plants a leftover on each place the
reading covers, inside a real browser, next to the places that must stay out. 51
deliberate breakages of the test's own logic were each caught and named by it. Run
without exemptions against a copy of one real site built with the toolkit, the first
version found two unfilled slots on each legal page and raised no false alarm.

Rows 10 to 23 come from the review. So do three corrections:
- The starter itself served two slots that start with a small letter (the analytics
  hosting choice on the privacy page and in the German draft), which the rule could
  not see. Both now start with a capital word, and while a page is still listed the
  test fails on any slot of that shape.
- The first version failed on "[MISSING: …]" everywhere, which broke the draft flow in
  `AGENTS.md`: the push check refused the very branch a draft pull request needs.
  Rows 15, 16, 22 and 23 are the fix.
- Several rules flagged genuine copy ("TODO" in Spanish, "Type your text here" in a
  form, "sample copy"). They are narrower now; rows 19 to 21.

Known limits, on purpose:
- A target still listed at launch only produces a warning. The list empties itself as
  pages are filled, and the launch checklist requires it empty, but nothing blocks a
  launch with an entry left. **Waived by the owner on 2026-10-04 until step A2**: the
  publish step is where a hard stop can live.
- A "[MISSING: …]" only warns on the author's machine, so a direct push of `main`
  that still carries one is not refused there (CI turns red afterwards). That was so
  before this test; the hard stop belongs to the same publish step.
- The starter's own example values (the name "Example", `hello@example.com`) and the
  slots in `public/llms.txt` are not caught. Both would put one more entry on the
  exemption list from the first commit; asked as a decision row.
- The rule for slots is "an opening bracket followed by a capital letter", plus
  brackets opening with a typical slot word in small letters ("[your name]"). Genuine
  text of that shape (a "[PDF]" label, an editor's note in a quote) has to be
  allow-listed by the site. Other small-letter brackets pass on a finished page.
- Not read: pages outside the page list (the 404 page), other files in `public/`,
  PDFs, text inside images.

### A2. The publish gate holds on GitHub's side (not built)

Today a two-stage site publishes with `npm run ship`, which pushes `main` to
`production`. The pre-push hook can be skipped with `--no-verify`, and nothing on
GitHub's side checks what arrives on `production`.

| # | Given | When | Then |
|---|---|---|---|
| 1 | the rule is on, and a commit that never went through the checks | someone pushes it to `production` | GitHub refuses; the live site is unchanged |
| 2 | the rule is on, and a commit whose check is red | someone pushes it to `production` | GitHub refuses |
| 3 | `main` is green | the owner runs `npm run ship` | it publishes as before |
| 4 | the check on `main` is still running | the owner runs `npm run ship` | refused, and `ship.sh` says in plain words to wait for the green tick and run it again |
| 5 | a private repo on a free plan | the skill tries to create the rule | GitHub answers 403; the skill says plainly that this plan offers no server-side gate and what still protects the site |

Done when row 2 has been seen on a real site. The rule is a repository setting:
`website-team-setup` guides it, the site owner applies it.

Not built yet for two reasons. GitHub's exact refusal message is needed for row 4
(`ship.sh` today recognises a rejected push only in its non-fast-forward wording), and
a runbook for the live branch should not ship on documentation alone.

### A3. Deeper message checks (rules not chosen)

Candidates, each a hard test unless noted:
- Two pages share the same title or the same description.
- A content page has no positioning term at launch (today a warning).
- The home page's headline is a greeting ("Welcome", "Willkommen") instead of the offer.

## B. Proof

| # | Given | When | Then |
|---|---|---|---|
| 1 | a site whose tests are green | the owner asks for a test report | a dated report: which checks ran, on how many pages, the commit they ran on. Nothing is published |
| 2 | a red or partly skipped run | the same | the report says so; it never shows a failed run as passed |
| 3 | the owner agrees to be shown | they publish it | the report is reachable at a stable address on their site, and the toolkit's own site can link to it |

Open: which sites may be named (each owner's consent), and whether performance numbers
from PageSpeed belong in it.

## C. Forms

| # | Given | When | Then |
|---|---|---|---|
| 1 | a contact page | a visitor sends name, email and a message | they see a thank-you on the page; the owner gets the message and can reply to the visitor directly |
| 2 | an empty message or a malformed email | the visitor presses send | a clear error next to the field; nothing is sent |
| 3 | a bot fills the hidden field | it submits | it sees the same thank-you; nothing is sent |
| 4 | the mail service is down | a visitor sends | they are told it did not arrive and shown another way to reach the owner; no message is lost silently |
| 5 | a site with a form | the tests run | the privacy page must name the form and what happens to the data |

The submission test calls the function directly, as `middleware.spec.ts` does, because
`astro preview` runs no functions.

## D. Import

| # | Given | When | Then |
|---|---|---|---|
| 1 | an existing site with 12 pages | the owner says "bring my site over" | first an inventory: every address, title, description, headline, images, forms. Nothing is built yet |
| 2 | an old address that changes | the new site is built | the old address redirects to the new one, and a test checks every old address |
| 3 | the old copy | it is carried over | word for word first; what the tone and positioning checks reject is listed for the owner to decide, not rewritten silently |
| 4 | an image without a description | it is carried over | it gets a "[MISSING: …]" placeholder, which the gate then holds back |

Done when the imported site passes the whole suite with every old address accounted for.

## E. Install

| # | Given | When | Then |
|---|---|---|---|
| 1 | Claude Code, nothing installed | the user adds the plugin with one command | all skills are available, no clone and no script |
| 2 | no assistant-specific setup | the user runs the `npm create` command | the skills are installed and the first step is explained |

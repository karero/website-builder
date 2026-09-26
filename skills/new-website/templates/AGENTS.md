# AGENTS.md — rules for AI assistants (Codex, Claude Code) working on this site

Website of [SITE_NAME]. Astro, static, GitHub → Cloudflare Pages.
Live: [LIVE_URL] · Preview: [PREVIEW_URL]

<!-- Scaffold note (delete after filling): new-website fills the [BRACKET] slots at
     scaffold time — SITE_NAME, LIVE_URL, PREVIEW_URL (two-stage: main.<project>.pages.dev;
     single-stage: "pull-request previews only, <branch>.<project>.pages.dev"),
     TITLE_SUFFIX + SUFFIX_LENGTH + TITLE_MAX in §6, and keeps ONE publish-model block
     in §2. §5 ships with single-owner defaults; website-team-setup rewrites it
     (collaborators, rights level, merge rule, who publishes). Owner writes in another
     language? Translate this file in-session, keep every rule, keep the commands
     verbatim — and if you translate the placeholder token "[MISSING: …]" (§2, §4),
     change the grep pattern in .github/workflows/ci.yml to the same word, or the CI
     gate never fires. CLAUDE.md imports this file, so Codex and Claude Code follow
     the same rules. -->

Several people and several AI assistants may work on this site, sometimes at the same
time. The rules below stop anyone from working on a stale state or overwriting someone
else's work. If a rule is unclear or does not fit the situation: ask, do not improvise.

## 1. At the start of EVERY session: get the latest state (mandatory)

Before you change any file:

1. `git status`: are there unsaved changes? Then **stop**. Tell the person which files
   are affected and ask what should happen to them. Discard nothing, overwrite nothing.
2. Fetch the newest state from GitHub and show what is new since the last sync:
   ```bash
   old=$(git rev-parse -q --verify origin/main)
   git fetch origin
   git log --format='%h %an, %ar: %s' ${old:+$old..}origin/main -n 20
   ```
   If Codex asks whether `git fetch` may use the network: allow it (it cannot work
   without).
3. Tell the person in plain words **what is new** (who changed what). If nothing is
   new: say so.
4. Then, depending on the task. If it is unclear which case applies: ask.
   - **New task:** own branch straight from the newest GitHub state. Do not use the
     local `main` branch. Any short branch name works; `content/` is the convention
     for content work, `setup/` for settings.
     ```bash
     git switch --no-track -c content/<short-name> origin/main
     ```
   - **Continuing a started branch** (e.g. an open pull request): stay on that branch.
     If it is linked to GitHub (`git rev-parse --abbrev-ref @{u}` works), update it with
     `git pull --ff-only`. If that does not work but the branch may already be on
     GitHub: stop and ask which GitHub branch is meant.
     Then check what `main` has gained meanwhile that is missing here:
     `git log --oneline HEAD..origin/main` and `git diff --stat HEAD...origin/main`.
     Tell the person. Do not mix `main` in unasked (no `merge`, no `rebase`).
5. If a git command from these steps fails (no network, conflict, branch already
   exists, …): **stop** and say so clearly. Never carry on with a stale state without
   the person knowing. Never `--force`, never `reset --hard`, never delete anything to
   get past an error.

**Codex in the cloud (in the browser) is its own case.** Every task starts with a fresh
copy from GitHub (the branch the person selected in Codex, normally `main`). Step 1
applies there; instead of steps 2 to 4, only this:

- Run `git log -1 --format='%h %an, %ar: %s'` and say: "Current working state of this
  task." A cloud task normally starts from a clone GitHub made moments ago, but
  nothing here proves that. So, if the task may use the network, compare the full
  commit ids of the branch you are on (not `main` — a task may start on any branch):
  ```bash
  git rev-parse HEAD
  git ls-remote origin "refs/heads/$(git rev-parse --abbrev-ref HEAD)"   # reads only
  ```
  Same id: say the state is current. Different: say GitHub has moved on and that a
  new task gets the newest state. Network off: say the comparison was not possible.
- If an **older** cloud task is being resumed, say: "Whether GitHub has moved on since
  is not checked. For the newest state, start a new task."
- Fetch nothing, create or switch no branch. Codex works on this state; Codex creates
  the branch and the pull request when the person presses "Create PR". If GitHub has
  meanwhile received overlapping changes, GitHub shows that in the pull request.
- Any git error: stop, as in step 5.

## 2. How work happens

- **Never push directly to `main` on GitHub.** Every change arrives as a pull request.
  This rule binds the assistant from day one. On a single-owner site the owner may
  still push to `main` themselves as `PUBLISHING.md` describes; once
  `website-team-setup` has run it binds everyone, and GitHub or the pre-push hook
  rejects a direct push.
  - Locally (Codex or Claude Code on your own computer): every task on its own branch
    (see 1.4), then `git push -u origin content/<short-name>` and open the pull request
    on GitHub.
  - Codex in the cloud: the person creates the pull request with the "Create PR"
    button (see the cloud case in §1).
  - If `"[MISSING: …]"` placeholders are still in it: open the pull request as a
    **draft** and list the places in the description.
- **Merging on GitHub:** a pull request may be merged, with the "Merge pull request"
  button on GitHub, only when
  - the automatic checks on GitHub are green (green tick on the pull request; while
    they run: wait; red: do not merge, report it instead),
  - no `"[MISSING: …]"` placeholder is left (CI greps `src/` and `public/` for it and
    turns red) and the pull request is not a draft,
  - and the person pressing the button may do so per the merge rule in §5 (default:
    the author merges their own pull request; other people's only after asking).

  The assistant never merges; the person does that on GitHub.
- **Preview before merging:** once the repo is connected to Cloudflare by git
  integration (`website-team-setup` §6 does that), every pull request gets its own
  preview address from Cloudflare, listed under the pull request's checks. Look at the
  change there before merging. Until then (a site deployed by token and `wrangler
  pages deploy`, see `PUBLISHING.md`) there is no pull-request preview: check locally
  with `npm run dev`.
- **What a merge means** depends on the publish model of this site. Both blocks
  assume the git integration above; on a token-deployed site a merge publishes
  nothing until someone runs the deploy command from `PUBLISHING.md`.

  <!-- PUBLISH MODEL: keep ONE of the two blocks below, delete the other. -->

  **Two-stage (main = preview, production = live).** A merge into `main` rebuilds
  the preview [PREVIEW_URL] within a few minutes. Nothing reaches [LIVE_URL] until
  someone runs `npm run ship`, which publishes `main` to `production` and verifies the
  live site serves the new build. Who may run it is set in §5. The assistant never
  runs `npm run ship` unasked, and always says whether an address is the preview or
  the live site (see `PUBLISHING.md`).

  **Single-stage (merge = online).** Cloudflare rebuilds the live site from `main`
  after every merge (takes a few minutes). Whether the new state is there is shown by
  [LIVE_URL]/build.txt (must show the commit id of the merge). Because a merge
  publishes, the merge conditions above are the only gate: a red check or a leftover
  placeholder must never be merged.

- Before the pull request: `npm ci` (installs the exact packages, also when
  `package-lock.json` changed), then `npm run check`, `npm run build` and
  `npx playwright test`. Everything must be green. Do not work around or disable red
  tests; report them. If the environment cannot run the tests (e.g. no browser
  installed): say so, do not claim "green".
- Change only what the task asks for. Nothing "on the side".

## 3. Where the content lives

- Pages: `src/pages/<slug>.astro`, each using the `Base` layout with a `title` and a
  `description`. Site-wide facts (name, URL, legal name, analytics) live in
  `src/config.ts`; only the URL is also in `astro.config.mjs` (`site:`), keep the two
  equal.
- If the site has content collections (blog posts, projects, events, …): one folder per
  entry under `src/content/<collection>/`, images next to the entry. Which fields exist
  and which are mandatory is defined in `src/content.config.ts`. Take an existing entry
  as the model; do not invent fields.
- Images: WebP or AVIF, sized to how they are displayed, every image with an `alt`
  text (see `website-design-system` in the bundled skills).
- Texts and voice: `CONTENT_GUIDE.md` and `BRAND.md` are the source of truth for how the
  site speaks; `POSITIONING.md` for what it says.
- Adding, renaming or deleting pages or entries: checklist in §6.

## 4. Texts

- Language of the site: the one set in `src/config.ts` (`SITE.locale`). Plain, calm,
  concrete. No marketing filler.
- **Invent nothing.** Use only facts the person gives or that are already on the site.
  If something is missing (a number, a year, a material, a name), write a placeholder
  and ask, **always in quotes** (in frontmatter an unquoted `[…]` breaks the build):
  `value: "[MISSING: year built]"`.
  Placeholders must not go live; see the draft rule in §2.
- Forbidden (the test `tests/tone.spec.ts` rejects it): the long dash (—), buzzwords
  and typical AI filler phrases, and in English any contraction. The full,
  language-specific list is in `tests/tone.spec.ts`; read it before writing copy.
  House style beyond the test: one form of address per site (German: du or Sie,
  never mixed).
- **Alt text (`alt`):** describes the image factually for people who cannot see it.
- **Meta description:** 140 to 160 characters (the test allows 120 to 160), says what
  the page offers and for whom.

## 5. Who may change what

<!-- website-team-setup rewrites the four lines below (collaborators, rights level,
     merge rule, who publishes). Until a team forms, these single-owner defaults apply
     unchanged — they are not placeholders. -->

Collaborators on GitHub: none yet; the owner works alone.

Rights level of collaborators: everything (the owner's own level; see the table).

Merge rule: the author merges their own pull request once §2's conditions hold; other
people's pull requests only after asking.

Publishing live (`npm run ship`, two-stage sites only): the owner.

| Level | Collaborators may change |
|---|---|
| **content** | texts, images, entries in content collections, `public/llms.txt`, `CONTENT_GUIDE.md`, plus the §6 edits an entry needs (`PAGES` in `tests/_helpers.ts`, the share-card list, `llms.txt`) |
| **content + design** | additionally navigation, components, layouts, styles, existing pages, `src/config.ts`, `BRAND.md` |
| **everything** | everything the owner may change: also new pages, tests, scripts, CI, settings |

For everyone, the owner included:
- Only change what was asked for; do not "tidy up".
- Describe in the pull request, in plain words, what changes visibly and on which
  pages.
- Tests may be **extended** (e.g. a new page in `PAGES`). Never weaken, delete or
  disable a test just to get green. If a test fails: fix the cause or report it.
- Changes to `.github/`, `scripts/`, `functions/`, `public/_headers`,
  `astro.config.mjs`, `package.json` or `AGENTS.md` affect tests, the server or
  publishing. Say so explicitly in the pull request.

## 6. Checklist: new page or new entry

The tests compare the site with `PAGES` in `tests/_helpers.ts` and with
`public/llms.txt`, check that every page is linked from somewhere, and that it has its
own share card (a few pages are exempt, listed in `tests/seo.spec.ts`). Order, the
share-card list and redirects are checked by no test; work through the steps below
completely. Addresses always without accents or umlauts and without a trailing `/`
(`/about-us`, not `/About-Us/`).

The layout appends "[TITLE_SUFFIX]" ([SUFFIX_LENGTH] characters) to every page title
except the home page, and the total may be at most 60. So a page `title` is at most
**[TITLE_MAX] characters**.

**New page** (e.g. `/pricing`):
1. Create `src/pages/pricing.astro` with `Base`, like the other pages. `title` at most
   [TITLE_MAX] characters, `description` 140 to 160 characters (test: 120 to 160).
2. Link the page from somewhere, usually the navigation. A page without a link fails a
   test.
3. Add the address to `PAGES` in `tests/_helpers.ts`.
4. Add a line to `public/llms.txt` in the style of the others.
5. Share card: add the page to `PAGES` in `scripts/generate_og_cards.py`, run
   `npm run og` (needs Python with Pillow), and pass `image="/images/og/pricing.jpg"`
   to `Base` on the page. If `npm run og` does not work because Python or Pillow is
   missing: say so and ask.

**New entry in a content collection** (e.g. a project or a post):
1. Folder or file under `src/content/<collection>/`, modelled on an existing entry.
   Mandatory fields: `src/content.config.ts`. The entry's title is the page title:
   at most [TITLE_MAX] characters.
2. If the collection has a hand-kept order (a list in `src/config.ts` or similar):
   add the entry at the wanted position.
3. Add the entry's address to `PAGES` in `tests/_helpers.ts`.
4. Add a line to `public/llms.txt`.
5. Share card as in step 5 above.

**Renaming or deleting a page or entry:**
1. First rename or delete the file (`src/pages/<name>.astro`) or the entry folder;
   the address comes from it.
2. Search the whole project for the old address and the old name
   (`grep -rn "old-name" src public scripts tests`) and fix every hit: links, `PAGES`,
   order lists, `llms.txt`, the share-card list, image imports.
3. When renaming, run `npm run og` again and commit the new share card.
4. Point internal links straight at the new address; a test rejects links that only
   work through a redirect.
5. Redirect the old address in `public/_redirects` (create the file if it does not
   exist; when deleting, point at a fitting existing page): `/old-address /new-address
   301`, so links from outside do not break. Existing redirects that point at the old
   address: change them to the new one.

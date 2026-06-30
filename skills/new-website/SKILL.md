---
name: new-website
description: >
  Orchestrates building a NEW website end-to-end, from insights to launch-ready
  and handoff-ready. Self-contained: it runs the stack decision interview,
  sequences the website-* skills + existing marketing skills in order, and
  scaffolds the project from its own templates/ (Astro starter overlay +
  a11y/seo/navigation/anchors/orphans/images/tone/positioning/email/links test suite + GDPR privacy page draft +
  setup + permission allowlist),
  copying the website-* skills + the three SEO-depth skills (ai-seo,
  schema-markup, seo-audit) + site-architecture + the marketing skills it
  delegates to (customer-research, copywriting, image) + outgoing-link-audit +
  internal-link-audit + website-permissions + search-console-setup INTO the project's skills dir
  (`.claude/skills`, or `.agents/skills` for a Codex install — see `$PROJECT_SKILLS_DIR`)
  so the repo is self-contained for a third party. Default stack Astro → GitHub → Cloudflare
  Pages. Use at the very start of any new site. Trigger phrases: "new website",
  "start a new site", "scaffold a website", "spin up a site", "build a new
  website", "set up a new web project", "website starter", "which stack for this site".
---

# New website — orchestrator

The entry point for every new site you build. It **decides the stack**,
**sequences the work**, and **scaffolds a self-contained, handoff-ready repo** from
this skill's `templates/`. Concrete content/SEO/design/QA work is delegated to seven
sibling skills + existing global skills.

Everything needed is bundled here:
- `templates/astro/` — the Astro starter overlay (Base.astro SEO+theme spine,
  `config.ts`, theme tokens, `astro.config`, `tests/` suite, CI, preview-noindex
  function, headers, llms.txt, GDPR privacy page draft). Its `README.md` is the
  assembly manual.
- `templates/SETUP.md` — accounts (GitHub + Cloudflare) + tools + the bootstrap.
- `templates/PUBLISHING.md` — plain-English "how to publish" for the owner
  (`commit`/`push`/`branch` explained + step-by-step per publish model).
- `templates/.gitignore`, `templates/claude/settings.json` — git ignore + the
  permission allowlist to copy into the repo.
- `templates/positioning.md`, `templates/content-guide.md`, `templates/brand.md` — the per-site docs.
- `references/WEBSITE_ARCHITECTURE.md` (bundled with this skill) — the Cloudflare
  **tier 1/2/3** decision tree + limits (the tiers are also summarized in §1, question 2).

Sibling skills (run in order, each usable on its own):
`website-positioning` · `website-content-guide` · `website-seo-geo` ·
`website-design-system` · `website-testimonials` · `website-qa` ·
`website-review`. Plus `outgoing-link-audit` — the pre-launch / monthly external-link
liveness sweep (only relevant once the site links out); `internal-link-audit` — the
internal-linking sweep that finds orphaned + thin pages and suggests where to cross-link
(run after adding a batch of pages); `website-permissions` — install + safely extend the
repo's permission allowlist (fewer prompts, same guardrails); and `search-console-setup`
— post-launch GSC + Bing registration + IndexNow.

## 1. Decision interview (answer before any code)

Default house stack: **Astro (static) → GitHub → Cloudflare Pages**. Six questions
decide everything downstream — ask them in order, offer the examples so a
non-expert can answer, and record the answers in the project `README.md`.

1. **Pages + content types — what does the sitemap look like?**
   *Decides: plain pages vs Content Collections.*
   - A handful of fixed pages (home, services, about, contact, imprint — ≤ ~15)
     → plain `.astro` pages. Example: a small-business brochure site.
   - Anything that repeats with the same shape — blog posts, events, case
     studies, team members → Astro **Content Collections** (one schema, one
     template, n entries) + the `Base` layout. Example: an event archive where
     every event has date/speaker/location.
   - Mixing both is normal: flat pages + one collection.

2. **Any dynamic/backend behaviour — what must a server actually do?**
   *Decides: the Cloudflare tier. Pick the LOWEST tier that fits — going higher
   is the classic mistake. Tier tree + limits: `references/WEBSITE_ARCHITECTURE.md`.*
   - Visitors only read; contact is `mailto:` or a form service → **Tier 1
     static** (~90% of sites).
   - Exactly one small server task — a form that emails you, site search,
     hiding a third-party API key, one live widget (e.g. a next-event box fed
     by an API) → **Tier 2** (one Pages Function or server island).
   - State per user — accounts/login, a database, checkout, user-generated
     content → **Tier 3** (SSR + D1). Rare; challenge the requirement first.

3. **Who edits content after launch?**
   *Decides: CMS or not.*
   - The owner/Claude editing files in git → **no CMS** (default; markdown +
     redeploy is the workflow).
   - A non-technical person (client, co-organizer writing posts) →
     **Keystatic** (git-based, no separate backend). Can be added later —
     don't install it speculatively. When chosen, run **`keystatic-setup`**
     (local mode; the GitHub cloud-mode upgrade is documented there).

4. **One language or several?**
   *Decides: i18n routing from day 1 or never.*
   - One language (German-only counts) → skip i18n entirely.
   - Two+ **at launch** (e.g. a DE+EN consultancy site) → run
     **`astro-i18n-setup`** (Astro i18n: clean default locale + prefixed others,
     self-referencing hreflang + `x-default`, sitemap alternates, language switcher,
     per-locale test harness).
   - **Multilingual, but building one language first?** Fine — keep the default locale
     **unprefixed** from day 1, ship/test the primary language, then run
     **`astro-i18n-setup`** to add the second locale when translations are ready. Because
     the default stays at `/`, that's additive, not a breaking retrofit (skill →
     *Phased rollout*).
   - "Maybe English someday" → treat as one language now; the unprefixed default keeps a
     future second locale additive. **The only costly change is later moving the default
     off `/`** (e.g. `/` → `/en/`).

5. **Analytics — will anyone act on the numbers? (optional)**
   - Just "is anyone visiting?" → **Google Search Console** alone (free, no
     script, no consent banner) is enough for search & referral traffic.
   - Real decisions from traffic data (campaigns, content strategy) →
     **Plausible** (cookieless, privacy-friendly, no consent banner needed).
     If you run a **self-hosted** Plausible instance, point at it; otherwise
     recommend the **paid cloud version** (from **€9/mo** —
     https://plausible.io/#pricing) so the client runs no server.
   - Prefer cookieless tools over Google Analytics, which would pull in a
     cookie-consent banner. Any analytics script is gated to the production
     branch only. The privacy page must match whatever is chosen here.

6. **Domain + how do changes go live? (publish model)**
   *Decides: the publish workflow — a safety-vs-simplicity trade-off. **Offer both, explain
   them, let the owner choose**; recommend two-stage. Record the choice in the README.*
   - New domain or subdomain of an existing site? (Affects canonical URLs and whether
     existing SEO authority carries over.) DNS moves to Cloudflare.
   - **Two-stage — recommended (default).** `main` is an **unlisted, noindexed preview**
     (`*.pages.dev` — noindexed, but public-by-URL, not access-controlled); `production` is
     the **live** site. The owner pushes to `main`, checks
     the preview link, then runs **`npm run ship`** to publish. A mistake never reaches the
     live domain. *Scaffold adds:* the `production` branch, the `_middleware.ts` noindex
     guard, and the `ship` script.
   - **Single-stage — simplest.** One branch — `main` is live, so every push goes straight
     to the public site. Fewer moving parts, no safety net. Pick this only for a low-stakes
     site whose owner is fine with "save = instantly public." **Note:** the `_middleware.ts`
     noindex guard de-indexes every `*.pages.dev` host, so a single-stage site is invisible
     to Google until a **custom domain** is attached — say this when recommending it.
   - **Don't assume git fluency.** Whichever they choose, hand them
     `templates/PUBLISHING.md` (plain-English `commit` / `push` / `branch` + the exact
     step-by-step to publish) and walk the **first** publish through with them.

Plain hand-written HTML (static `.html` files, no build step) is a legacy anti-pattern — use Astro.

## 2. The pipeline (the order to use the skills)

| # | Step | Skill / source |
|---|---|---|
| 1 | Insights: ICP, voice-of-customer, competitor scan | `customer-research` |
| 2 | Positioning: what you offer, for whom, market category → `POSITIONING.md` (Dunford) | **`website-positioning`** |
| 3 | Tone of Voice, EEAT, page inventory → `CONTENT_GUIDE.md` + `BRAND.md` | **`website-content-guide`** |
| 4 | Pages, clean URLs, nav, internal links | `site-architecture` |
| 5 | Decision interview + scaffold the repo | **this skill** §1, §3 |
| 6 | Build: mobile graphics, dark mode, theme tokens | **`website-design-system`** |
| 6 | Build: head metadata within limits, schema, llms.txt | **`website-seo-geo`** (+ `schema-markup`, `ai-seo`) |
| 6 | Build: per-page OG share cards (`npm run og` → 1200×630 ≤300 KB, tested) | **`og-images`** |
| 6 | Build: testimonials / Review schema from one data file (if the site has quotes) | **`website-testimonials`** |
| 7 | QA: a11y (light+dark) / seo / navigation / anchors / orphans / images / tone / positioning / email / links | **`website-qa`** |
| 8 | Performance: Lighthouse / PageSpeed for FCP & LCP | **`website-qa`** perf section (+ `seo-audit`) |
| 9 | **Double-Knuth review** (correctness + cross-file consistency) | **`website-review`** |
| 10 | Outgoing-link liveness sweep — **only if the site links out** (see §3a) | **`outgoing-link-audit`** |
| 10b | Internal-link sweep — orphaned + thin pages (run if the site grew past a handful of pages) | **`internal-link-audit`** |
| 11 | Launch & handoff: schema/sitemap/robots, deploy, hand over | **this skill** §4 |
| 12 | Post-launch: register with Google Search Console + Bing, submit sitemap, enable IndexNow | **`search-console-setup`** |

Work out **positioning** (step 2) *before* any content or SEO — it decides what the
copy is even trying to say. Build the Content Guide (step 3) *before* writing page
copy; positioning and voice are inputs to everything downstream, not an afterthought.

The build is **test-driven, not test-after**: the suite is green from commit 1,
and steps 6–7 run as a loop per page (red → green → commit, see §3 step 5 and
`website-qa` §1b). Step 7 in the table is the *final full-suite gate*, not the
first time tests run.

## 3. Scaffold the project (handoff-ready)

**Prerequisites (one-time).** Walk the user through `templates/SETUP.md` if needed —
Node/git/gh/wrangler + image tools, a **private GitHub** account, a **Cloudflare**
account (both 2FA). The accounts are a human action the agent cannot do.

Assemble the project at `<site>/` so it travels without any global setup:

0. **Git first, before any code:**
   ```bash
   # Resolve where the suite is installed (the cp SOURCE). Per tool:
   #   ~/.claude/skills = Claude Code · ~/.agents/skills = Codex · ~/.gemini/config/skills = Antigravity
   # Honour an explicit $SKILLS_ROOT; else auto-detect in priority order
   # Claude Code → Antigravity → Codex (Claude is the default/primary). On a machine with
   # more than one installed, set it yourself — e.g. `export SKILLS_ROOT=~/.agents/skills`
   # (Codex) or `~/.gemini/config/skills` (Antigravity); Antigravity workspace installs use
   # `export SKILLS_ROOT="$PWD/.agents/skills"`.
   if [ -z "${SKILLS_ROOT:-}" ]; then
     SKILLS_ROOT="$HOME/.claude/skills"
     for d in "$HOME/.claude/skills" "$HOME/.gemini/config/skills" "$HOME/.agents/skills"; do
       [ -d "$d/new-website" ] && SKILLS_ROOT="$d" && break
     done
   fi
   # Where bundled skills go IN the generated project (the cp DESTINATION). Claude default
   # (.claude/skills). Codex and Antigravity read repo-scoped skills from .agents/skills, so
   # derive that when the suite was installed through either of them. Force it with:
   # export PROJECT_SKILLS_DIR=.agents/skills
   if [ -z "${PROJECT_SKILLS_DIR:-}" ]; then
     case "$SKILLS_ROOT" in
       "$HOME/.agents/skills"*|"$HOME/.gemini/config/skills"*|*/.agents/skills*) PROJECT_SKILLS_DIR=".agents/skills" ;;
       *) PROJECT_SKILLS_DIR=".claude/skills" ;;
     esac
   fi
   mkdir <site> && cd <site> && git init
   cp "$SKILLS_ROOT"/new-website/templates/.gitignore .
   git add .gitignore && git commit -m "chore: init repo with .gitignore"
   ```
1. **Scaffold + overlay:** `npm create astro@latest .` (Empty, TS strict), then copy
   the `templates/astro/` overlay (`src/`, `tests/`, `public/`, `functions/`,
   `scripts/`, `.github/`, `.nvmrc`, root configs — see `templates/astro/README.md`
   for exact steps and npm deps). Set the real domain in `astro.config.mjs` (`site:`)
   and `src/config.ts`. **Astro 6 needs Node ≥22.12** — the overlay's `.nvmrc` pins
   22 for local + Cloudflare Pages builds.
2. **Permissions.** Copy the setup guide into the project (all tools), then — **Claude Code
   only** — copy the allowlist so routine `npm`/`astro`/`playwright`/`git commit` calls don't
   prompt (it still asks for `rm -rf`, `git push --force`, `wrangler … delete`, `gh repo delete`):
   ```bash
   cp "$SKILLS_ROOT"/new-website/templates/SETUP.md .          # all tools — receiving party can set up too
   cp "$SKILLS_ROOT"/new-website/templates/PUBLISHING.md .     # plain-English "how to publish" for the owner
   # Claude Code only:
   mkdir -p .claude
   cp "$SKILLS_ROOT"/new-website/templates/claude/settings.json .claude/settings.json
   ```
   *Codex / Antigravity: skip the `.claude/settings.json` copy — it's Claude Code-specific.
   Use their own approval systems instead (Codex: `AGENTS.md` + Codex rules/config;
   Antigravity: its sandbox approval model).* For Claude's allow/deny model and how to extend
   it safely when a prompt keeps recurring, use **`website-permissions`**.
3. **Skills travel with the repo** — copy the eighteen always-on skills in, plus any
   conditional setup skills selected by the interview, so the handoffs resolve for the
   receiving party. The always-on set is the seven
   `website-*` siblings, the three SEO-depth skills they delegate to —
   `ai-seo`, `schema-markup`, `seo-audit` — `site-architecture` (IA), the three
   marketing skills the pipeline delegates to — `customer-research`, `copywriting`,
   `image` — plus `outgoing-link-audit` (external link sweep), `internal-link-audit`
   (orphan/thin-page sweep), `og-images` (per-page share cards),
   `website-permissions` (allowlist),
   and `search-console-setup` (post-launch GSC/Bing/IndexNow):
   ```bash
   mkdir -p "$PROJECT_SKILLS_DIR"
   cp -R "$SKILLS_ROOT"/website-positioning \
         "$SKILLS_ROOT"/website-content-guide \
         "$SKILLS_ROOT"/website-seo-geo \
         "$SKILLS_ROOT"/website-design-system \
         "$SKILLS_ROOT"/website-testimonials \
         "$SKILLS_ROOT"/website-qa \
         "$SKILLS_ROOT"/website-review \
         "$SKILLS_ROOT"/ai-seo \
         "$SKILLS_ROOT"/schema-markup \
         "$SKILLS_ROOT"/seo-audit \
         "$SKILLS_ROOT"/site-architecture \
         "$SKILLS_ROOT"/customer-research \
         "$SKILLS_ROOT"/copywriting \
         "$SKILLS_ROOT"/image \
         "$SKILLS_ROOT"/outgoing-link-audit \
         "$SKILLS_ROOT"/internal-link-audit \
         "$SKILLS_ROOT"/og-images \
         "$SKILLS_ROOT"/website-permissions \
         "$SKILLS_ROOT"/search-console-setup \
         "$PROJECT_SKILLS_DIR"/
   ```
   The global copies stay the updateable source of truth; the project copies are
   the frozen handoff set.

   **Conditional setup skills** — run the matching line ONLY when the interview
   selected it (they don't ship with a single-locale, CMS-free site):
   ```bash
   # If Q3 = "non-technical editor" (Keystatic):
   cp -R "$SKILLS_ROOT"/keystatic-setup "$PROJECT_SKILLS_DIR"/
   # If Q4 = "2+ languages at launch":
   cp -R "$SKILLS_ROOT"/astro-i18n-setup "$PROJECT_SKILLS_DIR"/
   ```
4. **Docs** — copy `templates/positioning.md` → `POSITIONING.md`,
   `templates/content-guide.md` → `CONTENT_GUIDE.md` and `templates/brand.md` →
   `BRAND.md`; fill the `[BRACKET]` slots in pipeline steps 2–3.
5. **Confirm green:** `npm run build && npm test` (the overlay passes the
   a11y/seo/navigation/anchors/orphans/images/tone/positioning/email/links suite out of the box). Then build pages
   test-first: add the route to `tests/_helpers.ts` `PAGES` *before* writing the
   page (suite goes red), build until green, commit. New features get their test
   first too — `website-qa` §1b maps feature → test.

## 3a. Outgoing-link sweep — ask, but only if the site links out

The offline `tests/links.spec.ts` guard ships in the suite and runs in CI from commit
1 — nothing to decide there. The **liveness** sweep (`outgoing-link-audit`) is
network-dependent and optional, so gate it on whether the built site actually has
external links, and let the user choose:

```bash
cd "$(git rev-parse --show-toplevel)"
[ -d dist ] || npm run build >/dev/null
SITE_HOST=$(grep -oE "site:[[:space:]]*['\"]https?://[^'\"]+" astro.config.mjs \
  | sed -E "s#.*://(www\.)?##; s#/.*##" | head -1)
EXT=$(grep -rhoE '<a [^>]*href="https?://[^"]+"' dist --include='*.html' \
  | grep -oE 'href="https?://[^"]+"' | sed -E 's/^href="//; s/"$//' \
  | grep -vE "://(www\.)?${SITE_HOST}(/|$|:)" | sort -u | wc -l | tr -d ' ')
```

- **`EXT` is 0** → the site links only to itself. Say so and **skip silently** — do
  not ask.
- **`EXT` ≥ 1** → ask whether to run the liveness sweep now — use a structured
  user-input tool if the platform offers one (Claude Code's **`AskUserQuestion`**),
  otherwise just ask in chat — e.g. *"The site has N outgoing links. Run the `outgoing-link-audit` liveness
  sweep before launch? (fetches each third-party URL; ~a few seconds each)"* — options
  **Run it now (recommended)** / **Skip — I'll run it monthly**. If they say run it,
  invoke the `outgoing-link-audit` skill; otherwise note it as a monthly follow-up.

## 4. Launch & handoff checklist

- [ ] All QA green: `npm test`.
- [ ] **Double-Knuth review clean** (`website-review`): both passes — run it as the final
      gate AND after adding the last page.
- [ ] Lighthouse / PageSpeed run; FCP & LCP within target (see `website-qa`).
- [ ] **Outgoing links healthy** (`outgoing-link-audit`) — only if the site links out
      (§3a). No DEAD/REBRAND left unhandled; any retired domain added to
      `tests/links.spec.ts` `STALE_DOMAINS`.
- [ ] **No orphaned pages** — `tests/orphans.spec.ts` green (every page reachable from
      home). For a multi-page site, run `internal-link-audit` and resolve orphans + thin
      pages; deliberately-unlinked pages listed in `ORPHAN_EXEMPT` with a reason.
- [ ] `sitemap-index.xml` present; `robots.txt` + `llms.txt` accurate.
- [ ] Required schema validates (Rich Results / schema.org validator).
- [ ] **OG share cards** generated (`npm run og`, the `og-images` skill): a 1200×630
      JPEG **≤300 KB** per page (`public/images/og/`), each page wiring `image=` (or the
      default). `tests/seo.spec.ts` enforces size/dimensions; WhatsApp drops previews over
      ~300 KB. Plus favicon/manifest icon set in place.
- [ ] Imprint/legal + privacy pages present (EEAT trust + DE legal requirement).
      The starter ships a GDPR privacy draft (`src/pages/privacy.astro`): every
      `[BRACKET]` slot filled, the analytics section matching the real setup,
      German-market sites translated to German. The imprint stays site-specific.
- [ ] Deployed to Cloudflare Pages per the chosen **publish model** (§1 Q6).
      **Two-stage:** create the live branch (`git checkout -b production && git push -u
      origin production && git checkout main` — end back on `main`), then in Cloudflare set
      *Production branch* = `production` — so
      `main` = noindexed preview, `production` = live; analytics fires on production only.
      **Single-stage:** `main` = live (default Cloudflare production branch).
      **Creating the Pages project + first deploy** (the step a Cloudflare newcomer
      struggles with) — offer the bootstrap options in
      `references/CLOUDFLARE_FIRST_DEPLOY.md`: recommend the **token-assisted** path for
      owners new to Cloudflare (least-privilege, expiring token; you run Wrangler), with
      git-integration (push-to-deploy, no token) and browser/manual as the other offered paths.
      Either way: hand the owner `PUBLISHING.md` and walk the **first** publish with them.
- [ ] **Search engines notified** (`search-console-setup`): live domain added to Google
      Search Console (Domain property + DNS TXT) and Bing (import from GSC),
      `sitemap-index.xml` submitted to both, and **IndexNow on** (Cloudflare Crawler
      Hints toggle). Register the production domain only — never a preview host.
- [ ] Repo self-contained for the receiving party: `.gitignore`, `.claude/`,
      `POSITIONING.md`, `CONTENT_GUIDE.md`, `BRAND.md`, `tests/`, `SETUP.md`, and a `README.md` with
      the decision answers + "how to add a page / run tests / deploy".

### Always say whether it's PREVIEW or LIVE (two-stage)
A non-technical owner cannot tell a preview URL from the live site. So **every time** you
push to `main` (or they do), state it explicitly — never let a preview read as live:

> ✅ Your changes are on the **preview**: `https://main.<project>.pages.dev` — **this is NOT
> live yet.** When it looks right, run `npm run ship` to publish to `<live-domain>`.

Only after `npm run ship` (or the merge into `production`) **and** the Cloudflare production
build finishes is it actually live at `<live-domain>` — confirm that separately ("✅ now
live at …"). On a **single-stage** site there is no preview: say plainly that the push **is
going live now**.

**Which URL to quote.** Prefer the **memorable `pages.dev` alias** — the branch alias
`main.<project>.pages.dev` (or the project alias `<project>.pages.dev`) — over the random
per-deploy hash URL `<hash>.<project>.pages.dev`. The hash URL is ugly but **immutable**, so
keep it as a **backup**: when an alias looks **stale** (cache/propagation lag, or it's still
serving an older build), the hash URL pins the exact fresh deployment and confirms the new
build is up. Whichever you quote, **open it and confirm it loads** rather than reporting it
blind — and note it for the project. (A `pages.dev` URL is also the signal you deployed to
**Pages**, not a Worker — see `references/CLOUDFLARE_FIRST_DEPLOY.md`.)

## Notes

- Do not rebuild what existing skills cover — GEO depth → `ai-seo`; technical-SEO/
  Core-Web-Vitals → `seo-audit`; JSON-LD → `schema-markup`; IA → `site-architecture`;
  research → `customer-research`; copy → `copywriting`; images → `image`.
- After any code/copy edit, re-run `website-qa`. "Done" means the tests are green,
  not that the file was written.
- Run **`website-review`** (the Double-Knuth two-pass audit) at the **end of a build**
  (pre-launch) and **after adding/editing a page** — it's the cross-file consistency gate
  on top of `website-qa`'s tests (a new route can silently break `PAGES`, nav, the sitemap,
  internal links or canonical).
- **Editing the skill suite itself** (these templates, the test specs, or a sibling
  skill) is different from reviewing a site: green tests do not catch doc↔test drift,
  so run `/code-review` before trusting the change. The Double-Knuth pass that hardened
  this suite found exactly that class of issue.

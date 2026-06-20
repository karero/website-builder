# website-builder

**Build a fast, mobile-friendly, SEO-ready website with help from an AI coding assistant.**

website-builder is an open-source skill suite for **Claude Code**, **OpenAI Codex**, and
**Google Antigravity**. It turns a short brief into a complete website — content, mobile-first
responsive design, SEO, accessibility checks, schema markup, tests, and launch support — on a
modern, privacy-friendly stack (Astro → GitHub → Cloudflare Pages).

You can use it even if you're not deeply technical. Whether you're a founder, a community
organiser, a solo builder, a small team, or a developer, **the easiest way to start is to
let your AI assistant guide you step by step.**

> 🧭 **Never opened a terminal before?** Start with the gentle walkthrough in
> [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md).

## What it helps you build

Real sites people ship with it:

- event and community sites
- startup landing pages
- expert / personal profiles
- resource hubs
- small studio or agency websites

It's **not** a hosted no-code website builder. You own the code, the repository, and the
domain — there's no platform you're locked into, and no hosted-builder subscription required
to keep a basic static site online. (Your domain registration and your AI tool may still have
their own costs.)

## You don't do this alone

At any point — setup, building, or launch — just ask your AI assistant to **guide you in
plain language**. It will:

- check what you already have installed,
- explain what each step does before doing it,
- install any missing tools **only when they're needed** (always asking first), and
- run the commands for you, with your approval.

If you ever feel lost, you can literally type *"what does this do?"* and it will explain.

## The easiest way to start

1. **Install one AI assistant** — [Claude Code](https://code.claude.com/docs/en/setup)
   (recommended), or Google Antigravity, or OpenAI Codex.
2. **Open it** and paste the prompt below.
3. **Answer its questions.** That's it — it handles the rest.

**Copy-paste starter prompt:**

> I want to use the website-builder skill suite (https://github.com/karero/website-builder)
> to create a new website. Please guide me step by step in plain language.
> First, check which required tools this computer already has.
> Explain every command before you run it, and install missing tools only when they're
> actually needed. Then install the website-builder skills, tell me when to restart or
> reopen you so the skills load, and continue from there — starting a fresh site by running
> `new website` in a new, empty folder.

You don't have to memorise any of this — the assistant runs the real commands for you. (If
you'd rather type the commands yourself, see [Manual install](#manual-install--technical-reference)
below.)

## What you need

- an **AI coding assistant** — Claude Code, OpenAI Codex, or Google Antigravity
- a **GitHub account** (free) to store your site's code
- a **computer** where you can run basic commands (macOS, Linux, or Windows)
- *optionally*, a **Cloudflare account** (free) when you're ready to publish

You **don't** need to install Node, git, the GitHub CLI, image tools, or anything else
upfront — the assistant checks for those and helps you install them only when the moment
comes.

## What happens next

Once you run `new website`, the assistant will:

1. Ask what kind of website you want to build.
2. Help shape its positioning and structure.
3. Create the website (Astro).
4. Draft your pages and content.
5. Add SEO metadata, schema markup, and accessibility checks.
6. Run tests and quality gates.
7. Help you prepare the site for launch.

---

## Manual install & technical reference

*If you already know your way around a terminal, here are the exact commands. Everything
below is also what the AI assistant runs on your behalf.*

This repository is the **single source of truth** for the website-builder skill suite — an
orchestrated set of agent skills that build a new website end-to-end (insights →
positioning → content → SEO/GEO → design → QA → review → launch), on the house stack
**Astro → GitHub → Cloudflare Pages**.

Developed and used with **Claude Code**. It also works with **Google Antigravity** and
**OpenAI Codex** — the skills are plain `SKILL.md` files, so any of the three can run the
same suite (see the per-tool notes below).

It replaces the previous arrangement where the suite lived in three hand-synced copies
(`~/.claude/skills/`, a de-personalized `_new-site/` package, and a hand-built zip), which
constantly drifted. Now there is one canonical copy here; the global install is **derived**
from it.

### Quick start — build your first site

You need [Claude Code](https://code.claude.com/docs/en/setup) (a paid Claude plan or a
Console/API account). Then, **four steps**:

```bash
# 1. Get the files, then cd into the folder — unzip the handoff zip, OR clone the repo:
unzip website-builder.zip && cd website-builder
#   from source instead:  git clone https://github.com/karero/website-builder.git && cd website-builder

# 2. From that folder, install the skills globally. Claude only loads skills from
#    ~/.claude/skills/, so this one command is the whole setup — no copying by hand.
./scripts/install.sh          # symlinks every skill into ~/.claude/skills/ (idempotent)
                              # macOS/Linux/WSL/Git-Bash. Or: make install
```

```
# 3. Restart Claude Code so it discovers the new skills.

# 4. Open Claude Code in a FRESH, EMPTY folder for your new site, and say:
       new website
```

The `new-website` orchestrator takes over from there: it runs the stack-decision
interview, scaffolds a git-first repo (Astro overlay + test suite + permission
allowlist), then sequences the sibling skills through **positioning → content → SEO/GEO
→ design → QA → review → launch**. It also walks you through the one-time build tools
(Node, git, `gh`, `wrangler`, image tools) the first time you actually build.

> **Updating later:** if you cloned, `git pull` updates every skill at once — the global
> copies are symlinks, not copies, so there's nothing to re-install. From a zip, re-run
> `./scripts/install.sh` in a newer unzipped copy.
>
> **Windows:** run `./scripts/install.sh` from **Git Bash** or **WSL**, or copy
> `skills\*` into `%USERPROFILE%\.claude\skills\` with PowerShell
> (`Copy-Item -Recurse -Force .\skills\* "$env:USERPROFILE\.claude\skills\"`).

### Using with Google Antigravity

This suite is **100% compatible** with Google Antigravity, which natively understands the
`SKILL.md` format and can orchestrate the whole pipeline (it can even run skills like
`customer-research` or `seo-audit` as asynchronous subagents). Install the skills into your
global config, then type `new website` in chat:

```bash
mkdir -p ~/.gemini/config/skills && cp -R skills/* ~/.gemini/config/skills/
```

See [docs/ANTIGRAVITY.md](docs/ANTIGRAVITY.md) for install options and the minor
permission differences, and [docs/ANTIGRAVITY-TEST.md](docs/ANTIGRAVITY-TEST.md) for a
step-by-step compatibility checklist.

### Using with OpenAI Codex

Codex runs the same suite through a thin adaptation layer — `skills/*` stays the single
source of truth. Install, restart Codex, and say `new website` (or `$new-website`):

```bash
./scripts/install-codex.sh        # symlinks skills/* into ~/.agents/skills/  (or: make install-codex)
```

See [docs/CODEX.md](docs/CODEX.md) for the clone/zip install, usage, and the differences
from Claude Code, and [docs/CODEX-TEST.md](docs/CODEX-TEST.md) for a step-by-step
compatibility checklist.

### Layout

```
skills/            the suite skills (canonical)
  new-website/     orchestrator + templates/ (Astro starter overlay + test suite) +
                   references/WEBSITE_ARCHITECTURE.md (hosting-tier 1/2/3 decision doc,
                   the companion to the orchestrator's stack-decision interview)
  website-*        siblings (run in order): positioning (the strategic spine — what you
                   offer, for whom, what category; worked out FIRST, enforced by
                   positioning.spec.ts), content-guide, design-system, seo-geo,
                   testimonials, qa, review, permissions
  ai-seo, schema-markup, seo-audit, site-architecture, customer-research,
  copywriting, image, outgoing-link-audit, search-console-setup   (bundled deps)
  astro-i18n-setup, keystatic-setup   (opt-in setup skills — see below)
scripts/
  install.sh       symlink skills/* into ~/.claude/skills/ (Claude Code)
  install-codex.sh symlink skills/* into ~/.agents/skills/ (OpenAI Codex)
  package.sh       build dist/website-builder.zip for handoff (+ verify its contents)
  check_clean.sh   scan skills/ + root docs for names / contact info / credentials (make check)
docs/
  ANTIGRAVITY.md   using the suite with Google Antigravity
  CODEX.md         using the suite with OpenAI Codex
```

### Opt-in setup skills

Two skills are **not** part of the default build — the orchestrator pulls them in only when
the decision interview calls for them:

- **`astro-i18n-setup`** — turnkey multi-language: Astro i18n routing (clean default locale
  + prefixed others), self-referencing hreflang + `x-default`, sitemap alternates, a language
  switcher, and per-locale test harness. Use it for a **two-language launch**, or for a
  **phased rollout** where the primary language ships first and a secondary prefixed locale is
  added later while default URLs stay unchanged. (The costly retrofit is moving the default
  locale off `/`; adding a secondary locale is additive.) Triggered by interview Q4.
- **`keystatic-setup`** — adds **Keystatic**, a git-based CMS (by the Keystone team), so a
  non-technical person edits content through a UI while the data stays as Markdown in the
  repo. Wires **local mode** by default (edit via the dev server, commit to git) and
  documents the optional upgrade to **GitHub mode** for in-browser editing (commits straight
  to the repo, no dev server). Run at scaffold time when interview Q3 = *a non-technical
  person edits content*; don't install speculatively.

Because they're opt-in, the standard scaffold is unchanged — a site with one language and a
developer-edited repo never touches either.

### Use it locally

```bash
make install         # symlink every skill into ~/.claude/skills/  (Claude Code, idempotent)
make install-codex   # symlink every skill into ~/.agents/skills/   (OpenAI Codex)
```

Edit a skill once, here, and the change is live everywhere (the global location is a
symlink, not a copy). Restart your session to pick up new/renamed skills.

### Hand it off

```bash
make package     # → dist/website-builder.zip  (runs `make check` first)
```

A recipient unzips it and runs `scripts/install.sh` (Claude Code),
`scripts/install-codex.sh` (Codex), or copies `skills/*` into their tool's skills root
(Antigravity → `~/.gemini/config/skills/`). The repo is the thing you share — by clone or by zip.

### Stay generic (no names, no secrets)

The suite is a handoff artifact, so it must carry **no personal names, contact info, or
credentials**.

```bash
make check       # scans skills/ + root docs for PII + secrets; fails on any hit
```

`scripts/check_clean.sh` runs a denylist (owner / sites / org / home paths) plus generic
catches (any real email, credential/token formats, secret-looking assignments). It runs in
CI on every push/PR (`.github/workflows/clean.yml`) and is a prerequisite of `make package`,
so a personalized build cannot ship. A genuine false positive is fixed by tightening a
pattern in the script — never by loosening it.

## License & credits

MIT — see [LICENSE](LICENSE). Seven bundled skills (`ai-seo`, `seo-audit`,
`schema-markup`, `site-architecture`, `copywriting`, `customer-research`, `image`) are
derived from [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills)
(MIT, © 2025 Corey Haines); their notice is in
[THIRD-PARTY-LICENSES.md](THIRD-PARTY-LICENSES.md). Everything else is original to this
project.

# website-builder

The **single source of truth** for the website-builder skill suite — an orchestrated
set of Claude skills that build a new website end-to-end (insights → positioning →
content → SEO/GEO → design → QA → review → launch), on the house stack
**Astro → GitHub → Cloudflare Pages**.

Replaces the previous arrangement where the suite lived in three hand-synced copies
(`~/.claude/skills/`, a de-personalized `_new-site/` package, and a hand-built zip),
which constantly drifted. Now there is one canonical copy here; the global install is
**derived** from it.

## Quick start — build your first site

You need [Claude Code](https://code.claude.com/docs/en/setup) (a paid Claude plan or a
Console/API account). Then, **three steps**:

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

## Layout

```
skills/            the 18 suite skills (canonical)
  new-website/     orchestrator + templates/ (Astro starter overlay + test suite) +
                   references/WEBSITE_ARCHITECTURE.md (hosting-tier 1/2/3 decision doc,
                   the companion to the orchestrator's stack-decision interview)
  website-*        siblings (run in order): positioning (the strategic spine — what you
                   offer, for whom, what category; worked out FIRST, enforced by
                   positioning.spec.ts), content-guide, design-system, seo-geo,
                   testimonials, qa, review, permissions
  ai-seo, schema-markup, seo-audit, site-architecture, customer-research,
  copywriting, image, outgoing-link-audit, search-console-setup   (bundled deps)
scripts/
  install.sh       symlink skills/* into ~/.claude/skills/ (so Claude loads them)
  package.sh       build dist/website-builder.zip for handoff (+ verify its contents)
  check_clean.sh   scan skills/ + root docs for names / contact info / credentials (make check)
```

## Use it locally

```bash
make install     # symlink every skill into ~/.claude/skills/ (idempotent)
```

Edit a skill once, here, and the change is live everywhere (the global location is a
symlink, not a copy). Restart your Claude session to pick up new/renamed skills.

## Hand it off

```bash
make package     # → dist/website-builder.zip  (runs `make check` first)
```

A recipient unzips it and runs `scripts/install.sh` (or copies `skills/*` into their
`~/.claude/skills/`). The repo is the thing you share — by clone or by zip.

## Stay generic (no names, no secrets)

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

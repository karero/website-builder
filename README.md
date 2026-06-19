# website-builder

The **single source of truth** for the website-builder skill suite — an orchestrated
set of agent skills that build a new website end-to-end (insights → positioning →
content → SEO/GEO → design → QA → review → launch), on the house stack
**Astro → GitHub → Cloudflare Pages**.

Developed and used with **Claude Code**. It also works with **Google Antigravity** and
**OpenAI Codex** — the skills are plain `SKILL.md` files, so any of the three can run the
same suite (see the per-tool notes right below the quick start).

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

## Layout

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
scripts/
  install.sh       symlink skills/* into ~/.claude/skills/ (Claude Code)
  install-codex.sh symlink skills/* into ~/.agents/skills/ (OpenAI Codex)
  package.sh       build dist/website-builder.zip for handoff (+ verify its contents)
  check_clean.sh   scan skills/ + root docs for names / contact info / credentials (make check)
docs/
  ANTIGRAVITY.md   using the suite with Google Antigravity
  CODEX.md         using the suite with OpenAI Codex
```

## Use it locally

```bash
make install         # symlink every skill into ~/.claude/skills/  (Claude Code, idempotent)
make install-codex   # symlink every skill into ~/.agents/skills/   (OpenAI Codex)
```

Edit a skill once, here, and the change is live everywhere (the global location is a
symlink, not a copy). Restart your session to pick up new/renamed skills.

## Hand it off

```bash
make package     # → dist/website-builder.zip  (runs `make check` first)
```

A recipient unzips it and runs `scripts/install.sh` (Claude Code),
`scripts/install-codex.sh` (Codex), or copies `skills/*` into their tool's skills root
(Antigravity → `~/.gemini/config/skills/`). The repo is the thing you share — by clone or by zip.

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

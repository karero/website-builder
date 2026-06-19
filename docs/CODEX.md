# Using website-builder with OpenAI Codex

The `website-builder` skill suite was developed and used with Claude Code, but the skills
are plain Markdown (`SKILL.md` + templates), so Codex can run the same suite through a
small adaptation layer. **`skills/*` stays the single source of truth** — nothing is
duplicated for Codex.

> Want to verify it works on your setup? Run through [CODEX-TEST.md](CODEX-TEST.md) — a step-by-step compatibility checklist with a report-back template.

## Install

**From a clone:**
```bash
git clone https://github.com/karero/website-builder.git
cd website-builder
./scripts/install-codex.sh
```

**From the handoff zip** (after unzipping, from the extracted folder):
```bash
./scripts/install-codex.sh
```

What it does: symlinks `skills/*` into `~/.agents/skills/` (the equivalent of
`make install-codex`). Re-running just refreshes the links.

## Use

Restart Codex, open it in a **fresh, empty** folder for your new site, and say:

```text
new website
```

or invoke the orchestrator explicitly:

```text
$new-website
```

Codex runs the stack-decision interview, scaffolds the `templates/astro` overlay, and
sequences the rest of the `website-*` skills.

> **On a machine that also has Claude Code or Antigravity installed,** the scaffold's
> auto-detect prefers them over Codex (order: Claude Code → Antigravity → Codex). Force
> Codex's copy first:
> ```bash
> export SKILLS_ROOT="$HOME/.agents/skills"
> ```

## Differences from Claude Code

- Codex reads user skills from **`~/.agents/skills`**, not `~/.claude/skills`. The
  installer above handles this; the `new-website` scaffold resolves the right source via
  `$SKILLS_ROOT`, so it works regardless of which tool installed the suite.
- Codex can also read **repo-scoped** skills from `.agents/skills` within a project.
- `templates/claude/settings.json` is Claude Code-specific (its command-allowlist model).
  For Codex, use **`AGENTS.md`** for durable project instructions and Codex's own
  rules/config for command-approval policy. The bundled `website-permissions` skill is a
  no-op for Codex.
- Project-bundled skills are copied into `.claude/skills/` by default (so a Claude
  recipient is self-contained). The scaffold derives `$PROJECT_SKILLS_DIR` automatically —
  if the suite was installed through Codex (`$SKILLS_ROOT` = `~/.agents/skills`), generated
  projects bundle into `.agents/skills/` instead, so they're Codex-self-contained. Force it
  with `export PROJECT_SKILLS_DIR=.agents/skills` for a **Codex-only handoff**.

## Scope

This is intentionally a thin, direct skill install — not a Codex plugin. That's enough
for local use. A plugin (marketplace metadata, icons, MCP/app integration) would only be
worth it for app-directory distribution or team sharing later.

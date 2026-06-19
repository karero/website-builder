# Testing website-builder with OpenAI Codex

A validation checklist to confirm the suite runs end-to-end under **OpenAI Codex**.
For normal install/usage, see [CODEX.md](CODEX.md). This doc lists what was adapted, gives
a step-by-step test, and ends with a report-back template.

## What was adapted for Codex

- `scripts/install-codex.sh` (+ `make install-codex`) symlinks `skills/*` into
  `~/.agents/skills` — the mirror of `install.sh` (which targets `~/.claude/skills`).
- **The `new-website` scaffold no longer hardcodes `~/.claude/skills`.** Its cp-block now
  resolves a `$SKILLS_ROOT` variable that auto-detects your skills root (it checks
  `~/.claude/skills`, `~/.agents/skills`, `~/.gemini/config/skills`) — so the template and
  sibling-skill copies work under Codex. You can also force it:
  `export SKILLS_ROOT=~/.agents/skills`.
- `docs/CODEX.md` added (install + the differences from Claude Code).
- **No skill content was duplicated** — `skills/*` stays the single source of truth.

## Test checklist

### 1. Install
```bash
./scripts/install-codex.sh            # or: make install-codex
ls ~/.agents/skills                   # expect 18 symlinks, incl. new-website
```
**Expected:** 18 entries, each a symlink back into this repo's `skills/`.

### 2. Skill discovery
Restart Codex, then confirm it sees `new-website` and the `website-*` siblings as user
skills (from `~/.agents/skills`). Repo-scoped `.agents/skills` also works if you prefer
project-local install.
**Expected:** `new-website` is discoverable.

### 3. `$SKILLS_ROOT` resolution self-test
This is the exact logic the scaffold runs. On a machine that ALSO has Claude Code, force
Codex's path first:
```bash
export SKILLS_ROOT=~/.agents/skills           # only needed if ~/.claude/skills also exists
if [ -z "${SKILLS_ROOT:-}" ]; then
  SKILLS_ROOT="$HOME/.claude/skills"
  for d in "$HOME/.claude/skills" "$HOME/.gemini/config/skills" "$HOME/.agents/skills"; do
    [ -d "$d/new-website" ] && SKILLS_ROOT="$d" && break
  done
fi
echo "$SKILLS_ROOT"                   # expect: .../.agents/skills
```
**Expected:** prints your `~/.agents/skills`.

### 4. Trigger the orchestrator
In a **fresh, empty** folder, say `new website` — or invoke it explicitly: `$new-website`.
**Expected:** the stack-decision interview starts.

### 5. Scaffold copies resolve
Let the orchestrator run the scaffold (steps 0–3). Watch the `cp "$SKILLS_ROOT"/…`
commands.
**Expected:** `.gitignore`, `SETUP.md`, and the 17 sibling skills copy into the new project
with **no "No such file or directory"** errors.

### 5b. Generated project is Codex-self-contained
The scaffold derives `$PROJECT_SKILLS_DIR` from `$SKILLS_ROOT`. If you installed via Codex
(`$SKILLS_ROOT` = `~/.agents/skills`), the bundled skills should land in **`.agents/skills/`**
(not `.claude/skills/`), so the generated project works in Codex without renaming. To force
it regardless: `export PROJECT_SKILLS_DIR=.agents/skills` before scaffolding.
```bash
ls .agents/skills        # expect the 17 bundled sibling skills
```
**Expected:** `.agents/skills/` exists with the bundled skills. (The Claude-only
`.claude/settings.json` step is skipped for Codex — see docs/CODEX.md.)

### 6. (Optional) build the generated site
```bash
npm install && npm run build && npm test
```
**Expected:** green (the bundled Playwright gate: a11y, seo, positioning, etc.).

### 7. Approvals sanity
Confirm `templates/claude/settings.json` is ignored (it's Claude's allowlist model). For
Codex, durable project instructions belong in `AGENTS.md`, and command approval is governed
by Codex's own rules/config. `website-permissions` is a harmless no-op.

## Report back

```
Codex version:
1. Install (18 symlinks):          PASS / FAIL —
2. Discovery (sees new-website):   PASS / FAIL —
3. $SKILLS_ROOT resolved to:       __________
4. "new website" / $new-website:   PASS / FAIL —
5. Scaffold cp paths (no errors):  PASS / FAIL —
6. Generated site build + tests:   PASS / FAIL —
Anything that needed manual fixing:
```

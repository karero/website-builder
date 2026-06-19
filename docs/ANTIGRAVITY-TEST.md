# Testing website-builder with Google Antigravity

A validation checklist to confirm the suite runs end-to-end under **Google Antigravity**.
For normal install/usage, see [ANTIGRAVITY.md](ANTIGRAVITY.md). This doc lists what was
adapted, gives a step-by-step test, and ends with a report-back template.

## What was adapted for Antigravity

- README documents Antigravity as a first-class tool (install into `~/.gemini/config/skills`).
- **The `new-website` scaffold no longer hardcodes `~/.claude/skills`.** Its cp-block now
  resolves a `$SKILLS_ROOT` variable that auto-detects your skills root (it checks
  `~/.claude/skills`, `~/.agents/skills`, `~/.gemini/config/skills`) — so the template and
  sibling-skill copies work under Antigravity. You can also force it:
  `export SKILLS_ROOT=~/.gemini/config/skills`.
- `docs/ANTIGRAVITY.md` added (install options + permission differences).
- **No skill content was duplicated** — `skills/*` stays the single source of truth.

## Test checklist

### 1. Install
```bash
mkdir -p ~/.gemini/config/skills && cp -R skills/* ~/.gemini/config/skills/
ls ~/.gemini/config/skills            # expect 18 skill folders, incl. new-website
```
**Expected:** 18 entries.

### 2. Skill discovery
Restart/refresh Antigravity, then confirm it recognizes `new-website` and the `website-*`
siblings.
**Expected:** `new-website` is discoverable.

### 3. `$SKILLS_ROOT` resolution self-test
This is the exact logic the scaffold runs. On a machine that ALSO has Claude Code, force
Antigravity's path first:
```bash
export SKILLS_ROOT=~/.gemini/config/skills    # only needed if ~/.claude/skills also exists
if [ -z "${SKILLS_ROOT:-}" ]; then
  SKILLS_ROOT="$HOME/.claude/skills"
  for d in "$HOME/.claude/skills" "$HOME/.gemini/config/skills" "$HOME/.agents/skills"; do
    [ -d "$d/new-website" ] && SKILLS_ROOT="$d" && break
  done
fi
echo "$SKILLS_ROOT"                   # expect: .../.gemini/config/skills
```
**Expected:** prints your `~/.gemini/config/skills`.

> The loop's `~/.agents/skills` entry is **Codex's** location, and `~/.gemini/config/skills`
> is Antigravity's **global** install. If you used the **workspace** install (Option B in
> [ANTIGRAVITY.md](ANTIGRAVITY.md)), the skills live in the project's `.agents/skills` —
> point the scaffold at it with `export SKILLS_ROOT="$PWD/.agents/skills"`.

### 4. Trigger the orchestrator
In a **fresh, empty** folder, say `new website` (or "I want to build a new website").
**Expected:** the stack-decision interview starts.

### 5. Scaffold copies resolve
Let the orchestrator run the scaffold (steps 0–3). Watch the `cp "$SKILLS_ROOT"/…`
commands.
**Expected:** `.gitignore`, `.claude/settings.json`, `SETUP.md`, and the 17 sibling skills
copy into the new project with **no "No such file or directory"** errors.

### 6. (Optional) build the generated site
```bash
npm install && npm run build && npm test
```
**Expected:** green (the bundled Playwright gate: a11y, seo, positioning, etc.).

### 7. Permissions sanity
Confirm Antigravity ignores `templates/claude/settings.json` (it uses its sandbox/approval
model) and that `website-permissions` is a harmless no-op.

## Report back

```
Antigravity version:
1. Install (18 folders):           PASS / FAIL —
2. Discovery (sees new-website):   PASS / FAIL —
3. $SKILLS_ROOT resolved to:       __________
4. "new website" starts interview: PASS / FAIL —
5. Scaffold cp paths (no errors):  PASS / FAIL —
6. Generated site build + tests:   PASS / FAIL —
7. Subagents (async research/seo): YES / NO
Anything that needed manual fixing:
```

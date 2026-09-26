# Skill plan — `AGENTS.md` in every scaffold + `website-team-setup`

> **Status 2026-09-26: BUILT** in the same change as this plan — shipped as
> `skills/new-website/templates/AGENTS.md` + `templates/CLAUDE.md` (building block 1)
> and `skills/website-team-setup/` (building block 2). This document is the
> requirements record, written as scenarios the owner can check without reading code,
> plus the review trail. Where it and the shipped files disagree, the files win.

Distilled from one client site that went from a single owner working with an AI
assistant to a three-person team working with Codex (browser and local) and Claude
Code on the same repo, on the same day. Everything below was hit, decided, or fixed
there; names, accounts and site details stay out of this public repo on purpose.

## Two building blocks, not one skill

- **Building block 1 — `AGENTS.md` ships with every new site.** The working rules
  (fetch the latest state first, pull request instead of a direct push, when a merge
  is allowed, never invent facts, the new-page checklist) are useful even when one
  person works alone with Codex or Claude. So the template goes into `new-website`'s
  scaffold, next to `SETUP.md` and `PUBLISHING.md`, with a `CLAUDE.md` that imports it
  so Codex and Claude Code read the same rules.
- **Building block 2 — `website-team-setup`, run only when needed.** Inviting
  collaborators, the repository settings, checking that CI really starts on its own,
  the block against direct pushes to `main`, the Cloudflare connection with its traps,
  the rights level in `AGENTS.md`, and a short guide for the collaborators. A single
  owner never needs it; a team runs it once.

Owner decisions taken before building (2026-09-26): two building blocks — yes. Who may
publish live (`npm run ship`) — the template does not decide; `website-team-setup` asks
the owner at setup time, with "owner only" offered as the safer default.

## Scenarios (acceptance criteria)

Read each as: **situation → what the rules or the skill do**. "Assistant" means Codex or
Claude Code following `AGENTS.md`.

### A. `AGENTS.md` in a fresh scaffold (building block 1)

- **A1 — Single owner, fresh scaffold.** The owner runs `new-website`. → The repo
  contains `AGENTS.md` and a `CLAUDE.md` that reads `@AGENTS.md`. The site-specific
  slots are filled at scaffold time: site name, live URL, preview URL, the title
  suffix the layout appends and the resulting maximum page-title length, and the
  publish model chosen in interview question 6. No `[BRACKET]` slot is left in the
  working rules.
- **A2 — Session start, local checkout, nothing new.** A collaborator opens the
  assistant in their clone. → Before touching a file, the assistant runs `git status`,
  fetches, reports "nothing new since last time", and starts a new branch from
  `origin/main` (never works on the local `main`).
- **A3 — Session start, local checkout, someone else merged meanwhile.** Same as A2,
  but a teammate merged two pull requests since. → The assistant lists who changed what,
  in plain words, before doing anything else.
- **A4 — Session start with unsaved changes.** `git status` shows modified files. →
  The assistant stops, names the files, and asks what to do with them. It discards
  nothing.
- **A5 — Continuing an open pull request.** The task is "carry on with the menu
  change from yesterday". → The assistant stays on that branch, pulls it fast-forward
  only, reports what `main` has gained meanwhile that this branch lacks, and does not
  merge or rebase `main` into it unasked.
- **A6 — Codex in the browser (cloud).** The task starts from a fresh clone GitHub
  made a minute ago. → The assistant names the commit it is on, fetches nothing, creates
  no branch, and works on that state; the owner presses "Create PR". If an older cloud
  task is resumed, it says that GitHub may have moved on and that a fresh task gets the
  newest state.
- **A7 — A git command fails** (no network, conflict, branch exists). → The assistant
  stops and says so. Never `--force`, never `reset --hard`, never deletes anything to get
  past an error.
- **A8 — Direct push to `main`.** The assistant is asked to "just push it to main". →
  It refuses that route and opens a pull request instead. After building block 2, the
  push is also rejected: by GitHub where a ruleset exists, otherwise by the pre-push hook
  in every clone that ran `npm install`.
- **A9 — Merge conditions.** A collaborator's pull request is green, has no
  placeholders, and is not a draft. → They may merge it themselves on GitHub. Red or
  still running: wait, and report red instead of merging. Someone else's pull request:
  only after asking. The assistant never merges.
- **A10 — A missing fact.** Copy needs a year the owner did not supply. → The assistant
  writes a quoted placeholder such as `"[MISSING: year built]"` instead of inventing one,
  opens the pull request as a draft, and lists the placeholders in the description. A
  placeholder never goes live.
- **A11 — Two-stage site, merge is not live.** The site uses `main` = preview,
  `production` = live. → `AGENTS.md` says a merge updates the preview only, that
  `npm run ship` publishes, and who may run it (see scenario B8).
- **A12 — Single-stage site, merge is live.** The site publishes from `main`. →
  `AGENTS.md` says a merge is online within minutes, names the address that shows which
  commit is live (`/build.txt`), and says to check the pull request's own preview link
  before merging.
- **A13 — New page checklist.** A collaborator adds `/pricing`. → The checklist covers
  the page file with the `Base` layout, the title length limit that fits the suffix,
  the description length, a link from somewhere, the route in `tests/_helpers.ts`, the
  `llms.txt` line, and the share card. Renaming or deleting also covers the search for
  the old address, the redirect, and no internal link that goes through a redirect.
- **A14 — Tests going red.** A change makes a test fail. → Fix the cause or report it.
  Tests may be extended, never weakened, deleted or disabled to get green.
- **A15 — Files that affect everyone.** A pull request touches `.github/`, `scripts/`,
  `functions/`, `public/_headers`, `astro.config.mjs`, `package.json` or `AGENTS.md`.
  → The pull request description says so explicitly.
- **A16 — Owner writes in another language.** The owner's language is not English. →
  The assistant translates `AGENTS.md` and `CLAUDE.md` in-session, like
  `PUBLISHING.md`, keeping every rule (the checklist commands stay verbatim).

### B. `website-team-setup` (building block 2)

- **B1 — Trigger.** The owner says "my colleague will work on the site too" or
  "set up the team". → The skill runs; it is never part of the default scaffold path.
- **B2 — Invite collaborators.** The owner names two GitHub accounts. → The skill
  invites them with write access, says the invitation has to be accepted by email, and
  waits for confirmation before assuming they can push.
- **B3 — Repository settings.** → "Always suggest updating pull request branches" is on
  (the "Update branch" button appears on every pull request that is behind `main`),
  and head branches are deleted automatically after a merge. Both are set with one
  `gh repo edit` and shown in the dashboard path as a fallback.
- **B4 — CI that never started.** The workflow file has been on `main` for weeks but
  the Actions tab shows no run. → The skill checks Actions permissions, checks whether
  the workflow is listed as disabled, starts it once by hand (the template's
  `workflow_dispatch`), then proves the triggers with a throwaway pull request from an
  empty commit, and closes that pull request and deletes its branch afterwards. Only
  after a `pull_request` run is visible does it call CI "working". The root cause of
  the original silence was not pinned down; the skill says so and does not claim to
  prevent it.
- **B5 — Block direct pushes to `main`, paid plan or public repo.** → A ruleset on the
  default branch: pull request required, the CI job required to pass, no force pushes,
  no deletion. Applied to the owner too.
- **B6 — Block direct pushes to `main`, private repo on a free plan.** The ruleset
  request is refused with an upgrade message. → The skill falls back to enabling the
  pre-push hook block that ships commented out in `scripts/hooks/pre-push`, says plainly
  that this is a local convention that a clone without `npm install`, `--no-verify` or
  a different clone bypasses, and records that in `AGENTS.md`.
- **B7 — Cloudflare, connect the repo.** → The skill steers to the **Pages** flow, not
  the Workers form the dashboard now leads to first; warns that a Worker created by
  mistake leaves a "Workers Builds" check on every pull request until its build
  connection is removed, and gives the check to prove it is gone (a throwaway pull
  request opened after connecting shows only the CI check and the Cloudflare Pages
  preview check); warns that a Pages project name is global across
  all Cloudflare accounts, so the obvious name may be taken and a shorter one still
  works; sets the production branch to match the publish model; and notes that each
  pull request gets its own preview address in its checks.
- **B8 — Rights, merge rule and publish rights.** → The skill asks and writes the
  answers into `AGENTS.md` §5: the rights level for collaborators (content only; content
  and design; everything the owner may change), the merge rule (default: the author
  merges their own green pull request; alternative: the owner merges everything) and,
  on a two-stage site, who may run `npm run ship` (owner only, offered as the default;
  or every collaborator).
- **B9 — Collaborator guide.** → A short `TEAM-GUIDE.md` is added: what to install for
  local Codex or Claude Code, or how to start a Codex cloud task from the repo; the four
  moves per task (start, branch, pull request, merge); who to ask. Translated in-session
  for a non-English team, like `PUBLISHING.md`.
- **B10 — Second person opens a pull request while the first one merges.** → Their
  branch is behind `main`; GitHub shows "Update branch" (B3). They press it, CI runs
  again, then they merge. If both touched the same lines, GitHub shows a conflict and
  the rules say ask, do not guess.
- **B11 — Nothing client-specific leaks.** → `make check` (the clean scan) passes
  **with the maintainer's local name denylist present** (a fresh clone or CI skips that
  part and only runs the generic checks); the skill and templates contain no personal
  names, accounts, emails or client URLs.
- **B12 — Re-run is safe.** The skill runs a second time. → Every step is idempotent:
  existing collaborators are reported, settings already on stay on, a ruleset that
  exists is not duplicated, the hook block is not enabled twice.

## Out of scope (deliberately)

- Server-side branch protection on a private free-plan repo (GitHub does not offer it;
  B6 is the honest fallback).
- Cloudflare Access on the preview (the preview stays public-by-URL, as `PUBLISHING.md`
  says).
- Changing `ship.sh` or the pre-push hook themselves; the skill only enables the block
  that already ships.

## Review trail

**Round 1 — fresh-eyes seat** (Claude sub-agent, no shared context, same model family;
2026-09-26, on the first commit of the branch). It verified the template claims first
(job id, hook block, exemption names, tone rules, REST shapes, `gh` flags — all held),
then returned **3 BUG / 8 RISK / 7 NIT**. All fixed in the second commit:

| Sev | Finding | Fix |
|---|---|---|
| BUG | The push-block verification (`git push origin main` on a no-op) can never fail: git hands the hook nothing and sends GitHub nothing | Hook: `git push --dry-run origin HEAD:main` from a scratch commit. Ruleset: read `rules/branches/main` back |
| BUG | `gh run watch` without a run id fails non-interactively; the dispatched run does not exist for a few seconds | Resolve the run id from `gh run list` after a short wait, then watch it |
| BUG | The client's name appeared in scenario B11 of this plan | Reworded; note that the clean scan's name denylist is local-only |
| RISK | `[RIGHTS_LEVEL]` and `[SHIP_RIGHTS]` slots survived in every single-owner repo, contradicting A1 | §5 ships real single-owner defaults; slot names live only in the comment |
| RISK | A "content" collaborator could not finish the §6 checklist (needs `tests/_helpers.ts`, the share-card list) | Content row names those edits explicitly |
| RISK | The Workers-check proof (§6.2) pointed at a throwaway pull request opened *before* Cloudflare was connected | §6.2 opens a second one after connecting; B7 says so |
| RISK | `main.<project>.pages.dev` stated as the preview for both publish models; on single-stage `main` is live | Scaffold note and new-website step distinguish the models |
| RISK | Bypass list omitted `ALLOW_MAIN_PUSH=1`; "replace the OPTIONAL comment" would delete two load-bearing comment lines | Named; only the first sentence is replaced |
| RISK | Q3 "owner merges everything" had nowhere to land (§2 and the guide hard-coded the own-PR rule) | Merge rule is a §5 line; §2 and the guide point at it |
| RISK | Re-running §5-A would POST a second ruleset | Count existing "protect main" rulesets before creating |
| RISK | Single-stage sites keep `PROD_BRANCH = 'production'`; "must equal" invites setting Cloudflare to `production` | §6.5 says: set `PROD_BRANCH = 'main'` in the setup pull request |
| NIT ×7 | Dangling "step 4" in the guide once option A is deleted; incomplete slot list in §8; "Create PR" on the local path; `[SUFFIX_LENGTH]` missing from the scaffold note; "or the build breaks" only true in frontmatter; branch-name convention mismatch; description 5 chars under the hard limit; A8 overstated the hook | All fixed |

**Not run:** a cross-model Codex seat (`independent-review` DIFF gate) — no Codex CLI
in the environment that built this. Run it before merging; the pull request says so.
The round-1 fixes are self-verified only (`make check` green, text re-read against each
finding), not re-reviewed.

---
name: independent-review
description: >
  Domain-agnostic cross-model review gate: run a planning markdown (PLAN gate) or
  a branch/PR diff (DIFF gate) through INDEPENDENT reviewers — external models via
  scripts/independent_review.sh. Default STANDARD PAIR, runs automatically:
  Codex (gpt-class) + ollama-cloud (GLM). Antigravity/Gemini is OPT-IN ONLY
  (--with-antigravity) — never runs by default, since the owner's Antigravity
  credits are scarce and are spent only when explicitly worth it. PLUS a
  fresh-eyes no-shared-context pass by the host agent (optionally a same-family
  Fable pass on request) — consolidate a ranked BUG/RISK/NIT list, and BLOCK
  until every BUG is fixed or refuted and every RISK/NIT is fixed, refuted, or
  explicitly waived by the human owner. PLAN-typed artifacts DEFAULT to ≥2 reviewers attempted —
  an explicit --first-success is honored, not overridden, for callers who
  deliberately want one reviewer on a lower-stakes plan (e.g. website-content
  work — see website-review's "review depth" guidance). Use BEFORE building from any
  non-trivial plan and BEFORE merging any non-trivial PR. On first use, if no
  reviewer that's cross-model for the
  current host is set up yet (LOCAL ollama alone or a same-family cloud tool
  never counts — see the skill body), runs a guided ONBOARDING for non-technical
  users — explains
  the free-tier tradeoffs plainly (including realistic usage-limit
  expectations), walks the download/login steps, picks an ollama model sized
  to the user's actual RAM, then teaches how to use it. Trigger phrases:
  "cross-review this plan", "get a second model to review", "codex review",
  "gemini review", "antigravity review", "agy review", "adversarial review",
  "review before I merge", "independent review", "cross-model review", "set
  up independent review", "set up AI code review", "install codex for
  review", "install antigravity for review", "set up ollama for review",
  "which review tool should I use", "how do I get a second AI to review
  this".
---

# Independent review — the cross-model gate

A blocking review gate for two artifact types. The value is *independence*: a
model that did not write the artifact, ideally from a different model family,
cannot share the author's blind spots. Dogfooded on its own design plan — two
rounds caught 5 BUGs the author had shipped.

## The two gates

- **PLAN gate** — reviews a planning markdown *before* any code is written.
  Catches strategy errors, stale assumptions, internal contradictions.
- **DIFF gate** — reviews a branch/PR diff *before* merge. Catches test blind
  spots: a guard passing while the thing it protects regressed.

### "It's only a docs row" is the wrong test — ask what the reader will DO

(Codified 2026-08-03 after a single session sent five MRs through this gate and
**every one came back with something real**, including two where the defect was
in the artifact's *proposed fix* rather than its description.)

The instinct that a BUGLOG row, a ledger row, or a runbook is "too small to
review" is about the artifact's SIZE. The thing that matters is whether someone
will later ACT on it without re-deriving it. A deferred-bug row's "suggested
fix" field is a **delegated instruction**: months later, an implementer reads it,
trusts it, and builds it. It is simultaneously the field the author reasons
about least (the bug is already understood; the fix is an afterthought) and the
one the reader trusts most. That asymmetry is where the defects were:

- A row said "add the missing build steps to the CI job." The job was *manual*,
  so the fix would not have closed the gap. Round 1 caught it.
- The rewrite said "…and add a cross-project trigger." A triggered pipeline ran
  the *automatic* job, still never the manual one. **Round 2 caught the same
  class of error one level down** — which is the case for a verification round
  after any BUG, not just a code one.

Practical rule: **gate on consequence, not on diff size or file extension.** A
row whose fix someone will implement, a runbook headed for a production session,
a plan a stage agent will execute — all carry more downstream weight than a
small code change that CI will catch anyway. Where a lighter gate is genuinely
right, name the gate it got and why (Procedure step 9's trail does this), rather
than skipping silently.

**Corollary — send the code that CONSUMES the config, not just the config.**
Reviewing a compose/env/infra diff in isolation reliably produces
"this might be a silent no-op" and "this might fail indistinguishably" findings
that the consuming source already answers. In the session above, BOTH reviewers
independently raised exactly those two against a deploy-wiring diff, and both
were refuted from twenty lines of the application code that reads the variable.
That round cost a full standard pair to produce two speculations and two real
NITs. Include the reading code in the artifact, or expect to spend the round
refuting rather than fixing.

### PLAN gate preconditions — two things to check before spending a round

(Codified 2026-08-16, after a multi-day build cleared seven PLAN rounds and still
left its owner unable to say which steps were finished.)

#### 1. Can the plan report its own progress?

**The HOST agent runs this check itself** (the same orchestrating agent named throughout
this skill, e.g. in the clerk procedure — not item 3's "Fresh-eyes host-agent pass",
which is one specific reviewer seat), before the external pair goes out. Two different
reviewers are structurally unable to do it, for two different reasons: the fresh-eyes
seat receives only the artifact, per the Reviewer stack below, and has no repo access at
all; the external pair (Codex, ollama) does have repo access but is never asked this
question — it's a precondition on the plan, not a content-review prompt, so nothing in
either tool's instructions would surface it.

Two questions. **Does the plan, or a sibling document it names, have a place where each
step's state is recorded?** And **does every state claiming progress or completion carry
a reference another person can actually open** — a commit SHA, a repository-qualified
pull request, a test-run link retained per the project's own policy rather than an
ephemeral CI console URL? "Not started" is the one state needing no reference; every
state asserting something happened does.

If either answer is no, record it as a **RISK, not a NIT**, in the host's own findings
and in the trail (Procedure step 9), and keep it out of the artifact sent to the
external pair — including a verification round's prior-findings list, which would
otherwise spend their attention on a host-only structural point. **This does not gate
the external round**: the standard pair still runs on the plan's content exactly as
usual, and the plan is never held back from them over it. The concern is orthogonal to
content quality — it's whether anyone can tell what's done once building starts. That
cost lands weeks later, on the human, and hardest on plans that PASS: a well-reviewed
plan gets built over days, which is exactly when memory of progress fails and the
conversation holding it is gone.

**What this establishes, and what it does not.** It is a structural check at review
time — the plan has somewhere to record state, and the convention demands a reference.
It cannot tell you a row is *accurate*, and it cannot police updates during the build
that follows: at review time most steps have not happened yet, and nothing here is
watching weeks later. A tracker can still go stale by simply not being updated, and the
rule below is stated in a document reviewers read — if whoever executes the plan is a
different session, a different agent, or a human who never opens this skill, nothing
here reaches them. Say all of that plainly rather than imply a coverage this check does
not have: closing it needs the rule carried into wherever the builder actually looks —
the plan's own execution notes, or the handoff itself — which is a decision for that
handoff, not something this gate can reach into the future and enforce.

This prescribes no format. Whatever the project already uses is fine, on two conditions.
The record lives **in the repo**, not in a chat log or a session's to-do list — both die
with the session, and a plan reviewed in one session is usually built in another. And
**updating a step's state is part of finishing that step**, never a separate bookkeeping
pass afterwards — state this as the convention that makes the record worth keeping, not
as a promise this gate enforces: a tracker nobody updates goes stale silently, which is
worse than having none, because it still reads as authoritative.

#### 2. Are the plan's own decisions settled?

**A plan whose steps are still changing does not need another round yet.** It needs its
open decisions closed first. If any finding from the last round was "this section
depends on an undecided question", get that decision, let the document settle, then run
the verification round on the result — Procedure step 6 still applies in full; this
defers that round, it never replaces it. Re-reviewing a moving target is how a plan
reaches round seven, and every round after the first grades a document that is no longer
the plan.

## Reviewer stack (default STANDARD PAIR runs automatically; Antigravity is opt-in only)

1. **Codex CLI** (`codex exec -s read-only`) — genuine read-only sandbox; model +
   effort from `~/.codex/config.toml` (daily-driver default). Override per-run with
   `CODEX_MODEL=gpt-5.6-sol` for a harder case or a long plan — config.toml's
   reasoning-effort setting still applies on top, since the override only touches
   the model key.
2. **ollama cloud** (`OLLAMA_MODEL`, defaults to `glm-5.2:cloud`) — the standard
   second reviewer, runs automatically alongside Codex with no env var needed.
   Override to a different tag if a specific case warrants it.
3. **Fresh-eyes host-agent pass** — a read-only sub-agent (or the vendored
   `double-knuth` skill) with NO shared context: give it only the artifact and
   the strict prompt below. Never reuse the authoring conversation. If the host
   has no sub-agent primitive (some Codex installs), use a separate fresh
   session with only the artifact — or record the pass as *degraded* in the
   trail, not as no-shared-context. On a Claude Code host, a **Fable** pass
   (Agent tool, `model: "fable"`) is a good candidate for this seat when the
   owner wants a second same-family opinion on top of the Sonnet host pass —
   it's free (no external credits, no CLI), just not cross-model (see the
   Independence rule below). Offer it after presenting results, don't run it
   unasked.
4. **Antigravity — OPT-IN ONLY, never automatic.** Gemini 3.1 Pro (High) via
   the Antigravity CLI (`agy --sandbox --model "$AGY_MODEL" -p`, `AGY_MODEL` defaulting to
   "Gemini 3.1 Pro (High)" — see Step 5 below for the full invocation and how to override it),
   free Antigravity login. The
   owner's Antigravity free-tier credits are scarce and get spent only when
   explicitly worth it: pass `--with-antigravity` to the script, or the owner
   directly asks ("antigravity review", "agy review", "worth burning a
   credit on this one"). The default run (no flags) never touches it — this
   is a deliberate change from earlier drafts of this skill, which ran it
   unconditionally on every default pass and burned credits silently.
5. **ollama local** — sanity pass only; the script never lets it satisfy the
   gate alone.
6. **Any model, copy & paste** — the script emits the prompt; a human pastes it
   into whatever is available and feeds findings back.

**The standard pair (Codex + ollama-cloud) is the un-flagged default for both gates** —
DIFF included, not only PLAN; `--first-success` reduces either to a single reviewer.
**PLAN additionally treats fewer than 2 as worth flagging**: a plan is often high-stakes
enough that "whichever one answered first" isn't enough independence, so the script
notes it explicitly (see Procedure below) whenever a plan lands with fewer than 2
reviewers — DIFF gets no equivalent note. This is a default expectation, not a hard
floor: passing `--first-success` on a plan is a caller's conscious choice to accept one
reviewer instead (the script honors this, it does not override it — see the
credit-cost tradeoff this represents). If a
plan lands with only one reviewer's output for any reason — an explicit
`--first-success` or a tier failing — treat the round as degraded *only if
that wasn't the deliberate choice*, and say so either way.

**Independence rule:** *classify* every tier that actually ran — which tiers
those are is decided by the reviewer stack above (the standard pair by default;
Antigravity only on explicit opt-in; paste always manual; local ollama runs
whenever `OLLAMA_MODEL` names a local tag, but never *closes the gate* on its
own), and this rule governs how the ones that ran are scored, not how many to
launch. The tier matching the HOST agent's model family counts as the
fresh-eyes seat, never as cross-model independence. **The gate is satisfied only when at least one
successful reviewer is cross-model (a different family than the host)**; if
only same-family reviewers ran, the gate is degraded and needs an explicit
owner waiver — codex reviewing codex-authored work shares the blind spots this
gate exists to catch. Per host: **Claude Code** — fresh-eyes = the Claude pass
(optionally a **Fable** pass, see the reviewer stack above — same family,
doesn't count as cross-model either), cross-model = Codex + ollama-cloud
(GLM, Z.ai — the standard default pair) + Gemini/Antigravity (opt-in extra,
not needed to satisfy the gate since Codex or ollama-cloud already does).
**Codex** — fresh-eyes = Codex, cross-model = ollama-cloud + Gemini + Claude.
**Antigravity/Gemini** — fresh-eyes = Gemini, cross-model = Codex +
ollama-cloud + Claude. On any non-Claude host, an Anthropic seat may be
reachable via the Antigravity CLI — see `references/setup-guide.md` for the
current model tag, verification status, and free-tier caveat; it shares the
same scarce-quota, opt-in-only rule as every other `agy` use in this skill,
not a standing free lane.

## Onboarding — the agent runs this wizard on first use

**Everything below assumes a Claude Code host (the common case), where both
Codex and Antigravity are cross-model and either one satisfies the gate.**
If the current host is itself Codex or Antigravity/Gemini, substitute per
the Independence-rule table above wherever this wizard names a specific tool
as "the" recommended reviewer or as satisfying/not-satisfying the gate —
don't apply the Claude-host examples literally on a different host. This
applies to every step below, including the default recommendation in Step 3
and the fallback description in Step 6, not just the detection logic in
Step 2.

**When invoked and no reviewer that's gate-satisfying for the current host is
installed and working** (see Step 2's fuller definition below — not just
"nothing is installed at all"), do not dump install commands. Walk the user
through it like a friendly wizard.
Assume a non-technical user who has never used a terminal seriously — do the
heavy lifting yourself; clearly flag the few things only they can do. Full
install commands, the tool comparison table, and the ollama RAM/model tables
referenced below all live in `references/setup-guide.md` — pull from it as
needed rather than re-deriving any of this from general knowledge, since
exact free-tier limits and install commands drift and that file has current
sourcing plus an explicit "don't quote a stale number" caveat. **Numbers
belong in that reference file, not hardcoded in this wizard** — when a step
below needs a figure (a time estimate, a limit, a lockout report), pull it
from there rather than restating one here from memory, so there is exactly
one place to update when it goes stale.

**"Installed" is not "working" — three distinct checks, don't conflate them.**
On macOS/Linux, run these directly. **On Windows, if the agent's own shell is
PowerShell rather than a POSIX shell (WSL, git-bash), `command -v`/`test -f`
won't work as written** — use the PowerShell equivalents shown:
1. *On PATH* — `p="$(command -v codex)" && test -f "$p" && test -x "$p"` /
   same for `agy`/`ollama` (a bare `command -v` alone can match a shell
   alias or function, not the real binary; `test -x` alone isn't enough
   either — a directory can be `-x` without being the binary — so require
   both `-f` and `-x` on the resolved path). This is a best-effort check,
   not a perfect one — an edge case remains where `command -v` returns a
   bare function name and a same-named executable happens to sit in the
   current directory; don't spend more effort closing that specific gap,
   Step 5's real-review-output check is what actually matters. (PowerShell:
   `Get-Command codex -CommandType Application -ErrorAction
   SilentlyContinue`, same pattern for `agy`/`ollama` — `-CommandType
   Application` is the equivalent guard against matching an alias or
   function instead of the actual binary).
   Proves the binary exists, nothing more.
2. *Looks authenticated* — `test -f ~/.codex/auth.json` (PowerShell:
   `Test-Path -LiteralPath "$HOME\.codex\auth.json" -PathType Leaf` — plain
   `Test-Path` without `-PathType Leaf` would also match a directory
   accidentally named `auth.json`) for Codex; `agy models` returns a model
   list, not an error (Antigravity); `ollama list` returns without error
   (ollama, though this only proves the daemon runs, not that any model is
   pulled yet). A stale/expired token can still pass this check.
3. *Actually works* — a real review request returns real review-shaped
   output. This is the only check that proves the tool is usable right now;
   see Step 5. Don't report "done" off checks 1–2 alone.

### Step 1 — Sell the benefit first (before asking for anything)

In 3–4 plain sentences:
- *"Before I hand you a finished plan, or before we merge a real change, I can
  get it checked by a completely different AI — one that didn't write it, so
  it can catch mistakes I might miss myself. Think of it as a second, more
  skeptical pair of eyes."*
- *"This is free to set up — no new subscription required. Most of the setup
  is something I can do for you; you'll just need to click a couple of
  sign-in prompts yourself."*

Then ask **"Want to set this up now?"** If they say **no**, don't proceed —
but don't silently treat the artifact as reviewed either: this skill's own
rule is BLOCK until reviewed or explicitly waived (see Procedure step 5).
Tell them plainly: *"OK — I won't set this up now. That means I can't run an
independent review until either you change your mind, or you explicitly tell
me to skip the review this time (I'll record that as your call, not mine)."*
Record a decline as a named owner waiver if a gated action (merge, ship) is
actually blocked on it — don't just drop the topic.

### Step 2 — Check what's already there; never re-onboard a returning user

Run the detection commands above. **The skip condition is "the user's actual
request is already satisfied AND the gate is actually satisfiable with
what's installed," not "any one tool works":** per this skill's own
Independence rule above, a reviewer only satisfies the gate if it's
**cross-model relative to the CURRENT host**, not just "installed" — ollama
LOCAL never satisfies it regardless of host (tier 5 — sanity pass only), but
ollama CLOUD (a signed-in `:cloud`-tagged model, e.g. the default
`glm-5.2:cloud`) DOES count, same as Codex/Antigravity — it's tier 2, part of
the standard default pair (see Reviewer stack above), not tier 5. Which cloud
tool(s) count as cross-model depends on what's running this wizard: on a
Claude Code host, Codex and/or ollama-cloud and/or Antigravity all count; on
a Codex host, Codex CLI alone does NOT (same family as the host) —
ollama-cloud or Antigravity are the cross-model options there; on an
Antigravity/Gemini host, the reverse (Codex or ollama-cloud count,
Antigravity doesn't).
- If the user asked generically for review setup, and ≥1 reviewer that is
  **cross-model for the current host** (per the table above — not LOCAL
  ollama alone, and not same-family-as-host alone) is already installed and
  authenticated: **first run one real test review per Step 5's evidence
  standard — installed-and-authenticated is checks 1–2, not proof it
  works — then, only once that passes, skip the rest of onboarding and go
  straight to Step 6.** A failed test run means treat it as broken, not as
  done (see the last bullet below).
- If only LOCAL ollama is set up so far, treat that the same as "nothing set
  up yet" for gate purposes — it's a fine backup to already have, but proceed
  to Step 3 to add a cloud reviewer (including ollama-cloud itself — `ollama
  signin` on the same install), don't report the wizard as done.
- If the user asked for a **specific** tool that isn't set up yet (e.g. "set
  up ollama too" when only Codex is working), don't skip — go set up the one
  they actually asked for, even though the gate is already technically
  satisfiable without it.
- If a previously-working tool now fails (expired login, uninstalled), say
  plainly which one broke and offer to either fix it or move on with what's
  still working — don't restart the whole wizard for the tools that are fine.

### Step 3 — Help them choose (they don't need all three)

Present the three options as a short, plain-language summary — pull the full
comparison table from `references/setup-guide.md` if the user wants more
detail, but lead with this, not the table:

- **Codex CLI (OpenAI)** — free ChatGPT account, no payment. Of the two
  hosted-CLI options, the more predictable free tier (see `references/setup-guide.md`
  for what's currently known about its limits — pull the actual figures from
  there, don't restate a number from memory here).
- **Antigravity (Google)** — free personal Gmail account, no payment. Just as
  sharp a reviewer, but **its free-tier usage limit is tight and not clearly
  published.** Pull the current, sourced detail (including a dated real-world
  report of severe lockouts) from `references/setup-guide.md` and say it
  plainly — don't undersell it, and don't guess at numbers not in that file.
- **ollama** — free either way, two distinct modes:
  - *Cloud* (e.g. the default `glm-5.2:cloud`) — needs a one-time `ollama
    signin` (free, no payment) but nothing beyond that; runs on Ollama's own
    servers, so it DOES leave the machine. This is the script's actual
    standard second reviewer — sharp enough to satisfy the gate on its own,
    same tier as Codex/Antigravity.
  - *Local* (a model pulled to this computer) — completely free, unlimited,
    private (nothing leaves the machine), no account at all. Quality depends
    on the computer's RAM, and even a well-equipped machine's best local
    model lags the cloud options on subtle bugs — sanity-pass only, never
    satisfies the gate alone. Good as a free unlimited *backup*.

**Default recommendation if they're unsure (Claude Code host — see the note
at the top of this section for any other host):** set up Codex CLI plus
ollama-cloud (a free `ollama signin` — no payment method required) — that's the script's
actual standard default pair, and it runs automatically with no flags once
both are set up. Add a local ollama model pull too, as a free unlimited
backup for whenever Codex or ollama-cloud's free tier is temporarily tapped
out. Antigravity is worth adding on top if they want a third, independent
model family and are comfortable with a less predictable free tier — it is
not required. **If the current host is itself Codex, swap this
recommendation: Codex CLI would be same-family and wouldn't satisfy the
gate — recommend ollama-cloud (the script's standard automatic second reviewer)
as the main reviewer instead**, with local ollama as the same free backup either
way. Antigravity stays what it is everywhere else in this skill: an opt-in extra
that spends a scarce credit, never the default recommendation.

Ask which one(s) to set up, then proceed per tool below.

### Step 4 — The human-only steps ( 🧑 **you do this** )

Regardless of which tool(s): a sign-in step always needs the user's own
click, and installing anything means running a command in their terminal for
the first time — walk them to opening a terminal (Terminal.app on macOS,
PowerShell on Windows, their terminal of choice on Linux) if they've never
done it, one plain instruction at a time.

- 🧑 **Codex:** open a terminal, paste the install command I give you, press
  enter, wait for it to finish. Then run `codex` and follow the "Sign in with
  ChatGPT" prompt in the browser window that opens — one click to approve.
- 🧑 **Antigravity/`agy`:** same shape — paste the install command, then run
  `agy models` and follow the Google sign-in prompt (personal Gmail account).
- 🧑 **ollama:** for macOS/Windows, download and open the installer like any
  normal app (no terminal for the install itself) — but the model download
  in Step 4b still needs a terminal command; on Linux there's a single
  terminal install command. **For ollama-cloud** (the script's actual
  standard second reviewer), also run `ollama signin` once and follow the
  browser sign-in prompt — one click, free, no payment. For the local backup
  model, tell me your available RAM (or let me detect it) so I can recommend
  one — do NOT let them guess a model size themselves; see Step 4b.

Hand these over **one at a time**, wait for confirmation each step landed,
don't paste all the commands at once.

### Step 4a — Your steps ( 🤖 **I do this** )

- 🤖 Give the exact install command for their OS (from
  `references/setup-guide.md`), one tool at a time.
- 🤖 After each install, verify it actually landed using check 1's `-f`/`-x`
  test above (not a bare `command -v`, which check 1 itself says can match an
  alias or function rather than the real binary) before declaring success —
  a "looks done" claim without checking is exactly the kind of thing this
  skill exists to prevent elsewhere; don't do it here either.
- 🤖 If a `PATH`/"command not found" issue comes up after an apparently
  successful install, try the standard fix (new terminal window) before
  escalating — see the Gotchas in `references/setup-guide.md`.

### Step 4b — ollama only: pick the model from RAM, don't guess

**This is a machine-capability decision, not a preference — check before
recommending.**

- 🤖 Detect **total installed** RAM using the OS-appropriate command from
  `references/setup-guide.md` (`sysctl hw.memsize` on macOS, `systeminfo` or
  Task Manager on Windows, `free -h` on Linux) — most of these print BOTH a
  total and a free/available figure side by side; use the total one, not
  the free/available one printed next to it. If the machine is under heavy
  memory pressure from other apps, say so rather than silently dropping a
  tier. If
  you can't run the command directly (e.g. the user is on a different
  machine than the one you have shell access to), ask them to run it and
  paste back the number.
- 🤖 Look up the matching row in the RAM → model table in
  `references/setup-guide.md` and recommend exactly ONE model tag — don't
  offer the full menu and make a non-technical user pick blind.
- 🤖 **Warn about the download before pulling it** — model files run
  multiple GB; say the size and ask before running `ollama pull <model>` on
  a metered or slow connection.
- 🤖 State the honest ceiling plainly: *"This will catch a lot of the
  obvious stuff for free, but it's not as sharp as Codex or Antigravity on
  subtle bugs — think of it as a backup, not a replacement."* Don't let
  "free and unlimited" imply "just as good."

### Step 5 — Confirm it's actually working (with evidence, not a claim)

Run one real, small test review with each newly-configured tool — a trivial
throwaway artifact is fine (e.g. a two-line diff). **Quote or closely
paraphrase one actual line the reviewer produced**, not just your own
success claim: *"✅ Codex is working — I gave it a small test diff and it
came back with: '[actual excerpt from its output]'."* An assertion of
success with no quoted output is not evidence and doesn't satisfy this step.
A tool that installed but can't produce a real review (bad auth, model
unavailable, `looks_like_review()` in the script would reject its output) is
not done — fix it or tell the user honestly it isn't working yet.

**For Antigravity/`agy` specifically, this step must also confirm the
*model*, not just that a review came back.** `agy models` (used in Step
2/4a) only proves models can be listed — it says nothing about which model
the CLI will actually use for a review. Apply the ONE rule this whole skill
uses everywhere else (see the Independence rule table) — don't re-derive a
per-host list here, that's what kept breaking across earlier drafts of this
paragraph: **the reviewer's confirmed model family must differ from the
CURRENT host's family. That's it — check it against whichever host is
actually running right now, for whichever reviewer is actually being
verified, every time.**

`agy`'s default model is Gemini (`independent_review.sh` invokes `agy
--sandbox --model "$AGY_MODEL" ...`, `AGY_MODEL` defaulting to "Gemini 3.1
Pro (High)" — that env var is this script's own convention, mapped straight
onto `agy`'s real `--model` flag; it is not a native `agy` setting, so don't
expect it to do anything outside this script). Gemini differs from every
host in this skill except an Antigravity/Gemini host itself — so on a
Gemini host specifically, `agy` only satisfies the gate if `AGY_MODEL` is
overridden away from Gemini (e.g. to Claude); on every other host, `agy`'s
Gemini default already satisfies it. If a fallback reviewer is needed
because `agy`'s model can't be confirmed, apply the same one rule to pick
it — check whichever candidate's model family actually differs from the
current host's, rather than defaulting to a fixed choice; on most hosts
that resolves to Codex (cross-model everywhere except when the host is
itself Codex), but it's a derived result of the rule, not a hardcoded
default.

Look for a model identifier in the test review's own output — the actual
invocation's reported model, not a config file (a valid Codex install may
have no `config.toml`, or one with no explicit `model` entry, sourcing its
effective model from defaults/profile/CLI args instead; `codex exec` does
reliably print its effective config in its own output regardless, e.g.
"model: gpt-5.6-terra" — that's the thing to read, not the file). `agy`'s
output format for this wasn't independently confirmed while writing this
skill, so treat that pattern as a lead to check, not a guarantee. **If no
model identifier can be confirmed at all, do not report `agy` as
gate-satisfying** — "a review came back" and "a review came back from a
confirmed cross-model model" are different claims, and only the second one
closes the gate; say plainly that the model couldn't be verified and pick a
fallback the same way (the one rule, above) rather than defaulting to any
specific tool by name.

### Step 6 — THEN teach them how to use it. Don't skip this.

Tell the user they never need to touch the terminal again for this — from
now on, in any normal session, they just ask in plain language: *"get this
reviewed,"* *"codex review,"* *"antigravity review,"* *"independent review
this before we merge,"* or similar (see the trigger phrases in this skill's
frontmatter) and the review runs automatically using whichever tool(s) are
set up.

**Set the free-tier expectation now, not when it surprises them — and be
accurate about what "fallback" actually means:** *"Codex and Antigravity are
free but not unlimited — you may occasionally hit a limit (see
references/setup-guide.md for what's currently known about each). Here's
what actually happens if you do, depending on how review is run: by
default Codex and ollama-cloud run together each time — **Antigravity never
runs by default, even once it's set up**, because it spends one of your scarce
credits and waits for you to ask — so if Codex is temporarily rate-limited,
that round still runs with the ollama seat (cloud if it's available, local as a
degraded fallback). **That keeps you fully covered only if a
cross-model reviewer for this host is still available — if LOCAL ollama is the
only thing left, that round is a lighter-weight, degraded pass, not a full
substitute** (same rule as everywhere else in this skill: LOCAL ollama alone
never closes the gate on its own — signed-in ollama-cloud does). If review is
run in quick 'first available'
mode instead, it tries Codex first and only moves to the next one if Codex
fails outright. Either way, having a **locally pulled** ollama model (not
just `ollama signin`) means there's always a free, unlimited, fully-private
option in the mix — just know it's a lighter-weight reviewer, not a
like-for-like replacement."*

## Procedure

1. **Data check before anything leaves the machine.** External reviewers are
   third-party services: grep the artifact for secrets (keys, tokens, passwords,
   customer data) and get the owner's OK the first time a given repo's content
   is sent out **to each destination service, not just each named tool** —
   Codex, ollama-cloud, and Antigravity are separate services with separate
   consent, not one blanket "external reviewers are OK," and naming the tool
   isn't always naming the destination: Antigravity with `AGY_MODEL` set to
   a Claude tag routes content on to Anthropic too, a distinct destination
   from Antigravity's own Gemini path, needing its own consent — and the
   paste tier (tier 6) sends the same artifact to whatever service a human
   pastes it into, chosen ad hoc, which needs the same per-destination
   consent as any named provider, not a free pass for being manual. Record
   the OK the way step 9's permission table records
   an owner instruction (atom B: quoted verbatim). **Only a standing
   instruction durably written in the repo persists across sessions** — a
   later session can check for that and tell "owner consented for this
   provider" from "nobody has asked yet." This session's own in-conversation
   record is real consent for the current session, but per this file's own
   durability standard (an in-session hand-off doesn't count as durable
   anywhere else here either) it is invisible to a later one — that session
   re-asks rather than assuming consent it cannot see. Adding a new provider
   later needs its own consent, not an inherited one. If the content must stay local, run the script with
   `--local-only` (skips codex/agy/paste entirely; local ollama only — the
   script requires the EFFECTIVE ollama tag to be local: under `--local-only` the
   `glm-5.2:cloud` default is never applied, and an explicitly-set cloud tag is refused outright,
   rather than silently sending content out) plus the tier-3 host fresh-eyes
   pass — tier 6 (paste into any model) is just as
   external as the CLIs and is excluded. A local-only verdict is inherently
   DEGRADED; record that in the trail.
2. Run the external half (path relative to THIS skill's directory — after an
   install that is `<skills-root>/independent-review/scripts/…`):
   `scripts/independent_review.sh <artifact.md|diff-file|-> [--plan|--diff]`
   — `--plan`/`--diff` is optional: the script auto-detects from the input —
   a `.diff`/`.patch` filename resolves to diff, anything else to plan, and
   **stdin (`-`) has no filename to guess from at all, so it defaults to
   diff** — that resolved value is the `<gate>` step 9(a)'s trail filename
   uses. Pass the flag explicitly whenever the filename wouldn't guess
   right, and always when piping a plan through stdin (a piped plan
   otherwise silently loses the PLAN gate's <2-reviewers flag and gets
   mis-named as a diff trail). Default runs the standard pair (Codex + ollama-cloud) and prints one
   section per reviewer; `--first-success` is the quick mode (for a `--plan`
   this deliberately drops from the default 2 reviewers to 1 — a conscious
   choice for lower-stakes plans, honored not overridden — see the reviewer
   stack above). Add `--with-antigravity` only when it's genuinely worth
   spending one of the owner's scarce Antigravity credits — never by default.
   Exit 4 = no reviewer ran = gate FAIL (never treat as clean).

   **Build that artifact from the CHANGE, not from the whole diff — exclude `docs/reviews/`.** A
   DIFF gate on a branch that already carries a trail file will otherwise send the trail to the
   reviewers, and they will review it: its arithmetic, its finding counts, whether it describes the
   round currently reading it. Those findings are real — an arithmetic error in a trail IS an error
   — but they are about the review RECORD, not the change under review, and they arrive in rounds
   that would not otherwise have happened. Generate the artifact with the trail excluded:

   ```
   git diff <base>...HEAD -- . ':(exclude)docs/reviews/'
   ```

   Audit the trail's own numbers yourself instead. Two runs have now paid for this — two MRs on the same
   internal backend repo, one of 8 rounds and one of 7, each with a late round that found nothing
   but the trail auditing itself (on the 7-round MR that was round 6, whose two findings were both
   arithmetic errors in the trail; the truncation incident cited further down is a different round of the same
   MR, and the two are not the same event). The existing "scope it by RULE, not round number" guidance BOUNDS
   that loop; excluding the file PREVENTS it. **The trail must still be in the MR diff** — a repo CI
   gate may require it and clerk item 3 commits it — this is only about what reaches the reviewers.
3. Run tier 3 (fresh-eyes) with the same strict prompt.
4. **Consolidate**: dedup findings across reviewers; keep per finding — a stable
   id, severity (BUG/RISK/NIT), source reviewer(s), location, and status: open, fixed, refuted, or
   waived. A waiver needs a reason and the human owner's sign-off. Refuted applies the same way to
   a BUG, RISK, or NIT alike — it needs the disproving reasoning instead of an owner sign-off,
   since a refuted finding was never a real issue.

   **A pre-existing artifact annotation never auto-closes a finding that re-raises it — its own
   reasoning must actually cover what THIS reviewer raised, confirm that first.** Only once
   confirmed: if the artifact itself already explains a deliberate choice a finding re-raises (a
   code comment, a plan annotation — e.g. from a prior planning-stage review whose reasoning was
   carried forward, see `phased-plan-runner`'s equivalent convention for artifacts produced by
   that skill), triage can cite that existing reasoning instead of a from-scratch re-derivation —
   but citing it does not by itself pick a status: the finding still resolves to REFUTED only if
   the annotation's reasoning actually disproves it, or to WAIVED only if the annotation traces to
   a real prior owner decision (citing an old waiver does not manufacture a NEW one's required
   sign-off out of nothing — get a fresh one if the annotation doesn't already clearly carry it).
   An annotation that merely explains a tradeoff the team accepted, without disproving the finding,
   is waiver-shaped, not refutation-shaped — treat it as such, not as an automatic close.
   Whenever the annotation's reasoning does NOT cover what the new finding raises, that finding is
   new signal — not repetition — regardless of whether the reviewer saw the annotation; it gets
   triaged like any other finding, never dismissed because *something* was already written nearby.
5. **Enforce the verdict** (this is the skill's job — never the script's exit
   code): every BUG confirmed real by verification must be fixed, no exceptions — one conclusively
   shown to be a non-issue is REFUTED, not waived, and needs no owner sign-off; RISK/NIT
   may be waived only with a reason and the human owner's sign-off, OR likewise REFUTED (not waived)
   if conclusively shown to be a non-issue — no blanket waivers either way. "Conclusively shown"
   means evidence appropriate to what's actually being claimed: empirical verification (run it,
   reproduce it, or rule it out — under the SAME standard as failure shape (a) below, testing the
   claim's full stated reasoning, not just one cited example) for a claim about runtime/checkable
   behavior; direct textual or
   logical demonstration — quoting the actual contradiction, or its absence — for a claim about
   structure, logic, or wording, where there is no runtime to check against. Don't demand an
   empirical test a claim was never about in the first place.

   **Verify checkable claims — empirically where the claim is about runtime/checkable behavior, by
   direct textual/logical demonstration where it's about structure, logic, or wording — before
   calling them fixed OR refuted; a reviewer's named example is illustrative, not exhaustive.** Two
   recurring failure shapes:
   (a) a fix that resolves only the ONE example a reviewer happened to cite (a specific
   string, a specific input) can still leave the reviewer's actual, broader claim true — test
   against their full stated reasoning, not just the named case, before marking it fixed
   (caught in practice: a regex fix was accepted after disproving only one cited false-positive
   string, but the reviewer's broader point still reproduced on a harder test). (b) a finding that an
   API/data surface is reachable, or behaves a certain way, is NOT settled by confirming a
   type/field/shape matches — trace the real access path (auth mechanism, routing,
   permissions) it actually goes through; a correctly-shaped type sitting behind different
   auth than assumed is still wrong, and "the shape looks right" is exactly the plausible
   half-check that misses it. Both apply symmetrically to REFUTING a finding, not just
   fixing one: don't dismiss a reviewer's claim as wrong just because its own cited example
   fails to reproduce — check whether the underlying point still holds under a harder case
   before writing it off. **A claim that's checkable in principle but can't actually be tested
   right now** (missing environment, credentials, or permissions) **stays OPEN**, with the
   missing prerequisite recorded — don't force it into fixed or refuted without the check that
   would justify either. (A RISK/NIT in this state may still be WAIVED with a reason and the
   owner's sign-off, same as any other open RISK/NIT — waiving needs no check, just the owner's
   call; only fixed/refuted are blocked pending the missing prerequisite.)
6. **Iterate — fix, then re-review.** Send the updated artifact back through
   the reviewers as a *verification round*: give them the prior round's BUG
   list, ask them to confirm each fix landed AND that the fixes introduced
   nothing new — and tell them the author expects clean **and that they must
   not oblige out of politeness** (expectation of cleanliness is exactly the
   bias that turns round 2 into a rubber stamp). Repeat until essentially
   clean. Stop conditions: (a) clean — done; **(a2) a round returns ZERO BUG and ZERO RISK — that
   IS "clean", and it is the signal to stop, not an invitation to spend one more round chasing the
   NITs it did return.** NIT-only rounds are where a gate quietly doubles in cost: each one returns
   two or three more, because prose can always be tightened and a reviewer asked for findings will
   find some. Fix or refute that round's NITs and close, without sending them back out. **A NIT you FIX
   changes the artifact, so the thing you close on is not the thing that came back clean** —
   record those fixes as `locally_verified` (point 6's own two statuses) and note in the trail
   that the closing edits were not externally re-verified, the same admission (c) makes for the
   same reason. Refusing this costs another full round and defeats (a2); leaving it unsaid
   claims a coverage the gate did not have. A NIT that is refused or waived edits nothing and
   needs neither. Re-read the
   BUG/RISK-per-round series, not the raw finding count — a series like 5 → 2 → 2 → 1 → 0 has
   already converged at the 0, whatever the NIT column says; (b) 3 rounds with BUG/RISK still
   open — hard gate-FAIL, surface and block; (c) **budget/credits exhausted**
   — you may stop ITERATING once all known BUGs are *fixed or refuted* AND every RISK/NIT is
   fixed, refuted, or explicitly owner-waived (same bar as point 5's blocking rule), deferring
   only the external re-verification of those fixes; record "last round not
   re-verified" in the trail and run a later round when resources allow.
   Deferring verification is legitimate; deferring a fix or a waiver never is.
   **This governs whether to run another round, and nothing else** — in particular it has no
   bearing on the consolidated marker, whose own rule lives in clerk item 2.

   **What "3 rounds" counts, since this is ambiguous the moment you need it.** The cap is
   **per stable finding id** (point 4's id), not per calendar round: a finding first raised in
   round 3 gets its own remediation-and-verification round before the cap can fire on it, and a
   finding open across rounds 1–3 fails the gate even if that round found other, newer things.
   **A redesign starts a NEW artifact and a new count.** When point 7 says stop patching and
   redesign, the review of the redesign is round 1 of that new artifact, not round 4 of the cycle
   it replaced — otherwise the cap would forbid reviewing the very rewrite it just demanded. Say
   in the trail which artifact a round belongs to, so the count is never reconstructed by memory.
   Re-gates forced by a moved diff (clerk item 2) do not count against the cap — they re-establish
   coverage rather than iterating on findings.

   **Two verification statuses, not one — "verified" alone is what makes 6(c) ambiguous.**
   `locally_verified` = the author reproduced, demonstrated, or ruled out the claim themselves,
   to point 5's standard. `externally_reverified` = an independent reviewer confirmed the fix in
   a later round. A checkable claim with neither status stays OPEN and blocking. Record both per
   finding; a trail that says only "fixed" does not say which.
7. **Convergence check — the rabbit-hole detector.** Iteration is only healthy
   while quality demonstrably rises each round. After every round, check three signals:

   **(a) Finding count.** Is it falling? Don't read this alone as the verdict — a rising count
   from genuinely new scrutiny is healthy: a later round that finally verifies claims no earlier
   round checked SHOULD find more, not fewer, real issues.

   **(b) Are findings landing on genuinely new ground?** A finding PASSES (b) when it targets
   code *added by the previous round's fixes*, or when checking it names a concrete new thing —
   a specific check, input class, execution path, invariant, or evidence source the earlier pass
   didn't use (e.g. round 3 starts empirically tracing auth/data-access paths where rounds 1-2
   only reasoned from reviewer prose) — regardless of whether the overall method is nominally the
   same or different; simply asserting a pass was "more careful," "deeper," or used a "different"
   method, without naming that concrete delta, does not pass (b) on its own. A genuinely new
   method that comes back CLEAN isn't a (b) failure either — there's no finding for it to
   classify; it's valid convergence evidence, not wasted effort. (b) FAILS when a finding
   re-covers ground a PRIOR PASS explicitly checked and reported CLEAN, without naming that
   concrete new thing — this is about ground nothing was ever raised against, a different
   population from the re-raises (c) below covers, where something WAS raised and dispositioned.

   **(c) No oscillation.** A fix that, once verified per point 5's own standard (reproduced or
   demonstrated, not just asserted), DEMONSTRABLY re-breaks something an earlier round FIXED means
   STOP regardless of how many other findings that round are genuinely new — a regression isn't
   offset by unrelated progress elsewhere. This is the only EVEN-ONE-finding trigger in this
   section; every other case below pools into the STOP threshold's MOST-of-the-round test instead.

   A reviewer re-raising a finding THIS REVIEW's own round-to-round trail already dispositioned
   (matched by the stable id from point 4, not just similar wording) is common and NOT
   automatically oscillation — an independent reviewer, especially the no-shared-context
   fresh-eyes/Fable seat, is expected to sometimes re-notice something a prior round already
   handled, precisely because that seat doesn't know the prior rounds happened. What matters,
   checked with the same verification standard as any other claim (not just asserted): does the
   re-raise bring new reasoning or evidence beyond what the prior disposition already considered —
   the same coverage test point 4 uses for pre-existing artifact annotations (does the prior
   disposition's reasoning actually cover what the new evidence raises?), adapted here to
   round-to-round dispositions *within this review*. If it does, it's a fresh finding, full stop,
   regardless of what the prior disposition was. If it doesn't (checked, and the original
   disposition still holds), where it counts depends on that prior disposition:
   - a re-raise of something FIXED or REFUTED with no new reasoning pools into the MOST threshold
     below, alongside (b)-failures — NOT this signal's strict even-one bucket above. It's reviewer
     overhead (re-checking a claim that turned out to still be nothing new), not the artifact
     regressing; the strict bucket is for a DEMONSTRATED regression specifically, and holding a
     routine no-shared-context re-raise to that same bar would effectively punish running a
     genuinely independent reviewer every round — the whole point of that seat.
   - a re-raise of something WAIVED with no new reasoning also pools into the MOST threshold, for
     a related but distinct reason: waiving concedes the issue may be real, so it was never "ruled
     clean" (that's (b)'s own test above) and re-noticing it isn't a regression of something
     dispositioned-as-resolved (that's this signal's own test above) — it's an independent
     reviewer correctly re-noticing something the owner already knew about and accepted.
   - a re-raise of something still OPEN under point 5's untestable-claim rule (blocked on a
     missing prerequisite) pools into the MOST threshold the same way: it was never "ruled clean"
     either, and there's no fixed/refuted disposition for it to contradict — restating a known,
     already-tracked open item is not new signal, but it isn't instability either.

   **STOP patching when:** the regression case above fires for even one finding; OR (b)-failures
   and any of the three no-new-evidence re-raise cases above, TOGETHER, characterize MOST (more
   than half) or all of the round's findings — not just one stray finding amid otherwise-new ones;
   OR the count plateaus for two consecutive rounds AND those plateauing findings are not
   predominantly (b)-passing (a plateau of genuinely distinct, newly-surfaced findings each round
   is not itself non-convergence — see (a) above — it's a slower signal the artifact's surface
   area is bigger than first estimated, worth naming explicitly rather than silently forcing
   STOP). (This is an early-exit heuristic layered on top of, not instead of, point 6(b)'s hard
   3-round cap for any round that still has a BUG or RISK open — that cap bounds iteration on
   those regardless of how these signals read; a round left with ONLY NIT churn has no equivalent
   hard cap and relies on these signals alone.) When triggered: step back and redesign the
   component (patch-churn on a wrong design converges never), or take the open items to the owner
   as a decision — escalation can defer, re-scope, or reject the release, but it cannot waive a
   BUG that's still open (for an open BUG blocked on a missing prerequisite — see point 5's
   untestable-claim rule — deferral keeps the release blocked; the BUG can close only after the
   prerequisite becomes available and verification supports either a refutation or a verified fix
   — deferring is what you do while waiting, not the closure itself); point 5's rule holds
   regardless of who's deciding. Say so plainly in the trail — "stopped: not
   converging" is a legitimate, documented outcome; silent round 7 is not.
8. **Keep the human in the loop — narration is part of the gate.** Between
   rounds, tell the owner: what was found, what was fixed, what is pending,
   the convergence trend (e.g. 19 → 9 → 6), and roughly what each round
   costs. The owner steers — they can stop, waive, redirect, or run a
   **manual round of their own**; a human review round is a first-class
   reviewer seat and goes in the trail like any other (reviewer: owner,
   findings, dispositions). **It does not, however, satisfy cross-model
   independence** — a human round contributes findings, but the Independence
   rule's requirement of at least one successful CROSS-MODEL reviewer is about
   model families and can only be met by a model. An owner round on top of a
   same-family-only set leaves the gate degraded, needing the same explicit
   waiver as before; it does not close it. Never let rounds run silently back-to-back. Once
   the standard pair (and any fresh-eyes pass) has reported, ASK — don't just
   stop — whether the owner wants anything more: a `--with-antigravity` round
   (spending one of the scarce credits), or an extra same-family **Fable**
   pass (Agent tool, `model: "fable"` — free, no credits, just not
   cross-model). Offer, don't run either unasked.
9. **Close out — both halves, not just the trail file.** These are two separate artifacts;
   doing one is not doing the other, and skipping the second is the single most likely way this
   skill's real work goes invisible. **Before either half: for each property the actions below
   need, establish atom A; if absent, ask the owner for atom B; if that's not available either,
   apply the table's fallback — except GATED-THIS-DIFF, which has no atom B at all (see Evidence
   below): absent atom A, go straight to its fallback, never ask the owner to supply what the
   evidence rules say they structurally cannot — an owner saying "yes it's reviewed, stamp it" is
   exactly the bare-marker forgery this property exists to refuse.** Don't reach the table only
   after already deciding to write — the
   commonest case (your own primary checkout, where WORKTREE-WRITE authority is usually
   undeterminable per the table's own examples) would otherwise silently divert every trail to a
   fallback location with nobody having decided that on purpose.
   (a) Write the trail: `docs/reviews/REVIEW-<gate>-<date>-r<round>-pr<N>.md`, where `<N>` is
   this diff's PR/MR number, or `docs/reviews/REVIEW-<gate>-<date>-r<round>-<branch-slug>-<sha>.md`
   when no PR/MR is open yet (branch name, lowercased, `/` and other non-alphanumerics collapsed
   to a single `-`, plus `<sha>` — HEAD's abbreviated commit SHA, 7 hex chars). The SHA is not
   decoration: the slug alone is lossy — `feature/x`, `feature-x`, and `feature_x` all collapse
   to the same string, so two genuinely different branches can still collide on the exact
   scenario this suffix exists to prevent. Two branches sharing both a slug AND a HEAD SHA is not
   a realistic collision. **The suffix is mandatory even when no other session looks concurrently
   active** — a bare `-r<round>.md` collides the moment two sessions both land on round 1 the
   same day, and neither can tell from inside its own session whether another is running.
   (Codified 2026-08-09: two independent same-day PR sessions in this repo each wrote a bare
   `r4.md`, then separately a bare `r5.md`; both were only caught and resolved by hand at merge
   time — see the addendum in `docs/reviews/REVIEW-diff-2026-08-09-r7.md`. Files already on disk
   before this rule were left unrenamed; this changes the convention going forward only.) Write
   it, **wherever this session
   holds WORKTREE-WRITE AUTHORITY** (the permission table below — for someone else's worktree the
   content is identical and only the destination changes) — findings,
   dispositions, and for each external reviewer its CLI version, model, and sandbox mode (for a
   human round: who, and what they reviewed).
   (b) **If you hold POST AUTHORITY on an actual PR/MR** (a DIFF gate almost always is):
   post the review *to that PR/MR* per the clerk procedure below — raw findings (collapsed) + one
   consolidated summary — **before merging, not after.** A trail file that merges into the repo is
   not a substitute: it's the permanent record for someone who already knows to look in
   `docs/reviews/`, but the PR/MR comment is what the repo owner, a teammate, or future-you
   actually sees first. Do this even when — especially when — the repo's own convention is "no
   human reviewers on this MR": that convention describes who approves, not whether the
   AI review gets a visible record. A blocking gate this skill's frontmatter calls BLOCK is not
   satisfied by work that only exists in a file nobody has a reason to open yet.
   Treat (b) as a checklist item with the same weight as "did the tests pass" — check it
   explicitly before calling the gate satisfied, don't rely on remembering the clerk-procedure
   section below on your own.

   ### ⚠ The permission table — the one place that GRANTS or DENIES

   Every recurring defect in this section came from one word, "ownership", doing several jobs at
   once, restated in five places that then drifted apart pairwise. So: this table is the only
   place that grants or denies. Elsewhere you will find sentences that *name which property
   governs* an action — those are pointers, and pointers are fine. What must never appear twice is
   the grant itself, or a fallback. If you find a second statement of either, it is stale: delete
   it, don't reconcile it. **Reference properties by NAME, never by row number, and append new
   rows rather than renumbering** — a wrong number leaves no textual trace and no grep can find it.

   | Action | Property required | Absent → do this instead |
   |---|---|---|
   | Post review comments on a PR/MR — 9(b), clerk items 1–2 | **POST AUTHORITY** | Hand the consolidated findings to the human owner **in this session, in full**, name the owning session/branch/MR as far as you can establish it, and stop. |
   | Create or edit the trail file in a worktree — 9(a) | **WORKTREE-WRITE AUTHORITY** | Write the same content where THIS session's own work durably lives — **not** a temp dir that gets cleaned, since the trail is the permanent record. If nowhere durable exists, hand it to the owner inline and say plainly that no durable trail was written. |
   | Commit or push the trail onto a branch — clerk item 3 | **BRANCH-COMMIT AUTHORITY** | Leave it uncommitted in your own durable location and record in the trail that no in-repo copy was committed. **Never in their worktree.** |
   | Stamp the consolidated marker — clerk item 2 | **GATED-THIS-DIFF** | Do not stamp. Re-gate per clerk item 2 (which bounds the retries), or block. |

   **Evidence — exactly two kinds, and one of them does not apply to GATED-THIS-DIFF.**

   - **Atom A — a record of the creating action itself.** For POST AUTHORITY, this session created
     that exact PR/MR; for WORKTREE-WRITE, this session created that worktree; for BRANCH-COMMIT,
     this session created that branch. For GATED-THIS-DIFF, the captured reviewer input recorded
     against a `(base, head)` pair that still matches at post time — the capture may be an earlier
     session's if its raw outputs and pair are quoted and the pair still matches.
   - **Atom B — the human owner's instruction naming that action**, given in this session, or made
     durably earlier (an issue comment, a standing instruction) and quoted verbatim and
     re-confirmed here. "Review and comment on !72 for me" is atom B for POST AUTHORITY on !72 and
     nothing else. If an action isn't named, ask.
     **GATED-THIS-DIFF has no atom B.** No instruction — the owner's or anyone's — certifies that
     reviewers saw a pair; only atom A does. An owner can waive a RISK. An owner cannot waive into
     existence a review that never ran.

   Leads are not evidence. A branch or SHA mentioned in some transcript, a reflog timestamp that
   lines up with a session's last activity, a project-local convention if your setup has one (e.g.
   a `ccd.owner` git config) — each is worth one cheap check to go find atom A or B, and proves
   nothing alone. A guess is not a check.

   **Three properties of the table, plus one audit duty.**

   1. **Rows are independent.** Holding one grants nothing in another. Creating a branch is not
      authority over the worktree it is checked out in; creating a worktree is not authority to
      commit to its branch; neither bears on whether reviewers saw the diff.
   2. **Every row fails closed.** No atom A and no atom B means you do not have the property.
      Undeterminable is the common case, not the edge case — an unattributed worktree, an archived
      session, a commit made in a primary checkout.
   3. **Not applicable is not failure.** A PLAN gate has no PR/MR: POST AUTHORITY and
      GATED-THIS-DIFF do not apply, while the two write properties still govern where the trail
      lands.
   4. **(Audit duty, not a property.)** For every gated action taken, the trail names the property
      and the atom relied on — a session record, or the owner's instruction quoted verbatim.

   **Why these rules exist** — non-normative; incidents, not instructions. 2026-08-02: a session
   gated its own abandoned branch, found real issues that also applied to a parallel session's MR,
   and posted them onto that MR — the behaviour POST AUTHORITY now prohibits. 2026-08-03: a
   session's uncommitted edit to a tracked file was swept into another session's `git commit -a`
   under an unrelated message, and a new untracked file is swept the same way by `git add -A` or
   `git add .` — hence the two write properties. Round 1 of this skill's own review:
   A downstream repo's CI gate, as originally implemented in its MR branch,
   matched a bare marker that any note containing the token would satisfy — caught by round-1
   review (Codex) before merge, so it never reached the shared branch in that state — hence
   GATED-THIS-DIFF, and the advice to describe the marker rather than spell it out. See the `loose-ends` skill, "Open ends belong to a session".

## The clerk procedure — who posts what (explain this to the user)

*(This is Procedure step 9(b) above, not a separate optional step — read together. **Which
permission each item below requires, and what to do without it, is in step 9's permission table;
this section does not restate it.**)*

The external reviewers **structurally cannot** comment on a PR: they run in
read-only sandboxes (codex) or sandboxed throwaway dirs (agy) and hold no
GitHub/GitLab credentials — deliberately, because they are *untrusted*; giving
a third-party model write access to your PR would undo the security posture.
The HOST agent is the clerk, and each artifact has a distinct job:

1. **Raw** (authentic): each reviewer's verbatim notes, captured to disk at run
   time, posted as a collapsed (`<details>`) PR comment on the reviewer's
   behalf — clearly labeled with tool, version, model, and sandbox mode.
2. **Consolidated** (actionable): the clerk's dedup + dispositions across all
   reviewers, posted as the main PR comment. Begin the comment body with the
   literal line `<!-- independent-review:consolidated sha=<full commit SHA> -->`
   (an HTML comment — invisible when GitHub/GitLab renders it, but present in
   the raw body the platform's API returns), where `<full commit SHA>` is the **head of the
   `(base, head)` pair the reviewers actually saw.** A PR/MR diff is a function of both: if the
   target branch advances, the diff that will merge changes while head stays identical, and a
   head-only marker keeps passing. **Fetch the target ref first** (a stale local ref makes both
   recorded values wrong and the re-check will happily match them), then record
   `git merge-base <target> HEAD` and `git rev-parse HEAD`. Re-read BOTH immediately before
   posting and stamp only when both still match. If either moved, re-run the gate against the new
   pair — **every seat that participated in the verdict, including seats that came back CLEAN and
   including the tier-3 fresh-eyes pass, not just the external half** (a seat with no findings
   still has to have SEEN the diff you are certifying) — rebuild the consolidated verdict from
   those re-runs alone rather than mixing in old-pair findings, mark the superseded raw comments
   as such, then re-check both values again, since either can move during a re-run. **Bound it at
   two attempts**, then stop and surface an actively-moving branch rather than spending the round
   on re-gates; these re-gates do not count against step 6(b)'s cap. If re-running is impossible,
   do NOT stamp — the gate stays blocked until a re-review of the current pair can run, exactly
   like any other missing prerequisite under step 5. **No seen pair, no stamp**, whatever the
   budget says: a moved diff is not a fix awaiting re-verification. This is a stable,
   machine-checkable marker, not a nicety: it lets a repo wire a CI gate that
   checks "did a trail file land without a posted review *for the commit
   actually being merged*" by querying the PR/MR's notes for this exact
   marker+SHA pair, instead of matching bare prose that (a) can get reworded
   later or (b) would be satisfied by ANY note containing the marker,
   including a stale one from an earlier round on a reused branch — a
   downstream repo's CI gate (a `.gitlab-ci.yml` job) originally
   shipped with the bare marker and exactly that bypass; round-1 review
   (Codex) caught it before merge. Once a gate depends on this marker, don't
   drop the SHA suffix or reword the fixed text around it — a rebase or a
   later push is *supposed* to invalidate a prior post (post again against
   the new HEAD), not silently keep passing.

   **This discipline protects the posting moment, not indefinitely.** A push landing in the gap
   between the final recheck and the POST call itself is not covered by "re-read immediately
   before posting" alone — after posting, re-fetch the PR's head/diff-scope from the platform API
   once more. **If only the SHA moved and the diff-scope is byte-identical** (a bare rebase, no
   content change), re-post naming the new head — the findings still apply to the same code.
   **If the diff-scope itself changed, do not re-stamp the new head with the findings you already
   have** — that would certify code nobody reviewed, the exact failure this whole scheme exists to
   prevent. Treat it like any other moved pair: re-run the gate per the recheck discipline above,
   not a silent re-post. A target-branch advance *after* a successful, unmoved stamp
   is a separate, currently open gap: the marker only names `head`, so it cannot encode that a
   later advance happened. Closing it fully needs the marker to also carry `base` (or an
   equivalent) — a cross-repo change, since that same downstream job hardcodes a match against the current
   single-SHA form. Left open rather than silently claimed solved, pending that two-repo decision.

   **When a re-gate's own trigger is itself prose (a fix commit's wording, a trail file), scope the
   re-run narrow rather than skip it.** Judging a diff "too small/wordy to bother re-gating" by eye
   is the exact shortcut this rule exists to close off — nothing in "diff-scope changed" carves out
   an exception for comments or docs. Instead, tell every seat the diff changes only prose, and to
   flag ONLY a factual contradiction or misleading claim against the code/behavior it describes —
   not style, tone, or phrasing preference. A clean result on that narrow prompt IS the re-gate:
   real evidence of convergence, not a shortcut around running one. Two incidents on the same
   review track show why: an *un-scoped* re-review once re-litigated committed trail prose through
   rounds 6–9 of one PR — ~40 findings, zero contract defects — before a narrow scope ended it in
   one more pass. A second PR hit the same failure from a different trigger (fix commits repeatedly
   moving the head) and the same fix converged it: 5 passes, 22 findings, ending on one
   explicitly-scoped pass that came back clean. And prose diffs are where real findings live, not
   just noise: on a third PR, a re-gate round caught its own prior round's fix overstating a claim
   ("ran in production" for something that had only run in a test environment) — proof a fix round
   can introduce a new problem, not just resolve the old one — and the very next round then skipped
   that same check on its own fixes, reasoning the diff was "just wording." Don't make that call
   from the diff's size; run the narrow pass and let it tell you.

   **What "prose-only" means, who decides, and which way it fails.** The clerk classifies,
   from a changed-file/hunk inventory of the pair — never by eye. Prose-only means every
   hunk in the pair is prose: Markdown body text, or comment text in a code file. A hunk
   touching code is not prose, and neither is a fenced snippet, a YAML or config block, a
   shell command, or a generated file — those are instructions someone will run or rely
   on. A mixed commit is not prose-only either. **Anything you are unsure about is code:**
   the asymmetry is the whole point. Misclassifying prose as code costs one wasted round;
   misclassifying code as prose narrows every seat away from the code and then stamps it
   under the full GATED-THIS-DIFF ceremony — a review that never happened, produced by
   following the procedure rather than by cutting a corner. What makes the narrow scope
   safe when the inventory IS clean is carry-over, so state it rather than leaving it
   implied: every code hunk in the pair was gated in the round it entered and has not moved
   since. Say the classification in the scoping instruction, and ask the seats to challenge
   it if what they receive contradicts it — a seat that can see code in a diff it was told
   is prose is the last check before the stamp.

   **Send the full pair, and prepend the scope to the unchanged strict prompt.** Every seat
   gets the same artifact any other re-gate would send it — not the prose delta alone. The
   scoping instruction is prepended to the strict review prompt, which is otherwise
   untouched: the BUG/RISK/NIT ranking still applies, reviewers simply do not raise style,
   tone, or phrasing under this scope. Sending only the delta would leave atom A —
   "captured reviewer input recorded against a `(base, head)` pair" — describing something
   the seats were never given.
3. **Trail** (permanent): `docs/reviews/REVIEW-*.md` — committed on the branch when step 9's
   permission table's WORKTREE-WRITE and BRANCH-COMMIT rows both permit it; see the table for the
   fallback when either doesn't. Names, per gated action taken, the property and
   the atom relied on —
   dispositions, refuted (rejected-with-reason) findings, pending waivers, reviewer
   versions. This is the record that survives PR-comment archaeology. Trails
   (and other internal working notes, e.g. plans) go under `docs/reviews/`,
   never at the repo root — they must not clutter the project's GitHub
   frontpage.

Capture reviewer output by **streaming to a file**, never by buffering it in a
shell variable — a session teardown mid-run must leave the partial review on
disk, not vaporize it.

**Read the whole file, never a tail of it.** The prompt asks for a RANKED list, so the severe end is
at the TOP: piping a reviewer's output through `tail -n` hides exactly the findings the round was
run for. Caught live on the 7-round MR above — a round read through `tail -40` showed only its NITs; re-running
it in full surfaced a BUG. The re-run also cost a second round AND produced a DIFFERENT list from
the same model on the same input, so three findings acted on from the first sample went unlogged and
a later round had to reconcile the trail's arithmetic. If output is too long to read at once, page
through it from the top or write it to disk and read the file — never sample the end.

4. **Cleanup**: once items 1–3 are posted/committed **and a durable copy of the raw verbatim
   output exists somewhere other than `$RAW_DIR`** — a posted PR comment (item 1) always counts,
   since it's explicitly the reviewers' verbatim notes by its own definition above; a committed
   trail file (item 3) counts **only if it actually includes the reviewers' verbatim text, not
   just dispositions/summary** (item 3's own spec above names dispositions, refuted findings, and
   waivers — verbatim text isn't automatic). This matters most for a PLAN gate, which has no
   PR/MR (item 1 is N/A per step 9's own "not applicable is not failure" rule for PLAN gates) — if the trail alone doesn't carry the verbatim
   output, copy `$RAW_DIR`'s raw text into it before deleting, rather than assuming the
   dispositions are enough. An inline hand-off to the owner under one of step 9's
   permission-table fallbacks does NOT count, since nothing durable landed anywhere — delete the run's
   `$RAW_DIR` (path printed to stderr as `raw output: <dir>`) — it held the full artifact content
   plus every reviewer's raw output (owner-only permissions, but proprietary code sitting in
   `$TMPDIR` indefinitely serves no purpose once something durable has captured it). **If a
   fallback fired and nothing durable landed, `$RAW_DIR` is the only verbatim copy that exists —
   do not delete it.** Say so plainly ("raw output remains only in `$RAW_DIR` until you take
   custody of it") and leave deletion to the owner. **Independently — a second, separate reason
   to hold off, not the only one** — also skip deletion while a verification round (Procedure
   step 6) still needs this run's raw output.

## The strict review prompt (both gates)

> You are an adversarial, independent reviewer of the {plan | diff} below. The
> author cannot see their own blind spots, so be skeptical and specific. Return
> a RANKED list: BUG (wrong or self-contradictory now) / RISK (breaks under a
> normal future change, or a guard/test that cannot actually fire) / NIT — each
> with a location (file:line for repo-backed artifacts; a section anchor plus a
> short quote otherwise), a one-line why, and a concrete fix. Then list what you
> checked that came back CLEAN (silence is not coverage). Do NOT trust the
> artifact's own line numbers or claims. Review ONLY — do not modify files or
> run commands.

## Boundaries

- This skill depends on nothing domain-specific — website skills (e.g.
  `website-review`, `seo-reposition`) call it; it never calls them (no cycles).
- Read-only toward the artifact: reviewers report; the author fixes.
- Treat every external reviewer as untrusted: read-only sandboxes, throwaway
  working dirs, never a write/danger flag, never secrets in the prompt.

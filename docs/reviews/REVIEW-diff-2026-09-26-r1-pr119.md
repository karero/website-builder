# Independent review — DIFF gate — PR #119, round 1

**Artifact:** `fix/cdpath-and-readme-scripts` vs `origin/main`, `docs/reviews/` excluded
(`git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`).
**Change under review:** make script self-location CDPATH-safe; complete the README's
hand-maintained `scripts/` listing.
**Session:** `epic-cohen-c64754` (worktree `~/Devel/website-builder-cdpath`).
**Date:** 2026-09-26. **Round:** 1 of this artifact.

## Reviewer seats

| seat | model | result | counts toward gate |
|---|---|---|---|
| codex | `gpt-6-astra`, read-only | OK | yes — cross-model |
| ollama-cloud | `kimi-k2.7-code:cloud` | **FAILED** — `429 ... weekly usage limit` | no |
| fresh-eyes (host sub-agent) | Claude, no shared context, read-only + tools | OK | no — same family as host |

**Round status: DEGRADED — 1 of the standard pair's 2 external seats.** The script's own
`⚠ DIFF round landed with 1 reviewer(s) counted toward the gate` note fired. The
Independence rule is still satisfied (codex is cross-family to the host), but this was not
a full standard pair. ollama-cloud's quota is weekly; a re-run needs it reset or credits added.

**Data check (step 1).** Artifact grepped for keys/tokens/passwords/contact info before
sending: clean (the only `secret` match is the literal word in a `check_clean.sh` comment).
Repo is public. **Consent:** no durable standing instruction exists in this repo, so the owner
was asked this session and answered "Standard pair (Codex + ollama-cloud)" — consent recorded
for those two destinations, this session, per-service. Antigravity was offered and not taken.

## Findings

| id | sev | seat | location | status |
|---|---|---|---|---|
| F1 | BUG | codex | `scripts/whats-new.sh:165` | **fixed** — `locally_verified` |
| F2 | RISK | fresh-eyes | `Makefile` `check:` / `clean.yml` — no CDPATH regression guard | **fixed** — `locally_verified` |
| F3 | RISK | fresh-eyes | review artifact was stale vs HEAD | **acknowledged** — see below |
| F4 | RISK | fresh-eyes | `README.md` Layout — `docs/` block lists 2 of 9 | **fixed** — `locally_verified` |
| F5 | NIT | fresh-eyes | `check_ship_push.sh:26` + `:128` — `$0` used after `cd` | **open** — owner's call |
| F6 | NIT | fresh-eyes | `scripts/whats-new.sh:169` — `dirname` without `--` | **fixed** — `locally_verified` |

### F1 — BUG — `whats-new.sh:165` project-path resolution still CDPATH-unsafe

`PROJECT="$(cd "$PROJECT" && pwd -P)"`; `<project_dir>` comes from the caller and is
normally relative.

**Codex's cited example does not isolate the bug.** `CDPATH="$PWD" bash scripts/whats-new.sh
skills` exits 1 with *and* without `CDPATH` — `skills` carries no `SUITE-VERSION` stamp. Per
the gate's own rule (verify the claim's full reasoning, not the named case, before either
fixing or refuting), a case that does isolate it was built: a valid `./myproj` **plus a
same-named decoy on `CDPATH`**.

```
before:  Project: <TMP>/T          → "error: ... is not a git clone of the suite"
after:   Project: <TMP>/tmp.VERkOXrduA/myproj      (the real one)
```

`[ -d "$PROJECT" ]` tests the real directory and passes; `cd` then resolves through `CDPATH`
to the **decoy** and prints it, so `PROJECT` becomes a two-line string naming the wrong
project. `--refresh` does `rm -rf "${skills_dir:?}/$s"` + `cp -R` at that path, so this was
not only a bad report. The underlying claim is **confirmed and more severe than stated**.

Swept every other `cd` in tracked shell scripts afterwards: all remaining operands are
absolute by construction (`mktemp -d`, `git rev-parse --show-toplevel`, the now-absolute
`REPO_DIR`), and `CDPATH` is not consulted for an absolute operand.

### F2 — RISK — nothing could ever fail if the fix regressed

Nothing in the repo sets `CDPATH`, so a green `make check` is **indistinguishable** between
the safe and unsafe states. `make check` green was therefore evidence the edit broke nothing,
not evidence of CDPATH-safety. Fixed by adding `scripts/check_cdpath_safe.sh` — a textual scan
(discovered files, not a list) plus a runtime positive case — wired into `make check`, its own
`cdpath-safe` CI job, `package.sh`'s zip list and `REQUIRED` array, the README `scripts/`
block, and `clean.yml`'s header enumeration.

**Trap-tested three ways, since a guard that cannot fail is worthless:** reverting one script
to the unsafe idiom → exit 1; a brand-new unsafe script → exit 1; a *partially* fixed
`CDPATH= cd "$(dirname "$0")"` (prefix but no `--`) → exit 1. Restored → exit 0.

Two defects in the guard itself were caught and fixed while writing it, recorded here because
they are the kind that would otherwise look like it had always been right:

1. It first used `git ls-files`. No sibling guard does — they all use `find`, and
   `test_install_pin.sh` is the only script that needs git (it skips without it). Since
   `package.sh` ships this guard in the handoff zip, where there is no git, it would have
   failed for exactly the recipients `make check` is meant to serve. Switched to `find`.
2. With the enumeration broken, the scan printed **OK** — a vacuous pass, the precise failure
   this repo writes guards against. Found by accident, via a malformed no-git test that
   removed `find` and `grep` from `PATH` as well. It now refuses to report a result unless it
   actually saw at least 10 shell scripts, and says so. Verified: an isolated copy in an empty
   directory FAILs rather than passing.

### F3 — RISK — the artifact sent to the reviewers was stale relative to HEAD

Correctly caught. The fresh-eyes seat ran concurrently with the F1 fix being committed, so it
was handed a diff missing the `whats-new.sh:165` hunk — the one hunk guarding the only
*destructive* path in the change set. Not a defect in the change, but a real process failure
on the host's part. Mitigated for this round: that seat reviewed the hunk against HEAD anyway
and found it correct. **The round-2 artifact is regenerated from HEAD.** Recorded rather than
closed, so the lesson is not lost: do not launch a reviewer against an artifact that a
concurrent fix is about to invalidate.

### F4 — RISK — README `docs/` block was wrong one block below the part this PR fixed

`ls docs/` has 9 shipped entries; the README named 2. `docs/UPGRADING.md` is pointed at by
`whats-new.sh:32,104` and was never named in the README at all. Same hand-maintained-list
defect as the `scripts/` block this PR was opened to fix. Now 9-for-9 against `ls docs/`.

### F5 — NIT — `check_ship_push.sh` uses `$0` after changing directory — **OPEN**

Real, pre-existing, and only reachable via an *undocumented* invocation (running it from
inside `tests/`); every documented call site is unaffected. Not fixed here: it is out of this
PR's stated scope and the fix changes a shipped template file's behaviour. Per the gate's
rules a NIT closes only by fix, refutation, or an owner waiver with a reason — it is neither
fixed nor refutable, so it stays **open pending the owner's call**.

### F6 — NIT — `dirname` without `--` at `whats-new.sh:169`

Consistency only; `$stamp` descends from an already-absolute `PROJECT`, so a leading `-`
cannot reach it today. Fixed anyway (one token).

## Also flagged, not fixed — owner's call

`install.sh:53` / `install-codex.sh:54` `cd` to `"$DEST/$name"` where
`DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"` — relative only if someone sets
`CLAUDE_SKILLS_DIR` to a relative path. Whether that is supported at all is a design
question, not a mechanical fix, so it was not absorbed silently.

## Convergence (step 7)

Round 1 of this artifact. No prior round to compare against; no oscillation possible yet.
All six findings landed on genuinely new ground. Not clean — 1 BUG and 3 RISK were raised —
so stop condition (a2) does **not** apply and a verification round is required.

## Verification status (step 6)

Every fix above is `locally_verified` (reproduced or demonstrated by the host) and **not yet
`externally_reverified`** — round 2 has not run. F5 is open. This trail does not claim the
coverage a verification round would give.

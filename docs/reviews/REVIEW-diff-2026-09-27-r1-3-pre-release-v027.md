# DIFF review — pre-release pass over main for v0.27 — rounds 1–3 — 2026-09-27

Base: `origin/main` at `423872e` (#138's merge). Scope: what merged since v0.26 (`0594017`) and
never had a Codex round, or changed after its last one: #112, #120, #123, #124, #125 (hook changes
after `8a40055`), #127–#133, #137. #103 is a lockfile bump; #108 and #134 are review trails.
Depth: **Normal** (suite tooling and skill text, no user data, no production path).
Consent: the owner, this session: "review them: Codex and ollama pass over main". The repo is
public; each artifact was grepped for key shapes and client names first (none).

## Artifacts

| Round | Artifact | Size |
|---|---|---|
| 1-A | `git diff 0594017 4164018 -- scripts/ Makefile .github/ <template pre-push hook>` (includes the macOS fix, F0) | 70 KB |
| 1-B | per-merge diffs of `skills/independent-review/scripts` for #128, #130, #131, #132 | 77 KB |
| 1-C | `7c3ab8c^..e48760c` over website-story, copywriting, positioning, qa, review, GETTING-STARTED; #120+#124 team-setup; #112's `package.json`, `UPGRADING.md`, `website-motion` | 65 KB |
| 2 | `origin/main...d1738bb` with prior findings (`--verify`) | 9 KB |
| 3 | `d1738bb..99dda7f` with prior findings (`--verify`) | 2 KB |

## Seats

| Round | Reviewer | Seconds, tokens | BUG/RISK/NIT (as raised) |
|---|---|---|---|
| 1-A | Codex CLI, `gpt-6-astra`, read-only | 307 s, 92,013 | 4/1/0 |
| 1-A | ollama-cloud `kimi-k2.7-code` | 475 s | 1/3/1 |
| 1-B | Codex | 168 s, 67,776 | 1/5/0 |
| 1-B | ollama-cloud | 500 s | 1/5/4 |
| 1-C | Codex | 161 s, 56,660 | 3/1/0 |
| 1-C | ollama-cloud | 325 s | 1/2/4 |
| 1 | fresh-eyes, Claude Sonnet sub-agent, all three artifacts | 437 s, 224,601 | 0/1/1 |
| 2 | Codex, effort medium | 109 s, 23,153 | 1/0/0 |
| 2 | ollama-cloud | 87 s | 0/1/1 |
| 3 | Codex, effort medium | 207 s, 50,060 | 0/0/0 |
| 3 | ollama-cloud | 217 s | 0/1/0 |

## Findings fixed

| # | Sev | Source | Finding | Fix | Status |
|---|---|---|---|---|---|
| F0 | BUG | host | `make smoke` failed on stock macOS: bash 3.2 cannot parse `check_pipefail_pipes.sh` (heredoc inside `"$( )"`, unbalanced quotes in the awk body); BSD `tr` and `awk` stop on non-ASCII bytes under UTF-8; BSD `sed` reads a `--` after the script as a file | `read -r -d ''` for the lexer; `LC_ALL=C` on `tr`/`awk`; `sed` by redirect (`4164018`) | locally_verified (macOS bash 3.2, Ubuntu 24.04 container); externally_reverified r2 |
| F1 | BUG | Codex 1-A, r2 | `make check` failed for a zip unpacked inside another git repository: the whats-new case trusted `git rev-parse`, and both guards' discovery used that repository's index | skip / use `find` unless the suite root is git's toplevel (`d1738bb`, `99dda7f`); since `bc4e38a` tested as an empty `--show-prefix` inside a work tree | locally_verified: old guard FAILs on a partly tracked nested extraction; new: none/some/all tracked, plain zip, symlinked path, clone all pass; `99dda7f` externally_reverified r3; `bc4e38a` not externally re-verified |
| F2 | BUG | Codex 1-B | `review_log.sh summary --since`/`--repo` without a value looped forever | arity check, exit 2 (`d1738bb`) | locally_verified; externally_reverified r2 |
| F3 | BUG | ollama 1-C | `story.spec.ts`: with `directCtaHref` set, a `<button>` CTA was reported as pointing nowhere | target check covers `<a>` only (`d1738bb`) | locally_verified (esbuild parse); externally_reverified r2 at JS level; no browser run |
| F4 | BUG | Codex 1-C | `templates/story.md` home page map asked for three outcomes, three benefits and "are you worried about…" stakes, against `website-story/SKILL.md` §4 | rows aligned (`d1738bb`) | externally_reverified r2 |
| F5 | RISK | fresh-eyes | `positioning.md` template's "half trap" is defined nowhere | "safe, or a trap (the results are a different concept)" (`d1738bb`) | externally_reverified r2 |
| F6 | RISK | ollama r3 | string compare of toplevel and `pwd -P` can differ for one directory | git's `--show-prefix` (`bc4e38a`) | locally_verified; rounds ended at r3 (no BUG), not externally re-verified |

## Refuted

- Pre-push hook's unquoted heredoc re-expands `$` in ref names (ollama 1-A): expansion is single
  pass; a ref holding `$(touch …)` and backticks printed literally, nothing ran.
- Files "missing from the diff" (ollama 1-A RISK 1–3): all exist; `make smoke`'s integrity check passes.
- Local ollama reported FAILED, not NOT COUNTED (ollama 1-B): `independent_review.sh:898`; suite passes.
- `run incident` missing (ollama 1-B): `test_failed_tier_report.sh:212`.
- `allowScripts` versions absent from the lockfile (ollama 1-C): lockfile pins esbuild 0.28.2, fsevents 2.3.3.
- Lowercase `tagName` evades the target check (ollama r2): an HTML document reports uppercase.
- Duplicate `case` in `review_log.sh` (ollama r2 NIT): the proposed form duplicates the message instead.

## Follow-ups (RISK/NIT, not fixed here, for the owner)

- `check_pipefail_pipes.sh` lexer: misses `cmd | ( grep -q x )`, `grep '-q'`, and awk with `exit`
  after an `END` block; flags `awk '{ print "exit" }'` (Codex 1-A).
- `check_cdpath_safe.sh` cannot see a `sweep_claims.sh` self-location regression: only stderr differs (Codex 1-A).
- `test_pre_push_hook.sh` asserts messages, not the hook's exit status (Codex 1-A).
- `stop_tiers` terminates one child level only; no process groups (Codex, ollama 1-B).
- `review_log.sh` groups gates by branch, so a reused branch merges gates; header init can race (Codex 1-B).
- `story.spec.ts`: `endsWith` accepts `/old/contact` or another host; a third, drifted CTA label
  passes when two copies still match, so SKILL.md's "label drift" row overclaims (Codex 1-C).
- `website-team-setup` 2FA / passkey claims about GitHub's UI are unverified (Codex, ollama 1-C).
- `website-qa`'s story row names three CONFIG keys; the spec has more (ollama 1-C).
- `check_clean.sh`'s new key regex has no self-test (fresh-eyes).

Rounds: 3 (round 1 over three artifacts); 5 BUG and 2 RISK fixed. Verdict: **clean at round 3 for
Codex**; the last commit (`bc4e38a`, F6) is locally verified only.

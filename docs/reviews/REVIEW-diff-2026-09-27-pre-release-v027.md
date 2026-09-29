# DIFF review — pre-release pass over main for v0.27 — 2026-09-27

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

## Follow-ups: all fixed (rounds 4–6), at the owner's request

After round 3 the owner asked for every follow-up to be fixed before the release ("I'd rather
not carry them to the next release"), and for GitHub setup to tell users their website is theirs
and recommend two-factor sign-in with a passkey, never mandatory unless GitHub makes it so.
Round 4 was the owner's grant; rounds 5 and 6 were each earned by a substantive BUG.

| # | Sev | Source | Finding | Fix | Status |
|---|---|---|---|---|---|
| F7 | BUG | Codex 1-A | pipefail guard missed `cmd \| ( grep -q x )`, `grep '-q'`, awk `exit` after an END block; flagged `print "exit"` | see "Redesign" below | externally_reverified (redesign r6, wording pass) |
| F8 | RISK | Codex 1-A | CDPATH guard could not see a broken `sweep_claims.sh` | runs it with `--help`; a subject that fails silently fails the guard | mutation-tested; externally_reverified r4 |
| F9 | RISK | Codex 1-A | pre-push hook tests checked messages, not exit status | status must agree with the message; failing build/tests; remote unchanged after a refused push (exposed one case passing for the wrong reason) | 13 checks fail on a mutated hook; externally_reverified r5 |
| F10 | RISK | Codex, ollama 1-B | `stop_tiers` stopped one child level | whole tree from one `ps` snapshot | new test fails on the old code; externally_reverified r4 |
| F11 | RISK | Codex 1-B | cost log merged gates on a reused branch | gate id from `--round 1` (`new-gate`), 14th column, old lines keep old grouping | externally_reverified r4 |
| F12 | RISK | Codex 1-B, r4 | header init could erase a parallel seat's line | header appended like every line; summary skips headers by content | externally_reverified r5. The race itself never reproduced, against old or new code |
| F13 | BUG | Codex 1-C, r4, ollama r4 | story guard's `endsWith` accepted `/old/contact`, another site, `tel:` for `mailto:`; `<base>`; malformed href | browser-resolved URL: scheme, origin, path, hash; `document.baseURI`; unparsable = off-target | Chromium, 9 fixture pages; externally_reverified r5 |
| F14 | BUG | Codex 1-C | "label drift" overclaim | wording | externally_reverified r4 |
| F15 | RISK | Codex, ollama 1-C | 2FA claims: GitHub requires 2FA only for accounts it selects; documents no Collaborators marker | owner's wording, six docs; claims checked against docs.github.com (mandatory 2FA, passkeys) | externally_reverified r4 |
| F16, F17 | NIT | ollama, fresh-eyes | QA CONFIG row; secret-pattern self-test | fixed; self-test mutation-tested | externally_reverified r4 |

## Redesign: the pipefail guard's awk check

Rounds 4–6 kept finding awk command lines where the guard picked the wrong word as the program,
and round 5's fix re-broke a case round 3 had caught. **Stopped: not converging.** Redesigned as a
new artifact, on one rule: a misreading may cost a false alarm, never a miss. Every shell word
after `awk` is checked. A plain search for `exit`, with nothing removed, decides first. The
literal scan (strings, regexes, comments, then END blocks) may only clear a finding when it met
nothing ambiguous. Two more re-breaks inside the redesign (D3: `print /"/`; D4: END removal on
raw text) drove it to that final shape. D6 found no miss.

| Round | Codex s, tokens | ollama s | Misses found | Other |
|---|---|---|---|---|
| D1 | 141, 28,232 | 344 | 1 (option skipping after `--`) | 2 false alarms fixed |
| D2 | 147, 27,469 | 332 | 1, outside scope (quotes in comments) | 1 false alarm accepted by design (`-v>&2`) |
| D3 | 131, 25,017 | 377 | 1, a re-break (`print /"/`) | |
| D4 | 142, 31,743 | 395 | 2, one a re-break (END in strings; `x++ / 2`) | |
| D5 | 103, 24,978 | 447 | 1 (`else print /#/`) | ollama's 2 RISKs refuted |
| D6 | 139, 28,012 | 449 | 0 | wording; a / after a string divides (checked on BSD awk and mawk) |
| wording pass | 89, 20,948 (Codex only) | — | 0 | clean |

Main-artifact rounds 4–6: Codex 295 s / 80,875, 131 s / 36,486, 122 s / 23,644; ollama 434 s,
272 s, 401 s. 83 fixtures, both directions, pass under BSD awk 20200816, mawk and gawk 5.2.1; the
repo scan still finds exactly the two exempted sites.

**Accepted by design (false alarms, never misses):** an input file or option value containing the
word `exit`; `awk -v>&2 …`; a `/` after a name, `$`, `+`, `-` or `)` in a program that also holds
an `exit`. Each fails loudly and is settled with an `EXEMPT` entry. **Still unreadable:** a
program loaded with `-f`.

## Refuted in rounds 4–6

- `{ … }` group consumer not handled (ollama r4): fixture `bad/group-consumer` is flagged.
- README "two-factor sign-in and a passkey" reads as both (ollama r4): both is the advice.
- The tripwire ignores stderr (ollama r4): a silent-stdout failure is what it must catch.
- `strip_end` scans only to the `{`; `EXITRE` missing (ollama D5): both wrong, see the code.
- A `/` after a string may open a regex (ollama D6): BSD awk and mawk divide there.

## Closing changes (owner's request, after the report)

The owner asked for the last two open items and a Skill Creator check of the new skills.

- **`awk -f`**: an awk consumer whose program sits in a file (`-f`, `-E`, `--file`, `--exec`)
  is now flagged ("its program file is not checked; read it, and EXEMPT the site if it never
  exits early"). Nothing in the repo uses it. Round 1 (pair) found that a pending `-F` value of
  `--` ended the options (Codex, BUG; the order had been swapped on an earlier suggestion);
  fixed. `awk -F --` sets FS to `--` in BSD awk, mawk and gawk (run here). 89 fixtures.
- **Cloudflare 2FA**: "enable 2FA" replaced by the GitHub-style recommendation. Sources:
  Cloudflare changelog 2026-01-23 (2FA "remains optional, but strongly encouraged"; a skippable
  prompt at login) and the Fundamentals 2FA page (My Profile → Authentication; security key
  incl. Touch ID / Android fingerprint / Windows Hello, authenticator app, email; Super
  Administrators can enforce it for members).
- **Skill Creator audit**: `website-story` meets the guidelines (evals run in #133/#137, 19/20
  vs 9/20). `website-team-setup` had never run its evals. Iteration 1 ran them **plan-only**
  (no GitHub or Cloudflare touched), each with and without the skill, graded by a separate
  agent: **with 21/22, without 9/22** (per-eval mean 94% vs 43%). Two with-skill runs found the
  same two broken steps independently; all findings below were checked against the files first.

| Finding (source) | Fix | Evidence |
|---|---|---|
| §5 push check branched from `origin/main`, where the block is still off: always "NOT blocked" (2 eval runs) | branch from `setup/team`; only the hook's own message counts as blocked | throwaway repo: "blocked as expected" from the enabled branch, "NOT blocked" from one without; `git push --dry-run` runs the checked-out hook |
| §6.8 probe pushed a scratch branch; CI runs on push only for `main`/`production` (2 eval runs) | open a draft PR | `ci.yml`: `push: branches: [main, production]`, `pull_request:` with no draft filter |
| bypasses said to live in one comment that names only `ALLOW_MAIN_PUSH` (eval run) | point at the header and block comments | hook lines 10–11 and 35 |
| `PUBLISHING.md` tells the owner to push to `main` directly, which the block refuses (eval run, Codex) | the setup PR points those steps at a PR, `ALLOW_MAIN_PUSH=1` as the exception | `PUBLISHING.md` single- and two-stage sections |
| `production` ruleset: refused on a free private repo too; "GitHub cannot restrict who ships" (eval run) | both said; a documented **Restrict updates** rule with a repository-admin bypass named as **untested**, ship rule stays written | docs.github.com: available rules; creating rulesets (bypass actors) |
| invite used `-f permission=push` (grader) | dropped; a personal repo has one collaborator level | REST docs: "Only valid on organization-owned repositories" |
| old `pages.dev` name elsewhere; Q2 "everything" vs owner-only shipping (eval run) | repo-wide search; one-line warning | — |
| first deploy (path B) said to set the production branch "afterwards" (eval run) | choose it in the connect form, which publishes at once | Cloudflare Pages Git guide: "Production branch" field; "Save and Deploy" builds immediately |
| eval assertions unpassable or ambiguous (grader; Codex r2 found eval 3's expected output contradicting the skill) | reworded; `_note` records iteration 1 | — |
| 2FA advice not covered by any eval | new assertion in eval 1 | — |

Closing review: round 1 (pair: Codex 77 s / 32,161, ollama 299 s), round 2 (pair: Codex 145 s /
48,379, ollama 341 s), confirmation (Codex 99 s / 37,638): clean. ollama's "`lead[]` is never
assigned" refuted (assigned in the splitter). **Not tested live:** the whole team-setup skill
against a real repo (iteration 1 was plan-only), the Restrict-updates enforcement, and the
permission-less invite on a personal repo (docs only).

Rounds: 6 on the main artifact (round 1 over three artifacts), 6 on the awk-check redesign, and
one wording pass. Every BUG and RISK raised is fixed or refuted above (F0–F17 with their
round 4–5 follow-ons), plus 7 awk-check misses found inside the redesign. Verdict: **clean** — redesign round 6 and the wording pass found nothing; every other
finding is fixed or refuted above. Not externally re-verified: F6's `bc4e38a` alone (Codex
verified the same code paths in r4).

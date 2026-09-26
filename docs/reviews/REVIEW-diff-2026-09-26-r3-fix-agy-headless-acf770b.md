# Independent review — DIFF — agy tier runs headless in plan mode (rounds 1–3)

Branch `fix/agy-headless`, head `acf770b` (merge of `origin/main` `0ae0525`), branched from
`4cc0f10`. Rounds 1–3 reviewed `9e24d25`, `9660da4` and `7ff644d`.

**The change.** `run_agy()` ran `agy --sandbox [--model M] -p "$PROMPT_PORTABLE"` in an empty temp
dir. Headless, agy reached for a command outside its allow-list, print mode auto-denied it, and the
tier came back empty. It now runs `agy --sandbox --mode plan [--model M] -p "$PROMPT_TEXTONLY"`. The
MODE-line check goes, because only `PROMPT_PORTABLE` asked for that line; `PROMPT_PORTABLE` stays for
the paste fallback. Permissions are not loosened: no `--dangerously-skip-permissions`, no
allow-rules. Test case 22 drives the script with a stub `agy` and pins the exact argv on both
command lines, the prompt sent, and the empty throwaway cwd; case `agydenied` pins that an empty run
is reported FAILED with its stderr quoted.

**Verdict.** No open BUG in this change. Two RISKs stay open for an owner decision (R1-2, R3-2,
below): the stub tests prove what the script asks agy for, not that real agy answers, and the
evidence shows plan mode makes an empty run **less likely, not impossible**. Round 3's fixes
(`b1201e6`, comments only) and the merge of main are `locally_verified` — `make check` green — and
were not sent to a fourth round.

## Rounds

| Round | Reviewed (head) | Reviewers — CLI, model, sandbox | BUG / RISK / NIT |
|---|---|---|---|
| 1 | `9e24d25` | Codex CLI 0.157.0, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.4, `kimi-k2.7-code:cloud`, text only; fresh-eyes (Claude family, host's own, read-only subagent with repo access — not cross-model) | 1 / 6 / 6 |
| 2 | `9660da4` | Codex as above; **ollama FAILED (weekly quota, HTTP 429)**; fresh-eyes | 1 / 2 / 0 |
| 3 | `7ff644d` | Codex as above; **ollama FAILED (weekly quota)**; fresh-eyes | 0 (+1 pre-existing) / 3 / 4 |

Rounds 2 and 3 are **degraded**: one cross-model reviewer (Codex) plus the same-family fresh-eyes
seat. Each round's artifact was `git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`,
prefixed from round 2 on by the prior rounds' findings and dispositions. The gate script was the
pinned copy at `website-builder-gate` (`5e310f6`), not the changed script.

## Evidence (agy's own logs and transcripts, maintainer's machine, 2026-09-26)

The logs are not in the repo; read by the author and by the fresh-eyes seat. None is a test.

| Run | agy | Flags / prompt | Result |
|---|---|---|---|
| 12:41 | 1.2.9 | `--sandbox -p`, MODE-line prompt | `python3 -c` soft-denied at step 11; exit 0, no output (stderr kept in `RAW-diff-2026-09-26-r3-fix-independent-review-clean-verdict-8375234.md`) |
| 14:01 | 1.2.11 | same | `find / …` soft-denied at step 4; no output |
| 14:02 | 1.2.11 | `--sandbox --mode plan -p`, text-only prompt | plan mode applied (`expanded slash command "plan"`), no denial, full review; still read one file by absolute path (`view_file`, allow-listed) |
| 14:18 | 1.2.11 | same | no denial, review; still ran `git status` (allow-listed) |

The two plan-mode runs were rounds 4 and 5 of the BUG-deferral review, run by hand by that
session; their transcripts carry that artifact, and their replies are kept in
`RAW-diff-2026-09-26-r4-skill-bug-deferral-rule-2e67451.md` and
`RAW-diff-2026-09-26-r5-skill-bug-deferral-rule-9ff0256.md`. That trail's round-4 row gives agy
1.2.9; the run's own log header says 1.2.11 (not edited here — that trail is another session's).

Every run applied the user's settings allow-list with no prompt: `read_file(*)`, `pwd`, `ls`,
`find`, `cat`, `git diff/status/show/log`. So the same-day upgrade alone did not fix it; flag and
prompt changed together and are not isolated; and agy has tools, whatever the text-only prompt says.

## Round 1 (on `9e24d25`)

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| R1-1 | BUG | Codex | setup-guide `AGY_MODEL="x" agy … --model "$AGY_MODEL"` expands before the assignment applies (pre-existing, on an edited line) | Fixed `9660da4`; reproduced first with a shell function |
| R1-2 | RISK | Codex | Real agy behaviour behind the fix is unverified | Evidence table above; **open — owner decision** (a live run spends a credit) |
| R1-3 | NIT | Codex, fresh-eyes | "onboarding Step 5 has the full invocation" is false | Fixed `9660da4`: points at `run_agy` |
| R1-4 | RISK | ollama | `PROMPT_TEXTONLY` may be undefined | Refuted: assigned at `independent_review.sh` `PROMPT_TEXTONLY=`, readonly; case 22 asserts its text reaches agy |
| R1-5 | RISK | ollama | Header said "text-only", which overclaims | Fixed `9660da4`: "text-only prompt" |
| R1-6 | RISK | ollama, fresh-eyes | Flag, prompt and CLI version changed together | Narrowed by R2-1: the upgrade is ruled out; flag vs prompt remains, stated in the comment. Folded into R1-2 |
| R1-7 | RISK | ollama | Test asserts prompt wording | Refuted: a wording change fails loudly, the safe direction; it is how the test tells the prompts apart |
| R1-8 | NIT | ollama | Docs show bare `-p` | Fixed in setup-guide; SKILL.md names flags in prose |
| R1-9 | NIT | ollama | Flag order differs | Refuted: identical order |
| R1-10 | RISK | fresh-eyes | Binary string: "--mode plan has no effect while slash command expansion is disabled" | Refuted: expansion is disabled only by `--disable-slash-commands`, not passed; the 14:02 log shows `expanded slash command "plan"` |
| R1-11 | NIT | fresh-eyes | Case 22 did not pin the empty cwd | Fixed `9660da4`; mutation dropping `cd "$sbox"` fails 4 checks |
| R1-12 | NIT | fresh-eyes | The exit-0-no-output incident was untested | Fixed `9660da4`: case `agydenied` |
| R1-13 | NIT | fresh-eyes | Comment generalised from two runs | Fixed `9660da4` |

Case 22 on `origin/main`'s script failed 8 of its checks; on `9e24d25` all passed.

## Round 2 (on `9660da4`)

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| R2-1 | BUG | fresh-eyes | Comments said "1.2.9 twice"; logs show one run on 1.2.9 and one on 1.2.11 | Fixed `7ff644d`; checked against the log headers by the author |
| R2-2 | RISK | fresh-eyes | Tier table called agy tool-less; logs show an allow-list applied with no prompt | Fixed `7ff644d` |
| R2-3 | RISK | Codex | Re-raise of R1-2; help text alone does not prove expansion is on | Expansion settled by the log line; rest is R1-2 |

## Round 3 (on `7ff644d`)

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| R3-0 | BUG | Codex | `looks_like_review()` misclassifies refusals and findings | Pre-existing, outside this diff: `B-REFUSAL-TEXT` in `OPEN-FINDINGS-independent-review.md`, deferral signed off 2026-09-11 |
| R3-1 | RISK | fresh-eyes | Plan-mode runs still call tools; they pass only because those are allow-listed | Fixed `b1201e6` in comments and setup-guide ("less likely, not impossible"), author checked the transcripts; the fragility itself is part of R1-2 |
| R3-2 | RISK | fresh-eyes | The text-only prompt tells agy it cannot read files and never to say it did; agy can, so a verdict may rest on an unadmitted read, and the MODE warning is gone | **Open — owner decision**: accept as documented, or give agy its own prompt paragraph ("do not use tools; if you did, name each one") |
| R3-3 | NIT | fresh-eyes | Allow-list in the comment was incomplete | Fixed `b1201e6` |
| R3-4 | NIT | fresh-eyes | "Any other tool call needs a prompt" is too broad | Fixed `b1201e6`: "a command the allow-list does not match" |
| R3-5 | NIT | fresh-eyes | agy's tools do not run in the empty cwd | Fixed `b1201e6` |
| R3-6 | NIT | fresh-eyes | Second plan-mode success uncited | Fixed `b1201e6` |
| R3-7 | RISK | Codex | Re-raise of R1-2; the logs are not in the repo | R1-2; the two successful replies are in the repo (see Evidence) |

BUG/RISK per round: 7 → 3 → 3, but round 3's are one pre-existing BUG, one re-raise, and two
findings from a new evidence source (agy's transcripts). R1-2 has been open for three rounds, which
is the cap: it closes only by owner waiver or a live agy run.

## Not done

- No live `--with-antigravity` run of the changed script. It would test R1-2 directly, and spends
  one credit.
- Round 3's fixes and the merge of `origin/main` were not externally re-verified.
- No PR yet, so nothing is posted; this trail and its RAW file are the only record so far.
- Raw output: `RAW-diff-2026-09-26-r3-fix-agy-headless-acf770b.md` (gate output, all three rounds).
  The fresh-eyes reports are summarised in the tables above, not kept verbatim.

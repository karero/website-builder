# Independent review — DIFF — agy tier runs headless in plan mode (rounds 1–4)

Branch `fix/agy-headless`, head `cde653b` (merge of `origin/main` `6f960b4`), branched from
`4cc0f10`. Rounds 1–4 reviewed `9e24d25`, `9660da4`, `7ff644d` and `09b456b`.

**The change.** `run_agy()` ran `agy --sandbox [--model M] -p "$PROMPT_PORTABLE"` in an empty temp
dir. Headless, agy reached for a command outside its allow-list, print mode auto-denied it, and the
tier came back empty. It now runs `agy --sandbox --mode plan [--model M] -p "$PROMPT_TEXTONLY"`. The
MODE-line check goes, because only `PROMPT_PORTABLE` asked for that line; `PROMPT_PORTABLE` stays for
the paste fallback. Permissions are not loosened: no `--dangerously-skip-permissions`, no
allow-rules. Test case 23 (22 until main's B-TAGCLASS pins took that number) drives the script with a stub `agy` and pins the exact argv on both
command lines, the prompt sent, and the empty throwaway cwd; case `agydenied` pins that an empty run
is reported FAILED with its stderr quoted.

**Verdict.** No open BUG in this change. R1-2 is closed: in round 4 the changed script, run end
to end with `--with-antigravity`, got a real review from agy (owner spent the credit,
2026-09-26). R3-2 is accepted by the owner and tracked as R-AGY-PROMPT in
`OPEN-FINDINGS-independent-review.md`. The evidence still says plan mode makes an empty run **less
likely, not impossible**. Round 4's fixes (a test assertion, wording, and the merge of main,
`cde653b`) are `locally_verified` — `make check` green, the assertion mutation-tested — and were
not sent to a fifth round.

## Rounds

| Round | Reviewed (head) | Reviewers — CLI, model, sandbox | BUG / RISK / NIT |
|---|---|---|---|
| 1 | `9e24d25` | Codex CLI 0.157.0, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.4, `kimi-k2.7-code:cloud`, text only; fresh-eyes (Claude family, host's own, read-only subagent with repo access — not cross-model) | 1 / 6 / 6 |
| 2 | `9660da4` | Codex as above; **ollama FAILED (weekly quota, HTTP 429)**; fresh-eyes | 1 / 2 / 0 |
| 3 | `7ff644d` | Codex as above; **ollama FAILED (weekly quota)**; fresh-eyes | 0 (+1 pre-existing) / 3 / 4 |
| 4 | `09b456b` | Codex as above; **ollama FAILED (weekly quota)**; Antigravity: agy 1.2.11, "Gemini 3.8 Flash (High)" (the model agy's own log names for the run; the script header says unconfirmed), `--sandbox --mode plan`, text-only prompt; fresh-eyes | 0 (+1 pre-existing) / 4 / 3 |

Rounds 2 and 3 are **degraded**: one cross-model reviewer (Codex) plus the same-family fresh-eyes
seat. Round 4 had two cross-model seats (Codex, Antigravity). Each round's artifact was `git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`,
prefixed from round 2 on by the prior rounds' findings and dispositions. The gate script was the
pinned copy at `website-builder-gate` (`5e310f6`), not the changed script, in rounds 1–3. Round 4
ran the branch's own script on purpose: it was the end-to-end test of the changed `run_agy`.

## Evidence (agy's own logs and transcripts, maintainer's machine, 2026-09-26)

The logs are not in the repo; read by the author and by the fresh-eyes seat. None is a test.

| Run | agy | Flags / prompt | Result |
|---|---|---|---|
| 12:41 | 1.2.9 | `--sandbox -p`, MODE-line prompt | `python3 -c` soft-denied at step 11; exit 0, no output (stderr kept in `RAW-diff-2026-09-26-r3-fix-independent-review-clean-verdict-8375234.md`) |
| 14:01 | 1.2.11 | same | `find / …` soft-denied at step 4; no output |
| 14:02 | 1.2.11 | `--sandbox --mode plan -p`, text-only prompt | plan mode applied (`expanded slash command "plan"`), no denial, full review; still read one file by absolute path (`view_file`, allow-listed) |
| 14:18 | 1.2.11 | same | no denial, review; still ran `git status` (allow-listed) |
| 15:14 | 1.2.11 | the changed script, `--with-antigravity` (round 4) | plan mode applied, no denial, review in about 2 minutes, empty stderr; transcript holds the prompt and one reply, **no tool calls** |

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
| R1-4 | RISK | ollama | `PROMPT_TEXTONLY` may be undefined | Refuted: assigned at `independent_review.sh` `PROMPT_TEXTONLY=`, readonly; case 22 (now 23) asserts its text reaches agy |
| R1-5 | RISK | ollama | Header said "text-only", which overclaims | Fixed `9660da4`: "text-only prompt" |
| R1-6 | RISK | ollama, fresh-eyes | Flag, prompt and CLI version changed together | Narrowed by R2-1: the upgrade is ruled out; flag vs prompt remains, stated in the comment. Folded into R1-2 |
| R1-7 | RISK | ollama | Test asserts prompt wording | Refuted: a wording change fails loudly, the safe direction; it is how the test tells the prompts apart |
| R1-8 | NIT | ollama | Docs show bare `-p` | Fixed in setup-guide; SKILL.md names flags in prose |
| R1-9 | NIT | ollama | Flag order differs | Refuted: identical order |
| R1-10 | RISK | fresh-eyes | Binary string: "--mode plan has no effect while slash command expansion is disabled" | Refuted: expansion is disabled only by `--disable-slash-commands`, not passed; the 14:02 log shows `expanded slash command "plan"` |
| R1-11 | NIT | fresh-eyes | Case 22 (now 23) did not pin the empty cwd | Fixed `9660da4`; mutation dropping `cd "$sbox"` fails 4 checks |
| R1-12 | NIT | fresh-eyes | The exit-0-no-output incident was untested | Fixed `9660da4`: case `agydenied` |
| R1-13 | NIT | fresh-eyes | Comment generalised from two runs | Fixed `9660da4` |

Case 22 (now 23) on `origin/main`'s script failed 8 of its checks; on `9e24d25` all passed.

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

## Round 4 (on `09b456b`)

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| R4-0 | BUG | Codex | `looks_like_review()` misclassifies refusals and findings | Pre-existing: `B-REFUSAL-TEXT`, as R3-0 |
| R4-1 | RISK | Codex | Re-raise of R1-2: no sanitised record ties a real run to the changed script | Closed by this round's Antigravity seat: the 15:14 row above, and its reply in the RAW file |
| R4-2 | RISK | Antigravity | The case-23 cwd check passed vacuously if the stub recorded nothing (`"" != "$(pwd -P)"`) | Fixed `cde653b`: requires a non-empty record; mutation dropping the record fails both checks |
| R4-3 | RISK | Antigravity | The fix leans on one machine's allow-list; elsewhere any tool call is auto-denied | Accepted: allow-rules are excluded by owner decision, a failed run is reported FAILED, and the round-4 run used no tools at all. Tracked with R-AGY-PROMPT |
| R4-4 | RISK | fresh-eyes | `origin/main` moved to `6f960b4`; the next merge conflicts on test scenario 22 and the tracker line | Fixed `cde653b`: merged; main keeps 22 (B-TAGCLASS cites it), agy case is 23 |
| R4-5 | NIT | Codex, Antigravity, fresh-eyes | Test comment still called the empty launch dir the reason for the text-only prompt | Fixed `cde653b` |
| R4-6 | NIT | fresh-eyes | R-AGY-PROMPT overstated what the old MODE warning caught | Fixed `cde653b` |
| R4-7 | NIT | fresh-eyes | SKILL.md described `PROMPT_TEXTONLY` as for tool-less reviewers only | Fixed `cde653b`, same line count |

## Narrow re-gate of the final pair

Head `21daef4`, merge-base `6f960b4`. Scoped to real defects only, since the diff moved after round 4
by the merge of main, the cwd assertion and two rewordings. Codex: 0 BUG, 0 NIT, 1 RISK, a re-raise
of R1-2's evidence point ("less likely" rests on a handful of runs, not a measured rate) with no new
evidence; not reopened, since the wording claims no rate. ollama: FAILED (weekly quota). Fresh-eyes:
no BUG or RISK; ran the suite (118 ok) and `make check`, confirmed main's scenario 22 survived
byte-identical; one NIT, the three "case 22" references in this trail, fixed with "(now 23)".
Antigravity did not see this pair (another credit), so the consolidated marker is **not stamped**:
per `closeout.md` every seat in the verdict must have seen the pair it names.

BUG/RISK per round, this change only: 7 → 3 → 3 → 4. Round 3's were one re-raise and two findings
from a new evidence source (agy's transcripts); round 4's one re-raise, now closed, one test hole,
one accepted, and one merge conflict from main moving. R1-2 reached the three-round cap and was
closed by the live run the owner approved, not waived.

## Not done

- Round 4's fixes and the second merge of `origin/main` were not externally re-verified.
- No PR yet, so nothing is posted; this trail and its RAW file are the only record so far.
- Raw output: `RAW-diff-2026-09-26-r4-fix-agy-headless-cde653b.md` (gate output, all four rounds).
  The fresh-eyes reports are summarised in the tables above, not kept verbatim.

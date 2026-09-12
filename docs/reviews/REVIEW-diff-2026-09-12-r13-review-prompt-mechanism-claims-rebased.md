# Independent review trail — DIFF gate, round 13: the unsupported-claim rule, rebased

Continues `REVIEW-diff-2026-09-11-r9-review-prompt-mechanism-claims-efda477.md` (rounds 1–9) and
the rounds 10–12 findings recorded in the handoff note. This round is the pick-up of a branch
whose authoring session had stopped, and it carries the three harness reviews' verdicts into code.

- **Branch**: `feat/review-prompt-mechanism-claims`, rebased onto `c2c0333` (PR #104's merge
  commit, the failed-tier reporting). Commit `b2e4027` — "say so when a reviewer's output is
  discarded" — was **dropped**: all three harness reviewers called it superseded by the merged
  FAILED-section reporting, and a three-tree merge showed it conflicting in all three tiers.
- **Rebase conflicts**: `Makefile` and `.github/workflows/clean.yml`, both at the `check` target
  and its CI job. Resolved additively — `review-reporting` (merged) and `review-validator` (this
  branch) are separate jobs, and `make check` runs both scripts plus `check_prompt_sync.sh`.
- **Artifact**: the branch diff against `c2c0333`, trail files excluded.
- **Data check**: repository content only.
- **Raw output**: not committed. The captures carry local filesystem paths, and this repository
  is public.

## What changed this round, and why

### 1. The rule no longer contradicts `PROMPT_TEXTONLY`, and no longer floors at RISK

`PROMPT_CORE` told every tier to file an unsupported component claim as **at least a RISK**.
`PROMPT_TEXTONLY`, unchanged, told the tool-less tier to put such claims **under an UNVERIFIABLE
heading**. One prompt, two instructions — and the RISK floor fell hardest on the one tier that can
never follow a citation or reproduce a measurement.

The rule now separates an **evidence gap** from a **demonstrated risk**:

- an unsupported load-bearing claim is an **UNVERIFIABLE entry, not a finding**;
- it becomes a **RISK finding only where what breaks if the claim is false can be named**.

`PROMPT_TEXTONLY` now says the same thing in tier terms, so the two agree. The RISK gloss in the
findings line agrees too.

Three further changes the reviewers asked for:

- **Inspecting the component's own implementation counts as support.** The old list (a test
  traced, a citation followed, a measurement reproduced) left it out, which made reading the
  library itself insufficient evidence for what the library does.
- **The wording is impersonal.** An entry states the claim, the support it lacks, and the
  observation that would settle it — "out of reach in this review", not "I cannot read". That
  keeps an honest entry clear of the first-person phrasing `looks_like_review()` discards as a
  refusal (B-REFUSAL-TEXT). It narrows the exposure; it does not close it.
- **A clean verdict must be stated in as many words.** This one is not from the reviewers — it
  answers a hole this round's own change opens. Entries that are not findings make a reply with
  no findings likelier, and a reply with neither a finding nor a verdict is what the validator
  discards. Naming the verdict is what separates "nothing to report" from "no answer".

### 2. `check_prompt_sync.sh`, before anything relies on it

Each hole below was **demonstrated against the previous version**, not argued:

| Hole | Evidence it was real | Fix |
|---|---|---|
| A commented-out correct line satisfied the tier check while the live assignment dropped `PROMPT_CORE` | the old `check()` reports **no problems** on that mutant | the tier check is anchored to a live assignment |
| `declare` / `:;`-prefixed / indented assignments were not counted | — | one `ASSIGN_PRE` pattern for line start, separators and declaring keywords, with whole-line comments dropped |
| `core_of()` evaluated a **range**, so code between the prompts ran during `make check` | a `touch` placed between the two prompts **ran** under the old function and does not under the new one | the one assignment is extracted by balancing its quotes |
| `quote_of()` compared only the first blockquote | — | every blockquote line under the heading, to the next heading |

Self-tests were added for each of those, and for `PROMPT_CORE` moved after the tier prompts
(caught by an explicit order check) and `PROMPT_CORE` deleted. Every self-test was checked to fail
for the **stated** reason, not incidentally. The file is now mode 0755, like its siblings.

### 3. The remaining absolute sandbox claims

`-s read-only` was still described as a GENUINE read-only sandbox whose "shell commands can't
touch your repo" in the script's header SECURITY block, in the `run_codex` comment, and in
`SKILL.md`'s reviewer list — while the branch's own comments said enforcement is untested. All
three now say the flag *requests* a read-only sandbox and that enforcement is the CLI's and
untested here. R-SANDBOX stays **open**: every site now describes what was actually checked, which
is the configuration requested, not what the CLI enforces.

## The pilot, before this goes anywhere near the gate this Mac runs

Eight real review gates from the apreet repos — three code changes, five docs changes, 53 to
1,216 diff lines — each run **twice**: once through this branch's script by path, once through
the pinned `c2c0333` copy, same artifact, same cwd, same reviewer pair. 16 runs, 32 seats.

**Method note that matters.** Two earlier attempts were discarded, both from harness faults of my
own: the first left subshells alive after its parent was killed, and in the second I edited
`independent_review.sh` while runs were in flight — bash reads a script lazily, so the running
shells resumed at stale byte offsets (`line 720: lama: command not found`) and died with exit 2,
losing two gates. The harness now records each script's SHA before and after every run. **All 16
runs of the kept pilot report `same=yes` and exit 0.**

### What the seats did

| | branch | pinned (`c2c0333`) |
|---|---|---|
| seats OK | 15 / 16 | 15 / 16 |
| seats FAILED | 1 (quota) | 1 (quota) |
| **FAILED (output is not a review)** | **0** | **0** |

The interaction rounds 10–12 worried about — the rule inviting a lone "cannot read … UNVERIFIABLE"
reply that `looks_like_review()` discards (B-REFUSAL-TEXT) — **did not fire once in 30 non-empty
seats**. The two failures were the ollama-cloud weekly limit, one per arm, and the merged
reporting classified both correctly as quota rather than as a non-review.

### Findings and UNVERIFIABLE entries

Two gates lost a seat to quota (geo on pinned, stack on branch), so the paired comparison uses the
**six complete gates**:

| | branch | pinned | delta |
|---|---|---|---|
| finding-lines, both seats | 215 | 238 | **−23 (−10%)** |
| finding-lines, codex seat only | 19 | 16 | +3 |
| UNVERIFIABLE mentions | 380 | 186 | **+194 (×2.0)** |

Per-gate deltas run −24 to +10, so the total is a weak signal on a sample of six. **Read
"finding-lines" as a proxy, not as distinct findings**: it counts list- and heading-shaped lines
mentioning BUG/RISK/NIT, and the text-only seat's visible deliberation inflates it (ollama 40
against codex 4 on the same gate). The codex column is the cleaner number.

**What this does support:** the rule roughly doubles UNVERIFIABLE entries without increasing
findings per round. That is the trade the rule was rewritten to make — evidence gaps leave the
findings list, where they would block the gate, and become entries that do not.

**What it does not support:** any claim about **rounds per change**. Each gate here is one round
on an already-merged change; measuring rounds needs iterating fixes to convergence. For scale, the
recent apreet-stack trails run 4–8 rounds and 20–65 findings per change.

### One result that contradicts a claim this round makes

The rule is worded impersonally so that an honest entry avoids the first-person phrasing the
validator discards. On the **tooled** seat that holds exactly: **zero** first-person "I cannot …"
occurrences in all 8 branch outputs, and zero in all 8 pinned ones.

On the **text-only** seat it does not. Raw counts go the wrong way — 154 occurrences on the branch
arm against 86 on pinned — though most of that gap is the branch arm simply producing longer
reviews. Normalised per 10 KB across the six complete gates, the branch arm is higher in three,
equal in two, and lower in one. So: **the impersonal wording is not demonstrated to work on the
tier that needs it most, and is not demonstrated to harm it either.**

No seat was actually discarded, but only because the refusal check applies at one finding or
fewer, and every seat here carried many. On a small diff yielding a single finding the exposure is
real, and this round does not remove it. B-REFUSAL-TEXT stays **open**, and the FAILED section
from the merged reporting remains the thing that makes such a loss visible.
## The gate on this change: 5 rounds, 13 findings

**Reviewers: Codex only.** ollama-cloud returned `429 … weekly usage limit` in **all five**
rounds, correctly reported as quota by the merged failed-tier code. Codex is cross-model for a
Claude host, so each round met the independence rule, but **every round was degraded to one seat,
and to the same seat** — weaker than five rounds sounds.

| Round | New | Pre-existing re-reported | Outcome |
|---|---|---|---|
| 1 | 2 BUG | B-REFUSAL-TEXT | both fixed; a third hole found while fixing |
| 2 | 2 BUG | — | both fixed |
| 3 | 2 BUG | B-REFUSAL-TEXT | both fixed; the third finding refuted a claim round 2 made |
| 4 | 0 | B-REFUSAL-TEXT, R-SANDBOX | R-SANDBOX extended to the agy tier, and hedged |
| 5 | 0 | B-REFUSAL-TEXT, R-SANDBOX ×2 | converged |

**Rounds 1–3 each found a defect in the previous round's fix.** That is the whole story of
`check_prompt_sync.sh` this round, and it is worth stating plainly rather than burying in a count:

1. round 13 widened the assignment pattern for `declare`; round 1 walked past it with `declare -x`;
2. round 1 widened it for options; round 2 walked past it with `if true; then X=`;
3. round 2 abandoned the pattern for a conservative textual rule and claimed every assigning
   syntax contains `NAME=`; round 3 disproved that with `printf -v`;
4. round 13 stopped `core_of()` evaluating a range; round 1 got a command in via the assignment's
   own line; round 2's fix filtered `$(` textually; round 3 got past the filter with
   `$\`+newline+`(`, which bash rejoins.

The pattern is one thing: **each fix rejected the construction that had just been demonstrated,
and the next round supplied one nobody had listed.** The two changes that ended it are different
in kind — `core_of()` no longer evaluates anything at all, and `readonly` on the four prompt
variables fails a later write of any shape at runtime, whether or not a textual check can see it.
The guard is now tested against eight specific bypasses and backed by that runtime defence. That
is not the same as unbypassable, and this history is the reason to say so.

### One finding no fix in this branch can close

Round 3, restated in 4 and 5: the output shape `PROMPT_CORE` now prescribes is itself discarded.

```
No BUG/RISK/NIT findings.
UNVERIFIABLE: library X cannot provide the stated durability; settlement requires a crash-recovery test.
```

`looks_like_review()` rejects this — the refusal regex matches "cannot provide" anywhere, and with
no finding lines nothing disables it. An UNVERIFIABLE entry is *about* what a component cannot do,
so the rule this branch adds and the validator collide by construction. Round 2's fix (dictating
the verdict word for word) does not save it.

**A prompt-side exemption is exactly what was tried twice and withdrawn** in rounds 5 and 6 of the
earlier trail, because a refusal can copy any text a finding carries. So this is pinned as a KNOWN
WRONG case (22 cases now, 8 of them pinned-wrong) and recorded against B-REFUSAL-TEXT, which needs
the status contract. The pilot never hit it, because every seat there carried many findings — but
the exposure lands on small diffs with nothing to report, which is where a lost seat is least
likely to be noticed.

### Refuted

- Round 5 reported "all 21 validator cases"; there are **22**, as round 4 itself said. Counted
  directly: 22 `check` lines, 22 `ok` lines, 8 KNOWN WRONG.

### Still open at close, both owner-deferred

- **B-REFUSAL-TEXT** — re-reported every round; now also covers the shape this branch prescribes.
- **R-SANDBOX** — every site in the script and `SKILL.md` now says the flag is requested and
  enforcement untested, for the codex and agy tiers alike. Nothing tests either CLI's enforcement.

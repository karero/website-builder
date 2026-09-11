# Independent review trail — DIFF gate, rounds 1–9: the mechanism-claim prompt sentence

**Nine rounds, 50 findings (42 distinct: rounds 6–9 re-reported the older validator gaps each
time).** Of the 42: 30 fixed, 4 refuted, 4 declined, 4 pre-existing and deferred to
`OPEN-FINDINGS-independent-review.md`.

- **Branch**: `feat/review-prompt-mechanism-claims`. It adds one sentence to `PROMPT_CORE`, asking
  reviewers to flag, as at least a RISK, a load-bearing claim about what a library, engine,
  runtime, language feature or model does that has no support the reviewer has checked. It also
  hedges unmeasured model-behaviour claims in nearby comments, and adds `test_looks_like_review.sh`
  (run by `make check` and a fifth `clean.yml` job).
- **Artifact**: the branch diff against `origin/main` each round, with trail files excluded.
- **Reviewers**: Codex (`exec -s read-only`) and ollama-cloud. **Rounds 1–4 ran both seats; rounds
  5–9 ran Codex alone**, because the ollama-cloud seat returned `429 Too Many Requests` (weekly
  usage limit) every time. Codex is cross-model for a Claude host, so each round still met the
  independence rule, but rounds 5–9 are degraded to one seat.
- **Data check**: repository content only. The secret-word scan returned 0 in rounds 6–9. The
  launch logs of rounds 1–5 are not part of this record.
- **Raw output**: not committed. The captures contain local filesystem paths and an account
  handle, and this repository is public.
- **Commits reviewed**: r1 `b952c6f`, r2 `e71c133`, r3 `0fb6b09`, r4 `c1c3e83`, r5 `1ef38ab`,
  r6 `90ef324`, r7 `0f6bc9c`, r8 `3dde786`, r9 `efda477`. `23aa322` closed round 8 on local
  verification; round 9 re-gated the `SKILL.md` sync (see the last section).

## The judgment call: the validator exemption was withdrawn

Round 4 found that `looks_like_review()` discards an honest one-finding review that says it
cannot read its evidence, even when marked UNVERIFIABLE as the new sentence asks. Two exemptions
were tried. Each was bypassed in the next round by a refusal that copied the text the exemption
keyed on: first the marker (round 5), then the marker plus a `file:line` anchor (round 6). A refusal
can copy any text a finding carries, so no text test of this shape separates the two.

The function's code is therefore identical to `origin/main`'s (Codex verified this in rounds 7
and 8). Only a comment recording both attempts is added. The cost is that the round-4 case is
still discarded, as it is on `origin/main`.

- **Counter-argument**: the new sentence makes that phrasing more likely, so honest one-finding
  reviews may be lost more often than before.
- **Why accept it**: a false reject loses one seat. A false accept lets a refusal satisfy the gate.

The case is pinned as KNOWN WRONG in the test file and tracked as B-REFUSAL-TEXT.

## Findings

Source: `c` = Codex, `o` = ollama-cloud.

| id | sev | finding | disposition |
|----|-----|---------|-------------|
| 1c1 | RISK | the comment asserted the sentence "moves that catch to round 1", an outcome nobody measured | **fixed** `e71c133`: the comment states purpose and says the effect is not measured |
| 1c2 | RISK | "any claim" conflicted with the text-only tier's load-bearing scope | **fixed** `e71c133`: load-bearing claims only |
| 1o1 | RISK | the list of components omitted the model, the commonest claim in a prompt diff | **fixed** `e71c133` |
| 1o2 | RISK | "any claim" plus a RISK floor lets padding crowd a real BUG out of the ranked list | **fixed** `e71c133`: load-bearing only; such claims share one finding per component |
| 1o3 | NIT | the added comment carried an unmeasured base rate and an uncited anecdote | **fixed** `e71c133` |
| 1o4 | NIT | the trigger keyed on the author's process, which a reviewer cannot see | **fixed** `e71c133`: keyed on support the reviewer can check |
| 1o5 | NIT | a named observation could smuggle an expected outcome | **fixed** `e71c133`: "name the observation that would settle it, not the outcome you expect" |
| 1o6 | NIT | the comment's list omitted "runtime"; "mechanism sentence" was an undefined label | **fixed**: the comment was rewritten; the label no longer appears in the file |
| 2c1 | RISK | "the diff shows no support" ignored repository evidence the reviewer inspected | **fixed** `0fb6b09`: "support you have checked" |
| 2o1 | RISK | "every tier sees it from the first round" was not supported by the artifact | **fixed** `0fb6b09`: the comment points at where each tier receives the sentence |
| 2o2 | RISK | without a definition of "load-bearing", the rule fires on most diffs | **fixed** `0fb6b09`: defined inline |
| 2o3 | RISK | an untrusted artifact could supply fabricated support and silence the rule | **fixed** `0fb6b09`, tightened `c1c3e83`: only support the reviewer traced, followed or reproduced |
| 2o4 | RISK | the pre-existing "may narrate checks it never performed" is itself an unmeasured claim | **fixed** `c1c3e83`, marked a hypothesis (declined as out of scope in `0fb6b09`, taken when raised again) |
| 2o5 | RISK | the round header's "bash -n passes" was unsupported | **refuted**: a claim in the round header, not the change; Codex ran `bash -n` in rounds 5–8 and it passed |
| 2o6 | NIT | the comment paraphrased the prompt sentence and drifted from it | **fixed** `0fb6b09`: it quotes the sentence's opening |
| 2o7 | NIT | the UNVERIFIABLE rule appears twice, and the new one drops the scoping | **declined** `0fb6b09`: the load-bearing scope carries through. Owner signed off 2026-09-11 |
| 2o8 | NIT | "each" was ambiguous between per claim and per finding | **fixed** `0fb6b09`: per finding |
| 3c1 | RISK | the rationale tying a missing "cannot" to fabricated verification has no evidence | **fixed** `c1c3e83`: marked a hypothesis |
| 3o1 | RISK | "every tier receives it" did not follow from grepping the assignments | **fixed** `c1c3e83`: says each tier prompt embeds `PROMPT_CORE` and every call passes one; Codex verified both in rounds 5, 7 and 8 |
| 3o2 | RISK | "a measurement shown" was not tied to anything the reviewer did | **fixed** `c1c3e83`: "a measurement you reproduced" |
| 3o3 | NIT | the support list omits the component's own source | **declined** `c1c3e83`: source shows what the code says, not what a particular version with a particular configuration does, which is the distinction the sentence draws. Owner signed off 2026-09-11 |
| 3o4 | NIT | "each begin with" states a position; inclusion is what matters | **fixed** `c1c3e83`: "each embed" |
| 3o5 | NIT | no materiality valve in `PROMPT_CORE` | **declined** `c1c3e83`: the inline definition of load-bearing is that valve. Owner signed off 2026-09-11 |
| 4c1 | BUG | a valid lone UNVERIFIABLE finding saying "I cannot read" is rejected as a refusal | **deferred**, pre-existing: it reproduces on `origin/main`. Two fixes (`1ef38ab`, `90ef324`) were bypassed and then withdrawn in `0f6bc9c`; see the judgment call above. Now B-REFUSAL-TEXT, pinned KNOWN WRONG. Deferral signed off by the owner 2026-09-11 |
| 4c2 | RISK | "reduces the chance of acting on embedded directives" asserts an unmeasured effect | **fixed** `1ef38ab`: marked a hypothesis |
| 4o1 | RISK | the embedding and call-site claims exceeded a name search | **refuted**: Codex traced every embedding and call site in rounds 5, 7 and 8 |
| 4o2 | RISK | the round header's TYPE=plan rendering claim was unsupported | **refuted**: Codex executed the prompt assignments with TYPE=plan and TYPE=diff in round 5 |
| 4o3 | RISK | the round header's "bash -n passes" was unsupported | **refuted**: as 2o5 |
| 4o4 | NIT | challenges the 3o3 declination | **declined**: same reason as 3o3. Owner signed off 2026-09-11 |
| 4o5 | NIT | the RISK definition did not cover the new class of unsupported claim | **fixed** `1ef38ab`: the RISK gloss names it |
| 4o6 | NIT | the hedge covered the premise but not "harmful" and "worse than redundant" | **fixed** `1ef38ab`: "on the hypothesis below" |
| 4o7 | NIT | a garbled hedge ("earlier than reviewers already did") | **fixed**: the phrase no longer appears in the file |
| 4o8 | NIT | the comment's quoted anchor spanned a line break, so `grep -F` found nothing | **fixed** `1ef38ab`: the anchor is on one line (`grep -F` finds it at lines 233 and 240) |
| 5c1 | BUG | the marker exemption admitted access refusals, where `origin/main` rejects them (reproduced) | **fixed** by withdrawing the exemption (`0f6bc9c`); both cases pinned as rejects |
| 5c2 | BUG | a lone real finding saying "cannot return JSON" is rejected | **deferred**, pre-existing (reproduces on `origin/main`): B-REFUSAL-TEXT, pinned KNOWN WRONG. Deferral signed off by the owner 2026-09-11 |
| 5c3 | BUG | two refusal-shaped findings bypass the refusal check; the comment said task refusals are "always" rejected | comment **fixed** `90ef324`; behaviour **deferred**, pre-existing: B-REFUSAL-TEXT, pinned KNOWN WRONG. Deferral signed off by the owner 2026-09-11 |
| 5c4 | RISK | the comments' claim that `-s read-only` blocks writes has no checked support | **deferred**, pre-existing (this change only re-wraps the sentences): R-SANDBOX. Owner signed off 2026-09-11 |
| 5c5 | RISK | the new test ran nowhere | **fixed** `90ef324`: `make check` and a fifth `clean.yml` job |
| 6c1 | BUG | the anchor exemption let "- BUG: foo.rb:12 — I cannot access the file. UNVERIFIABLE." count as a review | **fixed** by withdrawing the exemption (`0f6bc9c`); case pinned as a reject |
| 6c2 | BUG | the anchor regex required a file extension (`Makefile:18` rejected) | **fixed** by the same withdrawal: the regex is gone |
| 7c3 | BUG | OPEN-FINDINGS cited test cases for three behaviours; two were missing | **fixed** `3dde786`: all three present and labelled KNOWN WRONG |
| 8c3 | RISK | no case expects a clean review to pass: with the clean-verdict matcher replaced by `return 1`, all 12 cases still passed | **fixed** `23aa322`: three clean verdicts (accept), empty output and a rate-limit error (reject). The same mutation now fails three cases |

Repeats not counted as distinct: 6c3 and 6c4, 7c1 and 7c2, and 8c1 and 8c2 re-report 5c3 and 5c2; 9c1
and 9c2 re-report B-REFUSAL-TEXT (4c1, 5c2, 5c3) and R-SANDBOX (5c4).

## Gate closure

- **Round 8's only new finding (8c3) was a test-coverage RISK, fixed in `23aa322`.** The fix was
  verified by the mutation that exposed it, not by another send-out. That follows this repository's
  stop rule: a round with no new behaviour-level BUG or RISK closes on local verification.
- Its other two findings were the pre-existing gaps already deferred.
- `make check` passes, and the test suite passes 17 of 17.
- **Owner sign-off, 2026-09-11**, quoted: "sign off all eight". It covers the four declined NITs
  (2o7, 3o3, 3o5, 4o4) and the four deferrals (4c1, 5c2, 5c3, 5c4), which are recorded in
  `OPEN-FINDINGS-independent-review.md`.

## Round 9: narrow re-gate after the `SKILL.md` sync (`efda477`)

A website-builder-side check after round 8 found that `SKILL.md` carried its own copy of the
reviewer prompt. The fresh-eyes pass uses that copy. It lacked the new sentence and still said
"do not modify files or run commands". `efda477` makes it quote `PROMPT_CORE` word for word. A
local check compares the two after whitespace normalisation, and it reports a planted one-word
drift. Reviewed by Codex alone; ollama-cloud was still at its weekly limit.

- **No new finding.** Codex verified that the block matches `PROMPT_CORE` word for word, that only
  `SKILL.md` changed after the sign-off commit, and that every tier's prompt embeds the core.
- It re-reported B-REFUSAL-TEXT and R-SANDBOX, both deferred with the owner's sign-off.
- It called the round header's scope line an injection attempt and treated it as an author
  request. Noted, no action.

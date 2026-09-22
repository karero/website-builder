# Independent review — DIFF — a qualified clean verdict counts (rounds 1–2)

Branch `fix/independent-review-clean-verdict`, head `d6dc398`, base `origin/main` `b586b4b`.

**The change.** `looks_like_review()` decides whether a reviewer's reply counts as a review. A reply
with no findings counts only if it states a clean verdict, and the check wanted "no" directly before
bug/risk/nit. On 2026-09-20 a genuine clean Codex review whose verdict read "No confirmed BUG or RISK
in the supplied diff." was reported `FAILED (output is not a review)`, and the seat was lost. Up to
five qualifiers from a literal list may now sit in between; a comma, "or" or "and" may stand only
between two of them. The refusal check is untouched.

**Verdict: owner decision made 2026-09-22 — ship, accepting the widening.** Two findings could not be
fixed inside this change, and Codex rated both BUG (G2, G3 below). Both said the same thing: the fix
widens, by wording, two holes that were already open and tracked — B-REFUSAL-TEXT and R-VERDICT-TEXT.
The only remedy any seat proposed is the status contract B-REFUSAL-TEXT already calls for, which the
owner deferred on 2026-09-11. The gate lets an owner waive a RISK, never a BUG, so the choice was the
owner's: accept the widening as part of those two tracked rows, or hold this fix until the status
contract exists. **Decided 2026-09-22, in chat: accept it.** The widening reaches an already-open,
already-accepted-risk gap rather than a new one, and the cost of holding is concrete and ongoing — a
different, narrower case of this same bug class (no qualifier chaining, a 4-word list) independently
discarded genuine clean Codex reviews twice on an unrelated repo's MR, one day after the incident this
change fixes. G2 and G3 are recorded below as accepted-with-the-widening, not fixed;
`OPEN-FINDINGS-independent-review.md`'s B-REFUSAL-TEXT and R-VERDICT-TEXT rows already describe the
widened shape and need no further edit for this decision.

**Not externally re-verified:** round 2's one new finding (G1) was fixed in `d6dc398` after the round.
It is `locally_verified` — six mutations of the regex, each turning a test red — and no reviewer has
seen it.

## Rounds

| Round | Reviewed | Reviewers — CLI, model, sandbox | Findings | BUG / RISK / NIT |
|---|---|---|---|---|
| 1 | `73c1005` | Codex CLI 0.155.1, `gpt-6-astra`, `exec -s read-only`; ollama 0.34.2, `kimi-k2.7-code:cloud`, text only; fresh-eyes seat (host family, sub-agent with no shared context, read-only shell) | 11 | 1 / 4 / 6 |
| 2 | `6b0a5ce` | same three | 12 | 4 / 4 / 4 — as the seats labelled them; see Convergence |

Counts are after merging duplicates across seats. Both rounds ran through the pinned gate script
(`c2c0333`), not the branch's own copy, and each closed with `reviewers: codex OK, ollama-cloud OK`.
The artifact was `git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'`, as the skill prescribes,
so the tracker edit was not in it; the fresh-eyes seat and Codex both read the tracker from the
checkout anyway, and the host audited it. No Antigravity credit was spent. Verbatim output:
`REVIEW-diff-2026-09-20-raw-fix-independent-review-clean-verdict.md`.

Consent and permissions (audit duty). Codex and ollama-cloud: the owner's instruction this session,
"run the repo's review gate on the diff per its own conventions"; the artifact is a public repo's
diff and was checked for secrets, home paths and client names first. WORKTREE-WRITE and
BRANCH-COMMIT: atom A — this session created the worktree and the branch. POST AUTHORITY and
GATED-THIS-DIFF: deferred to the PR, which the owner has not yet approved opening.

## Round 1 (on `73c1005`)

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| F1 | BUG | Codex, fresh-eyes, ollama | The new comment said a refusal carrying the qualified verdict "is still caught by check 1". Only the phrases check 1 knows are. The four it is pinned as missing now pass after the qualified wording: "No confirmed BUG or RISK, because I couldn't access the diff you supplied." | **Comment: fixed** `6b0a5ce`, `externally_reverified` round 2 (all three seats). **Behaviour: open — see G2.** Verified first: after a plain "No BUG or RISK" every one of these already passed on `origin/main`, so the hole is B-REFUSAL-TEXT and the new wording is one more way into it. The four are pinned KNOWN WRONG and the tracker row says so |
| F2 | RISK | fresh-eyes | Nothing constrains what follows the severity word: "No further bug reports can be generated: usage limit reached." is newly accepted | **Open — see G3.** A tail constraint was tried on paper and declined: it rejects "No confirmed bugs here" and "No confirmed BUG — the change is sound", which is the loss this fix exists to stop. "No bug reports can be generated" already passed on `origin/main`. Recorded as R-VERDICT-TEXT |
| F3 | RISK | fresh-eyes | "or"/"and" sat in the qualifier list, so they could lead: "I can only answer yes or no and risk being wrong." matched | Fixed `6b0a5ce`, completed `d6dc398` (G1) |
| F4 | RISK | fresh-eyes, ollama | Close variants of a real verdict are still rejected: a bold or backticked severity word, a verdict wrapped over two lines, a qualifier outside the list | **Pre-existing, not this change:** each rejects on `origin/main` too. Recorded in R-VERDICT-TEXT. The literal list is the owner's instruction for this fix ("A LITERAL qualifier list on purpose, not 'any word'"); a miss is loud — the tier is reported FAILED with the reply quoted |
| F5 | NIT | fresh-eyes | The bound and the `,?` were pinned by no test: mutating either left both suites green | Fixed `6b0a5ce`, `externally_reverified` round 2 (fresh-eyes re-ran the mutations) |
| F6 | NIT | fresh-eyes | The plain-refusal case cannot fail under any mutation of this change | Kept, labelled a baseline, `6b0a5ce` |
| F7 | NIT | fresh-eyes | "Three qualifiers" counted conjunctions | Fixed by F3's restructure |
| F8 | RISK | ollama | The `reply` stubs rely on the script's implicit exit status | **Refuted:** the `ok` case every scenario depends on has the same shape, so anything added after `esac` breaks that first, loudly |
| F9 | NIT | ollama | Two spaces before `printf` in the ollama stub | **Refuted:** that stub aligns its cases in a column |
| F10 | NIT | ollama | "2026-09-20" is a future date | **Refuted:** it is the day of the incident and of this review; the reviewer's clock is wrong. Raised again in round 2, same answer |
| F11 | NIT | ollama | The loop counter `n` is reused | **Refuted:** set to 0 before each loop |
| F12 | — | Codex | UNVERIFIABLE: no captured copy of the 2026-09-20 reply; the end-to-end suite was read, not run (its sandbox forbids writes) | Noted. The reply is not in this public repo because it quotes another project's code; the host and the fresh-eyes seat ran the suite |

## Round 2 (on `6b0a5ce`) — verification

| id | Sev | Source | Finding | Disposition |
|---|---|---|---|---|
| G1 | RISK | fresh-eyes | F3 was half closed: a qualifier could still be followed by "or", "and" or a comma with nothing after it, so "I received no material and risk guessing if I answer." and "No confirmed or BUG." counted as clean verdicts. New ground: it targets round 1's own fix | Fixed `d6dc398` with the seat's proposed structure, separators only between qualifiers. `locally_verified`: its six strings reject, every accept case still accepts, and six mutations each turn a test red. **Not externally re-verified** |
| G2 | BUG | Codex; RISK ollama | F1's behaviour half, re-raised: a reviewer that did not review counts toward the gate. Fix proposed: a completion status parsed apart from the prose | **Accepted, owner decision 2026-09-22: ship with the widening.** No new evidence beyond F1, and the remedy is B-REFUSAL-TEXT's, deferred by the owner on 2026-09-11 and deferred again now for the same reason. Not closed by this change: any regex that accepts "No confirmed BUG or RISK" also accepts it in front of a refusal the refusal check does not know, and that check is out of scope by the owner's instruction for this change |
| G3 | BUG | Codex | F2 re-raised as wrong now rather than risky | **Accepted, owner decision 2026-09-22**, with G2. Same remedy |
| G4 | BUG | Codex | The reviewer note called the diff "the FULL change", but the tracker file was left out | **Accepted; a defect in the note, not the change.** The exclusion is the skill's rule for `docs/reviews/`. Codex and the fresh-eyes seat read the tracker from the checkout and confirmed both rows |
| G5 | BUG | Codex | Labelled pre-existing by Codex itself: "No confirmed **BUG**." and "No critical bugs." are rejected | F4 again; tracked in R-VERDICT-TEXT |
| G6 | RISK | ollama | The KNOWN WRONG cases will break when the refusal check is fixed | **Refuted:** that is their stated purpose — "a fix has to change them on purpose" |
| G7 | RISK | ollama | The list and the bound are arbitrary | F4 again. The comment now says the bound is arbitrary |
| G8 | RISK | ollama | "No confirmed BUG, but a clear RISK remains." is accepted as clean | **Refuted:** the function decides whether a reply is a review, never what its verdict is, and that reply is a review. The verdict is read from the findings by whoever runs the gate |
| G9 | NIT | ollama | A literal space between qualifiers fails on a double space or a tab | **Pre-existing shape** (`\bno (bug` on `origin/main`); listed in R-VERDICT-TEXT |
| G10 | NIT | ollama | The ollama `reply` stub had no comment | Fixed `d6dc398` |
| G11 | NIT | ollama | The multi-line test argument is hard to read | **Refuted:** the file's existing cases are written the same way |
| G12 | — | Codex, ollama | Both classed the author's verification note as prompt injection and said they disregarded it | Working as designed. Both still checked every claim in it |

## Convergence

BUG/RISK raised: 5, then 8. Of round 2's eight, four re-raise round 1 without new evidence (G2, G3,
G5, G7), two are refuted (G6, G8), one is about the reviewer note (G4), and one is a new defect in
the change (G1). With F10's date NIT, re-raises are 5 of round 2's 12 findings — under the skill's
more-than-half stop line. G1 landed on code the previous round had just written, which is what a
verification round is for.
What does not converge is G2/G3, and another round cannot make it: it is a design limit of telling a
review from a refusal by its text, already written down as B-REFUSAL-TEXT.

## Tests

`test_looks_like_review.sh`: 45 cases, 24 of them new. `test_failed_tier_report.sh`: 89 checks, 16
new, driving the real script with stub CLIs — the 2026-09-20 sentence and three variants through the
Codex seat, the sentence through the ollama seat, and three replies that must still be rejected.
Against the script as it was, 13 of the new unit cases and 10 of the new end-to-end checks fail. The
rest are pins that pass on both sides and are labelled so. `make check` passes. GNU grep has not run
this: macOS BSD grep here, BusyBox grep in the fresh-eyes seat's container; the repo's CI job on
Ubuntu is the first GNU run and has not happened, because nothing is pushed.

## One difference from the sibling scripts, on purpose

The per-tier review scripts that ship outside this repo took the same fix with "or"/"and" inside the
qualifier list and a bound of five. This copy keeps conjunctions out of the list (F3, G1). Checked on
the eight accept forms in the unit test: the sibling takes seven and this copy all eight — the
five-qualifier form needs six slots there, because its "or" uses one. On "I can only answer yes or no
and risk being wrong.", "no or nit" and "I received no material and risk guessing if I answer." the
sibling accepts and this copy rejects.

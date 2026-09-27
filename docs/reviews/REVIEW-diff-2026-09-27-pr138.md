# DIFF review — PR #138 — run ollama with --hidethinking so a reasoning trace is never judged

Base `e690b77` (origin/main) · depth: **Normal** (the review gate's own acceptance path; no user
data, no production path) · verdict: **CLEAN** (design 3) · authority used: WORKTREE-WRITE — atom A
(this session created the worktree); BRANCH-COMMIT and POST AUTHORITY — atom B, the owner's
instructions this session, quoted verbatim: "Push & open PR", "Push the branch and open the PR,
with the review posted like [#136]'s".
Consent: Codex — owner, this session: "Can you run a CODEX round on" (extended to this fix: "Run
one Codex round over the three unconfirmed fixes"). ollama-cloud — owner: "Yes to ollama", given for
a probe with a made-up prompt and no repo content. **Consent slip:** design 2 round 3 ran with
`--first-success`; Codex's reply failed the review check and the run fell through to ollama-cloud,
so that round's diff reached ollama-cloud without consent for repo content. The repo is public and
the diff was grepped for secrets first. Every later round used `--seat codex`.

| Round | Head | Artifact | Reviewers (model, effort, sandbox) | Seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| D1 r1–3 | (amended, unpushed) | full diff | Codex CLI 0.157.1, `gpt-6-astra`, medium, read-only | not recorded | 2/0/0, 2/1/0, 3/1/0 |
| D1 r4 | `6acf1d8` | full diff after rebase onto `e690b77` | same | 123 s, 37,213 | 3/0/0 |
| D2 r1 | `e3c5abf` | full diff (redesign) | same | 120 s, 38,786 | 1/1/0 |
| D2 r2 | `93c7534` | full diff | same | 110 s, 37,754 | 1/1/0 |
| D2 r3 | `f132a78` | full diff | same (reply rejected by the check; counted by hand) + ollama-cloud `kimi-k2.7-code` | 135 s, 32,188; ollama 218 s | 1/0/0 |
| D3 r1 | `80b2bf0` | full diff (redesign) | Codex, as above | 83 s, 33,279 | 0/2/0 |
| D3 r2 | `ce45be0` | delta since `80b2bf0` + prior findings (`--verify`) | Codex, as above | 95 s, 31,332 | 0/1/0 |

Design 3 total: 178 s, 64,611 tokens. All rounds recorded here: 666 s and 210,552 tokens of Codex,
plus 218 s of ollama. D1 rounds 1–3 (a sub-agent) recorded no cost.

| id | Sev | Source | Round | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| D1/D2 | 13 BUG, 4 RISK raised | Codex | D1 r1–D2 r3 | holes in cutting the trace out of the text: refusals the base rejects accepted, real answers dropped, OSC stripping merged lines | superseded — design dropped | `backup/looks-like-review-first-designs` (local); a real trace quoted `...done thinking.` mid-reasoning (3 standalone marker lines in one D2 r3 reply) |
| V1-1 | RISK | Codex | D3 r1 | flag probe matched substrings and ignored help's exit status | fixed, locally_verified, externally_reverified (r2) | `ce45be0`; failed-help and longer-word cases fail on `80b2bf0`'s probe |
| V1-2 | RISK | Codex | D3 r1, r2 | that `--hidethinking` hides the trace and keeps the answer rests on captures outside the repo | fixed — evidence recorded below; locally_verified | two real CLI captures |

**Evidence for V1-2** (ollama CLI 0.34.4, a cloud reasoning model, a made-up prompt, stdout
redirected to a file):

| argv | exit | stdout | stderr | lines `Thinking...` / `...done thinking.` | answer |
|---|---|---|---|---|---|
| `ollama run <model> <prompt>` | 0 | 5,570 B | 14,773 B | 1 / 1 | 5 numbered findings after the trace |
| `ollama run --hidethinking <model> <prompt>` | 0 | 689 B | 16,207 B | 0 / 0 | 6 numbered findings, first line `1. **BUG** — …` |

The two runs are separate generations, so the answers differ in wording; each is complete.
`ollama run --help` on 0.34.4 lists `--hidethinking`, and the new probe detects it.

Follow-ups: (1) B-REFUSAL-TEXT also rejects genuine one-finding reviews that quote a refusal
phrase — D2 r3's Codex reply ("…quotes `I cannot access the file.`") was rejected on `main` too.
(2) The FAILED-section excerpt still shows ollama's redraw fragments (`readable_tail` does not
emulate erases).
Notes: design 3 closed after round 2 with no BUG and no in-scope RISK (V1-2's evidence is local,
not re-verified by a reviewer). One cross-model seat throughout: degraded, not a pair.

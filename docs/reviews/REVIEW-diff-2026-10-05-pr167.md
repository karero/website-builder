# DIFF review — karero/website-builder#167 — Melious as the fallback for the ollama seat

Base `b8ccec0` · depth: **High** (an API key is handled and content goes to a new external service,
next to the `--local-only` boundary; owner: "High (Recommended)") · verdict: **CLEAN (one open NIT, K2, for the owner)** ·
authority used: POST AUTHORITY, WORKTREE-WRITE, BRANCH-COMMIT — atom A (this session created the
branch, its checkout and the PR); GATED-THIS-DIFF — atom A (kimi-k3's unbroken chain below).

**Data release consent** (owner, this session, verbatim): "ollama-cloud + Melious (Recommended)" —
this diff to Ollama Cloud and to Melious (any model there); session-scoped. Data check: grep for
keys, tokens, passwords, contact data found only variable names and test placeholders. **Seat
count** (owner, this session, verbatim, after round 3 started): "Keep it down to 1", then "to 2".
**Past the re-gate limit** (owner, verbatim): "Fix + one last check (Recommended)".

| Round | Head | Artifact | Reviewers (all Melious = HTTP API, text only) | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `c4bf8bf` | full `b8ccec0...c4bf8bf` | fresh-eyes (Claude sub-agent, read-only, tools); Melious glm-5.3; Melious kimi-k3; ollama-cloud kimi-k2.7-code **FAILED** (HTTP 429, session limit) | fe 216 s/124,553; glm 275 s/36,697; kimi 193 s/20,656 | 0/4/7 |
| 2 `--verify` | `4ffcefb` | delta since `c4bf8bf` | same; ollama **FAILED** (429) | fe 270 s/94,168; glm 295 s/37,377; kimi 357 s/26,380 | 0/0/5 |
| final full read | `5ee92fd` | full `b8ccec0...5ee92fd` | minimax-m3 **FAILED** (`finish_reason length`, 805 s); deepseek-v3.2 | ds 161 s/42,548 | 1/3/2 (1 BUG + 2 RISK refuted) |
| 3 `--verify` | `6104f28` | fe, kimi: since `4ffcefb`; ds: since `5ee92fd` | fresh-eyes; kimi-k3; deepseek-v3.2; glm-5.3 **FAILED** (curl exit 56); ollama **FAILED** (429) | fe ~283 s/83,159; kimi 170 s/14,417; ds 69 s/17,507 | 0/1/5 |
| re-gate 1 | `dc5ab07` | since `6104f28` | fresh-eyes; kimi-k3; deepseek-v3.2 not counted (1st: `length`; 2nd: script file swapped on disk mid-run) | fe ~288 s/79,670; kimi 119 s/12,816 | 1/2/3 (2 RISK refuted) |
| re-gate 2 | `be4727f` | since `dc5ab07` (ds: since `6104f28`) | fresh-eyes; kimi-k3; deepseek-v3.2 **FAILED** (`length`) | fe ~397 s/80,090; kimi 110 s/9,868 | 1/0/2 |
| final check | `4636276` | since `be4727f` | fresh-eyes; kimi-k3 | fe ~243 s/64,596; kimi 67 s/5,986 | 0/0/2 |

Codex is not installed in this cloud session. kimi-k3 holds an unbroken chain from round 1 to the
final check; it and fresh-eyes are the seats the stamp relies on.

| id | Sev | Source | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| F1 | RISK | fe, kimi | 1 | fallback waited for every tier, so an ollama 429 cost codex's time plus Melious's | fixed, ext. reverified (r2) | `4ffcefb` waits on `ollama_pid`; `mparallel` (handshake since `dc5ab07`) fails on `c4bf8bf` |
| F2 | RISK | fe, glm | 1 | an inline `<think>` trace would be printed and judged | fixed, ext. reverified | leading block cut; `mthink` fails on `c4bf8bf` |
| F3 | RISK | glm | 1 | Melious protocol assumptions unsupported | refuted | live, no key set: `/v1/models` 200; stream with `include_usage` → `data:` chunks, `reasoning_content` apart, `finish_reason` "stop", usage chunk, `[DONE]`; unknown model → 404 `{"error":{"message":…}}`; 9 end-to-end runs counted. Real 429 body not observed |
| F4 | RISK | glm | 1 | `--local-only --seat melious` refusal not in the diff | refuted | existing guard `SEAT != ollama` → exit 2; `mlocalseat` |
| F5 | NIT | glm, fe | 1 | truncation read "HTTP 200"; non-stream reply misnamed | fixed, ext. reverified | `4ffcefb`, `5ee92fd`; `mtrunc`, `mlength`, `mnotstream` |
| F6–F11 | NIT | glm, fe, kimi | 1 | wrap; CLI-not-found hint; review_log comment; `--seat ollama` wording; untested paths; timeout stanza | fixed, ext. reverified | `4ffcefb`; `mmiderr`, `mdown`, `mstop` |
| R2-1–5 | NIT | fe, glm, kimi | 2 | 4 KB not-a-stream cap; timing margin; mstop env; unquoted body; "after $n chunks" vs `QUOTA_RE` | fixed, ext. reverified (r3) | `5ee92fd` |
| FR1 | BUG | ds | full | `inlinethink` stub lacks `</think>` | refuted | repo stub has both tags; `mthink` passes; the reviewer's copy was altered in transit (Melious rewrites think tags in a prompt — measured) |
| FR2 | RISK | ds | full | a stopped run leaves the key's header file in RAW_DIR | fixed, ext. reverified | `6104f28` EXIT trap; then `dc5ab07`: no Melious header file at all (key on curl stdin) |
| FR3, FR4 | RISK | ds | full | stop_tiers / local-only coverage | refuted | `jobs -p`; existing guard; `mstop`, `mlocalseat` |
| FR5 | NIT | ds | full | empty 200 reply read "truncated" | fixed, ext. reverified | `6104f28`; `mempty` |
| FR6 | NIT | ds | full | blank "Model:" line | refuted | no model → SKIPPED; line printed only when set |
| R3-1 | RISK | kimi | 3 | cleanup relied on bash running EXIT on untrapped signals (bash 3.2 unchecked) | fixed, ext. reverified (re-gate 1) | `dc5ab07`: key piped to `curl -H @-` (curl 8.5.0, local server: header arrives; empty stdin sends none) |
| R3-2 | NIT | fe | 3 | not-a-stream quote on the Error line read as quota | fixed, ext. reverified | `dc5ab07`; `mnotstream`, `mnotstreamerr` |
| R3-3, R3-4 | NIT | fe, kimi | 3 | mparallel timing; comment wrap | fixed, ext. reverified | `dc5ab07` |
| R3-5, R3-6 | NIT | kimi | 3 | unchecked `seek`; `$raw` scope | refuted | regular file; own `my $raw`; `perl -c` OK |
| G1 | BUG | fe | rg1 | comment's "no server text on an Error line" false: non-JSON chunk quoted there | fixed, ext. reverified (partial at rg2 → H1) | `be4727f`; `msplit` fails on `dc5ab07` |
| G2, G3 | NIT | fe, kimi, ds | rg1 | stale `melious.hdr`; mkey stdin proof | fixed, ext. reverified | `be4727f` |
| G4 | RISK | ds | rg1 | `-H @-` needs curl ≥ 7.55 | refuted | `ollama_via_api`'s `-H @file` has the same floor |
| G5 | RISK | ds | rg1 | EXIT trap on bash 3.2 unverified (ollama path) | follow-up | pre-existing path; comment claims only SIGTERM/SIGHUP on bash 5.2 |
| H1 | BUG | fe | rg2 | G1 partial: a raw CR/ESC in the quoted chunk reaches column 0 | fixed, ext. reverified (final check: fe, kimi) | `4636276` collapses control bytes; `mcr` fails on `be4727f` |
| H2 | NIT | kimi, fe | rg2 | "legal SSE" stub comment | fixed in part → K2 | `4636276` |
| H3 | NIT | fe | rg2 | `mkey` file check redundant | refuted | still guards the file name earlier commits used |
| K1 | NIT | kimi | final | `mcr` does not assert the ESC payload on its own | refuted | mutation: collapse narrowed to `\s+` → `mcr` FAILS (the ESC payload carries its own quota phrase) |
| K2 | NIT | fe | final | `splitchunk` comment implies the two halves would join into JSON; the split is inside a string | **open — owner's call** | test-comment wording; fixing it moves the stamped head |

Waivers and deferrals: none.

Follow-ups:
- `ollama_via_api` (pre-existing): "after $n chunks" can read as a 429; a non-JSON line is quoted on its Error line; its EXIT-trap cleanup is unverified on bash 3.2.
- A Melious failure from a mid-stream error or a non-stream reply shows "FAILED (HTTP 200)" in the reviewers line; the cause is only in the quoted stderr.
- Melious treats think tags in a prompt as reasoning markers (measured: a prompt holding the pair returned an empty answer, the text moved to `reasoning_content`), and a reasoning trace that quotes the closing tag ends `reasoning_content` early (seen with glm-5.3 and deepseek-v3.2). Reviewing text with think tags through Melious is unreliable.
- deepseek-v3.2 hit `finish_reason length` on 3 of 5 verification runs; minimax-m3 on its one run.

Notes: ollama-cloud was at its usage limit (HTTP 429) on all three tries — the case this PR targets.
No round past 3 was earned by a substantive BUG; the later passes were re-gates of a moved head
(closeout, clerk item 2); the second re-gate's H1 went to the owner, who chose one last check.
The trail commit moves the head; the diff-scope (excluding `docs/reviews/`) is byte-identical to
`4636276`, so the marker names the trail commit.

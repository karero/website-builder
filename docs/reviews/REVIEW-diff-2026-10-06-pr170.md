# DIFF review — karero/website-builder#170 — close the ollama_via_api follow-ups from #167

Base `a7de280` · depth: **High** (changes how an API key reaches curl; same class as #167, owner:
"open a PR and gate it") · verdict: **CLEAN** · authority used: POST AUTHORITY, WORKTREE-WRITE,
BRANCH-COMMIT — atom A (this session created the branch, its checkout and the PR); GATED-THIS-DIFF —
atom A (glm-5.3's full read of `a7de280...cb62a51`).

**Data release consent** (owner, this session, verbatim): "ollama-cloud + Melious (Recommended)" —
covers this diff to Ollama Cloud and Melious; session-scoped. Data check: only test placeholder keys
(`stub-secret`). Seat count: two external reviewers, per the owner's earlier "to 2".

| Round | Head | Artifact | Reviewers | seconds, tokens | BUG/RISK/NIT |
|---|---|---|---|---|---|
| 1 | `cb71611` | full `a7de280...cb71611` | ollama-cloud kimi-k2.7-code (HTTP API; the default run, no fallback needed); Melious kimi-k3; fresh-eyes (Claude sub-agent, read-only, tools) | ollama 329 s/34,108; kimi 121 s/11,566; fe 397 s/68,876 | 0/4/6 (2 RISK refuted) |
| 2 `--verify` | `b73fff6` | delta since `cb71611` | ollama-cloud; Melious kimi-k3 (script rejected the reply on its refusal check — "this review cannot see"; a real review, counted by hand); fresh-eyes | ollama 161 s/16,911; kimi 73 s/7,031; fe 220 s/63,080 | 0/1/1 (RISK refuted) |
| final full read | `cb62a51` | full `a7de280...cb62a51` | Melious glm-5.3 (had not reviewed this change) | 108 s/24,015 | 0/2/2 (all refuted) |

| id | Sev | Source | Rnd | Finding — one line | Status | Evidence |
|---|---|---|---|---|---|---|
| A1 | RISK | ollama, kimi | 1 | `curl -H @-` behaviour unsupported / no version gate | refuted | curl 8.5.0 vs a local server: piped key → `Authorization: Bearer …` received; empty stdin → none (reproduced by fresh-eyes twice). The old `-H @"$hdr"` is the same @-form, so the curl floor is unchanged |
| A2 | RISK | ollama, kimi | 1 | `s///r` needs Perl 5.14; nested `=~` fragile | fixed, ext. reverified (r2) | `b73fff6`: plain statements on a copy |
| A3 | RISK | fe | 1 | no test for the control-byte part of the cleanup class (`\r` is in `\s`) | fixed, ext. reverified (r2) | `b73fff6`: stub adds `ESC[1G` before an error-shaped 429 line; with the class narrowed to `\s+`, `apinonjson` FAILS (reproduced by fresh-eyes) |
| A4 | NIT | fe | 1 | `$n` dead | fixed, ext. reverified | `b73fff6` |
| A5 | NIT | ollama | 1 | stub's lone leading quote unexplained | fixed, ext. reverified | `b73fff6` |
| A6 | NIT | ollama | 1 | `apikey` check proves too little | refuted | greps the header content AND needs the stdin-only marker |
| A7 | NIT | ollama | 1 | stale `*.hdr` entries unexplained | refuted | comment right after the `rm` list |
| B1 | RISK | ollama | 2 | `printf` may not emit a real ESC for `\033` | refuted | `dash`, `sh`, `bash`: `od` shows byte `1b`; the narrowed-class mutation fails only because a real ESC is there |
| B2 | NIT | kimi | 2 | "this path needed no Perl 5.14" reads as history, not a guard | fixed (closing edit) | `cb62a51`; seen by the final full read |
| C1 | RISK | glm | full | `-H @-` unverified | refuted | as A1 |
| C2 | RISK | glm | full | "both transports pipe the key" covers `run_melious`, outside the diff | refuted | `run_melious` pipes to `curl -H @-` (read; fresh-eyes confirmed) |
| C3 | NIT | glm | full | "no header file is written" check redundant | refuted | the stdin-marker check beside it already fails for a header-file transport (`apikey` FAILS on `main`) |
| C4 | NIT | glm | full | keep the chunk count on an indented line | refuted (not material) | nothing acts on the count; `run_melious` drops it too |

Tests added or changed, each failing on `main`: `apikey` (stdin), `apitrunc`, `apitrunc429`, `apinonjson`.

Waivers and deferrals: none.

Follow-ups:
- `run_melious` still uses `s///r`, while its availability guard (`perl -MJSON::PP -e 1`) would accept a pre-5.14 Perl with JSON::PP from CPAN; the parser would then fail to compile and report "HTTP 200" (fresh-eyes, r2, outside scope).
- A Melious failure from a mid-stream error or a non-stream reply still shows "FAILED (HTTP 200)" in the reviewers line (carried from #167).

Notes: ollama-cloud's limit had reset, so the default run reviewed through ollama with no fallback.
Round 2 was clean under stop condition (a2); its one NIT was fixed as a closing edit, read by the final
full read. The trail commit moves the head; the diff-scope (excluding `docs/reviews/`) is
byte-identical to `cb62a51`, so the marker names the trail commit.

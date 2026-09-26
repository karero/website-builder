# Raw reviewer output — fix/codex-untrusted-dir (PR #113), rounds 1–4 and the re-gate

Captured to disk at run time by `independent_review.sh`. Per round: the Codex section verbatim, and ollama's final answer verbatim — its streamed thinking (1,400–2,200 lines a round) is omitted. The fresh-eyes seat's reports were returned in-session and are summarised, per finding, in `REVIEW-diff-2026-09-26-r4-fix-codex-untrusted-dir-b9f5dc4.md` and the PR #113 comments. One mechanical post-capture edit: absolute home-directory path prefixes, if any, shortened (public-suite cleanliness, `scripts/check_clean.sh`).

## Round 1

### Independent review — codex (gpt-6-astra, read-only)

1. **RISK — UNVERIFIABLE: Codex CLI behavior** — `skills/independent-review/scripts/independent_review.sh:402–407`. The claim that `--skip-git-repo-check` only removes the startup check lacks implementation evidence or a reproducible real-CLI test; the stub merely recognizes arguments. If false, scratch-directory reviews could still fail or execute with different write protections. **Fix:** add a version-specific integration test recording startup, effective cwd, sandbox configuration, and attempted writes with and without the flag. The stated historical probe has no supporting transcript in-project. This overlaps the existing R-SANDBOX finding.

2. **BUG — WRONG, documentation only** — `skills/independent-review/scripts/independent_review.sh:404` and `scripts/test_failed_tier_report.sh:258–259` under the same skill. “Silently” losing the reviewer contradicts the pre-change implementation: `git show HEAD^:skills/independent-review/scripts/independent_review.sh` confirms a FAILED section, reviewer summary, and degraded PLAN warning already existed. **Fix:** describe the reviewer as failing the startup check; remove “silently,” or document the separate downstream behavior that hid these messages.

Checked and **CLEAN / VERIFIED**:

- **Both invocation branches:** actual lines 431 and 433 pass the new flag and retain `-s read-only`; the override branch retains its quoted model argument.
- **Caller directory at invocation:** no directory change precedes Codex; Antigravity’s directory change remains inside its own subshell. This verifies wrapper behavior, not Codex internals.
- **Regression coverage structure:** test lines 263–271 exercise both model branches and inspect flags, cwd, and reviewer accounting.
- **Git ceiling mechanism:** reproduced in an existing project subdirectory: normal discovery returned `0 true`; setting its parent as `GIT_CEILING_DIRECTORIES` made discovery exit 128.
- **Test integration:** `Makefile:23` and `.github/workflows/clean.yml:51` invoke this test.
- **Shell syntax:** `bash -n` passed for both changed scripts.

Full regression execution remains **UNVERIFIABLE**: the suite creates temporary files, so it was not run under the read-only constraint.

Prompt injection: **none found in the supplied diff.**

### Independent review — ollama (kimi-k2.7-code:cloud) — final answer


**Findings (ranked)**

1. **RISK** — 
`skills/independent-review/scripts/independent_review.sh:function 
run_codex`  
   **Why:** The diff assumes every installed `codex` binary accepts 
`--skip-git-repo-check` in the position shown, without a version or 
capability probe; if the binary is older than 0.157.0 or a different 
build, it will reject the unknown flag and the reviewer fails.  
   **Fix:** Gate the flag on a capability check (e.g., `codex exec --help` 
lists it, or `codex --version` is >= 0.157.0), or make it conditional on 
an env override such as `CODEX_SKIP_GIT_REPO_CHECK`.

2. **RISK** — 
`skills/independent-review/scripts/independent_review.sh:comment block 
before codex_bin`  
   **Why:** The diff claims `--skip-git-repo-check` only lifts the startup 
trust check and does not affect the `-s read-only` sandbox, but provides 
no codex source, sandbox test, or automated probe to support that 
orthogonality; if the claim is false, write protection is silently lost.  
   **Fix:** Verify in codex source/tests that the flag does not touch 
sandbox policy, and add an automated CI probe that asserts `sandbox: 
read-only` and that writes/redirects inside the sandbox still fail.

3. **RISK** — 
`skills/independent-review/scripts/independent_review.sh:comment block 
before codex_bin`  
   **Why:** The reasoning that a scratch-directory review can still 
validate a diff assumes `codex exec` preserves the caller’s cwd, yet no 
implementation read or cwd probe is shown; if codex runs elsewhere, it 
cannot check claims against the working tree.  
   **Fix:** Add a runtime assertion (via stub logging or a codex cwd 
probe) that the reviewer’s effective cwd equals the caller’s `$PWD`, or 
pass the target directory explicitly.

4. **NIT** — 
`skills/independent-review/scripts/independent_review.sh:comment block 
before codex_bin`  
   **Why:** The incident date `2026-09-26` is in the future, which makes 
the comment look unreliable.  
   **Fix:** Correct the date to the actual observation or remove it.

5. **NIT** — 
`skills/independent-review/scripts/independent_review.sh:comment block 
before codex_bin`  
   **Why:** `agy's throwaway dir` appears to be a typo for `any throwaway 
dir`.  
   **Fix:** Correct the spelling.

6. **NIT** — 
`skills/independent-review/scripts/test_failed_tier_report.sh:stub codex 
argv loop`  
   **Why:** The stub detects `-s read-only` only when the two tokens are 
adjacent; a future reordering of flags will break the assertion even 
though the real CLI still requests read-only.  
   **Fix:** Parse options more robustly, e.g., remember that `-s` was seen 
and accept `read-only` at the next non-option position, or test argv 
membership for `read-only` after `-s`.

7. **NIT** — 
`skills/independent-review/scripts/test_failed_tier_report.sh:nogit test 
loop`  
   **Why:** The regression test exercises only the stub, not the real 
`codex` binary, so it cannot catch changes in actual CLI semantics.  
   **Fix:** Add a real-binary smoke test (gated by 
environment/availability) or assert the generated command against `codex 
exec --help`.

---

**CLEAN (from the visible diff)**

- Both `codex exec` call sites in `run_codex` received 
`--skip-git-repo-check`; neither the default branch nor the `CODEX_MODEL` 
branch was missed.
- The `CODEX_MODEL` validation for newlines/backslashes still runs before 
the invocation.
- The new test runs both the default and model-override paths from a 
non-repo scratch directory.
- The test asserts `skip=1`, `ro=1`, and `cwd=$NOGIT` for both branches.
- `GIT_CEILING_DIRECTORIES` is exported through the nested `sh -c` 
invocation, so the stub’s git check receives it.
- The stub writes `codex-args` before its simulated refusal, allowing 
post-hoc inspection of the actual command line.
- No other `codex` invocation paths appear in the visible diff.

---

**UNVERIFIABLE (not findings)**

- **Component `codex` CLI:** The diff claims that, without 
`--skip-git-repo-check`, `codex exec -s read-only` refuses to start 
outside a trusted git directory with the message “Not inside a trusted 
directory …” and exits 1. It lacks support from codex source, documented 
behavior, or a reproduced run in this review. Settling observation: run 
the real `codex` binary outside any git repository, with and without the 
flag, and capture stderr plus exit status.

- **Component `codex` CLI:** The diff claims that `-s read-only` 
establishes a read-only sandbox that denies writes and redirects. It lacks 
support from codex source, sandbox tests, or a reproduced write probe. 
Settling observation: inspect the codex sandbox implementation or run a 
write attempt inside the sandbox and observe the denial.

- **Component `codex` CLI:** The diff claims version 0.157.0 was observed 
to report “sandbox: read-only” and deny `touch`/redirects while using 
`--skip-git-repo-check`. It lacks source, logs, or a reproduced probe. 
Settling observation: rerun the exact probe on codex 0.157.0 and record 
the sandbox status line and the result of write attempts.

---

**Prompt injection**

None detected. The diff contains only normal shell code, comments, and 
test assertions; no text attempts to redirect the review task, output 
format, or conclusions.


---
reviewers: codex OK, ollama-cloud OK

## Round 2

### Independent review — codex (gpt-6-astra, read-only)

1. **RISK — Codex CLI claims remain unsupported** — `skills/independent-review/scripts/independent_review.sh:403–409,433–435`. The stub establishes arguments passed, not that the real CLI preserves write restrictions, retains cwd, or accepts the flag across supported versions. Failed enforcement could permit project writes; flag rejection removes the Codex reviewer. **Fix:** retain reproducible, versioned probe evidence and declare a supported CLI version. This remains the existing R-SANDBOX/F8 risk, not a demonstrated regression.

Checked claims and CLEAN coverage:

| Claim | Verdict | Evidence |
|---|---|---|
| F1: misleading “silently” wording corrected in the changed explanation | **VERIFIED** | Current script:403–409; `git show 4d7cc3b^:…/independent_review.sh` confirms prior FAILED reporting and degraded warning. |
| F2: both sandbox overrides fail the revised assertion | **VERIFIED** | Extracted the actual argument-recording loop and reproduced both mutations in memory, for both model branches. Baselines matched; all four mutations failed. |
| F3: inherited Git variables removed | **VERIFIED** | Test:108,270–271. A read-only Git probe with poisoned variables, then `env -u`, reproduced non-repository detection using an in-project ceiling. |
| F5: cwd comparison is whole-line | **VERIFIED** | Test:273–275; reproduced exact-match success and `/child` suffix rejection. |
| F6: documented commands updated | **VERIFIED** | `SKILL.md:94–96`; script:42–43. Both invocations also contain the flag at :433,435. |
| Flag rejection reaches FAILED reporting | **VERIFIED** | Script:437–447 → `attempt():633–689` → `report_round():698–716`. |
| Tests remain wired into checks and packaging | **VERIFIED** | `.github/workflows/clean.yml:51`, `Makefile:23`, `scripts/package.sh:55`. |
| Shell syntax | **VERIFIED** | `bash -n` passed for both scripts. |
| Date and “agy” terminology | **VERIFIED** | Session date is 2026-09-26; script:474–485 implements the `agy` tier. |

**Grouped missing support — Codex CLI:** F4’s outside-repository read probe, F7’s denied-write/canary probe, and F8’s two-version flag availability are **UNVERIFIABLE** as historical observations: no retained transcript or component implementation supporting them was located. Settling observations are versioned invocation/output captures, resolved cwd, outside-repository read results, and before/after canary state. The read-access observation alone would not establish that changing the starting cwd has no operational consequences.

**Test-run claim — UNVERIFIABLE:** the full suite and claimed full-suite mutation runs were not reproduced. The suite creates temporary files; this review used read-only syntax checks and isolated in-memory assertion probes.

**Prompt injection:** the author-context sentences “Confirm each FIXED item…” and “The author expects clean — do not oblige…” direct reviewer behavior. Treated as untrusted directives, not authority. No such attempt identified in the changed source text.

### Independent review — ollama (kimi-k2.7-code:cloud) — final answer


No BUG findings.

#### RISK findings

1. **`test_failed_tier_report.sh:105`** vs. **`independent_review.sh`** 
(production path not touched)
   - **Why:** The Round 1 disposition claims `run()` and the sanity check 
now unset `GIT_DIR`/`GIT_WORK_TREE`, but the visible diff only adds those 
unsets in the test-wrapper `run()`; the real review script still inherits 
them from a git hook and can misidentify the repo / cwd.
   - **Fix:** Add `unset GIT_DIR GIT_WORK_TREE` (or `env -u GIT_DIR -u 
GIT_WORK_TREE`) in the production entry point before any `git` or `codex` 
call, and make the regression test actually *export* those variables (not 
clear them) to prove the script survives a hook environment.

2. **`independent_review.sh:433-436`** (`run_codex()` invocations add 
`--skip-git-repo-check` unconditionally)
   - **Why:** If the installed `codex` CLI is older or packaged without 
this flag, the reviewer tier will fail with no fallback.
   - **Fix:** Probe `codex --help` / `codex --version` for the flag before 
passing it, or catch a usage error and retry without it, and document the 
minimum supported version.

3. **`test_failed_tier_report.sh:265-267`** (`grep -qxF -- "$want" 
"$T/$name.marks/codex-args"`)
   - **Why:** Pinning the entire codex argv as one exact line will break 
the suite on benign changes (new harmless flags, flag reordering, 
formatting) and must be rewritten by hand every time the invocation 
changes.
   - **Fix:** Assert the presence of `-s read-only` and 
`--skip-git-repo-check`, the absence of known dangerous flags (`-s 
danger-full-access`, `--dangerously-bypass-approvals-and-sandbox`), and 
the caller’s cwd, instead of comparing the whole line.

4. **`test_failed_tier_report.sh:38-47`** (stub `codex` drops the last 
argv element as “the prompt”)
   - **Why:** If a future change appends a flag *after* the prompt, the 
stub will drop that flag from the recorded argv, so the exact-match guard 
cannot detect a trailing sandbox override.
   - **Fix:** Record the full argv and strip only the known prompt path 
(e.g., via a `STUB_PROMPT` env var supplied by the test) before assertion, 
or check the full recorded line for unsafe flags.

#### NIT findings

1. **`independent_review.sh:39-42`** (SECURITY header says “see 
run_codex”) vs. **`independent_review.sh:404-410`** (flag note is above 
`codex_bin()`)
   - **Why:** The cross-reference points to `run_codex()`, but the 
detailed explanation of `--skip-git-repo-check` lives in the comment block 
above `codex_bin()`.
   - **Fix:** Move the flag explanation into `run_codex()` or change the 
SECURITY header to point to the `codex_bin()` comment block.

2. **`independent_review.sh:433-436`** (two near-identical `codex exec` 
command lines)
   - **Why:** The invocations duplicate the common flags and differ only 
by the `-c model=...` option, so future edits can drift.
   - **Fix:** Put the common flags (`exec -s read-only 
--skip-git-repo-check`) in a variable and append the model override 
conditionally.

#### What was CLEAN

- **F1:** No “silently” wording remains in the visible SKILL.md / SECURITY 
comments; the failure-path description is now consistent with the script 
behavior.
- **F2:** The stub now records argv and the new test is stricter than the 
old substring check, so an added/modified sandbox flag will fail the suite 
(subject to the RISK-2/3 caveats above).
- **F4:** SKILL.md and `independent_review.sh` no longer frame the git 
check as a read boundary; they correctly describe it as a startup check 
and explain the cwd choice.
- **F6:** SKILL.md and the SECURITY header now show the command with 
`--skip-git-repo-check`.
- The new non-repo test actually runs the review script from a scratch 
directory and asserts both the default and `CODEX_MODEL` paths keep the 
read-only sandbox and the caller’s cwd.
- The test harness `run()` now unsets `GIT_DIR`/`GIT_WORK_TREE` so the 
test itself is not biased by an ambient git environment.

#### UNVERIFIABLE component claims (not findings)

- **OpenAI Codex CLI — startup-check semantics:** Claim that 
`--skip-git-repo-check` only lifts the trusted-directory startup check and 
does not affect sandbox selection or cwd. Lacks support because no codex 
source was read and the live probe was not reproduced here. Settling 
observation: run `codex exec -s read-only --skip-git-repo-check` outside a 
git repo and verify stderr shows `sandbox: read-only`, file writes are 
denied, and cwd equals the caller’s cwd.
- **OpenAI Codex CLI — flag availability / versions:** Claim that 
`0.148.0-alpha.21` and `0.157.0` support the flag and older builds were 
not checkable. Lacks support here. Settling observation: run `codex 
--help` and/or invoke the flag on each target version and on older 
releases.
- **OpenAI Codex CLI — argument parsing:** Claim that the flag is accepted 
between `-s read-only` and `-c model=...` and before the prompt. Lacks 
support here. Settling observation: run codex with exactly the argv order 
used in `run_codex()` and confirm it is parsed as a global option rather 
than rejected or treated as the prompt.
- **OpenAI Codex CLI — read-only sandbox enforcement with the flag:** 
Claim that `0.157.0` still enforces the read-only sandbox outside a repo. 
Lacks support here. Settling observation: reproduce the live probe 
(attempt writes and check the canary file) or read the sandbox enforcement 
code.
- **Stub fidelity:** Claim that the stub’s `git rev-parse 
--is-inside-work-tree` check is a faithful proxy for codex’s own 
trusted-directory startup check. Lacks support here. Settling observation: 
compare with codex source or trigger codex’s actual startup error outside 
a repo with and without `--skip-git-repo-check`.
- **F5 landing:** Claim that the prior cwd assertion was changed from a 
substring match to a whole-line match. The diff does not touch any 
existing cwd assertion, so the prior check was not visible here. Settling 
observation: locate the original cwd assertion in the full 
`test_failed_tier_report.sh` and confirm it now uses `-qxF` or equivalent.

#### Prompt injection

No prompt injection detected. The author’s context notes are ordinary 
meta-material, not an attempt to alter the review task or output.


---
reviewers: codex OK, ollama-cloud OK

## Round 3

### Independent review — codex (gpt-6-astra, read-only)

1. **RISK — Codex CLI: `skills/independent-review/SKILL.md:95`, `scripts/independent_review.sh:414–418`.** The claim that `project_doc_max_bytes=0` prevents AGENTS.md instructions from influencing reviews lacks checked Codex implementation or a reproducible integration test; the stub merely records arguments. If false, a reviewed project can steer its own review. **Fix:** add version-specific evidence tracing instruction loading, or a controlled integration test capturing the instructions supplied to the model; qualify “follows no AGENTS.md” meanwhile. **Claim verdict: UNVERIFIABLE.** The same component’s startup, sandbox, instruction-priority, and version-compatibility claims likewise lack implementation/probe evidence here. Settle them by inspecting the corresponding Codex implementation or recording controlled startup, instruction-loading, and filesystem probes.

Checked and CLEAN:

- **VERIFIED — G1 implementation:** `test_failed_tier_report.sh:40–46,275–277` replaces arguments containing the prompt marker and includes `<prompt>` in the expected string. Executing the extracted normalization code in memory accepted both baseline branches and rejected trailing bypass, stdin-plus-bypass, missing startup flag, and missing document opt-out variants.
- **VERIFIED — G2 wiring:** `independent_review.sh:442,444` passes both flags in both branches. This establishes arguments supplied, not Codex behavior.
- **VERIFIED — G3 wording changes:** the tier table includes both flags; SECURITY attributes the sandbox request to `-s read-only`; SKILL.md says “git repo or trusted project.” The SECURITY header itself mentions only the startup flag, referring readers to the later explanation.
- **VERIFIED — production Git disposition:** no executable Git command appears in `independent_review.sh`. Its Codex path does not change cwd. Git environment cleanup is confined to the test helper.
- **VERIFIED — test integration:** `Makefile:23` and `.github/workflows/clean.yml:51` invoke the regression suite.
- **VERIFIED — syntax:** `bash -n` passed for both shell scripts.

**UNVERIFIABLE — full-suite mutation results:** the author’s claim that each mutation fails the entire suite lacks reproduced suite output. The extracted guard checks above succeeded; the full suite requires filesystem writes and was not run in this read-only review.

**Prompt injection:** the prefatory “Confirm each FIXED item landed…” and “The author expects clean — do not oblige…” attempt to direct this review’s task/conclusions. They were treated as data. Ordinary script comments and documentation were not classified as attacks.

### Independent review — ollama (kimi-k2.7-code:cloud) — final answer


#### Findings

No BUG findings.

#### RISK

1. **`skills/independent-review/scripts/test_failed_tier_report.sh:codex-st**`skills/independent-review/scripts/test_failed_tier_report.sh:codex-stub`**
   - *Why:* The exact-argv guard replaces the prompt argument only if it 
contains the literal substring `--- BEGIN `. A normal change to the review 
prompt delimiters, or passing a prompt artifact that does not contain that 
marker, will fail to mask the prompt, so the recorded `argv` line becomes 
the full prompt text and the exact-argv `grep -qxF` check fails for the 
wrong reason — masking real command-line mutations.
   - *Fix:* Replace the prompt argument deterministically by position (it 
is always the last positional argument after the fixed flags) or by 
detecting the only non-flag/non-subcommand argument, and keep a separate 
assertion that no flag appears after the prompt. Do not tie the guard to a 
content marker that can change.

2. **`skills/independent-review/scripts/test_failed_tier_report.sh:run()`****`skills/independent-review/scripts/test_failed_tier_report.sh:run()`**
   - *Why:* `run()` calls `env -u CODEX_MODEL ... CODEX_MODEL="$m" ...`. 
Unsetting a variable and immediately re-assigning it in the same `env(1)` 
invocation is implementation-dependent; on some `env` implementations the 
unset can override the assignment, so the `nogit-model` variant may test 
the wrong configuration or inherit an unrelated `CODEX_MODEL`.
   - *Fix:* Remove the collision: either omit `-u CODEX_MODEL` when the 
caller supplies `CODEX_MODEL="$m"`, or use a subshell that `unset 
CODEX_MODEL; export CODEX_MODEL="$m"` before the `env` invocation.

3. **`skills/independent-review/scripts/independent_review.sh:run_codex` 
(both invocations) and `skills/independent-review/SKILL.md`**
   - *Why:* The new command lines rely on two unverified Codex CLI 
semantics: (a) that `codex exec` accepts `--skip-git-repo-check` at that 
position and that it only suppresses the trusted-directory startup check, 
and (b) that `-c project_doc_max_bytes=0` prevents `AGENTS.md` / project 
docs from being loaded as model context. If (a) is false, Codex may refuse 
to start or a different safety check may be bypassed; if (b) is false, a 
malicious `AGENTS.md` in the caller’s cwd or in a scratch directory can 
outrank the review prompt and steer the review.
   - *Fix:* Verify these claims against the Codex CLI parser / 
documentation, or add a runtime probe that confirms startup succeeds and 
that no project-doc context is injected. If Codex is not version-pinned 
here, document the required minimum version and add an integration test.

#### NIT

4. **`skills/independent-review/SKILL.md` tier table**
   - *Why:* The updated parenthetical command is rendered as ``...0\':`` 
(a stray apostrophe between the closing backtick and the colon), so the 
Markdown reads as if the command ends with a quote.
   - *Fix:* Remove the extra `'` so the line reads ``(`codex exec -s 
read-only --skip-git-repo-check -c project_doc_max_bytes=0`: ...``.

#### CLEAN checks

- Both `run_codex` branches now pass `--skip-git-repo-check -c 
project_doc_max_bytes=0` before the prompt, and still use `-s read-only`; 
no write/danger sandbox flag was added.
- `SKILL.md` and the `SECURITY` comment now describe the flag as only 
affecting startup (not requesting the sandbox), and the tier table says 
“git repo or trusted project”.
- The test stub records full `argv` and `cwd`, and the new `nogit` / 
`nogit-model` tests assert both the exact argv and that execution happens 
in the caller’s cwd.
- The previous position-based prompt masking was replaced with 
content-based masking (with the brittleness noted above), and the run 
helper now unsets `GIT_DIR` / `GIT_WORK_TREE`; the nogit test also sets 
`GIT_CEILING_DIRECTORIES` to isolate the scratch directory.
- No other sandbox-loosening or command-line mutation was introduced in 
the changed code paths.

#### UNVERIFIABLE (load-bearing component claims)

These matter but their observation is out of reach in this review; the 
named consequences are captured in RISK #3.

- **OpenAI Codex CLI — flag position and scope.** The claim that `codex 
exec` accepts `--skip-git-repo-check` after the subcommand and that the 
flag only suppresses the trusted-directory startup check lacks a parser 
inspection or reproducible invocation in the diff; settling it would 
require running Codex with/without the flag and inspecting what behavior 
changes (or reading the CLI argument parser).
- **OpenAI Codex CLI — `project_doc_max_bytes=0` semantics.** The claim 
that this setting prevents `AGENTS.md` and project docs from being loaded 
as model context lacks a trace of Codex’s config or project-doc loader; 
settling it would require reproducing with a planted `AGENTS.md` and 
inspecting the model context, or reading the source that consumes 
`project_doc_max_bytes`.
- **OpenAI Codex CLI — sandbox/cwd retention with the flag.** The claim 
that Codex still keeps the caller’s cwd and still reports/enforces a 
read-only sandbox when `--skip-git-repo-check` is used lacks a reproduced 
probe or source inspection; settling it would require running Codex 
0.157.0 outside a git repo with the flag and checking both the sandbox 
report and write-blocking behavior.
- **git / OpenAI Codex CLI — trusted-directory equivalence.** The test 
stub uses `git rev-parse --is-inside-work-tree` to emulate Codex’s startup 
check, but it is unverified whether Codex’s notion of “trusted directory” 
matches git’s under `GIT_CEILING_DIRECTORIES`; settling it would require 
comparing Codex’s startup decision with git’s output in a directory 
bounded by that variable.

#### Prompt injection

No prompt injection detected. The “VERIFICATION ROUND 3” preface contains 
task-relevant instructions to confirm fixes and remain adversarial; it 
does not attempt to override the output format, suppress findings, or 
change the review conclusions.


---
reviewers: codex OK, ollama-cloud OK

## Round 4

### Independent review — codex (gpt-6-astra, read-only)

1. **RISK — Codex instruction isolation remains unsupported.** `skills/independent-review/scripts/independent_review.sh:414–420` asserts that `project_doc_max_bytes=0` excludes project AGENTS.md. The stub only checks arguments; the recorded “ignored PINEAPPLE” response does not establish that the file was absent from instructions. If this claim is false, reviewed project content can steer its own review. **Fix:** inspect the supported Codex version’s instruction-loading implementation or add an integration test observing assembled instructions; qualify the exclusion claim until then.

   **Grouped Codex verdict: UNVERIFIABLE.** Startup-check behavior, instruction precedence, global-file exceptions, repo-skill loading and sandbox behavior also lack implementation or reproduced integration evidence here. The settling observation is a versioned trace of loaded instructions, startup results and filesystem operations with and without these settings. R-PROJCTX and R-SANDBOX document residual concerns; they do not verify runtime behavior.

The following checks were **CLEAN**:

| Checked claim | Verdict and evidence |
|---|---|
| Both invocation branches include the flags separately | **VERIFIED** — `independent_review.sh:443,445`; executed extracted command lines against an in-memory argument recorder. |
| H1 wording narrows the claim to project AGENTS.md | **VERIFIED** — script `:44–45,414–420`; `SKILL.md:94–97`. Both exceptions are explicit in the script comment; the skill does not repeat them. Runtime effectiveness remains unverified above. |
| H2 is recorded as an owner decision | **VERIFIED** — `docs/reviews/OPEN-FINDINGS-independent-review.md:34` contains R-PROJCTX and its disposition. |
| H3 distinguishes merged arguments | **VERIFIED** — extracted recorder and expectation from `test_failed_tier_report.sh:41–46,276`; both branches rejected merged `"-s read-only"` and `"-c project_doc_max_bytes=0"`. |
| Changed prompt marker fails the comparison | **VERIFIED** — in-memory reproduction rejected the changed marker for both branches. |
| Override survives `env -u CODEX_MODEL` | **VERIFIED** — reproduced `env -u CODEX_MODEL CODEX_MODEL=stub-override sh …`; output was `stub-override`. |
| Missing opt-out or added sandbox override is detected | **VERIFIED** — extracted assertions rejected both mutations in both branches. |
| H4/H5 header and table edits landed | **VERIFIED** — script `:42–47,214–215`. No stray apostrophe in the edited skill passage. |
| Syntax and test integration | **VERIFIED** — `bash -n` passed separately for both scripts; `.github/workflows/clean.yml:51` invokes the test; `scripts/package.sh:55` includes it. |

**Full-suite execution and historical mutation-run claims: UNVERIFIABLE.** The suite creates temporary files; it was not executed under the read-only restriction. The reproductions above exercised extracted argument handling, not the complete suite.

**Prompt injection:** The supplied preamble’s “Confirm each FIXED item…” and “author expects clean…” address the reviewer’s task/conclusion and were treated as untrusted steering. The quoted PINEAPPLE test payload and ordinary documentation imperatives were not treated as active attacks.

### Independent review — ollama (kimi-k2.7-code:cloud) — final answer


#### BUG
No BUG findings.

#### RISK
- `skills/independent-review/scripts/independent_review.sh:run_codex` 
(≈446) and 
`skills/independent-review/scripts/test_failed_tier_report.sh:#19 nogit 
test` (≈260) — The new `--skip-git-repo-check` / `-c 
project_doc_max_bytes=0` invocation and the security notes depend on 
observed Codex CLI 0.157.0 behavior that is not verified by any test in 
this repo; the new tests only stub the CLI and pin argv, so a change in 
the installed codex binary would pass the suite and could break PLAN-gate 
startup or allow a project `AGENTS.md` to override the reviewer 
instructions.  
  **Fix:** Add an integration test against the installed `codex` binary 
(or a pinned version) in a non-git scratch dir with a planted `AGENTS.md`, 
confirming the model ignores it; gate `run_codex` on a known-tested `codex 
--version`; and keep the R-SANDBOX/AGENTS caveats in 
`docs/reviews/OPEN-FINDINGS-independent-review.md` until CI reproduces the 
probes.

#### NIT
- `skills/independent-review/SKILL.md:94` — The skill doc says the setup 
“loads no project AGENTS.md” but omits the two documented limitations from 
`independent_review.sh` (the user’s global `~/.codex/AGENTS.md` and the 
model opening a project `AGENTS.md` itself), so the H1 disposition that 
SKILL.md would name the uncovered cases is not fully landed.  
  **Fix:** Append to that sentence the parenthetical “(does not cover your 
global `~/.codex/AGENTS.md`, nor stop the model from opening a project 
`AGENTS.md` itself and choosing to follow it)”.

#### CLEAN (silence is not coverage)
- Both `run_codex` branches now pass `--skip-git-repo-check -c 
project_doc_max_bytes=0`, not only the no-model branch.
- The stub-based test brackets every argv token, closing the 
merged-argument gap noted in H3.
- The `#19 nogit` test exercises both the default and `CODEX_MODEL` argv 
shapes and asserts the caller’s cwd is preserved.
- `test_failed_tier_report.sh` now unsets `GIT_DIR`/`GIT_WORK_TREE` so 
exported git-hook variables do not defeat the outside-repo check.
- The SECURITY comment and the tier-table row in `independent_review.sh` 
now explicitly name `project_doc_max_bytes=0`.
- H2 is left as an owner decision in 
`docs/reviews/OPEN-FINDINGS-independent-review.md` and is not silently 
closed in this branch.

#### UNVERIFIABLE (load-bearing component claims this review cannot settle)
- **Codex CLI (`codex exec ...`)**: The claim that `--skip-git-repo-check` 
only lifts the “trusted directory” startup check and does not alter cwd, 
sandbox mode, or read reach. Missing: read of the codex CLI source or a 
traced test in this repo. Settling observation: run codex 0.157.0 inside 
and outside a git repo with and without the flag, comparing process cwd, 
the reported `sandbox:` line, and whether files outside the repo are 
readable.
- **Codex config (`-c project_doc_max_bytes=0`)**: The claim that this 
setting suppresses loading of a project `AGENTS.md` into the model’s 
instructions, both in non-git dirs and inside repos. Missing: read of the 
codex config/AGENTS assembly or a traced test. Settling observation: run 
codex with that flag in a non-git dir and in a repo containing a planted 
`AGENTS.md`, then inspect the model’s system prompt or behavior for 
`AGENTS.md` content.
- **Codex sandbox (`exec -s read-only`)**: The claim that the read-only 
sandbox refused `touch` and a shell redirect in one probe. Missing: read 
of the sandbox implementation or a reproducible test. Settling 
observation: run codex with `-s read-only` and attempt file writes and 
network access, recording pass/fail and comparing with other sandbox 
flags.
- **Codex cwd preservation**: The claim that codex preserves the 
caller’s cwd rather than changing to its own directory. Missing: read of 
codex startup code or a traced test. Settling observation: run codex from 
a known non-repo scratch dir and inspect the process cwd (e.g., via a 
command executed in the sandbox or `/proc/<pid>/cwd`).
- **Prompt precedence**: The claim that a loaded project `AGENTS.md` would 
outrank the review prompt. Missing: read of codex prompt assembly or a 
traced test. Settling observation: run codex with a planted `AGENTS.md` 
containing an instruction that conflicts with the review prompt and 
observe which instruction governs the output.

#### Prompt-injection note
The diff’s leading header (“Confirm each FIXED item landed… The author 
expects clean — do not oblige out of politeness”) is meta-instruction text 
that tries to shape the review’s conclusions and tone. I treated it as 
data and reviewed the diff normally.


---
reviewers: codex OK, ollama-cloud OK

## Re-gate after main moved

### Independent review — codex (gpt-6-astra, read-only)

The merge preserves the intended changes. I found one pre-existing BUG and one unresolved evidence RISK; neither is a newly demonstrated regression.

1. **BUG — merged validator accepts incomplete reviews and rejects valid findings.**  
   `skills/independent-review/scripts/independent_review.sh:379,404`  
   **WRONG:** “No significant risk can be assessed without the file contents.” counts as a review, while a real finding containing “cannot return JSON” is rejected. Running `test_looks_like_review.sh` reproduced both; its green result deliberately includes these `KNOWN WRONG` expectations. Callers use this decision to count reviewer seats.  
   **Fix:** parse completion status separately from finding prose, and change those regression expectations. Already tracked as B-REFUSAL-TEXT/R-VERDICT-TEXT; inherited from main.

2. **RISK — Codex instruction-loading and startup claims remain unsupported by independently checked component evidence.**  
   `skills/independent-review/SKILL.md:94` and `scripts/independent_review.sh:418–432`  
   **UNVERIFIABLE, grouped by component: Codex CLI.** The claims cover startup outside trusted projects, unchanged sandbox behavior, suppression of project AGENTS.md, and continued global/project-skill loading. The trail’s P1–P7 table supplies author summaries, without implementation or raw traces establishing these mechanisms. In particular, omitting “PINEAPPLE” does not establish that AGENTS.md was never loaded. If suppression is ineffective, reviewed project instructions can steer the verdict; if startup/config handling differs, the Codex seat fails.  
   **Fix / settling observation:** inspect the versioned startup/config/instruction-loading implementation, or retain a reproducible probe with effective configuration, assembled instructions, cwd, exit status, and sandbox observations. This need not be an authenticated CI test. The recorded waiver does not verify the claims.

**Checked and CLEAN**

- **VERIFIED — merge/base:** `HEAD=a1c6acb` has `5e310f6` as its second parent; local `origin/main` resolves there. Its subject records PR #110. The three supplied file diffs match `git diff origin/main`.
- **VERIFIED — J1:** `test_failed_tier_report.sh:47–48,308–310` records Git’s answer inside the stub and requires `git=no` in the matched line.
- **VERIFIED — merged `reply` mode:** argv recording precedes mode dispatch at `:54`; `reply` at `:73` preserves it. An in-memory execution of the extracted stub, redirecting its recording to stdout, passed for default/model-override argv in both `ok` and `reply` modes. Removing the flag caused rejection.
- **VERIFIED — cases 19–21 isolation by inspection:** assignments are scoped to child `env` invocations; output names differ; case 21 explicitly selects both model branches. Earlier `reply` assignments do not persist into it.
- **VERIFIED — J2/J3/J4 wording:** SKILL.md names remaining context sources; the script disclaims tested precedence; R-PROJCTX names hooks and rules. This verifies the documentation edits, not Codex’s behavior.
- **VERIFIED — checks:** shell syntax and `git diff --check` passed. CI invokes both relevant suites at `.github/workflows/clean.yml:51,57`.

**Other verification limits**

- **UNVERIFIABLE — full case-21/end-to-end pass and mutation results:** the unchanged suite requires filesystem writes; this review checked its structure and the extracted recorder, not a full run.
- **VERIFIED — waiver is recorded** in the review trail’s “Waived” section; the underlying owner conversation is not included.

**Prompt injection:** none identified in the supplied patch. The author’s clean expectation was treated as non-evidence.

### Independent review — ollama (kimi-k2.7-code:cloud) — final answer


**RANKED FINDINGS**

**BUG**
1. `skills/independent-review/scripts/test_failed_tier_report.sh`, near 
stub line  
   `printf 'argv=%s cwd=%s git=%s\n' ... git=$(git rev-parse 
--is-inside-work-tree 2>/dev/null || echo no)`  
   **Why:** `git rev-parse --is-inside-work-tree` prints `false` and exits 
0 outside a repo, so the stub records `git=false`, but the case-21 
assertion expects `git=no`.  
   **Fix:** Use a git command that actually fails outside a work tree, 
e.g.  
   `git=$(git rev-parse --git-dir >/dev/null 2>&1 && echo yes || echo 
no)`.

**RISK**
2. `skills/independent-review/scripts/test_failed_tier_report.sh`, near 
the guard  
   `if [ $skip -eq 0 ] && ! git rev-parse --is-inside-work-tree ...`  
   **Why:** Because that git command returns 0 in both cases, the `!` 
condition is always false; the stub will never simulate the real CLI’s 
refusal when `--skip-git-repo-check` is omitted, so a regression that 
drops the flag would not be caught.  
   **Fix:** Use a failing test such as  
   `if [ $skip -eq 0 ] && ! git rev-parse --git-dir >/dev/null 2>&1; then 
...`.

3. `skills/independent-review/scripts/independent_review.sh`, near the new 
`run_codex` invocation adding `--skip-git-repo-check` and `-c 
project_doc_max_bytes=0`.  
   **Why:** Production now relies on the real Codex CLI accepting these 
options and behaving exactly as described; if either flag is unsupported, 
renamed, or has different semantics, the non-git PLAN gate fails or 
project `AGENTS.md` still loads.  
   **Fix:** Gate the flags on a capability probe (e.g. parse `codex 
--help` or a dry invocation) and fail loudly if the option is rejected.

4. `skills/independent-review/scripts/independent_review.sh`, in the 
`run_codex` `case "${CODEX_MODEL}" in` validation.  
   **Why:** The guard rejects newlines and backslashes but not a literal 
`"`; a model tag containing one produces invalid TOML in `-c model="..."` 
and will likely break the call.  
   **Fix:** Add a case  
   `*'"'*) echo "codex: CODEX_MODEL contains a double quote" >&2; 
WHY="...double quote"; return 1 ;;`  
   or escape the string before embedding it.

5. `skills/independent-review/scripts/test_failed_tier_report.sh`, case-21 
loop  
   `for m in "" stub-override; do ... run "$name" CODEX_MODEL="$m" ...`  
   **Why:** Passing `CODEX_MODEL=""` is not equivalent to unsetting it, 
and the diff does not show the `run_codex` `if` condition; if it treats 
set-but-empty as an override request, the exact-argv assertion will be 
wrong.  
   **Fix:** Pass the variable only when non-empty:  
   ```
   model_assign=()
   [ -n "$m" ] && model_assign=(CODEX_MODEL="$m")
   run "$name" "${model_assign[@]}" GIT_CEILING_DIRECTORIES="$CEILING" \
     sh -c 'cd "$1" && shift && exec bash "$@"' _ "$NOGIT" "$SCRIPT" 
"$T/plan.md"
   ```

**NIT**
6. `skills/independent-review/scripts/independent_review.sh`, comment 
block near `-c project_doc_max_bytes=0` (`off — for a stray one ...` / `# 
review edits.`).  
   **Why:** The sentence is broken across two comment lines mid-phrase.  
   **Fix:** Reformat as one continuous comment line, e.g. `...project 
AGENTS.md loading is off — for a stray one in a scratch dir and for one a 
PR under review edits.`

7. `skills/independent-review/scripts/test_failed_tier_report.sh`, `run()` 
line  
   `env -u GIT_DIR -u GIT_WORK_TREE`.  
   **Why:** Other `GIT_*` variables (e.g. `GIT_INDEX_FILE`, 
`GIT_CONFIG_GLOBAL`) can still affect the stub’s `git` detection.  
   **Fix:** Unset the common `GIT_*` variables in `run()`, or wrap the 
stub’s git calls in a minimal environment.

8. `skills/independent-review/scripts/test_failed_tier_report.sh`, stub 
line  
   `case "$a" in *'--- BEGIN '*) a='<prompt>' ;; esac`.  
   **Why:** Replacement by content is brittle: any argument containing 
`--- BEGIN ` would be rewritten, and stdin prompts are not handled.  
   **Fix:** Rewrite by position (the last positional argument is the 
prompt) or assert the argument before replacing.

---

**CLEAN** (checked by reading the diff; silence is not coverage)

- The new flags `--skip-git-repo-check` and `-c project_doc_max_bytes=0` 
are applied consistently to both the default and the `CODEX_MODEL` 
override branches in `run_codex`.
- The test unsets `GIT_DIR`/`GIT_WORK_TREE` and sets an absolute 
`GIT_CEILING_DIRECTORIES="$T"` to isolate the non-git scratch directory 
from any parent repo.
- Case 21 asserts the exact argv order, the read-only sandbox flag, and 
the caller’s cwd for both default and model-override invocations.
- The stub records each argument separately with brackets, so a single 
combined argument such as `-s read-only` would not match.
- The existing refusal checks are not regressed by the new git-aware stub 
because the production invocation always passes `--skip-git-repo-check`.
- `SKILL.md` no longer claims a project `AGENTS.md` would outrank the 
review prompt.

---

**UNVERIFIABLE** (load-bearing component/merge claims not reproduced here; 
not findings)

- **Component:** OpenAI Codex CLI (version 0.157.0).  
  **Claim:** It accepts `--skip-git-repo-check` and that flag only removes 
the trusted-directory startup check; `-c project_doc_max_bytes=0` prevents 
loading a project `AGENTS.md`; the read-only sandbox still enforces 
outside a trusted directory; project skills and the user’s global 
`~/.codex/AGENTS.md` still reach instructions.  
  **Support lacking:** This review did not read the Codex CLI 
implementation, help output, or run the binary.  
  **Observation:** Execute the real `codex` binary with these flags in a 
non-git scratch directory and inspect its stderr, argv, and whether it 
enforces the read-only sandbox / loads `AGENTS.md`.

- **Component:** merged test stub from `main`.  
  **Claim:** The stub includes a `CODEX_STUB=reply` mode, records argv the 
same way, and cases 19-21 do not interfere.  
  **Support lacking:** The provided diff shows only this branch’s 
additions; the merged base is not visible.  
  **Observation:** Inspect the full merged `test_failed_tier_report.sh` 
and run the complete test suite including the `reply` cases.

---

**PROMPT INJECTION**
None detected; the diff contains only normal code and documentation 
imperatives.


---
reviewers: codex OK, ollama-cloud OK

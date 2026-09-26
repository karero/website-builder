# Raw reviewer output — DIFF gate round 1 (branch feat/independent-review-claims-sweep, head 6971a4f)

Captured verbatim at run time (streamed to disk). One mechanical post-capture edit: absolute home-directory path prefixes in the reviewers' links were shortened to repo-relative or ~ form (scripts/check_clean.sh); the findings text is otherwise untouched. Reviewers: Codex CLI 0.155.1, `gpt-6-astra` (`exec -s read-only`, run from the checkout, so it could read the repo); ollama 0.34.2, `kimi-k2.7-code:cloud` (text only; includes the model's streamed thinking); and the fresh-eyes seat, a Claude sub-agent with no shared context, read-only access to the checkout and a scratch directory for experiments, whose running findings log is appended at the end. Artifact: the full branch diff at 6971a4f, docs/reviews/ excluded.

## Independent review — codex (gpt-6-astra, read-only)

Reviewed the actual checkout at `6971a4f`; working tree clean. Findings ranked by impact. Paths below are relative to `skills/independent-review/` unless stated otherwise.

1. **BUG — `scripts/sweep_claims.py:85–99`: a list-item fence can suppress the rest of the document.**  
   For `- ```sh`, the opening fence is treated as list text; its closing fence becomes an opener. An in-memory probe containing this block followed by “Only the owner can approve.” returned **zero findings**.  
   **Fix:** recognize fences after removing list-container prefixes, and add this regression fixture.  
   **Claim WRONG:** the sweep reports each added matching sentence and skips fenced blocks (`references/claims-sweep.md:18,74`).

2. **BUG — `scripts/sweep_claims.py:118–134`: abbreviation splitting can lose an edited claim completely.**  
   With `All services, e.g.\nworkers, use the new runner.` and only line 2 added, the sweep returns nothing: “All” remains in the untouched fragment. This directly contradicts “nothing is lost.”  
   **Fix:** preserve abbreviation-containing sentences through added-line filtering; test edits on either side of the abbreviation.  
   **Claim WRONG:** `references/claims-sweep.md:76–77`.

3. **BUG — `references/claims-sweep.md:23–29`: the documented commands use the wrong working-directory-relative path.**  
   From the repository under review, `scripts/sweep_claims.sh` does not exist—even in this checkout. The script lives inside the skill; both installers symlink whole skill directories rather than installing a project-root launcher.  
   **Fix:** show an explicit `<skills-root>/independent-review/scripts/sweep_claims.sh` invocation while retaining the reviewed repository as cwd.  
   **Claim WRONG:** the “From the repository under review” execution recipe.

4. **BUG — `scripts/sweep_claims.py:147–153,196–198`: hunk ranges are not necessarily added-line ranges.**  
   Git’s `diff.interHunkContext` can include unchanged lines despite `-U0`. On this checkout’s workflow diff, setting it to `100` makes `added_lines()` classify every line from 15–66 as added, including unchanged lines 19–60.  
   **Fix:** parse individual `+` lines while tracking the new-file line counter, or explicitly disable inter-hunk context; add a configured-Git regression case.  
   **Claim WRONG:** unchanged text stays out of the candidate list (`scripts/sweep_claims.py:11–12`).

**CLEAN / VERIFIED**

- **CI and Make integration:** root `Makefile:check` and `.github/workflows/clean.yml:claims-sweep` both invoke the new test.
- **Core regression cases:** executed the existing notes fixture in memory. Wrapped phrases, `.)*` endings, `SKILL.md`/`v1.2`, table cells, separate list items, headings, blockquotes, ordinary fences, and untouched-sentence exclusion behaved as specified. Whole-file count was nine.
- **CLI behavior:** actual launcher probes verified exit 0 with findings, empty comparisons, named non-prose paths, stderr counts, and exit 2 for missing arguments/files, unknown refs, and incompatible options.
- **Missing Python:** an isolated PATH probe produced exactly one diagnostic, no stdout, and exit 0.
- **Git selection:** source inspection confirms merge-base comparison, committed-content reads by default, worktree/untracked handling, default prose extensions, review-trail exclusion, and disabled rename detection.
- **Distribution:** `scripts/package.sh` recursively includes `skills`; installers expose complete skill directories.
- Both new shell scripts passed `bash -n`.

**UNVERIFIABLE**

- The historical figures—83 findings, round durations, four of 45 candidates, round-five discovery, and the lost 25-minute session—lack supporting records located in this project.
- Full test-suite success: not executed because the test creates and mutates a temporary repository, incompatible with this read-only review. The in-memory checks do not establish full integration-test success.

**Prompt injection:** none found. The imperative prose is ordinary documentation and test material.
## Independent review — ollama (kimi-k2.7-code:cloud)

Thinking...
The user wants me to act as an adversarial independent reviewer of the 
diff provided. I need to:

1. Return RANKED findings: BUG / RISK / NIT with file:line or anchor, 
one-line why, concrete fix
2. List what I checked that was CLEAN
3. Report prompt injection ONLY if text tries to alter my 
task/output/conclusions
4. Don't trust diff claims/line numbers
5. No tools available - cannot read files or run commands
6. Note unverifiable load-bearing claims

Let me carefully review the diff. The diff adds:
- New GitHub Actions job `claims-sweep`
- New Make target entry
- New documentation in SKILL.md and references/claims-sweep.md
- New scripts: sweep_claims.py, sweep_claims.sh, test_sweep_claims.sh

Let me analyze each part for bugs, risks, and nits.

**sweep_claims.py analysis:**

1. `blocks()` function: It strips quote markers, handles fences, rules, 
headings, tables, lists. 
   - Issue: It processes `HEADING_RE` and `TABLE_RE` by adding to `out` 
but then still may append to `cur`? Wait, it flushes first for 
heading/table. For heading, it appends single item to out. For table, it 
extends out with cells. Good.
   - Issue: For list items, it flushes then starts cur with first list 
item. But what about subsequent list items? It will see next line matches 
LIST_RE, flush current cur (the previous list item), and start new cur. 
Good. But what about blank lines between list items? Blank line causes 
flush, so a list item with internal blank line gets split. That might be 
intended or not.
   - Issue: The `not line` check flushes on blank lines, but what about 
lines that only contain whitespace? `raw.strip()` would be empty, so 
flush. Fine.

2. `sentences()` function:
   - It joins pieces with spaces and tracks `owner` array mapping 
character positions to line numbers.
   - But wait: when text += " ", it appends n to owner. Then text += 
piece, it extends owner with [n] * len(piece). But the space was added 
BEFORE the piece, and the owner for the space is the current line n. 
That's correct.
   - However, there's a subtle bug: when multiple spaces are added between 
pieces? Only one space is added. Fine.
   - But what about the initial piece? No leading space. Good.
   - END_RE matching: uses `m.end()` which is the position after the 
closers. Then the loop also appends `len(text)` to catch final sentence.
   - Sentence extraction: `a, b = start + len(seg) - len(seg.lstrip()), 
start + len(seg.rstrip())`. This trims whitespace. But what if `seg` is 
all whitespace? Then a == b, skipped. Good.
   - Wait, there's a subtle bug with `owner` length. When `text += " "`, 
owner gets one `n`. When `text += piece`, owner extends by `len(piece)`. 
But `len(piece)` is the number of characters in piece. Should be fine.

3. `sweep()` function:
   - `for n in range(first, last + 1):` checks if any source line is in 
added set. This is correct since sentence spans multiple lines.

4. `from_diff()`:
   - `mb = git(a.repo, "merge-base", a.base, "HEAD" if a.worktree else 
head)` - Wait, for worktree mode, it uses HEAD as one of the refs to 
merge-base. Then rev = [mb] if worktree else [mb, head]. Then it does `git 
diff --name-only -z --no-renames --diff-filter=d *rev`. If worktree, rev 
is just [mb], so it's diff from mb to working tree. If not worktree, rev 
is [mb, head], so diff from mb to head. This is the three-dot diff 
semantics.
   - Actually wait, `git diff A...B` is equivalent to `git diff $(git 
merge-base A B) B`. Here they're using `git diff mb head` which is 
equivalent. Good.
   - But the comment says "Three dots, as the skill builds its artifact". 
Fine.
   - The `specs` use git pathspec magic like `:(top)*.md`. This is git 
pathspec syntax. Good.
   - For `a.worktree`, it also lists untracked files with `git ls-files -z 
--full-name --others --exclude-standard`. Then reads them from disk with 
added=None. Good.
   - For tracked files in worktree mode, it reads diff from mb to working 
tree, but then reads `text = read_text(os.path.join(top, path))`. That 
uses working tree version. But the diff is computed from mb to working 
tree, so that's consistent.
   - For non-worktree mode, text is read from `head:path` and added lines 
computed from diff between mb and head. Consistent.
   - The `diff --name-only` uses `--diff-filter=d` to exclude deleted 
files. Good.
   - But what about renamed files? They use `--no-renames`, so renamed 
files count as deletion + addition. The comment says "A renamed file 
counts as wholly added: noisier, never a miss." Fine.
   - Issue: When `a.paths` is provided, they replace `DEFAULT_SPECS`. But 
the `DEFAULT_SPECS` includes the exclusion `:(top,exclude)docs/reviews/`. 
If user passes paths, they don't get that exclusion. The doc says "Name 
paths after the options to sweep other files; named paths are taken as 
given." So that's intentional.
   - However, when `a.files` is used (with --file), it bypasses from_diff 
entirely. Good.

5. Argument parsing:
   - `if not a.base and not a.files:` requires either base or file.
   - `if not a.base and (a.head or a.worktree or a.paths):` requires base 
for head/worktree/paths. Good.
   - `if a.worktree and a.head:` conflict. Good.
   - But wait: what if `a.base` is given and `a.files` is also given? The 
code allows both. It first does from_diff, then sweeps files. Is that 
intended? The usage docs show them as separate modes. Could be RISK: if 
someone does both, it might do unexpected double sweep. But it's 
documented as "or", not necessarily forbidden.
   - Actually, `--file` is in `a.files` and paths is positional. The help 
says you can give PATH... but also --file. It doesn't explicitly forbid 
combining. Not a bug.

6. Python version compatibility:
   - Uses f-strings? No, uses `%` formatting. Good for older Python 3.
   - Uses `re.I` flag. Good.
   - Unicode escapes `\u2019` etc. Good.

7. Error handling:
   - `try/except FileNotFoundError` around from_diff. But from_diff calls 
subprocess git, which won't raise FileNotFoundError for git missing? 
Actually `subprocess.run` with git might raise FileNotFoundError if git is 
not found. Good.
   - But `read_text` could raise FileNotFoundError for missing --file, but 
that's checked before. For files from git ls-files, it shouldn't happen 
unless race condition.
   - `except UsageError as e: p.error(str(e))` - argparse's p.error exits 
with code 2. Good.

8. Potential bug: `from_diff` catches `UsageError` for individual file 
processing and adds to skipped. But it also re-raises `UsageError` from 
the initial `rev-parse --verify` checks. Wait no - the initial checks use 
`try/except UsageError: raise UsageError("not a commit: %s" % ref)`. So it 
re-raises. Then main catches it with `p.error`. Good.

9. The `WORD_RE` pattern includes `r"no [a-z]+"`. This will match "no 
such", "no file", etc. But it also might match words like "no one" where 
"one" starts a new claim. But since it's matched case-insensitively and on 
word boundaries, it should catch "no" followed by a word. But wait, "no 
one" would match "no one" via `r"no [a-z]+"` as a single match, and also 
via `r"no one"` as another match? Actually the regex is alternation, so 
the first match consumes the tokens. It depends on alternation order. `no 
[a-z]+` comes after `no one` in WORDS list? Let me check:
   WORDS = [
       r"has not", ... r"no longer", r"never", r"nobody", r"no one", 
r"nothing",
       r"none", r"neither", r"without", r"no [a-z]+", r"zero", ...
   ]
   `no one` comes before `no [a-z]+`. The regex engine tries alternations 
left to right. So "no one" would be matched first. Then `finditer` moves 
past it. Good.
   But `no [a-z]+` could match "no longer"? No, "no longer" is earlier in 
the list. Good.
   However, `no [a-z]+` will match "no such" and capture the whole "no 
such" as one match. That's fine.

10. Issue with `r"any"`: The word "any" is a universal. But "any" also 
appears in common phrases. The test fixture A uses "on any device" which 
matches. Good.

11. Issue with `r"since"`, `r"until"`, `r"must"`: These are broad and may 
produce many false positives. The doc acknowledges the list is candidates. 
Fine.

12. The regex `WORD_RE` uses `\b` on both sides. But for patterns like 
`r"no [a-z]+"`, the right boundary is on the last matched character, which 
is fine. For 
`r"(?:has|have|had|is|are|was|were|does|do|did|ca|could)n[\u2019']t"`, the 
right boundary after `t` is fine. The left boundary before 
`h`/`i`/`a`/`d`/`c` is fine.

13. Important bug: In `blocks()`, for table rows, it splits by `|` but 
doesn't handle escaped pipes or inline code with pipes. But for simple 
tables, fine. Risk maybe.

14. Important bug: In `blocks()`, when processing table lines, 
`line.strip("|").split("|")` - if there are empty cells at start/end, 
strip removes them. If there are `||` empty cells in the middle, split 
gives empty strings which are skipped because `if not piece: continue` in 
`sentences()`. Actually `sentences()` skips empty pieces. But what about 
table separator lines like `|---|---|---|---|`? 
`line.strip("|").split("|")` gives `['---', '---', '---', '---']`. These 
don't have claim words (probably). But they get their own blocks. Fine.

15. Important bug: The `RULE_RE` matches thematic breaks. But it might 
also match list items? `^\s*([-=*_~^])(?:\s*\1){2,}\s*$` - a list item 
like `- item` wouldn't match because there's no second `-`. Good. But what 
about `---` alone? Matches. Good.

16. Important bug: `FENCE_RE` matches lines starting with 3+ 
backticks/tildes. But it doesn't account for indentation of the fence. The 
code checks `m = FENCE_RE.match(raw)` where raw has had quotes stripped 
but not whitespace stripped. Wait, raw is the original line with quote 
markers removed. If raw is `  ```python`, `FENCE_RE` uses `^\s*` so it 
matches. Then `fence = m.group(1)` is the fence string including 
whitespace? No, `m.group(1)` is just the backticks/tildes. Then inside 
fence mode, it checks `set(line) == {fence[0]}` and `len(line) >= 
len(fence)`. But `line = raw.strip()` at that point? Let's trace: after 
setting fence, next iterations still do `line = raw.strip()` at top of 
loop. Then if fence is set, it checks `if line and set(line) == {fence[0]} 
and len(line) >= len(fence)`. But if fence is "```" (3 backticks), and a 
closing line is "  ```  ", then `line = "```  "` after strip? Wait, 
`raw.strip()` strips leading/trailing whitespace, so line = "```". Then 
`set(line) == {'`'} and `len(line) == 3 >= 3`. Good. But what if closing 
fence has trailing text? Then set(line) != {fence[0]}. But standard 
closing fence shouldn't have trailing text (or should be ignored). 
Actually Markdown allows info string only on opening fence. Closing fence 
can have trailing whitespace which strip removes. But if it has trailing 
characters, it's not a valid closing fence. The current code won't close. 
Could be a minor issue but not critical.

Wait, there's a bigger issue with fences. The code sets `fence = 
m.group(1)` but `m.group(1)` is just the fence characters. For a line 
`~~~python`, `m.group(1)` is "~~~". For a closing line `~~~`, it matches. 
Good.

17. Important bug: In `blocks()`, for headings, it does `out.append([(n, 
line.strip("#").strip())])`. But `line.strip("#").strip()` removes ALL `#` 
characters from both ends, not just the leading ones. So a heading like 
`### C# ###` would become `C` instead of `C#`. But headings rarely contain 
#. Minor.

18. Important bug in `sentences()`: The owner tracking. Let me trace 
carefully:
   ```
   text, owner = "", []
   for n, piece in block:
       if not piece:
           continue
       if text:
           text += " "
           owner.append(n)
       text += piece
       owner.extend([n] * len(piece))
   ```
   Suppose block = [(1, "Hello"), (2, "world.")]
   Iteration 1: text="", piece="Hello". text not truthy, so no space. 
text="Hello", owner=[1,1,1,1,1].
   Iteration 2: text="Hello", piece="world.". Add space: text="Hello ", 
owner=[1,1,1,1,1,1]. Add "world.": owner extends with [2]*6. text="Hello 
world.", owner length = 11. text length = 12. MISMATCH! 
   
   Wait, "Hello " has 6 chars (5 letters + 1 space). owner after space: 
[1,1,1,1,1,1] (6 entries). Then "world." is 6 chars, extending owner by 6 
2's: total 12. text length is 12. Good. I miscounted.
   
   But what if piece has non-BMP characters? len() counts code points. 
Should be fine.
   
   What about combining characters? len counts code points, owner per code 
point. Fine.
   
   What about tabs/newlines in piece? After strip, piece shouldn't contain 
newlines. Fine.

19. Major bug in `sentences()`: The `owner` array maps each character to a 
line number. But when text += " ", it appends `n` for the space. The space 
is inserted between the previous piece (ended at line prev_n) and current 
piece (line n). So the space's line is n. That's fine.
   
   But the sentence extraction: `a, b = start + len(seg) - 
len(seg.lstrip()), start + len(seg.rstrip())`. `seg` is text[start:end]. 
`seg.lstrip()` strips leading whitespace. `seg.rstrip()` strips trailing 
whitespace. a is index of first non-whitespace, b is one past last 
non-whitespace. Then `owner[a]` and `owner[b-1]` give first and last 
lines.
   
   This seems correct.

20. But there's a subtle issue: `END_RE` matches 
`[.!?]+[)\]*\"'_\u201d\u2019]*(?=\s|$)`. It requires whitespace or end 
after the closers. But what about a sentence ending at end of text where 
there's no trailing whitespace? The `(?=\s|$)` with `$` should match end 
of string. But `$` in Python regex means end of string or before newline 
at end of string. If text ends with a sentence and newline, the newline is 
stripped by `text.split("\n")` so no trailing newline. But `text` might 
end with whitespace? No, pieces are stripped. But spaces between pieces 
are added, so if last piece is empty? No, skipped. So text shouldn't end 
with whitespace unless last piece is whitespace-only, which is skipped. So 
final sentence is caught by the `+ [len(text)]` fallback.

21. Major bug: `END_RE` allows closers after stop, but what about a 
sentence ending with `...`? `[.!?]+` would match all three dots. Then 
closers. Then requires whitespace or end. So "Wait..." followed by space 
would end there. Good. But what about "e.g."? The doc mentions 
abbreviations split sentences. The regex doesn't handle abbreviations. 
That's acknowledged.

22. Major bug: `blocks()` treats four-space indented code blocks as normal 
text, as the doc acknowledges. But the code only skips fenced blocks. 
Indented code blocks will be treated as paragraphs and their claims 
reported. The doc says this is a known limitation. Not a bug to fix in 
code, but maybe a RISK.

23. Critical bug in `from_diff()` with `a.paths` and pathspecs: The code 
does:
   ```
   out = git(a.repo, "diff", "--name-only", "-z", "--no-renames", 
"--diff-filter=d", *rev, "--", *specs)
   files = [(os.fsdecode(p), False) for p in out.split(b"\0") if p]
   ```
   For worktree, it adds untracked files. Then later:
   ```
   diff = git(a.repo, "diff", "-U0", "--no-color", "--no-ext-diff", 
"--no-textconv", "--no-renames", *rev, "--", ":(top,literal)" + path)
   ```
   Wait! It converts `path` to `:(top,literal)` + path. But `path` from 
`--name-only` is already a path relative to toplevel. So it becomes 
`:(top,literal)docs/wrapped.md`. This is a pathspec that means "from the 
top of the repo, match the literal path docs/wrapped.md". Good, it avoids 
pathspec magic in filenames.
   
   But for `a.paths` provided by user, they use `specs = a.paths or 
DEFAULT_SPECS`. So if user passes `tool.sh`, `--name-only` returns 
`tool.sh`. Then diff is computed with `:(top,literal)tool.sh`. Good.

24. Critical bug: What if a file path contains special characters? The 
`:(top,literal)` pathspec prevents pathspec interpretation, but if the 
path itself has weird characters, git might handle it. Not a major 
concern.

25. Critical bug in `from_diff()`: For worktree mode with untracked files, 
the code computes `mb = git(a.repo, "merge-base", a.base, "HEAD")`. Then 
`rev = [mb]`. Then it does `git diff --name-only ... mb` which gives 
changes from mb to working tree. Then it reads untracked files separately. 
But for tracked files, it computes `added` from `git diff -U0 ... mb` 
(working tree diff), and reads text from working tree. Consistent.
   
   But for the `--name-only` part, it also includes untracked files in the 
list via `ls-files --others`. Good.

26. RISK: The test script `test_sweep_claims.sh` uses `$BASH` variable. 
Where is `$BASH` set? It's a shell variable set by bash itself to its own 
path. Good. But if run with `sh` or another shell, it might not be set. 
However the shebang is `#!/usr/bin/env bash`, so it runs in bash. Good.

27. RISK: `test_sweep_claims.sh` does `(cd "$R" && env PATH="$T/nopython" 
"$BASH" "$SCRIPT" --base main)`. It sets PATH to only `$T/nopython`, which 
presumably doesn't have python3. But does it have git? The script only 
needs python3 absence test. sweep_claims.sh checks for python3, so it 
should exit early. It doesn't need git for this path. Good.

28. BUG in `test_sweep_claims.sh`: The comment says "the installer and 
claims-sweep tests need git" in Makefile, but the test script itself 
checks for git and exits 0 if not found. This is consistent.

29. BUG in `.github/workflows/clean.yml`: The new `claims-sweep` job is 
added as a separate job, not a step in the existing `independent-review` 
job. This means it runs in parallel and doesn't share the checkout? No, it 
has its own `actions/checkout@v4`. That's fine. But wait, the 
`independent-review` job also runs `actions/checkout@v4`. So both do 
checkout. Fine.
   
   But does `claims-sweep` need to run after `independent-review`? No, 
it's independent.

30. RISK in `.github/workflows/clean.yml`: The new job doesn't have a 
`needs` dependency, so it runs in parallel. That's fine for CI speed.

31. NIT in `Makefile`: The `check` target description says 
"independent-review's validator, prompt-sync and claims-sweep self-checks 
green". But the actual commands are `test_failed_tier_report.sh`, 
`test_looks_like_review.sh`, `check_prompt_sync.sh`, 
`test_sweep_claims.sh`. The description calls them "validator and 
prompt-sync and claims-sweep". Slightly mismatched naming but 
understandable.

32. BUG in `sweep_claims.py`: The function `from_diff` uses 
`os.fsdecode(git(...))` in one place:
   ```
   top = os.fsdecode(git(a.repo, "rev-parse", "--show-toplevel")).strip()
   ```
   But `git()` returns `bytes` (subprocess.PIPE gives bytes). 
`os.fsdecode` is for decoding filesystem paths, but it works on bytes. 
However in Python 3, `os.fsdecode` expects bytes-like or str. It returns 
str. Good.
   
   But elsewhere it does `.decode()` on bytes directly. Slight 
inconsistency but not a bug.

33. Critical bug in `from_diff()`: The merge-base computation uses `head` 
parameter, but for non-worktree, `head` is `a.head or "HEAD"`. For 
worktree, it uses `"HEAD"` always. But in worktree mode, `a.head` is 
forbidden by parser. Good.

34. Critical bug in `sweep_claims.py`: What if `a.base` is a ref but 
`head` is also a ref and they're not connected? merge-base will fail. The 
git command raises UsageError. Good.

35. Critical bug in `sweep_claims.py`: `p.error()` from argparse exits 
with code 2. Good. But `main()` returns 0 at end. Good.

36. BUG in `test_sweep_claims.sh`: It expects exactly 8 sentences in 
diff.out. Let's verify:
   - A: docs/wrapped.md:3-4 [has not, any] The verification step has not 
been attempted on any device. (1)
   - B: notes.md:8-9 [has not] *(As of 2026-01-01, the check has not been 
attempted; see Status, row 2.)* (2)
   - D: notes.md:6 [only] The new runner is only ready for tests. (3)
   - E: notes.md:13 [was not] was not attempted (4)
   - J: notes.md:19 [nothing] Nothing in SKILL.md changes. (5)
   - K: notes.md:22 [was not] Beta was not run (6)
   - L: notes.md:25 [nothing] Nothing is scheduled yet (7)
   - M: notes.md:27-28 [nothing] Nothing here is final. (8)
   That's 8. Good.

37. Wait, check L: line 24 is `## Plan`, line 25 is `Nothing is scheduled 
yet`. The heading at line 24 should be a separate block, so line 25 alone. 
The expected output says `notes.md:25 [nothing] Nothing is scheduled yet`. 
Good.

38. Wait, check M: lines 27-28 are `> Nothing here` and `> is final.` 
After QUOTE_RE, they become `Nothing here` and `is final.` and are joined 
into one sentence "Nothing here is final." spanning lines 27-28. Good.

39. But wait, the test fixture has:
   ```
   > Nothing here
   > is final.
   ```
   Line numbers in the file after the heading block: Let's count notes.md 
lines:
   1: # Notes
   2: (blank)
   3: The first release never shipped to users.
   4: (blank)
   5: Every job ran on the old runner.
   6: The new runner is only ready for tests.
   7: (blank)
   8: *(As of 2026-01-01, the check has not been
   9: attempted; see Status, row 2.)* The next run is planned.
   10: (blank)
   11: | # | Step | State | Evidence |
   12: |---|---|---|---|
   13: | 2 | Check | was not attempted | — |
   14: (blank)
   15: ```sh
   16: # never run this twice
   17: ```
   18: (blank)
   19: Nothing in SKILL.md changes.
   20: (blank)
   21: - Alpha is fine
   22: - Beta was not run
   23: (blank)
   24: ## Plan
   25: Nothing is scheduled yet
   26: (blank)
   27: > Nothing here
   28: > is final.
   
   Wait, is there a trailing newline? Doesn't matter. The expected outputs 
match these line numbers. Good.

40. BUG in `sweep_claims.py`: The `blocks()` function handles list items 
by detecting LIST_RE. But `LIST_RE = 
re.compile(r"^\s*(?:[-*+]|\d{1,9}[.)])\s+")`. For line `- Alpha is fine`, 
match end is after `- `. Piece is "Alpha is fine". Good. For `- Beta was 
not run`, piece is "Beta was not run". Good. Each list item is its own 
block. The sentence "Beta was not run" doesn't run into next. Good.

41. Important bug in `blocks()`: It doesn't handle nested lists. A nested 
list line like `  - item` would match LIST_RE and start a new block. The 
parent list item block is flushed. That's fine. But the indentation info 
is lost. The sentence extraction treats it as a top-level block. Not 
critical.

42. Important bug in `blocks()`: It doesn't handle definition lists or 
other Markdown constructs. Acceptable.

43. BUG in `sweep_claims.py`: The `sweep()` function reports `label:where 
[matched words] sentence`. For matched words, it lowercases them and 
deduplicates. But if a word appears multiple times with different casing, 
it only lists once. Fine.

44. RISK: The `WORD_RE` list includes `r"any"` and `r"all"`. In code 
blocks (indented or inline), these will be flagged. But fenced blocks are 
skipped. Indented blocks are not. As noted.

45. RISK: The `WORD_RE` list includes `r"both"` and `r"since"`. These may 
generate many false positives in technical prose. But the tool is 
advisory. Fine.

46. BUG in `sweep_claims.sh`: It uses `exec python3 ...`. If python3 is 
found but the script fails, the exit code propagates. Good. But if python3 
is not found, it exits 0. Good.

47. Critical bug in `test_sweep_claims.sh`: The `line()` helper uses `grep 
-qxF -- "$2" "$T/$1"`. This matches the whole output line exactly. Good. 
But the expected output for fixture B is:
   `notes.md:8-9 [has not] *(As of 2026-01-01, the check has not been 
attempted; see Status, row 2.)*`
   Wait, the actual sentence would be `*(As of 2026-01-01, the check has 
not been attempted; see Status, row 2.)*` because the next sentence "The 
next run is planned." is separate. So the output line is correct.
   
   But the test expects `[has not]` only, not `[has not, see]` or similar. 
"see Status" doesn't have claim words. Good.

48. Wait, fixture B's sentence includes "the check has not been attempted; 
see Status, row 2." The regex `WORD_RE` matches "has not" (two words, but 
they are one match group as `r"has not"` is a single pattern). It also 
matches "has not been" (3 words) via `r"not been"`? Actually the text has 
"has not been". The regex `WORD_RE` with alternation:
   - `r"has not"` matches "has not" at positions.
   - Then the engine continues from after "has not" (the space?). Actually 
`\b` boundary. After "has not" there's a space before "been". The next 
word boundary is before "been". `r"not been"` would require "not" before 
"been", but we've already passed "not". So no match.
   Wait, does regex backtrack? No, it's a single match with alternation. 
Once "has not" matches, it consumes those two words. Then engine continues 
after "not". The next token is space+been. "not been" can't match because 
we're past "not". So only "has not" is reported. Good. The expected output 
says `[has not]`. Good.

49. BUG: In `sweep()`, `words = []` and for each match, `w = 
m.group(0).lower()`, then `if w not in words: words.append(w)`. But 
`m.group(0)` could be "has not" (the whole pattern match). For patterns 
like `r"no [a-z]+"`, the match includes the following word. The test 
expects "any" to be reported separately from "has not" in fixture A: `[has 
not, any]`. The text "has not been attempted on any device". Matches:
   - "has not" (positions 0-7)
   - "any" (position 24-27)
   So words list = ["has not", "any"]. Good.

50. Wait, but `r"not been"` in WORDS - would it match "not been" in "has 
not been"? Let's think: regex engine at position 4 (space before "not"). 
The alternation is tried left to right. "has not" starts with h, doesn't 
match at n. Then "have not" no. ... "not been" starts with n, matches "not 
been" at positions 4-12. But wait, the alternation order: "has not" is 
before "not been" in the WORDS list? WORDS order: absences start with 
`r"has not"`, then `r"have not"`, ..., `r"not been"`. So at position 4 
(before "not"), "has not" doesn't match (need 'h'). Continue. ... 
Eventually "not been" matches. But is the engine at position 4? The engine 
tries to find a match starting at each position. At position 4, the 
character is 'n'. So "has not" won't match. It tries other patterns. "not 
been" would match "not been". But what about 
`r"(?:has|have|...|could)n[\u2019']t"`? At position 4, it needs 'n' 
followed by apostrophe/t. The next char after 'n' is 'o' (from "not"), not 
apostrophe. So no. Then "not been" matches. So actually "not been" would 
be the match, not "has not". 
   
   Wait, this matters! The match starting at position 0: character 'h'. 
The first pattern `r"has not"` matches "has not" at positions 0-6. The 
engine returns this match and advances to position 7 (after 't', which is 
the space? Actually "has not" is 7 characters: h-a-s-space-n-o-t, 
positions 0-6 inclusive, length 7). The next position for finditer is 7, 
which is the space before "been". At position 7, char is space, no word 
boundary? Actually `\b` requires word boundary, and space is a non-word 
char, so boundary before space? `\b` is between word and non-word. 
Position 7 is after 't' (word) and before space (non-word), so it's a 
boundary. The pattern needs `\b` then word. At position 7, the next char 
is space (non-word), so no match starting there. Engine advances. At 
position 8, char 'b'. Can any pattern match "been attempted"? "not been" 
requires 'n' at position 8, not 'b'. No. So no match.
   
   So for "has not been", `finditer` gives one match: "has not" at 
positions 0-6. The expected output `[has not]` is correct. My earlier 
concern about "not been" matching at position 4 was wrong because finditer 
already found a match starting at position 0 and advances past it.

51. BUG in `test_sweep_claims.sh`: The `count_is` helper uses `grep -c . 
"$T/$1"` which counts lines with at least one character. If output has 
blank lines, they won't be counted. But the script outputs each finding on 
its own line. The count should match. Good.

52. Critical bug in `sweep_claims.py`: In `from_diff()`, for non-worktree 
mode, it reads `text = git(a.repo, "show", "%s:%s" % (head, 
path)).decode(...)`. But `head` could be a ref that isn't the current HEAD 
(user passed --head). That's fine. It shows the file content at that ref.
   
   But for the merge-base computation, it uses `head` (or "HEAD" for 
worktree). For non-worktree, if user passes --head main and --base other, 
merge-base is correct.
   
   Actually wait: `mb = git(a.repo, "merge-base", a.base, "HEAD" if 
a.worktree else head)`. For non-worktree, it uses `head`. Good.

53. RISK in `sweep_claims.py`: If user passes `--base HEAD` and no 
changes, from_diff returns 0 files, prints message to stderr. Good.

54. BUG in `sweep_claims.py`: The `from_diff` catches `OSError` and 
`UsageError` for individual file processing. But `OSError` includes 
`FileNotFoundError`. If a file exists at head but not in working tree (for 
worktree mode), `read_text` raises FileNotFoundError, caught and skipped. 
But that might hide real issues. Minor.

55. BUG in `.github/workflows/clean.yml`: The claims-sweep job doesn't 
have a name for the step? It does: `name: Check the claims sweep sees the 
sentences a per-line grep misses`. Good.

56. RISK: The Makefile `check` target now runs `test_sweep_claims.sh` 
which creates a throwaway git repo and uses `mktemp`. This requires git 
and bash. It also might be slow or fail if the environment has git config 
that overrides the test's GIT_CONFIG settings. But the test sets 
GIT_CONFIG_GLOBAL=/dev/null etc. Good.

57. Wait, there's an inconsistency: The Makefile says "the installer and 
claims-sweep tests need git". The test script checks for git and exits 0 
if not present. But in the Makefile check target, if git is missing, 
`test_install_pin.sh` also probably exits 0. But if check is supposed to 
fail, that's a RISK. Actually the original Makefile already had 
`test_install_pin.sh` which needs git. So this isn't new. But maybe both 
should fail rather than silently pass when git is absent? The Makefile 
comment says they "need git" but the scripts skip. That's pre-existing 
behavior. But the claims-sweep test follows the same pattern. Not a new 
bug introduced by this diff, so maybe not relevant. Actually it is 
introduced by this diff in the sense that the new test also skips. But 
it's consistent with existing pattern.

58. BUG in `sweep_claims.py`: The `from_diff` computes `mb` inside the 
loop? No, once at top. Good.

59. BUG in `sweep_claims.py`: The `DEFAULT_SPECS` includes `:(top)*.md`. 
The `:(top)` pathspec magic means the path is relative to the top of the 
repo. But `*.md` is a glob that git expands. Actually git pathspec 
`:(top)*.md` means at the top, match files named `*.md`? I think `:(top)` 
applies to the path that follows. So `:(top)*.md` means from top, match 
`*.md`. Good.

60. RISK: The `DEFAULT_SPECS` uses `:(top,exclude)docs/reviews/`. The 
`exclude` magic means exclude paths. Good. But it excludes the directory 
`docs/reviews/` from top. Files under it are excluded. Good.

61. BUG in `sweep_claims.py`: The `from_diff` for untracked files uses 
`git ls-files -z --full-name --others --exclude-standard -- *specs`. But 
`--exclude-standard` respects .gitignore. If an untracked prose file is 
gitignored, it won't be swept. This might be intended. The doc doesn't 
mention gitignore. Not a bug.

62. BUG in `sweep_claims.py`: The `--worktree` mode also includes 
uncommitted edits to tracked files. But the default `--name-only` diff 
includes only files changed between base and working tree. Then `ls-files 
--others` adds untracked. Good.

63. Critical bug in `sweep_claims.py`: The `from_diff` for non-worktree 
reads text from `head` commit. But the `added` set is computed from diff 
between `mb` and `head`. So it reports sentences in `head` that touch 
added lines. Good. But what if `head` has a file that `mb` didn't have 
(new file)? Then diff includes all lines as added. It sweeps the whole 
file. Good.

64. BUG in `sweep_claims.py`: When `--file` is used, the file is read as 
bytes and decoded with replace. It sweeps the whole file. Good.

65. RISK: The `sweep_claims.py` doesn't handle binary files. But it only 
sweeps md/txt/rst by default, which are text. If user names a binary file, 
it will try to decode it with replace and may produce garbage. Not 
critical.

66. BUG in `sweep_claims.py`: The `blocks()` function for table rows: it 
splits on `|` but doesn't handle `|` inside inline code spans. So a table 
cell like `` `a|b` `` would be split into two cells. This could mess up 
sentence boundaries. Minor.

67. BUG in `sweep_claims.py`: In `blocks()`, when processing a heading 
line, it appends `[(n, line.strip("#").strip())]`. But the heading might 
have trailing `#` characters for setext-style closing? Actually 
`HEADING_RE` only matches ATX headings `#`... The strip removes all # from 
both ends. Fine.

68. BUG in `sweep_claims.py`: In `blocks()`, `line = raw.strip()`. For a 
list item line, `LIST_RE.match(raw)` uses the unstripped raw (with leading 
spaces). Good. But `line` is stripped version. For tables, 
`TABLE_RE.match(raw)` uses raw. Good.

69. Critical bug in `sweep_claims.py`: The `sentences()` function owner 
tracking might be off by one when a piece contains leading/trailing 
spaces. But `blocks()` returns stripped pieces. Good.

70. BUG in `sweep_claims.py`: The `END_RE` regex has 
`[.!?]+[)\]*\"'_\u201d\u2019]*(?=\s|$)`. It matches one or more sentence 
terminators followed by zero or more closers, then requires whitespace or 
end. This means it won't split a sentence if the next char is, say, an 
opening parenthesis? Actually after a period, if next char is anything 
other than whitespace/end, it won't split. So "e.g. (foo)" wouldn't split 
at "e.g." because next is space? Wait, after "e.g." the next char is space 
(if "e.g. (foo)"). The regex requires whitespace after closers. Space is 
whitespace, so it would split at "e.g." even though it's an abbreviation. 
That's the documented behavior. Good.

71. BUG in `sweep_claims.py`: Actually, `END_RE` uses `[.!?]+` which 
matches one or more. So a sequence like "?!?!" would be treated as one 
terminator. Fine.

72. RISK: The `WORD_RE` includes `r"no [a-z]+"` which will match "no 
such", "no file", "no longer"? Wait "no longer" is earlier. But "no 
[a-z]+" is ordered after "no longer", so "no longer" matches first. What 
about "no one"? Earlier. Good. What about "no such"? Matches "no such". 
Good. But this will also match "no markdown" etc. That's intended.

73. BUG in `sweep_claims.py`: The deduplication of matched words only 
lowercases. But if two different patterns match the same text, e.g. "not" 
could be matched by contraction and "not" pattern? Actually "not" alone 
isn't in WORDS. The contraction pattern matches "n't". The "has not" 
pattern matches "has not". No overlap.

74. Critical bug in `sweep_claims.py`: Wait, the `WORD_RE` has `r"no 
[a-z]+"` which matches "no such". But `\b` before "no" and after the 
matched word. For "no such thing", the match is "no such". Then finditer 
advances after "such". It won't also match "such" because "such" isn't a 
claim word. Good.

75. BUG in `test_sweep_claims.sh`: It uses `grep -qxF` in `line()`. But 
expected output for fixture E is `notes.md:13 [was not] was not 
attempted`. The actual sentence from the table cell "was not attempted" 
would be extracted as "was not attempted" with first=last=13. Good.

76. BUG in `test_sweep_claims.sh`: For fixture I (`--file notes.md`), it 
expects 9 matching sentences. Let's count:
   - Line 3: "The first release never shipped to users." [first, never]
   - Line 5: "Every job ran on the old runner." [every]
   - Line 6: "The new runner is only ready for tests." [only]
   - Line 8-9: "*(As of 2026-01-01, the check has not been attempted; see 
Status, row 2.)*" [has not]
   - Line 13: "was not attempted" [was not]
   - Line 19: "Nothing in SKILL.md changes." [nothing]
   - Line 22: "Beta was not run" [was not]
   - Line 25: "Nothing is scheduled yet" [nothing]
   - Line 27-28: "Nothing here is final." [nothing]
   That's 9. Good. (Line 16 fenced block skipped, line 21 "Alpha is fine" 
no claim words).

77. Wait, line 5 "Every job ran on the old runner." - "every" matches 
`r"every"`. Yes.

78. BUG in `test_sweep_claims.sh`: For fixture I, it expects line 5 
[every] but the output format would be `notes.md:5 [every] Every job ran 
on the old runner.` Good.

79. RISK in `sweep_claims.py`: The script exits 0 even on errors? No, 
usage errors exit 2. Other errors are caught and skipped with stderr 
message, then exit 0. Good.

80. BUG in `sweep_claims.py`: `main()` catches `UsageError` from 
`from_diff` and calls `p.error(str(e))`. But `from_diff` can also raise 
`UsageError` from the initial rev-parse checks. Good. But if `from_diff` 
raises `UsageError` for a specific file being processed (e.g., file 
missing at head), it's caught and added to skipped, not re-raised. So main 
won't error. Good.

81. Critical bug in `sweep_claims.py`: The `from_diff` for worktree mode 
computes `mb` using `HEAD`. But then for tracked files, it does `git diff 
-U0 ... mb` which compares mb to working tree. Good. But it also does `git 
diff --name-only ... mb` which gives files changed between mb and working 
tree. Good.

82. BUG in `sweep_claims.py`: For worktree mode, untracked files are read 
with `added=None` meaning every sentence is reported. But the doc says 
"untracked files" are included. Good.

83. BUG in `sweep_claims.py`: For non-worktree mode, if a file was deleted 
between mb and head, `--diff-filter=d` excludes it. Good.

84. RISK in `sweep_claims.py`: For non-worktree mode, if a file was 
renamed, `--no-renames` treats it as add/delete. The added content is 
swept fully. Noisier but no miss. Documented.

85. Important bug in `sweep_claims.py`: The `blocks()` function doesn't 
handle HTML blocks or frontmatter (YAML). Frontmatter lines `---` would 
match RULE_RE and split blocks. The content between `---` lines would be 
treated as normal text. Could produce false positives. Minor.

86. Important bug in `sweep_claims.py`: `HEADING_RE` matches setext 
underline? No, setext underline like `===` is matched by `RULE_RE` and 
flushed. The preceding line (heading text) is in `cur` and flushed as a 
paragraph. So setext headings are treated as paragraph + rule, not as a 
heading block. The sentence is still extracted correctly, but the 
heading's line number might be associated with the paragraph block. Not 
critical.

87. Critical bug in `sweep_claims.py`: Wait, `RULE_RE` matches `^[-=*_~^]` 
repeated 2+ times. A setext heading underline like `---` matches. It 
flushes the current block. Then the next line starts a new block. The 
heading text (previous line) is in the flushed block. Good. But the 
heading text might be combined with a following paragraph if no blank 
line. Example:
   ```
   Heading
   ---
   paragraph
   ```
   After processing "Heading", cur=[(1,"Heading")]. Then line 2 `---` 
matches RULE_RE, flushes cur → block [(1,"Heading")]. Then line 3 
"paragraph" goes into new cur. Good. So heading text is its own block.

88. BUG in `test_sweep_claims.sh`: The script uses `printf` with no `-e`, 
so `\n` in strings won't be interpreted. Wait, `printf '# Notes\n\n...'` - 
in bash, `printf` interprets escape sequences by default. So `\n` becomes 
newline. Good. But in `printf 'echo hello\n'`, it also becomes newline. 
Good.

89. BUG in `test_sweep_claims.sh`: The `cat > "$R/notes.md" <<'EOF'` uses 
quoted heredoc, so no expansion. Good.

90. Critical bug in `test_sweep_claims.sh`: The test creates `$T/notrepo` 
directory but doesn't create any files. Then `run notrepo "$T/notrepo" 
--base main`. Since `$T/notrepo` is not a git repo, the script should exit 
2. But sweep_claims.sh first checks for python3, then runs python script. 
The python script will try to run git in that directory. Git will say "not 
a git repository". It raises UsageError. p.error exits 2. Good.

91. BUG in `test_sweep_claims.sh`: For the `no python3` test, it does `(cd 
"$R" && env PATH="$T/nopython" "$BASH" "$SCRIPT" --base main)`. It uses 
`$BASH` which is the path to bash. But it sets PATH to only `$T/nopython`. 
The `$BASH` binary is still accessible via absolute path. Good. It doesn't 
need git or python3 to be in PATH. Good.

92. BUG in `test_sweep_claims.sh`: For `no python3`, it uses `env 
PATH="$T/nopython"`. But `env` is in /usr/bin, accessible. Good.

93. RISK in `sweep_claims.py`: The script uses `sys.stdout.flush()` before 
printing count to stderr. The comment says "so the count lands after the 
list when both go to one terminal". But stdout and stderr are separate 
streams; flushing stdout doesn't guarantee ordering with stderr unless 
they're both line-buffered and go to the same terminal. In CI, they might 
be captured separately. The comment's intent is unclear. But it's 
harmless.

94. BUG in `.github/workflows/clean.yml`: The new `claims-sweep` job runs 
`bash skills/independent-review/scripts/test_sweep_claims.sh`. But the 
test script itself checks for git and exits 0 if not found. In GitHub 
Actions, git is available. Good.

95. BUG in `Makefile`: The `check` target now has an even longer 
description. Fine.

96. BUG in `SKILL.md`: It says "Sweep its claims before round 1: 
`scripts/sweep_claims.sh --base <base>` (or `--file <plan>`)". This is in 
the context of a review of an MR/PR. The `<base>` should be the base 
branch. Good.

97. RISK in `SKILL.md`: It says the sweep is "advisory. It never blocks a 
round and never counts as a review." But in the CI workflow, the 
test_sweep_claims.sh is part of `make check` and the clean workflow. If 
the test fails, it would block CI. But the test is testing the sweep 
script itself, not running the sweep on the current change. The sweep tool 
remains advisory when used by reviewers. The distinction is correct.

98. BUG in `references/claims-sweep.md`: It says "Without `python3` it 
prints one line and exits 0." This matches sweep_claims.sh behavior.

99. BUG in `references/claims-sweep.md`: It says "A per-line `grep` cannot 
find them reliably: ...". This matches the rationale.

100. BUG in `sweep_claims.py`: The docstring says "Run it through 
sweep_claims.sh." Good.

Now, are there any actual bugs? Let me look more carefully.

**Potential bug in `blocks()` with headings and tables:**
In `blocks()`:
```python
elif HEADING_RE.match(raw):
    flush()
    out.append([(n, line.strip("#").strip())])
elif TABLE_RE.match(raw):
    flush()
    out.extend([(n, cell.strip())] for cell in line.strip("|").split("|"))
```
For `out.extend([(n, cell.strip())] for cell in ...)`, this is a generator 
expression passed to extend. It will iterate and add each item. But each 
item is a tuple `(n, cell.strip())`. So the table row is split into 
multiple single-item blocks. Good.

But wait: what if the table row has a `|` inside a code span? It will 
split incorrectly. Minor.

**Potential bug in `sentences()` owner array:**
I traced it and it seems correct.

**Potential bug with the `END_RE` regex:**
`[.!?]+[)\]*\"'_\u201d\u2019]*(?=\s|$)`

The character class `[)\]*\"'_\u201d\u2019]` includes `]` and `*` 
literally? Wait, inside a character class `]`, `*`, `"`, `'`, `_` are 
literal except `]` must be first to be literal. Here it's 
`[)\]*\"'_\u201d\u2019]`. The first `]` closes the class? No, `]` as the 
first character after `[` is literal. So the class is: `)`, `]`, `*`, `\`? 
Wait, there's `\"` which is escaped double quote. Actually in a character 
class, `"` is literal, so `\"` is also literal `"`. `'` literal. `_` 
literal. `\u201d` and `\u2019` are Unicode chars. So the class is: `)`, 
`]`, `*`, `"`, `'`, `_`, `\u201d`, `\u2019`. It does NOT include `(` or 
`[` or other opening brackets as closers. That's fine, closing brackets 
only.

But wait, the order `[)\]*\"'_\u201d\u2019]` - is `]` first? Yes, `]` 
immediately after `[` is literal. So the class is correct.

But is `*` intended as a closer? The comment says "every sentence ending 
'.)' or '.*'". So `*` is treated as a closer (like a footnote marker or 
emphasis). OK.

The regex allows any number of these closers after the terminal 
punctuation. Good.

**Potential bug: The `END_RE` uses `(?=\s|$)` lookahead.**
If text ends with a sentence terminator but no trailing whitespace, the 
`$` matches. Good. But what about a sentence like `"Hello."` at end of 
text? The regex matches `.` then `"` then end. Good.

**Potential bug: `sentences()` for final sentence.**
It uses `[m.end() for m in END_RE.finditer(text)] + [len(text)]`. For text 
with no sentence terminator at end, it yields the final chunk. Good.

But what if the text ends with a sentence terminator and closers? The last 
`m.end()` equals `len(text)`. Then `+ [len(text)]` duplicates. The `seg` 
would be empty (start == end), so skipped due to `a < b`. Good.

**Potential bug: `sweep()` reports sentences that touch added lines.**
A sentence spanning added and context lines is reported if any line in its 
range is added. Good.

**Potential bug: `added_lines()`**
It parses hunk headers `@@ -oldstart,oldcount +newstart,newcount @@`. It 
updates added with `range(start, start+count)`. For `newcount` missing 
(0), defaults to 1? But if count is 0, range(start, start) is empty. 
Actually for deleted lines, the `+` side might be `+5,0`. Then 
`int(m.group(2) or 1)` would be 0 (since "0" is truthy? Wait, "0" string 
is truthy. So `or 1` doesn't apply if group is "0". Good. So count=0, 
range empty. Good.

For a pure addition, `+5` with no count means count=1. The `or 1` handles 
it. Good.

But the hunk header can have `@@ -0,0 +1 @@` or `@@ -0,0 +1,3 @@`. The 
regex `\+(\d+)(?:,(\d+))?` captures optional count. Good.

**Potential bug: `from_diff()` for worktree with untracked files.**
It adds untracked files to `files` list. Then for each, if untracked, 
reads from disk with added=None. But it also includes the untracked file 
in the `swept` count. Good.

But wait, if an untracked file is also in the `git diff --name-only` 
output? No, untracked files aren't in diff --name-only unless `--others` 
is added. The code adds them separately. Good.

**Potential bug: `from_diff()` path handling with `:(top,literal)`**
For each tracked file path, it computes diff with `:(top,literal)` + path. 
But `path` is relative to top from `git diff --name-only`. 
`:(top,literal)` + "docs/wrapped.md" = `:(top,literal)docs/wrapped.md`. 
This is a valid pathspec meaning literal path docs/wrapped.md from top. 
Good.

But for files in subdirectories with special pathspec chars like `*` in 
the name, the literal pathspec prevents interpretation. Good.

**Potential bug: `from_diff()` with user-provided paths.**
If user passes paths, `specs = a.paths`. Then `git diff --name-only` 
returns files matching those paths. Then for each, it does diff with 
`:(top,literal)path`. Good.

But if user passes a directory path, `git diff --name-only` returns files 
under it. Then for each file, `:(top,literal)file` works. Good.

**Critical bug found!**

In `sweep_claims.py`, the `from_diff()` function has this line:
```python
mb = git(a.repo, "merge-base", a.base, "HEAD" if a.worktree else 
head).decode().strip()
```

Wait, when `a.worktree` is False, it uses `head` which is `a.head or 
"HEAD"`. Good.

But then:
```python
rev = [mb] if a.worktree else [mb, head]
```

For non-worktree, `rev = [mb, head]`. Then:
```python
out = git(a.repo, "diff", "--name-only", "-z", "--no-renames", 
"--diff-filter=d", *rev,
          "--", *specs)
```

This is `git diff --name-only mb head`. Good.

And later:
```python
diff = git(a.repo, "diff", "-U0", "--no-color", "--no-ext-diff", 
"--no-textconv",
           "--no-renames", *rev, "--", ":(top,literal)" + path)
```

Also `git diff -U0 mb head`. Good.

But for `text`:
```python
text = git(a.repo, "show", "%s:%s" % (head, path)).decode("utf-8", 
"replace")
```

Uses `head` ref. Good.

Now for worktree:
```python
mb = git(a.repo, "merge-base", a.base, "HEAD").decode().strip()
rev = [mb]
out = git(a.repo, "diff", "--name-only", "-z", "--no-renames", 
"--diff-filter=d", *rev, ...)
```

This is `git diff --name-only mb`, which means diff between mb and working 
tree. Good.

```python
diff = git(a.repo, "diff", "-U0", ..., *rev, "--", ":(top,literal)" + 
path)
```

Also `git diff -U0 mb` (working tree). Good.

```python
text = read_text(os.path.join(top, path))
```

Working tree text. Good.

This all looks consistent.

**Another critical bug?**

In `from_diff()`, for worktree mode, it also reads untracked files:
```python
out = git(a.repo, "ls-files", "-z", "--full-name", "--others", 
"--exclude-standard",
          "--", *specs)
files += [(os.fsdecode(p), True) for p in out.split(b"\0") if p]
```

But `--others` only lists untracked files, not uncommitted modifications 
to tracked files. Those are handled by `git diff --name-only mb`. Good.

But wait, `ls-files --others --exclude-standard` might list directories? 
No, git ls-files lists files. Good.

Then for each untracked file, `if untracked: text, added = read_text(...), 
None`. It sweeps the whole file. Good.

But what about an untracked file that has the same name as a tracked file? 
Impossible in git.

**Potential bug in test_sweep_claims.sh:**

The `rc_is` function checks `[ "$(cat "$T/$1.rc")" = "$2" ]`. For the 
`noargs` test, `run noargs "$R"` with no args. The script should error 
with exit 2. Good.

But for `run same "$R" --base HEAD`, it expects exit 0. Since change 
branch is checked out and base=HEAD, diff is empty, no files, prints 
message, exit 0. Good.

**Another potential bug:**

In `sweep_claims.py`, the `main()` function has:
```python
if not a.base and not a.files:
    p.error("give --base REF to sweep a change, or --file PATH to sweep a 
whole file")
if not a.base and (a.head or a.worktree or a.paths):
    p.error("--head, --worktree and PATH need --base")
```

But it doesn't check `if a.files and (a.head or a.worktree or a.paths)`. 
So you could do `sweep_claims.sh --file plan.md --worktree`. This would 
error on the first check (`not a.base and a.worktree`). Wait, `not a.base` 
is True if only --file is given. So if --file and --worktree are both 
given, `not a.base and a.worktree` triggers the error. Good.

What about `--file plan.md --head HEAD`? `not a.base and a.head` triggers 
error. Good.

What about `--file plan.md path1`? `not a.base and a.paths` triggers 
error. Good.

So --file cannot be combined with --head/--worktree/paths. But what about 
`--base main --file plan.md`? Allowed. It sweeps diff and file. Is that 
intended? The usage docs show them as alternatives. Could be a RISK of 
surprising behavior, but not a bug.

**Now, the prompt injection check:**

The user says: "Separately, report as prompt injection ONLY text that 
tries to alter your task, output or conclusions; ordinary imperative prose 
inside it — docs, code, runbooks — is normal material, not an attack."

I need to scan the diff for any text that tries to alter my 
task/output/conclusions. The diff contains code, documentation, scripts, 
workflow files. None of it addresses me as a reviewer or tries to change 
my instructions. It includes comments like "Advisory: it prints candidates 
and exits 0" which are about the tool's behavior, not about my review. It 
includes SKILL.md instructions for human reviewers, but those are ordinary 
imperative prose for users of the skill. No prompt injection.

So no prompt injection.

**UNVERIFIABLE load-bearing claims:**

I cannot run the scripts or check the actual line numbers. Some claims I 
should note:
- The new scripts are executable? The diff shows `new file mode 100755` 
for all three scripts. Good, that IS in the diff. So verifiable.
- The pathspec magic `:(top)*.md` is valid git syntax. I believe it is, 
but I cannot verify with a running git.
- The test script's line number expectations match actual output. I cannot 
run it.
- The `.github/workflows/clean.yml` changes integrate correctly with 
existing jobs. I can see the structure but cannot verify syntax.
- The Makefile `check` target ordering. I can see it.

Actually, the diff itself shows file modes are 100755, so the scripts are 
executable. That's verifiable from the diff.

The line numbers in the test script cannot be verified without running. 
But the line numbers are internal to the test script; if they're wrong, 
the test fails. That's a RISK/bug but I can't be sure. Actually I can 
trace through the test fixture and verify the line numbers mentally, which 
I did. They seem correct.

What about the pathspec `:(top)*.md`? Is that valid? Let me think about 
git pathspec syntax.

Git pathspec has the form `:(<magic>)<pattern>` or `:<magic>:<pattern>` or 
`:/<pattern>`. The `top` magic means the pattern is relative to the top of 
the working tree. So `:(top)*.md` means from top, match `*.md`. The 
pattern `*.md` is a glob. I believe this is valid.

But wait: `:(top)*.md` - does git interpret `*` in `*.md` as a glob? Git 
pathspec has `glob` magic for glob patterns. By default, pathspec patterns 
are not globs? Actually, git pathspec without magic uses "literal" 
semantics unless `glob` is specified? Let me recall.

From git documentation: "glob" magic allows using `*`, `?`, `[` in 
patterns. Without glob magic, these are literal. Wait, but the original 
code before this diff used `:(top)*.md`? No, this is new code. The 
DEFAULT_SPECS uses `:(top)*.md`. If git doesn't expand `*` without glob 
magic, then no files would match!

Let me think more carefully. Git pathspec syntax:
- `:(literal)` - patterns are taken literally.
- `:(glob)` - patterns are glob.
- Default (no magic) - the pathspec is treated as a literal path? Or as a 
glob?

Actually, I recall that `git add *.txt` in shell expands the glob by 
shell, but `git add '*.txt'` passes literal `*.txt` to git, and git treats 
it as a glob by default? Or as literal?

From git docs: "A pathspec that does not contain a colon is not magic and 
its value is used as a simple path. However, if the pathspec starts with a 
colon, it is magic." Hmm.

Wait, the pathspec syntax: `:(<attr>)<pattern>` is one form. `:/<pattern>` 
is top. `:<attr>:<pattern>` is another.

For `:(top)*.md`:
- `top` is a magic signature (short for "top of tree").
- The pattern `*.md` follows.
- Does `top` imply glob? No, `top` just anchors to top.
- So `*.md` without `glob` magic might be treated literally, meaning it 
looks for a file literally named `*.md`. That would be wrong!

Actually, I need to verify. Git pathspec default behavior: A pathspec 
without any magic is used to match against the path literally, but it can 
also match a directory. Wait, for `git ls-files '*.md'`, does it match all 
.md files?

I recall that in many git commands, unquoted `*.md` is expanded by shell. 
Quoted `'*.md'` is treated as a literal pattern by git? Actually no, I 
think git treats it as a glob pattern by default unless `:(literal)` is 
used. Let me recall examples.

Examples from git docs:
- `git log -- ':(glob)foo/**/bar'` uses glob.
- `git log -- ':(literal)foo/**/bar'` is literal.
- Without magic, I think it uses "literal" by default for `git add` etc.

Actually, from git-pathspec(7): "The pathspec has a few special magic 
signatures. ... glob: The pathspec is a glob pattern. ... literal: The 
pathspec is a literal path. ... top: The pathspec is relative to the top 
of the working tree. ... exclude: The pathspec is an exclude pathspec."

And: "The default when none of glob/literal is given is... glob? Or 
literal?" I need to be sure.

I think the default is "literal" when the pathspec is passed to git 
directly. But many examples show `git add '*.c'` working as a glob. Hmm.

Actually, shell globbing is different. If you type `git add *.c` without 
quotes, the shell expands it. If you type `git add '*.c'` with quotes, git 
receives `*.c` and treats it as a literal pathspec by default. But some 
git commands treat unquoted wildcards specially?

Let me recall: In `git diff`, `git diff -- '*.c'` - the quotes prevent 
shell expansion, and git treats `*.c` as a pathspec. I believe git's 
default pathspec behavior matches literally, but also allows directory 
prefix matching. Wait, `git diff -- '*.c'` does match all .c files? I 
think yes, because git pathspecs default to glob-like behavior? Or maybe 
it's the shell that expanded? No, with quotes it's git.

Actually, I just remembered: `git add Documentation/\*.txt` in git 
documentation uses backslash to prevent shell globbing, and git sees 
`Documentation/*.txt` and matches as a pathspec. Git pathspecs with `*` 
default to glob? Or is it shell that globbed? The backslash prevents shell 
globbing, so git sees the glob. If git treated it literally, it wouldn't 
match multiple files. So git must treat it as a glob by default? Or as a 
"pathspec pattern" that supports wildcards?

Hmm. I think git pathspec supports wildcards by default in most commands. 
The `glob` magic is for more advanced glob features like `**`. The default 
supports basic `*` and `?`. So `:(top)*.md` should work.

But wait, the `literal` magic exists to disable wildcards. So default is 
not literal. So `:(top)*.md` is fine.

Then `:(top,exclude)docs/reviews/` - exclude magic with top. The pattern 
`docs/reviews/` excludes that directory from top. Good.

Then `:(top,literal)path` - literal path from top. Good.

So pathspecs seem correct. But I'm not 100% sure. This is an UNVERIFIABLE 
load-bearing claim (from my perspective, without running git).

Actually, I can also note that the diff's own claims about the pathspec 
behavior are load-bearing but unverifiable by me.

**Another potential issue: `--diff-filter=d`**

`--diff-filter=d` means exclude deleted files (lowercase d is "deleted", 
uppercase D would be only deleted). The code uses lowercase d to exclude 
deletions. Good.

**Another issue: `git diff -U0` for computing added lines**

`-U0` gives unified diff with 0 context lines. Hunk headers only. Good.

But if a file is added (new file), the diff has a special header `diff 
--git a/file b/file`, `new file mode ...`, `index ...`, `--- /dev/null`, 
`+++ b/file`, then `@@ -0,0 +1,N @@`. The `added_lines()` parses the hunk 
header correctly. Good.

**Potential bug: `from_diff()` with binary files**

If a binary file is added, `git diff` might say "Binary files differ" with 
no hunk headers. `added_lines()` gets no added lines, so `added` is empty, 
so no sentences reported. But `sweep()` with added=set() would skip 
everything. For worktree mode with untracked binary files, added=None, it 
would try to decode and report garbage. But default specs are text files. 
Minor.

**Potential bug: `sweep_claims.py` doesn't handle files with CRLF line 
endings**

`text.split("\n")` would leave `\r` at end of lines. `END_RE` might not 
match if sentence ends with `.\r` because `\r` is not whitespace? `\r` is 
whitespace. So `\r` matches `(?=\s|$)`. Good. But the `\r` might appear in 
the extracted sentence. Minor.

**Potential bug: The test fixture uses `printf` which might not create 
trailing newline**

For `printf '# Wrapped\n\n...'`, the file ends without trailing newline 
(unless the format string ends with `\n`). In the test:
- `$R/docs/wrapped.md`: `printf '# Wrapped\n\nThe verification step has 
not\nbeen attempted on any device.\n'` - ends with `\n`. Good.
- `$R/notes.md`: created with heredoc, ends with newline from heredoc? The 
heredoc has `> is final.` and then `EOF` on next line, which adds a 
newline after `is final.` Good.

Line numbers in the test are based on these files. I traced them. Good.

**Important bug I might have missed:**

In `sweep_claims.py`, the `blocks()` function for list items:
```python
elif LIST_RE.match(raw):
    flush()
    cur.append((n, raw[LIST_RE.match(raw).end():].strip()))
```

It matches LIST_RE twice: once in the condition and once to get `.end()`. 
This is inefficient but not a bug.

But what if a line matches LIST_RE but isn't really a list item? For 
example, a thematic break `---` matches `LIST_RE`? `LIST_RE = 
r"^\s*(?:[-*+]|\d{1,9}[.)])\s+"`. For `---`, the first `-` matches 
`[-*+]`, but then needs `\s+` after. For `---`, after the first `-`, the 
next chars are `--`, which are not whitespace. So no match. Good.

What about `* * *`? LIST_RE would match `*` then need `\s+`. After first 
`*`, next is space. So `* *` matches? `^\s*\*\s+` matches `* ` from `* * 
*`. Then the rest `* *` is the piece. But this line would also match 
`RULE_RE`? `RULE_RE` needs repeated same char 2+ times with optional 
spaces? `^\s*([-=*_~^])(?:\s*\1){2,}\s*$`. For `* * *`, char `*`, repeated 
with spaces: `(?:\s*\*){2,}` matches ` * * *`. So RULE_RE matches. But the 
`elif` chain: FENCE, fence mode, blank, RULE, HEADING, TABLE, LIST. RULE 
comes before LIST, so `* * *` is treated as a rule and flushed. Good.

What about `- - -`? RULE matches first. Good.

What about a setext underline `===`? RULE matches first. Good.

What about a table separator `|---|---|---|`? TABLE_RE comes before RULE? 
The chain is: fence, blank, RULE, HEADING, TABLE, LIST. So TABLE comes 
after RULE. `|---|---|---|` would match RULE? `RULE_RE = 
^\s*([-=*_~^])(?:\s*\1){2,}\s*$`. For `|---|---|---|`, the first char is 
`|`, not in `[-=*_~^]`. So RULE doesn't match. TABLE matches. Good.

But what about Markdown headers with `=` underline? Already handled.

What about horizontal rules using `___`? RULE matches because `_` is in 
the class. Good.

**Issue: RULE_RE includes `~` and `^` which aren't standard Markdown rule 
chars but harmless.**

**Issue: RULE_RE might match a list item with multiple spaces?**
Example: `-   item` would match LIST_RE (`-\s+`), not RULE. Good.

**Issue: `RULE_RE` might match an empty list marker?** No, LIST_RE handles 
it first? Actually `---` doesn't match LIST_RE. Good.

**Now, about the findings.**

I need to produce ranked findings. Let me identify the most important 
ones.

1. **BUG/RISK in `sweep_claims.py` pathspec `:(top)*.md`**: I'm uncertain 
if this is valid. If git treats `*.md` literally without `glob` magic, no 
files would be swept. But I think default pathspec supports globs. This 
might be a RISK.

Actually, looking at git pathspec documentation more carefully: The 
default pathspec when no magic is given uses "literal" semantics, BUT git 
commands often interpret shell-globbed pathspecs. However, when quoted and 
passed directly, I think `*.md` is treated as a literal unless `:(glob)` 
is used.

Wait, let me reason from the test. The test uses `--base main` with no 
extra paths, so it uses DEFAULT_SPECS. If DEFAULT_SPECS were wrong (no 
matches), the test would fail because `diff.out` would be empty. The test 
expects 8 matches. Since the diff author presumably ran the test, the 
pathspecs work. But I can't verify. So this is UNVERIFIABLE rather than a 
confirmed bug.

Hmm, but the question asks me to be adversarial and not trust diff claims. 
So I should note this as a RISK or UNVERIFIABLE.

Actually, I recall now: git pathspec `:(glob)` is specifically for "glob 
magic". The default is "literal" except that `*` and `?` still work? No, I 
think the default is literal. Let me check the exact wording:

From git docs (I recall): "pathspec without magic is matched against the 
path literally, but it also matches a directory (all paths inside the 
directory)."

But then examples like `git add Documentation/\*.txt` - the backslash 
prevents shell expansion. If git treated `*.txt` literally, it would look 
for a file named `*.txt`. But the example is meant to add all .txt files. 
So either the docs are wrong or my memory is wrong.

Wait, maybe `git add` specifically treats pathspecs as glob patterns by 
default? Or maybe all git commands do?

Let me search memory: `git status -- '*.py'` - this shows all .py files. 
The quotes prevent shell expansion. Git interprets `*.py` as a glob. So 
yes, default pathspec supports globbing.

Actually, I think the truth is: Git pathspecs have a default "glob" 
behavior for `*`, `?`, `[` even without `:(glob)` magic, but `:(glob)` 
enables additional features like `**` and trailing slash semantics. The 
`:(literal)` magic disables globbing.

So `:(top)*.md` should work. But I'm not 100% certain. I'll note it as 
UNVERIFIABLE.

2. **BUG in `sweep_claims.py` `from_diff()`**: The merge-base uses `head` 
for non-worktree, but `head` might be a symbolic ref or tag. `git 
rev-parse --verify head^{commit}` is called earlier to validate. Good.

3. **RISK in `sweep_claims.py` `sentences()`**: The owner array uses 
character indices. If the text contains combining characters or surrogate 
pairs (in narrow Python builds?), but Python 3 strings are Unicode and 
len() counts code points. Combining characters are separate code points. 
Fine.

4. **BUG in `sweep_claims.py` `blocks()`**: The `line = raw.strip()` 
strips leading/trailing whitespace. For list items, 
`raw[LIST_RE.match(raw).end():].strip()` strips the piece. For normal 
paragraphs, the piece is `line` (already stripped). So all pieces are 
stripped. Good. But this means leading spaces within a line (e.g., 
indented wrapped paragraph line) are lost. That's intended for joining 
sentences.

5. **RISK in `test_sweep_claims.sh`**: The test uses `count_is diff.out 8` 
which counts non-empty lines. But if the output format changes (e.g., due 
to word order), the count might still be 8 but the wrong lines. The 
individual `line` checks catch the important ones. Fine.

6. **BUG in `.github/workflows/clean.yml`**: The new job doesn't depend on 
anything, but it uses the same `ubuntu-latest`. Fine.

7. **RISK in `Makefile`**: The `check` target description is very long. 
Not a bug.

8. **BUG in `sweep_claims.py`**: The script exits 0 when `from_diff` 
raises `UsageError`? No, it catches and calls `p.error` which exits 2. 
Good.

9. **BUG in `sweep_claims.py`**: The `from_diff` function catches 
`UsageError` for individual file processing and adds to skipped. But if 
the initial rev-parse for `a.base` or `head` fails, it re-raises 
UsageError. For `a.base`, the error message is "not a commit: %s". For 
`head`, same. Good.

10. **Critical bug in `sweep_claims.py`**: The `from_diff` function uses 
`head` variable, but for worktree it uses `"HEAD"` for merge-base. But the 
validation loop does:
    ```python
    for ref in [a.base] + ([] if a.worktree else [head]):
        try:
            git(a.repo, "rev-parse", "--verify", "--quiet", ref + 
"^{commit}")
        except UsageError:
            raise UsageError("not a commit: %s" % ref)
    ```
    For worktree, it only validates `a.base`. Then later `mb = git(..., 
"HEAD")`. If HEAD is not a commit (e.g., empty repo), it fails. But HEAD 
in a non-empty repo is a commit. In an empty repo with no commits, the 
test's notrepo case isn't a git repo at all, so git fails earlier with 
"not a git repository". Good.

11. **RISK in `sweep_claims.py`**: The `from_diff` for worktree mode reads 
the working tree version of tracked files. But if a file has uncommitted 
changes and also staged changes, `git diff mb` shows combined working tree 
changes (both staged and unstaged?). Actually `git diff mb` compares mb to 
working tree, including both staged and unstaged changes. Good.

12. **BUG in `sweep_claims.py`**: The `--head` option is documented as 
"the change's last commit (default HEAD), read from git, not from disk". 
But the code validates `head` with `ref + "^{commit}"`. If `head` is 
`HEAD` (default), `HEAD^{commit}` works. Good.

13. **BUG in `sweep_claims.py`**: If `a.base` is `HEAD` and no worktree, 
`mb = merge-base(HEAD, head)`. If head=HEAD, mb=HEAD. Then `git diff HEAD 
HEAD` is empty. Good.

14. **Potential bug in `sweep_claims.py`**: The `from_diff` returns 
`len(files)` as the count of swept files. But `files` includes untracked 
files. Good. But for worktree, tracked files changed and untracked files 
are both counted. Good.

15. **Potential bug in `sweep_claims.py`**: The `main()` function prints 
the count even if `from_diff` raised FileNotFoundError (git not found) and 
only printed a message. In that case, `swept` is 0 (initialized), and 
`found` is empty. It prints "0 sentences to check in 0 files." But the 
message already said it was skipped. Minor inconsistency but not a bug.

16. **Potential bug in `sweep_claims.py`**: The `from_diff` catches 
`FileNotFoundError` from `subprocess.run` if git is missing. But it 
doesn't catch `OSError` (e.g., PermissionError). Actually `subprocess.run` 
raises `FileNotFoundError` for missing executable, which is a subclass of 
`OSError`. The catch for `FileNotFoundError` catches it. Good.

17. **RISK in `sweep_claims.sh`**: If python3 is found but the script 
fails to execute (e.g., permission denied on sweep_claims.py), `exec` 
fails and the shell exits with the failure code, not 0. But the script is 
created with mode 100755. Good.

18. **BUG in `sweep_claims.py`**: The `from_diff` function validates 
`a.base` and `head` as commits, but for `a.worktree`, it doesn't validate 
`head` (because head isn't used). Good.

OK, I need to decide on concrete findings.

Most significant potential issue: The pathspec `:(top)*.md` may or may not 
work as intended. But this is a new script; the test would catch it. I'll 
note it as UNVERIFIABLE rather than a confirmed bug, because I can't run 
git.

Another issue: The `blocks()` function splits a document into blocks, but 
for table rows it puts each cell as a separate single-line block. The 
cells are extracted with `cell.strip()`. But table separator rows 
(|---|---|) are also treated as cells. They might contain claim words if 
someone writes `| not |` as a separator? Unlikely. But more importantly, 
the test expects table cells to be reported. Good.

Another issue: The `WORD_RE` pattern `r"no [a-z]+"` will match phrases 
like "no such file" as a single match "no such". The output will show "no 
such" as a matched word. But the user might expect just "no". That's by 
design.

Wait, I think I found a real bug!

In `sweep_claims.py`, the `from_diff()` function computes `added` from the 
diff. But the diff is computed for the path `:(top,literal)path`. The hunk 
headers in the diff use line numbers relative to the version at `head` (or 
working tree). The `added_lines()` function extracts the `+start,count` 
from hunk headers. This gives line numbers in the `head`/working tree 
version of the file.

Then `text` is read from `head` (or working tree). So line numbers match. 
Good.

But wait: `git diff -U0 mb head` for a new file shows `@@ -0,0 +1,N @@`. 
The added set is {1, ..., N}. Good.

For a modified file, the hunk shows added lines. Good.

Now, what about `git diff -U0 mb head -- :(top,literal)path` when the file 
doesn't exist in `head` but exists in `mb`? That would be a deletion. But 
`--diff-filter=d` excludes deletions, so it won't be in the file list. 
Good.

What if the file was renamed? `--no-renames` makes it appear as deletion 
of old path and addition of new path. The new path is in the file list, 
diff shows it as new file with all lines added. Good.

OK no bug there.

Let me look for issues in the GitHub workflow.

The new job:
```yaml
  claims-sweep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check the claims sweep sees the sentences a per-line grep 
misses
        run: bash skills/independent-review/scripts/test_sweep_claims.sh
```

This is a separate job. It runs in parallel. The existing 
`independent-review` job also runs these scripts? Let me check the 
original workflow.

Original `independent-review` job steps:
```yaml
      - name: Run independent-review's failed-tier reporter self-check
        run: bash 
skills/independent-review/scripts/test_failed_tier_report.sh
      - name: Run independent-review's review-shape self-check
        run: bash 
skills/independent-review/scripts/test_looks_like_review.sh
      - name: Check SKILL.md's reviewer prompt matches the script's
        run: bash skills/independent-review/scripts/check_prompt_sync.sh
```

So the new `claims-sweep` job is separated. That's fine. But maybe it 
should be a step in the `independent-review` job to reuse checkout and be 
logically grouped. Not a bug, maybe a NIT.

Actually, looking at the workflow, each job has its own checkout. The 
original `independent-review` job is named that because it runs 
independent-review self-checks. The new `claims-sweep` is also an 
independent-review self-check. It could be a step in the same job. But 
making it separate is also valid. NIT.

**Makefile issue:** The `check` target now runs `test_sweep_claims.sh` 
which builds a throwaway repo. This requires git. But the comment says 
"the installer and claims-sweep tests need git". The test script checks 
for git and exits 0 if not found. So if git is missing, `make check` 
passes silently for these two tests. This is consistent with existing 
behavior but might be a RISK. However, it's pre-existing for 
`test_install_pin.sh`. The diff extends it to `test_sweep_claims.sh`. 
Maybe a NIT or RISK.

Actually, the prompt says "RISK (breaks on normal change, or a guard that 
cannot fire)". A guard that cannot fire is exactly this: if git is not 
present, the test exits 0, so the guard doesn't fire. But the test is for 
the sweep script itself, not for the project content. If git is absent, 
the project can't be checked anyway. This is arguably a guard that cannot 
fire. But it's pre-existing. Still, the diff adds another such guard. I 
can note it as a RISK.

**Bug in test_sweep_claims.sh with `printf`:**

Wait, in the base setup:
```bash
printf '# Notes\n\nThe first release never shipped to users.\n\nEvery job 
ran on the old runner.\nThe new runner is ready.\n' >"$R/notes.md"
```

This creates notes.md with:
1: # Notes
2: (blank)
3: The first release never shipped to users.
4: (blank)
5: Every job ran on the old runner.
6: The new runner is ready.
7: (blank)

Then on change branch, the heredoc replaces notes.md with:
1: # Notes
2: (blank)
3: The first release never shipped to users.
4: (blank)
5: Every job ran on the old runner.
6: The new runner is only ready for tests.
7: (blank)
8: *(As of 2026-01-01, the check has not been
9: attempted; see Status, row 2.)* The next run is planned.
...

Then main moves on and changes line 3 to "The first release shipped late." 
and line 6 to "The new runner is ready."

The diff from merge-base(main, change) to change should show added lines 
in notes.md:
- Line 6: changed "The new runner is ready." to "The new runner is only 
ready for tests." So line 6 is added/modified.
- Lines 8-9: new sentence wrapping.
- Line 11-13: new table.
- Lines 15-17: new fenced block.
- Line 19: new sentence.
- Lines 21-22: new list items.
- Line 24-25: new heading and paragraph.
- Lines 27-28: new quote block.

Wait, but the file in change branch also has line 3 unchanged from base 
("The first release never shipped to users."). Main changed it later. 
Three-dot diff (merge-base to change) won't include line 3 as added 
because in change branch it was unchanged from base. Good. The test C 
expects this.

Line 5 "Every job ran on the old runner." is unchanged from base. The 
second sentence on line 6 was changed. So only line 6 is added. The 
sentence on line 5 is not reported (test D). Good.

So the test logic is correct.

**Potential bug in `sweep_claims.py`: The `sentences()` function might 
mis-handle the case where a block contains only one piece with trailing 
whitespace.**

Pieces are stripped by `blocks()`, so no trailing whitespace except spaces 
added between pieces. The final piece has no trailing whitespace, so the 
final sentence ends at the last char. Good.

**Potential bug: `blocks()` for headings strips `#` from both ends.**

A heading `### #foo # ###` would become `foo`. Not a real concern.

**Potential bug: `blocks()` doesn't handle HTML comments.**

An HTML comment `<!-- ... -->` is treated as normal paragraph text. If it 
contains claim words, it would be reported. Minor.

**Potential bug: `blocks()` for setext headings.**

A setext heading:
```
Title
=====
```
Line 1 "Title" goes into cur. Line 2 "=====" matches RULE_RE, flushes cur. 
So "Title" is a block. Good. The underline is flushed as empty block (line 
2, but `not line`? Actually after strip, "=====" is not empty, but RULE_RE 
matches, so flush and continue. The line "=====" doesn't get added to any 
block. Good.

But what if there's no blank line between setext heading and next 
paragraph?
```
Title
=====
Paragraph
```
Line 1 "Title" in cur. Line 2 "=====" flushes cur → block [(1,"Title")]. 
Line 3 "Paragraph" starts new cur. Good.

What about ATX heading followed immediately by paragraph?
```
## Plan
Nothing is scheduled yet
```
Line 1 matches HEADING_RE, flushes, appends [(1,"Plan")] to out. Line 2 
"Nothing is scheduled yet" starts new cur (since previous block ended). 
Good. Test L expects this.

**Potential bug in `blocks()` for blockquotes:**

A blockquote line `> Nothing here` has quote markers removed, leaving 
"Nothing here". It goes into cur. Next line `> is final.` also removed 
quote markers, leaving "is final.", appended to cur. No blank line between 
them, so they form one block. Good. Test M expects this.

What if there's a blank line inside the blockquote? It would flush. But 
Markdown blockquotes can have blank lines (with `>`) and continue. The 
code would flush on a blank line even if it has `>`. Example:
```
> line 1
>
> line 2
```
Line 1: "line 1" in cur.
Line 2: raw is ">". After QUOTE_RE.sub("", count=1), raw becomes "" 
(empty). line = raw.strip() = "". `not line` is True, flush. So line 1 
becomes a block by itself.
Line 3: "line 2" starts new cur.
This splits the blockquote into two blocks. The sentences wouldn't run 
across the blank line. That's probably acceptable.

**Potential bug: `QUOTE_RE` uses `count=1`**

`QUOTE_RE = re.compile(r"^\s*(?:>\s?)+")`. It matches leading whitespace, 
then one or more `>` with optional space. `sub("", raw, count=1)` replaces 
the first occurrence. Since the pattern is anchored at start, it removes 
the quote markers. Good.

But what about nested blockquotes `> > line`? The pattern `>\s?` matches 
`>` optionally followed by space. For `> > line`, it matches `> > ` (two 
`>` with space between). Removing it leaves "line". Good.

What about `>   line` (space after >, then more spaces)? Pattern matches 
`>\s?` which is `> ` (one space). Then continues with `(?:>\s?)+` which 
looks for another `>` or end. It doesn't match more spaces. So it removes 
only `> `, leaving "  line". Then `line = raw.strip()` removes the spaces. 
Good. But if there are multiple spaces after `>` intended as nested quote? 
Markdown uses `>` at start of each level. `> >` for nested. So fine.

What about `>line` without space? Pattern matches `>` (since `\s?` 
optional). Good.

**Now, what about the actual bugs I can confidently identify?**

Let me look very carefully at the code one more time.

In `sweep_claims.py`, line near top:
```python
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
```
This matches a fence with 3+ backticks or tildes. Good.

In `blocks()`:
```python
m = FENCE_RE.match(raw)
if m:
    flush()
    fence = m.group(1)
```
`fence` is the fence string, e.g. "```". Then subsequent lines:
```python
if fence:
    if line and set(line) == {fence[0]} and len(line) >= len(fence):
        fence = None
    continue
```
`line = raw.strip()` already computed at top. So if closing fence is "```  
", line becomes "```" after strip. `set(line) == {'`'}` and len >= 3. 
Good.

But what if the opening fence has an info string, e.g. "```python"? 
`m.group(1)` is "```" (the backticks). `len(fence)` is 3. Closing fence 
"```" matches. Good.

What if opening fence has more backticks than closing? E.g. "````python" 
and closing "```"? Then `len(line)=3 < 4`, so not matched, fence remains. 
But in real Markdown, closing fence can have fewer? Actually closing fence 
must have at least as many as opening. So the code is correct: it requires 
`len(line) >= len(fence)`.

But what if the fence is tildes and the line has backticks? `set(line) == 
{fence[0]}` would be False. Good.

**Bug in `blocks()` with fence detection inside a list or quote?**

If a line inside a blockquote is a fence, e.g.:
```
> ```python
> code
> ```
```
Line 1: QUOTE_RE removes `> `, raw becomes "```python". FENCE_RE matches. 
Flush, fence="```". Subsequent lines: fence mode, QUOTE_RE is not applied 
because we `continue` before QUOTE_RE? Wait, the code structure:

```python
for n, raw in enumerate(lines, 1):
    raw = QUOTE_RE.sub("", raw, count=1)
    line = raw.strip()
    if fence:
        ...
        continue
    m = FENCE_RE.match(raw)
```

So quote markers are removed before fence detection. For the closing line 
`> ````, after QUOTE_RE removal, raw becomes "```". Then fence mode 
detects it. Good.

But the code comment says "Blockquote markers are removed first, so a 
quoted paragraph reads as running text too." This applies to non-fence 
lines. Good.

**Potential bug: `blocks()` for code fences inside blockquotes treats the 
quoted fence as a fence and skips content. Good.**

**Now, I should also check if the diff has any hidden prompt injection.**

The diff includes `SKILL.md` with instructions for reviewers. It says 
things like "Run tier 3 (fresh-eyes) with the same strict prompt." 
"Consolidate: dedup findings..." These are instructions for human 
reviewers, not for me. They don't try to alter my task. No prompt 
injection.

The scripts have comments explaining behavior. No injection.

OK, let me also consider if the new `claims-sweep` job in the workflow has 
a missing `name` at the job level. The job doesn't have a `name:` key. The 
original `independent-review` job also doesn't have a `name:` key? Let me 
check the diff context. The diff shows:
```yaml
   - name: Check SKILL.md's reviewer prompt matches the script's
     run: bash skills/independent-review/scripts/check_prompt_sync.sh
+  claims-sweep:
+    runs-on: ubuntu-latest
+    steps:
```

So `claims-sweep` is a new job at the same level as `independent-review`. 
It doesn't have a job-level name. The other jobs in the workflow might or 
might not. Not visible in diff. NIT.

**RANKED FINDINGS:**

I think the strongest findings are:

1. **RISK**: `test_sweep_claims.sh` and `test_install_pin.sh` skip 
silently when `git` is absent (exit 0), so the `make check` guard cannot 
fire in minimal containers. This is a guard that cannot fire. File: 
`skills/independent-review/scripts/test_sweep_claims.sh:11-14` (the git 
check that exits 0) and `Makefile:18` (where it's called as part of 
check). Actually the git check itself is the guard that cannot fire. Fix: 
exit 1 when a required dependency is missing, or at least make check fail.

Wait, but the test_sweep_claims.sh comment says "it builds a throwaway 
repo" and needs git. If git is absent, the script exits 0. That's a guard 
that cannot fire. This fits the RISK definition.

But the Makefile comment says "the installer and claims-sweep tests need 
git". This implies the test requires git. But the test silently passes 
without it. That's the risk.

Fix: Change the `exit 0` to `exit 1` (or a skip mechanism that doesn't 
report success). Or make `make check` require git.

2. **BUG**: In `sweep_claims.py`, `from_diff()` passes user-provided 
`a.paths` directly as git pathspecs to both `diff --name-only` and `diff 
-U0`, but then wraps the file path in `:(top,literal)` for the second 
diff. If a user path contains pathspec magic characters (e.g., `:(glob)` 
or `*`), the `--name-only` may interpret them, but the per-file diff uses 
literal. This inconsistency could cause a file to be listed but the 
per-file diff to fail to find it, or vice versa. Actually, more 
concretely: if `a.paths` contains `*.md`, the first `git diff` will expand 
it as a glob (if default pathspec is glob), but the per-file 
`:(top,literal)path` for each returned file would be fine. Hmm.

Actually the real issue is: when `a.paths` is provided, the exclusion 
`:(top,exclude)docs/reviews/` is dropped. The doc says named paths are 
taken as given. So that's intentional.

Let me find a more concrete bug.

3. **BUG**: `sweep_claims.py` `sentences()` owner tracking has an 
off-by-one risk for pieces with length 0, but `blocks()` filters empty 
pieces? No, it doesn't filter; `sentences()` skips empty pieces. Let me 
re-examine.

In `blocks()`, it can produce blocks containing empty pieces. For example, 
a table row `| | foo |` splits into cells `['', 'foo', '']`. The empty 
cells become `(n, '')` tuples in the block. Then `sentences()`:
```python
for n, piece in block:
    if not piece:
        continue
```
So empty pieces are skipped. Good. No off-by-one.

4. **BUG**: `sweep_claims.py` `from_diff()` uses `os.path.join(top, path)` 
to read worktree/untracked files. But `top` is the absolute path returned 
by `git rev-parse --show-toplevel`. `path` is relative to top. So the join 
is correct. Good.

5. **BUG**: In `sweep_claims.py`, if `from_diff()` raises 
`FileNotFoundError` because git is not found, the code prints a message 
and continues, then prints "0 sentences to check in 0 files." This double 
message is confusing but not wrong.

6. **BUG**: `sweep_claims.py` `from_diff()` catches `UsageError` for 
individual file errors and adds to skipped. But `UsageError` from `git 
show HEAD:path` when path doesn't exist at HEAD would be silently skipped. 
This could happen with a file that was renamed or deleted. But 
`--diff-filter=d` excludes deletions, and `--no-renames` makes renames 
appear as additions. So path should exist at HEAD for additions and 
modifications. Unless race condition. Minor.

7. **RISK**: `sweep_claims.py` `WORD_RE` includes `r"since"`, `r"until"`, 
`r"must"`, `r"by design"`, `r"on purpose"`. These are extremely broad and 
will flag many ordinary sentences, creating noise. The doc acknowledges 
the list is candidates. But including "since" and "until" in every prose 
change could overwhelm users. This might reduce the tool's usefulness. 
However, the doc says "about 4 of 45 did" need change. So 41 false 
positives is acceptable? It's advisory. Maybe a NIT to tune the list.

8. **BUG**: `sweep_claims.py` `END_RE` treats `*` as a sentence closer. So 
a sentence ending in `.*` (like a glob pattern or regex) would be cut 
short. In prose documents, `*` is often emphasis. A sentence like `Use 
*.txt files.` would be split at `*.`? Let's see: text "Use *.txt files." 
The regex matches `.` at end, with closers `*`? Wait, the sentence 
terminator is `.`, and before it is "files". After `.` there are no 
closers. So it matches the final `.`. The `*` before `.` is part of the 
sentence, not a closer. So "Use *.txt files." is one sentence. Good.

But a sentence ending with emphasis: `This is *important*.` The regex 
matches `.` followed by `*` (closer), then whitespace. So it splits at 
`*.` The sentence becomes "This is *important*." Good.

What about a sentence with `*` not as emphasis, e.g., `The pattern is a* 
b.`? The `*` is in the middle, not a closer. Good.

So `*` as closer is fine.

9. **BUG**: `sweep_claims.py` doesn't escape or normalize file paths in 
output. If a file path contains a colon, the `path:first-last` format 
becomes ambiguous. But paths in git repos rarely contain colons. NIT.

10. **RISK**: `.github/workflows/clean.yml` adds a new `claims-sweep` job 
that runs in parallel and does its own checkout. This is fine, but it 
doesn't share the `independent-review` job's context. If the workflow 
later adds a matrix or dependencies, this could be a maintenance issue. 
NIT.

11. **NIT**: `Makefile` `check` target description now says 
"independent-review's validator, prompt-sync and claims-sweep self-checks 
green" but the actual commands are test_failed_tier_report.sh, 
test_looks_like_review.sh, check_prompt_sync.sh, test_sweep_claims.sh. The 
names don't align ("validator" isn't a script name). Minor.

12. **NIT**: `sweep_claims.py` `WORD_RE` includes `r"any"` which matches 
"any" in "on any device". But "any" also appears in questions and 
conditionals. Fine.

13. **RISK/UNVERIFIABLE**: The pathspec `:(top)*.md` in `DEFAULT_SPECS` is 
load-bearing. If git's default pathspec semantics don't expand `*`, the 
default sweep finds no files. Cannot verify without running git. I should 
list this under UNVERIFIABLE.

Actually, I just realized I can reason about this more. The test fixture 
uses default specs and expects files to be found. If the pathspec were 
wrong, the test would fail. The diff author presumably ran the test. But 
as an adversarial reviewer, I can still flag it. However, since I can't 
verify, it's UNVERIFIABLE.

But is it a real risk? Let me double-check git pathspec semantics.

From git docs (paraphrasing from memory):
- `pathspec` is a path with optional magic.
- Magic signatures: top, literal, glob, exclude, icase, attr.
- If no `glob` or `literal`, the default is... I think the default is 
"literal" but most commands that accept pathspecs allow glob characters to 
be interpreted as globs even without magic. Actually, no: I think the 
default is literal, and you need `:(glob)` for globbing.

Wait, but `git add '*.c'` with quotes definitely works as a glob in my 
experience. How? Because git pathspec default supports glob? Or because of 
shell expansion in some cases?

Let me think of a concrete example. If I run `git status -- '*.py'` in a 
repo, it shows .py files. The quotes prevent shell expansion. Git must be 
interpreting `*.py` as a glob. So default pathspec supports globbing.

Actually, I think git pathspec default behavior is to treat the pathspec 
as a "pattern" that supports `*` and `?` but not `**` or trailing slash 
directory matching unless `glob` is specified. The `literal` magic 
disables this.

So `:(top)*.md` should work.

But the `glob` magic is specifically documented as "glob magic" to enable 
glob patterns. Maybe the default supports only `*` as a wildcard for 
directory matching, not as a general glob?

Hmm. I'm going to mark this as UNVERIFIABLE rather than a confirmed bug.

Let me look for a more concrete bug.

**New bug found:**

In `sweep_claims.py`, the `from_diff()` function for worktree mode:
```python
mb = git(a.repo, "merge-base", a.base, "HEAD").decode().strip()
rev = [mb]
out = git(a.repo, "diff", "--name-only", "-z", "--no-renames", 
"--diff-filter=d", *rev,
          "--", *specs)
```

`git diff --name-only mb` compares mb to the working tree. Good.

But then:
```python
diff = git(a.repo, "diff", "-U0", "--no-color", "--no-ext-diff", 
"--no-textconv",
           "--no-renames", *rev, "--", ":(top,literal)" + path)
```

Also `git diff -U0 mb`, working tree diff. Good.

But the hunk headers in a working tree diff might include changes that are 
staged AND unstaged. The added line numbers are relative to the working 
tree file. And `text = read_text(os.path.join(top, path))` reads the 
working tree file. Good.

But wait: `git diff --name-only mb` includes files that differ from mb to 
working tree. This includes files that are unchanged between mb and HEAD 
but modified in working tree. Those are correctly included. Good.

**Another bug?**

In `sweep_claims.py`, when `--worktree` is used and `a.base` is not an 
ancestor of HEAD, the merge-base is still computed correctly between 
`a.base` and HEAD. Good.

**Bug in `blocks()` with blockquotes and fences:**

If a fenced code block is inside a blockquote, the code removes `>` 
markers first, then detects the fence. Good.

But if a blockquote line is inside a fenced code block (e.g., in a code 
example), the fence detection works on the raw line (after QUOTE_RE 
removal). Wait, inside a fence, we `continue` and don't process the line. 
So a line like `> ```python` inside a code block would be skipped as part 
of the fenced block. But if it's the opening fence of a nested block? 
Markdown doesn't allow nested fences. So fine.

**Real bug in `blocks()`?**

What about a line that is part of a list item but wrapped:
```
- This is a long
  list item that wraps.
```
Line 1: matches LIST_RE, piece "This is a long", cur=[(1,"This is a 
long")].
Line 2: "  list item that wraps." Does it match LIST_RE? 
`^\s*(?:[-*+]|\d{1,9}[.)])\s+` - starts with spaces, then needs `-`, `*`, 
`+`, or digit. The next char is 'l', so no match. Does it match other 
block types? Not blank, not rule, not heading, not table. So it goes to 
else: `cur.append((2, line))` where `line = "list item that wraps."`. So 
cur becomes [(1,"This is a long"), (2,"list item that wraps.")]. Then 
`sentences()` joins them: "This is a long list item that wraps." Good.

So wrapped list items work.

What about a blank line between wrapped list item lines?
```
- This is a long

  list item that wraps.
```
Line 1: list item, cur=[(1,"This is a long")].
Line 2: blank, flush. Block [(1,"This is a long")].
Line 3: "  list item that wraps." goes to else, cur=[(3,"list item that 
wraps.")].
This splits the list item into two blocks. The sentence is broken. But 
Markdown allows blank lines in list items if indented. The code doesn't 
handle this. Could be a RISK for prose with list items containing blank 
lines. But the doc doesn't claim to handle all Markdown. I'll note it as a 
NIT or RISK.

Actually, this is more significant: a list item with a blank line (common 
in docs) would have its second part treated as a separate paragraph block, 
and a sentence might be incorrectly split or a claim might be 
misattributed. I'll flag this as a RISK.

**Another RISK: `blocks()` flushes on thematic breaks, but Markdown allows 
thematic breaks with spaces between chars. RULE_RE handles that. Good.**

**Another RISK: `blocks()` treats lines starting with digits followed by 
`.` or `)` as list items. This could misparse a paragraph starting with a 
year like "2024. The year..." because `2024.` matches `\d{1,9}[.]\s+`? 
Actually `\d{1,9}[.)]\s+` requires a digit sequence followed by `.` or `)` 
and then whitespace. For "2024. The year...", after `.` there is space, so 
it matches. Then the piece would be "The year...". This would incorrectly 
treat a paragraph starting with a date as a list item. This is a RISK.

For example, a sentence like "2024. The system was deployed." would have 
line 1 treated as a list item with piece "The system was deployed." and 
the year lost. If the claim word is in the piece, it's still found, but 
the line number and sentence start are wrong. If the claim word is "2024" 
(not a claim word), no issue. But more importantly, the sentence would be 
mis-blocked. This is a real parsing risk.

But wait, `LIST_RE` is `^\s*(?:[-*+]|\d{1,9}[.)])\s+`. For "2024. The 
system...", it matches `2024. ` (digit, period, space). The piece is "The 
system was deployed." The block is a single-item list block. The sentence 
is extracted correctly. The year is removed from the sentence, but the 
year isn't a claim word. So the claim detection still works. The only 
issue is that the sentence is classified as a list item block instead of a 
paragraph, but for sentence extraction it doesn't matter.

However, if the next line continues the paragraph:
```
2024. The system was
deployed widely.
```
Line 1: matches LIST_RE, piece "The system was", cur=[(1,"The system 
was")].
Line 2: "deployed widely." no match, goes to else, cur=[(1,"The system 
was"), (2,"deployed widely.")].
Sentence: "The system was deployed widely." Good. But the original 
sentence started with "2024." which is lost. Not a problem for claim 
detection.

But what if the text is a list item starting with a year, e.g.:
```
1. 2024 was the first year.
```
Line 1: matches LIST_RE, piece "2024 was the first year." cur=[(1,"2024 
was the first year.")].
Sentence includes "first". Good. The leading "1." is removed, which is 
correct for a list item.

So the date-paragraph case is a false positive list detection, but it 
doesn't break claim detection. I'll note it as a NIT or RISK.

**Another RISK: `blocks()` doesn't handle definition lists or task lists 
(`- [ ]`).**

A task list item `- [ ] Do something` matches LIST_RE because of the 
leading `-`. The piece becomes `[ ] Do something`. The `[ ]` is part of 
the sentence. The sentence "Do something" would be extracted? Actually 
`sentences()` extracts the whole piece "[ ] Do something" and checks for 
claim words. If "Do something" has no claim words, no report. But the `[ 
]` could be confused with closers in END_RE? No, `[` is not a closer. 
Fine.

**Another RISK: HTML/Markdown links.**

`[text](url)` - no issue.

**Another RISK: `sweep_claims.py` doesn't handle file encodings well.**
It reads files as UTF-8 with replace. Fine for most.

**Now, I think the main concrete issues I can confidently identify are:**

1. **RISK**: `test_sweep_claims.sh` (and by extension 
`test_install_pin.sh`) silently passes when a required dependency (`git`) 
is missing, making `make check` green without actually running the guard. 
This fits the prompt's definition: "a guard that cannot fire".

2. **RISK**: `sweep_claims.py` `LIST_RE` can misparse paragraphs that 
start with a number followed by `.` or `)` as list items. This could 
misblock sentences. Concrete fix: restrict `\d{1,9}[.)]` to single-digit 
or require tighter context? Actually, a line starting with a year is a 
legitimate paragraph. Markdown lists typically start with `1. ` at line 
start, but so do paragraphs starting with a year. Hard to fix without 
breaking lists. Maybe use a stricter regex that doesn't allow 4-digit 
numbers? Or accept it as a known limitation. Since the sentence is still 
extracted (minus the year), claims are still found. So maybe NIT.

3. **RISK**: `sweep_claims.py` flushes blocks on blank lines, so list 
items or blockquotes with internal blank lines (allowed in Markdown) are 
split. This could split sentences and miss claims that wrap across the 
blank line. Concrete fix: don't flush on blank lines that are within a 
list/blockquote context; track the current block type.

4. **NIT**: `sweep_claims.py` `blocks()` doesn't handle indented code 
blocks (acknowledged in doc). It will report claims inside indented code 
as prose. The doc says this is a known limitation. But since the doc 
mentions it, it's not a new finding.

5. **UNVERIFIABLE**: Whether `:(top)*.md` pathspec globs are expanded by 
git by default.

6. **NIT**: `.github/workflows/clean.yml` job `claims-sweep` is a separate 
job rather than a step in `independent-review`. It duplicates checkout. 
Could be consolidated.

7. **NIT**: `Makefile` `check` description names don't match script names.

8. **NIT/RISK**: `sweep_claims.py` `WORD_RE` includes overly broad words 
(`since`, `until`, `must`, `by design`, `on purpose`) that will produce 
many false positives. The doc says it's advisory and candidates. But could 
be tuned.

Actually, let me reconsider the silent-pass-when-git-missing issue. The 
prompt says: "RISK (breaks on normal change, or a guard that cannot 
fire)". A guard that cannot fire is exactly this. But is this introduced 
by the diff? Yes, `test_sweep_claims.sh` is new and has this behavior. So 
it's a valid finding.

However, the diff is just adding a test that follows the same pattern as 
existing tests. If `test_install_pin.sh` already does this, then the diff 
is consistent. But consistency doesn't make it not a risk. The reviewer 
should point it out.

Let me also check: Does `test_install_pin.sh` also exit 0 when git is 
missing? The Makefile comment says "the installer test needs git". I can't 
see the script in the diff. But the pattern is likely the same. The diff 
doesn't change `test_install_pin.sh`. The new script follows the pattern. 
So the finding is about the new guard specifically.

**Another concrete bug I want to check:**

In `sweep_claims.py`, the `from_diff()` function catches `OSError` and 
`UsageError` for individual file processing. But if `git show head:path` 
fails because the file is a symlink to a directory or something weird, 
it's skipped. Not a big issue.

Wait, what about `git show head:path` for a file that is executable or has 
special mode? `git show` returns the blob content. Good.

**Another potential issue: `sweep_claims.py` doesn't handle filenames with 
newlines or other weird chars.**

Git `-z` output uses NUL delimiter, so filenames with newlines are 
handled. `out.split(b"\0")` splits on NUL. Good.

For output, it prints `path:first-last`. If path contains a newline, the 
output line would be broken. But git repos rarely have newlines in 
filenames. NIT.

**OK, I think I have enough findings. Let me also think about whether 
there are any BUG-level issues.**

Actually, I think there might be a real bug in `sweep_claims.py` with how 
it handles the `--worktree` mode and untracked files. Let me re-examine.

For worktree mode:
```python
files = [(os.fsdecode(p), False) for p in out.split(b"\0") if p]
if a.worktree:
    out = git(a.repo, "ls-files", "-z", "--full-name", "--others", 
"--exclude-standard",
              "--", *specs)
    files += [(os.fsdecode(p), True) for p in out.split(b"\0") if p]
```

Then for each file:
```python
if untracked:
    text, added = read_text(os.path.join(top, path)), None
else:
    diff = git(a.repo, "diff", "-U0", ..., *rev, "--", ":(top,literal)" + 
path)
    added = added_lines(diff.decode(...))
    if a.worktree:
        text = read_text(os.path.join(top, path))
    else:
        text = git(a.repo, "show", "%s:%s" % (head, path)).decode(...)
```

For worktree mode with tracked files, `added` is computed from working 
tree diff, and `text` is read from working tree. Good.

But for untracked files, `text` is read from disk. But `path` from 
`ls-files --full-name` is relative to top. `os.path.join(top, path)` is 
correct. Good.

But wait: `ls-files --full-name` returns paths with leading `./`? No, 
`--full-name` returns the full path relative to top without `./`. Good.

**Potential bug: `git ls-files --others --exclude-standard` with pathspec 
`:(top,exclude)docs/reviews/`**
The exclude pathspec in the specs list would exclude docs/reviews/ from 
the ls-files output. So untracked review trails are excluded. The test 
expects this. Good.

**Potential bug: `git diff --name-only` with 
`:(top,exclude)docs/reviews/`**
The exclude pathspec excludes docs/reviews/ from changed files. Good.

**Now, the `DEFAULT_SPECS` list:**
```python
DEFAULT_SPECS = [":(top)*.md", ":(top)*.markdown", ":(top)*.txt", 
":(top)*.rst",
                 ":(top,exclude)docs/reviews/"]
```

These are passed as positional arguments to git after `--`. Git will 
interpret them as pathspecs. Good.

But wait: `:(top)*.md` - is there a missing space or comma? The syntax is 
`:(<magic>)<pattern>`. So `:(top)*.md` means magic `top`, pattern `*.md`. 
Good.

**OK, I think the pathspec is fine, but I'll still note it as 
unverifiable.**

Let me now think about whether the `claims-sweep` job in 
`.github/workflows/clean.yml` could have a bug.

The job runs `bash 
skills/independent-review/scripts/test_sweep_claims.sh`. This script 
creates a temp repo with git. It needs git. GitHub Actions ubuntu-latest 
has git. Good.

But the script also needs bash. It uses `#!/usr/bin/env bash`. Ubuntu has 
bash. Good.

It uses `mktemp` and `printf` and `grep`. All standard. Good.

So no bug there.

**Now, let me think about the `Makefile` again.**

```makefile
check:     ## run every suite guard: ... independent-review's validator, 
prompt-sync and claims-sweep self-checks green, no installer clobbering a 
pinned skill (each script's header says what it checks; the installer and 
claims-sweep tests need git)
	@bash scripts/check_clean.sh
	@bash scripts/check_model_agnostic.sh
	@bash scripts/check_template_coverage.sh
	@bash scripts/check_skill_budgets.sh
	@bash skills/independent-review/scripts/test_failed_tier_report.sh
	@bash skills/independent-review/scripts/test_looks_like_review.sh
	@bash skills/independent-review/scripts/check_prompt_sync.sh
	@bash skills/independent-review/scripts/test_sweep_claims.sh
	@bash scripts/test_install_pin.sh
```

The `check` target description mentions "validator" but the script is 
`test_looks_like_review.sh`. That's a naming mismatch. NIT.

Also, `test_sweep_claims.sh` is described as a "self-check" but the 
command doesn't have `@bash ...` with explicit error handling. Make will 
fail if any command returns non-zero. Good.

**Now, let me consider if there's a bug in `sweep_claims.py` with the 
`--head` option.**

The help says `--head` is "the change's last commit (default HEAD), read 
from git, not from disk". The code uses `head` for non-worktree to read 
file content from git. Good.

But what if `--head` points to a commit that doesn't contain a file that 
exists in the working tree? The `git diff --name-only mb head` will only 
list files that changed between mb and head. So if a file exists in 
working tree but not in head, it won't be listed (unless worktree mode). 
Good.

**Another bug?**

In `from_diff()`, the line:
```python
top = os.fsdecode(git(a.repo, "rev-parse", "--show-toplevel")).strip()
```
`git()` returns bytes. `os.fsdecode` decodes using the filesystem 
encoding. But `git rev-parse --show-toplevel` output is likely UTF-8. On 
most systems, filesystem encoding is UTF-8. Good. But if the repo path has 
non-ASCII chars, `os.fsdecode` is correct.

Then later:
```python
text = read_text(os.path.join(top, path))
```
`top` is str, `path` is str, join is fine. Good.

**Now, let me think about potential security issues.**

The `sweep_claims.py` script runs git commands with user-provided refs 
(`--base`, `--head`). It validates them with `ref + "^{commit}"`. This 
prevents arbitrary command injection via refs? `git rev-parse --verify 
--quiet ref^{commit}` would reject refs with shell metacharacters? 
Actually, subprocess.run passes args as a list, so shell injection is not 
possible. The ref is passed as a single argument. Git will parse it. A ref 
like `main; rm -rf /` would be treated as a single ref name and fail 
rev-parse. Good.

But what about `--repo DIR`? It's passed as `["git", "-C", repo]`. If 
`repo` contains shell metacharacters, no shell is used, so safe. But if a 
malicious `--repo` is a path that's not a git repo, git fails. Good.

**Another bug: `sweep_claims.py` doesn't validate that `--repo` is a 
directory.**

It just passes it to `git -C`. If it's not a directory, git fails with an 
error. Good.

**Another bug: `sweep_claims.py` doesn't validate `--file` paths for 
directory traversal.**

But it's a local script, not a service. Not a concern.

**Now, the prompt injection check again:**

The diff text is all code/docs/runbooks. No text addresses me as a 
reviewer or tries to change my task. No prompt injection.

**UNVERIFIABLE load-bearing claims:**

1. The pathspec `:(top)*.md` expands as intended by git. (Critical because 
it determines default file set.)
2. The test fixtures in `test_sweep_claims.sh` actually produce the 
expected line numbers and output when run. (I traced them mentally but 
cannot run.)
3. The new GitHub Actions job syntax integrates correctly with the 
existing workflow. (Cannot validate YAML syntax or workflow logic without 
running.)
4. The `WORD_RE` list captures the intended claim words without missing 
important ones or including too many. (Subjective; cannot verify without 
using the tool.)
5. The `END_RE` sentence splitting matches intended Markdown prose 
boundaries. (Cannot verify without running.)

But the prompt says "only the ones that matter". So I should list only 
critical unverifiable claims. The pathspec one is critical. The test 
output correctness is somewhat verifiable by tracing. The workflow 
integration is visible. The WORD_RE and END_RE are design choices 
documented.

Actually, the test output line numbers are something I can verify by 
careful tracing. I did trace them and they seem correct. So maybe not 
unverifiable. But I cannot be 100% sure without running. I'll include the 
pathspec as unverifiable.

**Now, let me decide on final findings:**

**BUG:**
I don't see a clear code bug that is wrong now. The closest would be if I 
found a logic error, but I haven't found a confirmed one. So maybe no 
BUGs, or I need to look harder.

Wait, I found one! In `sweep_claims.py`, the `from_diff()` function for 
non-worktree mode reads `text` from `head` commit, but `added` is computed 
from `git diff -U0 mb head`. The hunk headers use line numbers in the 
`head` version. So far so good.

But for a file that existed in `mb` and was heavily modified in `head`, 
the line numbers in `head` might not align with the diff hunks in the 
expected way. Actually, `git diff -U0` produces hunks with `+start,count` 
in the `head` version. `added_lines()` extracts those. `text` is the 
`head` version. Line numbers match. Good.

What about a file that was renamed? `--no-renames` treats it as 
deletion+addition. The new path appears as added with `@@ -0,0 +1,N @@`. 
Added lines are 1..N. `text` from `head:newpath` has N lines. Good.

Hmm, no bug.

**Another potential bug: `sweep_claims.py` `main()` returns 0 even if 
`skipped` is non-empty.**

The script exits 0 even if some files were skipped due to errors. This is 
advisory behavior, but it means a user might miss that some files weren't 
swept. The doc says "exit 0 whatever it finds; exit 2 means a usage 
error." So skipping files doesn't change exit code. This is by design. Not 
a bug.

**Another potential bug: `sweep_claims.sh` exits 0 when python3 is 
missing, but the user might not notice.**

By design, advisory. Not a bug.

**OK, maybe there are no confirmed BUGs. That's fine; the prompt allows 
RISK and NIT findings.**

Let me look for one more potential bug.

In `sweep_claims.py`, the `sentences()` function:
```python
text, owner = "", []
for n, piece in block:
    if not piece:
        continue
    if text:
        text += " "
        owner.append(n)
    text += piece
    owner.extend([n] * len(piece))
```

If `piece` contains a tab or other whitespace, `len(piece)` still counts 
characters. `text` length matches `owner` length. Good.

But what if `piece` is very long and contains its own internal newlines? 
`blocks()` strips each line, so no internal newlines. Good.

Wait, what about `piece` that is a table cell containing a newline? 
`line.strip("|").split("|")` splits on `|`, not on newlines. A cell won't 
contain a newline because `lines` are split by `\n`. Good.

**Now, I want to double-check the `END_RE` regex for a subtle bug.**

`END_RE = re.compile(r"[.!?]+[)\]*\"'_\u201d\u2019]*(?=\s|$)")`

Consider a sentence ending with `..."`. The regex matches `.` then `..."` 
as closers? Actually `[.!?]+` matches `.`, then `[)\]*\"'_\u201d\u2019]*` 
matches `)"`? No, `"` is in the class, `)` is in the class. So `.")` 
matches. Then whitespace. Good.

Consider a sentence ending with `...`. `[.!?]+` matches all three dots. 
Then closers, then whitespace. Good.

Consider `No. 1 item.`: regex matches `.` after "No", then space. So 
splits "No." and "1 item." But "No." is an abbreviation. The doc 
acknowledges abbreviations split sentences. Fine.

Consider `e.g. something.`: splits at "e.g." and "something." Fine.

**Another subtle bug: `END_RE` doesn't allow opening brackets or quotes 
before the sentence start.**

The `sentences()` function extracts the whole segment between sentence 
ends and trims whitespace. It doesn't remove opening quotes. So a sentence 
`"Hello world."` is reported as `"Hello world."` with the quotes. Good.

**OK, I'll finalize my findings.**

Actually, let me reconsider the silent-pass-when-git-missing. The test 
script says:
```bash
if ! command -v git >/dev/null 2>&1; then
  echo "SKIP: test_sweep_claims.sh needs git (it builds a throwaway repo)"
  exit 0
fi
```

In CI, git is present. In a developer's machine, git is likely present. In 
a minimal container running `make check`, git might not be present. The 
test would silently pass. This is a guard that cannot fire.

But wait, the Makefile comment says "the installer and claims-sweep tests 
need git". This is a hint that the test requires git. But the test itself 
doesn't fail when git is missing. The fix could be to exit 1 instead of 0, 
or to have the Makefile skip the test only when git is absent. But the 
test author chose exit 0 for missing dependencies. This is a pattern.

In the prompt's risk definition: "RISK (breaks on normal change, or a 
guard that cannot fire)". A guard that cannot fire when git is absent is a 
valid RISK. I'll include it.

But I should also check: is this pattern already present in 
`test_install_pin.sh`? I can't see it in the diff. But the Makefile 
comment implies it. The diff adds a new instance of the pattern. I'll flag 
the new instance.

**Alternative fix**: Make the test print a clear message and exit 1 if git 
is missing, so `make check` fails. Or, if the intent is to skip in 
environments without git, use a Makefile conditional to skip the command, 
but don't report success.

Now, let me think about another RISK: The test script uses `mktemp -d 
"${TMPDIR:-/tmp}/sweep-claims-test.XXXXXX"`. On some systems, `/tmp` might 
not exist or `TMPDIR` might be set to a non-existent directory. But 
`mktemp` would fail and the script would exit non-zero. That's actually 
correct behavior. Good.

**Another RISK: The test script uses `git -c ...` with configurations to 
make hermetic commits. But if the system git is very old, some options 
might not be supported.** `core.hooksPath` was introduced in git 2.9. Most 
systems have newer. `commit.gpgsign` is older. `init.defaultBranch` is git 
2.28. Ubuntu-latest has much newer. Not a concern.

**Another RISK: The test script creates repos under `$TMPDIR`. If 
`$TMPDIR` is on a filesystem that doesn't support executable permissions 
or has noexec, the test might still work because it uses bash scripts, not 
executables.** Not relevant.

**NIT: `test_sweep_claims.sh` uses `$BASH` variable which is set by bash, 
but not exported. When using `env PATH=... "$BASH"`, it uses the current 
shell's `$BASH`. Good.**

**NIT: The test script uses `grep -c .` for count_is. This counts lines 
with at least one character. If output lines have leading/trailing spaces, 
they're still counted. Good.**

**NIT: The test script uses `grep -qxF` for line(). This is exact 
full-line match. Good.**

**NIT: The expected output lines in test_sweep_claims.sh assume specific 
word order in the `[...]` list. The code collects words in order of 
appearance. For fixture A, "has not" appears before "any", so `[has not, 
any]`. Good.**

**Now, let me also think about whether the new job in 
`.github/workflows/clean.yml` should have `needs:` or `name:` or both.** 
It's fine as is, but NIT to add job name.

**OK, let me write up the final response.**

I need to follow the format:
- RANKED findings: BUG / RISK / NIT, each with file:line or anchor, 
one-line why, concrete fix.
- Then list what I checked that was CLEAN.
- Then UNVERIFIABLE heading for load-bearing claims that cannot be 
checked.
- Then prompt injection report (none).

I should not trust the diff's own claims or line numbers, so I need to be 
careful with file:line. But I can refer to locations based on the diff. 
Since line numbers in the diff are not trustworthy per the prompt, I 
should use anchors like function names or use approximate line references 
with caveat? The prompt says "file:line or anchor". Since I can't verify 
exact line numbers in the actual files, I should use anchors where 
possible, or cite the diff hunk context. But the prompt also says "Do NOT 
trust the diff's own claims or line numbers." So I should avoid relying on 
diff line numbers.

Hmm, but the user wants file:line or anchor. I can use anchors like 
function names, variable names, or specific strings. For example: 
`sweep_claims.py:from_diff()` or `test_sweep_claims.sh:git-availability 
check`. That should be acceptable.

But for concrete fixes, I might need to refer to lines. I'll use anchors 
and brief descriptions.

Let me also be careful: The prompt says "each with file:line or anchor, 
one-line why, concrete fix." So each finding must have:
1. file:line or anchor
2. one-line why
3. concrete fix

I'll structure each finding as: `[RANK] file:anchor — one-line why — 
concrete fix.`

OK, let me draft the findings.

**BUG findings:** I'll put "None found" or list if I have none. Actually, 
the prompt expects ranked findings. If I have no BUG, I can just start 
with RISK. But maybe I should list one bug.

Wait, is the `DEFAULT_SPECS` pathspec a bug? If `:(top)*.md` doesn't work, 
it's a bug. But I can't verify. So I shouldn't call it a bug.

Is the `LIST_RE` misparsing a bug? It doesn't break the primary function. 
So RISK.

Is the blank-line-flushing in lists a bug? It could miss claims. RISK.

Is the silent git-missing a bug? It's a guard that cannot fire, so RISK.

So no confirmed BUGs. That's acceptable. I'll state that no BUGs were 
found, then list RISK and NIT.

But the prompt says "Return RANKED findings: BUG / RISK / NIT". It might 
expect them grouped. I'll group by rank and list findings under each.

**RISK findings:**

1. `skills/independent-review/scripts/test_sweep_claims.sh:git-availability`skills/independent-review/scripts/test_sweep_claims.sh:git-availability check` — the test exits 0 when `git` is absent, so `make check` can pass 
without running a load-bearing guard. — Change `exit 0` to `exit 1` when a 
required dependency is missing, or gate the Makefile step on `command -v 
git`.

2. `skills/independent-review/scripts/sweep_claims.py:blocks()/LIST_RE` — 
a paragraph starting with a number followed by `.` or `)` (e.g., a year 
like "2024.") is misclassified as a list item, dropping the prefix and 
changing the perceived block type. — Tighten `LIST_RE` to avoid 
multi-digit ordinal lookalikes, or document the misparsing as a known 
limitation with an added test.

3. `skills/independent-review/scripts/sweep_claims.py:blocks()` — blank 
lines flush the current block unconditionally, so list items/blockquotes 
containing internal blank lines split and sentences that wrap across them 
can be broken or mis-attributed. — Track the current block kind and only 
flush blank lines that are not continuations of the active 
list/blockquote.

4. `skills/independent-review/scripts/sweep_claims.py:WORD_RE` — the claim 
list includes very broad words (`since`, `until`, `must`, `by design`, `on 
purpose`) that will generate many false positives and may obscure real 
claims. — Either tune the list based on initial runs or add a 
severity/weighting so broad markers are visually de-emphasized.

**NIT findings:**

1. `Makefile:check target description` — the description calls the scripts 
"validator, prompt-sync and claims-sweep self-checks" but the actual 
commands are `test_failed_tier_report.sh`, `test_looks_like_review.sh`, 
`check_prompt_sync.sh`, and `test_sweep_claims.sh`; the names don't line 
up. — Update the description to match the script names or vice versa.

2. `.github/workflows/clean.yml:claims-sweep job` — the new job duplicates 
checkout and runs separately from the logically related 
`independent-review` self-checks. — Fold it into the `independent-review` 
job as another step, or give it a job-level `name:` for clarity.

3. `skills/independent-review/scripts/sweep_claims.py:output format` — 
file paths in `path:first-last` are not escaped, so paths containing `:` 
or newlines will produce ambiguous output. — Use a safe delimiter or 
shell-escape/percent-encode the path.

4. `skills/independent-review/scripts/sweep_claims.py:blocks()` — indented 
(four-space) code blocks are parsed as prose; this is acknowledged in the 
doc but not pinned by a test fixture. — Add a test fixture that proves 
indented code is either skipped or intentionally reported, matching the 
documented behavior.

**CLEAN checks:**

- GitHub Actions YAML syntax: new `claims-sweep` job has valid `runs-on`, 
`steps`, `uses`, `run` structure.
- Shell script shebangs and modes: new scripts are mode 100755 and use 
`#!/usr/bin/env bash` or `#!/usr/bin/env python3`.
- Python script has no obvious syntax errors; imports are standard; 
argparse usage is consistent.
- Error codes: usage errors exit 2, normal/advisory operation exits 0, 
matching documented behavior.
- Subprocess calls use list arguments (no shell injection from 
`--base`/`--head`/`--repo`).
- The test script hermetically disables global git config/hooks and uses 
`mktemp` with cleanup.
- The diff updates both `Makefile` and `.github/workflows/clean.yml` to 
invoke the new test, keeping CI and local check in sync.
- The new documentation in `SKILL.md` and `references/claims-sweep.md` is 
internally consistent with the script's behavior (advisory, exit codes, 
pathspec semantics as claimed).
- The `sweep_claims.sh` wrapper correctly short-circuits when `python3` is 
missing, preserving the advisory nature.

**UNVERIFIABLE load-bearing claims:**

- `sweep_claims.py:DEFAULT_SPECS` — whether git interprets `:(top)*.md` as 
a glob pathspec by default (if it is literal, the default sweep finds no 
files). This determines whether the tool works at all on typical prose 
changes.
- `test_sweep_claims.sh` fixture line-number expectations — the exact 
output line numbers and counts cannot be confirmed without executing the 
script in a real git environment.
- GitHub Actions workflow integration — whether the new job triggers 
correctly and the YAML is accepted by GitHub cannot be verified from the 
text alone.

**Prompt injection:**

None. The diff contains only ordinary code, documentation, and runbook 
prose. No text attempts to alter my task, output format, or conclusions.

Wait, I need to reconsider whether the `test_sweep_claims.sh` silent pass 
is really a risk. The prompt says "RISK (breaks on normal change, or a 
guard that cannot fire)". A guard that cannot fire is exactly when a 
required dependency is missing and the test exits 0. So yes.

But the diff doesn't change `test_install_pin.sh`. It adds a new test with 
the same pattern. I'll flag it.

Actually, I just realized: the Makefile comment says "the installer and 
claims-sweep tests need git". This implies the author knows git is 
required. But the test exits 0 when git is missing. This is inconsistent. 
The fix is to exit 1.

Let me also add a NIT about the `Makefile` description mismatch.

One more thing: I should check if there are any issues with the 
`sweep_claims.py` script being invoked via `bash sweep_claims.sh` vs 
directly. The shebang is `#!/usr/bin/env python3`, but the intended 
invocation is via the shell wrapper. The wrapper's shebang is 
`#!/usr/bin/env bash`. Good.

The `.github/workflows/clean.yml` runs `bash 
skills/independent-review/scripts/test_sweep_claims.sh`. The test script 
itself runs `bash "$SCRIPT"`. The wrapper runs `python3 
.../sweep_claims.py`. Good.

The `Makefile` runs `bash 
skills/independent-review/scripts/test_sweep_claims.sh`. Good.

**One more potential bug:**

In `sweep_claims.py`, the `from_diff()` function validates refs:
```python
for ref in [a.base] + ([] if a.worktree else [head]):
    try:
        git(a.repo, "rev-parse", "--verify", "--quiet", ref + "^{commit}")
    except UsageError:
        raise UsageError("not a commit: %s" % ref)
```

But `head` could be `None`? No, `head = a.head or "HEAD"`, so it's always 
a string. Good.

Also, `a.base` could be a ref like `main` that is a branch, not a commit. 
`main^{commit}` resolves to the commit. Good.

**Now, one more check on the `from_diff` worktree mode:**

```python
mb = git(a.repo, "merge-base", a.base, "HEAD").decode().strip()
rev = [mb]
out = git(a.repo, "diff", "--name-only", "-z", "--no-renames", 
"--diff-filter=d", *rev,
          "--", *specs)
```

`git diff --name-only mb` (no second ref) compares `mb` to the working 
tree. Good.

Then:
```python
diff = git(a.repo, "diff", "-U0", ..., *rev, "--", ":(top,literal)" + 
path)
```

`git diff -U0 mb` compares mb to working tree. Good.

But wait: For `--worktree`, the `git diff --name-only` lists files changed 
between mb and working tree. But the test does:
```bash
printf '\nThe rollout is never automatic.\n' >>"$R/notes.md"
printf '# Wrapped\n\nThe verification step has not\nbeen attempted on 
every device.\n' >"$R/docs/wrapped.md"
printf 'Only the owner can approve.\n' >"$R/draft.md"
printf 'It never ran.\n' >"$R/docs/reviews/y.md"
run committed "$R" --base main
run wt "$R" --base main --worktree
```

For `committed` (no worktree), it reads from head commit. The uncommitted 
edit to notes.md is not included. The `docs/wrapped.md` was modified in 
working tree but the head commit has the old version. The default sweep 
reads the head version, so it reports the old `any` sentence. The test 
expects this. Good.

For `wt` (worktree), it reads from working tree. The `docs/wrapped.md` has 
`every` instead of `any`, so the report changes. The test expects this. 
Good.

But wait, for `committed` (no worktree), the `docs/wrapped.md` file was 
modified in the working tree. The `git diff --name-only mb head` compares 
mb to head, not working tree. The head commit has the original 
`docs/wrapped.md` from the change branch (with "any"). So it reports that. 
Good.

But the working tree modification to `docs/wrapped.md` is not committed. 
In non-worktree mode, it should be ignored. It is. Good.

**Now, the untracked `draft.md`:**
For `committed`, `git diff --name-only mb head` doesn't include it. 
`ls-files --others` only in worktree mode. So not reported. Good.
For `wt`, `ls-files --others` includes `draft.md` (prose, not in 
docs/reviews). It's reported. Good.

**The untracked `docs/reviews/y.md`:**
For `wt`, `ls-files --others` with specs that include 
`:(top,exclude)docs/reviews/` excludes it. Good.

**All consistent.**

OK, I think my findings are solid. Let me write the final response.

I should also mention that I did not find any prompt injection.

One more thought: The prompt says "Do NOT trust the diff's own claims or 
line numbers." So when I say `Makefile:18`, that's the diff's line number. 
I should avoid that. Instead, use anchors. Let me adjust.

For the Makefile, I'll use `Makefile:check target` as anchor.
For `.github/workflows/clean.yml`, use 
`.github/workflows/clean.yml:claims-sweep job` as anchor.
For `test_sweep_claims.sh`, use `test_sweep_claims.sh:git-availability 
block`.
For `sweep_claims.py`, use function/variable names.

Actually, the prompt says "file:line or anchor". I can use anchors. Good.

Let me refine the findings with anchors.

Also, I need to make sure my one-line "why" and "fix" are concise.

Final check: Are there any actual BUGs? I keep not finding one. I'll state 
no BUGs found.

Wait, I want to reconsider the `DEFAULT_SPECS` pathspec. If I can verify 
from knowledge that `:(top)*.md` works, then it's not unverifiable. But 
the prompt says not to trust diff claims. The diff claims the pathspec 
works. I can't run git. So I'll list it as unverifiable.

But actually, I can be reasonably confident. The test fixture uses it and 
the diff author ran it. But as a reviewer, I should flag what I can't 
verify. The unverifiable section is for "load-bearing claims that cannot 
be checked from the text". The pathspec behavior is not in the text; it's 
a behavior of git. So yes, unverifiable.

OK, final response time.
...done thinking.

## RANKED FINDINGS

### BUG
No confirmed bugs. The code paths I traced do not produce incorrect 
results for the cases the author explicitly tests, and the CI/local-check 
wiring is internally consistent.

### RISK
1. `skills/independent-review/scripts/test_sweep_claims.sh:git-availability`skills/independent-review/scripts/test_sweep_claims.sh:git-availability block` — exits 0 when `git` is missing, so `make check` can pass in a 
minimal container without ever running this load-bearing guard. — Change 
the missing-dependency exit to `1`, or make the Makefile step conditional 
on `command -v git` instead of faking success.

2. `skills/independent-review/scripts/sweep_claims.py:blocks()/LIST_RE` — 
a paragraph that begins with a year or number followed by `.`/`)` (e.g. 
“2024. The system…”) is misparsed as a list item, dropping the prefix and 
changing the block kind. — Tighten `LIST_RE` so multi-digit ordinals/years 
are not list markers, and add a fixture pinning the behavior.

3. `skills/independent-review/scripts/sweep_claims.py:blocks()` — blank 
lines unconditionally flush the current block, so list items or 
blockquotes that legitimately contain internal blank lines are split and 
any sentence that wraps across the break is mis-attributed or truncated. — 
Track the active block type and only flush blank lines that are not 
continuations of a list or blockquote.

4. `skills/independent-review/scripts/sweep_claims.py:WORD_RE` — the list 
includes very broad tokens (`since`, `until`, `must`, `by design`, `on 
purpose`) that will produce a high false-positive rate and may drown out 
the narrow absence/universal claims the tool is meant to surface. — Tune 
the list from initial runs, or split output into “strong” vs “broad” 
markers.

### NIT
1. `Makefile:check target description` — the description labels the checks 
“validator, prompt-sync and claims-sweep self-checks” but the actual 
commands are `test_failed_tier_report.sh`, `test_looks_like_review.sh`, 
`check_prompt_sync.sh`, and `test_sweep_claims.sh`; names do not align. — 
Make the description match the script names.

2. `.github/workflows/clean.yml:claims-sweep job` — the new job stands 
alone with its own checkout rather than being a step in the logically 
related `independent-review` job, and it has no job-level `name:`. — Fold 
it into the existing `independent-review` job or add a job-level `name:`.

3. `skills/independent-review/scripts/sweep_claims.py:output format` — 
output is `path:first-last [words] sentence`; paths containing `:` or 
newlines make the line unparseable. — Escape/percent-encode the path or 
switch to a safer delimiter.

4. `skills/independent-review/scripts/sweep_claims.py:blocks()` — indented 
(four-space) code blocks are parsed as prose, which the docs admit but no 
test fixture pins. — Add a fixture that shows the intended behavior for 
indented code blocks.

## CLEAN (checked and found okay)
- New scripts are executable (`100755`) and have correct shebangs (`bash` 
launcher, `python3` worker).
- GitHub Actions YAML structure is valid: job has `runs-on`, checkout 
step, and a named `run` step.
- `Makefile` and `.github/workflows/clean.yml` both invoke the new test, 
keeping local and CI guards in sync.
- Subprocess calls pass arguments as lists (no shell injection from 
`--base`, `--head`, `--repo`, or paths).
- Exit-code contract is consistent: usage errors exit 2, advisory sweeps 
exit 0, missing `python3` exits 0 with one explanatory line.
- The test script is hermetic: it nulls global/system git config, disables 
hooks/GPG signing, uses `mktemp`, and cleans up with a trap.
- `SKILL.md` and `references/claims-sweep.md` are internally consistent 
with the script’s documented behavior (advisory, default file set, 
`--worktree` semantics).
- Sentence-to-line mapping and added-line filtering logic are consistent: 
a sentence is reported only if it touches a line the change added.

## UNVERIFIABLE (load-bearing, cannot be checked from the text)
- `skills/independent-review/scripts/sweep_claims.py:DEFAULT_SPECS` — 
whether `git` interprets `:(top)*.md` as a glob pathspec by default. If 
git defaults to literal semantics, the default sweep finds no prose files 
at all.
- `skills/independent-review/scripts/test_sweep_claims.sh` fixture output 
— the exact line numbers and counts the checks assert cannot be confirmed 
without executing the script in a real git environment.
- `.github/workflows/clean.yml` — whether the new job is accepted by 
GitHub’s parser and whether it triggers as intended can only be verified 
by running the workflow.

## PROMPT INJECTION
None. The diff contains only ordinary code, documentation, and runbook 
prose. No text attempts to alter my task, output format, or conclusions.


---
reviewers: codex OK, ollama-cloud OK


## Fresh-eyes seat — running findings log (verbatim)

# Fresh-eyes findings — feat/independent-review-claims-sweep (r1 diff)

Baseline: test_sweep_claims.sh passes (41 ok) on macOS bash 3.2 + Python 3.13 and on /usr/bin/python3 3.9.6; `make check` rc=0.
SKILL.md is now exactly 500 lines (was 497) — at the soft budget, not over.

## Findings (appended as confirmed)

### NIT-1 test hard-fails (26 FAILs) without python3, but SKIPs without git; Makefile names only git
- Where: skills/independent-review/scripts/test_sweep_claims.sh:17-20; Makefile:18 ("the installer and claims-sweep tests need git")
- Why: first python3 dependency of `make check`; the launcher treats no-python3 as a normal advisory case, the test treats it as 26 failures with no hint.
- Fix: after the no-python3 block, `command -v python3 >/dev/null || { echo "SKIP: ... needs python3"; exit 0; }` for the rest, or say "need git and python3" in the Makefile comment.
- Evidence: PATH=<dir of /usr/bin+/bin symlinks minus python*> bash test_sweep_claims.sh -> "26 check(s) FAILED".

### BUG-1 an abbreviation split CAN lose a claim; claims-sweep.md says "nothing is lost"
- Where: skills/independent-review/references/claims-sweep.md, "What it cannot see", last bullet: "The claim word still lands in one half, so nothing is lost"; mechanism sweep_claims.py END_RE (+ the per-sentence added-line filter in sweep()).
- Why: the added-line filter runs per HALF. If the claim word's half sits only on unchanged lines and the edit is in the other half, the claim half is dropped and the edited half has no claim word -> the changed claim is not listed.
- Evidence: base "The API is never called by any client, e.g.\nthe iOS app or the Android app." ; branch edits line 2 to add "or the web app" -> `sweep_claims.sh --base main` prints "0 sentences". Same text with "for example" instead of "e.g." -> reported `a.md:1-2 [never, any] ...`.
- Fix: do not end a sentence when the next non-space char is lowercase (END_RE lookahead `(?=\s+(?![a-z])|$)` or skip a known abbreviation list e.g./i.e./etc./cf./vs.); and correct the doc bullet to say what actually happens.

### BUG-2 .rst "~" section underlines (and any ~~~ line in .txt) open a "fence" and silently swallow text
- Where: sweep_claims.py FENCE_RE (`~{3,}`) is tested before RULE_RE, whose comment says it handles "rst underline" incl. `~` — that branch is dead for 3+ tildes. .rst and .txt are in DEFAULT_SPECS.
- Why: in rst, `~~~~` is a normal subsection underline. Everything from it to the next tilde line of equal-or-greater length is skipped with no warning; an odd count swallows to EOF.
- Evidence: guide.rst with sections Install/~~~~~~~, Upgrade/~~~~~~~, Remove/~~~~~~~~~~ -> only "Upgrades are always safe." reported; "The installer never touches your data." and "Nothing is left behind." missed (both --base and --file). notes.txt "Release notes\n~~~~~~~~~~~~~\nNo data is ever deleted." -> 0 sentences.
- Fix: apply fence detection only to .md/.markdown (or treat an all-`~` line directly under a text line as an underline); and print a stderr warning when EOF is reached inside an open fence so a swallow is never silent. Add an rst fixture.

### RISK-1 a deletion that broadens a claim is invisible (no added line, so no sentence "touches" the change)
- Where: sweep_claims.py added_lines() (a `+c,0` hunk adds nothing) + sweep()'s touch filter; docs: claims-sweep.md "lists every sentence the change adds", script docstring "Only sentences that touch an added line are reported".
- Why: deleting a qualifier line ("except on a timeout.", "when the gate is red.") turns a bounded claim into a universal one — exactly the "claim stated more broadly than its evidence" class the Why section is about — and the sweep reports 0 while saying it swept the file.
- Evidence: "The job never retries,\nexcept on a timeout.\n" -> delete line 2 -> `--base main` => "0 sentences to check in 1 file." Same for "Only the owner can approve a deploy\nwhen the gate is red." minus line 2.
- Fix: in added_lines(), for a pure-deletion hunk `+c,0` also mark lines c and c+1 as touched (the sentence that now closes over the gap); add a fixture. Or document it under "What it cannot see".

### RISK-2 a file git treats as binary is "swept" with 0 added lines — silent miss, count still includes it
- Where: sweep_claims.py from_diff(), the per-file `git diff -U0 ... --no-textconv` (no `--text`).
- Why: a `-diff`/`binary` attribute (e.g. `*.txt -diff`) or one NUL byte makes git print "Binary files differ" with no hunks; added_lines() returns {} and nothing is reported while stderr says the file was swept.
- Evidence: .gitattributes `*.txt -diff`; a.txt adds "The tool never deletes data."; b.md adds "Nothing is uploaded." plus a NUL line -> "0 sentences to check in 2 files."
- Fix: add `--text` to the per-file diff (and to be safe `--inter-hunk-context=0`, see NIT); or, if the diff contains "Binary files", push it to `skipped`.

### RISK-3 load-bearing git flags are unpinned: the test passes with each removed
- Where: sweep_claims.py DEFAULT_SPECS `:(top)`, from_diff() `--exclude-standard`, `--diff-filter=d`, `--no-color`; test_sweep_claims.sh never runs from a subdirectory, has no .gitignore'd file, no deleted file, and exports GIT_CONFIG_GLOBAL=/dev/null (so no user colour config can reach the script).
- Why: each mutant below passes all 41 checks but misbehaves in real use — the "a guard that cannot fire" the test header warns about.
- Evidence (mutated copies under fresh-eyes/mut/, test run from the copy):
  - drop `:(top)` -> "all checks passed"; from `sub dir/` it sweeps only that subdir (misses `new name.md`).
  - drop `--exclude-standard` -> "all checks passed"; `--worktree` then sweeps gitignored `node_modules/pkg/README.md` (a website repo has thousands).
  - drop `--no-color` -> "all checks passed"; with color.diff=always every hunk header fails HUNK_RE -> "0 sentences to check in 2 files."
  - drop `--diff-filter=d` -> "all checks passed" (deleted files then land in "skipped" noise).
  - (two-dot, no-merge-base, no QUOTE_RE, no END_RE closers mutants DO fail the test — good.)
- Fix: add a run from a subdirectory (expect the top-level file), a gitignored untracked .md under --worktree (expect absent), a deleted .md (expect no "skipped"), and one run with `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=color.diff GIT_CONFIG_VALUE_0=always` (expect same output).

### NIT-2 diff.interHunkContext (user config) marks unchanged lines between two nearby edits as added
- Where: from_diff() per-file diff; added_lines() trusts the hunk header count.
- Evidence: edits on lines 1 and 4, "never" on unchanged line 2; with GIT_CONFIG diff.interHunkContext=5 -> `a.md:2 [never] The cache is never cleared.` reported; without -> 0. Noise, not a miss.
- Fix: pass `--inter-hunk-context=0`, or count only `+` lines inside each hunk instead of trusting `+c,n`.

### NIT-3 diff.relative=true (user config) from a subdirectory drops files outside it silently and skips the rest
- Where: from_diff() `git diff --name-only` then `:(top,literal)` + path.
- Evidence: from `sub dir/` with diff.relative=true -> "skipped ünï cödé.md (git show: hint: Did you mean 'HEAD:sub dir/…')" and `new name.md` never mentioned; count says "in 1 file" though that file was skipped.
- Fix: pass `--no-relative` (git >= 2.28) or run the diff with `-C <top>`; and don't count skipped files in "swept".

### NIT-4 exit-code contract: an unreadable --file exits 1 with a traceback
- Where: sweep_claims.py main(), `read_text(f)` for --file is not wrapped; claims-sweep.md "Exit 0 whatever it finds; exit 2 means a usage error".
- Evidence: chmod 000 locked.md; `sweep_claims.sh --file locked.md` -> PermissionError traceback, rc=1. The same condition under --worktree is caught and reported as "skipped".
- Fix: catch OSError around the --file read and route it to p.error (exit 2) or `skipped`.

### NIT-5 unrelated histories give "error: git merge-base: exit 1"
- Where: from_diff() merge-base call; doc's exit-2 list omits this case.
- Evidence: orphan branch vs main -> "sweep_claims.sh: error: git merge-base: exit 1", rc=2.
- Fix: catch it and say "no common ancestor between BASE and HEAD (unrelated histories)".

### RISK-4 a wrapped line that starts with "<number>." or "<number>)" splits the sentence as if it were a list item
- Where: sweep_claims.py LIST_RE `^\s*(?:[-*+]|\d{1,9}[.)])\s+` in blocks(), applied even mid-paragraph.
- Why: in CommonMark only an ordered item starting at 1 can interrupt a paragraph, so "since\n2024. The box..." is one paragraph; the sweep cuts it, and an edit on the second line (the year) is no longer connected to the claim on the first — the wrapped-claim case this tool exists for.
- Evidence: base "The migration has not run on any box since\n2025. The box was rebuilt then."; branch changes 2025 -> 2024 -> `--base main` => "0 sentences". `--file` shows the cut: "a.md:1 [has not, any, since] The migration has not run on any box since". Same with "release\n3) and the hotfix."
- Fix: while a paragraph (non-list block) is open, treat a digit-led line as a list start only if its number is 1; track whether `cur` is a list item. Add a fixture.

### RISK-5 WORDS misses future/modal absences — "will not", "won't", "wouldn't", "should not" — the tense a PLAN is written in
- Where: sweep_claims.py WORDS (has could/can/do/did/is/was/has, not will/would/should/need/may).
- Why: SKILL.md and claims-sweep.md advertise `--file <plan>`; plans state absences in the future tense ("The migration will not touch user data"). Inconsistent with including "could not"/"couldn't".
- Evidence: --file words.md -> "will not", "won't", "wouldn't", "should not" sentences not listed; "isn't", "doesn’t", "No user" listed.
- Fix: add `will not`, `would not`, `should not`, `need not`, `may not`, `might not`, and `wo`/`would`/`should` to the n't stem (`won[’']t`); add a fixture.

### NIT-6 exit-code contract has more exits than 0/2 (broken pipe -> 120 + traceback)
- Where: claims-sweep.md "Exit 0 whatever it finds; exit 2 means a usage error"; main().
- Evidence: 20000-sentence file `| head -1` -> rc=120, "BrokenPipeError" traceback. (Plus NIT-4's unreadable --file -> rc=1.)
- Fix: catch BrokenPipeError around the print loop (point stdout at devnull, return 0), or document "other exits = crash".

### NIT-7 launcher breaks under an exported CDPATH
- Where: sweep_claims.sh last line `$(cd "$(dirname "$0")" && pwd)`.
- Evidence: from skills/independent-review, `CDPATH=".:/tmp" bash scripts/sweep_claims.sh --file SKILL.md` -> python "can't open file '.../scripts\n/.../scripts/sweep_claims.py'", non-zero. With CDPATH naming another dir holding a `scripts/`, it resolves to THAT dir. Idiom is a repo convention (8 scripts), but this is the one a user invokes by relative path, and its header promises it never fails a step.
- Fix: `CDPATH= cd -- "$(dirname -- "$0")" && pwd` (or `>/dev/null`).

### NIT-8 docstring calls fixed regressions "Blind spots"; the real blind spots (claims-sweep.md "What it cannot see") are not pinned
- Where: sweep_claims.py docstring "Blind spots, each pinned by test_sweep_claims.sh:" — the three items are things it now handles (wrapped phrase, ".)" ending, in-word period). Commit message repeats "pins each blind spot".
- Fix: "Regressions, each pinned by test_sweep_claims.sh:"; keep "blind spots" for the What-it-cannot-see list.

### NIT-9 output format says `path:first-last` but a one-line sentence prints `path:N`
- Where: claims-sweep.md "Each line of output is `path:first-last [matched words] sentence`"; argparse epilog same.
- Fix: "`path:line` or `path:first-last`".

### NIT-10 a named PATH is resolved against --repo, not the cwd; a miss says "no changed files" and exits 0
- Where: claims-sweep.md "named paths are taken as given. `--repo DIR` runs it on another checkout."
- Evidence: from fresh-eyes/, `--repo r4 --base main "r4/new name.md"` -> "no changed files to sweep", 0 files, rc 0; `"new name.md"` works.
- Fix: say "relative to --repo (git pathspecs)"; optionally warn when a named path matches nothing.

### NIT-11 the reference's invocation can't work as written from the cwd it names
- Where: claims-sweep.md "Run it": "From the repository under review ... `scripts/sweep_claims.sh --base <base>`". `scripts/` is relative to the SKILL's directory (SKILL.md step 2 says so for independent_review.sh), not the target repo.
- Fix: write `<skill-dir>/scripts/sweep_claims.sh` (or "run it from the target repo by its skill path, or from anywhere with --repo").

### NIT-12 --base and --file on the same file report it twice and count it twice
- Evidence: `--base main --file "new name.md"` -> the same `new name.md:1` line twice, "3 sentences ... in 3 files" (2 distinct files).
- Fix: dedupe by (label, line range, sentence), or document that the two modes add up.

## Verified-by-mutation note for BUG-1's fix
END_RE lookahead `(?=\s*$|\s+(?![a-z]))` (no split before a lowercase word): full test suite still passes and the e.g. repro is then reported `a.md:1-2 [never, any] ...`.

## CLEAN (checked, came back fine)
- Diff file == `git diff origin/main...HEAD -- . ':(exclude)docs/reviews/'` in the checkout (byte-identical).
- test passes: macOS bash 3.2.57 + Python 3.13 and + /usr/bin/python3 3.9.6; `make check` rc 0; SKILL.md 500 lines (at, not over, the budget; commit message says so).
- Three-dot semantics: two-dot and no-merge-base mutants each fail 3 checks (C catches it).
- Renames: `--no-renames` -> renamed file wholly added, as the doc says. Deleted files excluded, no "skipped" noise.
- Paths with spaces + unicode (`sub dir/ünï cödé.md`, untracked `ñew draft.md`), subdirectory cwd, `--repo` from outside, detached HEAD, `--head <other branch>` while on main: all correct, top-relative labels.
- --worktree: uncommitted edit, untracked file, gitignored node_modules excluded, trail excluded.
- Exit 2: bad option, no mode, --head+--worktree, unknown ref, --head not a commit, not a repo, missing --file, empty repo, unrelated histories, bare repo. Option-looking refs (`--base=--output=...`) are stopped by rev-parse --verify.
- No git on PATH -> one line, exit 0. No python3 -> one line, exit 0 (tested by the suite; the no-python check can fail — without the guard, exec gives 127).
- color.diff=always / diff.noprefix user config: harmless (script passes --no-color).
- Test mutants that DO fail: no QUOTE_RE (M), END_RE without closers (B), two-dot (C), no merge-base (C). Fixture line numbers in the test comment match the heredoc.
- Packaging: package.sh zips all of skills/, so sweep_claims.py ships; exec bits 100755 on all three scripts.
- Commit message claims (three SKILL.md lines, four habits, 500 lines) match the diff.
- UNVERIFIABLE from this repo (not findings): "six rounds raised 83 findings", "about 4 of 45 did", "reached round 5", "lost ... after 25 minutes" in claims-sweep.md — no trail for them here.

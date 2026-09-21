# Claims sweep (Procedure step 2, prose changes)

Read this before round 1 of a review whose change is mostly prose: a docs PR/MR, a runbook, a
status table, a plan. The sweep is advisory. It never blocks a round and never counts as a
reviewer.

## Why

In a prose review the late, expensive findings are usually the author's own: a claim stated
more broadly than its evidence. "X was first deployed at revision R." "The only caller of Y."
"Never seen in production." "Step 4 has not been attempted." On one status-table
change of about 200 added lines, six rounds raised 83 findings, and from round 3 on each round
found one or two claims of this kind, at 30 to 40 minutes a round.

A per-line `grep` cannot find them reliably: "has not" at the end of one line and "been
attempted" at the start of the next is invisible to it, and one such phrase reached round 5
after a grep had "cleared" that wording. The sweep reads each paragraph, list item, heading
and table cell as running text, then lists every sentence the change adds that asserts an
absence or a universal.

## Run it

From the repository under review, with the same `<base>` the artifact uses:

```
scripts/sweep_claims.sh --base <base>              # what the branch's commits add
scripts/sweep_claims.sh --base <base> --worktree   # also uncommitted edits and untracked files
scripts/sweep_claims.sh --file <plan.md>           # a whole document: a plan, a brand-new file
scripts/sweep_claims.sh --base <sha of last round> # what this round's fixes added
```

By default it sweeps changed `*.md`, `*.markdown`, `*.txt` and `*.rst` files outside
`docs/reviews/`, the same trail exclusion the artifact uses. Name paths after the options to
sweep other files; named paths are taken as given. `--repo DIR` runs it on another checkout.

Each line of output is `path:first-last [matched words] sentence`; the count goes to stderr.
Exit 0 whatever it finds; exit 2 means a usage error (bad option, unknown ref, not a
repository, missing file). Without `python3` it prints one line and exits 0.

## Use the list

1. **Check each sentence against the record, or narrow it.** Most need no change: on the
   change above, about 4 of 45 did. The list is candidates, not errors. The sweep finds the
   sentence; only the evidence can clear it.
2. **Put what is left in the review brief** as claims to challenge, each with its evidence, so
   the seats test them instead of discovering them one round at a time.
3. **Re-run it on each fix round's new text** (`--base <sha of last round>`). A fix can make
   the next finding.

## The habits it backs

The sweep finds the sentence. These habits decide whether the sentence is true, and they do
more than the tool.

- **Write down the whole list first.** For a claim of the form first, only, last, all or
  never, list everything it ranges over (every deploy job, every caller) before writing the
  sentence, and put the whole list in the evidence block, not just the entries that support
  you. Only a reviewer who could list every deploy job could test "first deployed at R"; the
  author's evidence held two of them.
- **Read a seat's UNVERIFIABLE list as a lead.** An entry there can name your own claim. Test
  the claim; do not file the entry as a limit of that seat's access.
- **Delete an inference that has no stated basis; do not reword it.** A reworded claim is a
  new claim, and the next round reviews it.
- **Have the fresh-eyes agent keep a running findings log** in its scratch space and append
  each confirmed finding as soon as it is confirmed. One such agent was lost with its session
  after 25 minutes and left nothing.

## What it cannot see

- A claim without a listed word: "X was introduced in R" claims "first" without saying it.
  The list is `WORDS` in `scripts/sweep_claims.py`; extend it there, and add a case to
  `scripts/test_sweep_claims.sh`. Bare "not" is left out on purpose: on this skill's own
  docs, the sentences it adds are mostly contrasts ("X, not Y"), not absences.
- Indented (four-space) code blocks are read as text. Fenced blocks are skipped.
- A renamed file counts as wholly added, so all its claims are listed.
- An abbreviation such as "e.g." splits a sentence in two. The claim word still lands in one
  half, so nothing is lost; the sentence is just shorter.

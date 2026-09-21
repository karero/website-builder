#!/usr/bin/env python3
"""List the sentences a change ADDS that assert an absence or a universal.

Run it through sweep_claims.sh. Advisory: it prints candidates and exits 0; it exits 2
only for a usage error (bad arguments, an unknown ref, not a repository, a missing file).
Why and how to use the list: references/claims-sweep.md.

Why it reads sentences, not lines: a per-line grep for "not been attempted" cannot see
"has not" at the end of one line and "been attempted" at the start of the next. So each
paragraph, list item, heading or table cell is joined into running text, split into
sentences, and each sentence is mapped back to its source lines. Only sentences that
touch an added line are reported, so text the change did not write stays out of the list.

Blind spots, each pinned by test_sweep_claims.sh:
  - a phrase wrapped across a line break, which a per-line grep cannot see (the reason
    this exists);
  - an earlier sweep dropped every sentence ending ".)" or ".*": the end now allows
    closers after the stop;
  - the sweep after it cut off the start of any sentence with a period inside a word
    ("SKILL.md", "v1.2"): text between two sentence ends is now always one sentence.
"""
import argparse
import os
import re
import subprocess
import sys

# What counts as a claim worth checking: an absence, a universal, or an order ("first",
# "last"). Each entry is a regex fragment, matched case-insensitively on word boundaries.
# Extend it here. Bare "not" is left out on purpose: on this skill's own docs, the sentences
# it adds are mostly contrasts ("X, not Y"), not absences.
WORDS = [
    # absences
    r"has not", r"have not", r"had not", r"is not", r"are not", r"was not", r"were not",
    r"does not", r"do not", r"did not", r"cannot", r"can not", r"could not",
    r"(?:has|have|had|is|are|was|were|does|do|did|ca|could)n[\u2019']t",
    r"not been", r"not yet", r"no longer", r"never", r"nobody", r"no one", r"nothing",
    r"none", r"neither", r"without", r"no [a-z]+", r"zero", r"impossible",
    # universals, order and permanence
    r"only", r"first", r"last", r"all", r"every", r"any", r"always", r"ever", r"whole",
    r"entire", r"exactly", r"solely", r"both", r"unchanged", r"identical", r"since",
    r"until", r"must", r"by design", r"on purpose",
]
WORD_RE = re.compile(r"\b(?:" + "|".join(WORDS) + r")\b", re.I)

# A sentence ends at . ! or ? plus any closers, then whitespace or the end of the text.
END_RE = re.compile(r"[.!?]+[)\]*\"'_\u201d\u2019]*(?=\s|$)")

# Lines that end a block, so a sentence cannot run across two paragraphs. Blockquote
# markers are removed first, so a quoted paragraph reads as running text too.
QUOTE_RE = re.compile(r"^\s*(?:>\s?)+")
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
RULE_RE = re.compile(r"^\s*([-=*_~^])(?:\s*\1){2,}\s*$")  # thematic break, setext or rst underline
HEADING_RE = re.compile(r"^\s{0,3}#{1,6}(?:\s|$)")
TABLE_RE = re.compile(r"^\s*\|")
LIST_RE = re.compile(r"^\s*(?:[-*+]|\d{1,9}[.)])\s+")
HUNK_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")

# The default file set: prose, minus review trails (the skill keeps those out of the
# artifact it sends to reviewers, so their claims are not under review).
DEFAULT_SPECS = [":(top)*.md", ":(top)*.markdown", ":(top)*.txt", ":(top)*.rst",
                 ":(top,exclude)docs/reviews/"]


class UsageError(Exception):
    pass


def blocks(lines):
    """Split a document into blocks: lists of (line number, text) a sentence may not cross."""
    out, cur, fence = [], [], None

    def flush():
        if cur:
            out.append(list(cur))
            cur.clear()

    for n, raw in enumerate(lines, 1):
        raw = QUOTE_RE.sub("", raw, count=1)
        line = raw.strip()
        if fence:
            if line and set(line) == {fence[0]} and len(line) >= len(fence):
                fence = None
            continue
        m = FENCE_RE.match(raw)
        if m:
            flush()
            fence = m.group(1)
        elif not line or RULE_RE.match(raw):
            flush()
        elif HEADING_RE.match(raw):
            flush()
            out.append([(n, line.strip("#").strip())])
        elif TABLE_RE.match(raw):
            flush()
            out.extend([(n, cell.strip())] for cell in line.strip("|").split("|"))
        elif LIST_RE.match(raw):
            flush()
            cur.append((n, raw[LIST_RE.match(raw).end():].strip()))
        else:
            cur.append((n, line))
    flush()
    return out


def sentences(block):
    """Yield (sentence, first line, last line) for one block, its lines joined by spaces."""
    text, owner = "", []
    for n, piece in block:
        if not piece:
            continue
        if text:
            text += " "
            owner.append(n)
        text += piece
        owner.extend([n] * len(piece))
    start = 0
    for end in [m.end() for m in END_RE.finditer(text)] + [len(text)]:
        seg = text[start:end]
        a, b = start + len(seg) - len(seg.lstrip()), start + len(seg.rstrip())
        if a < b:
            yield text[a:b], owner[a], owner[b - 1]
        start = end


def sweep(label, text, added):
    """Return report lines for the sentences in text that touch an added line and make a claim.

    added is a set of line numbers, or None for "every line".
    """
    found = []
    for block in blocks(text.split("\n")):
        for sent, first, last in sentences(block):
            if added is not None and not any(n in added for n in range(first, last + 1)):
                continue
            words = []
            for m in WORD_RE.finditer(sent):
                w = m.group(0).lower()
                if w not in words:
                    words.append(w)
            if words:
                where = str(first) if first == last else "%d-%d" % (first, last)
                found.append("%s:%s [%s] %s" % (label, where, ", ".join(words), sent))
    return found


def added_lines(diff):
    added = set()
    for line in diff.splitlines():
        m = HUNK_RE.match(line)
        if m:
            start, count = int(m.group(1)), int(m.group(2) or 1)
            added.update(range(start, start + count))
    return added


def git(repo, *args):
    r = subprocess.run(["git", "-C", repo] + list(args),
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if r.returncode != 0:
        err = r.stderr.decode("utf-8", "replace").strip().splitlines()
        raise UsageError("git %s: %s" % (args[0], err[-1] if err else "exit %d" % r.returncode))
    return r.stdout


def read_text(path):
    with open(path, "rb") as f:
        return f.read().decode("utf-8", "replace")


def from_diff(a, head, found, skipped):
    """Sweep the lines added between the merge base and head (or the working tree)."""
    top = os.fsdecode(git(a.repo, "rev-parse", "--show-toplevel")).strip()
    for ref in [a.base] + ([] if a.worktree else [head]):
        try:
            git(a.repo, "rev-parse", "--verify", "--quiet", ref + "^{commit}")
        except UsageError:
            raise UsageError("not a commit: %s" % ref)
    # Three dots, as the skill builds its artifact: what head adds since it left base.
    mb = git(a.repo, "merge-base", a.base, "HEAD" if a.worktree else head).decode().strip()
    rev = [mb] if a.worktree else [mb, head]
    specs = a.paths or DEFAULT_SPECS
    # A renamed file counts as wholly added: noisier, never a miss.
    out = git(a.repo, "diff", "--name-only", "-z", "--no-renames", "--diff-filter=d", *rev,
              "--", *specs)
    files = [(os.fsdecode(p), False) for p in out.split(b"\0") if p]
    if a.worktree:
        out = git(a.repo, "ls-files", "-z", "--full-name", "--others", "--exclude-standard",
                  "--", *specs)
        files += [(os.fsdecode(p), True) for p in out.split(b"\0") if p]
    for path, untracked in files:
        try:
            if untracked:
                text, added = read_text(os.path.join(top, path)), None
            else:
                diff = git(a.repo, "diff", "-U0", "--no-color", "--no-ext-diff", "--no-textconv",
                           "--no-renames", *rev, "--", ":(top,literal)" + path)
                added = added_lines(diff.decode("utf-8", "replace"))
                if a.worktree:
                    text = read_text(os.path.join(top, path))
                else:
                    text = git(a.repo, "show", "%s:%s" % (head, path)).decode("utf-8", "replace")
        except (OSError, UsageError) as e:
            skipped.append("%s (%s)" % (path, e))
            continue
        found.extend(sweep(path, text, added))
    return len(files)


def main(argv):
    p = argparse.ArgumentParser(
        prog="sweep_claims.sh",
        description="List each sentence a change adds that asserts an absence or a universal "
                    "(never, only, first, has not ...). Advisory: exits 0 whatever it finds.",
        epilog="Output: path:first-last [matched words] sentence. The count goes to stderr. "
               "See references/claims-sweep.md.")
    p.add_argument("--base", metavar="REF",
                   help="sweep the lines added since REF (three-dot, like the review artifact)")
    p.add_argument("--head", metavar="REF",
                   help="the change's last commit (default HEAD), read from git, not from disk")
    p.add_argument("--worktree", action="store_true",
                   help="include uncommitted edits and untracked files")
    p.add_argument("--repo", metavar="DIR", default=".",
                   help="the repository (default: the current directory)")
    p.add_argument("--file", metavar="PATH", action="append", default=[], dest="files",
                   help="sweep this whole file (repeatable; for a plan or a new document)")
    p.add_argument("paths", nargs="*", metavar="PATH",
                   help="sweep only these paths, as given (default: changed *.md *.markdown "
                        "*.txt *.rst outside docs/reviews/)")
    a = p.parse_args(argv)
    if not a.base and not a.files:
        p.error("give --base REF to sweep a change, or --file PATH to sweep a whole file")
    if not a.base and (a.head or a.worktree or a.paths):
        p.error("--head, --worktree and PATH need --base")
    if a.worktree and a.head:
        p.error("--worktree reads the working tree; leave out --head")
    for f in a.files:
        if not os.path.isfile(f):
            p.error("no such file: %s" % f)

    found, skipped, swept = [], [], 0
    if a.base:
        try:
            swept = from_diff(a, a.head or "HEAD", found, skipped)
            if not swept:
                print("sweep_claims: no changed files to sweep between %s and %s." % (
                    a.base, "the working tree" if a.worktree else (a.head or "HEAD")),
                    file=sys.stderr)
        except FileNotFoundError:
            print("sweep_claims: git not found, so the change was not swept (it is advisory).",
                  file=sys.stderr)
        except UsageError as e:
            p.error(str(e))
    for f in a.files:
        found.extend(sweep(f, read_text(f), None))
        swept += 1

    for line in found:
        print(line)
    sys.stdout.flush()  # so the count lands after the list when both go to one terminal
    for s in skipped:
        print("sweep_claims: skipped %s" % s, file=sys.stderr)
    print("sweep_claims: %d sentence%s to check in %d file%s." % (
        len(found), "" if len(found) == 1 else "s", swept, "" if swept == 1 else "s"), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

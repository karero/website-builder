#!/usr/bin/env bash
# Guard: every tracked text file checks out with LF line endings, even where Git converts to
# CRLF (core.autocrlf=true, Git for Windows' default). Any sh but Git for Windows' own reads a
# CR as part of the command: a script fails in its first lines, and a check that reads Markdown
# or JSON as data sees drift that isn't there. The root .gitattributes prevents it.
#
# Why a guard: CI and every maintainer check out LF anyway, so a green `make check` looks the
# same whether that rule still works or not. This exports the index the way a CRLF checkout
# writes it, and fails on any text file that comes out holding a CR. It reads the working tree's
# .gitattributes (measured: a staged edit alone changes nothing), and ignores a global
# attributes file, which could otherwise hide a missing rule or break the self-test.
set -uo pipefail
CDPATH= cd -- "$(dirname -- "$0")/.."

if ! command -v git >/dev/null 2>&1; then
  echo "· LF checkout check skipped (no git on this machine)"
  exit 0
fi
# An unzipped copy has no index to export, and may sit inside some other repo: compare roots.
top="$(git rev-parse --show-toplevel 2>/dev/null)" && top="$(CDPATH= cd -- "$top" && pwd -P)"
if [ "$top" != "$(pwd -P)" ]; then
  echo "· LF checkout check skipped (not a git checkout of this repo, e.g. an unzipped copy)"
  exit 0
fi

T="$(mktemp -d "${TMPDIR:-/tmp}/lf-checkout.XXXXXX")" \
  || { echo "FAIL — could not create a temp dir."; exit 1; }
trap 'rm -rf "$T"' EXIT

# cr_files <repo> <dir> — export <repo>'s index into <dir> as a CRLF checkout would, then print
# each text file there that holds a CR, relative to <dir>. Exit 0 when it ran, found or not.
cr_files() {
  git -C "$1" -c core.autocrlf=true -c core.eol=crlf -c core.attributesfile=/dev/null \
    checkout-index -a -f --prefix="$2/" || return 2
  (CDPATH= cd -- "$2" && LC_ALL=C grep -rlI $'\r' .)
  [ "$?" -le 1 ]
}

# Self-test: without the rule, the same export must produce a CR, or this guard cannot fire.
mkdir -p "$T/bare" && git -C "$T/bare" init -q --template= \
  && printf 'set -eu\necho ok\n' >"$T/bare/a.sh" && git -C "$T/bare" add a.sh \
  || { echo "FAIL — could not build the self-test repo."; exit 1; }
out="$(cr_files "$T/bare" "$T/bare-out")" \
  || { echo "FAIL — the self-test export did not run."; exit 1; }
if [ -z "$out" ]; then
  echo "FAIL — self-test: a repo with no .gitattributes exported LF under core.autocrlf=true,"
  echo "so this check would pass whatever the rule says."
  exit 1
fi

out="$(cr_files . "$T/repo")" || { echo "FAIL — could not export this repo's index."; exit 1; }
if [ -n "$out" ]; then
  n="$(grep -c . <<<"$out")"
  sed -n 's|^\./||; 1,5p' <<<"$out"
  echo "FAIL — $n text file(s) would check out with CRLF on Windows (first 5 above)."
  echo "Is \`* text=auto eol=lf\` still in .gitattributes, and not overridden for these?"
  exit 1
fi
echo "LF checkout OK — every text file checks out LF even with core.autocrlf=true"

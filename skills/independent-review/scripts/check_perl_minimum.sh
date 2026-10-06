#!/usr/bin/env bash
# independent_review.sh runs its Perl programs from perl/*.pl. Each file declares the Perl it needs
# (`use 5.0xx;`), and this check holds it to that with Perl::MinimumVersion (the library behind
# `perlver`): a file whose syntax needs a newer Perl than it declares fails, and so does a file
# declaring more than its path allows. The programs the HTTP API transports run (GATED) may need up
# to the version api_tools_ok probes for; the ones that run with no version check (UNGATED: the
# ollama CLI filter, and readable_tail for any tier's FAILED section) may need no more than 5.8.
# Every file must be in exactly one list, so a new program has to be placed. Before 2026-10-06 the
# programs were inline and guarded one construct at a time (no r-flag substitution, no `//` in the
# CLI filter); the tool checks every construct it knows.
#
# Perl::MinimumVersion knows constructs, not everything: it reads syntax, so a core module or a
# built-in's newer behaviour can slip past (it is the tool's limit, not a promise of 5.8 safety). The
# runtime tests (test_failed_tier_report.sh, sections 35 and 36) still run the transports under a
# Perl that refuses the version probe.
#
# Always checked, with or without the module: every perl/*.pl is run by independent_review.sh and
# every file it runs exists; each file declares a version; the script holds no inline Perl program
# beyond the two probes in api_tools_ok. Without the module the version check is skipped, loudly;
# REQUIRE_PERL_MINIMUM=1 (CI) makes that a failure. Install: apt libperl-minimumversion-perl, or
# CPAN Perl::MinimumVersion.
# It tests itself first on fixtures, because a guard that cannot fire is worse than none.
# Run: bash skills/independent-review/scripts/check_perl_minimum.sh
set -u
here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SCRIPT="$here/independent_review.sh"; PL="$here/perl"
GATED="ollama_request.pl ollama_stream.pl melious_key.pl melious_request.pl melious_stream.pl"
UNGATED="ollama_filter.pl readable_tail.pl"
UNGATED_MAX=5.008
fails=0; checked="each needs no more than it declares (gated ≤ GMAX, ungated ≤ UMAX)"
fail() { echo "FAIL — $*"; fails=$((fails+1)); }

# The version api_tools_ok probes for is the ceiling for the gated programs.
GATED_MAX="$(sed -n "s/^[[:space:]]*perl -e 'require \(5\.[0-9]*\)'.*/\1/p" "$SCRIPT")"
[ "$(printf '%s\n' "$GATED_MAX" | grep -c .)" = 1 ] || { echo "FAIL — cannot read the one Perl version probe (perl -e 'require 5.0xx') in $SCRIPT"; exit 1; }

# --- structure (no module needed) ---
for f in "$PL"/*.pl; do
  n="${f##*/}"
  case " $GATED $UNGATED " in *" $n "*) ;; *) fail "perl/$n is in neither GATED nor UNGATED in this check: place it" ;; esac
  grep -qF "\"\$PERL_DIR/$n\"" "$SCRIPT" || fail "perl/$n is not run by independent_review.sh (\"\$PERL_DIR/$n\")"
  grep -qE '^use 5\.[0-9]+;' "$f" || fail "perl/$n declares no Perl version (a line 'use 5.0xx;')"
done
for n in $GATED $UNGATED; do
  case " $GATED " in *" $n "*) case " $UNGATED " in *" $n "*) fail "perl/$n is in both GATED and UNGATED" ;; esac ;; esac
done
for n in $(grep -o '"\$PERL_DIR/[^"]*"' "$SCRIPT" | sed 's/"\$PERL_DIR\///; s/"$//' | sort -u); do
  [ -f "$PL/$n" ] || fail "independent_review.sh runs perl/$n, which does not exist"
done
# An inline program: perl given -e (alone or bundled, as in -ne) on a line that is not a comment.
inline="$(grep -nE '(^|[^[:alnum:]_])perl([[:space:]]+-[[:alnum:]:=,]+)*[[:space:]]+-[[:alnum:]]*e([[:space:]]|$)' "$SCRIPT" \
  | grep -vE "^[0-9]+:[[:space:]]*#" \
  | grep -vE "^[0-9]+:[[:space:]]*perl -e 'require 5\.[0-9]+' 2>/dev/null \|\||^[0-9]+:[[:space:]]*perl -MJSON::PP -e 1 2>/dev/null \|\|" || true)"
[ -z "$inline" ] || fail "inline Perl in independent_review.sh; move it to perl/*.pl:
$(printf '%s\n' "$inline" | sed 's/^/    /')"

# --- minimum versions (Perl::MinimumVersion) ---
# judge <file> <max>: prints why the file fails, or nothing.
judge() {
  perl -MPerl::MinimumVersion -Mversion -e '
    my ($file, $max) = @ARGV;
    my $p = Perl::MinimumVersion->new($file) or do { print "Perl::MinimumVersion cannot parse it\n"; exit };
    my $e = $p->minimum_explicit_version;
    my $s = $p->minimum_syntax_version;
    if (!$e) { print "declares no Perl version\n"; exit }
    print "its syntax needs Perl $s, but it declares $e\n" if $s && version->parse("$s") > version->parse("$e");
    print "it declares Perl $e, above the $max its path allows\n" if version->parse("$e") > version->parse($max);
  ' "$1" "$2"
}
if ! perl -MPerl::MinimumVersion -e 1 2>/dev/null; then
  if [ "${REQUIRE_PERL_MINIMUM:-}" = 1 ]; then
    fail "Perl::MinimumVersion is not installed and REQUIRE_PERL_MINIMUM=1 (apt libperl-minimumversion-perl, or CPAN)"
  else
    echo "SKIP: Perl::MinimumVersion is not installed (apt libperl-minimumversion-perl, or CPAN), so the minimum Perl of perl/*.pl was NOT checked. CI runs it."
    checked="minimum versions NOT checked (no Perl::MinimumVersion)"
  fi
else
  # Self-test: each fixture must fail, the plain one must pass.
  T="$(mktemp -d "${TMPDIR:-/tmp}/perl-minimum.XXXXXX")" || { echo "FAIL — mktemp"; exit 1; }
  trap 'rm -rf "$T"' EXIT
  printf 'use 5.008;\nmy $x = $y // 0;\n' >"$T/dor.pl"
  printf 'use 5.010;\nmy $x = $y =~ s/a/b/r;\n' >"$T/rflag.pl"
  printf 'my $x = 1;\n' >"$T/noversion.pl"
  printf 'use 5.014;\nmy $x = 1;\n' >"$T/toohigh.pl"
  printf 'use 5.008;\nmy $x = defined $y ? $y : 0;\n' >"$T/plain.pl"
  for c in dor:5.008 rflag:5.010 noversion:5.010 toohigh:5.010; do
    [ -n "$(judge "$T/${c%%:*}.pl" "${c#*:}")" ] || fail "self-test: the check passes the ${c%%:*} fixture"
  done
  [ -z "$(judge "$T/plain.pl" 5.008)" ] || fail "self-test: the check fails the plain fixture: $(judge "$T/plain.pl" 5.008)"
  for n in $GATED $UNGATED; do
    [ -f "$PL/$n" ] || continue
    max="$GATED_MAX"; case " $UNGATED " in *" $n "*) max="$UNGATED_MAX" ;; esac
    why="$(judge "$PL/$n" "$max")"
    [ -z "$why" ] || fail "perl/$n: $why"
  done
fi

if [ $fails -ne 0 ]; then echo "$fails Perl minimum-version problem(s)"; exit 1; fi
checked="${checked/GMAX/$GATED_MAX}"; checked="${checked/UMAX/$UNGATED_MAX}"
echo "OK — perl/*.pl: every program is run and declares its Perl; $checked."

# Review trail — DIFF, rounds 1–2 (single external reviewer, owner-chosen)

- **Branch**: `fix/bing-redaction-test` — adds
  `skills/search-console-insights/scripts/tests/test_bing_key_redaction.py`,
  pinning the API-key redaction invariants shipped in #97. No production code.
- **Artifact, round 1**: branch diff `origin/main...166e696`.
- **Artifact, round 2**: branch diff `origin/main...b12bcb8` (round-1 fixes included).
- **Reviewer**: ollama `kimi-k3:cloud`, one shot per round via `ollama_review.sh --diff`,
  the same seat that reviewed #97. One seat, no clerk round.
- **Raw verbatim output**: RAW-diff-2026-09-03-r1-bing-redaction-tests-166e696.md,
  RAW-diff-2026-09-03-r2-bing-redaction-tests-b12bcb8.md.
- **Verdict, round 1**: 0 BUG, 4 RISK, 3 NIT — all accepted, none refuted.

## Why this branch exists at all

Both review rounds on #97 raised that nothing pinned the redaction invariants
(K4, then R1). Both times it was waived, with the reason recorded: the skill had
no Python test setup, so one assertion meant inventing a whole scaffold. #98 then
landed `scripts/tests/` with unittest discovery, which removed that premise about
three minutes after #97 merged. This branch closes the waiver rather than leaving
it standing on a reason that had expired.

## The verification that matters: mutation, not a green run

A passing test proves nothing by itself. Each invariant was checked by breaking
the source in the specific way the test claims to guard against, and confirming
the matching test fails. All five mutations are caught:

| # | mutation applied to `bing_query.py` | result |
|---|---|---|
| A | `raise err` moved back inside the `except` as `raise ... from None` | **caught** |
| C | structural `apikey=` pass deleted, key-based replaces kept | **caught** |
| D | key-based replaces deleted, structural pass kept | **caught** |
| E | `status_code` no longer copied onto the error | **caught** |
| F | the keyed `response` reattached to the error | **caught** |
| G | the keyed `request` reattached to the error | **caught** (only after round 2 — see T8) |

C and D are the reason two of the tests exist. The two redaction layers are
deliberately redundant, so a single outcome assertion stays green with either one
deleted — the tests would have implied a safety they were not providing. One test
now exercises a key encoding that only the structural pass catches, and another a
message shape that only the plain replace catches, pinning each layer through
behavior rather than by asserting on implementation.

A is the regression the whole file is really for: moving that raise back inside is
the natural-looking tidy-up, and it silently reattaches the unredacted original on
`__context__`, where anything walking the chain can still read the key.

## Round 1 findings (7) — on `origin/main...166e696`

| id | sev | finding | disposition |
|----|-----|---------|-------------|
| T1 | RISK | Nothing asserted the keyed `response`/`request` stay off the error; attaching either hands the key back via `.url` with the message still clean and every other assertion green | **fixed**: added `test_the_keyed_response_and_request_are_not_carried`. Confirmed by mutation F, which the new test catches and nothing else did |
| T2 | RISK | The fixture URL was hand-built with `quote_plus` while the comment called it genuine, free to drift from what requests actually produces | **fixed**: built through `requests.Request(...).prepare()`, the production encoder, no network. The fixture now tracks requests instead of guessing, so an encoding change moves the test with it |
| T3 | RISK | Patching only `requests.get` would silently miss a refactor onto `Session.get`, letting the test reach the network and pass anyway | **fixed**: the stub records that it was reached; the helper raises if production code bypassed it |
| T4 | RISK | The docstring implied `insights.py` was covered when no test invokes it | **fixed**: scope narrowed to `_fetch` reached through `get_query_stats`, stating why guarding the message there covers the callers that print it. Testing `insights` directly would drag `gsc_query` and its Google auth imports into the suite for no added guarantee |
| T5 | NIT | `assertIsInstance(err, requests.RequestException)` cannot fail — `error_from` only ever returns something caught as that type | **fixed**: removed |
| T6 | NIT | `assertNotIn(SPACED_KEY, ...)` cannot fail — the fixture only ever contains the encoded form | **fixed**: removed. The `"s3cret"` fragment assertion stays, which can fail and catches partial redaction |
| T7 | NIT | A comment claimed the structural pass was the only mechanism that could catch an exotic encoding, which over-claims | **fixed**: reworded to say what it exercises rather than what is uniquely possible |

Reviewer's CLEAN list (discovery compatibility, both error branches exercised, the
four message shapes, no credential needed, `mock.patch.object` scoping, the
no-raise guard, chaining checks, status preserved independently of the response,
synthetic keys distinctive enough for substring assertions) agrees with the
in-house pass.

## Round 2 findings (4) — on `origin/main...b12bcb8`

**Verdict**: 0 BUG, 2 RISK, 2 NIT. One RISK accepted, one refuted with evidence.

| id | sev | finding | disposition |
|----|-----|---------|-------------|
| T8 | RISK | The fixture left `.request` as `None`, so half of the assertion added in T1 could not fail. A real requests response carries the `PreparedRequest`, whose `.url` is keyed, so a regression forwarding it would copy `None` under test and the real key in production | **fixed**: the fixture sets `r.request = prepared`, as requests does. Mutation G above was added to prove it: reattaching the keyed request is now caught, and was not before this fix. A dead assertion that reads as coverage is worse than no assertion, so this was the round's real find |
| T9 | RISK | Patching `bing_query.requests.get` only intercepts attribute-style calls; a refactor to `from requests import get` would bypass the stub, reach the network, and let the test pass anyway | **refuted with evidence**: applied exactly that refactor to a copy and ran the suite. It fails — 8 failures, `AssertionError: the stubbed transport was never called` — it does not pass. The `reached` guard covers both branches: a real error trips it, and a real success falls through to the no-raise assertion. The residual is that I/O happens before the failure, 3.6s against 0.004s, which makes it a slow test rather than a false pass. A socket-level guard costs more machinery than that is worth |
| T10 | NIT | `quote_plus(KEY)` is a no-op on an alphanumeric key, so the transport-failure test was not exercising the encoded spelling it appeared to | **fixed**: uses the spaced key, so the encoded form is genuinely under test at the end of the message |
| T11 | NIT | A comment claimed the exotic-encoding case stands in for a future requests encoder, which the `keyed_400` fixture already tracks directly | **fixed**: trimmed to say what it exercises |

Reviewer's round-2 CLEAN list is notably specific and was spot-checked rather than
taken on trust: it independently confirms that `raise ... from None` still sets
`__context__` (only `__suppress_context__` changes), which is the premise the
whole file rests on, and that `RequestException.__init__` defaults `.response` and
`.request` to `None`. Both match what the mutation runs show.

## Round 3 findings (5) — on `origin/main...650291a`

**Verdict**: 0 BUG, 2 RISK, 3 NIT. Three fixed, two declined.

Tooling note: `ollama_review.sh` exited 1 on this round and routed the output to
stderr, judging it "not a review". Its heuristic misfired on the opening line
("**None demonstrable from the diff alone.**"). The content is a genuine review
and was triaged as one. Worth knowing that a clean exit code from that script is
not a reliable signal on its own.

| id | sev | finding | disposition |
|----|-----|---------|-------------|
| T12 | RISK | The stub discarded the arguments production passed it and returned a URL this file fabricated, so the suite proved redaction works on its own idea of the request rather than on the one `get_query_stats` builds | **fixed**: the fixture now prepares its response from the stub's actual arguments. Mutation H — rename the query parameter to `api_key` — is caught; before this it was not. The best finding of the three rounds: the tests read as end-to-end while quietly testing themselves |
| T13 | RISK | The chaining and attached-carrier checks ran only on the HTTP branch, though the file itself calls the transport path "a different branch" | **fixed**: both branches go through one `assertCarriesNothingKeyed` helper, which also collapses two single-assertion tests into one. Mutation A now fails on both branches instead of one |
| T14 | NIT | The docstring's "covers them all" overstates what guarding the message buys, since the file's own tests prove the message is not the only carrier | **fixed**: scoped to callers that print only the raised error, and says the response and request are checked separately |
| T15 | NIT | `sys.path.insert` uses an unnormalised, cwd-relative path | **declined**: `test_match_keywords.py` sets this pattern, and changing one of two files makes the directory inconsistent for a case the documented run command does not hit. Worth doing to both files or neither, as its own tidy |
| T16 | NIT | `mock.patch.object` mutates the shared `requests` module for the patch's duration | **no action, acknowledged**: sound under sequential unittest, which is what this suite is. The reviewer marked it as needing no action today; recorded here so a future threaded runner has the note |

Round 3's CLEAN list independently reproduced the mutation argument — it worked out
which test fails for each of the five source mutations, and matched the table above
without being shown it.

## Round closure

**Three rounds, 16 findings: 13 fixed, 1 refuted with evidence, 2 declined.** For a
test-only branch, which is a real cost and worth stating plainly. It was worth it:
rounds 2 and 3 each found a way the tests looked like they were guarding something
they were not — a dead `.request` assertion, then a fixture testing itself. Both are
the same failure mode the branch exists to prevent, one level up.

Stopping at three. The stop rule used on #97 was that a round with no behavior-level
finding closes on local verification, and round 3 did surface one, which would argue
for a fourth. The judgment against it: what carries the weight here is the mutation
table, not the rounds. Every invariant has been shown to fail when the source is
broken in the specific way it guards against, which is stronger evidence than another
opinion, and round 3's own CLEAN list arrived at that table independently. A fourth
round would most likely return more of what round 3's declined nits already were. What carries the weight here is not the
review rounds but the mutation table — every invariant has been shown to fail when
the source is broken in the specific way the test claims to guard against, which is
the only evidence that separates a real guard from a green run.

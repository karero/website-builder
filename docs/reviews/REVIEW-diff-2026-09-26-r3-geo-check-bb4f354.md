# REVIEW — DIFF gate round 3 (verification), weekly GEO check, 2026-09-26

**Reviewed:** the round-2 fix commit `3b2239c..bb4f354` (trail and fixture JSON excluded).
Verbatim: `RAW-diff-2026-09-26-r3-geo-check-bb4f354.md`.
**Reviewers:** Codex OK (cross-model). ollama-cloud FAILED (weekly usage limit). Claude fresh-eyes OK.

## Convergence check (Procedure step 7) — stopped patching, owner decided

BUGs per round: **12 → 4 → 4**. Not converging. Most round-3 findings sat again in the homepage
reader, **the sixth round** of findings on that component (P11 → Q14 → T8 → D12 → E2/E5 → R1/R2
here). Worse, the round-2 "visible text only" parser broke pages the older code read correctly
(an omitted `</head>`; `aria-hidden` split headings): a fix re-breaking working behaviour.
Taken to the owner as a decision. Verbatim: **"Simplify + fix, one final round (Recommended)"**,
with the stated rule that if the final round still finds BUGs, they go to the owner instead of
another patch cycle.

## Verified from round 2

Codex and fresh-eyes confirmed E1 (source filter), E3, E4, E6 (order), E8, E11, E12 (no-key
message) and the per-engine deadline, each shown to fail on the old code by mutating a scratch
copy.

## Round-3 findings and dispositions

C = Codex, F = fresh-eyes.

| id | sev | src | finding | disposition |
|---|---|---|---|---|
| G1 | BUG | C1 F-B2 | docs/docstring claimed a person decides before `--confirm` saves; it saved immediately; one line still promised automatic bot-wall refusal | fixed in code, not just docs: `--check-drift` prints a **page code**, and `--confirm` requires `--expect <code>` and refuses if the page changed since the preview. Docs and evals describe preview → read → confirm. `test_confirm_saves_only_the_previewed_page` (mutation-checked) |
| G2 | BUG | C2 F-N5 | hidden text inside the H1 entered the fingerprint | moot: hidden-element handling removed (G5) |
| G3 | BUG | C3 F-B3 | the stale `*` was missing on "failed" and "no answer" cells | fixed. `test_stale_marker_on_failed_and_no_answer_cells` |
| G4 | BUG | F-B1 | a lone surrogate (an emoji cut in a provider snippet) crashed the run and lost its rows | fixed: text and sources are made UTF-8-safe in `call_engine`; the answer write also catches `UnicodeError`. `test_cut_emoji_in_an_answer_does_not_crash_the_run` (mutation-checked) |
| G5 | RISK | F-R1 F-R2 | the round-2 "visible text" parser misread real homepages (no `</head>`, `aria-hidden`, implicitly closed hidden `<p>`) | **simplified (owner decision):** back to page text minus script/style/noscript/template contents; no `<head>`/hidden logic. The human preview (G1) is the safeguard. `test_page_without_closing_head_is_read` |
| G6 | RISK | F-R3 | what a person reviewed was not necessarily what was saved | fixed by G1 (`--expect`) |
| G7 | RISK | F-R4 | any empty AI Mode 200 became "no AI Mode answer", hiding a format change | fixed: only SerpApi's own "no results" maps to that state; an unreadable 200 is FAILED. `test_ai_mode_empty_200_is_a_failure_not_no_answer` |
| G8 | RISK | F-R5 | the real-response tests could not catch a parser dropping text; the mention test was circular; no real response went through `main()` | fixed: last-block phrases and exact source counts per engine; names taken from the real answer text; `test_real_anthropic_answer_through_the_weekly_run` replays a real response through `main()`. Mutations (Anthropic first block only, overview without nested lists) now fail |
| G9 | RISK | F-R6 | E12/E6 items without tests | fixed: `test_perplexity_incomplete_and_null_error_and_unclosed_quote`, `test_google_switch_cannot_be_combined_with_other_commands`, `test_legacy_config_with_unchanged_homepage_reads_same` |
| G10 | RISK | C4 | OpenAI never met a real response | **closed:** the owner added credit; real knows + finds responses captured as fixtures and parsed (7 cited sources, search confirmed) |
| G11 | RISK | C5 | E7's "only three test configs exist" lacked evidence | closed with evidence: `~/.config/gsc-insights/geo/` held exactly three configs (the test sites), all with `google: true`; the feature exists only on this unmerged branch |
| G12 | RISK | C6 | "Google's answers are steadier" was unmeasured | fixed: described as a cost choice (one paid search per question), with the thinner signal stated |
| G13 | RISK | C "provenance" | fixture capture had no record | fixed: `tests/fixtures/capture.py` is the capture script, with the trimming described |
| G14 | NIT | F-N1 | `.env`: `KEY=#abc` read as empty (bash keeps it) | fixed: only whitespace + `#` starts a comment; tested |
| G15 | NIT | F-N2 | fixtures carried third-party snippets (a bakery's phone/email) in the public repo; trimming overstated | fixed: reference titles/snippets/thumbnails and `encrypted_*` blobs dropped (40 KB total); docstrings accurate; `{}` fixture labelled synthetic. **Host note:** the first trim also blanked the AI Overview's own text (SerpApi keeps it in `snippet`), contrary to F-N2's "parsers read only url/link". It was caught before commit and that fixture re-captured |
| G16 | NIT | F-N3 | the weekly message asserted "homepage changed" for what may be a bot page | fixed: "looks different … (a real change, or a cookie/bot page this time)"; the session guide checks the "now" text first; eval 10 updated |
| G17 | NIT | F-N4 | a runtime hint printed a bare `geo_check.py` | fixed: prints the interpreter and script path actually in use |

## Status at close of round 3

- BUGs G1, G3, G4 fixed with tests (G1 and G4 mutation-checked); G2 moot.
- 107 tests pass; `check_clean` and `check_skill_budgets` pass.
- Nothing open except D24 (owner-waived pruning).
- **Round 4 (final, owner-limited):** verify these fixes. Per the owner's rule, any BUG it finds
  goes to the owner rather than into another patch cycle.

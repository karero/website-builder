# DIFF review — the visual Google & Bing report (search_report.py) — 2026-09-27

Branch `feat/gsc-visual-report`, from `7c1b320` (the build) to the PR head. Plan and scenarios:
`SKILL-PLAN-gsc-report.md` (its own PLAN gate: 7 rounds, a final full read and a wording pass).
Depth: **Normal** (reads the owner's Search Console data locally and writes a local page; no
data leaves the machine except to Google, read-only). Seats: Codex CLI (`gpt-6-astra`,
read-only) every round; a fresh-eyes Claude Sonnet pass in round 1. ollama-cloud was out of
credits for the whole gate, so every round is a single cross-model seat. Consent: the owner,
this session — "Codex and ollama pass over main" (repo content to Codex) and "run the Codex
plan review", "fix the findings and run the live run on <a real site>".

| Round | Head reviewed | BUG / RISK / NIT | What it found, in short |
|---|---|---|---|
| 1 | `7c1b320` | 4 / 4 / 1 (Codex + fresh-eyes; 3 shared) | `.env` inline comments; empty history setting; "none moved" when nothing was known; unbounded page drill-downs; position 0 as missing |
| 2 | round-1 fixes | 4 / 1 / 0 | `.env` `${VAR}`; Bing keywords from saved data; empty Bing section; root URL with a query |
| 3 | round-2 fixes | 1 / 1 / 0 | `.env` evaluated outside the job's environment |
| 4 | round-3 fixes | 1 / 2 / 0 | `.env` with track.sh's own variables and shell options — **fourth `.env` finding: stopped patching, redesigned** (track.sh records its resolved settings; the report only reads them) |
| 5 | the redesign | 4 / 1 / 0 | re-install advice would drop settings; custom history before the first record; recording failure; Bing key read as text |
| 6 | round-5 fixes | 1 / 2 / 0 | a stale record surviving a failed write; shared temp file |
| 7 | round-6 fixes | 2 / 0 / 0 | undated records; `--keywords` hid the staleness warning |
| 8 | round-7 fixes | 1 / 0 / 0 | a non-text date crashed the build |
| 9 | round-8 fix (owner-granted) | 0 / 0 / 0 | clean |

Every BUG and RISK was fixed, except:

- **Google-behaviour evidence (RISK, raised every round): waived by the owner** ("yes to both",
  2026-09-27). A no-network reviewer cannot check live Google responses. The evidence the repo
  can carry without client data: the probe script (`gsc-report-probe/gsc_probe.py`, anyone can
  re-run it), its anonymized output in the plan (identical rows across lower / Title / UPPER case;
  two individually non-empty searches return 0 rows combined; `firstIncompleteDate`; 16 months),
  and the API reference it quotes.
- Refuted: "a record written before dates existed" — no released version writes settings files
  (`git grep` on `origin/main` and `v0.27`: none), so no undated record exists in the wild; the
  code handles one anyway.

**Live runs** on one real site (read-only, the owner's OK; not named here, public repo): run 1
found two issues no stub could (old one-off keywords in the Bing section; full page addresses) —
fixed; run 2 clean.

**Tests:** 166 in the skill suite (48 new for this feature), all passing; `make check`
green. Seven deliberate breakages of key counting rules each failed the suite. Not tested:
concurrent writers beyond unique temp names and `os.replace`.

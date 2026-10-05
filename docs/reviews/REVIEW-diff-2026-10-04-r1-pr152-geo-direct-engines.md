# Independent review: PR #152, GEO_DIRECT_ENGINES (DIFF gate, depth Normal)

Reviewers: Codex (`gpt-6.1-sol`, read-only). Kimi (`kimi-k3:cloud`) FAILED: weekly usage limit
(429). Round 1 is degraded: one reviewer counted.

| Round | Head | Codex BUG / RISK / NIT | Kimi |
|---|---|---|---|
| 1 | `4576930` | 2 / 1 / 0 | failed (quota) |

## Dispositions, round 1

- **Fixed:**
  - BUG: the new comment said OpenRouter cannot give Gemini's "from memory" column; it can
    (`modes_for("gemini", "openrouter")` is `["knows"]`). The reason to name Gemini is its free
    direct key. Comment, the line-77 comment and `references/geo-check.md` say so.
  - BUG: the `--keys` summary said a named engine "uses its own key" even without one. It now
    lists the named engines and, separately, those actually routed direct. Both tests assert it.
  - RISK: "country-aware search" overstated what is known. Wording now: the site's country is
    "sent with its search", which the request builder does.
- **Verified by Codex:** routing over a 3,072-case matrix (router, keys, selections, all six
  engines); fallback without a key; unchanged behavior without OpenRouter; settings parsing;
  report and trend route marks.

## Verified

- `python -m unittest discover -s skills/search-console-insights/scripts/tests`: all pass.

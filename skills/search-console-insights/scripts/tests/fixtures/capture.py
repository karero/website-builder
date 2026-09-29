"""How tests/fixtures/*.json are made: one REAL response per engine x mode, for the parser tests
in test_real_responses.py. Not a test (no test_ prefix, never run by discovery); it calls the
real APIs with the owner's keys and costs a few cents.

  ~/.config/gsc-insights/venv/bin/python tests/fixtures/capture.py tests/fixtures

Neutral questions that name no client. A response is refused if it contains any configured key.
trim() then removes, in code, what the tests never read and the public repo shouldn't carry:
encrypted_* blobs, and the titles, snippets, thumbnails and dates of cited pages (third-party
page text) inside reference / citation / result lists. Answer text is never touched.
google-overview-finds-absent.json is a synthetic {} (a response with no ai_overview block).
After re-capturing, update test_real_responses.py: its phrases and source counts follow the
answers. First captured 2026-09-26.
"""
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
import geo_check as g  # noqa: E402

QUESTION = "Which bakeries in Munich sell sourdough bread?"
# Google showed no AI Overview for the bakery question, so that fixture uses an informational one.
QUESTION_FOR = {"google-overview": "how to make sourdough bread at home"}
META_LISTS = {"references", "citations", "results", "annotations"}
BLANK = {"title", "snippet", "thumbnail", "source", "source_icon", "cited_text", "favicon",
         "date", "last_updated", "page_age", "displayed_link",
         "content"}   # OpenRouter's url_citation carries a page excerpt here (only inside those lists)
SERP_KEEP = {"google-ai-mode": ("reconstructed_markdown", "text_blocks", "references"),
             "google-overview": ("ai_overview",)}


def trim(o, meta=False):
    if isinstance(o, dict):
        out = {}
        for k, v in o.items():
            # encrypted blobs, and OpenRouter's reasoning traces/signatures: never read by the tests
            if k.startswith("encrypted_") or k in ("reasoning", "reasoning_details", "signature", "thoughtSignature"):
                continue
            if meta and k in BLANK and isinstance(v, str):
                out[k] = ""
                continue
            inner = meta or k in META_LISTS or (k == "content" and o.get("type") == "web_search_tool_result")
            out[k] = trim(v, inner)
        return out
    if isinstance(o, list):
        return [trim(x, meta) for x in o]
    return o


def capture(out_dir: Path):
    out_dir.mkdir(parents=True, exist_ok=True)
    cfg = {"lang": "en", "country": "DE"}
    keys = g.load_keys()
    secrets = [k for k in keys.values() if k]
    for eng in g.ENGINES:
        for mode in g.modes_for(eng):
            if not keys[eng]:
                print(eng, mode, "skipped: no key")
                continue
            method, url, headers, payload = g.build_request(eng, mode, QUESTION_FOR.get(eng, QUESTION), cfg, keys[eng])
            try:
                data = g._send(method, url, headers, payload, secrets, time.monotonic() + 180)
                if eng == "google-overview":
                    ov = data.get("ai_overview") or {}
                    if ov.get("page_token") and not ov.get("text_blocks"):
                        follow = g._send("GET", url, {}, {"engine": "google_ai_overview", "page_token": ov["page_token"],
                                                          "api_key": keys[eng]}, secrets, time.monotonic() + 180)
                        data = {"ai_overview": follow.get("ai_overview", follow)}
            except g.EngineError as e:
                print(eng, mode, "ERROR", e)
                continue
            if eng in SERP_KEEP:
                data = {k: v for k, v in data.items() if k in SERP_KEEP[eng]}
            data = trim(data)
            blob = json.dumps(data, ensure_ascii=False, indent=1)
            if any(k in blob for k in secrets):
                raise SystemExit(f"{eng} {mode}: a configured key appears in the response — not saved")
            (out_dir / f"{eng}-{mode}.json").write_text(blob + "\n", encoding="utf-8")
            text, model, sources, searched = g.parse_response(eng, data)
            print(eng, mode, "chars", len(text), "model", model, "sources", len(sources), "searched", searched)
    capture_openrouter(out_dir, secrets)


def capture_openrouter(out_dir: Path, secrets):
    """The default route: openrouter-<engine>-<mode>.json, when GEO_OPENROUTER_API_KEY is set."""
    key = g.setting(g.ROUTER_VAR)
    if not key:
        print("openrouter skipped: no key")
        return
    for eng in g.CHAT_ENGINES:
        for mode in g.modes_for(eng, "openrouter"):
            method, url, headers, payload = g.build_request(eng, mode, QUESTION, {}, key, "openrouter")
            try:
                data = trim(g._send(method, url, headers, payload, [*secrets, key], time.monotonic() + 180))
            except g.EngineError as e:
                print("openrouter", eng, mode, "ERROR", e)
                continue
            blob = json.dumps(data, ensure_ascii=False, indent=1)
            if key in blob or any(k in blob for k in secrets):
                raise SystemExit(f"openrouter {eng} {mode}: a key appears in the response — not saved")
            (out_dir / f"openrouter-{eng}-{mode}.json").write_text(blob + "\n", encoding="utf-8")
            text, model, sources, searched, cost = g._openrouter_parse(data)
            print("openrouter", eng, mode, "chars", len(text), "sources", len(sources), "searched", searched, "cost", cost)


if __name__ == "__main__":
    capture(Path(sys.argv[1]))

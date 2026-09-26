"""How tests/fixtures/*.json were made: one REAL response per engine x mode, for the parser
tests in test_real_responses.py. Not a test (no test_ prefix, never run by discovery); it calls
the real APIs with the owner's keys and costs a few cents.

  ~/.config/gsc-insights/venv/bin/python tests/fixtures/capture.py tests/fixtures

Neutral question, no client. A response is refused if it contains any configured key.
Captured 2026-09-26 (OpenAI later that day, once its account had credit). Then trimmed by hand,
for size and privacy, without touching any answer text: encrypted_* blobs dropped everywhere;
the titles, snippets and thumbnails of cited references (third-party page text) blanked; SerpApi
kept to the answer blocks and reference links. The AI Overview fixture uses "how to make
sourdough bread at home" (no overview was shown for the bakery question);
google-overview-finds-absent.json is a synthetic {}. After any re-capture, re-run
test_real_responses.py: its phrases and source counts must be updated to the new answers."""
import json, sys, time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
import geo_check as g
OUT = Path(sys.argv[1]); OUT.mkdir(parents=True, exist_ok=True)
Q = "Which bakeries in Munich sell sourdough bread?"
cfg = {"lang": "en", "country": "DE", "names": ["x"], "domains": ["example.com"]}
keys = g.load_keys(); allk = [k for k in keys.values() if k]
KEEP = {"google-ai-mode": ["reconstructed_markdown", "text_blocks", "references", "error"],
        "google-overview": ["ai_overview", "error"]}
for eng in ["gemini", "anthropic", "perplexity", "google-ai-mode", "google-overview"]:
    for mode in g.MODES:
        if mode == "knows" and not g.KNOWS_SUPPORTED[eng]: continue
        if mode == "finds" and not g.FINDS_SUPPORTED[eng]: continue
        m, url, h, p = g.build_request(eng, mode, Q, cfg, keys[eng])
        try:
            data = g._send(m, url, h, p, allk, time.monotonic() + 180)
        except g.EngineError as e:
            print(eng, mode, "ERROR", e); continue
        if eng == "google-overview":
            ov = data.get("ai_overview") or {}
            if ov.get("page_token") and not ov.get("text_blocks"):
                data = g._send("GET", url, {}, {"engine": "google_ai_overview", "page_token": ov["page_token"], "api_key": keys[eng]}, allk, time.monotonic() + 180)
                data = {"ai_overview": data, "_via": "page_token follow-up"}
        if eng in KEEP:
            data = {k: v for k, v in data.items() if k in KEEP[eng] or k == "_via"}
        blob = json.dumps(data, ensure_ascii=False, indent=1)
        assert not any(k and k in blob for k in allk), "key in response!"
        (OUT / f"{eng}-{mode}.json").write_text(blob + "\n")
        t, mdl, src, srch = g.parse_response(eng, data)
        print(eng, mode, "chars", len(t), "model", mdl, "sources", len(src), "searched", srch, "bytes", len(blob))

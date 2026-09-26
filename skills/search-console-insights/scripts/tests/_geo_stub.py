"""A local stand-in for the homepage and the four AI engines, for the GEO tests.

One threaded HTTP server on 127.0.0.1 serves every route. Each test sets `STATE`
to decide what the homepage says and how each engine answers; every request is
recorded in `STATE["hits"]` so a test can prove the real code path reached it.
"""
import json
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

STATE = {}


def reset():
    STATE.clear()
    STATE.update({
        "homepage": ("<html><head><title>Bäckerei Example — Sourdough in Schwabing</title>"
                     "<meta name='description' content='Fresh sourdough bread every morning.'>"
                     "</head><body><h1>Bäckerei Example</h1></body></html>"),
        "homepage_status": 200,
        # engine -> {"status": int, "text": str, "model": str, "sources": [url], "body": str}
        "engines": {},
        "hits": [],
    })


def engine_reply(engine, text, model="m-1", sources=(), status=200, body=None, searched=True):
    STATE["engines"][engine] = {"text": text, "model": model, "sources": list(sources),
                                "status": status, "body": body, "searched": searched}


def _payload(engine, spec, finds):
    t, m, src = spec["text"], spec["model"], spec["sources"] if finds else []
    searched = finds and spec.get("searched", True)
    if engine == "gemini":
        return {"modelVersion": m, "candidates": [{"content": {"parts": [{"text": t}]}}]}
    if engine == "openai":
        out = [{"type": "web_search_call", "status": "completed"}] if searched else []
        out.append({"type": "message", "content": [{
            "type": "output_text", "text": t,
            "annotations": [{"type": "url_citation", "url": s} for s in src]}]})
        return {"model": m, "output": out}
    if engine == "anthropic":
        return {"model": m, "content": [{"type": "text", "text": t,
                                         "citations": [{"url": s} for s in src]}],
                "usage": {"server_tool_use": {"web_search_requests": 1 if searched else 0}}}
    if engine == "perplexity":
        out = [{"type": "message", "content": [{"type": "output_text", "text": t}]}]
        if src:
            out.append({"type": "search_results", "results": [{"url": s} for s in src]})
        return {"model": m, "output": out,
                "usage": {"tool_calls_details": {"search_web": {"invocation": 1 if searched else 0}}}}
    raise ValueError(engine)


def _engine_of(path):
    if ":generateContent" in path:
        return "gemini"
    return {"/v1/responses": "openai", "/v1/messages": "anthropic", "/v1/agent": "perplexity"}.get(path)


class _H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, status, body, ctype="application/json"):
        data = body.encode() if isinstance(body, str) else body
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        STATE["hits"].append(("GET", self.path, dict(self.headers), None))
        self._send(STATE["homepage_status"], STATE["homepage"], "text/html; charset=utf-8")

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        STATE["hits"].append(("POST", self.path, dict(self.headers), body))
        engine = _engine_of(self.path)
        spec = STATE["engines"].get(engine)
        if not spec:
            return self._send(500, '{"error": "no stub for this engine"}')
        if spec["status"] != 200:
            return self._send(spec["status"], spec["body"] or '{"error": "stubbed failure"}')
        finds = bool(body.get("tools"))
        self._send(200, json.dumps(_payload(engine, spec, finds)))


def start():
    reset()
    srv = ThreadingHTTPServer(("127.0.0.1", 0), _H)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv, f"http://127.0.0.1:{srv.server_address[1]}"


def env_for(base_url):
    """The environment that points geo_check at this stub — test mode only."""
    return {"GEO_TEST_MODE": "1", "GEO_HOMEPAGE_URL": base_url + "/",
            "GEO_GEMINI_BASE_URL": base_url, "GEO_OPENAI_BASE_URL": base_url,
            "GEO_ANTHROPIC_BASE_URL": base_url, "GEO_PERPLEXITY_BASE_URL": base_url}

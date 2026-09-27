"""track.sh end to end — the call launchd makes every week.

Why: the unit tests prove geo_check.py's pieces; this proves the weekly job the owner
actually relies on. Each scenario runs the real track.sh under /bin/bash (what the
launchd plist uses) with HOME in a temp dir. A shim stands in for the venv's python:
it records its argv, answers gsc_query.py / bing_query.py with the scenario's exit
code (their real work needs Google/Bing), and execs the real interpreter for everything
else — _history.py and geo_check.py run for real, against the local stub server.

Scenario ids (S1…S9) refer to docs/reviews/SKILL-PLAN-geo-check.md.

Run:  python3 -m unittest discover -s skills/search-console-insights/scripts/tests
"""
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(__file__))
import _geo_stub as stub  # noqa: E402

SCRIPTS = Path(__file__).resolve().parent.parent
DOMAIN = "example-bakery.de"
GKEY = "test-gemini-placeholder"

SHIM = """#!/bin/bash
printf '%s\\n' "$*" >> "$SHIM_LOG"
case "$1" in
  */gsc_query.py) exit "${SHIM_GSC_RC:-0}" ;;
  */bing_query.py) exit "${SHIM_BING_RC:-3}" ;;
  */_history.py) [ -n "${SHIM_HISTORY_RC:-}" ] && exit "$SHIM_HISTORY_RC" ;;
  */search_report.py) [ -n "${SHIM_REPORT_RC:-}" ] && exit "$SHIM_REPORT_RC" ;;
esac
exec "@PYTHON@" "$@"
"""


class TrackEntry(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.srv, cls.base = stub.start()

    @classmethod
    def tearDownClass(cls):
        cls.srv.shutdown()
        cls.srv.server_close()

    def setUp(self):
        stub.reset()
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        cfgdir = self.home / ".config/gsc-insights"
        (cfgdir / "venv/bin").mkdir(parents=True)
        shim = cfgdir / "venv/bin/python"
        shim.write_text(SHIM.replace("@PYTHON@", sys.executable))
        shim.chmod(0o755)
        (cfgdir / ".env").write_text("")
        self.log = self.home / "shim.log"
        self.env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": str(self.home),
                    "SHIM_LOG": str(self.log), **stub.env_for(self.base)}

    def tearDown(self):
        self.tmp.cleanup()

    def geo(self, *args, stdin=None):
        r = subprocess.run([sys.executable, str(SCRIPTS / "geo_check.py"), DOMAIN, *args],
                           env=self.env, input=stdin, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)

    def set_up_ai_check(self, key=True):
        self.geo("--init", "--name", "Bäckerei Example", "--lang", "de", "--country", "DE")
        self.geo("--set-question", "--slot", "broad", "--text-file", "-",
                 stdin="Where can I buy sourdough bread in Munich-Schwabing?")
        r = subprocess.run([sys.executable, str(SCRIPTS / "geo_check.py"), DOMAIN, "--check-drift"],
                           env=self.env, capture_output=True, text=True)
        code = re.search(r"Page code: (\w+)", r.stdout).group(1)
        self.geo("--confirm", "--expect", code)
        if key:
            self.env["GEO_GEMINI_API_KEY"] = GKEY

    def track(self, **shim_env):
        env = {**self.env, **{k: str(v) for k, v in shim_env.items()}}
        r = subprocess.run(["/bin/bash", str(SCRIPTS / "track.sh"), DOMAIN, "sourdough munich"],
                           env=env, capture_output=True, text=True, timeout=120)
        calls = self.log.read_text() if self.log.exists() else ""
        return r.returncode, r.stdout + r.stderr, calls

    def assertReachedGeo(self, calls):
        self.assertIn("geo_check.py " + DOMAIN, calls, "the shim never ran geo_check.py")

    def geo_rows(self):
        p = self.home / ".config/gsc-insights/geo/geo_history.csv"
        return p.read_text().count("\n") - 1 if p.exists() else 0

    def test_s1_green_run_with_gemini_only(self):
        self.set_up_ai_check()
        stub.engine_reply("gemini", "Bäckerei Example is the place.")
        rc, out, calls = self.track()
        self.assertEqual(rc, 0, out)
        self.assertReachedGeo(calls)
        self.assertIn("--no-browser", calls)
        self.assertIn("engines: 1 checked, 0 failed, 5 not set up", out)
        self.assertIn("Does AI name you?", out)  # the GEO trend printed after the keyword trend
        self.assertEqual(self.geo_rows(), 1)

    def test_s4_homepage_changed_stays_green(self):
        self.set_up_ai_check()
        stub.engine_reply("gemini", "Bäckerei Example.")
        stub.STATE["homepage"] = stub.STATE["homepage"].replace("Sourdough", "Cakes")
        rc, out, _ = self.track()
        self.assertEqual(rc, 0, out)
        self.assertIn("homepage looks different", out)

    def test_s4b_unreadable_homepage_stays_green(self):
        self.set_up_ai_check()
        stub.engine_reply("gemini", "Bäckerei Example.")
        stub.STATE["homepage_status"] = 503
        rc, out, _ = self.track()
        self.assertEqual(rc, 0, out)
        self.assertIn("Couldn't read your homepage", out)

    def test_the_weekly_run_writes_the_google_report_page(self):
        """S15: the owner's saved link must show this week, even when Google can't be reached
        (no sign-in here), since the page then says so at the top."""
        rc, out, calls = self.track()
        self.assertEqual(rc, 0, out)
        self.assertIn("search_report.py " + DOMAIN + " --keywords sourdough munich", calls)
        page = self.home / ".config/gsc-insights/reports" / DOMAIN / "google.html"
        self.assertTrue(page.exists(), out)
        self.assertIn("could not be loaded", page.read_text())

    def test_the_weekly_run_records_the_settings_it_resolved(self):
        """The on-demand report reads these instead of re-evaluating .env (DIFF rounds 1–4 found
        four ways a re-evaluation differs). A country set only in .env must land in the file."""
        (self.home / ".config/gsc-insights/.env").write_text("GSC_COUNTRY=deu\n")
        rc, out, _ = self.track()
        self.assertEqual(rc, 0, out)
        s = json.loads((self.home / ".config/gsc-insights/sites" / f"{DOMAIN}.json").read_text())
        self.assertEqual(s["keywords"], ["sourdough munich"])
        self.assertEqual(s["country"], "deu")
        self.assertEqual(s["csv"], str(self.home / ".config/gsc-insights/history.csv"))
        self.assertIs(s["bing"], False)                  # a flag only, never the key
        (self.home / ".config/gsc-insights/.env").write_text("BING_API_KEY=${MISSING:-}\n")
        self.track()
        s = json.loads((self.home / ".config/gsc-insights/sites" / f"{DOMAIN}.json").read_text())
        self.assertIs(s["bing"], False)                  # resolved empty, as bash sees it
        (self.home / ".config/gsc-insights/.env").write_text("BING_API_KEY=test-bing-placeholder\n")
        self.track()
        text = (self.home / ".config/gsc-insights/sites" / f"{DOMAIN}.json").read_text()
        self.assertIs(json.loads(text)["bing"], True)
        self.assertNotIn("test-bing-placeholder", text)

    def test_a_record_that_cannot_be_replaced_stays_dated_and_is_listed(self):
        """Review round 6: an older record surviving a failed write must be visible, not silent.
        Nothing is deleted (it could be another run's good record); the page names its date."""
        sites = self.home / ".config/gsc-insights/sites"
        sites.mkdir(parents=True)
        old = sites / f"{DOMAIN}.json"
        old.write_text(json.dumps({"keywords": ["old"], "country": "", "csv": "", "recorded": "2026-08-01"}))
        sites.chmod(0o555)
        try:
            rc, out, _ = self.track()
        finally:
            sites.chmod(0o755)
        self.assertEqual(rc, 1, out)
        self.assertIn("site settings not recorded", out)
        self.assertEqual(json.loads(old.read_text())["keywords"], ["old"])
        self.assertEqual([p.name for p in sites.iterdir()], [f"{DOMAIN}.json"])   # no temp file left

    def test_settings_that_cannot_be_recorded_are_listed(self):
        """A stale settings file would win over the history, so a failed write must be visible."""
        (self.home / ".config/gsc-insights/sites").write_text("not a folder")
        rc, out, _ = self.track()
        self.assertEqual(rc, 1, out)
        self.assertIn("site settings not recorded", out)

    def test_a_failed_report_page_is_listed_but_never_hides_the_gsc_exit(self):
        rc, out, _ = self.track(SHIM_REPORT_RC=1)
        self.assertEqual(rc, 1, out)
        self.assertIn("report page: exit 1", out)
        rc, out, _ = self.track(SHIM_REPORT_RC=1, SHIM_GSC_RC=2)
        self.assertEqual(rc, 2, out)                   # GSC's own code still wins

    def test_s7_not_set_up_keeps_the_old_green(self):
        rc, out, calls = self.track()
        self.assertEqual(rc, 0, out)
        self.assertReachedGeo(calls)
        self.assertIn("AI check: not set up", out)

    def test_s7b_set_up_without_key_is_red(self):
        self.set_up_ai_check(key=False)
        rc, out, _ = self.track()
        self.assertEqual(rc, 1, out)
        self.assertIn("has no engine key", out)
        self.assertIn("This run needs attention", out)

    def test_s8_failed_engine_is_red(self):
        self.set_up_ai_check()
        stub.engine_reply("gemini", "", status=403)
        rc, out, _ = self.track()
        self.assertEqual(rc, 1, out)
        self.assertIn("gemini FAILED", out)
        self.assertNotIn(GKEY, out)

    def test_s9_dead_gsc_signin_does_not_cost_the_ai_week(self):
        self.set_up_ai_check()
        stub.engine_reply("gemini", "Bäckerei Example.")
        rc, out, calls = self.track(SHIM_GSC_RC=2)
        self.assertEqual(rc, 2, out)
        self.assertReachedGeo(calls)
        self.assertEqual(self.geo_rows(), 1)
        self.assertIn("GSC: exit 2", out)

    def test_ai_check_crash_is_red(self):
        self.set_up_ai_check()
        (self.home / f".config/gsc-insights/geo/{DOMAIN}.json").write_text("{not json")
        rc, out, _ = self.track()
        self.assertEqual(rc, 1, out)
        self.assertIn("AI check: exit 1", out)

    def test_keyword_trend_failure_and_gsc_failure_both_reported(self):
        rc, out, _ = self.track(SHIM_GSC_RC=2, SHIM_HISTORY_RC=1)
        self.assertEqual(rc, 2, out)
        self.assertIn("GSC: exit 2", out)
        self.assertIn("keyword trend failed: exit 1", out)

    def test_bing_api_error_is_listed_not_swallowed(self):
        rc, out, _ = self.track(SHIM_BING_RC=1)
        self.assertEqual(rc, 1, out)
        self.assertIn("Bing: exit 1", out)

    def test_history_gap_keeps_exit_4(self):
        rc, out, _ = self.track(SHIM_BING_RC=4)
        self.assertEqual(rc, 4, out)


if __name__ == "__main__":
    unittest.main()

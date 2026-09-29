"""schedule_tracking.sh — the per-site settings file an on-demand report reads.

Why: the Google report page is built on request as well as weekly. On request it must use the
weekly job's key searches, country and history file, or the owner sees other numbers than the job
records (docs/reviews/SKILL-PLAN-gsc-report.md, Design → Site settings file). This drives the real
install and remove commands with a stand-in launchctl, so it runs on Linux CI and never loads a
real job on a Mac.

Run:  python3 -m unittest discover -s skills/search-console-insights/scripts/tests
"""
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent


class SiteSettingsFile(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        shims = self.home / "bin"
        shims.mkdir()
        for tool in ("launchctl", "plutil"):
            p = shims / tool
            p.write_text("#!/bin/sh\nexit 0\n" if tool == "launchctl" else "#!/bin/sh\nexit 1\n")
            p.chmod(0o755)
        self.env = {"HOME": str(self.home), "PATH": f"{shims}:{os.environ.get('PATH', '/usr/bin:/bin')}"}

    def tearDown(self):
        self.tmp.cleanup()

    def run_cmd(self, *args, **env):
        return subprocess.run(["/bin/bash", str(SCRIPTS / "schedule_tracking.sh"), *args],
                              env={**self.env, **env}, capture_output=True, text=True, timeout=60)

    def settings(self, domain="example-bakery.de"):
        p = self.home / ".config/gsc-insights/sites" / f"{domain}.json"
        return json.loads(p.read_text()) if p.exists() else None

    def test_install_writes_the_jobs_settings_and_remove_deletes_them(self):
        r = self.run_cmd("install", "Example-Bakery.DE", 'Sourdough "fresh",Brot München',
                         GSC_COUNTRY="deu", GSC_HISTORY_CSV="/tmp/own.csv")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        s = self.settings()
        self.assertEqual(s["keywords"], ['Sourdough "fresh"', "Brot München"])
        self.assertEqual((s["country"], s["csv"]), ("deu", "/tmp/own.csv"))
        r = self.run_cmd("remove", "example-bakery.de")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIsNone(self.settings())

    def test_an_empty_country_is_written_as_none(self):
        r = self.run_cmd("install", "example-bakery.de", "k", GSC_COUNTRY="", GSC_HISTORY_CSV="")
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual((self.settings()["country"], self.settings()["csv"]), ("", ""))


    def test_the_report_reads_what_install_writes(self):
        """Second-model review: the scheduler and track.sh each write this record, and nothing
        checked that the report reads the scheduler's copy as the weekly job's settings."""
        import sys
        from unittest import mock
        sys.path.insert(0, str(SCRIPTS))
        import search_report as sr
        own = str(self.home / "own.csv")      # read by the report, so never a shared path
        r = self.run_cmd("install", "Example-Bakery.DE", "Sourdough,Brot München",
                         GSC_COUNTRY="DEU", GSC_HISTORY_CSV=own)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        with mock.patch.dict(os.environ, {"HOME": str(self.home)}):
            s, _ = sr.resolve_settings("example-bakery.de", SimpleArgs())
        self.assertTrue(s["record_used"])
        self.assertEqual(s["keywords"], ["Sourdough", "Brot München"])
        self.assertEqual((s["country"], s["csv"]), ("deu", own))
        self.assertTrue(s["from"].startswith("your weekly check on "))


class SimpleArgs:
    keywords = country = csv = None

if __name__ == "__main__":
    unittest.main()

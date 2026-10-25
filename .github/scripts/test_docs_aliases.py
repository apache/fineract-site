#!/usr/bin/env python3
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#
"""Tests for docs_aliases.py."""

import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import docs_aliases

HTACCESS = """\
# deprecated "current" release version alias
RewriteRule ^docs/current(.*)$ docs/stable$1 [R=301,L]

# latest stable release version alias
RewriteRule ^docs/stable(.*)$ docs/1.16.0$1 [L]

# recent / bleeding-edge, built from develop branch of apache/fineract repo
RewriteRule ^docs/develop(.*)$ docs/1.17.0-SNAPSHOT$1 [L]

# stub for /docs/rc (enable outside release process)
RewriteRule ^docs/rc(.*)$ docs/stable$1 [L]
# candidate for next release (enable during release process)
#RewriteRule ^docs/rc(.*)$ docs/1.17.0$1 [L]
"""

MESSAGE = (
    "update /docs/{version}\n\n"
    "docs built with `./gradlew asciidoctor` from "
    "https://github.com/apache/fineract/commit/0000000000000000000000000000000000000000\n\n"
    "change made with `fineract-site docs`"
)


class UpdateAliasesTest(unittest.TestCase):
    def test_stable_moves_only_the_stable_line(self):
        htaccess, notes = docs_aliases.update_aliases(HTACCESS, "stable", "1.17.0")
        self.assertEqual(
            htaccess,
            HTACCESS.replace("docs/stable(.*)$ docs/1.16.0$1", "docs/stable(.*)$ docs/1.17.0$1"),
        )
        self.assertEqual(len(notes), 1)

    def test_develop_moves_develop_and_rc_candidate(self):
        htaccess, notes = docs_aliases.update_aliases(HTACCESS, "develop", "1.18.0-SNAPSHOT")
        self.assertIn("RewriteRule ^docs/develop(.*)$ docs/1.18.0-SNAPSHOT$1 [L]", htaccess)
        self.assertIn("#RewriteRule ^docs/rc(.*)$ docs/1.18.0$1 [L]", htaccess)
        # The active /docs/rc stub keeps pointing at stable.
        self.assertIn("RewriteRule ^docs/rc(.*)$ docs/stable$1 [L]", htaccess)
        self.assertIn("RewriteRule ^docs/stable(.*)$ docs/1.16.0$1 [L]", htaccess)
        self.assertEqual(len(notes), 2)

    def test_unchanged_version_is_a_no_op(self):
        self.assertEqual(docs_aliases.update_aliases(HTACCESS, "stable", "1.16.0"), (HTACCESS, []))
        self.assertEqual(
            docs_aliases.update_aliases(HTACCESS, "develop", "1.17.0-SNAPSHOT"), (HTACCESS, [])
        )

    def test_missing_rule_exits(self):
        with self.assertRaises(SystemExit):
            docs_aliases.update_aliases("RewriteEngine On\n", "stable", "1.17.0")


class MainTest(unittest.TestCase):
    """Runs the script against a scratch Git repo, after a simulated `fineract-site docs`."""

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.git("init", "--quiet")
        (self.root / ".htaccess").write_text(HTACCESS, encoding="utf-8")
        self.page("1.17.0-SNAPSHOT", "1.17.0-SNAPSHOT")
        self.git("add", "-A")
        self.git("-c", "user.name=t", "-c", "user.email=t@example.com", "-c", "commit.gpgsign=false",
                 "commit", "--quiet", "-m", "initial")

    def git(self, *args):
        return subprocess.run(
            ["git", "-C", str(self.root), *args], check=True, capture_output=True, text=True
        ).stdout

    def page(self, folder, version, built="Sat Oct 24 2026"):
        # Large and mostly shared, like two builds of the docs, so Git pairs them as a rename.
        body = "".join(f"<p>section {i}</p>\n" for i in range(200))
        body += f"<p>version {version}</p>\n<p>Built on: {built}</p>\n"
        (self.root / "docs" / folder).mkdir(parents=True, exist_ok=True)
        (self.root / "docs" / folder / "index.html").write_text(body, encoding="utf-8")

    def fineract_site_docs(self, version):
        """What `fineract-site docs --version VERSION` leaves behind."""
        self.page(version, version, built="Sun Oct 25 2026")
        self.git("add", f"docs/{version}/index.html")
        (self.root / "DOCS-LOG-MESSAGE").write_text(MESSAGE.format(version=version), encoding="utf-8")

    def run_main(self, version, alias):
        argv = ["docs_aliases.py", "--version", version, "--alias", alias, "--repo-root", str(self.root)]
        with mock.patch("sys.argv", argv), mock.patch("builtins.print"):
            docs_aliases.main()

    def staged(self):
        return self.git("diff", "--cached", "-M", "--name-status").splitlines()

    def message(self):
        return (self.root / "DOCS-LOG-MESSAGE").read_text(encoding="utf-8")

    def test_no_release_only_updates_the_snapshot(self):
        self.fineract_site_docs("1.17.0-SNAPSHOT")
        self.run_main("1.17.0-SNAPSHOT", "develop")
        self.assertEqual(self.staged(), ["M\tdocs/1.17.0-SNAPSHOT/index.html"])
        self.assertEqual(self.message(), MESSAGE.format(version="1.17.0-SNAPSHOT"))

    def test_snapshot_roll_renames_and_moves_the_aliases(self):
        self.fineract_site_docs("1.18.0-SNAPSHOT")
        self.run_main("1.18.0-SNAPSHOT", "develop")
        staged = self.staged()
        self.assertIn("M\t.htaccess", staged)
        self.assertTrue(
            any(line.startswith("R") and line.endswith("\tdocs/1.17.0-SNAPSHOT/index.html\tdocs/1.18.0-SNAPSHOT/index.html")
                for line in staged),
            staged,
        )
        self.assertEqual(len(staged), 2)
        htaccess = (self.root / ".htaccess").read_text(encoding="utf-8")
        self.assertIn("docs/develop(.*)$ docs/1.18.0-SNAPSHOT$1", htaccess)
        self.assertIn("#RewriteRule ^docs/rc(.*)$ docs/1.18.0$1", htaccess)
        self.assertIn("Rename docs/1.17.0-SNAPSHOT to docs/1.18.0-SNAPSHOT", self.message())
        self.assertIn("Point the /docs/develop alias at 1.18.0-SNAPSHOT", self.message())

    def test_release_adds_the_folder_and_moves_stable(self):
        self.fineract_site_docs("1.17.0")
        self.run_main("1.17.0", "stable")
        self.assertEqual(sorted(self.staged()), ["A\tdocs/1.17.0/index.html", "M\t.htaccess"])
        self.assertIn("docs/stable(.*)$ docs/1.17.0$1", (self.root / ".htaccess").read_text(encoding="utf-8"))
        self.assertTrue((self.root / "docs" / "1.17.0-SNAPSHOT").is_dir())

    def test_refuses_to_run_before_fineract_site_docs(self):
        with self.assertRaises(SystemExit):
            self.run_main("1.18.0-SNAPSHOT", "develop")


if __name__ == "__main__":
    unittest.main()
